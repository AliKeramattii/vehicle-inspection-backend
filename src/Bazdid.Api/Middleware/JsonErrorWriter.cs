using System.Threading.Tasks;
using Bazdid.Api.Contracts;
using Microsoft.AspNetCore.Http;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;

namespace Bazdid.Api.Middleware
{
    internal static class JsonErrorWriter
    {
        private static readonly JsonSerializerSettings Settings = new JsonSerializerSettings
        {
            ContractResolver = new CamelCasePropertyNamesContractResolver()
        };

        public static Task Write(HttpContext context, int status, string code, string message)
        {
            context.Response.StatusCode = status;
            context.Response.ContentType = "application/json; charset=utf-8";
            context.Response.Headers["Cache-Control"] = "no-store";
            return context.Response.WriteAsync(JsonConvert.SerializeObject(new ApiError
            {
                Code = code, Message = message, CorrelationId = context.TraceIdentifier
            }, Settings));
        }
    }
}
