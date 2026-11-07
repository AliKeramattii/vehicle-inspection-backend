# Checkpoint 3 — OTP و نشست (در حال اجرا)

تاریخ شروع: `2026-11-07`. **وضعیت: برش اول (منطق دامنه) و برش دوم (migration `0002` و storeهای SQL، با rehearsal واقعی روی پایگاه یک‌بارمصرف) پیاده و آزموده شدند. endpointها، cookie، CSRF و اعمال روی `BAZDID_Development` هنوز انجام نشده‌اند. Checkpoint 3 کامل نیست و پیشرفت 24% می‌ماند.** مرجع طراحی: [AUTH_AND_SESSION_FA.md](../AUTH_AND_SESSION_FA.md).

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

<a id="slice2"></a>

## ۷. برش دوم — migration `0002_otp_session` و storeهای SQL (2026-11-07)

شاهد: [MIGRATION_0002_REHEARSAL.json](../checkpoint3/MIGRATION_0002_REHEARSAL.json). مجوز: rehearsal فقط روی `BAZDID_MigrationTest` (مالک)؛ اعمال روی `BAZDID_Development` و تغییر GRANT مجاز **نشده‌اند**.

### ۷.۱ schema

[0002_otp_session.forward.sql](../../database/migrations/0002_otp_session.forward.sql) و [revert](../../database/migrations/0002_otp_session.revert.sql):

| جدول | نکات امنیتی |
| --- | --- |
| `BAZDIDOtpChallenges` | `HandleHash` = SHA-256 handle (UQ)؛ handle خام، کد یا موبایل ذخیره نمی‌شود. `CodeMac` و hash nonce مرورگر؛ FK به RequestContext؛ CHECKهای tenant، حالت، شمارنده‌ها، سازگاری کد و مصرف؛ rowversion |
| `BAZDIDCustomerSessions` | `HandleHash` (UQ)؛ **`UQ_BAZDIDCustomerSessions_Challenge`: هر چالش حداکثر یک نشست (ضد replay در خود پایگاه)**؛ FK مرکب `(BrokerageId,SourceSystem,CustomerLinkId)` به CustomerLinks (جداسازی tenant)؛ CHECK زمان (idle ≤ absolute) و دلیل ابطال؛ rowversion |
| `BAZDIDAuthRateCounters` | PK `(Scope, KeyHash)`؛ کلید همیشه hash است؛ Scopeهای مجاز با CHECK |

- **forward:** پیش‌شرط `0001_baseline`؛ اجرای تکراری no-op؛ checksum نابرابر یا حالت جزئی خطا.
- **revert:** فقط روی پایگاه آزمون؛ با وجود ردیف یا migration بعدی متوقف می‌شود؛ اشیای 0001 دست‌نخورده می‌مانند.

### ۷.۲ storeها

[SqlAuthStores.cs](../../src/Bazdid.Api/Infrastructure/Sql/SqlAuthStores.cs) شامل سه store است. همهٔ دستورها پارامتری‌اند و هر عملیات در transaction کوتاه از `IBazdidTransactionFactory` اجرا می‌شود؛ در برنامه، همین factory پشت gate و guard هویت Writer است.

- **`SqlOtpChallengeStore`:**
  - lookup با hash handle؛
  - درج فقط اگر context متعلق به همان tenant باشد (`51001`)؛
  - `TrySaveAsync` به‌صورت UPDATE شرطی روی rowversion.
- **`SqlCustomerSessionStore`:**
  - درج فقط از چالش `Consumed` همان context، tenant و مشتری؛
  - replay به `DuplicateConflict` می‌رسد؛
  - `TryTouchAsync` شرطی است و idle را تا absolute محدود می‌کند؛
  - `TryRevokeAsync` اتمیک است و فقط یک بار true برمی‌گرداند.
- **`SqlAuthRateLimiter`:** قفل `UPDLOCK,HOLDLOCK` روی کلید، پنجرهٔ زمانی و `RetryAfter`.

قرارداد دامنه گسترش یافت: `OtpChallenge.Id/Scope`، `IOtpChallengeStore.TryCreateAsync`، `CustomerSession`، `ICustomerSessionStore`، `IAuthRateLimiter`.

### ۷.۳ اجرای واقعی

```powershell
# اجرا شد — cwd: ریشهٔ مخزن، هویت مالک، فقط BAZDID_MigrationTest
.\database\tools\Invoke-BazdidMigration.ps1 -Action Accept -ApproveDisposableDatabase -ApprovalReference OWNER-2026-11-07-CP3-0002-REHEARSAL -EvidencePath .\docs\checkpoint3\MIGRATION_0002_REHEARSAL.json
```

خطاهای واقعی و رفع آن‌ها:

1. خطوط stderr فرمان `dotnet test` در PS 5.1 با `ErrorActionPreference=Stop` به خطای پایان‌دهنده تبدیل می‌شدند. فقط برای همان فراخوانی `Continue` شد.
2. `TryCreateAsync` با `SET NOCOUNT ON` همیشه false برمی‌گرداند، چون شمار ردیف `-1` بود. NOCOUNT حذف شد. در هر دو اجرای ناموفق، پایگاه پس از اثبات حذف شد.

اجرای نهایی: **۳۷ گام PASS**.

- همهٔ گام‌های 0001 تکرار شدند.
- 0002 بدون 0001 رد شد.
- 0002 forward انجام شد و همهٔ اشیای نام‌دار حاضر بودند.
- تکرار 0002 no-op بود و checksum نادرست رد شد.
- revert 0001 هنگام حضور 0002 رد شد.
- **۴ از ۴ آزمون store روی SQL واقعی موفق بودند:**
  - `Challenge_store_uses_handle_hash_conditional_save_and_tenant_check`
  - `Otp_service_on_sql_store_consumes_exactly_once_under_concurrency`
  - `Session_lifecycle_blocks_replay_and_cross_tenant_and_revokes_once`
  - `Rate_limiter_is_atomic_across_concurrent_hits_and_resets_after_window`
- آزمون‌ها هیچ ردیفی باقی نگذاشتند.
- revert 0002 با وجود داده رد شد. revert انجام شد، schema 0001 سالم ماند و revert تکراری no-op بود.
- بازاعمال انجام شد و تاریخچه هر دو migration را دارد.
- پایگاه حذف شد و `BAZDID_Development` بدون تغییر ماند.

regression آفلاین: build با 0 warning؛ ۱۴۶ از ۱۴۶ unit؛ در integration، ۵۰ موفق و ۱۷ Skipped (۱۳ متصل و ۴ store که فقط با انتخاب صریح اجرا می‌شوند).

### ۷.۴ آمادهٔ تصویب (اجرا نشده)

- **migration روی `BAZDID_Development`:**
  - `0001_baseline` در حالت `Adopted` (فقط ثبت تاریخچه و ساخت `BAZDIDSchemaMigrations`، بدون DDL روی سه جدول)؛
  - `0002_otp_session` در حالت `Created` (سه جدول، ۳ index و قیدهای فهرست‌شده در گام ۲۴).
  - action محافظ `ApplyDevelopment` در runner پس از تصویب افزوده و همان‌جا آزموده می‌شود، با snapshot قبل/بعد و بدون revert روی Development.
- **GRANT:** [0002_auth_grants.review.sql](../../database/proposals/0002_auth_grants.review.sql) (hash `83E7C02D…701C`):
  - Writer روی سه جدول: SELECT/INSERT/UPDATE، و DENY برای DELETE/ALTER؛
  - Reader: DENY همه؛
  - کاتالوگ P2 از ۴۰ به ۷۰ ردیف می‌رسد و انتظار runner مربوط به P2 همزمان به‌روز می‌شود.

| فایل | SHA-256 |
| --- | --- |
| `0002_otp_session.forward.sql` | `544D33CB343DC9A6DCF3503603553D66F3F3AABC3648C800933DFF6173A00248` |
| `0002_otp_session.revert.sql` | `66DDDD5A6129E1B425ED8E8540B18D056AAA06BAFAB1BBE16347FC997956F71C` |
| `0002_auth_grants.review.sql` | `83E7C02DD73FE3E7A6E9B1052F0EB2B1DB2C040B589A5431F352E6C8042A701C` |
| `Invoke-BazdidMigration.ps1` | `5517F9463054D1622C194FB0A430B9A8DB983D05089CD25A2FE277B8508D8A7B` |

### ۷.۵ باقی‌ماندهٔ Checkpoint 3

1. endpointهای `GET auth/csrf`، `POST referrals/validate`، `POST auth/otp/request`، `POST auth/otp/verify`، `GET me` و `POST auth/logout`.
2. cookie نشست و nonce مرورگر، `ITicketStore`، CSRF، rate limit در مسیرها و پاسخ‌های عمومی.
3. آزمون HTTP با TestServer.
4. اعمال روی Development، GRANT و اجرای متصل با Writer.

**وابستگی بیرونی:** قرارداد واقعی کد معرفی، موبایل و پیامک کارگزاری مشخص نیست. تا آن زمان فقط adapter ساختگی Development/Testing فعال است و خارج از آن fail-closed.

**24% + 0 = 24%.**
