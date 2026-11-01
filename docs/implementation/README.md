# راهنمای فرایند پیاده‌سازی Backend

این صفحه، نقطهٔ ورود به توضیح «چگونه انجام شد» است. گزارش‌های معتبر قبلی در جای خود می‌مانند و محتوا دوباره کپی نمی‌شود. تاریخ نگهداری `2026-11-01`؛ مبنای شروع این وظیفه `a2e0958`؛ پیشرفت کل **15%** و سهم تغییر سیاست مستندات **0** است. SQL و Checkpoint 2C در این وظیفه اجرا/شروع نشده‌اند.

## مراحل دارای کار واقعی

| مرحله | راهنمای اصلی و شواهد | آنچه واقعاً انجام شده | commit قابل انتشار |
|---|---|---|---|
| 0 | [روش و کنترل Phase 0](../PHASE0_VALIDATION_FA.md)، [منابع و تعارض‌ها](../SOURCE_REFERENCES_FA.md)، [معماری](../ARCHITECTURE_FA.md) | تحلیل منابع، قراردادها، برنامه و کنترل فایل/پیوند/hash؛ بدون runtime | [2ddf17a](https://github.com/AliKeramattii/vehicle-inspection-backend/commit/2ddf17a)، [اصلاح 2c9195c](https://github.com/AliKeramattii/vehicle-inspection-backend/commit/2c9195c) |
| 1 | [فرایند foundation و اجرای محلی](../CHECKPOINT1_IMPLEMENTATION_FA.md)، [شاهد HTTP](../checkpoint1/HTTP_SMOKE.json)، [audit](../checkpoint1/DEPENDENCY_SECURITY_FA.md) | API نسل 2.1، health و خطا/config/Swagger؛ build/test/run/publish محلی | [کد 613d351](https://github.com/AliKeramattii/vehicle-inspection-backend/commit/613d351)، [گزارش dafb037](https://github.com/AliKeramattii/vehicle-inspection-backend/commit/dafb037) |
| 1.5 | [روش ممیزی DuberFront](../DUBERFRONT_CODE_AUDIT_FA.md)، [ماتریس نگاشت](../BROKERAGE_DATA_MAPPING_FA.md) | central directory، خواندن محدود متن، شاهدهای مسیر و ابهام‌های mapping؛ بدون اجرای source | [2e217a0](https://github.com/AliKeramattii/vehicle-inspection-backend/commit/2e217a0) |
| 2A/2B | [فرایند کشف و آماده‌سازی](../CHECKPOINT2A_2B_REPORT_FA.md)، [راهنمای فایل‌های SQL](../../database/README.md)، [طراحی سه جدول](../DATABASE_DESIGN_FA.md) | metadata محلی و پیش‌نویس‌های بسته برای بازبینی؛ بدون ساخت DB/جدول/نقش یا repository | [a2e0958](https://github.com/AliKeramattii/vehicle-inspection-backend/commit/a2e0958) |

گزارشی برای 2C، احراز هویت، Info، media، submit، کارکنان یا deployment واقعی ایجاد نشده است؛ این قابلیت‌ها هنوز پیاده نشده‌اند. طراحی آینده در اسناد معماری/PLAN باقی می‌ماند. به‌ویژه `BAZDID_Development` و جدول‌های آن در آخرین کشف وجود نداشتند؛ [آموزش VS Code](../guides/VSCODE_SQLSERVER_SETUP_FA.md) ادعای وجود آن‌ها نیست.

## شیوهٔ استفاده و نگهداری

۱. ابتدا [AGENTS](../../AGENTS.md)، [PLAN و درصد فعلی](../../PLAN.md) و [تصمیم‌های باز](../OPEN_DECISIONS_FA.md) را بخوانید؛ مجوز تازه را از پیام مالک احراز کنید.
۲. گزارش مرحله و source/script واقعیِ لینک‌شده را کنار هم بخوانید. فرمان‌های تاریخی شاهد همان اجرا هستند؛ برای بازآزمایی، پیش‌نیاز و محیط همان نسخه لازم است.
۳. هنگام کار پیاده‌سازی، مراحل و دلیل تصمیم‌ها، فرمان/خطای غیرحساس و نتیجهٔ واقعی را ثبت کنید؛ پیش از تحویل به همان گزارش اضافه و این فهرست را به‌روز کنید. اگر گزارش مناسب موجود نیست، فایل فارسی مرتبط با checkpoint انجام‌شده در همین پوشه بسازید.
۴. فلو قابلیت را با نام واقعی API/service/adapter/table و خطاها شرح دهید؛ برای فرایند چندمرحله‌ای نمودار فقط وقتی مفید است اضافه کنید. قطعه‌کد کوتاه از source BAZDID باشد و خواننده را به فایل کامل هدایت کند.
۵. اجرای خودکار/دستی، موارد اجرا‌نشده، ریسک، تصمیم باز و کار بعد را جدا و صریح بنویسید. ادعای SQL Server، IIS یا مرورگر باید شاهد همان محیط را داشته باشد.
۶. پس از validation، فایل‌های امن را commit/push و HEAD/فایل remote را بررسی کنید؛ شناسه و نتیجهٔ واقعی در گزارش تحویل بیاید. این کار، مجوز انتشار آرشیو یا branch اصلی خصوصی نیست.

فهرست بیست موضوع اجباری و استثنای موارد نامرتبط فقط در [قاعدهٔ دائمی AGENTS](../../AGENTS.md#implementation-walkthrough) نگهداری می‌شود. برای مراحل تاریخی، فقدان command log کامل با بازسازی حدسی پوشانده نمی‌شود. SHAهای قدیمی و عبارت‌های «remote وجود نداشت» در گزارش‌ها وضعیت همان زمان‌اند؛ [نقشهٔ تاریخچه](../GIT_HISTORY_EXPORT.json) و [گزارش GitHub](../GITHUB_SYNC_FA.md) تبدیل تاریخچه را توضیح می‌دهند.

## کنترل همین تغییر مستنداتی

این وظیفه فقط سیاست، فهرست راهنماها، آموزش ابزار و تکمیل محدود گزارش‌های قبلی است. SQL، build/test برنامه و runtime دوباره اجرا نشدند؛ ۴۳ آزمون ثبت‌شده مربوط به اجرای قبلی 2A/2B هستند. ۱۲۷ پیوند/یک anchor، fence و تطابق نمونهٔ source در ۱۰ Markdown تأیید شدند. پنج نمونهٔ SQL فقط‌خواندنی و پنج بلوک PowerShell فقط parse شدند و اجرا نشدند؛ اسکن ۱۱۱ فایل/۱۳۹ blob تاریخی main هشدار راز باقی‌مانده نداشت. diff مستنداتی است و درصد تغییر ندارد. نتیجهٔ نهایی همگام‌سازی امن main و SHA از Git واقعی و گزارش تحویل خوانده شوند؛ [PLAN](../../PLAN.md) شاهد کنترل این نگهداری است.
