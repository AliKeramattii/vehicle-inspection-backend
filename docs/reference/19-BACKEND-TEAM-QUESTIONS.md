# پرسش‌های لازم برای تصویب قرارداد

برای هر پاسخ، مسئول، محیط، نسخه قرارداد، نمونه ساختگی و اثر پذیرش ثبت شود. تصمیم تأییدنشده نباید با فرض ضمنی بسته شود.

## تیم ASP.NET Core و پایگاه

۱. کدام API‌ها واقعاً موجودند؟ OpenAPI، نسخه، نمونه خطا و محیط تست کجاست؟
۲. نسخه پشتیبانی‌شده .NET/SQL Server، compatibility و collation چیست؟ مالک migration و rollback کیست؟
۳. publicId، GUID داخلی، request/attempt/tracking و داده تاریخی چگونه نگاشت می‌شوند؟ آیا هر تلاش همان inspection مستقل است؟
۴. session store، cookie، expiry/renewal/logout/revocation و Data Protection در چند instance چگونه‌اند؟
۵. scope و طول عمر Idempotency-Key، hash بدنه، lease، پاسخ in-flight و replay پس از timeout چگونه‌اند؟
۶. CAS با expectedVersion یا If-Match است؟ ETag و تفاوت ۴۰۹/۴۱۲/۴۲۸ چگونه تثبیت می‌شود؟
۷. private root، volume، ACL، scanner، quota، backup/restore و کنترل reparse چه مسئول و پایشی دارند؟
۸. آیا چیدمان مرجح محصول `GUI_{CustomerId}/INSPECTION_{InspectionId}/{temporary,finalized}/{photos,videos}` با قالب شناسه، نام فایل، volume و مهلت پاک‌سازی temporary پیشنهادی فصل ۸ تصویب می‌شود (D05)؟
۹. allowlist فرمت/codec، حد بایت/ابعاد/مدت، limits میزبان و تکلیف HEIC/AVIF چیست؟
۱۰. stream، resume، hash مشتری/سرور، expiry/renewal مجوز و رسید durable چگونه قرارداد می‌شوند؟
۱۱. worker و پروفایل پردازش، سقف CPU/memory/timeout، quarantine و خطای پردازش چگونه‌اند؟
۱۲. دریافت خصوصی، Range، thumbnail و history چه مجوز/cache دارند؟ آیا signed URL واقعاً لازم است؟
۱۳. تراکنش ظرفیت/ارجاع/تصمیم/snapshot/outbox و crash reconciliation چگونه تست می‌شوند؟
۱۴. audit، redaction، metrics، retention لاگ، monitoring و alert چه مالکی دارند؟
۱۵. Neshan و public settings چگونه provision می‌شوند و private key در کدام مرز مرکزی می‌ماند؟
۱۶. static artifact، gateway، CORS/CSRF/cookie، domain/HTTPS و استثنای API از fallback چه قراردادی دارند؟
۱۷. کانال، رضایت و متن اعلان چیست؟ شکست اعلان چه وضعیت عملیاتی دارد؟

## تیم API و هویت سامانه بیمه

۱. شناسه issuer/subject/customer، sourceRequest و خودرو چیست؟ چند درخواست و تلاش چگونه تشخیص داده می‌شوند؟
۲. مشتری با OIDC یا بلیت معتبر سرور وارد می‌شود؟ امضا/JWKS/introspection، audience، expiry، nonce/state و replay store چیست؟
۳. SSO کارکنان چه پروتکلی دارد؟ callback/logout، PKCE، گروه/نقش و تعلیق کاربر چگونه اعلام می‌شوند؟
۴. آیا شماره تنها از مبدأ خوانده می‌شود؟ OTP تکمیلی لازم است؟ طول، نرخ، cooldown و gateway پیامک چیست؟
۵. gateway هم‌origin ممکن است؟ محدودیت cookie در موبایل چیست و چه return URL هایی مجازند؟
۶. API مقصد، schema داده، authentication و allowlist مصوب چیست؟
۷. معنای ۲۰۰/۲۰۲/۲۰۴ مقصد، acknowledgementId/time و query نتیجه نامطمئن چیست؟
۸. آیا DeliveryKey، replay و conflict در مقصد پشتیبانی می‌شوند؟
۹. انتقال فایل، codec، سقف اندازه و نسخه approved مدنظر مقصد چیست؟ کیلومتر عددی چگونه دریافت می‌شود؟
۱۰. آیا اصلاح جزئی، تلاش تازه پس از رد و کد پیگیری باید به مبدأ اعلان شوند؟
۱۱. sandbox، داده ساختگی و مسئول تست end-to-end کدام‌اند؟
۱۲. سیاست دسترسی، نگهداری، حذف و backup میان دو سامانه چیست؟

## صاحب محصول، حقوقی و عملیات

۱. retention هر مرحله، legal hold و شرایط حذف مجاز چیست؟
۲. سقف کسب‌وکاری کیلومتر، تقویم سال خودرو و قالب پلاک متفاوت چگونه‌اند؟
۳. حداقل/حداکثر ویدیو و معیار خوانایی VIN/پلاک چیست؟ هدف ۶۰ ثانیه فعلی فقط راهنماست.
۴. شرایط، نسخه consent، رضایت اعلان، متن ETA و SLA واقعی چیست؟۳ تا ۵ روز کاری فعلی برآورد محصول است.
۵. آیا Admin حق خواندن یادداشت خصوصی یا بازگشایی پیشنهاد فیلد را دارد؟
۶. اعلان اختیاری الزامی می‌شود؟ کانال و متن شکست/موفقیت آن چیست؟
۷. پیشنهاد static routing، query context و سازگاری لینک‌های قبلی تأیید می‌شوند؟
۸. مسئول بررسی حقوق طرح بدنه سدان کیست؟ CC BY4 به تنهایی تمام حقوق ثالث را حل نمی‌کند.
۹. کلیپ آموزشی سدان با حقوق روشن از کجا تأمین می‌شود؟ ghost عکس جانشین ویدیو نیست.
۱۰. سیاست IndexedDB پس از خروج، تعویض کاربر و ارسال، بدون حذف بی‌اجازه مدرک خوب چیست؟

پاسخ‌ها با شناسه تصمیم، تأییدکننده و نسخه قرارداد در [فصل ۲۳](23-OPEN-DECISIONS.md) ثبت شوند.
