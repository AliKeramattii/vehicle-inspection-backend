# مدیریت، قالب و تنظیمات مستقل کارگزاری

منبع فعلی `src/features/admin/repository.ts`، `src/config/site-settings.repository.ts` و schema همان config است. تمام workspace‌های محلی برای demo هستند؛ انتشار بین دستگاه‌ها، SSO و سلامت واقعی Backend نیستند.

## قرارداد و اختیار

| قابلیت | قراردادها | اثر و کنترل |
|---|---|---|
| داشبورد/جست‌وجو/کد پیگیری | I04 و AD01 | شمار واقعی در scope؛ حد صفحه و query پارامتری، بدون حق از روی tracking |
| ارجاع و ظرفیت | RV02/RV03، خواندن AD01 | StaffUsers/ReviewerAssignments/StaffOperationsSettings؛ تراکنش ظرفیت و ارجاع فعال |
| قالب و draft | AD02/AD03 | InspectionTemplates/Requirements/Alternatives؛ editor فقط draft، CAS |
| انتشار/بایگانی | AD04 | فقط مدیر مجاز؛ snapshot منتشرشده ثابت و بازدید قدیمی پین‌شده |
| تنظیمات واحد | AD05/AD06/AD07 و P01 | draft و published با history ونسخه؛ F09 به همین مخزن نگاشت می‌شود |
| تصویر برند | AD08 | BrandingAssets ایمن/عمومی؛ نه صف مدرک خصوصی |
| نقش/فعال‌بودن | AD09 | نگاشت معتبر مبدأ؛ منع ارتقای دلخواه یا اعطای نقش سراسری از مرورگر |
| وب‌هوک | AD10 | فقط شناسه/مقصد whitelist سرور؛ enabled یک event config است |
| سلامت/ذخیره/خطا | AD11 | وضعیت واقعی یا unavailable؛ بدون root، connection string یا راز |

`platform-admin` در نام‌گذاری فعلی مدیر همین سایت است. `template-editor` draft را ویرایش می‌کند، `viewer` فقط مجاز به خواندن است و Reviewer از مجوز تصمیم پرونده ارجاع‌شده استفاده می‌کند. server claim/role mapping مرجع است؛ role در URL یا actor نمونه هیچ اختیاری ندارد.

## قالب فعلی و تاریخچه

نسخه ۲ باید همان هفت بخش، ده عکس ثابت، یک گروه spec-plate با چهار alternative دقیق، odometer-on جدا برای عدد و video360Required=true را نگه دارد. Admin فعلی اجازه حذف requirement، required=false، افزودن ID دلخواه یا تبدیل چهار گزینه به چهار عکس الزامی نمی‌دهد. کنترل server publication باید همین قواعد را enforce کند. reorder مجاز نمایش، معنای فیزیکی سمت‌ها یا ID را عوض نمی‌کند. نسخه منتشرشده و pin بازدیدهای قبلی با ذخیره draft یا انتخاب نسخه جدید تغییر نمی‌کنند.

## تنها provider تنظیمات

SiteSettings شامل identity، theme، images و application عمومی است؛ همان SiteSettingsProvider Frontend مرجع مصرف می‌ماند. draft save به معنی publish نیست؛ reset رنگ‌ها فقط یک تغییر draft است. CAS بر workspace جاری و انتشار immutable انجام شود و conflict ۴۰۹ نسخه تازه را برگرداند. history و reference دارایی‌ها برای rollback سازگار محفوظ‌اند.

theme از schema موجود پیروی می‌کند: primary/secondary/background/neutral/onPrimary/onBackground و accent/haloColor/haloIntensity اختیاری. شدت هاله ۰ تا ۱۰۰ و رنگ hex معتبر، contrast متن حداقل ۴٫۵ و سیاست دارایی slot بررسی شوند. shape تولیدی باید دقیقاً به schema جاری یا adapter نسخه‌دار نگاشت شود؛ هیچ color system جدیدی در این task ایجاد نمی‌شود.

لوگوی پیش‌فرض برنامه با لوگوی اختصاصی کارگزاری فرق دارد. null در identity.logo به fallback پیش‌فرض مصوب می‌رود و بارگذاری لوگوی کارگزاری همان تنظیم runtime را حفظ می‌کند. تصاویر public فقط PNG/WebP/JPEG مجاز و با signature/اندازه/ابعاد تصویب‌شده باشند؛ SVG/HTML دلخواه فعال نپذیرید. تصاویر/مدل خودرو و ghost‌ها evidence مشتری یا brand upload نامحدود نیستند.

Neshan، private key، service endpoint رازدار، auth secret و destination credentials از Admin معمولی قابل ویرایش نیستند. public locationMap می‌تواند به‌صورت projection از پیکربندی مرکزی افزوده شود؛ webMapKey عمومی با service key خصوصی یکی نیست. API base و binding نصب نیز از استقرار trusted می‌آیند، نه یک store رقیب تنظیمات. تنظیمات عمومی no-store و دارایی versioned عمومی cache immutable دارند؛ اطلاعات رسانه خصوصی هرگز به این resource وارد نمی‌شود.

عملیات سلامت باید زمان checkedAt و خطای امن واقعی داشته باشد. داده نمونه ثابت یا استثنای network نباید healthy دیده شود. تغییر retention/root/permission زیرساخت از UI فعلی مجاز فرض نشود؛ تنها خلاصه غیرمحرمانه خوانده شود تا قرارداد مجاز تغییر جداگانه تصویب گردد.
