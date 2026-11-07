using System;
using System.Data;
using System.Data.SqlClient;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Bazdid.Api.Domain.Auth;
using Bazdid.Api.Domain.Brokerage;
using Bazdid.Api.Domain.Persistence;

namespace Bazdid.Api.Infrastructure.Sql
{
    // Checkpoint 3 — storeهای SQL احراز (migration 0002). همهٔ دستورها پارامتری‌اند و هر عملیات در transaction کوتاه
    // از IBazdidTransactionFactory اجرا می‌شود؛ در برنامه همین factory پشت gate و guard هویت Writer است.
    internal static class AuthSql
    {
        internal static byte[] HandleHash(string handle)
        {
            if (string.IsNullOrEmpty(handle)) throw new ArgumentException("handle لازم است.", nameof(handle));
            using (var sha = SHA256.Create()) return sha.ComputeHash(Encoding.UTF8.GetBytes(handle));
        }
        internal static DateTime Utc(DateTimeOffset value) => value.UtcDateTime;
        internal static object Utc(DateTimeOffset? value) => value.HasValue ? (object)value.Value.UtcDateTime : null;
        internal static DateTimeOffset ReadUtc(SqlDataReader r, int i) => new DateTimeOffset(DateTime.SpecifyKind(r.GetDateTime(i), DateTimeKind.Utc));
        internal static DateTimeOffset? ReadUtcNull(SqlDataReader r, int i) => r.IsDBNull(i) ? (DateTimeOffset?)null : ReadUtc(r, i);
        internal static async Task<T> RunAsync<T>(IBazdidTransactionFactory transactions, int timeout, CancellationToken ct, Func<SqlCommand, Task<T>> work, bool commit = true)
        {
            using (var tx = await transactions.BeginAsync(ct))
            {
                var scope = tx as SqlWorkScope ?? throw new InvalidOperationException("transaction متعلق به SQL adapter لازم است.");
                using (var command = scope.Connection.CreateCommand())
                {
                    command.Transaction = scope.Transaction; command.CommandTimeout = timeout;
                    T result;
                    try { result = await work(command); }
                    catch (SqlException error) { throw SqlErrors.Map(error.Number); }
                    if (commit) tx.Commit(ct); else tx.Rollback();
                    return result;
                }
            }
        }
    }

    public sealed class SqlOtpChallengeStore : IOtpChallengeStore
    {
        private const string Columns = "Id,BrokerageId,SourceSystem,RequestContextId,BrowserNonceHash,State,Generation,CodeMac,CodeExpiresAtUtc,ContextExpiresAtUtc,FailedAttempts,LastSentAtUtc,SendWindowStartUtc,SendsInWindow,ConsumedAtUtc,RowVersion";
        private readonly IBazdidTransactionFactory _transactions;
        private readonly int _timeout;
        public SqlOtpChallengeStore(IBazdidTransactionFactory transactions, SqlRuntimeOptions options) { _transactions = transactions; _timeout = options.CommandTimeoutSeconds; }

        public Task<OtpChallenge> FindAsync(string challengeId, CancellationToken cancellationToken)
        {
            if (string.IsNullOrEmpty(challengeId) || challengeId.Length > 128) return Task.FromResult<OtpChallenge>(null);
            return AuthSql.RunAsync(_transactions, _timeout, cancellationToken, async command =>
            {
                command.CommandText = "SELECT " + Columns + " FROM dbo.BAZDIDOtpChallenges WHERE HandleHash=@Handle;";
                SqlCommands.Parameter(command, "@Handle", SqlDbType.Binary, 32, false, AuthSql.HandleHash(challengeId));
                using (var r = await command.ExecuteReaderAsync(cancellationToken))
                {
                    if (!await r.ReadAsync(cancellationToken)) return null;
                    return new OtpChallenge(challengeId, r.GetGuid(3), (byte[])r[4], AuthSql.ReadUtc(r, 9))
                    {
                        Id = r.GetGuid(0), Scope = new BrokerageScope(r.GetString(1), r.GetString(2)),
                        State = (OtpChallengeState)Enum.Parse(typeof(OtpChallengeState), r.GetString(5), false), Generation = r.GetInt32(6),
                        CodeMac = r.IsDBNull(7) ? null : (byte[])r[7], CodeExpiresAtUtc = AuthSql.ReadUtcNull(r, 8), FailedAttempts = r.GetInt32(10),
                        LastSentAtUtc = AuthSql.ReadUtcNull(r, 11), SendWindowStartUtc = AuthSql.ReadUtcNull(r, 12), SendsInWindow = r.GetInt32(13),
                        ConsumedAtUtc = AuthSql.ReadUtcNull(r, 14), Version = new RowVersionToken((byte[])r[15])
                    };
                }
            });
        }

        public Task<bool> TryCreateAsync(OtpChallenge challenge, CancellationToken cancellationToken)
        {
            if (challenge?.Scope == null) throw new ArgumentException("scope چالش لازم است.", nameof(challenge));
            return AuthSql.RunAsync(_transactions, _timeout, cancellationToken, async command =>
            {
                // بدون SET NOCOUNT: شمار ردیف INSERT نتیجهٔ موفقیت است (با NOCOUNT مقدار -1 برمی‌گردد).
                command.CommandText = @"IF NOT EXISTS (SELECT 1 FROM dbo.BAZDIDRequestContexts WHERE Id=@Context AND BrokerageId=@Brokerage AND SourceSystem=@Source)
 THROW 51001, 'BAZDID_OWNER_CONFLICT', 1;
INSERT dbo.BAZDIDOtpChallenges (Id,HandleHash,BrokerageId,SourceSystem,RequestContextId,BrowserNonceHash,State,ContextExpiresAtUtc)
VALUES (@Id,@Handle,@Brokerage,@Source,@Context,@Nonce,'Resolved',@ContextExpires);";
                SqlCommands.Parameter(command, "@Id", SqlDbType.UniqueIdentifier, 16, false, challenge.Id);
                SqlCommands.Parameter(command, "@Handle", SqlDbType.Binary, 32, false, AuthSql.HandleHash(challenge.ChallengeId));
                SqlCommands.Parameter(command, "@Brokerage", SqlDbType.NVarChar, 32, false, challenge.Scope.BrokerageId);
                SqlCommands.Parameter(command, "@Source", SqlDbType.NVarChar, 32, false, challenge.Scope.SourceSystem);
                SqlCommands.Parameter(command, "@Context", SqlDbType.UniqueIdentifier, 16, false, challenge.RequestContextId);
                SqlCommands.Parameter(command, "@Nonce", SqlDbType.Binary, 32, false, challenge.BrowserNonceHash);
                SqlCommands.Parameter(command, "@ContextExpires", SqlDbType.DateTime2, 0, false, AuthSql.Utc(challenge.ContextExpiresAtUtc));
                return await command.ExecuteNonQueryAsync(cancellationToken) == 1;
            });
        }

        public Task<bool> TrySaveAsync(OtpChallenge challenge, RowVersionToken expectedVersion, CancellationToken cancellationToken)
        {
            if (expectedVersion == null) return Task.FromResult(false);
            return AuthSql.RunAsync(_transactions, _timeout, cancellationToken, async command =>
            {
                // UPDATE شرطی روی rowversion: از دو تغییر هم‌زمان فقط یکی موفق است.
                command.CommandText = @"UPDATE dbo.BAZDIDOtpChallenges SET State=@State,Generation=@Generation,CodeMac=@Mac,CodeExpiresAtUtc=@CodeExpires,
 FailedAttempts=@Failed,LastSentAtUtc=@LastSent,SendWindowStartUtc=@WindowStart,SendsInWindow=@Sends,ConsumedAtUtc=@Consumed
WHERE Id=@Id AND HandleHash=@Handle AND RowVersion=@Expected;";
                SqlCommands.Parameter(command, "@State", SqlDbType.VarChar, 16, false, challenge.State.ToString());
                SqlCommands.Parameter(command, "@Generation", SqlDbType.Int, 0, false, challenge.Generation);
                SqlCommands.Parameter(command, "@Mac", SqlDbType.Binary, 32, true, challenge.CodeMac);
                SqlCommands.Parameter(command, "@CodeExpires", SqlDbType.DateTime2, 0, true, AuthSql.Utc(challenge.CodeExpiresAtUtc));
                SqlCommands.Parameter(command, "@Failed", SqlDbType.Int, 0, false, challenge.FailedAttempts);
                SqlCommands.Parameter(command, "@LastSent", SqlDbType.DateTime2, 0, true, AuthSql.Utc(challenge.LastSentAtUtc));
                SqlCommands.Parameter(command, "@WindowStart", SqlDbType.DateTime2, 0, true, AuthSql.Utc(challenge.SendWindowStartUtc));
                SqlCommands.Parameter(command, "@Sends", SqlDbType.Int, 0, false, challenge.SendsInWindow);
                SqlCommands.Parameter(command, "@Consumed", SqlDbType.DateTime2, 0, true, AuthSql.Utc(challenge.ConsumedAtUtc));
                SqlCommands.Parameter(command, "@Id", SqlDbType.UniqueIdentifier, 16, false, challenge.Id);
                SqlCommands.Parameter(command, "@Handle", SqlDbType.Binary, 32, false, AuthSql.HandleHash(challenge.ChallengeId));
                SqlCommands.Parameter(command, "@Expected", SqlDbType.Binary, 8, false, expectedVersion.ToArray());
                return await command.ExecuteNonQueryAsync(cancellationToken) == 1;
            });
        }
    }

    public sealed class SqlCustomerSessionStore : ICustomerSessionStore
    {
        private readonly IBazdidTransactionFactory _transactions;
        private readonly int _timeout;
        public SqlCustomerSessionStore(IBazdidTransactionFactory transactions, SqlRuntimeOptions options) { _transactions = transactions; _timeout = options.CommandTimeoutSeconds; }

        public Task CreateAsync(CustomerSession s, CancellationToken cancellationToken)
        {
            if (s?.Scope == null || s.HandleHash == null || s.HandleHash.Length != 32) throw new ArgumentException("نشست ناقص است.", nameof(s));
            return AuthSql.RunAsync(_transactions, _timeout, cancellationToken, async command =>
            {
                // نشست فقط از چالش مصرف‌شدهٔ همان context/tenant ساخته می‌شود؛ UQ روی OtpChallengeId جلوی replay را می‌گیرد.
                command.CommandText = @"SET NOCOUNT ON;
IF NOT EXISTS (SELECT 1 FROM dbo.BAZDIDOtpChallenges WHERE Id=@Challenge AND State='Consumed' AND RequestContextId=@Context
                AND BrokerageId=@Brokerage AND SourceSystem=@Source)
 OR NOT EXISTS (SELECT 1 FROM dbo.BAZDIDRequestContexts WHERE Id=@Context AND CustomerLinkId=@Customer AND BrokerageId=@Brokerage AND SourceSystem=@Source)
 THROW 51001, 'BAZDID_OWNER_CONFLICT', 1;
INSERT dbo.BAZDIDCustomerSessions (Id,HandleHash,BrokerageId,SourceSystem,RequestContextId,CustomerLinkId,OtpChallengeId,AuthenticatedAtUtc,LastSeenAtUtc,IdleExpiresAtUtc,AbsoluteExpiresAtUtc)
VALUES (@Id,@Handle,@Brokerage,@Source,@Context,@Customer,@Challenge,@Auth,@Auth,@Idle,@Absolute);
SELECT RowVersion FROM dbo.BAZDIDCustomerSessions WHERE Id=@Id;";
                SqlCommands.Parameter(command, "@Id", SqlDbType.UniqueIdentifier, 16, false, s.Id);
                SqlCommands.Parameter(command, "@Handle", SqlDbType.Binary, 32, false, s.HandleHash);
                SqlCommands.Parameter(command, "@Brokerage", SqlDbType.NVarChar, 32, false, s.Scope.BrokerageId);
                SqlCommands.Parameter(command, "@Source", SqlDbType.NVarChar, 32, false, s.Scope.SourceSystem);
                SqlCommands.Parameter(command, "@Context", SqlDbType.UniqueIdentifier, 16, false, s.RequestContextId);
                SqlCommands.Parameter(command, "@Customer", SqlDbType.UniqueIdentifier, 16, false, s.CustomerLinkId);
                SqlCommands.Parameter(command, "@Challenge", SqlDbType.UniqueIdentifier, 16, false, s.OtpChallengeId);
                SqlCommands.Parameter(command, "@Auth", SqlDbType.DateTime2, 0, false, AuthSql.Utc(s.AuthenticatedAtUtc));
                SqlCommands.Parameter(command, "@Idle", SqlDbType.DateTime2, 0, false, AuthSql.Utc(s.IdleExpiresAtUtc));
                SqlCommands.Parameter(command, "@Absolute", SqlDbType.DateTime2, 0, false, AuthSql.Utc(s.AbsoluteExpiresAtUtc));
                s.Version = new RowVersionToken((byte[])await command.ExecuteScalarAsync(cancellationToken));
                s.LastSeenAtUtc = s.AuthenticatedAtUtc;
                return true;
            });
        }

        public Task<CustomerSession> FindByHandleHashAsync(byte[] handleHash, CancellationToken cancellationToken)
        {
            if (handleHash == null || handleHash.Length != 32) return Task.FromResult<CustomerSession>(null);
            return AuthSql.RunAsync(_transactions, _timeout, cancellationToken, async command =>
            {
                command.CommandText = @"SELECT Id,HandleHash,BrokerageId,SourceSystem,RequestContextId,CustomerLinkId,OtpChallengeId,AuthenticatedAtUtc,LastSeenAtUtc,
 IdleExpiresAtUtc,AbsoluteExpiresAtUtc,RevokedAtUtc,RevokeReason,RowVersion FROM dbo.BAZDIDCustomerSessions WHERE HandleHash=@Handle;";
                SqlCommands.Parameter(command, "@Handle", SqlDbType.Binary, 32, false, handleHash);
                using (var r = await command.ExecuteReaderAsync(cancellationToken))
                {
                    if (!await r.ReadAsync(cancellationToken)) return null;
                    return new CustomerSession
                    {
                        Id = r.GetGuid(0), HandleHash = (byte[])r[1], Scope = new BrokerageScope(r.GetString(2), r.GetString(3)), RequestContextId = r.GetGuid(4),
                        CustomerLinkId = r.GetGuid(5), OtpChallengeId = r.GetGuid(6), AuthenticatedAtUtc = AuthSql.ReadUtc(r, 7), LastSeenAtUtc = AuthSql.ReadUtc(r, 8),
                        IdleExpiresAtUtc = AuthSql.ReadUtc(r, 9), AbsoluteExpiresAtUtc = AuthSql.ReadUtc(r, 10), RevokedAtUtc = AuthSql.ReadUtcNull(r, 11),
                        RevokeReason = r.IsDBNull(12) ? null : r.GetString(12), Version = new RowVersionToken((byte[])r[13])
                    };
                }
            });
        }

        public Task<bool> TryTouchAsync(Guid id, RowVersionToken expectedVersion, DateTimeOffset lastSeen, DateTimeOffset idleExpires, CancellationToken cancellationToken)
        {
            if (expectedVersion == null) return Task.FromResult(false);
            return AuthSql.RunAsync(_transactions, _timeout, cancellationToken, async command =>
            {
                // sliding فقط idle را جلو می‌برد و هرگز از absolute بیشتر نمی‌شود.
                command.CommandText = @"UPDATE dbo.BAZDIDCustomerSessions SET LastSeenAtUtc=@Seen,
 IdleExpiresAtUtc=CASE WHEN @Idle > AbsoluteExpiresAtUtc THEN AbsoluteExpiresAtUtc ELSE @Idle END
WHERE Id=@Id AND RowVersion=@Expected AND RevokedAtUtc IS NULL AND IdleExpiresAtUtc > @Seen AND AbsoluteExpiresAtUtc > @Seen;";
                SqlCommands.Parameter(command, "@Seen", SqlDbType.DateTime2, 0, false, AuthSql.Utc(lastSeen));
                SqlCommands.Parameter(command, "@Idle", SqlDbType.DateTime2, 0, false, AuthSql.Utc(idleExpires));
                SqlCommands.Parameter(command, "@Id", SqlDbType.UniqueIdentifier, 16, false, id);
                SqlCommands.Parameter(command, "@Expected", SqlDbType.Binary, 8, false, expectedVersion.ToArray());
                return await command.ExecuteNonQueryAsync(cancellationToken) == 1;
            });
        }

        public Task<bool> TryRevokeAsync(Guid id, string reason, DateTimeOffset now, CancellationToken cancellationToken)
        {
            if (reason != "Logout" && reason != "Expired" && reason != "Admin" && reason != "Superseded") throw new ArgumentException("دلیل ابطال نامعتبر است.", nameof(reason));
            return AuthSql.RunAsync(_transactions, _timeout, cancellationToken, async command =>
            {
                command.CommandText = "UPDATE dbo.BAZDIDCustomerSessions SET RevokedAtUtc=@Now,RevokeReason=@Reason WHERE Id=@Id AND RevokedAtUtc IS NULL AND @Now >= AuthenticatedAtUtc;";
                SqlCommands.Parameter(command, "@Now", SqlDbType.DateTime2, 0, false, AuthSql.Utc(now));
                SqlCommands.Parameter(command, "@Reason", SqlDbType.VarChar, 16, false, reason);
                SqlCommands.Parameter(command, "@Id", SqlDbType.UniqueIdentifier, 16, false, id);
                return await command.ExecuteNonQueryAsync(cancellationToken) == 1;
            });
        }
    }

    public sealed class SqlAuthRateLimiter : IAuthRateLimiter
    {
        private readonly IBazdidTransactionFactory _transactions;
        private readonly int _timeout;
        public SqlAuthRateLimiter(IBazdidTransactionFactory transactions, SqlRuntimeOptions options) { _transactions = transactions; _timeout = options.CommandTimeoutSeconds; }

        public Task<RateDecision> HitAsync(string scope, byte[] keyHash, int limit, TimeSpan window, DateTimeOffset now, CancellationToken cancellationToken)
        {
            if (keyHash == null || keyHash.Length != 32 || limit < 1 || window <= TimeSpan.Zero) throw new ArgumentException("پارامتر نرخ نامعتبر است.");
            return AuthSql.RunAsync(_transactions, _timeout, cancellationToken, async command =>
            {
                // قفل کلید (UPDLOCK,HOLDLOCK) شمارش را بین درخواست‌ها و instanceها اتمیک می‌کند.
                command.CommandText = @"SET NOCOUNT ON;
DECLARE @Start datetime2(3), @Hits int;
SELECT @Start=WindowStartUtc, @Hits=Hits FROM dbo.BAZDIDAuthRateCounters WITH (UPDLOCK, HOLDLOCK) WHERE Scope=@Scope AND KeyHash=@Key;
IF @Start IS NULL
BEGIN INSERT dbo.BAZDIDAuthRateCounters (Scope,KeyHash,WindowStartUtc,Hits) VALUES (@Scope,@Key,@Now,1); SELECT CAST(1 AS bit), @Now; RETURN; END;
IF DATEADD(millisecond, @WindowMs, @Start) <= @Now
BEGIN UPDATE dbo.BAZDIDAuthRateCounters SET WindowStartUtc=@Now, Hits=1 WHERE Scope=@Scope AND KeyHash=@Key; SELECT CAST(1 AS bit), @Now; RETURN; END;
IF @Hits >= @Limit BEGIN SELECT CAST(0 AS bit), @Start; RETURN; END;
UPDATE dbo.BAZDIDAuthRateCounters SET Hits=Hits+1 WHERE Scope=@Scope AND KeyHash=@Key;
SELECT CAST(1 AS bit), @Start;";
                SqlCommands.Parameter(command, "@Scope", SqlDbType.VarChar, 16, false, scope);
                SqlCommands.Parameter(command, "@Key", SqlDbType.Binary, 32, false, keyHash);
                SqlCommands.Parameter(command, "@Now", SqlDbType.DateTime2, 0, false, AuthSql.Utc(now));
                SqlCommands.Parameter(command, "@WindowMs", SqlDbType.Int, 0, false, (int)window.TotalMilliseconds);
                SqlCommands.Parameter(command, "@Limit", SqlDbType.Int, 0, false, limit);
                using (var r = await command.ExecuteReaderAsync(cancellationToken))
                {
                    if (!await r.ReadAsync(cancellationToken)) throw new PersistenceException(PersistenceFailure.Unexpected);
                    var allowed = r.GetBoolean(0);
                    var retry = allowed ? TimeSpan.Zero : (AuthSql.ReadUtc(r, 1) + window) - now;
                    return new RateDecision(allowed, retry < TimeSpan.Zero ? TimeSpan.Zero : retry);
                }
            });
        }
    }
}
