# امکان‌سنجی مهاجرت P0 برای رفع مانع Checkpoint 2F

تاریخ بررسی: `2026-11-03`؛ مجوز: `700bf7eb-76b8-4b84-ad87-1096b3eb12dd`؛ مبنای Git: `ce2d6c6f2be103b34135561cb81c5a4210b8e56d`. **مهاجرت به .NET 10 از نظر نمونهٔ محدود فنی امکان‌پذیر است؛ برنامهٔ اصلی مهاجرت نکرده و 2F هنوز پذیرش SQL ندارد. پیشرفت 20% باقی است.**

این راهنما کار انجام‌شده در P0، محدودیت شاهد و برنامهٔ پیشنهادی بعد از تصویب را جدا می‌کند. [خلاصهٔ قابل‌پردازش نتایج](../checkpoint2f/P0_FEASIBILITY_RESULTS.json)، [ماتریس فایل‌به‌فایل](../checkpoint2f/P0_MIGRATION_FILE_PLAN_FA.md) و [بستهٔ قبلی تصویب provider/حساب‌ها](../checkpoint2f/CONTINUATION_APPROVAL_FA.md) مکمل آن هستند. prototype و خروجی خام آن عمداً در Git نیستند؛ خلاصهٔ گزینش‌شده، جای کد قابل‌بازتولید مستقل در clone تازه را نمی‌گیرد.

## وضعیت اولیه و مرز مجوز

ریشهٔ مستقل Backend همان `C:\Projects\vehicle-inspection-backend` است. main و origin/main در شروع روی SHA مبنا بودند. تنها فایل شخصی untracked، `src/Bazdid.Api/Properties/launchSettings.json`، بدون خواندن محتوای آن حفظ شد. اثر انگشت ۶۴ فایل شامل source، test، سه lockfile، SDK/props/solution، SQL/deployment و فایل شخصی پیش و پس از آزمایش یکسان بود. Frontend و آرشیو خصوصی استفاده یا تغییر نکردند.

برنامهٔ اصلی هنوز `netcoreapp2.1`، SDK `2.1.818`، Runtime `2.1.30`، C# `7.3` و IIS `OutOfProcess` دارد. `SqlRuntime.Enabled=false` و `SqlRuntimeGate.ConnectedAcceptanceVerified=false` دست‌نخورده‌اند. هیچ endpoint، schema، migration، permission یا بستهٔ runtime اصلی تغییر نکرد. در P0 حتی metadata پایگاه خوانده نشد؛ وضعیت DB/حساب در اسناد قبلی، شاهد تاریخی است.

مجوز این مرحله فقط مطالعه، نمونهٔ آفلاینِ موقت، regression اصلی و انتشار اسناد امن بود. نصب سیستم، تغییر تنظیم عمومی SDK، مهاجرت canonical، SQL connection، حساب/role/login، task، ACL، certificate، registry و فعال‌سازی مجاز نبود و انجام نشد. token فعلی Windows غیرمدیر و فرآیند نمونه x64 بود؛ نقش SQL این token در این مرحله پرسیده نشد.

## علت مانع نسخهٔ موجود

خود metapackage `Microsoft.AspNetCore.App 2.1.30` در گراف اصلی قید `System.Data.SqlClient [4.5.3,4.6.0)` دارد. قیود CodePages، Caching.Memory، Pkcs و Channels نیز افزودن سادهٔ driverهای جدید را محدود می‌کنند. `System.Data.SqlClient 4.5.3` انتقالی است؛ حذف یک PackageReference مستقیم، این گراف را اصلاح نمی‌کند. جدول قیود، نه candidate و گراف ثبت‌شده در [PROVIDER_CANDIDATES.json](../checkpoint2f/PROVIDER_CANDIDATES.json) و [بررسی ادامه](../checkpoint2f/CONTINUATION_REVIEW.json) موجود است؛ lockfileهای اصلی عوض نشدند.

در شاهد قبلی، ۹ بستهٔ گراف legacy دارای advisory بودند، از جمله مورد Critical در Kestrel؛ این بررسی همان نتیجه را پاک یا به نتیجهٔ تازهٔ audit اصلی تبدیل نمی‌کند. پایان پشتیبانی 2.1 در `2021-08-21` است. pin نسخهٔ جدید در محدودهٔ ناسازگار، سرکوب warning یا تعویض دستی DLL راه پذیرفتنی رفع مانع نیست. [چرخهٔ عمر رسمی .NET](https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core).

## محیط و ساختار نمونهٔ واقعاً ساخته‌شده

SDKهای نصب‌شده شامل `2.1.818`، `3.1.426`، `8.0.427`، `9.0.320`، `10.0.302`، `10.0.400` و `10.0.403` بودند. نمونه با SDK موجود `10.0.403` و Runtime موجود `10.0.14` اجرا شد؛ چیزی نصب نشد. `global.json` محلی با `rollForward=disable` انتخاب SDK را فقط زیر پوشهٔ نمونه محدود کرد.

```text
.sync-tmp/p0-net10-spike-20261103/
  global.json                 SDK و runner مستقل
  Directory.Build.props       net10.0 / win-x64 و cache مستقل
  NuGet.Config                فقط feed رسمی و بدون fallback
  P0Spike.sln
  Api/P0.Api.csproj
  Api/Program.cs
  Api/SpikeStartup.cs
  Api/SqlOfflineProbe.cs
  Api/appsettings.json
  Tests/P0.Tests.csproj
  Tests/SpikeTests.cs
  Api/packages.lock.json
  Tests/packages.lock.json
  .packages/                  cache موقت؛ منتشر نمی‌شود
  MtpResultsVerified/          TRX خام؛ منتشر نمی‌شود
```

تمام این مسیر با `.gitignore` موجود پوشیده است؛ هیچ project، lockfile، source یا bin/obj نمونه در commit نیست. props محلی جست‌وجوی props والد را قطع می‌کند؛ مسیر restore، target و runner با canonical مشترک نیستند. API نمونه عمداً با C# `7.3` build شد؛ مهاجرت domain الزاماً به بازنویسی زبان نیاز ندارد. تست نمونه با ابزار جدید اجرا شد و این موضوع مجوز تغییر زبان یا runner نسخهٔ اصلی نیست.

| جزء آزمایش | نسخهٔ دقیق نهایی | شاهد/کارکرد |
|---|---|---|
| Runtime / SDK | `10.0.14` / `10.0.403` | نصب موجود؛ `net10.0`, `win-x64`, framework-dependent |
| SQL Client | `Microsoft.Data.SqlClient 6.1.7` | compile و managed load؛ اتصال صفر |
| اصلاح انتقالی امنیتی | `System.Security.Cryptography.Pkcs 10.0.14` | pin مستقیم سازگار با حداقل driver |
| MVC JSON | `Microsoft.AspNetCore.Mvc.NewtonsoftJson 10.0.14` | حفظ سیاست serializer موجود |
| JSON | `Newtonsoft.Json 13.0.4` | camelCase/UTC/MaxDepth32/TypeNameHandling.None |
| Test host | `Microsoft.AspNetCore.TestHost 10.0.14` | Generic Host و TestServer |
| آزمون | `xunit.v3.mtp-v2 4.0.2` | Microsoft.Testing.Platform؛ ۱۴ case |
| TRX | `Microsoft.Testing.Extensions.TrxReport 2.5.1` | گزارش واقعی مستقل |
| SNI انتقالی | `Microsoft.Data.SqlClient.SNI.runtime 6.0.3` | بررسی PE، hash و کپی خروجی x64 |

گراف کامل گزینش‌شده از lockها در JSON نتایج ثبت است: بخش net10.0 برای API شامل ۲۶ و برای Tests شامل ۵۰ ورودی resolved، و بخش RID به‌ترتیب ۴ و ۷ ورودی اضافه دارد؛ این‌ها شمار بخش‌های lock هستند و نباید با جمع بسته‌های یکتا اشتباه شوند. هیچ `System.Data.SqlClient` یا metapackage قدیمی App در این گراف مستقل نیست. نسخه‌های انتقالی resolve و lock شدند؛ lock نمونه به نسخهٔ اصلی منتقل نشد.

## مراحل واقعی و نتایج

۱. وضعیت Git، قواعد، walkthrough قبلی و همهٔ projectهای application/test بررسی و hash فایل‌های محافظت‌شده ثبت شد. اتصال SQL یا اجرای ابزار Verify انجام نشد.

۲. solution مستقل، cache/feed/props/global مستقل و API کنترلری بسیار کوچک ساخته شد. ابتدا همان `WebHost.CreateDefaultBuilder().UseStartup()` کامپایل شد: build موفق با چهار warning و صفر error؛ دو `ASPDEPR008` برای host قدیمی و دو هشدار NuGet برای Pkcs. این شاهد، حفظ مدل قدیمی را از نظر کامپایل ممکن ولی برای نگهداری نامطلوب نشان داد.

۳. بدون حذف `Startup`، میزبان نمونه به Generic Host تغییر کرد. این الگو build بدون warning داد؛ Minimal API یا `WebApplication` پیش‌نیاز مهاجرت نیست. [راهنمای رسمی منسوخ‌شدن WebHost](https://learn.microsoft.com/en-us/dotnet/core/compatibility/aspnet-core/10/webhostbuilder-deprecated).

```csharp
using (var host = Host.CreateDefaultBuilder(args)
    .ConfigureWebHostDefaults(web => web
        .UseStartup<SpikeStartup>()
        .UseUrls("http://127.0.0.1:0"))
    .Build())
{
    await host.StartAsync();
    await host.WaitForShutdownAsync();
}
```

این قطعهٔ کوتاه از نمونه است؛ در نمونه، پس از Start نشانی loopback برای helper چاپ می‌شود. نشانی/port پویا و فقط محلی است. در IIS آینده، binding و PathBase باید از میزبان واقعی بیاید؛ `UseUrls` آزمایش به deployment منتقل نمی‌شود.

۴. restore اولیه، Pkcs `9.0.11` را از حداقل driver برگزید و `NU1902/NU1903` داد. دو advisory رسمی `CVE-2026-70162` و `CVE-2026-84008` به ترتیب Moderate/High بودند. در محدودهٔ باز dependency، pin صریح `10.0.14` انتخاب و restore/locked restore/build/audit تکرار شد. suppress یا downgrade اجباری انجام نشد. audit نهایی هر دو project در تاریخ بررسی **صفر بستهٔ دارای هشدار شناخته‌شده** داشت؛ این نتیجه تضمین نبود آسیب‌پذیری نیست. canonical همچنان گراف قبلی را دارد. [اعلان Microsoft اول](https://github.com/dotnet/announcements/issues/454)، [اعلان دوم](https://github.com/dotnet/announcements/issues/468).

۵. اجرای اول runner قدیمی VSTest با MTPv2 قبل از شروع caseها شکست خورد. فقط global/project نمونه به `Microsoft.Testing.Platform` و بستهٔ صریح `xunit.v3.mtp-v2` تغییر کرد؛ TestSdk/runner قدیمیِ نمونه حذف شد. اولین اجرای واقعی ۱۴ case، ۱۰ موفق/۴ ناموفق داشت: exception اعتبارسنجی در `Build` ایجاد می‌شد ولی assertion تنها `Start` را می‌پوشاند. assertion به کل Build+Start گسترش یافت؛ validation ضعیف نشد. اجرای نهایی **۱۴ موفق، صفر شکست و صفر skipped** است. [runner رسمی .NET](https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-test-mtp)، [راهنمای xUnit](https://xunit.net/docs/getting-started/v3/microsoft-testing-platform).

۶. CLI مستقل `--inspect-provider`، `SqlConnection` خالی و بسته، command/parameter ساختگی و builder را ساخت؛ assembly managed واقعاً بارگذاری شد. متدهای async تنها به delegate متصل شدند؛ هیچ delegate، Open، Execute یا transaction فراخوانی نشد. inspection native تنها خواندن بایت PE بود.

۷. Kestrel واقعاً در Development و روی `127.0.0.1` با port موقت شروع شد. helper سه درخواست HTTP فرستاد، status/JSON/correlation/no-store را بررسی و در finally فقط فرآیند متعلق به خود را متوقف کرد. IIS، مرورگر، HTTPS و SQL در این smoke آزموده نشدند.

۸. regression canonical جداگانه با SDK اصلی اجرا شد؛ سپس hash تمام ۶۴ فایل دوباره برابر بود. اسناد، ماتریس و شواهد امن ساخته شدند؛ نتایج Git پس از راستی‌آزمایی در گزارش همگام‌سازی ثبت می‌شوند.

| اجرای تازه | نتیجهٔ واقعی | محدودیت |
|---|---|---|
| canonical restore/build | exit صفر؛ ۰ warning / ۰ error | ارتقا یا اصلاح امنیت نیست |
| canonical unit | ۱۰۹ موفق، صفر شکست | همان source موجود |
| canonical integration | ۵۰ موفق، صفر شکست، **۸ SQL Skipped** | هیچ پذیرش SQL کسب نشد |
| P0 restore/locked restore/build نهایی | exit صفر؛ ۰ warning / ۰ error | project جدا؛ source اصلی port نشده |
| P0 TestServer | ۱۴ موفق، صفر شکست/skip | جای IIS نیست |
| P0 Kestrel smoke | ۳ از ۳ موفق | فقط HTTP loopback |
| P0 NuGet audit نهایی | صفر بستهٔ flagged | فقط گراف مستقل و advisoryهای فعلی |
| managed/native inspection | managed موفق؛ PE x64 موجود | native load/SSPI/TLS/connect اجرا نشده |

۱۴ case شامل سه مسیر، چهار config نامعتبر، دو PathBase شبیه‌سازی‌شدهٔ IIS، یک خطای امن، یک DI/JSON، دو CORS دقیق و یک inspection آفلاین provider بودند. smoke واقعی: `/API/BAZDID/health/live` برابر ۲۰۰ با `{"status":"alive"}`؛ `/health/live` و `/API/BAZDID/API/BAZDID/health/live` برابر ۴۰۴؛ هر سه JSON، no-store و correlation معتبر داشتند. این‌ها endpoint موقت همان نمونه‌اند؛ **endpoint اصلی اضافه یا اصلاح نشد**.

## بررسی SQL Client و حدود شاهد

سری `6.1` LTS و patch فعلی `6.1.7` تا `2028-08-14` پشتیبانی دارد. .NET 10 LTS تا `2028-11-14` است؛ در طول عمر برنامه patchهای جاری هر دو لازم‌اند. .NET 8/9 در زمان بررسی نزدیک پایان پشتیبانی `2026-11-10` هستند و برای مقصد تازه ترجیح داده نشدند. پشتیبانی driver به runtime و OS پشتیبانی‌شده هم وابسته است. [سیاست رسمی driver](https://learn.microsoft.com/en-us/sql/connect/ado-net/sqlclient-driver-support-lifecycle)، [سیاست .NET](https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core).

بستهٔ 6.1.7 assetهای .NET Framework `4.6.2`، `net8.0`، `net9.0` و `netstandard2.0` دارد؛ روی net10.0 این آزمایش، reference از `ref/net9.0` و runtime مخصوص Windows از `runtimes/win/lib/net9.0` انتخاب شد. نبود پوشهٔ net10.0 شکست سازگاری نیست؛ شاهد واقعی build/load و ماتریس پشتیبانی هر دو لازم‌اند. SQL Server 2019 در ماتریس پشتیبانی driver است، ولی اتصال به instance محلی با این driver آزمایش نشده است. [بستهٔ رسمی](https://www.nuget.org/packages/Microsoft.Data.SqlClient/6.1.7)، [دانلود و سازگاری provider](https://learn.microsoft.com/en-us/sql/connect/ado-net/download-microsoft-sqlclient-data-provider).

| موضوع | مشاهده/تغییر لازم | پذیرش باقی‌مانده |
|---|---|---|
| managed | AssemblyVersion=`6.0.0.0`؛ FileVersion=`6.17.26253.4` | این نسخه‌ها با شمارهٔ package یکی نیستند |
| SNI Windows x64 | PE machine=`0x8664`؛ ۵۶۹۲۴۰ بایت؛ hash در JSON | بارگذاری native و وابستگی‌های OS/SSPI باید با process واقعی تأیید شوند |
| namespace/type | همهٔ `SqlConnection/SqlCommand/SqlTransaction/SqlException/SqlParameter` از `Microsoft.Data.SqlClient` شوند | تعویض یک using کافی نیست؛ interface و test همزمان |
| builder Encrypt | نوع `SqlConnectionEncryptOption`؛ Mandatory و Trust=false صریح | `!builder.Encrypt` قدیمی باید اصلاح شود؛ مقدار ToString در نمونه `True` بود |
| command/parameter | CreateCommand و parameter نوع/طول‌دار build و ساخته شدند | اجرای query، timeout، result mapping و خطای واقعی آزمایش نشده |
| async/cancel | OpenAsync، ExecuteNonQueryAsync و ExecuteReaderAsync با CancellationToken bind شدند؛ CommitAsync/RollbackAsync در reflection موجودند | لغو روی lock/network، disposal/pooling، commit مبهم و rollback باید متصل تست شوند |
| transaction | شکل SqlTransaction موجود است؛ تبدیل اجباری domain به async لازم نیست | مرز transaction/rowversion/idempotence برنامه باید حفظ شود؛ transaction واقعی P0 صفر |
| Windows Authentication | IntegratedSecurity=true در builder؛ بدون username/password | token مستقل Writer/Reader، SID، ORIGINAL_LOGIN، نبود admin/db_owner و SSPI واقعی لازم است |
| TLS | Mandatory، TrustServerCertificate=false؛ بدون DataSource | نام/SAN، trust، اعتبار/EKU، private-key ACL و transport واقعی بازند |

نمونهٔ واقعیِ سیاست builder در `SqlOfflineProbe`:

```csharp
var builder = new SqlConnectionStringBuilder {
    IntegratedSecurity = true,
    Encrypt = SqlConnectionEncryptOption.Mandatory,
    TrustServerCertificate = false,
    ConnectRetryCount = 0,
    Enlist = false
};
bool mandatory = builder.Encrypt.Equals(SqlConnectionEncryptOption.Mandatory);
```

DataSource، credential و اتصال در این کد وجود ندارند. `Encrypt=Strict` متکی به TDS8/SQL Server 2022 است و برای هدف SQL2019 انتخاب نشده؛ Mandatory به معنی Strict نیست. Shared memory شاهد TLS شبکه نیست؛ تغییر احتمالی guard از LPC به TCP loopback و endpoint دقیق باید جدا تصویب شود. bypass با Trust=true یا Encrypt=false پیشنهاد نمی‌شود. [رفتار encryption/certificate](https://learn.microsoft.com/en-us/sql/connect/ado-net/encryption-and-certificate-validation).

## حفظ قرارداد HTTP، امنیت و domain در مهاجرت آینده

کنترلرها و `Startup` قابل حفظ‌اند. پیشنهاد، Generic Host + `AddControllers().AddNewtonsoftJson()` و endpoint routing است؛ `SetCompatibilityVersion(2.1)` حذف و `IHostingEnvironment` با `IWebHostEnvironment` جایگزین شود. API باید فقط زیر `/API/BAZDID/` بماند. در Standalone تنها یک UsePathBase؛ در IIS، PathBase از sub-application و ANCM، بدون افزودن دوباره. ترتیب پیشنهادی correlation → exception → status JSON → PathBase/guard → سیاست‌های امنیت/Swagger → routing/CORS → endpoints با تست دقیق همان رفتار بازبینی شود.

حفظ camelCase، UTC، null/default، MaxDepth، enum/date و خطای JSON پیش‌نیاز پذیرش است. نمونه policy تنظیمات را نشان داد، اما همهٔ DTOهای canonical در net10 اجرا نشده‌اند. Default formatter جدید نباید بی‌صدا `System.Text.Json` شود. رفتار `[ApiController]`، 400/404/405، response headers، HTTPS redirect/HSTS و ForwardedHeaders زیر IIS باید در port اصلی regression شوند. origin دقیق و عدم credentials فعلی حفظ شود؛ اضافه‌کردن cookie/CSRF/CORS credentials کار این مهاجرت نیست. هیچ raw exception، SQL text، connection string یا payload مشتری log نشود.

Swagger4 فعلی مستقیم منتقل نمی‌شود. candidate بررسی‌شده از feed رسمی، `Swashbuckle.AspNetCore 10.3.1` است؛ نسل جدید از Microsoft.OpenApi2+ و مدل‌های متفاوت استفاده می‌کند. حفظ Swagger2/basePath یا تغییر آگاهانهٔ نسخهٔ سند باید جدا تصمیم و آزمون شود؛ JSON/UI و عدم host hardcode، مسیر نسبی UI، منع query و disabled بودن Production حفظ شوند. سازگاری `Swashbuckle.AspNetCore.Newtonsoft` و گراف دقیق این مجموعه در P0 build/audit نشده؛ **انتخاب نهایی Swagger و parity OpenAPI یک gate مهاجرت واقعی است**. صرف شمارهٔ candidate مجوز افزودن package نیست. [صفحهٔ package](https://www.nuget.org/packages/Swashbuckle.AspNetCore/10.3.1)، [راهنمای رسمی مهاجرت v10](https://github.com/domaindrivendev/Swashbuckle.AspNetCore/blob/master/docs/migrating-to-v10.md).

قراردادهای immutable domain، reader ساختگی، مالکیت درخواست، HMAC به‌عنوان شناسهٔ مستعار، پارامترهای SQL، کنترل rowversion و write فقط BAZDID بازنویسی تجاری نمی‌خواهند. `LinkagePersistenceService` همچنان transaction واحد link/context/audit را مدیریت می‌کند؛ نوع‌های provider عوض می‌شوند، نه معنا. `SqlErrors.Map` با شماره‌های واقعی بعداً تأیید شود. SourceReader همچنان unconfigured و fail-closed بماند. schema کارگزاری حدس زده نشود. gate ثابت بسته و تنظیم SQL خاموش حتی پس از port آفلاین باقی بمانند.

Authentication/OTP/session در نسخهٔ حاضر پیاده نشده‌اند. migration فقط startup rejection فعلی را حفظ می‌کند؛ طراحی بعدی cookie/ticket/DataProtection/CSRF باید بر APIهای نسل جدید بازبینی شود. keyring خارج release و با identity/ACL مصوب پایدار خواهد بود؛ این P0 key تولید یا ACL تغییر نداد. هیچ HMAC، secret، مشتری یا fallback آزمایشی Production وارد نمونه نشد.

## IIS، Windows Server و rollback پیشنهادی؛ اجرا نشده

ماتریس رسمی فعلی .NET10، Windows Server x64 نسخه‌های 2012/2012R2/2016/2019/2022/23H2/2025 را فهرست می‌کند؛ **2012 و 2012R2 به ESU نیاز دارند**. بنابراین «Server2012R2 به‌تنهایی کافی است» نتیجهٔ درستی برای یک نصب تازه نیست. حد پایین فهرست مشروط 2012+ESU و پایین‌ترین مورد فهرست بدون شرط ESU، 2016 است؛ پشتیبانی چرخهٔ عمر خود OS و آخرین patch هم باید برقرار باشد. پیشنهاد عملی برای مقصد تازه، Server2022 یا 2025 x64 با IIS10 و patch جاری است. نسخه/patch/IIS واقعی مقصد هنوز معلوم یا آزمایش نشده‌اند؛ این نمونه فقط روی Windows محلی اجرا شد. [ماتریس رسمی OS برای .NET10](https://github.com/dotnet/core/blob/main/release-notes/10.0/supported-os.md).

برای staging بعد از تصویب زیرساخت: Runtime/ASP.NET Core10 servicing جاری و Hosting Bundle/ANCM سازگار، app pool اختصاصی بدون CLR و x64، OutOfProcess حفظ‌شده، sub-application دقیق، identity کم‌اختیار، certificate معتبر HTTPS و محدودیت دسترسی لازم‌اند. framework-dependent با SDK روی ماشین build ساخته و runtime روی سرور اجرا شود؛ self-contained هم ANCM را حذف نمی‌کند. نصب/repair bundle بعد از IIS، reboot/recycle و اثر module مشترک بر سایر appها باید در change مصوب بررسی شوند. backward compatibility مستند ANCM برای نسخه‌های in-support است؛ سازگاری با2.1 را از آن نتیجه نگیرید. [مستند ANCM](https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/aspnet-core-module).

آزمون آینده روی میزبان واقعی شامل startup/shutdown/recycle، PathBase فقط یک بار، HTTPS/forwarded scheme از proxy مورداعتماد، health/Swagger، JSON errors، origin، identity فایل، keyring و نبود public media است. P0 فقط شبیه‌سازی IIS در TestServer داشت؛ نصب bundle یا deployment2G انجام نشده است.

rollback پیشنهادی: artifact و config بدون رازِ نسخهٔ پیشین با hash نگهداری، در staging مصوب و app pool جدا آزمایش، اتصال/SQL gate بسته، سپس با failure در gate پذیرش، ترافیک/نسخه به artifact آزموده‌شده برگردد. release switch نباید keyring یا media مشترک را حذف کند. چون مهاجرت آفلاین schema را تغییر نمی‌دهد، rollback آن DB migration ندارد؛ آزمون متصل آینده cleanup/verifier مستقل می‌خواهد. downgrade عمومی ANCM روی میزبان مشترک، بخشی از rollback خودکار نیست. برگشت به2.1 پشتیبانی امنیتی ایجاد نمی‌کند و گزینهٔ انتشار عمومی پذیرفته‌شده نیست. هیچ rollback یا deployment واقعی در این مرحله لازم/اجرا نشد.

## چک‌لیست نهایی تصویب P1/P2؛ همه منتظر تصویب مستقل

مقایسهٔ proposalها با connection guard و repositoryها انجام شد: Writer برای CustomerLinks به UPDATE نیاز ندارد؛ context UPDATE دارد؛ audit فقط INSERT و خواندن توسط verifier مستقل است. Reader نباید هنوز به مبدأ دسترسی داشته باشد. دو script بدون تغییر و با flag صفر حفظ شدند:

| script | SHA256 همین نسخه |
|---|---|
| [development_logins.review.sql](../../database/proposals/development_logins.review.sql) | `9099DE3DCE8E77FC037D1BDC6D5B8649BA835253DF067E6B0E8D89B121B5B15F` |
| [permissions.review.sql](../../database/proposals/permissions.review.sql) | `9888862C6997EB2AB0FC2EFFAAC6559E6399905E1290FEC506100AD46609A396` |

جزئیات کامل و recovery/ابطال در [بستهٔ تصویب موجود](../checkpoint2f/CONTINUATION_APPROVAL_FA.md) است. این چک‌لیست مصوب یا اجراشده نیست:

- [ ] مالک، نام‌های دقیق `.\BAZDIDDevWriter` و `.\BAZDIDDevReader` را فقط برای instance محلی `SQLSERVER2019` و DB `BAZDID_Development` تصویب کند؛ نام machine-qualified و SIDهای تازه در کانال امن ثبت شوند. اکنون وجود/نبود آن‌ها به‌صورت زنده دوباره بررسی نشده است.
- [ ] مسئول Windows با تصویب P1 فقط دو local user استاندارد، credential مستقل، Batch logon برای runner محدود، منع interactive/RDP و بدون Administrators ایجاد کند. ReadExecute به bundle آزمون و Write تنها به پوشهٔ نتیجهٔ اختصاصی؛ ACL/right/task/secret پیش از اجرا جدا بازبینی شوند. task موقت Limited و اجرای دو هویت در process جدا؛ اکنون هیچ task اجرا نشده است.
- [ ] DBA در P2 با مجوز و hash مصوب، machine/instance/DB، نبود Production/cluster/HADR/linked server/DB غیرمنتظره، نبود principal قبلی و تطبیق SID را بررسی کند؛ login FROM WINDOWS و user/roleهای دقیق فقط در guard مصوب و transaction بسازد. `AllowDdl=0`، approval و SIDهای NULL پیش‌فرض بسته‌اند؛ permission script را بدون تصویب باز نکنید.
- [ ] نام roleها دقیقاً `BAZDIDWriter` و `BAZDIDSourceReader` است؛ user هرکدام همان نام machine-qualified مربوط به login Windows خود را دارد. user مربوط به `BAZDIDDevWriter` فقط به نقش `BAZDIDWriter` و user مربوط به `BAZDIDDevReader` فقط به نقش `BAZDIDSourceReader` افزوده شود؛ عضویت نقش دیگری از این طرح مجاز نمی‌شود.
- [ ] Writer: فقط CONNECT و `SELECT,INSERT` روی `dbo.BAZDIDCustomerLinks`؛ `SELECT,INSERT,UPDATE` روی `dbo.BAZDIDRequestContexts`؛ `INSERT` روی `dbo.BAZDIDAuditLogs`. Customer UPDATE/DELETE/ALTER، context DELETE/ALTER، audit SELECT/UPDATE/DELETE/ALTER و CREATE TABLE/VIEW/PROCEDURE/FUNCTION/SCHEMA منع شوند. هیچ sysadmin/db_owner/db_ddladmin/CONTROL یا delegation/schema-wide grant نگیرد.
- [ ] Reader: فقط CONNECT؛ SELECT/INSERT/UPDATE/DELETE/ALTER روی هر سه جدول BAZDID و CREATEهای بالا منع شوند؛ **هیچ SELECT روی هیچ شیء کارگزاری تا تصویب mapping/شیء دقیق**. O24/O26 مجوز مبدأ نیستند.
- [ ] verifier مستقل با هویت و scope حداقلی مصوب، audit/count و نتیجهٔ transaction را بررسی کند؛ Writer برای مشاهدهٔ audit یا cleanup حق اضافه نگیرد. آزمون fixture فقط ساختگی و rollback-only؛ رقابت commitشده/cleanup مجوز جدا می‌خواهد.
- [ ] اجرای آزمون بعدی با خود token دو حساب: نام/SID Windows، ORIGINAL_LOGIN/DB_NAME/transport، نبود admin/db_owner، عضویت گروه/public و grants ستونی/مستقیم، تمام allow/denyهای جدول و DDL اثبات شوند؛ column GRANT می‌تواند ارزیابی table DENY را پیچیده کند. فقط دیدن role یا اتصال موفق کافی نیست. در حق اضافه/هویت نادرست متوقف شوید.
- [ ] TLS/certificate و transport دقیق در P3 مستقل تصویب شوند؛ احتمال نیاز TCP loopback و guard جدید، bypass خودکار ندارد. پس از port، P4 شامل native/SSPI/provider واقعی، cancel/timeout/locking/rowversion/atomicity، pooling/disposal، commit مبهم و مشاهده با verifier باشد. بستن O24/O26 یا بازکردن gate فقط پس از شواهد و تصویب مربوط.

خطرهای باز: SID اشتباه، گروه‌های ارثی، ذخیرهٔ ناامن credential task، اعطای audit read به Writer، دورزدن validation certificate و باقی‌ماندن principal ناقص پس از شکست. recovery باید فقط principal/SIDهای همین بسته را هدف بگیرد، بدون repair یا حذف خودکار حساب/عضویت نامرتبط. در این P0 هیچ account، SQL login/user/role، GRANT/DENY، DDL/DML، scheduled task، right/ACL یا certificate ساخته/تغییر داده نشد.

## انتخاب راهبرد و برآورد مشروط

| گزینه | دامنه و شاهد | ریسک/توصیه |
|---|---|---|
| A؛ پیشنهاد اصلی | .NET10 LTS + MDS6.1.7 LTS، pin امنیتی Pkcs، Generic Host با Startup، کنترلر/Newtonsoft، حفظ قرارداد و gate بسته؛ build/۱۴ تست/HTTP نمونه موفق | نیازمند port واقعی، OpenAPI parity، regression کامل، IIS و پذیرش SQL با هویت/TLS مصوب؛ انتخاب پیشنهادی |
| B؛ تداوم موقت legacy | حفظ2.1 و کد فعلی آفلاین؛ provider فعلی هنوز blocked | EOL و advisoryها باقی‌اند؛ مناسب انتشار عمومی نیست و SQL نباید فعال شود |

در B، بازطراحی granular package graph یا اجرای در VM/container/شبکهٔ ایزوله فقط فرضیهٔ آزمایش مستقل است؛ همهٔ bounded dependencyها، libraryهای قدیمی و host باید دوباره بررسی شوند. جداسازی، patch امنیتی یا بازگشت پشتیبانی نیست. هیچ graph legacy تازه یا DLL قدیمی برای عبور تست نصب/اجرا نشد. آزمایش بعدی B به مجوز صریح جدا، محدودهٔ بدون داده/Production و تصمیم امنیت نیاز دارد؛ هزینهٔ آن در برابر A توجیه ضعیف‌تری دارد.

برآورد کارشناسی با فرض یک مهندس آشنا و دسترسی به پاسخ مالک/زیرساخت؛ زمان انتظار مجوز، رفع certificate و bug ناشناخته داخل آن نیست:

| بستهٔ آینده | برآورد | شرط خروج |
|---|---|---|
| port آفلاین canonical، host/MVC/JSON/Swagger/provider/test/lock/docs | ۶ تا ۱۰ روز کاری مهندسی | build/audit و تمام caseهای قبلی با SQL بسته؛ parity HTTP/OpenAPI |
| بررسی/پذیرش hosting در staging مجزا | ۲ تا ۴ روز کاری | OS/bundle/ANCM/PathBase/HTTPS/recycle واقعی؛ تصویب زیرساخت |
| پذیرش متصل همین2F بعد از حساب/TLS | ۲ تا ۴ روز کاری | provider/native/permissions/transaction/cancel/rowversion با fixture مصوب |

مجموع مشروط ۱۰ تا ۱۸ روز کاری است؛ پذیرش staging در این جدول برنامهٔ وابستگی است و مجوز شروع2G نیست. توسعهٔ OTP/Session/Info/media و mapping واقعی مبدأ در این برآورد نیست.

ترتیب پیشنهادی پس از تصویب، در همین مخزن و بدون worktree: (۱) snapshot/remote/ref و baseline تازه؛ (۲) SDK/TFM/framework-reference و گراف pin/lock/audit؛ (۳) Generic Host/Startup و MVC/JSON/PathBase/security parity؛ (۴) Swagger تولیدشده و contract diff؛ (۵) تعویض typeهای provider و builder بدون تغییر gate/SQL؛ (۶) انتقال test harness/runner و حفظ تمام caseها؛ (۷) build، regression، HTTP loopback و walkthrough، سپس commit امن و بازبینی؛ (۸) فقط با تصویب‌های مستقل P1/P2/TLS، principal/effective permission و connected acceptance؛ (۹) نصب/استقرار تنها در change مستقل. شکست هر gate توقف و اصلاح همان بسته است؛ طراحی جدید کسب‌وکار در این مهاجرت وارد نشود.

## فرمان‌ها و بازبینی محلی

این دستورها **بازتولید در workspace آزمایشِ موجود** هستند؛ فایل‌های نمونه در clone تازه وجود ندارند. ساخت دوبارهٔ نمونه باید با همان مرز آفلاین و نسخه‌های ثبت‌شده باشد. خروجی خام اجراهای انجام‌شده در `.sync-tmp/` مانده و hash آن‌ها در JSON نتایج آمده است؛ secret و source خصوصی در گزارش نیست. از این فرمان‌ها مجوز اتصال SQL برداشت نشود.

```powershell
# cwd: C:\Projects\vehicle-inspection-backend
dotnet restore Bazdid.sln --locked-mode
dotnet build Bazdid.sln -c Release --no-restore
dotnet test Bazdid.sln -c Release --no-build --no-restore --logger trx --results-directory .sync-tmp/p0-canonical-tests

# cwd: C:\Projects\vehicle-inspection-backend\.sync-tmp\p0-net10-spike-20261103
dotnet --version
dotnet restore P0Spike.sln --locked-mode
dotnet build P0Spike.sln -c Release --no-restore
dotnet test --project Tests/P0.Tests.csproj -c Release --no-build --no-restore --report-trx --results-directory C:/Projects/vehicle-inspection-backend/.sync-tmp/p0-net10-spike-20261103/MtpResultsVerified
dotnet list P0Spike.sln package --vulnerable --include-transitive --format json --no-restore
dotnet Api/bin/Release/net10.0/win-x64/P0.Api.dll --inspect-provider
```

اجرای دستی محلی نمونه، فقط Development و loopback؛ تا توقف Ctrl+C فرآیند باز می‌ماند:

```powershell
# cwd: پوشهٔ Api نمونه؛ فقط در process همین آزمایش
$env:ASPNETCORE_ENVIRONMENT='Development'
$env:DOTNET_ENVIRONMENT='Development'
dotnet bin/Release/net10.0/win-x64/P0.Api.dll
# از P0_LISTEN نشانی loopback را بخوانید؛ port هر اجرا متفاوت است.
```

بازبینی واقعی این مرحله با helper محلی `.sync-tmp/p0-http-smoke.ps1` انجام شد: health و دو مسیر ردشده با HttpClient بررسی و فرآیند بسته شد. هیچ آزمون مرورگر/IIS یا نصب سرویس انجام نشد. مشکلات واقعی prototype و رفع آن‌ها در بخش مراحل بالا ثبت‌اند؛ مدت تاریخی ساخت، log گمشده یا موفقیت آزمون متصل بازسازی نشده است.

## تحویل Git، پیشرفت و مجوز بعدی

فایل‌های تازه: همین walkthrough، ماتریس فایل‌به‌فایل و JSON خلاصهٔ امن. اسناد ورود/ادامه/تصمیم/آزمون/منابع/PLAN/IIS به P0 ارجاع می‌دهند؛ فهرست دقیق diff و SHAهای واقعی در [گزارش GitHub](../GITHUB_SYNC_FA.md) ثبت می‌شود. prototype/cache/TRX/bin/obj و فایل شخصی کاربر خارج commit هستند. هیچ API اصلی، جدول یا migration افزوده نشد. انتشار فقط main به مقصد مصوب و بدون force/branch اصل است؛ «ارسال موفق»، «تطبیق HEAD» و «خواندن فایل GitHub» جدا راستی‌آزمایی می‌شوند.

ثبت واقعی بسته: `55573fda0c2741f103760c3e959c7ff108e10431` شامل۱۵فایل، با push عادی منتشر شد؛ HEAD محلی/origin/main/ls-remote برابر و اختلاف0/0 بود. سه blob راهنما/نتایج/ماتریس در GitHub با SHA محلی برابر شدند. چهارمین فایل تازه، `P0_DELIVERY_VALIDATION.json` خلاصهٔ کنترل اسناد است. گزارش Git و این ارجاع در ثبت تکمیلی به‌روز می‌شوند؛ SHA نهایی آن از گزارش تحویل/Git خوانده شود.

**پیشرفت: قبلی20 + سهم P0 صفر = فعلی20%؛ باقی80%.** وزن Checkpoint2 برابر12 از100 است؛ تا اینجا 2A/2B=3، 2C=2، 2D=2 و طراحی2E=1، به baseline12 افزوده و20 شده‌اند. P0/نگهداری اسناد امتیاز2F را کسب نمی‌کند. هدف مشروط پس از پذیرش واقعی کامل2F، **22%**؛ تکمیل بعدی Checkpoint2،24% است. 2G شروع نشده است.

**تصویب لازم برای گام پیشنهادی بعد:** مالک صریحاً الزام canonical `ASP.NET Core2.1/netcoreapp2.1` را برای مهاجرت واقعی به `.NET10 LTS` تغییر دهد و port آفلاین API و دو پروژهٔ تست، گراف/lockfileها، Generic Host با حفظ Startup، MVC/Newtonsoft/Swagger و MDS6.1.7 همراه pinهای امنیتی سازگار را مجاز کند؛ قواعد domain/HTTP و gate بسته حفظ شوند. این تصویب باید روشن کند شامل SQL connection، P1/P2، سیستم‌عامل/Hosting Bundle، certificate/ACL/task، activation و استقرار نیست. تصویب‌های آن عملیات بعداً مستقل‌اند. مجوز P0 فعلی فقط برای این آزمایش بود و خودبه‌خود مجوز هیچ‌یک از مراحل بعدی نیست.
