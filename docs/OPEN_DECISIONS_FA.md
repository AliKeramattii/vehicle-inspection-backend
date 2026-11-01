# دفتر تصمیم‌های واقعاً باز

این دفتر پرسش تکراری دربارهٔ الزامات قطعی نیست. target 2.1، IIS، پایگاه موجود، پیشوندها، referral/OTP، fixtureها، فیلد trusted، `BAZDIDInfo`، ساختار رسانه و اولویت مشتری قطعی‌اند. پاسخ لازم هر ردیف همراه مسئول، تاریخ، محیط، نسخهٔ قرارداد و پیوند تأیید ثبت شود. Checkpoint 1 در `2026-11-01` صریحاً مجاز و محلی تکمیل شد؛ پاسخ‌های Production زیر همچنان بازند.

| شناسه | تصمیم/دادهٔ لازم و پیشنهاد فعلی | مسئول | زمان نیاز و اثر |
|---|---|---|---|
| O01 | mapping جدول/ستون/join، uniqueness referral، وضعیت مجاز درخواست، trusted mobile و نسخهٔ منبع؛ اکنون همه نامعلوم | کارگزاری و DBA | adapter واقعی؛ fixture مانع برنامه‌ریزی نیست |
| O02 | نسخه SQL، compatibility، collation، schema اشیای BAZDID و پایگاه/حساب تست مصوب | DBA/زیرساخت | قبل از DDL تست در Checkpoint 2 |
| O03 | نسخه Windows Server/IIS/ANCM و Runtime، effective child application path و اثر Hosting Bundle بر برنامه‌های موجود | زیرساخت IIS | smoke واقعی؛ Checkpoint 1 محلی مستقل پیش می‌رود |
| O04 | دامنه‌های واقعی HTTPS، origin/port مجاز و same-site/cross-site بودن، گواهی و proxy trusted | زیرساخت و امنیت | اتصال مرورگر و Checkpoint 9 |
| O05 | secret store، اختیار pool، key ring، گواهی/DPAPI، rotation/backup و چند instance | امنیت/زیرساخت | طراحی توسعه در Checkpoint 3؛ Production پیش از نشر |
| O06 | قرارداد SMS موجود: endpoint/auth، ارسال کد تولیدشدهٔ BAZDID، timeout، dedupe/receipt، sandbox و ظرفیت | تیم سرویس کارگزاری | adapter واقعی؛ verify همچنان مسئول BAZDID |
| O07 | TTL چالش/نشست، attempts، cooldown و سقف پنجره/IP؛ پیشنهاد تست: OTP ۱۲۰ثانیه/۵تلاش/۶۰ثانیه، نشست idle۳۰دقیقه/absolute۸ساعت | مالک/امنیت | قبل از Checkpoint 3 در همان محیط؛ Production جدا |
| O08 | طول/قدرت OTP Production و UX؛ پنج‌رقمی بودن فقط fixture/Front current است | امنیت/محصول/Frontend | قبل از adapter Production؛ تغییر طول نیاز به قرارداد UI |
| O09 | سال شمسی/میلادی، VIN استاندارد یا شاسی قدیمی، full VIN لازم یا خیر، enum رنگ، پلاک غیرمعمول، سقف کیلومتر و InvalidSource | مالک محصول و کارگزاری | قرارداد Checkpoint 4/5؛ رفتار حدسی ممنوع |
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

## پیشنهادهای معماری منتظر بازبینی بستهٔ Phase 0

یک پروژهٔ API با دو پروژهٔ تست، ADO.NET پارامتری، ۱۷ جدول تدریجی، manifest قالب ثابت و snapshot به‌جای مدیریت قالب کامل، منشأهای ستونی Info، cookie با SQL ticket store، ادغام فرمان‌های ویرایش خودرو در information و whole-file retry پیشنهاد شده‌اند. این‌ها الزامات ازپیش‌تأییدشده معرفی نمی‌شوند. اگر بازبینی آن‌ها را تغییر داد، PLAN و docs مرتبط در یک تغییر همسو اصلاح شوند.

Checkpoint 1 با اجازهٔ کاربر انجام شد؛ گام بعدی **Checkpoint 2** اجازهٔ تازه و پاسخ O02 برای پایگاه تست می‌خواهد. O01 برای adapter واقعی لازم است، اما fixture تست بعداً می‌تواند مستقل از آن ساخته شود. O03 و O18 قبل از انتشار واقعی باز می‌مانند. [گزارش اجرا](CHECKPOINT1_IMPLEMENTATION_FA.md) و [audit واقعی](checkpoint1/DEPENDENCY_SECURITY_FA.md) مرجع وضعیت فعلی‌اند؛ هیچ جدول یا OTP به‌طور خودکار شروع نمی‌شود.
