using System;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Bazdid.Api.Domain.Auth;
using Bazdid.Api.Domain.Persistence;

namespace Bazdid.Api.Application.Auth
{
    /// <summary>تولید کد عددی با RNG رمزنگاشتی و نمونه‌برداری ردکننده (بدون سوگیری modulo).</summary>
    public static class OtpCodeGenerator
    {
        public static string Generate(int length)
        {
            if (length < 5 || length > 8) throw new ArgumentOutOfRangeException(nameof(length));
            var chars = new char[length];
            var buffer = new byte[1];
            using (var rng = RandomNumberGenerator.Create())
            {
                for (var i = 0; i < length;)
                {
                    rng.GetBytes(buffer);
                    if (buffer[0] >= 250) continue; // 250 = 25 × 10؛ مقادیر بالاتر رد می‌شوند.
                    chars[i++] = (char)('0' + buffer[0] % 10);
                }
            }
            return new string(chars);
        }

        public static string NewOpaqueId()
        {
            var bytes = new byte[32];
            using (var rng = RandomNumberGenerator.Create()) rng.GetBytes(bytes);
            return Convert.ToBase64String(bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_');
        }
    }

    /// <summary>
    /// MAC کد: HMAC-SHA256(secret, v1 ∥ challengeId ∥ generation ∥ code) با length-prefix؛ hash بدون secret برای فضای کوچک OTP کافی نیست.
    /// secret از secret store جدا از HMAC هویت و Data Protection می‌آید و در Git نیست.
    /// </summary>
    public sealed class OtpMac
    {
        private readonly byte[] _secret;
        public OtpMac(byte[] secret)
        {
            if (secret == null || secret.Length < 32) throw new ArgumentException("secret OTP دست‌کم ۲۵۶ بیت لازم است.", nameof(secret));
            _secret = (byte[])secret.Clone();
        }
        public byte[] Compute(string challengeId, int generation, string code)
        {
            using (var hmac = new HMACSHA256(_secret))
            {
                var payload = Encode("BAZDID-OTP-v1", challengeId, generation.ToString(System.Globalization.CultureInfo.InvariantCulture), code);
                return hmac.ComputeHash(payload);
            }
        }
        private static byte[] Encode(params string[] fields)
        {
            using (var stream = new System.IO.MemoryStream())
            {
                foreach (var field in fields)
                {
                    var bytes = Encoding.UTF8.GetBytes(field ?? throw new ArgumentNullException(nameof(fields)));
                    var length = BitConverter.GetBytes(bytes.Length);
                    if (!BitConverter.IsLittleEndian) Array.Reverse(length);
                    stream.Write(length, 0, length.Length); stream.Write(bytes, 0, bytes.Length);
                }
                return stream.ToArray();
            }
        }
        /// <summary>مقایسهٔ ثابت‌زمان (CryptographicOperations در netcoreapp2.1 موجود نیست).</summary>
        public static bool FixedTimeEquals(byte[] left, byte[] right)
        {
            if (left == null || right == null || left.Length != right.Length) return false;
            var diff = 0;
            for (var i = 0; i < left.Length; i++) diff |= left[i] ^ right[i];
            return diff == 0;
        }
    }

    /// <summary>
    /// گذارهای چالش: صدور/resend و verify. هر تغییر با Save شرطی روی Version انجام می‌شود تا دو verify هم‌زمان
    /// دقیقاً به یک مصرف برسند. اختلال store یا ارسال هیچ‌گاه دسترسی آزاد ایجاد نمی‌کند (fail-closed).
    /// </summary>
    public sealed class OtpChallengeService
    {
        private readonly IOtpChallengeStore _store;
        private readonly IOtpSender _sender;
        private readonly OtpMac _mac;
        private readonly OtpPolicy _policy;
        private readonly IClock _clock;
        private readonly Func<int, string> _codeSource;

        public OtpChallengeService(IOtpChallengeStore store, IOtpSender sender, OtpMac mac, OtpPolicy policy, IClock clock)
            : this(store, sender, mac, policy, clock, OtpCodeGenerator.Generate) { }

        internal OtpChallengeService(IOtpChallengeStore store, IOtpSender sender, OtpMac mac, OtpPolicy policy, IClock clock, Func<int, string> codeSource)
        {
            _store = store ?? throw new ArgumentNullException(nameof(store));
            _sender = sender ?? throw new ArgumentNullException(nameof(sender));
            _mac = mac ?? throw new ArgumentNullException(nameof(mac));
            _policy = policy ?? throw new ArgumentNullException(nameof(policy));
            _policy.Validate();
            _clock = clock ?? throw new ArgumentNullException(nameof(clock));
            _codeSource = codeSource ?? throw new ArgumentNullException(nameof(codeSource));
        }

        public async Task<OtpIssueResult> IssueAsync(string challengeId, byte[] browserNonceHash, CancellationToken cancellationToken)
        {
            var current = await _store.FindAsync(challengeId, cancellationToken);
            if (current == null || !OtpMac.FixedTimeEquals(current.BrowserNonceHash, browserNonceHash)) return new OtpIssueResult(OtpIssueOutcome.NotIssuable);
            var now = _clock.UtcNow;
            if (now >= current.ContextExpiresAtUtc) return new OtpIssueResult(OtpIssueOutcome.ContextExpired);
            if (current.State == OtpChallengeState.Consumed || current.State == OtpChallengeState.Locked) return new OtpIssueResult(OtpIssueOutcome.NotIssuable);
            if (current.LastSentAtUtc.HasValue && now - current.LastSentAtUtc.Value < _policy.ResendInterval)
                return new OtpIssueResult(OtpIssueOutcome.ResendTooSoon, _policy.ResendInterval - (now - current.LastSentAtUtc.Value));

            var next = current.Copy();
            if (!next.SendWindowStartUtc.HasValue || now - next.SendWindowStartUtc.Value >= _policy.SendWindow) { next.SendWindowStartUtc = now; next.SendsInWindow = 0; }
            if (next.SendsInWindow >= _policy.MaxSendsPerWindow)
                return new OtpIssueResult(OtpIssueOutcome.SendLimitReached, _policy.SendWindow - (now - next.SendWindowStartUtc.Value));

            // نسل تازه نسل قبلی را باطل می‌کند؛ resend شمار تلاش را صفر نمی‌کند تا سقف تلاش دور زده نشود.
            var code = _codeSource(_policy.CodeLength);
            next.Generation = current.Generation + 1;
            next.CodeMac = _mac.Compute(next.ChallengeId, next.Generation, code);
            next.CodeExpiresAtUtc = now + _policy.CodeLifetime;
            next.LastSentAtUtc = now;
            next.SendsInWindow++;
            next.State = OtpChallengeState.PendingSend;
            if (!await _store.TrySaveAsync(next, current.Version, cancellationToken)) return new OtpIssueResult(OtpIssueOutcome.NotIssuable);

            var saved = await _store.FindAsync(challengeId, cancellationToken);
            OtpDeliveryStatus status;
            try { status = await _sender.SendAsync(new OtpDelivery(next.ChallengeId, next.Generation, next.RequestContextId, code), cancellationToken); }
            catch (OperationCanceledException) { throw; }
            catch (Exception) { status = OtpDeliveryStatus.Failed; }
            var after = saved.Copy();
            after.State = status == OtpDeliveryStatus.Sent ? OtpChallengeState.Sent : OtpChallengeState.SendFailed;
            if (status != OtpDeliveryStatus.Sent) after.CodeMac = null; // کد ارسال‌نشده قابل verify نیست.
            await _store.TrySaveAsync(after, saved.Version, cancellationToken);
            return new OtpIssueResult(status == OtpDeliveryStatus.Sent ? OtpIssueOutcome.Issued : OtpIssueOutcome.NotIssuable);
        }

        public async Task<OtpVerifyOutcome> VerifyAsync(string challengeId, byte[] browserNonceHash, string code, CancellationToken cancellationToken)
        {
            var current = await _store.FindAsync(challengeId, cancellationToken);
            if (current == null) return OtpVerifyOutcome.NotActive;
            if (!OtpMac.FixedTimeEquals(current.BrowserNonceHash, browserNonceHash)) return OtpVerifyOutcome.BrowserMismatch;
            if (current.State == OtpChallengeState.Consumed) return OtpVerifyOutcome.AlreadyConsumed;
            if (current.State == OtpChallengeState.Locked) return OtpVerifyOutcome.Locked;
            if (current.State != OtpChallengeState.Sent || current.CodeMac == null || !current.CodeExpiresAtUtc.HasValue) return OtpVerifyOutcome.NotActive;
            var now = _clock.UtcNow;
            if (now >= current.CodeExpiresAtUtc.Value || now >= current.ContextExpiresAtUtc)
            {
                var expired = current.Copy(); expired.State = OtpChallengeState.Expired; expired.CodeMac = null;
                await _store.TrySaveAsync(expired, current.Version, cancellationToken);
                return OtpVerifyOutcome.CodeExpired;
            }
            var wellFormed = code != null && code.Length == _policy.CodeLength && IsDigits(code);
            var candidate = _mac.Compute(current.ChallengeId, current.Generation, wellFormed ? code : new string('x', _policy.CodeLength));
            var match = wellFormed & OtpMac.FixedTimeEquals(candidate, current.CodeMac);

            var next = current.Copy();
            if (match) { next.State = OtpChallengeState.Consumed; next.ConsumedAtUtc = now; next.CodeMac = null; }
            else
            {
                next.FailedAttempts++;
                if (next.FailedAttempts >= _policy.MaxAttemptsPerChallenge) { next.State = OtpChallengeState.Locked; next.CodeMac = null; }
            }
            // UPDATE شرطی: از دو verify هم‌زمان فقط یکی Save می‌کند؛ دیگری ConcurrencyConflict می‌گیرد و نشست نمی‌سازد.
            if (!await _store.TrySaveAsync(next, current.Version, cancellationToken)) return OtpVerifyOutcome.ConcurrencyConflict;
            if (match) return OtpVerifyOutcome.Verified;
            return next.State == OtpChallengeState.Locked ? OtpVerifyOutcome.Locked : OtpVerifyOutcome.InvalidCode;
        }

        private static bool IsDigits(string value)
        {
            foreach (var c in value) if (c < '0' || c > '9') return false;
            return true;
        }
    }

    /// <summary>
    /// fixture (`12345`) فقط در Development/Testing و با flag صریح مجاز است؛ Production با هر sender ساختگی متوقف می‌شود.
    /// هیچ fallback به fixture پس از خطای سرویس واقعی وجود ندارد.
    /// </summary>
    public static class OtpEnvironmentGuard
    {
        public const string FixtureCode = "12345";
        public static void Validate(string environment, bool fixtureEnabled, IOtpSender sender)
        {
            if (sender == null) throw new InvalidOperationException("ارسال‌کنندهٔ OTP پیکربندی نشده است.");
            var nonProduction = environment == "Development" || environment == "Testing";
            if (!nonProduction && (fixtureEnabled || sender.IsSynthetic))
                throw new InvalidOperationException("fixture یا sender ساختگی OTP فقط در Development/Testing مجاز است.");
            if (sender.IsSynthetic && !fixtureEnabled)
                throw new InvalidOperationException("sender ساختگی بدون flag صریح fixture مجاز نیست.");
        }
    }

    /// <summary>sender ساختگی Development/Testing: هیچ پیامک واقعی نمی‌فرستد و کد را جایی ثبت نمی‌کند.</summary>
    public sealed class SyntheticOtpSender : IOtpSender
    {
        public bool IsSynthetic => true;
        public Task<OtpDeliveryStatus> SendAsync(OtpDelivery delivery, CancellationToken cancellationToken)
        {
            cancellationToken.ThrowIfCancellationRequested();
            return Task.FromResult(OtpDeliveryStatus.Sent);
        }
    }
}
