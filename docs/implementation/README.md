# راهنمای فرایند پیاده‌سازی Backend

این صفحه، نقطهٔ ورود به توضیح «چگونه انجام شد» است؛ گزارش‌های قبلی سابقهٔ همان مرحله‌اند.

**وضعیت جاری `2026-11-07`:** [راستی‌آزمایی P3](CHECKPOINT-02F-CONNECTED-ACCEPTANCE_FA.md#p3-verification-20261107). نصب certificate موفق بود و اعتماد زنجیره حل شد. مقصد pin‌شدهٔ برنامه، `lpc:.\SQLSERVER2019`، با `SEC_E_WRONG_PRINCIPAL` رد می‌شود، در حالی که `localhost` و نام میزبان با اعتبارسنجی کامل موفق‌اند. تصمیم `D-P3-NAME` و اجرای P1 باز هستند. پیشرفت **20%**.

سابقه، **وضعیت `2026-11-06`:** [پذیرش متصل 2F (P1–P5)](CHECKPOINT-02F-CONNECTED-ACCEPTANCE_FA.md) در P3 متوقف است: TLS با `SEC_E_UNTRUSTED_ROOT` رد شد و نشست عامل elevated نیست. scriptهای مدیر آماده و اجرانشده‌اند و در `2026-11-07` پیش از اجرا بازنگری شدند ([بخش ۱۹](CHECKPOINT-02F-CONNECTED-ACCEPTANCE_FA.md#revision-20261107)). پیشرفت **20%**.

سابقه، **وضعیت `2026-11-06`:** [L1-A — وابستگی‌های canonical](CHECKPOINT-02F-L1A-CANONICAL-DEPENDENCIES_FA.md) را بخوانید. گراف ریز با `System.Data.SqlClient 4.8.6` روی canonical اعمال شده است. ۱۵۹ آزمون موفق، ۸ Skipped، Swagger بدون تغییر و audit با ۲ بستهٔ flagged ثبت شده‌اند. gate SQL بسته و پیشرفت **20%** است.

سابقه، **وضعیت `2026-11-03`:** [2F-L1 — SQL Client سازگار با 2.1](CHECKPOINT-02F-LEGACY-SQLCLIENT-FEASIBILITY_FA.md) را بخوانید. این سند ۱۲ گراف آزمایشی، گراف ریز با `System.Data.SqlClient 4.8.6` و pinهای امنیتی، کپی canonical با ۱۵۹ موفق/۸ Skipped، audit با ۲ بستهٔ flagged و چک‌لیست P1/P2 را دارد. canonical تغییر نکرد و اتصال SQL اجرا نشد. پیشرفت **20%** است. [شاهد](../checkpoint2f/LEGACY_SECURITY_PINS.json).

سابقه، وضعیت `2026-11-03`: [P0 امکان‌سنجی و آزمایش موقت](CHECKPOINT-02F-P0-MIGRATION-FEASIBILITY_FA.md) با۱۴ تست/سه HTTP smoke موفق انجام شد؛۱۵۹ تست canonical تازه موفق و۸SQL Skipped است. canonical مهاجرت نکرد و در P0 هیچ اتصال/metadata SQL اجرا نشد. پذیرش متصل O24/O26 باز و پیشرفت **20%** است. verificationهای زندهٔ اسناد قبلی و۳۵CASE SQL متعلق به مراحل تاریخی‌اند.

## مراحل دارای کار واقعی

| مرحله | راهنمای اصلی و شواهد | آنچه واقعاً انجام شده | commit قابل انتشار |
|---|---|---|---|
| 0 | [روش و کنترل Phase 0](../PHASE0_VALIDATION_FA.md)، [منابع و تعارض‌ها](../SOURCE_REFERENCES_FA.md)، [معماری](../ARCHITECTURE_FA.md) | تحلیل منابع، قراردادها، برنامه و کنترل فایل/پیوند/hash؛ بدون runtime | [2ddf17a](https://github.com/AliKeramattii/vehicle-inspection-backend/commit/2ddf17a)، [اصلاح 2c9195c](https://github.com/AliKeramattii/vehicle-inspection-backend/commit/2c9195c) |
| 1 | [فرایند foundation و اجرای محلی](../CHECKPOINT1_IMPLEMENTATION_FA.md)، [شاهد HTTP](../checkpoint1/HTTP_SMOKE.json)، [audit](../checkpoint1/DEPENDENCY_SECURITY_FA.md) | API نسل 2.1، health و خطا/config/Swagger؛ build/test/run/publish محلی | [کد 613d351](https://github.com/AliKeramattii/vehicle-inspection-backend/commit/613d351)، [گزارش dafb037](https://github.com/AliKeramattii/vehicle-inspection-backend/commit/dafb037) |
| 1.5 | [روش ممیزی DuberFront](../DUBERFRONT_CODE_AUDIT_FA.md)، [ماتریس نگاشت](../BROKERAGE_DATA_MAPPING_FA.md) | central directory، خواندن محدود متن، شاهدهای مسیر و ابهام‌های mapping؛ بدون اجرای source | [2e217a0](https://github.com/AliKeramattii/vehicle-inspection-backend/commit/2e217a0) |
| 2A/2B | [فرایند کشف و آماده‌سازی](../CHECKPOINT2A_2B_REPORT_FA.md)، [راهنمای فایل‌های SQL](../../database/README.md)، [طراحی سه جدول](../DATABASE_DESIGN_FA.md) | metadata محلی و پیش‌نویس‌های بسته برای بازبینی؛ بدون ساخت DB/جدول/نقش یا repository | [a2e0958](https://github.com/AliKeramattii/vehicle-inspection-backend/commit/a2e0958) |
| 2C | [ساخت و verification پایگاه](CHECKPOINT-02C-DATABASE-CREATION_FA.md)، [metadata](../checkpoint2c/SCHEMA_VERIFICATION.json)، [۳۵ آزمون SQL](../checkpoint2c/ROLLBACK_TEST_RESULTS.json)، [آزمون برنامه](../checkpoint2c/APPLICATION_VALIDATION.json) | DB محلی و فقط سه جدول، اصلاح CHECK با WITH CHECK و صفر ردیف پس از rollback؛ بدون SQL runtime | SHA بسته از Git واقعی و گزارش تحویل خوانده شود |
| 2D | [reader و قراردادهای داخلی](CHECKPOINT-02D-BROKERAGE-READER_FA.md)، [آزمون برنامه](../checkpoint2d/APPLICATION_VALIDATION.json)، [بررسی خواندنی DB](../checkpoint2d/DATABASE_VERIFICATION.json)، [HTTP واقعی](../checkpoint2d/HTTP_SMOKE.json) | ۱۸ fixture حافظه‌ای، provenance، scope و DI امن؛ ۱۰۸ آزمون و smoke Kestrel؛ بدون SQL واقعی مبدأ | [پیاده‌سازی 30112f1](https://github.com/AliKeramattii/vehicle-inspection-backend/commit/30112f104d9def9a5ea91cfd56b78d21e581685a)؛ تکمیل گزارش از Git و گزارش تحویل |
| 2E | [طرح persistence/refresh](CHECKPOINT-02E-INFO-PERSISTENCE-DESIGN_FA.md)، [schema پیشنهادی](../design/BAZDIDINFO_SCHEMA_PROPOSAL.json)، [baseline تازه](../checkpoint2e/APPLICATION_VALIDATION.json)، [Frontend](../checkpoint2e/FRONTEND_REVIEW.json)، [اعتبارسنجی طراحی](../checkpoint2e/DESIGN_VALIDATION.json) | فقط طراحی و تطبیق منابع؛ بدون Info/DDL/API یا تغییر runtime؛ ۱۰۸ آزمون موجود تازه موفق | [طرح 9f5f7df](https://github.com/AliKeramattii/vehicle-inspection-backend/commit/9f5f7df94dc6f1dd6e854af8d52e2d4818fd3d06)؛ ثبت تکمیلی از Git و گزارش تحویل |
| 2F، پذیرش ناقص | [repositoryهای آفلاین و gate بسته](CHECKPOINT-02F-SQL-REPOSITORIES_FA.md)، [شاهد آزمون](../checkpoint2f/APPLICATION_VALIDATION.json)، [SQL مسدود](../checkpoint2f/SQL_TEST_RESULTS.json) | سه repository/transaction/DI، ۱۵۹ موفق آفلاین و ۸ SQL Skipped؛ بدون DML/DDL/grant و بدون امتیاز تازه | [کد f3bf660](https://github.com/AliKeramattii/vehicle-inspection-backend/commit/f3bf660cc640eebd20ed348cdda181b041d0d799)؛ شواهد در [گزارش GitHub](../GITHUB_SYNC_FA.md) |

گزارشی برای **پیاده‌سازی** Info، احراز هویت، media، submit، کارکنان یا deployment واقعی ایجاد نشده است؛ راهنمای 2E فقط طراحی همان checkpoint مجاز است و گزارش اجرای Checkpoint 4 نیست. راهنمای 2F فقط کد آفلاین موجود و موانع واقعی آن را شرح می‌دهد؛ گزارش 2G ساخته نشده است. [آموزش VS Code](../guides/VSCODE_SQLSERVER_SETUP_FA.md) راه مشاهده است و اجرای تصویری VS Code را ادعا نمی‌کند.

## شیوهٔ استفاده و نگهداری

۱. ابتدا [AGENTS](../../AGENTS.md)، [PLAN و درصد فعلی](../../PLAN.md) و [تصمیم‌های باز](../OPEN_DECISIONS_FA.md) را بخوانید؛ مجوز تازه را از پیام مالک احراز کنید.
۲. گزارش مرحله و source/script واقعیِ لینک‌شده را کنار هم بخوانید. فرمان‌های تاریخی شاهد همان اجرا هستند؛ برای بازآزمایی، پیش‌نیاز و محیط همان نسخه لازم است.
۳. هنگام کار پیاده‌سازی، مراحل و دلیل تصمیم‌ها، فرمان/خطای غیرحساس و نتیجهٔ واقعی را ثبت کنید؛ پیش از تحویل به همان گزارش اضافه و این فهرست را به‌روز کنید. اگر گزارش مناسب موجود نیست، فایل فارسی مرتبط با checkpoint انجام‌شده در همین پوشه بسازید.
۴. فلو قابلیت را با نام واقعی API/service/adapter/table و خطاها شرح دهید؛ برای فرایند چندمرحله‌ای نمودار فقط وقتی مفید است اضافه کنید. قطعه‌کد کوتاه از source BAZDID باشد و خواننده را به فایل کامل هدایت کند.
۵. اجرای خودکار/دستی، موارد اجرا‌نشده، ریسک، تصمیم باز و کار بعد را جدا و صریح بنویسید. ادعای SQL Server، IIS یا مرورگر باید شاهد همان محیط را داشته باشد.
۶. پس از validation، فایل‌های امن را commit/push و HEAD/فایل remote را بررسی کنید؛ شناسه و نتیجهٔ واقعی در گزارش تحویل بیاید. این کار، مجوز انتشار آرشیو یا branch اصلی خصوصی نیست.

فهرست بیست موضوع اجباری و استثنای موارد نامرتبط فقط در [قاعدهٔ دائمی AGENTS](../../AGENTS.md#implementation-walkthrough) نگهداری می‌شود. برای مراحل تاریخی، فقدان command log کامل با بازسازی حدسی پوشانده نمی‌شود. SHAهای قدیمی و عبارت‌های «remote وجود نداشت» در گزارش‌ها وضعیت همان زمان‌اند؛ [نقشهٔ تاریخچه](../GIT_HISTORY_EXPORT.json) و [گزارش GitHub](../GITHUB_SYNC_FA.md) تبدیل تاریخچه را توضیح می‌دهند.

## ثبت تاریخی کنترل سیاست مستندات؛ پیش از 2C

در وظیفهٔ سیاست مستندات، فقط راهنما و گزارش‌ها تکمیل و SQL/build/test دوباره اجرا نشدند؛ ۴۳ آزمون آن زمان شاهد 2A/2B بود. ۱۲۷ پیوند/یک anchor، نمونهٔ source و ۱۰ Markdown تأیید شدند؛ پنج SQL فقط‌خواندنی و پنج PowerShell فقط parse شدند، اسکن ۱۱۱ فایل/۱۳۹ blob هشدار راز نداشت و سهم پیشرفت صفر بود. این آمار تاریخی است؛ اجرای واقعی و آزمون تازهٔ provisioning 2C در ردیف و walkthrough خودش ثبت است. SHA و همگام‌سازی از Git و تحویل مربوط خوانده شوند؛ [PLAN](../../PLAN.md) مرجع پیشرفت جاری است.


ادامهٔ 2F طبق `e252dad0-0bb1-4058-ab9b-f757dd2b272a` فقط تحلیل و آماده‌سازی تصویب است: [بستهٔ provider/حساب/permissions](../checkpoint2f/CONTINUATION_APPROVAL_FA.md)، [شاهد تازه](../checkpoint2f/CONTINUATION_REVIEW.json) و بخش ادامهٔ walkthrough موجود را بخوانید. نه candidate، دو script بستهٔ آفلاین parseشده و ۱۵۹ موفق/۸ SQL Skipped تازه ثبت شدند؛ provider، حساب‌ها و SQL متصل هنوز تصویب/اجرا نشده‌اند. درصد۲۰٪ و توقف پیش از تغییر نامصوب/2G حفظ شد.

## P0 امکان‌سنجی مهاجرت؛ تحویل مستقل از اجرای2F

[راهنمای الزامی P0](CHECKPOINT-02F-P0-MIGRATION-FEASIBILITY_FA.md)، [برنامهٔ فایل‌به‌فایل](../checkpoint2f/P0_MIGRATION_FILE_PLAN_FA.md) و [نتیجهٔ امن](../checkpoint2f/P0_FEASIBILITY_RESULTS.json) شامل ساختار نمونهٔ ignored، خطاهای واقعی/رفع آن‌ها،۱۴تست و سهHTTP موفق، regressionاصلی۱۵۹موفق/۸SQLSkip، گراف مستقل/pin امنیتی، hosting/IIS، برآورد و چک‌لیست تصویب‌اند. هیچ prototype/source/artifact موقتی منتشر نمی‌شود. canonical2.1 حفظ و اتصالSQL/IIS/P1/P2 اجرا نشد؛ **20+0=20%**. commit و remote از [گزارش GitHub](../GITHUB_SYNC_FA.md) خوانده شوند.

commit بستهٔ P0: [55573fd](https://github.com/AliKeramattii/vehicle-inspection-backend/commit/55573fda0c2741f103760c3e959c7ff108e10431)؛ push، HEAD و سه blob مستقلاً برابر تأیید شدند. گزارش و ارجاع‌های تحویل در ثبت تکمیلی به‌روز می‌شوند؛ نتیجهٔ نهایی از Git واقعی خوانده شود.
