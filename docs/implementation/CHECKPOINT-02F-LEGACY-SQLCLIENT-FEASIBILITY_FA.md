# امکان‌سنجی SQL Client سازگار با ASP.NET Core 2.1 — Checkpoint 2F-L1

تاریخ: `2026-11-03`؛ مبنای canonical: `dbdd6ee6ebead440af6d4dc58371f7ef407375d2`. این سند فرایند و نتیجهٔ بررسی گزینه‌های provider در **همان چارچوب الزامی 2.1** را ثبت می‌کند. هیچ اتصال SQL، حساب، مجوز، certificate یا استقرار انجام نشد و canonical تغییر نکرد. پیشرفت **20%** است.

## ۱. الزام قطعی ASP.NET Core 2.1

به دستور کارفرما و الزام زیرساخت فعلی، Backend canonical باید `netcoreapp2.1` بماند. تغییر آن فقط با تصویب صریح کارفرما و مالک پروژه مجاز است. آزمایش P0 با .NET10 ([walkthrough P0](CHECKPOINT-02F-P0-MIGRATION-FEASIBILITY_FA.md)) فقط پژوهش امکان‌سنجی آینده است و گام اجرایی مصوب نیست. پایان پشتیبانی .NET Core 2.1 در `2021-08-21` است و runtime این نسل «امن برای Production» معرفی نمی‌شود.

## ۲. وضعیت اولیه

- HEAD محلی و `origin/main` برابر `dbdd6ee`؛ worktree بدون تغییر tracked.
- دو مورد untracked: `src/Bazdid.Api/Properties/` (فایل شخصی کاربر، دست‌نخورده) و `docs/checkpoint2f/LEGACY_PROVIDER_RESULTS.json`. این JSON حاصل اجرای قبلیِ همین 2F-L1 در همان روز بود که walkthrough، به‌روزرسانی اسناد یا commit نداشت. محتوای آن بدون تغییر نگه داشته شد و فقط پس از اجرای مستقل دوباره، به‌عنوان شاهد اجرای قبلی منتشر می‌شود.
- پوشهٔ `.git` مالکیت حساب `CodexSandboxOffline` دارد. برای جلوگیری از تغییر تنظیم سراسری، هر فرمان git با `-c safe.directory=C:/Projects/vehicle-inspection-backend` اجرا شد.
- پایگاه `BAZDID_Development` روی `(local)\SQLSERVER2019` با سه جدول `BAZDIDCustomerLinks`، `BAZDIDRequestContexts` و `BAZDIDAuditLogs` در این مرحله **نه خوانده شد و نه تغییر کرد**.

## ۳. قید موجود SQL Client

`Microsoft.AspNetCore.App 2.1.30` در nuspec خود `System.Data.SqlClient (>= 4.5.3 && < 4.6.0)` و `System.Runtime.CompilerServices.Unsafe (>= 4.5.3 && < 4.6.0)` را تحمیل می‌کند. نسخه‌های پایدار داخل این بازه فقط `4.5.0`، `4.5.1` و `4.5.3` هستند. `4.5.3` فعلی دو advisory دارد: Moderate `GHSA-8g2p-5pqh-5jmc` و High `GHSA-98g6-xh36-x2p7`. پس **نسخهٔ وصله‌شده‌ای در بازهٔ مجاز metapackage وجود ندارد**.

## ۴. نامزدها

| شناسه | بسته/نسخه | گراف |
|---|---|---|
| `meta_sds486` / `meta_sds491` | `System.Data.SqlClient` 4.8.6 / 4.9.1 | با metapackage |
| `meta_mds114` / `meta_mds217` | `Microsoft.Data.SqlClient` 1.1.4 / 2.1.7 | با metapackage |
| `sds486`، `sds491`، `mds114`، `mds217`، `mds317`، `mds406` | نسخهٔ provider بدون ASP.NET Core | کنسول مستقل |
| `granular_sds486`، `granular_mds406` | provider + بسته‌های ریز ASP.NET Core 2.1 | جایگزین metapackage |
| `granular_sds486_secpin`، `secpin2`، `secpin3` | `granular_sds486` + pinهای امنیتی | **تازهٔ این نشست** |
| `l1-canonical-granular` | کپی کد canonical روی گراف `secpin2` | **تازهٔ این نشست** |

برای انتخاب MDS، آخرین patch هر خط که netcoreapp2.1 را هدف دارد گرفته شد. خط‌های پشتیبانی‌شدهٔ امروز (`6.1` LTS، `7.0`، `7.1`) netcoreapp2.1 را پشتیبانی نمی‌کنند.

## ۵. امکان گراف ریز (granular)

گراف ریز به‌جای `Microsoft.AspNetCore.App` همان بسته‌های مصرفی برنامه را با نسخهٔ دقیق pin می‌کند. نتیجهٔ مهم: برنامه دیگر به shared framework `Microsoft.AspNetCore.App` وابسته نیست. `runtimeconfig.json` فقط `Microsoft.NETCore.App 2.1.30` دارد و DLLهای ASP.NET Core از package و کنار برنامه بار می‌شوند. pinهای همسوسازی (`Http 2.1.22`، `Mvc.Core 2.1.16`، `Caching.Memory 2.1.23` و غیره) در اجرای قبلی تعیین شده بودند. در این نشست سه pin امنیتی اضافه شد:

```xml
<PackageReference Include="System.Text.RegularExpressions" Version="[4.3.1]" />
<PackageReference Include="System.Security.Cryptography.Xml" Version="[4.7.1]" />
<PackageReference Include="System.Security.Cryptography.Pkcs" Version="[4.7.0]" />
<PackageReference Include="Microsoft.AspNetCore.Server.Kestrel.Transport.Sockets" Version="[2.1.40]" />
```

`Pkcs 4.7.0` نیاز وابستگی `Cryptography.Xml 4.7.1` است. `Sockets 2.1.40` وصلهٔ رسمی CVE-2023-38180 برای خط 2.1 است (`<= 2.1.39` آسیب‌پذیر). همهٔ این‌ها بدون هیچ warning/downgrade حل شدند.

## ۶. آزمایش‌های جداشده

همه زیر `.sync-tmp/l1-legacy-spike-20261103/` و `.sync-tmp/l1-canonical-granular/` هستند که ignored‌اند و منتشر نمی‌شوند. تنظیمات مشترک نمونه‌ها:

```xml
<TargetFramework>netcoreapp2.1</TargetFramework><RuntimeFrameworkVersion>2.1.30</RuntimeFrameworkVersion>
<RuntimeIdentifier>win-x64</RuntimeIdentifier><LangVersion>7.3</LangVersion>
<RestorePackagesWithLockFile>true</RestorePackagesWithLockFile>
<WarningsAsErrors>NU1608;NU1605;NU1701</WarningsAsErrors>
```

probe آفلاین هر provider ده بررسی دارد:
- `SqlConnectionStringBuilder` با `IntegratedSecurity=true`، `Encrypt=true`، `TrustServerCertificate=false`، `ConnectRetryCount=0` و `Enlist=false`؛
- پارامتر typed `NVarChar(32)`؛
- بستن delegateهای `OpenAsync(CancellationToken)`، `ExecuteNonQueryAsync`، `ExecuteReaderAsync` و `BeginTransaction(IsolationLevel)` **بدون فراخوانی**؛
- وجود `Commit`/`Rollback`؛
- فرآیند x64 و بررسی PE فایل `sni.dll`.

probe میزبان گراف ریز ۱۴ سناریو را با TestServer و یک smoke loopback پوشش می‌دهد: `PathBase` `/API/BAZDID`، رد prefix تکراری، Swagger JSON/UI، CORS دقیق، خطای امن، اعتبارسنجی تنظیم و IIS شبیه‌سازی‌شده. این IIS واقعی نیست.

آزمایش `l1-canonical-granular`: فایل‌های tracked `src/` و `tests/` (بدون lockfile و `Properties`) کپی شدند و فقط `PackageReference`ها در `Bazdid.Api.csproj` کپی عوض شدند. هیچ فایل C# تغییر نکرد. `global.json`، `Directory.Build.props` و `NuGet.Config` ریشه همان canonical‌اند.

## ۷. نتایج restore/build (اجرای تازهٔ این نشست)

| آزمایش | restore | build | probe/میزبان |
|---|---|---|---|
| `meta_sds486` | شکست `NU1608`+`NU1107` | — | — |
| `meta_sds491` | شکست `NU1608` | — | — |
| `meta_mds217` | شکست `NU1107` | — | — |
| `meta_mds114` | موفق | 0/0 | probe موفق |
| `sds486` | locked موفق | 0/0 | probe موفق |
| `sds491` | locked موفق | ۱ warning «netcoreapp2.1 پشتیبانی نمی‌شود» | شکست `PlatformNotSupportedException` |
| `mds114`/`mds217`/`mds317`/`mds406` | locked موفق | 0/0 | probe موفق |
| `granular_sds486` / `granular_mds406` | locked موفق | 0/0 | probe موفق، میزبان ۱۴/۱۴ |
| `granular_sds486_secpin` | موفق، locked قطعی | 0/0 | probe موفق، میزبان ۱۴/۱۴ |
| `granular_sds486_secpin2` | موفق، locked قطعی، ۱۹۸ dependency | 0/0 | probe موفق، میزبان ۱۴/۱۴ |
| `granular_sds486_secpin3` (`Kestrel.Core 2.3.6`) | شکست `NU1605` | — | — |
| `l1-canonical-granular` | موفق، locked قطعی | **0 warning / 0 error** | **۱۰۹/۱۰۹ unit؛ ۵۰ موفق + ۸ Skipped از ۵۸ integration؛ صفر شکست** |

خروجی‌های آزمایش با canonical جمع نمی‌شوند. ۸ آزمون Skipped همان آزمون‌های SQL متصل‌اند و موفق شمرده نمی‌شوند.

## ۸. بررسی managed/native

- در همهٔ probeهای موفق، runtime برابر `.NET Core 4.6.30411.01` (2.1.30) از `C:\Program Files\dotnet\shared\Microsoft.NETCore.App\2.1.30` و فرآیند x64 بود.
- `System.Data.SqlClient 4.8.6`: assembly `4.6.1.6`، file `4.700.23.52603`، asset `runtimes/win/lib/netcoreapp2.1/System.Data.SqlClient.dll`.
- native: `runtime.win-x64.runtime.native.System.Data.SqlClient.sni/4.4.0` → `sni.dll` با machine `0x8664`، طول `160040` و SHA-256 `68705c4e…7d6`. این فایل با `sni.dll` موجود در shared framework `Microsoft.AspNetCore.App/2.1.30` یکسان است.
- `sni.dll` **بار نشد**. سازندهٔ `SqlConnection` آن را لازم ندارد و اتصال/SSPI/TLS آزموده نشد.
- `4.9.1` روی netcoreapp2.1 به asset ناپشتیبان می‌افتد و در runtime خطای `System.Data.SqlClient is not supported on this platform` می‌دهد. پس عملاً حذف است.
- در `l1-canonical-granular`، `deps.json` برنامه `System.Data.SqlClient/4.8.6`، `Sockets/2.1.40`، `RegularExpressions/4.3.1` و `Cryptography.Xml/4.7.1` را نشان می‌دهد.

## ۹. تحلیل advisory

audit با SDK `10.0.403` (خارج از `global.json` مخزن) و `dotnet list package --vulnerable --include-transitive` اجرا شد.

| گراف | تعداد flagged | جزئیات |
|---|---|---|
| canonical فعلی | 9 | Kestrel.Core Critical؛ Sockets 2.1.3 High؛ Identity 2.1.6 High؛ SqlClient 4.5.3 Moderate+High؛ System.Net.Http 4.3.0 High؛ RegularExpressions 4.3.0 High؛ Jwt 5.2.0 Moderate؛ Crypto.Xml 4.5.0 Moderate؛ SwaggerUI 4.0.1 Moderate |
| `meta_mds114` | 9 | به‌علاوهٔ خود MDS 1.1.4 High |
| `mds217`/`mds317`/`mds406` مستقل | 2 / 3 / 3 | Jwt/JsonWebTokens Moderate؛ `Azure.Identity 1.3.0` High در 3.x/4.x |
| `granular_sds486` | 5 | Kestrel Critical، Sockets High، RegEx High، Crypto.Xml Moderate، SwaggerUI Moderate |
| `secpin` | 3 | Kestrel Critical، Sockets High، SwaggerUI Moderate |
| **`secpin2` و `l1-canonical-granular`** | **2** | `Kestrel.Core 2.1.25` Critical و `SwaggerUI 4.0.1` Moderate |

دو advisory باقی‌مانده:
- **CVE-2025-55315** (`GHSA-5rrx-jjjq-q2r5`، CVSS 9.9، request smuggling). در Kestrel 2.x فقط `2.3.6` وصله دارد. آزمایش `secpin3` نشان داد که این وصله خط بسته‌های ASP.NET Core 2.3 و `System.Text.Encodings.Web 8.0.0` را می‌طلبد و با گراف 2.1 `NU1605` می‌دهد. خط 2.3 عملاً تغییر چارچوب است و بی‌اجازه اعمال نشد. وصله‌ای در خط 2.1 وجود ندارد و canonical فعلی هم همین آسیب‌پذیری را دارد.
- **`GHSA-qrmm-w75w-3wpx`** (SSRF در SwaggerUI، وصله در `6.3.0`). canonical، UI را فقط در `Development`/`Testing` فعال می‌کند (`Startup.cs:36`). وابستگی بستهٔ نسخهٔ قدیم Swagger همچنان در گراف هست.

هیچ warning یا advisory برای عبور نامزدی سرکوب نشد، هیچ DLL دستی جابه‌جا نشد و `TrustServerCertificate=true` یا `Encrypt=false` به کار نرفت.

## ۱۰. محدودیت‌های runtime فعلی

- .NET Core 2.1 و ASP.NET Core 2.1 از `2021-08-21` وصلهٔ امنیتی ندارند. وصلهٔ CVE-2025-55315 برای آن‌ها منتشر نمی‌شود.
- `System.Data.SqlClient` در NuGet deprecated اعلام و `Microsoft.Data.SqlClient` جانشین آن است. `4.8.6` در `2024-01-09` منتشر شده و advisory مخصوص نسخه ندارد. تاریخ دقیق پایان پشتیبانی از منبع اصلی Microsoft در این نشست تأیید نشد و نباید حدس زده شود.
- MDSهای سازگار با 2.1 همه خارج از پشتیبانی‌اند، طبق [صفحهٔ رسمی lifecycle](https://learn.microsoft.com/en-us/sql/connect/ado-net/sqlclient-driver-support-lifecycle):

  | خط | پایان پشتیبانی |
  |---|---|
  | 1.1 | `2022-11-21` |
  | 2.1 | `2023-11-20` |
  | 4.0 | `2024-11-19` |
  | 3.1 | `2025-03-30` |

- با گراف ریز، نسخهٔ واقعی هر DLL ASP.NET Core از package تعیین می‌شود، نه از shared framework نصب‌شده روی سرور. ارزیابی امنیتی باید روی lockfile انجام شود.

## ۱۱. سازگاری با معماری مخزن

| جزء | وضعیت با گزینهٔ پیشنهادی (گراف ریز + SDS 4.8.6) |
|---|---|
| `SqlRuntimeOptions` | بدون تغییر. namespace `System.Data.SqlClient` و `SqlConnectionStringBuilder` با `Encrypt`، `TrustServerCertificate`، `ApplicationIntent`، `ConnectRetryCount` و `Enlist` در 4.8.6 همان API است. آزمون‌های آفلاین builder روی 4.8.6 موفق بودند. |
| `SqlConnections` (factory، `SqlErrors`، `SqlTransactionFactory`، `SqlWorkScope`) | بدون تغییر کد. رفتار واقعی `OpenAsync`، کدهای خطا (`-2`، `2601`، `2627`، `547`، `53`، `18456` …)، `Commit`/`Rollback` و لغو فقط با آزمون متصل اثبات می‌شود. |
| `SqlCommands` / `SqlRepositories` | بدون تغییر. پارامترهای typed، `rowversion` با `Binary(8)` و `ExecuteReaderAsync`/`ReadAsync` با token در 4.8.6 موجودند. |
| `SqlRegistration` و DI | بدون تغییر. |
| `LinkagePersistenceService` | بدون تغییر. |
| `SqlRuntimeGate.ConnectedAcceptanceVerified=false` | **دست‌نخورده**؛ بازشدن فقط پس از P4. |
| ۸ آزمون SQL متصل | بدون تغییر؛ اجرا با هویت Writer مصوب پس از P1–P4. |
| `Bazdid.Api.csproj` و سه `packages.lock.json` | **تنها تغییر لازم**: جایگزینی metapackage با ۳۵ بستهٔ دقیق + `Newtonsoft.Json`/`Swashbuckle.AspNetCore` موجود و `WarningsAsErrors` NuGet؛ بازتولید lockfileها. |

گزینهٔ MDS نیازمند تعویض namespace به `Microsoft.Data.SqlClient` در چهار فایل SQL و آزمون‌ها، پیش‌فرض متفاوت `Encrypt` در 4.x و وابستگی‌های Azure/Identity است. با گزینه‌های بالا ارزش ندارد.

## ۱۲. legacy در برابر مرز دادهٔ جدا (گزینهٔ D)

فقط در سطح معماری: یک سرویس داخلی جدا (مثلاً روی .NET پشتیبانی‌شده با MDS 6.1) می‌تواند لایهٔ SQL را از runtime 2.1 جدا کند. هزینه‌های آن:
- runtime/سرویس دوم روی سرور؛
- احراز هویت سرویس‌به‌سرویس؛
- transaction توزیع‌شده یا API ریزدانه؛
- یک hop شبکه؛
- نگهداری مضاعف.

مشکل Kestrel 2.1 در لبهٔ HTTP را هم حل نمی‌کند. چون زیرساخت کارفرما ممکن است runtime اضافه را نپذیرد، این گزینه مشروط و تصویب‌نشده است و هیچ سرویسی ساخته نشد.

## ۱۳. حداقل تغییر کد لازم (برای اجرای آینده، نه اکنون)

۱. در `src/Bazdid.Api/Bazdid.Api.csproj`، `Microsoft.AspNetCore.App 2.1.30` حذف و فهرست دقیق `l1-canonical-granular` افزوده شود. ۳۵ بستهٔ زیر همراه با دو بستهٔ موجود:

```text
Microsoft.AspNetCore 2.1.7; Microsoft.AspNetCore.Mvc 2.1.3; Microsoft.AspNetCore.Mvc.Core 2.1.16;
Microsoft.AspNetCore.Server.Kestrel.Core 2.1.25; Microsoft.AspNetCore.Server.Kestrel.Transport.Sockets 2.1.40;
Microsoft.AspNetCore.Cors 2.1.1; Microsoft.AspNetCore.HttpsPolicy 2.1.1; Microsoft.AspNetCore.Diagnostics 2.1.1;
Microsoft.AspNetCore.Server.IISIntegration 2.1.7; System.Data.SqlClient 4.8.6;
Microsoft.AspNetCore.Authorization 2.1.2; Microsoft.AspNetCore.Authorization.Policy 2.1.2;
Microsoft.AspNetCore.Http 2.1.22; Microsoft.AspNetCore.Http.Extensions 2.1.21; Microsoft.AspNetCore.Mvc.Formatters.Json 2.1.18;
Microsoft.AspNetCore.Mvc.Razor.Extensions 2.1.2; Microsoft.AspNetCore.Mvc.RazorPages 2.1.11; Microsoft.AspNetCore.Razor 2.1.2;
Microsoft.AspNetCore.Razor.Design 2.1.2; Microsoft.AspNetCore.Razor.Language 2.1.2; Microsoft.AspNetCore.Razor.Runtime 2.1.2;
Microsoft.AspNetCore.StaticFiles 2.1.1; Microsoft.Extensions.Caching.Abstractions 2.1.23; Microsoft.Extensions.Caching.Memory 2.1.23;
Microsoft.Extensions.FileProviders.Embedded 2.1.1; Microsoft.Extensions.ObjectPool 2.1.6; Microsoft.Extensions.Primitives 2.1.6;
Microsoft.Net.Http.Headers 2.1.14; System.Collections.Immutable 1.5.0; System.IO.Pipelines 4.5.4;
System.Runtime.InteropServices.RuntimeInformation 4.3.0; System.Security.Cryptography.Pkcs 4.7.0;
System.Security.Cryptography.Xml 4.7.1; System.Text.RegularExpressions 4.3.1; System.Text.Encodings.Web 4.5.1
```

۲. `dotnet restore` و ثبت سه lockfile تازه، سپس `--locked-mode` و audit.
۳. build، کل regression و smoke HTTP. نتیجهٔ کپی: صفر warning/error و ۱۵۹ موفق/۸ Skipped.
۴. publish و آزمون IIS/ANCM در staging مصوب، چون shared framework ASP.NET Core دیگر استفاده نمی‌شود و DLLها app-local‌اند.

کد C#، تنظیمات، endpointها، schema و gate تغییر نمی‌کنند.

## ۱۴. توصیهٔ provider

**از نظر فنی:** تنها نامزد قابل‌اجرا در چارچوب الزامی، **`System.Data.SqlClient 4.8.6` روی گراف ریز ASP.NET Core 2.1 با pinهای امنیتی (`secpin2`)** است:
- گراف تمیز؛
- build صفر؛
- probe و میزبان موفق؛
- کپی canonical با همهٔ آزمون‌های قبلی؛
- کاهش advisoryها از ۹ به ۲.

بقیه حذف‌اند:
- metapackage + هر provider جدید: تعارض NuGet؛
- MDS 1.1.4: High و خارج از پشتیبانی؛
- MDS 2.x–4.x: خارج از پشتیبانی و advisory انتقالی؛
- SDS 4.9.1: ناسازگار با runtime؛
- Kestrel 2.3: تغییر چارچوب.

**از نظر امنیتی: هیچ نامزدی پذیرفتنی اعلام نمی‌شود.**
- Kestrel 2.1.25 با Critical بی‌وصله باقی است.
- runtime 2.1 و SDS deprecated هستند.
- اتصال واقعی، TLS و permissions آزموده نشده‌اند.

تصمیم پذیرش این ریسک با کارفرما است، نه تیم فنی. پیشنهاد ارجاع به کارفرما دو تصمیم جدا دارد:

۱. **امکان فنی:** تصویب تغییر بستهٔ canonical به گراف `secpin2` در یک commit متمرکز، بدون تغییر target یا کد. این گراف نسبت به وضع فعلی ۷ advisory را رفع می‌کند و advisory تازه‌ای نمی‌افزاید.
۲. **پذیرش ریسک:** پذیرش مکتوب و زمان‌دار ریسک باقیماندهٔ CVE-2025-55315 روی 2.1. کنترل‌های جبرانی پیشنهادی، هیچ‌کدام رفع نیستند:
   - Kestrel فقط پشت IIS/ANCM و روی loopback؛
   - بدون binding مستقیم؛
   - request filtering در IIS؛
   - SwaggerUI خاموش در Production.

   به‌علاوه، تاریخ هدف برای خروج از 2.1 یا تصمیم دربارهٔ گزینهٔ D تعیین شود.

بدون تصمیم ۱، SQL runtime بسته می‌ماند. بدون تصمیم ۲، فعال‌سازی متصل یا Production مجاز نیست.

## ۱۵. آمادگی تصویب P1/P2

بازبینی دو script با کد فعلی هم‌خوان است. hashها برابر شاهد قبلی‌اند: `development_logins.review.sql` → `9099de3d…5b5f` و `permissions.review.sql` → `9888862c…a396`. guard هر دو `@AllowDdl=0` و مقادیر approval/SID برابر `NULL` است.

**هویت‌ها:**
- `<MACHINE>\BAZDIDDevWriter` و `<MACHINE>\BAZDIDDevReader`. script فقط `@ExpectedMachine + N'\BAZDID…'` را می‌پذیرد.
- حساب‌های standard محلی، بدون admin/RDP/interactive، با Batch logon فقط برای task آزمون.

**عملیات مدیر Windows (P1، اجرانشده):**
- ساخت دو حساب؛
- ثبت SID هر حساب؛
- حق «Log on as a batch job» محدود؛
- ACL خواندنی روی خروجی آزمون؛
- task اجرای آزمون با Writer؛
- نگهداری رمز فقط در vault/Task Scheduler، نه در Git یا گفتگو.

**عملیات DBA (P2، اجرانشده):** اجرای دو script با `@AllowDdl=1`، مرجع تصویب، نام ماشین و SIDهای تأییدشده، که این اشیا را می‌سازد:
- `CREATE LOGIN … FROM WINDOWS`؛
- `CREATE USER`؛
- نقش‌های `BAZDIDWriter` و `BAZDIDSourceReader`.

| نقش | جدول | GRANT | DENY |
|---|---|---|---|
| `BAZDIDWriter` | `dbo.BAZDIDCustomerLinks` | `SELECT, INSERT` | `UPDATE, DELETE, ALTER` |
| `BAZDIDWriter` | `dbo.BAZDIDRequestContexts` | `SELECT, INSERT, UPDATE` | `DELETE, ALTER` |
| `BAZDIDWriter` | `dbo.BAZDIDAuditLogs` | `INSERT` | `SELECT, UPDATE, DELETE, ALTER` |
| `BAZDIDSourceReader` | هر سه جدول BAZDID | — | `SELECT, INSERT, UPDATE, DELETE, ALTER` |
| هر دو | پایگاه | — | `CREATE TABLE/VIEW/PROCEDURE/FUNCTION/SCHEMA` |

Reader هیچ GRANT مبدأ ندارد. تا تصویب mapping واقعی، به هیچ شیء کارگزاری دسترسی داده نمی‌شود. کد فعلی (`UnconfiguredSourceReadConnectionFactory`) اصلاً Reader را به کار نمی‌برد. پس می‌توان در تصویب بعدی ساخت Reader را تا تصویب mapping به تعویق انداخت. این کار نسخهٔ تازهٔ script و hash جدید می‌خواهد و فعلاً پیشنهاد است.

**احراز هویت و جداسازی اختیار:**
- تطبیق SID ساخته‌شده با `sys.server_principals.sid` توسط script؛
- `IS_SRVROLEMEMBER('sysadmin')=0` برای هر دو؛
- `Writer≠Reader`.

**آزمون effective permission:** هویت اجرای آزمون فقط Writer است و کد هنگام اتصال این شرط‌ها را با `ORIGINAL_LOGIN()=@Principal` می‌سنجد:
- `HAS_PERMS_BY_NAME` مثبت فقط برای ۶ مجوز بالا؛
- منفی برای `SELECT/UPDATE/DELETE/ALTER` روی audit و `DELETE/ALTER` روی دو جدول دیگر؛
- منفی برای `CONTROL`، `CONTROL SERVER` و `CREATE TABLE`؛
- انتقال `Shared memory`؛
- احراز `NTLM`/`KERBEROS`.

یک verifier مستقل با حساب DBA باید عضویت‌های ارثی گروه Windows/public را جدا کنترل کند.

**ابطال:** رویهٔ کامل در [CONTINUATION_APPROVAL_FA.md](../checkpoint2f/CONTINUATION_APPROVAL_FA.md) آمده است: توقف task، تطبیق SID، بستن session، حذف user/role/login و سپس حساب/حق/ACL Windows، بدون حذف دادهٔ کسب‌وکار.

**مجوزهای مستقل لازم:** P1 (Windows)، P2 (DBA)، P3 (TLS/certificate)، P4 (تغییر gate و اجرای rollback-only) و P5 (fixture/cleanup). هیچ‌کدام در این مرحله داده یا اجرا نشد.

## ۱۶. تصویب‌های باز دقیق

| شناسه | تصمیم | صاحب تصمیم |
|---|---|---|
| L1-A | تصویب تغییر بستهٔ canonical به گراف ریز `secpin2` با SDS 4.8.6، بدون تغییر target/کد | کارفرما + مالک پروژه |
| L1-R | پذیرش مکتوب و زمان‌دار ریسک CVE-2025-55315 و runtime EOL، با کنترل‌های جبرانی و تاریخ بازبینی | کارفرما/امنیت |
| P1 | ساخت دو حساب Windows محلی و حق Batch logon/task | مدیر Windows |
| P2 | اجرای دو script با SID/مرجع تصویب | DBA |
| P3 | طرح certificate و آزمون TLS برای `Encrypt=true`/`TrustServerCertificate=false` روی `lpc:.\SQLSERVER2019` | DBA/زیرساخت |
| P4/P5 | بازکردن gate، اجرای ۸ آزمون متصل، fixture و cleanup | مالک پروژه |
| D (اختیاری) | امکان runtime/سرویس دوم روی زیرساخت | زیرساخت کارفرما |

کوچک‌ترین تصمیم لازم برای ادامه **L1-A** است. پس از آن، اجرای آفلاین تغییر بسته در canonical ممکن است. پذیرش متصل 2F همچنان به L1-R و P1 تا P4 وابسته است.

## ۱۷. فرمان‌های واقعاً اجراشده

برچسب‌ها: «اجرا شد» یعنی در همین نشست اجرا شده است. اجرای قبلیِ همان روز فقط از `LEGACY_PROVIDER_RESULTS.json` گزارش می‌شود.

```powershell
# اجرا شد — cwd: C:\Projects\vehicle-inspection-backend (SDK 2.1.818)
dotnet restore Bazdid.sln --locked-mode
dotnet build Bazdid.sln --configuration Release --no-restore
dotnet test Bazdid.sln --configuration Release --no-build --no-restore

# اجرا شد — cwd: هر پوشهٔ نامزد زیر .sync-tmp\l1-legacy-spike-20261103 (SDK 2.1.818)
dotnet restore Probe.csproj --locked-mode
dotnet build Probe.csproj -c Release --no-restore
dotnet publish Probe.csproj -c Release --no-restore --output publish-rerun
dotnet publish-rerun/Probe.dll              # کنسول: probe provider؛ گراف ریز: ۱۴ سناریوی میزبان
dotnet publish-rerun/Probe.dll --provider   # فقط گراف ریز: probe provider
# نمونه‌های secpin* و secpin2/3 با خروجی publish (نه publish-rerun) ساخته شدند

# اجرا شد — cwd: .sync-tmp\l1-canonical-granular (کپی؛ SDK 2.1.818)
dotnet restore Bazdid.sln
dotnet restore Bazdid.sln --locked-mode
dotnet build Bazdid.sln --configuration Release --no-restore
dotnet test Bazdid.sln --configuration Release --no-build --no-restore

# اجرا شد — cwd: scratchpad خارج مخزن تا SDK 10.0.403 انتخاب شود
dotnet list <path>/Probe.csproj package --vulnerable --include-transitive --format json --no-restore
```

نتایج دقیق و SHA-256 lockfileها در [LEGACY_SECURITY_PINS.json](../checkpoint2f/LEGACY_SECURITY_PINS.json) ثبت شده‌اند.

## ۱۸. خطاهای واقعی

- `git status` با «detected dubious ownership» شکست خورد، چون مالک `.git` حساب sandbox است. با `-c safe.directory=…` در هر فرمان رفع شد و تنظیم global تغییر نکرد.
- `robocopy` در PowerShell این محیط یافت نشد. کپی canonical با `git ls-files` و `cp` در Bash انجام شد که فقط فایل‌های tracked را می‌گیرد.
- اولین audit با `Required command was not provided` شکست خورد. علت این بود که `global.json` ریشه SDK 2.1.818 را pin می‌کند و این SDK فرمان `--vulnerable` ندارد. audit از پوشهٔ خارج مخزن با SDK 10.0.403 تکرار شد.
- `secpin3` با `NU1605` شکست خورد. این یافتهٔ واقعی ثبت شد و با override یا سرکوب «رفع» نشد.
- `sds491` با `PlatformNotSupportedException` شکست خورد. این یافتهٔ سازگاری است، نه خطای ابزار.

## ۱۹. تغییرات Git

ساخته‌شده:
- این سند؛
- `docs/checkpoint2f/LEGACY_SECURITY_PINS.json`؛
- انتشار `docs/checkpoint2f/LEGACY_PROVIDER_RESULTS.json` اجرای قبلی، بدون تغییر محتوا.

به‌روزشده:
- `AGENTS.md`، `PLAN.md`، `README.md`؛
- `docs/OPEN_DECISIONS_FA.md`، `docs/AI_CONTINUATION_FA.md`، `docs/TESTING_STRATEGY_FA.md`؛
- `docs/checkpoint2f/CONTINUATION_APPROVAL_FA.md`، `docs/implementation/README.md`، `docs/SOURCE_REFERENCES_FA.md`.

کد، package، lockfile، SQL script و فایل شخصی `launchSettings.json` تغییر نکردند. پوشه‌های آزمایش، logها، `bin/obj` و cacheهای `.packages` ignored‌اند و منتشر نمی‌شوند. SHA و نتیجهٔ push از Git واقعی و [GITHUB_SYNC_FA.md](../GITHUB_SYNC_FA.md) خوانده شوند.

## ۲۰. اقدام مجاز بعدی و پیشرفت

**قبلی 20% + سهم این بررسی 0 = 20%؛ باقی 80%.** وزن‌ها تغییر نکردند. ۲ واحد 2F فقط با این شرایط کسب می‌شوند:
- provider مصوب در canonical؛
- اتصال واقعی؛
- هویت‌های مصوب؛
- effective permission؛
- آزمون‌های repository/transaction/concurrency؛
- regression و بازبینی امنیت.

هدف مشروط پس از آن **22%** است.

اقدام بعدی: توقف تا تصمیم کارفرما دربارهٔ **L1-A** و **L1-R**. پس از تصویب L1-A، یک checkpoint آفلاین متمرکز تغییر بستهٔ canonical را با ۱۵۹ موفق/۸ Skipped و audit ثبت می‌کند. سپس P1 تا P4 به ترتیب و هرکدام با مجوز مستقل اجرا می‌شوند. 2G، OTP، Session، Info، رسانه و Production شروع نشده‌اند.
