# ادامهٔ کار پس از قطع نشست عامل

هدف این فایل جلوگیری از تکرار کار و عبور ناخواسته از checkpoint مجاز است. وضعیت `2026-11-02`: **2D در دامنهٔ reader ساختگی/قرارداد طبق مجوز `2df8399e-d511-49b7-af28-a075f801dd57` تکمیل شد؛ پیشرفت 19%.** مبنای شروع `b495b10` بود. [walkthrough و شواهد 2D](implementation/CHECKPOINT-02D-BROKERAGE-READER_FA.md) مرجع‌اند؛ این تکمیل، مجوز 2E–2G یا SQL واقعی/Production نیست. پایگاه موجود را خودکار ایجاد، حذف، reset یا بازسازی نکنید.

پیوست سیاست مستندات `3d0d6a79-4b95-4875-88b4-571e799beb75` سهم صفر داشت؛ تلاش قدیمی 2D به‌علت نبود پایگاه متوقف شد. سپس 2C مستقل اجرا شد و در درخواست جدید، پیش‌نیاز آن دوباره تأیید و 2D تکمیل شد؛ ثبت توقف قدیمی وضعیت جاری نیست. فایل untracked کاربر `src/Bazdid.Api/Properties/launchSettings.json` از قبل وجود داشت، تغییر نکرد و commit نشد.

## ترتیب بازیابی زمینه

۱. `AGENTS.md`، `PLAN.md`، README، [شناسنامهٔ منابع](SOURCE_REFERENCES_FA.md)، [تصمیم‌های باز](OPEN_DECISIONS_FA.md)، [ممیزی DuberFront](DUBERFRONT_CODE_AUDIT_FA.md) و [نگاشت مبتنی بر شاهد](BROKERAGE_DATA_MAPPING_FA.md) را بخوانید. اعتبارسنجی Phase 0 و اجرای Checkpoint 1 اسناد تاریخی همان مراحل‌اند.
۲. cwd را `C:\Projects\vehicle-inspection-backend` احراز کنید. `git status --short`، branch و `git log -1` را بخوانید. تغییر کاربر را از کار قبلی جدا کنید و هیچ reset/clean/stash خودکار انجام ندهید.
۳. آخرین پیام صریح کاربر را بررسی کنید. مجوز 2D فقط reader/قرارداد ساختگی بود؛ اجرا/آزمون انجام و در همان مرحله توقف شد. checkbox و متن «گام بعد» مجوز شروع 2E، SQL واقعی کارگزاری یا تکرار DDL نیستند. ابتدا [PLAN](../PLAN.md) و walkthrough همان نسخه را بخوانید.
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

گام پیشنهادی بعد **2E — فقط طرح persistence/refresh اطلاعات** در درخواست جداگانه است؛ ساخت BAZDIDInfo در Checkpoint 4 می‌ماند. 2D اکنون IBrokerageRequestReader، دو متد async، مدل‌های immutable، BrokerageRequestService و reader ساختگی با ۱۸ رکورد حافظه‌ای دارد. DI پایه Disabled و Development/Testing صریحاً Synthetic با scope ثابت است؛ Production synthetic/scope آزمایشی را رد می‌کند. SqlBrokerageRequestReader تنها Unavailable/SourceNotConfigured می‌دهد و query ندارد؛ reference مجوز مالکیت نیست و هیچ endpoint تازه‌ای نداریم. زمان دریافت UTC، نسخهٔ واقعی یا freshness منبع را ثابت نمی‌کند.

ابزار `database/tools/Invoke-BazdidDevelopmentDatabase.ps1` پیش‌فرض Inspect است؛ Verify در 2D قبل/بعد خواندنی اجرا شد. هیچ DDL یا fixture DML و هیچ SQL CASE در 2D اجرا نشد. reviewها flag صفر دارند؛ مجوز 2C مجوز بازسازی DB موجود نیست. CASEهای 2C مستقیم اجرا نشوند؛ برای بازآزمایی مصوب همان ابزار transaction/rollback لازم است. identity/rowversion counter ممکن است از آزمون تاریخی جلو رفته باشد؛ reseed خودکار نکنید.

عیب تاریخی CHECK tenant در 2C رفع شده است؛ repair فقط سه قید را با WITH CHECK اصلاح کرد و نسخهٔ final initial_tables همین اصلاح را دارد. metadata قبل/بعد 2D: ۳۹ ستون/۱۰ index/سه PK/سه unique/یک FK/۱۳ CHECK trusted، دو rowversion و دو computed key؛ هر سه جدول صفر ردیف. ۳۵ CASE موفق متعلق به 2C هستند. SQL client 4.5.3 و قید framework تغییر نکردند؛ 2D به SQL package نیاز نداشت و O24 باز ماند. O25 بخش محلی بسته و O26 حساب/permission و mapping واقعی بازند؛ نقش یا grant جدیدی ایجاد نشد. Info/OTP/Session/media همچنان آینده‌اند؛ هدف مشروط بعد از 2E برابر ۲۰٪ است و اکنون کسب نشده.

## گزارش نهایی و همگام‌سازی

پس از هر وظیفه گزارش فارسی و مطابق [سیاست AGENTS.md](../AGENTS.md) باشد. در 2D، restore locked/build/test **تازه** با SDK 2.1.818 موفق شدند؛ build صفر warning/error و ۶۵ unit + ۴۳ integration، جمع ۱۰۸ موفق. شکست نخست کنترل case محیط با مقایسهٔ دقیق سازنده اصلاح شد؛ در شواهد ثبت است. smoke Kestrel تازه health/Swagger/404 snapshot را تأیید کرد؛ process آن متوقف شد. این integrationها حافظه‌ای/DI/TestServer هستند؛ SQL repository، permission runtime یا IIS را ثابت نمی‌کنند. package/lockfile/target، SQL scriptها و Frontend تغییر نکردند؛ کد reader داخلی و config/آزمون مرتبط اضافه شدند.

در گزارش بعدی درصد قبلی، سهم کسب‌شده و شاهد آن، درصد جدید و کار باقی‌مانده بیاید. سهم 2D با پیاده‌سازی و آزمون واقعی **17% + 2 = 19%**، باقی‌مانده ۸۱٪ است؛ نگهداری مستندات/بررسی gate امتیاز ندارند. برآورد مشروط 2E یک واحد تا ۲۰٪ است و مجوز شروع نیست. اجرای تاریخی را تازه معرفی نکنید و باقیماندهٔ SQL runtime را تکمیل‌شده ندانید.

مقصد مجاز `origin` برابر `https://github.com/AliKeramattii/vehicle-inspection-backend.git` است. [GITHUB_SYNC_FA.md](GITHUB_SYNC_FA.md) را پیش از push بخوانید: کاربر در `2026-11-01` حذف ZIP از تمام تاریخچهٔ ارسالی و نگهداری اصل فقط محلی را صریحاً مجاز کرد؛ SHAهای جدید با اصل متفاوت‌اند. `.gitignore` یا حذف فایل فقط در commit جدید، تاریخچه را پاک نمی‌کند. branch `local-original-history-2026-11-01` هرگز push یا merge به نسخهٔ انتشار نشود؛ `--all` و `--mirror` ممنوع‌اند. checkpointهای بعدیِ مجاز پس از validation و مرور تاریخچه به همین مقصد push و HEAD و فایل‌های remote بررسی شوند؛ تاریخچهٔ مستقل remote حفظ شود.
