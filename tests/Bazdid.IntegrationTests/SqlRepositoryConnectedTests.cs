using System;
using System.Data.SqlClient;
using System.Threading;
using System.Threading.Tasks;
using Bazdid.Api.Domain.Brokerage;
using Bazdid.Api.Domain.Persistence;
using Bazdid.Api.Infrastructure.Sql;
using Xunit;

namespace Bazdid.IntegrationTests
{
    // این تست‌ها SQL واقعی‌اند و در این نسخه به‌صراحت غیرفعال می‌مانند؛ هیچ راه عبور تنظیماتی از gate ندارند.
    public class SqlRepositoryConnectedTests
    {
        private static SqlRuntimeOptions Options()
        {
            var options=new SqlRuntimeOptions {
                Enabled=true, ConnectionString=Environment.GetEnvironmentVariable("BAZDID_TEST_SQL_CONNECTION")??"",
                ApprovedWriterPrincipal=Environment.GetEnvironmentVariable("BAZDID_TEST_WRITER_PRINCIPAL")??""
            };
            options.Validate("Testing");
            return options;
        }
        private static BrokerageScope Scope() => new BrokerageScope("TEST-BROKERAGE","T_"+Guid.NewGuid().ToString("N").Substring(0,30));
        private static RequestMetadata Metadata(string version="TEST-V1") => new RequestMetadata(RequestEligibility.Eligible,version,DateTimeOffset.UtcNow);
        private static SqlTransactionFactory Transactions(SqlRuntimeOptions options) => new SqlTransactionFactory(new BazdidWriteConnectionFactory(options));

        [Fact(Skip=SqlRuntimeGate.BlockReason)]
        public async Task Exact_keys_idempotence_multiple_requests_and_tenant_isolation()
        {
            var options=Options(); var customers=new SqlCustomerLinkRepository(options); var requests=new SqlRequestContextRepository(options); var scope=Scope();
            using (var tx=await Transactions(options).BeginAsync(CancellationToken.None))
            {
                var customer=await customers.GetOrCreateAsync(tx,scope,"TEST-CUSTOMER-001",CancellationToken.None);
                Assert.True(customer.Created);
                Assert.False((await customers.GetOrCreateAsync(tx,scope,"TEST-CUSTOMER-001",CancellationToken.None)).Created);
                var ids=new[]{"9223372036854775807","9007199254740993","Case","case","کیس","کیس ","e\u0301","é"};
                foreach (var id in ids)
                {
                    var reference=new BrokerageRequestReference(scope,id);
                    var first=await requests.GetOrCreateAsync(tx,reference,customer.Record,Metadata(),CancellationToken.None);
                    var again=await requests.GetOrCreateAsync(tx,reference,customer.Record,Metadata(),CancellationToken.None);
                    Assert.True(first.Created); Assert.False(again.Created); Assert.Equal(first.Record.Id,again.Record.Id);
                    Assert.Equal(id,again.Record.Reference.SourceRequestId);
                }
                var other=await customers.GetOrCreateAsync(tx,Scope(),"TEST-CUSTOMER-001",CancellationToken.None);
                Assert.NotEqual(customer.Record.Id,other.Record.Id);
                tx.Rollback();
            }
        }
        [Fact(Skip=SqlRuntimeGate.BlockReason)]
        public async Task Existing_request_cannot_be_relinked_to_another_customer()
        {
            var options=Options(); var customers=new SqlCustomerLinkRepository(options); var requests=new SqlRequestContextRepository(options); var scope=Scope();
            using (var tx=await Transactions(options).BeginAsync(CancellationToken.None))
            {
                var first=await customers.GetOrCreateAsync(tx,scope,"TEST-CUSTOMER-001",CancellationToken.None);
                var other=await customers.GetOrCreateAsync(tx,scope,"TEST-CUSTOMER-002",CancellationToken.None);
                var reference=new BrokerageRequestReference(scope,"TEST-REQUEST-001");
                await requests.GetOrCreateAsync(tx,reference,first.Record,Metadata(),CancellationToken.None);
                var error=await Assert.ThrowsAsync<PersistenceException>(()=>requests.GetOrCreateAsync(tx,reference,other.Record,Metadata(),CancellationToken.None));
                Assert.Equal(PersistenceFailure.OwnershipConflict,error.Failure);
            }
        }
        [Fact(Skip=SqlRuntimeGate.BlockReason)]
        public async Task Stale_rowversion_cannot_overwrite_metadata()
        {
            var options=Options(); var customers=new SqlCustomerLinkRepository(options); var requests=new SqlRequestContextRepository(options); var scope=Scope();
            using (var tx=await Transactions(options).BeginAsync(CancellationToken.None))
            {
                var customer=await customers.GetOrCreateAsync(tx,scope,"TEST-CUSTOMER-001",CancellationToken.None);
                var reference=new BrokerageRequestReference(scope,"TEST-REQUEST-001");
                var original=(await requests.GetOrCreateAsync(tx,reference,customer.Record,Metadata(),CancellationToken.None)).Record;
                var updated=await requests.UpdateMetadataAsync(tx,original.Id,reference,customer.Record,original.Version,Metadata("TEST-V2"),CancellationToken.None);
                Assert.NotEqual(original.Version.ToArray(),updated.Version.ToArray());
                var error=await Assert.ThrowsAsync<PersistenceException>(()=>requests.UpdateMetadataAsync(tx,original.Id,reference,customer.Record,original.Version,Metadata("TEST-V3"),CancellationToken.None));
                Assert.Equal(PersistenceFailure.ConcurrencyConflict,error.Failure);
            }
        }
        [Fact(Skip=SqlRuntimeGate.BlockReason)]
        public async Task Customer_request_and_audit_insert_are_rolled_back_together()
        {
            var options=Options(); var customers=new SqlCustomerLinkRepository(options); var requests=new SqlRequestContextRepository(options); var audit=new SqlAuditRepository(options); var scope=Scope();
            var reference=new BrokerageRequestReference(scope,"TEST-REQUEST-001");
            using (var tx=await Transactions(options).BeginAsync(CancellationToken.None))
            {
                var customer=await customers.GetOrCreateAsync(tx,scope,"TEST-CUSTOMER-001",CancellationToken.None);
                var request=await requests.GetOrCreateAsync(tx,reference,customer.Record,Metadata(),CancellationToken.None);
                await audit.AppendAsync(tx,new ContextAuditEvent(scope,request.Record.Id,AuditAction.LinkageCreated,Guid.NewGuid().ToString("N")),CancellationToken.None);
                tx.Rollback();
            }
            using (var tx=await Transactions(options).BeginAsync(CancellationToken.None))
            {
                Assert.Null(await customers.FindAsync(tx,scope,"TEST-CUSTOMER-001",CancellationToken.None));
                Assert.Null(await requests.FindAsync(tx,reference,CancellationToken.None));
                // تعداد audit پیش/پس باید جداگانه با verifier مجاز خوانده شود؛ Writer مجوز SELECT audit ندارد.
            }
        }
        [Fact(Skip=SqlRuntimeGate.BlockReason)]
        public async Task Concurrent_creation_waits_for_key_lock_and_leaves_no_committed_record()
        {
            var options=Options(); var customers=new SqlCustomerLinkRepository(options); var scope=Scope();
            using (var first=await Transactions(options).BeginAsync(CancellationToken.None))
            using (var second=await Transactions(options).BeginAsync(CancellationToken.None))
            using (var deadline=new CancellationTokenSource(TimeSpan.FromSeconds(15)))
            {
                await customers.GetOrCreateAsync(first,scope,"TEST-CUSTOMER-001",deadline.Token);
                var waiting=customers.GetOrCreateAsync(second,scope,"TEST-CUSTOMER-001",deadline.Token);
                await Task.Delay(100,deadline.Token);
                first.Rollback();
                var result=await waiting;
                Assert.True(result.Created); second.Rollback();
            }
        }
        [Fact(Skip=SqlRuntimeGate.BlockReason)]
        public async Task Actual_writer_cannot_read_audit_or_delete_contexts_or_issue_DDL()
        {
            var options=Options();
            using (var connection=await new BazdidWriteConnectionFactory(options).OpenAsync(CancellationToken.None))
            using (var command=connection.CreateCommand())
            {
                command.CommandTimeout=options.CommandTimeoutSeconds;
                command.CommandText="SELECT IS_SRVROLEMEMBER('sysadmin'),IS_MEMBER('db_owner'),HAS_PERMS_BY_NAME(N'dbo.BAZDIDRequestContexts',N'OBJECT',N'DELETE'),HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE TABLE');";
                using (var reader=await command.ExecuteReaderAsync()) { Assert.True(await reader.ReadAsync()); for(var i=0;i<4;i++) Assert.Equal(0,reader.GetInt32(i)); }
                command.CommandText="SELECT TOP (0) Id FROM dbo.BAZDIDAuditLogs;";
                var error=await Assert.ThrowsAsync<SqlException>(()=>command.ExecuteScalarAsync());
                Assert.Equal(229,error.Number);
            }
        }
        [Fact(Skip=SqlRuntimeGate.BlockReason)]
        public async Task Actual_SQL_timeout_is_not_not_found_or_duplicate()
        {
            var options=Options();
            using (var connection=await new BazdidWriteConnectionFactory(options).OpenAsync(CancellationToken.None))
            using (var command=connection.CreateCommand())
            {
                command.CommandTimeout=1; command.CommandText="WAITFOR DELAY '00:00:03'; SELECT 1;";
                var error=await Assert.ThrowsAsync<SqlException>(()=>command.ExecuteScalarAsync(CancellationToken.None));
                Assert.Equal(PersistenceFailure.Timeout,SqlErrors.Map(error.Number).Failure);
            }
        }
        [Fact(Skip=SqlRuntimeGate.BlockReason)]
        public async Task Actual_SQL_command_observes_cancellation()
        {
            var options=Options();
            using (var connection=await new BazdidWriteConnectionFactory(options).OpenAsync(CancellationToken.None))
            using (var command=connection.CreateCommand())
            using (var cancellation=new CancellationTokenSource(TimeSpan.FromMilliseconds(200)))
            {
                command.CommandTimeout=10; command.CommandText="WAITFOR DELAY '00:00:05'; SELECT 1;";
                await Assert.ThrowsAnyAsync<OperationCanceledException>(()=>command.ExecuteScalarAsync(cancellation.Token));
            }
        }
    }
}
