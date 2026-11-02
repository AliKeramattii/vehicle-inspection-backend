# شناسنامهٔ منابع و حل تعارض‌ها

تاریخ بازبینی `2026-11-01`؛ منابع بدون تغییر و فقط به اندازهٔ نیاز Phase 0 مطالعه شده‌اند. دستور جاری مالک پروژه بالاتر از proposalهای قبلی است. این سند منشأ را ثبت می‌کند و قرارداد اجرایی جدیدی از روی اسناد تولیدشده جعل نمی‌کند.

## نسخه و حدود مطالعه

Frontend خواندنی: `C:\Projects\vehicle-inspection-integrated`؛ شاخهٔ `feat/unified-ui-admin-3d` و HEAD مشاهده‌شده `448fa6aa9ce29f4fbf535203dbb96d2e862565ce`. worktree از قبل تغییرهای متعدد tracked/untracked دارد؛ HEAD به‌تنهایی نسخهٔ محتوای خوانده‌شده نیست. hash فایل‌ها در پایین، snapshot واقعی محتوای موجود را مشخص می‌کند. status اولیهٔ خوانده‌شده حفظ و با انتهای کار مقایسه می‌شود؛ Git Frontend با `GIT_OPTIONAL_LOCKS=0` و `safe.directory` فقط در همان فرمان خوانده شده، config سراسری آن تغییر نکرده است.

منبع دستور قطعی این وظیفه، فایل پیوست کاربر `Pasted text.txt` در شناسهٔ پیوست `cb10c396-14be-4d19-8cf8-15e712325a60` است؛ SHA-256 آن `8d96c52e4a95416c035b56b1826ac9e8f90ba531fc61c8fe27ccb260fa85f360` است. متن کامل پیوست دوباره به مخزن کپی نشده و الزاماتش در AGENTS/PLAN و اسناد موضوعی ثبت شده‌اند.

header تحویل جامع مبنای `74ef004836021656aa4d7ad8d31af9c7ae6551fe` در `2026-10-28` را ذکر می‌کند. README بسته مبناهای `fbc1bba/0e75f9c` و فصل provenance مبنای `cb4f1fc299d0bf159ce6dc1557842b717140e5e8` در `2026-10-27` دارند. این‌ها نشانهٔ snapshotهای تاریخی متفاوت‌اند؛ با HEAD امروز یکی فرض نمی‌شوند و hash محتوای هر فایل ملاک دقیق این تحلیل است.

| منبع canonical یا بخش | نحوهٔ استفاده |
|---|---|
| [تحویل ضروری](reference/BACKEND_ESSENTIAL_HANDOVER_FA.md) | مرور ساختار، workflow، قواعد، scope API/SQL و تصمیم‌ها؛ جزئیات حجیم endpointها از JSON خوانده شد |
| [تحویل جامع](reference/handover_full.md) | عنوان/نسخه، فهرست، فصل‌های زمینه، معماری و قواعد به‌صورت گزینشی؛ فایل حدود ۱٫۳۵MB کامل در context تکرار نشد |
| [README بسته](reference/README.md)، [provenance](reference/25-CONTRACT-STATUS-AND-PROVENANCE.md) | وضعیت پیشنهادها، شمارها، نسخه‌ها و محدودیت اثبات Backend |
| [الزامات نهایی](reference/FINAL_BUSINESS_REQUIREMENTS.md)، [قواعد مدرک](reference/03-BUSINESS-REQUIREMENTS.md) | مالکیت درخواست، نسخه‌ها، ۱۱ عکس، ویدیو، کیلومتر و عدم جعل forwarding |
| [چرخهٔ عمر](reference/11-INSPECTION-LIFECYCLE.md)، [اتصال](reference/22-FRONTEND-BACKEND-INTEGRATION.md)، [مدل‌ها](reference/28-DATA-MODELS-REFERENCE.md) | enumها، projection، مرز adapter و واقعیت mock |
| [منبع بیرونی](reference/29-SOURCE-SYSTEM-CONTRACTS.md)، [تصمیم‌های قدیمی](reference/23-OPEN-DECISIONS.md) | نیاز mapping/SMS/ack؛ بدون فرض وجود قرارداد مصوب |
| [هویت](reference/10-AUTHENTICATION-AND-SSO.md)، [رسانه](reference/08-MEDIA-FILE-STORAGE.md)، [میزبانی](reference/16-DEPLOYMENT-AND-SERVER-REQUIREMENTS.md) | مطالعهٔ بخش‌های مرتبط و تعارض با دستور جدید |
| [endpoints.json](reference/contracts/endpoints.json) | همهٔ method/path و ID/schemaها بررسی شد؛ برخی DTOهای مشتری عمیق‌تر مقایسه شدند |
| [schemas.json](reference/contracts/schemas.json) | Referral/Otp/Session/Vehicle/Location/Odometer گزینشی؛ ۸۰ DTO قرارداد اجراشده نیستند |
| [schema-manifest.json](reference/sql/schema-manifest.json) | نام/هدف و فهرست ستون‌های هر ۳۷ جدول بررسی شد؛ هر جدول در طرح جدید تعیین تکلیف دارد |
| `docs/API_FA/` در Frontend | منبع canonical قابل ویرایش بسته؛ مقایسهٔ hash نسخه‌های محلی با فایل‌های متناظر موجود انجام شد |
| کد فعلی Frontend؛ جدول hash پایین | type/schema/form/repository/mock/identity/template و adapterهای مستقیم برای استخراج فیلد و تعارض |

فایل‌های دیگر تحویل‌شده و ZIP دوباره کپی یا استخراج نشده‌اند؛ ثبت hash آن‌ها به معنی مطالعهٔ کامل یا تأیید تمام محتوایشان نیست. فهرست ZIP و الگوهای رایج راز در متن‌های آن بدون استخراج بررسی شد. SQL پیشنهادی موجود اجرا نشده است. ابزارهای generator داخل Frontend اجرا نشده‌اند تا فایل مرجع تغییر نکند.

مبدأ دو فایل با چیدمان متفاوت نیز شناسایی شد: `FINAL_BUSINESS_REQUIREMENTS.md` از `docs/02-project-overview/FINAL_BUSINESS_REQUIREMENTS.md` و ZIP از `docs/handover/BACKEND_HANDOVER_ESSENTIAL_FA.zip` در Frontend است. باقی فصل‌ها/JSON/SQL از `docs/API_FA/` و دو handover اصلی از `docs/handover/` مقایسه شده‌اند.

## منابع مفقود و پیوندهای تاریخی

نام دقیق `MASTER_PRODUCT_BUSINESS_SPECIFICATION_FA.md` در دو محل مورد بررسی و جست‌وجوی فایل‌های Projects پیدا نشد. برای قواعد، دستور مالک، FINAL_BUSINESS_REQUIREMENTS، فصل ۳ و کد فعلی استفاده شد؛ ادعای یافتن یا هم‌ارزی کامل سند مفقود نمی‌شود.

پوشهٔ محلی `docs/reference/API_FA/` وجود ندارد، اما فصل‌ها و JSON/SQL آن مستقیماً داخل `docs/reference/` هستند. دو فایل handover در همین محل موجود و نسخهٔ متناظر Frontend آن‌ها نیز قابل خواندن بود. برخی پیوندهای درون بستهٔ مرجع هنوز relative به layout اصلی Frontend هستند و پس از کپی مسطح به مقصد ناموجود اشاره می‌کنند؛ وضعیت آن‌ها در گزارش اعتبارسنجی ثبت می‌شود. اسناد تازه فقط به فایل موجود لینک می‌دهند؛ منابع تاریخی بی‌اجازه بازنویسی نمی‌شوند.

schema واقعی SQL کارگزاری، SMS contract، محیط IIS مقصد و API تجاری اجراشده در منابع تحویلی وجود ندارند؛ نام‌های پیشنهادی SQL و endpointها جای آن‌ها نیستند.

## تعارض‌ها و تصمیم این تحلیل

| موضوع | شواهد قبلی/فعلی | نتیجه و برچسب |
|---|---|---|
| فناوری | اسناد قبلی نسخهٔ دارای پشتیبانی را باز گذاشته‌اند | دستور جدید `netcoreapp2.1` قطعی؛ EOL و gate امنیت حفظ می‌شود |
| پایگاه | manifest، SQL Server 2022 و master linkage پیشنهادی دارد | نسخه نامعلوم؛ استفاده از پایگاه موجود؛ master واقعی تکثیر/تغییر نمی‌شود |
| ۳۷ جدول | نام‌های فاقد BAZDID و دامنهٔ کامل staff/brand/forwarding | فقط ۱۷ جدول تدریجی مشتری پیشنهاد می‌شود؛ همهٔ تازه‌ها BAZDID؛ جدول‌های آینده مؤخر |
| ورود مشتری | essential/فصل ۱۰ ticket/SSO را آغاز جریان می‌دانند | جریان قطعی جدید referral → request reader → OTP → session است؛ ticket اکنون پیاده نمی‌شود |
| مرجع verify | سند بیرونی امکان verify مبدأ را باز می‌گذارد | BAZDID مرجع verify است؛ SMS adapter برای ارسال، طبق دستور جدید |
| OTP DTO | mock، mobile دارد؛ schema مرجع challenge دارد و ReferralResult فاقد context است | حذف mobile از فرمان، افزودن context به resolution و binding سروری؛ **پیشنهاد اصلاح قرارداد** |
| API base | `/api` نمادین و `/api/bazdid` در متون قدیمی | `/API/BAZDID/` قطعی؛ فقط PathBase، بدون prefix کنترلر تکراری |
| trusted fields | فرم فعلی تغییر پلاک/رنگ را اجازه می‌دهد و make/model/year/VIN مفقود فرم ورود ندارند | trusted در سرور قفل؛ فرم‌های آینده باید metadata منشأ را رعایت کنند؛ **شکاف integration** |
| Vehicle DTO | مدل و قرارداد سال/رنگ/VIN نام‌های متفاوت و مقادیر required دارند | mapping صریح و nullability/منشأ جدید؛ placeholder ممنوع |
| محدودیت مکان | schema قدیمی address/ساختمان/پارک ۵۰۰/۴۰/۵۰۰؛ فرم ۳۰۰/۲۰/۳۰۰ | پیشنهاد API این فاز مطابق فرم جاری؛ تصویب در O10 |
| lifecycle | enum UI با وضعیت‌های lifecycle و forwarding متفاوت است | نگاشت صریح؛ حروف کوچک/بزرگ تبدیل قراردادی نیست |
| storage | سند مرجع همان ساختار را ترجیحی و D05 باز می‌داند؛ قرارداد قدیمی ریشه مستقیم inspection است | ساختار GUI/INSPECTION طبق دستور جدید قطعی؛ drive/ACL/backup باز |
| Admin | سند قدیمی staff مبتنی بر SSO و بدون رمز محلی پیشنهاد می‌کند | نیاز جدید bootstrap و ساخت Admin/Reviewer؛ طراحی shared staff+role و `BAZDIDAdmin` بدون credential تکراری، روش نهایی باز |
| ۱۲ عکس تاریخی | v1 دوازده‌عکسی و v2 یازده‌عکسی هم‌زمان در template فعلی‌اند | تعارض نیست؛ pinned نسخه حفظ می‌شود، تازه‌ها v2 و ۱۱+ویدیو |
| آمادگی Frontend | build معمولی و mock کامل، static export کل را ثابت نمی‌کنند | هیچ ادعای آمادگی Production/SSO/تحویل از ظاهر UI نتیجه گرفته نمی‌شود |

قطعی‌ها از دستور مالک و قواعد محصول‌اند؛ نام/شمار جدول مشتری، مسیرهای تازهٔ information/csrf/receipt، حذف aliasهای خودرو، packageها و policy زمان/حجم **پیشنهاد** هستند. هیچ API تجاری با برچسب `EXISTING VERIFIED BACKEND API` در این بررسی تأیید نشده است.

## منابع فنی بیرونی بررسی‌شده

در `2026-11-01` منابع رسمی برای اعتبارسنجی فناوری و پیشنهاد dependencyها مرور شدند؛ نتیجهٔ هدف package جای restore/build نیست.

- [.NET Core 2.1: نسخه‌های SDK/Runtime/Hosting Bundle](https://dotnet.microsoft.com/en-us/download/dotnet/2.1).
- [پایان پشتیبانی 2.1](https://devblogs.microsoft.com/dotnet/net-core-2-1-will-reach-end-of-support-on-august-21-2021/).
- [IIS و sub-application](https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/iis/?view=aspnetcore-2.1)؛ صفحهٔ Learn بخش‌هایی مشترک بین نسخه‌ها دارد و نمونهٔ جدید مستقیماً مبنا نیست.
- [اعلام محدودیت in-process برای 2.1](https://github.com/aspnet/Announcements/issues/302).
- [وصله‌های SameSite در 2.1](https://devblogs.microsoft.com/dotnet/upcoming-samesite-cookie-changes-in-asp-net-and-asp-net-core/).
- [حفاظت key ring فایل](https://learn.microsoft.com/en-us/aspnet/core/security/data-protection/implementation/key-storage-providers?view=aspnetcore-5.0)؛ فقط ملاحظهٔ persistence/encryption استفاده شد، APIهای جدید از این صفحه برای 2.1 تأیید نشده‌اند.
- metadata رسمی NuGet برای [Swashbuckle 4.0.1](https://www.nuget.org/packages/Swashbuckle.AspNetCore/4.0.1)، [SqlClient 4.8.6](https://www.nuget.org/packages/System.Data.SqlClient/4.8.6)، [EF Core 2.1.14](https://www.nuget.org/packages/Microsoft.EntityFrameworkCore.SqlServer/2.1.14) و [Dapper 1.60.6](https://www.nuget.org/packages/Dapper/1.60.6).

## اثر انگشت منابع

جدول‌های زیر SHA-256 کامل بایت فایل‌ها را ثبت می‌کنند. «یکسان» یعنی hash فایل محلی با متناظر Frontend موجود برابر است؛ این وضعیت قرارداد Production را تأیید نمی‌کند. فایل مرجع غیرخوانده‌شده هم برای بازتولید snapshot hash می‌شود.

<!-- HASH_MANIFEST_START -->

### منابع تحویل‌شدهٔ محلی

| فایل نسبت به `docs/reference/` | SHA-256 | مقایسه با Frontend |
|---|---|---|
| `01-PROJECT-OVERVIEW.md` | `d5ab2c91f3602a5bc3dac39d9b0b9952ef0ecf5e8e4c872229a920bb32d7bb9c` | یکسان |
| `02-SYSTEM-ARCHITECTURE.md` | `80b820db9dbf085d09648818cd1ed4f671a50ce641694a3ec50006652906d2a6` | یکسان |
| `03-BUSINESS-REQUIREMENTS.md` | `f81ab6ccda1886b54d87b89d48a7420a2ffc5c7b3254c7a22ab15eef27466522` | یکسان |
| `04-COMPLETE-API-REQUIREMENTS.md` | `c0c4c49681ef603d473eb5ca0612fd873436a9a37689367eb7e6a84e4ad5ddc4` | یکسان |
| `05-API-CONTRACTS.md` | `0d29796438a774001f2d4447da774e584bfea2245f6df09116b2f2a3073e8543` | یکسان |
| `06-DATABASE-DESIGN.md` | `68c3fe00a938d7b66c73bcf992e3554edf75c30b6c5414ed00650959e4dd187b` | یکسان |
| `07-DATABASE-RELATIONSHIPS.md` | `bc98da15f409d843400d61fb55bbc3547e4f55173a70e6dde777b767bbabd334` | یکسان |
| `08-MEDIA-FILE-STORAGE.md` | `20cb59804ff9f05b234697cc4c286b4101413031ff5990a7e32789e8950bf1ee` | یکسان |
| `09-UPLOAD-AND-MEDIA-PROCESSING.md` | `a12e13dedf0bf343a46505afa01a34ad3325a0e86201739808ee73a410f5a5bb` | یکسان |
| `10-AUTHENTICATION-AND-SSO.md` | `393996a48871ea2fe3855513923901685e25a51926cf00436b49a7dd609281f8` | یکسان |
| `11-INSPECTION-LIFECYCLE.md` | `9bbba231949ed3d476a81eed86b8a3c8e762f0f05b199cbb98d5c02c15bdae7f` | یکسان |
| `12-REVIEWER-OPERATIONS.md` | `1f3e1e20c1320dac7c1eacf590fbdf09aa2895f1e92657f0a4b78afe534fed80` | یکسان |
| `13-ADMIN-AND-SITE-SETTINGS.md` | `322db2e6e87a2630c6295c0e9d7df7dbe7603eae24e4d725c291556de0b93e68` | یکسان |
| `14-BROKERAGE-FORWARDING.md` | `cafbc79793ac147d49d5b02760050e8adff5af2550c63bd1d8ec0855381375b2` | یکسان |
| `15-SECURITY-AND-TENANT-ISOLATION.md` | `81b512c574affcd97aaebc461653158c12d98c30f131441ce49fcb24e41e7f3d` | یکسان |
| `16-DEPLOYMENT-AND-SERVER-REQUIREMENTS.md` | `740938bf1e3c799e255629f1bf2b20b3cfcf8a6af64cc31acaac463e505dfd78` | یکسان |
| `17-ERRORS-AND-HTTP-STATUS-CODES.md` | `af3ed3b17b54983b019ab7e3014c1f697df027fdffcc284a146fb198e4a51ae1` | یکسان |
| `18-IMPLEMENTATION-PRIORITIES.md` | `6d44aa588c0cd633f762f9f86281942b19664a0d5c8b0e2fa227fe51ca479143` | یکسان |
| `19-BACKEND-TEAM-QUESTIONS.md` | `5a9d0d5c024b26f3f644651f296a8db68ea5eef6087834cb74a64b6eef643df6` | یکسان |
| `20-API-DATABASE-MAPPING.md` | `71623220b657c744fb5a1f0ea373d8c2c1ab24f8ef86266859dcb11fec2cb6b8` | یکسان |
| `21-TESTING-AND-ACCEPTANCE.md` | `3287391aae31861cabb3305f6af89d3e1c6f7534d294e9cb8beb7849f19a7696` | یکسان |
| `22-FRONTEND-BACKEND-INTEGRATION.md` | `9dd6530c20f70f68bcafaabcd27bd323c60674970622da884ddee871a6db92dc` | یکسان |
| `23-OPEN-DECISIONS.md` | `6117e9479ae0a665bedada7ef883d759b3730711a73f4c68ff52c012ec1675d8` | یکسان |
| `24-DATABASE-TABLE-BLUEPRINTS.md` | `1f1378de8c5f192fd5cc39816b728bbb983b9e32578c38a94901774fa036c2f3` | یکسان |
| `25-CONTRACT-STATUS-AND-PROVENANCE.md` | `c1a483853189f044db7fe0c1ddd825002cb84038912c69e33552c945ae64b41f` | یکسان |
| `26-ROLES-AND-PERMISSIONS.md` | `0b9cf3e2aaaef8d045307c9272dabe7be409423feda0392d83132d48b811a473` | یکسان |
| `27-DELIVERY-CHECKLIST.md` | `f6704d466e00f4859730df2f6b83f2ba66412cdbd11f258a87729c4c04bbe127` | یکسان |
| `28-DATA-MODELS-REFERENCE.md` | `048f51f45994ed5e2b68bd0eeb08f4ad92360e443429a6ccf95af8ca564e6d8e` | یکسان |
| `29-SOURCE-SYSTEM-CONTRACTS.md` | `c0135eb7490fdec7df95981b73dab09a720e6494e63aab220d365d4284f3d40c` | یکسان |
| `30-GLOSSARY.md` | `e6619027e4ee572bb574f379045c9ca049752fed396f98ee55d64ac3b537a860` | یکسان |
| `BACKEND_ESSENTIAL_HANDOVER_FA.md` | `55ff00d51e9eac63b62250e88fb27888d5f6b62f4aab0090177db85d78d0cf87` | یکسان |
| `BACKEND_HANDOVER_ESSENTIAL_FA.zip` | `bb5516af19ca8c601ba56a32663b215c4bc2d778d93fd76989f2ceb3b89de450` | یکسان |
| `contracts/endpoints.json` | `a635689900e174d369e8b2b0d523052e70b923308f398c627ed38b913bdd3dd8` | یکسان |
| `contracts/examples.json` | `09a87399de8385fdca88ab0833b2b0ff2e0047e513caca9f025c1decb0014133` | یکسان |
| `contracts/operations.json` | `e10cc918019fbd23f544c44ca836ea94d492683460d9d975bf2073ee8431040c` | یکسان |
| `contracts/schemas.json` | `1896d16803ac9c8d5061b73e8a223ee7ccfac6ad9b99367eef29b1167b007553` | یکسان |
| `ESSENTIAL_HANDOVER_FA.md` | `1492aeffe34ea83792bc0c29d7e98fb13002bbc36216457d8b3950cb95be49f0` | یکسان |
| `FINAL_BUSINESS_REQUIREMENTS.md` | `a9c223e91589079391c0f7995c6a5f79a64a6364b7d58b884f60a71335c072af` | یکسان |
| `HANDOVER_CONTEXT_FA.md` | `3740a9bb267f543c8e9b6e00f7e5569cbf9f0742a6eb10a34eba26610ddc5d04` | یکسان |
| `handover_full.md` | `55c0c03d2da6aa0a36a70562f77af31d693a5bfb18524712f832afa84611934b` | یکسان |
| `HANDOVER_SOURCE_DISCOVERY_FA.md` | `88893aa833797bb97373781d98071482050c934f39b4fe14d2ce1e12d4a5fa43` | یکسان |
| `README.md` | `eb3795978c37f2c43e1d6130cbc42d9bcb69a51d57a581a2270f7b0868575d11` | یکسان |
| `sql/DATABASE_DIAGRAM.md` | `b3c4ae7695c858611b1a9250eb811570a03d85ae2c3a4e982914a7e00c8c1cc3` | یکسان |
| `sql/PROPOSED_SCHEMA.sql` | `7048814256e14f44ce16b5550f28d0495a35107439449863504e720f27302ebc` | یکسان |
| `sql/schema-manifest.json` | `0fb754fbe3c9cada8ce5734848528cc10dcd51575e51031cd724e779498baeb0` | یکسان |

### فایل‌های مستقیم Frontend

مسیرها نسبت به مخزن Frontend هستند؛ فایل‌های schema/form/type مستقیماً و template/مدل ارسال در بخش‌های مرتبط خوانده شدند.

| فایل | SHA-256 |
|---|---|
| `AGENTS.md` | `19bcfdf0da9dd897d2be5e9cba87a7642d5b45613450c95b9dfb6a68862c2577` |
| `src/schemas/auth.ts` | `736cfc12debce498c8d86b1cbf1fe54cdd9ddb91e711660e45d4f85090221886` |
| `src/schemas/domain.ts` | `4548fb426fbb5aeaeeaf3a4567927e583b016709f6971ed40c63258122be990b` |
| `src/types/auth.ts` | `76ea7d723211eceb1a2827f227d340eec94bc59a074d04864c9d8f94e881b410` |
| `src/types/domain.ts` | `050f85b6623a425e417ede96e97a42d0cded8d6e18109c02192b4634fbb49cfb` |
| `src/features/vehicle/vehicle-model.ts` | `c21f0454cf740c5986fdcbaf1ff566d8e3b42b6fd9184553cc964067eb1259df` |
| `src/features/vehicle/vehicle-form.tsx` | `791bc5428812916eb6cb08cec6d1e5e10d29ef50c46118bdf93fc6b674a44511` |
| `src/features/location/location-model.ts` | `37abb31cbba3191711c1977cd1fc4767597ccfbf3be9911f988547c6b5b05ab5` |
| `src/features/location/location-form.tsx` | `46fd30d8030b7e4a525b03d02b8848d388eae74b1b0833686faba5b2aa231dc3` |
| `src/lib/map/location-selection.ts` | `70b2471bd06c167deb76cb12b597ac55507a4aaddbb23c2c6b700ef3073bfd1c` |
| `src/features/consent/consent-model.ts` | `47f84de9ba4c59e24c9d63f4465ea6b0bf2d61cc3e7d1524904a18fa5642d796` |
| `src/features/identity/source-context.ts` | `3279218138fd329c12ef4c9419a97093efa9b31d256924cc36e869c809bd4f94` |
| `src/features/photography/inspection-template.ts` | `5202e59d57784f7da6ea58cd4be056a708feb59ce7b64d23e4da7653abe9cfc4` |
| `src/lib/api/repositories.ts` | `3dcfa37b3f557aa8de118b9a132d7b6746cd4105145793335a2af3c1d1a2c60c` |
| `src/lib/api/adapters/inspection.ts` | `70f97d8d6b3e62e5ea62d15dd9d2270cdec252ad38ce05d8a05ba9bcfe91e107` |
| `src/mocks/auth-repository.ts` | `820e3c104bbfb009773818ce766ab052f2e7043f3d9768231938a02860c13970` |
| `src/features/auth/config.ts` | `88f2665f8aff72a0b39c2873040a38ca2036f6d009fb14aa117192d4cb176d7f` |
| `src/features/submission/submission-model.ts` | `1b61e3cb65059efd735198dc6aa63a4e4691ce006c0b4b5cea5cb489435d1a82` |

## تطبیق و تعارض‌های طراحی 2E — 2026-11-02

جدول‌های hash بالا شاهد تاریخی مطالعهٔ اولیه‌اند؛ برای 2E، [hash بایت جاری ۲۶ فایل Frontend](checkpoint2e/FRONTEND_REVIEW.json) مرجع است. HEAD مرجع Frontend `448fa6aa9ce29f4fbf535203dbb96d2e862565ce` با ۲۲۶ تغییر قبلی، نسخهٔ تمام working tree را ثابت نمی‌کند. هیچ منبع یا آرشیو اختصاصی تازه منتقل نشد. تصمیم فعلی در [طرح 2E](implementation/CHECKPOINT-02E-INFO-PERSISTENCE-DESIGN_FA.md) پیشنهادِ Checkpoint 4 است، نه تغییر رفتار اجراشده.

| شناسه | تعارض واقعی | تصمیم طرح و gate |
|---|---|---|
| E-C01 | Vehicle کامل Frontend در برابر فیلد nullable/منشأدار reader | DTO آینده nullable و envelope؛ adapter آینده باید نقص را نشان دهد؛ بدون placeholder؛ O10/O29 |
| E-C02 | اصلاح plate/color trusted در فرم/mock و fallback سفید | قفل Present در Backend، manual فقط Missing صریح، confirmation بدون ارسال مقدار trusted؛ بدون تغییر Frontend در 2E |
| E-C03 | year عددی بدون تقویم در UI، رشته در 2D و CarYearSakhtId در سورس قدیمی | زوج سال/تقویم با SourceText؛ ID سال، مقدار سال نیست؛ O09/O29 |
| E-C04 | VIN و شاسی در عنوان UI یکی دیده می‌شوند؛ reader دو فیلد دارد | ذخیره/validation مستقل، خروجی mask و assurance؛ O28/O29 |
| E-C05 | SourceVersion غیرخالی 2D در برابر source واقعی احتمالاً فاقد version | تغییر پیشنهادی آیندهٔ mode/nullable version و hash؛ در این مرحله کد حفظ و نسخه از ساعت جعل نشد؛ O30 |
| E-C06 | پیشنهاد تاریخی Info، raw source IDs تکراری و Status تک‌محوری داشت | طرح جدید فقط مراجع داخلی pinned و provenance چندمحوری؛ source IDs از linkage/context، Manual شاهد Missing را حفظ می‌کند؛ manifest جدید مرجع پیشنهاد آینده است |
| E-C07 | factsConfirmed محلی از وجود object و مسیرهای /api در endpoints UI | readiness/ownership سروری و فقط مسیرهای planned /API/BAZDID؛ بدون alias یا افزودن route زنده |
