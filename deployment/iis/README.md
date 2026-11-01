# انتشار محلی/آزمایشی IIS برای Checkpoint 1

این راهنما هیچ برنامه‌ای را deploy نمی‌کند. فقط artifact محلی و template تولید شده‌اند؛ نصب Hosting Bundle و دسترسی IIS واقعی در این وظیفه انجام نشده است. تا تأیید امنیت، انتشار عمومی پشتهٔ EOL ممنوع است.

## ساخت artifact با ابزار موجود

از ریشهٔ Backend، با SDK انتخاب‌شده توسط `global.json`:

```powershell
dotnet --version
dotnet restore Bazdid.sln --locked-mode
dotnet build Bazdid.sln --configuration Release --no-restore
dotnet test Bazdid.sln --configuration Release --no-build --no-restore
dotnet publish src/Bazdid.Api/Bazdid.Api.csproj --configuration Release --no-build --no-restore --output ../../artifacts/publish
```

این دستورها واقعاً اجرا شده‌اند؛ مقصد نهایی `C:\Projects\vehicle-inspection-backend\artifacts\publish` است. انتشار framework-dependent و نیازمند `Microsoft.AspNetCore.App 2.1.30` و `Microsoft.NETCore.App 2.1.30` x64 است. SDK روی سرور اجرا لازم نیست. checksum artifact و نسخهٔ release در عملیات staging ثبت شوند؛ فایل‌های bin/obj یا repo کامل deploy نشوند.

## پیش‌نیاز میزبان و نصب Application

۱. تیم زیرساخت نسخهٔ Windows Server/IIS و runtime/ANCM را inventory و سازگاری را در staging تأیید کند. وجود Runtime به معنی وجود Hosting Bundle نیست. baseline تاریخی، Hosting Bundle `2.1.30` است؛ نصب/repair آن بدون مجوز انجام نشود و اثر آن بر برنامه‌های هم‌میزبان ارزیابی شود.
۲. pool اختصاصی با identity مستقل، `No Managed Code` و bitness x64 بسازید. مسیر release فقط خواندنی/اجرایی برای pool باشد. مجوز نوشتن به source یا کل سایت ندهید. در Checkpoint 1 هیچ media root یا اختیار SQL لازم نیست.
۳. در سایت موجود، Application واقعی با effective path دقیق `/API/BAZDID` اضافه کنید؛ virtual directory تنها کافی نیست. وضعیت parent `/API` و inheritance آن را بررسی کنید. سورس Backend اصلی لازم نیست و config سراسری آن تغییر نمی‌کند.
۴. physical path به artifact release اشاره کند. `web.config` **واقعی تولیدشده توسط publish** مبناست. نمونهٔ همراه برای راهنمای env است، نه جایگزین بررسی host.

publish با SDK 2.1 در این محیط handler با نام module برابر `AspNetCoreModule` و process برابر `dotnet .\Bazdid.Api.dll` تولید کرد؛ درون‌پردازه‌ای نیست. [web.config.example](web.config.example) از همان شکل مشتق شده است. اگر میزبان فقط `AspNetCoreModuleV2` دارد، زیرساخت handler سازگار out-of-process را در staging انتخاب و تست کند؛ تغییر به in-process برای 2.1 توصیه نمی‌شود. handler تکراری یا ارث‌رسیده را بدون بررسی parent حذف نکنید.

## تنظیمات میزبان بدون راز در مخزن

| کلید محیط/تنظیم | مقدار یا اقدام |
|---|---|
| `ASPNETCORE_ENVIRONMENT` | `Production`؛ برای staging ایزوله که Swagger لازم دارد `Testing`، بدون راز/دادهٔ Production |
| `Bazdid__HostingMode` | `Iis`؛ metadata واقعی PathBase باید `/API/BAZDID` باشد |
| `Bazdid__ApiBasePath` | `/API/BAZDID`، بدون slash انتهایی؛ مقدار قطعی پروژه |
| `AllowedHosts` | host واقعی مصوب، بدون scheme/path؛ default فقط loopback است |
| `Bazdid__TrustedFrontendOrigins__0` | origin دقیق واقعی HTTPS، بدون slash انتهایی؛ در صورت نبود نیاز خالی بماند |
| `Bazdid__HttpsRedirectionEnabled` | `true` در Production؛ scheme اصلی باید از IIS integration معتبر بیاید |
| `Bazdid__HttpsPort` | پورت HTTPS واقعی، پیش‌فرض 443؛ binding و گواهی معتبر در IIS |
| `Bazdid__HstsEnabled` | پیش‌فرض false؛ چون روی کل host اثر دارد، فقط پس از هماهنگی policy سایت مشترک true شود |
| `Bazdid__SwaggerEnabled` | Production همواره خاموش است؛ در Development/Testing با true قابل مشاهده |
| `Bazdid__BrokerageAdapterMode` | فقط `Disabled` در این checkpoint؛ مقدار دیگر startup را رد می‌کند |
| `Authentication__Enabled` | false؛ احراز هویت هنوز وجود ندارد و true startup را رد می‌کند |

نمونهٔ `appsettings.Production.example.json` فقط توضیحی است و publish نمی‌شود. تنظیم واقعی با environment حفاظت‌شدهٔ pool یا فایل محلی ACLدار خارج Git انجام شود. SQL، MediaStorage، Session و secret references فعلاً جای رزرو تنظیمات‌اند و هیچ اتصال یا عملیات ایجاد نمی‌کنند. ورود cookie/CSRF هنوز پیاده نیست؛ CORS فعلی فقط GET/HEAD/OPTIONS بدون credential است.

## مالک prefix و URLها

در `Standalone`، برنامه prefix ورودی را یک‌بار با `UsePathBase` جدا می‌کند. در `Iis`، این کار را **IIS integration** انجام می‌دهد و برنامه دوباره آن را جدا نمی‌کند. route کنترلر فقط `health/live` است. PathBase غلط یا prefix دوبرابر 404 JSON می‌دهد؛ header دلخواه `X-Forwarded-Prefix` استفاده نمی‌شود.

روی host واقعی مصوب:

```text
https://<backend-host>/API/BAZDID/health/live
https://<backend-host>/API/BAZDID/swagger/index.html       # فقط Development/Testing
https://<backend-host>/API/BAZDID/swagger/v1/swagger.json   # فقط Development/Testing
```

در Production هر سه مسیر Swagger شامل فایل JS، پاسخ 404 دارند؛ liveness فقط `{"status":"alive"}` برمی‌گرداند و نشانهٔ SQL/SMS/media readiness نیست. UI از `v1/swagger.json` نسبی استفاده می‌کند؛ JSON دارای `basePath=/API/BAZDID` و فقط مسیر `/health/live` است. queryهای Swagger، از جمله `url/configUrl`، رد می‌شوند.

## تشخیص startup و rollback

- `500.19`: inheritance، handler/module نصب‌شده و valid بودن web.config را بررسی کنید؛ کل سایت اصلی را برای آزمون تغییر ندهید.
- شکست process/startup یا `502.5`: runtime دقیق، bitness، module، ACL فایل DLL و خطای تنظیمات را بررسی کنید. ابتدا همان artifact را از console روی loopback با محیط مناسب اجرا کنید.
- `400` host: `AllowedHosts` را با hostname واقعی مقایسه کنید. wildcard وسیع برای رفع خطا نگذارید.
- `404` health: حالت Iis/Standalone، effective application path و PathBase را بررسی کنید؛ افزودن prefix به Controller راه‌حل نیست.
- redirect loop: scheme/HTTPS binding و proxy trusted را بررسی کنید؛ header اینترنتی را برای رفع مشکل trusted نکنید.
- Swagger 404 در Production رفتار صحیح است؛ برای نمایش عمومی فعال نشود.

log برنامه فقط correlation/status/duration، نوع خطای امن و startup غیرحساس را ثبت می‌کند؛ body/query/cookie/OTP/credential/PII ثبت نمی‌شود. stdout پیش‌فرض false است؛ فقط در تشخیص کوتاه‌مدت و پوشهٔ ACLدار و قابل rotation فعال شود. Event Log و خروجی تشخیص ممکن است دادهٔ حساس داشته باشند و عمومی نشوند.

قبل از تغییر release، backup و rollback artifact همین app آماده شود؛ `app_offline.htm` یا توقف کنترل‌شده فقط برای همین Application به‌کار رود. هیچ تغییر DB وجود ندارد. restart کل سایت کارگزاری لازم نیست. smoke staging باید health، 404 دوبرابر، CORS، TLS/host و عدم اخلال برنامه‌های موجود را بررسی کند. آزمون TestServer با metadata شبیه‌سازی‌شده، جای پذیرش واقعی ANCM نیست.
