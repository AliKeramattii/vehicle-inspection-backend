# Checkpoint 2F — repositoryهای SQL با اتصال مسدود

در `2026-11-03`، بخش مستقل و آفلاین 2F طبق مجوز `ea650fd0-47e2-4d02-bf9b-0fb87f03a254` پیاده شد. **پذیرش کامل 2F مسدود است؛ پیشرفت 20% باقی می‌ماند.** O24 و O26 حل نشده‌اند. هیچ عملیات repository روی SQL، تغییر schema، grant یا دسترسی کارگزاری انجام نشد. این سند راهنمای کد موجودِ غیرفعال و آزمون‌های واقعاً اجراشده است؛ راهنمای اتصال موفق نیست.

## وضعیت اولیه و پیش‌نیاز

مبنای Git برابر `228d3769fc3471a2e3d597b9272c9629fa9ebe28` روی `main` بود؛ 2C ساخت سه جدول، 2D خوانندهٔ ساختگی و 2E طراحی Info را تحویل داده بودند. تنها تغییر اولیهٔ کاربر، فایل untracked در `src/Bazdid.Api/Properties/launchSettings.json` بود که خوانده/ویرایش/ثبت نشد؛ hash آن پیش/پس کنترل می‌شود. مخزن Frontend و آرشیو خصوصی در این مرحله استفاده یا تغییر نکردند.

AGENTS، PLAN، ادامهٔ AI، README، معماری، طراحی پایگاه، mapping، تصمیم‌های باز، امنیت، راهبرد آزمون، راهنماهای 2C/2D/2E، ابزار verification و پیش‌نویس permissions بررسی شدند. مجوز 2F، بازسازی پایگاه، نصب نرم‌افزار، اجرای DDL یا تصویب نام حساب ایجاد نمی‌کند.

verification خواندنیِ مستقل قبل و بعد از کار، همان پایگاه محلی را تأیید کرد: موتور `15.0.2000.5`، major `15`، Shared memory، Windows/NTLM، همان ماشین، بدون linked server، Cluster/HADR و پایگاه کاربری غیرمنتظره. compatibility برابر `150` و schema همان قرارداد 2C است: سه جدول، ۳۹ ستون، ۱۰ index، سه PK، سه unique، یک FK، ۱۳ CHECK trusted، دو rowversion و دو کلید computed persisted؛ هر سه جدول صفر ردیف داشتند. [شاهد schema](../checkpoint2f/DATABASE_VERIFICATION.json) و [metadata حساب‌ها](../checkpoint2f/RUNTIME_PRINCIPALS.json).

## تصمیم O24 و حدود شاهد provider

هیچ PackageReference، lockfile، SDK ساخت یا target تغییر نکرد. `System.Data.SqlClient 4.5.3` انتقالی از گراف موجود است؛ قید framework برابر `[4.5.3,4.6.0)` است. `4.8.6` بیرون این بازه است و override اجباری یا suppress هشدار اجرا نشد. restore قفل‌شدهٔ گراف فعلی موفق بود؛ restore آزمایشی با provider جایگزین انجام نشد و تعارض جدیدی به‌عنوان نتیجهٔ اجرا گزارش نمی‌شود.

وابستگی مستقیم provider به `Microsoft.Win32.Registry 4.5.0`، `System.Security.Principal.Windows 4.5.0`، `System.Text.Encoding.CodePages 4.5.0` و `runtime.native.System.Data.SqlClient.sni 4.4.0` در lock بررسی شد. بستهٔ native به assetهای `win-x64 / win-x86 / win-arm64` نسخهٔ `4.4.0` متکی است؛ asset x64 در NuGetFallbackFolder موجود بود. فایل `sni.dll` shared framework نیز با PE machine برابر `0x8664` و SHA256 در [شاهد provider](../checkpoint2f/PROVIDER_AUDIT.json) ثبت شد. ابتدا جست‌وجوی صرفاً cache کاربر فایل را نیافت؛ بررسی packageFolders مسیر fallback را مشخص کرد. هیچ DLL جدید نصب یا کپی نشد.

آزمون metadata در test host هدف `netcoreapp2.1` و فرآیند x64، اسمبلی managed را واقعاً بارگذاری کرد: NuGet `4.5.3`، assembly version برابر `4.4.0.1` و file version برابر `4.6.28516.10`. محل بارگذاری، asset ویندوزِ همان بسته بود؛ شمارهٔ اسمبلی معادل شمارهٔ بسته نیست. Runtime نصب‌شده `2.1.30` است و رشتهٔ گزارش‌شدهٔ `RuntimeInformation` در JSON عیناً نگهداری شده است. **این آزمون connection باز نکرد؛ انتخاب/بارگذاری native در اتصال، TLS، cancel واقعی و query برنامه تأیید نشدند.** metadata در PowerShell از `System.Data` خودش استفاده می‌کند و جای این شاهد نیست.

ممیزی تازه با SDK نصب‌شدهٔ `10.0.403` فقط به‌عنوان ابزار خواندنی، ۹ بستهٔ دارای advisory در گراف راهکار یافت؛ از جمله Critical برای Kestrel و Moderate/High برای SQL Client. SDK ساخت همچنان `2.1.818` است. [اعلان رسمی Microsoft دربارهٔ CVE-2024-0056](https://github.com/dotnet/announcements/issues/292) نسخهٔ `4.8.6` را اصلاح شاخهٔ System.Data.SqlClient معرفی می‌کند؛ [بستهٔ 4.5.3](https://www.nuget.org/packages/System.Data.SqlClient/4.5.3) نیز deprecated و دارای هشدار است. Encrypt و gate، remediation این آسیب‌پذیری‌ها محسوب نمی‌شوند.

گزینهٔ `Microsoft.Data.SqlClient 2.1.7` asset هدف 2.1 دارد، ولی [بستهٔ رسمی](https://www.nuget.org/packages/Microsoft.Data.SqlClient/2.1.7) deprecated است و طبق [چرخهٔ پشتیبانی Microsoft](https://learn.microsoft.com/en-us/sql/connect/ado-net/sqlclient-driver-support-lifecycle?view=sql-server-ver17) پشتیبانی شاخهٔ 2.1 در `2023-11-20` تمام شده است. سازگاری asset با پشتیبانی/امنیت یا موفقیت native/runtime برابر نیست؛ این گزینه نصب یا تأیید نشد. شاخه‌های جدید دارای پشتیبانی نیز صرف وجود asset استاندارد، تضمین پشتیبانی runtime پایان‌یافتهٔ 2.1 نیستند. نتیجهٔ بررسی، انتخاب provider امنِ متصل نیست: گراف موجود **فقط برای کد و آزمون آفلاین** باقی ماند و O24 باز است. تصمیم بازبینی‌شده دربارهٔ provider/ریسک و آزمون واقعی با هویت مجاز هنوز لازم است.

## حساب‌ها و O26

بررسی metadata، صفر login غیرسرویسی Windows کم‌اختیار طبق فیلتر ثبت‌شده، صفر کاربر Windows در پایگاه، صفر نقش از دو نام پیشنهادی و صفر عضو آن نقش‌ها نشان داد. نام دو principal مصوب نیز تحویل نشده است. این شمارش، آزمون effective permission نیست؛ هویت بررسی‌کننده sysadmin است و فقط برای خواندن metadata استفاده شد.

برای ادامه، مالک/DBA باید نام دقیق دو هویت Windows موجود، روش اجرای برنامه با آن‌ها و مجوز هرکدام را جداگانه تصویب کند:

| مسئولیت | حداقل موردنیاز این کد | دسترسی ممنوع/نیازمند بازبینی |
|---|---|---|
| Writer | SELECT/INSERT روی CustomerLinks؛ SELECT/INSERT/UPDATE روی RequestContexts؛ INSERT روی AuditLogs | sysadmin، db_owner، CONTROL، DELETE و DDL؛ SELECT/UPDATE/DELETE/ALTER audit |
| SourceReader | SELECT فقط روی اشیای مبدأ که بعداً دقیقاً تصویب می‌شوند | نوشتن مبدأ، نوشتن BAZDID و دسترسی فراگیر؛ اکنون هیچ شیء مبدأ مصوب نیست |

`permissions.review.sql` تاریخی، UPDATE روی CustomerLinks هم پیشنهاد می‌کند؛ کد فعلی به آن نیاز ندارد. این اختلاف برای بازبینی حداقل دسترسی ثبت شد؛ script تغییر یا اجرا نشد. در Windows Authentication هر connection با هویت اجرایی فرآیند باز می‌شود؛ تغییر نام در تنظیمات هویت جدید ایجاد نمی‌کند. اجرای دو هویت مستقل و بررسی عضویت‌های ارثی Windows/public باید جداگانه حل شود. هیچ impersonation یا حساب جایگزین ساخته نشد. اثبات نقش یا مقدار تنظیمات، جای اجرای آزمون با خود principalها را نمی‌گیرد.

## فایل‌ها و معماری موجود

| فایل ساخته‌شده | مسئولیت |
|---|---|
| `src/Bazdid.Api/Domain/Persistence/PersistenceContracts.cs` | interfaceها، نتیجهٔ create، خطای امن، metadata محدود، tokenهای defensive و کلید UTF-16 دقیق |
| `src/Bazdid.Api/Infrastructure/Sql/SqlRuntimeOptions.cs` | تنظیمات timeout، محدودیت مقصد و gate بسته |
| `src/Bazdid.Api/Infrastructure/Sql/SqlConnections.cs` | مرزهای اتصال، preflight آینده، transaction/dispose و نگاشت شمارهٔ خطا |
| `src/Bazdid.Api/Infrastructure/Sql/SqlCommands.cs` | متن ثابت SQL و همهٔ پارامترها با نوع/اندازه/nullability/value |
| `src/Bazdid.Api/Infrastructure/Sql/SqlRepositories.cs` | سه repository و materialization رکوردها |
| `src/Bazdid.Api/Infrastructure/Sql/SqlRegistration.cs` | validation تنظیمات و DI موجود |
| `src/Bazdid.Api/Infrastructure/Sql/AssemblyAccess.cs` | دسترسی internal برای دو اسمبلی تست؛ endpoint یا bypass اتصال ایجاد نمی‌کند |
| `src/Bazdid.Api/Application/LinkagePersistenceService.cs` | orchestration اتمیکِ snapshot معتبر سرور، linkage و audit |
| `tests/Bazdid.UnitTests/SqlPersistenceTests.cs` | پارامترها، شناسه‌ها، خطاها، gate، تنظیمات و metadata managed |
| `tests/Bazdid.UnitTests/LinkageTransactionTests.cs` | شکست جزئی، dispose، عدم retry و audit replay با double؛ آزمون SQL نیست |
| `tests/Bazdid.IntegrationTests/SqlRuntimeRegistrationTests.cs` | host/DI واقعی TestServer و رد startup ناامن، بدون SQL |
| `tests/Bazdid.IntegrationTests/SqlRepositoryConnectedTests.cs` | هشت آزمون واقعی SQL آمادهٔ بازبینی، همگی Skip صریح |

`Startup.cs` فقط DI را وصل می‌کند و `appsettings.json` تنظیمات خاموش SqlRuntime را اضافه می‌کند. سایر تغییرها اسناد جاری و هفت فایل شاهد `docs/checkpoint2f/` هستند: APPLICATION_VALIDATION، SQL_TEST_RESULTS، PROVIDER_AUDIT، RUNTIME_PRINCIPALS، DATABASE_VERIFICATION، HTTP_SMOKE و [کنترل تحویل](../checkpoint2f/DELIVERY_VALIDATION.json). ابزارهای موقت و TRXهای محلی در `.sync-tmp` ignored ماندند. کد reader/fixtureهای 2D، قرارداد HTTP، CORS و authentication تغییر نکردند.

`SqlRuntime.Enabled=false` پیش‌فرض همهٔ محیط‌هاست. `SqlRuntimeGate.ConnectedAcceptanceVerified` در کد false است؛ تنظیم environment یا دست‌کاری options آن را باز نمی‌کند. فعال‌سازی SQL در startup رد می‌شود و factory پیش از ساخت/open کردن connection، خطای `Blocked` می‌دهد. Production هر اتصال/نام principal یا Enabled فعال را رد می‌کند. تغییر gate فقط پس از بازبینی کد/تصمیم/مجوز و طی مسیر کنترل‌شدهٔ اعتبارسنجی بعدی مجاز است؛ این سند دستور تغییر آن نیست.

builder آینده فقط مقصد دقیق `lpc:.\SQLSERVER2019 / BAZDID_Development` با Windows، Encrypt و بدون TrustServerCertificate را می‌پذیرد؛ کلیدهای ورودی محدود به `Data Source`، `Initial Catalog`، `Integrated Security`، `Encrypt`، `TrustServerCertificate`، `Connect Timeout` و `Application Name` هستند. credential حتی خالی، مقصد دیگر و transport override رد می‌شوند. timeout اتصال از options می‌آید، retry اتصال صفر و ambient enlist خاموش است. command timeout پیش‌فرض ۱۰ ثانیه و بازهٔ ۱ تا ۶۰؛ اتصال پیش‌فرض ۵ و بازهٔ ۱ تا ۱۵ است. اعتماد گواهی محلی ابزار metadata به runtime منتقل نشد؛ TLS واقعی هنوز آزموده نشده است.

preflight اتصالِ آینده، مقصد/ماشین/Windows/LPC، نام principal، عدم sysadmin/db_owner/CONTROL و DML موردنیاز و ممنوعیت audit SELECT/UPDATE/DELETE/ALTER و DELETE/ALTER لینک‌ها را بررسی می‌کند. این کد اکنون اجرا نشده، بازرسی کامل مجوزهای ارثی نیست و جای آزمون واقعی O26 را نمی‌گیرد. سپس SET optionهای لازم computed index و XACT_ABORT را روی session اعمال می‌کند. SourceRead factory همیشه تنظیم‌نشده می‌ماند و هیچ SQL کارگزاری ندارد.

## جریان و SQL واقعیِ نوشته‌شده

ورودی داخلی `LinkagePersistenceService.PersistAsync` یک `BrokerageRequestSnapshot` معتبر سرور و correlation با ۳۲ نویسهٔ lower-hex است. ساختن این نوع یا دانستن ID، احراز هویت/مالکیت HTTP نیست؛ مصرف‌کنندهٔ آینده باید نشستِ درخواست مجاز را احراز کند. سرویس فقط شناسه‌های scope/customer/request، eligibility و نسخه/زمان منبع را به persistence می‌دهد؛ موبایل، VIN، referral خام و دادهٔ خودرو منتقل نمی‌شوند. HMAC در این جریان null است؛ کلید یا semantics referral اختراع نشده است.

گام‌ها در کد: اعتبارسنجی ورودی ← Begin transaction کوتاه‌عمر ← GetOrCreate مشتری ← GetOrCreate درخواست ← INSERT audit فقط برای درخواست تازه ← Commit. هر خطای پیش از commit باعث dispose/rollback و بستن connection می‌شود. خطای commit به `CommitOutcomeUnknown` تبدیل می‌شود؛ ممکن است سرور commit کرده باشد و retry خودکار وجود ندارد. commit API در این نسل synchronous است و cancellation فقط پیش از شروع آن کنترل می‌شود؛ cancellation حین commit تضمین نشده است. خطای rollback در dispose برای حفظ خطای اصلی بیرون داده نمی‌شود و connection همیشه dispose می‌شود؛ این رفتار هنوز روی SQL واقعی آزموده نشده است.

Find مشتری از `(BrokerageId, SourceSystem, SourceCustomerIdKey)` استفاده می‌کند؛ Find درخواست از scope و `SourceRequestIdKey`. کلیدها UTF-16LE بدون normalization، trim، uppercase یا تبدیل عددی‌اند و با `CONVERT(varbinary(256),nvarchar(128))` schema هماهنگ طراحی شده‌اند. شناسهٔ Unicode نامعتبر، خالی/تمام‌فاصله یا بیش از ۱۲۸ UTF-16 code unit پیش از SQL رد می‌شود. SQL Server واقعی هنوز این تطبیق repository را تأیید نکرده است.

نمونهٔ کد همین نسخه در `SqlCommands.Customer`:

```csharp
Parameter(command,"@CustomerId",SqlDbType.NVarChar,128,false,customerId);
Parameter(command,"@CustomerKey",SqlDbType.VarBinary,256,false,key);
```

همهٔ نام اشیا/ستون‌ها ثابت‌اند؛ ورودی در متن SQL درج نمی‌شود. زمان منبع `DateTime2` با scale=3، HMAC با `Binary(32)` nullable و key ID با `VarChar(32)` nullable، rowversion با `Binary(8)` و GUID با نوع صریح bind می‌شود. مقدار null به `DBNull.Value` می‌رود و HMAC/key به‌صورت جفت معتبر ساخته می‌شوند. آرایهٔ token/digest هنگام ورود/خروج کپی می‌شود.

GetOrCreate داخل همان transaction از `UPDLOCK,HOLDLOCK` بر natural key و unique constraint موجود به‌عنوان دفاع نهایی استفاده می‌کند؛ عملیات SELECT-then-INSERT بدون قفل/transaction نیست. درخواست تکراری معادل، رکورد موجود و Created=false برمی‌گرداند و metadata را پنهانی refresh نمی‌کند. یک مشتری می‌تواند دو درخواست داشته باشد. اگر درخواست قبلاً متعلق به مشتری دیگر باشد، `OwnershipConflict` صادر می‌شود؛ scope، شناسهٔ لینک و کلید واقعی مشتری در SQL نیز کنترل می‌شوند. CustomerLinks در این نسخه عملیات update ندارد و نیاز CAS برای آن ایجاد نشده است.

UPDATE metadata درخواست، Id، scope، کلید دقیق درخواست، CustomerLinkId و نسخهٔ موردانتظار را در WHERE دارد:

```sql
WHERE Id=@Id AND BrokerageId=@Brokerage AND SourceSystem=@Source
 AND SourceRequestIdKey=@RequestKey AND CustomerLinkId=@CustomerLinkId
 AND RowVersion=@ExpectedVersion;
```

صفر ردیف با خطای اختصاصی `51002` به ConcurrencyConflict تبدیل می‌شود؛ نبود رکورد scoped هم در این write به همین خطای امن می‌رسد و افشای وجود مالک دیگر نمی‌کند. خطای مالکیت اختصاصی `51001` است. 2601/2627 فقط DuplicateConflict، 547 فقط ConstraintViolation، -2 فقط Timeout و خطاهای منتخب اتصال Unavailable هستند؛ سایر خطاها Unexpected هستند. هیچ خطای SQL به NotFound تبدیل نمی‌شود، raw message/inner exception بیرون نمی‌رود و retry عمومی یا retry روی transaction احتمالاً aborted وجود ندارد. در رقابت، انتظار می‌رود قفل بازه از duplicate معمول جلوگیری کند؛ duplicate غیرمنتظره typed conflict است و caller باید کل transaction را خاتمه دهد. این ادعا هنوز پذیرش connected race نیست.

Audit فقط INSERT کدهای enum، ActorType=System، outcome ثابت، context/resource GUID و correlation دارد. SELECT موجود در batch فقط روی RequestContexts برای scope guard است؛ هیچ OUTPUT یا SELECT از AuditLogs ندارد و با INSERT-only طراحی شده است. API update/delete audit وجود ندارد. برای update metadata و audit مرتبط، caller داخلی باید همان transaction را به هر دو repository بدهد؛ endpoint یا refresh workflow آینده در این checkpoint ساخته نشده است.

## ترتیب کار و فرمان‌های اجراشده

ترتیب واقعی: خواندن دستورها/پیش‌نیازها و وضعیت Git؛ verification خواندنی schema؛ بررسی lock/advisory/API/SNI؛ ساخت قراردادها و factory بسته؛ ساخت command/repository/service/DI؛ نوشتن آزمون‌های آفلاین و هشت آزمون SQL غیرفعال؛ restore/build/test و رفع شکست‌های واقعی؛ metadata حساب‌ها؛ verification بعدی و smoke Kestrel با SQL خاموش؛ ساخت شواهد و مستندات؛ کنترل فایل/پیوند/راز/تاریخچه و Git.

فرمان‌های زیر از cwd ریشهٔ Backend واقعاً اجرا شدند؛ برچسب آن‌ها دستور نصب یا مجوز اتصال جدید نیست:

```powershell
dotnet restore Bazdid.sln --locked-mode
dotnet build Bazdid.sln --configuration Release --no-restore
dotnet test Bazdid.sln --configuration Release --no-build --no-restore --logger trx --results-directory C:/Projects/vehicle-inspection-backend/.sync-tmp/cp2f-pass
dotnet 'C:\Program Files\dotnet\sdk\10.0.403\dotnet.dll' package list --project Bazdid.sln --vulnerable --include-transitive --no-restore --format json
& ./database/tools/Invoke-BazdidDevelopmentDatabase.ps1 -Action Verify
```

برای metadata حساب‌ها، همان session PowerShell ابزار با Action Verify به‌صورت dot-source بار شد، target با Get-VerifiedTarget دوباره کنترل شد و SELECTهای aggregate روی `sys.server_principals` در master و `sys.database_principals/sys.database_role_members` در BAZDID_Development اجرا شدند. فیلتر login غیرسرویسی: type در U/G، فعال، خارج `NT % / BUILTIN%` و `IS_SRVROLEMEMBER('sysadmin',name)=0`. نام loginها یا credential ثبت نشد. هیچ EXECUTE AS، CREATE یا GRANT انجام نشد.

اجرای smoke با ProcessStartInfo، CreateNoWindow و محیط Development انجام شد؛ `dotnet` فایل `src/Bazdid.Api/bin/Release/netcoreapp2.1/Bazdid.Api.dll` را از cwd پروژه روی loopback/port آزاد اجرا کرد. SQL تنظیم نشد و launchSettings خوانده نشد. health و Swagger خوانده و فقط فرآیند اختصاصی با finally متوقف شد. [شاهد HTTP](../checkpoint2f/HTTP_SMOKE.json) موفقیت 200/200، یک مسیر عمومی و PathBase صحیح را ثبت می‌کند؛ IIS/SQL readiness را ثابت نمی‌کند.

دستور پیشنهادی بازتولید محلی، با همان محدودیت SQL خاموش:

```powershell
Set-Location C:\Projects\vehicle-inspection-backend\src\Bazdid.Api
$env:ASPNETCORE_ENVIRONMENT='Development'
$env:ASPNETCORE_URLS='http://127.0.0.1:5081'
dotnet ./bin/Release/netcoreapp2.1/Bazdid.Api.dll
```

سپس `GET /API/BAZDID/health/live` و `GET /API/BAZDID/swagger/v1/swagger.json` بررسی و فرآیند متوقف شود. هیچ endpoint عمومی جدیدی اضافه/اصلاح نشده و prefix دوبار افزوده نشده است. API تجاری برای فراخوانی repository وجود ندارد.

## آزمون‌ها، خطاهای واقعی و نتیجه

restore و build نهایی exit صفر داشتند؛ build **صفر warning/error** بود. در اجرای نهایی ۱۶۷ case کشف شد: **۱۰۹ unit + ۵۰ integration آفلاین = ۱۵۹ موفق، صفر شکست و ۸ SQL Skipped**. از ۱۵۹ موفق، تمام ۱۰۸ baseline و ۵۱ case تازه هستند. [شاهد برنامه](../checkpoint2f/APPLICATION_VALIDATION.json) و [نتایج مجزای SQL](../checkpoint2f/SQL_TEST_RESULTS.json) مرجع شمارش‌اند؛ جمع موفق‌ها پوشانندهٔ skipها نیست.

آفلاین‌ها شناسه‌های بزرگ، case، Unicode، فاصلهٔ انتهایی، ورودی injection، null/اندازه/نوع پارامتر، scope/owner/CAS در command، HMAC/token، enum خطا، timeout classification، بسته‌ماندن gate، configuration Production و DI واقعی را پوشش دادند. آزمون orchestration از double برای شکست customer/request/audit/commit و عدم retry استفاده می‌کند؛ rollback یا concurrency واقعی SQL از آن نتیجه نمی‌شود. سناریوهای synthetic reader مانند موبایل متعارض، referral مبهم، missing/invalid/unavailable و zero-sentinel در baseline 2D دوباره موفق شدند.

هشت تست SQL برای کلید دقیق/تکرار/چند درخواست/tenant، مالک نادرست، stale rowversion، rollback چندجدولی، رقابت ایجاد، effective permissions Writer، timeout واقعی و cancellation نوشته شده‌اند. `[Fact(Skip=SqlRuntimeGate.BlockReason)]` دلیل O24/O26 را آشکار می‌کند؛ هیچ flag محیطی برای عبور از این تصمیم وجود ندارد. تعداد اجرای connected **صفر** است. body این آزمون‌ها هنوز نیازمند بازبینی/اجرای کنترل‌شده پس از رفع موانع است؛ SourceReader به principal و mapping مصوب نیاز دارد و شمار audit قبل/پس باید verifier مجاز جداگانه داشته باشد، چون Writer مجوز SELECT audit ندارد. آزمون رقابت فعلی rollback دو transaction را پوشش می‌دهد؛ آزمون رقابت commitشده و اثبات idempotence پس از commit/قطع ارتباط هنوز جزو کار پذیرش متصل است.

شکست‌های واقعی هنگام توسعه، رفع و بازآزمایی شدند:

- اجرای اول، یک unit شکست خورد چون ContainsKey در SqlConnectionStringBuilder معنی حضور ورودی نداشت. ShouldSerialize جایگزین شد؛ تست‌های تکمیلی نشان دادند parser کلید credential خالی را هم حذف می‌کند. کنترل محدود پیش از parser و whitelist اضافه شد؛ دو اجرای میانی سه و سپس دو شکست داشتند و اجرای نهایی همه را گذراند.
- یک build میانی، دو CS1061 برای ContextConnection و NetworkLibrary داشت؛ این propertyها در API هدف وجود نداشتند. استفاده از آن‌ها حذف و کلید ناشناخته پیش از builder رد شد؛ build بعدی صفر error شد. UserInstance و گزینه‌های موجود همان نسل باقی ماندند.
- smoke کمکی ابتدا به‌دلیل خواندن UTF-8 بدون BOM در PowerShell 5 parse نشد؛ خواندن صریح UTF-8 اصلاح شد. سپس مسیر اشتباه `/health` پاسخ 404 داد؛ route واقعی `/health/live` خوانده و smoke نهایی موفق شد. این شکست، خرابی startup نبود.
- EvidencePath ابزار 2C خارج `docs/checkpoint2c` رد شد؛ guard تغییر نکرد و شاهد تازه از stdout با UTF-8 در مسیر 2F ثبت شد. هیچ شاهد تاریخی بازنویسی نشد.

۳۵ CASE مستقیم SQL متعلق به 2C تاریخی‌اند و اینجا تکرار نشدند. DDL، DML repository، effective permission با runtime principal، rollback/rowversion/race واقعی و SQL runtime connection در 2F اجرا نشده‌اند. رسانه، migration، recovery/redeployment 2G و Frontend نیز خارج این کار ماندند.

## امنیت، Git و ادامه

SQL static/پارامتری، محدودهٔ مالک، ورودی محدود audit، حذف raw exception، timeout و dispose در کد بررسی شدند. با وجود آزمون‌های موفق، provider قدیمی، EOL framework، SQL Server RTM، مجوزهای آزموده‌نشده، TLS/native/runtime اتصال و hosting واقعی IIS بازند؛ آمادگی Production ادعا نمی‌شود. راز، connection string محرمانه، principal ساختگی، کد اختصاصی کارگزاری یا دادهٔ واقعی در بسته وجود ندارد.

SHA مبنا در ابتدای این سند ثبت است؛ commit/push این تحویل فقط پس از کنترل محتوای قابل ارسال و تاریخچه انجام می‌شود. SHA واقعی و شواهد HEAD/فایل GitHub در [گزارش همگام‌سازی](../GITHUB_SYNC_FA.md) ثبت می‌شوند؛ این بند به‌تنهایی ادعای push موفق نیست. branch تاریخچهٔ اصلی و ZIP خصوصی ارسال نمی‌شوند؛ فایل untracked کاربر خارج commit می‌ماند.

**محاسبه: قبلی 20 + سهم پذیرفتهٔ این تحویل 0 = فعلی 20%؛ باقی‌مانده 80%.** وزن پایهٔ PLAN تغییر نکرد؛ سهم دو واحدی 2F فقط پس از provider متصلِ پذیرفته، repositoryهای واقعی SQL، دو هویت کم‌اختیار و effective permission، concurrency/transaction و regression کامل قابل کسب است. برآورد مشروط ادامهٔ همین 2F **22%** و هدف پایان Checkpoint 2 برابر **24%** است؛ 2G شروع نشده است.

گام بعد، رفع O24 و تحویل/تصویب دو principal و مجوزها در O26، سپس بازبینی gate و suite متصل با بررسی schema پیش/پس است. نام/مجوز حساب و هر role/user/grant یا انتخاب جدید provider نیاز به تصمیم مشخص دارد؛ هیچ اجرای خودکار DDL یا استفاده از sysadmin مجاز نیست. پس از این تحویل توقف می‌شود و 2G، OTP، Session، Info، رسانه یا ماژول دیگری شروع نمی‌شود.
