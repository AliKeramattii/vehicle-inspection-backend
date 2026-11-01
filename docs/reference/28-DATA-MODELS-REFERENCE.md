# مرجع نگاشت مدل‌های موجود به قرارداد پیشنهادی

این سند قرارداد transport را از domain مرورگر جدا می‌کند. تمامی schema ها و مثال‌های کامل در قرارداد API به صورت متن درج شده‌اند؛ JSON ماشینی همان منبع تولید است. تغییر نام DTO نیازمند تصویب OpenAPI است، نه تغییر خودکار UI.

| مدل موجود | قرارداد پیشنهادی | نگاشت و قاعده |
|---|---|---|
| CustomerSourceContext | SourceContext داخل Session مشتری | issuer/subject/request trusted و mobile فقط‌خواندنی؛ authority=brokerage-session |
| AuthenticatedStaffSession | Session کارکنان | kind حذف و state/tenantId/subjectId/role/permissions/authority/expiresAt به adapter داده شوند |
| Inspection | Inspection | inspectionId به id دامنه؛ location/vehicle تأییدشده، tracking جدا؛ namespace محلی شناسه سرور نیست |
| PhotographyTemplate | CapturePlan | metadata کامل راهنما/section/choice؛ totalRequired و shots از adapter مشتق شوند |
| LocalPhoto / accepted video | Evidence + MediaFiles | Blob/key محلی فقط دستگاه؛ evidenceId و revision سروری مستقل ودارای receipt |
| UploadJob | Evidence/UploadTicket | id محلی ثابت، remoteEvidenceId، upload و verification جدا؛ MIME/size واقعی، بدون Blob در JSON |
| InspectionSummary | Summary | شمارها/آمادگی مشتق و authoritative؛ adapter شواهد را از EvidencePage و template همان نسخه می‌گیرد |
| SubmissionReceipt | Receipt | reference و submittedAt ثابت؛ status queued-for-review با status چرخه SUBMITTED یکی projection است، نه enum رقیب |
| CustomerInspectionStatus | Status | tenant/subject/mobile از نشست scoped؛ corrections و forwarding امن؛ source=backend در adapter |
| ReviewCase | Case | caseId به id، inspection به summary، reference/template/decisions/fieldCorrections حفظ؛ evidence به jobsmetadata و history نگاشت شود |
| ReviewWorkspace | InspectionPage + ReviewerPolicy + Case | list/cursor/آمار واقعی و reviewers از staff؛ نسخه case و workspace جدا |
| AdminWorkspace | AdminWorkspace | AdminTemplate/TemplateVersion، audit، staff→users، webhooks و assignmentPolicy؛ legacy branding به همان publicsettings نگاشت شود |
| IranianPlate | Plate | چهار segment جدا؛ LTR منطقی و numASCII؛ رشته نمایشی کل پلاک مرجع دامنه نیست |
| OdometerReading | Odometer | integer کیلومتر، صفر معتبر، بدون text فارسی در DB؛ evidenceVersion اختیاری همان عکس |
| VehicleCorrectionValue | FieldProposal | union به تفکیک plate/color/modelYear؛ expectedVersion فقط metadata فرمان، از value دامنه حذف شود |

## قواعدی که schema به تنهایی کافی نیست

شناسه مدرک باید عضو قالب pinned وهمان پرونده باشد؛ alternative باید به همان requirement تعلق داشته باشد. spec-plate نسخه ۲ فقط یک مدرک ویکی از pillar/engine/seat/windshield دارد؛ انتخاب راهنما هویت accepted قبلی را عوض نمی‌کند. engine-bay همچنان جدا لازم است. local/queued/uploading/failed ناقص‌اند؛ upload=uploaded با verification=processing receipt باینری دارد ولی approved نیست.

نسخه‌ای که کاربر قصد ارسال آن را تأیید کرده باید همان receipt و snapshot را داشته باشد. current قدیمی، candidate جدید و original پذیرفته‌شده سه ارجاع مستقل‌اند؛ امکان نگهداشت اعتبار completion هنگام draft replacement به معنی مجازبودن submit نسخه نامشخص نیست. درخواست کارشناس دقیقاً item/requestVersion را محدود می‌کند؛ full rejection تلاش جدید می‌خواهد، نه reset تاریخچه.

شماره نسخه opaque یا base64 rowversion برای CAS است و به زمان قابل تفسیر تبدیل نمی‌شود. IDs در API opaque باقی می‌مانند؛ cast آزاد رشته به GUID یا استفاده از localBlobKey به عنوان path مجاز نیست. normalizer ارقام فارسی/عربی و separators فقط ورودی UI است؛ سرور integer و safe range را دوباره بررسی می‌کند.

## نگاشت حقایق و وضعیت بنیادی

`Vehicle.modelYear/color/bodyColor/maskedVin` در قرارداد به `year/colorName/colorHex/vinMasked` در domain فعلی نگاشت می‌شوند. bodyColor اختیاری است؛ نبود hex نباید به مقدار ساختگی ذخیره‌شده تبدیل شود. SQL، نام رنگ و hex را جدا نگه می‌دارد. حرف پلاک دقیقاً از enum موجود است، ازجمله «الف» سه‌حرفی؛ ستون nvarchar(3) آن را بدون برش ذخیره می‌کند.

accuracyMeters در domain موقعیت nullable است؛ انتخاب دستی بدون GPS مقدار NULL دارد، نه دقت صفر جعلی. buildingNumber، unitFloor و parkingDescription اختیاری‌اند. selectionSource و recordedAt ادعای مرورگرند؛ زمان تأیید سرور جداست. فقط lat/lng معتبر و formattedAddress برایخلاصه کافی‌اند؛ اجازه GPS مجدد برایبازخوانی لازم نیست.

enum بنیادی Inspection.status فعلی شامل draft/capturing/uploading/readyToSubmit/queuedForReview/underReview/additionalEvidenceRequired/approved/rejected است. وضعیت lifecycle بالادستیِ موجود جداست و منبع نمایش پیگیری/forwarding می‌ماند. Backend پیشنهادی از همان enum بالادستی DRAFT…FORWARDED استفاده می‌کند؛ آداپتور باید projection بنیادی را جدا نگاشت کند. هیچ enum قدیمی approved یا state upload بهتنهایی گواه FORWARDED نیست. نگاشت نهایی در OpenAPI/adapters تأیید و با status fixture تست شود، نهبا cast خودکار حروف کوچک/بزرگ.
