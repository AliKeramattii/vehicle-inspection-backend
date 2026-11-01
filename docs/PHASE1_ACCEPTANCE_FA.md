# معیار پذیرش Phase 1 مشتری

این چک‌لیست برای **آینده** است؛ هیچ مورد اجرایی اکنون انجام‌شده اعلام نمی‌شود. Phase 1 فقط پس از مجوز صریح آغاز خواهد شد. نگاشت milestoneها در [PLAN.md](../PLAN.md) است.

## بنیاد و داده

- [ ] برنامه واقعاً با `netcoreapp2.1` و SDK/dependencyهای pinشده build و اجرا شده و نتیجه ثبت است.
- [ ] health، خطای JSON و Swagger همان implementation زیر `/API/BAZDID/` کار می‌کنند؛ مسیر دوبرابر پذیرفته نمی‌شود.
- [ ] SQL تست مصوب است؛ همهٔ جدول‌های تازه پیشوند BAZDID دارند و هیچ شیء مبدأ تغییر نکرده است.
- [ ] reader با fixture کامل/ناقص/صفر و دو درخواست یک مشتری کار می‌کند؛ schema واقعی حدس زده نشده است.
- [ ] accountها اختیار کمینه دارند؛ scriptهای تست بازبینی و restore بررسی شده‌اند.

## ورود و نشست

- [ ] `A4K9P2` و `12345` فقط در محیط fixture مجازند؛ هیچ SMS واقعی ارسال نمی‌شود.
- [ ] Production با mock/flag تست fail-closed و کد ثابت هیچ مسیر bypass ندارد.
- [ ] شماره از منبع trusted می‌آید، پیش از verify masked است و payload مشتری آن را عوض نمی‌کند.
- [ ] expiry/attempt/resend/rate مشترک/replay و دو verify هم‌زمان آزموده شده‌اند.
- [ ] نشست به request/customer/mobile/auth time/server ID/expiry/scope متصل و در restart/چند instance طبق دامنهٔ استقرار پایدار است.
- [ ] cookie/CSRF/CORS و خروج/ابطال واقعی در مرورگر آزمایش شده‌اند؛ OTP/secret/session token در log یا JSON عمومی نیست.
- [ ] HMAC نسخه‌دار، normalization، rotation و حفظ source IDs پیاده شده‌اند؛ hash مجوز دسترسی ایجاد نمی‌کند.

## اطلاعات و بازدید

- [ ] پاسخ، منشأ و وضعیت/قفل هر فیلد را نشان می‌دهد؛ trusted در Backend غیرقابل‌تغییر است.
- [ ] فقط missingهای مجاز با ورودی معتبر Manual ذخیره و در `BAZDIDInfo` مستقل از Session باقی می‌مانند.
- [ ] zero mapping فیلدی است، کیلومتر صفر معتبر و InvalidSource بی‌صدا manual نمی‌شود.
- [ ] create/resume/current اتمیک، owner محدود به درخواست نشست و stale version برابر conflict است.
- [ ] consent/version، موقعیت معتبر و accuracy nullable، تأیید اطلاعات و کیلومتر ذخیره می‌شوند.
- [ ] دادهٔ ناقص به placeholder ساختگی تبدیل نشده و نیاز اصلاح فرم Frontend در قرارداد تحویل مشخص است.

## مدرک و فایل

- [ ] هر ده عکس ثابت و دقیقاً یک `spec-plate` از چهار alternative لازم است؛ engine-bay مستقل کنترل می‌شود.
- [ ] یک video-360 اجباری و کیلومتر عددی مستقل کنترل می‌شوند؛ شمار صرف فایل ملاک نیست.
- [ ] قالب v1 دوازده‌عکسی و metadata/نسخهٔ تاریخی حفظ می‌شوند.
- [ ] فایل‌ها فقط ساختار خصوصی `GUI_.../INSPECTION_.../temporary|finalized/photos|videos` دارند؛ SQL فقط metadata است.
- [ ] MIME/signature/size/codec و حد stream مطابق policy مصوب تست شده؛ traversal و public mapping بسته‌اند.
- [ ] retry، revision، crash/reconcile، فایل missing، lease و عدم overwrite آزموده شده‌اند.
- [ ] receipt فقط بعد از durable file و commit SQL داده می‌شود؛ retrieval و thumbnail/Range مالکیت را رعایت می‌کنند.

## ارسال و تحویل توسعه

- [ ] summary از دادهٔ سرور، پیش‌نیازهای معتبر و receipt نسخه‌های دقیق نتیجه می‌گیرد.
- [ ] submit با CAS و idempotency، snapshot+receipt+history+audit را اتمیک می‌سازد و پس از آن داده قفل است.
- [ ] retry همان فرمان همان receipt، payload متفاوت conflict و status فقط وضعیت واقعاً انجام‌شده را می‌دهد.
- [ ] tracking/receipt دسترسی عمومی ایجاد نمی‌کند؛ ورود مجدد همان پرونده را بازیابی می‌کند.
- [ ] HTTPS staging، Swagger UI/JSON واقعی، DTO/خطا، fixture محدود و راهنمای adapter به Frontend تحویل شده‌اند.
- [ ] هیچ قابلیت Admin/Reviewer/forwarding پیاده‌نشده به‌عنوان موفق نمایش داده نمی‌شود.

## شرط جداگانهٔ Production

- [ ] mapping واقعی، SMS کارگزاری، domain، server/Hosting Bundle، root/ACL و secret manager تصویب و آزموده شده‌اند.
- [ ] TTL/rate/limits/retention، backup/restore و مسئول عملیات روشن‌اند.
- [ ] risk review پشتهٔ EOL و پذیرش امنیتی صریح همراه طرح مهاجرت ثبت شده است.
- [ ] اجازهٔ تغییر SQL/IIS و انتشار واقعی جداگانه صادر شده است.

پذیرش مشتری در staging، تصویب عمومی Production یا کامل‌بودن فرآیند Reviewer و تحویل کارگزاری نیست؛ وضعیت هرکدام مستقل گزارش می‌شود.
