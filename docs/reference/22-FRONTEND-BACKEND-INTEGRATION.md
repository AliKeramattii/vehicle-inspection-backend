# اتصال Frontend موجود به Backend

## اصل اتصال

UI یا pipeline رسانه از نو ساخته نمی‌شود. DTO تولیدشده از OpenAPI مصوب پشت repository/adapter به domain فعلی نگاشت می‌شود؛ transport وارد JSX نمی‌شود. TanStack Query مرجع server truth، Zustand وضعیت موقت و IndexedDB محل Blob/queue است. entity سرور در Zustand تکثیر نشود.

| مرز فعلی | جایگزینی پیشنهادی |
|---|---|
| CustomerSourceAdapter و StaffSessionAdapter | زمینه نشست معتبر ASP.NET، نه phone/role در URL |
| AuthRepository و InspectionRepository | client تایپ‌شده، اعتبارسنجی response و خطای فیلد |
| loader/provider و SiteSettingsRepository | تنها public/draft/publication، با binding نصب یکسان |
| CaptureDataStore و facts | sync کیلومتر و حقایق، بدون فایل جعلی |
| UploadTransport | register/stream/complete/reconcile مشترک و job/revision ثابت |
| SubmissionService و RequestService | receipt سروری idempotent و scope دقیق اصلاح |
| ReviewRepository و AdminRepository | query/mutation مجاز، CAS، pagination و خطای واقعی |
| status و forwarding projection | حقیقت سرور و موفقیت مقصد فقط با ack معتبر |

فایل مرز هر عملیات در فصل ۴/۲۰ است. `src/lib/api/endpoints.ts` قراردادهای planned اولیه دارد؛ همه مسیرهای فصل ۵ در آن پیاده نشده‌اند. بعد از تصویب، URL/base متمرکز و `/api/bazdid` فقط یک‌بار اضافه شود.

## ترتیب امن

۱. ابتدا auth/session/public settings را با base، cookie، CORS، CSRF و نسخه مصوب متصل کنید؛ نشست mock نباید در production فعال بماند.
۲. شناسه خارجی/داخلی و template/policy پین‌شده را نگاشت کنید. spec-plate همان logical ID و alternative فیلد جداست؛ داده تاریخی نسخه ۱ همچنان خوانده می‌شود. ID در UI opaque می‌ماند.
۳. ثبت مدرک را با job/revision ثابت متصل کنید. expiry یا refresh نباید remoteEvidenceId یا Blob جدید بسازد. قرارداد سرور و domain در تست کنار هم بررسی شوند.
۴. آمادگی summary، receipt، submitted lock، correction round، تصمیم کارشناس و forwarding truth به ترتیب وابستگی جایگزین شوند. projection محلی نباید وضعیت نهایی سرور را به DRAFT برگرداند.
۵. انتشار برند بین دستگاه‌ها تست شود. نشان همان مرز مرکزی، عکاسی همان ۲D و مدل اختیاری همان دارایی مشترک با gate حقوقی می‌ماند.

## حفظ داده و rollback

نسخه schema/policy/revision مرجع است. پنجره سازگاری پیش از rollout توافق شود. reset IndexedDB، پاک‌کردن صف، بازنویسی accepted یا migrate خودکار پرونده ۱۲ عکسی مجاز نیست. rollback باید با DTO/قالب/receipt موجود سازگار باشد و تاریخچه/DB را rewind نکند. chunk قبلی برای tab باز نگه داشته شود.

upload و verification جدا map می‌شوند؛ processing، verified نیست و کیلومتر فایل نیست. ناسازگاری schema به خطای روشن و بازیابی امن نیاز دارد، نه cast به any یا fallback خاموش به mock. telemetry گواه هویت یا تحویل نیست و داده محرمانه ندارد.

## پیش‌شرط انتشار

پایان feature، اتصال API، مهاجرت static و production clearance جدا گزارش شوند. proof فعلی GLB static، قبولی static کل Next یا گوشی واقعی نیست. پیش از تولید، تست فصل ۲۱، دو tenant، private media، SSO، restore و ack مقصد لازم است. این فصل راهنمای اتصال آینده است؛ هیچ API/auth تولیدی را اکنون فعال نمی‌کند.
