# Backend سامانهٔ بازدید خودرو

این مخزن مستقل، پایهٔ توسعهٔ Backend برنامهٔ فارسی خودبازدید خودرو برای کارگزاری بیمه است. Frontend موجود در `C:\Projects\vehicle-inspection-integrated` فقط مرجع خواندنی است؛ دو مخزن ادغام نمی‌شوند.

**وضعیت در 2026-11-01: Phase 0 تکمیل شده و منتظر بازبینی کاربر است؛ پیاده‌سازی Backend شروع نشده است.** هیچ برنامه، solution، جدول یا سرویس اجرایی در این مرحله ساخته نشده است. SQL داخل پوشهٔ مرجع، پیشنهاد ازپیش‌موجود و اجرا‌نشده است.

## فناوری و میزبانی

هدف قطعی `ASP.NET Core 2.1` / `netcoreapp2.1`، REST/JSON، SQL Server موجود کارگزاری و IIS روی Windows Server است. Backend یک IIS Application مستقل زیر `/API/BAZDID/` خواهد بود. Frontend روی subdomain جدا قرار می‌گیرد؛ دامنه‌های نمونه تنظیمات واقعی نیستند.

پشتیبانی .NET Core 2.1 در `2021-08-21` پایان یافته است. انتشار عمومی نیازمند بررسی امنیت و پذیرش صریح ریسک است. [اعلام رسمی Microsoft](https://devblogs.microsoft.com/dotnet/net-core-2-1-will-reach-end-of-support-on-august-21-2021/).

## ترتیب مطالعه

۱. [قواعد عامل‌ها](AGENTS.md) و [برنامهٔ مرجع](PLAN.md).
۲. [زمینهٔ پروژه](docs/PROJECT_CONTEXT_FA.md)، [معماری و محیط](docs/ARCHITECTURE_FA.md) و [قواعد کسب‌وکار](docs/BUSINESS_RULES_FA.md).
۳. [طراحی داده](docs/DATABASE_DESIGN_FA.md)، [نگاشت کارگزاری](docs/BROKERAGE_DATA_MAPPING_FA.md)، [هویت و نشست](docs/AUTH_AND_SESSION_FA.md) و [نقشهٔ API](docs/API_IMPLEMENTATION_FA.md).
۴. [رسانه](docs/MEDIA_STORAGE_FA.md)، [امنیت](docs/SECURITY_FA.md) و [IIS](docs/IIS_DEPLOYMENT_FA.md).
۵. [آزمون‌ها](docs/TESTING_STRATEGY_FA.md)، [پذیرش Phase 1](docs/PHASE1_ACCEPTANCE_FA.md)، [تصمیم‌های باز](docs/OPEN_DECISIONS_FA.md) و [ادامهٔ کار عامل](docs/AI_CONTINUATION_FA.md).
۶. [شناسنامهٔ منابع و تعارض‌ها](docs/SOURCE_REFERENCES_FA.md) و [اعتبارسنجی Phase 0](docs/PHASE0_VALIDATION_FA.md). اسناد بزرگ تاریخی فقط به تناسب نیاز خوانده شوند.

## ساختار فعلی و آینده

```text
vehicle-inspection-backend/
  AGENTS.md
  PLAN.md
  README.md
  .gitignore
  .gitattributes                   # حفظ بایت مرجع‌ها و پایان خط اسناد تازه
  docs/
    *_FA.md
    reference/                  # منابع تحویل‌شده؛ قرارداد اجرایی نیستند
```

ساختار پیشنهادی آینده، شامل یک پروژهٔ API و دو پروژهٔ آزمون، در [ARCHITECTURE_FA.md](docs/ARCHITECTURE_FA.md) است. `src/`، `tests/`، `database/` و `deployment/` هنوز ایجاد نشده‌اند.

## ابزار و دستورهای بررسی‌شده

دستورهای زیر در این محیط برای شناسایی ابزار اجرا شده‌اند:

```powershell
dotnet --info
dotnet --list-sdks
dotnet --list-runtimes
git --version
```

SDK `2.1.818` و Runtimeهای `Microsoft.NETCore.App 2.1.30` و `Microsoft.AspNetCore.App 2.1.30` نصب‌اند. SDK انتخاب‌شدهٔ فعلی، بدون `global.json`، برابر `10.0.403` است. نصب Runtime به معنی نصب IIS Hosting Bundle نیست؛ فایل‌های متداول ANCM و `appcmd.exe` در بررسی محلی یافت نشدند. سرور مقصد هنوز بررسی نشده است.

دستور build/run/test برنامه تا ساخت پروژه و اجرای واقعی منتشر نمی‌شود. در Checkpoint 1، نسخهٔ SDK با `global.json` قفل، dependencyها بررسی و دستورهای واقعاً موفق در همین فایل ثبت خواهند شد. در این مرحله هیچ آزمون کامپایل یا اجرا گزارش نمی‌شود.

گام بعدی پس از **اجازهٔ صریح کاربر** فقط Checkpoint 1 است: اسکلت ASP.NET Core 2.1، تنظیمات، logging، خطا، health و Swagger؛ اتصال Production و ساخت جدول‌ها بخشی از این اجازه نیستند.
