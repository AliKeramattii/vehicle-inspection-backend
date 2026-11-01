using System;

namespace Bazdid.Api.Domain.Brokerage
{
    public sealed class TrustedMobileReference
    {
        public TrustedMobileReference(string value, string policyId)
        {
            // سیاست صرفاً قالب fixture است؛ انتخاب/اعتبار موبایل واقعی به mapping مصوب نیاز دارد.
            if (value == null || value.Length != 11 || !value.StartsWith("09", StringComparison.Ordinal))
                throw new ArgumentException("مرجع موبایل معتبر نیست.");
            foreach (var c in value) if (c < '0' || c > '9') throw new ArgumentException("مرجع موبایل معتبر نیست.");
            if (string.IsNullOrWhiteSpace(policyId)) throw new ArgumentException("سیاست مرجع موبایل لازم است.");
            Value = value; PolicyId = policyId;
        }
        public string Value { get; }
        public string PolicyId { get; }
        public BrokerageFieldSource Source => BrokerageFieldSource.Brokerage;
        public bool IsReadOnly => true;
    }

    public sealed class BrokerageVehicleSnapshot
    {
        public BrokerageVehicleSnapshot(BrokerageField manufacturer, BrokerageField model, BrokerageField modelYear,
            BrokerageField color, BrokerageField licensePlate, BrokerageField vin, BrokerageField chassisNumber)
        {
            Manufacturer = manufacturer ?? throw new ArgumentNullException(nameof(manufacturer));
            Model = model ?? throw new ArgumentNullException(nameof(model));
            ModelYear = modelYear ?? throw new ArgumentNullException(nameof(modelYear));
            Color = color ?? throw new ArgumentNullException(nameof(color));
            LicensePlate = licensePlate ?? throw new ArgumentNullException(nameof(licensePlate));
            Vin = vin ?? throw new ArgumentNullException(nameof(vin));
            ChassisNumber = chassisNumber ?? throw new ArgumentNullException(nameof(chassisNumber));
        }
        public BrokerageField Manufacturer { get; }
        public BrokerageField Model { get; }
        public BrokerageField ModelYear { get; }
        public BrokerageField Color { get; }
        public BrokerageField LicensePlate { get; }
        public BrokerageField Vin { get; }
        public BrokerageField ChassisNumber { get; }
    }

    public sealed class BrokerageRequestSnapshot
    {
        public BrokerageRequestSnapshot(BrokerageRequestReference reference, string sourceCustomerId,
            TrustedMobileReference trustedMobile, RequestEligibility eligibility, BrokerageVehicleSnapshot vehicle,
            string sourceVersion, DateTimeOffset retrievedAtUtc)
        {
            Reference = reference ?? throw new ArgumentNullException(nameof(reference));
            BrokerageInput.ValidateSourceId(sourceCustomerId);
            TrustedMobile = trustedMobile ?? throw new ArgumentNullException(nameof(trustedMobile));
            Vehicle = vehicle ?? throw new ArgumentNullException(nameof(vehicle));
            if (!Enum.IsDefined(typeof(RequestEligibility), eligibility) || string.IsNullOrWhiteSpace(sourceVersion) ||
                retrievedAtUtc.Offset != TimeSpan.Zero) throw new ArgumentException("نسخه یا زمان snapshot معتبر نیست.");
            SourceCustomerId = sourceCustomerId; Eligibility = eligibility;
            SourceVersion = sourceVersion; RetrievedAtUtc = retrievedAtUtc;
        }
        public BrokerageRequestReference Reference { get; }
        public string SourceCustomerId { get; }
        public TrustedMobileReference TrustedMobile { get; }
        public RequestEligibility Eligibility { get; }
        public BrokerageVehicleSnapshot Vehicle { get; }
        public string SourceVersion { get; }
        public DateTimeOffset RetrievedAtUtc { get; }
    }
}
