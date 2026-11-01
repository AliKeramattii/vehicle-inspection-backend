# میزبانی static و الزامات سرور

## هدف و وضعیت اثبات‌شده

هدف: Frontend فایل static روی subdomain هر کارگزاری، ASP.NET Core مستقل، SQL Server مستقل و filesystem خصوصی همان نصب؛ بدون الزام Node تولیدی. نمونه نام‌ها صرفاً توضیحی‌اند: `https://bazdid.example.invalid` و Backend با پایه‌ای مانند `/api/bazdid`. دامنه/پایه نهایی باید با زیرساخت توافق شود.

**Static Export کل برنامه هنوز مسدود است.** نسخه نصب‌شده پروژه 16.3.8 است. probe قبلی پس از compile/typecheck روی `/inspection/[inspectionId]/location` به علت نبود generateStaticParams در `output: export` با exit1 شکست خورده و config‌ها byte-for-byte برگردانده شده‌اند. ساخت معمول Next موفق، بسته static نیست. این task probe یا مهاجرت مسیرها را تکرار نمی‌کند.

پیشنهاد قبلی منتظر تصویب، صفحات workflow محدود قابل export با context runtime اعتبارسنجی‌شده در query و سازگاری لینک‌های قبلی است؛ گزینه SPA/router واقعی نیز باید با کد بررسی شود. fallback ساده IIS، route/RSC ناموجود Next را خلق نمی‌کند. generateStaticParams فقط برای demo IDs راه‌حل شناسه دلخواه تولید نیست. [راهنمای رسمی static export](https://nextjs.org/docs/app/guides/static-exports) محدودیت‌ها را بیان می‌کند؛ مستند نصب‌شده نسخه پروژه و تست واقعی مبنای پذیرش‌اند، نه فرض درباره جدیدترین نسخه سایت.

## تحویل لازم از تیم زیرساخت

| موضوع | معیار |
|---|---|
| routing | strategy مصوب برای runtime inspection/request/case IDs، deep link، refresh، back/forward، unknown404 و legacy URLs |
| image | تصمیم unoptimized/custom static loader/derivative؛ default optimizer فعلی نیاز به بررسی Node-free دارد |
| dev handlers | API توسعه مدل و rewrite/proxy نشان از بسته release حذف شوند؛ proxy Node محلی deploy نشود |
| hosting | HTML/JS/CSS/font/WebP/GLB با MIME درست؛ فایل مفقود یا API نباید HTML ۲۰۰ بگیرد |
| HTTPS/auth | origin/callback/cookie/gateway و CSRF/CORS مصوب؛ connection/secret از استقرار trusted |
| limits | IIS/reverse proxy/Kestrel/stream timeout و request/body/quota همسو با سیاست فایل؛ مقدار نهایی مصوب |
| cache | bootstrap/settings/session/status/private media بدون cache عمومی؛ دارایی hash‌شده عمومی immutable |
| CSP | محدودیت واقعی script/connect/img/media/worker و WebAssembly اختیاری؛ نه wildcard وسیع برای حل خطا |
| SQL/files | migration مالکیت‌شده، ACL کمینه، disk monitoring، lease worker، backup/restore و retention hold |
| rollout | انتشار اتمیک و rollback سازگار قرارداد/قالب؛ نگهداری chunk‌های قبلی برای tab‌های باز؛ بدون rewind evidence |

GLB به‌طور جدا از Python static host با MIME و hash و decode و refresh بررسی شده است؛ این فقط قابلیت تحویل یک دارایی را ثابت می‌کند. active sedan14.2MB است و opt-in می‌ماند. attribution CC BY4 و gate حقوق طرح بدنه حفظ است؛ مدل به media root بازدیدها یا SQL نمی‌رود و old restricted Sportage نباید بسته‌بندی شود.

IndexedDB و صف durable به معنای offline cold launch/PWA نصب‌پذیر کامل نیستند؛ Serwist نصب شده ولی راهبرد ثبت/به‌روزرسانی سرویس‌ورکر و offline shell هنوز پذیرش جدا می‌خواهد. API/auth/private media نباید ناخواسته precache شوند. هیچ background sync تضمین‌شده‌ای برای موفقیت upload/submission فرض نشود.

## پذیرش میزبانی

روی host واقعی، لینک مستقیم ID تصادفی، refresh، دو tenant، جلسه منقضی، برند runtime، فونت محلی، map مرکزی، مجوز دوربین/ویدیو، Range، storage quota و off/on network آزمایش شوند. default ۲D نباید مدل دانلود کند. private key/root در artifact جست‌وجو و خطای API، 404 دارایی و cache policy بررسی شود. تا انجام این موارد، API readiness، frontend completion، static readiness و production clearance چهار milestone جدا هستند.
