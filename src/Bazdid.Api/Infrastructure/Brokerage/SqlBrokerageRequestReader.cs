using System;
using System.Threading;
using System.Threading.Tasks;
using Bazdid.Api.Domain.Brokerage;

namespace Bazdid.Api.Infrastructure.Brokerage
{
    // مرز صریحِ تنظیم‌نشده؛ هیچ provider، اتصال، query یا fallback ندارد.
    public sealed class SqlBrokerageRequestReader : IBrokerageRequestReader
    {
        public Task<BrokerageReadResult<BrokerageRequestReference>> ResolveReferralAsync(
            BrokerageScope serverScope, string referralCode, CancellationToken cancellationToken)
        {
            cancellationToken.ThrowIfCancellationRequested();
            BrokerageInput.ValidateReferral(serverScope, referralCode);
            return Task.FromResult(BrokerageReadResult<BrokerageRequestReference>.Failure(
                BrokerageReadStatus.Unavailable, BrokerageFailureReason.SourceNotConfigured));
        }
        public Task<BrokerageReadResult<BrokerageRequestSnapshot>> GetRequestSnapshotAsync(
            BrokerageRequestReference serverAuthorizedRequest, CancellationToken cancellationToken)
        {
            cancellationToken.ThrowIfCancellationRequested();
            if (serverAuthorizedRequest == null) throw new ArgumentNullException(nameof(serverAuthorizedRequest));
            return Task.FromResult(BrokerageReadResult<BrokerageRequestSnapshot>.Failure(
                BrokerageReadStatus.Unavailable, BrokerageFailureReason.SourceNotConfigured));
        }
    }
}
