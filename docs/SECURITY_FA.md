# طرح امنیت و مدیریت کارکنان آینده

## وضعیت واقعی Checkpoint 1

health، خطای JSON امن، correlation سروری، logging بدون body/query/exception message، validation startup، CORS origin دقیق بدون credential، HTTPS redirect و HSTS opt-in پیاده شده‌اند. Swagger فقط Development/Testing و با منع query remote definition است؛ Production حتی با flag روشن آن را ثبت نمی‌کند. هیچ auth/cookie/CSRF/SQL/SMS/media عملیاتی وجود ندارد؛ بخش‌های مربوط زیر طرح آینده‌اند.

**audit پاک نیست:** در گراف API، ۹ بسته با ۱۰ ارتباط advisory، از جمله Critical برای Kestrel، گزارش شده‌اند. [گزارش و محدودیت‌ها](checkpoint1/DEPENDENCY_SECURITY_FA.md). پشته برای انتشار عمومی تأیید امنیتی ندارد؛ صفر warning کامپایل با صفر آسیب‌پذیری برابر نیست.

## محدودیت پشته و شرط انتشار

`netcoreapp2.1` الزام پروژه است و تغییر نمی‌کند. پایان پشتیبانی `2021-08-21` یعنی دریافت وصله‌های امنیتی و پشتیبانی این نسل متوقف شده است؛ نصب آخرین patch تاریخی یا موفقیت build آن را ایمن نمی‌کند. [اعلام رسمی Microsoft](https://devblogs.microsoft.com/dotnet/net-core-2-1-will-reach-end-of-support-on-august-21-2021/).

انتشار عمومی Production نیازمند گزارش آسیب‌پذیری dependencyها، ارزیابی امنیت واقعی، پذیرش مستند ریسک با مسئول و موعد بازبینی، محدودیت دسترسی و طرح مهاجرت است. این شرط مربوط به Production است و شروع کار مجاز Development/Test را مسدود نمی‌کند. WAF، isolation و TLS خطر runtime بدون پشتیبانی را حذف نمی‌کنند.

## تهدیدها و کنترل‌های ضروری

| تهدید | کنترل و مدرک مورد انتظار |
|---|---|
| حدس referral/OTP و افشای موبایل | masked response، پاسخ خطای حداقلی، rate limit مشترک SQL، cooldown، expiry، سقف تلاش/پنجره و audit |
| replay و race | nonce/context معتبر، generation، مصرف شرطی اتمیک OTP، نشست تازه و تست verify هم‌زمان |
| fixture در Production | DI و flag fail-closed، نبود fallback، آزمون startup و قطع خروجی SMS mock |
| جعل tenant/customer/role | scope سروری؛ owner join در همهٔ درخواست‌ها، حتی file/complete/status/receipt |
| جعل `source/readOnly` | allowlist فیلد دستی از snapshot معتبر سرور؛ رد تغییر trusted و overposting |
| سرقت/تثبیت نشست | کوکی HttpOnly/Secure، Path اختصاصی، expiry و ابطال SQL، عدم localStorage، rotate پس از OTP |
| CSRF و origin ناخواسته | antiforgery header+cookie، کنترل origin، CORS دقیق با credentials؛ بدون wildcard |
| SQL injection و دسترسی بیش‌ازحد | typed parameters، query allowlist، حساب source فقط SELECT و BAZDID فقط DML مصوب |
| path traversal و محتوای مخرب | نام سروری، containment/reparse check، stream limit، signature/decode/scan، storage غیرقابل اجرا |
| تعارض نسخه و دوباره‌ارسال | rowversion/CAS و idempotency مقید به owner/command/payload؛ قید SQL |
| file/DB ناهماهنگ | state/intent پایدار و reconcile، backup و restore هماهنگ |
| نشت خطا و PII | پیام امن، projection مشتری مستقل، redaction، عدم request-body logging حساس |
| SSRF آینده | مقصد SMS/forwarding/map از تنظیمات trusted allowlist؛ URL دلخواه مشتری ممنوع |

## رازها و دادهٔ شخصی

secret HMAC هویت، secret OTP، اعتبارنامه SQL/SMS و کلیدهای Data Protection جدا هستند. در Git و `appsettings` عمومی یا `web.config` تحویلی قرار نمی‌گیرند. تنظیمات واقعی از secret store/فایل ACLدار مصوب زیرساخت یا environment حفاظت‌شدهٔ pool دریافت شود؛ environment نیز برای مدیر میزبان قابل خواندن است و secret vault خودکار محسوب نمی‌شود. Production secret manager هنوز انتخاب نشده است.

کد OTP، کلید، cookie، header Authorization، connection string، شماره کامل، VIN کامل و مسیر فیزیکی در log، OpenAPI examples و audit ثبت نشوند. telemetry فقط correlation، outcome، resource ID داخلی و دادهٔ حداقلی لازم دارد. IP کامل یا HMAC هم دادهٔ قابل ردیابی‌اند؛ retention و سطح دسترسی آن‌ها تصویب شود. query string ورود و logging کل request/response برای endpointهای حساس ممنوع است.

موبایل برای ارسال از trusted source می‌آید؛ فقط ciphertext کوتاه‌عمر لازم در challenge ذخیره می‌شود. شناسهٔ خارجیِ موردنیاز حفظ و دسترسی آن محدود است؛ Master PII تکثیر نمی‌شود. full VIN فقط در صورت نیاز اثبات‌شده و حفاظت‌شده ذخیره شود. ذخیرهٔ محل و تصویر، دادهٔ خصوصی است و TTL عمومی خودکار ندارد. حذف با legal hold و نگهداری رسید سازگار شود.

## audit و کنترل عملیاتی

رویدادها: resolve/OTP outcome بدون مقدار کد، ایجاد/ابطال نشست، منع دسترسی، تغییر فیلد دستی، رد دستکاری trusted، create/submit، دریافت/تکمیل فایل و بعداً bootstrap/role/assignment/decision/forwarding. actor از principal سرور، زمان UTC و correlation معتبر سروری ثبت شود؛ مقدار client نمی‌تواند audit actor باشد.

audit در BAZDID append-only با اختیار نوشتن محدود باشد؛ خواندن/نگهداری و export کنترل شود. خطای ثبت audit برای عمل امنیتی یا submit موفقیت پنهانی ایجاد نکند؛ تغییر حساس و audit در همان transaction باشند. برای تلاش ناموفق قبل از transaction نیز مسیر امن و محدود logging نیاز است. نرخ خطا، OTP abuse، نشست‌های غیرعادی و کمبود disk پایش شود.

## کارکنان و الزام `BAZDIDAdmin`

این طرح برای Checkpoint 8 است؛ در فاز آغاز مشتری هیچ جدول staff یا رمز اولیه ساخته نمی‌شود. نیاز قطعی: مدیر سیستم بتواند Admin و Reviewer بسازد. پیشنهاد مدل مشترک:

| جدول آینده | مسئولیت |
|---|---|
| `BAZDIDStaffUsers` | هویت مشترک، وضعیت فعال، username و **تنها محل credential** محلی یا external issuer/subject با نوع احراز؛ rowversion و security stamp |
| `BAZDIDStaffRoleAssignments` | نقش‌های `platform-admin/reviewer` و توسعهٔ permission در صورت نیاز؛ unique staff+role |
| `BAZDIDAdmin` | افزونهٔ یک‌به‌یک `StaffUserId` به‌عنوان PK/FK؛ metadata انتصاب/ایجاد مدیر، بدون رمز یا username تکراری |
| `BAZDIDReviewerAssignments` | ارجاع نسخه‌دار و history در زمان اجرای Reviewer؛ credential جدا ندارد |

ایجاد Admin، staff row + role + `BAZDIDAdmin` + audit را در یک transaction انجام می‌دهد؛ حذف/تغییر نقش نیز consistency را حفظ می‌کند. member بودن در جدول Admin به‌تنهایی مجوز نیست؛ policy نقش/فعال‌بودن و scope را کنترل می‌کند. ایجاد Reviewer فقط staff و نقش را لازم دارد. نام‌های دیگر جدول‌های آینده هم با `BAZDID` شروع خواهند شد.

رمز محلی با `PasswordHasher<TUser>` سازگار نسل 2.1 و قالب salt/work-factor نسخه‌دار نگهداری شود؛ نه SHA/HMAC مستقیم و نه encryption برگشت‌پذیر رمز. work factor در سخت‌افزار واقعی benchmark و قابلیت rehash در login پیش‌بینی شود. lockout، password reset یک‌بارمصرف، revoke نشست پس از تغییر رمز/نقش و محدودیت login لازم‌اند. روش SSO کارکنان اگر بعداً تأیید شد، پشت adapter جدا به همان staff mapping متصل می‌شود و باعث دو نسخهٔ credential نمی‌شود.

bootstrap پیشنهادی: عملیات یک‌بارمصرف خارج HTTP عمومی روی میزبان، دریافت secret تصادفی از کانال امن، قفل اتمیک «مدیر اولیه وجود ندارد»، ایجاد حساب نیازمند تغییر رمز، audit و حذف قابلیت/secret bootstrap. اجرای مجدد مدیر دوم ناخواسته نسازد. هیچ password در source/seed یا مستندات نیست. روش دقیق bootstrap، تحویل اولیه، MFA و بازیابی آخرین مدیر در دفتر تصمیم‌ها باز است.

## gateهای امنیتی

Checkpoint 1: کنترل تنظیمات، خطای امن و logging؛ Checkpoint 3: auth/CSRF/rate/replay/keys؛ Checkpoint 4: مالکیت و trusted fields؛ Checkpoint 6: فایل خصوصی و limits؛ Checkpoint 7: submit اتمیک؛ Checkpoint 9: SQL/ACL/TLS/restore/scan روی staging واقعی و پذیرش ریسک EOL. اجازهٔ شروع Phase 1 جای این gateها را نمی‌گیرد.
