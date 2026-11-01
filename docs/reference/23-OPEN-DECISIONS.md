# دفتر تصمیم‌های باز و تأییدنشده

همه موارد زیر بازند، مگر مسئول با نسخه، تاریخ و اثر قرارداد آن‌ها را تصویب کند. جزئیات پیشنهادی SQL/JSON به معنی تأیید نیست. برای هر تصمیم پاسخ، مسئول، نسخه OpenAPI/SQL، معیار پذیرش و پیوند تأیید ثبت شود.

| شناسه | تصمیم | مسئول | اثر مسدودکننده |
|---|---|---|---|
| D01 | OIDC code+PKCE یا بلیت یک‌بارمصرف؛ نقش OTP | هویت مبدأ و امنیت Backend | نشست، DTO ورود و replay |
| D02 | gateway هم‌origin یا CORS/cookie؛ callback/logout/CSRF | زیرساخت و امنیت | دسترسی امن موبایل و SSO |
| D03 | external/public/GUID، attempt/current و import قدیمی | Backend و مبدأ | FK، URL، scope و tracking |
| D04 | rowversion/ETag، idempotency، TTL/lease و in-flight ۲۰۲ | Backend | retry و concurrency |
| D05 | تصویب چیدمان فیزیکی `GUI_{CustomerId}/INSPECTION_{InspectionId}/{temporary,finalized}/{photos,videos}`؛ مالک محصول آن را ترجیح داده است. باقی‌مانده: پذیرش Backend، قالب شناسه بخش‌های مسیر، نام فایل، volume/ACL/backup و مهلت پاک‌سازی temporary ([فصل ۸](08-MEDIA-FILE-STORAGE.md)) | Backend و زیرساخت؛ ترجیح محصول ثبت شده | پیاده‌سازی ذخیره‌سازی فایل؛ ریشه مستقیم INSPECTION تاریخی است و مرجع اجرا نیست؛ Frontend و قرارداد API اثر نمی‌پذیرند |
| D06 | نسخه SQL، collation، migration و ۳۷ جدول پیشنهادی | معمار SQL و Backend | تصویب DDL و اختیار اجرا |
| D07 | MIME/codec/size/duration/quality، hash و resume | Backend و محصول | انتقال، processing و limits |
| D08 |۵۵ مسیر پیشنهادی، alias‌ها، DTO و schemaVersion | Frontend و Backend | OpenAPI؛ count نهایی تصویب نشده |
| D09 | فرمت/slot/limits برند، contrast و publication rollback | Backend و محصول | provider واحد تنظیمات |
| D10 | ظرفیت و ارجاع، Admin notes، reopen فیلد | عملیات، امنیت و محصول | Reviewer و scope |
| D11 | payload/auth/idempotency/ack/query مقصد و escalation | API بیمه و Backend | تحویل واقعی |
| D12 | retention، legal hold، delete، consent و restore | حقوقی، محصول و زیرساخت | فایل و تاریخچه |
| D13 | routing static، legacy URL و image strategy | محصول، Frontend و زیرساخت | export همچنان BLOCKED |
| D14 | داده محلی پس از logout، quota و PWA/update | امنیت، Frontend و محصول | دستگاه/offline بدون حذف بی‌اجازه |
| D15 | اعلان، رضایت، ETA و SLA | محصول و مبدأ | متن و زمان واقعی |
| D16 | Neshan مرکزی، origin restriction و reverse تولیدی | زیرساخت مرکزی | عدم افشای private key |
| D17 | اصلاح پس از final/forwarded در آینده | محصول و Backend | خارج جریان فعلی؛ unlock خودکار ممنوع |
| D18 | حقوق طرح بدنه سدان و کلیپ آموزشی cleared | حقوقی و محصول | CC BY4 همه حقوق ثالث را حل نمی‌کند |

Backend واقعی و Swagger هنوز تحویل نشده‌اند. SQL پیشنهاد review است و اجرا نشده. static export با شناسه dynamic مسدود است. auth/SSO، فایل خصوصی و تحویل نهایی باید از تیم Backend تأیید بگیرند. پذیرش Android/iOS، GPU، codec، quota و حقوق مدل مستقل است؛ ساخت معمول یا چک مستندات این موارد را نمی‌بندد.

گام بعدی جلسه تصویب قرارداد و پاسخ به [فصل ۱۹](19-BACKEND-TEAM-QUESTIONS.md) است. هیچ Backend development، طراحی تازه Frontend یا فاز دیگری از این دفتر به صورت خودکار شروع نمی‌شود.
