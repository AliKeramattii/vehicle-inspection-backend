# طرح پیشنهادی SQL Server

وضعیت: **پیشنهادی و نیازمند تصویب Backend**. تاریخ بررسی منابع: 2026-10-27. این اسناد هیچ سرویس تولیدی یا migration اجراشده‌ای را اثبات نمی‌کنند.

این طرح ۳۷ جدول و ۳۰۲ ستون دارد و اجرا نشده است. هدف SQL Server2022 برای syntax است؛ نسخه واقعی، collation، مهاجرت‌ها و تصمیم‌های نهایی باید تصویب شوند. [SQL پیشنهادی](sql/PROPOSED_SCHEMA.sql)، [روابط](07-DATABASE-RELATIONSHIPS.md) و [نگاشت API](20-API-DATABASE-MAPPING.md) را همراه بخوانید.

## مرز مالکیت و نرمال‌سازی

هر کارگزاری یک پایگاه مستقل دارد. Customers و StaffUsers فقط نگاشت حداقلی شناسه صادرکننده/subject هستند؛ رمز، OTP و پروفایل اصلی بیمه تکثیر نمی‌شوند. Vehicles snapshot همان تلاش است، نه مجوز تغییر منبع بیمه. یک Inspections برابر یک تلاش است؛ جدول InspectionAttempts جدا لازم نیست. Additional Evidence همان تلاش و tracking را حفظ می‌کند؛ رد کامل تنها با فرمان صریح یک تلاش خالی جدید می‌سازد.

SQL فقط metadata، snapshot ساختاریافته و hash/نسخه/مسیر نگه می‌دارد. nvarchar(max) در این طرح برای JSON/text است، نه Base64 رسانه. binary(32) صرفاً checksum است. عکس/ویدیو، FILESTREAM و VARBINARY(MAX) رسانه در این طرح وجود ندارد. نوع‌های زمانی datetime2 UTC هستند؛ rowversion زمان نیست.

## محدودیت‌های مدل

FK‌های ترکیبی مانع اتصال نسخه/درخواست/رسید به پرونده دیگر می‌شوند. CHECK جای مجوز، ظرفیت، توالی وضعیت یا تعداد دقیق الزامات را نمی‌گیرد. عضویت قالب، ۱۱ photo + video جدا، عدم تکرار گزینه، اعتبار MIME، path containment/reparse، اصل خوب/جایگزین، و دلیل رد در سرویس و تراکنش نیز کنترل شوند. collations رشته‌های فنی باید دقیق و مورد توافق باشند؛ نام فایل تولیدی canonical و بدون تصادم حروف بزرگ/کوچک باشد. هیچ cascade delete برای شواهد پیشنهاد نشده است.

## Customers

نگاشت حداقلی هویت مبدأ؛ بدون رمز یا تکثیر پروفایل بیمه

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | uniqueidentifier | خیر | NEWSEQUENTIALID() | شناسه داخلی سرور |
| SourceIssuer | nvarchar(200) | خیر | ندارد / مدیریت صریح سرور | صادرکننده معتبر هویت مبدأ |
| SourceSubjectId | nvarchar(128) | خیر | ندارد / مدیریت صریح سرور | شناسه پایدار مشتری نزد صادرکننده مبدأ |
| CreatedAt | datetime2(3) | خیر | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | (SourceIssuer, SourceSubjectId) |
| FK | ندارد |
| CHECK | کنترل دامنه در سرویس و نوع ستون |
| ایندکس | PK/UNIQUE؛ ایندکس اضافی تنها با query plan |
| عملیات مرتبط | A03, A05, A07, A08, A09, B04 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## SourceInsuranceRequests

درخواست بیمه متعلق به مشتری

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | uniqueidentifier | خیر | NEWSEQUENTIALID() | شناسه داخلی سرور |
| CustomerId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع CustomerId |
| SourceSystem | nvarchar(80) | خیر | ندارد / مدیریت صریح سرور | فراداده SourceSystem در SourceInsuranceRequests |
| ExternalRequestId | nvarchar(128) | خیر | ندارد / مدیریت صریح سرور | شناسه درخواست بیمه در سامانه مبدأ |
| SourceVehicleReference | nvarchar(128) | بله | ندارد / مدیریت صریح سرور | مرجع خودرو در منبع بیمه |
| CreatedAt | datetime2(3) | خیر | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | (SourceSystem, ExternalRequestId) |
| FK | (CustomerId) → Customers(Id) |
| CHECK | کنترل دامنه در سرویس و نوع ستون |
| ایندکس | (CustomerId, CreatedAt) |
| عملیات مرتبط | A03, A05, A07, A08, A09, B01, B03, B04, D09 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## InspectionTemplates

نسخه مستقل قالب؛ پس از انتشار تغییرناپذیر

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | uniqueidentifier | خیر | NEWSEQUENTIALID() | شناسه داخلی سرور |
| TemplateKey | nvarchar(80) | خیر | ندارد / مدیریت صریح سرور | کلید منطقی قالب |
| Version | int | خیر | ندارد / مدیریت صریح سرور | نسخه مثبت منبع |
| PhotoPolicyVersion | int | خیر | ندارد / مدیریت صریح سرور | نسخه ۱ تاریخی یا ۲ فعلی |
| State | varchar(16) | خیر | ندارد / مدیریت صریح سرور | وضعیت این منبع؛ قید CHECK حاکم است |
| SnapshotJson | nvarchar(max) | خیر | ندارد / مدیریت صریح سرور | snapshot فقط فراداده؛ بایت/Base64 رسانه ممنوع |
| CreatedAt | datetime2(3) | خیر | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt |
| PublishedAt | datetime2(3) | بله | ندارد / مدیریت صریح سرور | زمان UTC سرور برای PublishedAt |
| RowVersion | rowversion | خیر | ندارد / مدیریت صریح سرور | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | (TemplateKey, Version) |
| FK | ندارد |
| CHECK | [Version]>0؛ [PhotoPolicyVersion] IN (1,2)؛ [State] IN ('draft','published','archived')؛ ISJSON([SnapshotJson])=1 |
| ایندکس | PK/UNIQUE؛ ایندکس اضافی تنها با query plan |
| عملیات مرتبط | B01, B05, F01, F02, F03, F04 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## EvidenceRequirements

جایگاه الزام؛ عکس و ویدیو جدا هستند

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | uniqueidentifier | خیر | NEWSEQUENTIALID() | شناسه داخلی سرور |
| TemplateId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع TemplateId |
| RequirementKey | nvarchar(80) | خیر | ندارد / مدیریت صریح سرور | شناسه منطقی مانند spec-plate یا video-360 با نوع جدا |
| Kind | varchar(16) | خیر | ندارد / مدیریت صریح سرور | photo/video-360 و در قلم اصلاح field |
| SectionKey | nvarchar(80) | بله | ندارد / مدیریت صریح سرور | بخش عکس؛ برای ویدیو NULL |
| Required | bit | خیر | 1 | الزام نسخه قالب |
| HasChoice | bit | خیر | 0 | از تعریف ثابت الزام؛ فقط گروه VIN دارای گزینه است |
| SortOrder | int | خیر | ندارد / مدیریت صریح سرور | ترتیب نمایش |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | (TemplateId, RequirementKey)؛ (Id, TemplateId)؛ (Id, HasChoice) |
| FK | (TemplateId) → InspectionTemplates(Id) |
| CHECK | [Kind] IN ('photo','video-360')؛ [SortOrder]>0؛ ([Kind]='photo' AND [SectionKey] IS NOT NULL) OR ([Kind]='video-360' AND [SectionKey] IS NULL AND [HasChoice]=0) |
| ایندکس | PK/UNIQUE؛ ایندکس اضافی تنها با query plan |
| عملیات مرتبط | B05, F02, F03 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## RequirementAlternatives

چهار محل مجاز همان یک الزام VIN

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | uniqueidentifier | خیر | NEWSEQUENTIALID() | شناسه داخلی سرور |
| RequirementId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع RequirementId |
| AlternativeKey | varchar(20) | خیر | ندارد / مدیریت صریح سرور | pillar/engine/seat/windshield |
| TitleFa | nvarchar(250) | خیر | ندارد / مدیریت صریح سرور | عنوان فارسی |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | (RequirementId, AlternativeKey)؛ (Id, RequirementId) |
| FK | (RequirementId) → EvidenceRequirements(Id) |
| CHECK | [AlternativeKey] IN ('pillar','engine','seat','windshield') |
| ایندکس | PK/UNIQUE؛ ایندکس اضافی تنها با query plan |
| عملیات مرتبط | B05, F02, F03 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## Inspections

هر ردیف یک تلاش مستقل و دارای سابقه

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | uniqueidentifier | خیر | NEWSEQUENTIALID() | شناسه داخلی سرور |
| PublicId | nvarchar(80) | خیر | ندارد / مدیریت صریح سرور | شناسه opaque عمومی؛ داده قدیمی قابل نگاشت است |
| SourceRequestId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع SourceRequestId |
| TemplateId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع TemplateId |
| AttemptNumber | int | خیر | ندارد / مدیریت صریح سرور | شماره مثبت تلاش همان درخواست یا کار |
| PreviousInspectionId | uniqueidentifier | بله | ندارد / مدیریت صریح سرور | شناسه مرجع PreviousInspectionId |
| TrackingCode | nvarchar(80) | خیر | ندارد / مدیریت صریح سرور | کد پیگیری نمایشی؛ ابزار احراز هویت نیست |
| Status | varchar(24) | خیر | ندارد / مدیریت صریح سرور | وضعیت این بُعد؛ نه وضعیت مبهم تمام فرآیندها |
| IsCurrent | bit | خیر | 1 | تنها تلاش جاری همان درخواست |
| CreatedAt | datetime2(3) | خیر | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt |
| UpdatedAt | datetime2(3) | خیر | SYSUTCDATETIME() | زمان UTC سرور برای UpdatedAt |
| RowVersion | rowversion | خیر | ندارد / مدیریت صریح سرور | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | (PublicId)؛ (TrackingCode)؛ (SourceRequestId, AttemptNumber)؛ (Id, TemplateId)؛ (Id, SourceRequestId) |
| FK | (SourceRequestId) → SourceInsuranceRequests(Id)؛ (TemplateId) → InspectionTemplates(Id)؛ (PreviousInspectionId, SourceRequestId) → Inspections(Id, SourceRequestId) |
| CHECK | [AttemptNumber]>0؛ [Status] IN ('DRAFT','UPLOAD_PENDING','SUBMITTED','UNDER_REVIEW','CHANGES_REQUESTED','REJECTED','REVIEW_APPROVED','FORWARD_PENDING','FORWARDED','FORWARD_FAILED')؛ [PreviousInspectionId] IS NULL OR [PreviousInspectionId]<>[Id] |
| ایندکس | UNIQUE (SourceRequestId) WHERE [IsCurrent] = 1؛ (Status, UpdatedAt) INCLUDE SourceRequestId, TrackingCode |
| عملیات مرتبط | B01, B02, B03, B04, B07, B09, B10, D01, D02, D04, D07, D09, E01, E02, E03, E05, E06, E07, E09, G01, G02, G03 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## Vehicles

تصویر اطلاعاتی خودرو همان تلاش؛ منبع بیمه بازنویسی نمی‌شود

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | uniqueidentifier | خیر | NEWSEQUENTIALID() | شناسه داخلی سرور |
| InspectionId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع InspectionId |
| SourceVehicleReference | nvarchar(128) | بله | ندارد / مدیریت صریح سرور | مرجع خودرو در منبع بیمه |
| Make | nvarchar(100) | خیر | ندارد / مدیریت صریح سرور | سازنده خودرو |
| Model | nvarchar(100) | خیر | ندارد / مدیریت صریح سرور | مدل خودرو |
| ModelYear | int | خیر | ندارد / مدیریت صریح سرور | سال مطابق تقویم و سیاست مصوب |
| BodyColor | nvarchar(80) | خیر | ندارد / مدیریت صریح سرور | رنگ بدنه |
| PlateFirstTwo | char(2) | خیر | ندارد / مدیریت صریح سرور | دو رقم ASCII پلاک |
| PlateLetter | nvarchar(3) | خیر | ندارد / مدیریت صریح سرور | حرف مجاز پلاک |
| PlateThree | char(3) | خیر | ندارد / مدیریت صریح سرور | سه رقم ASCII پلاک |
| PlateRegion | char(2) | خیر | ندارد / مدیریت صریح سرور | دو رقم منطقه |
| MaskedVin | nvarchar(80) | خیر | ندارد / مدیریت صریح سرور | VIN پوشانده‌شده؛ نمایش کامل سیاست جدا می‌خواهد |
| ConfirmedAt | datetime2(3) | بله | ندارد / مدیریت صریح سرور | زمان UTC سرور برای ConfirmedAt |
| RowVersion | rowversion | خیر | ندارد / مدیریت صریح سرور | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست |
| BodyColorHex | char(7) | بله | ندارد / مدیریت صریح سرور | رنگ hex اختیاری برای swatch؛ نام رنگ در BodyColor است و رنگ ناشناخته نباید حدس قطعی شود. |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | (InspectionId) |
| FK | (InspectionId) → Inspections(Id) |
| CHECK | [ModelYear] BETWEEN 1000 AND 3000؛ [PlateFirstTwo] NOT LIKE '%[^0-9]%' AND [PlateThree] NOT LIKE '%[^0-9]%' AND [PlateRegion] NOT LIKE '%[^0-9]%' |
| ایندکس | PK/UNIQUE؛ ایندکس اضافی تنها با query plan |
| عملیات مرتبط | B01, B02, B08, B09, D09, E07 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## InspectionLocations

محل تأییدشده بازدید

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| InspectionId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع InspectionId |
| Latitude | decimal(9,6) | خیر | ندارد / مدیریت صریح سرور | عرض جغرافیایی[-90,90] |
| Longitude | decimal(9,6) | خیر | ندارد / مدیریت صریح سرور | طول جغرافیایی[-180,180] |
| AccuracyMeters | decimal(9,2) | بله | ندارد / مدیریت صریح سرور | دقت غیرمنفی بر حسب متر |
| FormattedAddress | nvarchar(500) | خیر | ندارد / مدیریت صریح سرور | نشانی فارسی قابل ویرایش |
| BuildingNumber | nvarchar(40) | بله | ندارد / مدیریت صریح سرور | شماره ساختمان به صورت رشته |
| UnitFloor | nvarchar(80) | بله | ندارد / مدیریت صریح سرور | واحد یا طبقه اختیاری |
| ParkingDescription | nvarchar(500) | بله | ندارد / مدیریت صریح سرور | توضیح اختیاری محل پارک |
| ConfirmedAt | datetime2(3) | خیر | SYSUTCDATETIME() | زمان UTC سرور برای ConfirmedAt |
| RowVersion | rowversion | خیر | ندارد / مدیریت صریح سرور | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست |
| SelectionSource | varchar(10) | بله | ندارد / مدیریت صریح سرور | روش انتخاب اعلام‌شده gps/manual؛ ادعای GPS بدونمجوزیا accuracy ساخته نشود. |
| ClientRecordedAt | datetime2(3) | بله | ندارد / مدیریت صریح سرور | زمان اعلامی مشتری؛ با ConfirmedAt سرور و audit trusted فرق دارد. |

| قید | تعریف |
|---|---|
| PK | InspectionId |
| UNIQUE | ندارد |
| FK | (InspectionId) → Inspections(Id) |
| CHECK | [Latitude] BETWEEN -90 AND 90؛ [Longitude] BETWEEN -180 AND 180؛ [AccuracyMeters]>=0؛ [SelectionSource] IS NULL OR [SelectionSource] IN ('gps','manual') |
| ایندکس | PK/UNIQUE؛ ایندکس اضافی تنها با query plan |
| عملیات مرتبط | B02, B07 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## InspectionConsents

رسید پذیرش نسخه شرایط

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | uniqueidentifier | خیر | NEWSEQUENTIALID() | شناسه داخلی سرور |
| InspectionId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع InspectionId |
| TermsVersion | nvarchar(80) | خیر | ندارد / مدیریت صریح سرور | نسخه متن شرایط مصوب |
| AcceptedBySubject | nvarchar(128) | خیر | ندارد / مدیریت صریح سرور | فراداده AcceptedBySubject در InspectionConsents |
| AcceptedAt | datetime2(3) | خیر | SYSUTCDATETIME() | زمان UTC سرور برای AcceptedAt |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | (InspectionId, TermsVersion) |
| FK | (InspectionId) → Inspections(Id) |
| CHECK | کنترل دامنه در سرویس و نوع ستون |
| ایندکس | PK/UNIQUE؛ ایندکس اضافی تنها با query plan |
| عملیات مرتبط | B06 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## OdometerReadings

کیلومتر عددی، مستقل از رسانه

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| InspectionId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع InspectionId |
| Kilometers | bigint | خیر | ندارد / مدیریت صریح سرور | عدد صحیح غیرمنفی در محدوده امن JavaScript |
| EvidenceVersionId | uniqueidentifier | بله | ندارد / مدیریت صریح سرور | شناسه مرجع EvidenceVersionId |
| UpdatedAt | datetime2(3) | خیر | SYSUTCDATETIME() | زمان UTC سرور برای UpdatedAt |
| RowVersion | rowversion | خیر | ندارد / مدیریت صریح سرور | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست |

| قید | تعریف |
|---|---|
| PK | InspectionId |
| UNIQUE | ندارد |
| FK | (InspectionId) → Inspections(Id)؛ (EvidenceVersionId, InspectionId) → EvidenceVersions(Id, InspectionId) |
| CHECK | [Kilometers] BETWEEN 0 AND 9007199254740991 |
| ایندکس | PK/UNIQUE؛ ایندکس اضافی تنها با query plan |
| عملیات مرتبط | B10, D01 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## InspectionEvidence

جایگاه مدرک و اشاره‌گر نسخه خوب/جایگزین منتظر

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | uniqueidentifier | خیر | NEWSEQUENTIALID() | شناسه داخلی سرور |
| InspectionId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع InspectionId |
| TemplateId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع TemplateId |
| RequirementId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع RequirementId |
| CurrentVersionId | uniqueidentifier | بله | ندارد / مدیریت صریح سرور | نسخه خوب فعلی تا موفقیت جایگزین محفوظ است |
| PendingVersionId | uniqueidentifier | بله | ندارد / مدیریت صریح سرور | جایگزین موردنظر که هنوز تأیید پایدار نشده |
| RowVersion | rowversion | خیر | ندارد / مدیریت صریح سرور | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | (InspectionId, RequirementId)؛ (Id, InspectionId)؛ (Id, RequirementId) |
| FK | (InspectionId, TemplateId) → Inspections(Id, TemplateId)؛ (RequirementId, TemplateId) → EvidenceRequirements(Id, TemplateId)؛ (CurrentVersionId, Id) → EvidenceVersions(Id, EvidenceId)؛ (PendingVersionId, Id) → EvidenceVersions(Id, EvidenceId) |
| CHECK | کنترل دامنه در سرویس و نوع ستون |
| ایندکس | PK/UNIQUE؛ ایندکس اضافی تنها با query plan |
| عملیات مرتبط | C01, C04, D01, D07 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## EvidenceVersions

نسخه مستقل با هویت واقعی گزینه و بایت‌ها

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | uniqueidentifier | خیر | NEWSEQUENTIALID() | شناسه داخلی سرور |
| EvidenceId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع EvidenceId |
| InspectionId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع InspectionId |
| RequirementId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع RequirementId |
| HasChoice | bit | خیر | ندارد / مدیریت صریح سرور | از تعریف ثابت الزام؛ فقط گروه VIN دارای گزینه است |
| AlternativeId | uniqueidentifier | بله | ندارد / مدیریت صریح سرور | گزینه واقعی فایل؛ نه ترجیح راهنمای بعدی |
| RevisionKey | nvarchar(160) | خیر | ندارد / مدیریت صریح سرور | کلید ثابت نسخه محلی برای تکرار امن |
| ReplacesVersionId | uniqueidentifier | بله | ندارد / مدیریت صریح سرور | شناسه مرجع ReplacesVersionId |
| UploadStatus | varchar(16) | خیر | ندارد / مدیریت صریح سرور | انتقال مستقل از پردازش و تصمیم کارشناس |
| VerificationStatus | varchar(24) | خیر | ندارد / مدیریت صریح سرور | not-started/processing/verified/retake-requested |
| CapturedAtClaim | datetime2(3) | خیر | ندارد / مدیریت صریح سرور | زمان ادعایی دستگاه؛ اثبات زمان واقعی نیست |
| CreatedAt | datetime2(3) | خیر | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt |
| RowVersion | rowversion | خیر | ندارد / مدیریت صریح سرور | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | (EvidenceId, RevisionKey)؛ (Id, EvidenceId)؛ (Id, InspectionId) |
| FK | (EvidenceId, InspectionId) → InspectionEvidence(Id, InspectionId)؛ (EvidenceId, RequirementId) → InspectionEvidence(Id, RequirementId)؛ (RequirementId, HasChoice) → EvidenceRequirements(Id, HasChoice)؛ (AlternativeId, RequirementId) → RequirementAlternatives(Id, RequirementId)؛ (ReplacesVersionId, EvidenceId) → EvidenceVersions(Id, EvidenceId) |
| CHECK | [UploadStatus] IN ('queued','uploading','uploaded','failed','cancelled')؛ [VerificationStatus] IN ('not-started','processing','verified','retake-requested')؛ ([HasChoice]=1 AND [AlternativeId] IS NOT NULL) OR ([HasChoice]=0 AND [AlternativeId] IS NULL) |
| ایندکس | PK/UNIQUE؛ ایندکس اضافی تنها با query plan |
| عملیات مرتبط | C01, C02, C03, C04, C05, C06, C07, D01, D06, E10 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## MediaFiles

فقط فراداده و مسیر فایل خصوصی؛ بدون باینری رسانه

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | uniqueidentifier | خیر | NEWSEQUENTIALID() | شناسه داخلی سرور |
| EvidenceVersionId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع EvidenceVersionId |
| Variant | varchar(16) | خیر | ندارد / مدیریت صریح سرور | original/thumbnail/preview/transcode |
| GeneratedFilename | nvarchar(200) | خیر | ندارد / مدیریت صریح سرور | نام تولیدشده سرور، نه نام فایل کاربر |
| RelativePath | nvarchar(450) | خیر | ندارد / مدیریت صریح سرور | مسیر نسبی canonical زیر ریشه خصوصی |
| MimeType | varchar(127) | خیر | ندارد / مدیریت صریح سرور | نوع واقعی تأییدشده رسانه |
| ByteSize | bigint | خیر | ندارد / مدیریت صریح سرور | اندازه واقعی مورد تطبیق در complete |
| Sha256 | binary(32) | بله | ندارد / مدیریت صریح سرور | هش ۳۲ بایتی؛ فراداده است و رسانه نیست |
| Width | int | بله | ندارد / مدیریت صریح سرور | عرض مثبت رسانه |
| Height | int | بله | ندارد / مدیریت صریح سرور | ارتفاع مثبت رسانه |
| DurationMs | bigint | بله | ندارد / مدیریت صریح سرور | مدت ویدیو به میلی‌ثانیه |
| StorageState | varchar(16) | خیر | ندارد / مدیریت صریح سرور | دوام/نگهداری مستقل از انتقال |
| CreatedAt | datetime2(3) | خیر | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt |
| RetentionUntil | datetime2(3) | بله | ندارد / مدیریت صریح سرور | سیاست مصوب؛ NULL مجوز حذف نیست |
| LegalHold | bit | خیر | 0 | مانع حذف قانونی یا عملیاتی |
| DeletedAt | datetime2(3) | بله | ندارد / مدیریت صریح سرور | زمان UTC سرور برای DeletedAt |
| RowVersion | rowversion | خیر | ندارد / مدیریت صریح سرور | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست |
| DerivedFromFileId | uniqueidentifier | بله | ندارد / مدیریت صریح سرور | فایل والد همان نسخه برای مشتق اختیاری؛ NULL یعنی بایت دریافتی یا فاقد مشتق. |
| ProfileVersion | nvarchar(80) | بله | ندارد / مدیریت صریح سرور | شناسه نسخه پروفایل پردازش سرور؛ سیاست مرورگر یا گواه کیفیت نیست. |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | (RelativePath)؛ (Id, EvidenceVersionId) |
| FK | (EvidenceVersionId) → EvidenceVersions(Id)؛ (DerivedFromFileId, EvidenceVersionId) → MediaFiles(Id, EvidenceVersionId) |
| CHECK | [Variant] IN ('original','thumbnail','preview','transcode')؛ [StorageState] IN ('staging','durable','submitted','finalized','historical','missing','deleted')؛ [ByteSize]>0؛ [Width] IS NULL OR [Width]>0؛ [Height] IS NULL OR [Height]>0؛ [DurationMs] IS NULL OR [DurationMs]>0؛ [RelativePath] NOT LIKE '%..%' AND [RelativePath] NOT LIKE '/%' AND [RelativePath] NOT LIKE '%:%' AND CHARINDEX(NCHAR(92),[RelativePath])=0؛ [DerivedFromFileId] IS NULL OR [DerivedFromFileId]<>[Id] |
| ایندکس | UNIQUE (EvidenceVersionId, Variant) WHERE [DeletedAt] IS NULL؛ (StorageState, RetentionUntil)؛ (EvidenceVersionId, Variant, ProfileVersion) INCLUDE MimeType, ByteSize |
| عملیات مرتبط | C01, C02, C03, C04, C05, C06, D06, G03 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## UploadSessions

مجوز و انتقال قابل بازیابی همان فایل

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | uniqueidentifier | خیر | NEWSEQUENTIALID() | شناسه داخلی سرور |
| MediaFileId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع MediaFileId |
| State | varchar(16) | خیر | ندارد / مدیریت صریح سرور | وضعیت این منبع؛ قید CHECK حاکم است |
| ExpectedBytes | bigint | خیر | ندارد / مدیریت صریح سرور | اندازه اظهارشده با سقف مجاز |
| BytesReceived | bigint | خیر | 0 | بایت واقعاً دریافت‌شده |
| IsActive | bit | خیر | 1 | حداکثر یک انتقال فعال برای فایل |
| ExpiresAt | datetime2(3) | خیر | ندارد / مدیریت صریح سرور | زمان UTC سرور برای ExpiresAt |
| AcknowledgedAt | datetime2(3) | بله | ندارد / مدیریت صریح سرور | زمان UTC سرور برای AcknowledgedAt |
| CreatedAt | datetime2(3) | خیر | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt |
| RowVersion | rowversion | خیر | ندارد / مدیریت صریح سرور | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | ندارد |
| FK | (MediaFileId) → MediaFiles(Id) |
| CHECK | [State] IN ('registered','receiving','staged','acknowledged','expired','cancelled')؛ [ExpectedBytes]>0 AND [BytesReceived]>=0 AND [BytesReceived]<=[ExpectedBytes] |
| ایندکس | UNIQUE (MediaFileId) WHERE [IsActive] = 1؛ (State, ExpiresAt) |
| عملیات مرتبط | C01, C02, C03, C07, D06 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## MediaProcessingJobs

کار اعتبارسنجی و تولید مشتق اختیاری

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | uniqueidentifier | خیر | NEWSEQUENTIALID() | شناسه داخلی سرور |
| MediaFileId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع MediaFileId |
| JobKind | varchar(24) | خیر | ندارد / مدیریت صریح سرور | validate/thumbnail/transcode |
| ProfileVersion | nvarchar(80) | خیر | ندارد / مدیریت صریح سرور | نسخه پروفایل پردازش |
| Status | varchar(16) | خیر | ندارد / مدیریت صریح سرور | وضعیت این بُعد؛ نه وضعیت مبهم تمام فرآیندها |
| AttemptCount | int | خیر | 0 | شمار تلاش غیرمنفی |
| LeaseUntil | datetime2(3) | بله | ندارد / مدیریت صریح سرور | زمان انقضای مالکیت موقت کارگر |
| NextRetryAt | datetime2(3) | بله | ندارد / مدیریت صریح سرور | زمان تلاش بعدی با backoff محدود |
| FailureCode | varchar(80) | بله | ندارد / مدیریت صریح سرور | کد امن؛ بدون stack، مسیر یا راز |
| CreatedAt | datetime2(3) | خیر | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt |
| RowVersion | rowversion | خیر | ندارد / مدیریت صریح سرور | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | (MediaFileId, JobKind, ProfileVersion) |
| FK | (MediaFileId) → MediaFiles(Id) |
| CHECK | [JobKind] IN ('validate','thumbnail','transcode')؛ [Status] IN ('queued','running','completed','failed')؛ [AttemptCount]>=0 |
| ایندکس | (Status, NextRetryAt) |
| عملیات مرتبط | C03, C05 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## StaffUsers

نگاشت کارکنان SSO؛ بدون حساب/رمز تکراری

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | uniqueidentifier | خیر | NEWSEQUENTIALID() | شناسه داخلی سرور |
| ExternalIssuer | nvarchar(200) | خیر | ندارد / مدیریت صریح سرور | فراداده ExternalIssuer در StaffUsers |
| ExternalSubject | nvarchar(128) | خیر | ندارد / مدیریت صریح سرور | فراداده ExternalSubject در StaffUsers |
| DisplayName | nvarchar(160) | خیر | ندارد / مدیریت صریح سرور | فراداده DisplayName در StaffUsers |
| Active | bit | خیر | 1 | فعال‌بودن نگاشت یا ارجاع |
| Capacity | int | خیر | 10 | ظرفیت پرونده فعال کارشناس |
| CreatedAt | datetime2(3) | خیر | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt |
| RowVersion | rowversion | خیر | ندارد / مدیریت صریح سرور | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | (ExternalIssuer, ExternalSubject) |
| FK | ندارد |
| CHECK | [Capacity]>=0 |
| ایندکس | PK/UNIQUE؛ ایندکس اضافی تنها با query plan |
| عملیات مرتبط | A04, A05, E01, E03, E04, F01, F10 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## StaffRoleAssignments

نقش کارکنان در همان نصب

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| StaffId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع StaffId |
| RoleCode | varchar(32) | خیر | ندارد / مدیریت صریح سرور | نقش همین نصب؛ platform-admin مدیر همین کارگزاری است |
| CreatedAt | datetime2(3) | خیر | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt |

| قید | تعریف |
|---|---|
| PK | StaffId, RoleCode |
| UNIQUE | ندارد |
| FK | (StaffId) → StaffUsers(Id) |
| CHECK | [RoleCode] IN ('platform-admin','reviewer','template-editor','viewer') |
| ایندکس | PK/UNIQUE؛ ایندکس اضافی تنها با query plan |
| عملیات مرتبط | A04, A05, F01, F10 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## StaffOperationsSettings

سیاست ارجاع مستقل از برند

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | tinyint | خیر | 1 | شناسه داخلی سرور |
| AssignmentMode | varchar(16) | خیر | ندارد / مدیریت صریح سرور | manual/random |
| RowVersion | rowversion | خیر | ندارد / مدیریت صریح سرور | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | ندارد |
| FK | ندارد |
| CHECK | [Id]=1؛ [AssignmentMode] IN ('manual','random') |
| ایندکس | PK/UNIQUE؛ ایندکس اضافی تنها با query plan |
| عملیات مرتبط | E04 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## ReviewerAssignments

سابقه ارجاع؛ یک ارجاع فعال هر پرونده

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | uniqueidentifier | خیر | NEWSEQUENTIALID() | شناسه داخلی سرور |
| InspectionId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع InspectionId |
| ReviewerId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع ReviewerId |
| AssignedBy | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع AssignedBy |
| Active | bit | خیر | 1 | فعال‌بودن نگاشت یا ارجاع |
| AssignedAt | datetime2(3) | خیر | SYSUTCDATETIME() | زمان UTC سرور برای AssignedAt |
| RevokedAt | datetime2(3) | بله | ندارد / مدیریت صریح سرور | زمان UTC سرور برای RevokedAt |
| RowVersion | rowversion | خیر | ندارد / مدیریت صریح سرور | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | (Id, InspectionId) |
| FK | (InspectionId) → Inspections(Id)؛ (ReviewerId) → StaffUsers(Id)؛ (AssignedBy) → StaffUsers(Id) |
| CHECK | کنترل دامنه در سرویس و نوع ستون |
| ایندکس | UNIQUE (InspectionId) WHERE [Active] = 1؛ (ReviewerId, Active) |
| عملیات مرتبط | C06, E01, E02, E03 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## InspectionSubmissions

رسید و نسخه ثابت ارسال اولیه/اصلاح

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | uniqueidentifier | خیر | NEWSEQUENTIALID() | شناسه داخلی سرور |
| InspectionId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع InspectionId |
| SubmissionNumber | int | خیر | ندارد / مدیریت صریح سرور | ترتیب مثبت ارسال |
| CorrectionRequestId | uniqueidentifier | بله | ندارد / مدیریت صریح سرور | شناسه مرجع CorrectionRequestId |
| SnapshotJson | nvarchar(max) | خیر | ندارد / مدیریت صریح سرور | snapshot فقط فراداده؛ بایت/Base64 رسانه ممنوع |
| SubmittedBySubject | nvarchar(128) | خیر | ندارد / مدیریت صریح سرور | فراداده SubmittedBySubject در InspectionSubmissions |
| SubmittedAt | datetime2(3) | خیر | SYSUTCDATETIME() | زمان UTC سرور برای SubmittedAt |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | (InspectionId, SubmissionNumber)؛ (Id, InspectionId) |
| FK | (InspectionId) → Inspections(Id)؛ (CorrectionRequestId, InspectionId) → CorrectionRequests(Id, InspectionId) |
| CHECK | [SubmissionNumber]>0؛ ISJSON([SnapshotJson])=1 |
| ایندکس | UNIQUE (InspectionId) WHERE [CorrectionRequestId] IS NULL |
| عملیات مرتبط | D02, D03, D05, D07, G02 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## SubmissionEvidence

نسخه دقیق هر مدرک در رسید ارسال

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| SubmissionId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع SubmissionId |
| InspectionId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع InspectionId |
| EvidenceId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع EvidenceId |
| EvidenceVersionId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع EvidenceVersionId |

| قید | تعریف |
|---|---|
| PK | SubmissionId, EvidenceId |
| UNIQUE | ندارد |
| FK | (SubmissionId, InspectionId) → InspectionSubmissions(Id, InspectionId)؛ (EvidenceId, InspectionId) → InspectionEvidence(Id, InspectionId)؛ (EvidenceVersionId, EvidenceId) → EvidenceVersions(Id, EvidenceId) |
| CHECK | کنترل دامنه در سرویس و نوع ستون |
| ایندکس | PK/UNIQUE؛ ایندکس اضافی تنها با query plan |
| عملیات مرتبط | D02, D07 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## EvidenceReviews

رویداد تغییرناپذیر تصمیم یک نسخه

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | uniqueidentifier | خیر | NEWSEQUENTIALID() | شناسه داخلی سرور |
| InspectionId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع InspectionId |
| EvidenceVersionId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع EvidenceVersionId |
| AssignmentId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع AssignmentId |
| Decision | varchar(16) | خیر | ندارد / مدیریت صریح سرور | approved/rejected؛ تصمیم مدرک و کل جدا |
| CustomerReason | nvarchar(2000) | بله | ندارد / مدیریت صریح سرور | دلیل قابل نمایش به مشتری؛ برای رد الزامی |
| DecidedAt | datetime2(3) | خیر | SYSUTCDATETIME() | زمان UTC سرور برای DecidedAt |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | ندارد |
| FK | (EvidenceVersionId, InspectionId) → EvidenceVersions(Id, InspectionId)؛ (AssignmentId, InspectionId) → ReviewerAssignments(Id, InspectionId) |
| CHECK | [Decision] IN ('approved','rejected')؛ [Decision]<>'rejected' OR ([CustomerReason] IS NOT NULL AND LEN(LTRIM(RTRIM([CustomerReason])))>0) |
| ایندکس | (InspectionId, DecidedAt)؛ (EvidenceVersionId, DecidedAt) |
| عملیات مرتبط | C05, E02, E05, E10 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## InspectionReviews

تصمیم کل مستقل از تحویل به مقصد

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | uniqueidentifier | خیر | NEWSEQUENTIALID() | شناسه داخلی سرور |
| InspectionId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع InspectionId |
| AssignmentId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع AssignmentId |
| SubmissionId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع SubmissionId |
| Decision | varchar(16) | خیر | ندارد / مدیریت صریح سرور | approved/rejected؛ تصمیم مدرک و کل جدا |
| CustomerReason | nvarchar(2000) | بله | ندارد / مدیریت صریح سرور | دلیل قابل نمایش به مشتری؛ برای رد الزامی |
| DecidedAt | datetime2(3) | خیر | SYSUTCDATETIME() | زمان UTC سرور برای DecidedAt |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | (InspectionId)؛ (Id, InspectionId)؛ (Id, InspectionId, SubmissionId) |
| FK | (AssignmentId, InspectionId) → ReviewerAssignments(Id, InspectionId)؛ (SubmissionId, InspectionId) → InspectionSubmissions(Id, InspectionId) |
| CHECK | [Decision] IN ('approved','rejected')؛ [Decision]<>'rejected' OR ([CustomerReason] IS NOT NULL AND LEN(LTRIM(RTRIM([CustomerReason])))>0) |
| ایندکس | PK/UNIQUE؛ ایندکس اضافی تنها با query plan |
| عملیات مرتبط | E09, G02 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## CorrectionRequests

دور اصلاح نسخه‌دار با حفظ اصل

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | uniqueidentifier | خیر | NEWSEQUENTIALID() | شناسه داخلی سرور |
| InspectionId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع InspectionId |
| OriginalSubmissionId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع OriginalSubmissionId |
| RequestedByAssignmentId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع RequestedByAssignmentId |
| RequestVersion | int | خیر | ندارد / مدیریت صریح سرور | نسخه مثبت درخواست |
| RoundNumber | int | خیر | ندارد / مدیریت صریح سرور | دور مثبت اصلاح |
| Status | varchar(24) | خیر | ندارد / مدیریت صریح سرور | وضعیت این بُعد؛ نه وضعیت مبهم تمام فرآیندها |
| Active | bit | خیر | 1 | فعال‌بودن نگاشت یا ارجاع |
| RequestedAt | datetime2(3) | خیر | SYSUTCDATETIME() | زمان UTC سرور برای RequestedAt |
| RowVersion | rowversion | خیر | ندارد / مدیریت صریح سرور | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | (Id, InspectionId)؛ (InspectionId, RoundNumber) |
| FK | (OriginalSubmissionId, InspectionId) → InspectionSubmissions(Id, InspectionId)؛ (RequestedByAssignmentId, InspectionId) → ReviewerAssignments(Id, InspectionId) |
| CHECK | [RequestVersion]>0 AND [RoundNumber]>0؛ [Status] IN ('requested','resubmitting','resubmitted','resubmit-failed','resolved','superseded') |
| ایندکس | (InspectionId, Active) |
| عملیات مرتبط | D04, D05, D07, E05, E06 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## CorrectionItems

قلم مشخص رسانه یا فیلد در درخواست

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | uniqueidentifier | خیر | NEWSEQUENTIALID() | شناسه داخلی سرور |
| RequestId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع RequestId |
| InspectionId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع InspectionId |
| Kind | varchar(16) | خیر | ندارد / مدیریت صریح سرور | photo/video-360 و در قلم اصلاح field |
| EvidenceId | uniqueidentifier | بله | ندارد / مدیریت صریح سرور | شناسه مرجع EvidenceId |
| OriginalVersionId | uniqueidentifier | بله | ندارد / مدیریت صریح سرور | شناسه مرجع OriginalVersionId |
| CandidateVersionId | uniqueidentifier | بله | ندارد / مدیریت صریح سرور | شناسه مرجع CandidateVersionId |
| FieldName | varchar(20) | بله | ندارد / مدیریت صریح سرور | plate/color/modelYear؛ سایر فیلدها بسته‌اند |
| ProposalJson | nvarchar(max) | بله | ندارد / مدیریت صریح سرور | پیشنهاد تایپ‌شده فیلد؛ فقط فراداده |
| CustomerReason | nvarchar(2000) | خیر | ندارد / مدیریت صریح سرور | دلیل قابل نمایش به مشتری؛ برای رد الزامی |
| State | varchar(16) | خیر | ندارد / مدیریت صریح سرور | وضعیت این منبع؛ قید CHECK حاکم است |
| RowVersion | rowversion | خیر | ندارد / مدیریت صریح سرور | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | ندارد |
| FK | (RequestId, InspectionId) → CorrectionRequests(Id, InspectionId)؛ (EvidenceId, InspectionId) → InspectionEvidence(Id, InspectionId)؛ (OriginalVersionId, EvidenceId) → EvidenceVersions(Id, EvidenceId)؛ (CandidateVersionId, EvidenceId) → EvidenceVersions(Id, EvidenceId) |
| CHECK | [Kind] IN ('photo','video-360','field')؛ ([Kind]='field' AND [FieldName] IS NOT NULL AND [FieldName] IN ('plate','color','modelYear') AND [EvidenceId] IS NULL AND [OriginalVersionId] IS NULL AND [CandidateVersionId] IS NULL) OR ([Kind] IN ('photo','video-360') AND [FieldName] IS NULL AND [EvidenceId] IS NOT NULL AND [OriginalVersionId] IS NOT NULL AND [ProposalJson] IS NULL)؛ [ProposalJson] IS NULL OR ISJSON([ProposalJson])=1؛ LEN(LTRIM(RTRIM([CustomerReason])))>0؛ [State] IN ('requested','submitted','approved') |
| ایندکس | UNIQUE (RequestId, EvidenceId) WHERE [EvidenceId] IS NOT NULL؛ UNIQUE (RequestId, FieldName) WHERE [FieldName] IS NOT NULL |
| عملیات مرتبط | D05, D06, D07, D08, E05, E06, E07 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## InternalNotes

یادداشت خصوصی کارکنان، خارج از DTO مشتری

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | uniqueidentifier | خیر | NEWSEQUENTIALID() | شناسه داخلی سرور |
| InspectionId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع InspectionId |
| AssignmentId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع AssignmentId |
| Text | nvarchar(4000) | خیر | ندارد / مدیریت صریح سرور | یادداشت خصوصی؛ در خروجی مشتری ممنوع |
| CreatedAt | datetime2(3) | خیر | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | ندارد |
| FK | (AssignmentId, InspectionId) → ReviewerAssignments(Id, InspectionId) |
| CHECK | LEN(LTRIM(RTRIM([Text])))>0 |
| ایندکس | (InspectionId, CreatedAt) |
| عملیات مرتبط | E02, E08 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## InspectionStatusHistory

تاریخچه تغییر چرخه عمر

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | uniqueidentifier | خیر | NEWSEQUENTIALID() | شناسه داخلی سرور |
| InspectionId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع InspectionId |
| FromStatus | varchar(24) | بله | ندارد / مدیریت صریح سرور | فراداده FromStatus در InspectionStatusHistory |
| ToStatus | varchar(24) | خیر | ندارد / مدیریت صریح سرور | فراداده ToStatus در InspectionStatusHistory |
| ActorReference | nvarchar(160) | خیر | ندارد / مدیریت صریح سرور | فراداده ActorReference در InspectionStatusHistory |
| ReasonCode | varchar(80) | خیر | ندارد / مدیریت صریح سرور | فراداده ReasonCode در InspectionStatusHistory |
| CreatedAt | datetime2(3) | خیر | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | ندارد |
| FK | (InspectionId) → Inspections(Id) |
| CHECK | [FromStatus] IS NULL OR [FromStatus] IN ('DRAFT','UPLOAD_PENDING','SUBMITTED','UNDER_REVIEW','CHANGES_REQUESTED','REJECTED','REVIEW_APPROVED','FORWARD_PENDING','FORWARDED','FORWARD_FAILED')؛ [ToStatus] IN ('DRAFT','UPLOAD_PENDING','SUBMITTED','UNDER_REVIEW','CHANGES_REQUESTED','REJECTED','REVIEW_APPROVED','FORWARD_PENDING','FORWARDED','FORWARD_FAILED') |
| ایندکس | (InspectionId, CreatedAt) |
| عملیات مرتبط | D02, D04, D07, D09, E03, E05, E06, E09, E10, G02, G03 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## IdempotencyRecords

رزرو و نتیجه پایدار فرمان

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | uniqueidentifier | خیر | NEWSEQUENTIALID() | شناسه داخلی سرور |
| ScopeKey | nvarchar(200) | خیر | ندارد / مدیریت صریح سرور | نصب + عامل + عملیات + منبع |
| CommandKey | varchar(100) | خیر | ندارد / مدیریت صریح سرور | کلید پایدار فرمان |
| RequestHash | binary(32) | خیر | ندارد / مدیریت صریح سرور | هش بدنه canonical فرمان |
| State | varchar(16) | خیر | ندارد / مدیریت صریح سرور | وضعیت این منبع؛ قید CHECK حاکم است |
| ResponseStatus | smallint | بله | ندارد / مدیریت صریح سرور | فراداده ResponseStatus در IdempotencyRecords |
| ResponseJson | nvarchar(max) | بله | ندارد / مدیریت صریح سرور | نتیجه whitelist بدون token، مسیر خصوصی یا رسانه |
| LeaseUntil | datetime2(3) | بله | ندارد / مدیریت صریح سرور | زمان انقضای مالکیت موقت کارگر |
| ExpiresAt | datetime2(3) | بله | ندارد / مدیریت صریح سرور | زمان UTC سرور برای ExpiresAt |
| CreatedAt | datetime2(3) | خیر | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt |
| RowVersion | rowversion | خیر | ندارد / مدیریت صریح سرور | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | (ScopeKey, CommandKey) |
| FK | ندارد |
| CHECK | [State] IN ('reserved','completed','failed')؛ [ResponseJson] IS NULL OR ISJSON([ResponseJson])=1؛ [ResponseStatus] IS NULL OR [ResponseStatus] BETWEEN 100 AND 599 |
| ایندکس | (State, LeaseUntil) |
| عملیات مرتبط | A03, A04, A09, B01, B06, B07, B09, B10, C01, C02, C03, C07, D02, D03, D06, D07, D08, D09, E03, E04, E05, E06, E07, E08, E09, F02, F03, F04, F06, F07, F08, F09, F10, F11, G01, G02, G03, G04 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## ForwardingJobs

outbox پایدار نسخه تأییدشده

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | uniqueidentifier | خیر | NEWSEQUENTIALID() | شناسه داخلی سرور |
| InspectionId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع InspectionId |
| InspectionReviewId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع InspectionReviewId |
| SubmissionId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع SubmissionId |
| DestinationKey | nvarchar(80) | خیر | ندارد / مدیریت صریح سرور | مرجع allowlist سرور؛ نه URL یا credential |
| DeliveryKey | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه ثابت مقصد برای تکرار امن |
| State | varchar(16) | خیر | ندارد / مدیریت صریح سرور | وضعیت این منبع؛ قید CHECK حاکم است |
| AttemptCount | int | خیر | 0 | شمار تلاش غیرمنفی |
| NextRetryAt | datetime2(3) | بله | ندارد / مدیریت صریح سرور | زمان تلاش بعدی با backoff محدود |
| LeaseUntil | datetime2(3) | بله | ندارد / مدیریت صریح سرور | زمان انقضای مالکیت موقت کارگر |
| AcknowledgementId | nvarchar(160) | بله | ندارد / مدیریت صریح سرور | شناسه تأیید معتبر مقصد |
| AcknowledgedAt | datetime2(3) | بله | ندارد / مدیریت صریح سرور | زمان UTC سرور برای AcknowledgedAt |
| CreatedAt | datetime2(3) | خیر | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt |
| RowVersion | rowversion | خیر | ندارد / مدیریت صریح سرور | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | (InspectionReviewId, DestinationKey)؛ (DeliveryKey) |
| FK | (InspectionReviewId, InspectionId, SubmissionId) → InspectionReviews(Id, InspectionId, SubmissionId)؛ (SubmissionId, InspectionId) → InspectionSubmissions(Id, InspectionId) |
| CHECK | [State] IN ('ready','sending','retrying','acknowledged','failed')؛ [AttemptCount]>=0؛ [State]<>'acknowledged' OR ([AcknowledgementId] IS NOT NULL AND [AcknowledgedAt] IS NOT NULL) |
| ایندکس | (State, NextRetryAt) |
| عملیات مرتبط | D04, E09, G02, G03, G04, G05 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## ForwardingAttempts

تلاش‌های تحویل مستقل و محفوظ

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | uniqueidentifier | خیر | NEWSEQUENTIALID() | شناسه داخلی سرور |
| JobId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع JobId |
| AttemptNumber | int | خیر | ندارد / مدیریت صریح سرور | شماره مثبت تلاش همان درخواست یا کار |
| StartedAt | datetime2(3) | خیر | SYSUTCDATETIME() | زمان UTC سرور برای StartedAt |
| FinishedAt | datetime2(3) | بله | ندارد / مدیریت صریح سرور | زمان UTC سرور برای FinishedAt |
| HttpStatus | smallint | بله | ندارد / مدیریت صریح سرور | فراداده HttpStatus در ForwardingAttempts |
| FailureCode | varchar(80) | بله | ندارد / مدیریت صریح سرور | کد امن؛ بدون stack، مسیر یا راز |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | (JobId, AttemptNumber) |
| FK | (JobId) → ForwardingJobs(Id) |
| CHECK | [AttemptNumber]>0؛ [HttpStatus] IS NULL OR [HttpStatus] BETWEEN 100 AND 599 |
| ایندکس | PK/UNIQUE؛ ایندکس اضافی تنها با query plan |
| عملیات مرتبط | G03, G04 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## BrandingAssets

دارایی عمومی ایمن برند، جدا از شواهد

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | uniqueidentifier | خیر | NEWSEQUENTIALID() | شناسه داخلی سرور |
| SlotCode | nvarchar(80) | خیر | ندارد / مدیریت صریح سرور | فراداده SlotCode در BrandingAssets |
| PublicRelativePath | nvarchar(450) | خیر | ندارد / مدیریت صریح سرور | مسیر عمومی برند؛ جدا از ریشه خصوصی شواهد |
| MimeType | varchar(127) | خیر | ندارد / مدیریت صریح سرور | نوع واقعی تأییدشده رسانه |
| ByteSize | bigint | خیر | ندارد / مدیریت صریح سرور | اندازه واقعی مورد تطبیق در complete |
| Width | int | خیر | ندارد / مدیریت صریح سرور | عرض مثبت رسانه |
| Height | int | خیر | ندارد / مدیریت صریح سرور | ارتفاع مثبت رسانه |
| Sha256 | binary(32) | خیر | ندارد / مدیریت صریح سرور | هش ۳۲ بایتی؛ فراداده است و رسانه نیست |
| CreatedAt | datetime2(3) | خیر | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | (PublicRelativePath) |
| FK | ندارد |
| CHECK | [ByteSize]>0 AND [Width]>0 AND [Height]>0 |
| ایندکس | PK/UNIQUE؛ ایندکس اضافی تنها با query plan |
| عملیات مرتبط | A02, F05, F08 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## SiteSettingsVersions

نسخه draft یا عمومی، بدون راز زیرساخت

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | uniqueidentifier | خیر | NEWSEQUENTIALID() | شناسه داخلی سرور |
| Version | int | خیر | ندارد / مدیریت صریح سرور | نسخه مثبت منبع |
| State | varchar(16) | خیر | ندارد / مدیریت صریح سرور | وضعیت این منبع؛ قید CHECK حاکم است |
| SchemaVersion | int | خیر | ندارد / مدیریت صریح سرور | فراداده SchemaVersion در SiteSettingsVersions |
| SettingsJson | nvarchar(max) | خیر | ندارد / مدیریت صریح سرور | تنظیمات عمومی whitelist؛ بدون راز Neshan یا احراز هویت |
| CreatedBy | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع CreatedBy |
| CreatedAt | datetime2(3) | خیر | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt |
| PublishedAt | datetime2(3) | بله | ندارد / مدیریت صریح سرور | زمان UTC سرور برای PublishedAt |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | (Version) |
| FK | (CreatedBy) → StaffUsers(Id) |
| CHECK | [Version]>0 AND [SchemaVersion]>0؛ [State] IN ('draft','published','archived')؛ ISJSON([SettingsJson])=1 |
| ایندکس | PK/UNIQUE؛ ایندکس اضافی تنها با query plan |
| عملیات مرتبط | A02, F05, F06, F07, F09 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## SiteSettings

اشاره‌گر تنها ارائه‌دهنده تنظیمات

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | tinyint | خیر | 1 | شناسه داخلی سرور |
| PublishedVersionId | uniqueidentifier | بله | ندارد / مدیریت صریح سرور | شناسه مرجع PublishedVersionId |
| DraftVersionId | uniqueidentifier | بله | ندارد / مدیریت صریح سرور | شناسه مرجع DraftVersionId |
| RowVersion | rowversion | خیر | ندارد / مدیریت صریح سرور | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | ندارد |
| FK | (PublishedVersionId) → SiteSettingsVersions(Id)؛ (DraftVersionId) → SiteSettingsVersions(Id) |
| CHECK | [Id]=1 |
| ایندکس | PK/UNIQUE؛ ایندکس اضافی تنها با query plan |
| عملیات مرتبط | A02, F05, F06, F07, F09 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## SiteSettingsAssetLinks

ارجاع نسخه تنظیمات به دارایی برند

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| SettingsVersionId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع SettingsVersionId |
| SlotCode | nvarchar(80) | خیر | ندارد / مدیریت صریح سرور | فراداده SlotCode در SiteSettingsAssetLinks |
| BrandingAssetId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع BrandingAssetId |

| قید | تعریف |
|---|---|
| PK | SettingsVersionId, SlotCode |
| UNIQUE | ندارد |
| FK | (SettingsVersionId) → SiteSettingsVersions(Id)؛ (BrandingAssetId) → BrandingAssets(Id) |
| CHECK | کنترل دامنه در سرویس و نوع ستون |
| ایندکس | PK/UNIQUE؛ ایندکس اضافی تنها با query plan |
| عملیات مرتبط | A02, F05, F06, F08, F09 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## WebhookSubscriptions

رویداد و مقصد سروری شناخته‌شده

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | uniqueidentifier | خیر | NEWSEQUENTIALID() | شناسه داخلی سرور |
| EventCode | varchar(80) | خیر | ندارد / مدیریت صریح سرور | فراداده EventCode در WebhookSubscriptions |
| DestinationKey | nvarchar(80) | خیر | ندارد / مدیریت صریح سرور | مرجع allowlist سرور؛ نه URL یا credential |
| Enabled | bit | خیر | 0 | فراداده Enabled در WebhookSubscriptions |
| RowVersion | rowversion | خیر | ندارد / مدیریت صریح سرور | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | (EventCode, DestinationKey) |
| FK | ندارد |
| CHECK | کنترل دامنه در سرویس و نوع ستون |
| ایندکس | PK/UNIQUE؛ ایندکس اضافی تنها با query plan |
| عملیات مرتبط | F11, G01 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## AuditLogs

audit سرور، بدون راز یا رسانه

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | bigint IDENTITY(1,1) | خیر | ندارد / مدیریت صریح سرور | شناسه داخلی سرور |
| ActorReference | nvarchar(160) | خیر | ندارد / مدیریت صریح سرور | فراداده ActorReference در AuditLogs |
| InspectionId | uniqueidentifier | بله | ندارد / مدیریت صریح سرور | شناسه مرجع InspectionId |
| ActionCode | varchar(100) | خیر | ندارد / مدیریت صریح سرور | فراداده ActionCode در AuditLogs |
| ResourceType | varchar(80) | خیر | ندارد / مدیریت صریح سرور | فراداده ResourceType در AuditLogs |
| ResourceId | nvarchar(160) | خیر | ندارد / مدیریت صریح سرور | فراداده ResourceId در AuditLogs |
| CorrelationId | varchar(80) | خیر | ندارد / مدیریت صریح سرور | فراداده CorrelationId در AuditLogs |
| MetadataJson | nvarchar(max) | بله | ندارد / مدیریت صریح سرور | جزئیات whitelist بدون راز یا باینری |
| CreatedAt | datetime2(3) | خیر | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | ندارد |
| FK | (InspectionId) → Inspections(Id) |
| CHECK | [MetadataJson] IS NULL OR ISJSON([MetadataJson])=1 |
| ایندکس | (InspectionId, CreatedAt)؛ (ActionCode, CreatedAt) |
| عملیات مرتبط | A03, A04, A06, A09, B01, B06, B07, B09, B10, C01, C02, C03, C07, D02, D06, D07, D08, D09, E03, E04, E05, E06, E07, E08, E09, E10, F01, F02, F03, F04, F06, F07, F08, F09, F10, F11, G01, G02, G03, G04 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## NotificationOutbox

اعلان اختیاری مصوب؛ نه جایگزین وضعیت سامانه

| ستون | نوع SQL Server | NULL | پیش‌فرض | معنا |
|---|---|---|---|---|
| Id | uniqueidentifier | خیر | NEWSEQUENTIALID() | شناسه داخلی سرور |
| InspectionId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع InspectionId |
| EventId | uniqueidentifier | خیر | ندارد / مدیریت صریح سرور | شناسه مرجع EventId |
| ChannelCode | varchar(16) | خیر | ندارد / مدیریت صریح سرور | فراداده ChannelCode در NotificationOutbox |
| RecipientReference | nvarchar(160) | خیر | ندارد / مدیریت صریح سرور | مرجع هویت مبدأ؛ نه شماره دلخواه مرورگر |
| TemplateKey | nvarchar(80) | خیر | ندارد / مدیریت صریح سرور | کلید منطقی قالب |
| State | varchar(16) | خیر | ندارد / مدیریت صریح سرور | وضعیت این منبع؛ قید CHECK حاکم است |
| AttemptCount | int | خیر | 0 | شمار تلاش غیرمنفی |
| NextRetryAt | datetime2(3) | بله | ندارد / مدیریت صریح سرور | زمان تلاش بعدی با backoff محدود |
| CreatedAt | datetime2(3) | خیر | SYSUTCDATETIME() | زمان UTC سرور برای CreatedAt |
| RowVersion | rowversion | خیر | ندارد / مدیریت صریح سرور | نسخه هشت‌بایتی CAS؛ زمان یا کلید هویت نیست |

| قید | تعریف |
|---|---|
| PK | Id |
| UNIQUE | (EventId, ChannelCode) |
| FK | (InspectionId) → Inspections(Id) |
| CHECK | [State] IN ('queued','sending','sent','failed')؛ [AttemptCount]>=0 |
| ایندکس | (State, NextRetryAt) |
| عملیات مرتبط | G01 |
| امنیت | فقط پایگاه همین نصب؛ کنترل مالکیت/نقش/ارجاع در لحظه commit؛ ذخیره باینری رسانه در SQL ممنوع |

## تراکنش و بازیابی

ثبت/تأیید فرمان، CAS، تغییر pointer، وضعیت و audit در تراکنش کوتاه SQL هستند؛ شبکه/کپی فایل را داخل قفل طولانی SQL نگه ندارید. filesystem و SQL دو منبع مستقل‌اند و commit مشترک خودکار ندارند. [فصل ۸](08-MEDIA-FILE-STORAGE.md) پروتکل manifest/staging، rename امن، receipt، reconciliation و retention hold را تعیین می‌کند. IdempotencyRecords نباید session token یا signed media URL را در پاسخ ذخیره کند. TTL همه اجاره‌ها/کلیدها/نگهداری باید با مسئول Backend و کسب‌وکار تصویب شود.
