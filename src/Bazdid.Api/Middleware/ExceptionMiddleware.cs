using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;

namespace Bazdid.Api.Middleware
{
    public sealed class ExceptionMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<ExceptionMiddleware> _logger;
        public ExceptionMiddleware(RequestDelegate next, ILogger<ExceptionMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task Invoke(HttpContext context)
        {
            try { await _next(context); }
            catch (OperationCanceledException) when (context.RequestAborted.IsCancellationRequested)
            {
                context.Abort();
            }
            catch (Exception exception)
            {
                // متن/stack خطا ممکن است credential یا دادهٔ شخصی داشته باشد.
                _logger.LogError("Unhandled error type {ExceptionType}; correlation {CorrelationId}",
                    exception.GetType().Name, context.TraceIdentifier);
                if (context.Response.HasStarted)
                {
                    context.Abort();
                    return;
                }
                context.Response.Clear();
                await JsonErrorWriter.Write(context, 500, "INTERNAL_ERROR", "خطای داخلی رخ داد؛ شناسهٔ پیگیری را به پشتیبانی اعلام کنید.");
            }
        }
    }
}
