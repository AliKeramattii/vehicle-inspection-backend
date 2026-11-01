# نقش‌ها، مجوزها و دامنه دسترسی

این ماتریس بازتاب الزامات موجود و پیشنهاد enforce در Backend است. نقش و permission باید از نشست معتبر همان نصب صادر شوند؛ query، body، localStorage و انتخابگر mock منشأ اختیار نیستند.

| عامل | خواندن | تغییر مجاز | ممنوعیت مهم |
|---|---|---|---|
| مشتری مالک | تلاش‌های همان subject/sourceRequest، رسید، دلایل عمومی و مدرک خود | حقایق و ثبت قبل submit؛ بعد submit فقط اقلام درخواست فعال | درخواست/پرونده دیگر، شماره مبدأ، یادداشت خصوصی، تصمیم کارشناس |
| `viewer` | قالب‌های مجاز | ندارد | مدیریت، تصمیم، فایل خصوصی بدون مجوز مستقل |
| `template-editor` | قالب‌ها و نسخه‌ها | پیش‌نویس با `templates:edit` و مجوز فعلی editDraft | انتشار، SSO، نقش‌ها، مدارک مشتری و تغییر قالب تاریخی |
| `platform-admin` | قالب، تنظیمات، عملیات و پرونده در محدوده مجاز | انتشار، برند، کارکنان، ظرفیت، ارجاع و بازیابی تحویل با مجوز جدا | تصمیم کارشناس صرفاً به دلیل admin بودن، کلید خصوصی نشان، دورزدن قفل نهایی |
| `reviewer` | پرونده ارجاع فعال و نسخه‌های مجاز | `evidence:decide` و `inspection:decide`، دلیل اصلاح و یادداشت خصوصی | پرونده ارجاع‌نشده، تغییر هویت، ارسال مستقیم مقصد، تصمیم روی revision کهنه |
| سرویس مبدأ | رابطه trusted مشتری/درخواست/خودرو و تحویل توافق‌شده | صدور زمینه معتبر و تأیید دریافت مقصد | واگذاری اعتماد به نقش یا شماره دلخواه مرورگر |
| کارگر سرور | job دارای lease و snapshot دقیق | پردازش/اعلان/forwarding با کمترین اختیار | تغییر تصمیم Reviewer، مسیر یا مقصد دلخواه، ادعای ack بدون رسید |

مجوزهای فعلی کارکنان: `templates:read`، `templates:edit`، `settings:write`، `staff:manage`، `inspections:read`، `inspections:assign`، `evidence:decide` و `inspection:decide`. نگاشت publish/branding/policies/webhooks/users در UI موجود نیز باید با policy سمت سرور همسو شود؛ صرف داشتن templates:edit به معنی publish نیست.

## نگاشت نشست و DTO

`Session.kind=staff` با state=authenticated باید tenantId، subjectId، role، permissions، authority=backend-session و expiresAt داشته باشد. آداپتور به AuthenticatedStaffSession فعلی نگاشت می‌کند؛ cookie/token خصوصی در این DTO قرار نمی‌گیرد. برای customer، source همان زمینه trusted شامل tenantId، subjectId، sourceRequestId و mobile فقط‌خواندنی است. نقش کارکنان از customer context ساخته نشود.

در هر فرمان: ابتدا نشست و نصب، سپس مالکیت درخواست یا permission، سپس ارجاع/قفل/نسخه و قواعد کسب‌وکار بررسی شود. کنترل هنگام خواندن کافی نیست؛ revoke/reassign میان بازکردن صفحه و تصمیم باید در تراکنش دوباره enforce شود. پاسخ نامرئی ۴۰۴ یا ۴۰۳ طبق سیاست مصوب، بدون افشای وجود پرونده دیگر، برگردد.

یادداشت داخلی در CustomerStatus، receipt، notification یا forwarding عمومی نیاید. حق خواندن یادداشت توسط Admin هنوز تصمیم D10 است؛ حذف از projection پیش‌فرض لازم است. خروج و انقضا درخواست بعدی را نامعتبر می‌کنند، ولی بهانه پاک‌کردن خودکار مدرک خوب IndexedDB نیستند. سیاست دستگاه مشترک در D14 تصویب شود.
