# گزارش پیاده‌سازی Checkpoint 1

تاریخ `2026-11-01`، مخزن `C:\Projects\vehicle-inspection-backend`. درخواست پیوست `9a55d0f7-876a-466b-b0d7-355974f22b9d` صریحاً فقط Checkpoint 1 را مجاز کرد. HEAD آغاز کار `1029465` و worktree پاک بود؛ تاریخچهٔ Phase 0 حفظ شد.

**نتیجه: foundation ساخته، build، run، test و محلی publish شد؛ Checkpoint 2 شروع نشده است.** هیچ جدول SQL، OTP، session عملیاتی، upload، تغییر Frontend یا استقرار کارگزاری انجام نشده است.

## ساختار و فایل‌های اجرایی

```text
Bazdid.sln
global.json                         # SDK 2.1.818
Directory.Build.props               # C# 7.3، Runtime 2.1.30 و lockfile
NuGet.Config                        # فقط feed رسمی
src/Bazdid.Api/
  Bazdid.Api.csproj
  Program.cs                        # WebHost.CreateDefaultBuilder
  Startup.cs                        # DI، MVC 2.1 و pipeline
  Configuration/FoundationOptions.cs
  Contracts/ApiError.cs
  Contracts/LivenessResponse.cs
  Controllers/HealthController.cs
  Middleware/CorrelationMiddleware.cs
  Middleware/ExceptionMiddleware.cs
  Middleware/JsonErrorWriter.cs
  appsettings.json
  appsettings.Development.json
  appsettings.Testing.json
  appsettings.Production.example.json
  packages.lock.json
  Application/README.md
  Domain/README.md
  Infrastructure/README.md
tests/Bazdid.UnitTests/              # csproj، lock و FoundationOptionsTests
tests/Bazdid.IntegrationTests/       # csproj، lock و FoundationHttpTests
database/README.md                   # بدون DDL یا migration
deployment/iis/                     # راهنمای اجرا و web.config.example
docs/checkpoint1/
  DEPENDENCY_SECURITY_FA.md
  PACKAGE_AUDIT.json
  HTTP_SMOKE.json
```

اجزای آینده مانند reader مبدأ و SQL repository، authentication، session store، domain بازدید و media storage ساخته نشده‌اند. پوشه‌های لایه‌ها با توضیح فارسی حفظ شده‌اند تا پیاده‌سازی صوری زودهنگام ایجاد نشود. یک deployable و دو test project داریم.

## ابزار و بسته‌های واقعی

`dotnet --list-sdks` و `--list-runtimes` دوباره اجرا شدند؛ SDK `2.1.818` و Runtimeهای `Microsoft.AspNetCore.App 2.1.30` و `Microsoft.NETCore.App 2.1.30` موجودند. پس از global.json، `dotnet --version` برابر `2.1.818` بود. فایل runtimeconfig ساخته‌شده، `netcoreapp2.1` و framework `Microsoft.AspNetCore.App 2.1.30` را نشان می‌دهد. MSBuild واقعی نسخهٔ `16.2.37902+b5aaefc9f` گزارش کرد.

نسخه‌های مستقیم: `Microsoft.AspNetCore.App 2.1.30`، `Newtonsoft.Json 13.0.4` و `Swashbuckle.AspNetCore 4.0.1`. تست: `Microsoft.NET.Test.Sdk 15.9.0`، `xunit 2.4.1`، `xunit.runner.visualstudio 2.4.1` و `Microsoft.AspNetCore.TestHost 2.1.1`. گراف کامل و content hash در سه lockfile ثبت‌اند. هیچ SDK/Runtime/Hosting Bundle نصب نشده است.

## رفتار پیاده‌شده

- **configuration:** فایل پایه و overrideهای Development/Testing، گزینهٔ typed زیر `Bazdid`، دریافت environment، validation startup برای محیط، base، mode، origin، port و غیرفعال‌بودن adapter/auth. SQL/media/HMAC/session کلیدهای رزروشده‌اند و برای startup خدمات آینده لازم نیستند.
- **route:** کنترلر فقط `health/live` دارد. Standalone یک‌بار prefix را جدا می‌کند؛ Iis از PathBase معتبر IIS integration استفاده می‌کند. مقدار ناقص/دوبرابر 404 می‌دهد.
- **JSON و خطا:** camelCase، UTC و عمق محدود؛ liveness کوچک؛ خطای 404/500 با `code/message/correlationId`، بدون stack یا پیام داخلی. خطای بعد از شروع response، connection را abort می‌کند؛ response نیمه‌کاره به JSON موفق تبدیل نمی‌شود.
- **logging:** شناسهٔ correlation تازهٔ سروری، header متناظر، status/duration و startup غیرحساس. body/query/cookie/OTP/secret/PII و پیام یا stack exception ثبت نمی‌شوند. request correlation دلخواه client trusted نیست.
- **HTTP:** HTTPS redirect در Production، HSTS فقط opt-in محیط Production با تأیید policy host، `nosniff` و no-store پاسخ‌های health/error. CORS با origin دقیق و فقط GET/HEAD/OPTIONS، فعلاً بدون credentials.
- **Swagger:** UI و JSON واقعی Swagger 2.0 فقط در Development/Testing و با flag؛ Production همواره بسته. XML توضیح endpoint/response دارد؛ document فقط health و basePath درست دارد. queryهای remote definition رد می‌شوند؛ نسخه‌های آیندهٔ API هنوز نمایش داده نمی‌شوند.

## فرمان‌ها و نتیجهٔ واقعی

تمام دستورهای زیر از ریشهٔ مخزن با SDK pinشده اجرا شدند. `--verbosity minimal/quiet` فقط حجم خروجی را کم کرد، شکست‌ها suppress نشدند.

| اجرا | نتیجه/exit code |
|---|---|
| `dotnet --version` | `2.1.818`، صفر |
| `dotnet restore Bazdid.sln --verbosity minimal` | هر سه project موفق، صفر |
| `dotnet restore Bazdid.sln --locked-mode --verbosity minimal` | هر سه project از lock، صفر |
| `dotnet build Bazdid.sln --configuration Release --no-restore --verbosity minimal` | موفق، **۰ warning و ۰ error**، صفر |
| `dotnet test Bazdid.sln --configuration Release --no-build --no-restore --verbosity quiet` | **۴۳ موفق، ۰ شکست و ۰ skipped**، صفر |
| `dotnet publish src/Bazdid.Api/Bazdid.Api.csproj --configuration Release --no-build --no-restore --output ../../artifacts/publish` | artifact محلی framework-dependent و web.config، صفر |
| audit خواندنی SDK 10 با `--no-restore` | اجرا موفق و خروجی ذخیره‌شده؛ **یافتهٔ امنیتی دارد**، exit صفر به معنی clean نیست |

زمان گزارش‌شدهٔ آخرین تست‌ها تقریباً ۱٫۱۹ ثانیه برای واحد و ۲٫۰۲ ثانیه برای integration بود. VSTest از SDK، نسخهٔ `16.2.0-preview-20190606-02` را نشان داد؛ نسخهٔ PackageReference تست با نسخهٔ runner SDK یکسان فرض نشده است. تست‌ها روی هدف 2.1 اجرا شدند.

فرمان دقیق startup آزموده‌شده:

```powershell
$env:ASPNETCORE_ENVIRONMENT = 'Development'
dotnet run --project src/Bazdid.Api/Bazdid.Api.csproj --configuration Release --no-build -- --urls http://127.0.0.1:5081
```

Kestrel پیام `Now listening on: http://127.0.0.1:5081` و content root پروژهٔ API را گزارش کرد. اجرای run طولانی‌مدت است و با `Ctrl+C` متوقف می‌شود؛ این توقف دستی، نتیجهٔ build/test نیست.

## نتیجهٔ HTTP واقعی

| URL یا سناریو | نتیجه |
|---|---|
| `http://127.0.0.1:5081/API/BAZDID/health/live` | 200 و دقیقاً `{"status":"alive"}` |
| `http://127.0.0.1:5081/API/BAZDID/swagger/index.html` | 200 و URL نسبی `v1/swagger.json` |
| `http://127.0.0.1:5081/API/BAZDID/swagger/v1/swagger.json` | 200، `swagger=2.0`، `basePath=/API/BAZDID` و تنها مسیر `/health/live` |
| prefix دوبرابر زیر همین پایه | 404 |
| query `url` روی Swagger UI | 400 |

شواهد غیرحساس در [HTTP_SMOKE.json](checkpoint1/HTTP_SMOKE.json) است. API base خودش endpoint مستقل ندارد و 404 آن طبیعی است؛ liveness هیچ claim دربارهٔ readiness سرویس‌های آینده نمی‌کند.

## پوشش آزمون و حد اعتبار

۱۵ آزمون واحد، محیط/مسیر/origin ناامن و gateهای تنظیم را پوشش می‌دهند. ۲۸ integration شامل startup، health، JSON/correlation، مسیر ناشناخته/آینده/دوبرابر، exception بدون نشت در Development و Production، UI/JS/JSON و disable Swagger، منع query، CORS معتبر/نامعتبر، HTTPS redirect، HSTS روشن/خاموش و metadata PathBase شبیه‌سازی‌شدهٔ IIS هستند. controller خطای مصنوعی فقط در assembly تست است و در artifact برنامه وجود ندارد.

**انجام‌نشده:** IIS/ANCM واقعی، گواهی/TLS واقعی شبکه، browser automation، SQL، SMS، cookie/CSRF و file upload. TestServer فقط رفتار pipeline را اثبات می‌کند؛ metadata شبیه‌سازی‌شده، تأیید نصب زیرساخت نیست. UI و JS با HTTP دریافت شدند؛ اجرای تصویری UI در مرورگر ادعا نمی‌شود.

## امنیت، مانع‌ها و آمادگی مرحلهٔ بعد

audit ۹ بستهٔ دارای هشدار در گراف API و ۱۰ ارتباط advisory، شامل **Critical برای Kestrel**، گزارش کرده است. محدودسازی Swagger و انتخاب Newtonsoft 13.0.4 برخی خطرها را کاهش می‌دهد؛ پشته patched یا قابل انتشار عمومی اعلام نمی‌شود. [گزارش جزئیات و منابع](checkpoint1/DEPENDENCY_SECURITY_FA.md). EOL و gate امنیتی O18 باز است.

مانع حل‌نشده‌ای برای build/run/test محلی Checkpoint 1 وجود ندارد. برای Checkpoint 2، اجازهٔ تازهٔ کاربر و پایگاه تست مصوب با نسخه/compatibility/schema/permission لازم است؛ mapping واقعی فقط پیش از adapter واقعی لازم می‌شود. سرور/Hosting Bundle، origin/domain واقعی و مجوز امنیت برای استقرار هنوز تحویل نشده‌اند. تغییر source Frontend، SQL یا IIS اصلی انجام نشده است.

## مستندات و Git

README، AGENTS، PLAN، معماری، API، آزمون، IIS، امنیت، تصمیم‌های باز و ادامهٔ AI با وضعیت جدید همسو شدند؛ اسناد تاریخی Phase 0 و همهٔ referenceها حفظ شده‌اند. commit کد و آزمون‌ها `2187316` است؛ راهنماها و شواهد در commit مستندات جدا ثبت می‌شوند و SHA آن از `git log`/پاسخ تحویل قابل خواندن است. remote ایجاد و push انجام نشده است. artifacts/bin/obj/log به Git نمی‌روند.

کنترل نهایی مستندات: ۲۶ Markdown مرتبط بدون پیوند محلی شکسته یا fence باز؛ JSONهای source/شواهد parse شدند و hash هر ۴۵ مرجع با commit آغاز کار برابر ماند. پوشهٔ database هیچ SQL تازه ندارد. فرایند Kestrel پس از smoke test عمداً متوقف شد؛ برای اجرای دوباره از فرمان startup بالا استفاده کنید.

**Checkpoint 1 کامل است؛ توقف در همین مرحله. Checkpoint 2 هنوز شروع نشده است.**
