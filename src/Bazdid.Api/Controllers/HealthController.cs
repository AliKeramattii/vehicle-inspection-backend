using Bazdid.Api.Contracts;
using Microsoft.AspNetCore.Mvc;

namespace Bazdid.Api.Controllers
{
    [ApiController]
    [Route("health/live")]
    public sealed class HealthController : ControllerBase
    {
        /// <summary>بررسی زنده‌بودن فرآیند Backend.</summary>
        /// <remarks>پاسخ نمونه: { "status": "alive" }. این endpoint اتصال SQL، پیامک یا فایل را بررسی نمی‌کند.</remarks>
        /// <response code="200">فرآیند در حال پاسخ‌گویی است.</response>
        [HttpGet]
        [Produces("application/json")]
        [ProducesResponseType(typeof(LivenessResponse), 200)]
        public ActionResult<LivenessResponse> Get()
        {
            Response.Headers["Cache-Control"] = "no-store";
            return new LivenessResponse();
        }
    }
}
