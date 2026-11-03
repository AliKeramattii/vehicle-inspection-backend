using System;
using System.Threading;
using System.Threading.Tasks;
using Bazdid.Api.Domain.Brokerage;
using Bazdid.Api.Domain.Persistence;

namespace Bazdid.Api.Application
{
    // فقط مصرف داخلیِ snapshot معتبر سرور؛ این سرویس اثبات هویت یا مجوز HTTP ایجاد نمی‌کند.
    public sealed class LinkagePersistenceService
    {
        private readonly IBazdidTransactionFactory _transactions;
        private readonly ICustomerLinkRepository _customers;
        private readonly IRequestContextRepository _requests;
        private readonly IAuditRepository _audit;
        public LinkagePersistenceService(IBazdidTransactionFactory transactions, ICustomerLinkRepository customers, IRequestContextRepository requests, IAuditRepository audit)
        { _transactions=transactions; _customers=customers; _requests=requests; _audit=audit; }
        public async Task<GetOrCreateResult<RequestContextRecord>> PersistAsync(BrokerageRequestSnapshot snapshot, string correlationId, CancellationToken cancellationToken)
        {
            if (snapshot == null) throw new ArgumentNullException(nameof(snapshot));
            // اعتبارسنجی پیش از بازکردن transaction؛ هیچ موبایل یا کد معرفی به persistence منتقل نمی‌شود.
            var metadata=new RequestMetadata(snapshot.Eligibility,snapshot.SourceVersion,snapshot.RetrievedAtUtc);
            PersistenceInput.SourceKey(snapshot.SourceCustomerId);
            PersistenceInput.SourceKey(snapshot.Reference.SourceRequestId);
            new ContextAuditEvent(snapshot.Reference.Scope,Guid.NewGuid(),AuditAction.LinkageCreated,correlationId);
            using (var transaction=await _transactions.BeginAsync(cancellationToken))
            {
                var customer=await _customers.GetOrCreateAsync(transaction,snapshot.Reference.Scope,snapshot.SourceCustomerId,cancellationToken);
                var request=await _requests.GetOrCreateAsync(transaction,snapshot.Reference,customer.Record,metadata,cancellationToken);
                if (request.Created) await _audit.AppendAsync(transaction,new ContextAuditEvent(snapshot.Reference.Scope,request.Record.Id,AuditAction.LinkageCreated,correlationId),cancellationToken);
                transaction.Commit(cancellationToken);
                return request;
            }
        }
    }
}
