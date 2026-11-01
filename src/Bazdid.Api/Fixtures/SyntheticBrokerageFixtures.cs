using System.Collections.Generic;
using Bazdid.Api.Domain.Brokerage;

namespace Bazdid.Api.Fixtures
{
    internal sealed class SyntheticBrokerageRecord
    {
        public BrokerageScope Scope { get; set; }
        public string RequestId { get; set; }
        public string CustomerId { get; set; } = "TEST-CUSTOMER-001";
        public string Referral { get; set; }
        public string CustomerMobile { get; set; } = "09000000001";
        public string RequestMobile { get; set; } = "09000000001";
        public RequestEligibility Eligibility { get; set; } = RequestEligibility.Eligible;
        public bool Unavailable { get; set; }
        public BrokerageVehicleSnapshot Vehicle { get; set; }
    }

    internal static class SyntheticBrokerageFixtures
    {
        // همهٔ سیاست‌ها fixture هستند؛ mapping واقعی سال/پلاک/VIN محسوب نمی‌شوند.
        public static IReadOnlyList<SyntheticBrokerageRecord> Create()
        {
            var scope = new BrokerageScope("TEST-BROKERAGE", "SYNTHETIC");
            var full = Vehicle("1399", "رنگ آزمایشی", "SYNTHETIC-VIN-001");
            return new[]
            {
                Record(scope, "TEST-REQUEST-001", "A4K9P2", full),
                Record(scope, "TEST-REQUEST-002", "SECOND", full),
                Record(scope, "TEST-MISSING", "MISS01", Vehicle(null, null, null)),
                Record(scope, "TEST-INVALID", "BAD001", Vehicle("invalid", "رنگ آزمایشی", "invalid")),
                Record(scope, "TEST-ZERO", "ZERO01", Vehicle("0", "0", "SYNTHETIC-VIN-001")),
                Record(scope, "TEST-AMBIGUOUS-1", "AMB001", full),
                Record(scope, "TEST-AMBIGUOUS-2", "AMB001", full),
                new SyntheticBrokerageRecord { Scope=scope, RequestId="TEST-INELIGIBLE", Referral="INEL01", Eligibility=RequestEligibility.Ineligible, Vehicle=full },
                new SyntheticBrokerageRecord { Scope=scope, RequestId="TEST-UNAVAILABLE", Referral="DOWN01", Unavailable=true, Vehicle=full },
                new SyntheticBrokerageRecord { Scope=scope, RequestId="TEST-MOBILE-CONFLICT", Referral="MOB001", RequestMobile="09000000002", Vehicle=full },
                new SyntheticBrokerageRecord { Scope=scope, RequestId="TEST-MOBILE-MISSING", Referral="MOB002", CustomerMobile=null, RequestMobile=null, Vehicle=full },
                new SyntheticBrokerageRecord { Scope=scope, RequestId="TEST-MOBILE-INVALID", Referral="MOB003", CustomerMobile="invalid", RequestMobile="invalid", Vehicle=full },
                new SyntheticBrokerageRecord { Scope=scope, RequestId="TEST-NO-CUSTOMER", Referral="CUST00", CustomerId=null, Vehicle=full },
                new SyntheticBrokerageRecord { Scope=scope, RequestId="TEST-UNKNOWN-ELIGIBILITY", Referral="ELIG00", Eligibility=RequestEligibility.Unknown, Vehicle=full },
                new SyntheticBrokerageRecord { Scope=scope, RequestId="9223372036854775807", CustomerId="9007199254740993", Referral="BIG001", Vehicle=full },
                Record(scope, "Opaque-درخواست ", "OPAQUE", full),
                Record(new BrokerageScope("OTHER-BROKERAGE", "SYNTHETIC"), "OTHER-REQUEST", "A4K9P2", full),
                Record(new BrokerageScope("TEST-BROKERAGE", "OTHER-SYNTHETIC"), "OTHER-SOURCE-REQUEST", "A4K9P2", full)
            };
        }
        private static SyntheticBrokerageRecord Record(BrokerageScope scope, string id, string referral, BrokerageVehicleSnapshot vehicle) =>
            new SyntheticBrokerageRecord { Scope=scope, RequestId=id, Referral=referral, Vehicle=vehicle };

        private static BrokerageVehicleSnapshot Vehicle(string year, string color, string vin) => new BrokerageVehicleSnapshot(
            BrokerageField.Present("سازندهٔ آزمایشی", "synthetic-manufacturer-v1"),
            BrokerageField.Present("مدل آزمایشی", "synthetic-model-v1"),
            year == null || year == "0" ? BrokerageField.Missing("synthetic-year-zero-missing-v1", true) :
                year == "1399" ? BrokerageField.Present(year, "synthetic-year-zero-missing-v1") : BrokerageField.Invalid(year, "synthetic-year-zero-missing-v1"),
            color == null ? BrokerageField.Missing("synthetic-color-label-v1", true) : BrokerageField.Present(color, "synthetic-color-label-v1"),
            BrokerageField.Present("SYNTHETIC-PLATE-001", "synthetic-plate-v1"),
            vin == null ? BrokerageField.Missing("synthetic-vin-v1", true) : vin.StartsWith("SYNTHETIC-", System.StringComparison.Ordinal) ?
                BrokerageField.Present(vin, "synthetic-vin-v1") : BrokerageField.Invalid(vin, "synthetic-vin-v1"),
            BrokerageField.Present("SYNTHETIC-CHASSIS-001", "synthetic-chassis-v1"));
    }
}
