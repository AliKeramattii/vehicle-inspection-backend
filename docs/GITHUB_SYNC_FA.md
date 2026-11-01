# اتصال GitHub و سیاست انتشار امن

تاریخ `2026-11-01`؛ دامنهٔ این وظیفه فقط Git و مستندات است. Checkpoint 1 تکمیل شده و Checkpoint 2 شروع نشده است. رفتار برنامه، endpoint و SQL تغییری نمی‌کنند.

## مقصد و نتیجهٔ بررسی اولیه

مخزن موجود و عمومی [AliKeramattii/vehicle-inspection-backend](https://github.com/AliKeramattii/vehicle-inspection-backend) مقصد مجاز است؛ مخزن دیگری ساخته نشده است. `origin` به `https://github.com/AliKeramattii/vehicle-inspection-backend.git` وصل شد. fetch و `ls-remote` موفق و فاقد refs بودند؛ remote در آغاز خالی و default branch معرفی‌شدهٔ GitHub برابر `main` بود.

HEAD اولیه `3c52503b345d3bc782feda8a5ca6effadb4ce65a` و branch محلی `main` بود؛ worktree پاک بود. هر چهار commit `196c000`، `1029465`، `2187316` و `3c52503` در زنجیرهٔ تاریخچه وجود داشتند.

اتصال GitHub حساب `AliKeramattii` و metadata دسترسی push/admin به همین مخزن را تأیید کرد. endpoint جداگانهٔ permission collaborator با محدودیت integration، 403 داد؛ این خطا با نبود دسترسی مخزن یکسان نیست. `gh auth status` ورود CLI را تأیید نکرد؛ نتیجهٔ واقعی transport Git باید مستقل بررسی شود. هیچ token یا credential در متن/فرمان/گزارش ذخیره نمی‌شود.

## تعارض تاریخچه و مجوز صریح کاربر

در commit اولیه، `docs/reference/BACKEND_HANDOVER_ESSENTIAL_FA.zip` وجود دارد؛ blob آن `9a0bf21f6dc0cfa1288e4070ecda04270863e5cd` است. انتشار کامل همان تاریخچه، با منع ZIP در درخواست جدید ناسازگار بود. حذف فایل فقط در HEAD یا افزودن ignore، نسخهٔ تاریخی را از push حذف نمی‌کند.

پس از توضیح این تعارض، کاربر صریحاً انتخاب کرد: **«تاریخچهٔ ارسالی پاک‌سازی شود؛ نسخهٔ اصلی فقط محلی بماند»**. بنابراین SHAهای اصلی قرار نیست روی GitHub باقی بمانند. نسخهٔ اصلی در branch محلی `local-original-history-2026-11-01` نگهداری می‌شود؛ این branch هرگز push نمی‌شود. نسخهٔ ارسالی فقط ZIP را از tree تمام commitها حذف می‌کند و پیام، ترتیب، author/committer و تاریخ commitهای اصلی را حفظ می‌کند. `main` جدید، نسخهٔ قابل انتشار خواهد بود؛ force push یا بازنویسی remote لازم نیست چون remote خالی است.

نقشهٔ SHA قدیم/جدید پس از اجرای export ثبت می‌شود. وجود original SHA در یک سند، به معنی وجود آن commit یا blob خصوصی در GitHub نیست. فایل ZIP برای مطالعهٔ محلی می‌تواند در مسیر ignored باقی بماند؛ نه خود فایل و نه تاریخچهٔ حامل آن مجاز به ارسال نیستند.

## بررسی امنیت پیش از انتشار

چهار commit اولیه، ۱۱۳ blob یکتا، نام فایل‌ها و محتوای متنی ۱۲ عضو ZIP بدون استخراج بررسی شدند. هیچ private key، provider token، SQL password، مقدار واقعی HMAC/API secret، فایل env واقعی، certificate خصوصی، media، backup یا bin/obj شناسایی نشد. تنها candidate مربوط به credential URI، مقدار ساختگی `user:password` در آزمون `FoundationOptionsTests.cs` روی دامنهٔ `.invalid` است؛ credential عملیاتی نیست.

شماره‌های موبایلِ شبیه PII فقط در mapping توسعه و مثال‌های مرجع دیده شدند؛ mapping آن را fixture و `contracts/examples.json` همهٔ مثال‌ها را ساختگی معرفی می‌کند. دادهٔ واقعی مشتری یا source اختصاصی Backend کارگزاری در این مخزن تحویل نشده است؛ فایل‌های SQL مرجع proposal هستند. این بررسی مبتنی بر الگو و بازبینی context است و تضمین مطلقِ نبود همهٔ انواع راز نیست.

ریسک آسیب‌پذیری dependencyهای پشتهٔ EOL قبلاً در [گزارش امنیت Checkpoint 1](checkpoint1/DEPENDENCY_SECURITY_FA.md) ثبت شده و با این کار رفع نمی‌شود. عمومی‌شدن source، تأیید عمومی‌بودن سرویس Production نیست.

## وضعیت اجرا

- [x] تاریخچه، branch، status، ignore و گزارش‌ها بررسی شدند.
- [x] origin تنظیم و remote خالی fetch شد.
- [x] سیاست اجباری گزارش نهایی فارسی با ۱۳ دسته در AGENTS، README و ادامهٔ AI ثبت شد.
- [x] مجوز پاک‌سازی تاریخچهٔ ارسالی با حفظ اصل فقط محلی دریافت شد.
- [ ] export پاک‌شده و نقشهٔ SHAها ساخته و بررسی شود.
- [ ] کل تاریخچهٔ قابل ارسال بدون ZIP دوباره اسکن شود.
- [ ] push معمولی فقط `main` و راستی‌آزمایی remote و فایل‌ها انجام شود.

تا زمانی که دو مورد آخر بررسی نشده‌اند، این سند ادعای upload موفق ندارد. نتایج نهایی در همین بخش تکمیل می‌شوند.

## ادامهٔ امن

checkpointهای بعدیِ مجاز و اعتبارسنجی‌شده به همین مخزن commit/push شوند. پیش از ارسال، fetch، URL، تغییرات و تمام تاریخچهٔ reachable **همان branch ارسالی** بررسی شوند؛ branch اصلیِ صرفاً محلی نباید وارد بررسی به‌عنوان محتوای مجاز ارسال شود. `git push --all`، `git push --mirror` و ارسال branch `local-original-history-2026-11-01` ممنوع‌اند. هیچ tag یا ref حامل تاریخچهٔ خصوصی منتشر نشود.

force push، حذف commit remote، reset مخرب، ایجاد مخزن دیگر و شروع Checkpoint 2 مجاز نیستند. در تعارض تاریخچهٔ تازهٔ remote، ابتدا آن را حفظ و راهکار امن branch/PR یا merge را بررسی کنید. گزارش نهایی هر وظیفه فارسی و دارای نتیجهٔ واقعی Git/test/build و وضعیت مرحله باشد. این وظیفه چون فقط Git/مستندات است، تست اجرایی تازه نمی‌طلبد؛ ۴۳ آزمون Checkpoint 1 نتیجهٔ تاریخی است، نه اجرای دوبارهٔ این وظیفه.
