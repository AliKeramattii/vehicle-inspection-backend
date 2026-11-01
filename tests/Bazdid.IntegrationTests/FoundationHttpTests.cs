using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using Bazdid.Api;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json.Linq;
using Xunit;

namespace Bazdid.IntegrationTests
{
    public class FoundationHttpTests
    {
        private const string Base = "/API/BAZDID";

        private static TestServer CreateServer(string environment = "Testing", string hosting = "Standalone",
            bool injectFailure = false, RecordingLogger logger = null, string simulatedBase = Base,
            IDictionary<string, string> overrides = null)
        {
            var folder = new DirectoryInfo(AppContext.BaseDirectory);
            while (folder != null && !File.Exists(Path.Combine(folder.FullName, "Bazdid.sln"))) folder = folder.Parent;
            if (folder == null) throw new InvalidOperationException("Solution root not found.");
            var settings = new Dictionary<string, string>
            {
                ["Bazdid:HostingMode"] = hosting,
                ["Bazdid:SwaggerEnabled"] = "true",
                ["Bazdid:TrustedFrontendOrigins:0"] = "https://frontend.example.invalid"
            };
            if (overrides != null) foreach (var pair in overrides) settings[pair.Key] = pair.Value;
            var builder = Program.CreateWebHostBuilder(new string[0])
                .UseContentRoot(Path.Combine(folder.FullName, "src", "Bazdid.Api"))
                .UseEnvironment(environment)
                .ConfigureAppConfiguration((context, configuration) => configuration.AddInMemoryCollection(settings));
            if (logger != null) builder.ConfigureLogging(logging => logging.AddProvider(logger));
            builder.ConfigureTestServices(services =>
            {
                if (injectFailure) services.AddMvc().AddApplicationPart(typeof(FailureController).Assembly);
                if (hosting == "Iis") services.AddSingleton<IStartupFilter>(new SimulatedIisFilter(simulatedBase));
            });
            return new TestServer(builder);
        }

        private static HttpClient Client(TestServer server)
        {
            var client = server.CreateClient();
            client.BaseAddress = new Uri("https://localhost");
            return client;
        }

        [Theory]
        [InlineData("Development")]
        [InlineData("Testing")]
        [InlineData("Production")]
        public async Task Starts_and_exposes_only_process_liveness(string environment)
        {
            using (var server = CreateServer(environment))
            using (var client = Client(server))
            {
                var response = await client.GetAsync(Base + "/health/live");
                Assert.Equal(HttpStatusCode.OK, response.StatusCode);
                Assert.Equal("application/json", response.Content.Headers.ContentType.MediaType);
                Assert.Equal("{\"status\":\"alive\"}", await response.Content.ReadAsStringAsync());
                Assert.True(response.Headers.CacheControl.NoStore);
                Assert.True(response.Headers.Contains("X-Correlation-ID"));
                Assert.Equal("nosniff", string.Join("", response.Headers.GetValues("X-Content-Type-Options")));
            }
        }

        [Theory]
        [InlineData("/health/live")]
        [InlineData("/API/BAZDIDx/health/live")]
        [InlineData("/API/BAZDID/API/BAZDID/health/live")]
        [InlineData("/API/BAZDID/not-a-route")]
        [InlineData("/API/BAZDID/auth/otp/verify")]
        [InlineData("/API/BAZDID/diagnostics/error")]
        public async Task Invalid_or_future_routes_return_safe_correlated_json(string route)
        {
            using (var server = CreateServer())
            using (var client = Client(server))
            {
                client.DefaultRequestHeaders.Add("X-Correlation-ID", "client-value-must-not-be-trusted");
                var response = await client.GetAsync(route);
                Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
                var error = JObject.Parse(await response.Content.ReadAsStringAsync());
                Assert.Equal("NOT_FOUND", (string)error["code"]);
                Assert.Equal(32, ((string)error["correlationId"]).Length);
                Assert.NotEqual("client-value-must-not-be-trusted", (string)error["correlationId"]);
                Assert.Equal((string)error["correlationId"], string.Join("", response.Headers.GetValues("X-Correlation-ID")));
            }
        }

        [Theory]
        [InlineData("Development")]
        [InlineData("Testing")]
        public async Task Swagger_describes_the_single_implemented_endpoint_and_uses_pathbase(string environment)
        {
            using (var server = CreateServer(environment))
            using (var client = Client(server))
            {
                var document = JObject.Parse(await client.GetStringAsync(Base + "/swagger/v1/swagger.json"));
                Assert.Equal("2.0", (string)document["swagger"]);
                Assert.Equal(Base, (string)document["basePath"]);
                Assert.Single(((JObject)document["paths"]).Properties());
                Assert.NotNull(document["paths"]["/health/live"]["get"]["responses"]["200"]);
                Assert.Null(document["host"]);
                var ui = await client.GetStringAsync(Base + "/swagger/index.html");
                Assert.Contains("v1/swagger.json", ui);
                Assert.Equal(HttpStatusCode.OK, (await client.GetAsync(Base + "/swagger/swagger-ui-bundle.js")).StatusCode);
            }
        }

        [Theory]
        [InlineData("/swagger/index.html")]
        [InlineData("/swagger/v1/swagger.json")]
        [InlineData("/swagger/swagger-ui-bundle.js")]
        public async Task Production_hides_swagger_even_if_enabled_by_configuration(string suffix)
        {
            using (var server = CreateServer("Production"))
            using (var client = Client(server))
                Assert.Equal(HttpStatusCode.NotFound, (await client.GetAsync(Base + suffix)).StatusCode);
        }

        [Theory]
        [InlineData("https://attacker.example.invalid")]
        [InlineData("https://frontend.example.invalid.attacker.invalid")]
        [InlineData("null")]
        public async Task Untrusted_origins_receive_no_cors_permission(string origin)
        {
            using (var server = CreateServer())
            using (var client = Client(server))
            {
                var request = new HttpRequestMessage(HttpMethod.Options, Base + "/health/live");
                request.Headers.Add("Origin", origin);
                request.Headers.Add("Access-Control-Request-Method", "GET");
                var response = await client.SendAsync(request);
                Assert.False(response.Headers.Contains("Access-Control-Allow-Origin"));
                Assert.False(response.Headers.Contains("Access-Control-Allow-Credentials"));
            }
        }

        [Fact]
        public async Task Trusted_origin_preflight_and_get_are_allowed_without_cookie_credentials()
        {
            using (var server = CreateServer())
            using (var client = Client(server))
            {
                var request = new HttpRequestMessage(HttpMethod.Options, Base + "/health/live");
                request.Headers.Add("Origin", "https://frontend.example.invalid");
                request.Headers.Add("Access-Control-Request-Method", "GET");
                var response = await client.SendAsync(request);
                Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
                Assert.Equal("https://frontend.example.invalid", string.Join("", response.Headers.GetValues("Access-Control-Allow-Origin")));
                Assert.False(response.Headers.Contains("Access-Control-Allow-Credentials"));
                client.DefaultRequestHeaders.Add("Origin", "https://frontend.example.invalid");
                Assert.True((await client.GetAsync(Base + "/health/live")).Headers.Contains("Access-Control-Allow-Origin"));
            }
        }

        [Fact]
        public async Task Iis_metadata_is_not_split_a_second_time()
        {
            using (var server = CreateServer(hosting: "Iis"))
            using (var client = Client(server))
            {
                Assert.Equal(HttpStatusCode.OK, (await client.GetAsync("/health/live")).StatusCode);
                Assert.Equal(HttpStatusCode.NotFound, (await client.GetAsync(Base + "/health/live")).StatusCode);
                var document = JObject.Parse(await client.GetStringAsync("/swagger/v1/swagger.json"));
                Assert.Equal(Base, (string)document["basePath"]);
            }
            using (var server = CreateServer(hosting: "Iis", simulatedBase: "/wrong"))
            using (var client = Client(server))
                Assert.Equal(HttpStatusCode.NotFound, (await client.GetAsync("/health/live")).StatusCode);
        }

        [Theory]
        [InlineData("Development")]
        [InlineData("Production")]
        public async Task Exceptions_never_expose_sensitive_messages_or_stacks_in_responses_or_logs(string environment)
        {
            var logger = new RecordingLogger();
            using (var server = CreateServer(environment, injectFailure: true, logger: logger))
            using (var client = Client(server))
            {
                var response = await client.GetAsync(Base + "/test-failure");
                Assert.Equal(HttpStatusCode.InternalServerError, response.StatusCode);
                var body = await response.Content.ReadAsStringAsync();
                Assert.Equal("INTERNAL_ERROR", (string)JObject.Parse(body)["code"]);
                Assert.DoesNotContain("DO_NOT_EXPOSE", body);
                Assert.DoesNotContain("stack", body.ToLowerInvariant());
                Assert.DoesNotContain("DO_NOT_EXPOSE", string.Join("\n", logger.Messages));
            }
        }

        [Fact]
        public async Task Production_redirects_http_to_https_with_prefix_intact()
        {
            using (var server = CreateServer("Production"))
            using (var client = Client(server))
            {
                var response = await client.GetAsync("http://localhost" + Base + "/health/live");
                Assert.Equal(HttpStatusCode.TemporaryRedirect, response.StatusCode);
                Assert.Equal("https://localhost" + Base + "/health/live", response.Headers.Location.ToString());
            }
        }

        [Fact]
        public void Application_rejects_invalid_settings_at_startup()
        {
            Assert.ThrowsAny<Exception>(() => CreateServer(overrides: new Dictionary<string, string> { ["Bazdid:ApiBasePath"] = "/api" }));
            Assert.ThrowsAny<Exception>(() => CreateServer(overrides: new Dictionary<string, string> { ["Authentication:Enabled"] = "true" }));
        }

        [Fact]
        public async Task Development_swagger_can_be_disabled_explicitly()
        {
            using (var server = CreateServer("Development", overrides: new Dictionary<string, string> { ["Bazdid:SwaggerEnabled"] = "false" }))
            using (var client = Client(server))
                Assert.Equal(HttpStatusCode.NotFound, (await client.GetAsync(Base + "/swagger/v1/swagger.json")).StatusCode);
        }

        [Theory]
        [InlineData("/swagger/index.html?url=https://attacker.example.invalid/spec.json")]
        [InlineData("/swagger/?configUrl=https://attacker.example.invalid/config")]
        public async Task Swagger_remote_definition_query_is_rejected(string suffix)
        {
            using (var server = CreateServer())
            using (var client = Client(server))
            {
                var response = await client.GetAsync(Base + suffix);
                Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
                Assert.Equal("SWAGGER_QUERY_NOT_ALLOWED", (string)JObject.Parse(await response.Content.ReadAsStringAsync())["code"]);
            }
        }

        [Theory]
        [InlineData(false)]
        [InlineData(true)]
        public async Task Hsts_requires_explicit_host_level_opt_in(bool enabled)
        {
            using (var server = CreateServer("Production", overrides: new Dictionary<string, string>
            {
                ["AllowedHosts"] = "api.example.invalid", ["Bazdid:HstsEnabled"] = enabled.ToString()
            }))
            using (var client = Client(server))
            {
                var response = await client.GetAsync("https://api.example.invalid" + Base + "/health/live");
                Assert.Equal(HttpStatusCode.OK, response.StatusCode);
                Assert.Equal(enabled, response.Headers.Contains("Strict-Transport-Security"));
            }
        }
    }

    // فقط assembly آزمون اضافه می‌شود؛ در artifact/API واقعی چنین endpointی وجود ندارد.
    [Route("test-failure")]
    public sealed class FailureController : ControllerBase
    {
        [HttpGet]
        public IActionResult Get() { throw new InvalidOperationException("DO_NOT_EXPOSE password or private path"); }
    }

    internal sealed class SimulatedIisFilter : IStartupFilter
    {
        private readonly string _base;
        public SimulatedIisFilter(string pathBase) { _base = pathBase; }
        public Action<IApplicationBuilder> Configure(Action<IApplicationBuilder> next)
        {
            return app =>
            {
                app.Use((context, proceed) => { context.Request.PathBase = _base; return proceed(); });
                next(app);
            };
        }
    }

    public sealed class RecordingLogger : ILoggerProvider, ILogger
    {
        public readonly ConcurrentQueue<string> Messages = new ConcurrentQueue<string>();
        public ILogger CreateLogger(string categoryName) { return this; }
        public IDisposable BeginScope<TState>(TState state) { return null; }
        public bool IsEnabled(LogLevel level) { return true; }
        public void Log<TState>(LogLevel level, EventId id, TState state, Exception exception, Func<TState, Exception, string> formatter)
        { Messages.Enqueue(formatter(state, exception) + (exception == null ? "" : exception.ToString())); }
        public void Dispose() { }
    }
}
