# ادامهٔ 2F — تصمیم provider و بستهٔ آمادهٔ تصویب دسترسی

تاریخ بررسی `2026-11-03`؛ مجوز تحلیل/آماده‌سازی `e252dad0-0bb1-4058-ab9b-f757dd2b272a`؛ مبنای Git برابر `3b5e78dd8c35d7da6b0550d92220b782ac1acc12`. **این بسته پیشنهاد است و مجوز تغییر provider، ساخت حساب یا اعمال SQL نیست. پذیرش 2F همچنان مسدود و پیشرفت 20% است.** بندهای ۴، ۶، ۷ و دستور نهایی پیوست مالک صریحاً تصویب جداگانه را لازم کرده‌اند؛ به همین دلیل قبل از این عملیات توقف می‌شود.

## نتیجهٔ قابل تصمیم

برای گراف فعلی `Microsoft.AspNetCore.App 2.1.30`، provider اصلاح‌شده و دارای پشتیبانی که بدون نقض قیدها قابل تأیید باشد پیدا نشد. پشتیبانی runtime 2.1 نیز از `2021-08-21` تمام شده است. پیشنهاد مهندسی، **تصویب تهیهٔ طرح مهاجرت جداگانه به .NET 10 LTS و ارزیابی Microsoft.Data.SqlClient 6.1.7 LTS** است؛ اکنون نه target تغییر کرده و نه provider انتخاب/نصب/فعال شده است. نسخهٔ patch runtime، SDK، Windows Server/IIS/ANCM و dependencyهای نهایی باید در آن طرح با تاریخ اجرا بررسی و pin شوند. [.NET lifecycle](https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core)، [راهنمای انتخاب driver](https://learn.microsoft.com/en-us/sql/connect/ado-net/download-microsoft-sqlclient-data-provider).

این نتیجه، اثبات ناممکن‌بودن اجرای فنی همهٔ providerها روی 2.1 نیست. حذف metapackage و بازسازی dependencyهای granular می‌تواند موضوع آزمایش مستقل legacy باشد؛ گراف، ریسک EOL و رفتار shared framework آن باید جداگانه تصویب/بررسی شوند و هیچ تضمین سازگاری ندارد. override اجباری، suppress هشدار و کپی DLL/SNI بین نسخه‌ها راه‌حل پذیرفته نیستند. اگر الزام 2.1 تغییرناپذیر بماند، پیشنهاد فعلی حفظ gate بسته است؛ هر آزمایش legacy به مصوبهٔ دقیق و پذیرش ریسک مستقل نیاز دارد.

## شواهد گراف و ماتریس provider

از `src/Bazdid.Api/obj/project.assets.json` مشخص شد **خود `Microsoft.AspNetCore.App/2.1.30`** بالاسقف SQL Client را می‌آورد. `Microsoft.EntityFrameworkCore.SqlServer/2.1.14` و `Microsoft.Extensions.Caching.SqlServer/2.1.2` فقط حداقل `4.5.1` را می‌خواهند و منشأ بالاسقف نیستند. استفاده‌نکردن repository از EF، وابستگی انتقالی metapackage را حذف نمی‌کند. [metadata رسمی App](https://www.nuget.org/packages/Microsoft.AspNetCore.App/2.1.30).

قیود اثبات‌شده در گراف موجود:

| کد | dependency | قید App 2.1.30 |
|---|---|---|
| C1 | System.Data.SqlClient | `[4.5.3,4.6.0)` |
| C2 | System.Text.Encoding.CodePages | `[4.5.1,4.6.0)` |
| C3 | System.Text.Encodings.Web | `[4.5.1,4.6.0)` |
| C4 | Microsoft.Extensions.Caching.Memory | `[2.1.23,2.2.0)` |
| C5 | System.Security.Cryptography.Pkcs | `[4.5.2,4.6.0)` |
| C6 | System.Threading.Channels | `[4.5.0,4.6.0)` |

نه nuspec نسخه‌دار از `api.nuget.org/v3-flatcontainer` فقط به‌صورت metadata خوانده شدند. فهرست TFMهای اعلام‌شده، dependencyهای گروه مرتبط با target فعلی، URL، SHA256 کل nuspec و تعارض مستقیم در [PROVIDER_CANDIDATES.json](PROVIDER_CANDIDATES.json) هستند؛ گروه‌های نامرتبط در artifact تکرار نشده‌اند و از URL نسخه‌دار قابل بازخوانی‌اند. مقایسهٔ بازه‌ها تحلیل metadata است؛ restore نامزدها، حل/audit کامل closure، build یا native/runtime test آن‌ها اجرا نشد، چون تغییر نسخه هنوز تصویب نشده است. آزمون تازه فقط provider قبلی را بدون Open بارگذاری کرد.

| provider و نسخه | شاهد سازگاری runtime | گراف dependency | آسیب‌پذیری شناخته‌شده/حد شاهد | پشتیبانی | آزمون انجام‌شده | ریسک باقیمانده | پیشنهاد |
|---|---|---|---|---|---|---|---|
| System.Data.SqlClient 4.5.3، موجود | asset `netcoreapp2.1`؛ managed x64 واقعاً بارگذاری شد | گراف قفل‌شدهٔ موجود | audit تازه Moderate/High؛ 0056 شامل آن است | deprecated؛ runtime EOL | regression/metadata؛ بدون Open | آسیب‌پذیری، native/TLS و مجوز تأییدنشده | فقط baseline آفلاین؛ اتصال رد شود |
| [System.Data.SqlClient 4.8.6](https://www.nuget.org/packages/System.Data.SqlClient/4.8.6) | گروه صریح `.NETCoreApp2.1` | خود نسخه C1 را نقض می‌کند؛ CodePages>=4.7.0 با C2 تعارض دارد | اصلاح CVE-2024-0056؛ audit کامل نامزد انجام نشده | خانوادهٔ deprecated، runtime EOL | nuspec/بازه‌ها | دو تعارض و ریسک EOL | در گراف فعلی رد؛ pin اجباری نشود |
| [System.Data.SqlClient 4.9.1](https://www.nuget.org/packages/System.Data.SqlClient/4.9.1) | گروه Standard 2.0 و اهداف جدید؛ اجرای 2.1 نامعلوم | C1 را نقض می‌کند | شاخهٔ بعد از اصلاح 0056؛ بی‌هشداری صفحه اثبات امنیت کل نیست | deprecated | nuspec/بازه‌ها | asset انتخاب‌شده/API/native نامعلوم، EOL | در گراف فعلی رد |
| [Microsoft.Data.SqlClient 2.1.7](https://www.nuget.org/packages/Microsoft.Data.SqlClient/2.1.7) | گروه صریح `.NETCoreApp2.1` | CodePages>=4.7.0 با C2 تعارض؛ SNI.runtime>=2.1.1 | اصلاح 0056؛ closure ارزیابی کامل نشده | پایان پشتیبانی 2023-11-20 | nuspec/بازه‌ها | transitive، EOL، assembly/native جدید | جایگزین امنِ تأییدشده نیست |
| [Microsoft.Data.SqlClient 3.1.7](https://www.nuget.org/packages/Microsoft.Data.SqlClient/3.1.7) | گروه صریح `.NETCoreApp2.1` | CodePages>=4.7.0 و Encodings.Web>=4.7.2 با C2/C3 تعارض؛ SNI.runtime دقیق 3.0.2 | شاخهٔ اصلاح‌شدهٔ 0056؛ closure audit نشده | پایان پشتیبانی 2025-03-30 | nuspec/بازه‌ها | دو تعارض و EOL؛ legacy trial نامصوب | در گراف فعلی رد |
| [Microsoft.Data.SqlClient 4.0.6](https://www.nuget.org/packages/Microsoft.Data.SqlClient/4.0.6) | گروه Standard 2.0؛ اجرای 2.1 تأیید نشده | CodePages/Encodings.Web جدیدتر از C2/C3 | شاخهٔ پس از اصلاح 0056؛ closure audit نشده | پایان پشتیبانی 2024-11-19 | nuspec/بازه‌ها | dependency/API/native و EOL | در گراف فعلی رد |
| [Microsoft.Data.SqlClient 5.2.3](https://www.nuget.org/packages/Microsoft.Data.SqlClient/5.2.3) | Standard 2.0 و اهداف جدید؛ 2.1 تأیید نشده | CodePages/Encodings.Web>=6.0.0 با C2/C3 تعارض | گراف نصب/audit نشده؛ اصلاح یک CVE تضمین کل نیست | پایان پشتیبانی 2025-08-28 | nuspec/بازه‌ها | API/native و dependencyهای جدید، EOL | توصیه نمی‌شود |
| [Microsoft.Data.SqlClient 6.1.7](https://www.nuget.org/packages/Microsoft.Data.SqlClient/6.1.7) | اهداف جدید و Standard 2.0؛ runtime دارای پشتیبانی لازم است | Caching.Memory>=8.0.1 و Pkcs>=8.0.1 با C4/C5 تعارض | نسخهٔ servicing فعلی شاخهٔ LTS؛ گراف نهایی پروژه هنوز audit نشده | LTS تا 2028-08-14 | nuspec/بازه‌ها | روی 2.1 قابل تأیید نیست؛ migration نیازمند بررسی | نامزد پیشنهادی طرح مهاجرت جدا |
| [Microsoft.Data.SqlClient 7.0.3](https://www.nuget.org/packages/Microsoft.Data.SqlClient/7.0.3) | Standard 2.0 و اهداف جدید؛ پشتیبانی executable قدیمی ثابت نشده | Caching/Pkcs/Channels با C4/C5/C6 تعارض | servicing شاخهٔ STS؛ closure audit نشده | تا 2026-12-17 | nuspec/بازه‌ها | migration و پایان پشتیبانی نزدیک | برای پروژهٔ تازه بر LTS ترجیح ندارد |
| [Microsoft.Data.SqlClient 7.1.1](https://www.nuget.org/packages/Microsoft.Data.SqlClient/7.1.1) | .NET8+ / Framework4.6.2+؛ Standard 2.0 asset کتابخانه است | Caching/Pkcs/Channels با C4/C5/C6 تعارض | نسخهٔ GA جاری؛ closure نصب/audit نشده | STS؛ وابسته به انتشار بعدی | nuspec/بازه‌ها | تغییرهای API/auth و cadence کوتاه‌تر | گزینهٔ جدید برای طرح جدا؛ اکنون نصب نشود |

مرجع اصلاح 0056، [اعلان Microsoft](https://github.com/dotnet/announcements/issues/292) است؛ «اصلاح 0056» به معنی فقدان همهٔ advisoryها نیست. تاریخ‌های پشتیبانی از [چرخهٔ رسمی driver](https://learn.microsoft.com/en-us/sql/connect/ado-net/sqlclient-driver-support-lifecycle) خوانده شدند. مطابق [راهنمای نصب رسمی](https://learn.microsoft.com/en-us/sql/connect/ado-net/download-microsoft-sqlclient-data-provider)، Standard 2.0 به‌تنهایی پشتیبانی executable روی runtime قدیمی را اثبات نمی‌کند و driver/SNI باید از گراف درست NuGet بیایند.

وابستگی‌های هویت، پیکربندی و native نامزدها در JSON ثبت‌اند؛ از جمله Registry/Principal.Windows، DiagnosticSource، ConfigurationManager، Runtime.Caching، IdentityModel و در شاخه‌های جدید Azure/Memory/Pkcs. بررسی تقاطع مستقیم برای رد گراف فعلی کافی است؛ ادعای حل همهٔ وابستگی‌های انتقالی یا عدم وجود تعارض دیگر نمی‌شود. تعویض namespace به Microsoft.Data.SqlClient نیز بستهٔ آسیب‌پذیر System.Data.SqlClient را خودکار از metapackage فعلی حذف نمی‌کند.

از نظر API، قراردادهای Domain/Persistence به provider وابسته نیستند، اما factoryهای Infrastructure اکنون `Task<System.Data.SqlClient.SqlConnection>` برمی‌گردانند و command/parameter/exception/transaction هم از همان namespace هستند. Microsoft.Data.SqlClient جایگزینی بدون بازبینی typeها نیست؛ factory، commandها و تست‌ها باید با هم compile و آزموده شوند. طبق راهنمای رسمی، از نسخهٔ 5.0 نوع `SqlConnectionStringBuilder.Encrypt` از bool به `SqlConnectionEncryptOption` تغییر کرده است؛ شرط فعلیِ validation و مقدار Mandatory/Strict باید برای نسخهٔ انتخابی بازبینی شوند. APIهای async/cancellation موجود روی provider فعلی build شدند، اما تضمین معادل برای API/native نامزدها بدون build و اتصال مصوب داده نمی‌شود. هیچ‌یک از این تغییرهای احتمالی اکنون انجام نشده است.

## هویت‌ها و اجرای واقعی پیشنهادی

metadata تازه: همان ماشین و `SQLSERVER2019`، موتور `15.0.2000.5`، Windows/NTLM و Shared memory؛ linked server و DB کاربری غیرمنتظره صفر؛ سه جدول/۳۹ ستون/۱۰ index/۱۳ CHECK و شمار صفر ردیف برقرارند. حساب metadata در SQL sysadmin است، اما token فعلی Windows عضو مؤثر Administrators نیست؛ اختیار SQL، اختیار ساخت Windows user نمی‌دهد. هیچ login غیرسرویسی کم‌اختیار طبق فیلتر، Windows user پایگاه، نقش پیشنهادی یا عضو آن نقش‌ها وجود نداشت. دو نام زیر نیز در فهرست local userها نبودند. [شاهد تازه](CONTINUATION_REVIEW.json).

| نام پیشنهادی، هنوز نامصوب/ساخته‌نشده | هدف | حق OS و ACL پیشنهادی | SQL |
|---|---|---|---|
| `.\BAZDIDDevWriter` | اجرای suite داخلی repositoryهای BAZDID در Development | standard local user؛ بدون Administrators و RDP؛ فقط Batch logon برای task مصوب، منع interactive/RDP؛ Read/Execute bundle و runtime، Write فقط پوشهٔ نتیجهٔ خودش | login از Windows، user در BAZDID_Development، عضو BAZDIDWriter |
| `.\BAZDIDDevReader` | مرز مستقل خواننده؛ فعلاً هیچ مبدأیی مصوب نیست | همان محدودیت OS، task و پوشهٔ نتیجهٔ مستقل | login از Windows، user همان پایگاه، عضو BAZDIDSourceReader؛ فعلاً هیچ SELECT مبدأ ندارد |

در SQL نام کامل باید از نام همان ماشین به شکل `<LOCAL_COMPUTER>\BAZDIDDevWriter` و Reader ساخته و با SID واقعی تازه‌خوانده‌شده تطبیق داده شود. placeholder نام ماشین/SID مقدار مصوب نیست؛ scriptها با NULL بسته‌اند. نام حساب پیشنهادی، موجود/مصوب معرفی نمی‌شود.

روش پیشنهادی اجرا پس از تصویب: دو Scheduled Task محدود، مثلاً `BAZDID-2F-Writer-Test` و `BAZDID-2F-Reader-Test`، با `RunLevel=Limited` و هویت مربوط؛ نه اجرای API با sysadmin و نه impersonation در connection factory. هویت فرآیند و SID، `ORIGINAL_LOGIN/SUSER_SNAME`، scope پایگاه و effective permissions باید در همان فرآیند کنترل شوند. SQL connection با Integrated Security همان token را مصرف می‌کند؛ گزینهٔ نام principal در تنظیمات account نمی‌سازد. [Batch logon](https://learn.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/log-on-as-a-batch-job) و [منع ورود محلی](https://learn.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/deny-log-on-locally) دو حق مستقل‌اند؛ GPO/denyهای ارثی نیز باید توسط مسئول Windows بررسی شوند.

برای این مدل، `Start-Process -Credential` با ورود interactive پیشنهاد نمی‌شود؛ ممکن است با منع ورود محلی تعارض داشته باشد. Service logon، تغییر IIS، عضویت admin یا دسترسی network گسترده لازم/پیشنهاد نشده‌اند. ساخت task و تغییر user rights نیز هنوز اجرا/تصویب نشده‌اند.

bundle تست باید بعد از انتخاب provider از خروجی کامل قابل بازبینی ساخته شود و تمام dependency/adapterهای test host را داشته باشد. مسیر پیشنهادی محلی ignored برابر `artifacts/restricted-tests/<RunId>/` و نتایج در `.sync-tmp/restricted-runs/<RunId>/<Writer|Reader>/` است. حساب‌ها فقط Read/Execute bundle و runtime و Modify پوشهٔ نتیجهٔ خود را بگیرند؛ به سورس، `.git`، تنظیمات خصوصی، profile مالک یا cache شخصی NuGet مجوز Write/Read فراگیر داده نشود. اجرای مستقیم dotnet test از checkout ممکن است به obj/cache مالک نیاز پیدا کند؛ bundle مستقل و probing path آن باید قبل از ثبت task بررسی شود. هیچ ACL یا bundle تازه‌ای اکنون ساخته نشده است.

رمزهای مستقل و تصادفی باید فقط توسط مسئول Windows/کانال امن مدیریت شوند؛ در chat، argv، script، Git، TRX یا log وارد نشوند. SQL loginها Windows هستند و SQL password ندارند. credential task توسط سازوکار امن Windows ثبت/گردش می‌شود؛ فایل exportشده حاوی credential یا حالت «رمز هرگز منقضی نشود» پیشنهاد نمی‌شود. این بسته، دستور نصب یا تغییر credential نیست.

## مجوز دقیق پیشنهادی و دو script بسته

| شیء | Writer مجاز | Writer منع صریح | Reader فعلی |
|---|---|---|---|
| dbo.BAZDIDCustomerLinks | SELECT, INSERT | UPDATE, DELETE, ALTER | منع SELECT/INSERT/UPDATE/DELETE/ALTER |
| dbo.BAZDIDRequestContexts | SELECT, INSERT, UPDATE | DELETE, ALTER | همان منع پنج‌گانه |
| dbo.BAZDIDAuditLogs | INSERT | SELECT, UPDATE, DELETE, ALTER | همان منع پنج‌گانه |
| پایگاه | CONNECT عادیِ user؛ بدون اختیار مدیریتی | CREATE TABLE/VIEW/PROCEDURE/FUNCTION/SCHEMA | همان منع CREATEها |
| اشیای مبدأ | هیچ مجوزی در این بسته | دسترسی حدسی ممنوع | هیچ SELECT تا تصویب شیء دقیق |

هیچ sysadmin، db_owner، db_ddladmin، CONTROL، grant با delegation، schema-wide DML یا UPDATE CustomerLinks پیشنهاد نشده است. Reader هیچ source object ساختگی یا واقعی ندارد؛ برای این ادامه نیازی به ساخت جدول مصنوعی پیشنهاد نشد. SELECT آینده فقط بعد از mapping/مجوز صریح همان شیء در تغییر مستقل بررسی می‌شود.

دو فایل فعلی برای بازبینی آماده‌اند، نه اجرا:

| فایل و ترتیب احتمالی بعد از تصویب | محیط و guard | SHA256 همین نسخه |
|---|---|---|
| [development_logins.review.sql](../../database/proposals/development_logins.review.sql) | master؛ دو login تازه FROM WINDOWS؛ نام ماشین/دو نام/SID/approval لازم؛ AllowDdl=0 | `9099DE3DCE8E77FC037D1BDC6D5B8649BA835253DF067E6B0E8D89B121B5B15F` |
| [permissions.review.sql](../../database/proposals/permissions.review.sql) | BAZDID_Development؛ فقط دو user/role و GRANT/DENY جدول بالا؛ AllowDdl=0 | `9888862C6997EB2AB0FC2EFFAAC6559E6399905E1290FEC506100AD46609A396` |

هر دو script نام ماشین/instance/Windows/LPC، نبود Cluster/HADR/linked server/DB غیرمنتظره و principalهای تازه با SID مصوب را guard می‌کنند. اگر user/role/login از قبل موجود باشد، با overwrite/repair ادامه نمی‌دهند. اجرای DDL داخل transaction است؛ script login نه Windows account می‌سازد و نه role مدیریتی می‌دهد. script permissions اجازهٔ اختیاری روی source را از نسخهٔ تاریخی حذف کرده است. فقط parser آفلاین TSql150Parser، دو فایل و دو template پویا را با صفر خطای syntax تأیید کرد؛ هیچ statement به SQL ارسال نشد.

تعریف role اثبات effective permission نیست. عضویت‌های Windows/public، grantهای مستقیم/ستونی، سایر database/server roleها و مالکیت schema باید با خود tokenهای دو حساب بررسی شوند. [قاعدهٔ Microsoft دربارهٔ DENY](https://learn.microsoft.com/en-us/sql/t-sql/statements/deny-object-permissions-transact-sql) استثنای column GRANT در برابر table DENY را هم دارد؛ فقط مشاهدهٔ DENY یا اتصال موفق کافی نیست. اگر حق اضافه‌ای یافت شود، test/activation متوقف شود؛ آن را خودکار حذف یا با sysadmin دور نزنید.

## TLS، SNI و شرط فعال‌سازی

خواندن registry همان instance نشان داد `ForceEncryption=0` و binding صریح Certificate خالی است. این، نبود certificate واقعی یا شکست TLS را ثابت نمی‌کند؛ SQL Server می‌تواند certificate را خودکار انتخاب یا تولید کند. گواهی ارائه‌شده به client، زنجیرهٔ اعتماد، SAN/نام سرور، اعتبار زمانی، Server Authentication EKU و ACL کلید خصوصی سرویس SQL هنوز بررسی عملی نشده‌اند. هیچ certificate، trust store، پروتکل، registry، firewall یا سرویس تغییر/Restart نشد. [الزامات گواهی](https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/certificate-requirements?view=sql-server-ver17)، [ترتیب انتخاب گواهی SQL](https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/configure-sql-server-encryption?view=sql-server-ver16).

شرط پیشنهادی runtime همان `Encrypt=true;TrustServerCertificate=false` با validation معتبر است. SQL Server 2019 هدف TDS8/Encrypt=Strict نیست؛ مقدارهای provider جدید را نباید بدون بررسی به builder قدیمی منتقل کرد. هیچ TrustServerCertificate=true یا Encrypt=false برای عبور تست پیشنهاد/اعمال نشد. استثنای قبلی ابزار metadata روی LPC، تنظیم provider برنامه یا اثبات TLS نیست. [سیاست encryption و validation](https://learn.microsoft.com/en-us/sql/connect/ado-net/encryption-and-certificate-validation).

LPC فقط همان ماشین را هدف می‌گیرد؛ موفقیت آن به‌تنهایی اثبات TLS شبکه نیست. روش Microsoft برای network encryption، Shared memory را از query مستثنا می‌کند. اگر اثبات TLS به TCP loopback نیاز داشته باشد، endpoint/port دقیق، certificate، محدودیت شبکه و تغییر محدود guard باید **جداگانه** تصویب شوند؛ اکنون هیچ TCP probe یا بازکردن پروتکل انجام نشد. شکست certificate باید ثبت/رفع شود و با bypass حل نشود.

provider موجود در فرآیند test x64 دوباره managed-load شد و فایل native موجود با PE machine `0x8664` و hash ثبت شد؛ candidate SNI بارگذاری یا اتصال آزمایش نشد. SNIهای 4.7.0/2.1.1/3.0.2/5.2.0/6.0.3/7.1.0 در metadata نامزدهای مربوط‌اند و با SNI گراف قبلی یکسان فرض نمی‌شوند. وجود DLL، احراز Windows، TLS یا pooling/disposal را اثبات نمی‌کند.

`SqlRuntime.Enabled=false` و `SqlRuntimeGate.ConnectedAcceptanceVerified=false` حفظ شدند؛ هیچ تنظیمی راه عبور نیست. پس از تصویب provider، حساب‌ها و test scope، تغییر activation باید جداگانه بازبینی شود: فقط Development، مقصد/هویت دقیق، default بسته، عدم Production، عدم fallback و آزمون واقعیِ provider برنامه. فعلاً نه branch فعال‌سازی و نه مسیر موازی اتصال ساخته شد.

## بازبینی هشت تست و شواهد واقعی این ادامه

هشت تست موجود بررسی و دست‌نخورده ماندند. کلید دقیق/tenant/دو درخواست، ownership، stale rowversion، rollback، رقابت، Writer permissions، timeout و cancel را هدف می‌گیرند؛ همگی با دلیل O24/O26 Skip باقی‌اند. gaps برای پذیرش بعدی: اثبات انتظار روی قفل به‌جای اتکای صرف به Delay، رقابت commitشده و idempotence بعد از قطع/commit مبهم، بررسی همهٔ منع‌های audit/DELETE/DDL، جداسازی Reader، بررسی native/TLS/pooling/disposal و شمار audit پیش/پس با verifier جدا. هیچ body غیرفعال، نتیجهٔ موفق معرفی نشده است.

پس از approvalهای لازم، اجرای اولیه باید rollback-only و با scope تصادفی ساختگی باشد. Writer خودش حق SELECT audit یا DELETE cleanup نمی‌گیرد؛ verifier جداگانهٔ مصوب، فقط شمار/شناسه‌های همان run را بررسی کند. مثبت‌بودن SELECT منبعِ Reader بدون شیء مصوب قابل آزمون نیست و Pending می‌ماند؛ منع دسترسی Reader به BAZDID مستقل آزموده شود. مجوز source واقعی از این بسته صادر نمی‌شود.

آزمون‌های commitشده به approval جدا برای `RunId`، شناسه‌های fixture، verifier و cleanup نیاز دارند. طرح cleanup: فقط ردیف‌های دقیق scope/run/فهرست GUID مصوب، بررسی نبود ردیف ناشناخته، حذف فرزندهای ساختگی با DBA/هویت cleanup جداگانه و transaction، سپس parent بدون وابسته؛ audit فقط با correlation/context مصوب همان run. در هر اختلاف شمار/مالکیت توقف؛ هیچ DELETE عمومی، پاک‌سازی ناشناخته، reseed، DROP یا بازسازی DB مجاز نیست. script اجرایی cleanup هنوز به‌علت نبود run مصوب تهیه/اجرا نشده و این طرح 2G نیست.

اجرای تازهٔ baseline: restore قفل‌شده و build exit صفر؛ صفر warning/error؛ **۱۰۹ unit + ۵۰ integration آفلاین = ۱۵۹ موفق، صفر شکست و ۸ SQL Skipped**. تست تازه‌ای ساخته نشد. SQL connected و effective permission test هر دو صفر؛ provider connection/native/TLS و repository DML اجرا نشده‌اند. ممیزی تازه همان ۹ بستهٔ دارای هشدار، از جمله Critical Kestrel و Moderate/High SQL Client را نشان داد. SQL schema دوباره مطابق و خالی بود. smoke Kestrel/IIS در این ادامه تکرار نشد. [CONTINUATION_REVIEW.json](CONTINUATION_REVIEW.json) شاهد شمارش/parse/metadata/audit است؛ شواهد تحویل اولیهٔ 2F بازنویسی نشدند.

## فرمان‌ها و روند واقعی

روند: احراز HEAD/status و حفظ hash فایل کاربر؛ خواندن دستورها/کد/اسناد؛ خواندن metadata Windows/SQL/registry؛ استخراج edgeهای App و دریافت nuspecها؛ تحلیل تقاطع؛ اصلاح پیش‌نویس permissions و ساخت پیش‌نویس login؛ parse آفلاین؛ regression baseline؛ تولید شواهد و این بسته؛ اعتبارسنجی اسناد/راز/Git و همگام‌سازی امن. هیچ package candidate یا نرم‌افزار تازه‌ای نصب نشد.

فرمان‌های واقعاً اجراشده از ریشهٔ Backend:

```powershell
git -c safe.directory=C:/Projects/vehicle-inspection-backend status --short
git -c safe.directory=C:/Projects/vehicle-inspection-backend rev-parse HEAD
& ./database/tools/Invoke-BazdidDevelopmentDatabase.ps1 -Action Verify
python .sync-tmp/cp2f-cont-metadata.py
dotnet 'C:\Program Files\dotnet\sdk\10.0.403\dotnet.dll' package list --project Bazdid.sln --vulnerable --include-transitive --no-restore --format json
dotnet restore Bazdid.sln --locked-mode
dotnet build Bazdid.sln --configuration Release --no-restore
dotnet test Bazdid.sln --configuration Release --no-build --no-restore --logger trx --results-directory C:/Projects/vehicle-inspection-backend/.sync-tmp/cp2f-cont-tests
python .sync-tmp/cp2f-cont-evidence.py
```

helperهای inspection/parse از فایل موقت با خواندن UTF-8 صریح و `ScriptBlock.Create` در PowerShell 5 اجرا شدند. ScriptDom موجود `161.8901.0/lib/net462` فقط parser بود و به dependency برنامه اضافه نشد. Windows metadata با WindowsIdentity/Get-LocalUser، SQL aggregateهای sys.server_principals و sys.database_principals/role_members، و registry SuperSocketNetLib خوانده شدند. مقدار credential، نام کاربران دیگر یا certificate/private key منتشر نشد. دریافت metadata فقط URLهای نسخه‌دار داخل PROVIDER_CANDIDATES را خواند؛ برای بازتولید، همان URLها و SHAها کنترل شوند.

نمونهٔ پیشنهادی بازتولیدِ منشأ قیدها، بدون restore یا تغییر فایل:

```python
import json
from pathlib import Path
assets = json.loads(Path('src/Bazdid.Api/obj/project.assets.json').read_text(encoding='utf-8-sig'))
target = next(iter(assets['targets'].values()))
for package, node in target.items():
    for name, version in node.get('dependencies', {}).items():
        if name in ('System.Data.SqlClient', 'System.Text.Encoding.CodePages'):
            print(package, name, version)
```

در یک helper اولیه، کنترل `$LASTEXITCODE` پس از script داخلی PowerShell به‌اشتباه verification را ناموفق خواند؛ JSON خود Verify موفق بود. نتیجه با Status=Passed و اجرای بعدی تأیید شد؛ وضعیت native executable و script PowerShell یکسان فرض نشد. هیچ خطای اتصالِ candidate رخ نداد، چون اتصال candidate اصلاً امتحان نشد؛ failure فرضی TLS یا رفع آن جعل نشده است.

## تصمیم‌های دقیق موردنیاز مالک

| شناسه | تصمیم لازم، هنوز تأیید نشده | مرز مجوز پیشنهادی |
|---|---|---|
| P0 | تهیهٔ طرح مهاجرت .NET10 LTS + ارزیابی Microsoft.Data.SqlClient6.1.7 LTS؛ یا تصمیم مستقل دربارهٔ آزمایش legacy | پیشنهاد این بسته فقط طراحی مهاجرت است؛ تغییر target/package به مجوز اجرای طرح بعدی نیاز دارد. حفظ 2.1 یعنی فعلاً gate بسته |
| P1 | تصویب دو نام `.\BAZDIDDevWriter` و `.\BAZDIDDevReader` و مسئول اجرای Windows با اختیار لازم | فقط local Development، standard users، Batch logon/task محدود، منع interactive/RDP و ACLهای محدود بالا؛ بدون حساب/گروه admin یا تغییر IIS |
| P2 | تصویب ساخت دو login از Windows و دو user/role و permissions جدول بالا، با نام کامل و SIDهای خوانده‌شده پس از ساخت P1 | فقط دو script با hash ثبت‌شده، همین instance/DB، ثبت مرجع جدید تصویب؛ default فایل‌ها بسته بماند؛ بدون source grant |
| P3 | تصویب طرح گواهی و روش آزمون TLS؛ در صورت نیاز TCP loopback با endpoint دقیق | بدون bypass، بدون تغییر خودکار certificate/trust/firewall/restart؛ اجرای هر تغییر زیرساخت جدا تصویب شود |
| P4 | تصویب تغییر محدود gate و اجرای rollback-only با provider/هویت‌های تأییدشده؛ تعیین verifier جدا برای audit counts | پس از P0 و پذیرش provider، P1/P2 و TLS؛ همهٔ effective permissionها با خود حساب‌ها، بدون sysadmin runtime |
| P5 | fixture و cleanup دقیق برای تست‌های commit/قطع ارتباط | پس از آماده‌شدن run واقعی و فهرست ردیف‌ها جدا بازبینی شود؛ approval کلی این سند مجوز DELETE ناشناخته نیست |

پیشنهاد این تحویل، تصمیم دربارهٔ **P0 و نام‌ها/حدود P1** و بازبینی P2 است؛ P4/P5 هنوز آمادهٔ اجرا نیستند. برای مرحلهٔ بعد، تصمیم انتخابی و دامنهٔ تصویب‌شده باید از پاسخ مالک به همین بسته به‌روشنی قابل احراز باشد؛ هر تصویب قبلی در محدودهٔ خودش معتبر می‌ماند. رمز یا connection string محرمانه در گفتگو فرستاده نشود.

برای ابطال آینده: ابتدا taskهای همان حساب متوقف و SIDها با ثبت زمان ساخت تطبیق داده شوند؛ دسترسی login/user فقط با تصویب جدید مسدود و sessionهای دقیق همان SID بررسی شوند. عضویت Windows group می‌تواند اثر غیرفعال‌کردن login منفرد را تغییر دهد و باید جدا کنترل شود. پس از تأیید نبود session/مالکیت schema یا عضو نامرتبط، user/role/loginهای همین بسته و سپس local user/task/right/ACLهای اختصاصی با مسئول Windows/DBA حذف شوند. هیچ دادهٔ کسب‌وکار یا حساب/عضویت دیگر حذف نشود؛ credentialهای task/vault نیز revoke شوند. اگر login ساخته ولی permissions شکست خورد، بدون repair خودکار متوقف شود؛ DB user/role از transaction ناموفق باقی نمی‌ماند و loginهای مرحلهٔ قبلی باید جدا بررسی شوند. این‌ها رویهٔ پیشنهادی‌اند و اکنون اجرا نشده‌اند.

فایل‌های این ادامه: این سند، PROVIDER_CANDIDATES و CONTINUATION_REVIEW و شاهد کنترل تحویل؛ پیشنهاد login جدید و permissions اصلاح‌شده؛ walkthrough موجود و PLAN/README/AGENTS/تصمیم‌ها/ادامهٔ AI/راهبرد آزمون/فهرست راهنما/راهنمای database/منابع به‌روز می‌شوند. کد runtime، gate، package/lockfile، هشت تست متصل، schema، endpoint و Frontend تغییر نمی‌کنند. SHA commit و شواهد ارسال در [GITHUB_SYNC_FA.md](../GITHUB_SYNC_FA.md) ثبت می‌شوند؛ وجود این بند اثبات push نیست.

**پیشرفت قبلی 20 + سهم این آماده‌سازی 0 = فعلی 20%؛ باقی 80%.** پس از پذیرش کامل همین 2F هدف مشروط 22% است؛ درصد پایان Checkpoint 2 برابر 24% می‌ماند. فعلاً 2F قابل پذیرش کامل نیست؛ توقف پیش از تغییر provider/حساب/SQL/activation و بدون شروع 2G، OTP، Session، Info، رسانه یا Production.
