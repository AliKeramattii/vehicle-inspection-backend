# روابط، مالکیت و حدود تراکنش

وضعیت: **پیشنهادی و نیازمند تصویب Backend**. تاریخ بررسی منابع: 2026-10-27. این اسناد هیچ سرویس تولیدی یا migration اجراشده‌ای را اثبات نمی‌کنند.

[نمودار کامل](sql/DATABASE_DIAGRAM.md) و [SQL پیشنهادی](sql/PROPOSED_SCHEMA.sql) مرجع مشترک‌اند. هر رابطه زیر به کلید اصلی/unique واقعی اشاره دارد؛ FK‌های چرخه‌ای پس از ساخت جدول‌ها اضافه شده‌اند.

| فرزند | ستون‌ها | والد | ستون مرجع |
|---|---|---|---|
| SourceInsuranceRequests | CustomerId | Customers | Id |
| EvidenceRequirements | TemplateId | InspectionTemplates | Id |
| RequirementAlternatives | RequirementId | EvidenceRequirements | Id |
| Inspections | SourceRequestId | SourceInsuranceRequests | Id |
| Inspections | TemplateId | InspectionTemplates | Id |
| Inspections | PreviousInspectionId, SourceRequestId | Inspections | Id, SourceRequestId |
| Vehicles | InspectionId | Inspections | Id |
| InspectionLocations | InspectionId | Inspections | Id |
| InspectionConsents | InspectionId | Inspections | Id |
| OdometerReadings | InspectionId | Inspections | Id |
| OdometerReadings | EvidenceVersionId, InspectionId | EvidenceVersions | Id, InspectionId |
| InspectionEvidence | InspectionId, TemplateId | Inspections | Id, TemplateId |
| InspectionEvidence | RequirementId, TemplateId | EvidenceRequirements | Id, TemplateId |
| InspectionEvidence | CurrentVersionId, Id | EvidenceVersions | Id, EvidenceId |
| InspectionEvidence | PendingVersionId, Id | EvidenceVersions | Id, EvidenceId |
| EvidenceVersions | EvidenceId, InspectionId | InspectionEvidence | Id, InspectionId |
| EvidenceVersions | EvidenceId, RequirementId | InspectionEvidence | Id, RequirementId |
| EvidenceVersions | RequirementId, HasChoice | EvidenceRequirements | Id, HasChoice |
| EvidenceVersions | AlternativeId, RequirementId | RequirementAlternatives | Id, RequirementId |
| EvidenceVersions | ReplacesVersionId, EvidenceId | EvidenceVersions | Id, EvidenceId |
| MediaFiles | EvidenceVersionId | EvidenceVersions | Id |
| MediaFiles | DerivedFromFileId, EvidenceVersionId | MediaFiles | Id, EvidenceVersionId |
| UploadSessions | MediaFileId | MediaFiles | Id |
| MediaProcessingJobs | MediaFileId | MediaFiles | Id |
| StaffRoleAssignments | StaffId | StaffUsers | Id |
| ReviewerAssignments | InspectionId | Inspections | Id |
| ReviewerAssignments | ReviewerId | StaffUsers | Id |
| ReviewerAssignments | AssignedBy | StaffUsers | Id |
| InspectionSubmissions | InspectionId | Inspections | Id |
| InspectionSubmissions | CorrectionRequestId, InspectionId | CorrectionRequests | Id, InspectionId |
| SubmissionEvidence | SubmissionId, InspectionId | InspectionSubmissions | Id, InspectionId |
| SubmissionEvidence | EvidenceId, InspectionId | InspectionEvidence | Id, InspectionId |
| SubmissionEvidence | EvidenceVersionId, EvidenceId | EvidenceVersions | Id, EvidenceId |
| EvidenceReviews | EvidenceVersionId, InspectionId | EvidenceVersions | Id, InspectionId |
| EvidenceReviews | AssignmentId, InspectionId | ReviewerAssignments | Id, InspectionId |
| InspectionReviews | AssignmentId, InspectionId | ReviewerAssignments | Id, InspectionId |
| InspectionReviews | SubmissionId, InspectionId | InspectionSubmissions | Id, InspectionId |
| CorrectionRequests | OriginalSubmissionId, InspectionId | InspectionSubmissions | Id, InspectionId |
| CorrectionRequests | RequestedByAssignmentId, InspectionId | ReviewerAssignments | Id, InspectionId |
| CorrectionItems | RequestId, InspectionId | CorrectionRequests | Id, InspectionId |
| CorrectionItems | EvidenceId, InspectionId | InspectionEvidence | Id, InspectionId |
| CorrectionItems | OriginalVersionId, EvidenceId | EvidenceVersions | Id, EvidenceId |
| CorrectionItems | CandidateVersionId, EvidenceId | EvidenceVersions | Id, EvidenceId |
| InternalNotes | AssignmentId, InspectionId | ReviewerAssignments | Id, InspectionId |
| InspectionStatusHistory | InspectionId | Inspections | Id |
| ForwardingJobs | InspectionReviewId, InspectionId, SubmissionId | InspectionReviews | Id, InspectionId, SubmissionId |
| ForwardingJobs | SubmissionId, InspectionId | InspectionSubmissions | Id, InspectionId |
| ForwardingAttempts | JobId | ForwardingJobs | Id |
| SiteSettingsVersions | CreatedBy | StaffUsers | Id |
| SiteSettings | PublishedVersionId | SiteSettingsVersions | Id |
| SiteSettings | DraftVersionId | SiteSettingsVersions | Id |
| SiteSettingsAssetLinks | SettingsVersionId | SiteSettingsVersions | Id |
| SiteSettingsAssetLinks | BrandingAssetId | BrandingAssets | Id |
| AuditLogs | InspectionId | Inspections | Id |
| NotificationOutbox | InspectionId | Inspections | Id |

## قواعد فراتر از FK

یک مشتری چند SourceInsuranceRequests و هر درخواست چند تلاش دارد؛ فقط IsCurrent یکی است. هر تلاش قالب immutable خود را پین می‌کند. نسخه مدرک باید همان EvidenceId، InspectionId، RequirementId و alternative همان گروه را داشته باشد. CurrentVersionId/PendingVersionId با FK ترکیبی به همان جایگاه محدودند. SubmissionEvidence نسخه‌های دقیق را ثابت نگه می‌دارد؛ تغییر current، گذشته را بازنویسی نمی‌کند.

ForwardingJobs به همان InspectionReview، InspectionId و SubmissionId مرتبط می‌شود. سرویس باید approved بودن تصمیم و کامل بودن همه نسخه‌ها را نیز چک کند. SQL CHECK به تنهایی نمی‌تواند join به جدول دیگر، مجوز نشست، محتوای فایل یا تضمین تحویل خارجی را enforce کند.

## مرز تراکنش

ایجاد تلاش: قفل ردیف درخواست/تلاش جاری، idempotency، تخصیص شماره تلاش و pin قالب در یک تراکنش. تصمیم کارشناس: بررسی ارجاع و rowversion، ثبت تصمیم و درخواست دقیق/audit در یک تراکنش. تأیید کل: snapshot ثابت، تصمیم و outbox در یک تراکنش. تحویل خارجی خارج از آن تراکنش با lease و ack پایدار. نوشتن فایل و SQL اتمیک مشترک نیست؛ reconciliation فصل ۸ الزامی است.
