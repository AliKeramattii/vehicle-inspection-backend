# دفتر تصمیم‌های واقعاً باز

این دفتر پرسش تکراری دربارهٔ الزامات قطعی نیست. target 2.1، IIS، پایگاه موجود، پیشوندها، referral/OTP، fixtureها، فیلد trusted، `BAZDIDInfo`، ساختار رسانه و اولویت مشتری قطعی‌اند. پاسخ هر ردیف با مسئول، تاریخ، محیط و مرجع تأیید ثبت شود. در `2026-11-01` فقط 2A/2B و metadata محلی مجاز شدند؛ [شواهد آرشیو](DUBERFRONT_CODE_AUDIT_FA.md) و [کشف محلی](CHECKPOINT2A_2B_REPORT_FA.md) تأیید Production نیستند. DDL و 2C–2G همچنان به تصویب تازه نیاز دارند.

| شناسه | تصمیم/دادهٔ لازم و پیشنهاد فعلی | مسئول | زمان نیاز و اثر |
|---|---|---|---|
| O01 | نگاشت source-only برای `Duber.OrderSales`، رابطهٔ CustomerId و candidateهای موبایل یافت شد؛ تأیید schema/ستون/join جاری، eligibility و نسخهٔ منبع لازم است؛ جزئیات در ماتریس mapping و O20 تا O22 | کارگزاری و DBA | adapter واقعی؛ fixture مانع برنامه‌ریزی نیست |
| O02 | بخش محلی پاسخ داده شد: کاربر `(local)\SQLSERVER2019`، Windows Authentication و نام `BAZDID_Development` را تأیید کرد. metadata: `15.0.2000.5 / RTM`؛ چهار DB سیستمی با `150 / SQL_Latin1_General_CP1_CI_AS`. تست DB هنوز وجود ندارد؛ schema/recovery/فایل‌ها، دو حساب کم‌اختیار، patch/TLS و DDL بازند. نسخه/compatibility Production نامعلوم است | کاربر/DBA/زیرساخت | مرجع: پاسخ تکمیلی وظیفهٔ `66aec801-d9a2-4943-a6e3-418104144dba` در `2026-11-01`؛ قبل از هر DDL تست |
| O03 | نسخه Windows Server/IIS/ANCM و Runtime، effective child application path و اثر Hosting Bundle بر برنامه‌های موجود | زیرساخت IIS | smoke واقعی؛ Checkpoint 1 محلی مستقل پیش می‌رود |
| O04 | دامنه‌های واقعی HTTPS، origin/port مجاز و same-site/cross-site بودن، گواهی و proxy trusted | زیرساخت و امنیت | اتصال مرورگر و Checkpoint 9 |
| O05 | secret store، اختیار pool، key ring، گواهی/DPAPI، rotation/backup و چند instance | امنیت/زیرساخت | طراحی توسعه در Checkpoint 3؛ Production پیش از نشر |
| O06 | قرارداد SMS موجود: endpoint/auth، ارسال کد تولیدشدهٔ BAZDID، timeout، dedupe/receipt، sandbox و ظرفیت؛ Kavenegar در سورس قدیمی مشاهده شد و قرارداد مصوب BAZDID محسوب نمی‌شود | تیم سرویس کارگزاری | adapter واقعی؛ verify همچنان مسئول BAZDID؛ بدون انتقال کلید آرشیو |
| O07 | TTL چالش/نشست، attempts، cooldown و سقف پنجره/IP؛ پیشنهاد تست: OTP ۱۲۰ثانیه/۵تلاش/۶۰ثانیه، نشست idle۳۰دقیقه/absolute۸ساعت | مالک/امنیت | قبل از Checkpoint 3 در همان محیط؛ Production جدا |
| O08 | طول/قدرت OTP Production و UX؛ پنج‌رقمی بودن فقط fixture/Front current است | امنیت/محصول/Frontend | قبل از adapter Production؛ تغییر طول نیاز به قرارداد UI |
| O09 | سال از `CarYearSakht.Name` رشته است، نه FK عددی؛ تقویم/تجزیه، تفاوت `VinNumber/ShasiNumber`، نیاز full VIN، رنگ، پلاک رشته‌ای، سقف کیلومتر، InvalidSource و ZeroMeansMissing هر فیلد باید مصوب شوند | مالک محصول و کارگزاری | mapping پیش از reader واقعی؛ قرارداد Checkpoint 4/5؛ صفر کیلومتر معتبر است |
| O10 | DTO اطلاعات ناقص/منشأدار، جایگزینی mobile در auth mock، colorId/discrepancy، status mapping و نسخهٔ contract | Frontend/Backend | پیش از اتصال checkpointهای 3/4؛ هیچ تغییر Frontend اینجا انجام نمی‌شود |
| O11 | محدودیت عکس/ویدیو/مدت/codec/ابعاد/quota و ابزار validation/scan مصوب | محصول/امنیت/زیرساخت | policy تست پیش از Checkpoint 6؛ policy Production پیش از نشر |
| O12 | drive/root واقعی storage، same volume، ACL، ظرفیت، shared storage و روش اجرای reconcile خارج وابستگی IIS timer | زیرساخت | قبل از upload محیط مربوط |
| O13 | retention، legal hold، حذف، log/IP، backup هماهنگ، RPO/RTO و آزمون restore | حقوقی/محصول/زیرساخت | پیش از پاک‌سازی یا Production؛ اکنون TTL قانونی اختراع نمی‌شود |
| O14 | نسخهٔ شرایط رضایت و scope پذیرش، متن خطا/receipt/tracking و سیاست freshness منبع | محصول/کارگزاری | قبل از Checkpoint 5/7؛ نسخهٔ جاری Front `2026-10` صرفاً شاهد کد |
| O15 | bootstrap اولیه Admin، credential محلی/SSO کارکنان، MFA، password policy و بازیابی آخرین مدیر | امنیت/مالک | Checkpoint 8؛ وجود مدیر و جدول `BAZDIDAdmin` قطعی است |
| O16 | assignment/capacity/correction و contract مقصد بیمه/ack/query/idempotency؛ اعلان و SLA در صورت نیاز | عملیات/تیم بیمه | Checkpoint 8؛ blocker مشتری نیست |
| O17 | انتخاب foundation انجام شد: App 2.1.30، Newtonsoft 13.0.4، Swagger 4.0.1 و ابزار تست نسخه‌دار؛ restore/build/run و ۴۳ آزمون موفق؛ audit با هشدار باقی است | Backend/امنیت | سازگاری محلی بسته شد؛ remediation/پذیرش امنیت Production همچنان باز و مرتبط با O18 |
| O18 | risk acceptance رسمی EOL و برنامه/مسئول/موعد مهاجرت به پشتهٔ دارای پشتیبانی | مالک/امنیت/زیرساخت | الزام پیش از انتشار عمومی |
| O19 | وضعیت static export کامل Frontend و reverse map مرکزی در topology واقعی | تیم Frontend/زیرساخت مرکزی | پذیرش integration؛ خارج تغییرات این مخزن |
| O20 | کدام context/پایگاه authoritative است؟ `DuberContext` و `irisdbContext` هر دو `Duber.OrderSales` دارند؛ schema/table مشتری و lookupها، نوع/nullability فیزیکی و حوزهٔ یکتایی شناسه‌ها تأیید نشده‌اند | DBA/کارگزاری | پیش از SQL reader؛ metadata حداقلی و دسترسی SELECT مصوب، بدون fallback حدسی |
| O21 | کد معرفی درخواست کجا صادر و نگهداری می‌شود و چگونه منتقل/حل می‌شود؟ شش‌کاراکتری بودن، case، uniqueness، انقضا و رابطهٔ دقیق آن با Id باید تعیین شوند؛ تخفیف/پرداخت/پست/نمایش verifyOrder پاسخ این پرسش نیست | مالک محصول/کارگزاری | پیش از resolver واقعی؛ `A4K9P2` فقط fixture مستقل باقی می‌ماند |
| O22 | کدام‌یک از `Customer.Mobile/OrderSales.Mobile` مرجع معتبر OTP است؟ اولویت، verified بودن، درخواست فاقد مشتری، شمارهٔ متعارض، تغییر مالک و سیاست freshness باید مصوب شوند | کارگزاری/امنیت/محصول | قبل از OTP واقعی؛ موبایل ورودی مشتری جایگزین نمی‌شود و وضعیت مبهم fail-closed است |
| O23 | بررسی امنِ اعتبار و لزوم گردش credentialهای موجود در آرشیو، به‌ویژه اتصال‌ها و تنظیمات پیامک؛ وضعیت فعال‌بودن معلوم نیست و هیچ مقدار منتقل یا آزمایش آنلاین نشده است | مالک سامانه/امنیت | رسیدگی جداگانه از طریق کانال امن؛ انتشار سورس یا راز برای تکمیل ممیزی لازم نیست |
| O24 | pin پیشنهادی `System.Data.SqlClient 4.8.6` target صریح netcoreapp2.1 دارد، اما از قید `[4.5.3,4.6.0)` framework فعلی خارج است؛ روش حل سازگار گراف، تمام انتقالی‌ها/SNI و audit/آزمون واقعی باید پیش از افزودن بسته نهایی شوند. نسخهٔ فعلی 4.5.3 تغییر نکرده است | Backend/امنیت | gate شروع پیاده‌سازی SQL در 2C؛ هیچ warning dependency پنهان نشود و هیچ پشتیبانی امنیتیِ جدید ادعا نشود |
| O25 | تصویب schema سه جدول/کلیدهای بایتی شناسه، collation، طول‌ها، HMAC/keyIdها و نقش‌ها؛ سپس اجازهٔ صریح ساخت `BAZDID_Development` و اجرای scriptهای بازبینی‌شده. حساب sysadmin کشف، account برنامه نیست | مالک/DBA/امنیت | scriptها فقط پیش‌نویس با flag صفر؛ تغییر flag جای تصویب نیست؛ آماده‌سازی 2B معادل provision محیط نیست |

## پیشنهادهای معماری منتظر بازبینی بستهٔ Phase 0

یک پروژهٔ API با دو پروژهٔ تست، ADO.NET پارامتری، ۱۷ جدول تدریجی، manifest قالب ثابت و snapshot به‌جای مدیریت قالب کامل، منشأهای ستونی Info، cookie با SQL ticket store، ادغام فرمان‌های ویرایش خودرو در information و whole-file retry پیشنهاد شده‌اند. این‌ها الزامات ازپیش‌تأییدشده معرفی نمی‌شوند. اگر بازبینی آن‌ها را تغییر داد، PLAN و docs مرتبط در یک تغییر همسو اصلاح شوند.

2A/2B در دامنهٔ بررسی/آماده‌سازی تکمیل می‌شوند؛ گام بعدی **2C** پس از بازبینی و تصویب صریح اجراست. O02/O24/O25 برای محیط و SQL client و O01/O20–O22 برای reader واقعی بازند. fixture تست بعداً در scope مصوب می‌تواند مستقل از منبع واقعی ساخته شود. O03/O18 پیش از انتشار واقعی باقی می‌مانند؛ [audit امنیت foundation](checkpoint1/DEPENDENCY_SECURITY_FA.md) پاک نشده است. پیشرفت وزنی اکنون `15%` و برآورد مشروط پس از 2C برابر `17%` است؛ OTP، SQL repository و migration خودکار مجوز ندارند.
