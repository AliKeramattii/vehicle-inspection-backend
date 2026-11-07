using System;
using System.Threading;
using System.Threading.Tasks;
using Bazdid.Api.Domain.Brokerage;
using Bazdid.Api.Domain.Persistence;

namespace Bazdid.Api.Domain.Auth
{
    // Checkpoint 3 (برش اول): قراردادهای دامنهٔ OTP مطابق docs/AUTH_AND_SESSION_FA.md.
    // اعداد سیاست «پیشنهاد اولیه» سند طراحی‌اند و policy مصوب Production نیستند.
    public sealed class OtpPolicy
    {
        public int CodeLength { get; set; } = 5;
        public TimeSpan CodeLifetime { get; set; } = TimeSpan.FromSeconds(120);
        public int MaxAttemptsPerChallenge { get; set; } = 5;
        public TimeSpan ResendInterval { get; set; } = TimeSpan.FromSeconds(60);
        public int MaxSendsPerWindow { get; set; } = 5;
        public TimeSpan SendWindow { get; set; } = TimeSpan.FromMinutes(15);
        public TimeSpan ContextLifetime { get; set; } = TimeSpan.FromMinutes(5);

        public void Validate()
        {
            if (CodeLength < 5 || CodeLength > 8) throw new InvalidOperationException("طول OTP خارج از بازهٔ مجاز است.");
            if (CodeLifetime < TimeSpan.FromSeconds(30) || CodeLifetime > TimeSpan.FromMinutes(10)) throw new InvalidOperationException("عمر OTP خارج از بازه است.");
            if (MaxAttemptsPerChallenge < 1 || MaxAttemptsPerChallenge > 10) throw new InvalidOperationException("سقف تلاش خارج از بازه است.");
            if (ResendInterval < TimeSpan.FromSeconds(30) || ResendInterval > CodeLifetime) throw new InvalidOperationException("فاصلهٔ resend نامعتبر است.");
            if (MaxSendsPerWindow < 1 || MaxSendsPerWindow > 10 || SendWindow < TimeSpan.FromMinutes(1) || SendWindow > TimeSpan.FromHours(24))
                throw new InvalidOperationException("سقف ارسال یا پنجرهٔ آن نامعتبر است.");
            if (ContextLifetime < TimeSpan.FromMinutes(1) || ContextLifetime > TimeSpan.FromMinutes(30)) throw new InvalidOperationException("عمر context نامعتبر است.");
        }
    }

    public enum OtpChallengeState { Resolved, PendingSend, Sent, Consumed, Expired, Locked, SendFailed, Superseded }

    /// <summary>
    /// وضعیت پایدار یک چالش. کد خام هرگز اینجا نیست؛ فقط MAC نسل جاری.
    /// موبایل خام هم نیست؛ مرجع موبایل trusted از adapter مبدأ و context درخواست می‌آید.
    /// </summary>
    public sealed class OtpChallenge
    {
        public OtpChallenge(string challengeId, Guid requestContextId, byte[] browserNonceHash, DateTimeOffset contextExpiresAtUtc)
        {
            if (string.IsNullOrWhiteSpace(challengeId) || challengeId.Length < 22) throw new ArgumentException("شناسهٔ چالش opaque و کافی لازم است.", nameof(challengeId));
            if (browserNonceHash == null || browserNonceHash.Length != 32) throw new ArgumentException("hash nonce مرورگر ۳۲ بایت لازم است.", nameof(browserNonceHash));
            ChallengeId = challengeId; RequestContextId = requestContextId;
            BrowserNonceHash = (byte[])browserNonceHash.Clone(); ContextExpiresAtUtc = contextExpiresAtUtc;
            State = OtpChallengeState.Resolved;
        }
        /// <summary>handle خام opaque؛ فقط در حافظه/پاسخ. در SQL فقط SHA-256 آن (HandleHash) ذخیره می‌شود.</summary>
        public string ChallengeId { get; }
        public Guid Id { get; set; } = Guid.NewGuid();
        public BrokerageScope Scope { get; set; }
        public Guid RequestContextId { get; }
        public byte[] BrowserNonceHash { get; }
        public DateTimeOffset ContextExpiresAtUtc { get; }
        public OtpChallengeState State { get; set; }
        public int Generation { get; set; }
        public byte[] CodeMac { get; set; }
        public DateTimeOffset? CodeExpiresAtUtc { get; set; }
        public int FailedAttempts { get; set; }
        public DateTimeOffset? LastSentAtUtc { get; set; }
        public DateTimeOffset? SendWindowStartUtc { get; set; }
        public int SendsInWindow { get; set; }
        public DateTimeOffset? ConsumedAtUtc { get; set; }
        public RowVersionToken Version { get; set; }

        public OtpChallenge Copy()
        {
            return new OtpChallenge(ChallengeId, RequestContextId, BrowserNonceHash, ContextExpiresAtUtc)
            {
                Id = Id, Scope = Scope, State = State, Generation = Generation, CodeMac = CodeMac == null ? null : (byte[])CodeMac.Clone(), CodeExpiresAtUtc = CodeExpiresAtUtc,
                FailedAttempts = FailedAttempts, LastSentAtUtc = LastSentAtUtc, SendWindowStartUtc = SendWindowStartUtc, SendsInWindow = SendsInWindow,
                ConsumedAtUtc = ConsumedAtUtc, Version = Version
            };
        }
    }

    public enum OtpIssueOutcome { Issued, ResendTooSoon, SendLimitReached, ContextExpired, NotIssuable }
    public enum OtpVerifyOutcome { Verified, InvalidCode, CodeExpired, Locked, AlreadyConsumed, NotActive, BrowserMismatch, ConcurrencyConflict }

    public sealed class OtpIssueResult
    {
        public OtpIssueResult(OtpIssueOutcome outcome, TimeSpan? retryAfter = null) { Outcome=outcome; RetryAfter=retryAfter; }
        public OtpIssueOutcome Outcome { get; }
        public TimeSpan? RetryAfter { get; }
    }

    public sealed class OtpDelivery
    {
        public OtpDelivery(string challengeId, int generation, Guid requestContextId, string code)
        { ChallengeId=challengeId; Generation=generation; RequestContextId=requestContextId; Code=code; }
        public string ChallengeId { get; }
        public int Generation { get; }
        public Guid RequestContextId { get; }
        /// <summary>کد خام فقط تا فراخوانی ارسال در حافظه است؛ در log، پاسخ یا SQL نمی‌آید.</summary>
        public string Code { get; }
        public override string ToString() => "OtpDelivery(" + ChallengeId + ", gen " + Generation + ")";
    }

    public enum OtpDeliveryStatus { Sent, Failed, Blocked }

    /// <summary>ارسال کد. مرجع verify و مصرف چالش خود BAZDID است، نه سرویس پیامک.</summary>
    public interface IOtpSender
    {
        bool IsSynthetic { get; }
        Task<OtpDeliveryStatus> SendAsync(OtpDelivery delivery, CancellationToken cancellationToken);
    }

    /// <summary>ذخیرهٔ چالش. Save فقط با Version مورد انتظار موفق است (UPDATE شرطی با rowversion).</summary>
    public interface IOtpChallengeStore
    {
        Task<OtpChallenge> FindAsync(string challengeId, CancellationToken cancellationToken);
        Task<bool> TryCreateAsync(OtpChallenge challenge, CancellationToken cancellationToken);
        Task<bool> TrySaveAsync(OtpChallenge challenge, RowVersionToken expectedVersion, CancellationToken cancellationToken);
    }

    /// <summary>نشست سروری مشتری. مرورگر فقط handle تصادفی دارد؛ SQL فقط hash آن را نگه می‌دارد.</summary>
    public sealed class CustomerSession
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public byte[] HandleHash { get; set; }
        public BrokerageScope Scope { get; set; }
        public Guid RequestContextId { get; set; }
        public Guid CustomerLinkId { get; set; }
        public Guid OtpChallengeId { get; set; }
        public DateTimeOffset AuthenticatedAtUtc { get; set; }
        public DateTimeOffset LastSeenAtUtc { get; set; }
        public DateTimeOffset IdleExpiresAtUtc { get; set; }
        public DateTimeOffset AbsoluteExpiresAtUtc { get; set; }
        public DateTimeOffset? RevokedAtUtc { get; set; }
        public string RevokeReason { get; set; }
        public RowVersionToken Version { get; set; }
        public bool IsActive(DateTimeOffset now) => RevokedAtUtc == null && now < IdleExpiresAtUtc && now < AbsoluteExpiresAtUtc;
    }

    public interface ICustomerSessionStore
    {
        /// <summary>درج نشست. چالش تکراری (replay) با DuplicateConflict رد می‌شود.</summary>
        Task CreateAsync(CustomerSession session, CancellationToken cancellationToken);
        Task<CustomerSession> FindByHandleHashAsync(byte[] handleHash, CancellationToken cancellationToken);
        /// <summary>تمدید idle بدون افزایش absolute؛ شرطی روی Version و فعال‌بودن.</summary>
        Task<bool> TryTouchAsync(Guid id, RowVersionToken expectedVersion, DateTimeOffset lastSeen, DateTimeOffset idleExpires, CancellationToken cancellationToken);
        /// <summary>ابطال اتمیک؛ فقط اگر هنوز ابطال نشده باشد true.</summary>
        Task<bool> TryRevokeAsync(Guid id, string reason, DateTimeOffset now, CancellationToken cancellationToken);
    }

    public sealed class RateDecision
    {
        public RateDecision(bool allowed, TimeSpan retryAfter) { Allowed = allowed; RetryAfter = retryAfter; }
        public bool Allowed { get; }
        public TimeSpan RetryAfter { get; }
    }

    /// <summary>شمارندهٔ نرخ مشترک و پایدار بین instanceها. کلید همیشه hash است، نه IP/موبایل خام.</summary>
    public interface IAuthRateLimiter
    {
        Task<RateDecision> HitAsync(string scope, byte[] keyHash, int limit, TimeSpan window, DateTimeOffset now, CancellationToken cancellationToken);
    }

    public interface IClock { DateTimeOffset UtcNow { get; } }
    public sealed class SystemClock : IClock { public DateTimeOffset UtcNow => DateTimeOffset.UtcNow; }
}
