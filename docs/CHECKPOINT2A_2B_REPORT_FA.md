# گزارش Checkpoint 2A/2B — کشف SQL و آماده‌سازی تست

تاریخ `2026-11-01`؛ مبنای Git در شروع `2e217a0` و worktree پاک بود. مجوز پیوست `66aec801-d9a2-4943-a6e3-418104144dba` فقط 2A/2B است. کاربر در پاسخ تکمیلی، instance محلی، Windows Authentication و نام `BAZDID_Development` را تأیید و **اجرای هر DDL را تا تصویب صریح بعدی ممنوع کرد**. script اولیهٔ جدول‌ها نیز با همین پاسخ فقط برای بازبینی آماده شد.

## یافته‌های واقعی SQL

| مورد | نتیجهٔ بررسی واقعی |
|---|---|
| سرویس | `MSSQL$SQLSERVER2019` در حال اجرا؛ سرویس Agent متوقف |
| مقصد مجاز | `(local)\SQLSERVER2019`، Development/Testing؛ اتصال عملاً با `lpc:.\SQLSERVER2019` انجام شد |
| نسخهٔ موتور | `15.0.2000.5`، `RTM`، `Standard Edition (64-bit)`، EngineEdition برابر ۲؛ حاصل SERVERPROPERTY، نه فقط نام سرویس |
| Windows Authentication | موفق؛ auth scheme برابر `NTLM` روی `Shared memory`؛ machine مقصد با رایانهٔ محلی تطبیق داشت |
| پایگاه‌های موجود | فقط `master`، `tempdb`، `model` و `msdb`؛ هر چهار ONLINE |
| compatibility | هر چهار پایگاه سیستمی `150`؛ مقدار پایگاه تست آینده هنوز وجود ندارد |
| collation | سرور و چهار پایگاه: `SQL_Latin1_General_CP1_CI_AS` |
| پایگاه پیشنهادی تست | `DB_ID('BAZDID_Development') = NULL`؛ وجود ندارد و ساخته نشد؛ نام قابل تنظیم می‌ماند |
| نشانه‌های اتصال بیرونی | linked server صفر، IsClustered و IsHadrEnabled هر دو صفر؛ پایگاه کاربری متصل روی instance وجود نداشت |
| مجوز هویت بررسی | `sysadmin = 1` و `VIEW ANY DATABASE = 1`؛ دید catalog کافی بود، ولی این هویت account برنامه نخواهد بود |
| ابزارها | SSMS `22.9.2` و sqlcmd نصب‌اند و در PATH نیستند؛ ODBC 17/18 نیز موجودند |
| LocalDB | دو instance موجود با نسخهٔ گزارش‌شدهٔ `17.0.4025.3` متوقف بودند؛ شروع یا اتصال داده نشدند و مقصد منتخب نیستند |

این شواهد، در زمان بررسی نبود پایگاه کارگزاری/linked server روی همین instance محلی را نشان می‌دهند. هیچ تضمین کلی دربارهٔ شبکهٔ میزبان، فایل‌های detach‌شده، LocalDBهای متوقف یا وضعیت آینده صادر نمی‌شود. به هیچ پایگاه Production متصل نشدیم؛ فقط master catalog خوانده شد و هیچ ردیف تجاری خوانده یا کپی نشد. قبل از اجرای مصوب بعدی، مقصد و catalog دوباره احراز شوند.

اتصال کشف با System.Data موجودِ PowerShell انجام شد؛ این اجرا آزمون SQL client روی Runtime برنامهٔ ASP.NET Core 2.1 نیست. برای همین transport محلی، Encrypt روشن و TrustServerCertificate روشن بود؛ هیچ رمز/connection string چاپ نشد. برنامهٔ شبکه‌ای آینده به گواهی معتبر و TrustServerCertificate خاموش نیاز دارد.

## وضعیت نگاشت کارگزاری

شواهد [ممیزی DuberFront](DUBERFRONT_CODE_AUDIT_FA.md) تغییر نمی‌کنند: `Duber.OrderSales` در دو context سورس، شناسهٔ درخواست CLR long، رابطهٔ CustomerId به Customer.Id و propertyهای `Mobile/Pelak/VinNumber/ShasiNumber` مشاهده شده‌اند. در instance محلی هیچ‌یک از این اشیا وجود ندارد؛ **هیچ schema/ستون Production در این مرحله تأیید نشد**. جدول‌های Customer/lookup را با dbo یا convention حدس نمی‌زنیم.

موارد لازم از DBA و مالک: پایگاه/context authoritative؛ metadata دقیق و مجاز schema/ستون/type/nullability/FK/index؛ صدور و lookup/uniqueness/انقضای referral؛ موبایل trusted و حل تعارض Customer.Mobile/OrderSales.Mobile؛ eligibility/freshness؛ تقویم سال، رنگ، VIN/شاسی و Missing/Invalid/ZeroMeansMissing هر فیلد. تخفیف، پرداخت یا شمارهٔ پست معادل referral نیستند. موبایل متعارض با انتخاب اولین مقدار حل نمی‌شود. [ماتریس نگاشت](BROKERAGE_DATA_MAPPING_FA.md) و O01/O20–O22 مرجع‌اند.

## محیط تست و طراحی سه جدول

آماده‌سازی برای بازبینی انجام شد؛ محیط دارای پایگاه/جدول/حساب برنامه هنوز provision نشده است. دو هویت Windows مستقل و کم‌اختیار، schema تست، recovery/فایل‌ها، patch و TLS باید تصویب شوند. حساب sysadmin کشف برای runtime مجاز نیست. نام/اتصال هر محیط از تنظیمات حفاظت‌شده می‌آید؛ هیچ credential آرشیو یا رکورد واقعی مشتری استفاده نمی‌شود. نصب SQL/ابزار یا تغییر سرویس انجام نشد.

| جدول پیشنهادی | نقش و قیود اصلی |
|---|---|
| `BAZDIDCustomerLinks` | linkage بدون master/موبایل؛ GUID PK، شناسه‌های tenant/source و مشتری، unique دقیق بایتی، زمان‌های UTC و rowversion |
| `BAZDIDRequestContexts` | درخواست به link همان tenant با FK ترکیبی داخلی، unique شناسهٔ درخواست، HMAC/keyId اختیاری بدون referral خام، eligibility/نسخهٔ منبع و rowversion |
| `BAZDIDAuditLogs` | append-only با bigint identity، UTC، actor/action/outcome/resource/correlation محدود، index جست‌وجو؛ بدون متن آزاد، PII، OTP و FK به جدول ناشناخته |

نام/نوع/طول/nullability تمام ستون‌ها، index و concurrency در [طراحی داده](DATABASE_DESIGN_FA.md) و script بازبینی آمده‌اند. schema برابر dbo فقط پیشنهاد تست محلی است. هیچ FK به مبدأ، cascade حذف تاریخچه، `BAZDIDInfo`، migration journal یا جدول auth/media اضافه نشده است. unique کد معرفی تا تعیین قرارداد فرض نمی‌شود. محدودیت طول/الگوی index قبل از Production با mapping و حجم واقعی بازبینی خواهد شد.

زنجیرهٔ fixture برنامه‌ریزی‌شده: `A4K9P2 → TEST-REQUEST-001 → TEST-CUSTOMER-001 → 09000000001` در `TEST-BROKERAGE`. OTP برابر `12345` فقط fixture Development/Testing آینده است؛ نه seed اجرا شد و نه OTP یا SMS پیاده/ارسال شد.

## فایل‌های SQL و معماری اتصال

| فایل زیر database | وضعیت |
|---|---|
| [discovery/server_inventory.sql](../database/discovery/server_inventory.sql) | فقط SELECT از metadata و کنترل مقصد؛ واقعاً روی master محلی مصوب اجرا شد |
| [discovery/source_object_metadata.sql](../database/discovery/source_object_metadata.sql) | فقط metadata یک شیء مصوب در هر اجرا؛ نام‌ها NULL و flag صفر، برای DBA؛ اجرا نشده |
| [proposals/create_development_database.review.sql](../database/proposals/create_development_database.review.sql) | ساخت پایگاه محلی پیشنهادی؛ DDL بسته و اجرا نشده |
| [proposals/initial_tables.review.sql](../database/proposals/initial_tables.review.sql) | سه جدول/constraint/index در transaction؛ DDL بسته و اجرا نشده |
| [proposals/permissions.review.sql](../database/proposals/permissions.review.sql) | نقش read و writer و کاربران Windows از login مصوب؛ بدون ساخت login/رمز؛ بسته و اجرا نشده |

پیش‌نویس‌ها به‌طور پیش‌فرض با `@AllowDdl = 0` و approval NULL متوقف می‌شوند؛ حتی flag NULL مجوز نمی‌دهد. مقصد shared memory، instance، پایگاه غیرسیستمی و عدم وجود پایگاه کاربری دیگر/linked server بررسی می‌شوند. برای DDL فقط هویت provisioning بازبینی‌شده استفاده می‌شود؛ کم‌اختیاری account برنامه جداست. script ساخت جدول نیازمند پایگاه خالی است؛ اجرای دوباره به‌عنوان migration پذیرفته نمی‌شود. هیچ DROP/حذف یا fallback به مقصد دیگر وجود ندارد. تصویب schema، سپس مجوز صریح DDL و 2C، پیش‌نیاز اجرا هستند.

ADO.NET حفظ شد: factory read/write جدا، اتصال کوتاه‌عمر، parameter دارای نوع/طول، command timeout و cancellation، transaction صریح و CAS؛ بدون ORM جدید یا reader Production. نسخهٔ فعلی lockfile `System.Data.SqlClient 4.5.3` است. pin **طرح آزمایش بعدی** برابر `4.8.6` با target صریح netcoreapp2.1 است، اما قید framework فعلی آن را نمی‌پذیرد؛ رفع تعارض گراف/بررسی تمام انتقالی‌ها و SNI و آزمون Runtime پیش از افزودن بسته در O24 باز است. هیچ بسته یا lockfile تغییر نکرد. [شاهد رسمی بسته](https://www.nuget.org/packages/System.Data.SqlClient/4.8.6) و منابع چرخهٔ پشتیبانی در طراحی داده ثبت شده‌اند.

## آزمون و محدودیت اعتبارسنجی

فرمان‌های زیر در همین وظیفه با SDK `2.1.818` واقعاً اجرا شدند:

```powershell
dotnet build Bazdid.sln --configuration Release --no-restore
dotnet test Bazdid.sln --configuration Release --no-build --no-restore
```

build موفق، صفر warning/error؛ unit برابر `15/15` و integration برابر `28/28`، مجموع `43/43` و exit code صفر. این نتایج تازه‌اند. هیچ package restore/install لازم نشد. SQL integration برنامه، اجرای DDL/constraint/permission و IIS واقعی آزمایش نشده‌اند.

پنج SQL با `Microsoft.SqlServer.TransactSql.ScriptDom.TSql150Parser` نصب‌شده بدون خطای syntax parse شدند؛ tokenهای تغییر داده/DDL در دو discovery وجود نداشتند و guard سه پیش‌نویس، پیشوند سه جدول و تنها FK داخلی کنترل شدند. ۶۴ پیوند Markdown معتبر، scope دقیق سیزده فایل، ۱۰۹ فایل نسخهٔ فعلی و ۱۲۶ blob تاریخی main بررسی شدند؛ هشدار راز باقی‌مانده صفر و fixture URL موجود در آزمون به‌صورت جداگانه تأیید شد. کد/lockfile/runtime با baseline تفاوت ندارند. parse، عملکرد transaction/unique/FK/permission یا متن dynamic SQL روی موتور را اثبات نمی‌کند. آزمون مؤثر با دو account، مقصد اشتباه، rollback، concurrency و idempotency به مرحلهٔ مجاز بعد تعلق دارد.

خطرهای باقی‌مانده: SQL محلی در build RTM است و patch/تنظیمات آن باید با DBA بازبینی شود؛ پشتهٔ .NET 2.1 خارج پشتیبانی است، audit تاریخی foundation پاک نیست، گراف SQL client نیازمند حل تعارض است و حساب‌های کم‌اختیار/TLS هنوز عملیاتی نشده‌اند. خطرهای سورس قدیمی دلیل انتقال credential یا الگوی OTP آن نیستند.

## تحویل، پیشرفت و توقف

اسناد DATABASE_DESIGN، BROKERAGE_DATA_MAPPING، OPEN_DECISIONS، AI_CONTINUATION و PLAN به‌روز شدند؛ AGENTS قاعدهٔ دائمی درصد پیشرفت را دارد و database/README راهنمای فایل‌هاست. API/کد runtime/dependency و Frontend تغییر نکرده‌اند. Git فقط تغییرهای امن همین بسته را روی main مقصد موجود ثبت و push می‌کند؛ نتیجهٔ واقعی SHA/HEAD در گزارش نهایی و Git قابل مشاهده است. آرشیو و source اختصاصی وارد تاریخچه نمی‌شوند.

**پیشرفت کل پذیرفته‌شدهٔ این دامنه: 15% = 12% قبلی + 1.5% کشف 2A + 1.5% آماده‌سازی 2B.** این سهم بابت deliverableهای فعلی است؛ ساخت پایگاه/جدول، حل mapping واقعی و اجرای reader انجام نشده و سهم اضافه ندارد. وزن کل Checkpoint 2 همچنان ۱۲ واحد است و ۹ واحد آن باقی است. جدول ۱۰۰درصدی و معیار تقسیم در PLAN ثبت شده‌اند. پس از پذیرش کامل 2C، برآورد مشروط **17%** و پس از تمام Checkpoint 2 برابر **24%** است؛ درصد آینده اکنون لحاظ نمی‌شود.

**گام بعد:** بازبینی سه جدول و scriptها، تعیین حساب‌ها/patch/TLS و حل gate بسته، سپس فقط با تصویب تازهٔ مالک اجرای پایگاه تست و شروع 2C. اطلاعات schema/referral/mobile/eligibility کارگزاری از DBA/مالک لازم‌اند و دسترسی Production هنوز مجاز نیست. **توقف در پایان 2A/2B؛ هیچ DDL، repository، authentication، OTP، upload یا 2C–2G اجرا/پیاده نشده است.**
