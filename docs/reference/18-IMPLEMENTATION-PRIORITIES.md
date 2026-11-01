# ترتیب پیاده‌سازی وابسته و معیار تحویل

مسیرها و جدول‌ها پیشنهادی‌اند و زمان‌بندی ثابت ندارند. قبل از هر گام، قرارداد OpenAPI و تصمیم‌های مسدودکننده همان گام تصویب شود. عملیات مشترک نباید در چند سرویس تکراری پیاده شوند.

| گام | API و مسئولیت | جدول و زیرساخت | پذیرش و وابستگی |
|---|---|---|---|
| ۰ | توافق قرارداد، شناسه‌ها، SSO، میزبانی و خطا/نسخه | دفتر تصمیم‌های فصل ۲۳ و بازبینی schema | مسئول هر تصمیم، نمونه ساختگی و معیار پذیرش مشخص باشد |
| ۱ | P00/P01 و AU01 تا AU07؛ هویت و context | Customers، SourceInsuranceRequests، StaffUsers/StaffRoleAssignments و idempotency | بلیت معتبر، شماره فقط‌خواندنی، منع replay، جداسازی نصب، expiry و logout |
| ۲ | I01 تا I10، current/list و capture-plan | Inspections، Templates/Requirements/Alternatives، Vehicles، Locations و Consents | تلاش جاری یکتا، pin ثابت، ۱۱ عکس و سازگاری تاریخی، قفل حقایق |
| ۳ | EV01 تا EV06 و I11 | Evidence/Versions، MediaFiles، UploadSessions، OdometerReadings و ProcessingJobs | pipeline مشترک، stream محدود، hash/size، receipt، Range و بازیابی crash |
| ۴ | I12 تا I14؛ summary/submit/status | Submissions، SubmissionEvidence، StatusHistory و IdempotencyRecords | آمادگی سروری، سیاست processing، دوبار ارسال، offline و refresh |
| ۵ | RV01 تا RV09 و I04/AD01 | Assignments، StaffOperationsSettings، EvidenceReviews، InspectionReviews و InternalNotes | ارجاع و ظرفیت، CAS، یادداشت خصوصی، تصمیم نسخه و تصمیم کل جدا |
| ۶ | R01 تا R04 و I15 | CorrectionRequests/Items و رسیدهای دور اصلاح | اصل محفوظ، قلم دقیق، VIN واحد، تلاش خالی تازه پس از رد کامل |
| ۷ | AD02 تا AD11 و سازگاری F09 | Settings/Versions/AssetLinks، BrandingAssets، StaffRoles و Webhooks | provider واحد، draft/publish، قالب ۱۱، نقشه مرکزی و سلامت واقعی |
| ۸ | G02/G03 و FW01 | ForwardingJobs/Attempts و outbox | تأیید کل و job اتمیک، retry همان key، موفقیت فقط با ack |
| ۹ | G01 و پایش | NotificationOutbox اختیاری، audit و metrics امن | کانال و متن مصوب؛ نبود SMS مانع خواندن وضعیت نیست |
| ۱۰ | پذیرش static و API واقعی | artifact، ASP.NET/IIS، SQL و پشتیبان فایل | شناسه دلخواه، deep link/refresh، نشست، رسانه و بازیابی واقعی |

مرز کد هر عملیات در فصل ۴ و ۲۰ است. کلاینت ابتدا پشت interface موجود جایگزین شود؛ ساخت UI یا pipeline موازی جزو برنامه نیست. server truth از Query/repository مصرف شود؛ Blob/queue محلی و تاریخچه نسخه‌ها حفظ شوند. مشکل اتصال با reset یا پاک‌کردن IndexedDB حل نشود.

خروجی هر گام باید شامل OpenAPI نسخه‌دار، DTO/خطای نمونه، تست امنیت/قرارداد/هم‌زمانی، migration/rollback مصوب، پایش و fixture ساختگی باشد. static migration و حقوق انتشار مدل، milestone مستقل‌اند؛ موفقیت ساخت معمول هیچ‌کدام را تأیید نمی‌کند.
