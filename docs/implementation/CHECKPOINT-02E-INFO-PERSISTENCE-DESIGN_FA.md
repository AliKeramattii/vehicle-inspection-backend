# طرح ماندگاری اطلاعات مشتری و خودرو — Checkpoint 2E

تاریخ `2026-11-02`؛ مجوز `20acc386-4be3-48e7-84da-a7457cf34b6f`؛ مبنای Git برابر `d704ad21f8d7cbb66abb29b160f3a9c7c6a7d705`. **این سند، قرارداد پیشنهادی آینده برای Checkpoint 4 است؛ پیاده‌سازی persistence نیست.** کد 2D، controller، dependency، Swagger و schema جاری تغییر نکردند. هیچ اتصال SQL، DDL، migration، repository، نوشتن رکورد یا تغییر Frontend در 2E انجام نشد.

## هدف، شواهد و حدود قطعیت

اطلاعات پرونده باید مستقل از ASP.NET Session، متعلق به یک درخواست بیمه و یک تلاش بازدید، با منشأ و تاریخچهٔ قابل‌تفسیر ماندگار شود. کپی master مشتری، موبایل خام، OTP، کوکی، token، شماره ملی یا تاریخ تولد برای این هدف لازم نیست. طرح زیر از قواعد قطعی و مدل فعلی مصرف‌کننده استفاده می‌کند؛ نگاشت فیزیکی کارگزاری، سیاست‌های هنوز مصوب‌نشده و امنیت Production را قطعی معرفی نمی‌کند.

AGENTS، PLAN، README، معماری، طراحی پایگاه، ماتریس کارگزاری، قواعد کسب‌وکار، API، تصمیم‌ها، امنیت، ممیزی DuberFront و walkthrough 2D بازبینی شدند. کد interface، BrokerageField، snapshot immutable، سرویس scope-bound، registration محیط، synthetic/SQL-unconfigured و آزمون‌های واقعی بررسی شدند. baseline **۶۵ unit + ۴۳ integration = ۱۰۸ موفق** با اجرای تازه تأیید شد؛ [شاهد اجرای این مرحله](../checkpoint2e/APPLICATION_VALIDATION.json). این آزمون‌ها قرارداد/reader موجود را می‌سنجند و اجرای طرح حاضر نیستند.

سه جدول موجود طبق [تعریف ثبت‌شدهٔ 2C](../../database/proposals/initial_tables.review.sql) و [شاهد خواندنی 2D](../checkpoint2d/DATABASE_VERIFICATION.json)، `BAZDIDCustomerLinks/BAZDIDRequestContexts/BAZDIDAuditLogs` هستند. در این مرحله وجود آن‌ها از SQL زنده دوباره استعلام نشد؛ تطبیق با فایل و شاهد نسخهٔ ثبت‌شده بود. Info، Inspections و دیگر جدول‌های آینده هنوز ساخته نشده‌اند. فایل شخصی ثبت‌نشدهٔ Backend، `launchSettings.json`، حفظ شد.

Frontend از working tree موجود با HEAD مرجع `448fa6aa9ce29f4fbf535203dbb96d2e862565ce` خوانده شد؛ ۲۲۶ ورودی تغییر از قبل داشت. بنابراین HEAD به‌تنهایی شاهد بایت فایل‌های خوانده‌شده نیست؛ hash ۲۶ فایل و کنترل حفظ آن‌ها در [شاهد بررسی Frontend](../checkpoint2e/FRONTEND_REVIEW.json) ثبت است. هیچ فرمان build/install/test یا ویرایش در Frontend اجرا نشد. کد آن قرارداد Production یا مجوز هویت نیست.

## ماتریس نیاز تا ذخیره‌سازی

در مسیرهای این جدول، `F` ریشهٔ خواندنی Frontend و `B` برابر `src/Bazdid.Api/Domain/Brokerage` است. سطرهای فاقد داده در reader با حدس پر نمی‌شوند. DTO ستون سوم، **پیشنهاد آینده** است.

| شاهد واقعی Frontend | snapshot واقعی 2D | قرارداد اطلاعات آینده | محل پیشنهادی | اعتبارسنجی و سیاست |
|---|---|---|---|---|
| `F/src/schemas/domain.ts`: `make`؛ VehicleCard | `Vehicle.Manufacturer` | `fields.make.value: string?` | `BAZDIDInfo.Make` و خانوادهٔ Make | حداکثر ۱۰۰ نویسه؛ Present معتبر قفل، Missing صریح طبق policy دستی |
| همان: `model` | `Vehicle.Model` | `fields.model.value: string?` | `Model` و metadata | همان طول؛ lookup/متن طبق policy، بدون placeholder |
| همان: `year` عدد صحیح مثبت | `Vehicle.ModelYear` رشته | `fields.modelYear.value: {year,calendar}?` | `ModelYear/ModelYearCalendar/ModelYearSourceText` | سال واقعی، نه CarYearSakhtId؛ تقویم اجباری و صریح |
| `colorName` و `vehicle-form.tsx`: `colorId` | `Vehicle.Color` رشته | `fields.color.value: {name}?`؛ ورودی دستی colorId | `ColorName` و خانوادهٔ Color | نام source حفظ؛ کاتالوگ دستی نسخه‌دار، بدون fallback سفید |
| `colorHex` اختیاری و swatch | در reader وجود ندارد | `colorHex: MetadataField<string?>` فقط نمایشی | `ColorHex` و پنج ستون metadata آن | از mapping یا کاتالوگ مصوب؛ فقدان hex مجوز تغییر رنگ نیست |
| `iranianPlateSchema` چهار بخش | `Vehicle.LicensePlate` رشته | `fields.plate.value: PlateValue?` | چهار ستون Plate و PlateSourceText | یک فیلد منطقی؛ منشأ/قفل مشترک، چهار بخش اتمیک |
| `vinMasked` و عنوان «شماره شاسی (VIN)» در VehicleCard | `Vehicle.Vin` رشته | `fields.vin.value: {masked,assurance}?` | VinCiphertext/VinMasked/VinAssurance | VIN کامل فقط داخلی/حفاظت‌شده؛ mask، VIN کامل نیست |
| فیلد مستقلی برای chassis در مدل فعلی UI نیست | `Vehicle.ChassisNumber` مستقل | `fields.chassisNumber` در صورت نیاز مصوب | خانوادهٔ Chassis | با VIN یکی نیست؛ نمایش/لزوم آینده نیازمند قرارداد UI |
| `vehicleSchema.odometerKm` اختیاری؛ فلو capture از `odometer.kilometers` استفاده می‌کند | عمداً ندارد | `odometer.kilometers: integer?` | OdometerKm و metadata | ۰ معتبر؛ ورودی مشتری مستقل، نه SourceStatus=Missing ساختگی |
| `odometerReadingSchema`: evidenceId/updatedAt اختیاری | ندارد | evidenceId projection رابطه؛ زمان سرور | عدد در Info؛ evidence در جدول مدارک آینده | evidence باید متعلق به همان inspection و الزام کیلومتر باشد؛ زمان browser مرجع نیست |
| `VehicleConfirmationInput/Receipt`: plate/colorId/discrepancy/confirmedAt | ندارد | manual allowlist + confirmVehicle + discrepancy | confirmation/revision/discrepancy در Info | تأیید، ویرایش trusted نیست؛ actor/time از سرور |
| `source-context.ts`: tenantId/subjectId/mobile/sourceRequestId از mock | Reference.Scope، SourceCustomerId، TrustedMobile | فقط projection داخلی سرور | linkage و request context؛ مالک پین‌شدهٔ inspection | این داده‌ها از body یا browser هویت نمی‌سازند؛ در Info خام تکثیر نمی‌شوند |
| `inspectionId` در workflow و summary | request reference، نه inspection | inspectionId فقط انتخاب منبع درخواست‌شده | InspectionId PK/FK | owner join در هر درخواست؛ دانستن GUID کافی نیست |
| ReadinessScreen/DeviceReadiness | ندارد | طرح آمادگی دستگاه خارج Info | ذخیرهٔ Info ندارد | صرف بررسی دستگاه و آماده‌سازی، اطلاعات هویتی تازه نمی‌سازد |
| ConsentForm: accepted/termsVersion | ندارد | رضایت مستقل بازدید | BAZDIDInspectionConsents در Checkpoint 5 | VehicleConfirmedAt جای رضایت‌نامه نیست |
| location در vehicle workflow و summary | ندارد | قرارداد مستقل location | BAZDIDInspectionLocations در Checkpoint 5 | prerequisite فعلی UI؛ منبع یا ستون خودرو نیست |
| `submission-model.ts`: factsConfirmed از وجود vehicle/location | ندارد | readiness از قواعد سرور و نسخه‌ها | وضعیت/receipt/snapshot جدول‌های ارسال آینده | وجود object، تأیید معتبر اطلاعات را اثبات نمی‌کند |

فایل‌های اصلی مصرف‌کننده علاوه بر schema/types: `vehicle-model.ts`، `vehicle-form.tsx`، `plate-input.tsx`، `vehicle-workflow.tsx`، `capture-package-model.ts`، `odometer-field.tsx`، `summary-sections.tsx`، `summary-source.ts`، `inspection.ts` adapter و repository/mock هستند؛ مسیر دقیق و hash در شاهد Frontend موجود است. نام/آدرس شخص، کد ملی و مشخصات مشتری دیگری در این فلو نیاز اثبات‌شده ندارند و به طرح اضافه نشدند.

### تعارض‌های اتصال که باید در Checkpoint 4 حل شوند

۱. Vehicle فعلی make/model/year/color/vinMasked/plate کامل می‌خواهد؛ مدل nullable منشأدار را نمی‌پذیرد. adapter آینده باید field state را نمایش دهد، نه دادهٔ خالی را با مقدار نمونه پر کند.
۲. فرم، plate trusted را قابل اصلاح و colorId را قابل انتخاب می‌کند؛ mock نیز آن‌ها را جایگزین می‌کند. Backend این مسیر را برای Present قفل می‌کند؛ حتی ارسال دوبارهٔ فیلد trusted با مقدار برابر در بخش manual رد می‌شود. تأیید صحیح با `confirmVehicle=true` و حذف آن فیلد از manual انجام می‌شود.
۳. پیش‌فرض رنگ با startsWith و fallback سفید، رابطهٔ معتبر lookup نیست. رنگ ناشناخته باید حفظ/بررسی شود؛ hex ناموجود تزئینی باقی می‌ماند.
۴. VIN و شاسی در عنوان فعلی UI مخلوط‌اند؛ مقدار reader دو فیلد مستقل است. mask، مبنای validation VIN کامل یا استخراج شاسی نیست.
۵. مدل فعلی تقویم سال ندارد، receipt زمان client می‌سازد و factsConfirmed صرفاً وجود object است؛ projection و قواعد سرور باید نسخه‌دار و پیش از اتصال مصوب شوند.
۶. `/api/inspections/.../vehicle/plate` در فایل endpoints Frontend، مجوز ساخت alias Backend نیست. پایهٔ آینده فقط `/API/BAZDID/` و مسیرهای ازپیش‌پیشنهادشدهٔ inspection است؛ هیچ endpoint جدیدی در 2E ثبت نمی‌شود.

## قرارداد typed دامنه و provenance

مدل پیشنهادی `InformationField<T>` عبارت است از Value، Origin، SourceStatus، InitialSourceStatus، ObservedSourceStatus، ValidationStatus/Code/PolicyId/ValidatedAtUtc، ManualAllowedWhenMissing و ManualBasisSourceRevision. `IsReadOnly` projection محاسبه‌شدهٔ سرور است، نه ستون قابل اعتماد یا property ورودی. هفت خانواده Make/Model/ModelYear/Color/Plate/Vin/Chassis ثابت‌اند؛ EAV یا نام فیلد آزاد وجود ندارد.

- `Origin=None/Brokerage/Manual` منشأ **مقدار مؤثر فعلی** است. Missing و Unavailable فاقد مقدار، Origin=None دارند ولی اعلام وضعیت از source کارگزاری آمده است.
- `SourceStatus=Present/Missing/Invalid/Unavailable` baseline پذیرفته‌شده و `InitialSourceStatus` شاهد تغییرناپذیر نخستین خواندن همان فیلد است؛ Manual آن را پاک نمی‌کند. `ObservedSourceStatus` مشاهدهٔ جدید را تا پذیرش از baseline جدا نگه می‌دارد.
- `ValidationStatus=None/PendingValidation/Valid/Invalid` مستقل است. Manual با syntax معتبر اما بررسی معنایی ناتمام، PendingValidation و غیرقابل تأیید نهایی است؛ ورودی بدقالب با 422 اصلاً ذخیره نمی‌شود. اگر مقدار Manual قبلی پس از تغییر policy از نظر معنایی نامعتبر شود، با مقدار و منشأ قبلی و Validation=Invalid حفظ می‌شود؛ این با SourceStatus=Invalid تفاوت دارد. در Missing معتبر، مالک می‌تواند همان مقدار دستی را اصلاح کند؛ تأیید تا Valid مسدود است.
- `ManualBasisSourceRevision` برای مقدار دستی، revision سروریِ baseline Missing را نگه می‌دارد؛ InitialSourceStatus و این شاهد، حتی بعد از refresh بدون تغییر آن فیلد، قابل تفسیر می‌مانند.

نگاشت enum صریح است: ordinalهای 2D Present=0/Missing=1/Invalid=2/Unavailable=3 به کد ذخیرهٔ 1/2/3/4 تبدیل می‌شوند؛ cast عددی ممنوع است. Validation در 2D، Valid/NotApplicable/Invalid/NotEvaluated دارد؛ به‌ترتیب به Valid/None/Invalid/None نگاشت و PolicyId/Code حفظ می‌شوند. source ثابت Brokerage در BrokerageField، معادل Origin=Brokerage برای یک مقدار null نیست. Manual و PendingValidation در reader 2D وجود ندارند و فقط از فرمان داخلی معتبر آینده ایجاد می‌شوند.

قاعدهٔ پیشنهادی قفل:

```text
isReadOnly = finalizedOrSubmitted
          OR sourceState != Current
          OR acceptedSourceStatus != Missing
          OR NOT approvedPolicy.manualAllowedWhenMissing
```

Present معتبر قفل است؛ Invalid، Unavailable، policy ناشناخته یا خرابی منبع هرگز Missing تلقی نمی‌شوند. فقط Missing صریح و policy نسخه‌دار اجازهٔ تکمیل می‌دهد. plate و modelYear با اجزای وابسته، یک فیلد منطقی‌اند. ColorHex metadata اختیاری است؛ Origin مستقل None/Brokerage/DerivedCatalog و readOnly دائمی دارد، زیرا reader 2D اصلاً آن را گزارش نمی‌کند. نبود mapping hex برابر Missing قابل‌ویرایش نیست.

## اعتبارسنجی پیشنهادی فیلدها

سیاست‌های زیر محدودیت فنی طراحی‌اند؛ policy کسب‌وکار و mapping Production هنوز طبق O09/O27/O29 نیازمند تصویب‌اند. سیاست‌های synthetic سال `1399`، VIN با prefix ساختگی و label رنگ `0`، validation Production نیستند. مجموعهٔ required fields و لزوم full VIN/chassis از ValidationProfileVersion مصوب سرور می‌آید؛ بدون آن قابلیت تأیید/ارسال فعال نمی‌شود.

| فیلد | normalization و validation پیشنهادی |
|---|---|
| Make/Model | رشتهٔ Unicode غیرخالی، سقف ۱۰۰؛ کنترل نویسه‌های کنترلی؛ trim/normalization فقط طبق policy همان فیلد. SourceText اصل bounded را نگه می‌دارد؛ identifier خارجی هیچ‌گاه normalize نمی‌شود. |
| ModelYear | زوج سال/تقویم؛ حد فنی 1..9999، بازهٔ واقعی با policy. Persian و Gregorian صریح‌اند؛ تبدیل صرفاً پس از تعیین تقویم، بدون حدس از بزرگی عدد و بدون تبدیل FK به سال. متن مبهم/تقویم نامعلوم Invalid/ReviewRequired و قفل است. صفر فقط در mapping همان فیلد، با شاهد PolicyId، Missing می‌شود. |
| Color | نام حداکثر ۸۰؛ manual فقط colorId از کاتالوگ نسخه‌دار مصوب. ده شناسهٔ موجود UI white/black/silver/grey/charcoal/blue/red/green/beige/brown پیشنهاد سازگاری‌اند، نه enum منبع کارگزاری. hex اختیاری `#RRGGBB` و بدون پیش‌فرض سفید است؛ تبدیل colorId به نام/hex از سرور. |
| Plate | چهار جزء 2/letter/3/2؛ normalization ارقام فارسی/عربی به ASCII و ي به ی فقط در ورودی پلاک؛ نگهداری صفر پیشرو. تبدیل کدها به integer، حذف کاراکتر دلخواه یا truncation ممنوع. |
| VIN | فقط پروفایل Standard17 مصوب: ASCII uppercase با ۱۷ نویسه و alphabet پیشنهادی بدون I/O/Q؛ trim فقط با policy. بررسی قالب، اصالت VIN یا check digit جهانی را اثبات نمی‌کند؛ check digit فقط در پروفایل حوزهٔ مصوب. VIN کامل در خروجی عمومی نیست. |
| Chassis | فیلد مستقل و opaque تا تعیین policy سازنده/دستهٔ خودرو؛ قاعدهٔ ۱۷ نویسهٔ VIN به آن تعمیم داده نمی‌شود. سقف فنی raw source برابر ۱۲۸؛ قالب/required بودن باید مصوب باشد. |
| Odometer | JSON integer صحیح 0..9007199254740991 و سقف کسب‌وکار مستقل؛ null=ثبت‌نشده، 0=مقدار معتبر. منفی، اعشار، overflow، numeric string و عدد خارج safe range در API رد می‌شوند؛ grouping/ارقام نمایشی را adapter UI تبدیل می‌کند و Backend عدد را دوباره می‌سنجد. |

مبنای فنی طول VIN، [مرجع NHTSA](https://www.nhtsa.gov/vin-decoder) است؛ این استناد، تصویب قوانین تمام خودروهای ایران یا مجوز ارسال VIN مشتری به سرویس خارجی نیست. هیچ VIN به decoder آنلاین ارسال نشد. برای خودرو/پلاک قدیمی یا قالب خاص، profile ناشناخته به ReviewRequired می‌رسد، نه Missing و نه پرکردن با دادهٔ ساختگی.

### پلاک ایرانی به‌عنوان یک فیلد

پروفایل فنی پیشنهادی `IR-UI-4PART-V1` دقیقاً مدل فعلی UI را پوشش می‌دهد: `firstTwoDigits/letter/threeDigits/regionDigits` و حروف `الف، ب، ج، د، س، ص، ط، ع، ق، ل، م، ن، و، ه، ی`. نمایش canonical در API object بخش‌بندی‌شده است؛ برای مقایسهٔ خصوصی از tuple طول‌دار و ثابت استفاده شود، نه concatenation مبهم. ترتیب نمایشی جهت RTL مجوز جابه‌جایی اجزا نیست. SourceText رشتهٔ اصلی را نگه می‌دارد و parser فقط با profile مصوب آن را به چهار جزء می‌برد.

Frontend فیلد vehicle category ندارد؛ از حرف پلاک یا شمارهٔ منطقه، مجوز نوع بیمه/دستهٔ خودرو استنباط نمی‌شود. اعتبار قانونی حرف/منطقه و دستهٔ قابل خدمت در O27 باز است. پلاک‌هایی که این چهار قسمت یا allowlist را ندارند، با خطای `UNSUPPORTED_PLATE_FORMAT` و هماهنگی با کارگزاری متوقف می‌شوند؛ فرم «فرمت متفاوت» فعلی نیز مسیر ثبت قالب دیگری ندارد. برای Present، تغییر حتی یک segment در بخش manual برابر FIELD_READ_ONLY است؛ برای Missing، باید هر چهار بخش با یک Origin/Policy/Validation ذخیره شوند، بدون ترکیب trusted/manual.

### دادهٔ حساس و مقدار ناقص

VinCiphertext/ChassisCiphertext فقط envelope حفاظت‌شدهٔ متن لازم‌اند، نه بایت رسانه. purpose باید به نسخهٔ قرارداد، InspectionId، RequestContextId، OwnerCustomerLinkId و نام فیلد bind شود؛ provider باید احراز اصالت، جلوگیری از جابه‌جایی ciphertext بین پرونده‌ها، rotation، key retention/backup و بازیابی روی IIS را اثبات کند. الگوریتم یا کلید موقت، HMAC به‌عنوان encryption یا API رمزنگاری جدیدِ ناسازگار با .NET 2.1 انتخاب نشده است. فقدان provider/key مصوب مساوی شکست نوشتن، نه ذخیرهٔ plaintext است؛ O05/O28 gate اجرا هستند.

mask VIN استاندارد فقط suffix محدود مصوب را نشان می‌دهد؛ برای مقدار کوتاه، هیچ نمایش کامل اتفاق نمی‌افتد. `Assurance=FullValue/MaskOnly` مانع جا زدن mask به‌عنوان full value می‌شود؛ FullValue به معنی اصالت تأییدشده نیست و ValidationStatus مستقل است. اگر تنها mask از منبع معتبر در دسترس باشد، حفظ آن برای نمایش مجاز ولی تأیید پرونده‌ای که full value لازم دارد مسدود است؛ customer حق overwrite آن را از unavailable بودن مقدار کامل به دست نمی‌آورد. برای raw source نامعتبر، ciphertext خصوصی می‌تواند شاهد محدود را نگه دارد؛ mask معتبر جعل نمی‌شود. نیاز به نگهداری full VIN/chassis و دورهٔ آن باید قبل از DDL تصویب شود؛ در صورت تصویب‌نشدن، ستون‌ها/پروفایل با تصمیم مستند کاهش می‌یابند.

## schema پیشنهادی BAZDIDInfo

[manifest کامل schema](../design/BAZDIDINFO_SCHEMA_PROPOSAL.json) **۱۳۱ ستون پیشنهادی، هفت خانواده و ۱۹ قاعدهٔ constraint** را با نام/نوع/طول/nullability/default فهرست می‌کند. این JSON، script SQL یا migration نیست؛ هیچ CREATE/ALTER اجرایی تولید یا اجرا نشد. checkpoint ایجاد، 4 است.

| گروه | ستون‌ها و تصمیم |
|---|---|
| مالکیت | InspectionId uniqueidentifier NOT NULL، PK clustered و یک‌به‌یک؛ RequestContextId و OwnerCustomerLinkId NOT NULL، همگی سروری. FK سه‌ستونی به `(Id,RequestContextId,OwnerCustomerLinkId)` در BAZDIDInspections آینده؛ parent نیازمند alternate key مصوب همان سه ستون است. NO ACTION؛ هیچ FK به کارگزاری یا جدول خیالیِ موجود ساخته نمی‌شود. |
| context | شناسهٔ خارجی درخواست/مشتری و BrokerageId/SourceSystem در Info تکرار نمی‌شوند؛ projection داخلی از context و linkage مالکِ پین‌شده حاصل می‌شود. Source IDs آن جدول‌ها باید immutable بمانند. ContextVersionAtSourceRead binary(8) صرفاً شاهد CAS است. |
| baseline منبع | SourceVersionMode tinyint، SourceVersion nvarchar(128) nullable، SourceRetrievedAtUtc datetime2(3)، SourceComparableHash binary(32)، SourceRevision bigint؛ versioned نیازمند نسخه و unversioned نیازمند NULL است. |
| refresh | SourceState، LastSourceAttemptAtUtc، PendingSourceHash/VersionMode/Version/RetrievedAtUtc و ChangedFieldMask؛ فقط fingerprint/شرط کاندید، نه تکثیر snapshot خام مشتری. |
| مقادیر خودرو | Make/Model nvarchar(100)، ModelYear smallint و تقویم tinyint، ColorName nvarchar(80)، hex char(7)، بخش‌های پلاک char(2)/nvarchar(3)/char(3)/char(2)، همگی nullable تا تکمیل. |
| شاهد source | برای Make/Model/ModelYear/Color/Plate، SourceText nvarchar(128) nullable؛ متن bounded و بدون truncation. raw حساس به‌جای متن در envelope همان فیلد قرار می‌گیرد؛ master کامل یا موبایل کپی نمی‌شود. |
| metadata هر X | XOrigin/SourceStatus/InitialSourceStatus/ObservedSourceStatus/ValidationStatus tinyint؛ XPolicyId و XValidationCode varchar(64)؛ XValidatedAtUtc datetime2(3) nullable؛ XManualAllowedWhenMissing bit؛ XManualBasisSourceRevision bigint nullable. X شامل همان هفت خانواده است. |
| حساس | Vin/ChassisCiphertext varbinary(2048) nullable، mask nvarchar(32) nullable و Assurance tinyint nullable؛ SensitiveProtectionProfileVersion varchar(64). طول envelope باید قبل از tx کنترل شود؛ overflow بدون truncation رد می‌شود. |
| کیلومتر | OdometerKm bigint nullable، Origin، ValidationStatus/Code/PolicyId و UpdatedAt/ValidatedAt UTC؛ منبع فقط Manual است؛ evidenceId در رابطهٔ مدارک آینده باقی می‌ماند. |
| تأیید | VehicleRevision bigint، VehicleConfirmedRevision/AtUtc/ByCustomerLinkId nullable؛ actor برابر مالک پین‌شده. تغییر مؤثر خودرو آن سه ستون را پاک می‌کند؛ تغییر عدد کیلومتر، تأیید خودرو را بی‌دلیل باطل نمی‌کند. |
| مغایرت | DiscrepancyField tinyint nullable و شرح nvarchar(500) nullable، کدهای model/year/color/vin منطبق UI؛ گزارش unresolved، ReviewRequired و بدون حق overwrite. |
| زمان/هم‌زمانی | CreatedAtUtc/UpdatedAtUtc datetime2(3) با UTC server default، FinalizedAtUtc nullable و یک Version rowversion NOT NULL؛ rowversion کلید اصلی یا تاریخ نیست. |

`BAZDIDInspections` هنوز وجود ندارد؛ افزودن OwnerCustomerLinkId و alternate key به طرح parent، پیشنهاد صریح این مرحله است و باید در migration مصوب Checkpoint 4 با همین Info هماهنگ ساخته شود. FK سه‌ستونی مانع اتصال Info به context/مالک متفاوت از همان inspection است. تطبیق مالک با context کارگزاری هنگام ایجاد و هر عمل، در transaction/authorization سرور نیز لازم است؛ FK به‌تنهایی OTP یا مجوز درخواست را اثبات نمی‌کند. audit موجود فقط action/resource/correlation حداقلی می‌گیرد؛ raw value یا متن exception در آن جا داده نمی‌شود. SourceText متن تحویل‌داده‌شده از reader است؛ بدون گواه mapping، ادعای حفظ بایت اصلی ستون Production نمی‌کند.

تنها index افزودهٔ پیشنهادی، `IX_BAZDIDInfo_RequestContext(RequestContextId,InspectionId)` غیر unique است؛ PK یکتایی Info هر inspection را می‌دهد. VIN، پلاک، موبایل و کد معرفی به index یکتایی حدسی تبدیل نمی‌شوند. تعداد ستون به‌خاطر typed value و metadata ثابت است؛ هزینهٔ schema صریح در برابر EAV، migration بیشتر هنگام افزودن فیلد است. varbinaryها bounded و مخصوص متن حساس‌اند؛ حداکثر مجموع طول‌های متغیر می‌تواند row-overflow بخواهد، بنابراین اندازه/IO باید روی SQL Server واقعی در Checkpoint 4 سنجیده شود. هیچ ادعای performance یا آزمون DDL این مرحله وجود ندارد.

### قواعد constraint و مرز service

manifest برای هر ستون nullability دقیق و FieldStateV1 مشترک دارد. قواعد None، BrokeragePresent، BrokerageInvalid و Manual، enumها، گروه‌های null، سال/تقویم، چهار جزء پلاک، hex، حساسیت، کیلومتر، confirmation و pending source صریح‌اند. در SQL نهایی، همهٔ ترکیب‌ها با IS NULL/IS NOT NULL سنجیده شوند؛ UNKNOWN در CHECK نباید حالت نامعتبر را عبور دهد. یک ستون nullable با مقایسهٔ ساده، قید کافی نیست. قیود نهایی باید با INSERT/UPDATE منفی روی SQL Server واقعی آزموده شوند، نه صرف parse.

موارد cross-row شامل وضعیت inspection، owner فعال، freshness، اعتبار policy، ممنوعیت تغییر InitialSourceStatus و post-submit lock از CHECK محلی به‌تنهایی نتیجه نمی‌شوند؛ query allowlist/مجوز کمینه، شرط UPDATE و transaction یکپارچه الزامی‌اند. confirmation ثبت‌شده می‌تواند هنگام قطع مبدأ به‌عنوان شاهد قبلی حفظ شود، ولی تا Current شدن منبع مؤثر نیست. FinalizedAt فقط همراه تأیید معتبر/نسخهٔ همان خودرو و sourceState=Current نوشته می‌شود؛ readiness کامل و مدارک در submit آینده دوباره سنجیده می‌شوند.

## چرخهٔ source و refresh

۱. در Checkpoint 3، resolve صرفاً زمینهٔ سرور می‌دهد؛ ورود/OTP/مالکیت مستقل‌اند. پس از احراز، snapshot باید با scope/request/customer/mobile معتبر سرور سازگار و policy آن مصوب همان محیط باشد.
۲. در POST ایجاد/resume آینده، source خارج transaction SQL خوانده، سپس context/مالک دوباره تحت CAS بررسی می‌شوند. inspection مالک را پین می‌کند و Info از baseline معتبر/وضعیت‌های صریح ساخته می‌شود؛ Invalid می‌تواند draft با ReviewRequired بسازد، Unavailable کلی یا هویت نامطمئن اجازهٔ initialization موفق ندارد.
۳. Missing قابل تکمیل به Manual تبدیل می‌شود؛ SourceStatus پذیرفته‌شده و InitialSourceStatus پاک نمی‌شوند. ورودی PendingValidation قابل ذخیره فقط در قالب typed معتبر و بدون تأیید نهایی است.
۴. GET مقدار پذیرفته‌شده را از رکورد durable می‌خواند؛ inspection ایجاد نمی‌کند و observation/refresh را در SQL ثبت نمی‌کند. preview اختیاری pending طبق قاعدهٔ پایین فقط بازخوانی بدون write است. آخرین sourceState ذخیره‌شده، ادعای آنلاین‌بودن همین لحظه نیست.
۵. PUT معتبر آینده قبل از تغییر/تأیید، source را با deadline/cancellation تازه می‌خواند. baseline، policy و fingerprint خصوصی با مشاهدهٔ جدید مقایسه می‌شوند. اگر تفاوت مؤثر باشد، transaction مستقلِ «ثبت مشاهده» فقط pending fingerprint/وضعیت/ObservedSourceStatus و audit را ثبت و **409 SOURCE_CHANGED** با Version جدید می‌دهد؛ manual value، منشأ و confirmation قبلی دست‌نخورده‌اند. این metadata مشاهده، تغییر جزئیِ موفقیت‌آمیز فرمان manual نیست و پاسخ باید صریحاً بگوید هنوز دادهٔ کاربر اعمال نشده است.
۶. پذیرش بعدی با expectedVersion جدید و `acceptSourceChanges=true`، source را دوباره می‌خواند؛ fingerprint باید با pending ثبت‌شده برابر باشد. کاندید تغییرکرده یا unavailable دوباره conflict/failure می‌دهد. فقط دادهٔ reader معتبر سرور اعمال می‌شود؛ client مقدار source، نسخه یا fingerprint authoritative نمی‌فرستد.

برای پذیرش قابل بازبینی، پاسخ 409 می‌تواند `details` از نوع پیشنهادی `SourceChangedDetails` داشته باشد: نسخهٔ جدید Info، نام فیلدهای تغییرکرده و `sourceChangePreview` با همان projection امن و ماسک‌شدهٔ candidate خوانده‌شده؛ preview همیشه readOnly است و اختیار دستی ایجاد نمی‌کند. GET بعدی فقط در صورت وجود pending، می‌تواند reader را بدون نوشتن SQL بازخوانی کند؛ اگر hash با pending و Info.Version خوانده‌شده هنوز برابر بود، preview متناظر همان نسخه را برمی‌گرداند. در غیر این صورت preview=null و requiresRefresh=true می‌دهد؛ PUT بعدی observation جدید ثبت می‌کند. قطع source نیز preview unavailable می‌دهد و مقدار تاریخی را حفظ می‌کند. هیچ raw source ID/mobile/VIN کامل یا hash مقایسه به این details راه نمی‌یابد؛ پذیرش با expectedVersion به همان مشاهده مقید می‌ماند.

| رویداد | رفتار پیشنهادی |
|---|---|
| همان نسخه و همان داده/سیاست | مقدار و Manual حفظ؛ نیاز به تأیید دوباره نیست. نوشتن بی‌دلیل انجام نشود؛ کنترل CAS همچنان لازم است. |
| نسخه تغییر کند ولی داده/سیاست مؤثر برابر باشد | SourceRevision/metadata baseline می‌تواند در فرمان صریح جلو رود؛ VehicleRevision/Manual/confirmation حفظ می‌شود. |
| همان نسخه و همان مجموعهٔ policy با دادهٔ متفاوت | SOURCE_INCONSISTENT و ReviewRequired؛ نسخهٔ منبع به‌تنهایی سند ثبات نیست. تغییر مصوب خود policy، مسیر بازاعتبارسنجی جدا دارد. |
| جزئیات trusted تغییر کند | SourceChanged؛ مقدار قبلی تا پذیرش صریح حفظ؛ پس از پذیرش، مقدار جدید trusted قفل و تأیید خودرو پاک می‌شود. |
| Missing به Present و مقدار Manual موجود | بدون overwrite خودکار؛ کاندید از source، تأیید صریح تغییر و audit لازم است. سپس Origin=Brokerage، شاهد InitialSourceStatus باقی و confirmation پاک می‌شود. |
| Missing همچنان Missing | Manual حفظ؛ با تغییر policy دوباره validate، در صورت شکست Validation=Invalid و readiness نامعتبر، بدون پاک‌کردن خاموش مقدار. اجازهٔ اصلاح Manual در Missing با Invalid خود source اشتباه نشود. |
| Present به Missing صریح | تا پذیرش، مقدار trusted قبلی حفظ و قفل؛ بعد از پذیرش و policy مصوب، مقدار null و تکمیل دستی ممکن می‌شود. مقدار trusted قدیمی خودکار Manual نمی‌شود. |
| Invalid/Unavailable فیلد | ویرایش باز نمی‌شود؛ مشاهدهٔ نامعتبر ReviewRequired است. source کلی unavailable باعث 503 و حفظ baseline/Manual/شاهد تأیید می‌شود؛ mutation و تأیید مسدودند. |
| مشتری/مالک/موبایل trusted عوض شود | SOURCE_IDENTITY_CHANGED، توقف عملیات، ابطال احراز مرتبط در ماژول آینده و نیاز به احراز دوباره؛ دادهٔ شخص جدید به inspection قدیمی وصل نمی‌شود. رفتار ایجاد تلاش مالک جدید قبل از اجرا باید مصوب شود. |
| refresh پس از submit | 409 INSPECTION_LOCKED؛ Info، زمان observation و snapshot ارسال تغییر نمی‌کنند. پیگیری تازه فقط با مجوز فرآیند جدید است. |

نسخهٔ منبع opaque است و UTC retrieval جای آن نیست. قرارداد 2D اکنون SourceVersion غیرخالی را لازم می‌داند؛ منبع واقعی بدون version، در آن قرارداد فعلی درست نمایش‌پذیر نیست. پیشنهاد تغییر **آینده و صریح** adapter/قرارداد، SourceVersionMode به‌همراه SourceVersion nullable است؛ نه تولید نسخه از ساعت و نه تغییر کد در 2E. fingerprint برای مقایسه از serialization canonical طول‌دار، ترتیب ثابت هفت فیلد، وضعیت‌ها، policy و تقویم/اجزای معنایی ساخته می‌شود؛ timestamp دریافت/نسخهٔ اعلامی از hash تفاوت مؤثر حذف می‌شوند. SHA-256 خصوصی ابزار equality است، نه ناشناس‌سازی PII، ورود، امضا یا تضمین صحت منبع؛ در log/API منتشر نمی‌شود.

در حالت unversioned، هر فرمان حساس دوباره source را می‌خواند و observation داخلی را با baseline مقایسه می‌کند؛ این کار race تغییر منبع پس از خواندن را کاملاً حذف نمی‌کند. بدون تضمین upstream، transaction محلی نمی‌تواند linearizability سراسری ادعا کند. TTL، رفتار outage و الزام بازخوانی پیش از submit باید در O30 تصویب شوند؛ پیش‌فرض امن برای عملیات حساس failure است و GET تاریخی مجاز می‌ماند.

## مرز transaction، هم‌زمانی و idempotency

طرح از ADO.NET پارامتری و transaction کوتاه روی SQL Server استفاده می‌کند؛ network call مبدأ داخل lock پایگاه انجام نمی‌شود. ترتیب lock همهٔ فرمان‌ها باید ثابت و مصوب باشد: context، inspection و سپس Info؛ مجوز و نسخهٔ خوانده‌شده قبل از source call داخل transaction دوباره بررسی شوند. عملیات SQL واقعی و جزئیات isolation/lock در Checkpoint 4 با تست رقابتی اثبات می‌شوند.

| فرمان آینده | واحد اتمیک و رفتار هم‌زمان |
|---|---|
| create/resume | بررسی principal/request/customer pinned، source snapshot معتبر، ایجاد یک current attempt طبق policy، Info اولیه، history و نتیجهٔ idempotency در یک transaction. یکتایی current/context و PK Info race را مهار می‌کنند؛ خطای duplicate به reselect مجاز/پاسخ replay منجر می‌شود، نه row دوم. GET سازنده نیست. |
| update manual | شرط owner/scope/حالت editable و expectedInfoVersion + expectedInspectionVersion، allowlist، validation همهٔ تغییرها، UPDATE با CAS، پاک‌کردن confirmation در تغییر مؤثر خودرو، audit و نتیجهٔ موفق همگی یک transaction؛ خطای یک فیلد یعنی rollback تمام تغییرهای manual. |
| مشاهدهٔ تغییر source | پس از authorization و نسخهٔ صحیح، فقط metadata مشاهده در transaction جدا ثبت می‌شود و SourceChanged برمی‌گردد؛ هیچ partial update مقدار manual صورت نمی‌گیرد. درخواست از ابتدا stale پیش از این کار 409 می‌گیرد و source به‌خاطر آن خوانده نمی‌شود. |
| پذیرش refresh/تأیید | بازخوانی منبع، تطبیق pending fingerprint و CAS/مالکیت، apply کاندید پذیرفته‌شده و validate مجدد Manual در یک transaction؛ تغییر مؤثر VehicleRevision را افزایش و confirmation قبلی را باطل می‌کند. تأیید تازه فقط برای همان revision و قواعد کامل معتبر است. |
| odometer | همان ownership/Info CAS و lock پس از submit؛ عدد مستقل در Info، شاهد عکس از رابطهٔ مدارک همان inspection. فقط Info.Version عوض می‌شود؛ VehicleRevision بی‌دلیل تغییر نمی‌کند. |
| submit هم‌زمان با edit | در Checkpoint 7 همان lock parent و CAS آخرین Info/inspection، readiness، receipt و snapshot ثابت در یک transaction؛ یکی برنده، دیگری 409؛ submit دوباره با کلید یکسان همان receipt را می‌دهد. |

Version یک rowversion هشت‌بایتی است، با Base64 نقل می‌شود و تاریخ/مجوز نیست؛ حتی UPDATE بی‌تغییر ممکن است آن را عوض کند. [مرجع فنی Microsoft](https://learn.microsoft.com/en-us/sql/t-sql/data-types/rowversion-transact-sql?view=sql-server-ver15). SQL آینده باید `OUTPUT inserted.Version` را در همان transaction بگیرد؛ صفر ردیف UPDATE موفقیت نیست. پس از احراز مالکیت، stale برابر `409 VERSION_CONFLICT` است؛ منبعِ خارج مالکیت پاسخ یکسان 404 دارد و conflict نباید وجود پروندهٔ دیگری را افشا کند.

SourceRevision، نسخهٔ provider و Info.Version سه مفهوم جدا هستند. VehicleRevision فقط تغییر مؤثر هفت فیلد/قواعد لازم را شماره‌گذاری می‌کند؛ VehicleConfirmedRevision به همان وصل است. مقایسهٔ byte توکن، sorting یا دستکاری آن در browser مجوز نمی‌سازد. پس از submit هیچ مسیری حتی refresh زمان‌های Info را UPDATE نمی‌کند؛ نسخهٔ تاریخی از BAZDIDInspectionSubmissions آینده خوانده می‌شود و به join روی source متغیر وابسته نیست.

POST create و submit کلید idempotency می‌خواهند. برای PUT information نیز کلید در BAZDIDIdempotencyRecords آینده پیشنهاد می‌شود: scope سروری + inspection + command + key یکتا، hash canonical فرمان و پاسخ حداقلی بدون PII. replay موفقِ یکسان فقط پس از authorization تازه همان نتیجهٔ قبلی را برمی‌گرداند؛ نسخهٔ آن الزاماً آخرین نسخهٔ فعلی نیست. body متفاوت با همان key برابر 409 IDEMPOTENCY_KEY_REUSED است. بدون key، retry با نسخهٔ stale برابر 409 است و عملیات خاموش تکرار نمی‌شود. observation ناموفق SourceChanged نتیجهٔ موفق manual محسوب/مصرف نمی‌شود؛ فرمان اصلاح‌شدهٔ پذیرش باید کلید تازه داشته باشد. شکست update/audit/idempotency همگی rollback می‌شوند؛ retry کور خطای مبهم commit ممنوع است.

## DTO و مسیرهای پیشنهادی آینده

هیچ‌یک از موارد این بخش در کد، controller یا Swagger زنده ثبت نشده‌اند. تنها مسیرهای ازپیش‌پیشنهادشده تکمیل می‌شوند: `GET /API/BAZDID/inspections/{inspectionId}/information` و `PUT` همان مسیر برای update/confirmation؛ projection خودرو در مسیر GET vehicle و PUT odometer مطابق برنامهٔ موجود Checkpoint 5، همین داده را مصرف می‌کنند و ذخیرهٔ موازی نمی‌سازند. refresh endpoint جدید یا alias `/api` پیشنهاد نشده است. پایه از IIS PathBase می‌آید و در route controller دوباره تکرار نمی‌شود.

DTO عمومی آینده `InspectionInformationResponse` شامل inspectionId، info/inspection version، fields هفت‌گانهٔ nullable با metadata، colorHex اختیاری، odometer، confirmation، sourceState/retrieval time و sourceChangePreview nullable طبق قاعدهٔ بالا است. raw SourceRequestId/CustomerId/mobile و ciphertext به browser داده نمی‌شوند. projection داخلی `InformationPersistenceContext` از join معتبر، InspectionId/RequestContextId/OwnerCustomerLinkId، BrokerageId/SourceSystem، شناسه‌های opaque مبدأ و نسخه/زمان snapshot را دارد؛ این فهرست ورودی endpoint نیست.

نمونهٔ **پیشنهادی و ساختگیِ بخشی از پاسخ**؛ باقی فیلدها دقیقاً همین envelope را با نوع مخصوص دارند، نه placeholder برای کامل جلوه‌دادن خودرو:

```json
{
  "inspectionId": "00000000-0000-0000-0000-000000000001",
  "version": "AQIDBAUGBwg=",
  "inspectionVersion": "CAcGBQQDAgE=",
  "fields": {
    "make": { "value": "سازندهٔ آزمایشی", "origin": "Brokerage", "sourceStatus": "Present", "initialSourceStatus": "Present", "observedSourceStatus": "Present", "isReadOnly": true, "validation": { "status": "Valid", "policyId": "example-make-v1", "code": "VALID" } },
    "color": { "value": null, "origin": "None", "sourceStatus": "Missing", "initialSourceStatus": "Missing", "observedSourceStatus": "Missing", "isReadOnly": false, "validation": { "status": "None", "policyId": "example-color-v1", "code": "EXPLICITLY_MISSING" } }
  },
  "odometer": { "kilometers": 0, "origin": "Manual", "sourceStatus": null, "isReadOnly": false, "validation": { "status": "Valid", "policyId": "example-odometer-v1", "code": "VALID" } },
  "confirmation": { "confirmed": false, "confirmedAtUtc": null },
  "source": { "state": "Current", "retrievedAtUtc": "2026-11-02T00:00:00Z", "requiresReconfirmation": false }
}
```

قرارداد شکل کامل Valueها: make/model رشته؛ modelYear برابر `{year:int, calendar:Persian|Gregorian}`؛ color برابر `{name:string}`؛ plate برابر چهار segment واقعی UI؛ vin/chassis برابر `{masked:string, assurance:FullValue|MaskOnly}`. ColorHex envelope جدا و readOnly با origin/SourceStatus/Validation خود دارد؛ کیلومتر integer مستقل با SourceStatus=null چون از brokerage نیامده است. `validatedAtUtc` در validation پاسخ nullable و server-controlled است. unavailable بودن source یا finalized بودن، isReadOnly تمام فیلدها و odometer را true می‌کند؛ روی رکورد submitted، confirmation و timestamp همان snapshot ثابت‌اند.

DTO ورودی `UpdateInspectionInformationRequest` دقیقاً expectedVersion، expectedInspectionVersion، manual، confirmVehicle، acceptSourceChanges و discrepancy را allowlist می‌کند. manual فقط کلیدهای make/model/modelYear/color/plate/vin/chassisNumber دارد و هیچ envelope منشأ/قفل/status/policy قبول نمی‌کند؛ رنگ ورودی فقط `{colorId}`، حساس‌ها فقط full string در فیلد مجاز، و سال زوج صریح است. property حذف‌شده یعنی بدون تغییر؛ null فقط برای پاک‌کردن مقدار Manual مجاز در Missing پذیرفته می‌شود و تأیید با فیلد required خالی رد می‌شود. کل object پلاک اجباری است؛ patch یک segment ممنوع است. کیلومتر از مسیر planned odometer تغییر می‌کند، نه دو محل رقابت‌کننده در manual.

نمونهٔ **پیشنهادیِ فرمان** تکمیل یک رنگ Missing؛ مقدار source یا هویت ارسال نمی‌شود:

```json
{
  "expectedVersion": "AQIDBAUGBwg=",
  "expectedInspectionVersion": "CAcGBQQDAgE=",
  "manual": { "color": { "colorId": "blue" } },
  "confirmVehicle": false,
  "acceptSourceChanges": false
}
```

هر property ناشناخته، duplicate JSON key، ورودی source/tenant/customer/request ID، مقدار readOnly، raw sourceVersion یا flag provenance با 400 رد می‌شود؛ bind مستقیم entity ممنوع است. با Newtonsoft سازگار 2.1، DTO بسته و بررسی حضور key لازم است؛ null با omission یکی نیست. payload خلاف قاعدهٔ فیلد برابر 422 و trusted overwrite برابر `422 FIELD_READ_ONLY` با fieldErrors فقط نام مسیر/کد امن است؛ مقدار حساس echo نمی‌شود. CSRF/کوکی/authorization در ماژول مصوب آینده الزامی‌اند؛ CORS فعلیِ read-only مجوز PUT ایجاد نمی‌کند.

خطاهای پیشنهادی دیگر: 401 احرازنشده، 404 خارج مالکیت/موجودنبودن، 409 VERSION_CONFLICT/SOURCE_CHANGED/SOURCE_IDENTITY_CHANGED/INSPECTION_LOCKED، 422 UNSUPPORTED_PLATE_FORMAT/VALIDATION_FAILED/REVIEW_REQUIRED، 503 SOURCE_UNAVAILABLE/SOURCE_INCONSISTENT/VALIDATION_POLICY_UNAVAILABLE/PROTECTION_UNAVAILABLE. body خطا code/message/correlationId/fieldErrors محدود دارد؛ فقط SOURCE_CHANGED می‌تواند details typed امن بالا را اضافه کند، نه متن آزاد exception. source unavailable پاسخ NotFound یا Missing نمی‌سازد. GET و پاسخ‌های خصوصی no-store دارند؛ exception/SQL/متن خام source یا اطلاعات پروندهٔ دیگر به پاسخ راه نمی‌یابد.

## سناریوهای پذیرش طراحی؛ اجرا نشده‌اند

این جدول، تحلیل مورد انتظار برای نوشتن آزمون Checkpoint 4 است؛ هیچ سطر آن آزمون runtime پاس‌شدهٔ طرح نیست.

| شناسه | سناریو | انتظار طراحی و ذخیره |
|---|---|---|
| E01 | همهٔ فیلدهای required، Present معتبر | مقدار trusted و metadata پین؛ manual آن‌ها قفل؛ تأیید فقط پس از مجوز/نسخه/freshness |
| E02 | Color یا Plate، Missing صریح | مقدار null و source/initial=Missing؛ manual تنها طبق policy؛ Origin=Manual بعد از validation |
| E03 | ModelYear نامعتبر یا تقویم نامعلوم | SourceText/Invalid حفظ؛ readonly؛ ReviewRequired و بدون تبدیل به Missing |
| E04 | source موقتاً unavailable | baseline و Manual حفظ، mutation/تأیید 503؛ همهٔ قفل‌ها بسته؛ GET تاریخی بدون ادعای تازگی |
| E05 | candidate موبایل/مالک متعارض | هویت جدید وارد Info نمی‌شود؛ عملیات و احراز وابسته متوقف/باطل، بررسی انسانی/قرارداد تازه |
| E06 | client یک segment trusted plate را عوض کند | 422 FIELD_READ_ONLY و rollback همهٔ تغییرهای manual همان فرمان |
| E07 | client کل فیلد trusted را با مقدار برابر بفرستد | به‌عنوان property غیرمجاز در manual رد؛ تأیید با فرمان confirmation مستقل از مقدار |
| E08 | source سال صفر را طبق policy Missing بداند | فقط همان فیلد Missing؛ کیلومتر صفر و label معتبر دیگر پاک نمی‌شوند |
| E09 | عدد کیلومتر صفر/اعشار/unsafe integer | صفر Valid؛ اعشار/منفی/overflow/رشته 422 و بدون write |
| E10 | manual syntax معتبر ولی validation معنایی pending | Origin=Manual، source Missing و basis محفوظ؛ تأیید و submit ممنوع تا Valid |
| E11 | دو update با یک rowversion | فقط یکی موفق؛ دیگری 409، بدون overwrite و audit موفق کاذب |
| E12 | refresh هنگام Manual و Missing→Present | فقط observation/409 ابتدا؛ مقدار Manual تا پذیرش صریح حفظ؛ تأیید بعدی برای نسخهٔ جدید |
| E13 | Present→Missing واقعی | تا پذیرش قفل؛ پس از پذیرش null و manual policy، بدون تبدیل مقدار قبلی به Manual |
| E14 | providerVersion ثابت اما payload متفاوت | ReviewRequired/SOURCE_INCONSISTENT؛ عدم اعتماد کور به نسخه |
| E15 | provider فاقد version | mode=Unversioned و version=NULL؛ compare/hash خصوصی + بازخوانی؛ بدون timestamp جعلی به‌عنوان نسخه |
| E16 | تغییر منبع حین پذیرش کاندید | fingerprint جدید با pending برابر نیست؛ SOURCE_CHANGED و بدون apply client data |
| E17 | تغییر Info هم‌زمان با submit | lock parent و CAS؛ یک فرمان برنده، دیگری conflict؛ snapshot/receipt نیمه‌کاره ایجاد نمی‌شود |
| E18 | refresh رکورد submitted | 409؛ حتی timestampهای Info ثابت، snapshot تاریخی دست‌نخورده |
| E19 | body با source/tenant/readOnly یا JSON key تکراری | 400 قبل از bind entity؛ هیچ اختیار از client ساخته نمی‌شود |
| E20 | parent inspection/context/owner نامنطبق | FK سه‌ستونی و owner query مانع اتصال؛ درخواست غیرمجاز 404، بدون افشای اختلاف مالک |
| E21 | mask-only با پروفایل نیازمند full VIN | نمایش mask مجاز، readiness مسدود؛ mask به full validate یا دستی‌پذیر تبدیل نمی‌شود |
| E22 | شکست audit/crypto/idempotency در update | rollback همهٔ تغییرهای کسب‌وکار؛ plaintext fallback و retry کور ممنوع |
| E23 | retry یک کلید idempotency با body متفاوت | 409؛ با body یکسان و authorization معتبر، همان نتیجهٔ موفق قبلی |
| E24 | رنگ منبع خارج کاتالوگ یا hex ناموجود | نام source حفظ و قفل؛ hex nullable؛ fallback سفید یا انتخاب نزدیک‌ترین label ممنوع |

## راه اجرای Checkpoint 4 و تصمیم‌های باز

این خروجی آمادهٔ تبدیل به قرارداد و migration **پس از gateهای صریح** است؛ مجوز انجام آن‌ها در 2E داده نشده است:

۱. O09/O27/O29: required fields، calendar/ranges، پلاک/دستهٔ خودرو، کاتالوگ رنگ، profile VIN/chassis و سقف کیلومتر با نمونهٔ ساختگی و مسئول تصویب شوند؛ ناسازگاری UI و semantics null با تیم Frontend قرارداد شود.
۲. O05/O28: نیاز full identifier، provider/envelope پایدار سازگار 2.1، key ring خارج release، ACL/rotation/backup/recovery و طول ciphertext اثبات شوند؛ هیچ کلید نمونه‌ای در Git قرار نگیرد.
۳. O20–O22/O30: mapping، هویت و freshness منبع؛ در صورت unversioned بودن، تغییر داخلی reader آگاهانه و با آزمون انجام شود. O24/O26 برای SQL runtime و حساب‌های واقعی کم‌اختیار هنوز بازند.
۴. در Checkpoint 4، parent inspection با owner پین‌شده و alternate key، سپس Info و index/قیود از manifest به SQL guarded مصوب تبدیل شوند؛ SQL آینده باید نام BAZDID داشته باشد. جدول‌های مبدأ و سه جدول فعلی بی‌مجوز تغییر نکنند. max row/row-overflow، NULL در CHECK و collation parser روی SQL Server واقعی تست شوند.
۵. repository پارامتری، transaction/CAS، crypto adapter، mapper explicit enum، DTO بسته و APIهای مصوب ساخته و E01–E24 با آزمون واقعی پوشش داده شوند؛ مجوز/CSRF/expiry/submit از مراحل خودش مصرف شود. readiness فعلی Frontend جای این کنترل‌ها نیست.
۶. create/resume، چند درخواست یک مشتری، race، rollback، owner change، key loss/recovery و post-submit immutability در محیط تست مصوب ثابت شوند؛ سپس OpenAPI از behavior واقعی تولید و اتصال Frontend جداگانه مجاز شود.

نیاز داشتن تصمیم‌های کسب‌وکار/زیرساخت، با خالی‌گذاشتن ساختار یا جعل mapping جبران نشده است؛ نوع‌ها و رفتار شکست این طرح مشخص‌اند و تا تصویب policy، مسیر حساس fail-closed می‌ماند. تصمیم‌ها در [دفتر باز](../OPEN_DECISIONS_FA.md) و تعارض‌ها در [شناسنامهٔ منابع](../SOURCE_REFERENCES_FA.md) ثبت شده‌اند. جدول source جدید، foreign key مبدأ، staff/reviewer یا فرآیند تأیید انسانی عملیاتی در این مرحله طراحی اجرایی/پیاده نشد.

## کار واقعی این مرحله، آزمون و Git

ترتیب واقعی: احراز status/مجوز، بررسی کد و اسناد 2D، خواندن مدل/فرم/خلاصهٔ Frontend و ثبت hash، restore/build/test تازه، تطبیق تعریف سه جدول بدون اتصال SQL، تهیهٔ ماتریس و manifest نوع‌دار، مرور حالت‌های refresh/NULL/مالکیت و سناریوها، سپس اعتبارسنجی مستندات و انتشار امن. در فرمان اولیهٔ inventory، Git با cwd Backend و safe-directory مربوط به Frontend اجرا شد و metadata نداد؛ با `-C` صریح اصلاح شد. این خطای ابزار هیچ فایل یا تاریخچه‌ای را تغییر نداد. log یا خطای runtime تازهٔ دیگری ساخته/حدس زده نمی‌شود.

فرمان‌های واقعاً اجراشده از ریشهٔ Backend:

```powershell
dotnet restore Bazdid.sln --locked-mode
dotnet build Bazdid.sln --configuration Release --no-restore
dotnet test Bazdid.sln --configuration Release --no-build --no-restore
```

هر سه exit صفر؛ build صفر warning/error؛ ۶۵ unit و ۴۳ integration، جمع ۱۰۸ موفق. آزمون جدیدی افزوده نشد و کد runtime/آزمون موجود تغییر نکرد. smoke Kestrel، SQL behavior، migration، crypto و DTO/API پیشنهادی در 2E اجرا نشدند؛ شواهد 2D/2C تاریخی‌اند. ابزارهای موقت صرفاً artifact/پیوند/hash/scope و consistency طرح را کنترل می‌کنند و آزمون پیاده‌سازی این مدل نیستند. همسوسازی نخست اسناد با stdin در Windows PowerShell به‌دلیل encoding عنوان فارسی را پیدا نکرد و قبل از نوشتن فایل‌های هدف متوقف شد؛ اجرای ابزار موقت از فایل UTF-8 مشکل را رفع کرد. نتیجهٔ واقعی کنترل مستندات در [گزارش اعتبارسنجی طراحی](../checkpoint2e/DESIGN_VALIDATION.json) ثبت می‌شود.

کنترل پیش از commit طرح: ۱۵ فایل در دامنه، ۱۱ Markdown، ۱۷۰ پیوند محلی و یک anchor معتبر، دو مثال JSON قابل parse؛ ۱۴۱ فایل فعلی و ۲۱۱ blob تاریخی main بدون هشدار راز باقی‌مانده اسکن شدند. ۱۳۱ نام/نوع/nullability ستون، هفت خانواده، ۱۹ قاعده، FK آینده و ۲۴ سناریوی تحلیلی کنترل شدند؛ این نتیجه آزمون اجرای SQL/DTO نیست. hash هر ۲۶ فایل Frontend، وضعیت ۲۲۶ تغییر قبلی آن و فایل untracked کاربر ثابت ماندند؛ source/test/SQL/dependency diff صفر است.

فایل‌های ایجادشده: همین walkthrough، manifest schema و شواهد Frontend/اجرای برنامه/اعتبارسنجی. PLAN، طراحی داده، mapping، API، تصمیم‌ها، منابع، ادامهٔ AI، فهرست راهنما، README و AGENTS همسو شدند. commit طرح `9f5f7df94dc6f1dd6e854af8d52e2d4818fd3d06` با push عادی منتشر و HEAD محلی/remote با اختلاف `0/0` تأیید شد؛ همین راهنما، manifest و شاهد کنترل از GitHub با blob SHA برابر خوانده شدند. [گزارش GitHub](../GITHUB_SYNC_FA.md) جزئیات و تفاوت commit طرح با تکمیل مستنداتی انتشار را ثبت می‌کند؛ SHA نهایی گزارش تکمیلی از Git واقعی در تحویل خوانده می‌شود. فایل شخصی و تغییرهای قبلی Frontend حفظ شدند؛ source خصوصی، کلید، PII واقعی، archive یا فایل پایگاه وارد بسته نشد.

**2E در دامنهٔ طراحی: 19% + 1 = 20%؛ باقی‌مانده 80%.** سهم Checkpoint 2 اکنون ۸ از ۱۲ واحد و هدف پایان آن همچنان ۲۴٪ است. گام پیشنهادی بعد 2F با مجوز جداگانه و پیش‌نیازهای واقعی است؛ برآورد مشروط پیشنهادی دو واحد تا ۲۲٪، فقط پس از تصویب scope و پذیرش شواهد آن، نه امتیاز فعلی. 2F/2G و Checkpoint 4 در این کار شروع نشدند.
