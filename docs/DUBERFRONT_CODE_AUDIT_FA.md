# ممیزی DuberFront و آمادگی نگاشت SQL — Checkpoint 1.5

تاریخ `2026-11-01`؛ مبنای Backend در شروع `d773c1a` و worktree پاک بود. مجوز این وظیفه فقط تحلیل و همگام‌سازی است؛ **Checkpoint 2 شروع نشده است**. هیچ کد آرشیو اجرا، dependency نصب، SQL متصل/اجرا یا فایل Frontend تغییر داده نشد.

این گزارشِ تاریخی، walkthrough همین ممیزی نیز هست و در [فهرست فرایندها](implementation/README.md) معرفی می‌شود. ترتیب کار ثبت‌شده: احراز Git/دامنه، central directory و hash، انتخاب متن‌های محدود، جداسازی کد فعال از کامنت، ردیابی request/mobile/Session/EF، تطبیق شواهد و تکمیل ماتریس/تصمیم‌ها، سپس validation و push امن. مسیرها و محدودیت‌های هر بخش در ادامه آمده‌اند؛ کد اختصاصی در گزارش نقل نمی‌شود.

ابزارهای خواندن محدود، موقت و ignored بودند و پس از کار حذف شدند؛ این گزارش ادعای وجود یک ابزار ممیزیِ قابل نصب در مخزن ندارد. برای بازآزماییِ مجاز، ابتدا همان hash/central directory و قواعد سقف حجم/نسبت/مسیر احراز شوند و فقط متن‌های شاهد خوانده شوند. دستورهای آن ابزار موقت یا log کامل در artifact پایدار موجود نیستند؛ دستور استخراج کلی یا اجرای آرشیو جای آن‌ها ارائه نمی‌شود. ممیزی یا hash آرشیو در وظیفهٔ نگهداری مستندات تکرار نشده است؛ وضعیت جاری از PLAN خوانده شود.

## ۱. شناسنامه و حدود بازرسی امن

| مشخصه | نتیجهٔ central directory |
|---|---|
| محل اصلی | `C:\Projects\reference-archives\DuberFront.zip`؛ بیرون مخزن Backend |
| اندازهٔ ZIP | `526233999` بایت؛ حدود ۵۲۶ مگابایت |
| محتوا | ۲۲۶۳ entry؛ ۲۰۶۰ فایل و ۲۰۳ directory |
| اندازهٔ بازشدهٔ اعلامی | `622870300` بایت؛ فقط metadata، بدون استخراج کلی |
| فایل‌های شاخص | ۷۵۲ `.cs`، ۴۶۰ `.cshtml`، ۵۱ `.js`، یک `.csproj` و یک `.sln`؛ شمار CS شامل خروجی تولیدشده نیز هست |
| ساختار | `DuberFront/Duber/{Controllers,Models,Views,Helpers,Api,Areas,Properties,wwwroot,bin,obj}` و `.vs` |
| ورودی پرخطر | مسیر traversal/absolute/ADS، symlink، رمزگذاری یا برخورد case مشاهده نشد؛ ۱۱ ZIP تو‌در‌توی حدود ۴۴MB از حد خواندن متن بزرگ‌تر بودند و کنار گذاشته شدند |
| فایل‌های کنارگذاشته‌شده | هر ۱۲ ZIP داخلی، DLL/PDB، دو `.lnk`، خروجی IDE/build، فایل‌های داده/تصویر/Excel؛ بررسی یا اجرا نشدند |

SHA-256 آرشیو:

```text
1a56ddc44707d55c4a30e8635ac81a8af2ca0e1c7abb793973c7d6c621abc1b3
```

هیچ `extractall` یا استخراج filesystem انجام نشد. متن‌های منتخب با سقف ۲MiB هر فایل، نسبت فشردگی حداکثر ۲۰۰ و بودجهٔ محدود در حافظه خوانده شدند؛ ۲۸۷ فایل C# خارج bin/obj/wwwroot/کد تولیدشدهٔ سرویس، جست‌وجوی ساختاری شدند. source کامنت‌شده از کد فعال تفکیک شد. literalهای حساس در خروجی حذف شدند و source در مخزن ذخیره نشد. این بررسی محدود، تضمین بی‌خطر بودن تمام آرشیو یا ZIPهای داخلی نیست.

## ۲. فناوری واقعی و مسیرهای شاهد

در این گزارش `P` برابر مسیر داخلی `DuberFront/Duber` است؛ شماره‌خط‌ها نسبت به فایل همان ZIP هستند، نه فایل محلی یا URL عمومی.

| شاهد | یافته |
|---|---|
| `P/Duber.csproj`، `Program.cs`، `Startup.cs:30–98` | C# و `ASP.NET Core MVC 2.1` روی `netcoreapp2.1`، WebHost/Startup و Razor؛ صرفاً Frontend نیست |
| `P/Duber.csproj` | EF Core/SqlServer `2.1.1` و `kavenegar-dotnetcore 2.0.0` در metadata بسته‌ها؛ نصب یا سازگاری امنیتی امروز تأیید نشده است |
| `P/Views/carbodyinsurance/Order.cshtml` | فرم Razor و JavaScript/jQuery AJAX؛ MVC actionها همراه UI هستند |
| `P/Models/DuberContext.cs` و `Models/irisdbContext.cs` | دو EF DbContext با ۱۹۶ DbSet در هرکدام؛ تعداد DbSet اثبات تعداد جدول فعال سرور نیست |
| `P/Startup.cs:73–77` | `UseSqlServer` با دو کلید تنظیمات `MyConnection` و `MyConnectionIRIS` |
| `P/Api/GetsListsController.cs:14–32` | scaffold دارای `[ApiController]` و Route؛ فقط constructor/field دارد و action عملیاتی ندارد |

شاهدی برای Web Forms یا ASP.NET MVC/Web API کلاسیک در مسیرهای بررسی‌شده یافت نشد. ADO.NET فقط در بلوک کامنت‌شدهٔ `P/Controllers/Admin/AdminHomeController.cs` دیده شد؛ در جست‌وجوی کد فعال، `SqlConnection/SqlCommand/FromSql/ExecuteSql/CommandType.StoredProcedure/ToView/DbQuery` مشاهده نشد. دسترسی دادهٔ فعالِ مرتبط، EF/LINQ است؛ نام view یا stored procedure موردنیاز BAZDID تأیید نشد.

## ۳. درخواست بیمه و تفاوت انواع کد

- `P/Models/OrderSales.cs:17–21,55,202,235–237`: شناسهٔ درخواست `Id` از نوع CLR `long`، ارتباط `CustomerId` از نوع `int?`، موبایل snapshot و فیلدهای خودرو وجود دارند.
- `P/Controllers/carbodyinsuranceController.cs:2082–2084,2217–2223`: `AddOrderSalesF` مدل سفارش را با EF ذخیره و `order.Id` را در Sessionهای `OrderId/OrderIdShow` می‌گذارد. تعیین خودکار و یکتایی فیزیکی Id باید با metadata پایگاه تأیید شود.
- `P/Controllers/HomeController.cs:8254–8267` و `Views/Home/verifyOrder.cshtml:13`: مسیر `verifyOrder/{Id}` فقط Id را به View می‌دهد و شمارهٔ پیگیری را نمایش می‌دهد؛ lookup کد معرفی یا احراز مالکیت/موبایل در این action وجود ندارد.
- `P/Controllers/CustomersController.cs:2179–2187`: `GetCusId` از Session می‌خواند و `CheckType` جست‌وجوی OrderSales را با Id و CustomerId محدود می‌کند؛ الگوی scope مالک قابل اقتباس مفهومی است، نه قرارداد قابل کپی.
- `P/Controllers/carbodyinsuranceController.cs:3147–3155` و `Models/TakhfifCode.cs`: `TakhfifCheck` به تخفیف مربوط است. `TakhfifCode`، پیگیری پرداخت و `RahgiriPost` معادل کد معرفی درخواست BAZDID نیستند.

**صدور، ستون، lookup و API تبدیل کد معرفی شش‌کاراکتری به درخواست تأیید نشد.** `A4K9P2` را نباید به `OrderSales.Id` یا کد تخفیف نگاشت کرد. این fixture و OTP برابر `12345` فقط Development/Test خود BAZDID باقی می‌مانند.

## ۴. شواهد SQL و دادهٔ مشتری/خودرو

`P/Models/DuberContext.cs:2578–2589` و `Models/irisdbContext.cs:2586–2597` هر دو، نگاشت صریح **`Duber.OrderSales`** را دارند. این نام در source قطعی است؛ وجود/نسخه/مجوز آن در سرور فعلی هنوز بررسی نشده است. رابطهٔ `OrderSales.CustomerId → Customer.Id` در `DuberContext.cs:2884–2887` ثبت شده است.

برای `Customer`، `Car`، `CompanyCar` و `CarYearSakht`، DbSet/model و روابط دیده شدند، اما schema/table آن‌ها در بلوک‌های مرتبط `ToTable` صریح ندارد؛ نام فیزیکی و schema را فقط از convention قطعی اعلام نمی‌کنیم. `Id/CustomerId/Mobile/Pelak/VinNumber/ShasiNumber` propertyهای مشاهده‌شده‌اند و نام/نوع/nullability ستون جاری باید با DBA تطبیق داده شود. فایل `.sql/.edmx/.dbml` در فهرست بیرونی آرشیو وجود ندارد؛ DDL یا وضعیت واقعی پایگاه تحویل نشده است.

`P/Models/Customer.cs:22–26` و `OrderSales.cs:18,55`، دو candidate موبایل `Customer.Mobile` و `OrderSales.Mobile` را نشان می‌دهند. view قدیمی در `P/Areas/Agents/Views/AgentHome/DetailsOrder.cshtml:70` برحسب وجود CustomerId یکی را نمایش می‌دهد؛ این انتخاب UI، اثبات trusted/verified بودن شماره برای OTP نیست. اولویت، مالکیت و شرایط استفاده از snapshot باید مصوب شوند؛ مشتری BAZDID حق جایگزینی موبایل ندارد.

مدل خودرو از `CarId → Car.Name/Company → CompanyCar.Name` و سال از `CarYearSakhtId → CarYearSakht.Name` قابل بررسی است؛ **Id سال، مقدار سال نیست** و Name رشته است. پلاک یک رشته و VIN/شاسی دو فیلد جدا هستند. رنگ، تقویم سال، نسخهٔ قابل اتکای منبع و قرارداد missing/zero برای نیاز BAZDID تأیید نشدند. [ماتریس اجرایی نگاشت](BROKERAGE_DATA_MAPPING_FA.md) وضعیت هر فیلد و fallback را مشخص می‌کند.

## ۵. OTP، احراز هویت و Session

`P/Controllers/HomeController.cs:2799–2855,2926,3051–3115` ورود یک‌بارمصرف بر پایهٔ موبایل را نشان می‌دهد: ساخت کد چهاررقمی با `Random`، ذخیره در `Customer.PasswordOne`، شمارنده/زمان متنی و ارسال از طریق Kavenegar. `Login/ LoginCHYekbar` در خطوط `2144–2166/2501–2556` کد را مقایسه و پس از موفقیت پاک و `CusId/CusName` را در Session می‌گذارند. وابستگی کد به درخواست بیمه و چالش SQL یک‌بارمصرف مطابق طرح BAZDID در این جریان اثبات نشد؛ `SendSMSRamz` در خطوط ۷۰–۷۳ بدنهٔ خالی دارد و adapter آماده محسوب نمی‌شود.

`P/Content/Utility.cs:67–77` تبدیل ارقام فارسی به لاتین را دارد؛ canonicalization کامل تلفن ایران/E.164 یا پوشش همهٔ ارقام عربی از آن اثبات نمی‌شود. provider مشاهده‌شده، قرارداد مصوب SMS کارگزاری برای BAZDID نیست؛ کلید/شمارهٔ فرستنده منتقل نمی‌شوند و BAZDID همچنان مرجع verify خواهد بود.

`P/Startup.cs:60–69,205–206` از `AddDistributedMemoryCache` و Session حافظه‌ای با `IdleTimeout` بسیار طولانی استفاده می‌کند. `P/Helpers/SessionHelper.cs:12–20`، JSON serialization را روی ISession انجام می‌دهد. کلیدهای مرتبط شامل `CusId/CusName`، `OrderId/OrderIdShow`، `OrderSales/OrderList` و `Mobile` هستند. هم نام کلید و هم scope، قرارداد احراز هویت قابل اعتماد میان دو IIS Application نیستند. ثبت `AddAuthentication/AddCookie/UseAuthentication` در کد فعال Startup مشاهده نشد؛ cookie نشست با cookie authentication یکی نیست.

BAZDID کوکی/Session قدیمی را خودکار نمی‌پذیرد و تنظیم حافظه‌ای/TTL آن را کپی نمی‌کند. مالکیت request/customer باید سمت سرور معتبر، Session صرفاً زمینهٔ موقت و اطلاعات نهایی در `BAZDIDInfo` پایدار باشد. ورودی مرورگر مبنی بر missing بودن فیلد، مجوز Manual ایجاد نمی‌کند؛ هیچ قاعدهٔ عمومی «۰ یعنی مفقود» در این ممیزی تصویب نشده است.

## ۶. اقتباس مفهومی و موارد غیرقابل انتقال

| قابل اقتباس با بازبینی | منتقل نشود |
|---|---|
| جداسازی context/تنظیمات اتصال و مسیر رابطهٔ درخواست به مشتری | دو DbContext بزرگ، connectionهای آرشیو یا fallback بی‌اجازه میان آن‌ها |
| scope lookup با request و customer معتبر | اعتماد به موبایل/CustomerId مدل POST یا Session اپلیکیشن دیگر |
| مدل lookup نام خودرو/سازنده/سال و تبدیل ارقام | تبدیل FK سال به سال واقعی یا تفسیر سراسری صفر |
| نقش پیامک و تجربهٔ کد یک‌بارمصرف | `Random`، کد plaintext، رمز مشترک fallback و TTL قدیمی |
| الگوی WebHost/Startup و DI نسل 2.1 | rewriteها، دامنه‌ها، profile انتشار و سیاست cookie قدیمی |

انتخاب ADO.NET پارامتری و adapter محدود در BAZDID تغییر نمی‌کند؛ وجود EF قدیمی دلیل واردکردن dependencyها یا ۲۰۲ فایل Models نیست.

## ۷. نگرانی‌های امنیت و اطلاعات مفقود

در `P/appsettings.json` و `Models/irisdbContext.cs:217–223` literal اتصال دارای پارامتر رمز وجود دارد؛ در متن برخی بلوک‌های قدیمی نیز مشابه آن دیده می‌شود. مقدار، host، database، username یا secret در این گزارش/مخزن کپی نشده و هیچ اتصال برای آزمایش آن‌ها انجام نشده است. فعال‌بودن این مقادیر معلوم نیست؛ مالک سامانه باید اعتبار و لزوم گردش آن‌ها را در کانال امن بررسی کند. publish profileهای `.pubxml/.user`، `.vs`، log و داده‌های ضمیمه نیز منتشر نشوند.

همچنین fallback رمز مشترک، مقایسهٔ مستقیم Password/PasswordOne، RNG نامناسب OTP، زمان متنی، catchهای خاموش، Session حافظه‌ای طولانی و `UseDeveloperExceptionPage` در شاخهٔ غیرDevelopmentِ `Startup.cs:135–142` دیده شد. مدل‌های قدیمی media از نوع `byte[]` دارند؛ الگوی BAZDID همچنان فایل خصوصی و SQL metadata است. هیچ‌یک از این یافته‌ها مجوز تغییر یا آزمون آنلاین سامانهٔ قدیمی نیست.

تصمیم‌های باز کلیدی: context/پایگاه authoritative، schema و مجوز جاری، نگاشت referral، موبایل trusted، eligibility/freshness، normalization سال/پلاک/VIN و ZeroMeansMissing، قرارداد SMS و پایگاه تست. وجود source جای تأیید production contract را نمی‌گیرد.

## ۸. نتیجهٔ برنامه‌ریزی و گام بعد

برنامهٔ Checkpoint 2 با بسته‌های discovery metadata، پایگاه تست، scriptهای BAZDID، reader ساختگی/قرارداد mapping، constraint/index، rollback و آزمون SQL به‌روز شد. سه جدول اولیهٔ linkage/audit در همان scope قبلی می‌مانند؛ طراحی persistence `BAZDIDInfo` آماده می‌شود و اجرای آن مطابق roadmap در Checkpoint 4 خواهد بود. در این وظیفه حتی آن سه جدول نیز ساخته نشده‌اند.

تغییرها فقط این گزارش، PLAN، نگاشت، تصمیم‌ها و ادامهٔ AI هستند. build/runtime/test برنامه تکرار نشده‌اند؛ نتیجهٔ ۴۳ آزمون متعلق به Checkpoint 1 است. کنترل پیش از commit شامل ۳۱ پیوند Markdown، ۳۱ بررسی ساختاری شاهد، ۱۰۳ فایل قابل انتشار و ۱۲۱ blob تاریخی main بود؛ هشدار راز باقی‌مانده صفر و hash آرشیو بدون تغییر بود. URL دارای credential در تست موجود، fixture ساختگیِ رد origin است و جداگانه تأیید شد. آرشیو اصلی و source آن در هیچ commit یا push قرار نمی‌گیرند. همگام‌سازی فقط main انجام می‌شود؛ SHA و نتیجهٔ remote از Git واقعی و گزارش تحویل خوانده شوند. **Checkpoint 1.5 کامل و آمادهٔ بازبینی است؛ برای شروع Checkpoint 2 مجوز تازه و پایگاه تست لازم است.**
