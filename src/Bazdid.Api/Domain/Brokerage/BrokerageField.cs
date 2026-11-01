using System;

namespace Bazdid.Api.Domain.Brokerage
{
    public enum BrokerageFieldStatus { Present, Missing, Invalid, Unavailable }
    public enum BrokerageFieldSource { Brokerage }
    public enum FieldValidationStatus { Valid, NotApplicable, Invalid, NotEvaluated }

    public sealed class BrokerageFieldValidation
    {
        internal BrokerageFieldValidation(string policyId, FieldValidationStatus status, string code)
        {
            if (string.IsNullOrWhiteSpace(policyId)) throw new ArgumentException("شناسهٔ سیاست لازم است.");
            PolicyId = policyId; Status = status; Code = code;
        }
        public string PolicyId { get; }
        public FieldValidationStatus Status { get; }
        public string Code { get; }
    }

    // مقادیر این snapshot رشتهٔ مبدأ هستند؛ تقویم/کد lookup بدون mapping حدس زده نمی‌شود.
    public sealed class BrokerageField
    {
        private BrokerageField(string value, BrokerageFieldStatus status, bool manualAllowed,
            BrokerageFieldValidation validation)
        { Value = value; Status = status; IsReadOnly = status != BrokerageFieldStatus.Missing || !manualAllowed; Validation = validation; }
        public string Value { get; }
        public BrokerageFieldSource Source => BrokerageFieldSource.Brokerage;
        public BrokerageFieldStatus Status { get; }
        public bool IsReadOnly { get; }
        public BrokerageFieldValidation Validation { get; }
        public static BrokerageField Present(string value, string policyId)
        {
            if (string.IsNullOrWhiteSpace(value)) throw new ArgumentException("مقدار معتبر لازم است.");
            return new BrokerageField(value, BrokerageFieldStatus.Present, false,
                new BrokerageFieldValidation(policyId, FieldValidationStatus.Valid, "VALID"));
        }
        public static BrokerageField Missing(string policyId, bool manualAllowed) =>
            new BrokerageField(null, BrokerageFieldStatus.Missing, manualAllowed,
                new BrokerageFieldValidation(policyId, FieldValidationStatus.NotApplicable, "EXPLICITLY_MISSING"));
        public static BrokerageField Invalid(string value, string policyId) =>
            new BrokerageField(value, BrokerageFieldStatus.Invalid, false,
                new BrokerageFieldValidation(policyId, FieldValidationStatus.Invalid, "INVALID_SOURCE_VALUE"));
        public static BrokerageField Unavailable(string policyId) =>
            new BrokerageField(null, BrokerageFieldStatus.Unavailable, false,
                new BrokerageFieldValidation(policyId, FieldValidationStatus.NotEvaluated, "SOURCE_UNAVAILABLE"));
    }
}
