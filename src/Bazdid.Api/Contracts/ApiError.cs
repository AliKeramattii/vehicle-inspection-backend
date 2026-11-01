namespace Bazdid.Api.Contracts
{
    public sealed class ApiError
    {
        public string Code { get; set; }
        public string Message { get; set; }
        public string CorrelationId { get; set; }
    }
}
