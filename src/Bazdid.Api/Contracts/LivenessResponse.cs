namespace Bazdid.Api.Contracts
{
    /// <summary>فقط زنده‌بودن فرآیند؛ وابستگی‌های خارجی بررسی نمی‌شوند.</summary>
    public sealed class LivenessResponse
    {
        /// <summary>مقدار ثابت alive؛ نشانهٔ آمادگی SQL، SMS یا storage نیست.</summary>
        public string Status { get; set; } = "alive";
    }
}
