# شناسنامه کامل جدول‌های پیشنهادی

وضعیت: **پیشنهادی و نیازمند تصویب Backend**. تاریخ بررسی منابع: 2026-10-27. این اسناد هیچ سرویس تولیدی یا migration اجراشده‌ای را اثبات نمی‌کنند.

این فرهنگ شامل ۳۴ مسئولیت الزامی و ۳ جدول مشروط/اختیاری است. الزامی به معنی لزوم جدول تکراری در کنار سامانه مبدأ نیست؛ reuse مطابق یادداشت هر جدول نیاز به تصویب دارد. همه نمونه‌ها ساختگی‌اند، روی پایگاه اجرا نشده‌اند و seed کامل یک پرونده نیستند. NULL برای retention مجوز حذف نیست. بخش key و قیود مکمل مثال است؛ rowversion و identity را SQL تولید می‌کند.

کدهای نشست، OTP و رمز در این مدل ساخته/تکثیر نشده‌اند؛ session store و replay store هویت باید از provider مصوب استفاده کنند.

## Customers

نگاشت حداقلی هویت مبدأ؛ بدون رمز یا تکثیر پروفایل بیمه

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | هویت اصلی متعلق به سامانه مبدأ؛ این ردیف فقط نگاشت حداقلی همان نصب است. |
| استفاده مجدد | نگاشت به جدول مشتری موجود در همان کارگزاری فقط با کلید issuer/subject پایدار و FK قابل اتکا؛ شماره و پروفایل مبدأ تکرار نشود. |
| هم‌زمانی | ثبت append-only/insert با کلید یکتا و idempotency؛ در صورت تغییر ارتباط، نسخه aggregate والد کنترل شود. تاریخچه درجا بازنویسی نشود. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | A03, A05, A07, A08, A09, B04 |
| API نویسنده | A03 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | ندارد |
| UNIQUE | (SourceIssuer, SourceSubjectId) |
| CHECK | قیود نوع/سرویس |
| ایندکس | کلیدهای PK/UNIQUE؛ ایندکس اضافه پس از بررسی query plan |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | uniqueidentifier | غیرمجاز | PK | NEWSEQUENTIALID() | شناسه داخلی سرور | "00000000-0000-0000-0000-000000000001" |
| SourceIssuer | nvarchar(200) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | صادرکننده معتبر هویت مبدأ | "https://identity.example.invalid" |
| SourceSubjectId | nvarchar(128) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه پایدار مشتری نزد صادرکننده مبدأ | "subject-example" |
| CreatedAt | datetime2(3) | غیرمجاز | — | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt | "2026-10-27T08:30:00.000Z" |

### نمونه رکورد Customers

```json
{
  "Id": "00000000-0000-0000-0000-000000000001",
  "SourceIssuer": "https://identity.example.invalid",
  "SourceSubjectId": "subject-example",
  "CreatedAt": "2026-10-27T08:30:00.000Z"
}
```

## SourceInsuranceRequests

درخواست بیمه متعلق به مشتری

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | هویت اصلی متعلق به سامانه مبدأ؛ این ردیف فقط نگاشت حداقلی همان نصب است. |
| استفاده مجدد | جدول درخواست بیمه موجود می‌تواند مرجع یا نمای read-only باشد؛ external ID و مالکیت باید پایدار باشند. |
| هم‌زمانی | ثبت append-only/insert با کلید یکتا و idempotency؛ در صورت تغییر ارتباط، نسخه aggregate والد کنترل شود. تاریخچه درجا بازنویسی نشود. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | A03, A05, A07, A08, A09, B01, B03, B04, D09 |
| API نویسنده | A03 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | CustomerId → Customers(Id) |
| UNIQUE | (SourceSystem, ExternalRequestId) |
| CHECK | قیود نوع/سرویس |
| ایندکس | CustomerId, CreatedAt |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | uniqueidentifier | غیرمجاز | PK | NEWSEQUENTIALID() | شناسه داخلی سرور | "00000000-0000-0000-0000-000000000002" |
| CustomerId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع CustomerId | "00000000-0000-0000-0000-000000000001" |
| SourceSystem | nvarchar(80) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | فراداده SourceSystem در SourceInsuranceRequests | "نمونه" |
| ExternalRequestId | nvarchar(128) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه درخواست بیمه در سامانه مبدأ | "request-example" |
| SourceVehicleReference | nvarchar(128) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | مرجع خودرو در منبع بیمه | null |
| CreatedAt | datetime2(3) | غیرمجاز | — | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt | "2026-10-27T08:30:00.000Z" |

### نمونه رکورد SourceInsuranceRequests

```json
{
  "Id": "00000000-0000-0000-0000-000000000002",
  "CustomerId": "00000000-0000-0000-0000-000000000001",
  "SourceSystem": "نمونه",
  "ExternalRequestId": "request-example",
  "SourceVehicleReference": null,
  "CreatedAt": "2026-10-27T08:30:00.000Z"
}
```

## InspectionTemplates

نسخه مستقل قالب؛ پس از انتشار تغییرناپذیر

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | جدول اختصاصی پیشنهادی؛ reuse فقط پس از اثبات برابری کلیدها، مجوز، تاریخچه، CAS و تراکنش مجاز است. یک API به معنی یک جدول تازه نیست. |
| هم‌زمانی | RowVersion فقط token باینری مقایسه است و زمان نیست؛ SQL آن را می‌سازد. CAS ردیف و قواعد aggregate در تراکنش کنترل شوند. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | B01, B05, F01, F02, F03, F04 |
| API نویسنده | F02, F03, F04 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | ندارد |
| UNIQUE | (TemplateKey, Version) |
| CHECK | [Version]>0؛ [PhotoPolicyVersion] IN (1,2)؛ [State] IN ('draft','published','archived')؛ ISJSON([SnapshotJson])=1 |
| ایندکس | کلیدهای PK/UNIQUE؛ ایندکس اضافه پس از بررسی query plan |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | uniqueidentifier | غیرمجاز | PK | NEWSEQUENTIALID() | شناسه داخلی سرور | "00000000-0000-0000-0000-000000000003" |
| TemplateKey | nvarchar(80) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | کلید منطقی قالب | "body-image-guided" |
| Version | int | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نسخه مثبت منبع | 2 |
| PhotoPolicyVersion | int | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نسخه ۱ تاریخی یا ۲ فعلی | 2 |
| State | varchar(16) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | وضعیت این منبع؛ قید CHECK حاکم است | "published" |
| SnapshotJson | nvarchar(max) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | snapshot فقط فراداده؛ بایت/Base64 رسانه ممنوع | JSON کامل در نمونه پایین |
| CreatedAt | datetime2(3) | غیرمجاز | — | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt | "2026-10-27T08:30:00.000Z" |
| PublishedAt | datetime2(3) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | زمان UTC سرور برای PublishedAt | null |
| RowVersion | rowversion | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست | "0x0000000000000001" |

### نمونه رکورد InspectionTemplates

```json
{
  "Id": "00000000-0000-0000-0000-000000000003",
  "TemplateKey": "body-image-guided",
  "Version": 2,
  "PhotoPolicyVersion": 2,
  "State": "published",
  "SnapshotJson": "{\"photoPolicyVersion\": 2, \"templateId\": \"body-image-guided\", \"templateVersion\": 2, \"sections\": [{\"id\": \"right\", \"title\": \"نمای راست\", \"order\": 1, \"photoRequirements\": [{\"id\": \"front-45-right\", \"title\": \"جلو ۴۵° راست\", \"description\": \"جلوی خودرو و سمت راست به صورت کامل دیده شود.\", \"sampleImage\": \"/assets/inspection-vehicle/photo-guides/front-45-right.webp\", \"instructions\": [\"جلوی خودرو و سمت راست به طور کامل داخل کادر باشد.\", \"حدود ۳ متر از خودرو فاصله بگیرید.\", \"از زاویه ۴۵ درجه سمت راست عکس بگیرید.\"], \"distance\": \"۳ متر\", \"height\": \"کمر\", \"orientation\": \"landscape\", \"required\": true, \"status\": \"pending\", \"checks\": [\"واضح\", \"نور مناسب\", \"خودرو کامل در کادر\"], \"guidanceTopics\": [\"frame\", \"distance\", \"angle\"]}, {\"id\": \"back-45-right\", \"title\": \"عقب ۴۵° راست\", \"description\": \"عقب خودرو و سمت راست به صورت کامل دیده شود.\", \"sampleImage\": \"/assets/inspection-vehicle/photo-guides/back-45-right.webp\", \"instructions\": [\"تمام قسمت عقب و سمت راست خودرو داخل کادر باشد.\", \"خودرو را از زاویه ۴۵ درجه ثبت کنید.\", \"در نور کافی و بدون سایه شدید عکاسی کنید.\"], \"distance\": \"۳ متر\", \"height\": \"کمر\", \"orientation\": \"landscape\", \"required\": true, \"status\": \"pending\", \"checks\": [\"واضح\", \"نور مناسب\", \"خودرو کامل در کادر\"], \"guidanceTopics\": [\"frame\", \"angle\", \"glare\"]}]}, {\"id\": \"left\", \"title\": \"نمای چپ\", \"order\": 2, \"photoRequirements\": [{\"id\": \"front-45-left\", \"title\": \"جلو ۴۵° چپ\", \"description\": \"جلوی خودرو و سمت چپ به صورت کامل دیده شود.\", \"sampleImage\": \"/assets/inspection-vehicle/photo-guides/front-45-left.webp\", \"instructions\": [\"جلوی خودرو و سمت چپ به طور کامل داخل کادر باشد.\", \"حدود ۳ متر از خودرو فاصله بگیرید.\", \"از زاویه ۴۵ درجه سمت چپ عکس بگیرید.\"], \"distance\": \"۳ متر\", \"height\": \"کمر\", \"orientation\": \"landscape\", \"required\": true, \"status\": \"pending\", \"checks\": [\"واضح\", \"نور مناسب\", \"خودرو کامل در کادر\"], \"guidanceTopics\": [\"frame\", \"distance\", \"angle\"]}, {\"id\": \"back-45-left\", \"title\": \"عقب ۴۵° چپ\", \"description\": \"عقب خودرو و سمت چپ به صورت کامل دیده شود.\", \"sampleImage\": \"/assets/inspection-vehicle/photo-guides/back-45-left.webp\", \"instructions\": [\"تمام قسمت عقب و سمت چپ خودرو داخل کادر باشد.\", \"خودرو را از زاویه ۴۵ درجه ثبت کنید.\", \"در نور کافی و بدون سایه شدید عکاسی کنید.\"], \"distance\": \"۳ متر\", \"height\": \"کمر\", \"orientation\": \"landscape\", \"required\": true, \"status\": \"pending\", \"checks\": [\"واضح\", \"نور مناسب\", \"خودرو کامل در کادر\"], \"guidanceTopics\": [\"frame\", \"angle\", \"glare\"]}]}, {\"id\": \"front\", \"title\": \"جلو\", \"order\": 3, \"photoRequirements\": [{\"id\": \"front-plate\", \"title\": \"نمای مستقیم جلو با پلاک\", \"description\": \"یک عکس مستقیم از نمای جلوی خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.\", \"sampleImage\": \"/assets/inspection-vehicle/photo-guides/front-plate.webp\", \"instructions\": [\"مستقیم روبه‌روی خودرو بایستید؛ خودرو وسط کادر باشد.\", \"نمای کامل جلو را بدون برش و زاویه شدید ثبت کنید.\", \"پلاک بدون بازتاب نور و کاملاً خوانا باشد.\"], \"distance\": \"۳ متر\", \"height\": \"چراغ‌ها\", \"orientation\": \"landscape\", \"required\": true, \"status\": \"pending\", \"checks\": [\"واضح\", \"نور مناسب\", \"پلاک خوانا است\"], \"guidanceTopics\": [\"angle\", \"frame\", \"text\"]}]}, {\"id\": \"rear\", \"title\": \"عقب\", \"order\": 4, \"photoRequirements\": [{\"id\": \"rear-plate\", \"title\": \"نمای مستقیم عقب با پلاک\", \"description\": \"یک عکس مستقیم از نمای عقب خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.\", \"sampleImage\": \"/assets/inspection-vehicle/photo-guides/rear-plate.webp\", \"instructions\": [\"مستقیم پشت خودرو بایستید؛ خودرو وسط کادر باشد.\", \"تمام نمای عقب بدون برش و زاویه شدید داخل کادر باشد.\", \"پلاک کاملاً خوانا و بدون بازتاب باشد.\"], \"distance\": \"۳ متر\", \"height\": \"چراغ‌ها\", \"orientation\": \"landscape\", \"required\": true, \"status\": \"pending\", \"checks\": [\"واضح\", \"نور مناسب\", \"پلاک خوانا است\"], \"guidanceTopics\": [\"angle\", \"frame\", \"text\"]}]}, {\"id\": \"cabin\", \"title\": \"کابین\", \"order\": 5, \"photoRequirements\": [{\"id\": \"odometer-on\", \"title\": \"کیلومترشمار\", \"description\": \"خودرو را روشن کنید و تصویری واضح از کیلومترشمار بگیرید.\", \"sampleImage\": \"/assets/inspection-vehicle/photo-guides/odometer-on.webp\", \"instructions\": [\"خودرو را روشن و در حالت توقف نگه دارید.\", \"تمام صفحه کیلومترشمار در کادر باشد.\", \"عدد کیلومتر خوانا باشد؛ از بازتاب نور جلوگیری کنید.\"], \"distance\": \"نزدیک\", \"height\": \"داشبورد\", \"orientation\": \"landscape\", \"required\": true, \"status\": \"pending\", \"checks\": [\"واضح\", \"نور مناسب\", \"عدد کیلومتر خوانا است\"], \"guidanceTopics\": [\"ignition\", \"frame\", \"glare\"]}, {\"id\": \"driver-interior\", \"title\": \"نمای داخل کابین از سمت راننده\", \"description\": \"از سمت راننده تصویری بگیرید که فضای داخلی خودرو به صورت واضح دیده شود.\", \"sampleImage\": \"/assets/inspection-vehicle/photo-guides/driver-interior.webp\", \"instructions\": [\"درِ سمت راننده را باز کنید.\", \"فرمان، داشبورد و صندلی‌ها دیده شوند.\", \"خیلی نزدیک نشوید؛ فضای داخلی کامل دیده شود.\"], \"distance\": \"۱ متر\", \"height\": \"درِ راننده\", \"orientation\": \"landscape\", \"required\": true, \"status\": \"pending\", \"checks\": [\"واضح\", \"نور مناسب\", \"کابین کامل در کادر\"], \"guidanceTopics\": [\"interior\", \"frame\", \"distance\"]}]}, {\"id\": \"engine-details\", \"title\": \"موتور و مشخصات\", \"order\": 6, \"photoRequirements\": [{\"id\": \"engine-bay\", \"title\": \"محفظه موتور\", \"description\": \"کاپوت را باز کنید و یک تصویر کامل و واضح از محفظه موتور بگیرید.\", \"sampleImage\": \"/assets/inspection-vehicle/photo-guides/engine-bay.webp\", \"instructions\": [\"خودرو متوقف باشد؛ کاپوت را کاملاً و ایمن باز کنید.\", \"تمام محفظه موتور دیده شود.\", \"گوشی ثابت و تصویر بدون تاری باشد.\"], \"distance\": \"۱ متر\", \"height\": \"سینه\", \"orientation\": \"landscape\", \"required\": true, \"status\": \"pending\", \"checks\": [\"واضح\", \"نور مناسب\", \"محفظه کامل در کادر\"], \"guidanceTopics\": [\"hood\", \"frame\", \"steady\"]}, {\"id\": \"spec-plate\", \"title\": \"محل شماره شاسی خودرو\", \"description\": \"شماره شاسی خودرو — انتخاب یکی از چهار گزینه. فقط یک تصویر لازم است.\", \"sampleImage\": \"/assets/inspection-vehicle/photo-guides/spec-plate.webp\", \"instructions\": [\"از نزدیک روی پلاک مشخصات فوکوس کنید.\", \"تمام متن پلاک داخل کادر باشد.\", \"نوشته‌ها خوانا و بدون بازتاب نور باشند.\"], \"distance\": \"۳۰ سانتی‌متر\", \"height\": \"هم‌سطح پلاک\", \"orientation\": \"landscape\", \"choice\": {\"groupId\": \"vehicle-identification\", \"alternatives\": [\"pillar\", \"engine\", \"seat\", \"windshield\"]}, \"required\": true, \"status\": \"pending\", \"checks\": [\"واضح\", \"نور مناسب\", \"اطلاعات قابل خواندن است\"], \"guidanceTopics\": [\"text\", \"frame\", \"glare\"]}]}, {\"id\": \"roof\", \"title\": \"سقف\", \"order\": 7, \"photoRequirements\": [{\"id\": \"car-roof\", \"title\": \"نمای سقف\", \"description\": \"تمام سطح سقف خودرو را در تصویر نشان دهید.\", \"sampleImage\": \"/assets/inspection-vehicle/photo-guides/car-roof.webp\", \"instructions\": [\"از موقعیتی ایمن، گوشی را بالاتر بگیرید.\", \"بیشترین سطح سقف و گوشه‌های اصلی در کادر باشند.\", \"برای عکاسی روی خودرو نایستید.\"], \"distance\": \"۱ متر\", \"height\": \"بالاتر از سقف\", \"orientation\": \"landscape\", \"required\": true, \"status\": \"pending\", \"checks\": [\"واضح\", \"نور مناسب\", \"سقف کامل در کادر\"], \"guidanceTopics\": [\"roof\", \"frame\", \"steady\"]}]}], \"captureRequirements\": {\"odometerRequirementId\": \"odometer-on\", \"video360Required\": true}}",
  "CreatedAt": "2026-10-27T08:30:00.000Z",
  "PublishedAt": null,
  "RowVersion": "0x0000000000000001"
}
```

## EvidenceRequirements

جایگاه الزام؛ عکس و ویدیو جدا هستند

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | جدول اختصاصی پیشنهادی؛ reuse فقط پس از اثبات برابری کلیدها، مجوز، تاریخچه، CAS و تراکنش مجاز است. یک API به معنی یک جدول تازه نیست. |
| هم‌زمانی | ثبت append-only/insert با کلید یکتا و idempotency؛ در صورت تغییر ارتباط، نسخه aggregate والد کنترل شود. تاریخچه درجا بازنویسی نشود. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | B05, F02, F03 |
| API نویسنده | F02, F03 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | TemplateId → InspectionTemplates(Id) |
| UNIQUE | (TemplateId, RequirementKey)؛ (Id, TemplateId)؛ (Id, HasChoice) |
| CHECK | [Kind] IN ('photo','video-360')؛ [SortOrder]>0؛ ([Kind]='photo' AND [SectionKey] IS NOT NULL) OR ([Kind]='video-360' AND [SectionKey] IS NULL AND [HasChoice]=0) |
| ایندکس | کلیدهای PK/UNIQUE؛ ایندکس اضافه پس از بررسی query plan |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | uniqueidentifier | غیرمجاز | PK | NEWSEQUENTIALID() | شناسه داخلی سرور | "00000000-0000-0000-0000-000000000004" |
| TemplateId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع TemplateId | "00000000-0000-0000-0000-000000000003" |
| RequirementKey | nvarchar(80) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه منطقی مانند spec-plate یا video-360 با نوع جدا | "spec-plate" |
| Kind | varchar(16) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | photo/video-360 و در قلم اصلاح field | "photo" |
| SectionKey | nvarchar(80) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | بخش عکس؛ برای ویدیو NULL | "engine-details" |
| Required | bit | غیرمجاز | — | 1 | الزام نسخه قالب | true |
| HasChoice | bit | غیرمجاز | — | 0 | از تعریف ثابت الزام؛ فقط گروه VIN دارای گزینه است | true |
| SortOrder | int | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | ترتیب نمایش | 1 |

### نمونه رکورد EvidenceRequirements

```json
{
  "Id": "00000000-0000-0000-0000-000000000004",
  "TemplateId": "00000000-0000-0000-0000-000000000003",
  "RequirementKey": "spec-plate",
  "Kind": "photo",
  "SectionKey": "engine-details",
  "Required": true,
  "HasChoice": true,
  "SortOrder": 1
}
```

## RequirementAlternatives

چهار محل مجاز همان یک الزام VIN

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | جدول اختصاصی پیشنهادی؛ reuse فقط پس از اثبات برابری کلیدها، مجوز، تاریخچه، CAS و تراکنش مجاز است. یک API به معنی یک جدول تازه نیست. |
| هم‌زمانی | ثبت append-only/insert با کلید یکتا و idempotency؛ در صورت تغییر ارتباط، نسخه aggregate والد کنترل شود. تاریخچه درجا بازنویسی نشود. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | B05, F02, F03 |
| API نویسنده | F02, F03 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | RequirementId → EvidenceRequirements(Id) |
| UNIQUE | (RequirementId, AlternativeKey)؛ (Id, RequirementId) |
| CHECK | [AlternativeKey] IN ('pillar','engine','seat','windshield') |
| ایندکس | کلیدهای PK/UNIQUE؛ ایندکس اضافه پس از بررسی query plan |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | uniqueidentifier | غیرمجاز | PK | NEWSEQUENTIALID() | شناسه داخلی سرور | "00000000-0000-0000-0000-000000000005" |
| RequirementId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع RequirementId | "00000000-0000-0000-0000-000000000004" |
| AlternativeKey | varchar(20) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | pillar/engine/seat/windshield | "pillar" |
| TitleFa | nvarchar(250) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | عنوان فارسی | "نمونه" |

### نمونه رکورد RequirementAlternatives

```json
{
  "Id": "00000000-0000-0000-0000-000000000005",
  "RequirementId": "00000000-0000-0000-0000-000000000004",
  "AlternativeKey": "pillar",
  "TitleFa": "نمونه"
}
```

## Inspections

هر ردیف یک تلاش مستقل و دارای سابقه

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | جدول اختصاصی پیشنهادی؛ reuse فقط پس از اثبات برابری کلیدها، مجوز، تاریخچه، CAS و تراکنش مجاز است. یک API به معنی یک جدول تازه نیست. |
| هم‌زمانی | RowVersion فقط token باینری مقایسه است و زمان نیست؛ SQL آن را می‌سازد. CAS ردیف و قواعد aggregate در تراکنش کنترل شوند. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | B01, B02, B03, B04, B07, B09, B10, D01, D02, D04, D07, D09, E01, E02, E03, E05, E06, E07, E09, G01, G02, G03 |
| API نویسنده | B01, B07, B09, B10, D02, D07, D09, E03, E05, E06, E07, E09, G02, G03 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | SourceRequestId → SourceInsuranceRequests(Id)؛ TemplateId → InspectionTemplates(Id)؛ PreviousInspectionId, SourceRequestId → Inspections(Id, SourceRequestId) |
| UNIQUE | (PublicId)؛ (TrackingCode)؛ (SourceRequestId, AttemptNumber)؛ (Id, TemplateId)؛ (Id, SourceRequestId) |
| CHECK | [AttemptNumber]>0؛ [Status] IN ('DRAFT','UPLOAD_PENDING','SUBMITTED','UNDER_REVIEW','CHANGES_REQUESTED','REJECTED','REVIEW_APPROVED','FORWARD_PENDING','FORWARDED','FORWARD_FAILED')؛ [PreviousInspectionId] IS NULL OR [PreviousInspectionId]<>[Id] |
| ایندکس | UNIQUE SourceRequestId WHERE [IsCurrent] = 1؛ Status, UpdatedAt INCLUDE SourceRequestId, TrackingCode |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | uniqueidentifier | غیرمجاز | PK | NEWSEQUENTIALID() | شناسه داخلی سرور | "00000000-0000-0000-0000-000000000006" |
| PublicId | nvarchar(80) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه opaque عمومی؛ داده قدیمی قابل نگاشت است | "insp-example-01" |
| SourceRequestId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع SourceRequestId | "00000000-0000-0000-0000-000000000002" |
| TemplateId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع TemplateId | "00000000-0000-0000-0000-000000000003" |
| AttemptNumber | int | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | شماره مثبت تلاش همان درخواست یا کار | 1 |
| PreviousInspectionId | uniqueidentifier | مجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع PreviousInspectionId | null |
| TrackingCode | nvarchar(80) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | کد پیگیری نمایشی؛ ابزار احراز هویت نیست | "BDI-EXAMPLE" |
| Status | varchar(24) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | وضعیت این بُعد؛ نه وضعیت مبهم تمام فرآیندها | "DRAFT" |
| IsCurrent | bit | غیرمجاز | — | 1 | تنها تلاش جاری همان درخواست | true |
| CreatedAt | datetime2(3) | غیرمجاز | — | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt | "2026-10-27T08:30:00.000Z" |
| UpdatedAt | datetime2(3) | غیرمجاز | — | SYSUTCDATETIME() | زمان UTC سرور برای UpdatedAt | "2026-10-27T08:30:00.000Z" |
| RowVersion | rowversion | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست | "0x0000000000000001" |

### نمونه رکورد Inspections

```json
{
  "Id": "00000000-0000-0000-0000-000000000006",
  "PublicId": "insp-example-01",
  "SourceRequestId": "00000000-0000-0000-0000-000000000002",
  "TemplateId": "00000000-0000-0000-0000-000000000003",
  "AttemptNumber": 1,
  "PreviousInspectionId": null,
  "TrackingCode": "BDI-EXAMPLE",
  "Status": "DRAFT",
  "IsCurrent": true,
  "CreatedAt": "2026-10-27T08:30:00.000Z",
  "UpdatedAt": "2026-10-27T08:30:00.000Z",
  "RowVersion": "0x0000000000000001"
}
```

## Vehicles

تصویر اطلاعاتی خودرو همان تلاش؛ منبع بیمه بازنویسی نمی‌شود

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | جدول اختصاصی پیشنهادی؛ reuse فقط پس از اثبات برابری کلیدها، مجوز، تاریخچه، CAS و تراکنش مجاز است. یک API به معنی یک جدول تازه نیست. |
| هم‌زمانی | RowVersion فقط token باینری مقایسه است و زمان نیست؛ SQL آن را می‌سازد. CAS ردیف و قواعد aggregate در تراکنش کنترل شوند. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | B01, B02, B08, B09, D09, E07 |
| API نویسنده | B01, B09, D09, E07 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | InspectionId → Inspections(Id) |
| UNIQUE | (InspectionId) |
| CHECK | [ModelYear] BETWEEN 1000 AND 3000؛ [PlateFirstTwo] NOT LIKE '%[^0-9]%' AND [PlateThree] NOT LIKE '%[^0-9]%' AND [PlateRegion] NOT LIKE '%[^0-9]%' |
| ایندکس | کلیدهای PK/UNIQUE؛ ایندکس اضافه پس از بررسی query plan |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | uniqueidentifier | غیرمجاز | PK | NEWSEQUENTIALID() | شناسه داخلی سرور | "00000000-0000-0000-0000-000000000007" |
| InspectionId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع InspectionId | "00000000-0000-0000-0000-000000000006" |
| SourceVehicleReference | nvarchar(128) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | مرجع خودرو در منبع بیمه | null |
| Make | nvarchar(100) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | سازنده خودرو | "نمونه" |
| Model | nvarchar(100) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | مدل خودرو | "نمونه" |
| ModelYear | int | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | سال مطابق تقویم و سیاست مصوب | 1402 |
| BodyColor | nvarchar(80) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | رنگ بدنه | "نمونه" |
| PlateFirstTwo | char(2) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | دو رقم ASCII پلاک | "12" |
| PlateLetter | nvarchar(3) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | حرف مجاز پلاک | "ب" |
| PlateThree | char(3) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | سه رقم ASCII پلاک | "345" |
| PlateRegion | char(2) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | دو رقم منطقه | "67" |
| MaskedVin | nvarchar(80) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | VIN پوشانده‌شده؛ نمایش کامل سیاست جدا می‌خواهد | "نمونه" |
| ConfirmedAt | datetime2(3) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | زمان UTC سرور برای ConfirmedAt | null |
| RowVersion | rowversion | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست | "0x0000000000000001" |
| BodyColorHex | char(7) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | رنگ hex اختیاری برای swatch؛ نام رنگ در BodyColor است و رنگ ناشناخته نباید حدس قطعی شود. | "#FFFFFF" |

### نمونه رکورد Vehicles

```json
{
  "Id": "00000000-0000-0000-0000-000000000007",
  "InspectionId": "00000000-0000-0000-0000-000000000006",
  "SourceVehicleReference": null,
  "Make": "نمونه",
  "Model": "نمونه",
  "ModelYear": 1402,
  "BodyColor": "نمونه",
  "PlateFirstTwo": "12",
  "PlateLetter": "ب",
  "PlateThree": "345",
  "PlateRegion": "67",
  "MaskedVin": "نمونه",
  "ConfirmedAt": null,
  "RowVersion": "0x0000000000000001",
  "BodyColorHex": "#FFFFFF"
}
```

## InspectionLocations

محل تأییدشده بازدید

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | جدول اختصاصی پیشنهادی؛ reuse فقط پس از اثبات برابری کلیدها، مجوز، تاریخچه، CAS و تراکنش مجاز است. یک API به معنی یک جدول تازه نیست. |
| هم‌زمانی | RowVersion فقط token باینری مقایسه است و زمان نیست؛ SQL آن را می‌سازد. CAS ردیف و قواعد aggregate در تراکنش کنترل شوند. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | B02, B07 |
| API نویسنده | B07 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | InspectionId |
| FK | InspectionId → Inspections(Id) |
| UNIQUE | ندارد |
| CHECK | [Latitude] BETWEEN -90 AND 90؛ [Longitude] BETWEEN -180 AND 180؛ [AccuracyMeters]>=0؛ [SelectionSource] IS NULL OR [SelectionSource] IN ('gps','manual') |
| ایندکس | کلیدهای PK/UNIQUE؛ ایندکس اضافه پس از بررسی query plan |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| InspectionId | uniqueidentifier | غیرمجاز | PK/FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع InspectionId | "00000000-0000-0000-0000-000000000006" |
| Latitude | decimal(9,6) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | عرض جغرافیایی[-90,90] | 35.6892 |
| Longitude | decimal(9,6) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | طول جغرافیایی[-180,180] | 51.389 |
| AccuracyMeters | decimal(9,2) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | دقت غیرمنفی بر حسب متر | 8 |
| FormattedAddress | nvarchar(500) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نشانی فارسی قابل ویرایش | "نمونه" |
| BuildingNumber | nvarchar(40) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | شماره ساختمان به صورت رشته | "نمونه" |
| UnitFloor | nvarchar(80) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | واحد یا طبقه اختیاری | null |
| ParkingDescription | nvarchar(500) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | توضیح اختیاری محل پارک | null |
| ConfirmedAt | datetime2(3) | غیرمجاز | — | SYSUTCDATETIME() | زمان UTC سرور برای ConfirmedAt | "2026-10-27T08:30:00.000Z" |
| RowVersion | rowversion | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست | "0x0000000000000001" |
| SelectionSource | varchar(10) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | روش انتخاب اعلام‌شده gps/manual؛ ادعای GPS بدونمجوزیا accuracy ساخته نشود. | "manual" |
| ClientRecordedAt | datetime2(3) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | زمان اعلامی مشتری؛ با ConfirmedAt سرور و audit trusted فرق دارد. | null |

### نمونه رکورد InspectionLocations

```json
{
  "InspectionId": "00000000-0000-0000-0000-000000000006",
  "Latitude": 35.6892,
  "Longitude": 51.389,
  "AccuracyMeters": 8,
  "FormattedAddress": "نمونه",
  "BuildingNumber": "نمونه",
  "UnitFloor": null,
  "ParkingDescription": null,
  "ConfirmedAt": "2026-10-27T08:30:00.000Z",
  "RowVersion": "0x0000000000000001",
  "SelectionSource": "manual",
  "ClientRecordedAt": null
}
```

## InspectionConsents

رسید پذیرش نسخه شرایط

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | جدول اختصاصی پیشنهادی؛ reuse فقط پس از اثبات برابری کلیدها، مجوز، تاریخچه، CAS و تراکنش مجاز است. یک API به معنی یک جدول تازه نیست. |
| هم‌زمانی | ثبت append-only/insert با کلید یکتا و idempotency؛ در صورت تغییر ارتباط، نسخه aggregate والد کنترل شود. تاریخچه درجا بازنویسی نشود. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | B06 |
| API نویسنده | B06 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | InspectionId → Inspections(Id) |
| UNIQUE | (InspectionId, TermsVersion) |
| CHECK | قیود نوع/سرویس |
| ایندکس | کلیدهای PK/UNIQUE؛ ایندکس اضافه پس از بررسی query plan |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | uniqueidentifier | غیرمجاز | PK | NEWSEQUENTIALID() | شناسه داخلی سرور | "00000000-0000-0000-0000-000000000009" |
| InspectionId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع InspectionId | "00000000-0000-0000-0000-000000000006" |
| TermsVersion | nvarchar(80) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نسخه متن شرایط مصوب | "نمونه" |
| AcceptedBySubject | nvarchar(128) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | فراداده AcceptedBySubject در InspectionConsents | "نمونه" |
| AcceptedAt | datetime2(3) | غیرمجاز | — | SYSUTCDATETIME() | زمان UTC سرور برای AcceptedAt | "2026-10-27T08:30:00.000Z" |

### نمونه رکورد InspectionConsents

```json
{
  "Id": "00000000-0000-0000-0000-000000000009",
  "InspectionId": "00000000-0000-0000-0000-000000000006",
  "TermsVersion": "نمونه",
  "AcceptedBySubject": "نمونه",
  "AcceptedAt": "2026-10-27T08:30:00.000Z"
}
```

## OdometerReadings

کیلومتر عددی، مستقل از رسانه

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | جدول اختصاصی پیشنهادی؛ reuse فقط پس از اثبات برابری کلیدها، مجوز، تاریخچه، CAS و تراکنش مجاز است. یک API به معنی یک جدول تازه نیست. |
| هم‌زمانی | RowVersion فقط token باینری مقایسه است و زمان نیست؛ SQL آن را می‌سازد. CAS ردیف و قواعد aggregate در تراکنش کنترل شوند. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | B10, D01 |
| API نویسنده | B10 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | InspectionId |
| FK | InspectionId → Inspections(Id)؛ EvidenceVersionId, InspectionId → EvidenceVersions(Id, InspectionId) |
| UNIQUE | ندارد |
| CHECK | [Kilometers] BETWEEN 0 AND 9007199254740991 |
| ایندکس | کلیدهای PK/UNIQUE؛ ایندکس اضافه پس از بررسی query plan |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| InspectionId | uniqueidentifier | غیرمجاز | PK/FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع InspectionId | "00000000-0000-0000-0000-000000000006" |
| Kilometers | bigint | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | عدد صحیح غیرمنفی در محدوده امن JavaScript | 48320 |
| EvidenceVersionId | uniqueidentifier | مجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع EvidenceVersionId | null |
| UpdatedAt | datetime2(3) | غیرمجاز | — | SYSUTCDATETIME() | زمان UTC سرور برای UpdatedAt | "2026-10-27T08:30:00.000Z" |
| RowVersion | rowversion | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست | "0x0000000000000001" |

### نمونه رکورد OdometerReadings

```json
{
  "InspectionId": "00000000-0000-0000-0000-000000000006",
  "Kilometers": 48320,
  "EvidenceVersionId": null,
  "UpdatedAt": "2026-10-27T08:30:00.000Z",
  "RowVersion": "0x0000000000000001"
}
```

## InspectionEvidence

جایگاه مدرک و اشاره‌گر نسخه خوب/جایگزین منتظر

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | جدول اختصاصی پیشنهادی؛ reuse فقط پس از اثبات برابری کلیدها، مجوز، تاریخچه، CAS و تراکنش مجاز است. یک API به معنی یک جدول تازه نیست. |
| هم‌زمانی | RowVersion فقط token باینری مقایسه است و زمان نیست؛ SQL آن را می‌سازد. CAS ردیف و قواعد aggregate در تراکنش کنترل شوند. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | C01, C04, D01, D07 |
| API نویسنده | C01, D07 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | InspectionId, TemplateId → Inspections(Id, TemplateId)؛ RequirementId, TemplateId → EvidenceRequirements(Id, TemplateId)؛ CurrentVersionId, Id → EvidenceVersions(Id, EvidenceId)؛ PendingVersionId, Id → EvidenceVersions(Id, EvidenceId) |
| UNIQUE | (InspectionId, RequirementId)؛ (Id, InspectionId)؛ (Id, RequirementId) |
| CHECK | قیود نوع/سرویس |
| ایندکس | کلیدهای PK/UNIQUE؛ ایندکس اضافه پس از بررسی query plan |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | uniqueidentifier | غیرمجاز | PK/FK | NEWSEQUENTIALID() | شناسه داخلی سرور | "00000000-0000-0000-0000-00000000000b" |
| InspectionId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع InspectionId | "00000000-0000-0000-0000-000000000006" |
| TemplateId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع TemplateId | "00000000-0000-0000-0000-000000000003" |
| RequirementId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع RequirementId | "00000000-0000-0000-0000-000000000004" |
| CurrentVersionId | uniqueidentifier | مجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | نسخه خوب فعلی تا موفقیت جایگزین محفوظ است | null |
| PendingVersionId | uniqueidentifier | مجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | جایگزین موردنظر که هنوز تأیید پایدار نشده | null |
| RowVersion | rowversion | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست | "0x0000000000000001" |

### نمونه رکورد InspectionEvidence

```json
{
  "Id": "00000000-0000-0000-0000-00000000000b",
  "InspectionId": "00000000-0000-0000-0000-000000000006",
  "TemplateId": "00000000-0000-0000-0000-000000000003",
  "RequirementId": "00000000-0000-0000-0000-000000000004",
  "CurrentVersionId": null,
  "PendingVersionId": null,
  "RowVersion": "0x0000000000000001"
}
```

## EvidenceVersions

نسخه مستقل با هویت واقعی گزینه و بایت‌ها

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | جدول اختصاصی پیشنهادی؛ reuse فقط پس از اثبات برابری کلیدها، مجوز، تاریخچه، CAS و تراکنش مجاز است. یک API به معنی یک جدول تازه نیست. |
| هم‌زمانی | RowVersion فقط token باینری مقایسه است و زمان نیست؛ SQL آن را می‌سازد. CAS ردیف و قواعد aggregate در تراکنش کنترل شوند. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | C01, C02, C03, C04, C05, C06, C07, D01, D06, E10 |
| API نویسنده | C01, C02, C03, C07, D06 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | EvidenceId, InspectionId → InspectionEvidence(Id, InspectionId)؛ EvidenceId, RequirementId → InspectionEvidence(Id, RequirementId)؛ RequirementId, HasChoice → EvidenceRequirements(Id, HasChoice)؛ AlternativeId, RequirementId → RequirementAlternatives(Id, RequirementId)؛ ReplacesVersionId, EvidenceId → EvidenceVersions(Id, EvidenceId) |
| UNIQUE | (EvidenceId, RevisionKey)؛ (Id, EvidenceId)؛ (Id, InspectionId) |
| CHECK | [UploadStatus] IN ('queued','uploading','uploaded','failed','cancelled')؛ [VerificationStatus] IN ('not-started','processing','verified','retake-requested')؛ ([HasChoice]=1 AND [AlternativeId] IS NOT NULL) OR ([HasChoice]=0 AND [AlternativeId] IS NULL) |
| ایندکس | کلیدهای PK/UNIQUE؛ ایندکس اضافه پس از بررسی query plan |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | uniqueidentifier | غیرمجاز | PK | NEWSEQUENTIALID() | شناسه داخلی سرور | "00000000-0000-0000-0000-00000000000c" |
| EvidenceId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع EvidenceId | "00000000-0000-0000-0000-00000000000b" |
| InspectionId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع InspectionId | "00000000-0000-0000-0000-000000000006" |
| RequirementId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع RequirementId | "00000000-0000-0000-0000-000000000004" |
| HasChoice | bit | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | از تعریف ثابت الزام؛ فقط گروه VIN دارای گزینه است | true |
| AlternativeId | uniqueidentifier | مجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | گزینه واقعی فایل؛ نه ترجیح راهنمای بعدی | "00000000-0000-0000-0000-000000000005" |
| RevisionKey | nvarchar(160) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | کلید ثابت نسخه محلی برای تکرار امن | "نمونه" |
| ReplacesVersionId | uniqueidentifier | مجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع ReplacesVersionId | null |
| UploadStatus | varchar(16) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | انتقال مستقل از پردازش و تصمیم کارشناس | "queued" |
| VerificationStatus | varchar(24) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | not-started/processing/verified/retake-requested | "not-started" |
| CapturedAtClaim | datetime2(3) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | زمان ادعایی دستگاه؛ اثبات زمان واقعی نیست | "2026-10-27T08:30:00.000Z" |
| CreatedAt | datetime2(3) | غیرمجاز | — | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt | "2026-10-27T08:30:00.000Z" |
| RowVersion | rowversion | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست | "0x0000000000000001" |

### نمونه رکورد EvidenceVersions

```json
{
  "Id": "00000000-0000-0000-0000-00000000000c",
  "EvidenceId": "00000000-0000-0000-0000-00000000000b",
  "InspectionId": "00000000-0000-0000-0000-000000000006",
  "RequirementId": "00000000-0000-0000-0000-000000000004",
  "HasChoice": true,
  "AlternativeId": "00000000-0000-0000-0000-000000000005",
  "RevisionKey": "نمونه",
  "ReplacesVersionId": null,
  "UploadStatus": "queued",
  "VerificationStatus": "not-started",
  "CapturedAtClaim": "2026-10-27T08:30:00.000Z",
  "CreatedAt": "2026-10-27T08:30:00.000Z",
  "RowVersion": "0x0000000000000001"
}
```

## MediaFiles

فقط فراداده و مسیر فایل خصوصی؛ بدون باینری رسانه

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | جدول اختصاصی پیشنهادی؛ reuse فقط پس از اثبات برابری کلیدها، مجوز، تاریخچه، CAS و تراکنش مجاز است. یک API به معنی یک جدول تازه نیست. |
| هم‌زمانی | RowVersion فقط token باینری مقایسه است و زمان نیست؛ SQL آن را می‌سازد. CAS ردیف و قواعد aggregate در تراکنش کنترل شوند. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | C01, C02, C03, C04, C05, C06, D06, G03 |
| API نویسنده | C01, C02, C03, D06 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | EvidenceVersionId → EvidenceVersions(Id)؛ DerivedFromFileId, EvidenceVersionId → MediaFiles(Id, EvidenceVersionId) |
| UNIQUE | (RelativePath)؛ (Id, EvidenceVersionId) |
| CHECK | [Variant] IN ('original','thumbnail','preview','transcode')؛ [StorageState] IN ('staging','durable','submitted','finalized','historical','missing','deleted')؛ [ByteSize]>0؛ [Width] IS NULL OR [Width]>0؛ [Height] IS NULL OR [Height]>0؛ [DurationMs] IS NULL OR [DurationMs]>0؛ [RelativePath] NOT LIKE '%..%' AND [RelativePath] NOT LIKE '/%' AND [RelativePath] NOT LIKE '%:%' AND CHARINDEX(NCHAR(92),[RelativePath])=0؛ [DerivedFromFileId] IS NULL OR [DerivedFromFileId]<>[Id] |
| ایندکس | UNIQUE EvidenceVersionId, Variant WHERE [DeletedAt] IS NULL؛ StorageState, RetentionUntil؛ EvidenceVersionId, Variant, ProfileVersion INCLUDE MimeType, ByteSize |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | uniqueidentifier | غیرمجاز | PK | NEWSEQUENTIALID() | شناسه داخلی سرور | "00000000-0000-0000-0000-00000000000d" |
| EvidenceVersionId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع EvidenceVersionId | "00000000-0000-0000-0000-00000000000c" |
| Variant | varchar(16) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | original/thumbnail/preview/transcode | "original" |
| GeneratedFilename | nvarchar(200) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نام تولیدشده سرور، نه نام فایل کاربر | "evidence-example-revision-01.jpg" |
| RelativePath | nvarchar(450) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | مسیر نسبی canonical زیر ریشه خصوصی | "GUI_example/INSPECTION_example/finalized/photos/evidence-example-revision-01.jpg" |
| MimeType | varchar(127) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نوع واقعی تأییدشده رسانه | "image/jpeg" |
| ByteSize | bigint | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | اندازه واقعی مورد تطبیق در complete | 1048576 |
| Sha256 | binary(32) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | هش ۳۲ بایتی؛ فراداده است و رسانه نیست | null |
| Width | int | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | عرض مثبت رسانه | null |
| Height | int | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | ارتفاع مثبت رسانه | null |
| DurationMs | bigint | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | مدت ویدیو به میلی‌ثانیه | null |
| StorageState | varchar(16) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | دوام/نگهداری مستقل از انتقال | "staging" |
| CreatedAt | datetime2(3) | غیرمجاز | — | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt | "2026-10-27T08:30:00.000Z" |
| RetentionUntil | datetime2(3) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | سیاست مصوب؛ NULL مجوز حذف نیست | null |
| LegalHold | bit | غیرمجاز | — | 0 | مانع حذف قانونی یا عملیاتی | false |
| DeletedAt | datetime2(3) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | زمان UTC سرور برای DeletedAt | null |
| RowVersion | rowversion | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست | "0x0000000000000001" |
| DerivedFromFileId | uniqueidentifier | مجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | فایل والد همان نسخه برای مشتق اختیاری؛ NULL یعنی بایت دریافتی یا فاقد مشتق. | null |
| ProfileVersion | nvarchar(80) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه نسخه پروفایل پردازش سرور؛ سیاست مرورگر یا گواه کیفیت نیست. | null |

### نمونه رکورد MediaFiles

```json
{
  "Id": "00000000-0000-0000-0000-00000000000d",
  "EvidenceVersionId": "00000000-0000-0000-0000-00000000000c",
  "Variant": "original",
  "GeneratedFilename": "evidence-example-revision-01.jpg",
  "RelativePath": "GUI_example/INSPECTION_example/finalized/photos/evidence-example-revision-01.jpg",
  "MimeType": "image/jpeg",
  "ByteSize": 1048576,
  "Sha256": null,
  "Width": null,
  "Height": null,
  "DurationMs": null,
  "StorageState": "staging",
  "CreatedAt": "2026-10-27T08:30:00.000Z",
  "RetentionUntil": null,
  "LegalHold": false,
  "DeletedAt": null,
  "RowVersion": "0x0000000000000001",
  "DerivedFromFileId": null,
  "ProfileVersion": null
}
```

## UploadSessions

مجوز و انتقال قابل بازیابی همان فایل

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | جدول اختصاصی پیشنهادی؛ reuse فقط پس از اثبات برابری کلیدها، مجوز، تاریخچه، CAS و تراکنش مجاز است. یک API به معنی یک جدول تازه نیست. |
| هم‌زمانی | RowVersion فقط token باینری مقایسه است و زمان نیست؛ SQL آن را می‌سازد. CAS ردیف و قواعد aggregate در تراکنش کنترل شوند. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | C01, C02, C03, C07, D06 |
| API نویسنده | C01, C02, C03, C07, D06 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | MediaFileId → MediaFiles(Id) |
| UNIQUE | ندارد |
| CHECK | [State] IN ('registered','receiving','staged','acknowledged','expired','cancelled')؛ [ExpectedBytes]>0 AND [BytesReceived]>=0 AND [BytesReceived]<=[ExpectedBytes] |
| ایندکس | UNIQUE MediaFileId WHERE [IsActive] = 1؛ State, ExpiresAt |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | uniqueidentifier | غیرمجاز | PK | NEWSEQUENTIALID() | شناسه داخلی سرور | "00000000-0000-0000-0000-00000000000e" |
| MediaFileId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع MediaFileId | "00000000-0000-0000-0000-00000000000d" |
| State | varchar(16) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | وضعیت این منبع؛ قید CHECK حاکم است | "registered" |
| ExpectedBytes | bigint | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | اندازه اظهارشده با سقف مجاز | 1048576 |
| BytesReceived | bigint | غیرمجاز | — | 0 | بایت واقعاً دریافت‌شده | 0 |
| IsActive | bit | غیرمجاز | — | 1 | حداکثر یک انتقال فعال برای فایل | false |
| ExpiresAt | datetime2(3) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | زمان UTC سرور برای ExpiresAt | "2026-10-27T08:30:00.000Z" |
| AcknowledgedAt | datetime2(3) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | زمان UTC سرور برای AcknowledgedAt | null |
| CreatedAt | datetime2(3) | غیرمجاز | — | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt | "2026-10-27T08:30:00.000Z" |
| RowVersion | rowversion | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست | "0x0000000000000001" |

### نمونه رکورد UploadSessions

```json
{
  "Id": "00000000-0000-0000-0000-00000000000e",
  "MediaFileId": "00000000-0000-0000-0000-00000000000d",
  "State": "registered",
  "ExpectedBytes": 1048576,
  "BytesReceived": 0,
  "IsActive": false,
  "ExpiresAt": "2026-10-27T08:30:00.000Z",
  "AcknowledgedAt": null,
  "CreatedAt": "2026-10-27T08:30:00.000Z",
  "RowVersion": "0x0000000000000001"
}
```

## MediaProcessingJobs

کار اعتبارسنجی و تولید مشتق اختیاری

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | اختیاری/مشروط |
| شرط | در صورت انتخاب پردازش غیرهم‌زمان سرور؛ دریافت باینری بدون transcoding اجباری ممکن است. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | جدول اختصاصی پیشنهادی؛ reuse فقط پس از اثبات برابری کلیدها، مجوز، تاریخچه، CAS و تراکنش مجاز است. یک API به معنی یک جدول تازه نیست. |
| هم‌زمانی | RowVersion فقط token باینری مقایسه است و زمان نیست؛ SQL آن را می‌سازد. CAS ردیف و قواعد aggregate در تراکنش کنترل شوند. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | C03, C05 |
| API نویسنده | C03 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | MediaFileId → MediaFiles(Id) |
| UNIQUE | (MediaFileId, JobKind, ProfileVersion) |
| CHECK | [JobKind] IN ('validate','thumbnail','transcode')؛ [Status] IN ('queued','running','completed','failed')؛ [AttemptCount]>=0 |
| ایندکس | Status, NextRetryAt |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | uniqueidentifier | غیرمجاز | PK | NEWSEQUENTIALID() | شناسه داخلی سرور | "00000000-0000-0000-0000-00000000000f" |
| MediaFileId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع MediaFileId | "00000000-0000-0000-0000-00000000000d" |
| JobKind | varchar(24) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | validate/thumbnail/transcode | "validate" |
| ProfileVersion | nvarchar(80) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نسخه پروفایل پردازش | "نمونه" |
| Status | varchar(16) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | وضعیت این بُعد؛ نه وضعیت مبهم تمام فرآیندها | "queued" |
| AttemptCount | int | غیرمجاز | — | 0 | شمار تلاش غیرمنفی | 0 |
| LeaseUntil | datetime2(3) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | زمان انقضای مالکیت موقت کارگر | null |
| NextRetryAt | datetime2(3) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | زمان تلاش بعدی با backoff محدود | null |
| FailureCode | varchar(80) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | کد امن؛ بدون stack، مسیر یا راز | null |
| CreatedAt | datetime2(3) | غیرمجاز | — | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt | "2026-10-27T08:30:00.000Z" |
| RowVersion | rowversion | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست | "0x0000000000000001" |

### نمونه رکورد MediaProcessingJobs

```json
{
  "Id": "00000000-0000-0000-0000-00000000000f",
  "MediaFileId": "00000000-0000-0000-0000-00000000000d",
  "JobKind": "validate",
  "ProfileVersion": "نمونه",
  "Status": "queued",
  "AttemptCount": 0,
  "LeaseUntil": null,
  "NextRetryAt": null,
  "FailureCode": null,
  "CreatedAt": "2026-10-27T08:30:00.000Z",
  "RowVersion": "0x0000000000000001"
}
```

## StaffUsers

نگاشت کارکنان SSO؛ بدون حساب/رمز تکراری

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | هویت اصلی متعلق به سامانه مبدأ؛ این ردیف فقط نگاشت حداقلی همان نصب است. |
| استفاده مجدد | شناسه SSO یا جدول کارکنان موجود قابل استفاده است؛ رمز و پروفایل هویت تکثیر نشود. |
| هم‌زمانی | RowVersion فقط token باینری مقایسه است و زمان نیست؛ SQL آن را می‌سازد. CAS ردیف و قواعد aggregate در تراکنش کنترل شوند. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | A04, A05, E01, E03, E04, F01, F10 |
| API نویسنده | A04, E04, F10 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | ندارد |
| UNIQUE | (ExternalIssuer, ExternalSubject) |
| CHECK | [Capacity]>=0 |
| ایندکس | کلیدهای PK/UNIQUE؛ ایندکس اضافه پس از بررسی query plan |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | uniqueidentifier | غیرمجاز | PK | NEWSEQUENTIALID() | شناسه داخلی سرور | "00000000-0000-0000-0000-000000000010" |
| ExternalIssuer | nvarchar(200) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | فراداده ExternalIssuer در StaffUsers | "https://identity.example.invalid" |
| ExternalSubject | nvarchar(128) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | فراداده ExternalSubject در StaffUsers | "subject-example" |
| DisplayName | nvarchar(160) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | فراداده DisplayName در StaffUsers | "نمونه" |
| Active | bit | غیرمجاز | — | 1 | فعال‌بودن نگاشت یا ارجاع | true |
| Capacity | int | غیرمجاز | — | 10 | ظرفیت پرونده فعال کارشناس | 8 |
| CreatedAt | datetime2(3) | غیرمجاز | — | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt | "2026-10-27T08:30:00.000Z" |
| RowVersion | rowversion | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست | "0x0000000000000001" |

### نمونه رکورد StaffUsers

```json
{
  "Id": "00000000-0000-0000-0000-000000000010",
  "ExternalIssuer": "https://identity.example.invalid",
  "ExternalSubject": "subject-example",
  "DisplayName": "نمونه",
  "Active": true,
  "Capacity": 8,
  "CreatedAt": "2026-10-27T08:30:00.000Z",
  "RowVersion": "0x0000000000000001"
}
```

## StaffRoleAssignments

نقش کارکنان در همان نصب

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | قابل نگاشت به RBAC موجود با همان scope و semantics؛ کد نقش تنها claim مرورگر نیست. |
| هم‌زمانی | ثبت append-only/insert با کلید یکتا و idempotency؛ در صورت تغییر ارتباط، نسخه aggregate والد کنترل شود. تاریخچه درجا بازنویسی نشود. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | A04, A05, F01, F10 |
| API نویسنده | A04, F10 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | StaffId, RoleCode |
| FK | StaffId → StaffUsers(Id) |
| UNIQUE | ندارد |
| CHECK | [RoleCode] IN ('platform-admin','reviewer','template-editor','viewer') |
| ایندکس | کلیدهای PK/UNIQUE؛ ایندکس اضافه پس از بررسی query plan |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| StaffId | uniqueidentifier | غیرمجاز | PK/FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع StaffId | "00000000-0000-0000-0000-000000000010" |
| RoleCode | varchar(32) | غیرمجاز | PK | تخصیص صریح سرویس؛ rowversion/identity خودکار | نقش همین نصب؛ platform-admin مدیر همین کارگزاری است | "reviewer" |
| CreatedAt | datetime2(3) | غیرمجاز | — | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt | "2026-10-27T08:30:00.000Z" |

### نمونه رکورد StaffRoleAssignments

```json
{
  "StaffId": "00000000-0000-0000-0000-000000000010",
  "RoleCode": "reviewer",
  "CreatedAt": "2026-10-27T08:30:00.000Z"
}
```

## StaffOperationsSettings

سیاست ارجاع مستقل از برند

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | جدول اختصاصی پیشنهادی؛ reuse فقط پس از اثبات برابری کلیدها، مجوز، تاریخچه، CAS و تراکنش مجاز است. یک API به معنی یک جدول تازه نیست. |
| هم‌زمانی | RowVersion فقط token باینری مقایسه است و زمان نیست؛ SQL آن را می‌سازد. CAS ردیف و قواعد aggregate در تراکنش کنترل شوند. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | E04 |
| API نویسنده | E04 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | ندارد |
| UNIQUE | ندارد |
| CHECK | [Id]=1؛ [AssignmentMode] IN ('manual','random') |
| ایندکس | کلیدهای PK/UNIQUE؛ ایندکس اضافه پس از بررسی query plan |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | tinyint | غیرمجاز | PK | 1 | شناسه داخلی سرور | 1 |
| AssignmentMode | varchar(16) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | manual/random | "manual" |
| RowVersion | rowversion | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست | "0x0000000000000001" |

### نمونه رکورد StaffOperationsSettings

```json
{
  "Id": 1,
  "AssignmentMode": "manual",
  "RowVersion": "0x0000000000000001"
}
```

## ReviewerAssignments

سابقه ارجاع؛ یک ارجاع فعال هر پرونده

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | جدول اختصاصی پیشنهادی؛ reuse فقط پس از اثبات برابری کلیدها، مجوز، تاریخچه، CAS و تراکنش مجاز است. یک API به معنی یک جدول تازه نیست. |
| هم‌زمانی | RowVersion فقط token باینری مقایسه است و زمان نیست؛ SQL آن را می‌سازد. CAS ردیف و قواعد aggregate در تراکنش کنترل شوند. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | C06, E01, E02, E03 |
| API نویسنده | E03 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | InspectionId → Inspections(Id)؛ ReviewerId → StaffUsers(Id)؛ AssignedBy → StaffUsers(Id) |
| UNIQUE | (Id, InspectionId) |
| CHECK | قیود نوع/سرویس |
| ایندکس | UNIQUE InspectionId WHERE [Active] = 1؛ ReviewerId, Active |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | uniqueidentifier | غیرمجاز | PK | NEWSEQUENTIALID() | شناسه داخلی سرور | "00000000-0000-0000-0000-000000000013" |
| InspectionId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع InspectionId | "00000000-0000-0000-0000-000000000006" |
| ReviewerId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع ReviewerId | "00000000-0000-0000-0000-000000000010" |
| AssignedBy | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع AssignedBy | "00000000-0000-0000-0000-000000000010" |
| Active | bit | غیرمجاز | — | 1 | فعال‌بودن نگاشت یا ارجاع | true |
| AssignedAt | datetime2(3) | غیرمجاز | — | SYSUTCDATETIME() | زمان UTC سرور برای AssignedAt | "2026-10-27T08:30:00.000Z" |
| RevokedAt | datetime2(3) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | زمان UTC سرور برای RevokedAt | null |
| RowVersion | rowversion | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست | "0x0000000000000001" |

### نمونه رکورد ReviewerAssignments

```json
{
  "Id": "00000000-0000-0000-0000-000000000013",
  "InspectionId": "00000000-0000-0000-0000-000000000006",
  "ReviewerId": "00000000-0000-0000-0000-000000000010",
  "AssignedBy": "00000000-0000-0000-0000-000000000010",
  "Active": true,
  "AssignedAt": "2026-10-27T08:30:00.000Z",
  "RevokedAt": null,
  "RowVersion": "0x0000000000000001"
}
```

## InspectionSubmissions

رسید و نسخه ثابت ارسال اولیه/اصلاح

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | جدول اختصاصی پیشنهادی؛ reuse فقط پس از اثبات برابری کلیدها، مجوز، تاریخچه، CAS و تراکنش مجاز است. یک API به معنی یک جدول تازه نیست. |
| هم‌زمانی | ثبت append-only/insert با کلید یکتا و idempotency؛ در صورت تغییر ارتباط، نسخه aggregate والد کنترل شود. تاریخچه درجا بازنویسی نشود. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | D02, D03, D05, D07, G02 |
| API نویسنده | D02, D07 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | InspectionId → Inspections(Id)؛ CorrectionRequestId, InspectionId → CorrectionRequests(Id, InspectionId) |
| UNIQUE | (InspectionId, SubmissionNumber)؛ (Id, InspectionId) |
| CHECK | [SubmissionNumber]>0؛ ISJSON([SnapshotJson])=1 |
| ایندکس | UNIQUE InspectionId WHERE [CorrectionRequestId] IS NULL |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | uniqueidentifier | غیرمجاز | PK | NEWSEQUENTIALID() | شناسه داخلی سرور | "00000000-0000-0000-0000-000000000014" |
| InspectionId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع InspectionId | "00000000-0000-0000-0000-000000000006" |
| SubmissionNumber | int | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | ترتیب مثبت ارسال | 1 |
| CorrectionRequestId | uniqueidentifier | مجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع CorrectionRequestId | null |
| SnapshotJson | nvarchar(max) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | snapshot فقط فراداده؛ بایت/Base64 رسانه ممنوع | JSON کامل در نمونه پایین |
| SubmittedBySubject | nvarchar(128) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | فراداده SubmittedBySubject در InspectionSubmissions | "نمونه" |
| SubmittedAt | datetime2(3) | غیرمجاز | — | SYSUTCDATETIME() | زمان UTC سرور برای SubmittedAt | "2026-10-27T08:30:00.000Z" |

### نمونه رکورد InspectionSubmissions

```json
{
  "Id": "00000000-0000-0000-0000-000000000014",
  "InspectionId": "00000000-0000-0000-0000-000000000006",
  "SubmissionNumber": 1,
  "CorrectionRequestId": null,
  "SnapshotJson": "{\"inspection\": {\"inspectionId\": \"insp_contract_001\", \"sourceRequestId\": \"REQ-DEMO-001\", \"trackingCode\": \"BDI-8F31K2\", \"status\": \"DRAFT\", \"templateId\": \"body-image-guided\", \"templateVersion\": 2, \"photoPolicyVersion\": 2, \"version\": \"AAAAAAAAB9E=\"}, \"photos\": {\"completed\": 11, \"required\": 11}, \"odometer\": {\"kilometers\": 48320, \"updatedAt\": \"2026-10-26T09:00:00Z\"}, \"video360\": {\"accepted\": true, \"durationSeconds\": 48}, \"media\": {\"uploaded\": 12, \"required\": 12, \"processing\": 2}, \"readiness\": {\"captureComplete\": true, \"requiredMediaUploaded\": true, \"odometerValid\": true, \"factsConfirmed\": true, \"canSubmit\": true, \"blockingUploadFailures\": false}, \"blockers\": []}",
  "SubmittedBySubject": "نمونه",
  "SubmittedAt": "2026-10-27T08:30:00.000Z"
}
```

## SubmissionEvidence

نسخه دقیق هر مدرک در رسید ارسال

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | جدول اختصاصی پیشنهادی؛ reuse فقط پس از اثبات برابری کلیدها، مجوز، تاریخچه، CAS و تراکنش مجاز است. یک API به معنی یک جدول تازه نیست. |
| هم‌زمانی | ثبت append-only/insert با کلید یکتا و idempotency؛ در صورت تغییر ارتباط، نسخه aggregate والد کنترل شود. تاریخچه درجا بازنویسی نشود. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | D02, D07 |
| API نویسنده | D02, D07 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | SubmissionId, EvidenceId |
| FK | SubmissionId, InspectionId → InspectionSubmissions(Id, InspectionId)؛ EvidenceId, InspectionId → InspectionEvidence(Id, InspectionId)؛ EvidenceVersionId, EvidenceId → EvidenceVersions(Id, EvidenceId) |
| UNIQUE | ندارد |
| CHECK | قیود نوع/سرویس |
| ایندکس | کلیدهای PK/UNIQUE؛ ایندکس اضافه پس از بررسی query plan |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| SubmissionId | uniqueidentifier | غیرمجاز | PK/FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع SubmissionId | "00000000-0000-0000-0000-000000000014" |
| InspectionId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع InspectionId | "00000000-0000-0000-0000-000000000006" |
| EvidenceId | uniqueidentifier | غیرمجاز | PK/FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع EvidenceId | "00000000-0000-0000-0000-00000000000b" |
| EvidenceVersionId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع EvidenceVersionId | "00000000-0000-0000-0000-00000000000c" |

### نمونه رکورد SubmissionEvidence

```json
{
  "SubmissionId": "00000000-0000-0000-0000-000000000014",
  "InspectionId": "00000000-0000-0000-0000-000000000006",
  "EvidenceId": "00000000-0000-0000-0000-00000000000b",
  "EvidenceVersionId": "00000000-0000-0000-0000-00000000000c"
}
```

## EvidenceReviews

رویداد تغییرناپذیر تصمیم یک نسخه

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | جدول اختصاصی پیشنهادی؛ reuse فقط پس از اثبات برابری کلیدها، مجوز، تاریخچه، CAS و تراکنش مجاز است. یک API به معنی یک جدول تازه نیست. |
| هم‌زمانی | ثبت append-only/insert با کلید یکتا و idempotency؛ در صورت تغییر ارتباط، نسخه aggregate والد کنترل شود. تاریخچه درجا بازنویسی نشود. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | E02, E05, E10 |
| API نویسنده | E05 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | EvidenceVersionId, InspectionId → EvidenceVersions(Id, InspectionId)؛ AssignmentId, InspectionId → ReviewerAssignments(Id, InspectionId) |
| UNIQUE | ندارد |
| CHECK | [Decision] IN ('approved','rejected')؛ [Decision]<>'rejected' OR ([CustomerReason] IS NOT NULL AND LEN(LTRIM(RTRIM([CustomerReason])))>0) |
| ایندکس | InspectionId, DecidedAt؛ EvidenceVersionId, DecidedAt |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | uniqueidentifier | غیرمجاز | PK | NEWSEQUENTIALID() | شناسه داخلی سرور | "00000000-0000-0000-0000-000000000016" |
| InspectionId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع InspectionId | "00000000-0000-0000-0000-000000000006" |
| EvidenceVersionId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع EvidenceVersionId | "00000000-0000-0000-0000-00000000000c" |
| AssignmentId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع AssignmentId | "00000000-0000-0000-0000-000000000013" |
| Decision | varchar(16) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | approved/rejected؛ تصمیم مدرک و کل جدا | "approved" |
| CustomerReason | nvarchar(2000) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | دلیل قابل نمایش به مشتری؛ برای رد الزامی | null |
| DecidedAt | datetime2(3) | غیرمجاز | — | SYSUTCDATETIME() | زمان UTC سرور برای DecidedAt | "2026-10-27T08:30:00.000Z" |

### نمونه رکورد EvidenceReviews

```json
{
  "Id": "00000000-0000-0000-0000-000000000016",
  "InspectionId": "00000000-0000-0000-0000-000000000006",
  "EvidenceVersionId": "00000000-0000-0000-0000-00000000000c",
  "AssignmentId": "00000000-0000-0000-0000-000000000013",
  "Decision": "approved",
  "CustomerReason": null,
  "DecidedAt": "2026-10-27T08:30:00.000Z"
}
```

## InspectionReviews

تصمیم کل مستقل از تحویل به مقصد

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | جدول اختصاصی پیشنهادی؛ reuse فقط پس از اثبات برابری کلیدها، مجوز، تاریخچه، CAS و تراکنش مجاز است. یک API به معنی یک جدول تازه نیست. |
| هم‌زمانی | ثبت append-only/insert با کلید یکتا و idempotency؛ در صورت تغییر ارتباط، نسخه aggregate والد کنترل شود. تاریخچه درجا بازنویسی نشود. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | E09, G02 |
| API نویسنده | E09 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | AssignmentId, InspectionId → ReviewerAssignments(Id, InspectionId)؛ SubmissionId, InspectionId → InspectionSubmissions(Id, InspectionId) |
| UNIQUE | (InspectionId)؛ (Id, InspectionId)؛ (Id, InspectionId, SubmissionId) |
| CHECK | [Decision] IN ('approved','rejected')؛ [Decision]<>'rejected' OR ([CustomerReason] IS NOT NULL AND LEN(LTRIM(RTRIM([CustomerReason])))>0) |
| ایندکس | کلیدهای PK/UNIQUE؛ ایندکس اضافه پس از بررسی query plan |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | uniqueidentifier | غیرمجاز | PK | NEWSEQUENTIALID() | شناسه داخلی سرور | "00000000-0000-0000-0000-000000000017" |
| InspectionId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع InspectionId | "00000000-0000-0000-0000-000000000006" |
| AssignmentId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع AssignmentId | "00000000-0000-0000-0000-000000000013" |
| SubmissionId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع SubmissionId | "00000000-0000-0000-0000-000000000014" |
| Decision | varchar(16) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | approved/rejected؛ تصمیم مدرک و کل جدا | "approved" |
| CustomerReason | nvarchar(2000) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | دلیل قابل نمایش به مشتری؛ برای رد الزامی | null |
| DecidedAt | datetime2(3) | غیرمجاز | — | SYSUTCDATETIME() | زمان UTC سرور برای DecidedAt | "2026-10-27T08:30:00.000Z" |

### نمونه رکورد InspectionReviews

```json
{
  "Id": "00000000-0000-0000-0000-000000000017",
  "InspectionId": "00000000-0000-0000-0000-000000000006",
  "AssignmentId": "00000000-0000-0000-0000-000000000013",
  "SubmissionId": "00000000-0000-0000-0000-000000000014",
  "Decision": "approved",
  "CustomerReason": null,
  "DecidedAt": "2026-10-27T08:30:00.000Z"
}
```

## CorrectionRequests

دور اصلاح نسخه‌دار با حفظ اصل

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | جدول اختصاصی پیشنهادی؛ reuse فقط پس از اثبات برابری کلیدها، مجوز، تاریخچه، CAS و تراکنش مجاز است. یک API به معنی یک جدول تازه نیست. |
| هم‌زمانی | RowVersion فقط token باینری مقایسه است و زمان نیست؛ SQL آن را می‌سازد. CAS ردیف و قواعد aggregate در تراکنش کنترل شوند. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | D04, D05, D07, E05, E06 |
| API نویسنده | D07, E05, E06 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | OriginalSubmissionId, InspectionId → InspectionSubmissions(Id, InspectionId)؛ RequestedByAssignmentId, InspectionId → ReviewerAssignments(Id, InspectionId) |
| UNIQUE | (Id, InspectionId)؛ (InspectionId, RoundNumber) |
| CHECK | [RequestVersion]>0 AND [RoundNumber]>0؛ [Status] IN ('requested','resubmitting','resubmitted','resubmit-failed','resolved','superseded') |
| ایندکس | InspectionId, Active |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | uniqueidentifier | غیرمجاز | PK | NEWSEQUENTIALID() | شناسه داخلی سرور | "00000000-0000-0000-0000-000000000018" |
| InspectionId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع InspectionId | "00000000-0000-0000-0000-000000000006" |
| OriginalSubmissionId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع OriginalSubmissionId | "00000000-0000-0000-0000-000000000014" |
| RequestedByAssignmentId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع RequestedByAssignmentId | "00000000-0000-0000-0000-000000000013" |
| RequestVersion | int | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نسخه مثبت درخواست | 1 |
| RoundNumber | int | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | دور مثبت اصلاح | 1 |
| Status | varchar(24) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | وضعیت این بُعد؛ نه وضعیت مبهم تمام فرآیندها | "requested" |
| Active | bit | غیرمجاز | — | 1 | فعال‌بودن نگاشت یا ارجاع | true |
| RequestedAt | datetime2(3) | غیرمجاز | — | SYSUTCDATETIME() | زمان UTC سرور برای RequestedAt | "2026-10-27T08:30:00.000Z" |
| RowVersion | rowversion | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست | "0x0000000000000001" |

### نمونه رکورد CorrectionRequests

```json
{
  "Id": "00000000-0000-0000-0000-000000000018",
  "InspectionId": "00000000-0000-0000-0000-000000000006",
  "OriginalSubmissionId": "00000000-0000-0000-0000-000000000014",
  "RequestedByAssignmentId": "00000000-0000-0000-0000-000000000013",
  "RequestVersion": 1,
  "RoundNumber": 1,
  "Status": "requested",
  "Active": true,
  "RequestedAt": "2026-10-27T08:30:00.000Z",
  "RowVersion": "0x0000000000000001"
}
```

## CorrectionItems

قلم مشخص رسانه یا فیلد در درخواست

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | جدول اختصاصی پیشنهادی؛ reuse فقط پس از اثبات برابری کلیدها، مجوز، تاریخچه، CAS و تراکنش مجاز است. یک API به معنی یک جدول تازه نیست. |
| هم‌زمانی | RowVersion فقط token باینری مقایسه است و زمان نیست؛ SQL آن را می‌سازد. CAS ردیف و قواعد aggregate در تراکنش کنترل شوند. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | D05, D06, D07, D08, E05, E06, E07 |
| API نویسنده | D06, D07, D08, E05, E06, E07 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | RequestId, InspectionId → CorrectionRequests(Id, InspectionId)؛ EvidenceId, InspectionId → InspectionEvidence(Id, InspectionId)؛ OriginalVersionId, EvidenceId → EvidenceVersions(Id, EvidenceId)؛ CandidateVersionId, EvidenceId → EvidenceVersions(Id, EvidenceId) |
| UNIQUE | ندارد |
| CHECK | [Kind] IN ('photo','video-360','field')؛ ([Kind]='field' AND [FieldName] IS NOT NULL AND [FieldName] IN ('plate','color','modelYear') AND [EvidenceId] IS NULL AND [OriginalVersionId] IS NULL AND [CandidateVersionId] IS NULL) OR ([Kind] IN ('photo','video-360') AND [FieldName] IS NULL AND [EvidenceId] IS NOT NULL AND [OriginalVersionId] IS NOT NULL AND [ProposalJson] IS NULL)؛ [ProposalJson] IS NULL OR ISJSON([ProposalJson])=1؛ LEN(LTRIM(RTRIM([CustomerReason])))>0؛ [State] IN ('requested','submitted','approved') |
| ایندکس | UNIQUE RequestId, EvidenceId WHERE [EvidenceId] IS NOT NULL؛ UNIQUE RequestId, FieldName WHERE [FieldName] IS NOT NULL |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | uniqueidentifier | غیرمجاز | PK | NEWSEQUENTIALID() | شناسه داخلی سرور | "00000000-0000-0000-0000-000000000019" |
| RequestId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع RequestId | "00000000-0000-0000-0000-000000000018" |
| InspectionId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع InspectionId | "00000000-0000-0000-0000-000000000006" |
| Kind | varchar(16) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | photo/video-360 و در قلم اصلاح field | "photo" |
| EvidenceId | uniqueidentifier | مجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع EvidenceId | "00000000-0000-0000-0000-00000000000b" |
| OriginalVersionId | uniqueidentifier | مجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع OriginalVersionId | null |
| CandidateVersionId | uniqueidentifier | مجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع CandidateVersionId | null |
| FieldName | varchar(20) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | plate/color/modelYear؛ سایر فیلدها بسته‌اند | null |
| ProposalJson | nvarchar(max) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | پیشنهاد تایپ‌شده فیلد؛ فقط فراداده | JSON کامل در نمونه پایین |
| CustomerReason | nvarchar(2000) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | دلیل قابل نمایش به مشتری؛ برای رد الزامی | "نمونه" |
| State | varchar(16) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | وضعیت این منبع؛ قید CHECK حاکم است | "requested" |
| RowVersion | rowversion | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست | "0x0000000000000001" |

### نمونه رکورد CorrectionItems

```json
{
  "Id": "00000000-0000-0000-0000-000000000019",
  "RequestId": "00000000-0000-0000-0000-000000000018",
  "InspectionId": "00000000-0000-0000-0000-000000000006",
  "Kind": "photo",
  "EvidenceId": "00000000-0000-0000-0000-00000000000b",
  "OriginalVersionId": null,
  "CandidateVersionId": null,
  "FieldName": null,
  "ProposalJson": null,
  "CustomerReason": "نمونه",
  "State": "requested",
  "RowVersion": "0x0000000000000001"
}
```

## InternalNotes

یادداشت خصوصی کارکنان، خارج از DTO مشتری

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | جدول اختصاصی پیشنهادی؛ reuse فقط پس از اثبات برابری کلیدها، مجوز، تاریخچه، CAS و تراکنش مجاز است. یک API به معنی یک جدول تازه نیست. |
| هم‌زمانی | ثبت append-only/insert با کلید یکتا و idempotency؛ در صورت تغییر ارتباط، نسخه aggregate والد کنترل شود. تاریخچه درجا بازنویسی نشود. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | E02, E08 |
| API نویسنده | E08 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | AssignmentId, InspectionId → ReviewerAssignments(Id, InspectionId) |
| UNIQUE | ندارد |
| CHECK | LEN(LTRIM(RTRIM([Text])))>0 |
| ایندکس | InspectionId, CreatedAt |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | uniqueidentifier | غیرمجاز | PK | NEWSEQUENTIALID() | شناسه داخلی سرور | "00000000-0000-0000-0000-00000000001a" |
| InspectionId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع InspectionId | "00000000-0000-0000-0000-000000000006" |
| AssignmentId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع AssignmentId | "00000000-0000-0000-0000-000000000013" |
| Text | nvarchar(4000) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | یادداشت خصوصی؛ در خروجی مشتری ممنوع | "نمونه" |
| CreatedAt | datetime2(3) | غیرمجاز | — | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt | "2026-10-27T08:30:00.000Z" |

### نمونه رکورد InternalNotes

```json
{
  "Id": "00000000-0000-0000-0000-00000000001a",
  "InspectionId": "00000000-0000-0000-0000-000000000006",
  "AssignmentId": "00000000-0000-0000-0000-000000000013",
  "Text": "نمونه",
  "CreatedAt": "2026-10-27T08:30:00.000Z"
}
```

## InspectionStatusHistory

تاریخچه تغییر چرخه عمر

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | جدول اختصاصی پیشنهادی؛ reuse فقط پس از اثبات برابری کلیدها، مجوز، تاریخچه، CAS و تراکنش مجاز است. یک API به معنی یک جدول تازه نیست. |
| هم‌زمانی | ثبت append-only/insert با کلید یکتا و idempotency؛ در صورت تغییر ارتباط، نسخه aggregate والد کنترل شود. تاریخچه درجا بازنویسی نشود. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | D04, E10 |
| API نویسنده | D02, D07, D09, E03, E05, E06, E09, G02, G03 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | InspectionId → Inspections(Id) |
| UNIQUE | ندارد |
| CHECK | [FromStatus] IS NULL OR [FromStatus] IN ('DRAFT','UPLOAD_PENDING','SUBMITTED','UNDER_REVIEW','CHANGES_REQUESTED','REJECTED','REVIEW_APPROVED','FORWARD_PENDING','FORWARDED','FORWARD_FAILED')؛ [ToStatus] IN ('DRAFT','UPLOAD_PENDING','SUBMITTED','UNDER_REVIEW','CHANGES_REQUESTED','REJECTED','REVIEW_APPROVED','FORWARD_PENDING','FORWARDED','FORWARD_FAILED') |
| ایندکس | InspectionId, CreatedAt |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | uniqueidentifier | غیرمجاز | PK | NEWSEQUENTIALID() | شناسه داخلی سرور | "00000000-0000-0000-0000-00000000001b" |
| InspectionId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع InspectionId | "00000000-0000-0000-0000-000000000006" |
| FromStatus | varchar(24) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | فراداده FromStatus در InspectionStatusHistory | null |
| ToStatus | varchar(24) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | فراداده ToStatus در InspectionStatusHistory | "DRAFT" |
| ActorReference | nvarchar(160) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | فراداده ActorReference در InspectionStatusHistory | "نمونه" |
| ReasonCode | varchar(80) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | فراداده ReasonCode در InspectionStatusHistory | "example" |
| CreatedAt | datetime2(3) | غیرمجاز | — | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt | "2026-10-27T08:30:00.000Z" |

### نمونه رکورد InspectionStatusHistory

```json
{
  "Id": "00000000-0000-0000-0000-00000000001b",
  "InspectionId": "00000000-0000-0000-0000-000000000006",
  "FromStatus": null,
  "ToStatus": "DRAFT",
  "ActorReference": "نمونه",
  "ReasonCode": "example",
  "CreatedAt": "2026-10-27T08:30:00.000Z"
}
```

## IdempotencyRecords

رزرو و نتیجه پایدار فرمان

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | جدول اختصاصی پیشنهادی؛ reuse فقط پس از اثبات برابری کلیدها، مجوز، تاریخچه، CAS و تراکنش مجاز است. یک API به معنی یک جدول تازه نیست. |
| هم‌زمانی | RowVersion فقط token باینری مقایسه است و زمان نیست؛ SQL آن را می‌سازد. CAS ردیف و قواعد aggregate در تراکنش کنترل شوند. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | A03, A04, B01, B06, B07, B09, B10, C01, C02, C03, C07, D02, D03, D06, D07, D08, D09, E03, E04, E05, E06, E07, E08, E09, F02, F03, F04, F06, F07, F08, F09, F10, F11, G01, G02, G03, G04 |
| API نویسنده | A03, A04, B01, B06, B07, B09, B10, C01, C02, C03, C07, D02, D06, D07, D08, D09, E03, E04, E05, E06, E07, E08, E09, F02, F03, F04, F06, F07, F08, F09, F10, F11, G01, G02, G03, G04 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | ندارد |
| UNIQUE | (ScopeKey, CommandKey) |
| CHECK | [State] IN ('reserved','completed','failed')؛ [ResponseJson] IS NULL OR ISJSON([ResponseJson])=1؛ [ResponseStatus] IS NULL OR [ResponseStatus] BETWEEN 100 AND 599 |
| ایندکس | State, LeaseUntil |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | uniqueidentifier | غیرمجاز | PK | NEWSEQUENTIALID() | شناسه داخلی سرور | "00000000-0000-0000-0000-00000000001c" |
| ScopeKey | nvarchar(200) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نصب + عامل + عملیات + منبع | "brokerage-example:subject-example:submit:insp-example-01" |
| CommandKey | varchar(100) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | کلید پایدار فرمان | "command-example" |
| RequestHash | binary(32) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | هش بدنه canonical فرمان | "0x0000000000000000000000000000000000000000000000000000000000000000" |
| State | varchar(16) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | وضعیت این منبع؛ قید CHECK حاکم است | "reserved" |
| ResponseStatus | smallint | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | فراداده ResponseStatus در IdempotencyRecords | null |
| ResponseJson | nvarchar(max) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نتیجه whitelist بدون token، مسیر خصوصی یا رسانه | JSON کامل در نمونه پایین |
| LeaseUntil | datetime2(3) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | زمان انقضای مالکیت موقت کارگر | null |
| ExpiresAt | datetime2(3) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | زمان UTC سرور برای ExpiresAt | null |
| CreatedAt | datetime2(3) | غیرمجاز | — | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt | "2026-10-27T08:30:00.000Z" |
| RowVersion | rowversion | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست | "0x0000000000000001" |

### نمونه رکورد IdempotencyRecords

```json
{
  "Id": "00000000-0000-0000-0000-00000000001c",
  "ScopeKey": "brokerage-example:subject-example:submit:insp-example-01",
  "CommandKey": "command-example",
  "RequestHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "State": "reserved",
  "ResponseStatus": null,
  "ResponseJson": null,
  "LeaseUntil": null,
  "ExpiresAt": null,
  "CreatedAt": "2026-10-27T08:30:00.000Z",
  "RowVersion": "0x0000000000000001"
}
```

## ForwardingJobs

outbox پایدار نسخه تأییدشده

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | جدول اختصاصی پیشنهادی؛ reuse فقط پس از اثبات برابری کلیدها، مجوز، تاریخچه، CAS و تراکنش مجاز است. یک API به معنی یک جدول تازه نیست. |
| هم‌زمانی | RowVersion فقط token باینری مقایسه است و زمان نیست؛ SQL آن را می‌سازد. CAS ردیف و قواعد aggregate در تراکنش کنترل شوند. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | D04, E09, G02, G03, G04, G05 |
| API نویسنده | E09, G02, G03, G04 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | InspectionReviewId, InspectionId, SubmissionId → InspectionReviews(Id, InspectionId, SubmissionId)؛ SubmissionId, InspectionId → InspectionSubmissions(Id, InspectionId) |
| UNIQUE | (InspectionReviewId, DestinationKey)؛ (DeliveryKey) |
| CHECK | [State] IN ('ready','sending','retrying','acknowledged','failed')؛ [AttemptCount]>=0؛ [State]<>'acknowledged' OR ([AcknowledgementId] IS NOT NULL AND [AcknowledgedAt] IS NOT NULL) |
| ایندکس | State, NextRetryAt |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | uniqueidentifier | غیرمجاز | PK | NEWSEQUENTIALID() | شناسه داخلی سرور | "00000000-0000-0000-0000-00000000001d" |
| InspectionId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع InspectionId | "00000000-0000-0000-0000-000000000006" |
| InspectionReviewId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع InspectionReviewId | "00000000-0000-0000-0000-000000000017" |
| SubmissionId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع SubmissionId | "00000000-0000-0000-0000-000000000014" |
| DestinationKey | nvarchar(80) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | مرجع allowlist سرور؛ نه URL یا credential | "نمونه" |
| DeliveryKey | uniqueidentifier | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه ثابت مقصد برای تکرار امن | "00000000-0000-0000-0000-00000000001d" |
| State | varchar(16) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | وضعیت این منبع؛ قید CHECK حاکم است | "ready" |
| AttemptCount | int | غیرمجاز | — | 0 | شمار تلاش غیرمنفی | 0 |
| NextRetryAt | datetime2(3) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | زمان تلاش بعدی با backoff محدود | null |
| LeaseUntil | datetime2(3) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | زمان انقضای مالکیت موقت کارگر | null |
| AcknowledgementId | nvarchar(160) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه تأیید معتبر مقصد | null |
| AcknowledgedAt | datetime2(3) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | زمان UTC سرور برای AcknowledgedAt | null |
| CreatedAt | datetime2(3) | غیرمجاز | — | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt | "2026-10-27T08:30:00.000Z" |
| RowVersion | rowversion | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست | "0x0000000000000001" |

### نمونه رکورد ForwardingJobs

```json
{
  "Id": "00000000-0000-0000-0000-00000000001d",
  "InspectionId": "00000000-0000-0000-0000-000000000006",
  "InspectionReviewId": "00000000-0000-0000-0000-000000000017",
  "SubmissionId": "00000000-0000-0000-0000-000000000014",
  "DestinationKey": "نمونه",
  "DeliveryKey": "00000000-0000-0000-0000-00000000001d",
  "State": "ready",
  "AttemptCount": 0,
  "NextRetryAt": null,
  "LeaseUntil": null,
  "AcknowledgementId": null,
  "AcknowledgedAt": null,
  "CreatedAt": "2026-10-27T08:30:00.000Z",
  "RowVersion": "0x0000000000000001"
}
```

## ForwardingAttempts

تلاش‌های تحویل مستقل و محفوظ

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | جدول اختصاصی پیشنهادی؛ reuse فقط پس از اثبات برابری کلیدها، مجوز، تاریخچه، CAS و تراکنش مجاز است. یک API به معنی یک جدول تازه نیست. |
| هم‌زمانی | ثبت append-only/insert با کلید یکتا و idempotency؛ در صورت تغییر ارتباط، نسخه aggregate والد کنترل شود. تاریخچه درجا بازنویسی نشود. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | G03, G04 |
| API نویسنده | G03 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | JobId → ForwardingJobs(Id) |
| UNIQUE | (JobId, AttemptNumber) |
| CHECK | [AttemptNumber]>0؛ [HttpStatus] IS NULL OR [HttpStatus] BETWEEN 100 AND 599 |
| ایندکس | کلیدهای PK/UNIQUE؛ ایندکس اضافه پس از بررسی query plan |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | uniqueidentifier | غیرمجاز | PK | NEWSEQUENTIALID() | شناسه داخلی سرور | "00000000-0000-0000-0000-00000000001e" |
| JobId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع JobId | "00000000-0000-0000-0000-00000000001d" |
| AttemptNumber | int | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | شماره مثبت تلاش همان درخواست یا کار | 1 |
| StartedAt | datetime2(3) | غیرمجاز | — | SYSUTCDATETIME() | زمان UTC سرور برای StartedAt | "2026-10-27T08:30:00.000Z" |
| FinishedAt | datetime2(3) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | زمان UTC سرور برای FinishedAt | null |
| HttpStatus | smallint | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | فراداده HttpStatus در ForwardingAttempts | null |
| FailureCode | varchar(80) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | کد امن؛ بدون stack، مسیر یا راز | null |

### نمونه رکورد ForwardingAttempts

```json
{
  "Id": "00000000-0000-0000-0000-00000000001e",
  "JobId": "00000000-0000-0000-0000-00000000001d",
  "AttemptNumber": 1,
  "StartedAt": "2026-10-27T08:30:00.000Z",
  "FinishedAt": null,
  "HttpStatus": null,
  "FailureCode": null
}
```

## BrandingAssets

دارایی عمومی ایمن برند، جدا از شواهد

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | جدول اختصاصی پیشنهادی؛ reuse فقط پس از اثبات برابری کلیدها، مجوز، تاریخچه، CAS و تراکنش مجاز است. یک API به معنی یک جدول تازه نیست. |
| هم‌زمانی | ثبت append-only/insert با کلید یکتا و idempotency؛ در صورت تغییر ارتباط، نسخه aggregate والد کنترل شود. تاریخچه درجا بازنویسی نشود. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | A02, F05, F08 |
| API نویسنده | F08 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | ندارد |
| UNIQUE | (PublicRelativePath) |
| CHECK | [ByteSize]>0 AND [Width]>0 AND [Height]>0 |
| ایندکس | کلیدهای PK/UNIQUE؛ ایندکس اضافه پس از بررسی query plan |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | uniqueidentifier | غیرمجاز | PK | NEWSEQUENTIALID() | شناسه داخلی سرور | "00000000-0000-0000-0000-00000000001f" |
| SlotCode | nvarchar(80) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | فراداده SlotCode در BrandingAssets | "نمونه" |
| PublicRelativePath | nvarchar(450) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | مسیر عمومی برند؛ جدا از ریشه خصوصی شواهد | "/branding/example-brokerage-logo.webp" |
| MimeType | varchar(127) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نوع واقعی تأییدشده رسانه | "image/webp" |
| ByteSize | bigint | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | اندازه واقعی مورد تطبیق در complete | 1048576 |
| Width | int | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | عرض مثبت رسانه | 320 |
| Height | int | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | ارتفاع مثبت رسانه | 160 |
| Sha256 | binary(32) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | هش ۳۲ بایتی؛ فراداده است و رسانه نیست | "0x0000000000000000000000000000000000000000000000000000000000000000" |
| CreatedAt | datetime2(3) | غیرمجاز | — | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt | "2026-10-27T08:30:00.000Z" |

### نمونه رکورد BrandingAssets

```json
{
  "Id": "00000000-0000-0000-0000-00000000001f",
  "SlotCode": "نمونه",
  "PublicRelativePath": "/branding/example-brokerage-logo.webp",
  "MimeType": "image/webp",
  "ByteSize": 1048576,
  "Width": 320,
  "Height": 160,
  "Sha256": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "CreatedAt": "2026-10-27T08:30:00.000Z"
}
```

## SiteSettingsVersions

نسخه draft یا عمومی، بدون راز زیرساخت

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | جدول اختصاصی پیشنهادی؛ reuse فقط پس از اثبات برابری کلیدها، مجوز، تاریخچه، CAS و تراکنش مجاز است. یک API به معنی یک جدول تازه نیست. |
| هم‌زمانی | ثبت append-only/insert با کلید یکتا و idempotency؛ در صورت تغییر ارتباط، نسخه aggregate والد کنترل شود. تاریخچه درجا بازنویسی نشود. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | A02, F05, F06, F07, F09 |
| API نویسنده | F06, F07, F09 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | CreatedBy → StaffUsers(Id) |
| UNIQUE | (Version) |
| CHECK | [Version]>0 AND [SchemaVersion]>0؛ [State] IN ('draft','published','archived')؛ ISJSON([SettingsJson])=1 |
| ایندکس | کلیدهای PK/UNIQUE؛ ایندکس اضافه پس از بررسی query plan |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | uniqueidentifier | غیرمجاز | PK | NEWSEQUENTIALID() | شناسه داخلی سرور | "00000000-0000-0000-0000-000000000020" |
| Version | int | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نسخه مثبت منبع | 2 |
| State | varchar(16) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | وضعیت این منبع؛ قید CHECK حاکم است | "draft" |
| SchemaVersion | int | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | فراداده SchemaVersion در SiteSettingsVersions | 1 |
| SettingsJson | nvarchar(max) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | تنظیمات عمومی whitelist؛ بدون راز Neshan یا احراز هویت | JSON کامل در نمونه پایین |
| CreatedBy | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع CreatedBy | "00000000-0000-0000-0000-000000000010" |
| CreatedAt | datetime2(3) | غیرمجاز | — | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt | "2026-10-27T08:30:00.000Z" |
| PublishedAt | datetime2(3) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | زمان UTC سرور برای PublishedAt | null |

### نمونه رکورد SiteSettingsVersions

```json
{
  "Id": "00000000-0000-0000-0000-000000000020",
  "Version": 2,
  "State": "draft",
  "SchemaVersion": 1,
  "SettingsJson": "{\"schemaVersion\": 1, \"tenantId\": \"demo\", \"version\": 2, \"publishedAt\": \"2026-10-26T09:00:00Z\", \"identity\": {\"brokerageName\": \"کارگزاری نمونه\", \"appTitle\": \"بازدید خودرو\", \"logo\": null, \"favicon\": null, \"publicEmail\": \"support@example.invalid\", \"publicPhone\": \"نمونه قراردادی\"}, \"theme\": {\"primary\": \"#047857\", \"secondary\": \"#475569\", \"background\": \"#FFFFFF\", \"neutral\": \"#64748B\", \"onPrimary\": \"#FFFFFF\", \"onBackground\": \"#0F172A\", \"accent\": \"#F59E0B\", \"haloColor\": \"#10B981\", \"haloIntensity\": 35}, \"images\": {\"landing\": null, \"referral\": null, \"otp\": null, \"readiness\": null, \"consent\": null, \"submission\": null}, \"application\": {\"apiBaseUrl\": \"/api/bazdid\", \"contractVersion\": \"1\", \"template\": {\"id\": \"body-image-guided\", \"version\": 2}, \"features\": {\"nativeCaptureFallback\": true, \"additionalEvidence\": true, \"supportLink\": false}, \"locationMap\": {\"enabled\": true, \"webMapKey\": null, \"mapType\": \"dreamy\", \"reverseGeocoding\": \"api\", \"initialViewport\": {\"latitude\": 35.699739, \"longitude\": 51.338097, \"zoom\": 12}}}}",
  "CreatedBy": "00000000-0000-0000-0000-000000000010",
  "CreatedAt": "2026-10-27T08:30:00.000Z",
  "PublishedAt": null
}
```

## SiteSettings

اشاره‌گر تنها ارائه‌دهنده تنظیمات

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | جدول اختصاصی پیشنهادی؛ reuse فقط پس از اثبات برابری کلیدها، مجوز، تاریخچه، CAS و تراکنش مجاز است. یک API به معنی یک جدول تازه نیست. |
| هم‌زمانی | RowVersion فقط token باینری مقایسه است و زمان نیست؛ SQL آن را می‌سازد. CAS ردیف و قواعد aggregate در تراکنش کنترل شوند. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | A02, F05, F06, F07, F09 |
| API نویسنده | F06, F07, F09 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | PublishedVersionId → SiteSettingsVersions(Id)؛ DraftVersionId → SiteSettingsVersions(Id) |
| UNIQUE | ندارد |
| CHECK | [Id]=1 |
| ایندکس | کلیدهای PK/UNIQUE؛ ایندکس اضافه پس از بررسی query plan |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | tinyint | غیرمجاز | PK | 1 | شناسه داخلی سرور | 1 |
| PublishedVersionId | uniqueidentifier | مجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع PublishedVersionId | null |
| DraftVersionId | uniqueidentifier | مجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع DraftVersionId | null |
| RowVersion | rowversion | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست | "0x0000000000000001" |

### نمونه رکورد SiteSettings

```json
{
  "Id": 1,
  "PublishedVersionId": null,
  "DraftVersionId": null,
  "RowVersion": "0x0000000000000001"
}
```

## SiteSettingsAssetLinks

ارجاع نسخه تنظیمات به دارایی برند

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | جدول اختصاصی پیشنهادی؛ reuse فقط پس از اثبات برابری کلیدها، مجوز، تاریخچه، CAS و تراکنش مجاز است. یک API به معنی یک جدول تازه نیست. |
| هم‌زمانی | ثبت append-only/insert با کلید یکتا و idempotency؛ در صورت تغییر ارتباط، نسخه aggregate والد کنترل شود. تاریخچه درجا بازنویسی نشود. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | A02, F05, F06, F08, F09 |
| API نویسنده | F06, F09 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | SettingsVersionId, SlotCode |
| FK | SettingsVersionId → SiteSettingsVersions(Id)؛ BrandingAssetId → BrandingAssets(Id) |
| UNIQUE | ندارد |
| CHECK | قیود نوع/سرویس |
| ایندکس | کلیدهای PK/UNIQUE؛ ایندکس اضافه پس از بررسی query plan |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| SettingsVersionId | uniqueidentifier | غیرمجاز | PK/FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع SettingsVersionId | "00000000-0000-0000-0000-000000000020" |
| SlotCode | nvarchar(80) | غیرمجاز | PK | تخصیص صریح سرویس؛ rowversion/identity خودکار | فراداده SlotCode در SiteSettingsAssetLinks | "نمونه" |
| BrandingAssetId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع BrandingAssetId | "00000000-0000-0000-0000-00000000001f" |

### نمونه رکورد SiteSettingsAssetLinks

```json
{
  "SettingsVersionId": "00000000-0000-0000-0000-000000000020",
  "SlotCode": "نمونه",
  "BrandingAssetId": "00000000-0000-0000-0000-00000000001f"
}
```

## WebhookSubscriptions

رویداد و مقصد سروری شناخته‌شده

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | اختیاری/مشروط |
| شرط | تنها در صورت فعال‌سازی اشتراک رویدادهای مصوب؛ مقصد دلخواه مرورگر مجاز نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | جدول اختصاصی پیشنهادی؛ reuse فقط پس از اثبات برابری کلیدها، مجوز، تاریخچه، CAS و تراکنش مجاز است. یک API به معنی یک جدول تازه نیست. |
| هم‌زمانی | RowVersion فقط token باینری مقایسه است و زمان نیست؛ SQL آن را می‌سازد. CAS ردیف و قواعد aggregate در تراکنش کنترل شوند. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | F11, G01 |
| API نویسنده | F11 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | ندارد |
| UNIQUE | (EventCode, DestinationKey) |
| CHECK | قیود نوع/سرویس |
| ایندکس | کلیدهای PK/UNIQUE؛ ایندکس اضافه پس از بررسی query plan |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | uniqueidentifier | غیرمجاز | PK | NEWSEQUENTIALID() | شناسه داخلی سرور | "00000000-0000-0000-0000-000000000023" |
| EventCode | varchar(80) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | فراداده EventCode در WebhookSubscriptions | "example" |
| DestinationKey | nvarchar(80) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | مرجع allowlist سرور؛ نه URL یا credential | "نمونه" |
| Enabled | bit | غیرمجاز | — | 0 | فراداده Enabled در WebhookSubscriptions | false |
| RowVersion | rowversion | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست | "0x0000000000000001" |

### نمونه رکورد WebhookSubscriptions

```json
{
  "Id": "00000000-0000-0000-0000-000000000023",
  "EventCode": "example",
  "DestinationKey": "نمونه",
  "Enabled": false,
  "RowVersion": "0x0000000000000001"
}
```

## AuditLogs

audit سرور، بدون راز یا رسانه

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | الزامی در جریان فعلی |
| شرط | مسئولیت این جدول برای جریان فعلی الزامی است؛ الزام به ایجاد جدول فیزیکی تکراری در صورت reuse مصوب نیست. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | زیرساخت audit موجود در صورت append-only بودن، redaction، scope و قابلیت جست‌وجو قابل استفاده است. |
| هم‌زمانی | ثبت append-only/insert با کلید یکتا و idempotency؛ در صورت تغییر ارتباط، نسخه aggregate والد کنترل شود. تاریخچه درجا بازنویسی نشود. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | خواندن زیرساختی در سرویس والد؛ API مستقیم ندارد |
| API نویسنده | A03, A04, B01, B06, B07, B09, B10, C01, C02, C03, C07, D02, D06, D07, D08, D09, E03, E04, E05, E06, E07, E08, E09, F02, F03, F04, F06, F07, F08, F09, F10, F11, G01, G02, G03, G04 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | InspectionId → Inspections(Id) |
| UNIQUE | ندارد |
| CHECK | [MetadataJson] IS NULL OR ISJSON([MetadataJson])=1 |
| ایندکس | InspectionId, CreatedAt؛ ActionCode, CreatedAt |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | bigint IDENTITY(1,1) | غیرمجاز | PK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه داخلی سرور | 1 |
| ActorReference | nvarchar(160) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | فراداده ActorReference در AuditLogs | "نمونه" |
| InspectionId | uniqueidentifier | مجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع InspectionId | null |
| ActionCode | varchar(100) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | فراداده ActionCode در AuditLogs | "example" |
| ResourceType | varchar(80) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | فراداده ResourceType در AuditLogs | "example" |
| ResourceId | nvarchar(160) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | فراداده ResourceId در AuditLogs | "نمونه" |
| CorrelationId | varchar(80) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | فراداده CorrelationId در AuditLogs | "example" |
| MetadataJson | nvarchar(max) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | جزئیات whitelist بدون راز یا باینری | JSON کامل در نمونه پایین |
| CreatedAt | datetime2(3) | غیرمجاز | — | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt | "2026-10-27T08:30:00.000Z" |

### نمونه رکورد AuditLogs

```json
{
  "Id": 1,
  "ActorReference": "نمونه",
  "InspectionId": null,
  "ActionCode": "example",
  "ResourceType": "example",
  "ResourceId": "نمونه",
  "CorrelationId": "example",
  "MetadataJson": "{\"action\":\"example\"}",
  "CreatedAt": "2026-10-27T08:30:00.000Z"
}
```

## NotificationOutbox

اعلان اختیاری مصوب؛ نه جایگزین وضعیت سامانه

| موضوع | تعریف |
|---|---|
| طبقه‌بندی | اختیاری/مشروط |
| شرط | فقط با تصویب کانال/رضایت اعلان؛ نبود آن وضعیت/رسید را از دسترس خارج نمی‌کند. |
| مالکیت | متعلق به برنامه بازدید همین کارگزاری؛ در صورت snapshot، تاریخچه immutable و مستقل از تغییرات بعدی مبدأ است. |
| استفاده مجدد | outbox مصوب موجود در همان deployment با یکتایی event/channel و retry قابل جایگزینی است. |
| هم‌زمانی | RowVersion فقط token باینری مقایسه است و زمان نیست؛ SQL آن را می‌سازد. CAS ردیف و قواعد aggregate در تراکنش کنترل شوند. |
| نگهداری | هیچ مدت حذف خودکار تصویب نشده است؛ active/submission/history/legal-hold و روابط قبل از حذف بررسی شوند. مدت، backup و حذف با D12 تصویب شود. |
| مجوز و محرمانگی | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |
| API خواننده | G01 |
| API نویسنده | G01 |
| تراکنش | نوشتن، CAS، audit و idempotency در تراکنش کوتاه SQL؛ I/O مستقل و نیازمند reconciliation. |
| PK | Id |
| FK | InspectionId → Inspections(Id) |
| UNIQUE | (EventId, ChannelCode) |
| CHECK | [State] IN ('queued','sending','sent','failed')؛ [AttemptCount]>=0 |
| ایندکس | State, NextRetryAt |

| ستون | نوع/طول/دقت SQL | NULL | کلید | پیش‌فرض | معنا | نمونه |
|---|---|---|---|---|---|---|
| Id | uniqueidentifier | غیرمجاز | PK | NEWSEQUENTIALID() | شناسه داخلی سرور | "00000000-0000-0000-0000-000000000025" |
| InspectionId | uniqueidentifier | غیرمجاز | FK | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع InspectionId | "00000000-0000-0000-0000-000000000006" |
| EventId | uniqueidentifier | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | شناسه مرجع EventId | "00000000-0000-0000-0000-000000000025" |
| ChannelCode | varchar(16) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | فراداده ChannelCode در NotificationOutbox | "example" |
| RecipientReference | nvarchar(160) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | مرجع هویت مبدأ؛ نه شماره دلخواه مرورگر | "نمونه" |
| TemplateKey | nvarchar(80) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | کلید منطقی قالب | "body-image-guided" |
| State | varchar(16) | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | وضعیت این منبع؛ قید CHECK حاکم است | "queued" |
| AttemptCount | int | غیرمجاز | — | 0 | شمار تلاش غیرمنفی | 0 |
| NextRetryAt | datetime2(3) | مجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | زمان تلاش بعدی با backoff محدود | null |
| CreatedAt | datetime2(3) | غیرمجاز | — | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt | "2026-10-27T08:30:00.000Z" |
| RowVersion | rowversion | غیرمجاز | — | تخصیص صریح سرویس؛ rowversion/identity خودکار | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست | "0x0000000000000001" |

### نمونه رکورد NotificationOutbox

```json
{
  "Id": "00000000-0000-0000-0000-000000000025",
  "InspectionId": "00000000-0000-0000-0000-000000000006",
  "EventId": "00000000-0000-0000-0000-000000000025",
  "ChannelCode": "example",
  "RecipientReference": "نمونه",
  "TemplateKey": "body-image-guided",
  "State": "queued",
  "AttemptCount": 0,
  "NextRetryAt": null,
  "CreatedAt": "2026-10-27T08:30:00.000Z",
  "RowVersion": "0x0000000000000001"
}
```
