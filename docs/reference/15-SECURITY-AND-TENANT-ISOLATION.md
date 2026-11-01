# امنیت، مالکیت و جداسازی کارگزاری

این فصل معیار پذیرش Backend است؛ guard و mock مرورگر، مرز امنیت تولید نیستند. پایگاه، media root، secret و deployment هر کارگزاری مستقل است. انتخاب connection/root از host و نصب trusted انجام شود؛ `tenantId`، sourceRequestId یا ID در body/query مجوز انتخاب پایگاه دیگر نمی‌دهد.

## ماتریس اختیار

| منبع | مشتری | کارشناس | مدیر سایت |
|---|---|---|---|
| بازدید/فایل | فقط مالک subject+sourceRequest+inspection | فقط پرونده دارای ارجاع فعال و مجوز خواندن | فقط خواندن عملیاتی مصوب |
| ثبت/تعویض پیش از submit | مالک در حالت قابل ویرایش | ندارد | ندارد |
| اصلاح پس از submit | فقط قلم/فیلد درخواست فعال با نسخه دقیق | ایجاد/بررسی task در ارجاع مجاز | بدون unlock عمومی |
| تصمیم مدرک/کل | ندارد | نقش Reviewer و ارجاع در لحظه تراکنش | مدیریت ارجاع، نه حق تصمیم خودکار |
| یادداشت خصوصی | هرگز | کارکنان مجاز همان پرونده | فقط در صورت مجوز روشن؛ در نبود آن حذف از projection |
| تنظیمات عمومی | whitelist منتشرشده | خواندن لازم | draft/publish طبق مجوز |
| کلید خصوصی Neshan/SSO/مقصد | هرگز | هرگز | مدیر معمول کارگزاری حق دریافت/ویرایش ندارد |
| retry تحویل | مشاهده وضعیت امن | مشاهده مجاز | فرمان بازیابی محدود همان job، با audit |

## کنترل‌های الزامی

- احراز هویت و authorization هر درخواست، از جمله Range، thumbnail، history، complete و URL منقضی‌شونده، مستقل از UI باشد. قبل از lookup حساس، scope معتبر حل شود؛ ۴۰۴ امن نباید وجود مدرک tenant دیگر را افشا کند.
- schema/نوع/اندازه/سقف صفحه/فیلتر/حروف/تاریخ/نسخه و enum‌ها سمت سرور کنترل شوند؛ query‌ها پارامتری و mass assignment مسدود باشد. Client timestamp و actorId جای زمان و هویت سرور نیستند.
- cookie HttpOnly/Secure، آدرس callback و return allowlist، CSRF برای mutation و CORS دقیق ضروری‌اند. `AllowAnyOrigin` با credentials یا اعتماد به تمام subdomain‌های کنترل‌نشده مجاز نیست. سیاست SameSite و gateway در فصل ۱۰ آمده است.
- rate limit روی مبدأ، OTP/referral، خواندن عمومی، انتقال/بایت، complete، تصمیم و retry اعمال شود؛ quota کلی نصب/مشتری و backpressure worker جدا از سقف هر فایل است. پاسخ ۴۲۹ راهنمای معتبر retry داشته باشد.
- کلیدهای private در secret store یا تنظیمات سرور با rotation باشند؛ نه `NEXT_PUBLIC_*`، public SiteSettings، SQL JSON معمولی، trace یا screenshot. source service credential هرگز به browser داده نشود.
- input/output logging محدود و redacted باشد: token، cookie، شماره کامل، ticket، URL خصوصی/signed، connection string، root و رسانه وارد log نشوند. traceId و resource ID مجاز برای پشتیبانی کافی‌اند.
- immutable audit شامل عامل معتبر، scope، فرمان، نسخه، زمان و نتیجه باشد. تغییر نقش، ارجاع، decision، publication، cleanup و forwarding ثبت شوند؛ یادداشت کارکنان به خروجی مشتری نرود.
- cookie/SSO ابطال‌شده و نقش/reassignment تازه باید درخواست بعدی را متوقف کند. local IndexedDB در دستگاه خود مشتری تهدید فیزیکی جدا دارد؛ policy قفل/نگهداری/encryption باید تصویب شود و با حذف بی‌اجازه evidence حل نشود.

## رسانه و backup

private root خارج از public است؛ path traversal، encoded traversal، UNC، symlink/reparse، filename collision و content-type spoofing آزموده شوند. فایل active هیچ execute permission ندارد. public BrandingAssets تنها پس از sanitization/بررسی slot مجاز است و دسترسی به شواهد را باز نمی‌کند.

SQL/file backup باید restore سازگار با manifest داشته باشد. retention/hold/deletion به تصمیم قانونی نیاز دارد. clone محیط production برای آزمون بدون ناشناس‌سازی مجاز فرض نشود؛ مثال‌های این بسته ساختگی‌اند. پاک‌شدن Blob محلی پس از upload یا حذف server originals بدون lifecycle مصوب ممنوع است.

Neshan به صورت مرکزی اداره می‌شود. public web key فقط در دامنه‌های مجاز frontend قابل نمایش است؛ private reverse key فقط در مرز سروری مجاز می‌ماند. tenant-admin store جدیدی برای map key یا provider ساخته نشود. API هایی که resource خصوصی می‌دهند زیر static fallback/cache عمومی قرار نگیرند.
