# پذیرش متصل Checkpoint 2F (P1–P5) — اجرای مرحله‌ای و مانع واقعی

تاریخ: `2026-11-06`؛ مبنا: `c17e5183b53b91cb7aa20d50f86604da7760360c`. **نتیجه: 2F پذیرفته نشد و پیشرفت 20% می‌ماند.** این سند پیش‌بررسی واقعی، مانع TLS، نبود دسترسی مدیر در نشست و بستهٔ دقیق ادامه را ثبت می‌کند. شاهد ماشین‌خوان: [CONNECTED_PREFLIGHT.json](../checkpoint2f/CONNECTED_PREFLIGHT.json).

> **به‌روزرسانی `2026-11-07`:** نصب certificate در P3 توسط مدیر موفق بود و اعتماد زنجیره حل شد. اتصال provider برنامه با مقصد pin‌شدهٔ `lpc:.\SQLSERVER2019` اکنون با `SEC_E_WRONG_PRINCIPAL` (ناسازگاری نام) رد می‌شود. همان سیاست امن با `localhost` یا نام میزبان، هم روی Shared Memory و هم روی loopback TCP، موفق است. جزئیات در [بخش ۲۰](#p3-verification-20261107) آمده است. پیشرفت همچنان 20% است.

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

بستهٔ تحویل مدیر: [New-BazdidDevIdentities.review.ps1](../../deployment/development/New-BazdidDevIdentities.review.ps1). نسخهٔ اولیه (`b8e0cb09…acfc`) در `2026-11-07` اصلاح شد و جای آن را نسخهٔ `351227f2…838a` گرفت. رفتار، فرمان‌ها، بازگشت و چرخهٔ عمر رمز در [بخش ۱۹](#revision-20261107) آمده‌اند.

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

**کوچک‌ترین اصلاح امن** (نیازمند مدیر و ری‌استارت همین instance محلی): اجرای [Set-BazdidSqlDevCertificate.review.ps1](../../deployment/development/Set-BazdidSqlDevCertificate.review.ps1). نسخهٔ اولیه (`638336a9…2536`) در `2026-11-07` اصلاح شد و جای آن را نسخهٔ `07383213…49ec` گرفت. مشخصات certificate، پیش‌شرط ری‌استارت، راستی‌آزمایی و بازگشت در [بخش ۱۹](#revision-20261107) آمده‌اند.

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
- Windows 11 Home ابزار گرافیکی Local Security Policy ندارد. از بازنگری `2026-11-07`، حق‌های logon مستقیم با LSA API اعطا و بازخوانی می‌شوند و دیگر به اعطای خودکار Task Scheduler تکیه نمی‌شود.

## ۱۸. تصمیم نهایی پذیرش 2F

**پذیرفته نشد.** دو مانع اجرایی وجود دارد:

۱. token مدیر برای P1 و P3 در نشست عامل وجود ندارد.
۲. certificate معتبر TLS برای instance تنظیم نشده است.

**قبلی 20% + سهم 0 = 20%.** 2G شروع نشده است.

ترتیب ادامه (فرمان‌های دقیق در [بخش ۱۹](#revision-20261107)):

۱. **مدیر محلی** در PowerShell elevated، پس از بازبینی hash، P3 را ابتدا dry run و سپس با `-Execute -RestartSqlService` اجرا می‌کند و `-VerifyOnly` را می‌گیرد. ری‌استارت فقط وقتی انجام شود که برنامهٔ دیگری به همین instance محلی وابسته نباشد.
۲. عامل probe را دوباره اجرا می‌کند و TLS، هویت، instance، پایگاه و metadata را ثبت می‌کند.
۳. مدیر P1 را با همان الگو اجرا می‌کند، `-VerifyOnly` را می‌گیرد و SIDها را اعلام می‌کند.
۴. عامل نسخهٔ اجرایی پارامتری P2 را آماده می‌کند و مدیر یا DBA آن را اجرا می‌کند.
۵. عامل P4 (مسیر آزمون internal و task اجرا با Writer) و P5 (manifest) را پیاده و اجرا می‌کند.

<a id="revision-20261107"></a>

## ۱۹. بازنگری scriptهای P1 و P3 پیش از اجرا (2026-11-07)

### ۱۹.۱ زمینه و مرز کار

مالک گزارش داد dry run هر دو نسخهٔ اولیه در PowerShell elevated روی ماشین هدف موفق بوده و هیچ تغییری اعمال نشده است. این گزارش مالک است و عامل آن را مستقلاً مشاهده نکرده است. در hash گزارش‌شده برای certificate یک نویسه جا افتاده است (`…696BBD14…` به‌جای `…696B6BD14…`). hash کامل نسخهٔ اولیه `638336a9696b6bd14cc43e7149ab7fa5f05594cdcafe22daa1a36e1050ea2536` بود.

عامل در این بازنگری هیچ script را اجرا نکرد. هیچ حساب، certificate، login یا مجوزی ساخته نشد و سرویس SQL ری‌استارت نشد. تحقیق SQL Client تکرار نشد.

### ۱۹.۲ نقص‌های واقعی و اصلاح آن‌ها

| مورد | نقص نسخهٔ اولیه | اصلاح |
| --- | --- | --- |
| P1 توضیح حساب | `New-LocalUser -Description` حداکثر ۴۸ نویسه می‌پذیرد (با `Get-Command` تأیید شد). توضیح قبلی با مرجع تصویب حدود ۶۶ نویسه بود، پس `-Execute` شکست می‌خورد. | توضیح `BAZDID-DEV-SQL <ref>` با مرجع حداکثر ۳۲ نویسه از `[A-Za-z0-9._-]`؛ حداکثر ۴۷ نویسه. |
| P1 اجرای task | هیچ `SeBatchLogonRight` صریحی نبود و به اعطای خودکار Task Scheduler تکیه می‌شد. | اعطای مستقیم با LSA API و بازخوانی دقیق. |
| P1 حداقل اختیار | ورود تعاملی، RDP و service فقط با عضونبودن در گروه محدود می‌شد. | `SeDenyInteractiveLogonRight`، `SeDenyRemoteInteractiveLogonRight` و `SeDenyServiceLogonRight` صریح. |
| P1 شکست جزئی | اگر حساب دوم شکست می‌خورد، حساب اول می‌ماند و هر اجرای بعدی رد می‌شد. | بازگشت خودکار فقط برای حساب‌ها و حق‌های ساخته‌شده در همان اجرا، به‌علاوهٔ حالت `-RemoveForRecovery`. |
| P1 کنترل گروه | `Get-LocalGroupMember ... -ErrorAction SilentlyContinue` شکست خواندن را «عضو نیست» تعبیر می‌کرد. | عضویت مستقیم از دید خود حساب با ADSI؛ شکست خواندن، خطا است. انتظار: هیچ گروه مستقیم. |
| P1 رمز | رمز دور ریخته می‌شد و ثبت task با رمز ذخیره‌شده، reset مستند‌نشده لازم داشت. | چرخهٔ عمر صریح (۱۹.۵): provisioning در P4 همیشه از طریق چرخش رمز. |
| P1 راستی‌آزمایی | فقط خروجی SID. | حالت فقط‌خواندنی `-VerifyOnly` با PASS/FAIL. |
| P3 ناسازگاری | شکست پس از ساخت certificate، آن را در My یا Root، یا registry را با thumbprint بارگذاری‌نشدنی باقی می‌گذاشت. | بازگشت خودکار به ترتیب معکوس (registry، Root، My با `-DeleteKey`)، به‌علاوهٔ اجرای دوبارهٔ سرویس اگر ری‌استارت شروع شده بود؛ بازگشت ناقص با پیام صریح و حالت `-RollbackThumbprint`. |
| P3 گسترهٔ trust | self-signed بدون BasicConstraints و KeyUsage محدود در Root قرار می‌گرفت و به‌طور بالقوه می‌توانست certificate دیگری را امضا کند. | BasicConstraints بحرانی `CA=false`، KeyUsage فقط `DigitalSignature, KeyEncipherment` (بدون `keyCertSign`)، EKU فقط serverAuth. |
| P3 ACL کلید | `Set-Acl` مالک را هم می‌نویسد و روی MachineKeys ممکن است شکست بخورد. | فقط DACL با `File.SetAccessControl`. حق دقیق `Read` برای SID سرویس، با بازخوانی. |
| P3 نام | CN از نام NetBIOS بود و FQDN از DNS query. | CN برابر نام DNS میزبان یا FQDN (الزام SQL Server) از `IPGlobalProperties` بدون query شبکه. SAN شامل NetBIOS، نام DNS، FQDN در صورت وجود و `localhost`. |
| P3 ری‌استارت | بدون پیش‌شرط و بدون شاهد بارگذاری. | فقط از وضعیت `Running` و بدون سرویس وابستهٔ در حال اجرا. تأیید پیام `Cert Hash(sha1) "<thumb>"] was successfully loaded for encryption` در ERRORLOG تا ۶۰ ثانیه؛ در غیر این صورت بازگشت. |
| P3 راستی‌آزمایی | وجود نداشت. | `-VerifyOnly` فقط‌خواندنی. |

### ۱۹.۳ طراحی P1

- **حق‌های LSA هر حساب، دقیقاً:** `SeBatchLogonRight`، `SeDenyInteractiveLogonRight`، `SeDenyRemoteInteractiveLogonRight` و `SeDenyServiceLogonRight`.
- **`SeDenyNetworkLogonRight` عمداً داده نمی‌شود.** احراز Windows در SQL Server (SSPI) حتی روی Shared Memory در سمت سرور یک network logon است. dry run هم بررسی می‌کند که `SeNetworkLogonRight` از طریق Everyone، Users یا Authenticated Users در دسترس باشد.
- **عضویت گروه:** هیچ عضویت مستقیمی در هیچ گروهی، از جمله Administrators، Users و Remote Desktop Users. token ویندوز از طریق Authenticated Users گروه Users را دارد، که برای خواندن `dotnet` و مخزن کافی است.
- **رمز:** ۴۰ نویسه از الفبای ۶۴تایی، یعنی ۲۴۰ بیت، مستقیم در `SecureString`؛ هیچ string میانی ساخته نمی‌شود. سپس `PasswordNeverExpires` و `UserMayNotChangePassword` تنظیم می‌شوند.
- **ثبت task با رمز ذخیره‌شده:** dry run تنظیم `DisableDomainCreds` را گزارش می‌کند. اگر برابر ۱ باشد ثبت task ممکن نیست؛ script آن را تغییر نمی‌دهد.
- **حذف بازیابی:** فقط حساب‌هایی که توضیحشان با `BAZDID-DEV-SQL` شروع شود و هیچ task ثبت‌شده‌ای نداشته باشند. حذف واقعی سوئیچ `-SqlLoginsAbsent` می‌خواهد. پس از حذف حساب، profile بارگذاری‌نشده هم حذف می‌شود.

### ۱۹.۴ طراحی P3

- **certificate:**
  - `CN=<نام DNS یا FQDN>`؛
  - RSA 2048 با `KeySpec=KeyExchange` در `Microsoft RSA SChannel Cryptographic Provider` (کلید CAPI، سازگار با SQL Server 2019)؛
  - کلید غیرقابل‌export، SHA256 و اعتبار یک‌ساله.
- **trust:** فقط بخش عمومی، با FriendlyName نشانه‌دار، در `LocalMachine\Root`. store کاربر کافی نیست، چون آزمون‌ها با حساب‌های Writer و Reader اجرا می‌شوند. محدودیت‌های بالا گسترهٔ این trust را به همین نام‌ها و این کلید غیرقابل‌export محدود می‌کنند.
- **چرا `localhost` در SAN است:** نامی که native SNI برای مقصد `lpc:.` در اعتبارسنجی به کار می‌برد هنوز آزموده نشده است. probe پس از P3 آن را مشخص می‌کند. اگر `localhost` لازم نبود، در چرخش بعدی certificate حذف می‌شود.
- **بدون تغییر:** `ForceEncryption=0`، پروتکل‌ها، firewall و تنظیم کلاینت. `Encrypt=true` و `TrustServerCertificate=false` در `BuildLocalConnectionString()` الزامی می‌مانند و هیچ bypass اضافه نشد.

### ۱۹.۵ چرخهٔ عمر رمز حساب‌ها

۱. **ساخت (P1):** رمز تصادفی ناشناخته؛ هیچ انسان یا فایلی آن را ندارد. حساب تا provisioning عملاً قابل استفاده نیست.
۲. **provisioning (P4، با script بازبینی‌شدهٔ جدا که هنوز نوشته نشده است):** در یک PowerShell elevated، رمز تازهٔ تصادفی در حافظه ساخته می‌شود و در همان فرایند با `Set-LocalUser -Password` روی حساب و با `Register-ScheduledTask -User -Password` روی task ثبت می‌شود. Task Scheduler آن را در LSA secrets نگه می‌دارد. `Register-ScheduledTask` رمز را به‌صورت string می‌گیرد، پس رمز فقط لحظه‌ای در حافظهٔ همان فرایند است: نه در command line، نه history، نه log و نه فایل.
۳. **چرخش:** حداکثر هر ۹۰ روز، پس از هر تغییر نفرات یا ظن افشا، با همان روش گام ۲. سپس رمز همهٔ taskهای همان حساب با `Set-ScheduledTask -User -Password` به‌روز می‌شود. رمز هرگز «بازیابی» یا نمایش داده نمی‌شود؛ فقط چرخانده می‌شود.
۴. **ابطال:** `Disable-LocalUser`، حذف taskها، حذف user و login SQL (معکوس P2)، سپس `-RemoveForRecovery -Execute -SqlLoginsAbsent`.

### ۱۹.۶ فرمان‌های dry run (PowerShell با Run as Administrator، cwd ریشهٔ مخزن)

```powershell
# پیشنهادی؛ عامل اجرا نکرده است
Get-FileHash .\deployment\development\Set-BazdidSqlDevCertificate.review.ps1, .\deployment\development\New-BazdidDevIdentities.review.ps1 -Algorithm SHA256
.\deployment\development\Set-BazdidSqlDevCertificate.review.ps1 -ExpectedMachine $env:COMPUTERNAME -ApprovalReference OWNER-2026-11-07
.\deployment\development\New-BazdidDevIdentities.review.ps1 -ExpectedMachine $env:COMPUTERNAME -ApprovalReference OWNER-2026-11-07
```

انتظار dry run در P3:

- `RegistryCertificate` خالی و `ForceEncryption` برابر `0`؛
- `MarkedInMy` و `MarkedInRoot` خالی؛
- `RunningDependents` خالی؛
- پیام «اجرای آزمایشی: هیچ تغییری انجام نشد. پیش‌شرط‌ها برقرارند.»

انتظار dry run در P1:

- `NetworkLogonViaGroup : True` و `StoredTaskPasswordAllowed : True`؛
- `PlannedLsaRights` با چهار حق بالا؛
- پیام «اجرای آزمایشی: هیچ حسابی ساخته نشد.»

هر خطا یعنی توقف قبل از هر تغییر.

### ۱۹.۷ فرمان‌های اجرا و انتظار راستی‌آزمایی

```powershell
# پیشنهادی؛ ترتیب: P3، سپس probe عامل، سپس P1
.\deployment\development\Set-BazdidSqlDevCertificate.review.ps1 -ExpectedMachine $env:COMPUTERNAME -ApprovalReference OWNER-2026-11-07 -Execute -RestartSqlService
.\deployment\development\Set-BazdidSqlDevCertificate.review.ps1 -ExpectedMachine $env:COMPUTERNAME -ApprovalReference OWNER-2026-11-07 -VerifyOnly

.\deployment\development\New-BazdidDevIdentities.review.ps1 -ExpectedMachine $env:COMPUTERNAME -ApprovalReference OWNER-2026-11-07 -Execute
.\deployment\development\New-BazdidDevIdentities.review.ps1 -ExpectedMachine $env:COMPUTERNAME -ApprovalReference OWNER-2026-11-07 -VerifyOnly
```

انتظار در P3:

- خروجی اجرا: `Thumbprint`، `Subject : CN=<host>`، `NotAfter` یک سال بعد و `Restarted : True`.
- `-VerifyOnly`: `LoadedPerErrorLog : True`، `LoadFailureInErrorLog : False`، `Problems` خالی و «راستی‌آزمایی P3: PASS».

انتظار در P1:

- `-VerifyOnly` برای هر حساب: `Exists : True`، `Enabled : True`، `DirectGroups` خالی و `LsaRights : SeBatchLogonRight, SeDenyInteractiveLogonRight, SeDenyRemoteInteractiveLogonRight, SeDenyServiceLogonRight`.
- `Pass : True` و «راستی‌آزمایی P1: PASS».
- SIDها برای P2 اعلام شوند. آن‌ها PII نیستند ولی ماشین‌خاص‌اند و در مستندات با placeholder ثبت می‌شوند.

### ۱۹.۸ بازگشت و بازیابی

**P3 شکست در حین اجرا:** script خودکار برمی‌گرداند. اگر پیام «بازگشت ناقص» داد، یا پس از موفقیت بخواهید برگردانید:

```powershell
.\deployment\development\Set-BazdidSqlDevCertificate.review.ps1 -ExpectedMachine $env:COMPUTERNAME -ApprovalReference OWNER-2026-11-07 -RollbackThumbprint <THUMBPRINT>
.\deployment\development\Set-BazdidSqlDevCertificate.review.ps1 -ExpectedMachine $env:COMPUTERNAME -ApprovalReference OWNER-2026-11-07 -RollbackThumbprint <THUMBPRINT> -Execute -RestartSqlService
```

**SQL پس از ری‌استارت اجرا نشد و بازگشت خودکار هم ناموفق بود:**

۱. مقدار `Certificate` را در `HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL15.SQLSERVER2019\MSSQLServer\SuperSocketNetLib` به رشتهٔ خالی برگردانید.
۲. `Start-Service 'MSSQL$SQLSERVER2019'` را اجرا کنید.
۳. ERRORLOG و Application Event Log را بررسی کنید.
۴. سپس `-RollbackThumbprint` را برای پاک‌سازی storeها اجرا کنید.

**P1 شکست در حین اجرا:** فقط حساب‌های همان اجرا خودکار برگردانده می‌شوند. برای وضعیت باقی‌مانده پس از قطع ناگهانی:

```powershell
.\deployment\development\New-BazdidDevIdentities.review.ps1 -ExpectedMachine $env:COMPUTERNAME -ApprovalReference OWNER-2026-11-07 -VerifyOnly
.\deployment\development\New-BazdidDevIdentities.review.ps1 -ExpectedMachine $env:COMPUTERNAME -ApprovalReference OWNER-2026-11-07 -RemoveForRecovery
.\deployment\development\New-BazdidDevIdentities.review.ps1 -ExpectedMachine $env:COMPUTERNAME -ApprovalReference OWNER-2026-11-07 -RemoveForRecovery -Execute -SqlLoginsAbsent
```

`-SqlLoginsAbsent` فقط وقتی داده شود که login یا user SQL این SIDها هرگز ساخته نشده یا با معکوس P2 حذف شده باشد. پیش از P2 این شرط برقرار است.

### ۱۹.۹ اعتبارسنجی واقعاً اجراشده (بدون elevation و بدون تغییر)

```powershell
# اجرا شد — cwd: ریشهٔ مخزن
(Get-Command New-LocalUser).Parameters['Description']   # MaxLength 48
(Get-Command New-SelfSignedCertificate).Parameters.Keys # شامل Extension و KeyUsage
# اجرا شد — scratchpad، در powershell.exe جدا
p1p3-offline-check.ps1 -Repo <repo>
```

نتیجه:

- parser PowerShell 5.1 برای هر دو فایل صفر خطا داد. هر دو UTF-8 BOM و CRLF دارند.
- LSA helper کامپایل شد. خواندن حق‌ها بدون elevation `Access is denied` داد، که انتظاری است. dry run elevated همین خواندن را پیش از هر تغییر انجام می‌دهد.
- secret درون‌حافظه ۴۴ نویسه و read-only بود. ADSI عضویت مستقیم را خواند.
- extensionهای BasicConstraints (`CA=False`، critical) و EKU فقط در حافظه ساخته شدند.
- guardهای منفی همه رد کردند: نبود elevation، ترکیب نامعتبر `-VerifyOnly -Execute`، `-RestartSqlService` بدون `-Execute`، مرجع نامعتبر و thumbprint نامعتبر.
- پس از آزمون: هیچ حساب BAZDID وجود ندارد و `Certificate` همچنان خالی است.

اجرای واقعی `New-SelfSignedCertificate`، LSA write، `New-LocalUser` و ری‌استارت آزموده نشده‌اند، چون طبق دستور ممنوع بودند. نخستین شاهد آن‌ها dry run و اجرای مدیر است.

### ۱۹.۱۰ hash نسخه‌های جدید

| فایل | SHA-256 |
| --- | --- |
| `deployment/development/Set-BazdidSqlDevCertificate.review.ps1` | `07383213ad35bfdac9a889f06639cbbd19f9c7440ed76440cc747ceaa71d49ec` |
| `deployment/development/New-BazdidDevIdentities.review.ps1` | `351227f2ca148bceea1354cbf2a7d153ef7a2a168bd8085bfc217248df3e838a` |

`.gitattributes` برای این فایل‌ها CRLF را pin می‌کند، پس hash checkout برابر می‌ماند. **2F همچنان پذیرفته نشده است و پیشرفت 20% است.** 2G شروع نشده است.

<a id="p3-verification-20261107"></a>

## ۲۰. راستی‌آزمایی اتصال پس از نصب certificate در P3 (2026-11-07)

شاهد ماشین‌خوان: [P3_TLS_VERIFICATION.json](../checkpoint2f/P3_TLS_VERIFICATION.json). نام میزبان و login در مستندات با `<HOST>` و `<owner>` جایگزین شده‌اند.

### ۲۰.۱ دو ادعای جدا

| ادعا | نتیجه | شاهد |
| --- | --- | --- |
| **نصب certificate (P3)** | **موفق** | گزارش مالک (elevated): `-VerifyOnly` برابر PASS، `LoadedPerErrorLog : True`، `LoadFailureInErrorLog : False`، `Problems` خالی. تلاش دوم نصب، درست، رد شد. عامل نصب را اجرا یا تکرار نکرد. |
| **اتصال provider برنامه با مقصد pin‌شده** `lpc:.\SQLSERVER2019` | **ناموفق** | `-2146893022` (`0x80090322`، `SEC_E_WRONG_PRINCIPAL`)، Class 20، سه اجرای پیاپی یکسان |

خطای قبلی `SEC_E_UNTRUSTED_ROOT` دیگر رخ نمی‌دهد، پس **اعتماد زنجیرهٔ certificate حل شده است**. اکنون مانع فقط **نام‌سنجی certificate** است.

### ۲۰.۲ وضعیت فقط‌خواندنی که عامل مستقلاً مشاهده کرد

- `SuperSocketNetLib\Certificate` برابر `9f8a13b7…e84f` است و `ForceEncryption=0` بدون تغییر مانده است.
- سرویس `MSSQL$SQLSERVER2019` در وضعیت `Running` است.
- certificate در `LocalMachine\My` با کلید خصوصی و در `LocalMachine\Root` بدون کلید خصوصی قرار دارد:
  - `CN=<HOST>`؛ SAN: `<HOST>` و `localhost`؛
  - EKU فقط Server Authentication؛ انقضا `2027-11-07`.
- hash هر دو script برابر نسخهٔ بخش ۱۹.۱۰ است. هیچ حساب `BAZDID*` محلی وجود ندارد.

### ۲۰.۳ اجرای probe

همان probe فقط‌خواندنی ignored بخش ۷ اجرا شد: `System.Data.SqlClient 4.8.6`، assembly `4.6.1.6`، runtime 2.1.30. سیاست ثابت بود: `Integrated Security=true`، `Encrypt=true`، `TrustServerCertificate=false`، `Pooling=false`.

برای تشخیص علت، سه حالت مقصد ثابت به probe ignored افزوده شد: `lpcname`، `lpclocalhost` و `tcplocalhost`. در این حالت‌ها فقط نام میزبان تغییر می‌کند و هیچ گزینهٔ امنیتی تغییر نکرد. حالت‌های `tcp` و `tcpname` از قبل وجود داشتند.

| Data Source | نتیجه | `net_transport` | `encrypt_option` |
| --- | --- | --- | --- |
| `lpc:.\SQLSERVER2019` (**pin برنامه**) | شکست `SEC_E_WRONG_PRINCIPAL` | — | — |
| `tcp:127.0.0.1,<port>` | شکست `SEC_E_WRONG_PRINCIPAL` | — | — |
| `tcp:<HOST>,<port>` | **موفق** | `TCP` | `TRUE` |
| `tcp:localhost,<port>` | **موفق** | `TCP` | `TRUE` |
| `lpc:<HOST>\SQLSERVER2019` | **موفق** | `Shared memory` | `TRUE` |
| `lpc:localhost\SQLSERVER2019` | **موفق** | `Shared memory` | `TRUE` |

اتصال TCP فقط روی loopback و با port پویای موجود انجام شد. firewall، پروتکل و port تغییر نکردند.

### ۲۰.۴ نتیجه‌گیری فنی

- **handshake TLS و اعتبارسنجی certificate** هم روی TCP و هم روی Shared Memory موفق‌اند، به شرطی که نام مقصد در CN/SAN باشد.
- **TLS شبکه:** فقط روی loopback TCP اثبات شد (`tcp:<HOST>` و `tcp:localhost`). این ادعا به Shared Memory تکیه ندارد. TLS از ماشین دیگر یا روی شبکهٔ واقعی آزموده نشده و در دامنه نیست.
- **native SNI:** کار می‌کند. `sni.dll` `4.6.25512.1` از بستهٔ `runtime.win-x64.runtime.native.System.Data.SqlClient.sni 4.4.0` بارگذاری شد. پیشوند `lpc:` فقط در native SNI پشتیبانی می‌شود و اتصال Shared Memory موفق شد.
- **علت دقیق باقی‌مانده:** نامی که native SNI برای مقصد `.` (و برای `127.0.0.1`) در اعتبارسنجی به کار می‌برد، با هیچ‌یک از `<HOST>` و `localhost` برابر نیست. پس `BuildLocalConnectionString()`، که مقصد را دقیقاً `lpc:.\SQLSERVER2019` pin می‌کند ([SqlRuntimeOptions.cs](../../src/Bazdid.Api/Infrastructure/Sql/SqlRuntimeOptions.cs))، با certificate فعلی وصل نمی‌شود. این یک ناسازگاری نام است، نه نقص certificate.

### ۲۰.۵ راستی‌آزمایی فقط‌خواندنی سرور

این خوانش از مسیر `lpc:localhost\SQLSERVER2019` با اعتبارسنجی کامل certificate و با هویت مالک انجام شد. فقط `SELECT` روی DMV، `SERVERPROPERTY` و `sys.*` و `COUNT_BIG` اجرا شد.

| مورد | مقدار |
| --- | --- |
| instance / نسخه | `SQLSERVER2019` / `15.0.2000.5`، Standard Edition (64-bit) |
| پایگاه | `BAZDID_Development`، compatibility `150`، `SQL_Latin1_General_CP1_CI_AS`، `ONLINE` |
| هویت اتصال | `<HOST>\<owner>`، `auth_scheme=NTLM`، `IsSysadmin=1` (هویت مالک است، نه Writer؛ پذیرش effective permission نیست) |
| جدول‌ها | `dbo.BAZDIDAuditLogs`، `dbo.BAZDIDCustomerLinks`، `dbo.BAZDIDRequestContexts`؛ هر سه با ۰ ردیف |
| امضای schema | ۳۹ ستون BAZDID، `CHECKSUM_AGG=1193879634` |
| principalها | هیچ login یا user BAZDID؛ صفر principal غیرثابت در پایگاه؛ صفر linked server |

این نخستین شاهد خوانده‌شدهٔ نسخه، collation و شمار ردیف‌هاست. با آن، مورد اول بخش ۱۷ بسته می‌شود.

### ۲۰.۶ گزینه‌های رفع، بدون تضعیف امنیت (تصمیم باز `D-P3-NAME`)

| گزینه | ارزیابی |
| --- | --- |
| **الف (پیشنهادی):** تغییر pin در `SqlRuntimeOptions` و آزمون‌های مرتبط به `lpc:localhost\SQLSERVER2019` | همچنان Shared Memory است و guard `net_transport='Shared memory'` بدون تغییر می‌ماند. به نام ماشین وابسته نیست و `localhost` در SAN هست. تغییر کد کوچکی است و مجوز جدا می‌خواهد. |
| ب: pin به `lpc:<HOST>\SQLSERVER2019` | کار می‌کند ولی نام ماشین را در پیکربندی hardcode می‌کند. |
| رد: افزودن `.` به SAN | `.` نام DNS معتبر نیست و نیاز به صدور دوبارهٔ certificate دارد، که طبق دستور ممنوع است. |
| رد: `TrustServerCertificate=true` یا `Encrypt=false` | دور زدن اعتبارسنجی است و ممنوع است. |
| رد: `HostNameInCertificate` | در `System.Data.SqlClient 4.8.6` وجود ندارد. |

از این به بعد `localhost` در SAN لازم است، چون گزینهٔ الف به آن وابسته است. پیشنهاد حذف آن در چرخش بعدی certificate (بخش ۱۹.۴) لغو می‌شود.

### ۲۰.۷ آنچه تغییر نکرد

- schema، داده، login، user، نقش، مجوز و حساب Windows؛
- certificate، registry و سرویس (ری‌استارت نشد)؛
- کد برنامه، آزمون‌ها، package و lockfile؛
- gate: `ConnectedAcceptanceVerified => false` و `SqlRuntime.Enabled=false`.

تنها تغییر کد، افزودن سه حالت مقصد به probe ignored در `.sync-tmp` است، که منتشر نمی‌شود.

### ۲۰.۸ فرمان‌های واقعاً اجراشده

```powershell
# اجرا شد — cwd: ریشهٔ مخزن؛ فقط‌خواندنی
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL15.SQLSERVER2019\MSSQLServer\SuperSocketNetLib'
Get-ChildItem Cert:\LocalMachine\My, Cert:\LocalMachine\Root | Where-Object Thumbprint -eq '9F8A13B7B6A2B86A1C42211ABF313F89D602E84F'
Get-FileHash .\deployment\development\*.review.ps1 -Algorithm SHA256
Get-LocalUser | Where-Object Name -like 'BAZDID*'

# اجرا شد — cwd: .sync-tmp\l1-legacy-spike-20261103\p3_probe (ignored)؛ SDK 2.1.818
dotnet restore Probe.csproj --locked-mode
dotnet build Probe.csproj -c Release --no-restore          # 0 warning، 0 error
dotnet bin/Release/netcoreapp2.1/win-x64/Probe.dll lpc meta
dotnet bin/Release/netcoreapp2.1/win-x64/Probe.dll tcp <port>
dotnet bin/Release/netcoreapp2.1/win-x64/Probe.dll tcpname <port>
dotnet bin/Release/netcoreapp2.1/win-x64/Probe.dll tcplocalhost <port>
dotnet bin/Release/netcoreapp2.1/win-x64/Probe.dll lpcname
dotnet bin/Release/netcoreapp2.1/win-x64/Probe.dll lpclocalhost meta
```

regression برنامه اجرا نشد، چون کد، package و آزمون تغییر نکردند.

### ۲۰.۹ گام دقیق بعدی

**P1** به TLS وابسته نیست و اکنون اجرایی است. کانال امن هم با certificate فعلی اثبات شد. مدیر محلی در PowerShell با Run as Administrator و cwd ریشهٔ مخزن اجرا می‌کند:

```powershell
# پیشنهادی؛ عامل اجرا نکرده است
Get-FileHash .\deployment\development\New-BazdidDevIdentities.review.ps1 -Algorithm SHA256
# انتظار: 351227F2CA148BCEEA1354CBF2A7D153EF7A2A168BD8085BFC217248DF3E838A
.\deployment\development\New-BazdidDevIdentities.review.ps1 -ExpectedMachine $env:COMPUTERNAME -ApprovalReference OWNER-2026-11-07
.\deployment\development\New-BazdidDevIdentities.review.ps1 -ExpectedMachine $env:COMPUTERNAME -ApprovalReference OWNER-2026-11-07 -Execute
.\deployment\development\New-BazdidDevIdentities.review.ps1 -ExpectedMachine $env:COMPUTERNAME -ApprovalReference OWNER-2026-11-07 -VerifyOnly
```

انتظارها همان‌اند که در بخش ۱۹.۷ آمده: `Pass : True`، «راستی‌آزمایی P1: PASS» و اعلام دو SID.

**هم‌زمان، پیش از P2 و P4**، مالک دربارهٔ `D-P3-NAME` تصمیم بگیرد. پیشنهاد گزینهٔ الف است. پس از تصویب، عامل pin و آزمون‌ها را تغییر می‌دهد، regression را اجرا می‌کند و probe را با مقصد جدید تکرار می‌کند. DBA در P2 می‌تواند با `localhost\SQLSERVER2019` و `Encrypt=true` وصل شود.

### ۲۰.۱۰ پیشرفت

**قبلی 20% + سهم 0 = 20%.** P3 از نظر certificate کامل است، اما پذیرش 2F به P1، P2، P4، P5 و رفع ناسازگاری نام وابسته است. هدف مشروط پس از پذیرش کامل 2F برابر 22% است. P2، P4، P5 و 2G شروع نشده‌اند.
