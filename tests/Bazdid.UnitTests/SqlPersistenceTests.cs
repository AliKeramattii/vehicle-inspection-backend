using System;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Threading;
using System.Threading.Tasks;
using Bazdid.Api.Domain.Brokerage;
using Bazdid.Api.Domain.Persistence;
using Bazdid.Api.Infrastructure.Sql;
using Newtonsoft.Json;
using Xunit;
using Xunit.Abstractions;

namespace Bazdid.UnitTests
{
    public class SqlPersistenceTests
    {
        private readonly ITestOutputHelper _output;
        public SqlPersistenceTests(ITestOutputHelper output) { _output=output; }
        private static readonly BrokerageScope Scope=new BrokerageScope("TEST-BROKERAGE","SYNTHETIC");
        private static CustomerLinkRecord Customer(BrokerageScope scope=null) => new CustomerLinkRecord(Guid.NewGuid(),scope??Scope,"TEST-CUSTOMER-001",DateTimeOffset.UtcNow,DateTimeOffset.UtcNow,new RowVersionToken(new byte[8]));
        private static RequestMetadata Metadata() => new RequestMetadata(RequestEligibility.Eligible,null,DateTimeOffset.UtcNow);

        [Theory]
        [InlineData("9223372036854775807")]
        [InlineData("9007199254740993")]
        [InlineData("Case")]
        [InlineData("case")]
        [InlineData("شناسه😀")]
        [InlineData("TEST-REQUEST-001 ")]
        [InlineData("x'; DROP TABLE dbo.BAZDIDCustomerLinks;--")]
        public void Opaque_keys_are_bound_exactly_and_never_interpolated(string id)
        {
            using (var command=SqlCommands.Customer(Scope,id,true))
            {
                var parameter=command.Parameters["@CustomerId"];
                Assert.Equal(id,parameter.Value);
                Assert.Equal(SqlDbType.NVarChar,parameter.SqlDbType); Assert.Equal(128,parameter.Size); Assert.False(parameter.IsNullable);
                Assert.Equal(PersistenceInput.SourceKey(id),(byte[])command.Parameters["@CustomerKey"].Value);
                Assert.Equal(SqlDbType.VarBinary,command.Parameters["@CustomerKey"].SqlDbType); Assert.Equal(256,command.Parameters["@CustomerKey"].Size);
                Assert.DoesNotContain(id,command.CommandText);
                Assert.Contains("SourceCustomerIdKey=@CustomerKey",command.CommandText);
            }
            using (var command=SqlCommands.CreateContext(new BrokerageRequestReference(Scope,id),Customer(),Metadata()))
            {
                Assert.Equal(id,command.Parameters["@RequestId"].Value);
                Assert.Equal(PersistenceInput.SourceKey(id),(byte[])command.Parameters["@RequestKey"].Value);
                Assert.Contains("UPDLOCK,HOLDLOCK",command.CommandText);
            }
        }
        [Fact]
        public void Binary_keys_distinguish_case_trailing_space_and_unicode_normalization()
        {
            Assert.NotEqual(PersistenceInput.SourceKey("ID"),PersistenceInput.SourceKey("id"));
            Assert.NotEqual(PersistenceInput.SourceKey("id"),PersistenceInput.SourceKey("id "));
            Assert.NotEqual(PersistenceInput.SourceKey("é"),PersistenceInput.SourceKey("e\u0301"));
            Assert.Equal(256,PersistenceInput.SourceKey(new string('x',128)).Length);
        }
        [Theory]
        [InlineData(null)] [InlineData("")] [InlineData(" ")]
        public void Missing_identity_is_rejected_before_SQL(string id) => Assert.Throws<ArgumentException>(()=>PersistenceInput.SourceKey(id));
        [Fact]
        public void Invalid_utf16_and_oversized_identity_are_rejected_without_echo()
        {
            Assert.Throws<ArgumentException>(()=>PersistenceInput.SourceKey("\ud800"));
            Assert.Throws<ArgumentException>(()=>PersistenceInput.SourceKey(new string('x',129)));
        }
        [Fact]
        public void Scope_and_owner_are_enforced_in_create_and_compare_and_swap()
        {
            var request=new BrokerageRequestReference(Scope,"TEST-REQUEST-001");
            var customer=Customer();
            using (var command=SqlCommands.UpdateContext(Guid.NewGuid(),request,customer,new RowVersionToken(new byte[8]),Metadata()))
            {
                Assert.Contains("Id=@Id AND BrokerageId=@Brokerage AND SourceSystem=@Source AND SourceRequestIdKey=@RequestKey AND CustomerLinkId=@CustomerLinkId AND RowVersion=@ExpectedVersion",command.CommandText);
                Assert.Contains("SourceCustomerIdKey=@CustomerKey",command.CommandText);
                Assert.Equal(8,command.Parameters["@ExpectedVersion"].Size);
            }
            var wrong=Customer(new BrokerageScope("OTHER","SYNTHETIC"));
            Assert.Equal(PersistenceFailure.OwnershipConflict,Assert.Throws<PersistenceException>(()=>SqlCommands.CreateContext(request,wrong,Metadata())).Failure);
        }
        [Fact]
        public void Nullable_metadata_has_explicit_types_and_HMAC_is_paired()
        {
            using (var command=SqlCommands.CreateContext(new BrokerageRequestReference(Scope,"TEST-REQUEST-001"),Customer(),Metadata()))
            {
                Assert.Equal(DBNull.Value,command.Parameters["@SourceVersion"].Value);
                Assert.True(command.Parameters["@SourceVersion"].IsNullable);
                Assert.Equal(SqlDbType.NVarChar,command.Parameters["@SourceVersion"].SqlDbType);
                Assert.Equal(128,command.Parameters["@SourceVersion"].Size);
                Assert.Equal(DBNull.Value,command.Parameters["@ReferralHmac"].Value);
                Assert.Equal(SqlDbType.Binary,command.Parameters["@ReferralHmac"].SqlDbType);
                Assert.Equal(32,command.Parameters["@ReferralHmac"].Size);
                Assert.Equal(SqlDbType.VarChar,command.Parameters["@ReferralKey"].SqlDbType);
                Assert.Equal((byte)3,command.Parameters["@Retrieved"].Scale);
            }
        }
        [Fact]
        public void Version_and_digest_are_defensive_and_reject_invalid_lengths()
        {
            var versionBytes=new byte[8]; var version=new RowVersionToken(versionBytes); versionBytes[0]=1; version.ToArray()[1]=2;
            Assert.Equal(new byte[8],version.ToArray());
            var digest=new byte[32]; var hmac=new HmacReference(digest,"TEST-KEY-1"); digest[0]=1; hmac.ToArray()[1]=2;
            Assert.Equal(new byte[32],hmac.ToArray());
            Assert.Throws<ArgumentException>(()=>new RowVersionToken(new byte[7]));
            Assert.Throws<ArgumentException>(()=>new HmacReference(new byte[31],"TEST"));
            Assert.Throws<ArgumentException>(()=>new HmacReference(new byte[32],"bad key"));
        }
        [Fact]
        public void Audit_command_only_inserts_structured_codes_without_returning_audit_rows()
        {
            using (var command=SqlCommands.Audit(new ContextAuditEvent(Scope,Guid.NewGuid(),AuditAction.LinkageCreated,new string('a',32))))
            {
                Assert.Contains("INSERT dbo.BAZDIDAuditLogs",command.CommandText);
                Assert.DoesNotContain("FROM dbo.BAZDIDAuditLogs",command.CommandText);
                Assert.DoesNotContain("OUTPUT",command.CommandText);
                Assert.DoesNotContain("UPDATE dbo.BAZDIDAuditLogs",command.CommandText);
                Assert.DoesNotContain("DELETE",command.CommandText);
                Assert.Equal(SqlDbType.Char,command.Parameters["@Correlation"].SqlDbType);
                Assert.Equal("LinkageCreated",command.Parameters["@Action"].Value);
            }
            Assert.Throws<ArgumentException>(()=>new ContextAuditEvent(Scope,Guid.NewGuid(),AuditAction.LinkageCreated,"sensitive arbitrary payload"));
        }
        [Theory]
        [InlineData(-2,PersistenceFailure.Timeout)] [InlineData(2601,PersistenceFailure.DuplicateConflict)]
        [InlineData(2627,PersistenceFailure.DuplicateConflict)] [InlineData(547,PersistenceFailure.ConstraintViolation)]
        [InlineData(18456,PersistenceFailure.Unavailable)] [InlineData(53,PersistenceFailure.Unavailable)]
        [InlineData(51001,PersistenceFailure.OwnershipConflict)] [InlineData(51002,PersistenceFailure.ConcurrencyConflict)]
        [InlineData(1205,PersistenceFailure.Unexpected)]
        public void SQL_errors_are_distinct_safe_codes_without_raw_exception(int number, PersistenceFailure expected)
        {
            var error=SqlErrors.Map(number); Assert.Equal(expected,error.Failure); Assert.Null(error.InnerException);
            Assert.DoesNotContain(number.ToString(),error.Message);
        }
        [Fact]
        public async Task Closed_gate_prevents_network_even_if_options_are_mutated_and_honors_cancellation()
        {
            var options=new SqlRuntimeOptions { Enabled=true,ConnectionString="invalid secret must never be parsed" };
            var factory=new BazdidWriteConnectionFactory(options);
            Assert.Equal(PersistenceFailure.Blocked,(await Assert.ThrowsAsync<PersistenceException>(()=>factory.OpenAsync(CancellationToken.None))).Failure);
            await Assert.ThrowsAnyAsync<OperationCanceledException>(()=>factory.OpenAsync(new CancellationToken(true)));
            await Assert.ThrowsAsync<PersistenceException>(()=>new UnconfiguredSourceReadConnectionFactory().OpenAsync(CancellationToken.None));
        }
        [Theory]
        [InlineData("Production",true,"")]
        [InlineData("Development",true,"")]
        [InlineData("Testing",true,"")]
        [InlineData("development",false,"")]
        [InlineData("Production",false,"Data Source=lpc:localhost\\SQLSERVER2019;Initial Catalog=BAZDID_Development;Integrated Security=true;Encrypt=true")]
        // مقصد قدیمی `.` در certificate نیست (D-P3-NAME)؛ نباید دوباره پذیرفته شود.
        [InlineData("Development",false,"Data Source=lpc:.\\SQLSERVER2019;Initial Catalog=BAZDID_Development;Integrated Security=true;Encrypt=true")]
        [InlineData("Development",false,"Data Source=tcp:localhost,1433;Initial Catalog=BAZDID_Development;Integrated Security=true;Encrypt=true")]
        [InlineData("Development",false,"Data Source=lpc:localhost\\SQLSERVER2019;Initial Catalog=master;Integrated Security=true;Encrypt=true")]
        [InlineData("Development",false,"Data Source=remote;Initial Catalog=BAZDID_Development;Integrated Security=true;Encrypt=true")]
        public void Unsafe_or_unaccepted_runtime_configuration_fails_closed(string environment,bool enabled,string connection)
        { Assert.Throws<InvalidOperationException>(()=>new SqlRuntimeOptions { Enabled=enabled,ConnectionString=connection }.Validate(environment)); }
        [Fact]
        public void Local_builder_disables_retry_and_refuses_certificate_bypass()
        {
            var options=new SqlRuntimeOptions {ConnectionString=@"Data Source=lpc:localhost\SQLSERVER2019;Initial Catalog=BAZDID_Development;Integrated Security=true;Encrypt=true;TrustServerCertificate=false"};
            var builder=new SqlConnectionStringBuilder(options.BuildLocalConnectionString());
            Assert.Equal(0,builder.ConnectRetryCount); Assert.Equal(5,builder.ConnectTimeout);
            options.ConnectionString+=";TrustServerCertificate=true";
            Assert.Throws<InvalidOperationException>(()=>options.BuildLocalConnectionString());
        }
        [Theory]
        [InlineData(";User ID=")] [InlineData(";Password=")] [InlineData(";User Instance=true")]
        [InlineData(";Network Library=dbmssocn")]
        public void Local_builder_rejects_explicit_credentials_or_transport_overrides(string suffix)
        {
            var options=new SqlRuntimeOptions { ConnectionString=@"Data Source=lpc:localhost\SQLSERVER2019;Initial Catalog=BAZDID_Development;Integrated Security=true;Encrypt=true"+suffix };
            Assert.Throws<InvalidOperationException>(()=>options.BuildLocalConnectionString());
        }
        [Fact]
        public void Loaded_provider_metadata_is_observed_without_opening_a_connection()
        {
            var assembly=typeof(SqlConnection).Assembly;
            using (var connection=new SqlConnection()) Assert.Equal(ConnectionState.Closed,connection.State);
            var directory=Path.GetDirectoryName(assembly.Location);
            _output.WriteLine("PROVIDER_METADATA="+JsonConvert.SerializeObject(new {
                Runtime=RuntimeInformation.FrameworkDescription, Is64BitProcess=Environment.Is64BitProcess,
                AssemblyVersion=assembly.GetName().Version.ToString(), FileVersion=FileVersionInfo.GetVersionInfo(assembly.Location).FileVersion,
                Location=assembly.Location, NativeSniAdjacent=File.Exists(Path.Combine(directory,"sni.dll")),
                NativeSniFiles=Directory.GetFiles(AppContext.BaseDirectory,"sni.dll",SearchOption.AllDirectories).Select(p=>p.Substring(AppContext.BaseDirectory.Length)).ToArray(),
                NativeSniLoadedVerified=false, ConnectionOpened=false
            }));
            Assert.Equal("System.Data.SqlClient",assembly.GetName().Name);
            Assert.True(Environment.Is64BitProcess);
        }
    }
}
