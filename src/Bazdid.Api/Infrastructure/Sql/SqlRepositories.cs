using System;
using System.Data.SqlClient;
using System.Threading;
using System.Threading.Tasks;
using Bazdid.Api.Domain.Brokerage;
using Bazdid.Api.Domain.Persistence;

namespace Bazdid.Api.Infrastructure.Sql
{
    internal static class SqlRecords
    {
        internal static DateTimeOffset Utc(SqlDataReader reader, int ordinal) => new DateTimeOffset(DateTime.SpecifyKind(reader.GetDateTime(ordinal),DateTimeKind.Utc));
        internal static CustomerLinkRecord Customer(SqlDataReader r) => new CustomerLinkRecord(r.GetGuid(0),new BrokerageScope(r.GetString(1),r.GetString(2)),r.GetString(3),Utc(r,4),Utc(r,5),new RowVersionToken((byte[])r[6]));
        private static HmacReference Hmac(SqlDataReader r, int ordinal) => r.IsDBNull(ordinal) ? null : new HmacReference((byte[])r[ordinal],r.GetString(ordinal+1));
        internal static RequestContextRecord Context(SqlDataReader r) => new RequestContextRecord(r.GetGuid(0),
            new BrokerageRequestReference(new BrokerageScope(r.GetString(1),r.GetString(2)),r.GetString(3)),r.GetGuid(4),
            new RequestMetadata((RequestEligibility)Enum.Parse(typeof(RequestEligibility),r.GetString(5),false),r.IsDBNull(6)?null:r.GetString(6),Utc(r,7),Hmac(r,8),Hmac(r,10),Hmac(r,12)),new RowVersionToken((byte[])r[14]));
        internal static void Attach(SqlCommand command, IBazdidTransaction transaction, int timeout, CancellationToken cancellationToken)
        {
            cancellationToken.ThrowIfCancellationRequested();
            var scope = transaction as SqlWorkScope;
            if (scope == null) throw new ArgumentException("transaction متعلق به همین SQL adapter لازم است.");
            scope.EnsureActive(); command.Connection=scope.Connection; command.Transaction=scope.Transaction; command.CommandTimeout=timeout;
        }
    }
    public sealed class SqlCustomerLinkRepository : ICustomerLinkRepository
    {
        private readonly int _timeout;
        public SqlCustomerLinkRepository(SqlRuntimeOptions options) { _timeout=options.CommandTimeoutSeconds; }
        public async Task<CustomerLinkRecord> FindAsync(IBazdidTransaction transaction, BrokerageScope scope, string customerId, CancellationToken cancellationToken)
        {
            using (var command=SqlCommands.Customer(scope,customerId,false))
            {
                SqlRecords.Attach(command,transaction,_timeout,cancellationToken);
                try { using (var reader=await command.ExecuteReaderAsync(cancellationToken)) return await reader.ReadAsync(cancellationToken)?SqlRecords.Customer(reader):null; }
                catch (SqlException error) { throw SqlErrors.Map(error.Number); }
            }
        }
        public async Task<GetOrCreateResult<CustomerLinkRecord>> GetOrCreateAsync(IBazdidTransaction transaction, BrokerageScope scope, string customerId, CancellationToken cancellationToken)
        {
            using (var command=SqlCommands.Customer(scope,customerId,true))
            {
                SqlRecords.Attach(command,transaction,_timeout,cancellationToken);
                try
                {
                    using (var reader=await command.ExecuteReaderAsync(cancellationToken))
                    {
                        if (!await reader.ReadAsync(cancellationToken)) throw new PersistenceException(PersistenceFailure.Unexpected);
                        return new GetOrCreateResult<CustomerLinkRecord>(SqlRecords.Customer(reader),reader.GetBoolean(7));
                    }
                }
                catch (SqlException error) { throw SqlErrors.Map(error.Number); }
            }
        }
    }
    public sealed class SqlRequestContextRepository : IRequestContextRepository
    {
        private readonly int _timeout;
        public SqlRequestContextRepository(SqlRuntimeOptions options) { _timeout=options.CommandTimeoutSeconds; }
        private async Task<GetOrCreateResult<RequestContextRecord>> ReadAsync(SqlCommand command, IBazdidTransaction transaction, bool hasCreated, CancellationToken ct)
        {
            SqlRecords.Attach(command,transaction,_timeout,ct);
            try
            {
                using (var reader=await command.ExecuteReaderAsync(ct))
                {
                    if (!await reader.ReadAsync(ct)) return null;
                    return new GetOrCreateResult<RequestContextRecord>(SqlRecords.Context(reader),hasCreated && reader.GetBoolean(15));
                }
            }
            catch (SqlException error) { throw SqlErrors.Map(error.Number); }
        }
        public async Task<RequestContextRecord> FindAsync(IBazdidTransaction transaction, BrokerageRequestReference request, CancellationToken cancellationToken)
        { using (var command=SqlCommands.FindContext(request)) return (await ReadAsync(command,transaction,false,cancellationToken))?.Record; }
        public async Task<GetOrCreateResult<RequestContextRecord>> GetOrCreateAsync(IBazdidTransaction transaction, BrokerageRequestReference request, CustomerLinkRecord customer, RequestMetadata metadata, CancellationToken cancellationToken)
        {
            using (var command=SqlCommands.CreateContext(request,customer,metadata))
                return await ReadAsync(command,transaction,true,cancellationToken) ?? throw new PersistenceException(PersistenceFailure.Unexpected);
        }
        public async Task<RequestContextRecord> UpdateMetadataAsync(IBazdidTransaction transaction, Guid id, BrokerageRequestReference request, CustomerLinkRecord customer, RowVersionToken expectedVersion, RequestMetadata metadata, CancellationToken cancellationToken)
        {
            using (var command=SqlCommands.UpdateContext(id,request,customer,expectedVersion,metadata))
                return (await ReadAsync(command,transaction,false,cancellationToken))?.Record ?? throw new PersistenceException(PersistenceFailure.Unexpected);
        }
    }
    public sealed class SqlAuditRepository : IAuditRepository
    {
        private readonly int _timeout;
        public SqlAuditRepository(SqlRuntimeOptions options) { _timeout=options.CommandTimeoutSeconds; }
        public async Task AppendAsync(IBazdidTransaction transaction, ContextAuditEvent auditEvent, CancellationToken cancellationToken)
        {
            using (var command=SqlCommands.Audit(auditEvent))
            {
                SqlRecords.Attach(command,transaction,_timeout,cancellationToken);
                try { await command.ExecuteNonQueryAsync(cancellationToken); }
                catch (SqlException error) { throw SqlErrors.Map(error.Number); }
            }
        }
    }
}
