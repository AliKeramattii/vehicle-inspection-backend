# عملیات کارشناس و پرونده ارجاع‌شده

مرجع فعلی `src/features/review-operations/repository.ts` و model همان feature است؛ محیط مرورگر mock است. کنترل Backend باید مستقل از مخفی‌بودن دکمه یا guard React باشد.

| عمل | قرارداد پیشنهادی و داده | مجوز/ذخیره/اثر |
|---|---|---|
| صف و فیلتر | I04؛ cursor/status/tracking و بازگشت scope/count | Reviewer فقط assigned، Admin با اختیار جست‌وجو؛ Inspections/ReviewerAssignments |
| جزئیات | RV01؛ caseId → Case/Summary/current revisions | ارجاع جاری؛ Admin فقط projection خواندن مجاز، بدون اختیار تصمیم |
| تصویر/ویدیو | EV05؛ ID، revision، variant و Range | هر درخواست مجوز جدا، MediaFiles خصوصی؛ بدون autoplay یا path |
| تصمیم مدرک | RV04؛ evidenceId+revision، approved/rejected، reason و version | فقط کارشناس همان ارجاع؛ EvidenceReviews؛ رد دلیل عمومی لازم دارد |
| درخواست فیلد | RV05؛ field محدود و دلیل | CorrectionItems؛ فقط همان فیلد برای مالک باز می‌شود |
| تأیید پیشنهاد | RV06؛ task/proposalVersion و CAS | proposal معتبر؛ snapshot اصلی عوض نمی‌شود؛ سیاست reopen هنوز باز است |
| یادداشت | RV07؛ text محدود و CAS | InternalNotes خصوصی؛ هیچ DTO مشتری آن را حمل نکند |
| تصمیم کل | RV08؛ تصمیم جداگانه و دلیل رد | InspectionReviews؛ approved نیاز به همه نسخه‌ها/فیلدهای پذیرفته‌شده دارد |
| تاریخچه | RV09؛ cursor و scope | نسخه/ارجاع/عامل/زمان؛ دسترسی رسانه قبلی نیز دوباره مجوز می‌خواهد |

## جزئیات تراکنش تصمیم

نشست، نقش، ارجاع فعال و rowversion در همان تراکنش بررسی شوند؛ revoke/reassignment هم‌زمان نباید اجازه commit تصمیم کارشناس قبلی بدهد. payload فقط requirementId کافی نیست: evidenceId و revision/current مورد انتظار نیز لازم‌اند. کلید ثابت فرمان replay را به همان تصمیم می‌رساند؛ تصمیم متعارض یا نسخه کهنه ۴۰۹ است. UI باید نسخه تازه را بخواند و تأیید دوباره بگیرد، نه اینکه بی‌صدا روی داده جدید تصمیم قبلی را تکرار کند.

رد یک مدرک، whole rejection نیست. درخواست دقیق به originalEvidenceId/revision و template/requestVersion متصل است؛ اصل قابل مقایسه باقی می‌ماند. VIN همچنان یک مدرک با alternative واقعی است. ویدیو در همان خانواده evidence و review قرار دارد؛ فرم کیفیت دستی مشتری ساخته نمی‌شود.

تأیید همه فایل‌ها نیز خودکار تأیید کل نیست. RV08 باید کامل‌بودن نسخه‌های جاری هدف، تصمیم approved هر مدرک لازم و بسته‌بودن فیلدهای خواسته‌شده را دوباره بررسی کند. پس از approved، outbox نسخه دقیق ساخته می‌شود و وضعیت هنوز تحویل موفق نیست. رد کل با دلیل برای مشتری نمایش داده و شروع تازه تنها با فرمان مالک انجام می‌شود.

Admin نقش مدیریت ارجاع دارد، نه جایگزین Reviewer برای تصمیم. دسترسی Admin به notes یا تاریخچه حساس نیاز به مجوز روشن دارد؛ در نبود آن، response بدون notes باشد. جابه‌جایی/zoom/مقایسه تصویری در UI عملیات محلی است و API جدا لازم ندارد. رسانه قبلی مفقود باید unavailable واقعی نشان داده شود، نه تصویر نمونه به جای مدرک مشتری.
