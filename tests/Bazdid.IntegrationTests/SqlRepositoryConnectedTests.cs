using System;
using System.Data.SqlClient;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using Bazdid.Api.Domain.Brokerage;
using Bazdid.Api.Domain.Persistence;
using Bazdid.Api.Infrastructure.Sql;
using Xunit;

namespace Bazdid.IntegrationTests
{
    /// <summary>
    /// آزمون SQL متصل فقط با انتخاب صریح (BAZDID_CONNECTED_SQL=1). در اجرای پیش‌فرض Skip می‌شود؛
    /// اگر انتخاب شده ولی هویت/محیط/RunId برقرار نباشد، آزمون شکست می‌خورد، نه Skip.
    /// </summary>
    public sealed class ConnectedSqlFactAttribute : FactAttribute
    {
        public ConnectedSqlFactAttribute()
        {
            if (!ConnectedTestAcceptance.Selected)
                Skip="SQL متصل انتخاب نشده است؛ فقط با BAZDID_CONNECTED_SQL=1 و token واقعی BAZDIDDevWriter اجرا می‌شود.";
        }
    }

    /// <summary>
    /// دامنهٔ داده‌های ساختگی هر اجرا: BrokerageId ثابت و SourceSystem = "R" + RunId + "_" + برچسب آزمون.
    /// verifier/cleanup مستقل فقط همین الگو را می‌خواند و حذف می‌کند (deployment/development/Invoke-BazdidConnectedRunVerifier.review.ps1).
    /// </summary>
    internal static class ConnectedRun
    {
        internal const string Brokerage = "TEST-BROKERAGE";
        internal static string Id
        {
            get
            {
                var id=Environment.GetEnvironmentVariable("BAZDID_TEST_RUN_ID") ?? "";
                if (!Regex.IsMatch(id,"^[0-9a-f]{16}$")) throw new InvalidOperationException("BAZDID_TEST_RUN_ID معتبر (۱۶ hex) لازم است.");
                return id;
            }
        }
        internal static BrokerageScope Scope(string tag)
        {
            if (!Regex.IsMatch(tag,"^[A-Z0-9]{1,8}$")) throw new ArgumentException("برچسب نامعتبر است.",nameof(tag));
            return new BrokerageScope(Brokerage,"R"+Id+"_"+tag);
        }
    }

    public class SqlRepositoryConnectedTests
    {
        private static SqlRuntimeOptions Options()
        {
            // مقصد ثابت D-P3-NAME؛ flag زمان اجرا بسته می‌ماند و فقط نشانهٔ آزمون internal کارخانه را باز می‌کند.
            return new SqlRuntimeOptions {
                Enabled=false,
                ConnectionString="Data Source="+SqlRuntimeOptions.ApprovedLocalDataSource+";Initial Catalog="+SqlRuntimeOptions.ApprovedDatabase+
                    ";Integrated Security=true;Encrypt=true;TrustServerCertificate=false",
                ApprovedWriterPrincipal=ConnectedTestAcceptance.ExpectedPrincipal
            };
        }
        private static BazdidWriteConnectionFactory Connections(SqlRuntimeOptions options) =>
            new BazdidWriteConnectionFactory(options,ConnectedTestAcceptance.Create("Testing",options));
        private static RequestMetadata Metadata(string version="TEST-V1") => new RequestMetadata(RequestEligibility.Eligible,version,DateTimeOffset.UtcNow);
        private static SqlTransactionFactory Transactions(SqlRuntimeOptions options) => new SqlTransactionFactory(Connections(options));

        // ---------- موارد rollback (هیچ ردیف پایدار؛ verifier صفر بودن را برای برچسب‌ها تأیید می‌کند) ----------

        [ConnectedSqlFact]
        public async Task Exact_keys_idempotence_multiple_requests_and_tenant_isolation()
        {
            var options=Options(); var customers=new SqlCustomerLinkRepository(options); var requests=new SqlRequestContextRepository(options); var scope=ConnectedRun.Scope("KEYS");
            using (var tx=await Transactions(options).BeginAsync(CancellationToken.None))
            {
                var customer=await customers.GetOrCreateAsync(tx,scope,"TEST-CUSTOMER-001",CancellationToken.None);
                Assert.True(customer.Created);
                Assert.False((await customers.GetOrCreateAsync(tx,scope,"TEST-CUSTOMER-001",CancellationToken.None)).Created);
                var ids=new[]{"9223372036854775807","9007199254740993","Case","case","کیس","کیس ","é","é"};
                foreach (var id in ids)
                {
                    var reference=new BrokerageRequestReference(scope,id);
                    var first=await requests.GetOrCreateAsync(tx,reference,customer.Record,Metadata(),CancellationToken.None);
                    var again=await requests.GetOrCreateAsync(tx,reference,customer.Record,Metadata(),CancellationToken.None);
                    Assert.True(first.Created); Assert.False(again.Created); Assert.Equal(first.Record.Id,again.Record.Id);
                    Assert.Equal(id,again.Record.Reference.SourceRequestId);
                }
                var other=await customers.GetOrCreateAsync(tx,ConnectedRun.Scope("KEYS2"),"TEST-CUSTOMER-001",CancellationToken.None);
                Assert.NotEqual(customer.Record.Id,other.Record.Id);
                tx.Rollback();
            }
        }
        [ConnectedSqlFact]
        public async Task Existing_request_cannot_be_relinked_to_another_customer()
        {
            var options=Options(); var customers=new SqlCustomerLinkRepository(options); var requests=new SqlRequestContextRepository(options); var scope=ConnectedRun.Scope("RELINK");
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
        [ConnectedSqlFact]
        public async Task Stale_rowversion_cannot_overwrite_metadata()
        {
            var options=Options(); var customers=new SqlCustomerLinkRepository(options); var requests=new SqlRequestContextRepository(options); var scope=ConnectedRun.Scope("STALE");
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
        [ConnectedSqlFact]
        public async Task Customer_request_and_audit_insert_are_rolled_back_together()
        {
            var options=Options(); var customers=new SqlCustomerLinkRepository(options); var requests=new SqlRequestContextRepository(options); var audit=new SqlAuditRepository(options); var scope=ConnectedRun.Scope("RBACK");
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
                // Writer مجوز SELECT audit ندارد؛ صفر بودن audit برچسب RBACK را verifier مستقل DBA تأیید می‌کند.
            }
        }
        [ConnectedSqlFact]
        public async Task Concurrent_creation_waits_for_key_lock_and_leaves_no_committed_record()
        {
            var options=Options(); var customers=new SqlCustomerLinkRepository(options); var scope=ConnectedRun.Scope("LOCK");
            using (var first=await Transactions(options).BeginAsync(CancellationToken.None))
            using (var second=await Transactions(options).BeginAsync(CancellationToken.None))
            using (var deadline=new CancellationTokenSource(TimeSpan.FromSeconds(15)))
            {
                await customers.GetOrCreateAsync(first,scope,"TEST-CUSTOMER-001",deadline.Token);
                var waiting=customers.GetOrCreateAsync(second,scope,"TEST-CUSTOMER-001",deadline.Token);
                await Task.Delay(300,deadline.Token);
                Assert.False(waiting.IsCompleted);
                first.Rollback();
                var result=await waiting;
                Assert.True(result.Created); second.Rollback();
            }
        }
        [ConnectedSqlFact]
        public async Task Audit_for_context_of_another_tenant_is_rejected()
        {
            var options=Options(); var customers=new SqlCustomerLinkRepository(options); var requests=new SqlRequestContextRepository(options); var audit=new SqlAuditRepository(options);
            var owner=ConnectedRun.Scope("AUDX"); var foreign=ConnectedRun.Scope("AUDY");
            using (var tx=await Transactions(options).BeginAsync(CancellationToken.None))
            {
                var customer=await customers.GetOrCreateAsync(tx,owner,"TEST-CUSTOMER-001",CancellationToken.None);
                var request=await requests.GetOrCreateAsync(tx,new BrokerageRequestReference(owner,"TEST-REQUEST-001"),customer.Record,Metadata(),CancellationToken.None);
                var error=await Assert.ThrowsAsync<PersistenceException>(()=>audit.AppendAsync(tx,
                    new ContextAuditEvent(foreign,request.Record.Id,AuditAction.LinkageCreated,Guid.NewGuid().ToString("N")),CancellationToken.None));
                Assert.Equal(PersistenceFailure.OwnershipConflict,error.Failure);
            }
        }

        // ---------- مجوز مؤثر واقعی Writer ----------

        [ConnectedSqlFact]
        public async Task Actual_writer_cannot_read_audit_or_delete_contexts_or_issue_DDL()
        {
            var options=Options();
            using (var connection=await Connections(options).OpenAsync(CancellationToken.None))
            using (var command=connection.CreateCommand())
            {
                command.CommandTimeout=options.CommandTimeoutSeconds;
                command.CommandText="SELECT IS_SRVROLEMEMBER('sysadmin'),IS_MEMBER('db_owner'),HAS_PERMS_BY_NAME(N'dbo.BAZDIDRequestContexts',N'OBJECT',N'DELETE'),HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE TABLE'),ORIGINAL_LOGIN();";
                using (var reader=await command.ExecuteReaderAsync())
                {
                    Assert.True(await reader.ReadAsync());
                    for(var i=0;i<4;i++) Assert.Equal(0,reader.GetInt32(i));
                    Assert.Equal(ConnectedTestAcceptance.ExpectedPrincipal,reader.GetString(4),StringComparer.OrdinalIgnoreCase);
                }
                foreach (var denied in new[]{
                    "SELECT TOP (0) Id FROM dbo.BAZDIDAuditLogs;",
                    "DELETE FROM dbo.BAZDIDRequestContexts WHERE 1=0;",
                    "DELETE FROM dbo.BAZDIDCustomerLinks WHERE 1=0;",
                    "UPDATE dbo.BAZDIDCustomerLinks SET UpdatedAtUtc=UpdatedAtUtc WHERE 1=0;",
                    "UPDATE dbo.BAZDIDAuditLogs SET MetadataCode=NULL WHERE 1=0;",
                    "DELETE FROM dbo.BAZDIDAuditLogs WHERE 1=0;"})
                {
                    command.CommandText=denied;
                    var error=await Assert.ThrowsAsync<SqlException>(()=>command.ExecuteNonQueryAsync());
                    Assert.Equal(229,error.Number);
                }
                command.CommandText="CREATE TABLE dbo.BAZDIDForbidden (Id int);";
                var ddl=await Assert.ThrowsAsync<SqlException>(()=>command.ExecuteNonQueryAsync());
                Assert.Contains(ddl.Number,new[]{262,2760,229});
            }
        }
        [ConnectedSqlFact]
        public async Task Actual_SQL_timeout_is_not_not_found_or_duplicate()
        {
            var options=Options();
            using (var connection=await Connections(options).OpenAsync(CancellationToken.None))
            using (var command=connection.CreateCommand())
            {
                command.CommandTimeout=1; command.CommandText="WAITFOR DELAY '00:00:03'; SELECT 1;";
                var error=await Assert.ThrowsAsync<SqlException>(()=>command.ExecuteScalarAsync(CancellationToken.None));
                Assert.Equal(PersistenceFailure.Timeout,SqlErrors.Map(error.Number).Failure);
            }
        }
        [ConnectedSqlFact]
        public async Task Actual_SQL_command_observes_cancellation()
        {
            var options=Options();
            using (var connection=await Connections(options).OpenAsync(CancellationToken.None))
            using (var command=connection.CreateCommand())
            using (var cancellation=new CancellationTokenSource(TimeSpan.FromMilliseconds(200)))
            {
                command.CommandTimeout=10; command.CommandText="WAITFOR DELAY '00:00:05'; SELECT 1;";
                await Assert.ThrowsAnyAsync<OperationCanceledException>(()=>command.ExecuteScalarAsync(cancellation.Token));
            }
        }

        // ---------- P5: fixtureهای commitشده با RunId (verifier تعداد دقیق را می‌شمارد و cleanup محدود انجام می‌دهد) ----------

        [ConnectedSqlFact]
        public async Task Committed_linkage_is_idempotent_across_transactions()
        {
            var options=Options(); var customers=new SqlCustomerLinkRepository(options); var requests=new SqlRequestContextRepository(options); var audit=new SqlAuditRepository(options);
            var scope=ConnectedRun.Scope("CIDEM"); var reference=new BrokerageRequestReference(scope,"TEST-REQUEST-001");
            Guid customerId, requestId;
            using (var tx=await Transactions(options).BeginAsync(CancellationToken.None))
            {
                var customer=await customers.GetOrCreateAsync(tx,scope,"TEST-CUSTOMER-001",CancellationToken.None);
                var request=await requests.GetOrCreateAsync(tx,reference,customer.Record,Metadata(),CancellationToken.None);
                await audit.AppendAsync(tx,new ContextAuditEvent(scope,request.Record.Id,AuditAction.LinkageCreated,Guid.NewGuid().ToString("N")),CancellationToken.None);
                Assert.True(customer.Created); Assert.True(request.Created);
                customerId=customer.Record.Id; requestId=request.Record.Id;
                tx.Commit(CancellationToken.None);
            }
            using (var tx=await Transactions(options).BeginAsync(CancellationToken.None))
            {
                var customer=await customers.GetOrCreateAsync(tx,scope,"TEST-CUSTOMER-001",CancellationToken.None);
                var request=await requests.GetOrCreateAsync(tx,reference,customer.Record,Metadata(),CancellationToken.None);
                Assert.False(customer.Created); Assert.False(request.Created);
                Assert.Equal(customerId,customer.Record.Id); Assert.Equal(requestId,request.Record.Id);
                tx.Commit(CancellationToken.None);
            }
        }
        [ConnectedSqlFact]
        public async Task Concurrent_committed_creation_yields_exactly_one_record()
        {
            var options=Options(); var customers=new SqlCustomerLinkRepository(options); var scope=ConnectedRun.Scope("CCONC");
            async Task<GetOrCreateResult<CustomerLinkRecord>> Create()
            {
                using (var tx=await Transactions(options).BeginAsync(CancellationToken.None))
                {
                    var result=await customers.GetOrCreateAsync(tx,scope,"TEST-CUSTOMER-001",CancellationToken.None);
                    await Task.Delay(100);
                    tx.Commit(CancellationToken.None);
                    return result;
                }
            }
            var results=await Task.WhenAll(Enumerable.Range(0,4).Select(_=>Task.Run(Create)));
            Assert.Equal(1,results.Count(r=>r.Created));
            Assert.Single(results.Select(r=>r.Record.Id).Distinct());
        }
        [ConnectedSqlFact]
        public async Task Committed_tenants_are_isolated()
        {
            var options=Options(); var customers=new SqlCustomerLinkRepository(options);
            var a=ConnectedRun.Scope("CTENA"); var b=ConnectedRun.Scope("CTENB");
            using (var tx=await Transactions(options).BeginAsync(CancellationToken.None))
            {
                var first=await customers.GetOrCreateAsync(tx,a,"TEST-CUSTOMER-001",CancellationToken.None);
                var second=await customers.GetOrCreateAsync(tx,b,"TEST-CUSTOMER-001",CancellationToken.None);
                Assert.True(first.Created); Assert.True(second.Created); Assert.NotEqual(first.Record.Id,second.Record.Id);
                tx.Commit(CancellationToken.None);
            }
            using (var tx=await Transactions(options).BeginAsync(CancellationToken.None))
            {
                Assert.Equal(a,(await customers.FindAsync(tx,a,"TEST-CUSTOMER-001",CancellationToken.None)).Scope);
                Assert.Null(await customers.FindAsync(tx,ConnectedRun.Scope("CTENC"),"TEST-CUSTOMER-001",CancellationToken.None));
            }
        }
        [ConnectedSqlFact]
        public async Task Committed_stale_rowversion_is_rejected_in_a_new_transaction()
        {
            var options=Options(); var customers=new SqlCustomerLinkRepository(options); var requests=new SqlRequestContextRepository(options);
            var scope=ConnectedRun.Scope("CSTALE"); var reference=new BrokerageRequestReference(scope,"TEST-REQUEST-001");
            CustomerLinkRecord customer; RequestContextRecord original;
            using (var tx=await Transactions(options).BeginAsync(CancellationToken.None))
            {
                customer=(await customers.GetOrCreateAsync(tx,scope,"TEST-CUSTOMER-001",CancellationToken.None)).Record;
                original=(await requests.GetOrCreateAsync(tx,reference,customer,Metadata(),CancellationToken.None)).Record;
                tx.Commit(CancellationToken.None);
            }
            using (var tx=await Transactions(options).BeginAsync(CancellationToken.None))
            {
                await requests.UpdateMetadataAsync(tx,original.Id,reference,customer,original.Version,Metadata("TEST-V2"),CancellationToken.None);
                tx.Commit(CancellationToken.None);
            }
            using (var tx=await Transactions(options).BeginAsync(CancellationToken.None))
            {
                var error=await Assert.ThrowsAsync<PersistenceException>(()=>requests.UpdateMetadataAsync(tx,original.Id,reference,customer,original.Version,Metadata("TEST-V3"),CancellationToken.None));
                Assert.Equal(PersistenceFailure.ConcurrencyConflict,error.Failure);
                Assert.Equal("TEST-V2",(await requests.FindAsync(tx,reference,CancellationToken.None)).Metadata.SourceVersion);
            }
        }
    }
}
