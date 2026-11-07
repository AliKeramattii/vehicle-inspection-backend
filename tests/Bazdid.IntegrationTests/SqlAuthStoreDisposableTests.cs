using System;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Bazdid.Api.Application.Auth;
using Bazdid.Api.Domain.Auth;
using Bazdid.Api.Domain.Brokerage;
using Bazdid.Api.Domain.Persistence;
using Bazdid.Api.Infrastructure.Sql;
using Xunit;

namespace Bazdid.IntegrationTests
{
    /// <summary>فقط با BAZDID_DISPOSABLE_SQL=1 و از داخل runner مربوط به migration (پایگاه یک‌بارمصرف) اجرا می‌شود.</summary>
    public sealed class DisposableSqlFactAttribute : FactAttribute
    {
        public DisposableSqlFactAttribute()
        {
            if (Environment.GetEnvironmentVariable("BAZDID_DISPOSABLE_SQL") != "1")
                Skip = "SQL یک‌بارمصرف انتخاب نشده است؛ فقط از Invoke-BazdidMigration.ps1 روی BAZDID_MigrationTest اجرا می‌شود.";
        }
    }

    /// <summary>اتصال آزمون فقط به BAZDID_MigrationTest با TLS معتبر و فقط پس از اثبات نشانهٔ BAZDID.Disposable.</summary>
    internal sealed class DisposableTransactions : IBazdidTransactionFactory
    {
        internal const string ConnectionString = @"Data Source=lpc:localhost\SQLSERVER2019;Initial Catalog=BAZDID_MigrationTest;Integrated Security=true;Encrypt=true;TrustServerCertificate=false;Connect Timeout=5;Pooling=false";
        public async Task<IBazdidTransaction> BeginAsync(CancellationToken cancellationToken)
        {
            var connection = new SqlConnection(ConnectionString);
            try
            {
                await connection.OpenAsync(cancellationToken);
                using (var check = connection.CreateCommand())
                {
                    check.CommandText = "SELECT CASE WHEN DB_NAME()=N'BAZDID_MigrationTest' AND (SELECT CONVERT(nvarchar(256),value) FROM sys.extended_properties WHERE class=0 AND name=N'BAZDID.Disposable')=N'BAZDID_MigrationTest;Checkpoint2G;disposable' THEN 1 ELSE 0 END;";
                    if (Convert.ToInt32(await check.ExecuteScalarAsync(cancellationToken)) != 1) throw new InvalidOperationException("مقصد آزمون پایگاه یک‌بارمصرف اثبات‌شده نیست.");
                }
                return new SqlWorkScope(connection, connection.BeginTransaction(IsolationLevel.ReadCommitted));
            }
            catch { connection.Dispose(); throw; }
        }
    }

    public class SqlAuthStoreDisposableTests
    {
        private static readonly SqlRuntimeOptions Options = new SqlRuntimeOptions();
        private static readonly DisposableTransactions Transactions = new DisposableTransactions();
        private static byte[] Hash(string value) { using (var sha = SHA256.Create()) return sha.ComputeHash(Encoding.UTF8.GetBytes(value)); }
        private static byte[] Secret() { var b = new byte[32]; using (var r = RandomNumberGenerator.Create()) r.GetBytes(b); return b; }
        private sealed class Sender : IOtpSender { public bool IsSynthetic => false; public Task<OtpDeliveryStatus> SendAsync(OtpDelivery d, CancellationToken ct) => Task.FromResult(OtpDeliveryStatus.Sent); }

        private sealed class Seed
        {
            public BrokerageScope Scope; public CustomerLinkRecord Customer; public RequestContextRecord Request;
        }
        private static async Task<Seed> SeedAsync(string tag)
        {
            var scope = new BrokerageScope("TEST-BROKERAGE", "D" + Guid.NewGuid().ToString("N").Substring(0, 12) + "_" + tag);
            using (var tx = await Transactions.BeginAsync(CancellationToken.None))
            {
                var customer = (await new SqlCustomerLinkRepository(Options).GetOrCreateAsync(tx, scope, "TEST-CUSTOMER-001", CancellationToken.None)).Record;
                var request = (await new SqlRequestContextRepository(Options).GetOrCreateAsync(tx, new BrokerageRequestReference(scope, "TEST-REQUEST-001"), customer,
                    new RequestMetadata(RequestEligibility.Eligible, "TEST-V1", DateTimeOffset.UtcNow), CancellationToken.None)).Record;
                tx.Commit(CancellationToken.None);
                return new Seed { Scope = scope, Customer = customer, Request = request };
            }
        }
        private static async Task CleanupAsync(BrokerageScope scope, params byte[][] rateKeys)
        {
            using (var c = new SqlConnection(DisposableTransactions.ConnectionString))
            {
                await c.OpenAsync();
                using (var cmd = c.CreateCommand())
                {
                    cmd.CommandText = @"DELETE FROM dbo.BAZDIDCustomerSessions WHERE SourceSystem=@S; DELETE FROM dbo.BAZDIDOtpChallenges WHERE SourceSystem=@S;
DELETE FROM dbo.BAZDIDAuditLogs WHERE SourceSystem=@S; DELETE FROM dbo.BAZDIDRequestContexts WHERE SourceSystem=@S; DELETE FROM dbo.BAZDIDCustomerLinks WHERE SourceSystem=@S;";
                    cmd.Parameters.AddWithValue("@S", scope?.SourceSystem ?? "-");
                    await cmd.ExecuteNonQueryAsync();
                    foreach (var key in rateKeys)
                    {
                        cmd.Parameters.Clear(); cmd.CommandText = "DELETE FROM dbo.BAZDIDAuthRateCounters WHERE KeyHash=@K;";
                        cmd.Parameters.Add("@K", SqlDbType.Binary, 32).Value = key; await cmd.ExecuteNonQueryAsync();
                    }
                }
            }
        }
        private static OtpChallenge NewChallenge(Seed seed, string handle, byte[] nonce) =>
            new OtpChallenge(handle, seed.Request.Id, nonce, DateTimeOffset.UtcNow.AddMinutes(5)) { Scope = seed.Scope };

        [DisposableSqlFact]
        public async Task Challenge_store_uses_handle_hash_conditional_save_and_tenant_check()
        {
            var seed = await SeedAsync("CH");
            try
            {
                var store = new SqlOtpChallengeStore(Transactions, Options);
                var handle = OtpCodeGenerator.NewOpaqueId(); var nonce = Hash("nonce-1");
                Assert.True(await store.TryCreateAsync(NewChallenge(seed, handle, nonce), CancellationToken.None));
                var found = await store.FindAsync(handle, CancellationToken.None);
                Assert.Equal(OtpChallengeState.Resolved, found.State); Assert.Equal(seed.Scope, found.Scope); Assert.Equal(nonce, found.BrowserNonceHash);
                Assert.Null(await store.FindAsync(OtpCodeGenerator.NewOpaqueId(), CancellationToken.None));
                using (var c = new SqlConnection(DisposableTransactions.ConnectionString))
                {
                    await c.OpenAsync(); var cmd = c.CreateCommand();
                    cmd.CommandText = "SELECT HandleHash FROM dbo.BAZDIDOtpChallenges WHERE SourceSystem=@S"; cmd.Parameters.AddWithValue("@S", seed.Scope.SourceSystem);
                    Assert.Equal(Hash(handle), (byte[])await cmd.ExecuteScalarAsync());
                }
                var first = found.Copy(); first.FailedAttempts = 1;
                Assert.True(await store.TrySaveAsync(first, found.Version, CancellationToken.None));
                var stale = found.Copy(); stale.FailedAttempts = 3;
                Assert.False(await store.TrySaveAsync(stale, found.Version, CancellationToken.None));
                Assert.Equal(1, (await store.FindAsync(handle, CancellationToken.None)).FailedAttempts);
                var foreign = NewChallenge(seed, OtpCodeGenerator.NewOpaqueId(), nonce); foreign.Scope = new BrokerageScope("TEST-BROKERAGE", "OTHER_TENANT");
                Assert.Equal(PersistenceFailure.OwnershipConflict, (await Assert.ThrowsAsync<PersistenceException>(() => store.TryCreateAsync(foreign, CancellationToken.None))).Failure);
            }
            finally { await CleanupAsync(seed.Scope); }
        }

        [DisposableSqlFact]
        public async Task Otp_service_on_sql_store_consumes_exactly_once_under_concurrency()
        {
            var seed = await SeedAsync("SV");
            try
            {
                var store = new SqlOtpChallengeStore(Transactions, Options);
                var handle = OtpCodeGenerator.NewOpaqueId(); var nonce = Hash("nonce-2");
                await store.TryCreateAsync(NewChallenge(seed, handle, nonce), CancellationToken.None);
                var service = new OtpChallengeService(store, new Sender(), new OtpMac(Secret()), new OtpPolicy(), new SystemClock(), _ => "48213");
                Assert.Equal(OtpIssueOutcome.Issued, (await service.IssueAsync(handle, nonce, CancellationToken.None)).Outcome);
                Assert.Equal(OtpVerifyOutcome.InvalidCode, await service.VerifyAsync(handle, nonce, "00000", CancellationToken.None));
                Assert.Equal(OtpVerifyOutcome.BrowserMismatch, await service.VerifyAsync(handle, Hash("other"), "48213", CancellationToken.None));
                var results = await Task.WhenAll(Enumerable.Range(0, 8).Select(_ => Task.Run(() => service.VerifyAsync(handle, nonce, "48213", CancellationToken.None))));
                Assert.Equal(1, results.Count(r => r == OtpVerifyOutcome.Verified));
                var row = await store.FindAsync(handle, CancellationToken.None);
                Assert.Equal(OtpChallengeState.Consumed, row.State); Assert.Null(row.CodeMac); Assert.Equal(1, row.FailedAttempts);
            }
            finally { await CleanupAsync(seed.Scope); }
        }

        [DisposableSqlFact]
        public async Task Session_lifecycle_blocks_replay_and_cross_tenant_and_revokes_once()
        {
            var seed = await SeedAsync("SE"); var other = await SeedAsync("OT");
            try
            {
                var challenges = new SqlOtpChallengeStore(Transactions, Options); var sessions = new SqlCustomerSessionStore(Transactions, Options);
                var handle = OtpCodeGenerator.NewOpaqueId(); var nonce = Hash("nonce-3");
                await challenges.TryCreateAsync(NewChallenge(seed, handle, nonce), CancellationToken.None);
                var challenge = await challenges.FindAsync(handle, CancellationToken.None);
                var now = DateTimeOffset.UtcNow;
                CustomerSession New(Guid customer) => new CustomerSession { HandleHash = Hash(OtpCodeGenerator.NewOpaqueId()), Scope = seed.Scope, RequestContextId = seed.Request.Id,
                    CustomerLinkId = customer, OtpChallengeId = challenge.Id, AuthenticatedAtUtc = now, IdleExpiresAtUtc = now.AddMinutes(30), AbsoluteExpiresAtUtc = now.AddHours(8) };
                // چالش هنوز مصرف نشده است.
                Assert.Equal(PersistenceFailure.OwnershipConflict, (await Assert.ThrowsAsync<PersistenceException>(() => sessions.CreateAsync(New(seed.Customer.Id), CancellationToken.None))).Failure);
                var consumed = challenge.Copy(); consumed.State = OtpChallengeState.Consumed; consumed.ConsumedAtUtc = now;
                Assert.True(await challenges.TrySaveAsync(consumed, challenge.Version, CancellationToken.None));
                // مشتری tenant دیگر رد می‌شود.
                Assert.Equal(PersistenceFailure.OwnershipConflict, (await Assert.ThrowsAsync<PersistenceException>(() => sessions.CreateAsync(New(other.Customer.Id), CancellationToken.None))).Failure);
                var session = New(seed.Customer.Id);
                await sessions.CreateAsync(session, CancellationToken.None);
                // replay همان چالش: نشست دوم ساخته نمی‌شود.
                Assert.Equal(PersistenceFailure.DuplicateConflict, (await Assert.ThrowsAsync<PersistenceException>(() => sessions.CreateAsync(New(seed.Customer.Id), CancellationToken.None))).Failure);
                var loaded = await sessions.FindByHandleHashAsync(session.HandleHash, CancellationToken.None);
                Assert.True(loaded.IsActive(now)); Assert.False(loaded.IsActive(now.AddMinutes(31))); Assert.False(loaded.IsActive(now.AddHours(9)));
                Assert.True(await sessions.TryTouchAsync(loaded.Id, loaded.Version, now.AddMinutes(1), now.AddHours(20), CancellationToken.None));
                var touched = await sessions.FindByHandleHashAsync(session.HandleHash, CancellationToken.None);
                Assert.Equal(touched.AbsoluteExpiresAtUtc, touched.IdleExpiresAtUtc); // idle هرگز از absolute بیشتر نمی‌شود.
                Assert.False(await sessions.TryTouchAsync(loaded.Id, loaded.Version, now.AddMinutes(2), now.AddMinutes(32), CancellationToken.None));
                Assert.True(await sessions.TryRevokeAsync(loaded.Id, "Logout", now.AddMinutes(3), CancellationToken.None));
                Assert.False(await sessions.TryRevokeAsync(loaded.Id, "Logout", now.AddMinutes(4), CancellationToken.None));
                var revoked = await sessions.FindByHandleHashAsync(session.HandleHash, CancellationToken.None);
                Assert.Equal("Logout", revoked.RevokeReason); Assert.False(revoked.IsActive(now.AddMinutes(5)));
                Assert.False(await sessions.TryTouchAsync(revoked.Id, revoked.Version, now.AddMinutes(5), now.AddMinutes(35), CancellationToken.None));
                Assert.Null(await sessions.FindByHandleHashAsync(Hash("unknown"), CancellationToken.None));
            }
            finally { await CleanupAsync(seed.Scope); await CleanupAsync(other.Scope); }
        }

        [DisposableSqlFact]
        public async Task Rate_limiter_is_atomic_across_concurrent_hits_and_resets_after_window()
        {
            var key = Hash("rate-" + Guid.NewGuid());
            try
            {
                var limiter = new SqlAuthRateLimiter(Transactions, Options);
                var now = new DateTimeOffset(DateTime.UtcNow.Ticks / TimeSpan.TicksPerMillisecond * TimeSpan.TicksPerMillisecond, TimeSpan.Zero);
                var decisions = await Task.WhenAll(Enumerable.Range(0, 10).Select(_ => Task.Run(() => limiter.HitAsync("otp-request", key, 3, TimeSpan.FromMinutes(15), now, CancellationToken.None))));
                Assert.Equal(3, decisions.Count(d => d.Allowed));
                Assert.All(decisions.Where(d => !d.Allowed), d => Assert.True(d.RetryAfter > TimeSpan.FromMinutes(14)));
                Assert.True((await limiter.HitAsync("otp-request", key, 3, TimeSpan.FromMinutes(15), now.AddMinutes(15), CancellationToken.None)).Allowed);
                await Assert.ThrowsAsync<PersistenceException>(() => limiter.HitAsync("not-a-scope", key, 3, TimeSpan.FromMinutes(1), now, CancellationToken.None));
            }
            finally { await CleanupAsync(null, key); }
        }
    }
}
