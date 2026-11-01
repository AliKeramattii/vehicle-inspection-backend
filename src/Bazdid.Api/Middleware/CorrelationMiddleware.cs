using System;
using System.Diagnostics;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;

namespace Bazdid.Api.Middleware
{
    public sealed class CorrelationMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<CorrelationMiddleware> _logger;
        public CorrelationMiddleware(RequestDelegate next, ILogger<CorrelationMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task Invoke(HttpContext context)
        {
            // شناسهٔ client مبنای اعتماد یا log نیست؛ از مقدار سروری استفاده می‌شود.
            context.TraceIdentifier = Guid.NewGuid().ToString("N");
            context.Response.OnStarting(() =>
            {
                context.Response.Headers["X-Correlation-ID"] = context.TraceIdentifier;
                context.Response.Headers["X-Content-Type-Options"] = "nosniff";
                return Task.CompletedTask;
            });
            var watch = Stopwatch.StartNew();
            using (_logger.BeginScope("CorrelationId:{CorrelationId}", context.TraceIdentifier))
            {
                try { await _next(context); }
                finally
                {
                    // مسیر و query و body ممکن است در آینده PII داشته باشند؛ ثبت نمی‌شوند.
                    _logger.LogInformation("Request completed with {StatusCode} in {ElapsedMilliseconds} ms; correlation {CorrelationId}",
                        context.Response.StatusCode, watch.ElapsedMilliseconds, context.TraceIdentifier);
                }
            }
        }
    }
}
