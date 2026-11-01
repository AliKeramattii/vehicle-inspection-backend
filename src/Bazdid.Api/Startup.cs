using System;
using System.IO;
using Bazdid.Api.Configuration;
using Bazdid.Api.Middleware;
using Bazdid.Api.Infrastructure.Brokerage;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;
using Swashbuckle.AspNetCore.Swagger;

namespace Bazdid.Api
{
    public class Startup
    {
        private readonly FoundationOptions _settings;
        private readonly bool _swaggerEnabled;
        private readonly IHostingEnvironment _environment;

        public Startup(IConfiguration configuration, IHostingEnvironment environment)
        {
            _environment = environment;
            _settings = new FoundationOptions();
            configuration.GetSection("Bazdid").Bind(_settings);
            _settings.Validate(environment.EnvironmentName);
            if (configuration.GetValue<bool>("Authentication:Enabled"))
                throw new InvalidOperationException("Authentication is not implemented in Checkpoint 1.");
            _swaggerEnabled = _settings.SwaggerEnabled && (environment.IsDevelopment() || environment.IsEnvironment("Testing"));
        }

        public void ConfigureServices(IServiceCollection services)
        {
            services.AddSingleton(_settings);
            services.AddBrokerageReader(_settings, _environment);
            services.AddCors(options => options.AddPolicy("TrustedFrontend", policy =>
            {
                if (_settings.TrustedFrontendOrigins.Length > 0)
                    policy.WithOrigins(_settings.TrustedFrontendOrigins);
                policy.WithMethods("GET", "HEAD", "OPTIONS")
                    .WithHeaders("Accept", "Content-Type")
                    .WithExposedHeaders("X-Correlation-ID");
                // احراز cookie هنوز وجود ندارد؛ credentials و mutation header بعداً با CSRF افزوده می‌شوند.
            }));
            services.AddHttpsRedirection(options => options.HttpsPort = _settings.HttpsPort);
            services.AddHsts(options => options.MaxAge = TimeSpan.FromDays(30));
            services.AddMvc().SetCompatibilityVersion(CompatibilityVersion.Version_2_1).AddJsonOptions(options =>
            {
                options.SerializerSettings.ContractResolver = new CamelCasePropertyNamesContractResolver();
                options.SerializerSettings.DateTimeZoneHandling = DateTimeZoneHandling.Utc;
                options.SerializerSettings.MaxDepth = 32;
                options.SerializerSettings.TypeNameHandling = TypeNameHandling.None;
            });
            if (_swaggerEnabled)
                services.AddSwaggerGen(options =>
                {
                    options.SwaggerDoc("v1", new Info
                    {
                        Title = "BAZDID API", Version = "v1",
                        Description = "فقط liveness در HTTP فعال است؛ خوانندهٔ داخلی ساختگی 2D فقط Development/Testing است. احراز هویت و SQL واقعی فعال نیستند."
                    });
                    options.IncludeXmlComments(Path.Combine(AppContext.BaseDirectory, "Bazdid.Api.xml"));
                });
        }

        public void Configure(IApplicationBuilder app, IHostingEnvironment environment, ILogger<Startup> logger)
        {
            app.UseMiddleware<CorrelationMiddleware>();
            app.UseMiddleware<ExceptionMiddleware>();
            app.UseStatusCodePages(async status =>
            {
                var code = status.HttpContext.Response.StatusCode;
                await JsonErrorWriter.Write(status.HttpContext, code,
                    code == 404 ? "NOT_FOUND" : "HTTP_ERROR",
                    code == 404 ? "مسیر درخواستی یافت نشد." : "درخواست قابل پردازش نیست.");
            });

            if (_settings.HostingMode == "Standalone")
                app.UsePathBase(_settings.ApiBasePath);
            app.Use(async (context, next) =>
            {
                if (!string.Equals(context.Request.PathBase.Value, _settings.ApiBasePath, StringComparison.Ordinal))
                {
                    await JsonErrorWriter.Write(context, 404, "NOT_FOUND", "مسیر درخواستی یافت نشد.");
                    return;
                }
                await next();
            });
            // HSTS بر کل host اثر دارد؛ روی سایت مشترک فقط پس از هماهنگی زیرساخت فعال می‌شود.
            if (environment.IsProduction() && _settings.HstsEnabled) app.UseHsts();
            if (_settings.HttpsRedirectionEnabled) app.UseHttpsRedirection();
            app.UseCors("TrustedFrontend");

            if (_swaggerEnabled)
            {
                app.Use(async (context, next) =>
                {
                    // Swagger UI قدیمی اجازهٔ تغییر remote definition با query دارد؛ این قابلیت لازم نیست.
                    if (context.Request.Path.StartsWithSegments("/swagger") && context.Request.QueryString.HasValue)
                    {
                        await JsonErrorWriter.Write(context, 400, "SWAGGER_QUERY_NOT_ALLOWED", "پارامتر query برای مستندات مجاز نیست.");
                        return;
                    }
                    await next();
                });
                app.UseSwagger(options => options.PreSerializeFilters.Add((document, request) =>
                {
                    document.BasePath = request.PathBase.Value;
                    document.Host = null;
                }));
                app.UseSwaggerUI(options => options.SwaggerEndpoint("v1/swagger.json", "BAZDID v1"));
            }
            app.UseMvc();
            logger.LogInformation("BAZDID foundation started; environment {Environment}, hosting {HostingMode}, base {ApiBasePath}, Swagger {SwaggerEnabled}. External integrations disabled.",
                environment.EnvironmentName, _settings.HostingMode, _settings.ApiBasePath, _swaggerEnabled);
        }
    }
}
