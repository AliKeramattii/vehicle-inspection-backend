# Checkpoint 3 — OTP و نشست (در حال اجرا)

تاریخ شروع: `2026-11-07`. **وضعیت: برش اول (منطق دامنهٔ OTP) پیاده و آزموده شد. Checkpoint 3 کامل نیست و پیشرفت 24% می‌ماند.** مرجع طراحی: [AUTH_AND_SESSION_FA.md](../AUTH_AND_SESSION_FA.md).

## ۱. مجوز و دامنهٔ این برش

مالک پس از پذیرش 2G دستور داد Checkpoint 3 با قراردادها، اینترفیس‌ها، سرویس‌ها، اعتبارسنجی و آزمون آغاز شود، با حفظ `netcoreapp2.1`/C# 7.3 و بدون Production.

این برش **فقط منطق دامنه** را دارد:

- بدون جدول SQL (نیازمند migration `0002_*` با مجوز جدا)؛
- بدون endpoint؛
- بدون ثبت در DI یا Startup؛
- بدون cookie، Data Protection یا CSRF.

`Authentication:Enabled=true` همچنان startup را رد می‌کند.

## ۲. فایل‌ها

| فایل | مسئولیت |
| --- | --- |
| [OtpContracts.cs](../../src/Bazdid.Api/Domain/Auth/OtpContracts.cs) | `OtpPolicy` (اعداد پیشنهادی سند و `Validate`)، `OtpChallengeState`، `OtpChallenge` (بدون کد یا موبایل خام)، نتایج issue/verify، `IOtpSender`، `IOtpChallengeStore` (Save شرطی با rowversion) و `IClock` |
| [OtpChallengeService.cs](../../src/Bazdid.Api/Application/Auth/OtpChallengeService.cs) | `OtpCodeGenerator`، `OtpMac`، `OtpChallengeService`، `OtpEnvironmentGuard` و `SyntheticOtpSender` |
| [OtpChallengeServiceTests.cs](../../tests/Bazdid.UnitTests/OtpChallengeServiceTests.cs) | ۲۶ آزمون unit با store حافظه‌ای که همان قرارداد Save شرطی را دارد |

## ۳. تصمیم‌های پیاده‌شده

- **تولید کد:** با `RandomNumberGenerator` و نمونه‌برداری ردکننده (بایت ≥۲۵۰ رد می‌شود)، تا سوگیری modulo نباشد. طول پیش‌فرض ۵ است، هم‌اندازهٔ fixture `12345`. شناسهٔ چالش ۳۲ بایت تصادفی base64url است.
- **MAC کد:** `HMAC-SHA256(secret, "BAZDID-OTP-v1" ∥ challengeId ∥ generation ∥ code)` با length-prefix در UTF-8. secret دست‌کم ۲۵۶ بیت است و از HMAC هویت جداست. کد خام فقط در `OtpDelivery` تا لحظهٔ ارسال وجود دارد و `ToString` آن را نشان نمی‌دهد.
- **مقایسهٔ ثابت‌زمان:** با پیاده‌سازی دستی، چون `CryptographicOperations` در netcoreapp2.1 وجود ندارد. کد نامعتبر هم MAC می‌شود تا مسیر زمانی یکسان بماند.
- **صدور و resend:**
  - nonce مرورگر باید برابر باشد؛
  - context منقضی رد می‌شود؛
  - فاصلهٔ resend ۶۰ ثانیه است، با `RetryAfter`؛
  - سقف ۵ ارسال در ۱۵ دقیقه؛
  - نسل تازه نسل قبلی را باطل می‌کند و شمار تلاش‌های ناموفق را صفر نمی‌کند؛
  - اگر ارسال شکست بخورد یا exception بدهد، MAC پاک و وضعیت `SendFailed` می‌شود و کد ارسال‌نشده قابل verify نیست.
- **verify:**
  - کد فقط عددی با طول دقیق پذیرفته می‌شود (ارقام فارسی رد می‌شوند) و ورودی نادرست شمرده می‌شود؛
  - انقضا پس از ۱۲۰ ثانیه، با پاک‌شدن MAC؛
  - قفل پس از ۵ تلاش؛
  - مصرف با Save شرطی روی Version انجام می‌شود، پس از ۱۶ verify هم‌زمان دقیقاً یکی `Verified` می‌گیرد؛
  - nonce مرورگر دیگر `BrowserMismatch` می‌گیرد و شمرده نمی‌شود.
- **fail-closed:** هر خطای store یا Save ناموفق به پاسخ منفی می‌رسد، نه دسترسی.
- **fixture:** `OtpEnvironmentGuard` sender ساختگی یا flag fixture را فقط در `Development`/`Testing` و آن هم با flag صریح می‌پذیرد و در هر محیط دیگری (حتی `production` با حروف کوچک) خطا می‌دهد. `SyntheticOtpSender` هیچ پیامک واقعی نمی‌فرستد. fallback وجود ندارد.

## ۴. آزمون‌ها (اجرای تازه)

```powershell
# اجرا شد — cwd: ریشهٔ مخزن
dotnet build Bazdid.sln --configuration Release --no-restore      # 0 warning، 0 error
dotnet test Bazdid.sln --configuration Release --no-build --no-restore
```

نتیجه: ۱۴۶ از ۱۴۶ آزمون unit موفق (۱۲۰ قبلی و ۲۶ تازهٔ OTP). در integration، ۵۰ موفق و ۱۳ متصلِ انتخاب‌نشده Skipped.

## ۵. باقی‌ماندهٔ Checkpoint 3

1. migration `0002_otp_session` (جدول‌های `BAZDIDOtpChallenges` و `BAZDIDCustomerSessions` با rowversion)، با همان الگوی 2G، آزمون روی `BAZDID_MigrationTest` و مجوز اجرا.
2. `SqlOtpChallengeStore` و store نشست، به‌همراه آزمون متصل با هویت Writer. GRANT جدید Writer نیازمند تغییر بازبینی‌شدهٔ P2 است.
3. resolution referral → context (پاسخ عمومی، nonce مرورگر، موبایل پوشانده) روی `IBrokerageRequestReader`.
4. نشست سروری: cookie `BAZDID.Customer` (`HttpOnly`، `Secure`، `Path=/API/BAZDID`، `SameSite=Lax`)، `ITicketStore`، idle ۳۰ دقیقه و absolute ۸ ساعت، logout و ابطال.
5. CSRF با `auth/csrf`، rate limit بین instanceها روی SQL، و endpointها با `401`/`403`/`429`.
6. ثبت در DI با `OtpEnvironmentGuard` در startup و آزمون ترکیب‌های محیط/flag.

**تصمیم‌های باز:** همهٔ اعداد policy پیشنهادی‌اند و تصویب امنیت/محصول را لازم دارند. قرارداد سرویس پیامک کارگزاری هم مشخص نیست (آیا فقط verify خارجی دارد یا نه).

## ۶. پیشرفت

**24% + سهم 0 = 24%.** برش اول کار ناتمام است و امتیاز ندارد. وزن Checkpoint 3 برابر 12% است.
