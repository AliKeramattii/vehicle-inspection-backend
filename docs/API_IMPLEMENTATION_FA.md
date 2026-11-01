# نقشهٔ قرارداد و پیاده‌سازی API

وضعیت همهٔ مسیرهای این سند **پیشنهادی برای Phase 1** است. سرویس تجاری موجود تأیید نشده و OpenAPI اجرایی هنوز تولید نشده است. مبنای مقایسه [endpointهای مرجع](reference/contracts/endpoints.json) و [schemaهای مرجع](reference/contracts/schemas.json) است؛ ۵۵ ترکیب HTTP تاریخی الزام به ساخت همهٔ آن‌ها نیست.

## پایه و قواعد مشترک

پایهٔ عمومی قطعی `/API/BAZDID/` است. در جدول زیر `R` به همین پایه اشاره دارد؛ مثلاً `R + auth/otp/request` برابر `/API/BAZDID/auth/otp/request` است. Controller فقط `auth/otp/request` را ثبت می‌کند. هیچ `/api` دیگری به آن وصل نمی‌شود. جزئیات IIS در [راهنمای استقرار](IIS_DEPLOYMENT_FA.md).

JSON با camelCase، UTF-8، زمان ISO-8601/UTC، شناسه‌های opaque، نسخهٔ base64 rowversion و enumهای صریح تعریف شود. query حساس مانند کد/موبایل برای ورود استفاده نشود. DTOها از entity جدا و فهرست فیلدهای ورودی allowlist باشد. mutation نیازمند CSRF و owner معتبر است. پاسخ‌های هویت، اطلاعات، وضعیت، رسید و رسانه `Cache-Control: no-store` دارند.

خطای پیشنهادی شامل `code`، پیام فارسی امن `message`، `correlationId` و `fieldErrors` اختیاری است؛ stack، SQL، source ID حساس یا مسیر فیزیکی ندارد. قواعد عمومی: `400` ساختار نامعتبر، `401` احراز نشده، `403` مجوز/CSRF نامعتبر، `404` موجود نیست یا خارج مالکیت، `409` تعارض نسخه/حالت/idempotency، `413` حجم، `415` نوع، `422` قاعدهٔ دامنه و `429` نرخ با `Retry-After`. خطای مبدأ `503 SOURCE_UNAVAILABLE` با retry امن است؛ payload خطای فنی مبدأ برنمی‌گردد.

## مسیرهای اولیه و provenance

| checkpoint | method و suffix پس از `R` | مرجع و رفتار پیشنهادی |
|---|---|---|
| 1 | `GET health/live` | تازه؛ فقط alive، بدون اطلاعات محیط/connection؛ readiness داخلی جدا |
| 1 | `GET swagger/` و `GET swagger/v1/swagger.json` | مستندات همان implementation؛ محافظت در Production |
| 3 | `GET auth/csrf` | تازه؛ token درخواست CSRF، برای origin مجاز و `no-store` |
| 3 | `POST referrals/validate` | اصلاح AU05؛ `{code}` → context opaque و موبایل masked، بدون مجوز تجاری |
| 3 | `POST auth/otp/request` | AU06؛ `{referralCode, challengeContextId}`؛ موبایل ورودی ندارد؛ resend از همین مسیر و generation معتبر |
| 3 | `POST auth/otp/verify` | AU07؛ `{challengeId, code}` → کوکی و Session حداقلی؛ مصرف یک‌بار |
| 3 | `GET me` | AU03؛ state/kind/expiresAt و current inspection مجاز در صورت وجود؛ عدم ایجاد روی GET |
| 3 | `POST auth/logout` | AU04؛ ابطال SQL و حذف cookie با Path یکسان |
| 4 | `POST inspections` | I01؛ create/resume فقط context نشست؛ `Idempotency-Key`، بدون customer/request/tenant دلخواه |
| 4 | `GET inspections/current` | I03؛ lookup درخواست احرازشده؛ nullable/404 طبق DTO مصوب؛ GET سازنده نیست |
| 4 | `GET inspections/{inspectionId}` | I02؛ summary محدود مالک و نسخه |
| 4 | `GET inspections/{inspectionId}/information` | تازه؛ اطلاعات همراه metadata منشأ، نقص و readOnly |
| 4 | `PUT inspections/{inspectionId}/information` | تازه؛ `expectedVersion` و فقط manual fields مجاز + confirmation؛ جانشین فرمان‌های موازی ویرایش خودرو |
| 5 | `POST inspections/{inspectionId}/consent` | I06؛ `accepted=true` و `termsVersion` معتبر؛ actor/time از سرور |
| 5 | `PUT inspections/{inspectionId}/location` | I07؛ مختصات/آدرس/جزئیات و نسخه؛ context مالک |
| 5 | `GET inspections/{inspectionId}/vehicle` | I08؛ projection فقط‌خواندنی Info برای adapter فعلی؛ کپی ذخیرهٔ خودرو ایجاد نمی‌کند |
| 5 | `PUT inspections/{inspectionId}/odometer` | I11؛ `kilometers` عدد صحیح + expectedVersion؛ evidenceId اختیاری و متعلق به همان بازدید |
| 5 | `GET inspections/{inspectionId}/capture-plan` | I05؛ template/policy پین‌شده، یازده الزام و ویدیو، alternativeها |
| 6 | `POST inspections/{inspectionId}/evidence` | EV01؛ kind/requirementId/alternativeId/revisionKey/size/MIME و نسخه؛ idempotent → UploadTicket |
| 6 | `PUT uploads/{uploadId}/content` | EV02؛ stream باینری، مجوز owner و upload nonce در header؛ فایل از JSON/Base64 نمی‌آید |
| 6 | `POST evidence/{evidenceId}/complete` | EV03؛ uploadId/version، کنترل فایل و durable receipt؛ idempotent |
| 6 | `GET inspections/{inspectionId}/evidence` | EV04؛ reconcile وضعیت نسخه‌ها و receipt؛ بدون path خصوصی |
| 6 | `GET inspections/{inspectionId}/evidence/{evidenceId}/file` | EV05؛ نسخه/variant مجاز؛ stream خصوصی با کنترل دسترسی و Range مصوب |
| 6 | `POST evidence/{evidenceId}/cancel-upload` | EV06؛ فقط upload فعال مجاز؛ مدرک تاریخی حذف نمی‌شود |
| 7 | `GET inspections/{inspectionId}/summary` | I12؛ readiness و missing items از سرور |
| 7 | `POST inspections/{inspectionId}/submit` | I13؛ expectedVersion و `Idempotency-Key`؛ snapshot اتمیک و Receipt |
| 7 | `GET inspections/{inspectionId}/status` | I14؛ lifecycle و projection امن مشتری؛ بدون یادداشت داخلی |
| 7 | `GET inspections/{inspectionId}/receipt` | تازه؛ بازیابی receipt پایدار پس از refresh یا گم‌شدن response |

همهٔ endpointهای evidence برای عکس و ویدیو مشترک‌اند؛ endpoint تکراری video صرفاً برای نام‌گذاری ساخته نمی‌شود. مرحلهٔ 4 حداقل inspection را برای ارتباط اجباری Info می‌سازد؛ مرحلهٔ 5 آن را با رضایت، موقعیت و capture plan تکمیل می‌کند.

مسیرهای I09/I10 یعنی PUT خودرو/پلاک مستقل در این پیشنهاد حذف و در PUT information ادغام‌اند؛ alias سازگاری تنها با وجود مصرف‌کنندهٔ واقعی و دورهٔ حذف مصوب افزوده می‌شود. گزارش مغایرت می‌تواند در همان فرمان confirmation، بدون تغییر trusted data ثبت شود؛ تصمیم نهایی شکل DTO قبل از Checkpoint 4 با Frontend است.

## نمونهٔ اطلاعات منشأدار

نمونه زیر صرفاً شکل DTO پیشنهادی است؛ نام و مقدار خودرو ساختگی‌اند. source و readOnly فقط خروجی سرورند.

```json
{
  "inspectionId": "test-inspection",
  "version": "AQIDBAUGBwg=",
  "fields": {
    "make": { "value": "سازنده آزمایشی", "source": "Brokerage", "status": "Valid", "readOnly": true },
    "model": { "value": null, "source": null, "status": "Missing", "readOnly": false }
  },
  "confirmed": false
}
```

PUT فقط فیلدهای مجاز دستی را دارد؛ نه کل object فوق و نه مقدار `source`. ارسال دوبارهٔ مقدار برابر trusted نیز فقط برای DTOی confirmation مصوب پذیرفته می‌شود؛ تغییر آن رد می‌شود. نیاز به اطلاعات ناقص، مدل `Vehicle` کاملاً پرِ Frontend را تغییر خواهد داد؛ نباید با placeholder پر شود.

## اصلاح DTOهای فعلی پیش از اتصال

| مرز | تعارض و اقدام لازم |
|---|---|
| `src/types/auth.ts` و `src/schemas/auth.ts` | mock، mobile را می‌فرستد و challengeId ندارد؛ adapter باید context/challenge را نگه دارد و mobile ورودی را حذف کند |
| `OtpRequest` مرجع | به context اشاره می‌کند، ولی ReferralResult آن context را تعریف نکرده؛ پاسخ resolution تکمیل شود |
| `Session` مرجع و mock | خروجی mock فقط verified/inspectionId است و schema مرجع source/permissions بیشتر دارد؛ خروجی مشتری حداقلی، بدون raw source/mobile غیرلازم تصویب شود |
| `Vehicle` مرجع/دامنه | `modelYear/color/bodyColor/maskedVin` به `year/colorName/colorHex/vinMasked` نگاشت می‌شوند؛ منشأ و nullability افزوده می‌شود |
| `VehicleRequest` مرجع | colorId و discrepancy ساختاری فعلی را کامل پوشش نمی‌دهد؛ فرمان information نسخه‌دار جایگزین می‌شود |
| مکان | schema قدیمی سقف‌های ۵۰۰/۴۰/۵۰۰ دارد، فرم جاری ۳۰۰/۲۰/۳۰۰؛ محدودیت مشترک پیش از اتصال تثبیت شود |
| وضعیت | lifecycle بزرگ `DRAFT...FORWARDED` با enum UI مثل `queuedForReview` یکی نیست؛ نگاشت صریح و آزمون fixture، نه تبدیل حروف |
| capture/upload | `spec-plate` با alternative مستقل و receipt نسخهٔ واقعی حفظ شود؛ localBlobKey وارد API یا مسیر فایل نشود |

## scopeهای مؤخر

AU01/AU02 (ticket مشتری/کارکنان) برای شروع لازم نیستند؛ ورود قطعی مشتری referral/OTP است. I04 فهرست فراگیر، R01–R04، I15، RV01–RV09، AD01–AD11 و FW01 در Checkpoint 8 یا پس از نیاز واقعی قرار می‌گیرند. P01 public settings و M01 reverse map به نیاز integration وابسته‌اند؛ provider برند و Neshan مرکزی موجود را با نسخهٔ تکراری جایگزین نکنید. P00 یعنی `/site-bootstrap.json` فایل عمومی Frontend موجود است و endpoint تجاری BAZDID نیست؛ منتقل یا بازتعریف نمی‌شود.

## OpenAPI و تحویل Frontend

Swashbuckle نامزد نسل 4، سند **Swagger 2.0** تولید می‌کند؛ compatibility به معنی اثبات OpenAPI 3 نیست. DTO واقعی، enum، nullability، نسخه، خطای فیلد، CSRF، cookie و `Idempotency-Key`، stream باینری و محدودیت‌ها باید در سند همان برنامه توضیح داده شوند. Swagger 2.0 توان مدل‌کردن کامل بعضی union/nullها را ندارد؛ توضیح و نمونهٔ مکمل معتبر لازم است، نه schema گمراه‌کننده.

در IIS مسیر JSON و UI نسبت به PathBase ساخته و در شبکهٔ مرورگر بررسی شوند؛ مقدار `/swagger/...` از root سایت hardcode نشود. محیط Production مستندات را فقط برای کارکنان مجاز یا شبکهٔ مدیریت نشان دهد. JSON برنامه‌نویسی‌شدهٔ جعلی در Phase 0 جای سند تولیدشده نمی‌نشیند.

بستهٔ تحویل هر milestone: URL واقعی HTTPS staging، UI/JSON همان نسخه، DTO و خطاها، fixture ساختگی، روش OTP تست محدود به محیط غیرتولیدی، روش کوکی/CSRF و CORS، مثال retry و نگاشت adapter، و نتیجهٔ تست اتصال. APIهای هنوز اجرا‌نشده در Swagger عملیاتی نمایش داده نشوند.
