# Checkpoint 2G — migrationهای شماره‌دار، rollback و پذیرش روی پایگاه یک‌بارمصرف

تاریخ: `2026-11-07`. **نتیجه: 2G پذیرفته شد؛ Checkpoint 2 کامل است؛ پیشرفت 22% → 24%.** شاهد ماشین‌خوان: [MIGRATION_ACCEPTANCE.json](../checkpoint2g/MIGRATION_ACCEPTANCE.json)؛ اجرای اول ناقص: [MIGRATION_ACCEPTANCE_RUN1_INCOMPLETE.json](../checkpoint2g/MIGRATION_ACCEPTANCE_RUN1_INCOMPLETE.json).

## ۱. مسئله و مجوز

PLAN برای 2G این‌ها را می‌خواهد:

- scriptهای شماره‌دار forward/revert فقط برای اشیای BAZDID، با guard مقصد و پیش‌شرط نسخه؛
- اثبات ساخت از صفر، اجرای تکراری، rollback و بازاعمال روی پایگاه تست، بدون تغییر جدول مبدأ یا Production.

مالک تصمیم `D-2G-TARGET` را تصویب کرد: پایگاه یک‌بارمصرف `BAZDID_MigrationTest`. این مجوز فقط ساخت، آزمون و حذف همین پایگاه با نام دقیق روی instance محلی تأییدشده را پوشش می‌دهد. وضعیت اولیه: HEAD `3fbad78` برابر remote؛ 2F پذیرفته‌شده؛ تنها پایگاه کاربری `BAZDID_Development`.

## ۲. فایل‌های ساخته‌شده

| فایل | مسئولیت |
| --- | --- |
| [0001_baseline.forward.sql](../../database/migrations/0001_baseline.forward.sql) | جدول تاریخچهٔ `BAZDIDSchemaMigrations` و baseline سه جدول. DDL جدول‌ها عیناً خطوط ۴۱ تا ۱۲۳ `initial_tables.review.sql` است و با script ساخته شده تا خطای رونویسی رخ ندهد. |
| [0001_baseline.revert.sql](../../database/migrations/0001_baseline.revert.sql) | حذف سه جدول و ردیف تاریخچهٔ همان migration. فقط روی `BAZDID_MigrationTest` اجرا می‌شود. |
| [Invoke-BazdidMigration.ps1](../../database/tools/Invoke-BazdidMigration.ps1) | runner با حالت‌های `Preflight`، `Accept` و `Cleanup` |
| `docs/checkpoint2g/*.json` | شاهد واقعی دو اجرا |

## ۳. طراحی

**جدول تاریخچه `BAZDIDSchemaMigrations`:** ستون‌های `MigrationId` (PK)، `Checksum` (SHA-256 فایل forward)، `AppliedAtUtc`، `AppliedBy` (`ORIGINAL_LOGIN()`)، `ApprovalReference` و `Mode` (`Created`/`Adopted`)، به‌علاوهٔ CHECK روی قالب checksum و Mode.

**رفتار forward:**

| حالت پایگاه | نتیجه |
| --- | --- |
| ردیف `0001_baseline` با همان checksum وجود دارد | `AlreadyApplied` (no-op) |
| checksum متفاوت | خطای `51101 BAZDID_MIGRATION_CHECKSUM_MISMATCH` |
| هیچ‌کدام از سه جدول وجود ندارد | ساخت سه جدول، `Created` |
| هر سه جدول با امضای دقیق 2C (۳۹ ستون، `1193879634`) | فقط ثبت تاریخچه، `Adopted`. این مسیر آیندهٔ ثبت baseline روی `BAZDID_Development` است و DDL ندارد. |
| حالت جزئی یا امضای نابرابر | خطای `51103`/`51102` |

**رفتار revert:**

- اگر ثبت نشده باشد: `NotApplied`.
- اگر migration بعدی ثبت شده باشد، داده وجود داشته باشد (با قفل `TABLOCKX`)، یا وابستگی بیرونی (FK یا ارجاع SQL از شیء دیگر) باشد: خطا. این یعنی **حفظ داده**.
- در غیر این صورت DROP به ترتیب وابستگی و حذف ردیف تاریخچه، همه در یک transaction.

**guardها:**

- هر دو script با `@AllowDdl=0` و مرجع خالی بسته‌اند. runner فقط خطوط `DECLARE` دقیق را در حافظه مقدار می‌دهد (هر خط باید دقیقاً یک بار وجود داشته باشد).
- forward فقط `BAZDID_MigrationTest`/`BAZDID_Development` را می‌پذیرد، با شرط‌های instance `SQLSERVER2019`، نسخهٔ ۱۵، sysadmin، Shared memory، compatibility ۱۵۰ و collation دقیق.
- revert فقط `BAZDID_MigrationTest` را می‌پذیرد.

**runner:**

- hash دو فایل pin شده است.
- مقصد تغییر، ثابت `BAZDID_MigrationTest` است و ورودی دلخواه نمی‌پذیرد.
- اتصال: `lpc:localhost\SQLSERVER2019` با `Encrypt=true` و `TrustServerCertificate=false`.
- preflight این‌ها را بررسی می‌کند: instance، نسخه، ماشین، Cluster/HADR، transport، TLS، sysadmin، نبود linked server، و اینکه پایگاه کاربری جز `{BAZDID_Development, BAZDID_MigrationTest}` وجود نداشته باشد.

**اثبات یک‌بارمصرف‌بودن**، که پیش از هر استفادهٔ مجدد یا حذف لازم است:

- extended property `BAZDID.Disposable` با مقدار دقیق؛
- مالک پایگاه برابر login جاری؛
- وضعیت ONLINE؛
- فقط چهار جدول BAZDID و هیچ شیء دیگری؛
- بدون user یا نقش؛
- بدون ردیف در سه جدول.

اگر پایگاه هم‌نام وجود داشته باشد ولی این اثبات را نداشته باشد، runner متوقف می‌شود و چیزی حذف نمی‌کند.

**مقایسهٔ schema:** امضای ۸۱ ویژگی (ستون‌ها شامل computed و collation، defaultها، CHECKها، indexها با ستون، ترتیب و فیلتر، و FKها) در پایگاه آزمون و در `BAZDID_Development` (فقط‌خواندنی) با SHA-256 مقایسه می‌شود.

**`BAZDID_Development`:** فقط خوانده می‌شود. snapshot قبل و بعد شامل ردیف‌ها، جدول‌ها، principalها، تعداد و checksum مجوزها، `modify_date` و امضای schema است.

## ۴. اجرای واقعی و خطاها

```powershell
# اجرا شد — cwd: ریشهٔ مخزن، PowerShell 5.1، هویت مالک (sysadmin)، بدون elevation ویندوز
.\database\tools\Invoke-BazdidMigration.ps1 -Action Preflight
.\database\tools\Invoke-BazdidMigration.ps1 -Action Accept -ApproveDisposableDatabase -ApprovalReference OWNER-2026-11-07-D-2G-TARGET -EvidencePath .\docs\checkpoint2g\MIGRATION_ACCEPTANCE.json
```

خطاهای واقعی به ترتیب رخ‌داد:

1. **compile:** هر دو migration با `SET NOEXEC ON` روی master بدون اجرا compile شدند.
2. **preflight اول:** `Clustered` واژهٔ رزرو T-SQL است و alias آن به `IsClustered` تغییر کرد.
3. **preflight دوم:** تعارض collation کاتالوگ در الحاق رشته پیش آمد. امضای schema به پنج query بدون UNION یا الحاق تبدیل شد و الحاق در PowerShell انجام می‌شود. در تاریخچه، `Mode COLLATE Latin1_General_100_BIN2` اضافه شد.
4. **Accept اول:** گام‌های ۰۱ تا ۰۷ PASS شدند. revert با `BAZDID_REVERT_EXTERNAL_DEPENDENCY` رد شد، چون `sys.sql_expression_dependencies` وابستگی‌های درونی خود جدول‌ها (computed column و CHECK) را هم برمی‌گرداند. guard درست و ایمن شکست خورد، `finally` پایگاه را پس از اثبات یک‌بارمصرف‌بودن حذف کرد، و شاهد `INCOMPLETE` حفظ شد.
5. **اصلاح:** بررسی وابستگی فقط اشیایی را مانع می‌داند که نه خود سه جدول باشند و نه زیرمجموعهٔ آن‌ها. hash فایل revert دوباره pin شد.
6. **Accept دوم:** هر ۲۲ گام PASS شدند.

| گام | نتیجه |
| --- | --- |
| ۰۱ ساخت پایگاه با نشانه | PASS |
| ۰۲ forward از صفر | `Created` |
| ۰۳ برابری schema با `BAZDID_Development` | hash `d4c57bc2…902b` برابر |
| ۰۴ تاریخچه | `0001_baseline:Created:2568AA10…D667` |
| ۰۵ تکرار forward | `AlreadyApplied` |
| ۰۶ checksum نادرست | `ChecksumMismatch` (رد شد) |
| ۰۷ schema پس از تکرارها | بدون تغییر |
| ۰۸ revert | `Reverted` |
| ۰۹ و ۱۰ وضعیت rollback | فقط `BAZDIDSchemaMigrations` با تاریخچهٔ خالی |
| ۱۱ تکرار revert | `NotApplied` |
| ۱۲ تا ۱۴ بازاعمال | `Created`؛ schema و تاریخچه برابر |
| ۱۵ و ۱۶ revert با داده | `DataPresent` (رد شد)؛ داده و schema سالم |
| ۱۷ و ۱۸ adopt schema موجود | `Adopted`؛ تاریخچه درست |
| ۱۹ schema نهایی | برابر مرجع |
| ۲۰ و ۲۱ حذف پایگاه یک‌بارمصرف | `Dropped`؛ پایگاه وجود ندارد |
| ۲۲ `BAZDID_Development` | snapshot قبل و بعد کاملاً برابر |

ردیف ساختگی گام ۱۵ (`TEST-2G`) فقط در پایگاه یک‌بارمصرف درج و حذف شد.

## ۵. regression پس از 2G

```powershell
# اجرا شد
dotnet build Bazdid.sln --configuration Release --no-restore      # 0 warning، 0 error
dotnet test Bazdid.sln --configuration Release --no-build --no-restore
.\deployment\development\Invoke-BazdidDevSqlPrincipals.review.ps1 -ExpectedMachine $env:COMPUTERNAME -ApprovalReference OWNER-2026-11-07 -VerifyOnly
.\database\tools\Invoke-BazdidDevelopmentDatabase.ps1 -Action Verify
.\deployment\development\Start-BazdidConnectedRun.ps1
```

- ۱۲۰ از ۱۲۰ unit؛ در integration، ۵۰ موفق، ۰ شکست و ۱۳ Skipped (متصل‌های انتخاب‌نشده).
- P2: ۴۰ از ۴۰ PASS. ابزار 2C در حالت Verify: `Passed`.
- اجرای متصل `1003a430e25ce496` با هویت Writer: ۱۳ از ۱۳ Passed، verifier برابر PASS، cleanup `1/2/5` و صفر ردیف باقی‌مانده.

## ۶. hashها

| فایل | SHA-256 |
| --- | --- |
| `database/migrations/0001_baseline.forward.sql` | `2568AA10017953AA0FA45BFBF15AF2F590B24E1B12E50EDCFCFCED47A16BD667` |
| `database/migrations/0001_baseline.revert.sql` | `E97734D7170BFB1B6E960BC188198854285147BAD7C9429563D773865F6DB5FC` |
| `database/tools/Invoke-BazdidMigration.ps1` | `9952014660873B9EE339B004647DF88E7AB7087465FB388591BAC29844D94CEF` |

`.gitattributes` برای `database/**` مقدار `eol=lf` را pin می‌کند، پس hash checkout برابر می‌ماند.

## ۷. امنیت و محدودیت‌ها

- هیچ تغییری روی `BAZDID_Development`، پایگاه دیگر یا پیکربندی SQL Server انجام نشد. guard اتصال برنامه، gate زمان اجرا و TLS دست‌نخورده ماندند.
- runner با login مالک اجرا می‌شود. این ابزار provisioning است، نه هویت برنامه.
- **ثبت baseline روی `BAZDID_Development`:** مسیر `Adopted` آزموده شده، اما اجرای آن روی `BAZDID_Development` جدول تازهٔ `BAZDIDSchemaMigrations` می‌سازد و به مجوز جدا نیاز دارد. revert هرگز روی آن اجرا نمی‌شود.
- **migrationهای بعدی** (Info، OTP/Session و …) باید `0002_*` به بعد باشند، با همین الگوی checksum، guard و revert محافظ داده.
- ریسک‌های legacy runtime (L1-R) و منع استقرار Production باقی‌اند.

## ۸. پیشرفت

**قبلی 22% + سهم 2G (2) = 24%.** Checkpoint 2 کامل است (۱۲ از ۱۲ واحد). گام بعد **Checkpoint 3 — OTP و نشست** با وزن 12% است.
