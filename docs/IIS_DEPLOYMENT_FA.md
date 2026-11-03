# طرح استقرار IIS و PathBase

آخرین بررسی `2026-11-03`: [P0 مهاجرت .NET10](implementation/CHECKPOINT-02F-P0-MIGRATION-FEASIBILITY_FA.md) فقط hosting محلی و PathBase شبیه‌سازی‌شده را آزمود. پیشنهاد Generic Host با حفظ Startup/OutOfProcess و الزامات OS/Hosting Bundle/rollback در آن آمده است؛ canonical همچنان2.1 و نصب/استقرار/IIS واقعی مجاز یا اجرا نشده‌اند. حداقل‌های legacy پایین این سند برای .NET10 قابل تعمیم نیستند؛ Server2012/2012R2 در ماتریس .NET10 شرط ESU دارند.

وضعیت: **در Checkpoint 1، artifact محلی publish و template ساخته شده؛ هیچ IIS، سرور یا برنامهٔ کارگزاری تغییر نکرده است.** راهنمای اجرایی و دستورهای واقعی در [deployment/iis](../deployment/iis/README.md) هستند. PathBase در Kestrel واقعی و metadata شبیه‌سازی‌شدهٔ IIS آزموده شده؛ ANCM واقعی هنوز آزموده نشده است. دامنه‌های مثال تنظیمات واقعی نیستند.

## Application مستقل و مدل hosting

Backend یک **IIS Application** در سایت موجود با مسیر کامل `/API/BAZDID` است، نه virtual directory ساده. اگر `/API` از قبل Application باشد، BAZDID به‌عنوان child application با isolation و بررسی inheritance تعریف شود؛ اگر فقط بخشی از مسیر سایت باشد، زیرساخت hierarchy لازم را طوری بسازد که effective application path همان `/API/BAZDID` باشد. routing برنامهٔ اصلی یا source آن تغییر نمی‌کند؛ handler/rewriteهای ارثی باید در staging بررسی شوند.

pool پیشنهادی اختصاصی `BAZDID` با identity مستقل، `No Managed Code`، bitness سازگار x64، pipeline مناسب و مجوز کمینه است. ASP.NET Core 2.1 با ANCM به Kestrel **out-of-process** وصل می‌شود؛ پورت داخلی فقط loopback و دسترسی مستقیم شبکه بسته است. in-process در baseline 2.1 استفاده نمی‌شود. [سند رسمی IIS](https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/iis/?view=aspnetcore-2.1)، [اعلام رسمی محدودیت in-process در 2.1](https://github.com/aspnet/Announcements/issues/302).

انتخاب ANCM/handler براساس نسخهٔ نصب‌شده و publish سازگار است؛ `AspNetCoreModuleV2` یا تنظیم inprocess از نمونه‌های جدید بی‌بررسی کپی نشود. `web.config` واقعی پس از publish در Checkpoint 1 تولید و در staging بازبینی می‌شود. handler تکراری، inheritance از parent و `500.19` باید با تنظیم محدود به همین Application رفع شوند؛ config سراسری سایت بدون مجوز تغییر نمی‌کند.

## پیش‌نیاز ابزار و سرور

ساخت روی محیط دارای SDK `2.1.818`؛ اجرای framework-dependent روی `Microsoft.NETCore.App` و `Microsoft.AspNetCore.App 2.1.30`. روی IIS، Runtime به‌تنهایی کافی نیست و ANCM سازگار لازم است. Hosting Bundle تاریخی `2.1.30` مرجع baseline است؛ نسخهٔ ANCM درج‌شده در صفحهٔ آن `12.1.21225.30` است. [نسخه‌های رسمی](https://dotnet.microsoft.com/en-us/download/dotnet/2.1).

وجود Runtime محلی تأیید شد، ولی Hosting Bundle محلی احراز نشد؛ فایل‌های متداول ANCM و `appcmd.exe` یافت نشدند. این وضعیت دربارهٔ سرور مقصد چیزی اثبات نمی‌کند. نسخهٔ Windows Server، IIS، ANCM، runtime x64/x86 و وضعیت وصله‌ها باید inventory شوند. OSهای جدید با runtime EOL صرفاً به دلیل اجراشدن، در وضعیت پشتیبانی قرار نمی‌گیرند.

نصب/repair یا downgrade Hosting Bundle می‌تواند برنامه‌های هم‌میزبان را متأثر کند؛ نصب خودکار انجام نشود. زیرساخت، نسخهٔ سازگار و اثر آن بر برنامه‌های موجود را در staging آزموده و برای تغییر میزبان تأیید بگیرد. self-contained publish نیز محدودیت امنیت و نیاز ANCM را حذف نمی‌کند؛ نوع انتشار نهایی پس از این بررسی تثبیت شود.

## جلوگیری از prefix تکراری

| لایه | مقدار نمونهٔ منطقی |
|---|---|
| URL عمومی | `https://<backend-host>/API/BAZDID/inspections/current` |
| `Request.PathBase` در IIS integration | `/API/BAZDID` |
| `Request.Path` در برنامه | `/inspections/current` |
| route کنترلر | `inspections/current` |
| URL فایل Swagger | `/API/BAZDID/swagger/v1/swagger.json` |

`WebHost.CreateDefaultBuilder` و IIS integration سازگار metadata path را دریافت می‌کنند؛ مقدار واقعی در smoke test مشاهده شود. روی IIS بار دیگر `UsePathBase("/API/BAZDID")` یا همان prefix روی همهٔ controllerها اعمال نشود. پشت proxy یا Kestrel توسعه، فقط یکی از راه‌های زیر فعال است: proxy با حفظ prefix و `UsePathBase` یک‌بار، یا تنظیم معتبر PathBase برای proxy که prefix را حذف می‌کند. این گزینه‌ها با حالت IIS هم‌زمان اعمال نمی‌شوند و header دلخواه مرورگر منبع PathBase نیست.

دسترسی root برنامه در توسعه باید با base تنظیم‌شده آزمایش شود؛ پذیرفتن اتفاقی مسیر بدون prefix در Production، قرارداد عمومی جدید نمی‌سازد. URLهای برگشتی، `Location`، file link، cookie Path و logout همگی با PathBase ساخته شوند. تنظیم frontend apiBase یک‌بار join می‌شود؛ هیچ lowercase `/api` تاریخی به `/API/BAZDID` اضافه نمی‌شود.

Swagger UI از URL نسبی نسبت به محل UI استفاده کند؛ network browser باید نشان دهد JSON از زیر Application بار می‌شود. در Swagger 2.0، `basePath` و در صورت لزوم host/schemes از تنظیم معتبر/درخواست trusted و نه header مهاجم تولید شود. alias مسیر دوبرابر ساخته نشود؛ `/API/BAZDID/API/BAZDID/...` باید 404 شود.

## ترتیب pipeline پیشنهادی 2.1

IIS integration و forwarded-header اعتمادشده → تنظیم PathBase فقط در حالت غیر-IIS مصوب → correlation و exception handling امن → HTTPS/HSTS طبق محیط → CORS → cookie policy → authentication → rate/authorization/antiforgery با طراحی مناسب endpoint → MVC (`UseMvc`). در 2.1 از الگوی Endpoint Routing نسخه‌های جدید استفاده نشود. CORS باید preflight را پیش از challenge احراز ببیند؛ CSRF mutationها با filter/validator سروری اعمال شود.

## TLS، مرورگر و اعتماد به header

پیاده‌سازی فعلی، در Production به HTTPS redirect نیاز دارد. HSTS با `Bazdid:HstsEnabled` به‌طور پیش‌فرض false است و فقط در Production و پس از هماهنگی policy کل host فعال می‌شود؛ روشن/خاموش‌بودن آن آزمون دارد. CORS فعلی فقط read-only و بدون credential است؛ بخش cookie/CSRF زیر طرح مراحل احراز هویت آینده است و اکنون فعال نشده است. Swagger در Production همواره غیرفعال است.

Backend و Frontend فقط HTTPS با گواهی معتبر و TLS policy مصوب میزبان باشند. redirect یا HSTS سراسری سایت که برنامه‌های دیگر را تحت تأثیر می‌گذارد بدون هماهنگی تغییر نکند. پشت proxy تنها proxyهای مشخص در `KnownProxies/KnownNetworks` قابل اعتمادند؛ `X-Forwarded-For/Proto/Host` از اینترنت پذیرفته نشوند. AllowedHosts و origin نصب از تنظیم trusted هستند.

CORS: فقط origin دقیق Frontend شامل scheme/host/port، `AllowCredentials` و method/headerهای لازم؛ `*` با credential ممنوع است. `OPTIONS` برای origin مجاز پاسخ می‌گیرد؛ origin ناشناس header مجوز نمی‌گیرد. `Vary: Origin` و `no-store` برای پاسخ‌های حساس بررسی شوند. دامنهٔ مثال `bazdid.example.com` در source hardcode نمی‌شود. کوکی host-only با Path اختصاصی و CSRF طبق [AUTH_AND_SESSION_FA.md](AUTH_AND_SESSION_FA.md) است.

## ACL و جداسازی فایل

| محل | اختیار حساب pool |
|---|---|
| publish directory | خواندن/اجرای لازم؛ بدون نوشتن عمومی |
| PrivateMediaRoot | create/read/write کنترل‌شده؛ بدون handler اجرا یا public mapping |
| key ring و گواهی | فقط خواندن/نوشتن لازم حساب‌های مجاز؛ حفاظت at-rest |
| log directory | نوشتن محدود و rotation؛ عدم exposure وب |
| SQL | SELECT روی مبدأ مصوب و DML اشیای BAZDID؛ بدون DDL/db_owner |

storage و key ring از release جدا هستند و recycle/rollback آن‌ها را حذف نمی‌کند. در چند instance، filesystem مشترک مصوب یا storage adapter معادل و key ring مشترک و SQL session store لازم است. sticky session جای persistence نیست. تفاوت UNC/identity و ACL باید عملی تست شود.

## روش انتشار آینده و پذیرش

artifact نسخه‌دار و بازبینی‌شده خارج از ریشهٔ رسانه منتشر شود؛ توقف کنترل‌شدهٔ همین app و `app_offline.htm` در صورت روش مصوب، rollback artifact و migration سازگار پیش‌بینی شوند. کل سایت اصلی recycle نشود. stdout فقط برای تشخیص کوتاه‌مدت با ACL/rotation و بدون راز، سپس خاموش؛ debug و Swagger عمومی در Production فعال نمانند.

smoke test: health زیر prefix، 401 JSON، preflight مجاز/غیرمجاز، cookie/CSRF، لینک Swagger، عدم prefix دوبل، direct Kestrel ممنوع، upload limit در تمام لایه‌ها، private file 403/404، Range مجاز، restart و دو instance، restore و عدم اخلال برنامهٔ موجود. دسترسی واقعی سرور و policy EOL هنوز مانع انتشار Production است؛ ساخت برنامه به‌تنهایی این پذیرش را نمی‌بندد.
