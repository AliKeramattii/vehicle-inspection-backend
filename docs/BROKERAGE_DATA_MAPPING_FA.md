# نگاشت خواندنی دادهٔ کارگزاری

## قرارداد منطقی adapter

در `2026-11-02` و طبق مجوز `2df8399e-d511-49b7-af28-a075f801dd57`، `IBrokerageRequestReader` با دو متد واقعی `ResolveReferralAsync` و `GetRequestSnapshotAsync` پیاده شد. resolve، BrokerageRequestReference حداقلی و snapshot، شناسه‌های دقیق مبدأ، مرجع موبایل، eligibility، هفت فیلد خودرو با provenance/validation، SourceVersion و RetrievedAtUtc مستقل دارد. این قرارداد داخلی با reader حافظه‌ای آزموده شده؛ query یا schema کارگزاری نیست. [کد، fixture و آزمون 2D](implementation/CHECKPOINT-02D-BROKERAGE-READER_FA.md).

نتیجه می‌تواند `Found`، `NotFound`، `Ambiguous`، `Ineligible` یا `Unavailable` باشد. هیچ‌کدام نباید به‌صورت خودکار به fixture تبدیل شوند. کد تکراری بدون قاعدهٔ یکتایی مصوب، انتخاب تصادفی درخواست را مجاز نمی‌کند. timeout یا خطای SQL با «اطلاعات مفقود» یکی نیست.

credential خواندن مبدأ از credential نوشتن BAZDID جدا باشد؛ DBA به viewهای مصوب یا اشیای دقیق مجوز SELECT می‌دهد. ممیزی Checkpoint 1.5 نام صریح `Duber.OrderSales` و چند property/رابطه را در سورس یافت؛ **schema جاری سرور، ستون‌های فیزیکی و مرجع authoritative هنوز تأیید نشده‌اند**. نه query آزمایشی روی Production نوشته می‌شود و نه ساخت/تغییر جدول آن مجاز است. هیچ FK به جدول مبدأ تا شناخت schema پیشنهاد اجرایی نمی‌شود.

## نتیجهٔ کشف محلی Checkpoint 2A/2B

در `2026-11-01` با مجوز صریح کاربر، فقط master catalog در `(local)\SQLSERVER2019` و Windows Authentication خوانده شد. چهار پایگاه سیستمی وجود داشتند و `BAZDID_Development` موجود نبود؛ هیچ پایگاه/شیء کارگزاری روی این instance مشاهده یا خوانده نشد. بنابراین تمام confidenceهای جدول زیر همچنان **شاهد سورس** هستند و به physical mapping تأییدشده ارتقا نمی‌یابند. نام instance، نسخه و compatibility محلی، مشخصات سرور کارگزاری محسوب نمی‌شوند.

[نمونهٔ metadata برای DBA](../database/discovery/source_object_metadata.sql) با مجوز صفر و نام پایگاه/schema/table برابر NULL بسته است. پس از تصویب مقصد و شیء واقعی، برای هر شیء جداگانه schema، column/type/nullability، FK و index را بدون خواندن ردیف تجاری برمی‌گرداند؛ definition/default literal یا credential خروجی ندارد. آن فایل در این وظیفه اجرا نشده است. نبود نتیجه با فقدان مجوز metadata یکی نیست و هیچ `dbo.Customer` یا join حدسی ساخته نمی‌شود.

اقلام لازم از DBA/مالک: انتخاب context/پایگاه authoritative، metadata حداقلی و پاک‌شدهٔ اشیای واقعی، تعریف صدور/uniqueness/lifecycle referral، اولویت و verified بودن موبایل، eligibility و نسخهٔ منبع، mapping خودرو/سال/رنگ و Missing/Invalid/ZeroMeansMissing هر فیلد. Production access در این مرحله مجاز نیست و credential آرشیو استفاده نمی‌شود. تعارض موبایل به انتخاب خودکار یکی از دو مقدار منجر نمی‌شود. [گزارش مرحله](CHECKPOINT2A_2B_REPORT_FA.md).

## دفتر mapping مبتنی بر شاهد — Checkpoint 1.5

مبنای این جدول آرشیو خصوصیِ ممیزی‌شده در `2026-11-01` است؛ hash و حدود جست‌وجو در [گزارش ممیزی](DUBERFRONT_CODE_AUDIT_FA.md) ثبت شده‌اند. `P` در مسیرهای زیر برابر `DuberFront/Duber` است. «صریح سورس» یعنی نگاشت EF مشاهده شده؛ «مدل سورس» یعنی property/رابطه دیده شده و نام ستون فیزیکی صرفاً از convention قابل حدس است. هیچ‌کدام تأیید پایگاه زنده نیستند. نام propertyهای جدول پیشنهاد تاریخی‌اند؛ مدل داخلی پیاده‌شدهٔ 2D در walkthrough مشخص است و قرارداد HTTP آینده هنوز مصوب نیست.

«مشروط» در ستون Manual فقط دربارهٔ فیلد خودروست: adapter مصوب باید همان فیلد را صریحاً `Missing` گزارش کند و ورودی با اعتبارسنجی مستقل ذخیره شود. نبود mapping، خطای منبع یا ادعای مرورگر، Missing نیست. تمام ردیف‌ها پیش از adapter واقعی به نام/نوع/nullability فیزیکی، نمونهٔ ساختگی و مسئول تأیید نیاز دارند.

| نیاز BAZDID | فیلد یا API مشاهده‌شده | مسیر دقیق شاهد در ZIP | اطمینان/وضعیت | property پیشنهادی DTO | فقط‌خواندنی | Manual | اطلاعات مفقود |
|---|---|---|---|---|---|---|---|
| tenant و منبع | دو context و دو کلید اتصال | `P/Startup.cs:73–77` | منبع authoritative حل‌نشده | `BrokerageId`, `SourceSystem` | بله؛ تنظیم سرور | خیر | context/پایگاه منتخب و حوزهٔ یکتایی |
| شناسهٔ درخواست | `OrderSales.Id` از نوع `long`؛ نگاشت `Duber.OrderSales` | `P/Models/OrderSales.cs:17`؛ `P/Models/DuberContext.cs:2578–2589`؛ `P/Models/irisdbContext.cs:2586–2597` | صریح سورس برای جدول؛ ستون جاری تأییدنشده | `SourceRequestId` رشته | بله | خیر | کلید/نوع واقعی و یکتایی در هر منبع |
| شناسهٔ مشتری | `OrderSales.CustomerId → Customer.Id`؛ `int? → int` | `P/Models/OrderSales.cs:18`؛ `P/Models/Customer.cs:22`؛ `P/Models/DuberContext.cs:2884–2887` | رابطهٔ سورس؛ جدول Customer صریح نیست | `SourceCustomerId` رشته | بله | خیر | schema/table مشتری، nullable و مالکیت معتبر |
| کد معرفی | resolver یا ستون شش‌کاراکتری تأیید نشد؛ `TakhfifCheck` تخفیف است | `P/Controllers/carbodyinsuranceController.cs:3147–3155`؛ `P/Controllers/HomeController.cs:8254–8267` | حل‌نشده؛ نمایش Id در verifyOrder کافی نیست | `ReferralCode` | بله؛ حل سمت سرور | خیر | صدور، انتقال، lookup، case، انقضا و uniqueness |
| موبایل معتبر | `Customer.Mobile` و snapshot در `OrderSales.Mobile` | `P/Models/Customer.cs:26`؛ `P/Models/OrderSales.cs:55`؛ `P/Areas/Agents/Views/AgentHome/DetailsOrder.cshtml:70` | دو candidate؛ اولویت UI اثبات اعتبار نیست | `TrustedMobile` | بله؛ نمایش masked | خیر | اولویت، verified بودن، تعارض و تغییر مالک/شماره |
| مرجع خودرو | `OrderSales.CarId` | `P/Models/OrderSales.cs:20` | مدل سورس | `SourceVehicleReference` | بله | خیر؛ زمینهٔ سرور | معنای شناسه و کاربرد موردنیاز |
| سازنده | `Car.CompanyId/Company → CompanyCar.Name` | `P/Models/Car.cs:17,34`؛ `P/Models/CompanyCar.cs:15` | مدل/رابطهٔ سورس | `Vehicle.Make` | اگر معتبر | مشروط | schema lookup، join جاری و اعتبار مقدار |
| مدل | `Car.Name` از رابطهٔ CarId | `P/Models/Car.cs:16`؛ `P/Controllers/CustomersController.cs:827–887` | مدل و مصرف سورس | `Vehicle.Model` | اگر معتبر | مشروط | schema lookup و normalization نام/کد |
| سال | `CarYearSakhtId → CarYearSakht.Name` رشته؛ FK سال نیست | `P/Models/OrderSales.cs:21`؛ `P/Models/CarYearSakht.cs:13–14` | مدل سورس | `Vehicle.ModelYear` | اگر معتبر | مشروط | تقویم، parsing، بازه و sentinel |
| رنگ | منبع قابل اتکا برای نیاز BAZDID تأیید نشد | `P/Models/OrderSales.cs` و مدل‌های lookup بررسی‌شده | حل‌نشده؛ غیبت در ممیزی، Missing نیست | `Vehicle.ColorName`, `ColorHex` | اگر معتبر | مشروط پس از mapping | فیلد/enum و سیاست Missing؛ hex اختیاری |
| پلاک | `OrderSales.Pelak` رشته | `P/Models/OrderSales.cs:202` | مدل سورس | `Vehicle.Plate` | اگر معتبر | مشروط | تجزیهٔ چهار segment و پلاک غیرمعمول |
| VIN | `OrderSales.VinNumber` | `P/Models/OrderSales.cs:237` | مدل سورس | `Vehicle.Vin`, `VinMasked` | اگر معتبر | مشروط | نیاز به full VIN، validation و masking |
| شاسی | `OrderSales.ShasiNumber`؛ مستقل از VIN | `P/Models/OrderSales.cs:235` | مدل سورس | `Vehicle.ChassisNumber` | اگر معتبر | مشروط | تفاوت شاسی قدیمی/VIN و سیاست نمایش |
| کیلومتر | منبع کارگزاری برای این جریان فرض نشده | `P/Models/OrderSales.cs`؛ قرارداد مستقل BAZDID | ورودی مشتری طبق قاعدهٔ قطعی | `Kilometers` | خیر | بله؛ اعتبارسنجی عدد صحیح | سقف مصوب؛ صفر معتبر است |
| مجازبودن درخواست | propertyهای `Status/TypeOrder`؛ معنی مجاز برای BAZDID مشخص نیست | `P/Models/OrderSales.cs` | مدل سورس؛ semantics حل‌نشده | `RequestEligibility` | بله | خیر | نوع بیمه، وضعیت لغو/بسته و زمان بازبینی |
| نسخه/تازگی | rowversion یا زمان تغییر قابل اتکا تأیید نشد | `P/Models/OrderSales.cs`؛ `P/Models/DuberContext.cs` | حل‌نشده | `SourceVersion`, `RetrievedAtUtc` | بله | خیر | نسخهٔ منبع؛ زمان دریافت UTC را خود Backend می‌سازد و جای نسخه نیست |

`OrderSales.Mobile` در EF حداکثر ۱۵ نویسه و غیرUnicode است (`DuberContext.cs:2730–2732`)؛ `Customer.Mobile` در همان مدل required با سقف ۱۵ است (`672–674`). این‌ها قید مدل سورسند، نه DDL تحویل‌شده. schema/table صریح برای Customer/Car/CompanyCar/CarYearSakht و override نام ستون‌های منتخب مشاهده نشد؛ `dbo` یا نام جدول قراردادی به query تبدیل نمی‌شود. view/SP/API آماده برای referral نیز تأیید نشده است.

شناسهٔ `long` درخواست در مرز adapter بدون کاهش به `int` یا عدد JavaScript حمل می‌شود؛ رشتهٔ opaque همراه tenant/source حفظ شود. انتخاب یکی از دو context یا fallback میان آن‌ها بدون تصویب ممنوع است. FK به اشیای ناشناخته ساخته نمی‌شود؛ عدم تطابق موبایل/مالک باید fail-closed باشد.

برای هر فیلد، `ZeroMeansMissing`، whitespace، sentinel، enum، encoding، mapping تقویم، اعتبارسنجی و سیاست refresh جدا ثبت شود. هیچ فرض کلی «۰ یعنی خالی» نداریم. شناسهٔ خارجی باید دقیقاً با semantics مبدأ حفظ شود؛ trim یا upper روی شناسهٔ opaque بدون قرارداد مجاز نیست.

## فیلدهای اثبات‌شدهٔ مصرف‌کننده

منابع مستقیم: `src/schemas/domain.ts`، `src/features/vehicle/vehicle-model.ts`، `vehicle-form.tsx`، `src/features/location/location-model.ts` و `src/lib/map/location-selection.ts` در Frontend.

| داده | رفتار فعلی و پیشنهاد Backend |
|---|---|
| `make/model/year/colorName/vinMasked/plate` | در مدل خودرو موجودند؛ فیلد trusted قفل، فیلد مفقود فرم آینده می‌خواهد؛ مقدار placeholder دادهٔ نهایی نیست |
| `colorHex` | اختیاری؛ فقدان آن رنگ سفید یا hex ساختگی ایجاد نمی‌کند |
| `plate` | `firstTwoDigits` دو رقم، `letter` از enum، `threeDigits` سه رقم و `regionDigits` دو رقم؛ ارقام ASCII پس از normalization |
| `discrepancy` | مدل فعلی `field=model/year/color/vin` و توضیح ۳ تا ۵۰۰ نویسه؛ گزارش، جایگزین فیلد trusted نیست |
| `latitude/longitude` | بازهٔ واقعی ±۹۰/±۱۸۰؛ decimal با precision کافی؛ منبع انتخاب `gps/manual` |
| `accuracyMeters` | نامنفی یا null؛ انتخاب دستی نباید دقت جعلی بسازد |
| `formattedAddress` | فرم فعلی حداکثر ۳۰۰ نویسه؛ schema پیشنهادی قدیم ۵۰۰ است؛ پیشنهاد اتصال این فاز ۳۰۰ |
| `buildingNumber/unitFloor/parkingDescription` | اختیاری؛ فرم فعلی به‌ترتیب سقف ۲۰/۸۰/۳۰۰؛ schema قدیمی ۴۰/۸۰/۵۰۰ بود |
| `kilometers` | از مشتری؛ عدد صحیح مستقل؛ ادعای مرورگر بازاعتبارسنجی می‌شود |

موقعیت، رضایت و کیلومتر نیازمند دریافت از جدول کارگزاری فرض نشده‌اند. شماره ملی، تاریخ تولد یا آدرس منزل برای این جریان لازم شناسایی نشد و اضافه نمی‌شود. شناسهٔ مشتری/درخواست زمینهٔ سرورند؛ نیازی به نمایش عمومی مقدار خام آن‌ها نیست.

## fixture ساختگی مستقل

در Development/Testing: scope برابر `TEST-BROKERAGE / SYNTHETIC`، مشتری `TEST-CUSTOMER-001`، درخواست `TEST-REQUEST-001`، referral برابر `A4K9P2` و موبایل fixture برابر `09000000001` است. این رشته صرفاً دادهٔ آزمون است؛ ادعای رزروشده یا تخصیص‌نیافته‌بودن شماره نمی‌شود. هیچ SMS/OTP/seed اجرا نمی‌شود. ۱۸ رکورد حافظه‌ای، کامل/ناقص/invalid/صفر با سیاست مستقل، دو درخواست یک مشتری، ambiguity، unavailable، تعارض موبایل، شناسهٔ بزرگ و scopeهای دیگر را پوشش می‌دهند؛ نام/مشخصات شخصی اضافی در snapshot وجود ندارد.

`SyntheticBrokerageRequestReader` از DI فقط در Development/Testing انتخاب می‌شود؛ سازنده هم محیط دقیق را کنترل می‌کند. Production mode/scope ساختگی را رد می‌کند. `SqlBrokerageRequestReader` اکنون مرز صریح تنظیم‌نشده است و صرفاً Unavailable/SourceNotConfigured می‌دهد؛ هیچ SQL یا fallback ندارد. سرویس داخلی scope سروری را bind می‌کند؛ reference به‌تنهایی مجوز مالکیت نیست. فیلد Present معتبر فقط‌خواندنی، Missing صریح با سیاست دستی null، Invalid قفل و Unavailable قفل است. سال صفر فقط طبق سیاست آزمایشی همان فیلد Missing می‌شود؛ label رنگ صفر با سیاست جدا Present می‌ماند. این سیاست‌ها، validation سال/رنگ/VIN واقعی کارگزاری نیستند.

## refresh و منشأ

به‌روزرسانی طراحی 2E: [ماتریس دقیق Frontend → reader → DTO → ذخیره](implementation/CHECKPOINT-02E-INFO-PERSISTENCE-DESIGN_FA.md) مرجع persistence آینده است؛ این کار query یا mapping کارگزاری را اضافه نکرد. Origin مقدار مؤثر با SourceStatus پذیرفته‌شده، InitialSourceStatus و ObservedSourceStatus جدا می‌شود؛ Manual شاهد Missing را پاک نمی‌کند. ordinalهای enum 2D به SQL آینده cast نمی‌شوند. ColorHex از reader فعلی نمی‌آید و کاتالوگ UI مرجع authoritative رنگ نیست. نسخهٔ اجباری غیرخالی 2D برای source unversioned نیازمند تغییر آگاهانهٔ آینده است؛ در 2E کد تغییر نکرد و نسخه‌ای از ساعت جعل نشد. بازخوانی بعد از submit نیز Info/snapshot را تغییر نمی‌دهد. توضیح lifecycle عمومی زیر طرح آینده باقی می‌ماند.

حل referral یک context کوتاه‌عمر سرور می‌دهد؛ موبایل در زمان صدور/ارسال مجدد و verify با نسخهٔ مورد اعتماد سازگار می‌ماند. تغییر موبایل/مالک، چالش قبلی را باطل می‌کند. در ایجاد بازدید، snapshot مبنای خواندنی پین و زمان بازیابی ثبت می‌شود. اگر پیش از نهایی‌سازی مبدأ تغییر کرد، Backend با `SOURCE_CHANGED` تأیید مجدد می‌خواهد؛ مقدار trusted بی‌صدا روی Manual نوشته نمی‌شود. پس از submit، snapshot تاریخی ثابت است. سیاست دقیق استعلام تازگی و امکان نسخه‌خوانی منبع در تصمیم‌های باز است.
