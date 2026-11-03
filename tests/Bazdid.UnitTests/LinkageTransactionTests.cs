using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Bazdid.Api.Application;
using Bazdid.Api.Domain.Brokerage;
using Bazdid.Api.Domain.Persistence;
using Bazdid.Api.Fixtures;
using Xunit;

namespace Bazdid.UnitTests
{
    // این‌ها آزمون orchestration با double هستند؛ شاهد transaction واقعی SQL نیستند.
    public class LinkageTransactionTests
    {
        private static BrokerageRequestSnapshot Snapshot()
        {
            var fixture=SyntheticBrokerageFixtures.Create().First();
            return new BrokerageRequestSnapshot(new BrokerageRequestReference(fixture.Scope,fixture.RequestId),fixture.CustomerId,
                new TrustedMobileReference(fixture.CustomerMobile,"synthetic-test"),fixture.Eligibility,fixture.Vehicle,"TEST-V1",DateTimeOffset.UtcNow);
        }
        [Theory]
        [InlineData("customer")] [InlineData("request")] [InlineData("audit")] [InlineData("commit")]
        public async Task Partial_failure_disposes_one_transaction_without_automatic_retry(string failAt)
        {
            var doubleStore=new DoubleStore {FailAt=failAt};
            var service=new LinkagePersistenceService(doubleStore,doubleStore,doubleStore,doubleStore);
            await Assert.ThrowsAsync<PersistenceException>(()=>service.PersistAsync(Snapshot(),new string('a',32),CancellationToken.None));
            Assert.Equal(1,doubleStore.BeginCount); Assert.True(doubleStore.Disposed); Assert.False(doubleStore.Committed);
            Assert.Equal(failAt=="commit"?1:0,doubleStore.CommitAttempts);
        }
        [Theory]
        [InlineData(true,1)] [InlineData(false,0)]
        public async Task New_linkage_audits_once_and_equivalent_replay_does_not_audit_again(bool created,int auditCount)
        {
            var store=new DoubleStore {Created=created};
            var service=new LinkagePersistenceService(store,store,store,store);
            var result=await service.PersistAsync(Snapshot(),new string('a',32),CancellationToken.None);
            Assert.Equal(created,result.Created); Assert.Equal(auditCount,store.AuditCount);
            Assert.True(store.Committed); Assert.True(store.Disposed); Assert.Equal(1,store.CommitAttempts);
            Assert.Null(store.Metadata.Referral); Assert.Null(store.Metadata.Identity); Assert.Null(store.Metadata.PreviousIdentity);
        }
        private sealed class DoubleStore : IBazdidTransactionFactory,IBazdidTransaction,ICustomerLinkRepository,IRequestContextRepository,IAuditRepository
        {
            public string FailAt; public bool Created=true; public int BeginCount,AuditCount,CommitAttempts; public bool Disposed,Committed; public RequestMetadata Metadata;
            public Task<IBazdidTransaction> BeginAsync(CancellationToken ct) { ct.ThrowIfCancellationRequested();BeginCount++;return Task.FromResult<IBazdidTransaction>(this); }
            private void Fail(string stage) { if(FailAt==stage) throw new PersistenceException(stage=="commit"?PersistenceFailure.CommitOutcomeUnknown:PersistenceFailure.Unavailable); }
            public void Commit(CancellationToken ct) { ct.ThrowIfCancellationRequested();CommitAttempts++;Fail("commit");Committed=true; }
            public void Rollback() { }
            public void Dispose() { Disposed=true; }
            public Task<GetOrCreateResult<CustomerLinkRecord>> GetOrCreateAsync(IBazdidTransaction tx,BrokerageScope scope,string id,CancellationToken ct)
            { Assert.Same(this,tx);Fail("customer");return Task.FromResult(new GetOrCreateResult<CustomerLinkRecord>(new CustomerLinkRecord(Guid.NewGuid(),scope,id,DateTimeOffset.UtcNow,DateTimeOffset.UtcNow,new RowVersionToken(new byte[8])),Created)); }
            public Task<GetOrCreateResult<RequestContextRecord>> GetOrCreateAsync(IBazdidTransaction tx,BrokerageRequestReference reference,CustomerLinkRecord customer,RequestMetadata metadata,CancellationToken ct)
            { Assert.Same(this,tx);Fail("request");Metadata=metadata;return Task.FromResult(new GetOrCreateResult<RequestContextRecord>(new RequestContextRecord(Guid.NewGuid(),reference,customer.Id,metadata,new RowVersionToken(new byte[8])),Created)); }
            public Task AppendAsync(IBazdidTransaction tx,ContextAuditEvent audit,CancellationToken ct) { Assert.Same(this,tx);Fail("audit");AuditCount++;return Task.CompletedTask; }
            public Task<CustomerLinkRecord> FindAsync(IBazdidTransaction tx,BrokerageScope scope,string id,CancellationToken ct) => throw new NotSupportedException();
            public Task<RequestContextRecord> FindAsync(IBazdidTransaction tx,BrokerageRequestReference reference,CancellationToken ct) => throw new NotSupportedException();
            public Task<RequestContextRecord> UpdateMetadataAsync(IBazdidTransaction tx,Guid id,BrokerageRequestReference reference,CustomerLinkRecord customer,RowVersionToken version,RequestMetadata metadata,CancellationToken ct) => throw new NotSupportedException();
        }
    }
}
