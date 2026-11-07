# ادامهٔ کار پس از قطع نشست عامل

**آخرین نقطهٔ ادامه در `2026-11-07`: Checkpoint 2G پذیرفته شد؛ Checkpoint 2 کامل است؛ پیشرفت 24%** ([walkthrough 2G](implementation/CHECKPOINT-02G-MIGRATIONS_FA.md)، [شاهد](checkpoint2g/MIGRATION_ACCEPTANCE.json)).

- migrationها در `database/migrations/` قرار دارند و runner در `database/tools/Invoke-BazdidMigration.ps1`. پایگاه یک‌بارمصرف `BAZDID_MigrationTest` حذف شده است. اجرای دوباره فقط با `-Action Accept` و نشانهٔ یک‌بارمصرف انجام می‌شود.
- revert هرگز روی `BAZDID_Development` اجرا نمی‌شود. ثبت baseline (`Adopted`) روی آن مجوز جدا لازم دارد.
- گام بعد: Checkpoint 3 (OTP و نشست)، با قراردادها، اینترفیس‌ها، سرویس‌ها و آزمون‌ها در `netcoreapp2.1`/C# 7.3.

**نقطهٔ قبلی، شب `2026-11-07`: Checkpoint 2F پذیرفته شد؛ پیشرفت 22%** ([بخش ۲۲](implementation/CHECKPOINT-02F-CONNECTED-ACCEPTANCE_FA.md#acceptance-20261107)، [شاهد](checkpoint2f/CONNECTED_ACCEPTANCE_RESULT.json)).

- P1 تا P5 کامل‌اند. task `BAZDID-Dev-ConnectedSqlTests` آماده است. هر اجرای تازهٔ متصل فقط با `deployment/development/Start-BazdidConnectedRun.ps1` و بدون elevation انجام می‌شود (publish، اجرا با هویت Writer، verifier و cleanup).
- حساب‌ها، loginها، certificate و task را بازسازی نکنید. رمز Writer را فقط با `-Rotate` (مدیر) بچرخانید.
- گام بعد: آماده‌سازی 2G طبق PLAN، با scriptهای forward/rollback بازبینی‌شده. اجرای DDL روی پایگاه موجود به preflight مقصد دقیق و مجوز دامنه نیاز دارد.

**نقطهٔ قبلی، عصر `2026-11-07`: P2 انجام شد؛ P4/P5 پیاده شده و منتظر provisioning مدیر است** ([بخش ۲۱](implementation/CHECKPOINT-02F-CONNECTED-ACCEPTANCE_FA.md#execution-20261107)، [شاهد](checkpoint2f/P2_P4_EXECUTION.json)).

- P1 `-VerifyOnly` توسط مالک PASS شد. اجرای اول P4 به‌خاطر تداخل نام `$action` شکست خورد و در [بخش ۲۱.۸.۱](implementation/CHECKPOINT-02F-CONNECTED-ACCEPTANCE_FA.md#execution-20261107) اصلاح شد (hash `3EB982D0…ADF1`). اجرای دوم امن است. خروجی publish از پیش در `bin` آماده است.
- P2 را دوباره اجرا نکنید. برای کنترل، `Invoke-BazdidDevSqlPrincipals.review.ps1 -VerifyOnly` کافی است.
- ابتدا وجود task `BAZDID-Dev-ConnectedSqlTests` را بررسی کنید (`Get-ScheduledTask`). اگر وجود دارد، `deployment/development/Start-BazdidConnectedRun.ps1` را اجرا کنید. اگر وجود ندارد، دستور بخش ۲۱.۸ برای مالک است.
- پس از PASS کامل: 2F پذیرفته، پیشرفت 22% و آماده‌سازی 2G. هرگز رمز Writer را نمایش ندهید و gate برنامه را باز نکنید.

**نقطهٔ قبلی، صبح `2026-11-07`: راستی‌آزمایی P3 انجام شد** ([بخش ۲۰](implementation/CHECKPOINT-02F-CONNECTED-ACCEPTANCE_FA.md#p3-verification-20261107)، [شاهد](checkpoint2f/P3_TLS_VERIFICATION.json)).

- certificate با thumbprint `9F8A13B7…E84F` نصب و اعتماد شده است. آن را دوباره نصب یا تغییر ندهید.
- مقصد pin‌شدهٔ برنامه، `lpc:.\SQLSERVER2019`، با `SEC_E_WRONG_PRINCIPAL` رد می‌شود. `lpc:localhost\SQLSERVER2019` و `lpc:<HOST>\SQLSERVER2019` با اعتبارسنجی کامل موفق‌اند.
- گام بعد: مدیر P1 را اجرا می‌کند، و مالک دربارهٔ `D-P3-NAME` تصمیم می‌گیرد (پیشنهاد: pin به `lpc:localhost\SQLSERVER2019`). تا تصویب، کد و gate را تغییر ندهید. **20%.**

سابقهٔ پیشین:

**آخرین نقطهٔ ادامه در `2026-11-06`: P1–P5 در P3 متوقف است.** [گزارش](implementation/CHECKPOINT-02F-CONNECTED-ACCEPTANCE_FA.md) و [شاهد](checkpoint2f/CONNECTED_PREFLIGHT.json) را بخوانید.

- اتصال امن با `SEC_E_UNTRUSTED_ROOT` رد شد.
- نشست عامل elevated نیست.
- پیش از هر کار، اجرای script P3 توسط مدیر را راستی‌آزمایی کنید: مقدار `SuperSocketNetLib\Certificate` غیرخالی باشد و certificate اعتماد شود. سپس probe `.sync-tmp/l1-legacy-spike-20261103/p3_probe` را با آرگومان‌های `lpc meta` دوباره اجرا کنید.
- `Encrypt` یا `TrustServerCertificate` را تضعیف نکنید. حساب یا رمز نسازید، مگر از طریق script بازبینی‌شده و با token مدیر.
- gate را پیش از تأیید P1 تا P3 تغییر ندهید. **20%.**
- از `2026-11-07` scriptهای P1/P3 بازنگری شده‌اند ([بخش ۱۹](implementation/CHECKPOINT-02F-CONNECTED-ACCEPTANCE_FA.md#revision-20261107)):
  - P3 با hash `07383213…49ec` و P1 با hash `351227f2…838a`؛
  - شاهد اجرا از مدیر: خروجی `-VerifyOnly` هر دو با PASS، به‌همراه SIDها؛
  - provisioning رمز حساب‌ها فقط با چرخش در P4 انجام می‌شود، هرگز با نمایش رمز.

**سابقه: L1-A روی canonical اعمال و push شد.** ابتدا [walkthrough L1-A](implementation/CHECKPOINT-02F-L1A-CANONICAL-DEPENDENCIES_FA.md) و [L1A_VALIDATION.json](checkpoint2f/L1A_VALIDATION.json) را بخوانید.

- canonical اکنون گراف ریز با `System.Data.SqlClient 4.8.6` دارد. آن را دوباره اعمال یا پژوهش نکنید و نسخه‌ها را بدون دلیل سازگاری مستند تغییر ندهید.
- gate و `SqlRuntime.Enabled` بسته‌اند.
- گام بعدی فقط با تصویب صریح انجام شود: L1-R، سپس P1، P2، P3 و P4/P5. 2G پیش از پذیرش کامل 2F ممنوع است. **20%.**

**سابقهٔ `2026-11-03`: 2F-L1 انجام شد.** ابتدا [walkthrough L1](implementation/CHECKPOINT-02F-LEGACY-SQLCLIENT-FEASIBILITY_FA.md) و [LEGACY_SECURITY_PINS.json](checkpoint2f/LEGACY_SECURITY_PINS.json) را بخوانید. `netcoreapp2.1` قید الزامی کارفرما است و مهاجرت شروع نشود. آزمایش‌ها در `.sync-tmp/l1-legacy-spike-20261103/` و `.sync-tmp/l1-canonical-granular/` هستند؛ ignored‌اند و منتشر نمی‌شوند. آن‌ها را دوباره نسازید، مگر برای بازآزمایی. canonical، package/lockfile، gate و `launchSettings.json` شخصی بدون تغییرند. تصمیم‌های بعدی L1-A، L1-R و P1 تا P5 هستند؛ پیش از تصویب توقف کنید. مالک `.git` حساب sandbox است؛ git را با `-c safe.directory=C:/Projects/vehicle-inspection-backend` اجرا کنید و تنظیم global را تغییر ندهید. **20%.**

سابقه — نقطهٔ قبلی: P0 با مجوز `700bf7eb-76b8-4b84-ad87-1096b3eb12dd` تکمیل شد؛ [CHECKPOINT-02F-P0-MIGRATION-FEASIBILITY_FA.md](implementation/CHECKPOINT-02F-P0-MIGRATION-FEASIBILITY_FA.md) و [ماتریس فایل‌ها](checkpoint2f/P0_MIGRATION_FILE_PLAN_FA.md) را ابتدا بخوانید. canonical در `netcoreapp2.1` و gate بسته ماند؛ نمونهٔ ignored با SDK10.0.403/Runtime10.0.14، MDS6.1.7 و Pkcs10.0.14، build بدون warning/error و۱۴ تست/سه smoke موفق دارد. regression اصلی تازه۱۰۹unit+۵۰offline موفق/۸SQL Skipped است. ۶۴ فایل محافظت‌شده از جمله launchSettings شخصی بدون تغییرند. هیچ SQL metadata/connect، native load، P1/P2، TLS/ACL/task یا IIS در P0 اجرا نشد. شواهد SQL پایین این صفحه تاریخی‌اند. **20+0=20%**؛ ابتدا تصویب صریح تغییر الزام2.1 برای port آفلاین لازم است؛ حساب/permission/TLS/activation/استقرار مستقل‌اند. پیش از تصویب عملیات بعدی توقف؛2G شروع نشود.

هدف این فایل جلوگیری از تکرار کار و عبور ناخواسته از checkpoint مجاز است. در `2026-11-03`، مجوز `ea650fd0-47e2-4d02-bf9b-0fb87f03a254` فقط 2F را پوشش داد. قراردادها، سه repository، transaction و DI با gate بسته پیاده شدند؛ O24/O26 مانع پذیرش متصل‌اند. ۱۰۹ unit و ۵۰ integration آفلاین موفق، صفر شکست و ۸ SQL Skipped؛ build صفر warning/error. verification خواندنی schema/ردیف قبل و بعد برابر و سه جدول خالی‌اند. DDL، DML repository، grant و اتصال runtime انجام نشدند. **پیشرفت 20%؛ توقف در 2F ناقص، بدون شروع 2G.** مبنای شروع 2F برابر `228d3769fc3471a2e3d597b9272c9629fa9ebe28` بود؛ [راهنمای 2F](implementation/CHECKPOINT-02F-SQL-REPOSITORIES_FA.md) و هفت شاهد `checkpoint2f/` مرجع تازه‌اند. پایگاه موجود را خودکار ایجاد، حذف، reset یا بازسازی نکنید.

پیوست سیاست مستندات `3d0d6a79-4b95-4875-88b4-571e799beb75` سهم صفر داشت؛ تلاش قدیمی 2D به‌علت نبود پایگاه متوقف شد. سپس 2C مستقل اجرا شد و در درخواست جدید، پیش‌نیاز آن دوباره تأیید و 2D تکمیل شد؛ ثبت توقف قدیمی وضعیت جاری نیست. فایل untracked کاربر `src/Bazdid.Api/Properties/launchSettings.json` از قبل وجود داشت، تغییر نکرد و commit نشد.

## ترتیب بازیابی زمینه

۱. `AGENTS.md`، `PLAN.md`، README، [شناسنامهٔ منابع](SOURCE_REFERENCES_FA.md)، [تصمیم‌های باز](OPEN_DECISIONS_FA.md)، [ممیزی DuberFront](DUBERFRONT_CODE_AUDIT_FA.md) و [نگاشت مبتنی بر شاهد](BROKERAGE_DATA_MAPPING_FA.md) را بخوانید. اعتبارسنجی Phase 0 و اجرای Checkpoint 1 اسناد تاریخی همان مراحل‌اند.
۲. cwd را `C:\Projects\vehicle-inspection-backend` احراز کنید. `git status --short`، branch و `git log -1` را بخوانید. تغییر کاربر را از کار قبلی جدا کنید و هیچ reset/clean/stash خودکار انجام ندهید.
۳. آخرین پیام صریح کاربر را بررسی کنید. مجوز 2E فقط طراحی آینده بود؛ بررسی/مستندسازی انجام و در همان مرحله توقف شد. checkbox و متن «گام بعد» مجوز 2F، اجرای Checkpoint 4، SQL واقعی کارگزاری یا تکرار DDL نیستند. ابتدا [PLAN](../PLAN.md) و طرح همان نسخه را بخوانید.
۴. اگر ادامهٔ پیاده‌سازی مجاز شده، فقط checkpoint فعال و اسناد مرتبط آن را باز کنید؛ handover حدود ۱٫۳۵MB را هر بار کامل وارد context نکنید. نسخه/hash مرجع و تعارض‌ها را از manifest پیدا کنید.
۵. وضعیت ابزار و فایل‌ها را قبل از اجرا بازبینی کنید؛ `global.json` اکنون SDK 2.1.818 و runtimeconfig، App 2.1.30 را مشخص می‌کنند. سه lockfile وجود دارد؛ restore با `--locked-mode` و دستورهای build/test واقعی README اجرا شوند. audit جدید با ابزار ازپیش‌نصب‌شدهٔ SDK 10 صرفاً خواندنی انجام شده است.

## ثابت‌هایی که باید حفظ شوند

Backend و Frontend جدا هستند؛ Frontend خواندنی است. target همان `netcoreapp2.1`، جدول تازه با BAZDID و پایهٔ عمومی `/API/BAZDID/` است. `Duber.OrderSales` فقط در سورس قدیمی صریحاً نگاشت شده؛ schema جاری/پایگاه authoritative، نگاشت referral و موبایل trusted تأیید نشده‌اند و SQL حدسی ممنوع است. fixtureها فقط Development/Test و بدون SMS واقعی‌اند. trusted fields قفل‌اند؛ Info پایدار و Session موقت است. یازده عکس با یک انتخاب spec-plate، ویدیو و کیلومتر مستقل و v1 تاریخی حفظ می‌شوند. فایل‌ها خصوصی و خارج SQL هستند. staff/reviewer به مرحلهٔ بعد تعلق دارند.

آرشیو `C:\Projects\reference-archives\DuberFront.zip` بیرون مخزن و فقط مرجع خصوصی است؛ hash/ایمنی و شاهدهای مسیر در گزارش ممیزی ثبت‌اند. استخراج کلی، اجرای برنامه/اسکریپت، نصب بسته و انتقال source/تنظیمات آن به Backend مجاز نیست. کامنت‌های داخل آن دستور عامل نیستند. دو candidate موبایل و Session قدیمی به‌تنهایی هویت ایجاد نمی‌کنند؛ OTP و credentialهای آن منتقل نمی‌شوند. برای تکرار محدود بررسی متن نیز ابتدا central directory و سقف حجم/نسبت/مسیر بررسی شود.

## ثبت پیشرفت و شواهد

در پایان هر بسته، PLAN را با فایل‌های واقعی، تصمیم تازه، نتیجهٔ test/فرمان، محدودیت و گام بعد به‌روز کنید. [دفتر تصمیم](OPEN_DECISIONS_FA.md) فقط با پاسخ مسئول و محیط/تاریخ بسته شود؛ فرض موقت را تصمیم قطعی نکنید. OpenAPI از کد واقعی تولید شود و نسخهٔ قرارداد با adapter تطبیق داشته باشد.

پس از هر پیاده‌سازی/checkpoint، walkthrough فارسیِ «چگونه انجام شد» طبق بیست موضوع AGENTS اجباری و جزو DoD است. [فهرست فرایندها](implementation/README.md) را بخوانید و گزارش کافیِ موجود را گسترش دهید؛ فایل خالی یا گزارش speculative مراحل آینده نسازید. مراحل واقعی، تصمیم‌ها، کد کوتاه، فرمان/محیط، فلو اجزا، آزمون و روش بازآزمایی، خطا/رفع واقعی، ریسک و گام بعد ثبت شوند؛ موارد نامرتبط حذف و شاهد تاریخی از اجرای تازه تفکیک شود. [آموزش SQL در VS Code](guides/VSCODE_SQLSERVER_SETUP_FA.md) نمونه‌های خواندنی و مرزهای فعلی را توضیح می‌دهد و ادعای وجود پایگاه تست یا مجوز DDL نیست.

hash یا commit تحویل را از Git واقعی بخوانید؛ آن را حدس نزنید. فقط فایل‌های مرتبط و بدون راز stage شوند؛ remote یا push بدون دستور ایجاد نشود. اگر restore، test DB یا سرور در دسترس نبود، دقیقاً همان محدودیت را ثبت و از ادعای موفقیت خودداری کنید؛ fixture مجوز دسترسی به Production نیست.

## نقطهٔ شروع پس از تأیید تازه

foundation از نو ساخته نشود: `Bazdid.sln`، API و دو پروژهٔ تست موجودند؛ build و ۴۳ آزمون و HTTP واقعی health/Swagger و publish موفق‌اند. ANCM واقعی و Production security آزموده/تأیید نشده‌اند؛ audit شامل Critical/High است. آخرین commitهای واقعی را از Git بخوانید؛ گزارش تاریخی Phase 0 را وضعیت امروز نگیرید.

آخرین بررسی 2C: اتصال `lpc:.\SQLSERVER2019` با Windows/NTLM و Shared memory به همان ماشین؛ `15.0.2000.5 / Standard x64`، linked server/Cluster/HADR و DB کاربری غیرمنتظره صفر. `BAZDID_Development` اکنون با compatibility `150`، collation `SQL_Latin1_General_CP1_CI_AS`، SIMPLE و فقط سه جدول dbo وجود دارد. فایل داده/log هرکدام ۱۶ MiB با رشد ۱۶ و سقف ۵۱۲/۲۵۶ MiB هستند. هویت provisioning sysadmin بود؛ حساب runtime نیست. TrustServerCertificate فقط استثنای همین lpc محلی است. هیچ source کارگزاری/Production یا LocalDB اجرا/وارد نشد؛ وضعیت مقصد قبل از کار مجاز بعدی دوباره بررسی شود.

پس از 2E، گام پیشنهادی 2F بود؛ اکنون مجوز آن صادر و بخش آفلاین تحویل شده است، اما پذیرش متصل O24/O26 باز است. ساخت BAZDIDInfo در Checkpoint 4 می‌ماند. کد 2D همچنان IBrokerageRequestReader، دو متد async، مدل‌های immutable، BrokerageRequestService و reader حافظه‌ای با ۱۸ fixture دارد. DI پایه Disabled و Development/Testing صریحاً Synthetic است؛ Production آن را رد می‌کند. SQL reader تنها Unavailable/SourceNotConfigured می‌دهد؛ reference مجوز مالکیت نیست و endpoint تازه‌ای نداریم. این کد در 2E تغییر نکرد.

2E یک manifest **پیشنهادی** با ۱۳۱ ستون/هفت خانواده/۱۹ قاعدهٔ constraint و ماتریس ۲۶ فایل Frontend دارد. Origin مقدار، SourceStatus پذیرفته‌شده، InitialSourceStatus و آخرین مشاهده جدا می‌مانند؛ Manual شاهد Missing را پاک نمی‌کند. FK سه‌ستونیِ owner/context/inspection به parent آینده، schema فعلی نیست. GET اطلاعات آینده read-only است؛ observation در PUT می‌تواند قبل از apply manual، 409 SourceChanged با نسخهٔ جدید بسازد و پذیرش بعدی باید source را دوباره بخواند. پس از submit حتی timestamp Info تغییر نمی‌کند. SourceVersionMode/nullable version، پیشنهاد تغییر آینده است؛ 2D فعلی نسخهٔ غیرخالی لازم دارد و آن را بی‌اجازه تغییر ندهید. O27–O30 policy/crypto/freshness/قرارداد را قبل از اجرا gate می‌کنند.

ابزار `database/tools/Invoke-BazdidDevelopmentDatabase.ps1` پیش‌فرض Inspect است؛ Verify در 2D قبل/بعد خواندنی اجرا شد. هیچ DDL یا fixture DML و هیچ SQL CASE در 2D اجرا نشد. reviewها flag صفر دارند؛ مجوز 2C مجوز بازسازی DB موجود نیست. CASEهای 2C مستقیم اجرا نشوند؛ برای بازآزمایی مصوب همان ابزار transaction/rollback لازم است. identity/rowversion counter ممکن است از آزمون تاریخی جلو رفته باشد؛ reseed خودکار نکنید.

عیب تاریخی CHECK tenant در 2C رفع شده است؛ repair فقط سه قید را با WITH CHECK اصلاح کرد و نسخهٔ final initial_tables همین اصلاح را دارد. metadata قبل/بعد 2D: ۳۹ ستون/۱۰ index/سه PK/سه unique/یک FK/۱۳ CHECK trusted، دو rowversion و دو computed key؛ هر سه جدول صفر ردیف. این شاهد تاریخی است؛ در 2E SQL متصل نشد. ۳۵ CASE موفق متعلق به 2C هستند. SQL client 4.5.3 و قید framework تغییر نکردند؛ O24/O26 و mapping واقعی بازند. Info/OTP/Session/media همچنان آینده‌اند؛ target فعلی ۲۰٪ برای طراحی است، نه اجرای Info.

## گزارش نهایی و همگام‌سازی

پس از هر وظیفه گزارش فارسی و مطابق [سیاست AGENTS.md](../AGENTS.md) باشد. در 2E، restore locked/build/test **تازه** با SDK 2.1.818 موفق شدند؛ build صفر warning/error و ۶۵ unit + ۴۳ integration، جمع ۱۰۸ موفق. این آزمون‌های همان کد 2D هستند؛ سناریوهای E01–E24، schema، DTO، refresh، crypto و transaction طرح 2E هنوز اجرا/تست runtime نشده‌اند. smoke Kestrel متعلق به 2D، SQL CASEها متعلق به 2C و آخرین verification زندهٔ DB متعلق به 2D است. runtime/test/dependency/SQL/Frontend تغییر نکردند؛ 2E فقط طراحی و اعتبارسنجی اسناد/منابع است.

در گزارش بعدی درصد قبلی، سهم کسب‌شده و شاهد آن، درصد جدید و کار باقی‌مانده بیاید. سهم طراحی 2E طبق مجوز مالک **19% + 1 = 20%**، باقی‌مانده ۸۰٪ است؛ نگهداری صرف مستندات/بررسی gate امتیاز ندارند. ادامهٔ همین 2F فقط پس از رفع gateها و پذیرش کامل، دو واحد تا ۲۲٪ دارد؛ تحویل آفلاین امتیاز ندارد و مجوز 2G نیست. اجرای تاریخی را تازه معرفی نکنید و طراحی Info را اجرای SQL ندانید.

مقصد مجاز `origin` برابر `https://github.com/AliKeramattii/vehicle-inspection-backend.git` است. [GITHUB_SYNC_FA.md](GITHUB_SYNC_FA.md) را پیش از push بخوانید: کاربر در `2026-11-01` حذف ZIP از تمام تاریخچهٔ ارسالی و نگهداری اصل فقط محلی را صریحاً مجاز کرد؛ SHAهای جدید با اصل متفاوت‌اند. `.gitignore` یا حذف فایل فقط در commit جدید، تاریخچه را پاک نمی‌کند. branch `local-original-history-2026-11-01` هرگز push یا merge به نسخهٔ انتشار نشود؛ `--all` و `--mirror` ممنوع‌اند. checkpointهای بعدیِ مجاز پس از validation و مرور تاریخچه به همین مقصد push و HEAD و فایل‌های remote بررسی شوند؛ تاریخچهٔ مستقل remote حفظ شود.


## ادامه پس از تحویل آفلاین 2F

مطالب 2C/2D/2E بالا سابقهٔ همان مراحل‌اند؛ وضعیت فعلی از این بخش و ابتدای فایل خوانده شود. 2F با کد غیرفعال تحویل شد و امتیاز نگرفت. gate در SqlRuntimeGate کدنویسی‌شده و false است؛ Enabled یا connection string راه عبور نیست. source factory و SqlBrokerageRequestReader همچنان تنظیم‌نشده‌اند. دو principal و role موجود نیستند؛ هویت provisioner برنامه نیست. O24 انتخاب provider امن/سازگار/متصل را حل نکرده و گراف فعلی فقط برای آفلاین حفظ شده است. ابتدا تصمیم provider و نام/مجوز دو Windows principal تصویب و schema/effective permissions با خود هویت‌ها بررسی شوند؛ سپس بازبینی gate و تست SQL کنترل‌شده، بدون DDL خودکار.

اجرای تازهٔ این تحویل: restore/build صفر، warning/error صفر، ۱۰۹ unit + ۵۰ integration آفلاین موفق، ۸ SQL Skipped و صفر connected SQL. Kestrel واقعی با SQL خاموش health/Swagger 200 و فرآیند متوقف شد؛ IIS آزموده نشد. schema قبل/بعد برابر و خالی است. برای آزمون‌های بعدی، transaction rollback-only و بررسی مجاز audit قبل/بعد، رقابت commitشده و commit مبهم هنوز لازم‌اند؛ body تست‌های غیرفعال تأیید رفتار نیست. dependency/lockfile/SQL script/Frontend و فایل untracked کاربر حفظ شدند.

**20 + 0 = 20%**؛ باقی 80% و هدف مشروط پس از پذیرش کامل همین 2F برابر 22% است. توقف پس از این تحویل؛ 2G، auth، Info یا checkpoint بعدی شروع نشود. وضعیت واقعی commit/push از GITHUB_SYNC و Git بررسی شود؛ تغییرهای ناتمام/کاربر را حفظ کنید.


## آخرین ادامهٔ 2F طبق e252dad0

این بخش وضعیت تازه‌تر از تحویل اولیهٔ آفلاین بالاست. مبنا `3b5e78dd8c35d7da6b0550d92220b782ac1acc12`؛ [بستهٔ تصمیم/تصویب](checkpoint2f/CONTINUATION_APPROVAL_FA.md)، [نه candidate](checkpoint2f/PROVIDER_CANDIDATES.json) و [شواهد تازه](checkpoint2f/CONTINUATION_REVIEW.json). منشأ range خود Microsoft.AspNetCore.App2.1.30 و تعارضهای CodePages و candidateهای جدید اثبات شد؛ provider امنِ متصل انتخاب/مصوب نشده و target/lockfile/package/runtime/test-code/gate دست‌نخورده‌اند. طرح .NET10/Microsoft.Data.SqlClient6.1.7 فقط پیشنهاد برای مجوز جداست؛ الزام 2.1 فعلاً معتبر است.

دو نام `.\BAZDIDDevWriter` و `.\BAZDIDDevReader` پیشنهاد مجاز این تحلیل‌اند، نه حساب مصوب/موجود. development_logins.review.sql جدید و permissions.review.sql اصلاح‌شده فقط پیشنهادند؛ هر دو AllowDdl0 و approval/ماشین/login/SIDهای NULL دارند. ScriptDom موجود فقط syntax دو فایل و دو template را parse کرد؛ هیچ SQL آن‌ها اجرا نشد. حساب metadata SQL sysadmin ولی Windows token فعلی admin مؤثر نیست؛ ساخت حساب نیازمند مسئول Windows و تصویب حقوق/ACL/task است. registry ForceEncryption0 و binding صریح خالی، گواه TLS یا نبود certificate نیست.

regression همین ادامه تازه اجرا شد: restore/build صفر، warning/error صفر، ۱۰۹ unit + ۵۰ integration آفلاین موفق، ۸ SQL Skipped و صفر متصل/effective permission. تست جدیدی ساخته نشد؛ smoke Kestrel/IIS و ۳۵ CASE تاریخی تکرار نشدند. metadata محلی همان schema/صفر ردیف است. پیش از نسخهٔ package، ایجاد account/login/user/role، grant، certificate/network یا بازکردن gate، تصمیم‌های P0–P5 را از پاسخ مالک احراز کنید؛ مصوبهٔ قبلی را در دامنهٔ خودش حفظ کنید. کد قبلی بازنویسی نشود و source reader واقعی تنظیم‌نشده بماند. **20 + 0 = 20%**؛ باقی80%، هدف مشروط پذیرش کامل همین 2F برابر22%، توقف پیش از2G. SHA/push از گزارش GitHub و Git واقعی خوانده شود.

<a id="agents-status-history"></a>

## سابقهٔ وضعیت منتقل‌شده از AGENTS

این بلوک‌ها در 2026-11-07 برای کوتاه‌شدن AGENTS.md بی‌تغییر به اینجا منتقل شدند (فقط مسیر نسبی پیوندها اصلاح شد).

**وضعیت جاری در 2026-11-07 (شب): Checkpoint 2F پذیرفته شد؛ پیشرفت 22% است.** اجرای متصل `09a21cbd72e12d91` با هویت واقعی `BAZDIDDevWriter`: ۱۳ از ۱۳ آزمون موفق، verifier برابر PASS و cleanup `1/2/5` ([بخش ۲۲](implementation/CHECKPOINT-02F-CONNECTED-ACCEPTANCE_FA.md#acceptance-20261107)). gate زمان اجرای برنامه و Production همچنان بسته‌اند. گام بعد: آماده‌سازی 2G. حساب‌ها، loginها، certificate و task را بازسازی نکنید.

**سابقهٔ عصر 2026-11-07: D-P3-NAME اعمال شد و P2 اجرا و تأیید شد (40/40 مجوز). P4/P5 پیاده شده‌اند و منتظر یک اجرای elevated مالک هستند.** [بخش ۲۱](implementation/CHECKPOINT-02F-CONNECTED-ACCEPTANCE_FA.md#execution-20261107):

- مقصد ثابت `lpc:localhost\SQLSERVER2019`. اشکال guard، یعنی `HAS_PERMS_BY_NAME(NULL,N'SERVER',…)` که همیشه NULL می‌داد، رفع شد.
- آزمون متصل فقط با `BAZDID_CONNECTED_SQL=1` و token واقعی `BAZDIDDevWriter` از طریق task اجرا می‌شود. gate برنامه بسته است.
- گام بعد: مالک `Register-BazdidConnectedTestTask.review.ps1 -Execute` را اجرا می‌کند، سپس عامل `Start-BazdidConnectedRun.ps1` را. پیشرفت 20% است و 2G شروع نشده است.

**سابقهٔ صبح 2026-11-07: certificate مربوط به P3 توسط مدیر نصب شد (thumbprint `9F8A13B7…E84F`). آن را دوباره نصب یا تغییر ندهید.** [راستی‌آزمایی](implementation/CHECKPOINT-02F-CONNECTED-ACCEPTANCE_FA.md#p3-verification-20261107):

- اعتماد زنجیره حل شد. مقصد pin‌شدهٔ `lpc:.\SQLSERVER2019` با `SEC_E_WRONG_PRINCIPAL` رد می‌شود.
- `localhost` و نام میزبان، روی Shared Memory و loopback TCP، با اعتبارسنجی کامل موفق‌اند.
- تصمیم باز `D-P3-NAME`؛ P1 آمادهٔ اجرای مدیر است. gate بسته است و پیشرفت 20% است.

**سابقهٔ 2026-11-06 (پس از L1-A): اجرای P1–P5 آغاز شد ولی 2F پذیرفته نشد.** [گزارش پذیرش متصل](implementation/CHECKPOINT-02F-CONNECTED-ACCEPTANCE_FA.md):

- اتصال امن با `Encrypt=true` و `TrustServerCertificate=false` با `SEC_E_UNTRUSTED_ROOT` رد شد، چون instance certificate معتبر ندارد.
- نشست عامل elevated نیست، پس P1 و P3 به مدیر محلی سپرده شدند: دو script بازبینی در `deployment/development/` که اجرا نشده‌اند.
- gate، کد و پایگاه بدون تغییرند. هیچ حساب، login یا دادهٔ آزمونی ساخته نشد. پیشرفت 20% است.

**سابقهٔ L1-A در 2026-11-06: L1-A با تصویب مالک روی canonical اعمال شد.** [walkthrough L1-A](implementation/CHECKPOINT-02F-L1A-CANONICAL-DEPENDENCIES_FA.md):

- metapackage با گراف ریز ASP.NET Core 2.1 و `System.Data.SqlClient 4.8.6` جایگزین شد؛ target همچنان `netcoreapp2.1`.
- build صفر warning/error؛ ۱۰۹ unit + ۵۰ integration موفق، ۸ SQL Skipped.
- Swagger قبل و بعد یکسان است و audit ۲ بستهٔ flagged دارد (Kestrel Critical، SwaggerUI Moderate).
- gate و `SqlRuntime.Enabled` بسته‌اند.

L1-R، P1 تا P5 و 2G تصویب یا اجرا نشده‌اند. **2F کامل نیست و پیشرفت 20% است.**

**سابقهٔ 2026-11-03: بررسی 2F-L1 (SQL Client سازگار با 2.1) انجام شد؛ canonical همچنان `netcoreapp2.1`، پذیرش متصل 2F باز و پیشرفت 20% است.** [walkthrough L1](implementation/CHECKPOINT-02F-LEGACY-SQLCLIENT-FEASIBILITY_FA.md) نشان داد:

- تنها نامزد فنی، `System.Data.SqlClient 4.8.6` روی گراف ریز ASP.NET Core 2.1 با pinهای امنیتی است.
- کپی ignored کد canonical روی این گراف صفر warning/error و ۱۰۹ unit + ۵۰ integration موفق/۸ SQL Skipped دارد.
- audit از ۹ به ۲ بستهٔ flagged رسید؛ Kestrel 2.1.25 با Critical CVE-2025-55315 بی‌وصله باقی است.

هیچ نامزدی امن یا آمادهٔ Production اعلام نشده است. کد، package، lockfile، gate، SQL و فایل شخصی کاربر حفظ شدند. هیچ اتصال SQL، native load، حساب/ACL/task، DDL/GRANT، TLS یا IIS اجرا نشد. ادامه نیازمند تصمیم کارفرما است:

- **L1-A**: تغییر بستهٔ canonical؛
- **L1-R**: پذیرش مکتوب ریسک باقی‌مانده؛
- P1 تا P4: هرکدام مستقل.

P0 با .NET10 ([walkthrough](implementation/CHECKPOINT-02F-P0-MIGRATION-FEASIBILITY_FA.md)) فقط پژوهش آینده است و مهاجرت گام مصوب نیست. پیش از تصویب‌ها توقف؛ 2G، source واقعی، OTP/Session/Info/media/Production شروع نشده‌اند.
