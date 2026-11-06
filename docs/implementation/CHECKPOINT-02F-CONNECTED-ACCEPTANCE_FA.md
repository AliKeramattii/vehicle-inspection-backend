# پذیرش متصل Checkpoint 2F (P1–P5) — اجرای مرحله‌ای و مانع واقعی

تاریخ: `2026-11-06`؛ مبنا: `c17e5183b53b91cb7aa20d50f86604da7760360c`. **نتیجه: 2F پذیرفته نشد و پیشرفت 20% می‌ماند.** این سند پیش‌بررسی واقعی، مانع TLS، نبود دسترسی مدیر در نشست و بستهٔ دقیق ادامه را ثبت می‌کند. شاهد ماشین‌خوان: [CONNECTED_PREFLIGHT.json](../checkpoint2f/CONNECTED_PREFLIGHT.json).

## ۱. دامنهٔ مجوز مالک

مالک پروژه در `2026-11-06` اعلام کرد کارفرما اختیار کامل کارهای لازم Development محلی را به او تفویض کرده است و تصویب‌های لازم قابل اخذند. این دستور برای عملیات محلی Development در دامنهٔ P1–P5 به‌عنوان **اعلام مالک** ثبت می‌شود. امضای کارفرما، شمارهٔ تصویب یا پذیرش رسمی ریسک Production وجود ندارد و ساخته نشد.

محدودیت‌ها:

- فقط ماشین محلی، instance `SQLSERVER2019` و پایگاه `BAZDID_Development`؛
- بدون Production، بدون استقرار و بدون دسترسی به داده یا جدول کارگزاری؛
- بدون bypass امنیتی، بدون عملیات مخرب و بدون ری‌استارت سرویس مشترک بدون احراز اثر آن.

## ۲. محیط واقعی

| مورد | مقدار مشاهده‌شده |
|---|---|
| سیستم‌عامل | Windows 11 Home `10.0.26200` |
| هویت نشست | کاربر مالک، عضو Administrators، اما **token نشست elevated نیست** (UAC) |
| SDK / runtime | `2.1.818` / `2.1.30`؛ provider برنامه `System.Data.SqlClient 4.8.6` |
| سرویس SQL | `MSSQL$SQLSERVER2019` در حال اجرا با حساب `NT Service\MSSQL$SQLSERVER2019` |
| پروتکل‌ها | Shared Memory فعال، Named Pipes غیرفعال، TCP فعال با port پویای `59725` |
| TLS سرور | `ForceEncryption=0` و مقدار `Certificate` **خالی**؛ instance از certificate خودساختهٔ داخلی استفاده می‌کند |
| certificate ماشین | فقط یک `CN=localhost` self-signed توسعه‌ای که برای SQL تنظیم نشده است |
| حساب‌های P1 | `BAZDIDDevWriter` و `BAZDIDDevReader` وجود ندارند |
| Git | `main` برابر `origin/main` (`c17e518`)؛ فقط `src/Bazdid.Api/Properties/` شخصی untracked |

نام ماشین فقط محلی خوانده شد و در مستندات منتشر نمی‌شود.

## ۳. ریسک‌های باقی‌مانده و ثبت L1-R در دامنهٔ Development

- `Microsoft.AspNetCore.Server.Kestrel.Core 2.1.25`: Critical، CVE-2025-55315، بدون وصله در خط 2.1.
- `Swashbuckle.AspNetCore.SwaggerUI 4.0.1`: Moderate.
- runtime پشتیبانی‌نشدهٔ ASP.NET Core 2.1.

موارد زیر صریحاً ثبت می‌شوند:

- مجوز آزمون Development **تصویب امنیتی Production نیست**.
- تغییر مجوزها یا حساب‌ها هیچ‌کدام از این آسیب‌پذیری‌ها را رفع نمی‌کند.
- سرویس‌های Development نباید در دسترس عمومی قرار گیرند: Kestrel فقط loopback، SQL بدون پورت عمومی یا تغییر firewall.
- هیچ استقرار Production مجاز نیست.
- ریسک باقی‌مانده مالک و تصمیم اصلاحی آینده لازم دارد. **L1-R رسمی** برای هر استفادهٔ عمومی یا Production همچنان باز است و باید مالک ریسک، کنترل‌های جبرانی و تاریخ بازبینی را تعیین کند.

## ۴. P1 — حساب‌های Windows

**اجرا نشد.** ساخت حساب محلی به token مدیر نیاز دارد و نشست فعلی elevated نیست. حساب‌ها وجود ندارند و چیزی ساخته یا reset نشد.

بستهٔ تحویل مدیر: [New-BazdidDevIdentities.review.ps1](../../deployment/development/New-BazdidDevIdentities.review.ps1) با SHA-256 `b8e0cb09…acfc`. رفتار آن:

- بدون `-Execute` فقط پیش‌شرط‌ها را نشان می‌دهد.
- اگر هرکدام از حساب‌ها وجود داشته باشد، متوقف می‌شود.
- رمز تصادفی ۲۵۶ بیتی را فقط در حافظه و به‌صورت `SecureString` می‌سازد و هرگز نمایش، ثبت یا ذخیره نمی‌کند.
- حساب‌ها را عضو Administrators، Users یا Remote Desktop Users نمی‌کند، پس ورود تعاملی و RDP ندارند.
- خروجی فقط نام کامل و SID است.

حق batch logon و ACL پوشهٔ آزمون در P4، هنگام ثبت task اجرای آزمون، با همان حساب و رمز تازهٔ درون‌حافظه تنظیم می‌شوند.

## ۵. P2 — principalها و نقش‌های SQL

**اجرا نشد.** P2 به SID واقعی حساب‌های P1 و یک اتصال امن به SQL نیاز دارد، که P3 مانع آن است. دو script بازبینی‌شده بدون تغییر ماندند و hash آن‌ها با شاهد قبلی برابر است. نسخهٔ اجرایی پارامتری فقط پس از P1 و با این مقادیر ساخته می‌شود:

- نام ماشین؛
- نام کامل دو login؛
- SID باینری خوانده‌شده از Windows؛
- مرجع تصویب؛
- `@AllowDdl=1` فقط در همان نسخهٔ اجرایی.

guard فایل‌های ثبت‌شده حذف نمی‌شود. مجوزهای هدف همان جدول بخش ۱۵ [walkthrough L1](CHECKPOINT-02F-LEGACY-SQLCLIENT-FEASIBILITY_FA.md) هستند.

## ۶. آزمون effective permission

اجرا نشد، چون هیچ حساب یا login وجود ندارد. روش آزمون بعد از P2: آزمون `Actual_writer_cannot_read_audit_or_delete_contexts_or_issue_DDL` و guard اتصال در `BazdidWriteConnectionFactory` زیر token واقعی Writer اجرا شوند. یک verifier مستقل با هویت DBA هم عضویت‌های ارثی را کنترل کند.

## ۷. نتیجهٔ اتصال SQL Client

probe فقط‌خواندنی ignored با همان provider برنامه ساخته شد (netcoreapp2.1، `System.Data.SqlClient 4.8.6`، win-x64). در کد آن هیچ DML یا DDL وجود ندارد.

```text
Data Source=lpc:.\SQLSERVER2019; Initial Catalog=BAZDID_Development;
Integrated Security=true; Encrypt=true; TrustServerCertificate=false; Connect Timeout=5
```

نتیجهٔ واقعی:

| بررسی | نتیجه |
|---|---|
| بارگذاری provider مدیریت‌شده | موفق؛ assembly `4.6.1.6` روی runtime 2.1.30 |
| رسیدن native SNI به سرور | موفق؛ پیام «A connection was successfully established with the server» |
| TLS / login | **شکست** `-2146893019` (`0x80090325`، `SEC_E_UNTRUSTED_ROOT`)، Class 20: «The certificate chain was issued by an authority that is not trusted» |
| هویت SQL، instance، پایگاه | **تأیید نشد**؛ login کامل نشد |

سیاست اتصال تضعیف نشد. با `Encrypt=false` یا `TrustServerCertificate=true` هیچ تلاشی انجام نشد.

## ۸. یافته‌های TLS و certificate

- با `Encrypt=true`، handshake TLS حتی روی **Shared Memory** انجام می‌شود و certificate سرور اعتبارسنجی می‌شود. پس اتصال محلی بدون certificate معتبر قابل پذیرش نیست.
- این به معنای اثبات رمزنگاری شبکه نیست. TCP جداگانه آزموده نشد، چون با همین certificate همان شکست را می‌دهد و endpoint شبکه در دامنهٔ کد برنامه نیست.
- علت: مقدار `Certificate` در `SuperSocketNetLib` خالی است و instance certificate خودساختهٔ نامعتبر برای کلاینت ارائه می‌کند.

**کوچک‌ترین اصلاح امن** (نیازمند مدیر و ری‌استارت همین instance محلی): اجرای [Set-BazdidSqlDevCertificate.review.ps1](../../deployment/development/Set-BazdidSqlDevCertificate.review.ps1) با SHA-256 `638336a9…2536`. این script:

- certificate اختصاصی `CN=<MACHINE>` با SAN `<MACHINE>` و `localhost` و FQDN، EKU serverAuth، کلید RSA 2048 غیرقابل‌export و اعتبار یک‌ساله می‌سازد؛
- مجوز Read کلید خصوصی را فقط به `NT Service\MSSQL$SQLSERVER2019` می‌دهد؛
- فقط بخش عمومی همان certificate را به `LocalMachine\Root` می‌افزاید؛
- thumbprint را در `SuperSocketNetLib\Certificate` ثبت می‌کند؛
- ری‌استارت را فقط با `-RestartSqlService` انجام می‌دهد؛
- اگر certificate دیگری از قبل تنظیم شده باشد، متوقف می‌شود.

جایگزین بهتر، اگر PKI سازمانی وجود دارد: certificate صادرشده از CA سازمان، که نیاز به افزودن self-signed به Root را حذف می‌کند.

اینکه برای مقصد `lpc:.\SQLSERVER2019` کدام نام در اعتبارسنجی certificate به کار می‌رود، پس از نصب certificate با همین probe آزموده می‌شود. اگر نام برابر نباشد، شکست ثبت و اصلاح می‌شود، نه دور زده.

## ۹. gate زمان اجرا

**بدون تغییر:** `SqlRuntimeGate.ConnectedAcceptanceVerified => false` و `SqlRuntime.Enabled=false`. طبق دستور، مسیر فعال‌سازی فقط «پس از تأیید پیش‌نیازها» پیاده می‌شود و P1 و P3 تأیید نشده‌اند. طرح پیشنهادی آینده، که هنوز پیاده نشده:

- **نشانهٔ پذیرش آزمون** به‌صورت `internal` (دسترس‌پذیر فقط برای `Bazdid.IntegrationTests` از طریق `InternalsVisibleTo` موجود). فقط وقتی ساخته می‌شود که همهٔ این شرط‌ها برقرار باشد:
  - محیط `Testing`؛
  - انتخاب صریح اجرای متصل؛
  - برابری token جاری Windows با `ApprovedWriterPrincipal` که به `\BAZDIDDevWriter` ختم شود؛
  - مقصد دقیق `BuildLocalConnectionString()`.
- سازندهٔ `internal` دوم برای `BazdidWriteConnectionFactory`. DI برنامه فقط سازندهٔ public را می‌بیند، پس Production و برنامه بسته می‌مانند.
- query guard موجود (نبود sysadmin و db_owner، مجوزهای دقیق، Shared Memory، NTLM/Kerberos) دست‌نخورده باقی می‌ماند.
- جایگزینی `[Fact(Skip=...)]` با attributeی که بدون انتخاب صریح Skip می‌ماند. اگر اجرا انتخاب شده ولی پیش‌شرط برقرار نباشد، آزمون شکست می‌خورد، نه Skip.

## ۱۰. آزمون‌های SQL متصل

صفر اجرا. هر ۸ آزمون `SqlRepositoryConnectedTests` با `SqlRuntimeGate.BlockReason` Skip هستند و موفق شمرده نمی‌شوند.

## ۱۱. transaction و concurrency

اجرا نشد. P5، یعنی manifest با `RunId` و شناسه‌های ساختگی، ردیف‌های انتظاری، دامنهٔ cleanup و verifier مستقل، فقط پس از P4 تعریف و اجرا می‌شود.

## ۱۲. شاهد cleanup و وضعیت پایگاه

هیچ دادهٔ آزمونی نوشته نشد و cleanup لازم نیست. وضعیت پایگاه قبل و بعد **خوانده نشد**، چون اتصال امن پیش از login رد شد. اتصال ضعیف‌تر هم صرفاً برای خواندن metadata برقرار نشد. هیچ DML یا DDL، تغییر حساب یا تغییر registry انجام نشد. اجرای غیرelevated دو script تحویلی هم در guard اول رد شد و پس از آن حساب‌ها همچنان وجود نداشتند و `Certificate` همچنان خالی بود.

## ۱۳. خطاها و اصلاح‌ها

- خطای TLS بالا یافتهٔ اصلی است و با دور زدن «رفع» نشد.
- بدون elevation، P1 ممکن نبود؛ به‌جای ادعای اجرا، بستهٔ مدیر تهیه شد.
- PowerShell 5.1 فایل UTF-8 بدون BOM را ANSI می‌خواند، پس هر دو script با BOM ذخیره شدند و parser صفر خطا داد.

## ۱۴. فایل‌های تغییرکرده

ساخته‌شده:

- این سند؛
- [CONNECTED_PREFLIGHT.json](../checkpoint2f/CONNECTED_PREFLIGHT.json)؛
- `deployment/development/Set-BazdidSqlDevCertificate.review.ps1`؛
- `deployment/development/New-BazdidDevIdentities.review.ps1`.

به‌روزشده: `AGENTS.md`، `PLAN.md`، `README.md`، `docs/OPEN_DECISIONS_FA.md`، `docs/AI_CONTINUATION_FA.md`، `docs/TESTING_STRATEGY_FA.md`، `docs/checkpoint2f/CONTINUATION_APPROVAL_FA.md`، `docs/implementation/README.md` و `docs/GITHUB_SYNC_FA.md`.

کد برنامه، آزمون‌ها، package و lockfile، SQL scriptها و `launchSettings.json` تغییر نکردند.

## ۱۵. فرمان‌های واقعاً اجراشده

```powershell
# اجرا شد — cwd: ریشهٔ مخزن؛ فقط‌خواندنی
[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole('Administrator')
Get-LocalUser -Name BAZDIDDevWriter, BAZDIDDevReader
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL15.SQLSERVER2019\MSSQLServer\SuperSocketNetLib'
Get-ChildItem Cert:\LocalMachine\My

# اجرا شد — cwd: .sync-tmp\l1-legacy-spike-20261103\p3_probe (ignored)
dotnet restore Probe.csproj --locked-mode
dotnet build Probe.csproj -c Release --no-restore
dotnet bin/Release/netcoreapp2.1/win-x64/Probe.dll lpc meta

# اجرا شد — آزمون منفی guard بدون elevation؛ هر دو رد شدند
& deployment/development/New-BazdidDevIdentities.review.ps1 -ExpectedMachine $env:COMPUTERNAME -ApprovalReference NEGATIVE-TEST
& deployment/development/Set-BazdidSqlDevCertificate.review.ps1 -ExpectedMachine $env:COMPUTERNAME -ApprovalReference NEGATIVE-TEST

# اجرا شد — regression
dotnet restore Bazdid.sln --locked-mode
dotnet build Bazdid.sln --configuration Release --no-restore
dotnet test Bazdid.sln --configuration Release --no-build --no-restore
```

نتیجهٔ regression: build با 0 warning و 0 error؛ ۱۰۹/۱۰۹ unit؛ ۵۰ موفق، ۰ شکست و ۸ Skipped از ۵۸ integration. smoke Kestrel: health و Swagger برابر 200، basePath `/API/BAZDID`، یک path عمومی، و Swagger برابر مبنای L1-A.

## ۱۶. Git

SHA و push در [GITHUB_SYNC_FA.md](../GITHUB_SYNC_FA.md) ثبت می‌شوند. probe، logها و خروجی‌های موقت منتشر نمی‌شوند.

## ۱۷. محدودیت‌ها

- نسخهٔ SQL Server، collation و شمار ردیف‌ها خوانده نشدند.
- رفتار نام‌سنجی certificate برای Shared Memory هنوز آزموده نشده است.
- TCP و TLS شبکه آزموده نشدند.
- طرح P4 پیاده نشده است.
- Windows 11 Home ابزار گرافیکی Local Security Policy ندارد. طرح حساب‌ها برای همین به عضویت گروه و حق خودکار batch در Task Scheduler تکیه دارد، و این حق پس از ثبت task باید جداگانه راستی‌آزمایی شود.

## ۱۸. تصمیم نهایی پذیرش 2F

**پذیرفته نشد.** دو مانع اجرایی وجود دارد:

۱. token مدیر برای P1 و P3 در نشست عامل وجود ندارد.
۲. certificate معتبر TLS برای instance تنظیم نشده است.

**قبلی 20% + سهم 0 = 20%.** 2G شروع نشده است.

ترتیب ادامه:

۱. **مدیر محلی** در PowerShell elevated، پس از بازبینی، P3 را ابتدا با `-ExpectedMachine <MACHINE> -ApprovalReference <مرجع>` و بدون `-Execute` اجرا می‌کند، سپس با `-Execute -RestartSqlService`. ری‌استارت فقط وقتی انجام شود که برنامهٔ دیگری به همین instance محلی وابسته نباشد.
۲. عامل probe را دوباره اجرا می‌کند و TLS، هویت، instance، پایگاه و metadata را ثبت می‌کند.
۳. مدیر P1 را با همان الگو اجرا می‌کند و SIDها را اعلام می‌کند.
۴. عامل نسخهٔ اجرایی پارامتری P2 را آماده می‌کند و مدیر یا DBA آن را اجرا می‌کند.
۵. عامل P4 (مسیر آزمون internal و task اجرا با Writer) و P5 (manifest) را پیاده و اجرا می‌کند.
