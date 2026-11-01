# Backend سامانهٔ بازدید خودرو

این مخزن مستقل، پایهٔ توسعهٔ Backend برنامهٔ فارسی خودبازدید خودرو برای کارگزاری بیمه است. Frontend موجود در `C:\Projects\vehicle-inspection-integrated` فقط مرجع خواندنی است؛ دو مخزن ادغام نمی‌شوند.

**وضعیت در 2026-11-01: Checkpoint 1 با اجازهٔ صریح کاربر پیاده و محلی آزموده شده است.** API واقعی فقط liveness، زیرساخت خطا/log/config و Swagger محیط غیرتولیدی دارد. SQL، OTP، Session، بازدید و upload هنوز پیاده نشده‌اند. SQL داخل پوشهٔ مرجع، پیشنهاد تاریخی اجرا‌نشده است.

## فناوری و میزبانی

هدف قطعی `ASP.NET Core 2.1` / `netcoreapp2.1`، REST/JSON، SQL Server موجود کارگزاری و IIS روی Windows Server است. Backend یک IIS Application مستقل زیر `/API/BAZDID/` خواهد بود. Frontend روی subdomain جدا قرار می‌گیرد؛ دامنه‌های نمونه تنظیمات واقعی نیستند.

پشتیبانی .NET Core 2.1 در `2021-08-21` پایان یافته است. انتشار عمومی نیازمند بررسی امنیت و پذیرش صریح ریسک است. [اعلام رسمی Microsoft](https://devblogs.microsoft.com/dotnet/net-core-2-1-will-reach-end-of-support-on-august-21-2021/).

## ترتیب مطالعه

۱. [قواعد عامل‌ها](AGENTS.md) و [برنامهٔ مرجع](PLAN.md).
۲. [زمینهٔ پروژه](docs/PROJECT_CONTEXT_FA.md)، [معماری و محیط](docs/ARCHITECTURE_FA.md) و [قواعد کسب‌وکار](docs/BUSINESS_RULES_FA.md).
۳. [طراحی داده](docs/DATABASE_DESIGN_FA.md)، [نگاشت کارگزاری](docs/BROKERAGE_DATA_MAPPING_FA.md)، [هویت و نشست](docs/AUTH_AND_SESSION_FA.md) و [نقشهٔ API](docs/API_IMPLEMENTATION_FA.md).
۴. [رسانه](docs/MEDIA_STORAGE_FA.md)، [امنیت](docs/SECURITY_FA.md) و [IIS](docs/IIS_DEPLOYMENT_FA.md).
۵. [آزمون‌ها](docs/TESTING_STRATEGY_FA.md)، [پذیرش Phase 1](docs/PHASE1_ACCEPTANCE_FA.md)، [تصمیم‌های باز](docs/OPEN_DECISIONS_FA.md) و [ادامهٔ کار عامل](docs/AI_CONTINUATION_FA.md).
۶. [گزارش Checkpoint 1](docs/CHECKPOINT1_IMPLEMENTATION_FA.md)، [یافته‌های امنیت dependency](docs/checkpoint1/DEPENDENCY_SECURITY_FA.md)، [شناسنامهٔ منابع](docs/SOURCE_REFERENCES_FA.md) و [اعتبارسنجی تاریخی Phase 0](docs/PHASE0_VALIDATION_FA.md). اسناد بزرگ تاریخی فقط به تناسب نیاز خوانده شوند.

## ساختار فعلی و آینده

```text
vehicle-inspection-backend/
  Bazdid.sln
  global.json                     # SDK 2.1.818
  Directory.Build.props
  NuGet.Config
  AGENTS.md
  PLAN.md
  README.md
  .gitignore
  .gitattributes                   # حفظ بایت مرجع‌ها و پایان خط اسناد تازه
  docs/
    *_FA.md
    reference/                  # منابع تحویل‌شده؛ قرارداد اجرایی نیستند
  src/Bazdid.Api/                # WebHost + Startup + health و زیرساخت
  tests/Bazdid.UnitTests/
  tests/Bazdid.IntegrationTests/
  database/                     # فقط README؛ بدون SQL اجرایی
  deployment/iis/               # راهنما و web.config.example
```

یک پروژهٔ API و دو پروژهٔ آزمون ساخته شده‌اند. پوشه‌های Application/Domain/Infrastructure فعلاً مرز مستند دارند و کد تجاری صوری ندارند. جدول‌های BAZDID یا adapter خواندن مبدأ هنوز ساخته نشده‌اند.

## ابزار و دستورهای بررسی‌شده

دستورهای زیر در این محیط برای شناسایی ابزار اجرا شده‌اند:

```powershell
dotnet --info
dotnet --list-sdks
dotnet --list-runtimes
git --version
```

SDK `2.1.818` اکنون با `global.json` انتخاب می‌شود. Runtimeهای `Microsoft.NETCore.App 2.1.30` و `Microsoft.AspNetCore.App 2.1.30` موجودند؛ target و C# به‌ترتیب `netcoreapp2.1` و `7.3` هستند. نصب Runtime به معنی نصب IIS Hosting Bundle نیست؛ ANCM/IIS واقعی و سرور مقصد هنوز احراز/آزموده نشده‌اند. هیچ نرم‌افزار سیستمی نصب نشده است.

از ریشهٔ مخزن، دستورهای زیر واقعاً اجرا شده‌اند:

```powershell
dotnet --version
dotnet restore Bazdid.sln --locked-mode
dotnet build Bazdid.sln --configuration Release --no-restore
dotnet test Bazdid.sln --configuration Release --no-build --no-restore
$env:ASPNETCORE_ENVIRONMENT = 'Development'
dotnet run --project src/Bazdid.Api/Bazdid.Api.csproj --configuration Release --no-build -- --urls http://127.0.0.1:5081
```

restore/build موفق و ۴۳ آزمون موفق‌اند؛ build نهایی صفر warning و صفر error داشت. فرمان run تا `Ctrl+C` فعال می‌ماند. URLهای محلی آزموده‌شده:

| قابلیت | URL |
|---|---|
| پایهٔ API | `http://127.0.0.1:5081/API/BAZDID/`؛ خود ریشه endpoint ندارد |
| health | `http://127.0.0.1:5081/API/BAZDID/health/live` |
| Swagger UI | `http://127.0.0.1:5081/API/BAZDID/swagger/index.html` |
| Swagger 2.0 JSON | `http://127.0.0.1:5081/API/BAZDID/swagger/v1/swagger.json` |

پاسخ health فقط `{"status":"alive"}` است؛ SQL/SMS/storage readiness را ثابت نمی‌کند. `Development` و `Testing` Swagger دارند؛ در Production همیشه 404 است. queryهای Swagger برای remote definition رد می‌شوند. برای آزمون HTTP محلی `Invoke-WebRequest -UseBasicParsing` به‌کار رفت.

در Kestrel حالت `Standalone`، برنامه prefix را جدا می‌کند؛ در IIS حالت `Iis`، IIS integration مالک PathBase است. route کنترلر prefix ندارد. ریشهٔ بدون prefix و prefix دوبرابر 404 JSON می‌دهند. [روش publish و نصب staging](deployment/iis/README.md).

## تنظیمات و محدودیت امنیت

`appsettings.json` تنظیم امن پایه و فایل‌های Development/Testing override محیط را دارند. مقادیر واقعی از environment/secret store مصوب تأمین شوند. نمونهٔ Production فقط مثال و خارج artifact است. originها پیش‌فرض خالی و در صورت تنظیم باید دقیق باشند؛ wildcard مجاز نیست. CORS فعلی read-only و بدون credential است؛ cookie/CSRF آینده هنوز فعال نیست.

بسته‌های اصلی `Microsoft.AspNetCore.App 2.1.30`، `Swashbuckle.AspNetCore 4.0.1` و `Newtonsoft.Json 13.0.4` هستند؛ نسخه‌های تست و lockfileها در [گزارش dependency](docs/checkpoint1/DEPENDENCY_SECURITY_FA.md) ثبت‌اند. audit واقعی، ۹ بستهٔ دارای هشدار در گراف API، از جمله Critical برای Kestrel، نشان داد. **Production تأیید امنیتی ندارد.**

Checkpoint 1 نقطهٔ توقف است. گام بعدی فقط پس از **اجازهٔ تازهٔ کاربر**، Checkpoint 2 و تعیین پایگاه تست/نسخه SQL است؛ هیچ SQL، OTP، تغییر Frontend یا استقرار واقعی به‌طور خودکار شروع نمی‌شود.
