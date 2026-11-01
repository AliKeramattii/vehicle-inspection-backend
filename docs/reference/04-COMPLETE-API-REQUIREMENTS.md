# فهرست کامل عملیات موردنیاز Backend

وضعیت: **پیشنهادی و نیازمند تصویب Backend**. تاریخ بررسی منابع: 2026-10-27. این اسناد هیچ سرویس تولیدی یا migration اجراشده‌ای را اثبات نمی‌کنند.

این فصل هر ۶۳ شناسه کاتالوگ فعلی را یک‌بار پوشش می‌دهد. F05 همان A02، F09 سازگارکننده F06/F07، G05 نمایش D04/E01 و D03 بازیابی همان فرمان D02 است. A01 فایل عمومی است. G01 تا G03 رویداد/کارگر سرورند. عملیات محلی دوربین، انتخاب راهنما و ذخیره Blob endpoint نیستند.

مرجع قابل ویرایش این فصل [operations.json](contracts/operations.json) است؛ خروجی با `node tools/generate-api-handoff.mjs` بازتولید و با `--check` کنترل می‌شود. [قراردادها](05-API-CONTRACTS.md)، [چرخه عمر](11-INSPECTION-LIFECYCLE.md) و [اولویت‌ها](18-IMPLEMENTATION-PRIORITIES.md) مکمل‌اند.

## پیکربندی و هویت

### A01 — بارگذاری هویت نصب و نشانی‌های عمومی

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_FRONTEND_IMPLEMENTATION / CURRENT_FRONTEND_IMPLEMENTATION |
| هدف | بارگذاری هویت نصب و نشانی‌های عمومی |
| صفحه وابسته | شروع برنامه |
| عامل | خواننده عمومی تنظیمات همین نصب |
| ورودی | origin مورد اعتماد |
| خروجی | SiteBootstrap معتبر، نه هویت کاربر |
| اعتبارسنجی | ساختار SiteBootstrap، origin مجاز و URL عمومی معتبر؛ فایل هیچ کلید خصوصی، session یا هویت مشتری ندارد. |
| مجوز و tenant | بدون نشست؛ فقط داده عمومی مجاز نصب |
| اثر ذخیره‌سازی | داده استقرار/هویت بیرونی یا سرویس مرکزی؛ فایل رسانه/جدول کسب‌وکار ایجاد نمی‌شود |
| اثر وضعیت | خواندن بدون تغییر چرخه عمر |
| خطا | 404 پیکربندی/فایل یافت نشد؛ 503 پیکربندی یا میزبان در دسترس نیست؛ داده خصوصی یا fallback موفق جعلی منتشر نشود. |
| تکرار و retry | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| پیاده‌سازی فعلی | A01 فایل عمومی واقعی؛ A02/F05 بارگذار واقعی و انتشار محلی؛ B11 مرز توسعه زنده مجاز. این مورد تضمین Backend تولید نیست |
| مرز منبع | src/config/site-settings.loader.ts |
| پیشنهاد Backend | برای A01 فایل عمومی استقرار موجود کافی است؛ A02/F05 فقط یک projection عمومی از نسخه منتشرشده همان provider تنظیمات می‌خواهند، بدون نشست/SQL تجاری اضافه. |
| وابستگی | توافق هویت/نصب و قرارداد عمومی |
| قرارداد مرتبط | P00 |
| خواندن SQL | بدون جدول برنامه |
| نوشتن SQL | بدون تغییر SQL برنامه |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تصمیم باز | D01, D02 |

### A02 — خواندن تنظیمات منتشرشده

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_FRONTEND_IMPLEMENTATION / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | خواندن تنظیمات منتشرشده |
| صفحه وابسته | همه صفحه‌ها |
| عامل | خواننده عمومی تنظیمات همین نصب |
| ورودی | نصب و نسخه انتشار |
| خروجی | SiteSettings عمومی بدون راز |
| اعتبارسنجی | schemaVersion و tenant نصب و نسخه انتشار معتبر؛ projection فقط عمومی است و secret سرویس یا مسیر خصوصی ندارد. |
| مجوز و tenant | بدون نشست؛ فقط داده عمومی مجاز نصب |
| اثر ذخیره‌سازی | BrandingAssets، SiteSettings، SiteSettingsAssetLinks، SiteSettingsVersions |
| اثر وضعیت | خواندن بدون تغییر چرخه عمر |
| خطا | 404 پیکربندی/فایل یافت نشد؛ 503 پیکربندی یا میزبان در دسترس نیست؛ داده خصوصی یا fallback موفق جعلی منتشر نشود. |
| تکرار و retry | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| پیاده‌سازی فعلی | A01 فایل عمومی واقعی؛ A02/F05 بارگذار واقعی و انتشار محلی؛ B11 مرز توسعه زنده مجاز. این مورد تضمین Backend تولید نیست |
| مرز منبع | src/config/site-settings.loader.ts |
| پیشنهاد Backend | برای A01 فایل عمومی استقرار موجود کافی است؛ A02/F05 فقط یک projection عمومی از نسخه منتشرشده همان provider تنظیمات می‌خواهند، بدون نشست/SQL تجاری اضافه. |
| وابستگی | توافق هویت/نصب و قرارداد عمومی |
| قرارداد مرتبط | P01 |
| خواندن SQL | BrandingAssets، SiteSettings، SiteSettingsAssetLinks، SiteSettingsVersions |
| نوشتن SQL | بدون تغییر SQL برنامه |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تصمیم باز | D01, D02 |

### A03 — تحویل هویت مشتری از سامانه بیمه

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | تحویل هویت مشتری از سامانه بیمه |
| صفحه وابسته | ورود از کارگزاری |
| عامل | source |
| ورودی | ticket یک‌بارمصرف و state |
| خروجی | CustomerSourceContext با شماره فقط‌خواندنی |
| اعتبارسنجی | issuer، audience، expiry، state/nonce و اتصال subject به sourceRequest؛ مصرف اتمیک بلیت یک‌بارمصرف و رد replay. |
| مجوز و tenant | بلیت معتبر مبدأ و ضد replay؛ روش نهایی نیازمند تصویب |
| اثر ذخیره‌سازی | AuditLogs، Customers، IdempotencyRecords، SourceInsuranceRequests |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/features/identity/source-context.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/identity/source-context.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | توافق هویت/نصب و قرارداد عمومی |
| قرارداد مرتبط | AU01 |
| خواندن SQL | Customers، IdempotencyRecords، SourceInsuranceRequests |
| نوشتن SQL | AuditLogs، Customers، IdempotencyRecords، SourceInsuranceRequests |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات Customers,SourceInsuranceRequests,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D01, D02 |

### A04 — ورود سازمانی کارکنان

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | ورود سازمانی کارکنان |
| صفحه وابسته | ورود مدیریت و کارشناسی |
| عامل | staff-handoff |
| ورودی | ticket معتبر یا callback مورد توافق OIDC |
| خروجی | StaffSession شامل نقش و مجوزهای نصب |
| اعتبارسنجی | پروتکل SSO مصوب، issuer/audience/callback/PKCE یا بلیت محدود؛ نگاشت subject به نقش فعال از مرجع trusted. |
| مجوز و tenant | بلیت معتبر مبدأ و ضد replay؛ روش نهایی نیازمند تصویب |
| اثر ذخیره‌سازی | AuditLogs، IdempotencyRecords، StaffRoleAssignments، StaffUsers |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/features/identity/staff-session.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/identity/staff-session.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | توافق هویت/نصب و قرارداد عمومی |
| قرارداد مرتبط | AU02 |
| خواندن SQL | IdempotencyRecords، StaffRoleAssignments، StaffUsers |
| نوشتن SQL | AuditLogs، IdempotencyRecords، StaffRoleAssignments، StaffUsers |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات StaffUsers,StaffRoleAssignments,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D01, D02 |

### A05 — بررسی تداوم نشست

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | بررسی تداوم نشست |
| صفحه وابسته | بازگشت کاربر و حفاظت مسیرها |
| عامل | session |
| ورودی | نشست امن مرورگر |
| خروجی | نشست معتبر یا پاسخ انقضا |
| اعتبارسنجی | اعتبار نشست سرور، expiry/revocation و scope نصب؛ بازگردانی sessionStorage mock مدرک احراز هویت تولیدی نیست. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | Customers، SourceInsuranceRequests، StaffRoleAssignments، StaffUsers |
| اثر وضعیت | خواندن بدون تغییر چرخه عمر |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| پیاده‌سازی فعلی | مرز فعلی src/features/identity/source-context.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/identity/source-context.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | توافق هویت/نصب و قرارداد عمومی |
| قرارداد مرتبط | AU03 |
| خواندن SQL | Customers، SourceInsuranceRequests، StaffRoleAssignments، StaffUsers |
| نوشتن SQL | بدون تغییر SQL برنامه |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تصمیم باز | D01, D02 |

### A06 — خروج و ابطال نشست

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | خروج و ابطال نشست |
| صفحه وابسته | خروج مشتری یا کارکنان |
| عامل | session |
| ورودی | نشست جاری و حفاظت CSRF |
| خروجی | تأیید خروج و توقف دسترسی بعدی |
| اعتبارسنجی | نشست معتبر و ضد CSRF؛ ابطال سرور و cookie؛ logout سراسری مبدأ فقط طبق توافق. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | سرویس خروج/ابطال تولید وجود ندارد؛ قرارداد باید با تأمین‌کننده هویت توافق شود. |
| مرز منبع | src/features/identity/staff-session.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | توافق هویت/نصب و قرارداد عمومی |
| قرارداد مرتبط | AU04 |
| خواندن SQL | بدون جدول برنامه |
| نوشتن SQL | بدون تغییر SQL برنامه |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تصمیم باز | D01, D02 |

### A07 — اعتبارسنجی معرفی‌نامه

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | اعتبارسنجی معرفی‌نامه |
| صفحه وابسته | ورود مشتری |
| عامل | source |
| ورودی | code و زمینه معتبر درخواست بیمه |
| خروجی | اعتبار، شریک یا خطای معرفی‌نامه |
| اعتبارسنجی | معرفی‌نامه معتبر، انقضا و اتصال به درخواست و شماره trusted؛ پاسخ نباید شماره دیگران را افشا کند. |
| مجوز و tenant | بلیت معتبر مبدأ و ضد replay؛ روش نهایی نیازمند تصویب |
| اثر ذخیره‌سازی | Customers، SourceInsuranceRequests |
| اثر وضعیت | خواندن بدون تغییر چرخه عمر |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| پیاده‌سازی فعلی | مرز فعلی src/lib/api/repositories.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/lib/api/repositories.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | توافق هویت/نصب و قرارداد عمومی |
| قرارداد مرتبط | AU05 |
| خواندن SQL | Customers، SourceInsuranceRequests |
| نوشتن SQL | بدون تغییر SQL برنامه |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تصمیم باز | D01, D02 |

### A08 — صدور و ارسال دوباره چالش پیامکی

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | صدور و ارسال دوباره چالش پیامکی |
| صفحه وابسته | ورود و OTP |
| عامل | source |
| ورودی | زمینه هویت مبدأ و referralCode |
| خروجی | challengeId، انقضا، زمان ارسال دوباره و تعداد تلاش |
| اعتبارسنجی | همان شماره فقط‌خواندنی منبع، challenge/sourceRequest، cooldown و rate limit؛ هیچ شماره قابل‌ویرایش هویت نمی‌سازد. |
| مجوز و tenant | بلیت معتبر مبدأ و ضد replay؛ روش نهایی نیازمند تصویب |
| اثر ذخیره‌سازی | Customers، SourceInsuranceRequests |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/lib/api/repositories.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/lib/api/repositories.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | توافق هویت/نصب و قرارداد عمومی |
| قرارداد مرتبط | AU06 |
| خواندن SQL | Customers، SourceInsuranceRequests |
| نوشتن SQL | بدون تغییر SQL برنامه |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تصمیم باز | D01, D02 |

### A09 — تأیید چالش پیامکی

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | تأیید چالش پیامکی |
| صفحه وابسته | صفحه OTP |
| عامل | source |
| ورودی | challengeId و code در همان زمینه |
| خروجی | نشست محدود به درخواست و بازدید مجاز |
| اعتبارسنجی | challenge فعال، کد با طول مصوب، expiry و سقف تلاش؛ مصرف اتمیک؛ کد پنج‌رقمی mock قاعده تولیدی نیست. |
| مجوز و tenant | بلیت معتبر مبدأ و ضد replay؛ روش نهایی نیازمند تصویب |
| اثر ذخیره‌سازی | AuditLogs، Customers، IdempotencyRecords، SourceInsuranceRequests |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/lib/api/repositories.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/lib/api/repositories.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | توافق هویت/نصب و قرارداد عمومی |
| قرارداد مرتبط | AU07 |
| خواندن SQL | Customers، SourceInsuranceRequests |
| نوشتن SQL | بدون تغییر SQL برنامه |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تصمیم باز | D01, D02 |

## بازدید و حقایق

### B01 — ساخت اولین تلاش بازدید

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | ساخت اولین تلاش بازدید |
| صفحه وابسته | ورود مشتری جدید |
| عامل | customer |
| ورودی | sourceRequestId، کلید فرمان |
| خروجی | inspectionId، trackingCode و قالب پین‌شده |
| اعتبارسنجی | مالکیت درخواست مبدأ و قالب منتشرشده؛ عدم ایجاد current دوم؛ کلید ثابت و شماره attempt در تراکنش. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، IdempotencyRecords، InspectionTemplates، Inspections، SourceInsuranceRequests، Vehicles |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/features/inspection-status/lifecycle-repository.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/inspection-status/lifecycle-repository.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A03/A05؛ قالب منتشرشده و مالکیت درخواست |
| قرارداد مرتبط | I01 |
| خواندن SQL | IdempotencyRecords، InspectionTemplates، Inspections، SourceInsuranceRequests، Vehicles |
| نوشتن SQL | AuditLogs، IdempotencyRecords، Inspections، Vehicles |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات Inspections,Vehicles,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D04, D08 |

### B02 — خواندن بازدید مجاز

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | خواندن بازدید مجاز |
| صفحه وابسته | حفاظت مسیر و ادامه بازدید |
| عامل | owner-staff |
| ورودی | inspectionId |
| خروجی | حقایق و نسخه بازدید با projection مجاز |
| اعتبارسنجی | شناسه opaque و اتصال مالک یا اختیار کارکنان؛ نسخه قالب و حقایق همان تلاش، نه رکورد ساختگی جدید. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | InspectionLocations، Inspections، Vehicles |
| اثر وضعیت | خواندن بدون تغییر چرخه عمر |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| پیاده‌سازی فعلی | مرز فعلی src/lib/api/repositories.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/lib/api/repositories.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A03/A05؛ قالب منتشرشده و مالکیت درخواست |
| قرارداد مرتبط | I02 |
| خواندن SQL | InspectionLocations، Inspections، Vehicles |
| نوشتن SQL | بدون تغییر SQL برنامه |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تصمیم باز | D04, D08 |

### B03 — یافتن تلاش جاری همان درخواست

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | یافتن تلاش جاری همان درخواست |
| صفحه وابسته | مراجعه دوباره مشتری |
| عامل | customer |
| ورودی | زمینه نشست و sourceRequestId |
| خروجی | تلاش قبلی و مقصد امن؛ بدون ایجاد خودکار |
| اعتبارسنجی | sourceRequest متعلق به subject نشست؛ پاسخ nullable برای نبود current؛ GET اجازه ساخت تلاش ندارد. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | Inspections، SourceInsuranceRequests |
| اثر وضعیت | خواندن بدون تغییر چرخه عمر |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| پیاده‌سازی فعلی | مرز فعلی src/features/inspection-status/customer-entry.tsx؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/inspection-status/customer-entry.tsx |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A03/A05؛ قالب منتشرشده و مالکیت درخواست |
| قرارداد مرتبط | I03 |
| خواندن SQL | Inspections، SourceInsuranceRequests |
| نوشتن SQL | بدون تغییر SQL برنامه |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تصمیم باز | D04, D08 |

### B04 — پیگیری و جست‌وجوی مجاز

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | پیگیری و جست‌وجوی مجاز |
| صفحه وابسته | پیگیری مشتری و فهرست عملیات |
| عامل | owner-staff |
| ورودی | trackingCode یا فیلتر و cursor |
| خروجی | نتیجه محدود به مالک یا اختیار کارکنان |
| اعتبارسنجی | scope مشتری یا permission کارکنان، cursor و pageSize محدود؛ trackingCode به تنهایی مجوز نیست. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | Customers، Inspections، SourceInsuranceRequests |
| اثر وضعیت | خواندن بدون تغییر چرخه عمر |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| پیاده‌سازی فعلی | مرز فعلی src/features/review-operations/model.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/review-operations/model.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A03/A05؛ قالب منتشرشده و مالکیت درخواست |
| قرارداد مرتبط | I04 |
| خواندن SQL | Customers، Inspections، SourceInsuranceRequests |
| نوشتن SQL | بدون تغییر SQL برنامه |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تصمیم باز | D04, D08 |

### B05 — خواندن قالب ثابت بازدید

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | خواندن قالب ثابت بازدید |
| صفحه وابسته | عکاسی، راهنما و بازبینی |
| عامل | owner-staff |
| ورودی | inspectionId و نسخه پین‌شده |
| خروجی | هفت بخش، شناسه‌ها، انتخاب VIN و الزام‌های جداگانه |
| اعتبارسنجی | قالب immutable پین‌شده همین تلاش؛ requirementId‌های یکتا و گزینه‌های همان نسخه؛ نسخه قدیمی بازنویسی نشود. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | EvidenceRequirements، InspectionTemplates، RequirementAlternatives |
| اثر وضعیت | خواندن بدون تغییر چرخه عمر |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| پیاده‌سازی فعلی | مرز فعلی src/lib/api/repositories.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/lib/api/repositories.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A03/A05؛ قالب منتشرشده و مالکیت درخواست |
| قرارداد مرتبط | I05 |
| خواندن SQL | EvidenceRequirements، InspectionTemplates، RequirementAlternatives |
| نوشتن SQL | بدون تغییر SQL برنامه |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تصمیم باز | D04, D08 |

### B06 — ثبت پذیرش نسخه شرایط

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | ثبت پذیرش نسخه شرایط |
| صفحه وابسته | رضایت‌نامه |
| عامل | customer |
| ورودی | accepted=true و termsVersion |
| خروجی | رسید با زمان سرور |
| اعتبارسنجی | accepted=true، نسخه شرایط مجاز و عدم جعل زمان/هویت؛ رسید سرور و نسخه بازدید ثبت شود. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، IdempotencyRecords، InspectionConsents |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/lib/api/repositories.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/lib/api/repositories.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A03/A05؛ قالب منتشرشده و مالکیت درخواست |
| قرارداد مرتبط | I06 |
| خواندن SQL | IdempotencyRecords، InspectionConsents |
| نوشتن SQL | AuditLogs، IdempotencyRecords، InspectionConsents |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات InspectionConsents,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D04, D08 |

### B07 — ثبت محل تأییدشده

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | ثبت محل تأییدشده |
| صفحه وابسته | انتخاب موقعیت |
| عامل | customer |
| ورودی | مختصات، دقت، نشانی، پلاک ساختمان، واحد و توضیح پارک |
| خروجی | InspectionLocation و نسخه جدید |
| اعتبارسنجی | lat/lng محدود، accuracy غیرمنفی و رشته‌های محدود؛ نسخه و اجازه ویرایش؛ درخواست مجدد GPS لازم نیست. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، IdempotencyRecords، InspectionLocations، Inspections |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/lib/media/inspection-facts-store.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/lib/media/inspection-facts-store.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A03/A05؛ قالب منتشرشده و مالکیت درخواست |
| قرارداد مرتبط | I07 |
| خواندن SQL | IdempotencyRecords، InspectionLocations، Inspections |
| نوشتن SQL | AuditLogs، IdempotencyRecords، InspectionLocations، Inspections |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات InspectionLocations,Inspections,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D04, D08 |

### B08 — نمایش مشخصات خودرو

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | نمایش مشخصات خودرو |
| صفحه وابسته | تأیید خودرو و خلاصه |
| عامل | owner-staff |
| ورودی | inspectionId |
| خروجی | Vehicle، پلاک ساختاریافته، VIN پوشانده‌شده |
| اعتبارسنجی | snapshot خودرو همین بازدید؛ پلاک ساختاریافته، VIN با projection مناسب و مجوز خواندن. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | Vehicles |
| اثر وضعیت | خواندن بدون تغییر چرخه عمر |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| پیاده‌سازی فعلی | مرز فعلی src/lib/api/repositories.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/lib/api/repositories.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A03/A05؛ قالب منتشرشده و مالکیت درخواست |
| قرارداد مرتبط | I08 |
| خواندن SQL | Vehicles |
| نوشتن SQL | بدون تغییر SQL برنامه |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تصمیم باز | D04, D08 |

### B09 — تأیید خودرو یا اصلاح مجاز پلاک

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | تأیید خودرو یا اصلاح مجاز پلاک |
| صفحه وابسته | هویت خودرو |
| عامل | customer |
| ورودی | حقایق تأییدشده یا IranianPlate و expectedVersion |
| خروجی | رسید تأیید و حقایق معتبر |
| اعتبارسنجی | IranianPlate segment‌ها، حقایق مجاز و نسخه؛ پس از ارسال تغییر آزاد ممنوع و field correction باید scoped باشد. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، IdempotencyRecords، Inspections، Vehicles |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/lib/api/repositories.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/lib/api/repositories.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A03/A05؛ قالب منتشرشده و مالکیت درخواست |
| قرارداد مرتبط | I09، I10 |
| خواندن SQL | IdempotencyRecords، Inspections، Vehicles |
| نوشتن SQL | AuditLogs، IdempotencyRecords، Inspections، Vehicles |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات Vehicles,Inspections,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D04, D08 |

### B10 — ثبت و ویرایش کیلومتر عددی

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | ثبت و ویرایش کیلومتر عددی |
| صفحه وابسته | بازبینی عکس کیلومتر و خلاصه |
| عامل | customer |
| ورودی | kilometers صحیح، evidenceId اختیاری و نسخه |
| خروجی | OdometerReading عددی؛ نه فایل |
| اعتبارسنجی | kilometers صحیح و امن، صفر مجاز؛ evidenceId در صورت وجود به عکس کیلومتر همین بازدید؛ replacement عدد را خودکار پاک نکند. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، IdempotencyRecords، Inspections، OdometerReadings |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/lib/media/capture-data-store.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/lib/media/capture-data-store.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A03/A05؛ قالب منتشرشده و مالکیت درخواست |
| قرارداد مرتبط | I11، I12 |
| خواندن SQL | IdempotencyRecords، Inspections، OdometerReadings |
| نوشتن SQL | AuditLogs، IdempotencyRecords، Inspections، OdometerReadings |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات OdometerReadings,Inspections,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D04, D08 |

### B11 — دریافت نشانی فارسی مختصات

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_FRONTEND_IMPLEMENTATION / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | دریافت نشانی فارسی مختصات |
| صفحه وابسته | انتخاب موقعیت |
| عامل | customer |
| ورودی | lat و lng |
| خروجی | formatted_address یا خطای قابل بازیابی |
| اعتبارسنجی | مختصات محدود، مجوز و quota درخواست؛ کلید خصوصی Neshan فقط سرور مرکزی و پاسخ عمومی نشانی فارسی. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | داده استقرار/هویت بیرونی یا سرویس مرکزی؛ فایل رسانه/جدول کسب‌وکار ایجاد نمی‌شود |
| اثر وضعیت | خواندن بدون تغییر چرخه عمر |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| پیاده‌سازی فعلی | A01 فایل عمومی واقعی؛ A02/F05 بارگذار واقعی و انتشار محلی؛ B11 مرز توسعه زنده مجاز. این مورد تضمین Backend تولید نیست |
| مرز منبع | src/lib/map/reverse-geocoder.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A03/A05؛ قالب منتشرشده و مالکیت درخواست |
| قرارداد مرتبط | M01 |
| خواندن SQL | بدون جدول برنامه |
| نوشتن SQL | بدون تغییر SQL برنامه |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تصمیم باز | D04, D08 |

## مدرک و انتقال

### C01 — ثبت نسخه مدرک و قرارداد انتقال

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | ثبت نسخه مدرک و قرارداد انتقال |
| صفحه وابسته | مرکز ارسال عکس و ویدیو |
| عامل | customer |
| ورودی | kind، requirementId، alternativeId، revision و فراداده |
| خروجی | شناسه ثابت مدرک، نسخه و UploadTicket |
| اعتبارسنجی | kind و revision ثابت؛ requirement عضو قالب پین‌شده؛ spec-plate نسخه ۲ دقیقاً یک alternative معتبر؛ video فاقد photoId؛ فراداده نوع/اندازه و scope اصلاح. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، EvidenceVersions، IdempotencyRecords، InspectionEvidence، MediaFiles، UploadSessions |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/features/upload/upload-transport.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/upload/upload-transport.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A03/A05، B01/B05؛ سیاست نوع/اندازه و فضای خصوصی |
| قرارداد مرتبط | EV01 |
| خواندن SQL | EvidenceVersions، IdempotencyRecords، InspectionEvidence، MediaFiles، UploadSessions |
| نوشتن SQL | AuditLogs، EvidenceVersions، IdempotencyRecords، InspectionEvidence، MediaFiles، UploadSessions |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | رزرو مسیر نسخه در metadata؛ هنوز هیچ بایتی از مرورگر دریافت نشده است. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات InspectionEvidence,EvidenceVersions,MediaFiles,UploadSessions,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D04, D08 |

### C02 — انتقال بایت‌های رسانه

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | انتقال بایت‌های رسانه |
| صفحه وابسته | مرکز ارسال |
| عامل | upload-owner |
| ورودی | uploadId و جریان Blob بدون Base64 |
| خروجی | بایت دریافت‌شده در staging؛ هنوز تأیید نهایی انتقال نیست |
| اعتبارسنجی | upload session متعلق به همان نسخه، expiry و سقف stream؛ signature/hash واقعی در سرور؛ فایل بدون Base64 و بدون مسیر دلخواه نوشته شود. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، EvidenceVersions، IdempotencyRecords، MediaFiles، UploadSessions |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/features/upload/upload-coordinator.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/upload/upload-coordinator.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A03/A05، B01/B05؛ سیاست نوع/اندازه و فضای خصوصی |
| قرارداد مرتبط | EV02 |
| خواندن SQL | EvidenceVersions، IdempotencyRecords، MediaFiles، UploadSessions |
| نوشتن SQL | AuditLogs، EvidenceVersions، IdempotencyRecords، MediaFiles، UploadSessions |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | نوشتن stream محدود در staging همان uploadId؛ بدون بازنویسی اصل خوب. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات UploadSessions,MediaFiles,EvidenceVersions,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D04, D08 |

### C03 — تأیید دریافت پایدار فایل

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | تأیید دریافت پایدار فایل |
| صفحه وابسته | مرکز ارسال |
| عامل | upload-owner |
| ورودی | evidenceId، revision و اندازه/هش مورد توافق |
| خروجی | رسید باینری و وضعیت پردازش جدا |
| اعتبارسنجی | بایت پایدار، اندازه و hash سرور، revision هدف و receipt قابل بازیابی؛ پردازش جدا؛ اصل خوب قبل از موفقیت حفظ شود. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، EvidenceVersions، IdempotencyRecords، MediaFiles، MediaProcessingJobs، UploadSessions |
| اثر وضعیت | پس از hash/size و دوام فایل، رسید uploaded ثبت می‌شود؛ processing/verified مستقل‌اند. کاندیدای دور اصلاح تا resubmit تأییدشده جای اصل را نمی‌گیرد. |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/features/upload/upload-transport.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/upload/upload-transport.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A03/A05، B01/B05؛ سیاست نوع/اندازه و فضای خصوصی |
| قرارداد مرتبط | EV03 |
| خواندن SQL | EvidenceVersions، IdempotencyRecords، MediaFiles، MediaProcessingJobs، UploadSessions |
| نوشتن SQL | AuditLogs، EvidenceVersions، IdempotencyRecords، MediaFiles، MediaProcessingJobs، UploadSessions |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | verify/hash/flush، انتشار فایل همان نسخه و در صورت تصویب enqueue مشتق؛ SQL و filesystem نیاز به reconciliation دارند. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات UploadSessions,MediaFiles,EvidenceVersions,MediaProcessingJobs,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D04, D08 |

### C04 — بازخوانی و تطبیق وضعیت مدارک

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | بازخوانی و تطبیق وضعیت مدارک |
| صفحه وابسته | مرکز ارسال، refresh و خلاصه |
| عامل | owner-staff |
| ورودی | inspectionId، current/history و cursor |
| خروجی | نسخه‌ها و رسیدهای همان بازدید |
| اعتبارسنجی | scope پرونده/نسخه و cursor محدود؛ نمایش current/history دقیق؛ localBlobKey مرجع فایل سرور نیست. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | EvidenceVersions، InspectionEvidence، MediaFiles |
| اثر وضعیت | خواندن بدون تغییر چرخه عمر |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| پیاده‌سازی فعلی | مرز فعلی src/features/upload/queue-repository.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/upload/queue-repository.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A03/A05، B01/B05؛ سیاست نوع/اندازه و فضای خصوصی |
| قرارداد مرتبط | EV04 |
| خواندن SQL | EvidenceVersions، InspectionEvidence، MediaFiles |
| نوشتن SQL | بدون تغییر SQL برنامه |
| خواندن فایل | فایل/مشتق خصوصی همان نسخه با مجوز؛ فقط در صورت نیاز و بدون بارگذاری گروهی بایت‌ها. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تصمیم باز | D04, D08 |

### C05 — خواندن نتیجه پردازش مدرک

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | خواندن نتیجه پردازش مدرک |
| صفحه وابسته | مرکز ارسال و بازبینی |
| عامل | owner-staff |
| ورودی | شناسه نسخه مورد انتظار |
| خروجی | processing یا نتیجه معتبر با دلیل عمومی |
| اعتبارسنجی | processing از upload و تصمیم کارشناس جدا؛ فقط وضعیت نسخه مجاز و بدون درصد ساختگی برگردد. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | EvidenceReviews، EvidenceVersions، MediaFiles، MediaProcessingJobs |
| اثر وضعیت | خواندن بدون تغییر چرخه عمر |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| پیاده‌سازی فعلی | مرز فعلی src/features/upload/upload-transport.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/upload/upload-transport.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A03/A05، B01/B05؛ سیاست نوع/اندازه و فضای خصوصی |
| قرارداد مرتبط | EV04 |
| خواندن SQL | EvidenceVersions، MediaFiles، MediaProcessingJobs |
| نوشتن SQL | بدون تغییر SQL برنامه |
| خواندن فایل | فایل/مشتق خصوصی همان نسخه با مجوز؛ فقط در صورت نیاز و بدون بارگذاری گروهی بایت‌ها. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تصمیم باز | D04, D08 |

### C06 — نمایش امن عکس یا پخش ویدیو

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | نمایش امن عکس یا پخش ویدیو |
| صفحه وابسته | بازبینی مشتری و کارشناس |
| عامل | owner-staff |
| ورودی | شناسه مدرک/نسخه و Range برای ویدیو |
| خروجی | جریان مجاز فایل یا thumbnail؛ بدون مسیر دیسک |
| اعتبارسنجی | مجوز هر درخواست و Range، نسخه دقیق و path containment؛ MIME/nosniff و 206/416 صحیح؛ فایل خصوصی عمومی نشود. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | EvidenceVersions، MediaFiles، ReviewerAssignments |
| اثر وضعیت | خواندن بدون تغییر چرخه عمر |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| پیاده‌سازی فعلی | مرز فعلی src/features/upload/upload-preview.tsx؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/upload/upload-preview.tsx |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A03/A05، B01/B05؛ سیاست نوع/اندازه و فضای خصوصی |
| قرارداد مرتبط | EV05 |
| خواندن SQL | EvidenceVersions، MediaFiles، ReviewerAssignments |
| نوشتن SQL | بدون تغییر SQL برنامه |
| خواندن فایل | فایل/مشتق خصوصی همان نسخه با مجوز؛ فقط در صورت نیاز و بدون بارگذاری گروهی بایت‌ها. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تصمیم باز | D04, D08 |

### C07 — لغو انتقال نسخه منسوخ

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | لغو انتقال نسخه منسوخ |
| صفحه وابسته | تعویض مدرک و صف ارسال |
| عامل | upload-owner |
| ورودی | نسخه قبلی و expectedVersion |
| خروجی | لغو انتقال نامعتبر بدون حذف نسخه پذیرفته‌شده |
| اعتبارسنجی | فقط session منسوخ مجاز با CAS لغو شود؛ فایل پذیرفته‌شده یا snapshot قبلی حذف نشود. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، EvidenceVersions، IdempotencyRecords، UploadSessions |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/features/upload/upload-coordinator.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/upload/upload-coordinator.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A03/A05، B01/B05؛ سیاست نوع/اندازه و فضای خصوصی |
| قرارداد مرتبط | EV06 |
| خواندن SQL | EvidenceVersions، IdempotencyRecords، UploadSessions |
| نوشتن SQL | AuditLogs، EvidenceVersions، IdempotencyRecords، UploadSessions |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | توقف session منسوخ؛ فایل current یا تاریخچه حذف نمی‌شود. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات UploadSessions,EvidenceVersions,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D04, D08 |

## ارسال و اصلاحات

### D01 — خلاصه و آمادگی ارسال

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | خلاصه و آمادگی ارسال |
| صفحه وابسته | مرور نهایی |
| عامل | customer |
| ورودی | inspectionId |
| خروجی | خلاصه مشتق، شمارنده و دلیل موانع |
| اعتبارسنجی | خلاصه از همان منابع مشتق؛ ۱۱ عکس قالب تازه، کیلومتر معتبر و ویدیو جدا؛ شمار فایل از قالب، نه عدد ثابت. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | EvidenceVersions، InspectionEvidence، Inspections، OdometerReadings |
| اثر وضعیت | خواندن بدون تغییر چرخه عمر |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| پیاده‌سازی فعلی | مرز فعلی src/features/submission/summary-source.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/submission/summary-source.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | B01-B10، C01-C06؛ نسخه دقیق و آمادگی سرور |
| قرارداد مرتبط | I12 |
| خواندن SQL | EvidenceVersions، InspectionEvidence، Inspections، OdometerReadings |
| نوشتن SQL | بدون تغییر SQL برنامه |
| خواندن فایل | فایل/مشتق خصوصی همان نسخه با مجوز؛ فقط در صورت نیاز و بدون بارگذاری گروهی بایت‌ها. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تصمیم باز | D04, D08 |

### D02 — ارسال رسمی بازدید

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | ارسال رسمی بازدید |
| صفحه وابسته | خلاصه و CTA نهایی |
| عامل | customer |
| ورودی | expectedVersion و Idempotency-Key |
| خروجی | رسید پایدار و قفل snapshot |
| اعتبارسنجی | آمادگی سروری، receipt همه نسخه‌های هدف، کیلومتر، قفل و CAS؛ processing/uploaded/verified با سیاست باینری سازگار و local/queued/failed مسدود. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، IdempotencyRecords، InspectionStatusHistory، InspectionSubmissions، Inspections، SubmissionEvidence |
| اثر وضعیت | snapshot نسخه‌های دقیق، رسید پایدار و قفل submitted؛ پردازش غیرنهایی مانع باینری نیست، retake و نسخه نامعتبر مانع‌اند. |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/features/submission/submission-service.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/submission/submission-service.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | B01-B10، C01-C06؛ نسخه دقیق و آمادگی سرور |
| قرارداد مرتبط | I13 |
| خواندن SQL | IdempotencyRecords، InspectionSubmissions، Inspections، SubmissionEvidence |
| نوشتن SQL | AuditLogs، IdempotencyRecords، InspectionStatusHistory، InspectionSubmissions، Inspections، SubmissionEvidence |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات InspectionSubmissions,SubmissionEvidence,Inspections,InspectionStatusHistory,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D04, D08 |

### D03 — بازیابی نتیجه ارسال نامطمئن

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | بازیابی نتیجه ارسال نامطمئن |
| صفحه وابسته | بارگذاری دوباره خلاصه یا رسید |
| عامل | customer |
| ورودی | همان کلید و همان payload ارسال |
| خروجی | همان رسید؛ نه بازدید یا ارسال جدید |
| اعتبارسنجی | همان کلید و بدنه فرمان قبلی با احراز مجدد مجوز؛ بازیابی receipt پیش از رد نسخه کهنه؛ ارسال تکراری نسازد. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | IdempotencyRecords، InspectionSubmissions |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/features/submission/submission-service.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/submission/submission-service.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | B01-B10، C01-C06؛ نسخه دقیق و آمادگی سرور |
| قرارداد مرتبط | I13 |
| خواندن SQL | IdempotencyRecords، InspectionSubmissions |
| نوشتن SQL | بدون تغییر SQL برنامه |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تصمیم باز | D04, D08 |

### D04 — وضعیت و رسید مشتری

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | وضعیت و رسید مشتری |
| صفحه وابسته | پیگیری و بازگشت پس از ارسال |
| عامل | owner-staff |
| ورودی | inspectionId مجاز |
| خروجی | چرخه عمر، دلایل عمومی و تأیید مقصد در صورت وجود |
| اعتبارسنجی | همان inspection و رسید موجود؛ submit و upload و review و forwarding جدا؛ نبود رسید مجوز ادعای موفقیت نیست. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | CorrectionRequests، ForwardingJobs، InspectionStatusHistory، Inspections |
| اثر وضعیت | خواندن بدون تغییر چرخه عمر |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| پیاده‌سازی فعلی | مرز فعلی src/features/inspection-status/status-service.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/inspection-status/status-service.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | B01-B10، C01-C06؛ نسخه دقیق و آمادگی سرور |
| قرارداد مرتبط | I14 |
| خواندن SQL | CorrectionRequests، ForwardingJobs، InspectionStatusHistory، Inspections |
| نوشتن SQL | بدون تغییر SQL برنامه |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تصمیم باز | D04, D08 |

### D05 — درخواست دقیق مدرک تکمیلی

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | درخواست دقیق مدرک تکمیلی |
| صفحه وابسته | فهرست اصلاحات |
| عامل | owner-staff |
| ورودی | inspectionId و requestId/version |
| خروجی | اقلام مشخص، دلیل و نسخه اصلی |
| اعتبارسنجی | requestId/version متعلق به همین بازدید و مشتری؛ reason عمومی و اقلام فعال دقیق؛ اطلاعات خصوصی کارشناس حذف شود. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | CorrectionItems، CorrectionRequests، InspectionSubmissions |
| اثر وضعیت | خواندن بدون تغییر چرخه عمر |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| پیاده‌سازی فعلی | مرز فعلی src/features/additional-evidence/request-repository.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/additional-evidence/request-repository.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | B01-B10، C01-C06؛ نسخه دقیق و آمادگی سرور |
| قرارداد مرتبط | R01 |
| خواندن SQL | CorrectionItems، CorrectionRequests، InspectionSubmissions |
| نوشتن SQL | بدون تغییر SQL برنامه |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تصمیم باز | D04, D08 |

### D06 — پیوند نسخه جایگزین به قلم درخواست

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | پیوند نسخه جایگزین به قلم درخواست |
| صفحه وابسته | بازبینی اصلاح عکس/ویدیو |
| عامل | customer / upload-owner / customer-request |
| ورودی | requestId، itemId، version و candidateRevision |
| خروجی | پیشرفت همان قلم؛ اصل پذیرفته‌شده محفوظ |
| اعتبارسنجی | candidate به request/item/requirement/revision مجاز وصل باشد؛ هیچ قلم اضافی یا job قدیمی pointer اصل را تغییر ندهد. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، CorrectionItems، EvidenceVersions، IdempotencyRecords، MediaFiles، UploadSessions |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/features/additional-evidence/request-service.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/additional-evidence/request-service.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | B01-B10، C01-C06؛ نسخه دقیق و آمادگی سرور |
| قرارداد مرتبط | EV01، EV03، R02 |
| خواندن SQL | CorrectionItems، EvidenceVersions، IdempotencyRecords، MediaFiles، UploadSessions |
| نوشتن SQL | AuditLogs، CorrectionItems، EvidenceVersions، IdempotencyRecords، MediaFiles، UploadSessions |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات EvidenceVersions,MediaFiles,UploadSessions,CorrectionItems,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D04, D08 |

### D07 — ارسال دوباره اصلاحات مشخص

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | ارسال دوباره اصلاحات مشخص |
| صفحه وابسته | مرکز ارسال اصلاحات |
| عامل | customer-request |
| ورودی | requestVersion و candidateEvidenceIds تأییدشده |
| خروجی | SupplementalReceipt با همان کد پیگیری |
| اعتبارسنجی | نسخه درخواست و receipt تمام اقلام خواسته‌شده؛ promotion اتمیک؛ اقلام تأییدشده خارج از scope ثابت بمانند. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، CorrectionItems، CorrectionRequests، IdempotencyRecords، InspectionEvidence، InspectionStatusHistory، InspectionSubmissions، Inspections، SubmissionEvidence |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/features/additional-evidence/request-service.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/additional-evidence/request-service.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | B01-B10، C01-C06؛ نسخه دقیق و آمادگی سرور |
| قرارداد مرتبط | R03 |
| خواندن SQL | CorrectionItems، CorrectionRequests، IdempotencyRecords، InspectionEvidence، InspectionSubmissions، Inspections، SubmissionEvidence |
| نوشتن SQL | AuditLogs، CorrectionItems، CorrectionRequests، IdempotencyRecords، InspectionEvidence، InspectionStatusHistory، InspectionSubmissions، Inspections، SubmissionEvidence |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات CorrectionRequests,CorrectionItems,InspectionEvidence,InspectionSubmissions,SubmissionEvidence,Inspections,InspectionStatusHistory,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D04, D08 |

### D08 — پیشنهاد اصلاح فیلد خواسته‌شده

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | پیشنهاد اصلاح فیلد خواسته‌شده |
| صفحه وابسته | ویرایش پلاک، رنگ یا سال |
| عامل | customer-request |
| ورودی | taskId، نسخه و مقدار union تایپ‌شده |
| خروجی | پیشنهاد ثبت‌شده؛ بدون بازکردن سایر فیلدها |
| اعتبارسنجی | field از union مجاز همان task و نوع مقدار درست؛ فقط scope خواسته‌شده و CAS؛ درخواست جدید ضمنی ایجاد نشود. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، CorrectionItems، IdempotencyRecords |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/features/inspection-status/lifecycle-repository.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/inspection-status/lifecycle-repository.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | B01-B10، C01-C06؛ نسخه دقیق و آمادگی سرور |
| قرارداد مرتبط | R04 |
| خواندن SQL | CorrectionItems، IdempotencyRecords |
| نوشتن SQL | AuditLogs، CorrectionItems، IdempotencyRecords |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات CorrectionItems,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D04, D08 |

### D09 — تلاش تازه پس از رد کامل

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | تلاش تازه پس از رد کامل |
| صفحه وابسته | صفحه رد و تأیید شروع دوباره |
| عامل | customer |
| ورودی | شناسه تلاش ردشده، نسخه و کلید ثابت |
| خروجی | بازدید جدید خالی با previousAttemptId |
| اعتبارسنجی | فقط رد کامل و فرمان صریح مالک؛ current/attempt اتمیک؛ تلاش جدید خالی و تاریخچه قبلی immutable. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، IdempotencyRecords، InspectionStatusHistory، Inspections، SourceInsuranceRequests، Vehicles |
| اثر وضعیت | یک inspectionId/attempt تازه، با previousAttemptId و فضای مدرک خالی؛ وضعیت و فایل تلاش ردشده عوض نمی‌شود. |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/features/inspection-status/lifecycle-repository.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/inspection-status/lifecycle-repository.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | B01-B10، C01-C06؛ نسخه دقیق و آمادگی سرور |
| قرارداد مرتبط | I15 |
| خواندن SQL | IdempotencyRecords، Inspections، SourceInsuranceRequests، Vehicles |
| نوشتن SQL | AuditLogs، IdempotencyRecords، InspectionStatusHistory، Inspections، Vehicles |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات Inspections,Vehicles,InspectionStatusHistory,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D04, D08 |

## عملیات کارشناس

### E01 — فهرست پرونده‌ها و آمار واقعی

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | فهرست پرونده‌ها و آمار واقعی |
| صفحه وابسته | داشبورد و صف عملیات |
| عامل | owner-staff |
| ورودی | جست‌وجو، وضعیت، cursor و اندازه صفحه |
| خروجی | فهرست مجاز و شمارش در همان scope |
| اعتبارسنجی | فیلتر، cursor و scope کارکنان؛ آمار از query واقعی، نه مقدار نمایشی ثابت؛ حد pageSize. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | Inspections، ReviewerAssignments، StaffUsers |
| اثر وضعیت | خواندن بدون تغییر چرخه عمر |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| پیاده‌سازی فعلی | مرز فعلی src/features/review-operations/repository.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/review-operations/repository.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A04/A05، D02؛ ارجاع و نسخه پرونده |
| قرارداد مرتبط | I04 |
| خواندن SQL | Inspections، ReviewerAssignments، StaffUsers |
| نوشتن SQL | بدون تغییر SQL برنامه |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تصمیم باز | D04, D08 |

### E02 — پرونده ارجاع‌شده و جزئیات

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | پرونده ارجاع‌شده و جزئیات |
| صفحه وابسته | محیط شواهد کارشناس |
| عامل | case-read |
| ورودی | caseId و نسخه |
| خروجی | خلاصه، مدارک و یادداشت صرفاً کارکنان |
| اعتبارسنجی | ارجاع فعال کارشناس یا مجوز خواندن مدیر؛ projection نقش و نسخه پرونده؛ مدیر حق تصمیم ضمنی ندارد. |
| مجوز و tenant | نشست کارکنان؛ کارشناس دارای ارجاع یا مدیر دارای مجوز خواندن همان پرونده. پاسخ براساس نقش پالایش شود؛ یادداشت خصوصی فقط با اختیار صریح و تصمیم فقط برای کارشناس مجاز است. |
| اثر ذخیره‌سازی | EvidenceReviews، Inspections، InternalNotes، ReviewerAssignments |
| اثر وضعیت | خواندن بدون تغییر چرخه عمر |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| پیاده‌سازی فعلی | مرز فعلی src/features/review-operations/repository.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/review-operations/repository.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A04/A05، D02؛ ارجاع و نسخه پرونده |
| قرارداد مرتبط | RV01 |
| خواندن SQL | EvidenceReviews، Inspections، InternalNotes، ReviewerAssignments |
| نوشتن SQL | بدون تغییر SQL برنامه |
| خواندن فایل | فایل/مشتق خصوصی همان نسخه با مجوز؛ فقط در صورت نیاز و بدون بارگذاری گروهی بایت‌ها. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تصمیم باز | D04, D08 |

### E03 — ارجاع و ارجاع مجدد

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | ارجاع و ارجاع مجدد |
| صفحه وابسته | مدیریت کارشناسان |
| عامل | admin |
| ورودی | inspectionId، reviewerId، reassign و نسخه |
| خروجی | ارجاع فعال و ثبت رویداد یا خطای ظرفیت |
| اعتبارسنجی | staff فعال، permission ارجاع، ظرفیت و سیاست؛ reassignment با CAS و audit؛ تصمیم کارشناس قبلی بعد از جابه‌جایی رد شود. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، IdempotencyRecords، InspectionStatusHistory، Inspections، ReviewerAssignments، StaffUsers |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/features/review-operations/model.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/review-operations/model.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A04/A05، D02؛ ارجاع و نسخه پرونده |
| قرارداد مرتبط | RV02 |
| خواندن SQL | IdempotencyRecords، Inspections، ReviewerAssignments، StaffUsers |
| نوشتن SQL | AuditLogs، IdempotencyRecords، InspectionStatusHistory، Inspections، ReviewerAssignments |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات ReviewerAssignments,Inspections,InspectionStatusHistory,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D04, D08 |

### E04 — تنظیم حالت و ظرفیت ارجاع

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | تنظیم حالت و ظرفیت ارجاع |
| صفحه وابسته | مدیریت کارشناسان |
| عامل | admin / admin-read |
| ورودی | manual/random، ظرفیت و expectedVersion |
| خروجی | سیاست ارجاع معتبر و بار کاری |
| اعتبارسنجی | mode از manual/random، ظرفیت صحیح و نسخه workspace؛ random در سرور و اختیار مدیریت لازم. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، IdempotencyRecords، StaffOperationsSettings، StaffUsers |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/features/review-operations/repository.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/review-operations/repository.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A04/A05، D02؛ ارجاع و نسخه پرونده |
| قرارداد مرتبط | RV03، AD01 |
| خواندن SQL | IdempotencyRecords، StaffOperationsSettings، StaffUsers |
| نوشتن SQL | AuditLogs، IdempotencyRecords، StaffOperationsSettings، StaffUsers |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات StaffOperationsSettings,StaffUsers,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D04, D08 |

### E05 — تصمیم درباره یک نسخه مدرک

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | تصمیم درباره یک نسخه مدرک |
| صفحه وابسته | کارشناس، عکس یا ویدیو |
| عامل | assigned-reviewer |
| ورودی | evidenceId، revision، تصمیم، دلیل و نسخه پرونده |
| خروجی | ReviewDecision و در صورت رد درخواست دقیق |
| اعتبارسنجی | نسخه دقیق مدرک و پرونده، ارجاع فعال؛ دلیل عمومی برای رد/retake اجباری؛ نسخه جدید با پاسخ قدیمی overwrite نشود. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، CorrectionItems، CorrectionRequests، EvidenceReviews، IdempotencyRecords، InspectionStatusHistory، Inspections |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/features/review-operations/repository.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/review-operations/repository.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A04/A05، D02؛ ارجاع و نسخه پرونده |
| قرارداد مرتبط | RV04 |
| خواندن SQL | CorrectionItems، CorrectionRequests، EvidenceReviews، IdempotencyRecords، Inspections |
| نوشتن SQL | AuditLogs، CorrectionItems، CorrectionRequests، EvidenceReviews، IdempotencyRecords، InspectionStatusHistory، Inspections |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات EvidenceReviews,CorrectionRequests,CorrectionItems,Inspections,InspectionStatusHistory,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D04, D08 |

### E06 — درخواست اصلاح مشخصات خودرو

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | درخواست اصلاح مشخصات خودرو |
| صفحه وابسته | کارشناس و مشخصات |
| عامل | assigned-reviewer |
| ورودی | field از plate/color/modelYear و دلیل عمومی |
| خروجی | قلم اصلاح محدود با زمان و عامل سرور |
| اعتبارسنجی | field فقط plate/color/modelYear و دلیل روشن؛ task مستقل از رد کلی و مدرک دیگر؛ کارشناس باید ارجاع فعال داشته باشد. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، CorrectionItems، CorrectionRequests، IdempotencyRecords، InspectionStatusHistory، Inspections |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/features/review-operations/repository.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/review-operations/repository.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A04/A05، D02؛ ارجاع و نسخه پرونده |
| قرارداد مرتبط | RV05 |
| خواندن SQL | CorrectionItems، CorrectionRequests، IdempotencyRecords، Inspections |
| نوشتن SQL | AuditLogs، CorrectionItems، CorrectionRequests، IdempotencyRecords، InspectionStatusHistory، Inspections |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات CorrectionRequests,CorrectionItems,Inspections,InspectionStatusHistory,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D04, D08 |

### E07 — بررسی پیشنهاد اصلاح فیلد

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | بررسی پیشنهاد اصلاح فیلد |
| صفحه وابسته | کارشناس و اصلاحات |
| عامل | assigned-reviewer |
| ورودی | taskId، نسخه پیشنهاد و تصمیم |
| خروجی | تأیید projection بررسی‌شده؛ snapshot اولیه ثابت |
| اعتبارسنجی | همان task/proposalVersion و مجوز؛ کد فعلی approve دارد، reopen هنوز تصمیم باز است و مسیر فرضی اجراشده نیست. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، CorrectionItems، IdempotencyRecords، Inspections، Vehicles |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/features/review-operations/repository.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/review-operations/repository.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A04/A05، D02؛ ارجاع و نسخه پرونده |
| قرارداد مرتبط | RV06 |
| خواندن SQL | CorrectionItems، IdempotencyRecords، Inspections، Vehicles |
| نوشتن SQL | AuditLogs، CorrectionItems، IdempotencyRecords، Inspections، Vehicles |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات CorrectionItems,Vehicles,Inspections,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D04, D08 |

### E08 — ثبت یادداشت خصوصی

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | ثبت یادداشت خصوصی |
| صفحه وابسته | پرونده کارشناس |
| عامل | assigned-reviewer |
| ورودی | متن، نسخه و کلید فرمان |
| خروجی | یادداشت کارکنان، بدون انتشار برای مشتری |
| اعتبارسنجی | متن محدود و private واقعی، اختیار مشاهده/نوشتن و نسخه؛ در DTO مشتری یا گزارش عمومی نیاید. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، IdempotencyRecords، InternalNotes |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/features/review-operations/repository.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/review-operations/repository.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A04/A05، D02؛ ارجاع و نسخه پرونده |
| قرارداد مرتبط | RV07 |
| خواندن SQL | IdempotencyRecords، InternalNotes |
| نوشتن SQL | AuditLogs، IdempotencyRecords، InternalNotes |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات InternalNotes,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D04, D08 |

### E09 — تصمیم جداگانه کل بازدید

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | تصمیم جداگانه کل بازدید |
| صفحه وابسته | اقدام نهایی کارشناس |
| عامل | assigned-reviewer |
| ورودی | approved/rejected، دلیل رد و نسخه |
| خروجی | تصمیم کل؛ تأیید مساوی تحویل به کارگزاری نیست |
| اعتبارسنجی | تصمیم کل جدا از تک‌مدرک؛ approved فقط پس از آمادگی همه اقلام؛ rejected نیازمند دلیل؛ تأیید outbox می‌سازد نه FORWARDED. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، ForwardingJobs، IdempotencyRecords، InspectionReviews، InspectionStatusHistory، Inspections |
| اثر وضعیت | تأیید کل فقط پس از تأیید همه نسخه‌های لازم و فیلدها؛ outbox پایدار ایجاد می‌شود، FORWARDED تا ack معتبر ممنوع. |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/features/review-operations/repository.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/review-operations/repository.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A04/A05، D02؛ ارجاع و نسخه پرونده |
| قرارداد مرتبط | RV08 |
| خواندن SQL | ForwardingJobs، IdempotencyRecords، InspectionReviews، Inspections |
| نوشتن SQL | AuditLogs، ForwardingJobs، IdempotencyRecords، InspectionReviews، InspectionStatusHistory، Inspections |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات InspectionReviews,Inspections,InspectionStatusHistory,ForwardingJobs,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D04, D08 |

### E10 — تاریخچه نسخه‌ها و تصمیم‌ها

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | تاریخچه نسخه‌ها و تصمیم‌ها |
| صفحه وابسته | تاریخچه پرونده |
| عامل | case-read |
| ورودی | caseId و cursor مجاز |
| خروجی | رویدادها و ارجاع‌های نسخه دقیق |
| اعتبارسنجی | مجوز خواندن پرونده، cursor و projection نقش؛ نسخه‌ها و تصمیم‌ها حذف نشوند؛ private notes به نقش غیرمجاز نرسند. |
| مجوز و tenant | نشست کارکنان؛ کارشناس دارای ارجاع یا مدیر دارای مجوز خواندن همان پرونده. پاسخ براساس نقش پالایش شود؛ یادداشت خصوصی فقط با اختیار صریح و تصمیم فقط برای کارشناس مجاز است. |
| اثر ذخیره‌سازی | AuditLogs، EvidenceReviews، EvidenceVersions، InspectionStatusHistory |
| اثر وضعیت | خواندن بدون تغییر چرخه عمر |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| پیاده‌سازی فعلی | مرز فعلی src/features/review-operations/repository.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/review-operations/repository.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A04/A05، D02؛ ارجاع و نسخه پرونده |
| قرارداد مرتبط | RV09 |
| خواندن SQL | EvidenceReviews، EvidenceVersions، InspectionStatusHistory |
| نوشتن SQL | بدون تغییر SQL برنامه |
| خواندن فایل | فایل/مشتق خصوصی همان نسخه با مجوز؛ فقط در صورت نیاز و بدون بارگذاری گروهی بایت‌ها. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تصمیم باز | D04, D08 |

## مدیریت و تنظیمات

### F01 — خواندن محیط مدیریت و قالب‌ها

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | خواندن محیط مدیریت و قالب‌ها |
| صفحه وابسته | مدیریت |
| عامل | admin-read |
| ورودی | مجوز، فیلتر و نسخه |
| خروجی | قالب، کاربران و سیاست قابل مشاهده |
| اعتبارسنجی | permission‌های مجزا، نسخه workspace و projection مجاز؛ مدیر همان نصب، نه مالک کلید مرکزی نقشه. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، InspectionTemplates، StaffRoleAssignments، StaffUsers |
| اثر وضعیت | خواندن بدون تغییر چرخه عمر |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| پیاده‌سازی فعلی | مرز فعلی src/features/admin/repository.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/admin/repository.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A04/A05؛ مجوز و CAS تنظیمات/قالب |
| قرارداد مرتبط | AD01 |
| خواندن SQL | InspectionTemplates، StaffRoleAssignments، StaffUsers |
| نوشتن SQL | بدون تغییر SQL برنامه |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تصمیم باز | D04, D08 |

### F02 — ایجاد قالب یا پیش‌نویس

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | ایجاد قالب یا پیش‌نویس |
| صفحه وابسته | ویرایشگر قالب |
| عامل | template-editor |
| ورودی | عنوان، قالب مبنا، نسخه و کلید فرمان |
| خروجی | پیش‌نویس جدید؛ قالب منتشرشده دست‌نخورده |
| اعتبارسنجی | عنوان و قالب مبنا معتبر و نسخه جدید مستقل؛ هیچ قالب پین‌شده تاریخی درجا تغییر نکند. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، EvidenceRequirements، IdempotencyRecords، InspectionTemplates، RequirementAlternatives |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/features/admin/repository.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/admin/repository.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A04/A05؛ مجوز و CAS تنظیمات/قالب |
| قرارداد مرتبط | AD02 |
| خواندن SQL | EvidenceRequirements، IdempotencyRecords، InspectionTemplates، RequirementAlternatives |
| نوشتن SQL | AuditLogs، EvidenceRequirements، IdempotencyRecords، InspectionTemplates، RequirementAlternatives |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات InspectionTemplates,EvidenceRequirements,RequirementAlternatives,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D04, D08 |

### F03 — ویرایش و ذخیره پیش‌نویس

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | ویرایش و ذخیره پیش‌نویس |
| صفحه وابسته | ویرایشگر قالب |
| عامل | template-editor |
| ورودی | PhotographyTemplate معتبر و expectedRevision |
| خروجی | پیش‌نویس ذخیره‌شده یا خطای فیلد/تعارض |
| اعتبارسنجی | Zod فعلی کامل شامل راهنماها، شناسه‌های یکتا، ۱۱ عکس و گروه یک‌ازچهار؛ expectedRevision و حالت draft. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، EvidenceRequirements، IdempotencyRecords، InspectionTemplates، RequirementAlternatives |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/features/admin/repository.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/admin/repository.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A04/A05؛ مجوز و CAS تنظیمات/قالب |
| قرارداد مرتبط | AD03 |
| خواندن SQL | EvidenceRequirements، IdempotencyRecords، InspectionTemplates، RequirementAlternatives |
| نوشتن SQL | AuditLogs، EvidenceRequirements، IdempotencyRecords، InspectionTemplates، RequirementAlternatives |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات InspectionTemplates,EvidenceRequirements,RequirementAlternatives,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D04, D08 |

### F04 — انتشار یا بایگانی نسخه قالب

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | انتشار یا بایگانی نسخه قالب |
| صفحه وابسته | مدیر سایت |
| عامل | admin |
| ورودی | نسخه مورد انتظار و action مجاز |
| خروجی | انتشار immutable؛ بازدیدهای پین‌شده ثابت |
| اعتبارسنجی | فقط draft معتبر منتشر یا نسخه مجاز بایگانی شود؛ قالب پین‌شده قابل خواندن بماند؛ CAS و audit. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، IdempotencyRecords، InspectionTemplates |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/features/admin/repository.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/admin/repository.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A04/A05؛ مجوز و CAS تنظیمات/قالب |
| قرارداد مرتبط | AD04 |
| خواندن SQL | IdempotencyRecords، InspectionTemplates |
| نوشتن SQL | AuditLogs، IdempotencyRecords، InspectionTemplates |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات InspectionTemplates,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D04, D08 |

### F05 — خواندن عمومی برند

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_FRONTEND_IMPLEMENTATION / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | خواندن عمومی برند |
| صفحه وابسته | صفحات مشتری |
| عامل | خواننده عمومی تنظیمات همین نصب |
| ورودی | نسخه منتشرشده نصب |
| خروجی | همان نتیجه A02؛ نه مخزن دوم |
| اعتبارسنجی | همان projection عمومی A02؛ هیچ store یا endpoint رقیب برای برند ساخته نشود. |
| مجوز و tenant | بدون نشست؛ فقط داده عمومی مجاز نصب |
| اثر ذخیره‌سازی | BrandingAssets، SiteSettings، SiteSettingsAssetLinks، SiteSettingsVersions |
| اثر وضعیت | خواندن بدون تغییر چرخه عمر |
| خطا | 404 پیکربندی/فایل یافت نشد؛ 503 پیکربندی یا میزبان در دسترس نیست؛ داده خصوصی یا fallback موفق جعلی منتشر نشود. |
| تکرار و retry | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| پیاده‌سازی فعلی | A01 فایل عمومی واقعی؛ A02/F05 بارگذار واقعی و انتشار محلی؛ B11 مرز توسعه زنده مجاز. این مورد تضمین Backend تولید نیست |
| مرز منبع | src/config/site-settings.loader.ts |
| پیشنهاد Backend | برای A01 فایل عمومی استقرار موجود کافی است؛ A02/F05 فقط یک projection عمومی از نسخه منتشرشده همان provider تنظیمات می‌خواهند، بدون نشست/SQL تجاری اضافه. |
| وابستگی | A04/A05؛ مجوز و CAS تنظیمات/قالب |
| قرارداد مرتبط | P01 |
| خواندن SQL | BrandingAssets، SiteSettings، SiteSettingsAssetLinks، SiteSettingsVersions |
| نوشتن SQL | بدون تغییر SQL برنامه |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تصمیم باز | D04, D08 |

### F06 — خواندن و ذخیره پیش‌نویس تنظیمات

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | خواندن و ذخیره پیش‌نویس تنظیمات |
| صفحه وابسته | تنظیمات سایت |
| عامل | admin |
| ورودی | فیلدهای مجاز برند/محتوا و expectedRevision |
| خروجی | workspace پیش‌نویس با نسخه CAS |
| اعتبارسنجی | whitelist متن/برند، قالب، URL و contrast؛ API base و Neshan مرکزی از فرم عادی قابل تغییر نیستند؛ CAS draft. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، IdempotencyRecords، SiteSettings، SiteSettingsAssetLinks، SiteSettingsVersions |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/config/site-settings.repository.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/config/site-settings.repository.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A04/A05؛ مجوز و CAS تنظیمات/قالب |
| قرارداد مرتبط | AD05، AD06 |
| خواندن SQL | IdempotencyRecords، SiteSettings، SiteSettingsAssetLinks، SiteSettingsVersions |
| نوشتن SQL | AuditLogs، IdempotencyRecords، SiteSettings، SiteSettingsAssetLinks، SiteSettingsVersions |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات SiteSettings,SiteSettingsVersions,SiteSettingsAssetLinks,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D04, D08 |

### F07 — انتشار تنظیمات یا بازنشانی بصری پیش‌نویس

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | انتشار تنظیمات یا بازنشانی بصری پیش‌نویس |
| صفحه وابسته | تنظیمات سایت |
| عامل | admin |
| ورودی | نسخه و کلید انتشار؛ reset یک ویرایش draft است |
| خروجی | نسخه عمومی جدید و تاریخچه |
| اعتبارسنجی | publish با CAS و اعتبار کامل؛ reset فقط draft بصری است، نه حذف مدارک/بازدید/تنظیمات مرکزی. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، IdempotencyRecords، SiteSettings، SiteSettingsVersions |
| اثر وضعیت | reset بصری فقط پیش‌نویس را ویرایش می‌کند؛ فقط انتشار، نسخه عمومی جدید می‌سازد. |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/config/site-settings.repository.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/config/site-settings.repository.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A04/A05؛ مجوز و CAS تنظیمات/قالب |
| قرارداد مرتبط | AD07 |
| خواندن SQL | IdempotencyRecords، SiteSettings، SiteSettingsVersions |
| نوشتن SQL | AuditLogs، IdempotencyRecords، SiteSettings، SiteSettingsVersions |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات SiteSettings,SiteSettingsVersions,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D04, D08 |

### F08 — بارگذاری دارایی برند و حل مرجع

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | بارگذاری دارایی برند و حل مرجع |
| صفحه وابسته | تنظیمات تصاویر |
| عامل | admin |
| ورودی | File، slot و فراداده نوع/اندازه |
| خروجی | assetId و URL عمومی مجاز برای برند |
| اعتبارسنجی | slot مجاز، اندازه، signature، ابعاد و نوع امن فایل؛ SVG خام نامطمئن ممنوع؛ لوگوی کارگزاری از هویت برنامه جدا. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، BrandingAssets، IdempotencyRecords، SiteSettingsAssetLinks |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/features/admin/assets/asset-repository.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/admin/assets/asset-repository.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A04/A05؛ مجوز و CAS تنظیمات/قالب |
| قرارداد مرتبط | AD08 |
| خواندن SQL | BrandingAssets، IdempotencyRecords، SiteSettingsAssetLinks |
| نوشتن SQL | AuditLogs، BrandingAssets، IdempotencyRecords |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ایجاد فایل برند sanitised در مسیر عمومی مجاز برند؛ این استثنا برای لوگو است، نه رسانه بازدید. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات BrandingAssets,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D04, D08 |

### F09 — سازگاری تنظیمات قدیمی برند

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | سازگاری تنظیمات قدیمی برند |
| صفحه وابسته | پنل قدیمی برندینگ |
| عامل | admin |
| ورودی | payload اعتبارسنجی‌شده قدیمی و نسخه |
| خروجی | تبدیل به همان draft/publication F06/F07 |
| اعتبارسنجی | تبدیل payload قدیمی به همان schema جدید، whitelist و CAS؛ مسیر مستقل ذخیره حقیقت ایجاد نشود. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، IdempotencyRecords، SiteSettings، SiteSettingsAssetLinks، SiteSettingsVersions |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/features/admin/repository.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/admin/repository.ts |
| پیشنهاد Backend | نام مستعار مهاجرتی به F06/F07؛ منبع تنظیمات و جدول جدا ساخته نشود. |
| وابستگی | A04/A05؛ مجوز و CAS تنظیمات/قالب |
| قرارداد مرتبط | AD06 |
| خواندن SQL | IdempotencyRecords، SiteSettings، SiteSettingsAssetLinks، SiteSettingsVersions |
| نوشتن SQL | AuditLogs، IdempotencyRecords، SiteSettings، SiteSettingsAssetLinks، SiteSettingsVersions |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات SiteSettings,SiteSettingsVersions,SiteSettingsAssetLinks,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D04, D08 |

### F10 — نقش و فعال‌بودن کارکنان

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | نقش و فعال‌بودن کارکنان |
| صفحه وابسته | مدیریت دسترسی |
| عامل | admin-read / admin |
| ورودی | staffId، نقش مجاز و نسخه |
| خروجی | نقش نصب و audit؛ نه خودارتقایی مرورگر |
| اعتبارسنجی | staffId همان نصب، نقش/فعال‌بودن مجاز و جلوگیری از ارتقای بی‌اختیار؛ هویت SSO در Frontend ساخته نشود. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، IdempotencyRecords، StaffRoleAssignments، StaffUsers |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/features/admin/repository.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/admin/repository.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A04/A05؛ مجوز و CAS تنظیمات/قالب |
| قرارداد مرتبط | AD01، AD09 |
| خواندن SQL | IdempotencyRecords، StaffRoleAssignments، StaffUsers |
| نوشتن SQL | AuditLogs، IdempotencyRecords، StaffRoleAssignments، StaffUsers |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات StaffUsers,StaffRoleAssignments,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D04, D08 |

### F11 — فعال‌سازی وب‌هوک ازپیش‌تعریف‌شده

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | فعال‌سازی وب‌هوک ازپیش‌تعریف‌شده |
| صفحه وابسته | تنظیمات عملیات |
| عامل | admin |
| ورودی | شناسه whitelist، enabled و نسخه |
| خروجی | تنظیم رویداد سروری؛ نه URL دلخواه مشتری |
| اعتبارسنجی | فقط webhook ازپیش‌تعریف‌شده whitelist؛ مقصد و credential دلخواه مرورگر مردود؛ تغییر enabled با مجوز و CAS. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، IdempotencyRecords، WebhookSubscriptions |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | مرز فعلی src/features/admin/repository.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/admin/repository.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A04/A05؛ مجوز و CAS تنظیمات/قالب |
| قرارداد مرتبط | AD10 |
| خواندن SQL | IdempotencyRecords، WebhookSubscriptions |
| نوشتن SQL | AuditLogs، IdempotencyRecords، WebhookSubscriptions |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات WebhookSubscriptions,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D04, D08 |

### F12 — سلامت، ذخیره‌سازی و سیاست قابل مشاهده

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | سلامت، ذخیره‌سازی و سیاست قابل مشاهده |
| صفحه وابسته | مدیریت زیرساخت |
| عامل | admin |
| ورودی | نشست مجاز |
| خروجی | سلامت واقعی و خلاصه غیرمحرمانه یا unavailable |
| اعتبارسنجی | اندازه‌گیری واقعی فضای فایل/صف/worker و وضعیت dependency؛ secret یا physical root در پاسخ نیاید؛ نبود تحلیل با موفقیت جعل نشود. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | داده استقرار/هویت بیرونی یا سرویس مرکزی؛ فایل رسانه/جدول کسب‌وکار ایجاد نمی‌شود |
| اثر وضعیت | خواندن بدون تغییر چرخه عمر |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| پیاده‌سازی فعلی | مرز فعلی src/features/admin/operational-snapshot.tsx؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/admin/operational-snapshot.tsx |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | A04/A05؛ مجوز و CAS تنظیمات/قالب |
| قرارداد مرتبط | AD11 |
| خواندن SQL | بدون جدول برنامه |
| نوشتن SQL | بدون تغییر SQL برنامه |
| خواندن فایل | فایل/مشتق خصوصی همان نسخه با مجوز؛ فقط در صورت نیاز و بدون بارگذاری گروهی بایت‌ها. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تصمیم باز | D04, D08 |

## اعلان و تحویل سروری

### G01 — اعلان رویداد وضعیت

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | اعلان رویداد وضعیت |
| صفحه وابسته | کارگر سرور |
| عامل | کارگر سرور یا مدیر دارای مجوز عملیاتی؛ مشتری فقط projection امن |
| ورودی | eventId و گیرنده مجاز |
| خروجی | تأیید درگاه یا خطا و audit |
| اعتبارسنجی | eventId یکتا، گیرنده مجاز، ترجیحات/رضایت و payload بدون راز؛ اعلان به معنی تغییر تصمیم نیست. |
| مجوز و tenant | tenant از نصب و نشست معتبر؛ اتصال subject/sourceRequest/inspection و برای Reviewer ارجاع فعال. کارگر سرور یا مدیر دارای مجوز عملیاتی؛ مشتری فقط projection امن |
| اثر ذخیره‌سازی | AuditLogs، IdempotencyRecords، Inspections، NotificationOutbox، WebhookSubscriptions |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | فقط type/projection فعلی؛ هیچ انتقال واقعی یا درگاه اعلان پیاده نشده است. |
| مرز منبع | src/features/inspection-status/integration-contracts.ts |
| پیشنهاد Backend | کارگر/رویداد سروری؛ endpoint مرورگر ندارد. تولید outbox، ارسال به درگاه/سامانه بیمه و تأیید دریافت طبق فصل ۱۴. |
| وابستگی | E09؛ snapshot و مقصد/تأیید مقصد مورد توافق |
| قرارداد مرتبط | کارگر/رویداد سرور؛ مسیر مرورگر ندارد |
| خواندن SQL | IdempotencyRecords، Inspections، NotificationOutbox، WebhookSubscriptions |
| نوشتن SQL | AuditLogs، IdempotencyRecords، NotificationOutbox |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات NotificationOutbox,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D11, D12 |

### G02 — ایجاد کار تحویل نسخه تأییدشده

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | ایجاد کار تحویل نسخه تأییدشده |
| صفحه وابسته | تراکنش تأیید کل |
| عامل | کارگر سرور یا مدیر دارای مجوز عملیاتی؛ مشتری فقط projection امن |
| ورودی | snapshot تأییدشده و مقصد whitelist |
| خروجی | یک outbox پایدار برای همان تأیید |
| اعتبارسنجی | snapshot همان تصمیم approved، inspection/submission یکسان و مقصد whitelist؛ ایجاد outbox اتمیک با تصمیم. |
| مجوز و tenant | tenant از نصب و نشست معتبر؛ اتصال subject/sourceRequest/inspection و برای Reviewer ارجاع فعال. کارگر سرور یا مدیر دارای مجوز عملیاتی؛ مشتری فقط projection امن |
| اثر ذخیره‌سازی | AuditLogs، ForwardingJobs، IdempotencyRecords، InspectionReviews، InspectionStatusHistory، InspectionSubmissions، Inspections |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | فقط type/projection فعلی؛ هیچ انتقال واقعی یا درگاه اعلان پیاده نشده است. |
| مرز منبع | src/features/inspection-status/integration-contracts.ts |
| پیشنهاد Backend | کارگر/رویداد سروری؛ endpoint مرورگر ندارد. تولید outbox، ارسال به درگاه/سامانه بیمه و تأیید دریافت طبق فصل ۱۴. |
| وابستگی | E09؛ snapshot و مقصد/تأیید مقصد مورد توافق |
| قرارداد مرتبط | کارگر/رویداد سرور؛ مسیر مرورگر ندارد |
| خواندن SQL | ForwardingJobs، IdempotencyRecords، InspectionReviews، InspectionSubmissions، Inspections |
| نوشتن SQL | AuditLogs، ForwardingJobs، IdempotencyRecords، InspectionStatusHistory، Inspections |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات ForwardingJobs,Inspections,InspectionStatusHistory,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D11, D12 |

### G03 — ارسال به سامانه بیمه و تأیید دریافت

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | ارسال به سامانه بیمه و تأیید دریافت |
| صفحه وابسته | کارگر سرور |
| عامل | کارگر سرور یا مدیر دارای مجوز عملیاتی؛ مشتری فقط projection امن |
| ورودی | deliveryKey و نسخه‌های تأییدشده |
| خروجی | acknowledgementId/time معتبر یا خطای طبقه‌بندی‌شده |
| اعتبارسنجی | deliveryKey ثابت، احراز مقصد و پاسخ معتبر؛ HTTP200 به تنهایی رسید نیست؛ ack/query و retry طبقه‌بندی‌شده. |
| مجوز و tenant | tenant از نصب و نشست معتبر؛ اتصال subject/sourceRequest/inspection و برای Reviewer ارجاع فعال. کارگر سرور یا مدیر دارای مجوز عملیاتی؛ مشتری فقط projection امن |
| اثر ذخیره‌سازی | AuditLogs، ForwardingAttempts، ForwardingJobs، IdempotencyRecords، InspectionStatusHistory، Inspections، MediaFiles |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | فقط type/projection فعلی؛ هیچ انتقال واقعی یا درگاه اعلان پیاده نشده است. |
| مرز منبع | src/features/inspection-status/integration-contracts.ts |
| پیشنهاد Backend | کارگر/رویداد سروری؛ endpoint مرورگر ندارد. تولید outbox، ارسال به درگاه/سامانه بیمه و تأیید دریافت طبق فصل ۱۴. |
| وابستگی | E09؛ snapshot و مقصد/تأیید مقصد مورد توافق |
| قرارداد مرتبط | کارگر/رویداد سرور؛ مسیر مرورگر ندارد |
| خواندن SQL | ForwardingAttempts، ForwardingJobs، IdempotencyRecords، Inspections، MediaFiles |
| نوشتن SQL | AuditLogs، ForwardingAttempts، ForwardingJobs، IdempotencyRecords، InspectionStatusHistory، Inspections |
| خواندن فایل | فایل/مشتق خصوصی همان نسخه با مجوز؛ فقط در صورت نیاز و بدون بارگذاری گروهی بایت‌ها. |
| نوشتن فایل | خواندن/stream نسخه‌های snapshot approved به مقصد whitelist؛ نه کپی Base64 و نه حذف اصل. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات ForwardingJobs,ForwardingAttempts,Inspections,InspectionStatusHistory,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D11, D12 |

### G04 — بازیابی عملیاتی ارسال به کارگزاری

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | بازیابی عملیاتی ارسال به کارگزاری |
| صفحه وابسته | مدیر مجاز |
| عامل | admin-operations |
| ورودی | jobId، نسخه و کلید retry |
| خروجی | صف مجدد همان job؛ بدون عکاسی دوباره |
| اعتبارسنجی | همان job معتبر و permission عملیاتی؛ lease، نسخه و retryable بودن؛ job جدید برای همان تحویل نسازد. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | AuditLogs، ForwardingAttempts، ForwardingJobs، IdempotencyRecords |
| اثر وضعیت | فرمان تراکنشی و audit مطابق خروجی؛ جدول انتقال فصل ۱۱ حاکم است |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| پیاده‌سازی فعلی | projection شکست/انتظار موجود است؛ فرمان retry سرور و ارسال واقعی هنوز پیاده نشده است. |
| مرز منبع | src/features/inspection-status/integration-contracts.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | E09؛ snapshot و مقصد/تأیید مقصد مورد توافق |
| قرارداد مرتبط | FW01 |
| خواندن SQL | ForwardingAttempts، ForwardingJobs، IdempotencyRecords |
| نوشتن SQL | AuditLogs، ForwardingJobs، IdempotencyRecords |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات ForwardingJobs,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تصمیم باز | D11, D12 |

### G05 — نمایش وضعیت تحویل

| موضوع | الزام |
|---|---|
| وضعیت موجود / قرارداد | CURRENT_MOCK / PROPOSED_BACKEND_CONTRACT, PENDING_BACKEND_APPROVAL |
| هدف | نمایش وضعیت تحویل |
| صفحه وابسته | مشتری و کارکنان مجاز |
| عامل | owner-staff |
| ورودی | زمینه بازدید |
| خروجی | همان projection در D04/E01، با ack واقعی |
| اعتبارسنجی | نمایش از D04 و فقط پس از ack معتبر FORWARDED؛ وضعیت داخلی credential/خطای خام نشت نکند. |
| مجوز و tenant | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| اثر ذخیره‌سازی | ForwardingJobs |
| اثر وضعیت | خواندن بدون تغییر چرخه عمر |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تکرار و retry | خواندن قابل تکرار؛ backoff محدود روی خطای موقت و رعایت Retry-After |
| پیاده‌سازی فعلی | مرز فعلی src/features/inspection-status/lifecycle-model.ts؛ رفتار تجاری محلی/mock است |
| مرز منبع | src/features/inspection-status/lifecycle-model.ts |
| پیشنهاد Backend | پیشنهاد نیازمند تصویب؛ سرویس ASP.NET با احراز هویت/مجوز، DTO معتبر و SQL metadata/فایل خصوصی در صورت ارتباط |
| وابستگی | E09؛ snapshot و مقصد/تأیید مقصد مورد توافق |
| قرارداد مرتبط | I14 |
| خواندن SQL | ForwardingJobs |
| نوشتن SQL | بدون تغییر SQL برنامه |
| خواندن فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. |
| نوشتن فایل | ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | خواندن scope دار بدون تغییر چرخه؛ نشست/چالش در provider هویت مصوب مدیریت می‌شود و جدول خیالی به SQL اضافه نمی‌شود. |
| تصمیم باز | D11, D12 |
