# چک‌لیست تحویل واقعی Backend

این چک‌لیست معیار پذیرش آینده است، نه ادعای اینکه API ها اکنون اجرا شده‌اند. هر مورد با نسخه قرارداد، محیط، مسئول و نتیجه آزمون ثبت شود. checkbox تعاملی از مشتری درخواست نمی‌شود.

| حوزه | خروجی لازم | شاهد پذیرش |
|---|---|---|
| قرارداد | OpenAPI نسخه‌دار، DTO ها، خطا و نمونه‌ها | پوشش ۶۳ عملیات بدون endpoint رقیب برای alias ها |
| هویت | نشست واقعی مبدأ، بلیت/OIDC مصوب، logout و expiry | replay، tenant دیگر، subject/request دیگر و دستکاری شماره رد شوند |
| پایگاه | migration و rollback مصوب، FK/UNIQUE/CHECK/index | ساخت روی پایگاه disposable مجاز تیم Backend، نه دیتابیس موجود مشتری |
| قالب | pin نسخه، ۱۰ ثابت + یک VIN، ویدیوی جدا | هر چهار گزینه به تنهایی پذیرفته؛ engine-bay مستقل؛ legacy ۱۲ خوانا |
| رسانه | stream محدود، signature/hash، مسیر خصوصی، receipt | interruption، فایل مفقود، crash بین فایل و SQL، Range و permission |
| صف | lease/idempotency/reconcile | refresh، offline/online و job کهنه نسخه فعلی را خراب نکند |
| submit | snapshot اتمیک، قفل و receipt | دوبار ارسال و پاسخ گم‌شده یک نتیجه بدهند؛ queued/failed مانع باشد |
| کارشناس | ارجاع/ظرفیت، تصمیم نسخه، قلم اصلاح، تصمیم کل | ارجاع لغوشده، revision کهنه و scope اضافه رد شوند |
| رد کامل | تلاش خالی تازه با فرمان مالک | tracking/history و فایل قدیمی حفظ شوند |
| تنظیمات | provider واحد، draft/publish، برند و audit | مشتری دیگر انتشار را بخواند؛ private Neshan قابل ویرایش نباشد |
| تحویل مقصد | outbox/lease، کلید ثابت و ack معتبر | timeout بعد از دریافت مقصد duplicate نسازد؛ تأیید Reviewer با FORWARDED یکی نباشد |
| عملیات | log امن، metrics، backup/restore، retention hold | root/credential/PII در log و response نباشند؛ restore فایل و SQL همسو |
| میزبانی | راهبرد static/deep link/runtime IDs مصوب | refresh و direct URL شناسه تصادفی، auth، asset404 و mediaRange واقعی |
| یکپارچگی | adapter ها واصلاحات partial بدون بازنویسی UI | test قرارداد، tenant، device و end-to-end روی محیط توافق‌شده |

## حد تحویل این مستندات

در این task هیچ DDL اجرا، API پیاده یا migration static انجام نمی‌شود. صحت syntax/نمونه/لینک جای آزمون امنیت یا کارایی SQL را نمی‌گیرد. سرویس‌ورکر، codec واقعی iOS/Android، retention قانونی وحقوق طرح بدنه مستقل از قبولی Markdown هستند.

## ثبت اختلاف و عیب‌یابی

۴۰۱ به بازیابی نشست، ۴۰۳/۴۰۴ به scope، ۴۰۹/۴۱۲ به بازخوانی نسخه و ۴۱۳/۴۱۵/۴۲۲ به اصلاح ورودی می‌روند؛ tight retry ممنوع است. برای پاسخ نامطمئن submit/complete/forward از همان هویت فرمان و query/replay نتیجه استفاده شود. اصل خوب با خطای save یا job قدیمی حذف نشود. نبود فایل واقعی، موفقیت fake یا verified نیست.
