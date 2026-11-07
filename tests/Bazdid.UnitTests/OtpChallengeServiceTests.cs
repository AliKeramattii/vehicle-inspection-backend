using System;
using System.Collections.Concurrent;
using System.Linq;
using System.Security.Cryptography;
using System.Threading;
using System.Threading.Tasks;
using Bazdid.Api.Application.Auth;
using Bazdid.Api.Domain.Auth;
using Bazdid.Api.Domain.Persistence;
using Xunit;

namespace Bazdid.UnitTests
{
    // Checkpoint 3 برش اول: منطق چالش OTP بدون SQL/HTTP. store حافظه‌ای فقط برای آزمون است و همان قرارداد Save شرطی را دارد.
    public class OtpChallengeServiceTests
    {
        private sealed class Clock : IClock { public DateTimeOffset UtcNow { get; set; } = new DateTimeOffset(2026, 11, 7, 12, 0, 0, TimeSpan.Zero); }
        private sealed class Store : IOtpChallengeStore
        {
            private readonly ConcurrentDictionary<string, OtpChallenge> _rows = new ConcurrentDictionary<string, OtpChallenge>();
            private long _version;
            private readonly object _gate = new object();
            public void Add(OtpChallenge challenge) { challenge.Version = Next(); _rows[challenge.ChallengeId] = challenge.Copy(); }
            private RowVersionToken Next() => new RowVersionToken(BitConverter.GetBytes(Interlocked.Increment(ref _version)));
            public Task<OtpChallenge> FindAsync(string id, CancellationToken ct)
            { OtpChallenge row; return Task.FromResult(_rows.TryGetValue(id, out row) ? row.Copy() : null); }
            public Task<bool> TrySaveAsync(OtpChallenge challenge, RowVersionToken expected, CancellationToken ct)
            {
                lock (_gate)
                {
                    OtpChallenge row;
                    if (!_rows.TryGetValue(challenge.ChallengeId, out row) || expected == null || !row.Version.ToArray().SequenceEqual(expected.ToArray())) return Task.FromResult(false);
                    var copy = challenge.Copy(); copy.Version = Next(); _rows[challenge.ChallengeId] = copy;
                    return Task.FromResult(true);
                }
            }
            public OtpChallenge Raw(string id) => _rows[id];
        }
        private sealed class Sender : IOtpSender
        {
            public OtpDeliveryStatus Status = OtpDeliveryStatus.Sent;
            public bool Throw;
            public OtpDelivery Last;
            public int Calls;
            public bool IsSynthetic => false;
            public Task<OtpDeliveryStatus> SendAsync(OtpDelivery delivery, CancellationToken ct)
            { Calls++; Last = delivery; if (Throw) throw new TimeoutException("sms"); return Task.FromResult(Status); }
        }

        private static readonly byte[] Nonce = SHA256.Create().ComputeHash(new byte[] { 1, 2, 3 });
        private static readonly byte[] OtherNonce = SHA256.Create().ComputeHash(new byte[] { 9 });
        private static byte[] Secret() { var b = new byte[32]; using (var r = RandomNumberGenerator.Create()) r.GetBytes(b); return b; }

        private static (OtpChallengeService Service, Store Store, Clock Clock, Sender Sender, string Id) Create(Func<int, string> codes = null)
        {
            var store = new Store(); var clock = new Clock(); var sender = new Sender();
            var id = OtpCodeGenerator.NewOpaqueId();
            store.Add(new OtpChallenge(id, Guid.NewGuid(), Nonce, clock.UtcNow + TimeSpan.FromMinutes(5)));
            var service = new OtpChallengeService(store, sender, new OtpMac(Secret()), new OtpPolicy(), clock, codes ?? OtpCodeGenerator.Generate);
            return (service, store, clock, sender, id);
        }

        [Fact]
        public void Generator_is_numeric_has_requested_length_and_is_not_constant()
        {
            var codes = Enumerable.Range(0, 200).Select(_ => OtpCodeGenerator.Generate(5)).ToList();
            Assert.All(codes, c => { Assert.Equal(5, c.Length); Assert.True(c.All(char.IsDigit)); });
            Assert.True(codes.Distinct().Count() > 150);
            Assert.Throws<ArgumentOutOfRangeException>(() => OtpCodeGenerator.Generate(4));
            Assert.True(OtpCodeGenerator.NewOpaqueId().Length >= 43);
        }

        [Fact]
        public void Mac_binds_challenge_generation_and_code_and_requires_strong_secret()
        {
            var mac = new OtpMac(Secret());
            var a = mac.Compute("challenge-aaaaaaaaaaaaaaaaaaaaa", 1, "12345");
            Assert.Equal(32, a.Length);
            Assert.True(OtpMac.FixedTimeEquals(a, mac.Compute("challenge-aaaaaaaaaaaaaaaaaaaaa", 1, "12345")));
            Assert.False(OtpMac.FixedTimeEquals(a, mac.Compute("challenge-aaaaaaaaaaaaaaaaaaaaa", 2, "12345")));
            Assert.False(OtpMac.FixedTimeEquals(a, mac.Compute("challenge-bbbbbbbbbbbbbbbbbbbbb", 1, "12345")));
            Assert.False(OtpMac.FixedTimeEquals(a, mac.Compute("challenge-aaaaaaaaaaaaaaaaaaaaa", 1, "12346")));
            Assert.False(OtpMac.FixedTimeEquals(a, new OtpMac(Secret()).Compute("challenge-aaaaaaaaaaaaaaaaaaaaa", 1, "12345")));
            Assert.Throws<ArgumentException>(() => new OtpMac(new byte[16]));
            Assert.False(OtpMac.FixedTimeEquals(a, null)); Assert.False(OtpMac.FixedTimeEquals(a, new byte[31]));
        }

        [Fact]
        public async Task Issue_then_verify_consumes_once_and_stores_no_plaintext()
        {
            var t = Create(_ => "48213");
            Assert.Equal(OtpIssueOutcome.Issued, (await t.Service.IssueAsync(t.Id, Nonce, CancellationToken.None)).Outcome);
            Assert.Equal("48213", t.Sender.Last.Code);
            Assert.DoesNotContain("48213", t.Sender.Last.ToString());
            var raw = t.Store.Raw(t.Id);
            Assert.Equal(OtpChallengeState.Sent, raw.State); Assert.Equal(1, raw.Generation); Assert.Equal(32, raw.CodeMac.Length);
            Assert.Equal(OtpVerifyOutcome.Verified, await t.Service.VerifyAsync(t.Id, Nonce, "48213", CancellationToken.None));
            Assert.Equal(OtpChallengeState.Consumed, t.Store.Raw(t.Id).State); Assert.Null(t.Store.Raw(t.Id).CodeMac);
            Assert.Equal(OtpVerifyOutcome.AlreadyConsumed, await t.Service.VerifyAsync(t.Id, Nonce, "48213", CancellationToken.None));
        }

        [Fact]
        public async Task Wrong_codes_count_attempts_and_lock_at_limit_even_for_correct_code_afterwards()
        {
            var t = Create(_ => "48213");
            await t.Service.IssueAsync(t.Id, Nonce, CancellationToken.None);
            for (var i = 0; i < 4; i++) Assert.Equal(OtpVerifyOutcome.InvalidCode, await t.Service.VerifyAsync(t.Id, Nonce, "00000", CancellationToken.None));
            Assert.Equal(OtpVerifyOutcome.Locked, await t.Service.VerifyAsync(t.Id, Nonce, "abcde", CancellationToken.None));
            Assert.Equal(OtpVerifyOutcome.Locked, await t.Service.VerifyAsync(t.Id, Nonce, "48213", CancellationToken.None));
            Assert.Equal(OtpIssueOutcome.NotIssuable, (await t.Service.IssueAsync(t.Id, Nonce, CancellationToken.None)).Outcome);
        }

        [Theory]
        [InlineData(null)] [InlineData("")] [InlineData("4821")] [InlineData("482130")] [InlineData("4821a")] [InlineData("۴۸۲۱۳")]
        public async Task Malformed_codes_are_rejected_and_counted(string code)
        {
            var t = Create(_ => "48213");
            await t.Service.IssueAsync(t.Id, Nonce, CancellationToken.None);
            Assert.Equal(OtpVerifyOutcome.InvalidCode, await t.Service.VerifyAsync(t.Id, Nonce, code, CancellationToken.None));
            Assert.Equal(1, t.Store.Raw(t.Id).FailedAttempts);
        }

        [Fact]
        public async Task Expired_code_is_rejected_and_cleared()
        {
            var t = Create(_ => "48213");
            await t.Service.IssueAsync(t.Id, Nonce, CancellationToken.None);
            t.Clock.UtcNow += TimeSpan.FromSeconds(120);
            Assert.Equal(OtpVerifyOutcome.CodeExpired, await t.Service.VerifyAsync(t.Id, Nonce, "48213", CancellationToken.None));
            Assert.Equal(OtpChallengeState.Expired, t.Store.Raw(t.Id).State); Assert.Null(t.Store.Raw(t.Id).CodeMac);
        }

        [Fact]
        public async Task Resend_respects_interval_invalidates_previous_generation_and_keeps_attempts()
        {
            var codes = new[] { "11111", "22222" }; var n = 0;
            var t = Create(_ => codes[n++]);
            await t.Service.IssueAsync(t.Id, Nonce, CancellationToken.None);
            await t.Service.VerifyAsync(t.Id, Nonce, "99999", CancellationToken.None);
            var early = await t.Service.IssueAsync(t.Id, Nonce, CancellationToken.None);
            Assert.Equal(OtpIssueOutcome.ResendTooSoon, early.Outcome); Assert.Equal(TimeSpan.FromSeconds(60), early.RetryAfter);
            t.Clock.UtcNow += TimeSpan.FromSeconds(60);
            Assert.Equal(OtpIssueOutcome.Issued, (await t.Service.IssueAsync(t.Id, Nonce, CancellationToken.None)).Outcome);
            Assert.Equal(2, t.Store.Raw(t.Id).Generation); Assert.Equal(1, t.Store.Raw(t.Id).FailedAttempts);
            Assert.Equal(OtpVerifyOutcome.InvalidCode, await t.Service.VerifyAsync(t.Id, Nonce, "11111", CancellationToken.None));
            Assert.Equal(OtpVerifyOutcome.Verified, await t.Service.VerifyAsync(t.Id, Nonce, "22222", CancellationToken.None));
        }

        [Fact]
        public async Task Send_window_caps_issues_until_window_passes_or_context_expires()
        {
            var t = Create(_ => "48213");
            var service = new OtpChallengeService(t.Store, t.Sender, new OtpMac(Secret()), new OtpPolicy { MaxSendsPerWindow = 2, SendWindow = TimeSpan.FromMinutes(15) }, t.Clock, _ => "48213");
            Assert.Equal(OtpIssueOutcome.Issued, (await service.IssueAsync(t.Id, Nonce, CancellationToken.None)).Outcome);
            t.Clock.UtcNow += TimeSpan.FromSeconds(60);
            Assert.Equal(OtpIssueOutcome.Issued, (await service.IssueAsync(t.Id, Nonce, CancellationToken.None)).Outcome);
            t.Clock.UtcNow += TimeSpan.FromSeconds(60);
            var capped = await service.IssueAsync(t.Id, Nonce, CancellationToken.None);
            Assert.Equal(OtpIssueOutcome.SendLimitReached, capped.Outcome); Assert.True(capped.RetryAfter > TimeSpan.Zero);
            t.Clock.UtcNow += TimeSpan.FromMinutes(5);
            Assert.Equal(OtpIssueOutcome.ContextExpired, (await service.IssueAsync(t.Id, Nonce, CancellationToken.None)).Outcome);
        }

        [Fact]
        public async Task Other_browser_cannot_issue_or_verify()
        {
            var t = Create(_ => "48213");
            Assert.Equal(OtpIssueOutcome.NotIssuable, (await t.Service.IssueAsync(t.Id, OtherNonce, CancellationToken.None)).Outcome);
            await t.Service.IssueAsync(t.Id, Nonce, CancellationToken.None);
            Assert.Equal(OtpVerifyOutcome.BrowserMismatch, await t.Service.VerifyAsync(t.Id, OtherNonce, "48213", CancellationToken.None));
            Assert.Equal(0, t.Store.Raw(t.Id).FailedAttempts);
            Assert.Equal(OtpIssueOutcome.NotIssuable, (await t.Service.IssueAsync("unknown-challenge-id-xxxxxxxx", Nonce, CancellationToken.None)).Outcome);
        }

        [Theory]
        [InlineData(OtpDeliveryStatus.Failed, false)] [InlineData(OtpDeliveryStatus.Blocked, false)] [InlineData(OtpDeliveryStatus.Sent, true)]
        public async Task Failed_delivery_leaves_no_verifiable_code(OtpDeliveryStatus status, bool throws)
        {
            var t = Create(_ => "48213");
            t.Sender.Status = status; t.Sender.Throw = throws;
            Assert.Equal(OtpIssueOutcome.NotIssuable, (await t.Service.IssueAsync(t.Id, Nonce, CancellationToken.None)).Outcome);
            Assert.Equal(OtpChallengeState.SendFailed, t.Store.Raw(t.Id).State); Assert.Null(t.Store.Raw(t.Id).CodeMac);
            Assert.Equal(OtpVerifyOutcome.NotActive, await t.Service.VerifyAsync(t.Id, Nonce, "48213", CancellationToken.None));
        }

        [Fact]
        public async Task Concurrent_verifies_with_correct_code_consume_exactly_once()
        {
            var t = Create(_ => "48213");
            await t.Service.IssueAsync(t.Id, Nonce, CancellationToken.None);
            var results = await Task.WhenAll(Enumerable.Range(0, 16).Select(_ => Task.Run(() => t.Service.VerifyAsync(t.Id, Nonce, "48213", CancellationToken.None))));
            Assert.Equal(1, results.Count(r => r == OtpVerifyOutcome.Verified));
            Assert.All(results.Where(r => r != OtpVerifyOutcome.Verified), r => Assert.Contains(r, new[] { OtpVerifyOutcome.ConcurrencyConflict, OtpVerifyOutcome.AlreadyConsumed }));
        }

        [Theory]
        [InlineData("Production", true, false)] [InlineData("Production", false, true)] [InlineData("Staging", false, true)]
        [InlineData("Development", false, true)] [InlineData("production", true, true)]
        public void Fixture_or_synthetic_sender_outside_allowed_environments_fails_closed(string environment, bool fixture, bool synthetic)
        {
            IOtpSender sender = synthetic ? (IOtpSender)new SyntheticOtpSender() : new Sender();
            Assert.Throws<InvalidOperationException>(() => OtpEnvironmentGuard.Validate(environment, fixture, sender));
        }

        [Theory]
        [InlineData("Development")] [InlineData("Testing")]
        public void Synthetic_sender_is_allowed_only_with_explicit_fixture_flag_in_dev_or_test(string environment)
        {
            OtpEnvironmentGuard.Validate(environment, true, new SyntheticOtpSender());
            OtpEnvironmentGuard.Validate("Production", false, new Sender());
            Assert.Throws<InvalidOperationException>(() => OtpEnvironmentGuard.Validate(environment, false, null));
        }

        [Fact]
        public void Policy_rejects_unsafe_values()
        {
            new OtpPolicy().Validate();
            Assert.Throws<InvalidOperationException>(() => new OtpPolicy { CodeLength = 4 }.Validate());
            Assert.Throws<InvalidOperationException>(() => new OtpPolicy { MaxAttemptsPerChallenge = 0 }.Validate());
            Assert.Throws<InvalidOperationException>(() => new OtpPolicy { CodeLifetime = TimeSpan.FromHours(1) }.Validate());
            Assert.Throws<InvalidOperationException>(() => new OtpPolicy { ResendInterval = TimeSpan.FromMinutes(5) }.Validate());
            Assert.Throws<ArgumentException>(() => new OtpChallenge("short", Guid.NewGuid(), Nonce, DateTimeOffset.UtcNow));
            Assert.Throws<ArgumentException>(() => new OtpChallenge(OtpCodeGenerator.NewOpaqueId(), Guid.NewGuid(), new byte[8], DateTimeOffset.UtcNow));
        }
    }
}
