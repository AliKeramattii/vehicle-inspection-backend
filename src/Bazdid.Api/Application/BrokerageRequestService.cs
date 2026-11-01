using System;
using System.Threading;
using System.Threading.Tasks;
using Bazdid.Api.Domain.Brokerage;

namespace Bazdid.Api.Application
{
    // scope از DI سرور است؛ این سرویس داخلی احراز هویت یا مجوز مالکیت صادر نمی‌کند.
    public sealed class BrokerageRequestService
    {
        private readonly IBrokerageRequestReader _reader;
        private readonly BrokerageScope _serverScope;
        public BrokerageRequestService(IBrokerageRequestReader reader, BrokerageScope serverScope)
        { _reader = reader ?? throw new ArgumentNullException(nameof(reader)); _serverScope = serverScope; }

        public async Task<BrokerageReadResult<BrokerageRequestReference>> ResolveReferralAsync(
            string referralCode, CancellationToken cancellationToken)
        {
            cancellationToken.ThrowIfCancellationRequested();
            if (_serverScope == null) return Unconfigured<BrokerageRequestReference>();
            BrokerageInput.ValidateReferral(_serverScope, referralCode);
            var result = await ReadAsync(() => _reader.ResolveReferralAsync(_serverScope, referralCode, cancellationToken), cancellationToken);
            if (result.Status == BrokerageReadStatus.Found && !result.Value.Scope.Equals(_serverScope))
                return InvalidIdentity<BrokerageRequestReference>();
            return result;
        }

        public async Task<BrokerageReadResult<BrokerageRequestSnapshot>> GetRequestSnapshotAsync(
            BrokerageRequestReference serverAuthorizedRequest, CancellationToken cancellationToken)
        {
            cancellationToken.ThrowIfCancellationRequested();
            if (serverAuthorizedRequest == null) throw new ArgumentNullException(nameof(serverAuthorizedRequest));
            if (_serverScope == null) return Unconfigured<BrokerageRequestSnapshot>();
            if (!_serverScope.Equals(serverAuthorizedRequest.Scope))
                return BrokerageReadResult<BrokerageRequestSnapshot>.Failure(BrokerageReadStatus.NotFound);
            var result = await ReadAsync(() => _reader.GetRequestSnapshotAsync(serverAuthorizedRequest, cancellationToken), cancellationToken);
            if (result.Status == BrokerageReadStatus.Found && !result.Value.Reference.Equals(serverAuthorizedRequest))
                return InvalidIdentity<BrokerageRequestSnapshot>();
            return result;
        }

        private static async Task<BrokerageReadResult<T>> ReadAsync<T>(Func<Task<BrokerageReadResult<T>>> read,
            CancellationToken cancellationToken) where T : class
        {
            try
            {
                var result = await read();
                cancellationToken.ThrowIfCancellationRequested();
                return result ?? InvalidIdentity<T>();
            }
            catch (TimeoutException) { cancellationToken.ThrowIfCancellationRequested(); return SourceUnavailable<T>(); }
            catch (OperationCanceledException) when (!cancellationToken.IsCancellationRequested) { return SourceUnavailable<T>(); }
        }
        private static BrokerageReadResult<T> Unconfigured<T>() where T : class =>
            BrokerageReadResult<T>.Failure(BrokerageReadStatus.Unavailable, BrokerageFailureReason.SourceNotConfigured);
        private static BrokerageReadResult<T> SourceUnavailable<T>() where T : class =>
            BrokerageReadResult<T>.Failure(BrokerageReadStatus.Unavailable, BrokerageFailureReason.SourceUnavailable);
        private static BrokerageReadResult<T> InvalidIdentity<T>() where T : class =>
            BrokerageReadResult<T>.Failure(BrokerageReadStatus.Unavailable, BrokerageFailureReason.InvalidSourceIdentity);
    }
}
