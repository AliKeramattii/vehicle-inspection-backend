# ذخیره و انتقال خصوصی رسانه

قاعدهٔ قطعی: عکس/ویدیو فایل خصوصی‌اند؛ SQL فقط reference و metadata نگه می‌دارد. `VARBINARY(MAX)` و Base64 برای بایت رسانه ممنوع‌اند. این سند طراحی است؛ هیچ پوشهٔ رسانه یا فایل مشتری ساخته نشده است.

## چیدمان تأییدشدهٔ مالک

```text
PrivateMediaRoot/
  GUI_{CustomerId}/
    INSPECTION_{InspectionId}/
      temporary/
        photos/
        videos/
      finalized/
        photos/
        videos/
```

این ساختار مبنای طراحی است؛ برخلاف متن قدیمی، انتخاب این الگو دیگر سؤال باز محصول نیست. drive/root واقعی، ACL، backup و ظرفیت هنوز باید توسط زیرساخت تأیید شوند. `CustomerId` در مسیر همان GUID داخلی `BAZDIDCustomerLinks.Id` و `InspectionId` شناسهٔ داخلی تلاش است؛ هیچ شماره موبایل، کد معرفی، source ID یا نام شخص وارد مسیر نمی‌شود.

ریشه بیرون webroot، virtual directory و publish directory قرار می‌گیرد و در تنظیمات خصوصی میزبان تعیین می‌شود. SQL فقط مسیر نسبی با separator `/` ذخیره می‌کند؛ مرورگر فقط ID و endpoint مجاز می‌بیند. physical root، RelativePath و نام drive در DTO، Swagger example و log عمومی قرار نمی‌گیرند.

## ایجاد و اعتبارسنجی فایل

سرور پس از owner/status check، upload را رزرو و نام `<UploadId>.part` را با create-new در temporary ایجاد می‌کند. مسیر نهایی از `EvidenceId/RevisionId` تولیدشدهٔ سرور و پسوند برآمده از نوع واقعی فایل ساخته می‌شود. نام و پسوند client فقط اطلاعات غیرقابل‌اعتمادند و استفادهٔ مستقیم نمی‌شوند. شناسه‌ها canonical ASCII محدود هستند.

join مسیر، canonicalization با مسیر کامل و کنترل containment در ریشه با separator درست انجام شود؛ `..`، absolute/UNC، ADS، symlink/reparse point و escapeهای encode شده نباید خروج ایجاد کنند. ریشه و زیرپوشه‌ها فقط تحت کنترل حساب سرویس باشند تا race ناشی از junction کاربر ایجاد نشود. فایل upload هیچ permission اجرایی یا handler IIS نمی‌گیرد.

کنترل‌ها: سقف stream حتی بدون Content-Length، quota هر درخواست/مشتری، timeout و cancellation، signature واقعی در کنار allowlist MIME، decode امن تصویر با سقف ابعاد/تعداد پیکسل، container/codec/duration ویدیو، hash سروری و اندازهٔ واقعی. header MIME به‌تنهایی کافی نیست. SVG/HTML/فایل اجرایی برای evidence پذیرفته نمی‌شود. JPEG/PNG/WebP و MP4/WebM نامزدند؛ پذیرش نهایی codec و ابزار decode اسکن‌شده باید روی دستگاه/سرور واقعی تأیید شود.

مقادیر سقف عکس/ویدیو، مدت، dimensions و retention اکنون بازند؛ مقدار تصادفی به‌عنوان policy Production ثبت نمی‌شود. Checkpoint 6 فقط با پروفایل محدود و مصوب Development/Test شروع می‌شود؛ Production بدون policy صریح fail-closed است. سقف IIS requestFiltering، reverse proxy و Kestrel و application باید همسو باشد؛ body buffering در RAM برای ویدیو توصیه نمی‌شود.

## چرخه و سازگاری SQL/فایل

۱. در SQL، media/version و uploadId، nonce hash، expected bytes/type و lease با idempotency رزرو می‌شوند. `BAZDIDMediaFiles` فعلاً metadata upload session را هم دارد؛ whole-file retry است و resume chunk ادعا نمی‌شود.
۲. stream تحت lease یکتا به temporary نوشته می‌شود. قطع ارتباط، فایل ناقص را قابل ارسال نمی‌کند. retry مجاز با همان uploadId پس از آزادشدن lease، انتقال کامل را دوباره شروع می‌کند؛ concurrent writer رد می‌شود.
۳. complete، طول/hash/type و کنترل‌های امنیتی را اجرا می‌کند، فایل را flush و در همان volume با rename امن و بدون overwrite به finalized منتقل می‌کند. حالت DB مانند `Moving` مقصد نسبی و intent را پیش از حرکت ثبت می‌کند.
۴. پس از موفقیت فایل، SQL در transaction وضعیت `Durable` و رسید نسخه را تثبیت می‌کند. پاسخ `uploaded` فقط پس از commit داده می‌شود. شکست در هر نقطه با reconcile بازیابی می‌شود؛ SQL و filesystem transaction توزیع‌شده ندارند.
۵. فایل نهایی immutable است؛ retry همان upload/hash/size همان رسید را می‌دهد. ناسازگاری hash یا revision همان key برابر `409` است، نه overwrite.

reconciler پایدار و قابل اجرای مجدد، reservation بدون فایل، `.part` متروک، `Moving` با مقصد موجود، فایل نهایی بدون commit و DB با فایل missing را تشخیص می‌دهد. metadata lease/زمان روی SQL است؛ اجرای صرف timer حافظه‌ای در IIS تضمین انجام کار پس از recycle نیست. نسخهٔ اولیه می‌تواند ابزار عملیاتی/Task Scheduler مصوب برای اسکن دوره‌ای داشته باشد؛ اگر worker async لازم شد، job پایدار جدید با پیشوند BAZDID و برنامهٔ روشن تصویب می‌شود.

دریافت باینری با اعتبارسنجی فنی/امنیتی، تأیید کیفیت کارشناس نیست. اسکن امنیتی pending اجازهٔ retrieval/submit نمی‌دهد. پردازش مشتق غیرمسدودکننده می‌تواند جدا `processing` باشد؛ وضعیت upload، scan و review با هم ادغام نمی‌شوند.

## revision و دسترسی

هر جایگاه مدرک، نسخهٔ current و candidate مستقل دارد؛ alternative واقعی در همان نسخه ثبت می‌شود. نسخهٔ پذیرفته‌شده هنگام retry/retake پاک یا relabel نمی‌شود. snapshot ارسال، ID نسخهٔ دقیق و hash را نگه می‌دارد. فایل جدید نام تازه دارد و جای نسخهٔ رسید قبلی نوشته نمی‌شود.

GET فایل از controller مجاز، پس از join مالکیت inspection/evidence/version انجام می‌شود. cookie مشتری برای پروندهٔ دیگر و token upload برای خواندن عمومی کافی نیست. نوع پاسخ، `nosniff`، cache خصوصی/no-store و disposition امن تنظیم شود. Range ویدیو در صورت پیاده‌سازی مجوز را برای هر درخواست دوباره بررسی می‌کند؛ URL عمومی دائمی یا presigned link اختیاری بدون policy نداریم. thumbnail نیز خصوصی است.

## پاک‌سازی، backup و نگهداری

cleanup فقط expired temporary بدون lease/receipt/reference فعال را با بازبینی و audit پاک می‌کند. finalized، original تاریخی، rejected attempt و submission evidence تا retention مصوب و نبود legal hold حذف نمی‌شوند. حذف مجاز با tombstone/intent و reconcile اجرا شود؛ پاک‌کردن فایل بدون ثبت DB یا پاک‌کردن تاریخچه برای خالی‌کردن فضا مجاز نیست.

backup هماهنگ SQL و فایل با manifest و hash نسخه‌های قطعی و key ring لازم است. restore باید به محیط جدا انجام و نمونهٔ receipt→version→file را بررسی کند. RPO/RTO، رمزگذاری volume/backup، retention و اختیار حذف بازند. فضای آزاد، orphanها، خطای خواندن و backup failure پایش شوند. بازیابی برنامه بدون فایل و کلید، بازیابی کامل سامانه نیست.
