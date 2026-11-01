using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Bazdid.Api.Domain.Brokerage;
using Bazdid.Api.Fixtures;
using Microsoft.AspNetCore.Hosting;

namespace Bazdid.Api.Infrastructure.Brokerage
{
    public sealed class SyntheticBrokerageRequestReader : IBrokerageRequestReader
    {
        private readonly IReadOnlyList<SyntheticBrokerageRecord> _records;
        private readonly IClock _clock;
        public SyntheticBrokerageRequestReader(IHostingEnvironment environment, IClock clock)
        {
            if (environment == null || (environment.EnvironmentName != "Development" && environment.EnvironmentName != "Testing"))
                throw new InvalidOperationException("خوانندهٔ ساختگی فقط در Development/Testing مجاز است.");
            _clock = clock ?? throw new ArgumentNullException(nameof(clock));
            _records = SyntheticBrokerageFixtures.Create();
        }
        public Task<BrokerageReadResult<BrokerageRequestReference>> ResolveReferralAsync(
            BrokerageScope serverScope, string referralCode, CancellationToken cancellationToken)
        {
            cancellationToken.ThrowIfCancellationRequested();
            BrokerageInput.ValidateReferral(serverScope, referralCode);
            var matches = _records.Where(r => r.Scope.Equals(serverScope) &&
                string.Equals(r.Referral, referralCode, StringComparison.Ordinal)).Take(2).ToArray();
            if (matches.Length == 0) return Result(BrokerageReadResult<BrokerageRequestReference>.Failure(BrokerageReadStatus.NotFound));
            if (matches.Length > 1) return Result(BrokerageReadResult<BrokerageRequestReference>.Failure(BrokerageReadStatus.Ambiguous));
            var record = matches[0];
            var reason = FailureReason(record);
            if (reason != BrokerageFailureReason.None) return Result(BrokerageReadResult<BrokerageRequestReference>.Failure(BrokerageReadStatus.Unavailable, reason));
            if (record.Eligibility == RequestEligibility.Ineligible) return Result(BrokerageReadResult<BrokerageRequestReference>.Failure(BrokerageReadStatus.Ineligible));
            cancellationToken.ThrowIfCancellationRequested();
            return Result(BrokerageReadResult<BrokerageRequestReference>.Found(new BrokerageRequestReference(record.Scope, record.RequestId)));
        }
        public Task<BrokerageReadResult<BrokerageRequestSnapshot>> GetRequestSnapshotAsync(
            BrokerageRequestReference serverAuthorizedRequest, CancellationToken cancellationToken)
        {
            cancellationToken.ThrowIfCancellationRequested();
            if (serverAuthorizedRequest == null) throw new ArgumentNullException(nameof(serverAuthorizedRequest));
            var record = _records.SingleOrDefault(r => r.Scope.Equals(serverAuthorizedRequest.Scope) &&
                string.Equals(r.RequestId, serverAuthorizedRequest.SourceRequestId, StringComparison.Ordinal));
            if (record == null) return Result(BrokerageReadResult<BrokerageRequestSnapshot>.Failure(BrokerageReadStatus.NotFound));
            var reason = FailureReason(record);
            if (reason != BrokerageFailureReason.None) return Result(BrokerageReadResult<BrokerageRequestSnapshot>.Failure(BrokerageReadStatus.Unavailable, reason));
            if (record.Eligibility == RequestEligibility.Ineligible) return Result(BrokerageReadResult<BrokerageRequestSnapshot>.Failure(BrokerageReadStatus.Ineligible));
            var snapshot = new BrokerageRequestSnapshot(serverAuthorizedRequest, record.CustomerId,
                new TrustedMobileReference(record.CustomerMobile, "synthetic-agreeing-candidates-v1"),
                record.Eligibility, record.Vehicle, "synthetic-v1", _clock.UtcNow);
            cancellationToken.ThrowIfCancellationRequested();
            return Result(BrokerageReadResult<BrokerageRequestSnapshot>.Found(snapshot));
        }
        private static Task<T> Result<T>(T result) => Task.FromResult(result);
        private static BrokerageFailureReason FailureReason(SyntheticBrokerageRecord record)
        {
            if (record.Unavailable) return BrokerageFailureReason.SourceUnavailable;
            if (string.IsNullOrWhiteSpace(record.CustomerId)) return BrokerageFailureReason.InvalidSourceIdentity;
            if (record.Eligibility == RequestEligibility.Unknown) return BrokerageFailureReason.EligibilityUnknown;
            if (record.CustomerMobile == null || record.RequestMobile == null) return BrokerageFailureReason.TrustedMobileMissing;
            if (!string.Equals(record.CustomerMobile, record.RequestMobile, StringComparison.Ordinal)) return BrokerageFailureReason.TrustedMobileConflict;
            try { new TrustedMobileReference(record.CustomerMobile, "synthetic-agreeing-candidates-v1"); }
            catch (ArgumentException) { return BrokerageFailureReason.TrustedMobileInvalid; }
            return BrokerageFailureReason.None;
        }
    }
}
