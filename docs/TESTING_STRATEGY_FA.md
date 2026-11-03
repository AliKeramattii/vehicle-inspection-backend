# راهبرد آزمون و کنترل کیفیت

وضعیت جاری `2026-11-03`: ۱۵۹ آزمون آفلاین موفق، صفر شکست و ۸ SQL Skipped؛ جزئیات اجرای تازهٔ 2F در انتهای سند و [شاهد برنامه](checkpoint2f/APPLICATION_VALIDATION.json) است. پذیرش SQL متصل مسدود است. این سند راهبرد کلی و سابقهٔ آزمون‌های قبلی را حفظ می‌کند. در 2D، **۶۵ آزمون واحد و ۴۳ integration، جمعاً ۱۰۸ آزمون، موفق اجرا شدند**؛ همهٔ ۴۳ قبلی و ۶۵ جدید. build SDK 2.1.818 صفر warning/error و smoke واقعی Kestrel موفق بود. [شواهد تازهٔ 2D](checkpoint2d/APPLICATION_VALIDATION.json). integrationهای تازه DI/TestServer/reader حافظه‌ای‌اند؛ SQL repository یا IIS/ANCM را اثبات نمی‌کنند. ۳۵ آزمون مستقیم schema SQL متعلق به 2C است و در 2D فقط verification خواندنی DB اجرا شد. بخش foundation پایین تاریخی است؛ [گزارش همان مرحله](CHECKPOINT1_IMPLEMENTATION_FA.md).

## اجرای فعلی Checkpoint 1

```powershell
dotnet restore Bazdid.sln --locked-mode
dotnet build Bazdid.sln --configuration Release --no-restore
dotnet test Bazdid.sln --configuration Release --no-build --no-restore
```

این فرمان‌ها واقعاً exit code صفر داشتند. unit شامل اعتبارسنجی محیط/base/origin و integration شامل startup، liveness، JSON، 404، عدم افشای خطا/log، correlation، Swagger UI/JS/JSON و مسیر درست، خاموش‌بودن Production، CORS، HTTPS redirect، HSTS اختیاری و metadata شبیه‌سازی‌شدهٔ IIS است. خطای عمدی فقط در controller متعلق به پروژهٔ تست تزریق می‌شود؛ endpoint تشخیصی در API منتشرشده نداریم. آزمون DB/SMS/upload فعلاً وجود ندارد چون آن قابلیت‌ها پیاده نشده‌اند.

## سطوح و محیط

آزمون واحد برای قواعد domain بدون SQL/HTTP، آزمون integration برای MVC/auth/SQL Server و فایل، و پذیرش مرورگر/IIS روی staging جدا هستند. دو پروژهٔ پیشنهادی `Bazdid.UnitTests` و `Bazdid.IntegrationTests` کافی‌اند. نسخهٔ xUnit/Test SDK/TestHost پس از احراز restore و سازگاری واقعی با 2.1 pin می‌شود؛ از جدیدترین runner خودکار استفاده نشود.

SQL integration روی Microsoft SQL Server محلی/تست مصوب و جدا از Production اجرا شود. EF InMemory یا SQLite، filtered index، rowversion، locking، collation و raceهای SQL Server را اثبات نمی‌کند. fixtureها کاملاً ساختگی‌اند و SMS واقعی مسدود است. زمان با `IClock`، OTP/شناسه با provider قابل جایگزینی آزمون و storage با root موقت محدود کنترل شود؛ cleanup فقط همان root تأییدشده را هدف بگیرد.

## ماتریس پوشش

| حوزه | آزمون‌های ضروری |
|---|---|
| foundation | SDK/target دقیق، dependency graph، startup نامعتبر، health، خطای JSON، correlation، نبود stack/secret |
| reader | referral معتبر/نامعتبر/مبهم، دو درخواست یک مشتری، مبدأ unavailable، عدم fallback، mapping zero فقط همان فیلد، account بدون write |
| OTP | expiry در مرز زمان، ۵ شکست طبق policy تست، cooldown، سقف پنجره با resend، challenge اشتباه/نسل قبلی، verify هم‌زمان، replay و SMS timeout |
| fixture gate | ترکیب Production + هر adapter/flag/mock OTP باید fail شود؛ محیط ناشناس هم Development تلقی نشود؛ mock هیچ SMS نفرستد |
| نشست و HMAC | request scope، mobile trusted، fixation، expiry مطلق/idle، logout، restart و دو instance، rotation HMAC و DP keys، encoding بدون ابهام و normalization ارقام |
| مرورگر | cookie host/path/secure/HttpOnly، 401 بدون redirect، origin نامجاز، preflight، credentials، CSRF token قبل/بعد login، login/logout/upload CSRF |
| اطلاعات | trusted/manual/missing/InvalidSource، null و صفر معتبر، جعل source/readOnly، overposting، CAS، source change و persistence مستقل Session |
| inspection | create هم‌زمان و idempotency، current uniqueness، owner mismatch، رضایت نسخه‌دار، location دستی accuracy null، حدود آدرس/پلاک/سال |
| مدارک | ده ثابت، هر چهار VIN به‌تنهایی، دو VIN مردود، تکرار جایگاه، engine-bay مستقل، v1 با ۱۲ عکس، template پین‌شده و عدم relabel accepted |
| کیلومتر | صفر، مقدار صحیح، منفی، اعشار، متن، overflow و JS-safe bound؛ مستقل از عکس و شمار رسانه |
| upload | stream بدون length، سقف حجم/پیکسل/مدت، MIME جعلی، hash mismatch، traversal/UNC/ADS/reparse، cancel، retry و writer هم‌زمان |
| سازگاری فایل | fault بعد از reservation، وسط stream، قبل/بعد rename و commit، orphan/missing، reconcile دوباره، stale lease و جلوگیری از overwrite |
| retrieval | مالک/غیرمالک، version/variant غلط، thumbnail، Range مجاز/غیرمجاز، no-store و عدم افشای path |
| submit | missing هر پیش‌نیاز، رسید نسخهٔ کهنه، pending جایگزین، دو submit هم‌زمان، rollback، retry پاسخ گم‌شده، key یکسان با payload متفاوت، snapshot/receipt ثابت و قفل |
| SQL و عملیات | script از صفر/ارتقا، least privilege، transaction rollback، constraints، timeout/deadlock retry محدود، backup/restore فایل+DB+keys |
| آینده | staff credential واحد، bootstrap یک‌بار، role revoke، assignment در لحظهٔ تصمیم، correction scope، full rejection تلاش خالی و forwarding فقط با ack |

## آزمون قرارداد و اتصال

OpenAPI همان implementation با نمونهٔ واقعی responseها تطبیق داده شود: casing، required/null، enum، integer، خطا، cookie/CSRF، binary stream و headerهای concurrency/idempotency. `Vehicle` و lifecycle در adapter به مدل UI نگاشت شوند؛ contract test جلوی cast کور و fallback به mock را بگیرد. نمونهٔ static manifest جای server response نیست.

تست مرورگر با originهای HTTPS واقعی sibling و در صورت انتخاب cross-site، topology واقعی اجرا شود. TestServer رفتار IIS PathBase، TLS، محدودیت body یا سیاست Safari را اثبات نمی‌کند. آزمون دستگاه Android/iOS برای codec، camera، ویدیو/Range و network interruption به تیم Frontend مربوط است، با هماهنگی staging؛ موفقیت Backend به معنی static export کامل Next نیست.

## معیار خروج هر سطح

واحد: قواعد دامنه و مرزهای خطا پوشش داده شوند؛ تست کپی عین implementation ساخته نشود. Integration: SQL و فایل در race/failure مستقل بررسی شوند، نه فقط happy path. Staging: مسیر عمومی prefixدار، SSL/CORS/cookie/CSRF، privacy، recycle، دو instance در صورت نیاز و restore با شواهد ثبت شوند. تست‌های موفق صرفاً برای افزایش شمار تکرار نشوند؛ تغییر تازه یا نگرانی حل‌نشده دلیل اجرای مجدد است.

هر گزارش شامل نسخهٔ commit، SDK/runtime/SQL در صورت استفاده، محیط غیرحساس، فرمان واقعی، نتیجه/exit code، پوشش و محدودیت باشد. خطای محیط جدا از شکست assertion ثبت می‌شود. دستورهای فعلی در README ثبت شده‌اند؛ اضافه‌شدن تست‌های SQL/رسانه و پذیرش staging واقعی در checkpoint مربوط انجام می‌شود.

## کنترل Phase 0

وجود root/docهای لازم، فارسی UTF-8، پیوندهای نسبی اسناد تازه، ۳۷ ردیف تصمیم SQL، ۱۷ جدول پیشنهادی مشتری، checkpointهای ۰ تا ۹، قواعد ۱۱+۱، نبود کد برنامه/DDL جدید، .gitignore، hash مرجع، عدم تغییر Frontend و Git مستقل کنترل شوند. پیوندهای ناقص داخل بستهٔ مرجع ازقبل‌موجود به‌عنوان محدودیت همان بسته ثبت و فایل‌های تاریخی بی‌اجازه بازنویسی نشوند. نتیجه در [PHASE0_VALIDATION_FA.md](PHASE0_VALIDATION_FA.md) ثبت می‌شود.


## شواهد تازه و تفکیک آزمون‌های 2F

در `2026-11-03`، [شاهد برنامه](checkpoint2f/APPLICATION_VALIDATION.json) اجرای تازهٔ restore/build و test را ثبت کرد: صفر warning/error، ۱۰۹ unit + ۵۰ integration آفلاین = ۱۵۹ موفق، صفر شکست، تمام ۱۰۸ baseline و ۵۱ case تازه. هشت آزمون `SqlRepositoryConnectedTests` جداگانه Skipped با دلیل O24/O26 هستند؛ **صفر SQL connected اجرا شد**. TestServer/DI و doubleهای transaction این مرحله شاهد SQL Server نیستند. [نتایج SQL مجزا](checkpoint2f/SQL_TEST_RESULTS.json)، [provider](checkpoint2f/PROVIDER_AUDIT.json) و [walkthrough](implementation/CHECKPOINT-02F-SQL-REPOSITORIES_FA.md) حدود پذیرش را مشخص می‌کنند.

آفلاین‌ها binding دقیق/نوع/اندازه/null، source ID بزرگ/case/Unicode/trailing space، injection، owner/CAS در متن command، خطا/timeout، token/HMAC، config/gate و شکست جزئی/عدم retry را پوشش می‌دهند. هشت تست متصل برای طبیعی‌کلید/تکرار/tenant، مالک نادرست، stale version، rollback، رقابت، effective permissions Writer، timeout و cancellation نوشته شده‌اند؛ هیچ bypass محیطی ندارند. پس از تصمیم provider و تصویب دو principal، suite باید بازبینی و با خود هویت‌ها اجرا شود؛ SourceReader نیاز به mapping مصوب و verifier شمار audit قبل/پس دارد. رقابت commitشده، commit مبهم و عدم باقی‌ماندن داده باید واقعاً اثبات شوند؛ طرح body فعلی، معیار پذیرش اجراشده نیست.

verification metadata با provisioner فقط‌خواندنی و smoke واقعی Kestrel با SQL خاموش موفق شدند؛ IIS و native/connection واقعی provider آزموده نشدند. ۳۵ CASE تاریخی 2C تکرار نشدند. هر نتیجهٔ بعدی باید passed/offline/skipped/connected را جدا و بدون افزایش درصد برای gate مسدود ثبت کند.
