using System;
using System.Threading;
using System.Threading.Tasks;

namespace Bazdid.Api.Domain.Brokerage
{
    public enum BrokerageReadStatus { Found, NotFound, Ambiguous, Ineligible, Unavailable }
    public enum BrokerageFailureReason
    {
        None, SourceNotConfigured, SourceUnavailable, TrustedMobileConflict,
        TrustedMobileMissing, TrustedMobileInvalid, InvalidSourceIdentity, EligibilityUnknown
    }
    public enum RequestEligibility { Eligible, Ineligible, Unknown }

    // این قرارداد داخلی، principal یا مجوز دسترسی HTTP نیست.
    public sealed class BrokerageScope : IEquatable<BrokerageScope>
    {
        public BrokerageScope(string brokerageId, string sourceSystem)
        {
            ValidatePart(brokerageId);
            ValidatePart(sourceSystem);
            BrokerageId = brokerageId;
            SourceSystem = sourceSystem;
        }
        public string BrokerageId { get; }
        public string SourceSystem { get; }
        private static void ValidatePart(string value)
        {
            if (string.IsNullOrEmpty(value) || value.Length > 32)
                throw new ArgumentException("شناسهٔ scope سرور نامعتبر است.");
            foreach (var c in value)
                if (!(c >= 'A' && c <= 'Z') && !(c >= 'a' && c <= 'z') &&
                    !(c >= '0' && c <= '9') && c != '-' && c != '_')
                    throw new ArgumentException("شناسهٔ scope سرور نامعتبر است.");
        }
        public bool Equals(BrokerageScope other) => other != null &&
            string.Equals(BrokerageId, other.BrokerageId, StringComparison.Ordinal) &&
            string.Equals(SourceSystem, other.SourceSystem, StringComparison.Ordinal);
        public override bool Equals(object obj) => Equals(obj as BrokerageScope);
        public override int GetHashCode() => StringComparer.Ordinal.GetHashCode(BrokerageId) ^
            StringComparer.Ordinal.GetHashCode(SourceSystem);
    }

    public sealed class BrokerageRequestReference : IEquatable<BrokerageRequestReference>
    {
        public BrokerageRequestReference(BrokerageScope scope, string sourceRequestId)
        {
            Scope = scope ?? throw new ArgumentNullException(nameof(scope));
            BrokerageInput.ValidateSourceId(sourceRequestId);
            SourceRequestId = sourceRequestId;
        }
        public BrokerageScope Scope { get; }
        public string SourceRequestId { get; }
        public bool Equals(BrokerageRequestReference other) => other != null && Scope.Equals(other.Scope) &&
            string.Equals(SourceRequestId, other.SourceRequestId, StringComparison.Ordinal);
        public override bool Equals(object obj) => Equals(obj as BrokerageRequestReference);
        public override int GetHashCode() => Scope.GetHashCode() ^ StringComparer.Ordinal.GetHashCode(SourceRequestId);
    }

    public sealed class BrokerageReadResult<T> where T : class
    {
        private BrokerageReadResult(BrokerageReadStatus status, T value, BrokerageFailureReason reason)
        { Status = status; Value = value; Reason = reason; }
        public BrokerageReadStatus Status { get; }
        public T Value { get; }
        public BrokerageFailureReason Reason { get; }
        public static BrokerageReadResult<T> Found(T value) => new BrokerageReadResult<T>(
            BrokerageReadStatus.Found, value ?? throw new ArgumentNullException(nameof(value)), BrokerageFailureReason.None);
        public static BrokerageReadResult<T> Failure(BrokerageReadStatus status,
            BrokerageFailureReason reason = BrokerageFailureReason.None)
        {
            if (!Enum.IsDefined(typeof(BrokerageReadStatus), status) || status == BrokerageReadStatus.Found ||
                !Enum.IsDefined(typeof(BrokerageFailureReason), reason) ||
                (status == BrokerageReadStatus.Unavailable) != (reason != BrokerageFailureReason.None))
                throw new ArgumentException("ترکیب نتیجهٔ خواندن معتبر نیست.");
            return new BrokerageReadResult<T>(status, null, reason);
        }
    }

    public interface IBrokerageRequestReader
    {
        Task<BrokerageReadResult<BrokerageRequestReference>> ResolveReferralAsync(
            BrokerageScope serverScope, string referralCode, CancellationToken cancellationToken);

        // فراخوان باید پیش از این عملیات مالکیت را احراز کند؛ دانستن ID مجوز نیست.
        Task<BrokerageReadResult<BrokerageRequestSnapshot>> GetRequestSnapshotAsync(
            BrokerageRequestReference serverAuthorizedRequest, CancellationToken cancellationToken);
    }

    public interface IClock { DateTimeOffset UtcNow { get; } }

    internal static class BrokerageInput
    {
        public static void ValidateSourceId(string value)
        {
            if (string.IsNullOrWhiteSpace(value) || value.Length > 128)
                throw new ArgumentException("شناسهٔ خارجی معتبر نیست.");
        }
        public static void ValidateReferral(BrokerageScope scope, string code)
        {
            if (scope == null) throw new ArgumentNullException(nameof(scope));
            if (string.IsNullOrWhiteSpace(code) || code.Length > 128)
                throw new ArgumentException("ساختار کد معرفی معتبر نیست.");
        }
    }
}
