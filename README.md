# Backend سامانهٔ بازدید خودرو

این مخزن مستقل، پایهٔ توسعهٔ Backend برنامهٔ فارسی خودبازدید خودرو برای کارگزاری بیمه است. Frontend موجود در `C:\Projects\vehicle-inspection-integrated` فقط مرجع خواندنی است؛ دو مخزن ادغام نمی‌شوند.

در `2026-11-03`، مجوز `ea650fd0-47e2-4d02-bf9b-0fb87f03a254` فقط 2F را پوشش داد. قراردادها، سه repository، transaction و DI با gate بسته پیاده شدند؛ O24/O26 مانع پذیرش متصل‌اند. ۱۰۹ unit و ۵۰ integration آفلاین موفق، صفر شکست و ۸ SQL Skipped؛ build صفر warning/error. verification خواندنی schema/ردیف قبل و بعد برابر و سه جدول خالی‌اند. DDL، DML repository، grant و اتصال runtime انجام نشدند. **پیشرفت 20%؛ توقف در 2F ناقص، بدون شروع 2G.** [راهنمای 2F و شواهد](docs/implementation/CHECKPOINT-02F-SQL-REPOSITORIES_FA.md).

## فناوری و میزبانی

هدف قطعی `ASP.NET Core 2.1` / `netcoreapp2.1`، REST/JSON، SQL Server موجود کارگزاری و IIS روی Windows Server است. Backend یک IIS Application مستقل زیر `/API/BAZDID/` خواهد بود. Frontend روی subdomain جدا قرار می‌گیرد؛ دامنه‌های نمونه تنظیمات واقعی نیستند.

پشتیبانی .NET Core 2.1 در `2021-08-21` پایان یافته است. انتشار عمومی نیازمند بررسی امنیت و پذیرش صریح ریسک است. [اعلام رسمی Microsoft](https://devblogs.microsoft.com/dotnet/net-core-2-1-will-reach-end-of-support-on-august-21-2021/).

## راهنمای مطالعهٔ توسعه‌دهنده

| موضوع | محل مطالعه |
|---|---|
| معماری و قواعد | [معماری](docs/ARCHITECTURE_FA.md)، [زمینه](docs/PROJECT_CONTEXT_FA.md)، [قواعد کسب‌وکار](docs/BUSINESS_RULES_FA.md) و [امنیت](docs/SECURITY_FA.md) |
| چگونه پیاده شد | [فهرست walkthroughها و شواهد مراحل](docs/implementation/README.md)؛ به‌روزرسانی فرایند بعد از هر پیاده‌سازی اجباری است |
| راه‌اندازی و بررسی پایگاه | [VS Code و SQL Server](docs/guides/VSCODE_SQLSERVER_SETUP_FA.md)، [وضعیت scriptها](database/README.md)، [طراحی داده](docs/DATABASE_DESIGN_FA.md) و [نگاشت](docs/BROKERAGE_DATA_MAPPING_FA.md) |
| API و قرارداد | [قرارداد اجراشده/طرح آینده](docs/API_IMPLEMENTATION_FA.md)؛ Swagger واقعیِ محیط محلی پایین همین صفحه معرفی شده است |
| آزمون و پذیرش | [راهبرد و فرمان‌ها](docs/TESTING_STRATEGY_FA.md)، [پذیرش](docs/PHASE1_ACCEPTANCE_FA.md) و [audit dependency](docs/checkpoint1/DEPENDENCY_SECURITY_FA.md) |
| میزبانی و استقرار | [راهنمای IIS](docs/IIS_DEPLOYMENT_FA.md)؛ استقرار واقعی هنوز انجام نشده است |
| پیشرفت و گام بعد | [PLAN](PLAN.md)، [تصمیم‌های باز](docs/OPEN_DECISIONS_FA.md)، [AGENTS](AGENTS.md) و [ادامهٔ نشست](docs/AI_CONTINUATION_FA.md) |

طرح‌های [احراز هویت](docs/AUTH_AND_SESSION_FA.md) و [رسانه](docs/MEDIA_STORAGE_FA.md) با رفتار فعلی اشتباه نشوند. منشأ منابع در [SOURCE_REFERENCES_FA.md](docs/SOURCE_REFERENCES_FA.md) ثبت است؛ اسناد تاریخی بزرگ فقط به تناسب نیاز خوانده شوند.

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
    implementation/             # فهرست فرایندها با ارجاع به گزارش‌های واقعی
    guides/                     # آموزش عملی ابزار؛ بدون مجوز اجرای DDL
    reference/                  # منابع تحویل‌شده؛ قرارداد اجرایی نیستند
  src/Bazdid.Api/                # WebHost + Startup + health و زیرساخت
  tests/Bazdid.UnitTests/
  tests/Bazdid.IntegrationTests/
  database/                     # discovery، reviewهای بسته، ابزار محلی و verification 2C
  deployment/iis/               # راهنما و web.config.example
```

یک پروژهٔ API و دو پروژهٔ آزمون موجودند. Application/Domain/Infrastructure و Fixtures اکنون reader ساختگی و قراردادهای 2D را دارند؛ repository SQL برنامه پیاده نشده است. سه جدول اولیه فقط در پایگاه توسعهٔ محلی ساخته شده‌اند. برای بررسی خواندنی metadata از ریشه `.\database\tools\Invoke-BazdidDevelopmentDatabase.ps1 -Action Verify` را اجرا کنید؛ DDL مجدد یا reset خودکار وجود ندارد.

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

restore/build/test در 2D دوباره موفق اجرا شدند: **۶۵ unit و ۴۳ integration، جمع ۱۰۸ موفق**؛ build صفر warning/error. فرمان run بالا متعلق به smoke تاریخی foundation است؛ در 2D اجرای مستقیم DLL روی loopback پورت 5082 نیز health/Swagger و 404 مسیر snapshot را تأیید کرد. روش بازتولید بدون launchSettings کاربر در walkthrough 2D است. فرمان run تا `Ctrl+C` فعال می‌ماند. URLهای تاریخی foundation:

| قابلیت | URL |
|---|---|
| پایهٔ API | `http://127.0.0.1:5081/API/BAZDID/`؛ خود ریشه endpoint ندارد |
| health | `http://127.0.0.1:5081/API/BAZDID/health/live` |
| Swagger UI | `http://127.0.0.1:5081/API/BAZDID/swagger/index.html` |
| Swagger 2.0 JSON | `http://127.0.0.1:5081/API/BAZDID/swagger/v1/swagger.json` |

پاسخ health فقط `{"status":"alive"}` است؛ SQL/SMS/storage readiness را ثابت نمی‌کند. `Development` و `Testing` Swagger دارند؛ در Production همیشه 404 است. queryهای Swagger برای remote definition رد می‌شوند. برای آزمون HTTP محلی `Invoke-WebRequest -UseBasicParsing` به‌کار رفت.

در Kestrel حالت `Standalone`، برنامه prefix را جدا می‌کند؛ در IIS حالت `Iis`، IIS integration مالک PathBase است. route کنترلر prefix ندارد. ریشهٔ بدون prefix و prefix دوبرابر 404 JSON می‌دهند. [روش publish و نصب staging](deployment/iis/README.md).

## تنظیمات و محدودیت امنیت

`appsettings.json` خواننده را Disabled نگه می‌دارد؛ overrideهای Development/Testing صریحاً Synthetic و scope ثابت `TEST-BROKERAGE / SYNTHETIC` دارند. Production synthetic یا scope آزمایشی را رد می‌کند و منبع تنظیم‌نشده Unavailable می‌ماند؛ fallback وجود ندارد. هیچ SMS/OTP یا seed فعال نیست. مقادیر واقعی از environment/secret store مصوب تأمین شوند. نمونهٔ Production فقط مثال و خارج artifact است. originها پیش‌فرض خالی و در صورت تنظیم باید دقیق باشند؛ wildcard مجاز نیست. CORS فعلی read-only و بدون credential است؛ cookie/CSRF آینده هنوز فعال نیست.

بسته‌های اصلی `Microsoft.AspNetCore.App 2.1.30`، `Swashbuckle.AspNetCore 4.0.1` و `Newtonsoft.Json 13.0.4` هستند؛ نسخه‌های تست و lockfileها در [گزارش dependency](docs/checkpoint1/DEPENDENCY_SECURITY_FA.md) ثبت‌اند. audit واقعی، ۹ بستهٔ دارای هشدار در گراف API، از جمله Critical برای Kestrel، نشان داد. **Production تأیید امنیتی ندارد.**

Checkpoint 2F فقط در بخش آفلاین تحویل شد و پذیرش آن مسدود است. `SqlRuntime.Enabled=false` و gate کد بسته است؛ روشن‌کردن آن در تنظیمات startup را رد می‌کند. O24 و دو principal مصوب O26 باید پیش از هر اتصال برنامه حل شوند. گام بعد ادامهٔ همین 2F با تصمیم/مجوز لازم است؛ 2G شروع نشد و Info در Checkpoint 4 می‌ماند.

## GitHub و گزارش‌دهی فارسی

مخزن مقصد مجاز [AliKeramattii/vehicle-inspection-backend](https://github.com/AliKeramattii/vehicle-inspection-backend) است. `origin` به URL همین مخزن وصل شده است؛ وضعیت ارسال و تطبیق HEADها فقط از [گزارش همگام‌سازی](docs/GITHUB_SYNC_FA.md) خوانده شود و وجود remote به‌معنی push موفق فرض نشود.

پس از هر وظیفهٔ Codex، گزارش نهایی باید طبق [سیاست اجباری AGENTS.md](AGENTS.md) فارسی باشد و تغییر، فایل، آزمون/build، امنیت، Git، مرحلهٔ فعلی و گام بعد را با شواهد واقعی توضیح دهد. checkpointهای بعدیِ مجاز و اعتبارسنجی‌شده به همین مقصد commit/push شوند؛ force push، انتشار secret/تنظیم Production/آرشیو مرجع خصوصی و شروع خودکار checkpoint بعد ممنوع است. پیش از ارسال، تمام تاریخچهٔ قابل ارسال بررسی شود؛ حذف فایل ممنوع فقط از HEAD آن را از commitهای قدیمی حذف نمی‌کند.
