# اعمال L1-A روی canonical — وابستگی‌های ریز ASP.NET Core 2.1 و `System.Data.SqlClient 4.8.6`

تاریخ: `2026-11-06`؛ مبنا: `0eda1f3e08d1184caafbf706751cfbd9ea61b67a`. این مرحله فقط بخش آفلاین وابستگی‌های Checkpoint 2F است. **2F کامل نیست و پیشرفت 20% می‌ماند.**

## مجوز و مرز کار

دستور مالک پروژه در `2026-11-06` («Execute Approved L1-A») تغییر بستهٔ canonical را صریحاً تصویب کرد. دامنهٔ آن فقط «L1-A offline dependency changes» است. همان دستور تصریح کرد که این تصویب **پذیرش ریسک امنیتی Production (L1-R) نیست** و اتصال SQL، حساب، مجوز، زیرساخت و استقرار مجاز نیستند. سند جداگانه‌ای از کارفرما در مخزن ثبت نشده است؛ مبنای مجوز همین دستور مالک است.

وضعیت اولیه:

- HEAD محلی و `origin/main` برابر `0eda1f3` بودند و worktree فقط `src/Bazdid.Api/Properties/` شخصی را untracked داشت، که دست‌نخورده ماند.
- پیش از تغییر، build مبنا و smoke Kestrel اجرا و Swagger مبنا ذخیره شد تا مقایسهٔ قرارداد ممکن باشد.

## ۱. تغییر دقیق وابستگی‌ها

در `src/Bazdid.Api/Bazdid.Api.csproj` فقط این‌ها تغییر کردند:

- `<PackageReference Include="Microsoft.AspNetCore.App" Version="2.1.30" />` حذف شد.
- ۳۵ بستهٔ ریز با نسخهٔ دقیق (`[x.y.z]`) افزوده شدند.
- `Newtonsoft.Json 13.0.4` و `Swashbuckle.AspNetCore 4.0.1` همان قبلی ماندند.
- `<WarningsAsErrors>NU1608;NU1605;NU1701</WarningsAsErrors>` افزوده شد تا هر تعارض یا downgrade آینده build را متوقف کند. این خط سخت‌گیری را بیشتر می‌کند و warningی را سرکوب نمی‌کند.

فایل حاصل از نظر محتوا **دقیقاً همان** csproj آزموده‌شدهٔ `.sync-tmp/l1-canonical-granular` است؛ فقط پایان خط به CRLF مخزن یکسان شد. سه lockfile تولیدشده هم **بایت‌به‌بایت** با lockfileهای همان کپی برابرند (SHA-256 در [L1A_VALIDATION.json](../checkpoint2f/L1A_VALIDATION.json)). هیچ نسخه‌ای خارج از گراف آزموده انتخاب نشد.

قطعهٔ مهم:

```xml
<PackageReference Include="Microsoft.AspNetCore.Server.Kestrel.Transport.Sockets" Version="[2.1.40]" />
<PackageReference Include="System.Data.SqlClient" Version="[4.8.6]" />
<PackageReference Include="System.Security.Cryptography.Pkcs" Version="[4.7.0]" />
<PackageReference Include="System.Security.Cryptography.Xml" Version="[4.7.1]" />
<PackageReference Include="System.Text.RegularExpressions" Version="[4.3.1]" />
```

فهرست کامل ۳۵ بسته در بخش ۱۳ [walkthrough L1](CHECKPOINT-02F-LEGACY-SQLCLIENT-FEASIBILITY_FA.md) و در خود [Bazdid.Api.csproj](../../src/Bazdid.Api/Bazdid.Api.csproj) آمده است.

## ۲. چرا لازم بود

`Microsoft.AspNetCore.App 2.1.30` سقف `System.Data.SqlClient < 4.6.0` را تحمیل می‌کند. تنها نسخهٔ موجود در آن بازه (`4.5.3`) دو advisory دارد و نسخهٔ وصله‌شده‌ای در آن بازه وجود ندارد. گراف ریز این سقف را برمی‌دارد و `4.8.6` را بدون override یا سرکوب warning ممکن می‌کند. هم‌زمان ۷ advisory انتقالی دیگر canonical را هم رفع می‌کند. جزئیات پژوهش در [walkthrough L1](CHECKPOINT-02F-LEGACY-SQLCLIENT-FEASIBILITY_FA.md) آمده و در این مرحله تکرار نشد.

## ۳. سازگاری target

- `TargetFramework` برابر `netcoreapp2.1`؛ `LangVersion 7.3` و `RuntimeFrameworkVersion 2.1.30` در `Directory.Build.props` بدون تغییر.
- `runtimeconfig.json` خروجی اکنون فقط `Microsoft.NETCore.App 2.1.30` را می‌خواهد. پیش‌تر `Microsoft.AspNetCore.App 2.1.30` را می‌خواست.
- پیامد استقرار: DLLهای ASP.NET Core دیگر از shared framework سرور بار نمی‌شوند و کنار برنامه قرار می‌گیرند. publish آزمایشی به scratchpad (بدون استقرار) ۱۲۰ DLL، `sni.dll` برای `win-x64`/`win-x86`/`win-arm64` و `web.config` تولید کرد. `appsettings.Production.example.json` و `packages.lock.json` همچنان منتشر نمی‌شوند. ANCM و Hosting Bundle روی IIS هنوز لازم‌اند و رفتار IIS/staging آزموده نشده است.
- در `deps.json`: `System.Data.SqlClient/4.8.6`، `Kestrel.Core/2.1.25`، `Kestrel.Transport.Sockets/2.1.40`، `RegularExpressions/4.3.1`، `Cryptography.Xml/4.7.1`، `Pkcs/4.7.0`. در `project.assets.json` هیچ `Microsoft.AspNetCore.App` وجود ندارد.

## ۴. نتایج build و آزمون (اجرای تازه)

```powershell
# اجرا شد — cwd: C:\Projects\vehicle-inspection-backend (SDK 2.1.818)
dotnet restore Bazdid.sln
dotnet restore Bazdid.sln --locked-mode
dotnet build Bazdid.sln --configuration Release --no-restore
dotnet test Bazdid.sln --configuration Release --no-build --no-restore
```

| مرحله | نتیجه |
|---|---|
| restore / locked restore | exit 0 / exit 0؛ بدون warning NuGet |
| build | 0 warning، 0 error |
| `Bazdid.UnitTests` | ۱۰۹ کل، ۱۰۹ موفق |
| `Bazdid.IntegrationTests` (آفلاین) | ۵۸ کل، ۵۰ موفق، ۰ شکست، **۸ Skipped** |
| آزمون SQL متصل | ۰ اجرا؛ ۸ مورد Skip با `SqlRuntimeGate.BlockReason` |

آزمون Skipped موفق شمرده نمی‌شود. کد آزمون تغییری نکرد: ۷۹ attribute `Fact`/`Theory` و ۸ `Skip` همان قبلی‌اند و `git diff` روی `tests/` فقط سه lockfile را نشان می‌دهد.

**smoke Kestrel** (helper محلی برگرفته از `.sync-tmp/cp2f-smoke.ps1`، loopback، `Development`):

| | health | Swagger | `basePath` | تعداد path عمومی |
|---|---|---|---|---|
| پیش از تغییر | 200 | 200 | `/API/BAZDID` | 1 (`/health/live`) |
| پس از تغییر | 200 | 200 | `/API/BAZDID` | 1 |

سند Swagger قبل و بعد **بایت‌به‌بایت یکسان** است (SHA-256 `4396ffe7…c173`). پس endpoint، route یا قرارداد عمومی جدیدی ایجاد نشده است. فرآیند پس از آزمون بسته شد. IIS آزموده نشد.

## ۵. نتیجهٔ audit

`dotnet list <project> package --vulnerable --include-transitive` با SDK `10.0.403` از پوشهٔ خارج مخزن اجرا شد، چون `global.json` ریشه SDK 2.1.818 را pin می‌کند که این فرمان را ندارد. نتیجه در هر سه پروژه: **۲ بستهٔ flagged** (پیش‌تر ۹).

## ۶. آسیب‌پذیری‌های باقی‌مانده

| بسته | شدت | advisory | وضعیت |
|---|---|---|---|
| `Microsoft.AspNetCore.Server.Kestrel.Core 2.1.25` | **Critical** | `GHSA-5rrx-jjjq-q2r5` / CVE-2025-55315 (request smuggling) | وصله فقط در خط 2.3 (`2.3.6`)؛ در 2.1 وصله‌ای نیست |
| `Swashbuckle.AspNetCore.SwaggerUI 4.0.1` | Moderate | `GHSA-qrmm-w75w-3wpx` (SSRF در UI) | وصله در `6.3.0`؛ UI فقط در `Development`/`Testing` فعال می‌شود |

به‌علاوه، runtime 2.1 از `2021-08-21` پشتیبانی ندارد و `System.Data.SqlClient` در NuGet deprecated است. هیچ advisory سرکوب نشد. **این نسخه امن یا آمادهٔ Production اعلام نمی‌شود.** پذیرش این ریسک تصمیم L1-R کارفرما است.

## ۷. فایل‌های تغییرکرده

| فایل | مسئولیت |
|---|---|
| `src/Bazdid.Api/Bazdid.Api.csproj` | جایگزینی metapackage با گراف ریز آزموده |
| `src/Bazdid.Api/packages.lock.json`، `tests/Bazdid.IntegrationTests/packages.lock.json`، `tests/Bazdid.UnitTests/packages.lock.json` | lockfileهای بازتولیدشده، برابر کپی آزموده |
| این سند و [L1A_VALIDATION.json](../checkpoint2f/L1A_VALIDATION.json) | walkthrough و شاهد ماشین‌خوان |
| `AGENTS.md`، `PLAN.md`، `README.md`، `docs/OPEN_DECISIONS_FA.md`، `docs/AI_CONTINUATION_FA.md`، `docs/TESTING_STRATEGY_FA.md`، `docs/implementation/README.md`، `docs/GITHUB_SYNC_FA.md` | به‌روزرسانی وضعیت |

هیچ فایل C#، تنظیمات، SQL script، endpoint یا آزمونی تغییر نکرد. `launchSettings.json` شخصی و Frontend دست‌نخورده‌اند.

## ۸. خطاهای واقعی

- helper smoke که در scratchpad بدون BOM ذخیره شده بود، در PowerShell 5.1 با رمزگذاری ANSI خوانده شد و متن فارسی آن parse نشد (`Unexpected token`). با ذخیرهٔ UTF-8 همراه BOM رفع شد. این خطا مربوط به ابزار آزمون بود، نه برنامه.
- کپی خام csproj پایان خط متفاوتی داشت. با یکسان‌سازی به CRLF رفع شد و محتوای بدون CR با کپی آزموده برابر تأیید شد.
- خطای restore، build یا آزمون رخ نداد.

## ۹. وضعیت gate SQL

- `SqlRuntimeGate.ConnectedAcceptanceVerified => false` بدون تغییر.
- `appsettings.json`: `SqlRuntime.Enabled=false`. فایل‌های محیطی دیگر این کلید را override نمی‌کنند.
- هیچ اتصال SQL، کوئری، DDL/DML، load فایل native، SSPI یا TLS اجرا نشد.

## ۱۰. تصویب‌های بعدی لازم

به ترتیب، هرکدام مستقل:

۱. **L1-R** (کارفرما/امنیت): پذیرش مکتوب و زمان‌دار ریسک CVE-2025-55315 و runtime EOL، با کنترل‌های جبرانی (Kestrel فقط پشت IIS/ANCM، request filtering، SwaggerUI خاموش در Production) و تاریخ بازبینی.
۲. **P1** (مدیر Windows): دو حساب `<MACHINE>\BAZDIDDevWriter` و `<MACHINE>\BAZDIDDevReader`، یا فقط Writer با نسخهٔ تازهٔ script.
۳. **P2** (DBA): اجرای دو script بازبینی‌شده با SID و مرجع تصویب.
۴. **P3**: certificate و آزمون TLS برای `Encrypt=true` و `TrustServerCertificate=false`.
۵. **P4/P5**: بازکردن کنترل‌شدهٔ gate، اجرای ۸ آزمون متصل، fixture و cleanup.

پس از پذیرش کامل 2F، Checkpoint 2G با مجوز جدای پایگاه موقت شروع می‌شود. آزمون IIS/staging برای خروجی app-local هم پیش از هر استقرار لازم است.

## ۱۱. Git

commit این تغییر و نتیجهٔ push در [GITHUB_SYNC_FA.md](../GITHUB_SYNC_FA.md) ثبت می‌شوند. SHA نهایی را از Git واقعی بخوانید. هیچ آزمایش، log، خروجی publish، `bin/obj` یا راز منتشر نمی‌شود.

## ۱۲. پیشرفت

**قبلی 20% + سهم L1-A 0 = 20%؛ باقی 80%.** L1-A پیش‌نیاز آفلاین است و معیار پذیرش 2F (اتصال واقعی، هویت‌ها، effective permission، آزمون‌های repository/transaction/concurrency) را برآورده نمی‌کند. هدف مشروط پس از پذیرش کامل 2F برابر **22%** است. 2G شروع نشده است.
