# یافته‌های dependency و امنیت Checkpoint 1

تاریخ بررسی: `2026-11-01`. پشتهٔ برنامه طبق الزام مالک `netcoreapp2.1` باقی مانده است. restore/build/run موفق، تأیید امنیت Production نیست. هیچ یافتهٔ audit مخفی یا با suppression حذف نشده است.

## نسخه‌های نصب و بررسی‌شده

| بسته | نسخهٔ مستقیم | علت و وضعیت |
|---|---|---|
| `Microsoft.AspNetCore.App` | `2.1.30` | آخرین shared framework تاریخی الزام‌شده؛ package lock شامل componentهای با شمارهٔ patch متفاوت است |
| `Newtonsoft.Json` | `13.0.4` | asset سازگار netstandard؛ عمداً روی نسخهٔ قدیمی transitive override شده؛ MVC و خطای JSON با آن تست شدند |
| `Swashbuckle.AspNetCore` | `4.0.1` | Swagger 2.0 و UI سازگار واقعی با ASP.NET Core 2.1؛ فقط محیط غیرتولیدی |
| `Microsoft.NET.Test.Sdk` | `15.9.0` | فقط تست؛ runner واقعی SDK 2.1 در این سیستم VSTest `16.2.0-preview-20190606-02` گزارش می‌کند |
| `xunit` | `2.4.1` | فقط تست؛ نسل قدیمی، آزمون اجراشده روی Runtime 2.1 |
| `xunit.runner.visualstudio` | `2.4.1` | فقط تست، PrivateAssets=all؛ نسخهٔ 2.4.5 با نیاز netcoreapp3.1 انتخاب نشد |
| `Microsoft.AspNetCore.TestHost` | `2.1.1` | asset netstandard2.0؛ تست Startup/HTTP در همان نسل؛ شمارهٔ 2.1.30 برای این بسته فرض نشد |

سه `packages.lock.json` نسخه و content hash گراف واقعی را ثبت می‌کنند؛ restore قفل‌شده آزموده شد. برای source فقط feed رسمی NuGet تعریف شده است. جدیدترین dependency کورکورانه نصب نشده و هیچ SDK یا Hosting Bundle نصب نشده است.

metadata رسمی: [Swashbuckle 4.0.1](https://www.nuget.org/packages/Swashbuckle.AspNetCore/4.0.1)، [Newtonsoft 13.0.4](https://www.nuget.org/packages/Newtonsoft.Json/13.0.4)، [TestHost 2.1.1](https://www.nuget.org/packages/Microsoft.AspNetCore.TestHost/2.1.1)، [Test SDK 15.9](https://www.nuget.org/packages/Microsoft.NET.Test.Sdk/15.9.0) و [runner 2.4.1](https://www.nuget.org/packages/xunit.runner.visualstudio/2.4.1).

Newtonsoft قدیمی‌تر از 13.0.1 در advisory مشخصی مشکل nesting دارد؛ نسخهٔ 13.0.4 و `MaxDepth=32`/`TypeNameHandling=None` در MVC انتخاب شده‌اند. این اقدام، رفع تمام خطرهای پشته نیست. [advisory Newtonsoft](https://github.com/advisories/GHSA-5crp-9r3c-p9vr).

## audit واقعی

SDK 2.1 ابزار audit جدید ندارد. فقط برای **خواندن گراف restoreشده**، CLI ازپیش‌نصب‌شدهٔ 10.0.403 مستقیماً اجرا شد؛ target و SDK ساخت/اجرا/تست تغییر نکردند و `--no-restore` به‌کار رفت:

```powershell
dotnet 'C:\Program Files\dotnet\sdk\10.0.403\dotnet.dll' package list --project Bazdid.sln --vulnerable --include-transitive --no-restore --format json
```

فرمان نهایی exit code صفر داشت. خروجی اصلی در [PACKAGE_AUDIT.json](PACKAGE_AUDIT.json) نگهداری می‌شود. برای پروژهٔ API، ۹ بسته و ۱۰ ارتباط package/advisory گزارش شد؛ پروژه‌های تست گراف مشترک را دوباره گزارش می‌کنند و این‌ها یافتهٔ مستقل بیشتر نیستند. این audit «پاک» نیست.

| بستهٔ گزارش‌شده | نسخهٔ resolved | severity گزارش‌شده |
|---|---|---|
| `Microsoft.AspNetCore.Identity` | `2.1.6` | High |
| `Microsoft.AspNetCore.Server.Kestrel.Core` | `2.1.25` | Critical |
| `Microsoft.AspNetCore.Server.Kestrel.Transport.Sockets` | `2.1.3` | High |
| `Swashbuckle.AspNetCore.SwaggerUI` | `4.0.1` | Moderate |
| `System.Data.SqlClient` | `4.5.3` | Moderate و High |
| `System.IdentityModel.Tokens.Jwt` | `5.2.0` | Moderate |
| `System.Net.Http` | `4.3.0` | High |
| `System.Security.Cryptography.Xml` | `4.5.0` | Moderate |
| `System.Text.RegularExpressions` | `4.3.0` | High |

گزارش metadata با تشخیص exploit قطعی در هر deployment یکسان نیست؛ shared framework، asset انتخابی و ویژگی فعال اثر دارند. با این حال هشدارهای Kestrel را نمی‌توان صرفاً با خاموش‌بودن auth کنار گذاشت: Kestrel همین حالا میزبان درخواست است و فایل‌های runtime نصب‌شده نیز شمارهٔ component قدیمی را دارند. بررسی دقیق اثر [CVE-2025-55315](https://github.com/advisories/GHSA-5rrx-jjjq-q2r5) و [CVE-2023-38180](https://github.com/advisories/GHSA-vmch-3w2x-vhgq) برای chain واقعی IIS/proxy، gate امنیت Production است. componentهای SQL/Identity/JWT اکنون در کد فعال نشده‌اند، ولی در گراف موجودند و پیش از مصرف آینده باید ارزیابی شوند.

## محدودسازی Swagger و تصمیم سازگاری

advisory [GHSA-qrmm-w75w-3wpx](https://github.com/advisories/GHSA-qrmm-w75w-3wpx) دربارهٔ remote definition از query و امکان فیشینگ است؛ آن را XSS اثبات‌شده یا SSRF سروریِ قطعیِ این برنامه معرفی نمی‌کنیم. رفع upstream برای بسته UI از 6.3.0 ذکر شده است؛ ارتقای کور به major جدید بدون اثبات سازگاری 2.1 مجاز نیست. نسخهٔ 5.6.3 نیز در metadata همان advisory را دارد و صرف تغییر major رفع آن نیست.

در implementation فعلی، Swagger در Production اصلاً middleware/route ندارد؛ در محیط‌های مجاز هم flag خاموش‌شدن دارد و تمام queryهای `/swagger` از جمله `url/configUrl` با 400 رد می‌شوند. سند فقط از همان برنامه می‌آید و cookie/auth نیز هنوز وجود ندارد. آزمون query و بسته‌بودن Production موفق است. این‌ها کاهش سطح دسترسی‌اند و package را patched یا ایمن برای اینترنت اعلام نمی‌کنند. اجرای محلی روی loopback باقی می‌ماند؛ محیط Testing نیز برای شبکهٔ عمومی تأیید نشده است.

## تصمیم امنیتی باقی‌مانده

EOL از `2021-08-21`، نبود وصلهٔ نسل 2.1، هشدارهای Critical/High و نیاز بررسی میزبان مانع تأیید عمومی Production هستند. user requirement اجازهٔ تغییر target نداده است، پس framework بی‌اجازه ارتقا نیافت. مسیر لازم: ارزیابی مستقل، محدودیت شبکه/دسترسی staging، پذیرش صریح ریسک با مسئول/موعد، تصمیم دربارهٔ mitigations معتبر و برنامهٔ مهاجرت. audit در تغییر dependency و پیش از انتشار دوباره انجام شود؛ silent suppression یا اتکا به WAF کافی نیست.
