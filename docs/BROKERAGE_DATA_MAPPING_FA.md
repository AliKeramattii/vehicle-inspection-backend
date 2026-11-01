# نگاشت خواندنی دادهٔ کارگزاری

## قرارداد منطقی adapter

`IBrokerageRequestReader` باید دو قابلیت منطقی داشته باشد: حل کد معرفی در tenant معتبر سرور، و بازخوانی زمینهٔ درخواست با شناسهٔ مبدأ. خروجی `BrokerageRequestSnapshot` شامل شناسه‌های مبدأ، موبایل معتبر، وضعیت مجازبودن درخواست، فیلدهای خودرو با وضعیت/منشأ و شناسه یا زمان نسخهٔ منبع است. این‌ها نام interface و DTO پیشنهادی‌اند؛ query یا schema مبدأ نیستند.

نتیجه می‌تواند `Found`، `NotFound`، `Ambiguous`، `Ineligible` یا `Unavailable` باشد. هیچ‌کدام نباید به‌صورت خودکار به fixture تبدیل شوند. کد تکراری بدون قاعدهٔ یکتایی مصوب، انتخاب تصادفی درخواست را مجاز نمی‌کند. timeout یا خطای SQL با «اطلاعات مفقود» یکی نیست.

credential خواندن مبدأ از credential نوشتن BAZDID جدا باشد؛ DBA به viewهای مصوب یا اشیای دقیق مجوز SELECT می‌دهد. فهرست schema/table/column اکنون **نامعلوم** است. نه query آزمایشی روی Production نوشته می‌شود و نه ساخت/تغییر جدول آن مجاز است. هیچ FK به جدول مبدأ تا شناخت schema پیشنهاد اجرایی نمی‌شود.

## دفتر mapping لازم از تیم کارگزاری

تمام ردیف‌ها باید پیش از adapter واقعی با نام واقعی، نوع، nullability، نمونهٔ ساختگی و مسئول تأیید تکمیل شوند.

| کلید منطقی | نیاز و mapping مقصد | وضعیت مبدأ |
|---|---|---|
| `brokerageId` / `sourceSystem` | context معتبر از تنظیمات نصب؛ نه ورودی مرورگر | شناسه و حوزهٔ یکتایی نامعلوم |
| `sourceCustomerId` | رشتهٔ پایدار در `BAZDIDCustomerLinks`؛ حفظ بدون cast اجباری | جدول/ستون/join نامعلوم |
| `sourceRequestId` | رشتهٔ پایدار و یکتا در context همان tenant | جدول/ستون/join نامعلوم |
| `referralCode` | شاخص درخواست بیمه؛ normalization و lookup مصوب | ستون، حساسیت به case و uniqueness نامعلوم |
| `trustedMobile` | منبع trusted برای OTP؛ masked در UI؛ plaintext حداقلی | ستون، ارتباط مالک و وضعیت تأیید نامعلوم |
| `requestEligibility` | مجاز/بسته/لغو؛ بازبینی پیش از OTP و ایجاد/ارسال طبق قرارداد | وضعیت‌ها و قواعد نامعلوم |
| `sourceVehicleReference` | شناسهٔ خارجی اختیاری در snapshot | منبع/نیاز واقعی نامعلوم |
| `make`, `model` | نام سازنده و مدل؛ مدل UI `Vehicle.make/model` | جدول یا کد lookup نامعلوم |
| `modelYear` | `Vehicle.year`؛ نوع تقویم و بازه باید روشن شود | mapping و معنی صفر نامعلوم |
| `color`, `bodyColor` | `colorName` و hex اختیاری؛ رنگ ساختگی پیش‌فرض ممنوع | mapping کد رنگ نامعلوم |
| `plate` | چهار segment معتبر؛ حرف «الف» تا سه نویسه | فرمت ذخیره و تجزیه نامعلوم |
| `vin` / `chassisNumber` | مقدار trusted در صورت نیاز؛ `maskedVin → vinMasked` در UI | تفاوت VIN استاندارد و شاسی قدیمی نامعلوم |
| `sourceVersion` / `retrievedAt` | تغییر موبایل/مالک/خودرو و جلوگیری از snapshot کهنه | rowversion/زمان معتبر منبع نامعلوم |

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

در Development/Test: tenant برابر `TEST-BROKERAGE`، مشتری `TEST-CUSTOMER-001`، درخواست `TEST-REQUEST-001`، referral برابر `A4K9P2` و موبایل fixture برابر `09000000001`. این رشته صرفاً دادهٔ آزمون است؛ ادعای رزروشده یا تخصیص‌نیافته‌بودن شماره نمی‌شود. **خروجی SMS در حالت ساختگی کاملاً غیرفعال است.** نام مشتری «مشتری آزمایشی» و مدل/رنگ دادهٔ ساختگی‌اند. fixtureهای کامل، ناقص، صفر با mapping و دو درخواست برای یک مشتری جدا تعریف شوند؛ اکنون seed اجرا نمی‌شود.

کلاس‌های پیشنهادی `SyntheticBrokerageRequestReader` و `SqlBrokerageRequestReader` تنها از DI محیط انتخاب می‌شوند. در Production فعال‌بودن synthetic، نبود mapping مصوب یا قرارداد SMS باید startup احراز هویت را fail-closed کند. Production با دادهٔ mock «موقتاً» راه‌اندازی نمی‌شود.

## refresh و منشأ

حل referral یک context کوتاه‌عمر سرور می‌دهد؛ موبایل در زمان صدور/ارسال مجدد و verify با نسخهٔ مورد اعتماد سازگار می‌ماند. تغییر موبایل/مالک، چالش قبلی را باطل می‌کند. در ایجاد بازدید، snapshot مبنای خواندنی پین و زمان بازیابی ثبت می‌شود. اگر پیش از نهایی‌سازی مبدأ تغییر کرد، Backend با `SOURCE_CHANGED` تأیید مجدد می‌خواهد؛ مقدار trusted بی‌صدا روی Manual نوشته نمی‌شود. پس از submit، snapshot تاریخی ثابت است. سیاست دقیق استعلام تازگی و امکان نسخه‌خوانی منبع در تصمیم‌های باز است.
