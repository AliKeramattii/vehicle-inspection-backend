using System;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Bazdid.Api.Domain.Brokerage;

namespace Bazdid.Api.Domain.Persistence
{
    public enum PersistenceFailure { Blocked, Timeout, Unavailable, DuplicateConflict, ConstraintViolation, ConcurrencyConflict, OwnershipConflict, Unexpected, CommitOutcomeUnknown }
    public sealed class PersistenceException : Exception
    {
        public PersistenceException(PersistenceFailure failure) : base("عملیات ماندگاری تکمیل نشد؛ کد امن نتیجه را بررسی کنید.") { Failure = failure; }
        public PersistenceFailure Failure { get; }
    }
    public sealed class RowVersionToken
    {
        private readonly byte[] _bytes;
        public RowVersionToken(byte[] bytes)
        { if (bytes == null || bytes.Length != 8) throw new ArgumentException("نسخهٔ هشت‌بایتی لازم است."); _bytes = (byte[])bytes.Clone(); }
        public byte[] ToArray() => (byte[])_bytes.Clone();
    }
    public sealed class HmacReference
    {
        private readonly byte[] _digest;
        public HmacReference(byte[] digest, string keyId)
        {
            if (digest == null || digest.Length != 32 || string.IsNullOrEmpty(keyId) || keyId.Length > 32)
                throw new ArgumentException("مرجع HMAC معتبر نیست.");
            foreach (var c in keyId) if (!((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '-' || c == '_'))
                throw new ArgumentException("شناسهٔ کلید معتبر نیست.");
            _digest = (byte[])digest.Clone(); KeyId = keyId;
        }
        public string KeyId { get; }
        public byte[] ToArray() => (byte[])_digest.Clone();
    }
    public sealed class RequestMetadata
    {
        public RequestMetadata(RequestEligibility eligibility, string sourceVersion, DateTimeOffset retrievedAtUtc,
            HmacReference referral = null, HmacReference identity = null, HmacReference previousIdentity = null)
        {
            if (!Enum.IsDefined(typeof(RequestEligibility), eligibility) || retrievedAtUtc.Offset != TimeSpan.Zero ||
                (sourceVersion != null && (string.IsNullOrWhiteSpace(sourceVersion) || sourceVersion.Length > 128)))
                throw new ArgumentException("metadata درخواست معتبر نیست.");
            Eligibility = eligibility; SourceVersion = sourceVersion; RetrievedAtUtc = retrievedAtUtc;
            Referral = referral; Identity = identity; PreviousIdentity = previousIdentity;
        }
        public RequestEligibility Eligibility { get; }
        public string SourceVersion { get; }
        public DateTimeOffset RetrievedAtUtc { get; }
        public HmacReference Referral { get; }
        public HmacReference Identity { get; }
        public HmacReference PreviousIdentity { get; }
    }
    public sealed class CustomerLinkRecord
    {
        public CustomerLinkRecord(Guid id, BrokerageScope scope, string sourceCustomerId, DateTimeOffset createdAtUtc, DateTimeOffset updatedAtUtc, RowVersionToken version)
        { PersistenceInput.Id(id); PersistenceInput.SourceKey(sourceCustomerId); Id=id; Scope=scope ?? throw new ArgumentNullException(nameof(scope)); SourceCustomerId=sourceCustomerId; CreatedAtUtc=createdAtUtc; UpdatedAtUtc=updatedAtUtc; Version=version ?? throw new ArgumentNullException(nameof(version)); }
        public Guid Id { get; }
        public BrokerageScope Scope { get; }
        public string SourceCustomerId { get; }
        public DateTimeOffset CreatedAtUtc { get; }
        public DateTimeOffset UpdatedAtUtc { get; }
        public RowVersionToken Version { get; }
    }
    public sealed class RequestContextRecord
    {
        public RequestContextRecord(Guid id, BrokerageRequestReference reference, Guid customerLinkId, RequestMetadata metadata, RowVersionToken version)
        { PersistenceInput.Id(id); PersistenceInput.Id(customerLinkId); Id=id; Reference=reference ?? throw new ArgumentNullException(nameof(reference)); CustomerLinkId=customerLinkId; Metadata=metadata ?? throw new ArgumentNullException(nameof(metadata)); Version=version ?? throw new ArgumentNullException(nameof(version)); }
        public Guid Id { get; }
        public BrokerageRequestReference Reference { get; }
        public Guid CustomerLinkId { get; }
        public RequestMetadata Metadata { get; }
        public RowVersionToken Version { get; }
    }
    public sealed class GetOrCreateResult<T> where T : class
    {
        public GetOrCreateResult(T record, bool created) { Record=record ?? throw new ArgumentNullException(nameof(record)); Created=created; }
        public T Record { get; }
        public bool Created { get; }
    }
    public enum AuditAction { LinkageCreated, RequestMetadataUpdated }
    public sealed class ContextAuditEvent
    {
        public ContextAuditEvent(BrokerageScope scope, Guid requestContextId, AuditAction action, string correlationId)
        {
            Scope=scope ?? throw new ArgumentNullException(nameof(scope)); PersistenceInput.Id(requestContextId);
            if (!Enum.IsDefined(typeof(AuditAction),action) || correlationId == null || correlationId.Length != 32)
                throw new ArgumentException("رویداد audit معتبر نیست.");
            foreach (var c in correlationId) if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f'))) throw new ArgumentException("correlation معتبر نیست.");
            RequestContextId=requestContextId; Action=action; CorrelationId=correlationId;
        }
        public BrokerageScope Scope { get; }
        public Guid RequestContextId { get; }
        public AuditAction Action { get; }
        public string CorrelationId { get; }
    }
    public interface IBazdidTransaction : IDisposable { void Commit(CancellationToken cancellationToken); void Rollback(); }
    public interface IBazdidTransactionFactory { Task<IBazdidTransaction> BeginAsync(CancellationToken cancellationToken); }
    public interface ICustomerLinkRepository
    {
        Task<CustomerLinkRecord> FindAsync(IBazdidTransaction transaction, BrokerageScope scope, string customerId, CancellationToken cancellationToken);
        Task<GetOrCreateResult<CustomerLinkRecord>> GetOrCreateAsync(IBazdidTransaction transaction, BrokerageScope scope, string customerId, CancellationToken cancellationToken);
    }
    public interface IRequestContextRepository
    {
        Task<RequestContextRecord> FindAsync(IBazdidTransaction transaction, BrokerageRequestReference request, CancellationToken cancellationToken);
        Task<GetOrCreateResult<RequestContextRecord>> GetOrCreateAsync(IBazdidTransaction transaction, BrokerageRequestReference request, CustomerLinkRecord customer, RequestMetadata metadata, CancellationToken cancellationToken);
        Task<RequestContextRecord> UpdateMetadataAsync(IBazdidTransaction transaction, Guid id, BrokerageRequestReference request, CustomerLinkRecord customer, RowVersionToken expectedVersion, RequestMetadata metadata, CancellationToken cancellationToken);
    }
    public interface IAuditRepository { Task AppendAsync(IBazdidTransaction transaction, ContextAuditEvent auditEvent, CancellationToken cancellationToken); }
    public static class PersistenceInput
    {
        public static void Id(Guid value) { if (value == Guid.Empty) throw new ArgumentException("شناسهٔ داخلی معتبر نیست."); }
        public static byte[] SourceKey(string value)
        {
            if (string.IsNullOrWhiteSpace(value) || value.Length > 128) throw new ArgumentException("شناسهٔ مبدأ معتبر نیست.");
            try { return new UnicodeEncoding(false,false,true).GetBytes(value); }
            catch (EncoderFallbackException) { throw new ArgumentException("شناسهٔ مبدأ Unicode معتبر ندارد."); }
        }
    }
}
