# راهبرد آزمون و کنترل کیفیت

این سند برنامهٔ آزمون آینده است؛ در Phase 0 فقط کنترل مستندات/منابع انجام می‌شود. هیچ قبولی build، runtime، SQL یا deployment بدون اجرای واقعی ثبت نمی‌شود.

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

هر گزارش شامل نسخهٔ commit، SDK/runtime/SQL، محیط غیرحساس، فرمان واقعی، نتیجه/exit code، پوشش و محدودیت باشد. خطای محیط جدا از شکست assertion ثبت می‌شود. هیچ test command برنامه اکنون منتشر نمی‌شود چون هنوز پروژه‌ای نیست؛ در Checkpoint 1 فقط دستورهای واقعاً اجراشده به README اضافه می‌شوند.

## کنترل Phase 0

وجود root/docهای لازم، فارسی UTF-8، پیوندهای نسبی اسناد تازه، ۳۷ ردیف تصمیم SQL، ۱۷ جدول پیشنهادی مشتری، checkpointهای ۰ تا ۹، قواعد ۱۱+۱، نبود کد برنامه/DDL جدید، .gitignore، hash مرجع، عدم تغییر Frontend و Git مستقل کنترل شوند. پیوندهای ناقص داخل بستهٔ مرجع ازقبل‌موجود به‌عنوان محدودیت همان بسته ثبت و فایل‌های تاریخی بی‌اجازه بازنویسی نشوند. نتیجه در [PHASE0_VALIDATION_FA.md](PHASE0_VALIDATION_FA.md) ثبت می‌شود.
