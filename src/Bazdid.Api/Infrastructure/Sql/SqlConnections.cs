using System;
using System.Data;
using System.Data.SqlClient;
using System.Threading;
using System.Threading.Tasks;
using Bazdid.Api.Domain.Persistence;

namespace Bazdid.Api.Infrastructure.Sql
{
    public sealed class BazdidWriteConnectionFactory : IBazdidWriteConnectionFactory
    {
        private readonly SqlRuntimeOptions _options;
        private readonly ConnectedTestAcceptance _testAcceptance;
        public BazdidWriteConnectionFactory(SqlRuntimeOptions options) { _options=options ?? throw new ArgumentNullException(nameof(options)); }
        // فقط آزمون متصل P4؛ DI این سازندهٔ internal را نمی‌بیند. guard هویت/مجوز پایین بدون تغییر اجرا می‌شود.
        internal BazdidWriteConnectionFactory(SqlRuntimeOptions options, ConnectedTestAcceptance testAcceptance) : this(options)
        { _testAcceptance=testAcceptance ?? throw new ArgumentNullException(nameof(testAcceptance)); }
        public async Task<SqlConnection> OpenAsync(CancellationToken cancellationToken)
        {
            cancellationToken.ThrowIfCancellationRequested();
            var open=_testAcceptance != null
                ? string.Equals(_options.ApprovedWriterPrincipal,_testAcceptance.Principal,StringComparison.OrdinalIgnoreCase)
                : _options.Enabled && SqlRuntimeGate.ConnectedAcceptanceVerified;
            if (!open) throw new PersistenceException(PersistenceFailure.Blocked);
            if (string.IsNullOrWhiteSpace(_options.ApprovedWriterPrincipal)) throw new PersistenceException(PersistenceFailure.Blocked);
            var connection=new SqlConnection(_options.BuildLocalConnectionString());
            try
            {
                await connection.OpenAsync(cancellationToken);
                using (var command=connection.CreateCommand())
                {
                    command.CommandTimeout=_options.CommandTimeoutSeconds;
                    command.CommandText=@"SELECT CASE WHEN DB_NAME()=N'BAZDID_Development'
 AND CONVERT(nvarchar(128),SERVERPROPERTY('InstanceName'))=N'SQLSERVER2019'
 AND CONVERT(int,SERVERPROPERTY('ProductMajorVersion'))=15
 AND CONVERT(int,SERVERPROPERTY('IsClustered'))=0 AND CONVERT(int,SERVERPROPERTY('IsHadrEnabled'))=0
 AND CONVERT(nvarchar(128),CONNECTIONPROPERTY('net_transport'))=N'Shared memory'
 AND CONVERT(nvarchar(128),CONNECTIONPROPERTY('auth_scheme')) IN (N'NTLM',N'KERBEROS')
 AND CONVERT(nvarchar(128),SERVERPROPERTY('MachineName'))=@Machine
 AND ORIGINAL_LOGIN()=@Principal AND IS_SRVROLEMEMBER('sysadmin')=0 AND IS_MEMBER('db_owner')=0
 AND HAS_PERMS_BY_NAME(N'dbo.BAZDIDCustomerLinks',N'OBJECT',N'SELECT')=1
 AND HAS_PERMS_BY_NAME(N'dbo.BAZDIDCustomerLinks',N'OBJECT',N'INSERT')=1
 AND HAS_PERMS_BY_NAME(N'dbo.BAZDIDRequestContexts',N'OBJECT',N'SELECT')=1
 AND HAS_PERMS_BY_NAME(N'dbo.BAZDIDRequestContexts',N'OBJECT',N'INSERT')=1
 AND HAS_PERMS_BY_NAME(N'dbo.BAZDIDRequestContexts',N'OBJECT',N'UPDATE')=1
 AND HAS_PERMS_BY_NAME(N'dbo.BAZDIDAuditLogs',N'OBJECT',N'INSERT')=1
 AND HAS_PERMS_BY_NAME(N'dbo.BAZDIDAuditLogs',N'OBJECT',N'SELECT')=0
 AND HAS_PERMS_BY_NAME(N'dbo.BAZDIDAuditLogs',N'OBJECT',N'UPDATE')=0
 AND HAS_PERMS_BY_NAME(N'dbo.BAZDIDAuditLogs',N'OBJECT',N'DELETE')=0
 AND HAS_PERMS_BY_NAME(N'dbo.BAZDIDAuditLogs',N'OBJECT',N'ALTER')=0
 AND HAS_PERMS_BY_NAME(N'dbo.BAZDIDCustomerLinks',N'OBJECT',N'DELETE')=0
 AND HAS_PERMS_BY_NAME(N'dbo.BAZDIDCustomerLinks',N'OBJECT',N'ALTER')=0
 AND HAS_PERMS_BY_NAME(N'dbo.BAZDIDRequestContexts',N'OBJECT',N'DELETE')=0
 AND HAS_PERMS_BY_NAME(N'dbo.BAZDIDRequestContexts',N'OBJECT',N'ALTER')=0
 AND HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CONTROL')=0
 AND HAS_PERMS_BY_NAME(NULL,NULL,N'CONTROL SERVER')=0
 AND HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE TABLE')=0 THEN 1 ELSE 0 END;";
                    SqlCommands.Parameter(command,"@Machine",SqlDbType.NVarChar,128,false,Environment.MachineName);
                    SqlCommands.Parameter(command,"@Principal",SqlDbType.NVarChar,128,false,_options.ApprovedWriterPrincipal);
                    if (Convert.ToInt32(await command.ExecuteScalarAsync(cancellationToken))!=1) throw new PersistenceException(PersistenceFailure.Blocked);
                    command.Parameters.Clear();
                    command.CommandText="SET XACT_ABORT ON; SET ANSI_NULLS ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET QUOTED_IDENTIFIER ON; SET NUMERIC_ROUNDABORT OFF;";
                    await command.ExecuteNonQueryAsync(cancellationToken);
                }
                return connection;
            }
            catch (SqlException error) { connection.Dispose(); throw SqlErrors.Map(error.Number); }
            catch { connection.Dispose(); throw; }
        }
    }
    public sealed class UnconfiguredSourceReadConnectionFactory : ISourceReadConnectionFactory
    {
        public Task<SqlConnection> OpenAsync(CancellationToken cancellationToken)
        { cancellationToken.ThrowIfCancellationRequested(); throw new PersistenceException(PersistenceFailure.Blocked); }
    }
    public static class SqlErrors
    {
        public static PersistenceException Map(int number)
        {
            switch (number)
            {
                case -2:return new PersistenceException(PersistenceFailure.Timeout);
                case 2601:case 2627:return new PersistenceException(PersistenceFailure.DuplicateConflict);
                case 547:return new PersistenceException(PersistenceFailure.ConstraintViolation);
                case 51001:return new PersistenceException(PersistenceFailure.OwnershipConflict);
                case 51002:return new PersistenceException(PersistenceFailure.ConcurrencyConflict);
                case 53:case 233:case 4060:case 18456:case 10054:case 10060:return new PersistenceException(PersistenceFailure.Unavailable);
                default:return new PersistenceException(PersistenceFailure.Unexpected);
            }
        }
    }
    public sealed class SqlTransactionFactory : IBazdidTransactionFactory
    {
        private readonly IBazdidWriteConnectionFactory _connections;
        public SqlTransactionFactory(IBazdidWriteConnectionFactory connections) { _connections=connections; }
        public async Task<IBazdidTransaction> BeginAsync(CancellationToken cancellationToken)
        {
            var connection=await _connections.OpenAsync(cancellationToken);
            try { cancellationToken.ThrowIfCancellationRequested(); return new SqlWorkScope(connection,connection.BeginTransaction(IsolationLevel.ReadCommitted)); }
            catch (SqlException error) { connection.Dispose();throw SqlErrors.Map(error.Number); }
            catch { connection.Dispose();throw; }
        }
    }
    internal sealed class SqlWorkScope : IBazdidTransaction
    {
        private bool _finished;
        private bool _disposed;
        internal SqlWorkScope(SqlConnection connection,SqlTransaction transaction) { Connection=connection;Transaction=transaction; }
        internal SqlConnection Connection { get; }
        internal SqlTransaction Transaction { get; }
        internal void EnsureActive() { if (_finished || _disposed) throw new InvalidOperationException("transaction فعال لازم است."); }
        public void Commit(CancellationToken cancellationToken)
        {
            EnsureActive(); cancellationToken.ThrowIfCancellationRequested();
            try { Transaction.Commit();_finished=true; }
            catch (SqlException) { _finished=true; throw new PersistenceException(PersistenceFailure.CommitOutcomeUnknown); }
            catch (InvalidOperationException) { _finished=true; throw new PersistenceException(PersistenceFailure.CommitOutcomeUnknown); }
        }
        public void Rollback() { EnsureActive();try { Transaction.Rollback(); } catch (SqlException) { throw new PersistenceException(PersistenceFailure.Unavailable); } finally { _finished=true; } }
        public void Dispose()
        {
            if (_disposed) return;
            try { if (!_finished) { try { Transaction.Rollback(); } catch (SqlException) { } catch (InvalidOperationException) { } } }
            finally { _disposed=true;Transaction.Dispose();Connection.Dispose(); }
        }
    }
}
