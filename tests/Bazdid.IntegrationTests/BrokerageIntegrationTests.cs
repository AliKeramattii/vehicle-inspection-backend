using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Threading;
using System.Threading.Tasks;
using Bazdid.Api;
using Bazdid.Api.Application;
using Bazdid.Api.Domain.Brokerage;
using Bazdid.Api.Infrastructure.Brokerage;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json.Linq;
using Xunit;

namespace Bazdid.IntegrationTests
{
    public class BrokerageIntegrationTests
    {
        private static TestServer Server(string environment, IDictionary<string, string> settings = null, RecordingLogger logger = null)
        {
            var root = new DirectoryInfo(AppContext.BaseDirectory);
            while (root != null && !File.Exists(Path.Combine(root.FullName, "Bazdid.sln"))) root = root.Parent;
            if (root == null) throw new InvalidOperationException("Solution root not found.");
            var builder = Program.CreateWebHostBuilder(new string[0])
                .UseContentRoot(Path.Combine(root.FullName, "src", "Bazdid.Api"))
                .UseEnvironment(environment)
                .ConfigureAppConfiguration((context, configuration) => configuration.AddInMemoryCollection(settings ?? new Dictionary<string, string>()));
            if (logger != null) builder.ConfigureLogging(logging => logging.AddProvider(logger));
            return new TestServer(builder);
        }

        [Theory]
        [InlineData("Development")]
        [InlineData("Testing")]
        public async Task Nonproduction_di_selects_synthetic_and_the_service_consumes_its_interface(string environment)
        {
            using (var server = Server(environment))
            {
                Assert.IsType<SyntheticBrokerageRequestReader>(server.Host.Services.GetRequiredService<IBrokerageRequestReader>());
                var service = server.Host.Services.GetRequiredService<BrokerageRequestService>();
                var resolution = await service.ResolveReferralAsync("A4K9P2", CancellationToken.None);
                Assert.Equal(BrokerageReadStatus.Found, resolution.Status);
                var snapshot = await service.GetRequestSnapshotAsync(resolution.Value, CancellationToken.None);
                Assert.Equal("TEST-REQUEST-001", snapshot.Value.Reference.SourceRequestId);
                Assert.Equal("TEST-CUSTOMER-001", snapshot.Value.SourceCustomerId);
                Assert.Equal(TimeSpan.Zero, snapshot.Value.RetrievedAtUtc.Offset);
            }
        }

        [Theory]
        [InlineData("Development")]
        [InlineData("Testing")]
        [InlineData("Production")]
        public async Task Explicit_disabled_mode_never_falls_back_to_a_synthetic_source(string environment)
        {
            var settings = new Dictionary<string, string>
            {
                ["Bazdid:BrokerageAdapterMode"]="Disabled", ["Bazdid:BrokerageId"]="", ["Bazdid:BrokerageSourceSystem"]=""
            };
            using (var server = Server(environment, settings))
            {
                Assert.IsType<SqlBrokerageRequestReader>(server.Host.Services.GetRequiredService<IBrokerageRequestReader>());
                var result = await server.Host.Services.GetRequiredService<BrokerageRequestService>().ResolveReferralAsync("A4K9P2", CancellationToken.None);
                Assert.Equal(BrokerageReadStatus.Unavailable, result.Status);
                Assert.Equal(BrokerageFailureReason.SourceNotConfigured, result.Reason);
                Assert.Null(result.Value);
            }
        }

        [Fact]
        public async Task Production_defaults_are_unconfigured_and_contain_no_fixed_fixture_scope()
        {
            using (var server = Server("Production"))
            {
                Assert.IsType<SqlBrokerageRequestReader>(server.Host.Services.GetRequiredService<IBrokerageRequestReader>());
                var result = await server.Host.Services.GetRequiredService<BrokerageRequestService>().ResolveReferralAsync("A4K9P2", CancellationToken.None);
                Assert.Equal(BrokerageFailureReason.SourceNotConfigured, result.Reason);
            }
        }

        [Fact]
        public async Task Configuring_a_real_scope_does_not_enable_unapproved_sql_or_fixture_fallback()
        {
            using (var server = Server("Production", new Dictionary<string, string>
            {
                ["Bazdid:BrokerageId"]="REAL-BROKER", ["Bazdid:BrokerageSourceSystem"]="PRIMARY"
            }))
            {
                var service = server.Host.Services.GetRequiredService<BrokerageRequestService>();
                var result = await service.ResolveReferralAsync("A4K9P2", CancellationToken.None);
                Assert.Equal(BrokerageFailureReason.SourceNotConfigured, result.Reason);
                var snapshot = await service.GetRequestSnapshotAsync(new BrokerageRequestReference(new BrokerageScope("REAL-BROKER", "PRIMARY"), "TEST-REQUEST-001"), CancellationToken.None);
                Assert.Equal(BrokerageReadStatus.Unavailable, snapshot.Status);
                Assert.Null(snapshot.Value);
            }
        }

        [Theory]
        [InlineData("Synthetic", "", "")]
        [InlineData("Synthetic", "TEST-BROKERAGE", "SYNTHETIC")]
        [InlineData("Disabled", "TEST-BROKERAGE", "SYNTHETIC")]
        [InlineData("Disabled", "REAL-BROKER", "synthetic")]
        public void Production_rejects_unsafe_mode_or_fixture_scope_at_startup(string mode, string brokerage, string source)
        {
            Assert.ThrowsAny<Exception>(() => Server("Production", new Dictionary<string, string>
            {
                ["Bazdid:BrokerageAdapterMode"]=mode, ["Bazdid:BrokerageId"]=brokerage, ["Bazdid:BrokerageSourceSystem"]=source
            }));
        }

        [Theory]
        [InlineData("Sql")]
        [InlineData("Automatic")]
        public void No_configuration_can_enable_an_unimplemented_sql_adapter(string mode)
        {
            Assert.ThrowsAny<Exception>(() => Server("Testing", new Dictionary<string, string> { ["Bazdid:BrokerageAdapterMode"]=mode }));
        }

        [Fact]
        public async Task Internal_reader_has_no_anonymous_http_surface_and_swagger_still_lists_only_health()
        {
            using (var server = Server("Testing"))
            using (var client = server.CreateClient())
            {
                client.BaseAddress = new Uri("https://localhost");
                foreach (var path in new[] { "/brokerage/requests/TEST-REQUEST-001", "/requests/TEST-REQUEST-001", "/referrals/A4K9P2", "/customers/TEST-CUSTOMER-001" })
                    Assert.Equal(HttpStatusCode.NotFound, (await client.GetAsync("/API/BAZDID" + path)).StatusCode);
                var doc = JObject.Parse(await client.GetStringAsync("/API/BAZDID/swagger/v1/swagger.json"));
                Assert.Single(((JObject)doc["paths"]).Properties());
                Assert.NotNull(doc["paths"]["/health/live"]);
                Assert.Equal("/API/BAZDID", (string)doc["basePath"]);
            }
        }

        [Fact]
        public async Task Reader_calls_do_not_log_referral_mobile_or_vehicle_values()
        {
            var logger = new RecordingLogger();
            using (var server = Server("Testing", logger: logger))
            {
                var service = server.Host.Services.GetRequiredService<BrokerageRequestService>();
                var resolution = await service.ResolveReferralAsync("A4K9P2", CancellationToken.None);
                await service.GetRequestSnapshotAsync(resolution.Value, CancellationToken.None);
                await service.ResolveReferralAsync("MOB001", CancellationToken.None);
                var log = string.Join("\n", logger.Messages);
                foreach (var secret in new[] { "A4K9P2", "09000000001", "09000000002", "SYNTHETIC-VIN-001" })
                    Assert.DoesNotContain(secret, log);
            }
        }
    }
}
