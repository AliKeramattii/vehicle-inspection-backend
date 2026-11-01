# نگاشت عملیات، API و پایگاه داده

وضعیت: **پیشنهادی و نیازمند تصویب Backend**. تاریخ بررسی منابع: 2026-10-27. این اسناد هیچ سرویس تولیدی یا migration اجراشده‌ای را اثبات نمی‌کنند.

این جدول تمام ۶۳ عملیات را به قرارداد پیشنهادی و اثر ذخیره‌سازی وصل می‌کند. شناسه‌های فنی با domain/adapter تطبیق دارند؛ مرز برنامه تغییر نکرده است. ستون خالی SQL برای static/bootstrap، نشست سرویس هویت یا Neshan به معنای ایجاد جدول جعلی نیست.

| عملیات | قرارداد | جدول‌ها | آداپتور |
|---|---|---|---|
| A01 | P00 | بدون جدول رسانه/تجاری جدید | src/config/site-settings.loader.ts |
| A02 | P01 | BrandingAssets, SiteSettings, SiteSettingsAssetLinks, SiteSettingsVersions | src/config/site-settings.loader.ts |
| A03 | AU01 | AuditLogs, Customers, IdempotencyRecords, SourceInsuranceRequests | src/features/identity/source-context.ts |
| A04 | AU02 | AuditLogs, IdempotencyRecords, StaffRoleAssignments, StaffUsers | src/features/identity/staff-session.ts |
| A05 | AU03 | Customers, SourceInsuranceRequests, StaffRoleAssignments, StaffUsers | src/features/identity/source-context.ts |
| A06 | AU04 | AuditLogs | src/features/identity/staff-session.ts |
| A07 | AU05 | Customers, SourceInsuranceRequests | src/lib/api/repositories.ts |
| A08 | AU06 | Customers, SourceInsuranceRequests | src/lib/api/repositories.ts |
| A09 | AU07 | AuditLogs, Customers, IdempotencyRecords, SourceInsuranceRequests | src/lib/api/repositories.ts |
| B01 | I01 | AuditLogs, IdempotencyRecords, InspectionTemplates, Inspections, SourceInsuranceRequests, Vehicles | src/features/inspection-status/lifecycle-repository.ts |
| B02 | I02 | InspectionLocations, Inspections, Vehicles | src/lib/api/repositories.ts |
| B03 | I03 | Inspections, SourceInsuranceRequests | src/features/inspection-status/customer-entry.tsx |
| B04 | I04 | Customers, Inspections, SourceInsuranceRequests | src/features/review-operations/model.ts |
| B05 | I05 | EvidenceRequirements, InspectionTemplates, RequirementAlternatives | src/lib/api/repositories.ts |
| B06 | I06 | AuditLogs, IdempotencyRecords, InspectionConsents | src/lib/api/repositories.ts |
| B07 | I07 | AuditLogs, IdempotencyRecords, InspectionLocations, Inspections | src/lib/media/inspection-facts-store.ts |
| B08 | I08 | Vehicles | src/lib/api/repositories.ts |
| B09 | I09, I10 | AuditLogs, IdempotencyRecords, Inspections, Vehicles | src/lib/api/repositories.ts |
| B10 | I11, I12 | AuditLogs, IdempotencyRecords, Inspections, OdometerReadings | src/lib/media/capture-data-store.ts |
| B11 | M01 | بدون جدول رسانه/تجاری جدید | src/lib/map/reverse-geocoder.ts |
| C01 | EV01 | AuditLogs, EvidenceVersions, IdempotencyRecords, InspectionEvidence, MediaFiles, UploadSessions | src/features/upload/upload-transport.ts |
| C02 | EV02 | AuditLogs, EvidenceVersions, IdempotencyRecords, MediaFiles, UploadSessions | src/features/upload/upload-coordinator.ts |
| C03 | EV03 | AuditLogs, EvidenceVersions, IdempotencyRecords, MediaFiles, MediaProcessingJobs, UploadSessions | src/features/upload/upload-transport.ts |
| C04 | EV04 | EvidenceVersions, InspectionEvidence, MediaFiles | src/features/upload/queue-repository.ts |
| C05 | EV04 | EvidenceReviews, EvidenceVersions, MediaFiles, MediaProcessingJobs | src/features/upload/upload-transport.ts |
| C06 | EV05 | EvidenceVersions, MediaFiles, ReviewerAssignments | src/features/upload/upload-preview.tsx |
| C07 | EV06 | AuditLogs, EvidenceVersions, IdempotencyRecords, UploadSessions | src/features/upload/upload-coordinator.ts |
| D01 | I12 | EvidenceVersions, InspectionEvidence, Inspections, OdometerReadings | src/features/submission/summary-source.ts |
| D02 | I13 | AuditLogs, IdempotencyRecords, InspectionStatusHistory, InspectionSubmissions, Inspections, SubmissionEvidence | src/features/submission/submission-service.ts |
| D03 | I13 | IdempotencyRecords, InspectionSubmissions | src/features/submission/submission-service.ts |
| D04 | I14 | CorrectionRequests, ForwardingJobs, InspectionStatusHistory, Inspections | src/features/inspection-status/status-service.ts |
| D05 | R01 | CorrectionItems, CorrectionRequests, InspectionSubmissions | src/features/additional-evidence/request-repository.ts |
| D06 | EV01, EV03, R02 | AuditLogs, CorrectionItems, EvidenceVersions, IdempotencyRecords, MediaFiles, UploadSessions | src/features/additional-evidence/request-service.ts |
| D07 | R03 | AuditLogs, CorrectionItems, CorrectionRequests, IdempotencyRecords, InspectionEvidence, InspectionStatusHistory, InspectionSubmissions, Inspections, SubmissionEvidence | src/features/additional-evidence/request-service.ts |
| D08 | R04 | AuditLogs, CorrectionItems, IdempotencyRecords | src/features/inspection-status/lifecycle-repository.ts |
| D09 | I15 | AuditLogs, IdempotencyRecords, InspectionStatusHistory, Inspections, SourceInsuranceRequests, Vehicles | src/features/inspection-status/lifecycle-repository.ts |
| E01 | I04 | Inspections, ReviewerAssignments, StaffUsers | src/features/review-operations/repository.ts |
| E02 | RV01 | EvidenceReviews, Inspections, InternalNotes, ReviewerAssignments | src/features/review-operations/repository.ts |
| E03 | RV02 | AuditLogs, IdempotencyRecords, InspectionStatusHistory, Inspections, ReviewerAssignments, StaffUsers | src/features/review-operations/model.ts |
| E04 | RV03, AD01 | AuditLogs, IdempotencyRecords, StaffOperationsSettings, StaffUsers | src/features/review-operations/repository.ts |
| E05 | RV04 | AuditLogs, CorrectionItems, CorrectionRequests, EvidenceReviews, IdempotencyRecords, InspectionStatusHistory, Inspections | src/features/review-operations/repository.ts |
| E06 | RV05 | AuditLogs, CorrectionItems, CorrectionRequests, IdempotencyRecords, InspectionStatusHistory, Inspections | src/features/review-operations/repository.ts |
| E07 | RV06 | AuditLogs, CorrectionItems, IdempotencyRecords, Inspections, Vehicles | src/features/review-operations/repository.ts |
| E08 | RV07 | AuditLogs, IdempotencyRecords, InternalNotes | src/features/review-operations/repository.ts |
| E09 | RV08 | AuditLogs, ForwardingJobs, IdempotencyRecords, InspectionReviews, InspectionStatusHistory, Inspections | src/features/review-operations/repository.ts |
| E10 | RV09 | AuditLogs, EvidenceReviews, EvidenceVersions, InspectionStatusHistory | src/features/review-operations/repository.ts |
| F01 | AD01 | AuditLogs, InspectionTemplates, StaffRoleAssignments, StaffUsers | src/features/admin/repository.ts |
| F02 | AD02 | AuditLogs, EvidenceRequirements, IdempotencyRecords, InspectionTemplates, RequirementAlternatives | src/features/admin/repository.ts |
| F03 | AD03 | AuditLogs, EvidenceRequirements, IdempotencyRecords, InspectionTemplates, RequirementAlternatives | src/features/admin/repository.ts |
| F04 | AD04 | AuditLogs, IdempotencyRecords, InspectionTemplates | src/features/admin/repository.ts |
| F05 | P01 | BrandingAssets, SiteSettings, SiteSettingsAssetLinks, SiteSettingsVersions | src/config/site-settings.loader.ts |
| F06 | AD05, AD06 | AuditLogs, IdempotencyRecords, SiteSettings, SiteSettingsAssetLinks, SiteSettingsVersions | src/config/site-settings.repository.ts |
| F07 | AD07 | AuditLogs, IdempotencyRecords, SiteSettings, SiteSettingsVersions | src/config/site-settings.repository.ts |
| F08 | AD08 | AuditLogs, BrandingAssets, IdempotencyRecords, SiteSettingsAssetLinks | src/features/admin/assets/asset-repository.ts |
| F09 | AD06 | AuditLogs, IdempotencyRecords, SiteSettings, SiteSettingsAssetLinks, SiteSettingsVersions | src/features/admin/repository.ts |
| F10 | AD01, AD09 | AuditLogs, IdempotencyRecords, StaffRoleAssignments, StaffUsers | src/features/admin/repository.ts |
| F11 | AD10 | AuditLogs, IdempotencyRecords, WebhookSubscriptions | src/features/admin/repository.ts |
| F12 | AD11 | بدون جدول رسانه/تجاری جدید | src/features/admin/operational-snapshot.tsx |
| G01 | رویداد/کارگر سرور | AuditLogs, IdempotencyRecords, Inspections, NotificationOutbox, WebhookSubscriptions | src/features/inspection-status/integration-contracts.ts |
| G02 | رویداد/کارگر سرور | AuditLogs, ForwardingJobs, IdempotencyRecords, InspectionReviews, InspectionStatusHistory, InspectionSubmissions, Inspections | src/features/inspection-status/integration-contracts.ts |
| G03 | رویداد/کارگر سرور | AuditLogs, ForwardingAttempts, ForwardingJobs, IdempotencyRecords, InspectionStatusHistory, Inspections, MediaFiles | src/features/inspection-status/integration-contracts.ts |
| G04 | FW01 | AuditLogs, ForwardingAttempts, ForwardingJobs, IdempotencyRecords | src/features/inspection-status/integration-contracts.ts |
| G05 | I14 | ForwardingJobs | src/features/inspection-status/lifecycle-model.ts |

## شناسه خارجی در برابر کلید SQL

sourceRequestId خارجی از SourceInsuranceRequests.ExternalRequestId با اتصال issuer/owner حل می‌شود؛ Id داخلی GUID است. inspectionId در API از PublicId بازدید حل می‌شود. PhotoRequirement.id مانند spec-plate در EvidenceRequirements.RequirementKey ذخیره می‌شود؛ GUID جدول جای این رشته در DTO را نمی‌گیرد. alternativeId دامنه از RequirementAlternatives.AlternativeKey و revision از EvidenceVersions.RevisionKey به کلیدهای داخلی نگاشت می‌شوند. localBlobKey مسیر filesystem سرور نیست و برای یافتن فایل در سرور پذیرفته نمی‌شود.

## نگاشت کامل اثر هر عملیات

جدول نشست/OTP در provider هویت مصوب است و در شمار ۳۷ جدول تجاری جعل نشده است. جدول اختیاری فقط با فعال‌بودن مسئولیت مربوط به کار می‌رود. مجوز و قفل والد در همه فرمان‌ها بازبینی می‌شود.

### A01 — بارگذاری هویت نصب و نشانی‌های عمومی

| موضوع | اثر |
|---|---|
| روش و مسیر | GET /site-bootstrap.json |
| خواندن SQL | ندارد |
| نوشتن SQL | ندارد |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | خواندن بدون تغییر چرخه عمر |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تکرار امن | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| مجوز | بدون نشست؛ فقط داده عمومی مجاز نصب |
| تصمیم باز | D01, D02 |

### A02 — خواندن تنظیمات منتشرشده

| موضوع | اثر |
|---|---|
| روش و مسیر | GET /api/public/site-settings |
| خواندن SQL | BrandingAssets, SiteSettings, SiteSettingsAssetLinks, SiteSettingsVersions |
| نوشتن SQL | ندارد |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | خواندن بدون تغییر چرخه عمر |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تکرار امن | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| مجوز | بدون نشست؛ فقط داده عمومی مجاز نصب |
| تصمیم باز | D01, D02 |

### A03 — تحویل هویت مشتری از سامانه بیمه

| موضوع | اثر |
|---|---|
| روش و مسیر | POST /api/auth/customer-handoff |
| خواندن SQL | Customers, IdempotencyRecords, SourceInsuranceRequests |
| نوشتن SQL | AuditLogs, Customers, IdempotencyRecords, SourceInsuranceRequests |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات Customers,SourceInsuranceRequests,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | بلیت معتبر مبدأ و ضد replay؛ روش نهایی نیازمند تصویب |
| تصمیم باز | D01, D02 |

### A04 — ورود سازمانی کارکنان

| موضوع | اثر |
|---|---|
| روش و مسیر | POST /api/auth/staff/exchange |
| خواندن SQL | IdempotencyRecords, StaffRoleAssignments, StaffUsers |
| نوشتن SQL | AuditLogs, IdempotencyRecords, StaffRoleAssignments, StaffUsers |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات StaffUsers,StaffRoleAssignments,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | بلیت معتبر مبدأ و ضد replay؛ روش نهایی نیازمند تصویب |
| تصمیم باز | D01, D02 |

### A05 — بررسی تداوم نشست

| موضوع | اثر |
|---|---|
| روش و مسیر | GET /api/me |
| خواندن SQL | Customers, SourceInsuranceRequests, StaffRoleAssignments, StaffUsers |
| نوشتن SQL | ندارد |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | خواندن بدون تغییر چرخه عمر |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تکرار امن | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D01, D02 |

### A06 — خروج و ابطال نشست

| موضوع | اثر |
|---|---|
| روش و مسیر | POST /api/auth/logout |
| خواندن SQL | ندارد |
| نوشتن SQL | ندارد |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D01, D02 |

### A07 — اعتبارسنجی معرفی‌نامه

| موضوع | اثر |
|---|---|
| روش و مسیر | POST /api/referrals/validate |
| خواندن SQL | Customers, SourceInsuranceRequests |
| نوشتن SQL | ندارد |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | خواندن بدون تغییر چرخه عمر |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تکرار امن | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| مجوز | بلیت معتبر مبدأ و ضد replay؛ روش نهایی نیازمند تصویب |
| تصمیم باز | D01, D02 |

### A08 — صدور و ارسال دوباره چالش پیامکی

| موضوع | اثر |
|---|---|
| روش و مسیر | POST /api/auth/otp/request |
| خواندن SQL | Customers, SourceInsuranceRequests |
| نوشتن SQL | ندارد |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | بلیت معتبر مبدأ و ضد replay؛ روش نهایی نیازمند تصویب |
| تصمیم باز | D01, D02 |

### A09 — تأیید چالش پیامکی

| موضوع | اثر |
|---|---|
| روش و مسیر | POST /api/auth/otp/verify |
| خواندن SQL | Customers, SourceInsuranceRequests |
| نوشتن SQL | ندارد |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | بلیت معتبر مبدأ و ضد replay؛ روش نهایی نیازمند تصویب |
| تصمیم باز | D01, D02 |

### B01 — ساخت اولین تلاش بازدید

| موضوع | اثر |
|---|---|
| روش و مسیر | POST /api/inspections |
| خواندن SQL | IdempotencyRecords, InspectionTemplates, Inspections, SourceInsuranceRequests, Vehicles |
| نوشتن SQL | AuditLogs, IdempotencyRecords, Inspections, Vehicles |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات Inspections,Vehicles,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### B02 — خواندن بازدید مجاز

| موضوع | اثر |
|---|---|
| روش و مسیر | GET /api/inspections/{inspectionId} |
| خواندن SQL | InspectionLocations, Inspections, Vehicles |
| نوشتن SQL | ندارد |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | خواندن بدون تغییر چرخه عمر |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تکرار امن | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### B03 — یافتن تلاش جاری همان درخواست

| موضوع | اثر |
|---|---|
| روش و مسیر | GET /api/inspections/current |
| خواندن SQL | Inspections, SourceInsuranceRequests |
| نوشتن SQL | ندارد |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | خواندن بدون تغییر چرخه عمر |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تکرار امن | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### B04 — پیگیری و جست‌وجوی مجاز

| موضوع | اثر |
|---|---|
| روش و مسیر | GET /api/inspections |
| خواندن SQL | Customers, Inspections, SourceInsuranceRequests |
| نوشتن SQL | ندارد |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | خواندن بدون تغییر چرخه عمر |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تکرار امن | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### B05 — خواندن قالب ثابت بازدید

| موضوع | اثر |
|---|---|
| روش و مسیر | GET /api/inspections/{inspectionId}/capture-plan |
| خواندن SQL | EvidenceRequirements, InspectionTemplates, RequirementAlternatives |
| نوشتن SQL | ندارد |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | خواندن بدون تغییر چرخه عمر |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تکرار امن | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### B06 — ثبت پذیرش نسخه شرایط

| موضوع | اثر |
|---|---|
| روش و مسیر | POST /api/inspections/{inspectionId}/consent |
| خواندن SQL | IdempotencyRecords, InspectionConsents |
| نوشتن SQL | AuditLogs, IdempotencyRecords, InspectionConsents |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات InspectionConsents,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### B07 — ثبت محل تأییدشده

| موضوع | اثر |
|---|---|
| روش و مسیر | PUT /api/inspections/{inspectionId}/location |
| خواندن SQL | IdempotencyRecords, InspectionLocations, Inspections |
| نوشتن SQL | AuditLogs, IdempotencyRecords, InspectionLocations, Inspections |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات InspectionLocations,Inspections,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### B08 — نمایش مشخصات خودرو

| موضوع | اثر |
|---|---|
| روش و مسیر | GET /api/inspections/{inspectionId}/vehicle |
| خواندن SQL | Vehicles |
| نوشتن SQL | ندارد |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | خواندن بدون تغییر چرخه عمر |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تکرار امن | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### B09 — تأیید خودرو یا اصلاح مجاز پلاک

| موضوع | اثر |
|---|---|
| روش و مسیر | PUT /api/inspections/{inspectionId}/vehicle؛ PUT /api/inspections/{inspectionId}/vehicle/plate |
| خواندن SQL | IdempotencyRecords, Inspections, Vehicles |
| نوشتن SQL | AuditLogs, IdempotencyRecords, Inspections, Vehicles |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات Vehicles,Inspections,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### B10 — ثبت و ویرایش کیلومتر عددی

| موضوع | اثر |
|---|---|
| روش و مسیر | PUT /api/inspections/{inspectionId}/odometer؛ GET /api/inspections/{inspectionId}/summary |
| خواندن SQL | IdempotencyRecords, Inspections, OdometerReadings |
| نوشتن SQL | AuditLogs, IdempotencyRecords, Inspections, OdometerReadings |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات OdometerReadings,Inspections,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### B11 — دریافت نشانی فارسی مختصات

| موضوع | اثر |
|---|---|
| روش و مسیر | GET /api/maps/reverse |
| خواندن SQL | ندارد |
| نوشتن SQL | ندارد |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | خواندن بدون تغییر چرخه عمر |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تکرار امن | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### C01 — ثبت نسخه مدرک و قرارداد انتقال

| موضوع | اثر |
|---|---|
| روش و مسیر | POST /api/inspections/{inspectionId}/evidence |
| خواندن SQL | EvidenceVersions, IdempotencyRecords, InspectionEvidence, MediaFiles, UploadSessions |
| نوشتن SQL | AuditLogs, EvidenceVersions, IdempotencyRecords, InspectionEvidence, MediaFiles, UploadSessions |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | رزرو مسیر نسخه در metadata؛ هنوز هیچ بایتی از مرورگر دریافت نشده است. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات InspectionEvidence,EvidenceVersions,MediaFiles,UploadSessions,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### C02 — انتقال بایت‌های رسانه

| موضوع | اثر |
|---|---|
| روش و مسیر | PUT /api/uploads/{uploadId}/content |
| خواندن SQL | EvidenceVersions, IdempotencyRecords, MediaFiles, UploadSessions |
| نوشتن SQL | AuditLogs, EvidenceVersions, IdempotencyRecords, MediaFiles, UploadSessions |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | نوشتن stream محدود در staging همان uploadId؛ بدون بازنویسی اصل خوب. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات UploadSessions,MediaFiles,EvidenceVersions,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### C03 — تأیید دریافت پایدار فایل

| موضوع | اثر |
|---|---|
| روش و مسیر | POST /api/evidence/{evidenceId}/complete |
| خواندن SQL | EvidenceVersions, IdempotencyRecords, MediaFiles, MediaProcessingJobs, UploadSessions |
| نوشتن SQL | AuditLogs, EvidenceVersions, IdempotencyRecords, MediaFiles, MediaProcessingJobs, UploadSessions |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | verify/hash/flush، انتشار فایل همان نسخه و در صورت تصویب enqueue مشتق؛ SQL و filesystem نیاز به reconciliation دارند. |
| وضعیت | پس از hash/size و دوام فایل، رسید uploaded ثبت می‌شود؛ processing/verified مستقل‌اند. کاندیدای دور اصلاح تا resubmit تأییدشده جای اصل را نمی‌گیرد. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات UploadSessions,MediaFiles,EvidenceVersions,MediaProcessingJobs,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### C04 — بازخوانی و تطبیق وضعیت مدارک

| موضوع | اثر |
|---|---|
| روش و مسیر | GET /api/inspections/{inspectionId}/evidence |
| خواندن SQL | EvidenceVersions, InspectionEvidence, MediaFiles |
| نوشتن SQL | ندارد |
| خواندن فایل | فایل/مشتق خصوصی همان نسخه با مجوز؛ فقط در صورت نیاز و بدون بارگذاری گروهی بایت‌ها. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | خواندن بدون تغییر چرخه عمر |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تکرار امن | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### C05 — خواندن نتیجه پردازش مدرک

| موضوع | اثر |
|---|---|
| روش و مسیر | GET /api/inspections/{inspectionId}/evidence |
| خواندن SQL | EvidenceVersions, MediaFiles, MediaProcessingJobs |
| نوشتن SQL | ندارد |
| خواندن فایل | فایل/مشتق خصوصی همان نسخه با مجوز؛ فقط در صورت نیاز و بدون بارگذاری گروهی بایت‌ها. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | خواندن بدون تغییر چرخه عمر |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تکرار امن | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### C06 — نمایش امن عکس یا پخش ویدیو

| موضوع | اثر |
|---|---|
| روش و مسیر | GET /api/inspections/{inspectionId}/evidence/{evidenceId}/file |
| خواندن SQL | EvidenceVersions, MediaFiles, ReviewerAssignments |
| نوشتن SQL | ندارد |
| خواندن فایل | فایل/مشتق خصوصی همان نسخه با مجوز؛ فقط در صورت نیاز و بدون بارگذاری گروهی بایت‌ها. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | خواندن بدون تغییر چرخه عمر |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تکرار امن | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### C07 — لغو انتقال نسخه منسوخ

| موضوع | اثر |
|---|---|
| روش و مسیر | POST /api/evidence/{evidenceId}/cancel-upload |
| خواندن SQL | EvidenceVersions, IdempotencyRecords, UploadSessions |
| نوشتن SQL | AuditLogs, EvidenceVersions, IdempotencyRecords, UploadSessions |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | توقف session منسوخ؛ فایل current یا تاریخچه حذف نمی‌شود. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات UploadSessions,EvidenceVersions,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### D01 — خلاصه و آمادگی ارسال

| موضوع | اثر |
|---|---|
| روش و مسیر | GET /api/inspections/{inspectionId}/summary |
| خواندن SQL | EvidenceVersions, InspectionEvidence, Inspections, OdometerReadings |
| نوشتن SQL | ندارد |
| خواندن فایل | فایل/مشتق خصوصی همان نسخه با مجوز؛ فقط در صورت نیاز و بدون بارگذاری گروهی بایت‌ها. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | خواندن بدون تغییر چرخه عمر |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تکرار امن | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### D02 — ارسال رسمی بازدید

| موضوع | اثر |
|---|---|
| روش و مسیر | POST /api/inspections/{inspectionId}/submit |
| خواندن SQL | IdempotencyRecords, InspectionSubmissions, Inspections, SubmissionEvidence |
| نوشتن SQL | AuditLogs, IdempotencyRecords, InspectionStatusHistory, InspectionSubmissions, Inspections, SubmissionEvidence |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | snapshot نسخه‌های دقیق، رسید پایدار و قفل submitted؛ پردازش غیرنهایی مانع باینری نیست، retake و نسخه نامعتبر مانع‌اند. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات InspectionSubmissions,SubmissionEvidence,Inspections,InspectionStatusHistory,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### D03 — بازیابی نتیجه ارسال نامطمئن

| موضوع | اثر |
|---|---|
| روش و مسیر | POST /api/inspections/{inspectionId}/submit |
| خواندن SQL | IdempotencyRecords, InspectionSubmissions |
| نوشتن SQL | ندارد |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### D04 — وضعیت و رسید مشتری

| موضوع | اثر |
|---|---|
| روش و مسیر | GET /api/inspections/{inspectionId}/status |
| خواندن SQL | CorrectionRequests, ForwardingJobs, InspectionStatusHistory, Inspections |
| نوشتن SQL | ندارد |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | خواندن بدون تغییر چرخه عمر |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تکرار امن | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### D05 — درخواست دقیق مدرک تکمیلی

| موضوع | اثر |
|---|---|
| روش و مسیر | GET /api/inspections/{inspectionId}/evidence-requests |
| خواندن SQL | CorrectionItems, CorrectionRequests, InspectionSubmissions |
| نوشتن SQL | ندارد |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | خواندن بدون تغییر چرخه عمر |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تکرار امن | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### D06 — پیوند نسخه جایگزین به قلم درخواست

| موضوع | اثر |
|---|---|
| روش و مسیر | POST /api/inspections/{inspectionId}/evidence؛ POST /api/evidence/{evidenceId}/complete؛ POST /api/evidence-requests/{requestId}/replacement |
| خواندن SQL | CorrectionItems, EvidenceVersions, IdempotencyRecords, MediaFiles, UploadSessions |
| نوشتن SQL | AuditLogs, CorrectionItems, EvidenceVersions, IdempotencyRecords, MediaFiles, UploadSessions |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات EvidenceVersions,MediaFiles,UploadSessions,CorrectionItems,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### D07 — ارسال دوباره اصلاحات مشخص

| موضوع | اثر |
|---|---|
| روش و مسیر | POST /api/inspections/{inspectionId}/resubmit |
| خواندن SQL | CorrectionItems, CorrectionRequests, IdempotencyRecords, InspectionEvidence, InspectionSubmissions, Inspections, SubmissionEvidence |
| نوشتن SQL | AuditLogs, CorrectionItems, CorrectionRequests, IdempotencyRecords, InspectionEvidence, InspectionStatusHistory, InspectionSubmissions, Inspections, SubmissionEvidence |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات CorrectionRequests,CorrectionItems,InspectionEvidence,InspectionSubmissions,SubmissionEvidence,Inspections,InspectionStatusHistory,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### D08 — پیشنهاد اصلاح فیلد خواسته‌شده

| موضوع | اثر |
|---|---|
| روش و مسیر | PUT /api/inspections/{inspectionId}/field-corrections/{taskId} |
| خواندن SQL | CorrectionItems, IdempotencyRecords |
| نوشتن SQL | AuditLogs, CorrectionItems, IdempotencyRecords |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات CorrectionItems,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### D09 — تلاش تازه پس از رد کامل

| موضوع | اثر |
|---|---|
| روش و مسیر | POST /api/inspections/{inspectionId}/attempts |
| خواندن SQL | IdempotencyRecords, Inspections, SourceInsuranceRequests, Vehicles |
| نوشتن SQL | AuditLogs, IdempotencyRecords, InspectionStatusHistory, Inspections, Vehicles |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | یک inspectionId/attempt تازه، با previousAttemptId و فضای مدرک خالی؛ وضعیت و فایل تلاش ردشده عوض نمی‌شود. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات Inspections,Vehicles,InspectionStatusHistory,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### E01 — فهرست پرونده‌ها و آمار واقعی

| موضوع | اثر |
|---|---|
| روش و مسیر | GET /api/inspections |
| خواندن SQL | Inspections, ReviewerAssignments, StaffUsers |
| نوشتن SQL | ندارد |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | خواندن بدون تغییر چرخه عمر |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تکرار امن | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### E02 — پرونده ارجاع‌شده و جزئیات

| موضوع | اثر |
|---|---|
| روش و مسیر | GET /api/reviewer/cases/{caseId} |
| خواندن SQL | EvidenceReviews, Inspections, InternalNotes, ReviewerAssignments |
| نوشتن SQL | ندارد |
| خواندن فایل | فایل/مشتق خصوصی همان نسخه با مجوز؛ فقط در صورت نیاز و بدون بارگذاری گروهی بایت‌ها. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | خواندن بدون تغییر چرخه عمر |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تکرار امن | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| مجوز | نشست کارکنان؛ کارشناس دارای ارجاع یا مدیر دارای مجوز خواندن همان پرونده. پاسخ براساس نقش پالایش شود؛ یادداشت خصوصی فقط با اختیار صریح و تصمیم فقط برای کارشناس مجاز است. |
| تصمیم باز | D04, D08 |

### E03 — ارجاع و ارجاع مجدد

| موضوع | اثر |
|---|---|
| روش و مسیر | POST /api/admin/inspections/{inspectionId}/assignment |
| خواندن SQL | IdempotencyRecords, Inspections, ReviewerAssignments, StaffUsers |
| نوشتن SQL | AuditLogs, IdempotencyRecords, InspectionStatusHistory, Inspections, ReviewerAssignments |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات ReviewerAssignments,Inspections,InspectionStatusHistory,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### E04 — تنظیم حالت و ظرفیت ارجاع

| موضوع | اثر |
|---|---|
| روش و مسیر | PUT /api/admin/reviewer-policy؛ GET /api/admin/workspace |
| خواندن SQL | IdempotencyRecords, StaffOperationsSettings, StaffUsers |
| نوشتن SQL | AuditLogs, IdempotencyRecords, StaffOperationsSettings, StaffUsers |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات StaffOperationsSettings,StaffUsers,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### E05 — تصمیم درباره یک نسخه مدرک

| موضوع | اثر |
|---|---|
| روش و مسیر | POST /api/reviewer/cases/{caseId}/evidence-decisions |
| خواندن SQL | CorrectionItems, CorrectionRequests, EvidenceReviews, IdempotencyRecords, Inspections |
| نوشتن SQL | AuditLogs, CorrectionItems, CorrectionRequests, EvidenceReviews, IdempotencyRecords, InspectionStatusHistory, Inspections |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات EvidenceReviews,CorrectionRequests,CorrectionItems,Inspections,InspectionStatusHistory,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### E06 — درخواست اصلاح مشخصات خودرو

| موضوع | اثر |
|---|---|
| روش و مسیر | POST /api/reviewer/cases/{caseId}/field-corrections |
| خواندن SQL | CorrectionItems, CorrectionRequests, IdempotencyRecords, Inspections |
| نوشتن SQL | AuditLogs, CorrectionItems, CorrectionRequests, IdempotencyRecords, InspectionStatusHistory, Inspections |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات CorrectionRequests,CorrectionItems,Inspections,InspectionStatusHistory,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### E07 — بررسی پیشنهاد اصلاح فیلد

| موضوع | اثر |
|---|---|
| روش و مسیر | POST /api/reviewer/field-corrections/{taskId}/decision |
| خواندن SQL | CorrectionItems, IdempotencyRecords, Inspections, Vehicles |
| نوشتن SQL | AuditLogs, CorrectionItems, IdempotencyRecords, Inspections, Vehicles |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات CorrectionItems,Vehicles,Inspections,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### E08 — ثبت یادداشت خصوصی

| موضوع | اثر |
|---|---|
| روش و مسیر | POST /api/reviewer/cases/{caseId}/notes |
| خواندن SQL | IdempotencyRecords, InternalNotes |
| نوشتن SQL | AuditLogs, IdempotencyRecords, InternalNotes |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات InternalNotes,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### E09 — تصمیم جداگانه کل بازدید

| موضوع | اثر |
|---|---|
| روش و مسیر | POST /api/reviewer/cases/{caseId}/decision |
| خواندن SQL | ForwardingJobs, IdempotencyRecords, InspectionReviews, Inspections |
| نوشتن SQL | AuditLogs, ForwardingJobs, IdempotencyRecords, InspectionReviews, InspectionStatusHistory, Inspections |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | تأیید کل فقط پس از تأیید همه نسخه‌های لازم و فیلدها؛ outbox پایدار ایجاد می‌شود، FORWARDED تا ack معتبر ممنوع. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات InspectionReviews,Inspections,InspectionStatusHistory,ForwardingJobs,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### E10 — تاریخچه نسخه‌ها و تصمیم‌ها

| موضوع | اثر |
|---|---|
| روش و مسیر | GET /api/reviewer/cases/{caseId}/history |
| خواندن SQL | EvidenceReviews, EvidenceVersions, InspectionStatusHistory |
| نوشتن SQL | ندارد |
| خواندن فایل | فایل/مشتق خصوصی همان نسخه با مجوز؛ فقط در صورت نیاز و بدون بارگذاری گروهی بایت‌ها. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | خواندن بدون تغییر چرخه عمر |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تکرار امن | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| مجوز | نشست کارکنان؛ کارشناس دارای ارجاع یا مدیر دارای مجوز خواندن همان پرونده. پاسخ براساس نقش پالایش شود؛ یادداشت خصوصی فقط با اختیار صریح و تصمیم فقط برای کارشناس مجاز است. |
| تصمیم باز | D04, D08 |

### F01 — خواندن محیط مدیریت و قالب‌ها

| موضوع | اثر |
|---|---|
| روش و مسیر | GET /api/admin/workspace |
| خواندن SQL | InspectionTemplates, StaffRoleAssignments, StaffUsers |
| نوشتن SQL | ندارد |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | خواندن بدون تغییر چرخه عمر |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تکرار امن | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### F02 — ایجاد قالب یا پیش‌نویس

| موضوع | اثر |
|---|---|
| روش و مسیر | POST /api/admin/capture-templates |
| خواندن SQL | EvidenceRequirements, IdempotencyRecords, InspectionTemplates, RequirementAlternatives |
| نوشتن SQL | AuditLogs, EvidenceRequirements, IdempotencyRecords, InspectionTemplates, RequirementAlternatives |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات InspectionTemplates,EvidenceRequirements,RequirementAlternatives,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### F03 — ویرایش و ذخیره پیش‌نویس

| موضوع | اثر |
|---|---|
| روش و مسیر | PUT /api/admin/capture-templates/{templateId}/versions/{version}/draft |
| خواندن SQL | EvidenceRequirements, IdempotencyRecords, InspectionTemplates, RequirementAlternatives |
| نوشتن SQL | AuditLogs, EvidenceRequirements, IdempotencyRecords, InspectionTemplates, RequirementAlternatives |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات InspectionTemplates,EvidenceRequirements,RequirementAlternatives,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### F04 — انتشار یا بایگانی نسخه قالب

| موضوع | اثر |
|---|---|
| روش و مسیر | POST /api/admin/capture-templates/{templateId}/versions/{version}/publication |
| خواندن SQL | IdempotencyRecords, InspectionTemplates |
| نوشتن SQL | AuditLogs, IdempotencyRecords, InspectionTemplates |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات InspectionTemplates,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### F05 — خواندن عمومی برند

| موضوع | اثر |
|---|---|
| روش و مسیر | GET /api/public/site-settings |
| خواندن SQL | BrandingAssets, SiteSettings, SiteSettingsAssetLinks, SiteSettingsVersions |
| نوشتن SQL | ندارد |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | خواندن بدون تغییر چرخه عمر |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تکرار امن | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| مجوز | بدون نشست؛ فقط داده عمومی مجاز نصب |
| تصمیم باز | D04, D08 |

### F06 — خواندن و ذخیره پیش‌نویس تنظیمات

| موضوع | اثر |
|---|---|
| روش و مسیر | GET /api/admin/site-settings؛ PUT /api/admin/site-settings/draft |
| خواندن SQL | IdempotencyRecords, SiteSettings, SiteSettingsAssetLinks, SiteSettingsVersions |
| نوشتن SQL | AuditLogs, IdempotencyRecords, SiteSettings, SiteSettingsAssetLinks, SiteSettingsVersions |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات SiteSettings,SiteSettingsVersions,SiteSettingsAssetLinks,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### F07 — انتشار تنظیمات یا بازنشانی بصری پیش‌نویس

| موضوع | اثر |
|---|---|
| روش و مسیر | POST /api/admin/site-settings/publish |
| خواندن SQL | IdempotencyRecords, SiteSettings, SiteSettingsVersions |
| نوشتن SQL | AuditLogs, IdempotencyRecords, SiteSettings, SiteSettingsVersions |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | reset بصری فقط پیش‌نویس را ویرایش می‌کند؛ فقط انتشار، نسخه عمومی جدید می‌سازد. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات SiteSettings,SiteSettingsVersions,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### F08 — بارگذاری دارایی برند و حل مرجع

| موضوع | اثر |
|---|---|
| روش و مسیر | POST /api/admin/branding-assets |
| خواندن SQL | BrandingAssets, IdempotencyRecords, SiteSettingsAssetLinks |
| نوشتن SQL | AuditLogs, BrandingAssets, IdempotencyRecords |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ایجاد فایل برند sanitised در مسیر عمومی مجاز برند؛ این استثنا برای لوگو است، نه رسانه بازدید. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات BrandingAssets,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### F09 — سازگاری تنظیمات قدیمی برند

| موضوع | اثر |
|---|---|
| روش و مسیر | PUT /api/admin/site-settings/draft |
| خواندن SQL | IdempotencyRecords, SiteSettings, SiteSettingsAssetLinks, SiteSettingsVersions |
| نوشتن SQL | AuditLogs, IdempotencyRecords, SiteSettings, SiteSettingsAssetLinks, SiteSettingsVersions |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات SiteSettings,SiteSettingsVersions,SiteSettingsAssetLinks,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### F10 — نقش و فعال‌بودن کارکنان

| موضوع | اثر |
|---|---|
| روش و مسیر | GET /api/admin/workspace؛ PUT /api/admin/staff/{staffId}/roles |
| خواندن SQL | IdempotencyRecords, StaffRoleAssignments, StaffUsers |
| نوشتن SQL | AuditLogs, IdempotencyRecords, StaffRoleAssignments, StaffUsers |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات StaffUsers,StaffRoleAssignments,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### F11 — فعال‌سازی وب‌هوک ازپیش‌تعریف‌شده

| موضوع | اثر |
|---|---|
| روش و مسیر | PUT /api/admin/webhooks/{webhookId} |
| خواندن SQL | IdempotencyRecords, WebhookSubscriptions |
| نوشتن SQL | AuditLogs, IdempotencyRecords, WebhookSubscriptions |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات WebhookSubscriptions,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### F12 — سلامت، ذخیره‌سازی و سیاست قابل مشاهده

| موضوع | اثر |
|---|---|
| روش و مسیر | GET /api/admin/system/health |
| خواندن SQL | ندارد |
| نوشتن SQL | ندارد |
| خواندن فایل | فایل/مشتق خصوصی همان نسخه با مجوز؛ فقط در صورت نیاز و بدون بارگذاری گروهی بایت‌ها. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | خواندن بدون تغییر چرخه عمر |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تکرار امن | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D04, D08 |

### G01 — اعلان رویداد وضعیت

| موضوع | اثر |
|---|---|
| روش و مسیر | رویداد/کارگر؛ بدون مسیر مرورگر |
| خواندن SQL | IdempotencyRecords, Inspections, NotificationOutbox, WebhookSubscriptions |
| نوشتن SQL | AuditLogs, IdempotencyRecords, NotificationOutbox |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات NotificationOutbox,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | tenant از نصب و نشست معتبر؛ اتصال subject/sourceRequest/inspection و برای Reviewer ارجاع فعال. کارگر سرور یا مدیر دارای مجوز عملیاتی؛ مشتری فقط projection امن |
| تصمیم باز | D11, D12 |

### G02 — ایجاد کار تحویل نسخه تأییدشده

| موضوع | اثر |
|---|---|
| روش و مسیر | رویداد/کارگر؛ بدون مسیر مرورگر |
| خواندن SQL | ForwardingJobs, IdempotencyRecords, InspectionReviews, InspectionSubmissions, Inspections |
| نوشتن SQL | AuditLogs, ForwardingJobs, IdempotencyRecords, InspectionStatusHistory, Inspections |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات ForwardingJobs,Inspections,InspectionStatusHistory,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | tenant از نصب و نشست معتبر؛ اتصال subject/sourceRequest/inspection و برای Reviewer ارجاع فعال. کارگر سرور یا مدیر دارای مجوز عملیاتی؛ مشتری فقط projection امن |
| تصمیم باز | D11, D12 |

### G03 — ارسال به سامانه بیمه و تأیید دریافت

| موضوع | اثر |
|---|---|
| روش و مسیر | رویداد/کارگر؛ بدون مسیر مرورگر |
| خواندن SQL | ForwardingAttempts, ForwardingJobs, IdempotencyRecords, Inspections, MediaFiles |
| نوشتن SQL | AuditLogs, ForwardingAttempts, ForwardingJobs, IdempotencyRecords, InspectionStatusHistory, Inspections |
| خواندن فایل | فایل/مشتق خصوصی همان نسخه با مجوز؛ فقط در صورت نیاز و بدون بارگذاری گروهی بایت‌ها. |
| ساخت/تغییر فایل | خواندن/stream نسخه‌های snapshot approved به مقصد whitelist؛ نه کپی Base64 و نه حذف اصل. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات ForwardingJobs,ForwardingAttempts,Inspections,InspectionStatusHistory,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | tenant از نصب و نشست معتبر؛ اتصال subject/sourceRequest/inspection و برای Reviewer ارجاع فعال. کارگر سرور یا مدیر دارای مجوز عملیاتی؛ مشتری فقط projection امن |
| تصمیم باز | D11, D12 |

### G04 — بازیابی عملیاتی ارسال به کارگزاری

| موضوع | اثر |
|---|---|
| روش و مسیر | POST /api/admin/forwarding-jobs/{jobId}/retry |
| خواندن SQL | ForwardingAttempts, ForwardingJobs, IdempotencyRecords |
| نوشتن SQL | AuditLogs, ForwardingJobs, IdempotencyRecords |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات ForwardingJobs,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار امن | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D11, D12 |

### G05 — نمایش وضعیت تحویل

| موضوع | اثر |
|---|---|
| روش و مسیر | GET /api/inspections/{inspectionId}/status |
| خواندن SQL | ForwardingJobs |
| نوشتن SQL | ندارد |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| ساخت/تغییر فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| وضعیت | خواندن بدون تغییر چرخه عمر |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تکرار امن | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| مجوز | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| تصمیم باز | D11, D12 |
