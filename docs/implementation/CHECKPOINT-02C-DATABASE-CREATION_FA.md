# فرایند ایجاد پایگاه توسعه — Checkpoint 2C

تاریخ `2026-11-01`؛ HEAD شروع `da56c2d`؛ پیشرفت قبلی `15%`. درخواست `553dc9cd-5abe-4eb0-9856-ee1763d5250b` ساخت فقط `BAZDID_Development` روی `(local)\SQLSERVER2019` با Windows Authentication و فقط سه جدول dbo را صریحاً مجاز کرد. این گزارش اجرای واقعی 2C است؛ 2D، OTP، Session، Info، رسانه و Production در این کار اجرا نشدند.

## مسئله، پیش‌نیاز و دامنه

تلاش قبلی 2D طبق gate متوقف شده بود: پایگاه وجود نداشت و schema/آزمون واقعی 2C ثبت نشده بود. AGENTS، PLAN، طراحی داده، گزارش 2A/2B، O24/O25، سه پیش‌نویس SQL و راهنمای database بازخوانی شدند. وضعیت اولیهٔ Git فقط `src/Bazdid.Api/Properties/launchSettings.json` ثبت‌نشده داشت؛ محتوا تغییر نکرد و وارد commit نشد.

هیچ table mapping کارگزاری از source قدیمی به‌عنوان واقعیت Production پذیرفته نشد. ابزارهای این مرحله به master و همین پایگاه محلی محدودند؛ credential آرشیو، backup و رکورد واقعی مشتری استفاده نشد.

## بررسی تازهٔ مقصد و تصمیم تنظیمات

[ابزار کنترل‌شده](../../database/tools/Invoke-BazdidDevelopmentDatabase.ps1) از System.Data موجود در Windows PowerShell استفاده می‌کند و connection string را چاپ نمی‌کند. اتصال فقط `lpc:.\SQLSERVER2019`، Windows Authentication، Shared memory و همان ماشین است؛ نام instance، نسخهٔ اصلی ۱۵، sysadmin بودن provisioner، نبود linked server/Cluster/HADR/پایگاه کاربری غیرمنتظره و خالی‌بودن اشیای سفارشی model پیش از mutation دوباره بررسی می‌شوند. transport و نام host ورودی دلخواه نیستند.

| بررسی پیش از DDL | نتیجهٔ واقعی |
|---|---|
| موتور | `15.0.2000.5`، SQL Server 2019 Standard x64 |
| اتصال | Shared memory، Windows/NTLM، تطبیق ماشین محلی موفق |
| catalog اولیه | فقط master/tempdb/model/msdb؛ DB_ID مقصد NULL |
| جداسازی | linked server صفر، Cluster/HADR صفر، user DB غیرمنتظره صفر |
| defaults | collation برابر `SQL_Latin1_General_CP1_CI_AS`؛ model دارای recovery برابر FULL |
| model | داده و log هرکدام ۸ MiB، رشد ۶۴ MiB؛ بدون شیء سفارشی |
| مسیر فایل | پوشهٔ DATA پیش‌فرض همان instance در `C:\Program Files\Microsoft SQL Server\MSSQL15.SQLSERVER2019\MSSQL\DATA\` |
| ظرفیت | پیش از اجرا بیش از ۲۰۰ GiB فضای آزاد محلی؛ ابزار حداقل ۲ GiB را کنترل کرد |

تنظیمات پایگاه تازه: compatibility `150`، collation بالا، recovery **SIMPLE**، AutoClose/AutoShrink خاموش و PageVerify برابر CHECKSUM. داده و log هرکدام ۱۶ MiB اولیه و رشد ۱۶ MiB، سقف داده ۵۱۲ و log برابر ۲۵۶ MiB دارند؛ نام فیزیکی `BAZDID_Development.mdf` و `BAZDID_Development_log.ldf` است. مسیر از SERVERPROPERTY همان instance می‌آید؛ فایل موجود حذف/overwrite/attach نمی‌شود. model و تنظیمات چهار پایگاه سیستم تغییر نکردند؛ ثبت catalog ضروریِ CREATE DATABASE انجام شد.

Encrypt روشن است؛ TrustServerCertificate تنها برای همین اتصال lpc محلی روشن بود. این استثنا، تنظیم runtime یا اتصال شبکه‌ای/Production نیست. نسخهٔ RTM موتور نیازمند بازبینی patch توسط DBA است و در این وظیفه ارتقا یا تغییر سرویس انجام نشد.

## ترتیب واقعی اجرا و حفاظت فایل‌ها

۱. SQLها با TSql150Parser و ابزار PowerShell از نظر syntax بررسی شدند؛ schema، طول‌ها، FK ترکیبی tenant/source، unique، computed key، UTC و rowversion بازبینی شدند.
۲. [پیش‌نویس ایجاد DB](../../database/proposals/create_development_database.review.sql) برای اندازه/رشد/سقف فایل و SIMPLE نهایی شد. فایل commitشونده همچنان `@AllowDdl=0` و approval برابر NULL دارد.
۳. ابزار با `-ApproveLocalDdl`، شناسهٔ همین مجوز و SHA-256 دقیق فایلِ بازبینی‌شده اجرا شد. فقط دو مقدار guard در نسخهٔ حافظه‌ای مجاز شدند؛ SQL باز یا فایل موقت بدون guard نوشته نشد.
۴. CREATE DATABASE خارج transaction صریح، سپس compatibility و recovery فقط روی پایگاه تازه اعمال شدند؛ metadata مستقیم، وجود پایگاه با id برابر ۵ و تنظیمات صحیح را تأیید کرد.
۵. سه جدول و index/constraintهای داخلی در یک transaction ساخته شدند. اولین تطبیق metadata موفق بود، اما آزمون درج معتبر عیب واقعی CHECK tenant را آشکار کرد؛ اصلاح محدود و آزمون مجدد در بخش خطاها ثبت است.
۶. پس از اصلاح، metadata نهایی با قرارداد مستقل و همهٔ ۳۵ CASE روی SQL Server واقعی تأیید شدند. سپس restore/build و ۴۳ آزمون برنامه جداگانه اجرا شدند.

| اجرای DDL واقعی | SHA-256 فایلِ زمان اجرا |
|---|---|
| ساخت پایگاه | `B9D042F0C31A6812C7F961DB24F54ED5FB781B538E69D6E12033766E4B02867B` |
| ساخت اولیهٔ سه جدول، پیش از رفع CHECK | `72BC89B64BC6EBBA76C381E48FD2993879DE7CA73CC7152C2535F0C62E4ECEB6` |
| اصلاح سه CHECK با WITH CHECK | `8FAB224AAEB75AC85DBB82642631E3D297489272025FEEA47544E831F892D32C` |

نسخهٔ نهایی [initial_tables.review.sql](../../database/proposals/initial_tables.review.sql) اصلاح را در خود دارد؛ hash آن با نسخهٔ اولیهٔ اجراشده فرق دارد. این نسخهٔ نهایی برای ساخت از صفرِ بعدی است و روی پایگاه موجود دوباره اجرا نشده؛ schema نهایی با آن تطبیق و رفتارش با آزمون تأیید شده است. [repair_tenant_checks.review.sql](../../database/proposals/repair_tenant_checks.review.sql) شاهد اصلاح این اجرای واقعی است، حذف پایگاه یا migration عمومی نیست.

چهار آزمون منفی guard نیز بدون DDL/DML موفق شدند: نبود مجوز DDL، hash متفاوت، تلاش ساخت پایگاه موجود و تست بدون مجوز همگی قبل از mutation رد شدند. [GUARD_TEST_RESULTS.json](../checkpoint2c/GUARD_TEST_RESULTS.json) شاهد است. فایل‌های database در Git با LF نگهداری می‌شوند تا hash بازبینی پایدار باشد؛ ابزار PowerShell برای متن فارسی در Windows PowerShell 5.1 دارای UTF-8 BOM است. hashها پس از بازبینی و از فایل جاری خوانده شوند؛ hash تاریخی نسخهٔ پیش از repair را برای نسخهٔ final استفاده نکنید.

## جدول‌ها و آنچه تأیید شد

| جدول | مسئولیت و نتیجه |
|---|---|
| `dbo.BAZDIDCustomerLinks` | linkage مشتری؛ ۸ ستون، GUID PK، unique دقیق شناسهٔ منبع و unique کمکی tenant/source/Id؛ rowversion |
| `dbo.BAZDIDRequestContexts` | linkage درخواست؛ ۱۸ ستون، GUID PK، unique درخواست، FK سه‌ستونی به link همان tenant/source؛ rowversion و HMAC/keyIdهای nullable |
| `dbo.BAZDIDAuditLogs` | رویداد حداقلی؛ ۱۳ ستون، bigint identity PK، UTC، actor/correlation محدود؛ بدون payload آزاد یا FK به مبدأ |

جمع واقعی: **۳ جدول، ۳۹ ستون، ۱۰ index، ۳ PK، ۳ unique constraint، ۱ FK، ۱۳ CHECK فعال و trusted، دو rowversion و دو computed persisted key**. هیچ cascade، FK به کارگزاری، جدول اضافی، journal، Info یا auth/media ایجاد نشد. `schema_expected.json` نام/ترتیب/نوع/طول/nullability ستون‌های عادی، scale، collation، default، index و FK را بررسی می‌کند. nullability توصیفی computed را SQL Server تعیین می‌کند؛ ورودی اجباری و تبدیل دقیق و non-null بودن مقدار با آزمون تأیید شدند.

شناسه‌های مبدأ nvarchar و کلید مقایسهٔ آن‌ها varbinary حاصل از UTF-16 هستند؛ case، فاصلهٔ انتهایی، Unicode و عدد بزرگ بدون کاهش دقت آزموده شدند. tenant/source فقط شناسه‌های تنظیم‌شدهٔ ASCII شامل حرف/رقم/زیرخط/خط تیره‌اند. برای بررسی کامل ستون‌ها و تعریف قیود، [طراحی داده](../DATABASE_DESIGN_FA.md)، [قرارداد مورد انتظار](../../database/verification/schema_expected.json) و [metadata واقعی](../checkpoint2c/SCHEMA_VERIFICATION.json) مرجع‌اند.

## آزمون‌های SQL واقعی و خطاهای رفع‌شده

[فایل CASEها](../../database/verification/checkpoint2c_rollback_cases.sql) مستقیم اجرا نمی‌شود. ابزار برای هر CASE یک SqlTransaction مستقل با ReadCommitted می‌سازد، fixture ساختگی را درج می‌کند، success یا error number مورد انتظار را بررسی و در finally همیشه **Rollback** می‌کند. بعد از هر CASE شمار ردیف هر سه جدول صفر و @@TRANCOUNT صفر کنترل می‌شود؛ پس از پایان، metadata دوباره تطبیق داده می‌شود. هیچ COMMIT یا کنترل transaction در خود CASEها وجود ندارد.

۳۵ CASE نهایی موفق شدند: درج/default/computed، PK و unique تکراری، FK نامعتبر و tenant/source دیگر، چند درخواست برای یک مشتری، استقلال یکتایی tenant، حفظ case/فاصله/Unicode/شناسهٔ بزرگ، rowversion و رد stale update، null/empty/حروف غیرمجاز tenant، eligibility، ترتیب timestamp، زوج‌های HMAC/keyId، مجازبودن referral hash تکراری، actor/correlation audit و منع cascade حذف. نتایج و error numberهای مورد انتظار در [ROLLBACK_TEST_RESULTS.json](../checkpoint2c/ROLLBACK_TEST_RESULTS.json) ثبت‌اند. این آزمون، reader یا احراز هویت نیست.

| مشکل واقعی | علت و رفع |
|---|---|
| parse فایل PowerShell فارسی | Windows PowerShell 5.1 فایل UTF-8 بدون BOM را درست نخواند؛ ابزار با UTF-8 BOM ذخیره شد، قبل از اتصال رفع شد |
| parse query metadata | alias رزروشدهٔ RowCount با `[RowCount]` تصحیح شد؛ SQL هنوز اجرا نشده بود |
| درج معتبر با خطای 547 | الگوی CHECK اولیه `[^A-Za-z0-9_-]` خط تیره و زیرخط را نیز رد می‌کرد؛ روی literalهای ساختگی با SELECT اثبات شد. در سه جدول، REPLACE خط تیره را فقط برای آزمون alphabet جدا می‌کند و الگوی `[^A-Za-z0-9_]` بقیه را محدود می‌کند؛ مقدار ذخیره‌شده تغییر نمی‌کند |
| تطبیق متنی CHECK پس از اصلاح | SQL Server، NOT LIKE را در definition به NOT expression LIKE بازنویسی کرد؛ مقایسه با فرم canonical واقعی اصلاح شد، قیدها تغییر اضافی نکردند |

اصلاح CHECK با ALTER محدود، DROP/ADD همان نام در **یک transaction** و `WITH CHECK` انجام شد؛ هیچ NOCHECK یا غیرفعال‌سازی constraint استفاده نشد. تمام درج‌های دو اجرای ناموفق نخست نیز rollback شدند. بعد از اجرای موفق نهایی، هر سه جدول **صفر ردیف** دارند. counterهای identity و rowversion ممکن است با rollback جلو بروند؛ شکاف آن‌ها طبیعی است و reseed انجام نشد.

## برنامه، مجوزها و وابستگی حل‌نشده

فرمان‌های واقعی از ریشهٔ مخزن:

```powershell
dotnet restore Bazdid.sln --locked-mode
dotnet build Bazdid.sln --configuration Release --no-restore
dotnet test Bazdid.sln --configuration Release --no-build --no-restore
```

SDK `2.1.818`؛ restore/build/test با exit صفر؛ build صفر warning/error؛ ۱۵ unit و ۲۸ integration، جمع **43/43** موفق. [APPLICATION_VALIDATION.json](../checkpoint2c/APPLICATION_VALIDATION.json) خلاصهٔ واقعی است؛ لاگ تفصیلی ignored است. این تست‌های موجود SQL repository، مجوز مؤثر account برنامه، مرورگر یا IIS را اثبات نمی‌کنند.

O24 دوباره بررسی شد: lockfile فعلی `System.Data.SqlClient 4.5.3` است و Microsoft.AspNetCore.App 2.1.30 بازهٔ `[4.5.3,4.6.0)` را الزام می‌کند. 4.8.6 target نسل 2.1 دارد، ولی خارج این بازه است؛ هیچ PackageReference/lockfile، runtime یا warning policy تغییر نکرد. [قید رسمی framework](https://www.nuget.org/packages/Microsoft.AspNetCore.App/2.1.30)، [metadata بستهٔ 4.8.6](https://www.nuget.org/packages/System.Data.SqlClient/4.8.6). اجرای DDL از System.Data در PowerShell، تست provider برنامه روی .NET Core نیست. این gate برای SQL runtime آینده باز می‌ماند و طبق دامنهٔ جدید 2C، مانع تکمیل provisioning نیست.

هیچ principal کم‌اختیار مصوب تحویل نشده است؛ `BAZDIDSourceReader/BAZDIDWriter` یا login/user سفارشیِ runtime ساخته و هیچ grant جدیدی اعمال نشد. کاربران/نقش‌های داخلیِ عادی پایگاه با CREATE DATABASE وجود دارند. [permissions.review.sql](../../database/proposals/permissions.review.sql) فقط طرح بسته است. sysadmin فقط برای provisioning/بررسی محلی بود؛ استفادهٔ runtime از آن ممنوع می‌ماند. append-only بودن audit برای account برنامه بعد از ایجاد هویت و آزمون permission باید عملیاتی شود؛ CHECKهای داده جای ACL را نمی‌گیرند. پشتهٔ EOL و SQL RTM همچنان ریسک دارند؛ آمادگی Production ادعا نمی‌شود.

## بازتولید امن و بررسی دستی

فرمان‌های زیر راه بازبینی نسخهٔ نهایی‌اند و فایل guard را باز نمی‌کنند:

```powershell
.\database\tools\Invoke-BazdidDevelopmentDatabase.ps1 -Action Inspect
.\database\tools\Invoke-BazdidDevelopmentDatabase.ps1 -Action Verify
$caseHash = (Get-FileHash .\database\verification\checkpoint2c_rollback_cases.sql -Algorithm SHA256).Hash
.\database\tools\Invoke-BazdidDevelopmentDatabase.ps1 -Action Test -ApproveRollbackTests `
  -AuthorizationReference '553dc9cd-5abe-4eb0-9856-ee1763d5250b' -ReviewedScriptSha256 $caseHash
```

Test فقط با مجوز، روی همین پایگاه **خالی** و با rollback-only اجرا می‌شود؛ فایل CASEها باید پیش از محاسبهٔ hash بازبینی شود. ساخت دوبارهٔ DB موجود یا جدول‌های موجود خودکار نیست. برای پایگاه از صفر، پس از تصویب و preflight روی مقصد مجازِ فاقد DB، ابتدا Action CreateDatabase با switch ApproveLocalDdl و hash بازبینی‌شدهٔ فایل create، سپس CreateTables با hash نسخهٔ نهایی initial_tables استفاده می‌شود. دستورات DDL این مرحله با شناسهٔ مجوز همین مرحله اجرا شدند؛ تغییر دامنه/مقصد یا بازسازی، تصویب تازه می‌خواهد. repair برای پایگاه تازه با نسخهٔ نهایی لازم نیست و اینجا دوباره اجرا نمی‌شود. حذف/cleanup خودکار DB وجود ندارد؛ در شکست CREATE، ابتدا metadata و مرحلهٔ واقعی را بررسی کنید؛ در شکست ساخت جدول یا repair، transaction rollback می‌شود و علت باید پیش از تلاش بعدی رفع شود.

در VS Code با افزونهٔ رسمی Microsoft و Windows Authentication، اتصال محلی را باز و Databases را Refresh کنید:

```text
SQLSERVER2019 > Databases > BAZDID_Development > Tables
```

روی `BAZDID_Development` گزینهٔ New Query را بزنید و با SELECT DB_NAME زمینه را احراز کنید. [راهنمای VS Code](../guides/VSCODE_SQLSERVER_SETUP_FA.md) آموزش ابزار است؛ اتصال تصویری VS Code در این مرحله آزمایش نشده است. queryهای خواندنی زیر ردیف مشتری را نمی‌خوانند:

```sql
SELECT DB_NAME() AS CurrentDatabase;
SELECT s.name AS SchemaName,t.name AS TableName FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id=t.schema_id WHERE t.name LIKE N'BAZDID%';
SELECT OBJECT_NAME(c.object_id) AS TableName,c.name AS ColumnName,ty.name AS TypeName,
 c.max_length,c.is_nullable,c.is_computed FROM sys.columns AS c
JOIN sys.types AS ty ON ty.user_type_id=c.user_type_id
WHERE OBJECT_NAME(c.object_id) LIKE N'BAZDID%';
SELECT OBJECT_NAME(i.object_id) AS TableName,i.name,i.is_primary_key,i.is_unique
FROM sys.indexes AS i WHERE OBJECT_NAME(i.object_id) LIKE N'BAZDID%' AND i.index_id>0;
SELECT name,OBJECT_NAME(parent_object_id) AS ParentTable,
 OBJECT_NAME(referenced_object_id) AS ReferencedTable,is_disabled,is_not_trusted
FROM sys.foreign_keys WHERE OBJECT_NAME(parent_object_id) LIKE N'BAZDID%';
```

برای جزئیات ترتیب ستون index/FK و trusted بودن قیود از [query کامل metadata](../../database/verification/checkpoint2c_metadata.sql) استفاده کنید. snapshotها، داده یا backup نیستند و credential ندارند. فایل‌های mdf/ldf/log خصوصی خارج Git ماندند؛ منبع کارگزاری/Frontend تغییر نکرد. بستهٔ بررسی‌شده در commit `bf1c3c759d163ee716947af46f074b20d60fc043` با push عادی به `origin/main` ارسال شد؛ HEAD محلی/remote برابر و خود walkthrough و شاهد schema از GitHub با blob SHA برابر خوانده شدند. جزئیات و تمایز commit پیاده‌سازی از commit تکمیل گزارش در [گزارش همگام‌سازی](../GITHUB_SYNC_FA.md) ثبت است.

[PROVISIONING_SUMMARY.json](../checkpoint2c/PROVISIONING_SUMMARY.json) مرجع تجمیعیِ مجوز، تنظیمات، hash فایل‌های بازبینی‌شده و تفکیک آزمون SQL/برنامه است. کنترل پیش از commit: ۲۳ فایل بسته، ۱۰ Markdown، ۱۴۳ پیوند محلی و یک anchor معتبر؛ ۱۲۲ فایل فعلی و ۱۵۰ blob تاریخی main بدون هشدار راز باقی‌مانده اسکن شدند. ۴۸ واحد SQL شامل ۳۵ CASE و شش نمونهٔ خواندنی مستندات parse شدند؛ پنج بلوک PowerShell و ابزار نیز از نظر syntax صحیح‌اند. این کنترل استاتیک از اجرای واقعی ۳۵ آزمون SQL و ۴۳ آزمون برنامه جداست. فایل untracked کاربر با hash ثابت حفظ و از staging کنار گذاشته شد.

## نتیجه و گام بعد

**2C تکمیل شد: 15% + 2 = 17%.** این افزایش فقط بابت ساخت و verification واقعیِ همین پایگاه و سه جدول است؛ SQL runtime، account برنامه و mapping واقعی بسته نشده‌اند. 2D تکمیل یا شروع نشده و گام بعد فقط در درخواست جداگانه و پس از بررسی مستقل دوبارهٔ این شواهد است. O24، مجوز کم‌اختیار و mapping کارگزاری برای دامنهٔ بعدی باقی‌اند؛ OTP/Session/Info/media و Production مجوز این کار را ندارند.
