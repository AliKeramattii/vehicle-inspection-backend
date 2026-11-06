# راهبرد آزمون و کنترل کیفیت

شاهد تازهٔ P1–P5 در `2026-11-06` ([گزارش](implementation/CHECKPOINT-02F-CONNECTED-ACCEPTANCE_FA.md)):

- regression: ۱۰۹ unit و ۵۰ integration موفق، ۰ شکست، ۸ SQL Skipped؛ build با 0 warning و 0 error؛ smoke و Swagger بدون تغییر.
- آزمون متصل: **صفر اجرا**.
- probe اتصال امن به سرور رسید، اما TLS رد شد؛ این شکست، شاهد مانع است، نه آزمون موفق.
- scriptهای مدیر فقط parse شدند و آزمون منفی guard بدون elevation روی آن‌ها اجرا شد.

قاعدهٔ پایدار: پذیرش متصل فقط با `Encrypt=true` و `TrustServerCertificate=false` و زیر token واقعی Writer معتبر است.

شاهد L1-A در `2026-11-06` ([روش](implementation/CHECKPOINT-02F-L1A-CANONICAL-DEPENDENCIES_FA.md)، [نتایج](checkpoint2f/L1A_VALIDATION.json)): canonical روی گراف ریز با `System.Data.SqlClient 4.8.6`.

- `restore`، `restore --locked-mode`، build Release: صفر warning/error.
- ۱۰۹/۱۰۹ unit؛ ۵۰ موفق، ۰ شکست و ۸ SQL Skipped از ۵۸ integration. آزمون Skipped موفق نیست و آزمون متصل اجرا نشد.
- smoke Kestrel قبل و بعد با Swagger بایت‌به‌بایت یکسان.
- audit با SDK 10 خارج از `global.json`: ۲ بستهٔ flagged.

از این پس هر تغییر بسته باید همین چهار فرمان، مقایسهٔ Swagger و audit را ثبت کند.

سابقهٔ 2F-L1 در `2026-11-03`: [روش](implementation/CHECKPOINT-02F-LEGACY-SQLCLIENT-FEASIBILITY_FA.md) و [نتایج](checkpoint2f/LEGACY_SECURITY_PINS.json).

- **canonical** (`restore --locked-mode`، `build --configuration Release --no-restore`، `test --configuration Release --no-build --no-restore`): صفر warning/error، ۱۰۹ unit + ۵۰ integration موفق، صفر شکست، ۸ SQL Skipped.
- **آزمایش‌های جدا:** هر نامزد probe آفلاین ۱۰ بررسی بدون `Open`/کوئری دارد. گراف ریز ۱۴ سناریوی میزبان دارد. کپی canonical روی گراف ریز همان ۱۰۹ + ۵۰ موفق/۸ Skipped را دارد.
- این شمارش‌ها با canonical جمع نمی‌شوند و Skip موفق نیست.
- audit باید با SDK دارای `--vulnerable` و خارج از `global.json` ریشه اجرا شود. هر تغییر بستهٔ آینده باید audit را ثبت کند و warning NuGet را سرکوب نکند.
- اتصال SQL، native load، TLS و IIS آزموده نشدند و پیشرفت 20% است.

سابقهٔ P0 در `2026-11-03`: [روش و فرمان‌ها](implementation/CHECKPOINT-02F-P0-MIGRATION-FEASIBILITY_FA.md) و [نتایج گزینش‌شده](checkpoint2f/P0_FEASIBILITY_RESULTS.json). canonical: build صفر warning/error،۱۰۹ unit و۵۰ integration آفلاین موفق، صفر شکست و۸ SQL Skipped. نمونهٔ مستقل net10: build صفر warning/error،۱۴ موفق/صفر شکست و سه HTTP smoke موفق؛ audit نهایی نمونه صفر بستهٔ flagged. نتیجهٔ نمونه و canonical قابل جمع به‌عنوان suite واحد نیستند؛ هیچ SQL connect/metadata، native load، TLS، IIS یا Windows Server اجرا نشد. مهاجرت واقعی باید تمام caseهای قبلی را با runner جدید نگاشت و حفظ کند؛ Skip موفق نیست. پیشرفت20% باقی است.

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


## اجرای تازهٔ ادامهٔ 2F و محدودیت acceptance

مجوز `e252dad0-0bb1-4058-ab9b-f757dd2b272a` هنوز اجازهٔ تغییر provider/حساب/permission یا activation نداد. [شاهد تازه](checkpoint2f/CONTINUATION_REVIEW.json): ۱۰۹ unit و ۵۰ integration آفلاین موفق، صفر شکست، ۸ SQL Skipped؛ build صفر warning/error، تست جدید صفر. این baseline قبلی دوباره اجرا شد؛ شواهد تحویل اولیه بازنویسی نشدند. دو proposal و دو template با ScriptDom/TSql150 آفلاین parse شدند؛ این SQL اجرا یا effective permission test نیست.

[بستهٔ تصویب](checkpoint2f/CONTINUATION_APPROVAL_FA.md) review هشت تست را ثبت می‌کند: اثبات انتظار قفل، رقابت commitشده، commit مبهم/بازیابی، همهٔ منع‌های audit/DDL، Reader مستقل، native/TLS/pooling و verifier شمار audit هنوز به تکمیل و اجرای مصوب نیاز دارند. هیچ fixture commitشده یا cleanup قبل از approval run/شناسه‌ها/هویت جدا مجاز نیست؛ Writer حق DELETE/SELECT audit نمی‌گیرد. native فایل موجود و managed load فعلی، اتصال را ثابت نمی‌کنند. نگهداری این بسته امتیاز ندارد؛ ۲۰٪ باقی می‌ماند.
