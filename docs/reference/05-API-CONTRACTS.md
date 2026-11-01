# قراردادهای پیشنهادی API

وضعیت: **پیشنهادی و نیازمند تصویب Backend**. تاریخ بررسی منابع: 2026-10-27. این اسناد هیچ سرویس تولیدی یا migration اجراشده‌ای را اثبات نمی‌کنند.

این پیش‌نویس 55 ترکیب method/path پیشنهادی، یک فایل موجود bootstrap و سه مسئولیت سروری دارد. شمار نهایی تصویب نشده است؛ نام‌های مستعار سازگاری و روش شرطی تبادل بلیت کارکنان نیز در این شمار هستند. انتخاب OIDC می‌تواند قرارداد AU02 را با handler‌های استاندارد Backend جایگزین کند. هیچ مسیر این فصل از React فراخوانی واقعی نشده است.

## قرارداد مشترک

در مسیرهای زیر `/api` نماد پایه پیکربندی‌شده است. برای نصب دارای `/api/bazdid`، پسوند resource فقط یک‌بار به base اضافه می‌شود؛ `/api/api` تولید نشود. شناسه‌ها در UI رشته opaque هستند. کلیدهای داخلی SQL می‌توانند GUID باشند؛ PublicId و شناسه‌های خارجی با نگاشت سرور حل می‌شوند، نه cast دلخواه مرورگر. tenant از میزبان/نشست معتبر است، نه body/query. زمان‌ها UTC با ISO8601، اعداد دامنه ASCII و شناسه‌های فنی LTR هستند.

تمام پاسخ‌های حساس و تنظیمات mutable از `Cache-Control: no-store` استفاده می‌کنند. پاسخ منابع نسخه‌دار ETag/نسخه opaque دارد. برای فرمان اثرگذار، Idempotency-Key در scope نصب + عامل + عملیات + منبع ذخیره و hash بدنه بررسی می‌شود؛ replay همان نتیجه، payload متفاوت 409. expectedVersion/If-Match در تراکنش کنترل می‌شود؛ در صورت اختلاف header/body درخواست 400 است. درخواست بدون precondition لازم 428؛ نسخه کهنه 409؛ precondition If-Match نامعتبر طبق پروتکل مصوب 412. بازخوانی و تأیید کاربر پس از conflict لازم است. حالت in-flight همان کلید، 202 با Location بازیابی و Retry-After دارد و نباید به صورت موفقیت نهایی تفسیر شود.

بازیابی نتیجه idempotency پس از احراز مجدد مجوز و پیش از رد نسخه کهنه انجام شود؛ retry پاسخ موفق گم‌شده با همان کلید و بدنه نباید به conflict نسخه تبدیل شود. Idempotency conflict به معنی اختلاف hash بدنه است؛ با عوض‌کردن کورکورانه کلید از آن عبور نکنید. پس از VERSION_CONFLICT قطعی که هیچ اثری ثبت نکرده، بازخوانی/تأیید و بدنه تازه با expectedVersion جدید، فرمان و کلید جدید می‌خواهد؛ شناسه منطقی job/revision ثابت می‌ماند تا مدرک تکراری ساخته نشود.

مرجع نسخه هر فرمان مشخص باشد: حقایق/submit/new-attempt روی aggregate بازدید؛ قالب/تنظیمات روی workspace مربوط؛ تصمیم/ارجاع کارشناس روی case؛ اصلاحات روی requestVersion به همراه نسخه دقیق مدرک/پرونده. ثبت/تکمیل رسانه نسخه همان جایگاه یا upload session را کنترل کند و عضویت/قفل بازدید در همان تراکنش بازبینی شود. دو انتقال باینری هم‌زمان مجازند؛ هر chunk یا پیشرفت byte نباید نسخه کل بازدید را تغییر دهد. فرمان‌های metadata کوتاه می‌توانند نیازمند بازخوانی نسخه باشند؛ این granularity پیشنهادی باید در D04 تصویب شود.

JSON schema‌های [schemas.json](contracts/schemas.json) با Draft7 پیشنهاد شده‌اند، نه OpenAPI تصویب‌شده. $defs و allOf قرارداد ساختاری را مشخص می‌کنند؛ مالکیت، ظرفیت، پین قالب، انتخاب VIN، نوع واقعی فایل، انتقال وضعیت و آمادگی باید دوباره در سرویس enforce شوند. مثال‌ها در [examples.json](contracts/examples.json) ساختگی‌اند؛ دامنه invalid، بلیت و هش صفر اعتبار عملیاتی ندارند. باینری در JSON ارسال نمی‌شود.

خطاهای مشترک در [فصل ۱۷](17-ERRORS-AND-HTTP-STATUS-CODES.md) از Problem پیروی می‌کنند؛ فیلدها قابل اتصال به ورودی UI هستند. schema پاسخ هر endpoint را در `$defs` ببینید. برای auth error از redirect HTML به صفحه ورود در پاسخ API استفاده نشود. در GET بدنه JSON وجود ندارد؛ query/path/header زیر قرارداد ورودی است. پاسخ null تلاش جاری با 200 به معنی نداشتن تلاش است، نه اجازه ایجاد خودکار.

برای upload/replacement نسخه‌ها مستقل‌اند: اصل خوب تا موفقیت محفوظ است. Candidate ثبت‌شده شمار اعتبار اصل را پاک نمی‌کند؛ ولی اگر جایگزین تأییدشده کاربر به عنوان نسخه هدف انتخاب شده، submission باید receipt همان نسخه را مطالبه کند. اصلاحات درخواست کارشناس تنها با resubmit اتمیک و receipt نسخه‌های مجاز promote می‌شوند؛ پاسخ دیررس یا job قدیمی مجاز به جابه‌جایی pointer نیست.

## نمای منابع

| شناسه | روش و مسیر | عملیات | نوع |
|---|---|---|---|
| P00 | GET /site-bootstrap.json | A01 | فایل موجود عمومی |
| P01 | GET /api/public/site-settings | A02, F05 | پیشنهادی |
| AU01 | POST /api/auth/customer-handoff | A03 | پیشنهادی |
| AU02 | POST /api/auth/staff/exchange | A04 | پیشنهادی |
| AU03 | GET /api/me | A05 | پیشنهادی |
| AU04 | POST /api/auth/logout | A06 | پیشنهادی |
| AU05 | POST /api/referrals/validate | A07 | پیشنهادی |
| AU06 | POST /api/auth/otp/request | A08 | پیشنهادی |
| AU07 | POST /api/auth/otp/verify | A09 | پیشنهادی |
| I01 | POST /api/inspections | B01 | پیشنهادی |
| I02 | GET /api/inspections/{inspectionId} | B02 | پیشنهادی |
| I03 | GET /api/inspections/current | B03 | پیشنهادی |
| I04 | GET /api/inspections | B04, E01 | پیشنهادی |
| I05 | GET /api/inspections/{inspectionId}/capture-plan | B05 | پیشنهادی |
| I06 | POST /api/inspections/{inspectionId}/consent | B06 | پیشنهادی |
| I07 | PUT /api/inspections/{inspectionId}/location | B07 | پیشنهادی |
| I08 | GET /api/inspections/{inspectionId}/vehicle | B08 | پیشنهادی |
| I09 | PUT /api/inspections/{inspectionId}/vehicle | B09 | پیشنهادی |
| I10 | PUT /api/inspections/{inspectionId}/vehicle/plate | B09 | پیشنهادی |
| I11 | PUT /api/inspections/{inspectionId}/odometer | B10 | پیشنهادی |
| M01 | GET /api/maps/reverse | B11 | پیشنهادی |
| EV01 | POST /api/inspections/{inspectionId}/evidence | C01, D06 | پیشنهادی |
| EV02 | PUT /api/uploads/{uploadId}/content | C02 | پیشنهادی |
| EV03 | POST /api/evidence/{evidenceId}/complete | C03, D06 | پیشنهادی |
| EV04 | GET /api/inspections/{inspectionId}/evidence | C04, C05 | پیشنهادی |
| EV05 | GET /api/inspections/{inspectionId}/evidence/{evidenceId}/file | C06 | پیشنهادی |
| EV06 | POST /api/evidence/{evidenceId}/cancel-upload | C07 | پیشنهادی |
| I12 | GET /api/inspections/{inspectionId}/summary | D01, B10 | پیشنهادی |
| I13 | POST /api/inspections/{inspectionId}/submit | D02, D03 | پیشنهادی |
| I14 | GET /api/inspections/{inspectionId}/status | D04, G05 | پیشنهادی |
| R01 | GET /api/inspections/{inspectionId}/evidence-requests | D05 | پیشنهادی |
| R02 | POST /api/evidence-requests/{requestId}/replacement | D06 | پیشنهادی |
| R03 | POST /api/inspections/{inspectionId}/resubmit | D07 | پیشنهادی |
| R04 | PUT /api/inspections/{inspectionId}/field-corrections/{taskId} | D08 | پیشنهادی |
| I15 | POST /api/inspections/{inspectionId}/attempts | D09 | پیشنهادی |
| RV01 | GET /api/reviewer/cases/{caseId} | E02 | پیشنهادی |
| RV02 | POST /api/admin/inspections/{inspectionId}/assignment | E03 | پیشنهادی |
| RV03 | PUT /api/admin/reviewer-policy | E04 | پیشنهادی |
| RV04 | POST /api/reviewer/cases/{caseId}/evidence-decisions | E05 | پیشنهادی |
| RV05 | POST /api/reviewer/cases/{caseId}/field-corrections | E06 | پیشنهادی |
| RV06 | POST /api/reviewer/field-corrections/{taskId}/decision | E07 | پیشنهادی |
| RV07 | POST /api/reviewer/cases/{caseId}/notes | E08 | پیشنهادی |
| RV08 | POST /api/reviewer/cases/{caseId}/decision | E09 | پیشنهادی |
| RV09 | GET /api/reviewer/cases/{caseId}/history | E10 | پیشنهادی |
| AD01 | GET /api/admin/workspace | F01, F10, E04 | پیشنهادی |
| AD02 | POST /api/admin/capture-templates | F02 | پیشنهادی |
| AD03 | PUT /api/admin/capture-templates/{templateId}/versions/{version}/draft | F03 | پیشنهادی |
| AD04 | POST /api/admin/capture-templates/{templateId}/versions/{version}/publication | F04 | پیشنهادی |
| AD05 | GET /api/admin/site-settings | F06 | پیشنهادی |
| AD06 | PUT /api/admin/site-settings/draft | F06, F09 | پیشنهادی |
| AD07 | POST /api/admin/site-settings/publish | F07 | پیشنهادی |
| AD08 | POST /api/admin/branding-assets | F08 | پیشنهادی |
| AD09 | PUT /api/admin/staff/{staffId}/roles | F10 | پیشنهادی |
| AD10 | PUT /api/admin/webhooks/{webhookId} | F11 | پیشنهادی |
| AD11 | GET /api/admin/system/health | F12 | پیشنهادی |
| FW01 | POST /api/admin/forwarding-jobs/{jobId}/retry | G04 | پیشنهادی |

## P00 — فایل عمومی هویت نصب

**فایل عمومی موجود؛ سرویس Backend نیست** — `GET /site-bootstrap.json`

| موضوع | قرارداد |
|---|---|
| عملیات | A01 |
| نقش | عمومی نصب |
| احراز هویت | بدون نشست؛ فقط داده عمومی مجاز نصب |
| ورودی مسیر | ندارد |
| query | ندارد |
| سرآیند | Accept: application/json |
| بدنه | ندارد |
| خروجی | Bootstrap؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 404, 503 |
| اعتبارسنجی | ساختار SiteBootstrap، origin مجاز و URL عمومی معتبر؛ فایل هیچ کلید خصوصی، session یا هویت مشتری ندارد. |
| تکرار امن | بدون اثر تجاری؛ تکرار خواندن امن است، حساس‌ها no-store و بدون cache عمومی |
| هم‌زمانی | خواندن ETag/version؛ GET هیچ بازدید یا تصمیمی ایجاد نمی‌کند |
| SQL | فایل استقرار/ارائه‌دهنده بیرونی؛ SQL خصوصی جدید نمی‌خواهد |
| خواندن جدول | ندارد |
| نوشتن جدول | ندارد |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D01, D02 |
| آداپتور فعلی | src/config/site-settings.loader.ts |
| وابستگی | توافق هویت/نصب و قرارداد عمومی |

### پاسخ P00

```json
{
  "schemaVersion": 1,
  "tenantId": "demo",
  "apiBaseUrl": "/api/bazdid",
  "siteSettingsEndpoint": "/api/bazdid/public/site-settings",
  "settingsSource": "api"
}
```

### نمونه خطای P00

```json
{
  "type": "urn:inspection:problem:NOT_FOUND",
  "title": "منبع مجاز پیدا نشد.",
  "status": 404,
  "code": "NOT_FOUND",
  "traceId": "trace-example",
  "errors": {}
}
```

## P01 — تنظیمات عمومی منتشرشده

**پیشنهادی؛ تصویب نشده** — `GET /api/public/site-settings`

| موضوع | قرارداد |
|---|---|
| عملیات | A02, F05 |
| نقش | عمومی نصب |
| احراز هویت | بدون نشست؛ فقط داده عمومی مجاز نصب |
| ورودی مسیر | ندارد |
| query | ندارد |
| سرآیند | Accept: application/json |
| بدنه | ندارد |
| خروجی | PublicSettings؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 404, 503 |
| اعتبارسنجی | schemaVersion و tenant نصب و نسخه انتشار معتبر؛ projection فقط عمومی است و secret سرویس یا مسیر خصوصی ندارد.؛ همان projection عمومی A02؛ هیچ store یا endpoint رقیب برای برند ساخته نشود. |
| تکرار امن | بدون اثر تجاری؛ تکرار خواندن امن است، حساس‌ها no-store و بدون cache عمومی |
| هم‌زمانی | خواندن ETag/version؛ GET هیچ بازدید یا تصمیمی ایجاد نمی‌کند |
| SQL | BrandingAssets, SiteSettings, SiteSettingsAssetLinks, SiteSettingsVersions |
| خواندن جدول | BrandingAssets, SiteSettings, SiteSettingsAssetLinks, SiteSettingsVersions |
| نوشتن جدول | ندارد |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه.؛ ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D01, D02, D04, D08 |
| آداپتور فعلی | src/config/site-settings.loader.ts |
| وابستگی | توافق هویت/نصب و قرارداد عمومی؛ A04/A05؛ مجوز و CAS تنظیمات/قالب |

### پاسخ P01

```json
{
  "schemaVersion": 1,
  "tenantId": "demo",
  "version": 2,
  "publishedAt": "2026-10-26T09:00:00Z",
  "identity": {
    "brokerageName": "کارگزاری نمونه",
    "appTitle": "بازدید خودرو",
    "logo": null,
    "favicon": null,
    "publicEmail": "support@example.invalid",
    "publicPhone": "نمونه قراردادی"
  },
  "theme": {
    "primary": "#047857",
    "secondary": "#475569",
    "background": "#FFFFFF",
    "neutral": "#64748B",
    "onPrimary": "#FFFFFF",
    "onBackground": "#0F172A",
    "accent": "#F59E0B",
    "haloColor": "#10B981",
    "haloIntensity": 35
  },
  "images": {
    "landing": null,
    "referral": null,
    "otp": null,
    "readiness": null,
    "consent": null,
    "submission": null
  },
  "application": {
    "apiBaseUrl": "/api/bazdid",
    "contractVersion": "1",
    "template": {
      "id": "body-image-guided",
      "version": 2
    },
    "features": {
      "nativeCaptureFallback": true,
      "additionalEvidence": true,
      "supportLink": false
    },
    "locationMap": {
      "enabled": true,
      "webMapKey": null,
      "mapType": "dreamy",
      "reverseGeocoding": "api",
      "initialViewport": {
        "latitude": 35.699739,
        "longitude": 51.338097,
        "zoom": 12
      }
    }
  }
}
```

### نمونه خطای P01

```json
{
  "type": "urn:inspection:problem:NOT_FOUND",
  "title": "منبع مجاز پیدا نشد.",
  "status": 404,
  "code": "NOT_FOUND",
  "traceId": "trace-example",
  "errors": {}
}
```

## AU01 — تبادل بلیت مشتری مبدأ

**پیشنهادی؛ تصویب نشده** — `POST /api/auth/customer-handoff`

| موضوع | قرارداد |
|---|---|
| عملیات | A03 |
| نقش | زمینه معتبر مبدأ |
| احراز هویت | بلیت معتبر مبدأ و ضد replay؛ روش نهایی نیازمند تصویب |
| ورودی مسیر | ندارد |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema TicketRequest |
| خروجی | Session؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503 |
| اعتبارسنجی | issuer، audience، expiry، state/nonce و اتصال subject به sourceRequest؛ مصرف اتمیک بلیت یک‌بارمصرف و رد replay. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | بلیت/nonce یک‌بار به‌صورت اتمیک مصرف شود؛ بازیابی همان تحویل پس از پاسخ گم‌شده باید امن باشد. این فرمان expectedVersion بازدید ندارد؛ TTL و پروتکل بازیابی در قرارداد هویت تصویب شود. |
| SQL | AuditLogs, Customers, IdempotencyRecords, SourceInsuranceRequests |
| خواندن جدول | Customers, IdempotencyRecords, SourceInsuranceRequests |
| نوشتن جدول | AuditLogs, Customers, IdempotencyRecords, SourceInsuranceRequests |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D01, D02 |
| آداپتور فعلی | src/features/identity/source-context.ts |
| وابستگی | توافق هویت/نصب و قرارداد عمومی |

### ساختار درخواست AU01

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| ticket | string | بله | {"minLength":16,"maxLength":2048} |
| state | string | بله | {"minLength":16,"maxLength":256} |
| returnPath | string | بله | {"pattern":"^/(?!/)"} |

### مثال درخواست AU01

```json
{
  "ticket": "FICTIONAL_ONE_USE_TICKET_NOT_A_CREDENTIAL",
  "state": "FICTIONAL_STATE_FOR_REVIEW_ONLY",
  "returnPath": "/readiness"
}
```

### پاسخ AU01

```json
{
  "state": "authenticated",
  "kind": "customer",
  "expiresAt": "2026-10-26T09:00:00Z",
  "source": {
    "tenantId": "demo",
    "subjectId": "customer-fixture",
    "sourceRequestId": "REQ-DEMO-001",
    "mobile": "09120000000",
    "authority": "brokerage-session"
  }
}
```

### نمونه خطای AU01

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## AU02 — تبادل بلیت کارکنان؛ مشروط به انتخاب این روش SSO

**پیشنهادی؛ تصویب نشده** — `POST /api/auth/staff/exchange`

| موضوع | قرارداد |
|---|---|
| عملیات | A04 |
| نقش | تحویل سازمانی معتبر |
| احراز هویت | بلیت معتبر مبدأ و ضد replay؛ روش نهایی نیازمند تصویب |
| ورودی مسیر | ندارد |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema TicketRequest |
| خروجی | Session؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503 |
| اعتبارسنجی | پروتکل SSO مصوب، issuer/audience/callback/PKCE یا بلیت محدود؛ نگاشت subject به نقش فعال از مرجع trusted. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | بلیت/nonce یک‌بار به‌صورت اتمیک مصرف شود؛ بازیابی همان تحویل پس از پاسخ گم‌شده باید امن باشد. این فرمان expectedVersion بازدید ندارد؛ TTL و پروتکل بازیابی در قرارداد هویت تصویب شود. |
| SQL | AuditLogs, IdempotencyRecords, StaffRoleAssignments, StaffUsers |
| خواندن جدول | IdempotencyRecords, StaffRoleAssignments, StaffUsers |
| نوشتن جدول | AuditLogs, IdempotencyRecords, StaffRoleAssignments, StaffUsers |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D01, D02 |
| آداپتور فعلی | src/features/identity/staff-session.ts |
| وابستگی | توافق هویت/نصب و قرارداد عمومی |

### ساختار درخواست AU02

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| ticket | string | بله | {"minLength":16,"maxLength":2048} |
| state | string | بله | {"minLength":16,"maxLength":256} |
| returnPath | string | بله | {"pattern":"^/(?!/)"} |

### مثال درخواست AU02

```json
{
  "ticket": "FICTIONAL_ONE_USE_TICKET_NOT_A_CREDENTIAL",
  "state": "FICTIONAL_STATE_FOR_REVIEW_ONLY",
  "returnPath": "/readiness"
}
```

### پاسخ AU02

```json
{
  "state": "authenticated",
  "kind": "staff",
  "role": "reviewer",
  "permissions": [
    "inspections:read",
    "evidence:decide",
    "inspection:decide"
  ],
  "tenantId": "brokerage-example",
  "subjectId": "staff-example",
  "authority": "backend-session",
  "expiresAt": "2026-10-26T09:00:00Z"
}
```

### نمونه خطای AU02

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## AU03 — وضعیت نشست

**پیشنهادی؛ تصویب نشده** — `GET /api/me`

| موضوع | قرارداد |
|---|---|
| عملیات | A05 |
| نقش | نشست معتبر مشتری/کارکنان |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | ندارد |
| query | ندارد |
| سرآیند | Accept: application/json |
| بدنه | ندارد |
| خروجی | Session؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503 |
| اعتبارسنجی | اعتبار نشست سرور، expiry/revocation و scope نصب؛ بازگردانی sessionStorage mock مدرک احراز هویت تولیدی نیست. |
| تکرار امن | بدون اثر تجاری؛ تکرار خواندن امن است، حساس‌ها no-store و بدون cache عمومی |
| هم‌زمانی | خواندن ETag/version؛ GET هیچ بازدید یا تصمیمی ایجاد نمی‌کند |
| SQL | Customers, SourceInsuranceRequests, StaffRoleAssignments, StaffUsers |
| خواندن جدول | Customers, SourceInsuranceRequests, StaffRoleAssignments, StaffUsers |
| نوشتن جدول | ندارد |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D01, D02 |
| آداپتور فعلی | src/features/identity/source-context.ts |
| وابستگی | توافق هویت/نصب و قرارداد عمومی |

### پاسخ AU03

```json
{
  "state": "authenticated",
  "kind": "customer",
  "expiresAt": "2026-10-26T09:00:00Z",
  "source": {
    "tenantId": "demo",
    "subjectId": "customer-fixture",
    "sourceRequestId": "REQ-DEMO-001",
    "mobile": "09120000000",
    "authority": "brokerage-session"
  }
}
```

### نمونه خطای AU03

```json
{
  "type": "urn:inspection:problem:NOT_FOUND",
  "title": "منبع مجاز پیدا نشد.",
  "status": 404,
  "code": "NOT_FOUND",
  "traceId": "trace-example",
  "errors": {}
}
```

## AU04 — ابطال نشست

**پیشنهادی؛ تصویب نشده** — `POST /api/auth/logout`

| موضوع | قرارداد |
|---|---|
| عملیات | A06 |
| نقش | نشست معتبر مشتری/کارکنان |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | ندارد |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست |
| بدنه | application/json؛ schema Empty |
| خروجی | Acknowledgement؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503 |
| اعتبارسنجی | نشست معتبر و ضد CSRF؛ ابطال سرور و cookie؛ logout سراسری مبدأ فقط طبق توافق. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | ابطال نشست با logout موازی امن باشد؛ logout تکراری اثر اضافه ندارد و نسخه بازدید لازم نیست. |
| SQL | AuditLogs |
| خواندن جدول | ندارد |
| نوشتن جدول | ندارد |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D01, D02 |
| آداپتور فعلی | src/features/identity/staff-session.ts |
| وابستگی | توافق هویت/نصب و قرارداد عمومی |

### ساختار درخواست AU04

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|

### مثال درخواست AU04

```json
{}
```

### پاسخ AU04

```json
{
  "acknowledged": true,
  "version": "AAAAAAAAB9E=",
  "at": "2026-10-26T09:00:00Z"
}
```

### نمونه خطای AU04

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## AU05 — اعتبار معرفی‌نامه در زمینه مبدأ

**پیشنهادی؛ تصویب نشده** — `POST /api/referrals/validate`

| موضوع | قرارداد |
|---|---|
| عملیات | A07 |
| نقش | زمینه معتبر مبدأ |
| احراز هویت | بلیت معتبر مبدأ و ضد replay؛ روش نهایی نیازمند تصویب |
| ورودی مسیر | ندارد |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema ReferralRequest |
| خروجی | ReferralResult؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503 |
| اعتبارسنجی | معرفی‌نامه معتبر، انقضا و اتصال به درخواست و شماره trusted؛ پاسخ نباید شماره دیگران را افشا کند. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | اعتبارسنجی خواندنی است و تلاش بازدید نمی‌سازد؛ rate limit از scope trusted مشتق شود، بدون CAS بازدید. |
| SQL | Customers, SourceInsuranceRequests |
| خواندن جدول | Customers, SourceInsuranceRequests |
| نوشتن جدول | ندارد |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D01, D02 |
| آداپتور فعلی | src/lib/api/repositories.ts |
| وابستگی | توافق هویت/نصب و قرارداد عمومی |

### ساختار درخواست AU05

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| code | string | بله | {"minLength":1,"maxLength":80} |

### مثال درخواست AU05

```json
{
  "code": "48216"
}
```

### پاسخ AU05

```json
{
  "valid": true
}
```

### نمونه خطای AU05

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## AU06 — صدور یا ارسال دوباره چالش OTP

**پیشنهادی؛ تصویب نشده** — `POST /api/auth/otp/request`

| موضوع | قرارداد |
|---|---|
| عملیات | A08 |
| نقش | زمینه معتبر مبدأ |
| احراز هویت | بلیت معتبر مبدأ و ضد replay؛ روش نهایی نیازمند تصویب |
| ورودی مسیر | ندارد |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema OtpRequest |
| خروجی | OtpChallenge؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503 |
| اعتبارسنجی | همان شماره فقط‌خواندنی منبع، challenge/sourceRequest، cooldown و rate limit؛ هیچ شماره قابل‌ویرایش هویت نمی‌سازد. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | نسخه/expiry/سقف تلاش و مصرف challenge در سرور اتمیک کنترل شود؛ expectedVersion بازدید در این مرحله کاربرد ندارد. |
| SQL | Customers, SourceInsuranceRequests |
| خواندن جدول | Customers, SourceInsuranceRequests |
| نوشتن جدول | ندارد |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D01, D02 |
| آداپتور فعلی | src/lib/api/repositories.ts |
| وابستگی | توافق هویت/نصب و قرارداد عمومی |

### ساختار درخواست AU06

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| referralCode | string | بله | {"minLength":1,"maxLength":80} |
| challengeContextId | string | بله | {"minLength":1,"maxLength":160} |

### مثال درخواست AU06

```json
{
  "referralCode": "A4K9P2",
  "challengeContextId": "source-context-fixture"
}
```

### پاسخ AU06

```json
{
  "challengeId": "11111111-1111-4111-8111-111111111111",
  "expiresAt": "2026-10-26T09:00:00Z",
  "retryAfterSeconds": 1,
  "remainingAttempts": 1,
  "codeLength": 5
}
```

### نمونه خطای AU06

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## AU07 — تأیید چالش و صدور نشست محدود

**پیشنهادی؛ تصویب نشده** — `POST /api/auth/otp/verify`

| موضوع | قرارداد |
|---|---|
| عملیات | A09 |
| نقش | زمینه معتبر مبدأ |
| احراز هویت | بلیت معتبر مبدأ و ضد replay؛ روش نهایی نیازمند تصویب |
| ورودی مسیر | ندارد |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema OtpVerification |
| خروجی | Session؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503 |
| اعتبارسنجی | challenge فعال، کد با طول مصوب، expiry و سقف تلاش؛ مصرف اتمیک؛ کد پنج‌رقمی mock قاعده تولیدی نیست. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | نسخه/expiry/سقف تلاش و مصرف challenge در سرور اتمیک کنترل شود؛ expectedVersion بازدید در این مرحله کاربرد ندارد. |
| SQL | AuditLogs, Customers, IdempotencyRecords, SourceInsuranceRequests |
| خواندن جدول | Customers, SourceInsuranceRequests |
| نوشتن جدول | ندارد |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D01, D02 |
| آداپتور فعلی | src/lib/api/repositories.ts |
| وابستگی | توافق هویت/نصب و قرارداد عمومی |

### ساختار درخواست AU07

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| challengeId | string | بله | {"minLength":1,"maxLength":160} |
| code | string | بله | {"pattern":"^[0-9]{5}$"} |

### مثال درخواست AU07

```json
{
  "challengeId": "11111111-1111-4111-8111-111111111111",
  "code": "48216"
}
```

### پاسخ AU07

```json
{
  "state": "authenticated",
  "kind": "customer",
  "expiresAt": "2026-10-26T09:00:00Z",
  "source": {
    "tenantId": "demo",
    "subjectId": "customer-fixture",
    "sourceRequestId": "REQ-DEMO-001",
    "mobile": "09120000000",
    "authority": "brokerage-session"
  }
}
```

### نمونه خطای AU07

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## I01 — ایجاد بازدید و تثبیت نسخه قالب

**پیشنهادی؛ تصویب نشده** — `POST /api/inspections`

| موضوع | قرارداد |
|---|---|
| عملیات | B01 |
| نقش | مشتری مالک |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | ندارد |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema CreateInspection |
| خروجی | Inspection؛ تعریف دقیق در schemas.json |
| کد موفقیت | 201, 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503 |
| اعتبارسنجی | مالکیت درخواست مبدأ و قالب منتشرشده؛ عدم ایجاد current دوم؛ کلید ثابت و شماره attempt در تراکنش. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | expectedVersion یا If-Match باید با نسخه سرور تطبیق کند؛ transition و idempotency و audit در یک تراکنش SQL؛ بایت فایل تراکنش SQL نیست |
| SQL | AuditLogs, IdempotencyRecords, InspectionTemplates, Inspections, SourceInsuranceRequests, Vehicles |
| خواندن جدول | IdempotencyRecords, InspectionTemplates, Inspections, SourceInsuranceRequests, Vehicles |
| نوشتن جدول | AuditLogs, IdempotencyRecords, Inspections, Vehicles |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/inspection-status/lifecycle-repository.ts |
| وابستگی | A03/A05؛ قالب منتشرشده و مالکیت درخواست |

### ساختار درخواست I01

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| sourceRequestId | string | بله | {"minLength":1,"maxLength":160} |

### مثال درخواست I01

```json
{
  "sourceRequestId": "REQ-DEMO-001"
}
```

### پاسخ I01

```json
{
  "inspectionId": "insp_contract_001",
  "sourceRequestId": "REQ-DEMO-001",
  "trackingCode": "BDI-8F31K2",
  "status": "DRAFT",
  "templateId": "body-image-guided",
  "templateVersion": 2,
  "photoPolicyVersion": 2,
  "version": "AAAAAAAAB9E="
}
```

### نمونه خطای I01

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## I02 — دریافت حقایق بازدید

**پیشنهادی؛ تصویب نشده** — `GET /api/inspections/{inspectionId}`

| موضوع | قرارداد |
|---|---|
| عملیات | B02 |
| نقش | مالک یا کارکنان مجاز؛ projection جدا |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | inspectionId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | ندارد |
| سرآیند | Accept: application/json |
| بدنه | ندارد |
| خروجی | Inspection؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503 |
| اعتبارسنجی | شناسه opaque و اتصال مالک یا اختیار کارکنان؛ نسخه قالب و حقایق همان تلاش، نه رکورد ساختگی جدید. |
| تکرار امن | بدون اثر تجاری؛ تکرار خواندن امن است، حساس‌ها no-store و بدون cache عمومی |
| هم‌زمانی | خواندن ETag/version؛ GET هیچ بازدید یا تصمیمی ایجاد نمی‌کند |
| SQL | InspectionLocations, Inspections, Vehicles |
| خواندن جدول | InspectionLocations, Inspections, Vehicles |
| نوشتن جدول | ندارد |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/lib/api/repositories.ts |
| وابستگی | A03/A05؛ قالب منتشرشده و مالکیت درخواست |

### پاسخ I02

```json
{
  "inspectionId": "insp_contract_001",
  "sourceRequestId": "REQ-DEMO-001",
  "trackingCode": "BDI-8F31K2",
  "status": "DRAFT",
  "templateId": "body-image-guided",
  "templateVersion": 2,
  "photoPolicyVersion": 2,
  "version": "AAAAAAAAB9E="
}
```

### نمونه خطای I02

```json
{
  "type": "urn:inspection:problem:NOT_FOUND",
  "title": "منبع مجاز پیدا نشد.",
  "status": 404,
  "code": "NOT_FOUND",
  "traceId": "trace-example",
  "errors": {}
}
```

## I03 — تلاش جاری درخواست بیمه

**پیشنهادی؛ تصویب نشده** — `GET /api/inspections/current`

| موضوع | قرارداد |
|---|---|
| عملیات | B03 |
| نقش | مشتری مالک |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | ندارد |
| query | sourceRequestId: string؛ باید متعلق به زمینه معتبر نشست باشد |
| سرآیند | Accept: application/json |
| بدنه | ندارد |
| خروجی | InspectionOrNone؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503 |
| اعتبارسنجی | sourceRequest متعلق به subject نشست؛ پاسخ nullable برای نبود current؛ GET اجازه ساخت تلاش ندارد. |
| تکرار امن | بدون اثر تجاری؛ تکرار خواندن امن است، حساس‌ها no-store و بدون cache عمومی |
| هم‌زمانی | خواندن ETag/version؛ GET هیچ بازدید یا تصمیمی ایجاد نمی‌کند |
| SQL | Inspections, SourceInsuranceRequests |
| خواندن جدول | Inspections, SourceInsuranceRequests |
| نوشتن جدول | ندارد |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/inspection-status/customer-entry.tsx |
| وابستگی | A03/A05؛ قالب منتشرشده و مالکیت درخواست |

### پاسخ I03

```json
{
  "inspectionId": "insp_contract_001",
  "sourceRequestId": "REQ-DEMO-001",
  "trackingCode": "BDI-8F31K2",
  "status": "DRAFT",
  "templateId": "body-image-guided",
  "templateVersion": 2,
  "photoPolicyVersion": 2,
  "version": "AAAAAAAAB9E="
}
```

### نمونه خطای I03

```json
{
  "type": "urn:inspection:problem:NOT_FOUND",
  "title": "منبع مجاز پیدا نشد.",
  "status": 404,
  "code": "NOT_FOUND",
  "traceId": "trace-example",
  "errors": {}
}
```

## I04 — پیگیری مالک یا صف و جست‌وجوی مجاز کارکنان

**پیشنهادی؛ تصویب نشده** — `GET /api/inspections`

| موضوع | قرارداد |
|---|---|
| عملیات | B04, E01 |
| نقش | مالک یا کارکنان مجاز؛ projection جدا |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | ندارد |
| query | cursor: string اختیاری، opaque و scope-bound؛ pageSize: integer از 1 تا 100؛ پیش‌فرض 20؛ sort: whitelist، ترتیب پایدار با شناسه نهایی؛ trackingCode: string اختیاری؛ مجوز از نشست، نه کد؛ status: InspectionLifecycle اختیاری؛ q: string حداکثر 100، بدون اطلاعات خصوصی در log |
| سرآیند | Accept: application/json |
| بدنه | ندارد |
| خروجی | InspectionPage؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503 |
| اعتبارسنجی | scope مشتری یا permission کارکنان، cursor و pageSize محدود؛ trackingCode به تنهایی مجوز نیست.؛ فیلتر، cursor و scope کارکنان؛ آمار از query واقعی، نه مقدار نمایشی ثابت؛ حد pageSize. |
| تکرار امن | بدون اثر تجاری؛ تکرار خواندن امن است، حساس‌ها no-store و بدون cache عمومی |
| هم‌زمانی | خواندن ETag/version؛ GET هیچ بازدید یا تصمیمی ایجاد نمی‌کند |
| SQL | Customers, Inspections, ReviewerAssignments, SourceInsuranceRequests, StaffUsers |
| خواندن جدول | Customers, Inspections, SourceInsuranceRequests, ReviewerAssignments, StaffUsers |
| نوشتن جدول | ندارد |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه.؛ ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/review-operations/model.ts؛ src/features/review-operations/repository.ts |
| وابستگی | A03/A05؛ قالب منتشرشده و مالکیت درخواست؛ A04/A05، D02؛ ارجاع و نسخه پرونده |

### پاسخ I04

```json
{
  "items": [
    {
      "inspectionId": "insp_contract_001",
      "sourceRequestId": "REQ-DEMO-001",
      "trackingCode": "BDI-8F31K2",
      "status": "DRAFT",
      "templateId": "body-image-guided",
      "templateVersion": 2,
      "photoPolicyVersion": 2,
      "version": "AAAAAAAAB9E="
    }
  ],
  "nextCursor": null,
  "total": 1
}
```

### نمونه خطای I04

```json
{
  "type": "urn:inspection:problem:NOT_FOUND",
  "title": "منبع مجاز پیدا نشد.",
  "status": 404,
  "code": "NOT_FOUND",
  "traceId": "trace-example",
  "errors": {}
}
```

## I05 — قالب ثابت همان بازدید

**پیشنهادی؛ تصویب نشده** — `GET /api/inspections/{inspectionId}/capture-plan`

| موضوع | قرارداد |
|---|---|
| عملیات | B05 |
| نقش | مالک یا کارکنان مجاز؛ projection جدا |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | inspectionId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | ندارد |
| سرآیند | Accept: application/json |
| بدنه | ندارد |
| خروجی | CapturePlan؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503 |
| اعتبارسنجی | قالب immutable پین‌شده همین تلاش؛ requirementId‌های یکتا و گزینه‌های همان نسخه؛ نسخه قدیمی بازنویسی نشود. |
| تکرار امن | بدون اثر تجاری؛ تکرار خواندن امن است، حساس‌ها no-store و بدون cache عمومی |
| هم‌زمانی | خواندن ETag/version؛ GET هیچ بازدید یا تصمیمی ایجاد نمی‌کند |
| SQL | EvidenceRequirements, InspectionTemplates, RequirementAlternatives |
| خواندن جدول | EvidenceRequirements, InspectionTemplates, RequirementAlternatives |
| نوشتن جدول | ندارد |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/lib/api/repositories.ts |
| وابستگی | A03/A05؛ قالب منتشرشده و مالکیت درخواست |

### پاسخ I05

```json
{
  "photoPolicyVersion": 2,
  "templateId": "body-image-guided",
  "templateVersion": 2,
  "sections": [
    {
      "id": "right",
      "title": "نمای راست",
      "order": 1,
      "photoRequirements": [
        {
          "id": "front-45-right",
          "title": "جلو ۴۵° راست",
          "description": "جلوی خودرو و سمت راست به صورت کامل دیده شود.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-right.webp",
          "instructions": [
            "جلوی خودرو و سمت راست به طور کامل داخل کادر باشد.",
            "حدود ۳ متر از خودرو فاصله بگیرید.",
            "از زاویه ۴۵ درجه سمت راست عکس بگیرید."
          ],
          "distance": "۳ متر",
          "height": "کمر",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "خودرو کامل در کادر"
          ],
          "guidanceTopics": [
            "frame",
            "distance",
            "angle"
          ]
        },
        {
          "id": "back-45-right",
          "title": "عقب ۴۵° راست",
          "description": "عقب خودرو و سمت راست به صورت کامل دیده شود.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/back-45-right.webp",
          "instructions": [
            "تمام قسمت عقب و سمت راست خودرو داخل کادر باشد.",
            "خودرو را از زاویه ۴۵ درجه ثبت کنید.",
            "در نور کافی و بدون سایه شدید عکاسی کنید."
          ],
          "distance": "۳ متر",
          "height": "کمر",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "خودرو کامل در کادر"
          ],
          "guidanceTopics": [
            "frame",
            "angle",
            "glare"
          ]
        }
      ]
    },
    {
      "id": "left",
      "title": "نمای چپ",
      "order": 2,
      "photoRequirements": [
        {
          "id": "front-45-left",
          "title": "جلو ۴۵° چپ",
          "description": "جلوی خودرو و سمت چپ به صورت کامل دیده شود.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-left.webp",
          "instructions": [
            "جلوی خودرو و سمت چپ به طور کامل داخل کادر باشد.",
            "حدود ۳ متر از خودرو فاصله بگیرید.",
            "از زاویه ۴۵ درجه سمت چپ عکس بگیرید."
          ],
          "distance": "۳ متر",
          "height": "کمر",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "خودرو کامل در کادر"
          ],
          "guidanceTopics": [
            "frame",
            "distance",
            "angle"
          ]
        },
        {
          "id": "back-45-left",
          "title": "عقب ۴۵° چپ",
          "description": "عقب خودرو و سمت چپ به صورت کامل دیده شود.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/back-45-left.webp",
          "instructions": [
            "تمام قسمت عقب و سمت چپ خودرو داخل کادر باشد.",
            "خودرو را از زاویه ۴۵ درجه ثبت کنید.",
            "در نور کافی و بدون سایه شدید عکاسی کنید."
          ],
          "distance": "۳ متر",
          "height": "کمر",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "خودرو کامل در کادر"
          ],
          "guidanceTopics": [
            "frame",
            "angle",
            "glare"
          ]
        }
      ]
    },
    {
      "id": "front",
      "title": "جلو",
      "order": 3,
      "photoRequirements": [
        {
          "id": "front-plate",
          "title": "نمای مستقیم جلو با پلاک",
          "description": "یک عکس مستقیم از نمای جلوی خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/front-plate.webp",
          "instructions": [
            "مستقیم روبه‌روی خودرو بایستید؛ خودرو وسط کادر باشد.",
            "نمای کامل جلو را بدون برش و زاویه شدید ثبت کنید.",
            "پلاک بدون بازتاب نور و کاملاً خوانا باشد."
          ],
          "distance": "۳ متر",
          "height": "چراغ‌ها",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "پلاک خوانا است"
          ],
          "guidanceTopics": [
            "angle",
            "frame",
            "text"
          ]
        }
      ]
    },
    {
      "id": "rear",
      "title": "عقب",
      "order": 4,
      "photoRequirements": [
        {
          "id": "rear-plate",
          "title": "نمای مستقیم عقب با پلاک",
          "description": "یک عکس مستقیم از نمای عقب خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/rear-plate.webp",
          "instructions": [
            "مستقیم پشت خودرو بایستید؛ خودرو وسط کادر باشد.",
            "تمام نمای عقب بدون برش و زاویه شدید داخل کادر باشد.",
            "پلاک کاملاً خوانا و بدون بازتاب باشد."
          ],
          "distance": "۳ متر",
          "height": "چراغ‌ها",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "پلاک خوانا است"
          ],
          "guidanceTopics": [
            "angle",
            "frame",
            "text"
          ]
        }
      ]
    },
    {
      "id": "cabin",
      "title": "کابین",
      "order": 5,
      "photoRequirements": [
        {
          "id": "odometer-on",
          "title": "کیلومترشمار",
          "description": "خودرو را روشن کنید و تصویری واضح از کیلومترشمار بگیرید.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/odometer-on.webp",
          "instructions": [
            "خودرو را روشن و در حالت توقف نگه دارید.",
            "تمام صفحه کیلومترشمار در کادر باشد.",
            "عدد کیلومتر خوانا باشد؛ از بازتاب نور جلوگیری کنید."
          ],
          "distance": "نزدیک",
          "height": "داشبورد",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "عدد کیلومتر خوانا است"
          ],
          "guidanceTopics": [
            "ignition",
            "frame",
            "glare"
          ]
        },
        {
          "id": "driver-interior",
          "title": "نمای داخل کابین از سمت راننده",
          "description": "از سمت راننده تصویری بگیرید که فضای داخلی خودرو به صورت واضح دیده شود.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/driver-interior.webp",
          "instructions": [
            "درِ سمت راننده را باز کنید.",
            "فرمان، داشبورد و صندلی‌ها دیده شوند.",
            "خیلی نزدیک نشوید؛ فضای داخلی کامل دیده شود."
          ],
          "distance": "۱ متر",
          "height": "درِ راننده",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "کابین کامل در کادر"
          ],
          "guidanceTopics": [
            "interior",
            "frame",
            "distance"
          ]
        }
      ]
    },
    {
      "id": "engine-details",
      "title": "موتور و مشخصات",
      "order": 6,
      "photoRequirements": [
        {
          "id": "engine-bay",
          "title": "محفظه موتور",
          "description": "کاپوت را باز کنید و یک تصویر کامل و واضح از محفظه موتور بگیرید.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/engine-bay.webp",
          "instructions": [
            "خودرو متوقف باشد؛ کاپوت را کاملاً و ایمن باز کنید.",
            "تمام محفظه موتور دیده شود.",
            "گوشی ثابت و تصویر بدون تاری باشد."
          ],
          "distance": "۱ متر",
          "height": "سینه",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "محفظه کامل در کادر"
          ],
          "guidanceTopics": [
            "hood",
            "frame",
            "steady"
          ]
        },
        {
          "id": "spec-plate",
          "title": "محل شماره شاسی خودرو",
          "description": "شماره شاسی خودرو — انتخاب یکی از چهار گزینه. فقط یک تصویر لازم است.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/spec-plate.webp",
          "instructions": [
            "از نزدیک روی پلاک مشخصات فوکوس کنید.",
            "تمام متن پلاک داخل کادر باشد.",
            "نوشته‌ها خوانا و بدون بازتاب نور باشند."
          ],
          "distance": "۳۰ سانتی‌متر",
          "height": "هم‌سطح پلاک",
          "orientation": "landscape",
          "choice": {
            "groupId": "vehicle-identification",
            "alternatives": [
              "pillar",
              "engine",
              "seat",
              "windshield"
            ]
          },
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "اطلاعات قابل خواندن است"
          ],
          "guidanceTopics": [
            "text",
            "frame",
            "glare"
          ]
        }
      ]
    },
    {
      "id": "roof",
      "title": "سقف",
      "order": 7,
      "photoRequirements": [
        {
          "id": "car-roof",
          "title": "نمای سقف",
          "description": "تمام سطح سقف خودرو را در تصویر نشان دهید.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/car-roof.webp",
          "instructions": [
            "از موقعیتی ایمن، گوشی را بالاتر بگیرید.",
            "بیشترین سطح سقف و گوشه‌های اصلی در کادر باشند.",
            "برای عکاسی روی خودرو نایستید."
          ],
          "distance": "۱ متر",
          "height": "بالاتر از سقف",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "سقف کامل در کادر"
          ],
          "guidanceTopics": [
            "roof",
            "frame",
            "steady"
          ]
        }
      ]
    }
  ],
  "captureRequirements": {
    "odometerRequirementId": "odometer-on",
    "video360Required": true
  }
}
```

### نمونه خطای I05

```json
{
  "type": "urn:inspection:problem:NOT_FOUND",
  "title": "منبع مجاز پیدا نشد.",
  "status": 404,
  "code": "NOT_FOUND",
  "traceId": "trace-example",
  "errors": {}
}
```

## I06 — ثبت پذیرش شرایط

**پیشنهادی؛ تصویب نشده** — `POST /api/inspections/{inspectionId}/consent`

| موضوع | قرارداد |
|---|---|
| عملیات | B06 |
| نقش | مشتری مالک |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | inspectionId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema ConsentRequest |
| خروجی | Acknowledgement؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503 |
| اعتبارسنجی | accepted=true، نسخه شرایط مجاز و عدم جعل زمان/هویت؛ رسید سرور و نسخه بازدید ثبت شود. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | expectedVersion یا If-Match باید با نسخه سرور تطبیق کند؛ transition و idempotency و audit در یک تراکنش SQL؛ بایت فایل تراکنش SQL نیست |
| SQL | AuditLogs, IdempotencyRecords, InspectionConsents |
| خواندن جدول | IdempotencyRecords, InspectionConsents |
| نوشتن جدول | AuditLogs, IdempotencyRecords, InspectionConsents |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/lib/api/repositories.ts |
| وابستگی | A03/A05؛ قالب منتشرشده و مالکیت درخواست |

### ساختار درخواست I06

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| accepted | const true | بله | {"const":true} |
| termsVersion | string | بله | {"minLength":1,"maxLength":80} |

### مثال درخواست I06

```json
{
  "accepted": true,
  "termsVersion": "نمونه قراردادی"
}
```

### پاسخ I06

```json
{
  "acknowledged": true,
  "version": "AAAAAAAAB9E=",
  "at": "2026-10-26T09:00:00Z"
}
```

### نمونه خطای I06

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## I07 — ثبت موقعیت تأییدشده

**پیشنهادی؛ تصویب نشده** — `PUT /api/inspections/{inspectionId}/location`

| موضوع | قرارداد |
|---|---|
| عملیات | B07 |
| نقش | مشتری مالک |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | inspectionId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema LocationRequest |
| خروجی | Location؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503, 428, 412 |
| اعتبارسنجی | lat/lng محدود، accuracy غیرمنفی و رشته‌های محدود؛ نسخه و اجازه ویرایش؛ درخواست مجدد GPS لازم نیست. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | expectedVersion یا If-Match باید با نسخه سرور تطبیق کند؛ transition و idempotency و audit در یک تراکنش SQL؛ بایت فایل تراکنش SQL نیست |
| SQL | AuditLogs, IdempotencyRecords, InspectionLocations, Inspections |
| خواندن جدول | IdempotencyRecords, InspectionLocations, Inspections |
| نوشتن جدول | AuditLogs, IdempotencyRecords, InspectionLocations, Inspections |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/lib/media/inspection-facts-store.ts |
| وابستگی | A03/A05؛ قالب منتشرشده و مالکیت درخواست |

### ساختار درخواست I07

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| latitude | number | بله | {"minimum":-90,"maximum":90} |
| longitude | number | بله | {"minimum":-180,"maximum":180} |
| accuracyMeters | number | بله | {"minimum":0} |
| formattedAddress | string | بله | {"minLength":1,"maxLength":500} |
| buildingNumber | string | بله | {"maxLength":40} |
| unitFloor | string | بله | {"maxLength":80} |
| parkingDescription | string | بله | {"maxLength":500} |
| expectedVersion | string | بله | {"minLength":1,"maxLength":100} |

### مثال درخواست I07

```json
{
  "latitude": 35.699739,
  "longitude": 51.338097,
  "accuracyMeters": 8,
  "formattedAddress": "تهران، خیابان نمونه، محل بازدید",
  "buildingNumber": "نمونه قراردادی",
  "unitFloor": "نمونه قراردادی",
  "parkingDescription": "نمونه قراردادی",
  "expectedVersion": "AAAAAAAAB9E="
}
```

### پاسخ I07

```json
{
  "latitude": 35.699739,
  "longitude": 51.338097,
  "accuracyMeters": 8,
  "formattedAddress": "تهران، خیابان نمونه، محل بازدید",
  "buildingNumber": "نمونه قراردادی",
  "unitFloor": "نمونه قراردادی",
  "parkingDescription": "نمونه قراردادی"
}
```

### نمونه خطای I07

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## I08 — مشخصات خودرو

**پیشنهادی؛ تصویب نشده** — `GET /api/inspections/{inspectionId}/vehicle`

| موضوع | قرارداد |
|---|---|
| عملیات | B08 |
| نقش | مالک یا کارکنان مجاز؛ projection جدا |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | inspectionId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | ندارد |
| سرآیند | Accept: application/json |
| بدنه | ندارد |
| خروجی | Vehicle؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503 |
| اعتبارسنجی | snapshot خودرو همین بازدید؛ پلاک ساختاریافته، VIN با projection مناسب و مجوز خواندن. |
| تکرار امن | بدون اثر تجاری؛ تکرار خواندن امن است، حساس‌ها no-store و بدون cache عمومی |
| هم‌زمانی | خواندن ETag/version؛ GET هیچ بازدید یا تصمیمی ایجاد نمی‌کند |
| SQL | Vehicles |
| خواندن جدول | Vehicles |
| نوشتن جدول | ندارد |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/lib/api/repositories.ts |
| وابستگی | A03/A05؛ قالب منتشرشده و مالکیت درخواست |

### پاسخ I08

```json
{
  "id": "11111111-1111-4111-8111-111111111111",
  "make": "خودروی نمونه",
  "model": "سدان نمونه",
  "modelYear": 2024,
  "color": "سفید",
  "bodyColor": "#F1F5F9",
  "plate": {
    "firstTwoDigits": "12",
    "letter": "ب",
    "threeDigits": "345",
    "regionDigits": "67"
  },
  "maskedVin": "DEMO••••••3456",
  "confirmed": true,
  "version": "AAAAAAAAB9E="
}
```

### نمونه خطای I08

```json
{
  "type": "urn:inspection:problem:NOT_FOUND",
  "title": "منبع مجاز پیدا نشد.",
  "status": 404,
  "code": "NOT_FOUND",
  "traceId": "trace-example",
  "errors": {}
}
```

## I09 — تأیید مشخصات و مغایرت مجاز

**پیشنهادی؛ تصویب نشده** — `PUT /api/inspections/{inspectionId}/vehicle`

| موضوع | قرارداد |
|---|---|
| عملیات | B09 |
| نقش | مشتری مالک |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | inspectionId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema VehicleRequest |
| خروجی | Vehicle؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503, 428, 412 |
| اعتبارسنجی | IranianPlate segment‌ها، حقایق مجاز و نسخه؛ پس از ارسال تغییر آزاد ممنوع و field correction باید scoped باشد. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | expectedVersion یا If-Match باید با نسخه سرور تطبیق کند؛ transition و idempotency و audit در یک تراکنش SQL؛ بایت فایل تراکنش SQL نیست |
| SQL | AuditLogs, IdempotencyRecords, Inspections, Vehicles |
| خواندن جدول | IdempotencyRecords, Inspections, Vehicles |
| نوشتن جدول | AuditLogs, IdempotencyRecords, Inspections, Vehicles |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/lib/api/repositories.ts |
| وابستگی | A03/A05؛ قالب منتشرشده و مالکیت درخواست |

### ساختار درخواست I09

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| expectedVersion | string | بله | {"minLength":1,"maxLength":100} |
| confirmed | const true | بله | {"const":true} |
| plate | Plate | اختیاری | {} |
| discrepancy | string | اختیاری | {"maxLength":1000} |

### مثال درخواست I09

```json
{
  "expectedVersion": "AAAAAAAAB9E=",
  "confirmed": true
}
```

### پاسخ I09

```json
{
  "id": "11111111-1111-4111-8111-111111111111",
  "make": "خودروی نمونه",
  "model": "سدان نمونه",
  "modelYear": 2024,
  "color": "سفید",
  "bodyColor": "#F1F5F9",
  "plate": {
    "firstTwoDigits": "12",
    "letter": "ب",
    "threeDigits": "345",
    "regionDigits": "67"
  },
  "maskedVin": "DEMO••••••3456",
  "confirmed": true,
  "version": "AAAAAAAAB9E="
}
```

### نمونه خطای I09

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## I10 — نام مستعار سازگار برای اصلاح پلاک پیش از ارسال

**پیشنهادی؛ تصویب نشده** — `PUT /api/inspections/{inspectionId}/vehicle/plate`

| موضوع | قرارداد |
|---|---|
| عملیات | B09 |
| نقش | مشتری مالک |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | inspectionId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema PlateRequest |
| خروجی | Vehicle؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503, 428, 412 |
| اعتبارسنجی | IranianPlate segment‌ها، حقایق مجاز و نسخه؛ پس از ارسال تغییر آزاد ممنوع و field correction باید scoped باشد. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | expectedVersion یا If-Match باید با نسخه سرور تطبیق کند؛ transition و idempotency و audit در یک تراکنش SQL؛ بایت فایل تراکنش SQL نیست |
| SQL | AuditLogs, IdempotencyRecords, Inspections, Vehicles |
| خواندن جدول | IdempotencyRecords, Inspections, Vehicles |
| نوشتن جدول | AuditLogs, IdempotencyRecords, Inspections, Vehicles |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/lib/api/repositories.ts |
| وابستگی | A03/A05؛ قالب منتشرشده و مالکیت درخواست |

### ساختار درخواست I10

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| expectedVersion | string | بله | {"minLength":1,"maxLength":100} |
| plate | Plate | بله | {} |

### مثال درخواست I10

```json
{
  "expectedVersion": "AAAAAAAAB9E=",
  "plate": {
    "firstTwoDigits": "12",
    "letter": "ب",
    "threeDigits": "345",
    "regionDigits": "67"
  }
}
```

### پاسخ I10

```json
{
  "id": "11111111-1111-4111-8111-111111111111",
  "make": "خودروی نمونه",
  "model": "سدان نمونه",
  "modelYear": 2024,
  "color": "سفید",
  "bodyColor": "#F1F5F9",
  "plate": {
    "firstTwoDigits": "12",
    "letter": "ب",
    "threeDigits": "345",
    "regionDigits": "67"
  },
  "maskedVin": "DEMO••••••3456",
  "confirmed": true,
  "version": "AAAAAAAAB9E="
}
```

### نمونه خطای I10

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## I11 — کیلومتر عددی؛ خواندن از summary

**پیشنهادی؛ تصویب نشده** — `PUT /api/inspections/{inspectionId}/odometer`

| موضوع | قرارداد |
|---|---|
| عملیات | B10 |
| نقش | مشتری مالک |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | inspectionId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema OdometerRequest |
| خروجی | Odometer؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503, 428, 412 |
| اعتبارسنجی | kilometers صحیح و امن، صفر مجاز؛ evidenceId در صورت وجود به عکس کیلومتر همین بازدید؛ replacement عدد را خودکار پاک نکند. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | expectedVersion یا If-Match باید با نسخه سرور تطبیق کند؛ transition و idempotency و audit در یک تراکنش SQL؛ بایت فایل تراکنش SQL نیست |
| SQL | AuditLogs, IdempotencyRecords, Inspections, OdometerReadings |
| خواندن جدول | IdempotencyRecords, Inspections, OdometerReadings |
| نوشتن جدول | AuditLogs, IdempotencyRecords, Inspections, OdometerReadings |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/lib/media/capture-data-store.ts |
| وابستگی | A03/A05؛ قالب منتشرشده و مالکیت درخواست |

### ساختار درخواست I11

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| kilometers | integer | بله | {"minimum":0,"maximum":9007199254740991} |
| evidenceId | string | اختیاری | {"minLength":1,"maxLength":160} |
| expectedVersion | string | بله | {"minLength":1,"maxLength":100} |

### مثال درخواست I11

```json
{
  "kilometers": 48320,
  "expectedVersion": "AAAAAAAAB9E="
}
```

### پاسخ I11

```json
{
  "kilometers": 48320,
  "updatedAt": "2026-10-26T09:00:00Z"
}
```

### نمونه خطای I11

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## M01 — مرز مرکزی نشانی نشان

**پیشنهادی؛ تصویب نشده** — `GET /api/maps/reverse`

| موضوع | قرارداد |
|---|---|
| عملیات | B11 |
| نقش | مشتری مالک |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | ندارد |
| query | lat: number محدود به[-90,90]؛ lng: number محدود به[-180,180] |
| سرآیند | Accept: application/json |
| بدنه | ندارد |
| خروجی | ReverseAddress؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503 |
| اعتبارسنجی | مختصات محدود، مجوز و quota درخواست؛ کلید خصوصی Neshan فقط سرور مرکزی و پاسخ عمومی نشانی فارسی. |
| تکرار امن | بدون اثر تجاری؛ تکرار خواندن امن است، حساس‌ها no-store و بدون cache عمومی |
| هم‌زمانی | خواندن ETag/version؛ GET هیچ بازدید یا تصمیمی ایجاد نمی‌کند |
| SQL | فایل استقرار/ارائه‌دهنده بیرونی؛ SQL خصوصی جدید نمی‌خواهد |
| خواندن جدول | ندارد |
| نوشتن جدول | ندارد |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/lib/map/reverse-geocoder.ts |
| وابستگی | A03/A05؛ قالب منتشرشده و مالکیت درخواست |

### پاسخ M01

```json
{
  "formatted_address": "تهران، خیابان نمونه، محل بازدید"
}
```

### نمونه خطای M01

```json
{
  "type": "urn:inspection:problem:NOT_FOUND",
  "title": "منبع مجاز پیدا نشد.",
  "status": 404,
  "code": "NOT_FOUND",
  "traceId": "trace-example",
  "errors": {}
}
```

## EV01 — ثبت نسخه و قرارداد انتقال مشترک عکس و ویدیو

**پیشنهادی؛ تصویب نشده** — `POST /api/inspections/{inspectionId}/evidence`

| موضوع | قرارداد |
|---|---|
| عملیات | C01, D06 |
| نقش | مشتری مالک |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | inspectionId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema EvidenceRegistration |
| خروجی | UploadTicket؛ تعریف دقیق در schemas.json |
| کد موفقیت | 201, 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503, 428, 412 |
| اعتبارسنجی | kind و revision ثابت؛ requirement عضو قالب پین‌شده؛ spec-plate نسخه ۲ دقیقاً یک alternative معتبر؛ video فاقد photoId؛ فراداده نوع/اندازه و scope اصلاح.؛ candidate به request/item/requirement/revision مجاز وصل باشد؛ هیچ قلم اضافی یا job قدیمی pointer اصل را تغییر ندهد. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | نسخه همان evidence slot/upload session با CAS کنترل شود؛ عضویت، قفل بازدید و scope اصلاح در تراکنش بررسی شود. Byte progress نسخه aggregate را عوض نکند. replay نتیجه ثبت‌شده پیش از رد CAS کهنه؛ granularity نهایی در D04 تصویب شود. |
| SQL | AuditLogs, CorrectionItems, EvidenceVersions, IdempotencyRecords, InspectionEvidence, MediaFiles, UploadSessions |
| خواندن جدول | EvidenceVersions, IdempotencyRecords, InspectionEvidence, MediaFiles, UploadSessions, CorrectionItems |
| نوشتن جدول | AuditLogs, EvidenceVersions, IdempotencyRecords, InspectionEvidence, MediaFiles, UploadSessions, CorrectionItems |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. رزرو مسیر نسخه در metadata؛ هنوز هیچ بایتی از مرورگر دریافت نشده است.؛ ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/additional-evidence/request-service.ts؛ src/features/upload/upload-transport.ts |
| وابستگی | A03/A05، B01/B05؛ سیاست نوع/اندازه و فضای خصوصی؛ B01-B10، C01-C06؛ نسخه دقیق و آمادگی سرور |

### ساختار درخواست EV01

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| kind | photo / video-360 | بله | {"enum":["photo","video-360"]} |
| requirementId | string | اختیاری | {"minLength":1,"maxLength":160} |
| alternativeId | pillar / engine / seat / windshield | اختیاری | {"enum":["pillar","engine","seat","windshield"]} |
| templateId | string | بله | {"minLength":1,"maxLength":160} |
| templateVersion | integer | بله | {"minimum":1} |
| photoPolicyVersion | 1 / 2 | بله | {"enum":[1,2]} |
| revision | string | بله | {"minLength":1,"maxLength":160} |
| mimeType | string | بله | {"minLength":1,"maxLength":127} |
| byteSize | integer | بله | {"minimum":1,"maximum":9007199254740991} |
| capturedAt | string | بله | {"format":"date-time"} |
| durationSeconds | number | اختیاری | {"exclusiveMinimum":0} |
| sha256 | string | اختیاری | {"pattern":"^[0-9a-f]{64}$"} |
| replacesEvidenceId | string | اختیاری | {"minLength":1,"maxLength":160} |
| request | RequestScope | اختیاری | {} |
| expectedVersion | string | بله | {"minLength":1,"maxLength":100} |

### مثال درخواست EV01

```json
{
  "kind": "photo",
  "requirementId": "spec-plate",
  "alternativeId": "pillar",
  "templateId": "body-image-guided",
  "templateVersion": 2,
  "photoPolicyVersion": 2,
  "revision": "client-revision-0002",
  "mimeType": "image/jpeg",
  "byteSize": 420000,
  "capturedAt": "2026-10-26T09:00:00Z",
  "expectedVersion": "AAAAAAAAB9E="
}
```

### پاسخ EV01

```json
{
  "evidenceId": "11111111-1111-4111-8111-111111111111",
  "evidenceVersionId": "22222222-2222-4222-8222-222222222222",
  "uploadId": "33333333-3333-4333-8333-333333333333",
  "uploadUrl": "/api/bazdid/uploads/33333333-3333-4333-8333-333333333333/content",
  "method": "PUT",
  "expiresAt": "2026-10-26T09:00:00Z",
  "version": "AAAAAAAAB9E="
}
```

### نمونه خطای EV01

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## EV02 — جریان فایل به فضای موقت خصوصی

**پیشنهادی؛ تصویب نشده** — `PUT /api/uploads/{uploadId}/content`

| موضوع | قرارداد |
|---|---|
| عملیات | C02 |
| نقش | مالک مجوز انتقال همین فایل |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | uploadId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: MIME واقعی مذاکره‌شده؛ Content-Length: اگر توسط UA/پروتکل ارسال شد باید مطابق ticket باشد؛ درغیاب آن stream محدود و count واقعی ملاک است. |
| بدنه | application/octet-stream؛ schema BinaryTransfer |
| خروجی | TransferResult؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 413, 415, 422, 429, 500, 503 |
| اعتبارسنجی | upload session متعلق به همان نسخه، expiry و سقف stream؛ signature/hash واقعی در سرور؛ فایل بدون Base64 و بدون مسیر دلخواه نوشته شود. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | فقط مالک lease/session و هویت ثابت همین انتقال می‌تواند stream بنویسد؛ انتقال تکراری هم‌زمان باید رد یا به همان نتیجه وصل شود. پیشرفت بایت rowversion کل بازدید را تغییر ندهد. |
| SQL | AuditLogs, EvidenceVersions, IdempotencyRecords, MediaFiles, UploadSessions |
| خواندن جدول | EvidenceVersions, IdempotencyRecords, MediaFiles, UploadSessions |
| نوشتن جدول | AuditLogs, EvidenceVersions, IdempotencyRecords, MediaFiles, UploadSessions |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. نوشتن stream محدود در staging همان uploadId؛ بدون بازنویسی اصل خوب. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/upload/upload-coordinator.ts |
| وابستگی | A03/A05، B01/B05؛ سیاست نوع/اندازه و فضای خصوصی |

### ساختار درخواست EV02

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|

بدنه جریان بایت همان فایل است؛ هیچ نمونه Base64/JSON باینری مجاز نیست. Content-Length و MIME با ticket و signature واقعی تطبیق می‌شود؛ resume بایتی فقط پس از توافق پروتکل، فعلاً restart همان انتقال با هویت ثابت قابل قبول است.

### پاسخ EV02

```json
{
  "uploadId": "33333333-3333-4333-8333-333333333333",
  "state": "staged",
  "bytesReceived": 420000
}
```

### نمونه خطای EV02

```json
{
  "type": "urn:inspection:problem:FILE_TOO_LARGE",
  "title": "اندازه فایل از حد مجاز بیشتر است.",
  "status": 413,
  "code": "FILE_TOO_LARGE",
  "traceId": "trace-example",
  "errors": {}
}
```

## EV03 — تأیید پایدار انتقال و اعلام پردازش

**پیشنهادی؛ تصویب نشده** — `POST /api/evidence/{evidenceId}/complete`

| موضوع | قرارداد |
|---|---|
| عملیات | C03, D06 |
| نقش | مالک مجوز انتقال همین فایل |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | evidenceId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema CompleteUpload |
| خروجی | Evidence؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503, 428, 412 |
| اعتبارسنجی | بایت پایدار، اندازه و hash سرور، revision هدف و receipt قابل بازیابی؛ پردازش جدا؛ اصل خوب قبل از موفقیت حفظ شود.؛ candidate به request/item/requirement/revision مجاز وصل باشد؛ هیچ قلم اضافی یا job قدیمی pointer اصل را تغییر ندهد. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | نسخه همان evidence slot/upload session با CAS کنترل شود؛ عضویت، قفل بازدید و scope اصلاح در تراکنش بررسی شود. Byte progress نسخه aggregate را عوض نکند. replay نتیجه ثبت‌شده پیش از رد CAS کهنه؛ granularity نهایی در D04 تصویب شود. |
| SQL | AuditLogs, CorrectionItems, EvidenceVersions, IdempotencyRecords, MediaFiles, MediaProcessingJobs, UploadSessions |
| خواندن جدول | EvidenceVersions, IdempotencyRecords, MediaFiles, MediaProcessingJobs, UploadSessions, CorrectionItems |
| نوشتن جدول | AuditLogs, EvidenceVersions, IdempotencyRecords, MediaFiles, MediaProcessingJobs, UploadSessions, CorrectionItems |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. verify/hash/flush، انتشار فایل همان نسخه و در صورت تصویب enqueue مشتق؛ SQL و filesystem نیاز به reconciliation دارند.؛ ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/additional-evidence/request-service.ts؛ src/features/upload/upload-transport.ts |
| وابستگی | A03/A05، B01/B05؛ سیاست نوع/اندازه و فضای خصوصی؛ B01-B10، C01-C06؛ نسخه دقیق و آمادگی سرور |

### ساختار درخواست EV03

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| revision | string | بله | {"minLength":1,"maxLength":160} |
| byteSize | integer | بله | {"minimum":1} |
| sha256 | string | اختیاری | {"pattern":"^[0-9a-f]{64}$"} |
| expectedVersion | string | بله | {"minLength":1,"maxLength":100} |

### مثال درخواست EV03

```json
{
  "revision": "client-revision-0002",
  "byteSize": 420000,
  "expectedVersion": "AAAAAAAAB9E="
}
```

### پاسخ EV03

```json
{
  "evidenceId": "11111111-1111-4111-8111-111111111111",
  "evidenceVersionId": "22222222-2222-4222-8222-222222222222",
  "inspectionId": "insp_contract_001",
  "kind": "photo",
  "requirementId": "spec-plate",
  "alternativeId": "pillar",
  "revision": "client-revision-0002",
  "upload": "uploaded",
  "verification": "processing",
  "byteSize": 420000,
  "mimeType": "image/jpeg",
  "sha256": "0000000000000000000000000000000000000000000000000000000000000000",
  "current": true,
  "version": "AAAAAAAAB9E="
}
```

### نمونه خطای EV03

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## EV04 — فهرست و تطبیق نسخه و وضعیت پردازش

**پیشنهادی؛ تصویب نشده** — `GET /api/inspections/{inspectionId}/evidence`

| موضوع | قرارداد |
|---|---|
| عملیات | C04, C05 |
| نقش | مالک یا کارکنان مجاز؛ projection جدا |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | inspectionId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | cursor: string اختیاری، opaque و scope-bound؛ pageSize: integer از 1 تا 100؛ پیش‌فرض 20؛ sort: whitelist، ترتیب پایدار با شناسه نهایی؛ view: current یا history؛ history تنها با مجوز |
| سرآیند | Accept: application/json |
| بدنه | ندارد |
| خروجی | EvidencePage؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503 |
| اعتبارسنجی | scope پرونده/نسخه و cursor محدود؛ نمایش current/history دقیق؛ localBlobKey مرجع فایل سرور نیست.؛ processing از upload و تصمیم کارشناس جدا؛ فقط وضعیت نسخه مجاز و بدون درصد ساختگی برگردد. |
| تکرار امن | بدون اثر تجاری؛ تکرار خواندن امن است، حساس‌ها no-store و بدون cache عمومی |
| هم‌زمانی | خواندن ETag/version؛ GET هیچ بازدید یا تصمیمی ایجاد نمی‌کند |
| SQL | EvidenceReviews, EvidenceVersions, InspectionEvidence, MediaFiles, MediaProcessingJobs |
| خواندن جدول | EvidenceVersions, InspectionEvidence, MediaFiles, MediaProcessingJobs |
| نوشتن جدول | ندارد |
| اثر فایل | فایل/مشتق خصوصی همان نسخه با مجوز؛ فقط در صورت نیاز و بدون بارگذاری گروهی بایت‌ها. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه.؛ فایل/مشتق خصوصی همان نسخه با مجوز؛ فقط در صورت نیاز و بدون بارگذاری گروهی بایت‌ها. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/upload/queue-repository.ts؛ src/features/upload/upload-transport.ts |
| وابستگی | A03/A05، B01/B05؛ سیاست نوع/اندازه و فضای خصوصی |

### پاسخ EV04

```json
{
  "items": [
    {
      "evidenceId": "11111111-1111-4111-8111-111111111111",
      "evidenceVersionId": "22222222-2222-4222-8222-222222222222",
      "inspectionId": "insp_contract_001",
      "kind": "photo",
      "requirementId": "spec-plate",
      "alternativeId": "pillar",
      "revision": "client-revision-0002",
      "upload": "uploaded",
      "verification": "processing",
      "byteSize": 420000,
      "mimeType": "image/jpeg",
      "sha256": "0000000000000000000000000000000000000000000000000000000000000000",
      "current": true,
      "version": "AAAAAAAAB9E="
    }
  ],
  "nextCursor": null
}
```

### نمونه خطای EV04

```json
{
  "type": "urn:inspection:problem:NOT_FOUND",
  "title": "منبع مجاز پیدا نشد.",
  "status": 404,
  "code": "NOT_FOUND",
  "traceId": "trace-example",
  "errors": {}
}
```

## EV05 — دریافت مجاز نسخه و Range ویدیو

**پیشنهادی؛ تصویب نشده** — `GET /api/inspections/{inspectionId}/evidence/{evidenceId}/file`

| موضوع | قرارداد |
|---|---|
| عملیات | C06 |
| نقش | مالک یا کارکنان مجاز؛ projection جدا |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | inspectionId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت؛ evidenceId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | revision: string اختیاری؛ نسخه مجاز دقیق؛ variant: original، thumbnail، preview یا transcode؛ فقط variant موجود و مجاز همان revision |
| سرآیند | Accept: نوع رسانه مجاز؛ Range: bytes=start-end اختیاری؛ پاسخ 206 یا 416 معتبر |
| بدنه | ندارد |
| خروجی | BinaryTransfer؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200, 206 |
| کد خطا | 400, 401, 403, 404, 409, 416, 422, 429, 500, 503 |
| اعتبارسنجی | مجوز هر درخواست و Range، نسخه دقیق و path containment؛ MIME/nosniff و 206/416 صحیح؛ فایل خصوصی عمومی نشود. |
| تکرار امن | بدون اثر تجاری؛ تکرار خواندن امن است، حساس‌ها no-store و بدون cache عمومی |
| هم‌زمانی | خواندن ETag/version؛ GET هیچ بازدید یا تصمیمی ایجاد نمی‌کند |
| SQL | EvidenceVersions, MediaFiles, ReviewerAssignments |
| خواندن جدول | EvidenceVersions, MediaFiles, ReviewerAssignments |
| نوشتن جدول | ندارد |
| اثر فایل | فایل/مشتق خصوصی همان نسخه با مجوز؛ فقط در صورت نیاز و بدون بارگذاری گروهی بایت‌ها. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/upload/upload-preview.tsx |
| وابستگی | A03/A05، B01/B05؛ سیاست نوع/اندازه و فضای خصوصی |

### پاسخ EV05

بدنه باینری مجاز، با Content-Type واقعی، Content-Length، X-Content-Type-Options:nosniff و Range/Content-Range استاندارد برای ویدیو؛ مسیر فیزیکی برگردانده نمی‌شود. این جریان پخش خودکار ندارد.

### نمونه خطای EV05

```json
{
  "type": "urn:inspection:problem:NOT_FOUND",
  "title": "منبع مجاز پیدا نشد.",
  "status": 404,
  "code": "NOT_FOUND",
  "traceId": "trace-example",
  "errors": {}
}
```

## EV06 — لغو انتقال منسوخ بدون حذف مدرک خوب

**پیشنهادی؛ تصویب نشده** — `POST /api/evidence/{evidenceId}/cancel-upload`

| موضوع | قرارداد |
|---|---|
| عملیات | C07 |
| نقش | مالک مجوز انتقال همین فایل |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | evidenceId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema Command |
| خروجی | Acknowledgement؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503, 428, 412 |
| اعتبارسنجی | فقط session منسوخ مجاز با CAS لغو شود؛ فایل پذیرفته‌شده یا snapshot قبلی حذف نشود. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | expectedVersion یا If-Match باید با نسخه سرور تطبیق کند؛ transition و idempotency و audit در یک تراکنش SQL؛ بایت فایل تراکنش SQL نیست |
| SQL | AuditLogs, EvidenceVersions, IdempotencyRecords, UploadSessions |
| خواندن جدول | EvidenceVersions, IdempotencyRecords, UploadSessions |
| نوشتن جدول | AuditLogs, EvidenceVersions, IdempotencyRecords, UploadSessions |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. توقف session منسوخ؛ فایل current یا تاریخچه حذف نمی‌شود. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/upload/upload-coordinator.ts |
| وابستگی | A03/A05، B01/B05؛ سیاست نوع/اندازه و فضای خصوصی |

### ساختار درخواست EV06

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| expectedVersion | string | بله | {"minLength":1,"maxLength":100} |

### مثال درخواست EV06

```json
{
  "expectedVersion": "AAAAAAAAB9E="
}
```

### پاسخ EV06

```json
{
  "acknowledged": true,
  "version": "AAAAAAAAB9E=",
  "at": "2026-10-26T09:00:00Z"
}
```

### نمونه خطای EV06

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## I12 — مرور نهایی و موانع مشتق

**پیشنهادی؛ تصویب نشده** — `GET /api/inspections/{inspectionId}/summary`

| موضوع | قرارداد |
|---|---|
| عملیات | D01, B10 |
| نقش | مشتری مالک |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | inspectionId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | ندارد |
| سرآیند | Accept: application/json |
| بدنه | ندارد |
| خروجی | Summary؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503 |
| اعتبارسنجی | خلاصه از همان منابع مشتق؛ ۱۱ عکس قالب تازه، کیلومتر معتبر و ویدیو جدا؛ شمار فایل از قالب، نه عدد ثابت.؛ kilometers صحیح و امن، صفر مجاز؛ evidenceId در صورت وجود به عکس کیلومتر همین بازدید؛ replacement عدد را خودکار پاک نکند. |
| تکرار امن | بدون اثر تجاری؛ تکرار خواندن امن است، حساس‌ها no-store و بدون cache عمومی |
| هم‌زمانی | خواندن ETag/version؛ GET هیچ بازدید یا تصمیمی ایجاد نمی‌کند |
| SQL | AuditLogs, EvidenceVersions, IdempotencyRecords, InspectionEvidence, Inspections, OdometerReadings |
| خواندن جدول | IdempotencyRecords, Inspections, OdometerReadings, EvidenceVersions, InspectionEvidence |
| نوشتن جدول | AuditLogs, IdempotencyRecords, Inspections, OdometerReadings |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه.؛ فایل/مشتق خصوصی همان نسخه با مجوز؛ فقط در صورت نیاز و بدون بارگذاری گروهی بایت‌ها. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/submission/summary-source.ts؛ src/lib/media/capture-data-store.ts |
| وابستگی | B01-B10، C01-C06؛ نسخه دقیق و آمادگی سرور؛ A03/A05؛ قالب منتشرشده و مالکیت درخواست |

### پاسخ I12

```json
{
  "inspection": {
    "inspectionId": "insp_contract_001",
    "sourceRequestId": "REQ-DEMO-001",
    "trackingCode": "BDI-8F31K2",
    "status": "DRAFT",
    "templateId": "body-image-guided",
    "templateVersion": 2,
    "photoPolicyVersion": 2,
    "version": "AAAAAAAAB9E="
  },
  "photos": {
    "completed": 11,
    "required": 11
  },
  "odometer": {
    "kilometers": 48320,
    "updatedAt": "2026-10-26T09:00:00Z"
  },
  "video360": {
    "accepted": true,
    "durationSeconds": 48
  },
  "media": {
    "uploaded": 12,
    "required": 12,
    "processing": 2
  },
  "readiness": {
    "captureComplete": true,
    "requiredMediaUploaded": true,
    "odometerValid": true,
    "factsConfirmed": true,
    "canSubmit": true,
    "blockingUploadFailures": false
  },
  "blockers": []
}
```

### نمونه خطای I12

```json
{
  "type": "urn:inspection:problem:NOT_FOUND",
  "title": "منبع مجاز پیدا نشد.",
  "status": 404,
  "code": "NOT_FOUND",
  "traceId": "trace-example",
  "errors": {}
}
```

## I13 — ارسال رسمی و بازیابی همان فرمان

**پیشنهادی؛ تصویب نشده** — `POST /api/inspections/{inspectionId}/submit`

| موضوع | قرارداد |
|---|---|
| عملیات | D02, D03 |
| نقش | مشتری مالک |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | inspectionId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema Command |
| خروجی | Receipt؛ تعریف دقیق در schemas.json |
| کد موفقیت | 201, 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503, 428, 412 |
| اعتبارسنجی | آمادگی سروری، receipt همه نسخه‌های هدف، کیلومتر، قفل و CAS؛ processing/uploaded/verified با سیاست باینری سازگار و local/queued/failed مسدود.؛ همان کلید و بدنه فرمان قبلی با احراز مجدد مجوز؛ بازیابی receipt پیش از رد نسخه کهنه؛ ارسال تکراری نسازد. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | expectedVersion یا If-Match باید با نسخه سرور تطبیق کند؛ transition و idempotency و audit در یک تراکنش SQL؛ بایت فایل تراکنش SQL نیست |
| SQL | AuditLogs, IdempotencyRecords, InspectionStatusHistory, InspectionSubmissions, Inspections, SubmissionEvidence |
| خواندن جدول | IdempotencyRecords, InspectionSubmissions, Inspections, SubmissionEvidence |
| نوشتن جدول | AuditLogs, IdempotencyRecords, InspectionStatusHistory, InspectionSubmissions, Inspections, SubmissionEvidence |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه.؛ ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/submission/submission-service.ts |
| وابستگی | B01-B10، C01-C06؛ نسخه دقیق و آمادگی سرور |

### ساختار درخواست I13

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| expectedVersion | string | بله | {"minLength":1,"maxLength":100} |

### مثال درخواست I13

```json
{
  "expectedVersion": "AAAAAAAAB9E="
}
```

### پاسخ I13

```json
{
  "reference": "BDI-8F31K2",
  "submittedAt": "2026-10-26T09:00:00Z",
  "status": "queued-for-review",
  "inspectionId": "insp_contract_001",
  "version": "AAAAAAAAB9E=",
  "reviewEstimateLabel": "۳ تا ۵ روز کاری؛ برآورد نمونه محصول، نه SLA",
  "isEstimate": true
}
```

### نمونه خطای I13

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## I14 — وضعیت امن و رسید تأیید مقصد

**پیشنهادی؛ تصویب نشده** — `GET /api/inspections/{inspectionId}/status`

| موضوع | قرارداد |
|---|---|
| عملیات | D04, G05 |
| نقش | مالک یا کارکنان مجاز؛ projection جدا |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | inspectionId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | ندارد |
| سرآیند | Accept: application/json |
| بدنه | ندارد |
| خروجی | Status؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503 |
| اعتبارسنجی | همان inspection و رسید موجود؛ submit و upload و review و forwarding جدا؛ نبود رسید مجوز ادعای موفقیت نیست.؛ نمایش از D04 و فقط پس از ack معتبر FORWARDED؛ وضعیت داخلی credential/خطای خام نشت نکند. |
| تکرار امن | بدون اثر تجاری؛ تکرار خواندن امن است، حساس‌ها no-store و بدون cache عمومی |
| هم‌زمانی | خواندن ETag/version؛ GET هیچ بازدید یا تصمیمی ایجاد نمی‌کند |
| SQL | CorrectionRequests, ForwardingJobs, InspectionStatusHistory, Inspections |
| خواندن جدول | CorrectionRequests, ForwardingJobs, InspectionStatusHistory, Inspections |
| نوشتن جدول | ندارد |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه.؛ ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08, D11, D12 |
| آداپتور فعلی | src/features/inspection-status/lifecycle-model.ts؛ src/features/inspection-status/status-service.ts |
| وابستگی | B01-B10، C01-C06؛ نسخه دقیق و آمادگی سرور؛ E09؛ snapshot و مقصد/تأیید مقصد مورد توافق |

### پاسخ I14

```json
{
  "inspectionId": "insp_contract_001",
  "status": "FORWARD_PENDING",
  "trackingCode": "BDI-8F31K2",
  "version": "AAAAAAAAB9E=",
  "updatedAt": "2026-10-26T09:00:00Z",
  "forwarding": {
    "phase": "ready"
  },
  "corrections": []
}
```

### نمونه خطای I14

```json
{
  "type": "urn:inspection:problem:NOT_FOUND",
  "title": "منبع مجاز پیدا نشد.",
  "status": 404,
  "code": "NOT_FOUND",
  "traceId": "trace-example",
  "errors": {}
}
```

## R01 — اقلام و دلایل دقیق اصلاح

**پیشنهادی؛ تصویب نشده** — `GET /api/inspections/{inspectionId}/evidence-requests`

| موضوع | قرارداد |
|---|---|
| عملیات | D05 |
| نقش | مالک یا کارکنان مجاز؛ projection جدا |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | inspectionId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | ندارد |
| سرآیند | Accept: application/json |
| بدنه | ندارد |
| خروجی | EvidenceRequestPage؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503 |
| اعتبارسنجی | requestId/version متعلق به همین بازدید و مشتری؛ reason عمومی و اقلام فعال دقیق؛ اطلاعات خصوصی کارشناس حذف شود. |
| تکرار امن | بدون اثر تجاری؛ تکرار خواندن امن است، حساس‌ها no-store و بدون cache عمومی |
| هم‌زمانی | خواندن ETag/version؛ GET هیچ بازدید یا تصمیمی ایجاد نمی‌کند |
| SQL | CorrectionItems, CorrectionRequests, InspectionSubmissions |
| خواندن جدول | CorrectionItems, CorrectionRequests, InspectionSubmissions |
| نوشتن جدول | ندارد |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/additional-evidence/request-repository.ts |
| وابستگی | B01-B10، C01-C06؛ نسخه دقیق و آمادگی سرور |

### پاسخ R01

```json
{
  "items": [
    {
      "id": "11111111-1111-4111-8111-111111111111",
      "inspectionId": "insp_contract_001",
      "version": 1,
      "round": 1,
      "status": "requested",
      "items": [
        {
          "id": "11111111-1111-4111-8111-111111111111",
          "kind": "photo",
          "requirementId": "spec-plate",
          "originalEvidenceId": "11111111-1111-4111-8111-111111111111",
          "originalRevision": "client-revision-0001",
          "reviewerReason": "شماره شاسی خوانا نیست.",
          "state": "requested"
        }
      ],
      "template": {
        "photoPolicyVersion": 2,
        "templateId": "body-image-guided",
        "templateVersion": 2,
        "sections": [
          {
            "id": "right",
            "title": "نمای راست",
            "order": 1,
            "photoRequirements": [
              {
                "id": "front-45-right",
                "title": "جلو ۴۵° راست",
                "description": "جلوی خودرو و سمت راست به صورت کامل دیده شود.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-right.webp",
                "instructions": [
                  "جلوی خودرو و سمت راست به طور کامل داخل کادر باشد.",
                  "حدود ۳ متر از خودرو فاصله بگیرید.",
                  "از زاویه ۴۵ درجه سمت راست عکس بگیرید."
                ],
                "distance": "۳ متر",
                "height": "کمر",
                "orientation": "landscape",
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "خودرو کامل در کادر"
                ],
                "guidanceTopics": [
                  "frame",
                  "distance",
                  "angle"
                ]
              },
              {
                "id": "back-45-right",
                "title": "عقب ۴۵° راست",
                "description": "عقب خودرو و سمت راست به صورت کامل دیده شود.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/back-45-right.webp",
                "instructions": [
                  "تمام قسمت عقب و سمت راست خودرو داخل کادر باشد.",
                  "خودرو را از زاویه ۴۵ درجه ثبت کنید.",
                  "در نور کافی و بدون سایه شدید عکاسی کنید."
                ],
                "distance": "۳ متر",
                "height": "کمر",
                "orientation": "landscape",
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "خودرو کامل در کادر"
                ],
                "guidanceTopics": [
                  "frame",
                  "angle",
                  "glare"
                ]
              }
            ]
          },
          {
            "id": "left",
            "title": "نمای چپ",
            "order": 2,
            "photoRequirements": [
              {
                "id": "front-45-left",
                "title": "جلو ۴۵° چپ",
                "description": "جلوی خودرو و سمت چپ به صورت کامل دیده شود.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-left.webp",
                "instructions": [
                  "جلوی خودرو و سمت چپ به طور کامل داخل کادر باشد.",
                  "حدود ۳ متر از خودرو فاصله بگیرید.",
                  "از زاویه ۴۵ درجه سمت چپ عکس بگیرید."
                ],
                "distance": "۳ متر",
                "height": "کمر",
                "orientation": "landscape",
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "خودرو کامل در کادر"
                ],
                "guidanceTopics": [
                  "frame",
                  "distance",
                  "angle"
                ]
              },
              {
                "id": "back-45-left",
                "title": "عقب ۴۵° چپ",
                "description": "عقب خودرو و سمت چپ به صورت کامل دیده شود.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/back-45-left.webp",
                "instructions": [
                  "تمام قسمت عقب و سمت چپ خودرو داخل کادر باشد.",
                  "خودرو را از زاویه ۴۵ درجه ثبت کنید.",
                  "در نور کافی و بدون سایه شدید عکاسی کنید."
                ],
                "distance": "۳ متر",
                "height": "کمر",
                "orientation": "landscape",
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "خودرو کامل در کادر"
                ],
                "guidanceTopics": [
                  "frame",
                  "angle",
                  "glare"
                ]
              }
            ]
          },
          {
            "id": "front",
            "title": "جلو",
            "order": 3,
            "photoRequirements": [
              {
                "id": "front-plate",
                "title": "نمای مستقیم جلو با پلاک",
                "description": "یک عکس مستقیم از نمای جلوی خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/front-plate.webp",
                "instructions": [
                  "مستقیم روبه‌روی خودرو بایستید؛ خودرو وسط کادر باشد.",
                  "نمای کامل جلو را بدون برش و زاویه شدید ثبت کنید.",
                  "پلاک بدون بازتاب نور و کاملاً خوانا باشد."
                ],
                "distance": "۳ متر",
                "height": "چراغ‌ها",
                "orientation": "landscape",
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "پلاک خوانا است"
                ],
                "guidanceTopics": [
                  "angle",
                  "frame",
                  "text"
                ]
              }
            ]
          },
          {
            "id": "rear",
            "title": "عقب",
            "order": 4,
            "photoRequirements": [
              {
                "id": "rear-plate",
                "title": "نمای مستقیم عقب با پلاک",
                "description": "یک عکس مستقیم از نمای عقب خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/rear-plate.webp",
                "instructions": [
                  "مستقیم پشت خودرو بایستید؛ خودرو وسط کادر باشد.",
                  "تمام نمای عقب بدون برش و زاویه شدید داخل کادر باشد.",
                  "پلاک کاملاً خوانا و بدون بازتاب باشد."
                ],
                "distance": "۳ متر",
                "height": "چراغ‌ها",
                "orientation": "landscape",
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "پلاک خوانا است"
                ],
                "guidanceTopics": [
                  "angle",
                  "frame",
                  "text"
                ]
              }
            ]
          },
          {
            "id": "cabin",
            "title": "کابین",
            "order": 5,
            "photoRequirements": [
              {
                "id": "odometer-on",
                "title": "کیلومترشمار",
                "description": "خودرو را روشن کنید و تصویری واضح از کیلومترشمار بگیرید.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/odometer-on.webp",
                "instructions": [
                  "خودرو را روشن و در حالت توقف نگه دارید.",
                  "تمام صفحه کیلومترشمار در کادر باشد.",
                  "عدد کیلومتر خوانا باشد؛ از بازتاب نور جلوگیری کنید."
                ],
                "distance": "نزدیک",
                "height": "داشبورد",
                "orientation": "landscape",
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "عدد کیلومتر خوانا است"
                ],
                "guidanceTopics": [
                  "ignition",
                  "frame",
                  "glare"
                ]
              },
              {
                "id": "driver-interior",
                "title": "نمای داخل کابین از سمت راننده",
                "description": "از سمت راننده تصویری بگیرید که فضای داخلی خودرو به صورت واضح دیده شود.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/driver-interior.webp",
                "instructions": [
                  "درِ سمت راننده را باز کنید.",
                  "فرمان، داشبورد و صندلی‌ها دیده شوند.",
                  "خیلی نزدیک نشوید؛ فضای داخلی کامل دیده شود."
                ],
                "distance": "۱ متر",
                "height": "درِ راننده",
                "orientation": "landscape",
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "کابین کامل در کادر"
                ],
                "guidanceTopics": [
                  "interior",
                  "frame",
                  "distance"
                ]
              }
            ]
          },
          {
            "id": "engine-details",
            "title": "موتور و مشخصات",
            "order": 6,
            "photoRequirements": [
              {
                "id": "engine-bay",
                "title": "محفظه موتور",
                "description": "کاپوت را باز کنید و یک تصویر کامل و واضح از محفظه موتور بگیرید.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/engine-bay.webp",
                "instructions": [
                  "خودرو متوقف باشد؛ کاپوت را کاملاً و ایمن باز کنید.",
                  "تمام محفظه موتور دیده شود.",
                  "گوشی ثابت و تصویر بدون تاری باشد."
                ],
                "distance": "۱ متر",
                "height": "سینه",
                "orientation": "landscape",
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "محفظه کامل در کادر"
                ],
                "guidanceTopics": [
                  "hood",
                  "frame",
                  "steady"
                ]
              },
              {
                "id": "spec-plate",
                "title": "محل شماره شاسی خودرو",
                "description": "شماره شاسی خودرو — انتخاب یکی از چهار گزینه. فقط یک تصویر لازم است.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/spec-plate.webp",
                "instructions": [
                  "از نزدیک روی پلاک مشخصات فوکوس کنید.",
                  "تمام متن پلاک داخل کادر باشد.",
                  "نوشته‌ها خوانا و بدون بازتاب نور باشند."
                ],
                "distance": "۳۰ سانتی‌متر",
                "height": "هم‌سطح پلاک",
                "orientation": "landscape",
                "choice": {
                  "groupId": "vehicle-identification",
                  "alternatives": [
                    "pillar",
                    "engine",
                    "seat",
                    "windshield"
                  ]
                },
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "اطلاعات قابل خواندن است"
                ],
                "guidanceTopics": [
                  "text",
                  "frame",
                  "glare"
                ]
              }
            ]
          },
          {
            "id": "roof",
            "title": "سقف",
            "order": 7,
            "photoRequirements": [
              {
                "id": "car-roof",
                "title": "نمای سقف",
                "description": "تمام سطح سقف خودرو را در تصویر نشان دهید.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/car-roof.webp",
                "instructions": [
                  "از موقعیتی ایمن، گوشی را بالاتر بگیرید.",
                  "بیشترین سطح سقف و گوشه‌های اصلی در کادر باشند.",
                  "برای عکاسی روی خودرو نایستید."
                ],
                "distance": "۱ متر",
                "height": "بالاتر از سقف",
                "orientation": "landscape",
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "سقف کامل در کادر"
                ],
                "guidanceTopics": [
                  "roof",
                  "frame",
                  "steady"
                ]
              }
            ]
          }
        ],
        "captureRequirements": {
          "odometerRequirementId": "odometer-on",
          "video360Required": true
        }
      }
    }
  ]
}
```

### نمونه خطای R01

```json
{
  "type": "urn:inspection:problem:NOT_FOUND",
  "title": "منبع مجاز پیدا نشد.",
  "status": 404,
  "code": "NOT_FOUND",
  "traceId": "trace-example",
  "errors": {}
}
```

## R02 — پوسته سازگار ثبت جایگزین؛ همان سرویس EV01

**پیشنهادی؛ تصویب نشده** — `POST /api/evidence-requests/{requestId}/replacement`

| موضوع | قرارداد |
|---|---|
| عملیات | D06 |
| نقش | مالک و قلم درخواست اصلاح فعال |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | requestId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema EvidenceRegistration |
| خروجی | UploadTicket؛ تعریف دقیق در schemas.json |
| کد موفقیت | 201, 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503, 428, 412 |
| اعتبارسنجی | candidate به request/item/requirement/revision مجاز وصل باشد؛ هیچ قلم اضافی یا job قدیمی pointer اصل را تغییر ندهد. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | expectedVersion یا If-Match باید با نسخه سرور تطبیق کند؛ transition و idempotency و audit در یک تراکنش SQL؛ بایت فایل تراکنش SQL نیست |
| SQL | AuditLogs, CorrectionItems, EvidenceVersions, IdempotencyRecords, MediaFiles, UploadSessions |
| خواندن جدول | CorrectionItems, EvidenceVersions, IdempotencyRecords, MediaFiles, UploadSessions |
| نوشتن جدول | AuditLogs, CorrectionItems, EvidenceVersions, IdempotencyRecords, MediaFiles, UploadSessions |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/additional-evidence/request-service.ts |
| وابستگی | B01-B10، C01-C06؛ نسخه دقیق و آمادگی سرور |

### ساختار درخواست R02

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| kind | photo / video-360 | بله | {"enum":["photo","video-360"]} |
| requirementId | string | اختیاری | {"minLength":1,"maxLength":160} |
| alternativeId | pillar / engine / seat / windshield | اختیاری | {"enum":["pillar","engine","seat","windshield"]} |
| templateId | string | بله | {"minLength":1,"maxLength":160} |
| templateVersion | integer | بله | {"minimum":1} |
| photoPolicyVersion | 1 / 2 | بله | {"enum":[1,2]} |
| revision | string | بله | {"minLength":1,"maxLength":160} |
| mimeType | string | بله | {"minLength":1,"maxLength":127} |
| byteSize | integer | بله | {"minimum":1,"maximum":9007199254740991} |
| capturedAt | string | بله | {"format":"date-time"} |
| durationSeconds | number | اختیاری | {"exclusiveMinimum":0} |
| sha256 | string | اختیاری | {"pattern":"^[0-9a-f]{64}$"} |
| replacesEvidenceId | string | اختیاری | {"minLength":1,"maxLength":160} |
| request | RequestScope | اختیاری | {} |
| expectedVersion | string | بله | {"minLength":1,"maxLength":100} |

### مثال درخواست R02

```json
{
  "kind": "photo",
  "requirementId": "spec-plate",
  "alternativeId": "pillar",
  "templateId": "body-image-guided",
  "templateVersion": 2,
  "photoPolicyVersion": 2,
  "revision": "client-revision-0002",
  "mimeType": "image/jpeg",
  "byteSize": 420000,
  "capturedAt": "2026-10-26T09:00:00Z",
  "expectedVersion": "AAAAAAAAB9E="
}
```

### پاسخ R02

```json
{
  "evidenceId": "11111111-1111-4111-8111-111111111111",
  "evidenceVersionId": "22222222-2222-4222-8222-222222222222",
  "uploadId": "33333333-3333-4333-8333-333333333333",
  "uploadUrl": "/api/bazdid/uploads/33333333-3333-4333-8333-333333333333/content",
  "method": "PUT",
  "expiresAt": "2026-10-26T09:00:00Z",
  "version": "AAAAAAAAB9E="
}
```

### نمونه خطای R02

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## R03 — ثبت دور اصلاحات تأییدشده و برگشت به بررسی

**پیشنهادی؛ تصویب نشده** — `POST /api/inspections/{inspectionId}/resubmit`

| موضوع | قرارداد |
|---|---|
| عملیات | D07 |
| نقش | مالک و قلم درخواست اصلاح فعال |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | inspectionId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema ResubmitRequest |
| خروجی | Receipt؛ تعریف دقیق در schemas.json |
| کد موفقیت | 201, 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503, 428, 412 |
| اعتبارسنجی | نسخه درخواست و receipt تمام اقلام خواسته‌شده؛ promotion اتمیک؛ اقلام تأییدشده خارج از scope ثابت بمانند. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | expectedVersion یا If-Match باید با نسخه سرور تطبیق کند؛ transition و idempotency و audit در یک تراکنش SQL؛ بایت فایل تراکنش SQL نیست |
| SQL | AuditLogs, CorrectionItems, CorrectionRequests, IdempotencyRecords, InspectionEvidence, InspectionStatusHistory, InspectionSubmissions, Inspections, SubmissionEvidence |
| خواندن جدول | CorrectionItems, CorrectionRequests, IdempotencyRecords, InspectionEvidence, InspectionSubmissions, Inspections, SubmissionEvidence |
| نوشتن جدول | AuditLogs, CorrectionItems, CorrectionRequests, IdempotencyRecords, InspectionEvidence, InspectionStatusHistory, InspectionSubmissions, Inspections, SubmissionEvidence |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/additional-evidence/request-service.ts |
| وابستگی | B01-B10، C01-C06؛ نسخه دقیق و آمادگی سرور |

### ساختار درخواست R03

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| requestId | string | بله | {"minLength":1,"maxLength":160} |
| requestVersion | integer | بله | {"minimum":1} |
| candidateEvidenceIds | array | بله | {"items":{"type":"string","minLength":1,"maxLength":160},"minItems":1,"uniqueItems":true} |
| expectedVersion | string | بله | {"minLength":1,"maxLength":100} |

### مثال درخواست R03

```json
{
  "requestId": "11111111-1111-4111-8111-111111111111",
  "requestVersion": 1,
  "candidateEvidenceIds": [
    "00000000-0000-4000-8000-000000000021"
  ],
  "expectedVersion": "AAAAAAAAB9E="
}
```

### پاسخ R03

```json
{
  "reference": "BDI-8F31K2",
  "submittedAt": "2026-10-26T09:00:00Z",
  "status": "queued-for-review",
  "inspectionId": "insp_contract_001",
  "version": "AAAAAAAAB9E=",
  "reviewEstimateLabel": "۳ تا ۵ روز کاری؛ برآورد نمونه محصول، نه SLA",
  "isEstimate": true
}
```

### نمونه خطای R03

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## R04 — پیشنهاد اصلاح همان فیلد

**پیشنهادی؛ تصویب نشده** — `PUT /api/inspections/{inspectionId}/field-corrections/{taskId}`

| موضوع | قرارداد |
|---|---|
| عملیات | D08 |
| نقش | مالک و قلم درخواست اصلاح فعال |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | inspectionId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت؛ taskId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema FieldProposal |
| خروجی | Acknowledgement؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503, 428, 412 |
| اعتبارسنجی | field از union مجاز همان task و نوع مقدار درست؛ فقط scope خواسته‌شده و CAS؛ درخواست جدید ضمنی ایجاد نشود. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | expectedVersion یا If-Match باید با نسخه سرور تطبیق کند؛ transition و idempotency و audit در یک تراکنش SQL؛ بایت فایل تراکنش SQL نیست |
| SQL | AuditLogs, CorrectionItems, IdempotencyRecords |
| خواندن جدول | CorrectionItems, IdempotencyRecords |
| نوشتن جدول | AuditLogs, CorrectionItems, IdempotencyRecords |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/inspection-status/lifecycle-repository.ts |
| وابستگی | B01-B10، C01-C06؛ نسخه دقیق و آمادگی سرور |

### ساختار درخواست R04

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| expectedVersion | string | بله | {"minLength":1,"maxLength":100} |
| field | plate / color / modelYear | بله | {"enum":["plate","color","modelYear"]} |
| value | oneOf | بله | {"oneOf":[{"$ref":"#/$defs/Plate"},{"type":"string","minLength":1,"maxLength":80},{"type":"integer","minimum":1000,"maximum":3000}]} |

### مثال درخواست R04

```json
{
  "expectedVersion": "AAAAAAAAB9E=",
  "field": "plate",
  "value": {
    "firstTwoDigits": "12",
    "letter": "ب",
    "threeDigits": "345",
    "regionDigits": "67"
  }
}
```

### پاسخ R04

```json
{
  "acknowledged": true,
  "version": "AAAAAAAAB9E=",
  "at": "2026-10-26T09:00:00Z"
}
```

### نمونه خطای R04

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## I15 — تلاش جدید خالی پس از رد کامل

**پیشنهادی؛ تصویب نشده** — `POST /api/inspections/{inspectionId}/attempts`

| موضوع | قرارداد |
|---|---|
| عملیات | D09 |
| نقش | مشتری مالک |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | inspectionId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema Command |
| خروجی | Inspection؛ تعریف دقیق در schemas.json |
| کد موفقیت | 201, 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503, 428, 412 |
| اعتبارسنجی | فقط رد کامل و فرمان صریح مالک؛ current/attempt اتمیک؛ تلاش جدید خالی و تاریخچه قبلی immutable. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | expectedVersion یا If-Match باید با نسخه سرور تطبیق کند؛ transition و idempotency و audit در یک تراکنش SQL؛ بایت فایل تراکنش SQL نیست |
| SQL | AuditLogs, IdempotencyRecords, InspectionStatusHistory, Inspections, SourceInsuranceRequests, Vehicles |
| خواندن جدول | IdempotencyRecords, Inspections, SourceInsuranceRequests, Vehicles |
| نوشتن جدول | AuditLogs, IdempotencyRecords, InspectionStatusHistory, Inspections, Vehicles |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/inspection-status/lifecycle-repository.ts |
| وابستگی | B01-B10، C01-C06؛ نسخه دقیق و آمادگی سرور |

### ساختار درخواست I15

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| expectedVersion | string | بله | {"minLength":1,"maxLength":100} |

### مثال درخواست I15

```json
{
  "expectedVersion": "AAAAAAAAB9E="
}
```

### پاسخ I15

```json
{
  "inspectionId": "insp_contract_001",
  "sourceRequestId": "REQ-DEMO-001",
  "trackingCode": "BDI-8F31K2",
  "status": "DRAFT",
  "templateId": "body-image-guided",
  "templateVersion": 2,
  "photoPolicyVersion": 2,
  "version": "AAAAAAAAB9E="
}
```

### نمونه خطای I15

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## RV01 — پرونده کارشناس با یادداشت خصوصی

**پیشنهادی؛ تصویب نشده** — `GET /api/reviewer/cases/{caseId}`

| موضوع | قرارداد |
|---|---|
| عملیات | E02 |
| نقش | کارشناس دارای ارجاع یا مدیر دارای مجوز خواندن؛ بدون حق تصمیم ضمنی |
| احراز هویت | نشست کارکنان؛ کارشناس دارای ارجاع یا مدیر دارای مجوز خواندن همان پرونده. پاسخ براساس نقش پالایش شود؛ یادداشت خصوصی فقط با اختیار صریح و تصمیم فقط برای کارشناس مجاز است. |
| ورودی مسیر | caseId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | ندارد |
| سرآیند | Accept: application/json |
| بدنه | ندارد |
| خروجی | Case؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503 |
| اعتبارسنجی | ارجاع فعال کارشناس یا مجوز خواندن مدیر؛ projection نقش و نسخه پرونده؛ مدیر حق تصمیم ضمنی ندارد. |
| تکرار امن | بدون اثر تجاری؛ تکرار خواندن امن است، حساس‌ها no-store و بدون cache عمومی |
| هم‌زمانی | خواندن ETag/version؛ GET هیچ بازدید یا تصمیمی ایجاد نمی‌کند |
| SQL | EvidenceReviews, Inspections, InternalNotes, ReviewerAssignments |
| خواندن جدول | EvidenceReviews, Inspections, InternalNotes, ReviewerAssignments |
| نوشتن جدول | ندارد |
| اثر فایل | فایل/مشتق خصوصی همان نسخه با مجوز؛ فقط در صورت نیاز و بدون بارگذاری گروهی بایت‌ها. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/review-operations/repository.ts |
| وابستگی | A04/A05، D02؛ ارجاع و نسخه پرونده |

### پاسخ RV01

```json
{
  "caseId": "insp_contract_001",
  "inspection": {
    "inspection": {
      "inspectionId": "insp_contract_001",
      "sourceRequestId": "REQ-DEMO-001",
      "trackingCode": "BDI-8F31K2",
      "status": "UNDER_REVIEW",
      "templateId": "body-image-guided",
      "templateVersion": 2,
      "photoPolicyVersion": 2,
      "version": "AAAAAAAAB9E="
    },
    "photos": {
      "completed": 11,
      "required": 11
    },
    "odometer": {
      "kilometers": 48320,
      "updatedAt": "2026-10-26T09:00:00Z"
    },
    "video360": {
      "accepted": true,
      "durationSeconds": 48
    },
    "media": {
      "uploaded": 12,
      "required": 12,
      "processing": 2
    },
    "readiness": {
      "captureComplete": true,
      "requiredMediaUploaded": true,
      "odometerValid": true,
      "factsConfirmed": true,
      "canSubmit": true,
      "blockingUploadFailures": false
    },
    "blockers": []
  },
  "version": "AAAAAAAAB9E=",
  "evidence": [
    {
      "evidenceId": "11111111-1111-4111-8111-111111111111",
      "evidenceVersionId": "22222222-2222-4222-8222-222222222222",
      "inspectionId": "insp_contract_001",
      "kind": "photo",
      "requirementId": "spec-plate",
      "alternativeId": "pillar",
      "revision": "client-revision-0002",
      "upload": "uploaded",
      "verification": "processing",
      "byteSize": 420000,
      "mimeType": "image/jpeg",
      "sha256": "0000000000000000000000000000000000000000000000000000000000000000",
      "current": true,
      "version": "AAAAAAAAB9E="
    }
  ],
  "internalNotes": [],
  "reference": "BDI-8F31K2",
  "submittedAt": "2026-10-27T08:30:00Z",
  "status": "in-review",
  "template": {
    "photoPolicyVersion": 2,
    "templateId": "body-image-guided",
    "templateVersion": 2,
    "sections": [
      {
        "id": "right",
        "title": "نمای راست",
        "order": 1,
        "photoRequirements": [
          {
            "id": "front-45-right",
            "title": "جلو ۴۵° راست",
            "description": "جلوی خودرو و سمت راست به صورت کامل دیده شود.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-right.webp",
            "instructions": [
              "جلوی خودرو و سمت راست به طور کامل داخل کادر باشد.",
              "حدود ۳ متر از خودرو فاصله بگیرید.",
              "از زاویه ۴۵ درجه سمت راست عکس بگیرید."
            ],
            "distance": "۳ متر",
            "height": "کمر",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "خودرو کامل در کادر"
            ],
            "guidanceTopics": [
              "frame",
              "distance",
              "angle"
            ]
          },
          {
            "id": "back-45-right",
            "title": "عقب ۴۵° راست",
            "description": "عقب خودرو و سمت راست به صورت کامل دیده شود.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/back-45-right.webp",
            "instructions": [
              "تمام قسمت عقب و سمت راست خودرو داخل کادر باشد.",
              "خودرو را از زاویه ۴۵ درجه ثبت کنید.",
              "در نور کافی و بدون سایه شدید عکاسی کنید."
            ],
            "distance": "۳ متر",
            "height": "کمر",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "خودرو کامل در کادر"
            ],
            "guidanceTopics": [
              "frame",
              "angle",
              "glare"
            ]
          }
        ]
      },
      {
        "id": "left",
        "title": "نمای چپ",
        "order": 2,
        "photoRequirements": [
          {
            "id": "front-45-left",
            "title": "جلو ۴۵° چپ",
            "description": "جلوی خودرو و سمت چپ به صورت کامل دیده شود.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-left.webp",
            "instructions": [
              "جلوی خودرو و سمت چپ به طور کامل داخل کادر باشد.",
              "حدود ۳ متر از خودرو فاصله بگیرید.",
              "از زاویه ۴۵ درجه سمت چپ عکس بگیرید."
            ],
            "distance": "۳ متر",
            "height": "کمر",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "خودرو کامل در کادر"
            ],
            "guidanceTopics": [
              "frame",
              "distance",
              "angle"
            ]
          },
          {
            "id": "back-45-left",
            "title": "عقب ۴۵° چپ",
            "description": "عقب خودرو و سمت چپ به صورت کامل دیده شود.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/back-45-left.webp",
            "instructions": [
              "تمام قسمت عقب و سمت چپ خودرو داخل کادر باشد.",
              "خودرو را از زاویه ۴۵ درجه ثبت کنید.",
              "در نور کافی و بدون سایه شدید عکاسی کنید."
            ],
            "distance": "۳ متر",
            "height": "کمر",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "خودرو کامل در کادر"
            ],
            "guidanceTopics": [
              "frame",
              "angle",
              "glare"
            ]
          }
        ]
      },
      {
        "id": "front",
        "title": "جلو",
        "order": 3,
        "photoRequirements": [
          {
            "id": "front-plate",
            "title": "نمای مستقیم جلو با پلاک",
            "description": "یک عکس مستقیم از نمای جلوی خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/front-plate.webp",
            "instructions": [
              "مستقیم روبه‌روی خودرو بایستید؛ خودرو وسط کادر باشد.",
              "نمای کامل جلو را بدون برش و زاویه شدید ثبت کنید.",
              "پلاک بدون بازتاب نور و کاملاً خوانا باشد."
            ],
            "distance": "۳ متر",
            "height": "چراغ‌ها",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "پلاک خوانا است"
            ],
            "guidanceTopics": [
              "angle",
              "frame",
              "text"
            ]
          }
        ]
      },
      {
        "id": "rear",
        "title": "عقب",
        "order": 4,
        "photoRequirements": [
          {
            "id": "rear-plate",
            "title": "نمای مستقیم عقب با پلاک",
            "description": "یک عکس مستقیم از نمای عقب خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/rear-plate.webp",
            "instructions": [
              "مستقیم پشت خودرو بایستید؛ خودرو وسط کادر باشد.",
              "تمام نمای عقب بدون برش و زاویه شدید داخل کادر باشد.",
              "پلاک کاملاً خوانا و بدون بازتاب باشد."
            ],
            "distance": "۳ متر",
            "height": "چراغ‌ها",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "پلاک خوانا است"
            ],
            "guidanceTopics": [
              "angle",
              "frame",
              "text"
            ]
          }
        ]
      },
      {
        "id": "cabin",
        "title": "کابین",
        "order": 5,
        "photoRequirements": [
          {
            "id": "odometer-on",
            "title": "کیلومترشمار",
            "description": "خودرو را روشن کنید و تصویری واضح از کیلومترشمار بگیرید.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/odometer-on.webp",
            "instructions": [
              "خودرو را روشن و در حالت توقف نگه دارید.",
              "تمام صفحه کیلومترشمار در کادر باشد.",
              "عدد کیلومتر خوانا باشد؛ از بازتاب نور جلوگیری کنید."
            ],
            "distance": "نزدیک",
            "height": "داشبورد",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "عدد کیلومتر خوانا است"
            ],
            "guidanceTopics": [
              "ignition",
              "frame",
              "glare"
            ]
          },
          {
            "id": "driver-interior",
            "title": "نمای داخل کابین از سمت راننده",
            "description": "از سمت راننده تصویری بگیرید که فضای داخلی خودرو به صورت واضح دیده شود.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/driver-interior.webp",
            "instructions": [
              "درِ سمت راننده را باز کنید.",
              "فرمان، داشبورد و صندلی‌ها دیده شوند.",
              "خیلی نزدیک نشوید؛ فضای داخلی کامل دیده شود."
            ],
            "distance": "۱ متر",
            "height": "درِ راننده",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "کابین کامل در کادر"
            ],
            "guidanceTopics": [
              "interior",
              "frame",
              "distance"
            ]
          }
        ]
      },
      {
        "id": "engine-details",
        "title": "موتور و مشخصات",
        "order": 6,
        "photoRequirements": [
          {
            "id": "engine-bay",
            "title": "محفظه موتور",
            "description": "کاپوت را باز کنید و یک تصویر کامل و واضح از محفظه موتور بگیرید.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/engine-bay.webp",
            "instructions": [
              "خودرو متوقف باشد؛ کاپوت را کاملاً و ایمن باز کنید.",
              "تمام محفظه موتور دیده شود.",
              "گوشی ثابت و تصویر بدون تاری باشد."
            ],
            "distance": "۱ متر",
            "height": "سینه",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "محفظه کامل در کادر"
            ],
            "guidanceTopics": [
              "hood",
              "frame",
              "steady"
            ]
          },
          {
            "id": "spec-plate",
            "title": "محل شماره شاسی خودرو",
            "description": "شماره شاسی خودرو — انتخاب یکی از چهار گزینه. فقط یک تصویر لازم است.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/spec-plate.webp",
            "instructions": [
              "از نزدیک روی پلاک مشخصات فوکوس کنید.",
              "تمام متن پلاک داخل کادر باشد.",
              "نوشته‌ها خوانا و بدون بازتاب نور باشند."
            ],
            "distance": "۳۰ سانتی‌متر",
            "height": "هم‌سطح پلاک",
            "orientation": "landscape",
            "choice": {
              "groupId": "vehicle-identification",
              "alternatives": [
                "pillar",
                "engine",
                "seat",
                "windshield"
              ]
            },
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "اطلاعات قابل خواندن است"
            ],
            "guidanceTopics": [
              "text",
              "frame",
              "glare"
            ]
          }
        ]
      },
      {
        "id": "roof",
        "title": "سقف",
        "order": 7,
        "photoRequirements": [
          {
            "id": "car-roof",
            "title": "نمای سقف",
            "description": "تمام سطح سقف خودرو را در تصویر نشان دهید.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/car-roof.webp",
            "instructions": [
              "از موقعیتی ایمن، گوشی را بالاتر بگیرید.",
              "بیشترین سطح سقف و گوشه‌های اصلی در کادر باشند.",
              "برای عکاسی روی خودرو نایستید."
            ],
            "distance": "۱ متر",
            "height": "بالاتر از سقف",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "سقف کامل در کادر"
            ],
            "guidanceTopics": [
              "roof",
              "frame",
              "steady"
            ]
          }
        ]
      }
    ],
    "captureRequirements": {
      "odometerRequirementId": "odometer-on",
      "video360Required": true
    }
  },
  "decisions": [
    {
      "id": "decision-example",
      "requirementId": "spec-plate",
      "revision": "client-revision-0002",
      "evidenceId": "11111111-1111-4111-8111-111111111111",
      "decision": "approved",
      "actorId": "staff-example",
      "at": "2026-10-27T08:30:00Z"
    }
  ],
  "fieldCorrections": []
}
```

### نمونه خطای RV01

```json
{
  "type": "urn:inspection:problem:NOT_FOUND",
  "title": "منبع مجاز پیدا نشد.",
  "status": 404,
  "code": "NOT_FOUND",
  "traceId": "trace-example",
  "errors": {}
}
```

## RV02 — ارجاع اتمیک و کنترل ظرفیت

**پیشنهادی؛ تصویب نشده** — `POST /api/admin/inspections/{inspectionId}/assignment`

| موضوع | قرارداد |
|---|---|
| عملیات | E03 |
| نقش | مدیر سایت همین نصب |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | inspectionId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema AssignmentRequest |
| خروجی | Acknowledgement؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503, 428, 412 |
| اعتبارسنجی | staff فعال، permission ارجاع، ظرفیت و سیاست؛ reassignment با CAS و audit؛ تصمیم کارشناس قبلی بعد از جابه‌جایی رد شود. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | expectedVersion یا If-Match باید با نسخه سرور تطبیق کند؛ transition و idempotency و audit در یک تراکنش SQL؛ بایت فایل تراکنش SQL نیست |
| SQL | AuditLogs, IdempotencyRecords, InspectionStatusHistory, Inspections, ReviewerAssignments, StaffUsers |
| خواندن جدول | IdempotencyRecords, Inspections, ReviewerAssignments, StaffUsers |
| نوشتن جدول | AuditLogs, IdempotencyRecords, InspectionStatusHistory, Inspections, ReviewerAssignments |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/review-operations/model.ts |
| وابستگی | A04/A05، D02؛ ارجاع و نسخه پرونده |

### ساختار درخواست RV02

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| reviewerId | string | بله | {"minLength":1,"maxLength":160} |
| reassign | boolean | بله | {} |
| expectedVersion | string | بله | {"minLength":1,"maxLength":100} |

### مثال درخواست RV02

```json
{
  "reviewerId": "11111111-1111-4111-8111-111111111111",
  "reassign": true,
  "expectedVersion": "AAAAAAAAB9E="
}
```

### پاسخ RV02

```json
{
  "acknowledged": true,
  "version": "AAAAAAAAB9E=",
  "at": "2026-10-26T09:00:00Z"
}
```

### نمونه خطای RV02

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## RV03 — حالت و ظرفیت ارجاع؛ خواندن از workspace

**پیشنهادی؛ تصویب نشده** — `PUT /api/admin/reviewer-policy`

| موضوع | قرارداد |
|---|---|
| عملیات | E04 |
| نقش | مدیر سایت همین نصب |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | ندارد |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema ReviewerPolicy |
| خروجی | Acknowledgement؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503, 428, 412 |
| اعتبارسنجی | mode از manual/random، ظرفیت صحیح و نسخه workspace؛ random در سرور و اختیار مدیریت لازم. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | expectedVersion یا If-Match باید با نسخه سرور تطبیق کند؛ transition و idempotency و audit در یک تراکنش SQL؛ بایت فایل تراکنش SQL نیست |
| SQL | AuditLogs, IdempotencyRecords, StaffOperationsSettings, StaffUsers |
| خواندن جدول | IdempotencyRecords, StaffOperationsSettings, StaffUsers |
| نوشتن جدول | AuditLogs, IdempotencyRecords, StaffOperationsSettings, StaffUsers |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/review-operations/repository.ts |
| وابستگی | A04/A05، D02؛ ارجاع و نسخه پرونده |

### ساختار درخواست RV03

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| mode | manual / random | بله | {"enum":["manual","random"]} |
| capacities | array | بله | {"items":{"type":"object","additionalProperties":false,"properties":{"staffId":{"type":"string","minLength":1,"maxLength":160},"capacity":{"type":"integer","minimum":0,"maximum":10000}},"required":["staffId","capacity"]}} |
| expectedVersion | string | بله | {"minLength":1,"maxLength":100} |

### مثال درخواست RV03

```json
{
  "mode": "manual",
  "capacities": [],
  "expectedVersion": "AAAAAAAAB9E="
}
```

### پاسخ RV03

```json
{
  "acknowledged": true,
  "version": "AAAAAAAAB9E=",
  "at": "2026-10-26T09:00:00Z"
}
```

### نمونه خطای RV03

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## RV04 — تصمیم یک نسخه عکس یا ویدیو

**پیشنهادی؛ تصویب نشده** — `POST /api/reviewer/cases/{caseId}/evidence-decisions`

| موضوع | قرارداد |
|---|---|
| عملیات | E05 |
| نقش | کارشناس دارای ارجاع فعال |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | caseId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema EvidenceDecision |
| خروجی | Acknowledgement؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503, 428, 412 |
| اعتبارسنجی | نسخه دقیق مدرک و پرونده، ارجاع فعال؛ دلیل عمومی برای رد/retake اجباری؛ نسخه جدید با پاسخ قدیمی overwrite نشود. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | expectedVersion یا If-Match باید با نسخه سرور تطبیق کند؛ transition و idempotency و audit در یک تراکنش SQL؛ بایت فایل تراکنش SQL نیست |
| SQL | AuditLogs, CorrectionItems, CorrectionRequests, EvidenceReviews, IdempotencyRecords, InspectionStatusHistory, Inspections |
| خواندن جدول | CorrectionItems, CorrectionRequests, EvidenceReviews, IdempotencyRecords, Inspections |
| نوشتن جدول | AuditLogs, CorrectionItems, CorrectionRequests, EvidenceReviews, IdempotencyRecords, InspectionStatusHistory, Inspections |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/review-operations/repository.ts |
| وابستگی | A04/A05، D02؛ ارجاع و نسخه پرونده |

### ساختار درخواست RV04

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| evidenceId | string | بله | {"minLength":1,"maxLength":160} |
| revision | string | بله | {"minLength":1,"maxLength":160} |
| decision | approved / rejected | بله | {"enum":["approved","rejected"]} |
| reason | string | اختیاری | {"maxLength":2000,"minLength":1} |
| expectedVersion | string | بله | {"minLength":1,"maxLength":100} |

### مثال درخواست RV04

```json
{
  "evidenceId": "11111111-1111-4111-8111-111111111111",
  "revision": "client-revision-0002",
  "decision": "approved",
  "expectedVersion": "AAAAAAAAB9E="
}
```

### پاسخ RV04

```json
{
  "acknowledged": true,
  "version": "AAAAAAAAB9E=",
  "at": "2026-10-26T09:00:00Z"
}
```

### نمونه خطای RV04

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## RV05 — ایجاد درخواست اصلاح مشخصات

**پیشنهادی؛ تصویب نشده** — `POST /api/reviewer/cases/{caseId}/field-corrections`

| موضوع | قرارداد |
|---|---|
| عملیات | E06 |
| نقش | کارشناس دارای ارجاع فعال |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | caseId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema FieldRequest |
| خروجی | Acknowledgement؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503, 428, 412 |
| اعتبارسنجی | field فقط plate/color/modelYear و دلیل روشن؛ task مستقل از رد کلی و مدرک دیگر؛ کارشناس باید ارجاع فعال داشته باشد. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | expectedVersion یا If-Match باید با نسخه سرور تطبیق کند؛ transition و idempotency و audit در یک تراکنش SQL؛ بایت فایل تراکنش SQL نیست |
| SQL | AuditLogs, CorrectionItems, CorrectionRequests, IdempotencyRecords, InspectionStatusHistory, Inspections |
| خواندن جدول | CorrectionItems, CorrectionRequests, IdempotencyRecords, Inspections |
| نوشتن جدول | AuditLogs, CorrectionItems, CorrectionRequests, IdempotencyRecords, InspectionStatusHistory, Inspections |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/review-operations/repository.ts |
| وابستگی | A04/A05، D02؛ ارجاع و نسخه پرونده |

### ساختار درخواست RV05

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| field | plate / color / modelYear | بله | {"enum":["plate","color","modelYear"]} |
| customerReason | string | بله | {"minLength":1,"maxLength":2000} |
| expectedVersion | string | بله | {"minLength":1,"maxLength":100} |

### مثال درخواست RV05

```json
{
  "field": "plate",
  "customerReason": "رنگ ثبت‌شده با خودرو تطبیق ندارد.",
  "expectedVersion": "AAAAAAAAB9E="
}
```

### پاسخ RV05

```json
{
  "acknowledged": true,
  "version": "AAAAAAAAB9E=",
  "at": "2026-10-26T09:00:00Z"
}
```

### نمونه خطای RV05

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## RV06 — تأیید پیشنهاد فیلد؛ بازگشایی نیازمند تصمیم جدا

**پیشنهادی؛ تصویب نشده** — `POST /api/reviewer/field-corrections/{taskId}/decision`

| موضوع | قرارداد |
|---|---|
| عملیات | E07 |
| نقش | کارشناس دارای ارجاع فعال |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | taskId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema FieldDecision |
| خروجی | Acknowledgement؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503, 428, 412 |
| اعتبارسنجی | همان task/proposalVersion و مجوز؛ کد فعلی approve دارد، reopen هنوز تصمیم باز است و مسیر فرضی اجراشده نیست. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | expectedVersion یا If-Match باید با نسخه سرور تطبیق کند؛ transition و idempotency و audit در یک تراکنش SQL؛ بایت فایل تراکنش SQL نیست |
| SQL | AuditLogs, CorrectionItems, IdempotencyRecords, Inspections, Vehicles |
| خواندن جدول | CorrectionItems, IdempotencyRecords, Inspections, Vehicles |
| نوشتن جدول | AuditLogs, CorrectionItems, IdempotencyRecords, Inspections, Vehicles |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/review-operations/repository.ts |
| وابستگی | A04/A05، D02؛ ارجاع و نسخه پرونده |

### ساختار درخواست RV06

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| decision | const approved | بله | {"const":"approved"} |
| proposalVersion | string | بله | {"minLength":1,"maxLength":100} |
| expectedVersion | string | بله | {"minLength":1,"maxLength":100} |

### مثال درخواست RV06

```json
{
  "decision": "approved",
  "proposalVersion": "AAAAAAAAB9E=",
  "expectedVersion": "AAAAAAAAB9E="
}
```

### پاسخ RV06

```json
{
  "acknowledged": true,
  "version": "AAAAAAAAB9E=",
  "at": "2026-10-26T09:00:00Z"
}
```

### نمونه خطای RV06

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## RV07 — یادداشت صرفاً کارکنان

**پیشنهادی؛ تصویب نشده** — `POST /api/reviewer/cases/{caseId}/notes`

| موضوع | قرارداد |
|---|---|
| عملیات | E08 |
| نقش | کارشناس دارای ارجاع فعال |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | caseId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema NoteRequest |
| خروجی | Acknowledgement؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503, 428, 412 |
| اعتبارسنجی | متن محدود و private واقعی، اختیار مشاهده/نوشتن و نسخه؛ در DTO مشتری یا گزارش عمومی نیاید. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | expectedVersion یا If-Match باید با نسخه سرور تطبیق کند؛ transition و idempotency و audit در یک تراکنش SQL؛ بایت فایل تراکنش SQL نیست |
| SQL | AuditLogs, IdempotencyRecords, InternalNotes |
| خواندن جدول | IdempotencyRecords, InternalNotes |
| نوشتن جدول | AuditLogs, IdempotencyRecords, InternalNotes |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/review-operations/repository.ts |
| وابستگی | A04/A05، D02؛ ارجاع و نسخه پرونده |

### ساختار درخواست RV07

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| text | string | بله | {"minLength":1,"maxLength":4000} |
| expectedVersion | string | بله | {"minLength":1,"maxLength":100} |

### مثال درخواست RV07

```json
{
  "text": "یادداشت نمونه برای کارکنان؛ عمومی نیست.",
  "expectedVersion": "AAAAAAAAB9E="
}
```

### پاسخ RV07

```json
{
  "acknowledged": true,
  "version": "AAAAAAAAB9E=",
  "at": "2026-10-26T09:00:00Z"
}
```

### نمونه خطای RV07

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## RV08 — تصمیم جداگانه کل بازدید

**پیشنهادی؛ تصویب نشده** — `POST /api/reviewer/cases/{caseId}/decision`

| موضوع | قرارداد |
|---|---|
| عملیات | E09 |
| نقش | کارشناس دارای ارجاع فعال |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | caseId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema FinalDecision |
| خروجی | Acknowledgement؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503, 428, 412 |
| اعتبارسنجی | تصمیم کل جدا از تک‌مدرک؛ approved فقط پس از آمادگی همه اقلام؛ rejected نیازمند دلیل؛ تأیید outbox می‌سازد نه FORWARDED. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | expectedVersion یا If-Match باید با نسخه سرور تطبیق کند؛ transition و idempotency و audit در یک تراکنش SQL؛ بایت فایل تراکنش SQL نیست |
| SQL | AuditLogs, ForwardingJobs, IdempotencyRecords, InspectionReviews, InspectionStatusHistory, Inspections |
| خواندن جدول | ForwardingJobs, IdempotencyRecords, InspectionReviews, Inspections |
| نوشتن جدول | AuditLogs, ForwardingJobs, IdempotencyRecords, InspectionReviews, InspectionStatusHistory, Inspections |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/review-operations/repository.ts |
| وابستگی | A04/A05، D02؛ ارجاع و نسخه پرونده |

### ساختار درخواست RV08

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| decision | approved / rejected | بله | {"enum":["approved","rejected"]} |
| customerReason | string | اختیاری | {"maxLength":2000,"minLength":1} |
| expectedVersion | string | بله | {"minLength":1,"maxLength":100} |

### مثال درخواست RV08

```json
{
  "decision": "approved",
  "expectedVersion": "AAAAAAAAB9E="
}
```

### پاسخ RV08

```json
{
  "acknowledged": true,
  "version": "AAAAAAAAB9E=",
  "at": "2026-10-26T09:00:00Z"
}
```

### نمونه خطای RV08

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## RV09 — تاریخچه صفحه‌بندی‌شده نسخه و تصمیم

**پیشنهادی؛ تصویب نشده** — `GET /api/reviewer/cases/{caseId}/history`

| موضوع | قرارداد |
|---|---|
| عملیات | E10 |
| نقش | کارشناس دارای ارجاع یا مدیر دارای مجوز خواندن؛ بدون حق تصمیم ضمنی |
| احراز هویت | نشست کارکنان؛ کارشناس دارای ارجاع یا مدیر دارای مجوز خواندن همان پرونده. پاسخ براساس نقش پالایش شود؛ یادداشت خصوصی فقط با اختیار صریح و تصمیم فقط برای کارشناس مجاز است. |
| ورودی مسیر | caseId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | cursor: string اختیاری، opaque و scope-bound؛ pageSize: integer از 1 تا 100؛ پیش‌فرض 20؛ sort: whitelist، ترتیب پایدار با شناسه نهایی |
| سرآیند | Accept: application/json |
| بدنه | ندارد |
| خروجی | HistoryPage؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503 |
| اعتبارسنجی | مجوز خواندن پرونده، cursor و projection نقش؛ نسخه‌ها و تصمیم‌ها حذف نشوند؛ private notes به نقش غیرمجاز نرسند. |
| تکرار امن | بدون اثر تجاری؛ تکرار خواندن امن است، حساس‌ها no-store و بدون cache عمومی |
| هم‌زمانی | خواندن ETag/version؛ GET هیچ بازدید یا تصمیمی ایجاد نمی‌کند |
| SQL | AuditLogs, EvidenceReviews, EvidenceVersions, InspectionStatusHistory |
| خواندن جدول | EvidenceReviews, EvidenceVersions, InspectionStatusHistory |
| نوشتن جدول | ندارد |
| اثر فایل | فایل/مشتق خصوصی همان نسخه با مجوز؛ فقط در صورت نیاز و بدون بارگذاری گروهی بایت‌ها. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/review-operations/repository.ts |
| وابستگی | A04/A05، D02؛ ارجاع و نسخه پرونده |

### پاسخ RV09

```json
{
  "items": [],
  "nextCursor": null
}
```

### نمونه خطای RV09

```json
{
  "type": "urn:inspection:problem:NOT_FOUND",
  "title": "منبع مجاز پیدا نشد.",
  "status": 404,
  "code": "NOT_FOUND",
  "traceId": "trace-example",
  "errors": {}
}
```

## AD01 — قالب‌ها، کارکنان و سیاست در محدوده مجوز

**پیشنهادی؛ تصویب نشده** — `GET /api/admin/workspace`

| موضوع | قرارداد |
|---|---|
| عملیات | F01, F10, E04 |
| نقش | خواندن مدیریت در محدوده مجوز |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | ندارد |
| query | ندارد |
| سرآیند | Accept: application/json |
| بدنه | ندارد |
| خروجی | AdminWorkspace؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503 |
| اعتبارسنجی | permission‌های مجزا، نسخه workspace و projection مجاز؛ مدیر همان نصب، نه مالک کلید مرکزی نقشه.؛ staffId همان نصب، نقش/فعال‌بودن مجاز و جلوگیری از ارتقای بی‌اختیار؛ هویت SSO در Frontend ساخته نشود.؛ mode از manual/random، ظرفیت صحیح و نسخه workspace؛ random در سرور و اختیار مدیریت لازم. |
| تکرار امن | بدون اثر تجاری؛ تکرار خواندن امن است، حساس‌ها no-store و بدون cache عمومی |
| هم‌زمانی | خواندن ETag/version؛ GET هیچ بازدید یا تصمیمی ایجاد نمی‌کند |
| SQL | AuditLogs, IdempotencyRecords, InspectionTemplates, StaffOperationsSettings, StaffRoleAssignments, StaffUsers |
| خواندن جدول | IdempotencyRecords, StaffOperationsSettings, StaffUsers, InspectionTemplates, StaffRoleAssignments |
| نوشتن جدول | AuditLogs, IdempotencyRecords, StaffOperationsSettings, StaffUsers, StaffRoleAssignments |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه.؛ ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه.؛ ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/admin/repository.ts؛ src/features/review-operations/repository.ts |
| وابستگی | A04/A05؛ مجوز و CAS تنظیمات/قالب؛ A04/A05، D02؛ ارجاع و نسخه پرونده |

### پاسخ AD01

```json
{
  "templates": [
    {
      "id": "template-example",
      "title": "بازدید بدنه سدان نمونه",
      "partner": "کارگزاری نمونه",
      "currentPublishedId": "template-version-example",
      "versions": [
        {
          "id": "template-version-example",
          "version": 2,
          "revision": 1,
          "state": "published",
          "snapshot": {
            "photoPolicyVersion": 2,
            "templateId": "body-image-guided",
            "templateVersion": 2,
            "sections": [
              {
                "id": "right",
                "title": "نمای راست",
                "order": 1,
                "photoRequirements": [
                  {
                    "id": "front-45-right",
                    "title": "جلو ۴۵° راست",
                    "description": "جلوی خودرو و سمت راست به صورت کامل دیده شود.",
                    "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-right.webp",
                    "instructions": [
                      "جلوی خودرو و سمت راست به طور کامل داخل کادر باشد.",
                      "حدود ۳ متر از خودرو فاصله بگیرید.",
                      "از زاویه ۴۵ درجه سمت راست عکس بگیرید."
                    ],
                    "distance": "۳ متر",
                    "height": "کمر",
                    "orientation": "landscape",
                    "required": true,
                    "status": "pending",
                    "checks": [
                      "واضح",
                      "نور مناسب",
                      "خودرو کامل در کادر"
                    ],
                    "guidanceTopics": [
                      "frame",
                      "distance",
                      "angle"
                    ]
                  },
                  {
                    "id": "back-45-right",
                    "title": "عقب ۴۵° راست",
                    "description": "عقب خودرو و سمت راست به صورت کامل دیده شود.",
                    "sampleImage": "/assets/inspection-vehicle/photo-guides/back-45-right.webp",
                    "instructions": [
                      "تمام قسمت عقب و سمت راست خودرو داخل کادر باشد.",
                      "خودرو را از زاویه ۴۵ درجه ثبت کنید.",
                      "در نور کافی و بدون سایه شدید عکاسی کنید."
                    ],
                    "distance": "۳ متر",
                    "height": "کمر",
                    "orientation": "landscape",
                    "required": true,
                    "status": "pending",
                    "checks": [
                      "واضح",
                      "نور مناسب",
                      "خودرو کامل در کادر"
                    ],
                    "guidanceTopics": [
                      "frame",
                      "angle",
                      "glare"
                    ]
                  }
                ]
              },
              {
                "id": "left",
                "title": "نمای چپ",
                "order": 2,
                "photoRequirements": [
                  {
                    "id": "front-45-left",
                    "title": "جلو ۴۵° چپ",
                    "description": "جلوی خودرو و سمت چپ به صورت کامل دیده شود.",
                    "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-left.webp",
                    "instructions": [
                      "جلوی خودرو و سمت چپ به طور کامل داخل کادر باشد.",
                      "حدود ۳ متر از خودرو فاصله بگیرید.",
                      "از زاویه ۴۵ درجه سمت چپ عکس بگیرید."
                    ],
                    "distance": "۳ متر",
                    "height": "کمر",
                    "orientation": "landscape",
                    "required": true,
                    "status": "pending",
                    "checks": [
                      "واضح",
                      "نور مناسب",
                      "خودرو کامل در کادر"
                    ],
                    "guidanceTopics": [
                      "frame",
                      "distance",
                      "angle"
                    ]
                  },
                  {
                    "id": "back-45-left",
                    "title": "عقب ۴۵° چپ",
                    "description": "عقب خودرو و سمت چپ به صورت کامل دیده شود.",
                    "sampleImage": "/assets/inspection-vehicle/photo-guides/back-45-left.webp",
                    "instructions": [
                      "تمام قسمت عقب و سمت چپ خودرو داخل کادر باشد.",
                      "خودرو را از زاویه ۴۵ درجه ثبت کنید.",
                      "در نور کافی و بدون سایه شدید عکاسی کنید."
                    ],
                    "distance": "۳ متر",
                    "height": "کمر",
                    "orientation": "landscape",
                    "required": true,
                    "status": "pending",
                    "checks": [
                      "واضح",
                      "نور مناسب",
                      "خودرو کامل در کادر"
                    ],
                    "guidanceTopics": [
                      "frame",
                      "angle",
                      "glare"
                    ]
                  }
                ]
              },
              {
                "id": "front",
                "title": "جلو",
                "order": 3,
                "photoRequirements": [
                  {
                    "id": "front-plate",
                    "title": "نمای مستقیم جلو با پلاک",
                    "description": "یک عکس مستقیم از نمای جلوی خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.",
                    "sampleImage": "/assets/inspection-vehicle/photo-guides/front-plate.webp",
                    "instructions": [
                      "مستقیم روبه‌روی خودرو بایستید؛ خودرو وسط کادر باشد.",
                      "نمای کامل جلو را بدون برش و زاویه شدید ثبت کنید.",
                      "پلاک بدون بازتاب نور و کاملاً خوانا باشد."
                    ],
                    "distance": "۳ متر",
                    "height": "چراغ‌ها",
                    "orientation": "landscape",
                    "required": true,
                    "status": "pending",
                    "checks": [
                      "واضح",
                      "نور مناسب",
                      "پلاک خوانا است"
                    ],
                    "guidanceTopics": [
                      "angle",
                      "frame",
                      "text"
                    ]
                  }
                ]
              },
              {
                "id": "rear",
                "title": "عقب",
                "order": 4,
                "photoRequirements": [
                  {
                    "id": "rear-plate",
                    "title": "نمای مستقیم عقب با پلاک",
                    "description": "یک عکس مستقیم از نمای عقب خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.",
                    "sampleImage": "/assets/inspection-vehicle/photo-guides/rear-plate.webp",
                    "instructions": [
                      "مستقیم پشت خودرو بایستید؛ خودرو وسط کادر باشد.",
                      "تمام نمای عقب بدون برش و زاویه شدید داخل کادر باشد.",
                      "پلاک کاملاً خوانا و بدون بازتاب باشد."
                    ],
                    "distance": "۳ متر",
                    "height": "چراغ‌ها",
                    "orientation": "landscape",
                    "required": true,
                    "status": "pending",
                    "checks": [
                      "واضح",
                      "نور مناسب",
                      "پلاک خوانا است"
                    ],
                    "guidanceTopics": [
                      "angle",
                      "frame",
                      "text"
                    ]
                  }
                ]
              },
              {
                "id": "cabin",
                "title": "کابین",
                "order": 5,
                "photoRequirements": [
                  {
                    "id": "odometer-on",
                    "title": "کیلومترشمار",
                    "description": "خودرو را روشن کنید و تصویری واضح از کیلومترشمار بگیرید.",
                    "sampleImage": "/assets/inspection-vehicle/photo-guides/odometer-on.webp",
                    "instructions": [
                      "خودرو را روشن و در حالت توقف نگه دارید.",
                      "تمام صفحه کیلومترشمار در کادر باشد.",
                      "عدد کیلومتر خوانا باشد؛ از بازتاب نور جلوگیری کنید."
                    ],
                    "distance": "نزدیک",
                    "height": "داشبورد",
                    "orientation": "landscape",
                    "required": true,
                    "status": "pending",
                    "checks": [
                      "واضح",
                      "نور مناسب",
                      "عدد کیلومتر خوانا است"
                    ],
                    "guidanceTopics": [
                      "ignition",
                      "frame",
                      "glare"
                    ]
                  },
                  {
                    "id": "driver-interior",
                    "title": "نمای داخل کابین از سمت راننده",
                    "description": "از سمت راننده تصویری بگیرید که فضای داخلی خودرو به صورت واضح دیده شود.",
                    "sampleImage": "/assets/inspection-vehicle/photo-guides/driver-interior.webp",
                    "instructions": [
                      "درِ سمت راننده را باز کنید.",
                      "فرمان، داشبورد و صندلی‌ها دیده شوند.",
                      "خیلی نزدیک نشوید؛ فضای داخلی کامل دیده شود."
                    ],
                    "distance": "۱ متر",
                    "height": "درِ راننده",
                    "orientation": "landscape",
                    "required": true,
                    "status": "pending",
                    "checks": [
                      "واضح",
                      "نور مناسب",
                      "کابین کامل در کادر"
                    ],
                    "guidanceTopics": [
                      "interior",
                      "frame",
                      "distance"
                    ]
                  }
                ]
              },
              {
                "id": "engine-details",
                "title": "موتور و مشخصات",
                "order": 6,
                "photoRequirements": [
                  {
                    "id": "engine-bay",
                    "title": "محفظه موتور",
                    "description": "کاپوت را باز کنید و یک تصویر کامل و واضح از محفظه موتور بگیرید.",
                    "sampleImage": "/assets/inspection-vehicle/photo-guides/engine-bay.webp",
                    "instructions": [
                      "خودرو متوقف باشد؛ کاپوت را کاملاً و ایمن باز کنید.",
                      "تمام محفظه موتور دیده شود.",
                      "گوشی ثابت و تصویر بدون تاری باشد."
                    ],
                    "distance": "۱ متر",
                    "height": "سینه",
                    "orientation": "landscape",
                    "required": true,
                    "status": "pending",
                    "checks": [
                      "واضح",
                      "نور مناسب",
                      "محفظه کامل در کادر"
                    ],
                    "guidanceTopics": [
                      "hood",
                      "frame",
                      "steady"
                    ]
                  },
                  {
                    "id": "spec-plate",
                    "title": "محل شماره شاسی خودرو",
                    "description": "شماره شاسی خودرو — انتخاب یکی از چهار گزینه. فقط یک تصویر لازم است.",
                    "sampleImage": "/assets/inspection-vehicle/photo-guides/spec-plate.webp",
                    "instructions": [
                      "از نزدیک روی پلاک مشخصات فوکوس کنید.",
                      "تمام متن پلاک داخل کادر باشد.",
                      "نوشته‌ها خوانا و بدون بازتاب نور باشند."
                    ],
                    "distance": "۳۰ سانتی‌متر",
                    "height": "هم‌سطح پلاک",
                    "orientation": "landscape",
                    "choice": {
                      "groupId": "vehicle-identification",
                      "alternatives": [
                        "pillar",
                        "engine",
                        "seat",
                        "windshield"
                      ]
                    },
                    "required": true,
                    "status": "pending",
                    "checks": [
                      "واضح",
                      "نور مناسب",
                      "اطلاعات قابل خواندن است"
                    ],
                    "guidanceTopics": [
                      "text",
                      "frame",
                      "glare"
                    ]
                  }
                ]
              },
              {
                "id": "roof",
                "title": "سقف",
                "order": 7,
                "photoRequirements": [
                  {
                    "id": "car-roof",
                    "title": "نمای سقف",
                    "description": "تمام سطح سقف خودرو را در تصویر نشان دهید.",
                    "sampleImage": "/assets/inspection-vehicle/photo-guides/car-roof.webp",
                    "instructions": [
                      "از موقعیتی ایمن، گوشی را بالاتر بگیرید.",
                      "بیشترین سطح سقف و گوشه‌های اصلی در کادر باشند.",
                      "برای عکاسی روی خودرو نایستید."
                    ],
                    "distance": "۱ متر",
                    "height": "بالاتر از سقف",
                    "orientation": "landscape",
                    "required": true,
                    "status": "pending",
                    "checks": [
                      "واضح",
                      "نور مناسب",
                      "سقف کامل در کادر"
                    ],
                    "guidanceTopics": [
                      "roof",
                      "frame",
                      "steady"
                    ]
                  }
                ]
              }
            ],
            "captureRequirements": {
              "odometerRequirementId": "odometer-on",
              "video360Required": true
            }
          },
          "updatedAt": "2026-10-27T08:30:00Z",
          "updatedBy": "staff-example",
          "publishedAt": "2026-10-27T08:30:00Z"
        }
      ]
    }
  ],
  "staff": [
    {
      "staffId": "staff-example",
      "name": "کارشناس نمونه",
      "identifier": "source-subject-example",
      "role": "reviewer",
      "active": true,
      "capacity": 8
    }
  ],
  "version": "AAAAAAAAB9E=",
  "audit": [
    {
      "id": "audit-example",
      "at": "2026-10-27T08:30:00Z",
      "actor": "staff-example",
      "action": "template.published",
      "resource": "template-version-example"
    }
  ],
  "webhooks": [
    {
      "id": "webhook-example",
      "label": "اعلان ارسال بازدید",
      "endpoint": "https://brokerage.example.invalid/events/inspection",
      "event": "inspection.submitted",
      "enabled": false
    }
  ],
  "assignmentPolicy": {
    "mode": "manual",
    "capacities": [],
    "expectedVersion": "AAAAAAAAB9E="
  }
}
```

### نمونه خطای AD01

```json
{
  "type": "urn:inspection:problem:NOT_FOUND",
  "title": "منبع مجاز پیدا نشد.",
  "status": 404,
  "code": "NOT_FOUND",
  "traceId": "trace-example",
  "errors": {}
}
```

## AD02 — ایجاد قالب یا draft بر پایه نسخه موجود

**پیشنهادی؛ تصویب نشده** — `POST /api/admin/capture-templates`

| موضوع | قرارداد |
|---|---|
| عملیات | F02 |
| نقش | ویرایشگر مجاز پیش‌نویس یا مدیر |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | ندارد |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema TemplateDraftRequest |
| خروجی | CapturePlan؛ تعریف دقیق در schemas.json |
| کد موفقیت | 201, 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503 |
| اعتبارسنجی | عنوان و قالب مبنا معتبر و نسخه جدید مستقل؛ هیچ قالب پین‌شده تاریخی درجا تغییر نکند. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | expectedVersion یا If-Match باید با نسخه سرور تطبیق کند؛ transition و idempotency و audit در یک تراکنش SQL؛ بایت فایل تراکنش SQL نیست |
| SQL | AuditLogs, EvidenceRequirements, IdempotencyRecords, InspectionTemplates, RequirementAlternatives |
| خواندن جدول | EvidenceRequirements, IdempotencyRecords, InspectionTemplates, RequirementAlternatives |
| نوشتن جدول | AuditLogs, EvidenceRequirements, IdempotencyRecords, InspectionTemplates, RequirementAlternatives |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/admin/repository.ts |
| وابستگی | A04/A05؛ مجوز و CAS تنظیمات/قالب |

### ساختار درخواست AD02

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| title | string | بله | {"minLength":1,"maxLength":100} |
| templateId | string | اختیاری | {"minLength":1,"maxLength":160} |
| baseVersion | integer | اختیاری | {"minimum":1} |

### مثال درخواست AD02

```json
{
  "title": "نمونه قراردادی"
}
```

### پاسخ AD02

```json
{
  "photoPolicyVersion": 2,
  "templateId": "body-image-guided",
  "templateVersion": 2,
  "sections": [
    {
      "id": "right",
      "title": "نمای راست",
      "order": 1,
      "photoRequirements": [
        {
          "id": "front-45-right",
          "title": "جلو ۴۵° راست",
          "description": "جلوی خودرو و سمت راست به صورت کامل دیده شود.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-right.webp",
          "instructions": [
            "جلوی خودرو و سمت راست به طور کامل داخل کادر باشد.",
            "حدود ۳ متر از خودرو فاصله بگیرید.",
            "از زاویه ۴۵ درجه سمت راست عکس بگیرید."
          ],
          "distance": "۳ متر",
          "height": "کمر",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "خودرو کامل در کادر"
          ],
          "guidanceTopics": [
            "frame",
            "distance",
            "angle"
          ]
        },
        {
          "id": "back-45-right",
          "title": "عقب ۴۵° راست",
          "description": "عقب خودرو و سمت راست به صورت کامل دیده شود.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/back-45-right.webp",
          "instructions": [
            "تمام قسمت عقب و سمت راست خودرو داخل کادر باشد.",
            "خودرو را از زاویه ۴۵ درجه ثبت کنید.",
            "در نور کافی و بدون سایه شدید عکاسی کنید."
          ],
          "distance": "۳ متر",
          "height": "کمر",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "خودرو کامل در کادر"
          ],
          "guidanceTopics": [
            "frame",
            "angle",
            "glare"
          ]
        }
      ]
    },
    {
      "id": "left",
      "title": "نمای چپ",
      "order": 2,
      "photoRequirements": [
        {
          "id": "front-45-left",
          "title": "جلو ۴۵° چپ",
          "description": "جلوی خودرو و سمت چپ به صورت کامل دیده شود.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-left.webp",
          "instructions": [
            "جلوی خودرو و سمت چپ به طور کامل داخل کادر باشد.",
            "حدود ۳ متر از خودرو فاصله بگیرید.",
            "از زاویه ۴۵ درجه سمت چپ عکس بگیرید."
          ],
          "distance": "۳ متر",
          "height": "کمر",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "خودرو کامل در کادر"
          ],
          "guidanceTopics": [
            "frame",
            "distance",
            "angle"
          ]
        },
        {
          "id": "back-45-left",
          "title": "عقب ۴۵° چپ",
          "description": "عقب خودرو و سمت چپ به صورت کامل دیده شود.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/back-45-left.webp",
          "instructions": [
            "تمام قسمت عقب و سمت چپ خودرو داخل کادر باشد.",
            "خودرو را از زاویه ۴۵ درجه ثبت کنید.",
            "در نور کافی و بدون سایه شدید عکاسی کنید."
          ],
          "distance": "۳ متر",
          "height": "کمر",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "خودرو کامل در کادر"
          ],
          "guidanceTopics": [
            "frame",
            "angle",
            "glare"
          ]
        }
      ]
    },
    {
      "id": "front",
      "title": "جلو",
      "order": 3,
      "photoRequirements": [
        {
          "id": "front-plate",
          "title": "نمای مستقیم جلو با پلاک",
          "description": "یک عکس مستقیم از نمای جلوی خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/front-plate.webp",
          "instructions": [
            "مستقیم روبه‌روی خودرو بایستید؛ خودرو وسط کادر باشد.",
            "نمای کامل جلو را بدون برش و زاویه شدید ثبت کنید.",
            "پلاک بدون بازتاب نور و کاملاً خوانا باشد."
          ],
          "distance": "۳ متر",
          "height": "چراغ‌ها",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "پلاک خوانا است"
          ],
          "guidanceTopics": [
            "angle",
            "frame",
            "text"
          ]
        }
      ]
    },
    {
      "id": "rear",
      "title": "عقب",
      "order": 4,
      "photoRequirements": [
        {
          "id": "rear-plate",
          "title": "نمای مستقیم عقب با پلاک",
          "description": "یک عکس مستقیم از نمای عقب خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/rear-plate.webp",
          "instructions": [
            "مستقیم پشت خودرو بایستید؛ خودرو وسط کادر باشد.",
            "تمام نمای عقب بدون برش و زاویه شدید داخل کادر باشد.",
            "پلاک کاملاً خوانا و بدون بازتاب باشد."
          ],
          "distance": "۳ متر",
          "height": "چراغ‌ها",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "پلاک خوانا است"
          ],
          "guidanceTopics": [
            "angle",
            "frame",
            "text"
          ]
        }
      ]
    },
    {
      "id": "cabin",
      "title": "کابین",
      "order": 5,
      "photoRequirements": [
        {
          "id": "odometer-on",
          "title": "کیلومترشمار",
          "description": "خودرو را روشن کنید و تصویری واضح از کیلومترشمار بگیرید.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/odometer-on.webp",
          "instructions": [
            "خودرو را روشن و در حالت توقف نگه دارید.",
            "تمام صفحه کیلومترشمار در کادر باشد.",
            "عدد کیلومتر خوانا باشد؛ از بازتاب نور جلوگیری کنید."
          ],
          "distance": "نزدیک",
          "height": "داشبورد",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "عدد کیلومتر خوانا است"
          ],
          "guidanceTopics": [
            "ignition",
            "frame",
            "glare"
          ]
        },
        {
          "id": "driver-interior",
          "title": "نمای داخل کابین از سمت راننده",
          "description": "از سمت راننده تصویری بگیرید که فضای داخلی خودرو به صورت واضح دیده شود.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/driver-interior.webp",
          "instructions": [
            "درِ سمت راننده را باز کنید.",
            "فرمان، داشبورد و صندلی‌ها دیده شوند.",
            "خیلی نزدیک نشوید؛ فضای داخلی کامل دیده شود."
          ],
          "distance": "۱ متر",
          "height": "درِ راننده",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "کابین کامل در کادر"
          ],
          "guidanceTopics": [
            "interior",
            "frame",
            "distance"
          ]
        }
      ]
    },
    {
      "id": "engine-details",
      "title": "موتور و مشخصات",
      "order": 6,
      "photoRequirements": [
        {
          "id": "engine-bay",
          "title": "محفظه موتور",
          "description": "کاپوت را باز کنید و یک تصویر کامل و واضح از محفظه موتور بگیرید.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/engine-bay.webp",
          "instructions": [
            "خودرو متوقف باشد؛ کاپوت را کاملاً و ایمن باز کنید.",
            "تمام محفظه موتور دیده شود.",
            "گوشی ثابت و تصویر بدون تاری باشد."
          ],
          "distance": "۱ متر",
          "height": "سینه",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "محفظه کامل در کادر"
          ],
          "guidanceTopics": [
            "hood",
            "frame",
            "steady"
          ]
        },
        {
          "id": "spec-plate",
          "title": "محل شماره شاسی خودرو",
          "description": "شماره شاسی خودرو — انتخاب یکی از چهار گزینه. فقط یک تصویر لازم است.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/spec-plate.webp",
          "instructions": [
            "از نزدیک روی پلاک مشخصات فوکوس کنید.",
            "تمام متن پلاک داخل کادر باشد.",
            "نوشته‌ها خوانا و بدون بازتاب نور باشند."
          ],
          "distance": "۳۰ سانتی‌متر",
          "height": "هم‌سطح پلاک",
          "orientation": "landscape",
          "choice": {
            "groupId": "vehicle-identification",
            "alternatives": [
              "pillar",
              "engine",
              "seat",
              "windshield"
            ]
          },
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "اطلاعات قابل خواندن است"
          ],
          "guidanceTopics": [
            "text",
            "frame",
            "glare"
          ]
        }
      ]
    },
    {
      "id": "roof",
      "title": "سقف",
      "order": 7,
      "photoRequirements": [
        {
          "id": "car-roof",
          "title": "نمای سقف",
          "description": "تمام سطح سقف خودرو را در تصویر نشان دهید.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/car-roof.webp",
          "instructions": [
            "از موقعیتی ایمن، گوشی را بالاتر بگیرید.",
            "بیشترین سطح سقف و گوشه‌های اصلی در کادر باشند.",
            "برای عکاسی روی خودرو نایستید."
          ],
          "distance": "۱ متر",
          "height": "بالاتر از سقف",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "سقف کامل در کادر"
          ],
          "guidanceTopics": [
            "roof",
            "frame",
            "steady"
          ]
        }
      ]
    }
  ],
  "captureRequirements": {
    "odometerRequirementId": "odometer-on",
    "video360Required": true
  }
}
```

### نمونه خطای AD02

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## AD03 — ذخیره draft با قفل نسخه

**پیشنهادی؛ تصویب نشده** — `PUT /api/admin/capture-templates/{templateId}/versions/{version}/draft`

| موضوع | قرارداد |
|---|---|
| عملیات | F03 |
| نقش | ویرایشگر مجاز پیش‌نویس یا مدیر |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | templateId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت؛ version: integer مثبت؛ نسخه immutable قالب |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema TemplateSaveRequest |
| خروجی | CapturePlan؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503, 428, 412 |
| اعتبارسنجی | Zod فعلی کامل شامل راهنماها، شناسه‌های یکتا، ۱۱ عکس و گروه یک‌ازچهار؛ expectedRevision و حالت draft. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | expectedVersion یا If-Match باید با نسخه سرور تطبیق کند؛ transition و idempotency و audit در یک تراکنش SQL؛ بایت فایل تراکنش SQL نیست |
| SQL | AuditLogs, EvidenceRequirements, IdempotencyRecords, InspectionTemplates, RequirementAlternatives |
| خواندن جدول | EvidenceRequirements, IdempotencyRecords, InspectionTemplates, RequirementAlternatives |
| نوشتن جدول | AuditLogs, EvidenceRequirements, IdempotencyRecords, InspectionTemplates, RequirementAlternatives |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/admin/repository.ts |
| وابستگی | A04/A05؛ مجوز و CAS تنظیمات/قالب |

### ساختار درخواست AD03

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| expectedVersion | string | بله | {"minLength":1,"maxLength":100} |
| template | CapturePlan | بله | {} |

### مثال درخواست AD03

```json
{
  "expectedVersion": "AAAAAAAAB9E=",
  "template": {
    "photoPolicyVersion": 2,
    "templateId": "body-image-guided",
    "templateVersion": 2,
    "sections": [
      {
        "id": "right",
        "title": "نمای راست",
        "order": 1,
        "photoRequirements": [
          {
            "id": "front-45-right",
            "title": "جلو ۴۵° راست",
            "description": "جلوی خودرو و سمت راست به صورت کامل دیده شود.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-right.webp",
            "instructions": [
              "جلوی خودرو و سمت راست به طور کامل داخل کادر باشد.",
              "حدود ۳ متر از خودرو فاصله بگیرید.",
              "از زاویه ۴۵ درجه سمت راست عکس بگیرید."
            ],
            "distance": "۳ متر",
            "height": "کمر",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "خودرو کامل در کادر"
            ],
            "guidanceTopics": [
              "frame",
              "distance",
              "angle"
            ]
          },
          {
            "id": "back-45-right",
            "title": "عقب ۴۵° راست",
            "description": "عقب خودرو و سمت راست به صورت کامل دیده شود.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/back-45-right.webp",
            "instructions": [
              "تمام قسمت عقب و سمت راست خودرو داخل کادر باشد.",
              "خودرو را از زاویه ۴۵ درجه ثبت کنید.",
              "در نور کافی و بدون سایه شدید عکاسی کنید."
            ],
            "distance": "۳ متر",
            "height": "کمر",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "خودرو کامل در کادر"
            ],
            "guidanceTopics": [
              "frame",
              "angle",
              "glare"
            ]
          }
        ]
      },
      {
        "id": "left",
        "title": "نمای چپ",
        "order": 2,
        "photoRequirements": [
          {
            "id": "front-45-left",
            "title": "جلو ۴۵° چپ",
            "description": "جلوی خودرو و سمت چپ به صورت کامل دیده شود.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-left.webp",
            "instructions": [
              "جلوی خودرو و سمت چپ به طور کامل داخل کادر باشد.",
              "حدود ۳ متر از خودرو فاصله بگیرید.",
              "از زاویه ۴۵ درجه سمت چپ عکس بگیرید."
            ],
            "distance": "۳ متر",
            "height": "کمر",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "خودرو کامل در کادر"
            ],
            "guidanceTopics": [
              "frame",
              "distance",
              "angle"
            ]
          },
          {
            "id": "back-45-left",
            "title": "عقب ۴۵° چپ",
            "description": "عقب خودرو و سمت چپ به صورت کامل دیده شود.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/back-45-left.webp",
            "instructions": [
              "تمام قسمت عقب و سمت چپ خودرو داخل کادر باشد.",
              "خودرو را از زاویه ۴۵ درجه ثبت کنید.",
              "در نور کافی و بدون سایه شدید عکاسی کنید."
            ],
            "distance": "۳ متر",
            "height": "کمر",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "خودرو کامل در کادر"
            ],
            "guidanceTopics": [
              "frame",
              "angle",
              "glare"
            ]
          }
        ]
      },
      {
        "id": "front",
        "title": "جلو",
        "order": 3,
        "photoRequirements": [
          {
            "id": "front-plate",
            "title": "نمای مستقیم جلو با پلاک",
            "description": "یک عکس مستقیم از نمای جلوی خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/front-plate.webp",
            "instructions": [
              "مستقیم روبه‌روی خودرو بایستید؛ خودرو وسط کادر باشد.",
              "نمای کامل جلو را بدون برش و زاویه شدید ثبت کنید.",
              "پلاک بدون بازتاب نور و کاملاً خوانا باشد."
            ],
            "distance": "۳ متر",
            "height": "چراغ‌ها",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "پلاک خوانا است"
            ],
            "guidanceTopics": [
              "angle",
              "frame",
              "text"
            ]
          }
        ]
      },
      {
        "id": "rear",
        "title": "عقب",
        "order": 4,
        "photoRequirements": [
          {
            "id": "rear-plate",
            "title": "نمای مستقیم عقب با پلاک",
            "description": "یک عکس مستقیم از نمای عقب خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/rear-plate.webp",
            "instructions": [
              "مستقیم پشت خودرو بایستید؛ خودرو وسط کادر باشد.",
              "تمام نمای عقب بدون برش و زاویه شدید داخل کادر باشد.",
              "پلاک کاملاً خوانا و بدون بازتاب باشد."
            ],
            "distance": "۳ متر",
            "height": "چراغ‌ها",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "پلاک خوانا است"
            ],
            "guidanceTopics": [
              "angle",
              "frame",
              "text"
            ]
          }
        ]
      },
      {
        "id": "cabin",
        "title": "کابین",
        "order": 5,
        "photoRequirements": [
          {
            "id": "odometer-on",
            "title": "کیلومترشمار",
            "description": "خودرو را روشن کنید و تصویری واضح از کیلومترشمار بگیرید.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/odometer-on.webp",
            "instructions": [
              "خودرو را روشن و در حالت توقف نگه دارید.",
              "تمام صفحه کیلومترشمار در کادر باشد.",
              "عدد کیلومتر خوانا باشد؛ از بازتاب نور جلوگیری کنید."
            ],
            "distance": "نزدیک",
            "height": "داشبورد",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "عدد کیلومتر خوانا است"
            ],
            "guidanceTopics": [
              "ignition",
              "frame",
              "glare"
            ]
          },
          {
            "id": "driver-interior",
            "title": "نمای داخل کابین از سمت راننده",
            "description": "از سمت راننده تصویری بگیرید که فضای داخلی خودرو به صورت واضح دیده شود.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/driver-interior.webp",
            "instructions": [
              "درِ سمت راننده را باز کنید.",
              "فرمان، داشبورد و صندلی‌ها دیده شوند.",
              "خیلی نزدیک نشوید؛ فضای داخلی کامل دیده شود."
            ],
            "distance": "۱ متر",
            "height": "درِ راننده",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "کابین کامل در کادر"
            ],
            "guidanceTopics": [
              "interior",
              "frame",
              "distance"
            ]
          }
        ]
      },
      {
        "id": "engine-details",
        "title": "موتور و مشخصات",
        "order": 6,
        "photoRequirements": [
          {
            "id": "engine-bay",
            "title": "محفظه موتور",
            "description": "کاپوت را باز کنید و یک تصویر کامل و واضح از محفظه موتور بگیرید.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/engine-bay.webp",
            "instructions": [
              "خودرو متوقف باشد؛ کاپوت را کاملاً و ایمن باز کنید.",
              "تمام محفظه موتور دیده شود.",
              "گوشی ثابت و تصویر بدون تاری باشد."
            ],
            "distance": "۱ متر",
            "height": "سینه",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "محفظه کامل در کادر"
            ],
            "guidanceTopics": [
              "hood",
              "frame",
              "steady"
            ]
          },
          {
            "id": "spec-plate",
            "title": "محل شماره شاسی خودرو",
            "description": "شماره شاسی خودرو — انتخاب یکی از چهار گزینه. فقط یک تصویر لازم است.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/spec-plate.webp",
            "instructions": [
              "از نزدیک روی پلاک مشخصات فوکوس کنید.",
              "تمام متن پلاک داخل کادر باشد.",
              "نوشته‌ها خوانا و بدون بازتاب نور باشند."
            ],
            "distance": "۳۰ سانتی‌متر",
            "height": "هم‌سطح پلاک",
            "orientation": "landscape",
            "choice": {
              "groupId": "vehicle-identification",
              "alternatives": [
                "pillar",
                "engine",
                "seat",
                "windshield"
              ]
            },
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "اطلاعات قابل خواندن است"
            ],
            "guidanceTopics": [
              "text",
              "frame",
              "glare"
            ]
          }
        ]
      },
      {
        "id": "roof",
        "title": "سقف",
        "order": 7,
        "photoRequirements": [
          {
            "id": "car-roof",
            "title": "نمای سقف",
            "description": "تمام سطح سقف خودرو را در تصویر نشان دهید.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/car-roof.webp",
            "instructions": [
              "از موقعیتی ایمن، گوشی را بالاتر بگیرید.",
              "بیشترین سطح سقف و گوشه‌های اصلی در کادر باشند.",
              "برای عکاسی روی خودرو نایستید."
            ],
            "distance": "۱ متر",
            "height": "بالاتر از سقف",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "سقف کامل در کادر"
            ],
            "guidanceTopics": [
              "roof",
              "frame",
              "steady"
            ]
          }
        ]
      }
    ],
    "captureRequirements": {
      "odometerRequirementId": "odometer-on",
      "video360Required": true
    }
  }
}
```

### پاسخ AD03

```json
{
  "photoPolicyVersion": 2,
  "templateId": "body-image-guided",
  "templateVersion": 2,
  "sections": [
    {
      "id": "right",
      "title": "نمای راست",
      "order": 1,
      "photoRequirements": [
        {
          "id": "front-45-right",
          "title": "جلو ۴۵° راست",
          "description": "جلوی خودرو و سمت راست به صورت کامل دیده شود.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-right.webp",
          "instructions": [
            "جلوی خودرو و سمت راست به طور کامل داخل کادر باشد.",
            "حدود ۳ متر از خودرو فاصله بگیرید.",
            "از زاویه ۴۵ درجه سمت راست عکس بگیرید."
          ],
          "distance": "۳ متر",
          "height": "کمر",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "خودرو کامل در کادر"
          ],
          "guidanceTopics": [
            "frame",
            "distance",
            "angle"
          ]
        },
        {
          "id": "back-45-right",
          "title": "عقب ۴۵° راست",
          "description": "عقب خودرو و سمت راست به صورت کامل دیده شود.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/back-45-right.webp",
          "instructions": [
            "تمام قسمت عقب و سمت راست خودرو داخل کادر باشد.",
            "خودرو را از زاویه ۴۵ درجه ثبت کنید.",
            "در نور کافی و بدون سایه شدید عکاسی کنید."
          ],
          "distance": "۳ متر",
          "height": "کمر",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "خودرو کامل در کادر"
          ],
          "guidanceTopics": [
            "frame",
            "angle",
            "glare"
          ]
        }
      ]
    },
    {
      "id": "left",
      "title": "نمای چپ",
      "order": 2,
      "photoRequirements": [
        {
          "id": "front-45-left",
          "title": "جلو ۴۵° چپ",
          "description": "جلوی خودرو و سمت چپ به صورت کامل دیده شود.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-left.webp",
          "instructions": [
            "جلوی خودرو و سمت چپ به طور کامل داخل کادر باشد.",
            "حدود ۳ متر از خودرو فاصله بگیرید.",
            "از زاویه ۴۵ درجه سمت چپ عکس بگیرید."
          ],
          "distance": "۳ متر",
          "height": "کمر",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "خودرو کامل در کادر"
          ],
          "guidanceTopics": [
            "frame",
            "distance",
            "angle"
          ]
        },
        {
          "id": "back-45-left",
          "title": "عقب ۴۵° چپ",
          "description": "عقب خودرو و سمت چپ به صورت کامل دیده شود.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/back-45-left.webp",
          "instructions": [
            "تمام قسمت عقب و سمت چپ خودرو داخل کادر باشد.",
            "خودرو را از زاویه ۴۵ درجه ثبت کنید.",
            "در نور کافی و بدون سایه شدید عکاسی کنید."
          ],
          "distance": "۳ متر",
          "height": "کمر",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "خودرو کامل در کادر"
          ],
          "guidanceTopics": [
            "frame",
            "angle",
            "glare"
          ]
        }
      ]
    },
    {
      "id": "front",
      "title": "جلو",
      "order": 3,
      "photoRequirements": [
        {
          "id": "front-plate",
          "title": "نمای مستقیم جلو با پلاک",
          "description": "یک عکس مستقیم از نمای جلوی خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/front-plate.webp",
          "instructions": [
            "مستقیم روبه‌روی خودرو بایستید؛ خودرو وسط کادر باشد.",
            "نمای کامل جلو را بدون برش و زاویه شدید ثبت کنید.",
            "پلاک بدون بازتاب نور و کاملاً خوانا باشد."
          ],
          "distance": "۳ متر",
          "height": "چراغ‌ها",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "پلاک خوانا است"
          ],
          "guidanceTopics": [
            "angle",
            "frame",
            "text"
          ]
        }
      ]
    },
    {
      "id": "rear",
      "title": "عقب",
      "order": 4,
      "photoRequirements": [
        {
          "id": "rear-plate",
          "title": "نمای مستقیم عقب با پلاک",
          "description": "یک عکس مستقیم از نمای عقب خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/rear-plate.webp",
          "instructions": [
            "مستقیم پشت خودرو بایستید؛ خودرو وسط کادر باشد.",
            "تمام نمای عقب بدون برش و زاویه شدید داخل کادر باشد.",
            "پلاک کاملاً خوانا و بدون بازتاب باشد."
          ],
          "distance": "۳ متر",
          "height": "چراغ‌ها",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "پلاک خوانا است"
          ],
          "guidanceTopics": [
            "angle",
            "frame",
            "text"
          ]
        }
      ]
    },
    {
      "id": "cabin",
      "title": "کابین",
      "order": 5,
      "photoRequirements": [
        {
          "id": "odometer-on",
          "title": "کیلومترشمار",
          "description": "خودرو را روشن کنید و تصویری واضح از کیلومترشمار بگیرید.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/odometer-on.webp",
          "instructions": [
            "خودرو را روشن و در حالت توقف نگه دارید.",
            "تمام صفحه کیلومترشمار در کادر باشد.",
            "عدد کیلومتر خوانا باشد؛ از بازتاب نور جلوگیری کنید."
          ],
          "distance": "نزدیک",
          "height": "داشبورد",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "عدد کیلومتر خوانا است"
          ],
          "guidanceTopics": [
            "ignition",
            "frame",
            "glare"
          ]
        },
        {
          "id": "driver-interior",
          "title": "نمای داخل کابین از سمت راننده",
          "description": "از سمت راننده تصویری بگیرید که فضای داخلی خودرو به صورت واضح دیده شود.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/driver-interior.webp",
          "instructions": [
            "درِ سمت راننده را باز کنید.",
            "فرمان، داشبورد و صندلی‌ها دیده شوند.",
            "خیلی نزدیک نشوید؛ فضای داخلی کامل دیده شود."
          ],
          "distance": "۱ متر",
          "height": "درِ راننده",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "کابین کامل در کادر"
          ],
          "guidanceTopics": [
            "interior",
            "frame",
            "distance"
          ]
        }
      ]
    },
    {
      "id": "engine-details",
      "title": "موتور و مشخصات",
      "order": 6,
      "photoRequirements": [
        {
          "id": "engine-bay",
          "title": "محفظه موتور",
          "description": "کاپوت را باز کنید و یک تصویر کامل و واضح از محفظه موتور بگیرید.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/engine-bay.webp",
          "instructions": [
            "خودرو متوقف باشد؛ کاپوت را کاملاً و ایمن باز کنید.",
            "تمام محفظه موتور دیده شود.",
            "گوشی ثابت و تصویر بدون تاری باشد."
          ],
          "distance": "۱ متر",
          "height": "سینه",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "محفظه کامل در کادر"
          ],
          "guidanceTopics": [
            "hood",
            "frame",
            "steady"
          ]
        },
        {
          "id": "spec-plate",
          "title": "محل شماره شاسی خودرو",
          "description": "شماره شاسی خودرو — انتخاب یکی از چهار گزینه. فقط یک تصویر لازم است.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/spec-plate.webp",
          "instructions": [
            "از نزدیک روی پلاک مشخصات فوکوس کنید.",
            "تمام متن پلاک داخل کادر باشد.",
            "نوشته‌ها خوانا و بدون بازتاب نور باشند."
          ],
          "distance": "۳۰ سانتی‌متر",
          "height": "هم‌سطح پلاک",
          "orientation": "landscape",
          "choice": {
            "groupId": "vehicle-identification",
            "alternatives": [
              "pillar",
              "engine",
              "seat",
              "windshield"
            ]
          },
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "اطلاعات قابل خواندن است"
          ],
          "guidanceTopics": [
            "text",
            "frame",
            "glare"
          ]
        }
      ]
    },
    {
      "id": "roof",
      "title": "سقف",
      "order": 7,
      "photoRequirements": [
        {
          "id": "car-roof",
          "title": "نمای سقف",
          "description": "تمام سطح سقف خودرو را در تصویر نشان دهید.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/car-roof.webp",
          "instructions": [
            "از موقعیتی ایمن، گوشی را بالاتر بگیرید.",
            "بیشترین سطح سقف و گوشه‌های اصلی در کادر باشند.",
            "برای عکاسی روی خودرو نایستید."
          ],
          "distance": "۱ متر",
          "height": "بالاتر از سقف",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "سقف کامل در کادر"
          ],
          "guidanceTopics": [
            "roof",
            "frame",
            "steady"
          ]
        }
      ]
    }
  ],
  "captureRequirements": {
    "odometerRequirementId": "odometer-on",
    "video360Required": true
  }
}
```

### نمونه خطای AD03

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## AD04 — انتشار یا بایگانی immutable

**پیشنهادی؛ تصویب نشده** — `POST /api/admin/capture-templates/{templateId}/versions/{version}/publication`

| موضوع | قرارداد |
|---|---|
| عملیات | F04 |
| نقش | مدیر سایت همین نصب |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | templateId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت؛ version: integer مثبت؛ نسخه immutable قالب |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema PublicationRequest |
| خروجی | Acknowledgement؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503, 428, 412 |
| اعتبارسنجی | فقط draft معتبر منتشر یا نسخه مجاز بایگانی شود؛ قالب پین‌شده قابل خواندن بماند؛ CAS و audit. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | expectedVersion یا If-Match باید با نسخه سرور تطبیق کند؛ transition و idempotency و audit در یک تراکنش SQL؛ بایت فایل تراکنش SQL نیست |
| SQL | AuditLogs, IdempotencyRecords, InspectionTemplates |
| خواندن جدول | IdempotencyRecords, InspectionTemplates |
| نوشتن جدول | AuditLogs, IdempotencyRecords, InspectionTemplates |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/admin/repository.ts |
| وابستگی | A04/A05؛ مجوز و CAS تنظیمات/قالب |

### ساختار درخواست AD04

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| expectedVersion | string | بله | {"minLength":1,"maxLength":100} |
| action | publish / archive | بله | {"enum":["publish","archive"]} |

### مثال درخواست AD04

```json
{
  "expectedVersion": "AAAAAAAAB9E=",
  "action": "publish"
}
```

### پاسخ AD04

```json
{
  "acknowledged": true,
  "version": "AAAAAAAAB9E=",
  "at": "2026-10-26T09:00:00Z"
}
```

### نمونه خطای AD04

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## AD05 — workspace واحد تنظیمات

**پیشنهادی؛ تصویب نشده** — `GET /api/admin/site-settings`

| موضوع | قرارداد |
|---|---|
| عملیات | F06 |
| نقش | مدیر سایت همین نصب |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | ندارد |
| query | ندارد |
| سرآیند | Accept: application/json |
| بدنه | ندارد |
| خروجی | SettingsWorkspace؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503 |
| اعتبارسنجی | whitelist متن/برند، قالب، URL و contrast؛ API base و Neshan مرکزی از فرم عادی قابل تغییر نیستند؛ CAS draft. |
| تکرار امن | بدون اثر تجاری؛ تکرار خواندن امن است، حساس‌ها no-store و بدون cache عمومی |
| هم‌زمانی | خواندن ETag/version؛ GET هیچ بازدید یا تصمیمی ایجاد نمی‌کند |
| SQL | AuditLogs, IdempotencyRecords, SiteSettings, SiteSettingsAssetLinks, SiteSettingsVersions |
| خواندن جدول | IdempotencyRecords, SiteSettings, SiteSettingsAssetLinks, SiteSettingsVersions |
| نوشتن جدول | AuditLogs, IdempotencyRecords, SiteSettings, SiteSettingsAssetLinks, SiteSettingsVersions |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/config/site-settings.repository.ts |
| وابستگی | A04/A05؛ مجوز و CAS تنظیمات/قالب |

### پاسخ AD05

```json
{
  "published": {
    "schemaVersion": 1,
    "tenantId": "demo",
    "version": 2,
    "publishedAt": "2026-10-26T09:00:00Z",
    "identity": {
      "brokerageName": "کارگزاری نمونه",
      "appTitle": "بازدید خودرو",
      "logo": null,
      "favicon": null,
      "publicEmail": "support@example.invalid",
      "publicPhone": "نمونه قراردادی"
    },
    "theme": {
      "primary": "#047857",
      "secondary": "#475569",
      "background": "#FFFFFF",
      "neutral": "#64748B",
      "onPrimary": "#FFFFFF",
      "onBackground": "#0F172A",
      "accent": "#F59E0B",
      "haloColor": "#10B981",
      "haloIntensity": 35
    },
    "images": {
      "landing": null,
      "referral": null,
      "otp": null,
      "readiness": null,
      "consent": null,
      "submission": null
    },
    "application": {
      "apiBaseUrl": "/api/bazdid",
      "contractVersion": "1",
      "template": {
        "id": "body-image-guided",
        "version": 2
      },
      "features": {
        "nativeCaptureFallback": true,
        "additionalEvidence": true,
        "supportLink": false
      },
      "locationMap": {
        "enabled": true,
        "webMapKey": null,
        "mapType": "dreamy",
        "reverseGeocoding": "api",
        "initialViewport": {
          "latitude": 35.699739,
          "longitude": 51.338097,
          "zoom": 12
        }
      }
    }
  },
  "draft": {
    "schemaVersion": 1,
    "tenantId": "demo",
    "version": 2,
    "publishedAt": "2026-10-26T09:00:00Z",
    "identity": {
      "brokerageName": "کارگزاری نمونه",
      "appTitle": "بازدید خودرو",
      "logo": null,
      "favicon": null,
      "publicEmail": "support@example.invalid",
      "publicPhone": "نمونه قراردادی"
    },
    "theme": {
      "primary": "#047857",
      "secondary": "#475569",
      "background": "#FFFFFF",
      "neutral": "#64748B",
      "onPrimary": "#FFFFFF",
      "onBackground": "#0F172A",
      "accent": "#F59E0B",
      "haloColor": "#10B981",
      "haloIntensity": 35
    },
    "images": {
      "landing": null,
      "referral": null,
      "otp": null,
      "readiness": null,
      "consent": null,
      "submission": null
    },
    "application": {
      "apiBaseUrl": "/api/bazdid",
      "contractVersion": "1",
      "template": {
        "id": "body-image-guided",
        "version": 2
      },
      "features": {
        "nativeCaptureFallback": true,
        "additionalEvidence": true,
        "supportLink": false
      },
      "locationMap": {
        "enabled": true,
        "webMapKey": null,
        "mapType": "dreamy",
        "reverseGeocoding": "api",
        "initialViewport": {
          "latitude": 35.699739,
          "longitude": 51.338097,
          "zoom": 12
        }
      }
    }
  },
  "version": "AAAAAAAAB9E="
}
```

### نمونه خطای AD05

```json
{
  "type": "urn:inspection:problem:NOT_FOUND",
  "title": "منبع مجاز پیدا نشد.",
  "status": 404,
  "code": "NOT_FOUND",
  "traceId": "trace-example",
  "errors": {}
}
```

## AD06 — ذخیره برندینگ در همان مخزن

**پیشنهادی؛ تصویب نشده** — `PUT /api/admin/site-settings/draft`

| موضوع | قرارداد |
|---|---|
| عملیات | F06, F09 |
| نقش | مدیر سایت همین نصب |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | ندارد |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema SettingsDraft |
| خروجی | SettingsWorkspace؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503, 428, 412 |
| اعتبارسنجی | whitelist متن/برند، قالب، URL و contrast؛ API base و Neshan مرکزی از فرم عادی قابل تغییر نیستند؛ CAS draft.؛ تبدیل payload قدیمی به همان schema جدید، whitelist و CAS؛ مسیر مستقل ذخیره حقیقت ایجاد نشود. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | expectedVersion یا If-Match باید با نسخه سرور تطبیق کند؛ transition و idempotency و audit در یک تراکنش SQL؛ بایت فایل تراکنش SQL نیست |
| SQL | AuditLogs, IdempotencyRecords, SiteSettings, SiteSettingsAssetLinks, SiteSettingsVersions |
| خواندن جدول | IdempotencyRecords, SiteSettings, SiteSettingsAssetLinks, SiteSettingsVersions |
| نوشتن جدول | AuditLogs, IdempotencyRecords, SiteSettings, SiteSettingsAssetLinks, SiteSettingsVersions |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه.؛ ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/config/site-settings.repository.ts؛ src/features/admin/repository.ts |
| وابستگی | A04/A05؛ مجوز و CAS تنظیمات/قالب |

### ساختار درخواست AD06

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| expectedVersion | string | بله | {"minLength":1,"maxLength":100} |
| identity | object | بله | {"additionalProperties":false,"required":["brokerageName","appTitle","logo","publicEmail","publicPhone","favicon"]} |
| theme | object | بله | {"additionalProperties":false,"required":["primary","secondary","background","neutral","onPrimary","onBackground"]} |
| images | object | بله | {"additionalProperties":false,"required":[]} |
| template | object | بله | {"additionalProperties":false,"required":["id","version"]} |

### مثال درخواست AD06

```json
{
  "expectedVersion": "AAAAAAAAB9E=",
  "identity": {
    "brokerageName": "کارگزاری نمونه",
    "appTitle": "بازدید خودرو",
    "logo": null,
    "favicon": null,
    "publicEmail": "support@example.invalid",
    "publicPhone": "نمونه قراردادی"
  },
  "theme": {
    "primary": "#047857",
    "secondary": "#475569",
    "background": "#FFFFFF",
    "neutral": "#64748B",
    "onPrimary": "#FFFFFF",
    "onBackground": "#0F172A",
    "accent": "#F59E0B",
    "haloColor": "#10B981",
    "haloIntensity": 35
  },
  "images": {},
  "template": {
    "id": "body-image-guided",
    "version": 2
  }
}
```

### پاسخ AD06

```json
{
  "published": {
    "schemaVersion": 1,
    "tenantId": "demo",
    "version": 2,
    "publishedAt": "2026-10-26T09:00:00Z",
    "identity": {
      "brokerageName": "کارگزاری نمونه",
      "appTitle": "بازدید خودرو",
      "logo": null,
      "favicon": null,
      "publicEmail": "support@example.invalid",
      "publicPhone": "نمونه قراردادی"
    },
    "theme": {
      "primary": "#047857",
      "secondary": "#475569",
      "background": "#FFFFFF",
      "neutral": "#64748B",
      "onPrimary": "#FFFFFF",
      "onBackground": "#0F172A",
      "accent": "#F59E0B",
      "haloColor": "#10B981",
      "haloIntensity": 35
    },
    "images": {
      "landing": null,
      "referral": null,
      "otp": null,
      "readiness": null,
      "consent": null,
      "submission": null
    },
    "application": {
      "apiBaseUrl": "/api/bazdid",
      "contractVersion": "1",
      "template": {
        "id": "body-image-guided",
        "version": 2
      },
      "features": {
        "nativeCaptureFallback": true,
        "additionalEvidence": true,
        "supportLink": false
      },
      "locationMap": {
        "enabled": true,
        "webMapKey": null,
        "mapType": "dreamy",
        "reverseGeocoding": "api",
        "initialViewport": {
          "latitude": 35.699739,
          "longitude": 51.338097,
          "zoom": 12
        }
      }
    }
  },
  "draft": {
    "schemaVersion": 1,
    "tenantId": "demo",
    "version": 2,
    "publishedAt": "2026-10-26T09:00:00Z",
    "identity": {
      "brokerageName": "کارگزاری نمونه",
      "appTitle": "بازدید خودرو",
      "logo": null,
      "favicon": null,
      "publicEmail": "support@example.invalid",
      "publicPhone": "نمونه قراردادی"
    },
    "theme": {
      "primary": "#047857",
      "secondary": "#475569",
      "background": "#FFFFFF",
      "neutral": "#64748B",
      "onPrimary": "#FFFFFF",
      "onBackground": "#0F172A",
      "accent": "#F59E0B",
      "haloColor": "#10B981",
      "haloIntensity": 35
    },
    "images": {
      "landing": null,
      "referral": null,
      "otp": null,
      "readiness": null,
      "consent": null,
      "submission": null
    },
    "application": {
      "apiBaseUrl": "/api/bazdid",
      "contractVersion": "1",
      "template": {
        "id": "body-image-guided",
        "version": 2
      },
      "features": {
        "nativeCaptureFallback": true,
        "additionalEvidence": true,
        "supportLink": false
      },
      "locationMap": {
        "enabled": true,
        "webMapKey": null,
        "mapType": "dreamy",
        "reverseGeocoding": "api",
        "initialViewport": {
          "latitude": 35.699739,
          "longitude": 51.338097,
          "zoom": 12
        }
      }
    }
  },
  "version": "AAAAAAAAB9E="
}
```

### نمونه خطای AD06

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## AD07 — انتشار draft؛ reset از همین مسیر ویرایش draft

**پیشنهادی؛ تصویب نشده** — `POST /api/admin/site-settings/publish`

| موضوع | قرارداد |
|---|---|
| عملیات | F07 |
| نقش | مدیر سایت همین نصب |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | ندارد |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema Command |
| خروجی | PublicSettings؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503, 428, 412 |
| اعتبارسنجی | publish با CAS و اعتبار کامل؛ reset فقط draft بصری است، نه حذف مدارک/بازدید/تنظیمات مرکزی. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | expectedVersion یا If-Match باید با نسخه سرور تطبیق کند؛ transition و idempotency و audit در یک تراکنش SQL؛ بایت فایل تراکنش SQL نیست |
| SQL | AuditLogs, IdempotencyRecords, SiteSettings, SiteSettingsVersions |
| خواندن جدول | IdempotencyRecords, SiteSettings, SiteSettingsVersions |
| نوشتن جدول | AuditLogs, IdempotencyRecords, SiteSettings, SiteSettingsVersions |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/config/site-settings.repository.ts |
| وابستگی | A04/A05؛ مجوز و CAS تنظیمات/قالب |

### ساختار درخواست AD07

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| expectedVersion | string | بله | {"minLength":1,"maxLength":100} |

### مثال درخواست AD07

```json
{
  "expectedVersion": "AAAAAAAAB9E="
}
```

### پاسخ AD07

```json
{
  "schemaVersion": 1,
  "tenantId": "demo",
  "version": 2,
  "publishedAt": "2026-10-26T09:00:00Z",
  "identity": {
    "brokerageName": "کارگزاری نمونه",
    "appTitle": "بازدید خودرو",
    "logo": null,
    "favicon": null,
    "publicEmail": "support@example.invalid",
    "publicPhone": "نمونه قراردادی"
  },
  "theme": {
    "primary": "#047857",
    "secondary": "#475569",
    "background": "#FFFFFF",
    "neutral": "#64748B",
    "onPrimary": "#FFFFFF",
    "onBackground": "#0F172A",
    "accent": "#F59E0B",
    "haloColor": "#10B981",
    "haloIntensity": 35
  },
  "images": {
    "landing": null,
    "referral": null,
    "otp": null,
    "readiness": null,
    "consent": null,
    "submission": null
  },
  "application": {
    "apiBaseUrl": "/api/bazdid",
    "contractVersion": "1",
    "template": {
      "id": "body-image-guided",
      "version": 2
    },
    "features": {
      "nativeCaptureFallback": true,
      "additionalEvidence": true,
      "supportLink": false
    },
    "locationMap": {
      "enabled": true,
      "webMapKey": null,
      "mapType": "dreamy",
      "reverseGeocoding": "api",
      "initialViewport": {
        "latitude": 35.699739,
        "longitude": 51.338097,
        "zoom": 12
      }
    }
  }
}
```

### نمونه خطای AD07

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## AD08 — دارایی برند عمومیِ ایمن، جدا از شواهد خصوصی

**پیشنهادی؛ تصویب نشده** — `POST /api/admin/branding-assets`

| موضوع | قرارداد |
|---|---|
| عملیات | F08 |
| نقش | مدیر سایت همین نصب |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | ندارد |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست |
| بدنه | multipart/form-data؛ schema BrandUpload |
| خروجی | BrandAsset؛ تعریف دقیق در schemas.json |
| کد موفقیت | 201, 200 |
| کد خطا | 400, 401, 403, 404, 409, 413, 415, 422, 429, 500, 503 |
| اعتبارسنجی | slot مجاز، اندازه، signature، ابعاد و نوع امن فایل؛ SVG خام نامطمئن ممنوع؛ لوگوی کارگزاری از هویت برنامه جدا. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | expectedVersion یا If-Match باید با نسخه سرور تطبیق کند؛ transition و idempotency و audit در یک تراکنش SQL؛ بایت فایل تراکنش SQL نیست |
| SQL | AuditLogs, BrandingAssets, IdempotencyRecords, SiteSettingsAssetLinks |
| خواندن جدول | BrandingAssets, IdempotencyRecords, SiteSettingsAssetLinks |
| نوشتن جدول | AuditLogs, BrandingAssets, IdempotencyRecords |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ایجاد فایل برند sanitised در مسیر عمومی مجاز برند؛ این استثنا برای لوگو است، نه رسانه بازدید. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/admin/assets/asset-repository.ts |
| وابستگی | A04/A05؛ مجوز و CAS تنظیمات/قالب |

### ساختار درخواست AD08

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| slot | string | بله | {} |
| file | BinaryTransfer | بله | {} |

درخواست multipart شامل slot و file واقعی است؛ فایل به JSON تبدیل نمی‌شود. نام فایل ارسالی صرفاً داده نامطمئن است. signature، اندازه، ابعاد، نقش slot و نوع ایمن طبق سیاست مصوب بررسی می‌شوند.

### پاسخ AD08

```json
{
  "assetId": "11111111-1111-4111-8111-111111111111",
  "url": "/branding/example-brokerage-logo.webp",
  "mimeType": "image/jpeg",
  "byteSize": 420000,
  "width": 320,
  "height": 160
}
```

### نمونه خطای AD08

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## AD09 — نگاشت نقش فعال نصب از هویت مبدأ

**پیشنهادی؛ تصویب نشده** — `PUT /api/admin/staff/{staffId}/roles`

| موضوع | قرارداد |
|---|---|
| عملیات | F10 |
| نقش | مدیر سایت همین نصب |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | staffId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema StaffRolesRequest |
| خروجی | Acknowledgement؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503, 428, 412 |
| اعتبارسنجی | staffId همان نصب، نقش/فعال‌بودن مجاز و جلوگیری از ارتقای بی‌اختیار؛ هویت SSO در Frontend ساخته نشود. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | expectedVersion یا If-Match باید با نسخه سرور تطبیق کند؛ transition و idempotency و audit در یک تراکنش SQL؛ بایت فایل تراکنش SQL نیست |
| SQL | AuditLogs, IdempotencyRecords, StaffRoleAssignments, StaffUsers |
| خواندن جدول | IdempotencyRecords, StaffRoleAssignments, StaffUsers |
| نوشتن جدول | AuditLogs, IdempotencyRecords, StaffRoleAssignments, StaffUsers |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/admin/repository.ts |
| وابستگی | A04/A05؛ مجوز و CAS تنظیمات/قالب |

### ساختار درخواست AD09

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| roles | array | بله | {"items":{"enum":["platform-admin","reviewer","template-editor","viewer"]},"minItems":1,"uniqueItems":true} |
| active | boolean | بله | {} |
| expectedVersion | string | بله | {"minLength":1,"maxLength":100} |

### مثال درخواست AD09

```json
{
  "roles": [
    "platform-admin"
  ],
  "active": true,
  "expectedVersion": "AAAAAAAAB9E="
}
```

### پاسخ AD09

```json
{
  "acknowledged": true,
  "version": "AAAAAAAAB9E=",
  "at": "2026-10-26T09:00:00Z"
}
```

### نمونه خطای AD09

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## AD10 — فعال‌بودن مقصد سروری whitelist

**پیشنهادی؛ تصویب نشده** — `PUT /api/admin/webhooks/{webhookId}`

| موضوع | قرارداد |
|---|---|
| عملیات | F11 |
| نقش | مدیر سایت همین نصب |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | webhookId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema WebhookRequest |
| خروجی | Acknowledgement؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503, 428, 412 |
| اعتبارسنجی | فقط webhook ازپیش‌تعریف‌شده whitelist؛ مقصد و credential دلخواه مرورگر مردود؛ تغییر enabled با مجوز و CAS. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | expectedVersion یا If-Match باید با نسخه سرور تطبیق کند؛ transition و idempotency و audit در یک تراکنش SQL؛ بایت فایل تراکنش SQL نیست |
| SQL | AuditLogs, IdempotencyRecords, WebhookSubscriptions |
| خواندن جدول | IdempotencyRecords, WebhookSubscriptions |
| نوشتن جدول | AuditLogs, IdempotencyRecords, WebhookSubscriptions |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/admin/repository.ts |
| وابستگی | A04/A05؛ مجوز و CAS تنظیمات/قالب |

### ساختار درخواست AD10

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| enabled | boolean | بله | {} |
| expectedVersion | string | بله | {"minLength":1,"maxLength":100} |

### مثال درخواست AD10

```json
{
  "enabled": true,
  "expectedVersion": "AAAAAAAAB9E="
}
```

### پاسخ AD10

```json
{
  "acknowledged": true,
  "version": "AAAAAAAAB9E=",
  "at": "2026-10-26T09:00:00Z"
}
```

### نمونه خطای AD10

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## AD11 — سلامت واقعی بدون مسیر و راز

**پیشنهادی؛ تصویب نشده** — `GET /api/admin/system/health`

| موضوع | قرارداد |
|---|---|
| عملیات | F12 |
| نقش | مدیر سایت همین نصب |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | ندارد |
| query | ندارد |
| سرآیند | Accept: application/json |
| بدنه | ندارد |
| خروجی | Health؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503 |
| اعتبارسنجی | اندازه‌گیری واقعی فضای فایل/صف/worker و وضعیت dependency؛ secret یا physical root در پاسخ نیاید؛ نبود تحلیل با موفقیت جعل نشود. |
| تکرار امن | بدون اثر تجاری؛ تکرار خواندن امن است، حساس‌ها no-store و بدون cache عمومی |
| هم‌زمانی | خواندن ETag/version؛ GET هیچ بازدید یا تصمیمی ایجاد نمی‌کند |
| SQL | فایل استقرار/ارائه‌دهنده بیرونی؛ SQL خصوصی جدید نمی‌خواهد |
| خواندن جدول | ندارد |
| نوشتن جدول | ندارد |
| اثر فایل | فایل/مشتق خصوصی همان نسخه با مجوز؛ فقط در صورت نیاز و بدون بارگذاری گروهی بایت‌ها. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D04, D08 |
| آداپتور فعلی | src/features/admin/operational-snapshot.tsx |
| وابستگی | A04/A05؛ مجوز و CAS تنظیمات/قالب |

### پاسخ AD11

```json
{
  "state": "healthy",
  "checkedAt": "2026-10-26T09:00:00Z",
  "components": []
}
```

### نمونه خطای AD11

```json
{
  "type": "urn:inspection:problem:NOT_FOUND",
  "title": "منبع مجاز پیدا نشد.",
  "status": 404,
  "code": "NOT_FOUND",
  "traceId": "trace-example",
  "errors": {}
}
```

## FW01 — تلاش مجدد همان کار تحویل

**پیشنهادی؛ تصویب نشده** — `POST /api/admin/forwarding-jobs/{jobId}/retry`

| موضوع | قرارداد |
|---|---|
| عملیات | G04 |
| نقش | مدیر با اختیار بازیابی تحویل |
| احراز هویت | نشست امن HttpOnly/Secure؛ نقش، مالکیت و ارجاع سمت سرور؛ نه localStorage/URL |
| ورودی مسیر | jobId: شناسه opaque؛ resolve از پایگاه همین نصب و بررسی مالکیت |
| query | ندارد |
| سرآیند | Accept: application/json؛ Idempotency-Key: کلید پایدار فرمان؛ برای PUT باینری uploadId/همان انتقال، نه ساخت نسخه تازه؛ X-CSRF-Token: برای احراز هویت cookie طبق پروتکل مصوب؛ مقدار واقعی هرگز در مثال/log نیست؛ Content-Type: application/json |
| بدنه | application/json؛ schema Command |
| خروجی | Acknowledgement؛ تعریف دقیق در schemas.json |
| کد موفقیت | 200 |
| کد خطا | 400, 401, 403, 404, 409, 422, 429, 500, 503, 428, 412 |
| اعتبارسنجی | همان job معتبر و permission عملیاتی؛ lease، نسخه و retryable بودن؛ job جدید برای همان تحویل نسازد. |
| تکرار امن | رزرو اتمیک کلید در scope نصب + عامل + عملیات + منبع با hash بدنه؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409. CAS همان تراکنش؛ فرمان متفاوت با نسخه کهنه 409. |
| هم‌زمانی | expectedVersion یا If-Match باید با نسخه سرور تطبیق کند؛ transition و idempotency و audit در یک تراکنش SQL؛ بایت فایل تراکنش SQL نیست |
| SQL | AuditLogs, ForwardingAttempts, ForwardingJobs, IdempotencyRecords |
| خواندن جدول | ForwardingAttempts, ForwardingJobs, IdempotencyRecords |
| نوشتن جدول | AuditLogs, ForwardingJobs, IdempotencyRecords |
| اثر فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تصمیم باز | D11, D12 |
| آداپتور فعلی | src/features/inspection-status/integration-contracts.ts |
| وابستگی | E09؛ snapshot و مقصد/تأیید مقصد مورد توافق |

### ساختار درخواست FW01

| فیلد | نوع/مرجع | الزام | قیود ساختاری |
|---|---|---|---|
| expectedVersion | string | بله | {"minLength":1,"maxLength":100} |

### مثال درخواست FW01

```json
{
  "expectedVersion": "AAAAAAAAB9E="
}
```

### پاسخ FW01

```json
{
  "acknowledged": true,
  "version": "AAAAAAAAB9E=",
  "at": "2026-10-26T09:00:00Z"
}
```

### نمونه خطای FW01

```json
{
  "type": "urn:inspection:problem:VERSION_CONFLICT",
  "title": "نسخه تغییر کرده است؛ اطلاعات را بازخوانی کنید.",
  "status": 409,
  "code": "VERSION_CONFLICT",
  "traceId": "trace-example",
  "errors": {}
}
```

## قرارداد وظایف سروری؛ بدون endpoint مرورگر

این سه مورد جزو ۶۳ عملیات هستند ولی HTTP route تازه ندارند. acknowledged در نتیجه G01 فقط ثبت پایدار رویداد در outbox را تأیید می‌کند، نه رسیدن پیام بهگیرنده؛ سرویس اختیاری غیرفعال نباید تحویل موفق جعل کند. قالب پیام زیر پیشنهاد است و قرارداد مقصد/کانال و ack باید با مبدأ تصویب شود. رسانه به JSON باینری تبدیل نمی‌شود. مثال ForwardingSnapshot فقط یک عضو آرایه را برایخوانایی نمایش می‌دهد؛ سرور باید همه ۱۲ رسانه نسخه ۲ را ازقالب و snapshot معتبر مشتق کند، نه minItems یا count ثابت عمومی.

### G01 — اعلان رویداد وضعیت

| موضوع | قرارداد |
|---|---|
| عامل و مجوز | tenant از نصب و نشست معتبر؛ اتصال subject/sourceRequest/inspection و برای Reviewer ارجاع فعال. کارگر سرور یا مدیر دارای مجوز عملیاتی؛ مشتری فقط projection امن |
| ورودی | NotificationEvent |
| خروجی | Acknowledgement |
| SQL خوانده‌شده | IdempotencyRecords, Inspections, NotificationOutbox, WebhookSubscriptions |
| SQL نوشته‌شده | AuditLogs, IdempotencyRecords, NotificationOutbox |
| فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات NotificationOutbox,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تصمیم باز | D11, D12 |

### نمونه پیام G01

```json
{
  "id": "event-example",
  "tenantId": "brokerage-example",
  "inspectionId": "insp_contract_001",
  "trackingCode": "BDI-8F31K2",
  "type": "review-approved",
  "at": "2026-10-27T08:30:00Z"
}
```

### نمونه نتیجه G01

```json
{
  "acknowledged": true,
  "version": "AAAAAAAAB9E=",
  "at": "2026-10-26T09:00:00Z"
}
```

### G02 — ایجاد کار تحویل نسخه تأییدشده

| موضوع | قرارداد |
|---|---|
| عامل و مجوز | tenant از نصب و نشست معتبر؛ اتصال subject/sourceRequest/inspection و برای Reviewer ارجاع فعال. کارگر سرور یا مدیر دارای مجوز عملیاتی؛ مشتری فقط projection امن |
| ورودی | ForwardingSnapshot |
| خروجی | ForwardingJob |
| SQL خوانده‌شده | ForwardingJobs, IdempotencyRecords, InspectionReviews, InspectionSubmissions, Inspections |
| SQL نوشته‌شده | AuditLogs, ForwardingJobs, IdempotencyRecords, InspectionStatusHistory, Inspections |
| فایل | ندارد؛ URL راهنما و برند فقط reference عمومی مجاز است، نه بایت مدرک. ندارد؛ اثر این عملیات روی داده یا نشست است، نه تولید/حذف رسانه. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات ForwardingJobs,Inspections,InspectionStatusHistory,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تصمیم باز | D11, D12 |

### نمونه پیام G02

```json
{
  "deliveryKey": "delivery-example",
  "submissionId": "submission-example",
  "sourceRequestId": "REQ-DEMO-001",
  "inspectionId": "insp_contract_001",
  "trackingCode": "BDI-8F31K2",
  "decision": "approved",
  "approvedAt": "2026-10-27T08:30:00Z",
  "submittedAt": "2026-10-27T08:30:00Z",
  "templateId": "body-image-guided",
  "templateVersion": 2,
  "location": {
    "latitude": 35.699739,
    "longitude": 51.338097,
    "accuracyMeters": 8,
    "formattedAddress": "تهران، خیابان نمونه، محل بازدید",
    "buildingNumber": "نمونه قراردادی",
    "unitFloor": "نمونه قراردادی",
    "parkingDescription": "نمونه قراردادی"
  },
  "vehicle": {
    "id": "11111111-1111-4111-8111-111111111111",
    "make": "خودروی نمونه",
    "model": "سدان نمونه",
    "modelYear": 2024,
    "color": "سفید",
    "bodyColor": "#F1F5F9",
    "plate": {
      "firstTwoDigits": "12",
      "letter": "ب",
      "threeDigits": "345",
      "regionDigits": "67"
    },
    "maskedVin": "DEMO••••••3456",
    "confirmed": true,
    "version": "AAAAAAAAB9E="
  },
  "odometer": {
    "kilometers": 48320,
    "updatedAt": "2026-10-26T09:00:00Z"
  },
  "media": [
    {
      "evidenceId": "11111111-1111-4111-8111-111111111111",
      "evidenceVersionId": "22222222-2222-4222-8222-222222222222",
      "inspectionId": "insp_contract_001",
      "kind": "photo",
      "requirementId": "spec-plate",
      "alternativeId": "pillar",
      "revision": "client-revision-0002",
      "upload": "uploaded",
      "verification": "processing",
      "byteSize": 420000,
      "mimeType": "image/jpeg",
      "sha256": "0000000000000000000000000000000000000000000000000000000000000000",
      "current": true,
      "version": "AAAAAAAAB9E="
    }
  ]
}
```

### نمونه نتیجه G02

```json
{
  "jobId": "job-example",
  "inspectionId": "insp_contract_001",
  "submissionId": "submission-example",
  "deliveryKey": "delivery-example",
  "phase": "ready",
  "attemptCount": 0,
  "version": "version-example"
}
```

### G03 — ارسال به سامانه بیمه و تأیید دریافت

| موضوع | قرارداد |
|---|---|
| عامل و مجوز | tenant از نصب و نشست معتبر؛ اتصال subject/sourceRequest/inspection و برای Reviewer ارجاع فعال. کارگر سرور یا مدیر دارای مجوز عملیاتی؛ مشتری فقط projection امن |
| ورودی | ForwardingSnapshot |
| خروجی | DeliveryAcknowledgement |
| SQL خوانده‌شده | ForwardingAttempts, ForwardingJobs, IdempotencyRecords, Inspections, MediaFiles |
| SQL نوشته‌شده | AuditLogs, ForwardingAttempts, ForwardingJobs, IdempotencyRecords, InspectionStatusHistory, Inspections |
| فایل | فایل/مشتق خصوصی همان نسخه با مجوز؛ فقط در صورت نیاز و بدون بارگذاری گروهی بایت‌ها. خواندن/stream نسخه‌های snapshot approved به مقصد whitelist؛ نه کپی Base64 و نه حذف اصل. |
| تراکنش | پیشنهادی: احراز scope/CAS، ثبت فرمان و تغییرات ForwardingJobs,ForwardingAttempts,Inspections,InspectionStatusHistory,AuditLogs,IdempotencyRecords در تراکنش کوتاه؛ I/O یا شبکه بیرون تراکنش و از طریق receipt/outbox/lease بازیابی شود. |
| تکرار | Idempotency-Key پایدار + hash درخواست + scope و expectedVersion؛ همان کلید/بدنه همان نتیجه، بدنه متفاوت 409؛ retry نامطمئن همان فرمان |
| خطا | 400/422 اعتبارسنجی ساختاریافته؛ 401 نشست؛ 403 اختیار؛ 404 منبع نامرئی؛ 409 تعارض نسخه/کلید؛ 429 زمان retry؛ 5xx خطای موقت بدون حذف داده |
| تصمیم باز | D11, D12 |

### نمونه پیام G03

```json
{
  "deliveryKey": "delivery-example",
  "submissionId": "submission-example",
  "sourceRequestId": "REQ-DEMO-001",
  "inspectionId": "insp_contract_001",
  "trackingCode": "BDI-8F31K2",
  "decision": "approved",
  "approvedAt": "2026-10-27T08:30:00Z",
  "submittedAt": "2026-10-27T08:30:00Z",
  "templateId": "body-image-guided",
  "templateVersion": 2,
  "location": {
    "latitude": 35.699739,
    "longitude": 51.338097,
    "accuracyMeters": 8,
    "formattedAddress": "تهران، خیابان نمونه، محل بازدید",
    "buildingNumber": "نمونه قراردادی",
    "unitFloor": "نمونه قراردادی",
    "parkingDescription": "نمونه قراردادی"
  },
  "vehicle": {
    "id": "11111111-1111-4111-8111-111111111111",
    "make": "خودروی نمونه",
    "model": "سدان نمونه",
    "modelYear": 2024,
    "color": "سفید",
    "bodyColor": "#F1F5F9",
    "plate": {
      "firstTwoDigits": "12",
      "letter": "ب",
      "threeDigits": "345",
      "regionDigits": "67"
    },
    "maskedVin": "DEMO••••••3456",
    "confirmed": true,
    "version": "AAAAAAAAB9E="
  },
  "odometer": {
    "kilometers": 48320,
    "updatedAt": "2026-10-26T09:00:00Z"
  },
  "media": [
    {
      "evidenceId": "11111111-1111-4111-8111-111111111111",
      "evidenceVersionId": "22222222-2222-4222-8222-222222222222",
      "inspectionId": "insp_contract_001",
      "kind": "photo",
      "requirementId": "spec-plate",
      "alternativeId": "pillar",
      "revision": "client-revision-0002",
      "upload": "uploaded",
      "verification": "processing",
      "byteSize": 420000,
      "mimeType": "image/jpeg",
      "sha256": "0000000000000000000000000000000000000000000000000000000000000000",
      "current": true,
      "version": "AAAAAAAAB9E="
    }
  ]
}
```

### نمونه نتیجه G03

```json
{
  "deliveryKey": "delivery-example",
  "inspectionId": "insp_contract_001",
  "submissionId": "submission-example",
  "accepted": true,
  "acknowledgementId": "ack-example",
  "acknowledgedAt": "2026-10-27T08:30:00Z"
}
```

## فرهنگ کامل DTO و schema مشترک

تمام تعاریف زیر پیشنهادی‌اند. ارجاع #/$defs در محدوده همین سند به تعریف متناظر اشاره دارد؛ required، additionalProperties، enum، allOf و شرط‌ها جزو قراردادند. تعاریف برای اجرای validator در schemas.json هم به صورت ماشینی نگهداری می‌شوند.

### تعریف Empty

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {},
  "required": []
}
```

### مثال مستقل Empty

```json
{}
```

### تعریف Command

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "expectedVersion": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    }
  },
  "required": [
    "expectedVersion"
  ]
}
```

### مثال مستقل Command

```json
{
  "expectedVersion": "AAAAAAAAB9E="
}
```

### تعریف Acknowledgement

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "acknowledged": {
      "type": "boolean"
    },
    "version": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    },
    "at": {
      "type": "string",
      "format": "date-time"
    }
  },
  "required": [
    "acknowledged",
    "version",
    "at"
  ]
}
```

### مثال مستقل Acknowledgement

```json
{
  "acknowledged": true,
  "version": "AAAAAAAAB9E=",
  "at": "2026-10-26T09:00:00Z"
}
```

### تعریف Bootstrap

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "schemaVersion": {
      "const": 1
    },
    "tenantId": {
      "type": "string",
      "pattern": "^[a-z][a-z0-9-]{1,47}$"
    },
    "apiBaseUrl": {
      "type": "string"
    },
    "siteSettingsEndpoint": {
      "type": "string"
    },
    "settingsSource": {
      "enum": [
        "mock",
        "api"
      ]
    }
  },
  "required": [
    "schemaVersion",
    "tenantId",
    "apiBaseUrl",
    "siteSettingsEndpoint",
    "settingsSource"
  ]
}
```

### مثال مستقل Bootstrap

```json
{
  "schemaVersion": 1,
  "tenantId": "demo",
  "apiBaseUrl": "/api/bazdid",
  "siteSettingsEndpoint": "/api/bazdid/public/site-settings",
  "settingsSource": "api"
}
```

### تعریف SourceContext

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "tenantId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "subjectId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "sourceRequestId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "mobile": {
      "type": "string",
      "pattern": "^09[0-9]{9}$"
    },
    "authority": {
      "const": "brokerage-session"
    }
  },
  "required": [
    "tenantId",
    "subjectId",
    "sourceRequestId",
    "mobile",
    "authority"
  ]
}
```

### مثال مستقل SourceContext

```json
{
  "tenantId": "demo",
  "subjectId": "customer-fixture",
  "sourceRequestId": "REQ-DEMO-001",
  "mobile": "09120000000",
  "authority": "brokerage-session"
}
```

### تعریف TicketRequest

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "ticket": {
      "type": "string",
      "minLength": 16,
      "maxLength": 2048
    },
    "state": {
      "type": "string",
      "minLength": 16,
      "maxLength": 256
    },
    "returnPath": {
      "type": "string",
      "pattern": "^/(?!/)"
    }
  },
  "required": [
    "ticket",
    "state",
    "returnPath"
  ]
}
```

### مثال مستقل TicketRequest

```json
{
  "ticket": "FICTIONAL_ONE_USE_TICKET_NOT_A_CREDENTIAL",
  "state": "FICTIONAL_STATE_FOR_REVIEW_ONLY",
  "returnPath": "/readiness"
}
```

### تعریف Session

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "state": {
      "enum": [
        "authenticated",
        "anonymous",
        "expired"
      ]
    },
    "kind": {
      "enum": [
        "customer",
        "staff"
      ]
    },
    "expiresAt": {
      "type": "string",
      "format": "date-time"
    },
    "source": {
      "$ref": "#/$defs/SourceContext"
    },
    "role": {
      "enum": [
        "platform-admin",
        "reviewer",
        "template-editor",
        "viewer"
      ]
    },
    "permissions": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "tenantId": {
      "type": "string",
      "minLength": 1
    },
    "subjectId": {
      "type": "string",
      "minLength": 1
    },
    "authority": {
      "const": "backend-session"
    }
  },
  "required": [
    "state",
    "kind"
  ],
  "allOf": [
    {
      "if": {
        "properties": {
          "state": {
            "const": "authenticated"
          }
        },
        "required": [
          "state"
        ]
      },
      "then": {
        "required": [
          "expiresAt"
        ],
        "properties": {
          "expiresAt": {}
        }
      }
    },
    {
      "if": {
        "properties": {
          "state": {
            "const": "authenticated"
          },
          "kind": {
            "const": "customer"
          }
        },
        "required": [
          "state",
          "kind"
        ]
      },
      "then": {
        "required": [
          "source"
        ],
        "properties": {
          "source": {}
        }
      }
    },
    {
      "if": {
        "properties": {
          "state": {
            "const": "authenticated"
          },
          "kind": {
            "const": "staff"
          }
        },
        "required": [
          "state",
          "kind"
        ]
      },
      "then": {
        "required": [
          "role",
          "permissions",
          "tenantId",
          "subjectId",
          "authority"
        ],
        "properties": {
          "role": {},
          "permissions": {},
          "tenantId": {},
          "subjectId": {},
          "authority": {}
        }
      }
    }
  ]
}
```

### مثال مستقل Session

```json
{
  "state": "authenticated",
  "kind": "customer",
  "expiresAt": "2026-10-26T09:00:00Z",
  "source": {
    "tenantId": "demo",
    "subjectId": "customer-fixture",
    "sourceRequestId": "REQ-DEMO-001",
    "mobile": "09120000000",
    "authority": "brokerage-session"
  }
}
```

### تعریف ReferralRequest

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "code": {
      "type": "string",
      "minLength": 1,
      "maxLength": 80
    }
  },
  "required": [
    "code"
  ]
}
```

### مثال مستقل ReferralRequest

```json
{
  "code": "48216"
}
```

### تعریف ReferralResult

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "valid": {
      "type": "boolean"
    },
    "partnerId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "partnerName": {
      "type": "string"
    }
  },
  "required": [
    "valid"
  ]
}
```

### مثال مستقل ReferralResult

```json
{
  "valid": true
}
```

### تعریف OtpRequest

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "referralCode": {
      "type": "string",
      "minLength": 1,
      "maxLength": 80
    },
    "challengeContextId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    }
  },
  "required": [
    "referralCode",
    "challengeContextId"
  ]
}
```

### مثال مستقل OtpRequest

```json
{
  "referralCode": "A4K9P2",
  "challengeContextId": "source-context-fixture"
}
```

### تعریف OtpChallenge

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "challengeId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "expiresAt": {
      "type": "string",
      "format": "date-time"
    },
    "retryAfterSeconds": {
      "type": "integer",
      "minimum": 0,
      "maximum": 9007199254740991
    },
    "remainingAttempts": {
      "type": "integer",
      "minimum": 0,
      "maximum": 9007199254740991
    },
    "codeLength": {
      "const": 5
    }
  },
  "required": [
    "challengeId",
    "expiresAt",
    "retryAfterSeconds",
    "remainingAttempts",
    "codeLength"
  ]
}
```

### مثال مستقل OtpChallenge

```json
{
  "challengeId": "11111111-1111-4111-8111-111111111111",
  "expiresAt": "2026-10-26T09:00:00Z",
  "retryAfterSeconds": 1,
  "remainingAttempts": 1,
  "codeLength": 5
}
```

### تعریف OtpVerification

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "challengeId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "code": {
      "type": "string",
      "pattern": "^[0-9]{5}$"
    }
  },
  "required": [
    "challengeId",
    "code"
  ]
}
```

### مثال مستقل OtpVerification

```json
{
  "challengeId": "11111111-1111-4111-8111-111111111111",
  "code": "48216"
}
```

### تعریف CreateInspection

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "sourceRequestId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    }
  },
  "required": [
    "sourceRequestId"
  ]
}
```

### مثال مستقل CreateInspection

```json
{
  "sourceRequestId": "REQ-DEMO-001"
}
```

### تعریف Plate

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "firstTwoDigits": {
      "type": "string",
      "pattern": "^[0-9]{2}$"
    },
    "letter": {
      "enum": [
        "الف",
        "ب",
        "ج",
        "د",
        "س",
        "ص",
        "ط",
        "ع",
        "ق",
        "ل",
        "م",
        "ن",
        "و",
        "ه",
        "ی"
      ]
    },
    "threeDigits": {
      "type": "string",
      "pattern": "^[0-9]{3}$"
    },
    "regionDigits": {
      "type": "string",
      "pattern": "^[0-9]{2}$"
    }
  },
  "required": [
    "firstTwoDigits",
    "letter",
    "threeDigits",
    "regionDigits"
  ]
}
```

### مثال مستقل Plate

```json
{
  "firstTwoDigits": "12",
  "letter": "ب",
  "threeDigits": "345",
  "regionDigits": "67"
}
```

### تعریف Location

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "latitude": {
      "type": "number",
      "minimum": -90,
      "maximum": 90
    },
    "longitude": {
      "type": "number",
      "minimum": -180,
      "maximum": 180
    },
    "accuracyMeters": {
      "type": [
        "number",
        "null"
      ],
      "minimum": 0
    },
    "formattedAddress": {
      "type": "string",
      "minLength": 1,
      "maxLength": 500
    },
    "buildingNumber": {
      "type": "string",
      "maxLength": 40
    },
    "unitFloor": {
      "type": "string",
      "maxLength": 80
    },
    "parkingDescription": {
      "type": "string",
      "maxLength": 500
    },
    "selectionSource": {
      "enum": [
        "gps",
        "manual"
      ]
    },
    "recordedAt": {
      "type": "string",
      "format": "date-time"
    }
  },
  "required": [
    "latitude",
    "longitude",
    "accuracyMeters",
    "formattedAddress"
  ]
}
```

### مثال مستقل Location

```json
{
  "latitude": 35.699739,
  "longitude": 51.338097,
  "accuracyMeters": 8,
  "formattedAddress": "تهران، خیابان نمونه، محل بازدید",
  "buildingNumber": "نمونه قراردادی",
  "unitFloor": "نمونه قراردادی",
  "parkingDescription": "نمونه قراردادی"
}
```

### تعریف LocationRequest

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "latitude": {
      "type": "number",
      "minimum": -90,
      "maximum": 90
    },
    "longitude": {
      "type": "number",
      "minimum": -180,
      "maximum": 180
    },
    "accuracyMeters": {
      "type": "number",
      "minimum": 0
    },
    "formattedAddress": {
      "type": "string",
      "minLength": 1,
      "maxLength": 500
    },
    "buildingNumber": {
      "type": "string",
      "maxLength": 40
    },
    "unitFloor": {
      "type": "string",
      "maxLength": 80
    },
    "parkingDescription": {
      "type": "string",
      "maxLength": 500
    },
    "expectedVersion": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    }
  },
  "required": [
    "latitude",
    "longitude",
    "accuracyMeters",
    "formattedAddress",
    "buildingNumber",
    "unitFloor",
    "parkingDescription",
    "expectedVersion"
  ]
}
```

### مثال مستقل LocationRequest

```json
{
  "latitude": 35.699739,
  "longitude": 51.338097,
  "accuracyMeters": 8,
  "formattedAddress": "تهران، خیابان نمونه، محل بازدید",
  "buildingNumber": "نمونه قراردادی",
  "unitFloor": "نمونه قراردادی",
  "parkingDescription": "نمونه قراردادی",
  "expectedVersion": "AAAAAAAAB9E="
}
```

### تعریف ConsentRequest

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "accepted": {
      "const": true
    },
    "termsVersion": {
      "type": "string",
      "minLength": 1,
      "maxLength": 80
    }
  },
  "required": [
    "accepted",
    "termsVersion"
  ]
}
```

### مثال مستقل ConsentRequest

```json
{
  "accepted": true,
  "termsVersion": "نمونه قراردادی"
}
```

### تعریف Vehicle

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "id": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "make": {
      "type": "string"
    },
    "model": {
      "type": "string"
    },
    "modelYear": {
      "type": "integer",
      "minimum": 1000,
      "maximum": 3000
    },
    "color": {
      "type": "string"
    },
    "bodyColor": {
      "type": "string",
      "pattern": "^#[0-9a-fA-F]{6}$"
    },
    "plate": {
      "$ref": "#/$defs/Plate"
    },
    "maskedVin": {
      "type": "string"
    },
    "confirmed": {
      "type": "boolean"
    },
    "version": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    }
  },
  "required": [
    "id",
    "make",
    "model",
    "modelYear",
    "color",
    "plate",
    "maskedVin",
    "confirmed",
    "version"
  ]
}
```

### مثال مستقل Vehicle

```json
{
  "id": "11111111-1111-4111-8111-111111111111",
  "make": "خودروی نمونه",
  "model": "سدان نمونه",
  "modelYear": 2024,
  "color": "سفید",
  "bodyColor": "#F1F5F9",
  "plate": {
    "firstTwoDigits": "12",
    "letter": "ب",
    "threeDigits": "345",
    "regionDigits": "67"
  },
  "maskedVin": "DEMO••••••3456",
  "confirmed": true,
  "version": "AAAAAAAAB9E="
}
```

### تعریف VehicleRequest

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "expectedVersion": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    },
    "confirmed": {
      "const": true
    },
    "plate": {
      "$ref": "#/$defs/Plate"
    },
    "discrepancy": {
      "type": "string",
      "maxLength": 1000
    }
  },
  "required": [
    "expectedVersion",
    "confirmed"
  ]
}
```

### مثال مستقل VehicleRequest

```json
{
  "expectedVersion": "AAAAAAAAB9E=",
  "confirmed": true
}
```

### تعریف PlateRequest

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "expectedVersion": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    },
    "plate": {
      "$ref": "#/$defs/Plate"
    }
  },
  "required": [
    "expectedVersion",
    "plate"
  ]
}
```

### مثال مستقل PlateRequest

```json
{
  "expectedVersion": "AAAAAAAAB9E=",
  "plate": {
    "firstTwoDigits": "12",
    "letter": "ب",
    "threeDigits": "345",
    "regionDigits": "67"
  }
}
```

### تعریف OdometerRequest

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "kilometers": {
      "type": "integer",
      "minimum": 0,
      "maximum": 9007199254740991
    },
    "evidenceId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "expectedVersion": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    }
  },
  "required": [
    "kilometers",
    "expectedVersion"
  ]
}
```

### مثال مستقل OdometerRequest

```json
{
  "kilometers": 48320,
  "expectedVersion": "AAAAAAAAB9E="
}
```

### تعریف Odometer

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "kilometers": {
      "type": "integer",
      "minimum": 0,
      "maximum": 9007199254740991
    },
    "updatedAt": {
      "type": "string",
      "format": "date-time"
    },
    "evidenceId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    }
  },
  "required": [
    "kilometers",
    "updatedAt"
  ]
}
```

### مثال مستقل Odometer

```json
{
  "kilometers": 48320,
  "updatedAt": "2026-10-26T09:00:00Z"
}
```

### تعریف Requirement

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "id": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "title": {
      "type": "string"
    },
    "required": {
      "type": "boolean"
    },
    "sampleImage": {
      "type": "string"
    },
    "instructions": {
      "type": "array",
      "items": {
        "type": "string",
        "minLength": 1
      },
      "minItems": 1
    },
    "choice": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "groupId": {
          "const": "vehicle-identification"
        },
        "alternatives": {
          "type": "array",
          "items": {
            "enum": [
              "pillar",
              "engine",
              "seat",
              "windshield"
            ]
          },
          "minItems": 4,
          "maxItems": 4,
          "uniqueItems": true
        }
      },
      "required": [
        "groupId",
        "alternatives"
      ]
    },
    "description": {
      "type": "string",
      "minLength": 1
    },
    "distance": {
      "type": "string",
      "minLength": 1
    },
    "height": {
      "type": "string",
      "minLength": 1
    },
    "orientation": {
      "enum": [
        "portrait",
        "landscape"
      ]
    },
    "checks": {
      "type": "array",
      "items": {
        "type": "string",
        "minLength": 1
      },
      "minItems": 1
    },
    "status": {
      "enum": [
        "pending",
        "captured",
        "uploading",
        "uploaded",
        "verified",
        "retake-requested"
      ]
    },
    "reviewerReason": {
      "type": "string",
      "minLength": 1
    },
    "semanticNodes": {
      "type": "array",
      "items": {
        "type": "string",
        "minLength": 1
      }
    },
    "guidanceTopics": {
      "type": "array",
      "items": {
        "enum": [
          "frame",
          "distance",
          "angle",
          "ignition",
          "glare",
          "interior",
          "hood",
          "text",
          "focus",
          "roof",
          "steady"
        ]
      }
    }
  },
  "required": [
    "id",
    "title",
    "required",
    "sampleImage",
    "instructions",
    "description",
    "checks",
    "status"
  ]
}
```

### مثال مستقل Requirement

```json
{
  "id": "front-45-right",
  "title": "جلو ۴۵° راست",
  "description": "جلوی خودرو و سمت راست به صورت کامل دیده شود.",
  "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-right.webp",
  "instructions": [
    "جلوی خودرو و سمت راست به طور کامل داخل کادر باشد.",
    "حدود ۳ متر از خودرو فاصله بگیرید.",
    "از زاویه ۴۵ درجه سمت راست عکس بگیرید."
  ],
  "distance": "۳ متر",
  "height": "کمر",
  "orientation": "landscape",
  "required": true,
  "status": "pending",
  "checks": [
    "واضح",
    "نور مناسب",
    "خودرو کامل در کادر"
  ],
  "guidanceTopics": [
    "frame",
    "distance",
    "angle"
  ]
}
```

### تعریف Section

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "id": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "title": {
      "type": "string"
    },
    "order": {
      "type": "integer",
      "minimum": 1
    },
    "photoRequirements": {
      "type": "array",
      "items": {
        "$ref": "#/$defs/Requirement"
      }
    }
  },
  "required": [
    "id",
    "title",
    "order",
    "photoRequirements"
  ]
}
```

### مثال مستقل Section

```json
{
  "id": "right",
  "title": "نمای راست",
  "order": 1,
  "photoRequirements": [
    {
      "id": "front-45-right",
      "title": "جلو ۴۵° راست",
      "description": "جلوی خودرو و سمت راست به صورت کامل دیده شود.",
      "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-right.webp",
      "instructions": [
        "جلوی خودرو و سمت راست به طور کامل داخل کادر باشد.",
        "حدود ۳ متر از خودرو فاصله بگیرید.",
        "از زاویه ۴۵ درجه سمت راست عکس بگیرید."
      ],
      "distance": "۳ متر",
      "height": "کمر",
      "orientation": "landscape",
      "required": true,
      "status": "pending",
      "checks": [
        "واضح",
        "نور مناسب",
        "خودرو کامل در کادر"
      ],
      "guidanceTopics": [
        "frame",
        "distance",
        "angle"
      ]
    },
    {
      "id": "back-45-right",
      "title": "عقب ۴۵° راست",
      "description": "عقب خودرو و سمت راست به صورت کامل دیده شود.",
      "sampleImage": "/assets/inspection-vehicle/photo-guides/back-45-right.webp",
      "instructions": [
        "تمام قسمت عقب و سمت راست خودرو داخل کادر باشد.",
        "خودرو را از زاویه ۴۵ درجه ثبت کنید.",
        "در نور کافی و بدون سایه شدید عکاسی کنید."
      ],
      "distance": "۳ متر",
      "height": "کمر",
      "orientation": "landscape",
      "required": true,
      "status": "pending",
      "checks": [
        "واضح",
        "نور مناسب",
        "خودرو کامل در کادر"
      ],
      "guidanceTopics": [
        "frame",
        "angle",
        "glare"
      ]
    }
  ]
}
```

### تعریف CapturePlan

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "templateId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "templateVersion": {
      "type": "integer",
      "minimum": 1
    },
    "photoPolicyVersion": {
      "type": "integer",
      "enum": [
        1,
        2
      ]
    },
    "sections": {
      "type": "array",
      "items": {
        "$ref": "#/$defs/Section"
      },
      "minItems": 1,
      "maxItems": 7
    },
    "captureRequirements": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "odometerRequirementId": {
          "const": "odometer-on"
        },
        "video360Required": {
          "const": true
        }
      },
      "required": [
        "odometerRequirementId",
        "video360Required"
      ]
    }
  },
  "required": [
    "templateId",
    "templateVersion",
    "photoPolicyVersion",
    "sections",
    "captureRequirements"
  ]
}
```

### مثال مستقل CapturePlan

```json
{
  "photoPolicyVersion": 2,
  "templateId": "body-image-guided",
  "templateVersion": 2,
  "sections": [
    {
      "id": "right",
      "title": "نمای راست",
      "order": 1,
      "photoRequirements": [
        {
          "id": "front-45-right",
          "title": "جلو ۴۵° راست",
          "description": "جلوی خودرو و سمت راست به صورت کامل دیده شود.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-right.webp",
          "instructions": [
            "جلوی خودرو و سمت راست به طور کامل داخل کادر باشد.",
            "حدود ۳ متر از خودرو فاصله بگیرید.",
            "از زاویه ۴۵ درجه سمت راست عکس بگیرید."
          ],
          "distance": "۳ متر",
          "height": "کمر",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "خودرو کامل در کادر"
          ],
          "guidanceTopics": [
            "frame",
            "distance",
            "angle"
          ]
        },
        {
          "id": "back-45-right",
          "title": "عقب ۴۵° راست",
          "description": "عقب خودرو و سمت راست به صورت کامل دیده شود.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/back-45-right.webp",
          "instructions": [
            "تمام قسمت عقب و سمت راست خودرو داخل کادر باشد.",
            "خودرو را از زاویه ۴۵ درجه ثبت کنید.",
            "در نور کافی و بدون سایه شدید عکاسی کنید."
          ],
          "distance": "۳ متر",
          "height": "کمر",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "خودرو کامل در کادر"
          ],
          "guidanceTopics": [
            "frame",
            "angle",
            "glare"
          ]
        }
      ]
    },
    {
      "id": "left",
      "title": "نمای چپ",
      "order": 2,
      "photoRequirements": [
        {
          "id": "front-45-left",
          "title": "جلو ۴۵° چپ",
          "description": "جلوی خودرو و سمت چپ به صورت کامل دیده شود.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-left.webp",
          "instructions": [
            "جلوی خودرو و سمت چپ به طور کامل داخل کادر باشد.",
            "حدود ۳ متر از خودرو فاصله بگیرید.",
            "از زاویه ۴۵ درجه سمت چپ عکس بگیرید."
          ],
          "distance": "۳ متر",
          "height": "کمر",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "خودرو کامل در کادر"
          ],
          "guidanceTopics": [
            "frame",
            "distance",
            "angle"
          ]
        },
        {
          "id": "back-45-left",
          "title": "عقب ۴۵° چپ",
          "description": "عقب خودرو و سمت چپ به صورت کامل دیده شود.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/back-45-left.webp",
          "instructions": [
            "تمام قسمت عقب و سمت چپ خودرو داخل کادر باشد.",
            "خودرو را از زاویه ۴۵ درجه ثبت کنید.",
            "در نور کافی و بدون سایه شدید عکاسی کنید."
          ],
          "distance": "۳ متر",
          "height": "کمر",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "خودرو کامل در کادر"
          ],
          "guidanceTopics": [
            "frame",
            "angle",
            "glare"
          ]
        }
      ]
    },
    {
      "id": "front",
      "title": "جلو",
      "order": 3,
      "photoRequirements": [
        {
          "id": "front-plate",
          "title": "نمای مستقیم جلو با پلاک",
          "description": "یک عکس مستقیم از نمای جلوی خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/front-plate.webp",
          "instructions": [
            "مستقیم روبه‌روی خودرو بایستید؛ خودرو وسط کادر باشد.",
            "نمای کامل جلو را بدون برش و زاویه شدید ثبت کنید.",
            "پلاک بدون بازتاب نور و کاملاً خوانا باشد."
          ],
          "distance": "۳ متر",
          "height": "چراغ‌ها",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "پلاک خوانا است"
          ],
          "guidanceTopics": [
            "angle",
            "frame",
            "text"
          ]
        }
      ]
    },
    {
      "id": "rear",
      "title": "عقب",
      "order": 4,
      "photoRequirements": [
        {
          "id": "rear-plate",
          "title": "نمای مستقیم عقب با پلاک",
          "description": "یک عکس مستقیم از نمای عقب خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/rear-plate.webp",
          "instructions": [
            "مستقیم پشت خودرو بایستید؛ خودرو وسط کادر باشد.",
            "تمام نمای عقب بدون برش و زاویه شدید داخل کادر باشد.",
            "پلاک کاملاً خوانا و بدون بازتاب باشد."
          ],
          "distance": "۳ متر",
          "height": "چراغ‌ها",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "پلاک خوانا است"
          ],
          "guidanceTopics": [
            "angle",
            "frame",
            "text"
          ]
        }
      ]
    },
    {
      "id": "cabin",
      "title": "کابین",
      "order": 5,
      "photoRequirements": [
        {
          "id": "odometer-on",
          "title": "کیلومترشمار",
          "description": "خودرو را روشن کنید و تصویری واضح از کیلومترشمار بگیرید.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/odometer-on.webp",
          "instructions": [
            "خودرو را روشن و در حالت توقف نگه دارید.",
            "تمام صفحه کیلومترشمار در کادر باشد.",
            "عدد کیلومتر خوانا باشد؛ از بازتاب نور جلوگیری کنید."
          ],
          "distance": "نزدیک",
          "height": "داشبورد",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "عدد کیلومتر خوانا است"
          ],
          "guidanceTopics": [
            "ignition",
            "frame",
            "glare"
          ]
        },
        {
          "id": "driver-interior",
          "title": "نمای داخل کابین از سمت راننده",
          "description": "از سمت راننده تصویری بگیرید که فضای داخلی خودرو به صورت واضح دیده شود.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/driver-interior.webp",
          "instructions": [
            "درِ سمت راننده را باز کنید.",
            "فرمان، داشبورد و صندلی‌ها دیده شوند.",
            "خیلی نزدیک نشوید؛ فضای داخلی کامل دیده شود."
          ],
          "distance": "۱ متر",
          "height": "درِ راننده",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "کابین کامل در کادر"
          ],
          "guidanceTopics": [
            "interior",
            "frame",
            "distance"
          ]
        }
      ]
    },
    {
      "id": "engine-details",
      "title": "موتور و مشخصات",
      "order": 6,
      "photoRequirements": [
        {
          "id": "engine-bay",
          "title": "محفظه موتور",
          "description": "کاپوت را باز کنید و یک تصویر کامل و واضح از محفظه موتور بگیرید.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/engine-bay.webp",
          "instructions": [
            "خودرو متوقف باشد؛ کاپوت را کاملاً و ایمن باز کنید.",
            "تمام محفظه موتور دیده شود.",
            "گوشی ثابت و تصویر بدون تاری باشد."
          ],
          "distance": "۱ متر",
          "height": "سینه",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "محفظه کامل در کادر"
          ],
          "guidanceTopics": [
            "hood",
            "frame",
            "steady"
          ]
        },
        {
          "id": "spec-plate",
          "title": "محل شماره شاسی خودرو",
          "description": "شماره شاسی خودرو — انتخاب یکی از چهار گزینه. فقط یک تصویر لازم است.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/spec-plate.webp",
          "instructions": [
            "از نزدیک روی پلاک مشخصات فوکوس کنید.",
            "تمام متن پلاک داخل کادر باشد.",
            "نوشته‌ها خوانا و بدون بازتاب نور باشند."
          ],
          "distance": "۳۰ سانتی‌متر",
          "height": "هم‌سطح پلاک",
          "orientation": "landscape",
          "choice": {
            "groupId": "vehicle-identification",
            "alternatives": [
              "pillar",
              "engine",
              "seat",
              "windshield"
            ]
          },
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "اطلاعات قابل خواندن است"
          ],
          "guidanceTopics": [
            "text",
            "frame",
            "glare"
          ]
        }
      ]
    },
    {
      "id": "roof",
      "title": "سقف",
      "order": 7,
      "photoRequirements": [
        {
          "id": "car-roof",
          "title": "نمای سقف",
          "description": "تمام سطح سقف خودرو را در تصویر نشان دهید.",
          "sampleImage": "/assets/inspection-vehicle/photo-guides/car-roof.webp",
          "instructions": [
            "از موقعیتی ایمن، گوشی را بالاتر بگیرید.",
            "بیشترین سطح سقف و گوشه‌های اصلی در کادر باشند.",
            "برای عکاسی روی خودرو نایستید."
          ],
          "distance": "۱ متر",
          "height": "بالاتر از سقف",
          "orientation": "landscape",
          "required": true,
          "status": "pending",
          "checks": [
            "واضح",
            "نور مناسب",
            "سقف کامل در کادر"
          ],
          "guidanceTopics": [
            "roof",
            "frame",
            "steady"
          ]
        }
      ]
    }
  ],
  "captureRequirements": {
    "odometerRequirementId": "odometer-on",
    "video360Required": true
  }
}
```

### تعریف Inspection

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "inspectionId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "sourceRequestId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "trackingCode": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "status": {
      "enum": [
        "DRAFT",
        "UPLOAD_PENDING",
        "SUBMITTED",
        "UNDER_REVIEW",
        "CHANGES_REQUESTED",
        "REJECTED",
        "REVIEW_APPROVED",
        "FORWARD_PENDING",
        "FORWARDED",
        "FORWARD_FAILED"
      ]
    },
    "templateId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "templateVersion": {
      "type": "integer",
      "minimum": 1
    },
    "photoPolicyVersion": {
      "type": "integer",
      "enum": [
        1,
        2
      ]
    },
    "version": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    },
    "previousAttemptId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "location": {
      "$ref": "#/$defs/Location"
    },
    "vehicle": {
      "$ref": "#/$defs/Vehicle"
    }
  },
  "required": [
    "inspectionId",
    "sourceRequestId",
    "trackingCode",
    "status",
    "templateId",
    "templateVersion",
    "photoPolicyVersion",
    "version"
  ]
}
```

### مثال مستقل Inspection

```json
{
  "inspectionId": "insp_contract_001",
  "sourceRequestId": "REQ-DEMO-001",
  "trackingCode": "BDI-8F31K2",
  "status": "DRAFT",
  "templateId": "body-image-guided",
  "templateVersion": 2,
  "photoPolicyVersion": 2,
  "version": "AAAAAAAAB9E="
}
```

### تعریف InspectionPage

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "items": {
      "type": "array",
      "items": {
        "$ref": "#/$defs/Inspection"
      }
    },
    "nextCursor": {
      "type": [
        "string",
        "null"
      ]
    },
    "total": {
      "type": "integer",
      "minimum": 0,
      "maximum": 9007199254740991
    },
    "countsByStatus": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "DRAFT": {
          "type": "integer",
          "minimum": 0
        },
        "UPLOAD_PENDING": {
          "type": "integer",
          "minimum": 0
        },
        "SUBMITTED": {
          "type": "integer",
          "minimum": 0
        },
        "UNDER_REVIEW": {
          "type": "integer",
          "minimum": 0
        },
        "CHANGES_REQUESTED": {
          "type": "integer",
          "minimum": 0
        },
        "REJECTED": {
          "type": "integer",
          "minimum": 0
        },
        "REVIEW_APPROVED": {
          "type": "integer",
          "minimum": 0
        },
        "FORWARD_PENDING": {
          "type": "integer",
          "minimum": 0
        },
        "FORWARDED": {
          "type": "integer",
          "minimum": 0
        },
        "FORWARD_FAILED": {
          "type": "integer",
          "minimum": 0
        }
      },
      "required": []
    }
  },
  "required": [
    "items",
    "nextCursor",
    "total"
  ]
}
```

### مثال مستقل InspectionPage

```json
{
  "items": [
    {
      "inspectionId": "insp_contract_001",
      "sourceRequestId": "REQ-DEMO-001",
      "trackingCode": "BDI-8F31K2",
      "status": "DRAFT",
      "templateId": "body-image-guided",
      "templateVersion": 2,
      "photoPolicyVersion": 2,
      "version": "AAAAAAAAB9E="
    }
  ],
  "nextCursor": null,
  "total": 1
}
```

### تعریف RequestScope

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "requestId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "requestVersion": {
      "type": "integer",
      "minimum": 1
    },
    "requestItemId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    }
  },
  "required": [
    "requestId",
    "requestVersion",
    "requestItemId"
  ]
}
```

### مثال مستقل RequestScope

```json
{
  "requestId": "11111111-1111-4111-8111-111111111111",
  "requestVersion": 1,
  "requestItemId": "11111111-1111-4111-8111-111111111111"
}
```

### تعریف EvidenceRegistration

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "kind": {
      "enum": [
        "photo",
        "video-360"
      ]
    },
    "requirementId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "alternativeId": {
      "enum": [
        "pillar",
        "engine",
        "seat",
        "windshield"
      ]
    },
    "templateId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "templateVersion": {
      "type": "integer",
      "minimum": 1
    },
    "photoPolicyVersion": {
      "type": "integer",
      "enum": [
        1,
        2
      ]
    },
    "revision": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "mimeType": {
      "type": "string",
      "minLength": 1,
      "maxLength": 127
    },
    "byteSize": {
      "type": "integer",
      "minimum": 1,
      "maximum": 9007199254740991
    },
    "capturedAt": {
      "type": "string",
      "format": "date-time"
    },
    "durationSeconds": {
      "type": "number",
      "exclusiveMinimum": 0
    },
    "sha256": {
      "type": "string",
      "pattern": "^[0-9a-f]{64}$"
    },
    "replacesEvidenceId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "request": {
      "$ref": "#/$defs/RequestScope"
    },
    "expectedVersion": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    }
  },
  "required": [
    "kind",
    "templateId",
    "templateVersion",
    "photoPolicyVersion",
    "revision",
    "mimeType",
    "byteSize",
    "capturedAt",
    "expectedVersion"
  ],
  "allOf": [
    {
      "if": {
        "properties": {
          "kind": {
            "const": "photo"
          }
        }
      },
      "then": {
        "required": [
          "requirementId"
        ],
        "properties": {
          "requirementId": {}
        }
      }
    },
    {
      "if": {
        "properties": {
          "kind": {
            "const": "video-360"
          }
        }
      },
      "then": {
        "required": [
          "durationSeconds"
        ],
        "not": {
          "anyOf": [
            {
              "required": [
                "requirementId"
              ],
              "properties": {
                "requirementId": {}
              }
            },
            {
              "required": [
                "alternativeId"
              ],
              "properties": {
                "alternativeId": {}
              }
            }
          ]
        },
        "properties": {
          "durationSeconds": {}
        }
      }
    },
    {
      "if": {
        "properties": {
          "kind": {
            "const": "photo"
          },
          "photoPolicyVersion": {
            "const": 2
          },
          "requirementId": {
            "const": "spec-plate"
          }
        },
        "required": [
          "requirementId"
        ]
      },
      "then": {
        "required": [
          "alternativeId"
        ],
        "properties": {
          "alternativeId": {}
        }
      }
    }
  ]
}
```

### مثال مستقل EvidenceRegistration

```json
{
  "kind": "photo",
  "requirementId": "spec-plate",
  "alternativeId": "pillar",
  "templateId": "body-image-guided",
  "templateVersion": 2,
  "photoPolicyVersion": 2,
  "revision": "client-revision-0002",
  "mimeType": "image/jpeg",
  "byteSize": 420000,
  "capturedAt": "2026-10-26T09:00:00Z",
  "expectedVersion": "AAAAAAAAB9E="
}
```

### تعریف UploadTicket

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "evidenceId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "evidenceVersionId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "uploadId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "uploadUrl": {
      "type": "string"
    },
    "method": {
      "const": "PUT"
    },
    "expiresAt": {
      "type": "string",
      "format": "date-time"
    },
    "version": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    }
  },
  "required": [
    "evidenceId",
    "evidenceVersionId",
    "uploadId",
    "uploadUrl",
    "method",
    "expiresAt",
    "version"
  ]
}
```

### مثال مستقل UploadTicket

```json
{
  "evidenceId": "11111111-1111-4111-8111-111111111111",
  "evidenceVersionId": "22222222-2222-4222-8222-222222222222",
  "uploadId": "33333333-3333-4333-8333-333333333333",
  "uploadUrl": "/api/bazdid/uploads/33333333-3333-4333-8333-333333333333/content",
  "method": "PUT",
  "expiresAt": "2026-10-26T09:00:00Z",
  "version": "AAAAAAAAB9E="
}
```

### تعریف BinaryTransfer

```json
{
  "type": "string",
  "contentMediaType": "application/octet-stream"
}
```

### مثال مستقل BinaryTransfer

```json
"نمونه قراردادی"
```

### تعریف TransferResult

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "uploadId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "state": {
      "const": "staged"
    },
    "bytesReceived": {
      "type": "integer",
      "minimum": 0,
      "maximum": 9007199254740991
    }
  },
  "required": [
    "uploadId",
    "state",
    "bytesReceived"
  ]
}
```

### مثال مستقل TransferResult

```json
{
  "uploadId": "33333333-3333-4333-8333-333333333333",
  "state": "staged",
  "bytesReceived": 420000
}
```

### تعریف CompleteUpload

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "revision": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "byteSize": {
      "type": "integer",
      "minimum": 1
    },
    "sha256": {
      "type": "string",
      "pattern": "^[0-9a-f]{64}$"
    },
    "expectedVersion": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    }
  },
  "required": [
    "revision",
    "byteSize",
    "expectedVersion"
  ]
}
```

### مثال مستقل CompleteUpload

```json
{
  "revision": "client-revision-0002",
  "byteSize": 420000,
  "expectedVersion": "AAAAAAAAB9E="
}
```

### تعریف Evidence

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "evidenceId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "evidenceVersionId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "inspectionId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "kind": {
      "enum": [
        "photo",
        "video-360"
      ]
    },
    "requirementId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "alternativeId": {
      "enum": [
        "pillar",
        "engine",
        "seat",
        "windshield"
      ]
    },
    "revision": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "upload": {
      "enum": [
        "queued",
        "uploading",
        "uploaded",
        "failed",
        "cancelled"
      ]
    },
    "verification": {
      "enum": [
        "not-started",
        "processing",
        "verified",
        "retake-requested"
      ]
    },
    "byteSize": {
      "type": "integer",
      "minimum": 1
    },
    "mimeType": {
      "type": "string"
    },
    "sha256": {
      "type": "string",
      "pattern": "^[0-9a-f]{64}$"
    },
    "current": {
      "type": "boolean"
    },
    "reviewerReason": {
      "type": "string"
    },
    "version": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    }
  },
  "required": [
    "evidenceId",
    "evidenceVersionId",
    "inspectionId",
    "kind",
    "revision",
    "upload",
    "verification",
    "byteSize",
    "mimeType",
    "current",
    "version"
  ],
  "allOf": [
    {
      "if": {
        "properties": {
          "kind": {
            "const": "photo"
          }
        },
        "required": [
          "kind"
        ]
      },
      "then": {
        "properties": {
          "requirementId": {}
        },
        "required": [
          "requirementId"
        ]
      }
    },
    {
      "if": {
        "properties": {
          "kind": {
            "const": "video-360"
          }
        },
        "required": [
          "kind"
        ]
      },
      "then": {
        "not": {
          "anyOf": [
            {
              "required": [
                "requirementId"
              ],
              "properties": {
                "requirementId": {}
              }
            },
            {
              "required": [
                "alternativeId"
              ],
              "properties": {
                "alternativeId": {}
              }
            }
          ]
        }
      }
    }
  ]
}
```

### مثال مستقل Evidence

```json
{
  "evidenceId": "11111111-1111-4111-8111-111111111111",
  "evidenceVersionId": "22222222-2222-4222-8222-222222222222",
  "inspectionId": "insp_contract_001",
  "kind": "photo",
  "requirementId": "spec-plate",
  "alternativeId": "pillar",
  "revision": "client-revision-0002",
  "upload": "uploaded",
  "verification": "processing",
  "byteSize": 420000,
  "mimeType": "image/jpeg",
  "sha256": "0000000000000000000000000000000000000000000000000000000000000000",
  "current": true,
  "version": "AAAAAAAAB9E="
}
```

### تعریف EvidencePage

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "items": {
      "type": "array",
      "items": {
        "$ref": "#/$defs/Evidence"
      }
    },
    "nextCursor": {
      "type": [
        "string",
        "null"
      ]
    }
  },
  "required": [
    "items",
    "nextCursor"
  ]
}
```

### مثال مستقل EvidencePage

```json
{
  "items": [
    {
      "evidenceId": "11111111-1111-4111-8111-111111111111",
      "evidenceVersionId": "22222222-2222-4222-8222-222222222222",
      "inspectionId": "insp_contract_001",
      "kind": "photo",
      "requirementId": "spec-plate",
      "alternativeId": "pillar",
      "revision": "client-revision-0002",
      "upload": "uploaded",
      "verification": "processing",
      "byteSize": 420000,
      "mimeType": "image/jpeg",
      "sha256": "0000000000000000000000000000000000000000000000000000000000000000",
      "current": true,
      "version": "AAAAAAAAB9E="
    }
  ],
  "nextCursor": null
}
```

### تعریف Summary

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "inspection": {
      "$ref": "#/$defs/Inspection"
    },
    "odometer": {
      "$ref": "#/$defs/Odometer"
    },
    "photos": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "completed": {
          "type": "integer",
          "minimum": 0,
          "maximum": 9007199254740991
        },
        "required": {
          "type": "integer",
          "minimum": 0,
          "maximum": 9007199254740991
        }
      },
      "required": [
        "completed",
        "required"
      ]
    },
    "video360": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "accepted": {
          "type": "boolean"
        },
        "durationSeconds": {
          "type": "number",
          "minimum": 0
        }
      },
      "required": [
        "accepted"
      ]
    },
    "media": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "uploaded": {
          "type": "integer",
          "minimum": 0,
          "maximum": 9007199254740991
        },
        "required": {
          "type": "integer",
          "minimum": 0,
          "maximum": 9007199254740991
        },
        "processing": {
          "type": "integer",
          "minimum": 0,
          "maximum": 9007199254740991
        }
      },
      "required": [
        "uploaded",
        "required",
        "processing"
      ]
    },
    "readiness": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "captureComplete": {
          "type": "boolean"
        },
        "requiredMediaUploaded": {
          "type": "boolean"
        },
        "odometerValid": {
          "type": "boolean"
        },
        "blockingUploadFailures": {
          "type": "boolean"
        },
        "factsConfirmed": {
          "type": "boolean"
        },
        "canSubmit": {
          "type": "boolean"
        }
      },
      "required": [
        "captureComplete",
        "requiredMediaUploaded",
        "odometerValid",
        "blockingUploadFailures",
        "factsConfirmed",
        "canSubmit"
      ]
    },
    "blockers": {
      "type": "array",
      "items": {
        "type": "string"
      }
    }
  },
  "required": [
    "inspection",
    "photos",
    "video360",
    "media",
    "readiness",
    "blockers"
  ]
}
```

### مثال مستقل Summary

```json
{
  "inspection": {
    "inspectionId": "insp_contract_001",
    "sourceRequestId": "REQ-DEMO-001",
    "trackingCode": "BDI-8F31K2",
    "status": "DRAFT",
    "templateId": "body-image-guided",
    "templateVersion": 2,
    "photoPolicyVersion": 2,
    "version": "AAAAAAAAB9E="
  },
  "photos": {
    "completed": 11,
    "required": 11
  },
  "odometer": {
    "kilometers": 48320,
    "updatedAt": "2026-10-26T09:00:00Z"
  },
  "video360": {
    "accepted": true,
    "durationSeconds": 48
  },
  "media": {
    "uploaded": 12,
    "required": 12,
    "processing": 2
  },
  "readiness": {
    "captureComplete": true,
    "requiredMediaUploaded": true,
    "odometerValid": true,
    "factsConfirmed": true,
    "canSubmit": true,
    "blockingUploadFailures": false
  },
  "blockers": []
}
```

### تعریف Receipt

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "reference": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "submittedAt": {
      "type": "string",
      "format": "date-time"
    },
    "status": {
      "const": "queued-for-review"
    },
    "inspectionId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "version": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    },
    "reviewEstimateLabel": {
      "type": "string"
    },
    "isEstimate": {
      "type": "boolean"
    }
  },
  "required": [
    "reference",
    "submittedAt",
    "status",
    "inspectionId",
    "version"
  ]
}
```

### مثال مستقل Receipt

```json
{
  "reference": "BDI-8F31K2",
  "submittedAt": "2026-10-26T09:00:00Z",
  "status": "queued-for-review",
  "inspectionId": "insp_contract_001",
  "version": "AAAAAAAAB9E=",
  "reviewEstimateLabel": "۳ تا ۵ روز کاری؛ برآورد نمونه محصول، نه SLA",
  "isEstimate": true
}
```

### تعریف Status

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "inspectionId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "status": {
      "enum": [
        "DRAFT",
        "UPLOAD_PENDING",
        "SUBMITTED",
        "UNDER_REVIEW",
        "CHANGES_REQUESTED",
        "REJECTED",
        "REVIEW_APPROVED",
        "FORWARD_PENDING",
        "FORWARDED",
        "FORWARD_FAILED"
      ]
    },
    "trackingCode": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "version": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    },
    "updatedAt": {
      "type": "string",
      "format": "date-time"
    },
    "customerExplanation": {
      "type": "string"
    },
    "forwarding": {
      "$ref": "#/$defs/Forwarding"
    },
    "corrections": {
      "type": "array",
      "items": {
        "$ref": "#/$defs/FieldCorrection"
      }
    }
  },
  "required": [
    "inspectionId",
    "status",
    "trackingCode",
    "version",
    "updatedAt",
    "corrections"
  ],
  "allOf": [
    {
      "if": {
        "properties": {
          "status": {
            "const": "FORWARDED"
          }
        },
        "required": [
          "status"
        ]
      },
      "then": {
        "required": [
          "forwarding"
        ],
        "properties": {
          "forwarding": {
            "allOf": [
              {
                "$ref": "#/$defs/Forwarding"
              },
              {
                "type": "object",
                "properties": {
                  "phase": {
                    "const": "acknowledged"
                  }
                }
              }
            ]
          }
        }
      }
    }
  ]
}
```

### مثال مستقل Status

```json
{
  "inspectionId": "insp_contract_001",
  "status": "FORWARD_PENDING",
  "trackingCode": "BDI-8F31K2",
  "version": "AAAAAAAAB9E=",
  "updatedAt": "2026-10-26T09:00:00Z",
  "forwarding": {
    "phase": "ready"
  },
  "corrections": []
}
```

### تعریف CorrectionItem

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "id": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "kind": {
      "enum": [
        "photo",
        "video-360",
        "field"
      ]
    },
    "requirementId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "field": {
      "enum": [
        "plate",
        "color",
        "modelYear"
      ]
    },
    "originalEvidenceId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "originalRevision": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "reviewerReason": {
      "type": "string",
      "minLength": 1
    },
    "state": {
      "enum": [
        "requested",
        "submitted",
        "approved"
      ]
    }
  },
  "required": [
    "id",
    "kind",
    "reviewerReason",
    "state"
  ]
}
```

### مثال مستقل CorrectionItem

```json
{
  "id": "11111111-1111-4111-8111-111111111111",
  "kind": "photo",
  "requirementId": "spec-plate",
  "originalEvidenceId": "11111111-1111-4111-8111-111111111111",
  "originalRevision": "client-revision-0001",
  "reviewerReason": "شماره شاسی خوانا نیست.",
  "state": "requested"
}
```

### تعریف EvidenceRequest

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "id": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "inspectionId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "version": {
      "type": "integer",
      "minimum": 1
    },
    "round": {
      "type": "integer",
      "minimum": 1
    },
    "status": {
      "enum": [
        "requested",
        "resubmitting",
        "resubmitted",
        "resubmit-failed",
        "resolved",
        "superseded"
      ]
    },
    "items": {
      "type": "array",
      "items": {
        "$ref": "#/$defs/CorrectionItem"
      },
      "minItems": 1
    },
    "template": {
      "$ref": "#/$defs/CapturePlan"
    }
  },
  "required": [
    "id",
    "inspectionId",
    "version",
    "round",
    "status",
    "items",
    "template"
  ]
}
```

### مثال مستقل EvidenceRequest

```json
{
  "id": "11111111-1111-4111-8111-111111111111",
  "inspectionId": "insp_contract_001",
  "version": 1,
  "round": 1,
  "status": "requested",
  "items": [
    {
      "id": "11111111-1111-4111-8111-111111111111",
      "kind": "photo",
      "requirementId": "spec-plate",
      "originalEvidenceId": "11111111-1111-4111-8111-111111111111",
      "originalRevision": "client-revision-0001",
      "reviewerReason": "شماره شاسی خوانا نیست.",
      "state": "requested"
    }
  ],
  "template": {
    "photoPolicyVersion": 2,
    "templateId": "body-image-guided",
    "templateVersion": 2,
    "sections": [
      {
        "id": "right",
        "title": "نمای راست",
        "order": 1,
        "photoRequirements": [
          {
            "id": "front-45-right",
            "title": "جلو ۴۵° راست",
            "description": "جلوی خودرو و سمت راست به صورت کامل دیده شود.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-right.webp",
            "instructions": [
              "جلوی خودرو و سمت راست به طور کامل داخل کادر باشد.",
              "حدود ۳ متر از خودرو فاصله بگیرید.",
              "از زاویه ۴۵ درجه سمت راست عکس بگیرید."
            ],
            "distance": "۳ متر",
            "height": "کمر",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "خودرو کامل در کادر"
            ],
            "guidanceTopics": [
              "frame",
              "distance",
              "angle"
            ]
          },
          {
            "id": "back-45-right",
            "title": "عقب ۴۵° راست",
            "description": "عقب خودرو و سمت راست به صورت کامل دیده شود.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/back-45-right.webp",
            "instructions": [
              "تمام قسمت عقب و سمت راست خودرو داخل کادر باشد.",
              "خودرو را از زاویه ۴۵ درجه ثبت کنید.",
              "در نور کافی و بدون سایه شدید عکاسی کنید."
            ],
            "distance": "۳ متر",
            "height": "کمر",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "خودرو کامل در کادر"
            ],
            "guidanceTopics": [
              "frame",
              "angle",
              "glare"
            ]
          }
        ]
      },
      {
        "id": "left",
        "title": "نمای چپ",
        "order": 2,
        "photoRequirements": [
          {
            "id": "front-45-left",
            "title": "جلو ۴۵° چپ",
            "description": "جلوی خودرو و سمت چپ به صورت کامل دیده شود.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-left.webp",
            "instructions": [
              "جلوی خودرو و سمت چپ به طور کامل داخل کادر باشد.",
              "حدود ۳ متر از خودرو فاصله بگیرید.",
              "از زاویه ۴۵ درجه سمت چپ عکس بگیرید."
            ],
            "distance": "۳ متر",
            "height": "کمر",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "خودرو کامل در کادر"
            ],
            "guidanceTopics": [
              "frame",
              "distance",
              "angle"
            ]
          },
          {
            "id": "back-45-left",
            "title": "عقب ۴۵° چپ",
            "description": "عقب خودرو و سمت چپ به صورت کامل دیده شود.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/back-45-left.webp",
            "instructions": [
              "تمام قسمت عقب و سمت چپ خودرو داخل کادر باشد.",
              "خودرو را از زاویه ۴۵ درجه ثبت کنید.",
              "در نور کافی و بدون سایه شدید عکاسی کنید."
            ],
            "distance": "۳ متر",
            "height": "کمر",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "خودرو کامل در کادر"
            ],
            "guidanceTopics": [
              "frame",
              "angle",
              "glare"
            ]
          }
        ]
      },
      {
        "id": "front",
        "title": "جلو",
        "order": 3,
        "photoRequirements": [
          {
            "id": "front-plate",
            "title": "نمای مستقیم جلو با پلاک",
            "description": "یک عکس مستقیم از نمای جلوی خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/front-plate.webp",
            "instructions": [
              "مستقیم روبه‌روی خودرو بایستید؛ خودرو وسط کادر باشد.",
              "نمای کامل جلو را بدون برش و زاویه شدید ثبت کنید.",
              "پلاک بدون بازتاب نور و کاملاً خوانا باشد."
            ],
            "distance": "۳ متر",
            "height": "چراغ‌ها",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "پلاک خوانا است"
            ],
            "guidanceTopics": [
              "angle",
              "frame",
              "text"
            ]
          }
        ]
      },
      {
        "id": "rear",
        "title": "عقب",
        "order": 4,
        "photoRequirements": [
          {
            "id": "rear-plate",
            "title": "نمای مستقیم عقب با پلاک",
            "description": "یک عکس مستقیم از نمای عقب خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/rear-plate.webp",
            "instructions": [
              "مستقیم پشت خودرو بایستید؛ خودرو وسط کادر باشد.",
              "تمام نمای عقب بدون برش و زاویه شدید داخل کادر باشد.",
              "پلاک کاملاً خوانا و بدون بازتاب باشد."
            ],
            "distance": "۳ متر",
            "height": "چراغ‌ها",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "پلاک خوانا است"
            ],
            "guidanceTopics": [
              "angle",
              "frame",
              "text"
            ]
          }
        ]
      },
      {
        "id": "cabin",
        "title": "کابین",
        "order": 5,
        "photoRequirements": [
          {
            "id": "odometer-on",
            "title": "کیلومترشمار",
            "description": "خودرو را روشن کنید و تصویری واضح از کیلومترشمار بگیرید.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/odometer-on.webp",
            "instructions": [
              "خودرو را روشن و در حالت توقف نگه دارید.",
              "تمام صفحه کیلومترشمار در کادر باشد.",
              "عدد کیلومتر خوانا باشد؛ از بازتاب نور جلوگیری کنید."
            ],
            "distance": "نزدیک",
            "height": "داشبورد",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "عدد کیلومتر خوانا است"
            ],
            "guidanceTopics": [
              "ignition",
              "frame",
              "glare"
            ]
          },
          {
            "id": "driver-interior",
            "title": "نمای داخل کابین از سمت راننده",
            "description": "از سمت راننده تصویری بگیرید که فضای داخلی خودرو به صورت واضح دیده شود.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/driver-interior.webp",
            "instructions": [
              "درِ سمت راننده را باز کنید.",
              "فرمان، داشبورد و صندلی‌ها دیده شوند.",
              "خیلی نزدیک نشوید؛ فضای داخلی کامل دیده شود."
            ],
            "distance": "۱ متر",
            "height": "درِ راننده",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "کابین کامل در کادر"
            ],
            "guidanceTopics": [
              "interior",
              "frame",
              "distance"
            ]
          }
        ]
      },
      {
        "id": "engine-details",
        "title": "موتور و مشخصات",
        "order": 6,
        "photoRequirements": [
          {
            "id": "engine-bay",
            "title": "محفظه موتور",
            "description": "کاپوت را باز کنید و یک تصویر کامل و واضح از محفظه موتور بگیرید.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/engine-bay.webp",
            "instructions": [
              "خودرو متوقف باشد؛ کاپوت را کاملاً و ایمن باز کنید.",
              "تمام محفظه موتور دیده شود.",
              "گوشی ثابت و تصویر بدون تاری باشد."
            ],
            "distance": "۱ متر",
            "height": "سینه",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "محفظه کامل در کادر"
            ],
            "guidanceTopics": [
              "hood",
              "frame",
              "steady"
            ]
          },
          {
            "id": "spec-plate",
            "title": "محل شماره شاسی خودرو",
            "description": "شماره شاسی خودرو — انتخاب یکی از چهار گزینه. فقط یک تصویر لازم است.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/spec-plate.webp",
            "instructions": [
              "از نزدیک روی پلاک مشخصات فوکوس کنید.",
              "تمام متن پلاک داخل کادر باشد.",
              "نوشته‌ها خوانا و بدون بازتاب نور باشند."
            ],
            "distance": "۳۰ سانتی‌متر",
            "height": "هم‌سطح پلاک",
            "orientation": "landscape",
            "choice": {
              "groupId": "vehicle-identification",
              "alternatives": [
                "pillar",
                "engine",
                "seat",
                "windshield"
              ]
            },
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "اطلاعات قابل خواندن است"
            ],
            "guidanceTopics": [
              "text",
              "frame",
              "glare"
            ]
          }
        ]
      },
      {
        "id": "roof",
        "title": "سقف",
        "order": 7,
        "photoRequirements": [
          {
            "id": "car-roof",
            "title": "نمای سقف",
            "description": "تمام سطح سقف خودرو را در تصویر نشان دهید.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/car-roof.webp",
            "instructions": [
              "از موقعیتی ایمن، گوشی را بالاتر بگیرید.",
              "بیشترین سطح سقف و گوشه‌های اصلی در کادر باشند.",
              "برای عکاسی روی خودرو نایستید."
            ],
            "distance": "۱ متر",
            "height": "بالاتر از سقف",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "سقف کامل در کادر"
            ],
            "guidanceTopics": [
              "roof",
              "frame",
              "steady"
            ]
          }
        ]
      }
    ],
    "captureRequirements": {
      "odometerRequirementId": "odometer-on",
      "video360Required": true
    }
  }
}
```

### تعریف EvidenceRequestPage

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "items": {
      "type": "array",
      "items": {
        "$ref": "#/$defs/EvidenceRequest"
      }
    }
  },
  "required": [
    "items"
  ]
}
```

### مثال مستقل EvidenceRequestPage

```json
{
  "items": [
    {
      "id": "11111111-1111-4111-8111-111111111111",
      "inspectionId": "insp_contract_001",
      "version": 1,
      "round": 1,
      "status": "requested",
      "items": [
        {
          "id": "11111111-1111-4111-8111-111111111111",
          "kind": "photo",
          "requirementId": "spec-plate",
          "originalEvidenceId": "11111111-1111-4111-8111-111111111111",
          "originalRevision": "client-revision-0001",
          "reviewerReason": "شماره شاسی خوانا نیست.",
          "state": "requested"
        }
      ],
      "template": {
        "photoPolicyVersion": 2,
        "templateId": "body-image-guided",
        "templateVersion": 2,
        "sections": [
          {
            "id": "right",
            "title": "نمای راست",
            "order": 1,
            "photoRequirements": [
              {
                "id": "front-45-right",
                "title": "جلو ۴۵° راست",
                "description": "جلوی خودرو و سمت راست به صورت کامل دیده شود.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-right.webp",
                "instructions": [
                  "جلوی خودرو و سمت راست به طور کامل داخل کادر باشد.",
                  "حدود ۳ متر از خودرو فاصله بگیرید.",
                  "از زاویه ۴۵ درجه سمت راست عکس بگیرید."
                ],
                "distance": "۳ متر",
                "height": "کمر",
                "orientation": "landscape",
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "خودرو کامل در کادر"
                ],
                "guidanceTopics": [
                  "frame",
                  "distance",
                  "angle"
                ]
              },
              {
                "id": "back-45-right",
                "title": "عقب ۴۵° راست",
                "description": "عقب خودرو و سمت راست به صورت کامل دیده شود.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/back-45-right.webp",
                "instructions": [
                  "تمام قسمت عقب و سمت راست خودرو داخل کادر باشد.",
                  "خودرو را از زاویه ۴۵ درجه ثبت کنید.",
                  "در نور کافی و بدون سایه شدید عکاسی کنید."
                ],
                "distance": "۳ متر",
                "height": "کمر",
                "orientation": "landscape",
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "خودرو کامل در کادر"
                ],
                "guidanceTopics": [
                  "frame",
                  "angle",
                  "glare"
                ]
              }
            ]
          },
          {
            "id": "left",
            "title": "نمای چپ",
            "order": 2,
            "photoRequirements": [
              {
                "id": "front-45-left",
                "title": "جلو ۴۵° چپ",
                "description": "جلوی خودرو و سمت چپ به صورت کامل دیده شود.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-left.webp",
                "instructions": [
                  "جلوی خودرو و سمت چپ به طور کامل داخل کادر باشد.",
                  "حدود ۳ متر از خودرو فاصله بگیرید.",
                  "از زاویه ۴۵ درجه سمت چپ عکس بگیرید."
                ],
                "distance": "۳ متر",
                "height": "کمر",
                "orientation": "landscape",
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "خودرو کامل در کادر"
                ],
                "guidanceTopics": [
                  "frame",
                  "distance",
                  "angle"
                ]
              },
              {
                "id": "back-45-left",
                "title": "عقب ۴۵° چپ",
                "description": "عقب خودرو و سمت چپ به صورت کامل دیده شود.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/back-45-left.webp",
                "instructions": [
                  "تمام قسمت عقب و سمت چپ خودرو داخل کادر باشد.",
                  "خودرو را از زاویه ۴۵ درجه ثبت کنید.",
                  "در نور کافی و بدون سایه شدید عکاسی کنید."
                ],
                "distance": "۳ متر",
                "height": "کمر",
                "orientation": "landscape",
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "خودرو کامل در کادر"
                ],
                "guidanceTopics": [
                  "frame",
                  "angle",
                  "glare"
                ]
              }
            ]
          },
          {
            "id": "front",
            "title": "جلو",
            "order": 3,
            "photoRequirements": [
              {
                "id": "front-plate",
                "title": "نمای مستقیم جلو با پلاک",
                "description": "یک عکس مستقیم از نمای جلوی خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/front-plate.webp",
                "instructions": [
                  "مستقیم روبه‌روی خودرو بایستید؛ خودرو وسط کادر باشد.",
                  "نمای کامل جلو را بدون برش و زاویه شدید ثبت کنید.",
                  "پلاک بدون بازتاب نور و کاملاً خوانا باشد."
                ],
                "distance": "۳ متر",
                "height": "چراغ‌ها",
                "orientation": "landscape",
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "پلاک خوانا است"
                ],
                "guidanceTopics": [
                  "angle",
                  "frame",
                  "text"
                ]
              }
            ]
          },
          {
            "id": "rear",
            "title": "عقب",
            "order": 4,
            "photoRequirements": [
              {
                "id": "rear-plate",
                "title": "نمای مستقیم عقب با پلاک",
                "description": "یک عکس مستقیم از نمای عقب خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/rear-plate.webp",
                "instructions": [
                  "مستقیم پشت خودرو بایستید؛ خودرو وسط کادر باشد.",
                  "تمام نمای عقب بدون برش و زاویه شدید داخل کادر باشد.",
                  "پلاک کاملاً خوانا و بدون بازتاب باشد."
                ],
                "distance": "۳ متر",
                "height": "چراغ‌ها",
                "orientation": "landscape",
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "پلاک خوانا است"
                ],
                "guidanceTopics": [
                  "angle",
                  "frame",
                  "text"
                ]
              }
            ]
          },
          {
            "id": "cabin",
            "title": "کابین",
            "order": 5,
            "photoRequirements": [
              {
                "id": "odometer-on",
                "title": "کیلومترشمار",
                "description": "خودرو را روشن کنید و تصویری واضح از کیلومترشمار بگیرید.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/odometer-on.webp",
                "instructions": [
                  "خودرو را روشن و در حالت توقف نگه دارید.",
                  "تمام صفحه کیلومترشمار در کادر باشد.",
                  "عدد کیلومتر خوانا باشد؛ از بازتاب نور جلوگیری کنید."
                ],
                "distance": "نزدیک",
                "height": "داشبورد",
                "orientation": "landscape",
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "عدد کیلومتر خوانا است"
                ],
                "guidanceTopics": [
                  "ignition",
                  "frame",
                  "glare"
                ]
              },
              {
                "id": "driver-interior",
                "title": "نمای داخل کابین از سمت راننده",
                "description": "از سمت راننده تصویری بگیرید که فضای داخلی خودرو به صورت واضح دیده شود.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/driver-interior.webp",
                "instructions": [
                  "درِ سمت راننده را باز کنید.",
                  "فرمان، داشبورد و صندلی‌ها دیده شوند.",
                  "خیلی نزدیک نشوید؛ فضای داخلی کامل دیده شود."
                ],
                "distance": "۱ متر",
                "height": "درِ راننده",
                "orientation": "landscape",
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "کابین کامل در کادر"
                ],
                "guidanceTopics": [
                  "interior",
                  "frame",
                  "distance"
                ]
              }
            ]
          },
          {
            "id": "engine-details",
            "title": "موتور و مشخصات",
            "order": 6,
            "photoRequirements": [
              {
                "id": "engine-bay",
                "title": "محفظه موتور",
                "description": "کاپوت را باز کنید و یک تصویر کامل و واضح از محفظه موتور بگیرید.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/engine-bay.webp",
                "instructions": [
                  "خودرو متوقف باشد؛ کاپوت را کاملاً و ایمن باز کنید.",
                  "تمام محفظه موتور دیده شود.",
                  "گوشی ثابت و تصویر بدون تاری باشد."
                ],
                "distance": "۱ متر",
                "height": "سینه",
                "orientation": "landscape",
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "محفظه کامل در کادر"
                ],
                "guidanceTopics": [
                  "hood",
                  "frame",
                  "steady"
                ]
              },
              {
                "id": "spec-plate",
                "title": "محل شماره شاسی خودرو",
                "description": "شماره شاسی خودرو — انتخاب یکی از چهار گزینه. فقط یک تصویر لازم است.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/spec-plate.webp",
                "instructions": [
                  "از نزدیک روی پلاک مشخصات فوکوس کنید.",
                  "تمام متن پلاک داخل کادر باشد.",
                  "نوشته‌ها خوانا و بدون بازتاب نور باشند."
                ],
                "distance": "۳۰ سانتی‌متر",
                "height": "هم‌سطح پلاک",
                "orientation": "landscape",
                "choice": {
                  "groupId": "vehicle-identification",
                  "alternatives": [
                    "pillar",
                    "engine",
                    "seat",
                    "windshield"
                  ]
                },
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "اطلاعات قابل خواندن است"
                ],
                "guidanceTopics": [
                  "text",
                  "frame",
                  "glare"
                ]
              }
            ]
          },
          {
            "id": "roof",
            "title": "سقف",
            "order": 7,
            "photoRequirements": [
              {
                "id": "car-roof",
                "title": "نمای سقف",
                "description": "تمام سطح سقف خودرو را در تصویر نشان دهید.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/car-roof.webp",
                "instructions": [
                  "از موقعیتی ایمن، گوشی را بالاتر بگیرید.",
                  "بیشترین سطح سقف و گوشه‌های اصلی در کادر باشند.",
                  "برای عکاسی روی خودرو نایستید."
                ],
                "distance": "۱ متر",
                "height": "بالاتر از سقف",
                "orientation": "landscape",
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "سقف کامل در کادر"
                ],
                "guidanceTopics": [
                  "roof",
                  "frame",
                  "steady"
                ]
              }
            ]
          }
        ],
        "captureRequirements": {
          "odometerRequirementId": "odometer-on",
          "video360Required": true
        }
      }
    }
  ]
}
```

### تعریف ResubmitRequest

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "requestId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "requestVersion": {
      "type": "integer",
      "minimum": 1
    },
    "candidateEvidenceIds": {
      "type": "array",
      "items": {
        "type": "string",
        "minLength": 1,
        "maxLength": 160
      },
      "minItems": 1,
      "uniqueItems": true
    },
    "expectedVersion": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    }
  },
  "required": [
    "requestId",
    "requestVersion",
    "candidateEvidenceIds",
    "expectedVersion"
  ]
}
```

### مثال مستقل ResubmitRequest

```json
{
  "requestId": "11111111-1111-4111-8111-111111111111",
  "requestVersion": 1,
  "candidateEvidenceIds": [
    "00000000-0000-4000-8000-000000000021"
  ],
  "expectedVersion": "AAAAAAAAB9E="
}
```

### تعریف FieldProposal

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "expectedVersion": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    },
    "field": {
      "enum": [
        "plate",
        "color",
        "modelYear"
      ]
    },
    "value": {
      "oneOf": [
        {
          "$ref": "#/$defs/Plate"
        },
        {
          "type": "string",
          "minLength": 1,
          "maxLength": 80
        },
        {
          "type": "integer",
          "minimum": 1000,
          "maximum": 3000
        }
      ]
    }
  },
  "required": [
    "expectedVersion",
    "field",
    "value"
  ],
  "allOf": [
    {
      "if": {
        "properties": {
          "field": {
            "const": "plate"
          }
        }
      },
      "then": {
        "properties": {
          "value": {
            "$ref": "#/$defs/Plate"
          }
        }
      }
    },
    {
      "if": {
        "properties": {
          "field": {
            "const": "color"
          }
        }
      },
      "then": {
        "properties": {
          "value": {
            "type": "string",
            "minLength": 1,
            "maxLength": 80
          }
        }
      }
    },
    {
      "if": {
        "properties": {
          "field": {
            "const": "modelYear"
          }
        }
      },
      "then": {
        "properties": {
          "value": {
            "type": "integer",
            "minimum": 1000,
            "maximum": 3000
          }
        }
      }
    }
  ]
}
```

### مثال مستقل FieldProposal

```json
{
  "expectedVersion": "AAAAAAAAB9E=",
  "field": "plate",
  "value": {
    "firstTwoDigits": "12",
    "letter": "ب",
    "threeDigits": "345",
    "regionDigits": "67"
  }
}
```

### تعریف AssignmentRequest

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "reviewerId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "reassign": {
      "type": "boolean"
    },
    "expectedVersion": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    }
  },
  "required": [
    "reviewerId",
    "reassign",
    "expectedVersion"
  ]
}
```

### مثال مستقل AssignmentRequest

```json
{
  "reviewerId": "11111111-1111-4111-8111-111111111111",
  "reassign": true,
  "expectedVersion": "AAAAAAAAB9E="
}
```

### تعریف ReviewerPolicy

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "mode": {
      "enum": [
        "manual",
        "random"
      ]
    },
    "capacities": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "staffId": {
            "type": "string",
            "minLength": 1,
            "maxLength": 160
          },
          "capacity": {
            "type": "integer",
            "minimum": 0,
            "maximum": 10000
          }
        },
        "required": [
          "staffId",
          "capacity"
        ]
      }
    },
    "expectedVersion": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    }
  },
  "required": [
    "mode",
    "capacities",
    "expectedVersion"
  ]
}
```

### مثال مستقل ReviewerPolicy

```json
{
  "mode": "manual",
  "capacities": [],
  "expectedVersion": "AAAAAAAAB9E="
}
```

### تعریف EvidenceDecision

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "evidenceId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "revision": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "decision": {
      "enum": [
        "approved",
        "rejected"
      ]
    },
    "reason": {
      "type": "string",
      "maxLength": 2000,
      "minLength": 1
    },
    "expectedVersion": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    }
  },
  "required": [
    "evidenceId",
    "revision",
    "decision",
    "expectedVersion"
  ],
  "allOf": [
    {
      "if": {
        "properties": {
          "decision": {
            "const": "rejected"
          }
        },
        "required": [
          "decision"
        ]
      },
      "then": {
        "properties": {
          "reason": {}
        },
        "required": [
          "reason"
        ]
      }
    }
  ]
}
```

### مثال مستقل EvidenceDecision

```json
{
  "evidenceId": "11111111-1111-4111-8111-111111111111",
  "revision": "client-revision-0002",
  "decision": "approved",
  "expectedVersion": "AAAAAAAAB9E="
}
```

### تعریف FieldRequest

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "field": {
      "enum": [
        "plate",
        "color",
        "modelYear"
      ]
    },
    "customerReason": {
      "type": "string",
      "minLength": 1,
      "maxLength": 2000
    },
    "expectedVersion": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    }
  },
  "required": [
    "field",
    "customerReason",
    "expectedVersion"
  ]
}
```

### مثال مستقل FieldRequest

```json
{
  "field": "plate",
  "customerReason": "رنگ ثبت‌شده با خودرو تطبیق ندارد.",
  "expectedVersion": "AAAAAAAAB9E="
}
```

### تعریف FieldDecision

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "decision": {
      "const": "approved"
    },
    "proposalVersion": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    },
    "expectedVersion": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    }
  },
  "required": [
    "decision",
    "proposalVersion",
    "expectedVersion"
  ]
}
```

### مثال مستقل FieldDecision

```json
{
  "decision": "approved",
  "proposalVersion": "AAAAAAAAB9E=",
  "expectedVersion": "AAAAAAAAB9E="
}
```

### تعریف NoteRequest

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "text": {
      "type": "string",
      "minLength": 1,
      "maxLength": 4000
    },
    "expectedVersion": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    }
  },
  "required": [
    "text",
    "expectedVersion"
  ]
}
```

### مثال مستقل NoteRequest

```json
{
  "text": "یادداشت نمونه برای کارکنان؛ عمومی نیست.",
  "expectedVersion": "AAAAAAAAB9E="
}
```

### تعریف FinalDecision

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "decision": {
      "enum": [
        "approved",
        "rejected"
      ]
    },
    "customerReason": {
      "type": "string",
      "maxLength": 2000,
      "minLength": 1
    },
    "expectedVersion": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    }
  },
  "required": [
    "decision",
    "expectedVersion"
  ],
  "allOf": [
    {
      "if": {
        "properties": {
          "decision": {
            "const": "rejected"
          }
        },
        "required": [
          "decision"
        ]
      },
      "then": {
        "properties": {
          "customerReason": {}
        },
        "required": [
          "customerReason"
        ]
      }
    }
  ]
}
```

### مثال مستقل FinalDecision

```json
{
  "decision": "approved",
  "expectedVersion": "AAAAAAAAB9E="
}
```

### تعریف Case

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "caseId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "inspection": {
      "$ref": "#/$defs/Summary"
    },
    "reviewerId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "version": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    },
    "internalNotes": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "text": {
            "type": "string"
          },
          "actorId": {
            "type": "string",
            "minLength": 1,
            "maxLength": 160
          },
          "at": {
            "type": "string",
            "format": "date-time"
          }
        },
        "required": [
          "text",
          "actorId",
          "at"
        ]
      }
    },
    "evidence": {
      "type": "array",
      "items": {
        "$ref": "#/$defs/Evidence"
      }
    },
    "reference": {
      "type": "string",
      "minLength": 1
    },
    "submittedAt": {
      "type": "string",
      "format": "date-time"
    },
    "status": {
      "enum": [
        "awaiting-assignment",
        "in-review",
        "needs-more-evidence",
        "review-complete"
      ]
    },
    "template": {
      "$ref": "#/$defs/CapturePlan"
    },
    "decisions": {
      "type": "array",
      "items": {
        "$ref": "#/$defs/ReviewDecision"
      }
    },
    "fieldCorrections": {
      "type": "array",
      "items": {
        "$ref": "#/$defs/FieldCorrection"
      }
    },
    "finalDecision": {
      "$ref": "#/$defs/FinalReview"
    },
    "forwarding": {
      "$ref": "#/$defs/Forwarding"
    },
    "evidenceHistory": {
      "type": "array",
      "items": {
        "$ref": "#/$defs/Evidence"
      }
    }
  },
  "required": [
    "caseId",
    "inspection",
    "version",
    "evidence",
    "reference",
    "submittedAt",
    "status",
    "template",
    "decisions",
    "fieldCorrections"
  ]
}
```

### مثال مستقل Case

```json
{
  "caseId": "insp_contract_001",
  "inspection": {
    "inspection": {
      "inspectionId": "insp_contract_001",
      "sourceRequestId": "REQ-DEMO-001",
      "trackingCode": "BDI-8F31K2",
      "status": "UNDER_REVIEW",
      "templateId": "body-image-guided",
      "templateVersion": 2,
      "photoPolicyVersion": 2,
      "version": "AAAAAAAAB9E="
    },
    "photos": {
      "completed": 11,
      "required": 11
    },
    "odometer": {
      "kilometers": 48320,
      "updatedAt": "2026-10-26T09:00:00Z"
    },
    "video360": {
      "accepted": true,
      "durationSeconds": 48
    },
    "media": {
      "uploaded": 12,
      "required": 12,
      "processing": 2
    },
    "readiness": {
      "captureComplete": true,
      "requiredMediaUploaded": true,
      "odometerValid": true,
      "factsConfirmed": true,
      "canSubmit": true,
      "blockingUploadFailures": false
    },
    "blockers": []
  },
  "version": "AAAAAAAAB9E=",
  "evidence": [
    {
      "evidenceId": "11111111-1111-4111-8111-111111111111",
      "evidenceVersionId": "22222222-2222-4222-8222-222222222222",
      "inspectionId": "insp_contract_001",
      "kind": "photo",
      "requirementId": "spec-plate",
      "alternativeId": "pillar",
      "revision": "client-revision-0002",
      "upload": "uploaded",
      "verification": "processing",
      "byteSize": 420000,
      "mimeType": "image/jpeg",
      "sha256": "0000000000000000000000000000000000000000000000000000000000000000",
      "current": true,
      "version": "AAAAAAAAB9E="
    }
  ],
  "internalNotes": [],
  "reference": "BDI-8F31K2",
  "submittedAt": "2026-10-27T08:30:00Z",
  "status": "in-review",
  "template": {
    "photoPolicyVersion": 2,
    "templateId": "body-image-guided",
    "templateVersion": 2,
    "sections": [
      {
        "id": "right",
        "title": "نمای راست",
        "order": 1,
        "photoRequirements": [
          {
            "id": "front-45-right",
            "title": "جلو ۴۵° راست",
            "description": "جلوی خودرو و سمت راست به صورت کامل دیده شود.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-right.webp",
            "instructions": [
              "جلوی خودرو و سمت راست به طور کامل داخل کادر باشد.",
              "حدود ۳ متر از خودرو فاصله بگیرید.",
              "از زاویه ۴۵ درجه سمت راست عکس بگیرید."
            ],
            "distance": "۳ متر",
            "height": "کمر",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "خودرو کامل در کادر"
            ],
            "guidanceTopics": [
              "frame",
              "distance",
              "angle"
            ]
          },
          {
            "id": "back-45-right",
            "title": "عقب ۴۵° راست",
            "description": "عقب خودرو و سمت راست به صورت کامل دیده شود.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/back-45-right.webp",
            "instructions": [
              "تمام قسمت عقب و سمت راست خودرو داخل کادر باشد.",
              "خودرو را از زاویه ۴۵ درجه ثبت کنید.",
              "در نور کافی و بدون سایه شدید عکاسی کنید."
            ],
            "distance": "۳ متر",
            "height": "کمر",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "خودرو کامل در کادر"
            ],
            "guidanceTopics": [
              "frame",
              "angle",
              "glare"
            ]
          }
        ]
      },
      {
        "id": "left",
        "title": "نمای چپ",
        "order": 2,
        "photoRequirements": [
          {
            "id": "front-45-left",
            "title": "جلو ۴۵° چپ",
            "description": "جلوی خودرو و سمت چپ به صورت کامل دیده شود.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-left.webp",
            "instructions": [
              "جلوی خودرو و سمت چپ به طور کامل داخل کادر باشد.",
              "حدود ۳ متر از خودرو فاصله بگیرید.",
              "از زاویه ۴۵ درجه سمت چپ عکس بگیرید."
            ],
            "distance": "۳ متر",
            "height": "کمر",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "خودرو کامل در کادر"
            ],
            "guidanceTopics": [
              "frame",
              "distance",
              "angle"
            ]
          },
          {
            "id": "back-45-left",
            "title": "عقب ۴۵° چپ",
            "description": "عقب خودرو و سمت چپ به صورت کامل دیده شود.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/back-45-left.webp",
            "instructions": [
              "تمام قسمت عقب و سمت چپ خودرو داخل کادر باشد.",
              "خودرو را از زاویه ۴۵ درجه ثبت کنید.",
              "در نور کافی و بدون سایه شدید عکاسی کنید."
            ],
            "distance": "۳ متر",
            "height": "کمر",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "خودرو کامل در کادر"
            ],
            "guidanceTopics": [
              "frame",
              "angle",
              "glare"
            ]
          }
        ]
      },
      {
        "id": "front",
        "title": "جلو",
        "order": 3,
        "photoRequirements": [
          {
            "id": "front-plate",
            "title": "نمای مستقیم جلو با پلاک",
            "description": "یک عکس مستقیم از نمای جلوی خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/front-plate.webp",
            "instructions": [
              "مستقیم روبه‌روی خودرو بایستید؛ خودرو وسط کادر باشد.",
              "نمای کامل جلو را بدون برش و زاویه شدید ثبت کنید.",
              "پلاک بدون بازتاب نور و کاملاً خوانا باشد."
            ],
            "distance": "۳ متر",
            "height": "چراغ‌ها",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "پلاک خوانا است"
            ],
            "guidanceTopics": [
              "angle",
              "frame",
              "text"
            ]
          }
        ]
      },
      {
        "id": "rear",
        "title": "عقب",
        "order": 4,
        "photoRequirements": [
          {
            "id": "rear-plate",
            "title": "نمای مستقیم عقب با پلاک",
            "description": "یک عکس مستقیم از نمای عقب خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/rear-plate.webp",
            "instructions": [
              "مستقیم پشت خودرو بایستید؛ خودرو وسط کادر باشد.",
              "تمام نمای عقب بدون برش و زاویه شدید داخل کادر باشد.",
              "پلاک کاملاً خوانا و بدون بازتاب باشد."
            ],
            "distance": "۳ متر",
            "height": "چراغ‌ها",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "پلاک خوانا است"
            ],
            "guidanceTopics": [
              "angle",
              "frame",
              "text"
            ]
          }
        ]
      },
      {
        "id": "cabin",
        "title": "کابین",
        "order": 5,
        "photoRequirements": [
          {
            "id": "odometer-on",
            "title": "کیلومترشمار",
            "description": "خودرو را روشن کنید و تصویری واضح از کیلومترشمار بگیرید.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/odometer-on.webp",
            "instructions": [
              "خودرو را روشن و در حالت توقف نگه دارید.",
              "تمام صفحه کیلومترشمار در کادر باشد.",
              "عدد کیلومتر خوانا باشد؛ از بازتاب نور جلوگیری کنید."
            ],
            "distance": "نزدیک",
            "height": "داشبورد",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "عدد کیلومتر خوانا است"
            ],
            "guidanceTopics": [
              "ignition",
              "frame",
              "glare"
            ]
          },
          {
            "id": "driver-interior",
            "title": "نمای داخل کابین از سمت راننده",
            "description": "از سمت راننده تصویری بگیرید که فضای داخلی خودرو به صورت واضح دیده شود.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/driver-interior.webp",
            "instructions": [
              "درِ سمت راننده را باز کنید.",
              "فرمان، داشبورد و صندلی‌ها دیده شوند.",
              "خیلی نزدیک نشوید؛ فضای داخلی کامل دیده شود."
            ],
            "distance": "۱ متر",
            "height": "درِ راننده",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "کابین کامل در کادر"
            ],
            "guidanceTopics": [
              "interior",
              "frame",
              "distance"
            ]
          }
        ]
      },
      {
        "id": "engine-details",
        "title": "موتور و مشخصات",
        "order": 6,
        "photoRequirements": [
          {
            "id": "engine-bay",
            "title": "محفظه موتور",
            "description": "کاپوت را باز کنید و یک تصویر کامل و واضح از محفظه موتور بگیرید.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/engine-bay.webp",
            "instructions": [
              "خودرو متوقف باشد؛ کاپوت را کاملاً و ایمن باز کنید.",
              "تمام محفظه موتور دیده شود.",
              "گوشی ثابت و تصویر بدون تاری باشد."
            ],
            "distance": "۱ متر",
            "height": "سینه",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "محفظه کامل در کادر"
            ],
            "guidanceTopics": [
              "hood",
              "frame",
              "steady"
            ]
          },
          {
            "id": "spec-plate",
            "title": "محل شماره شاسی خودرو",
            "description": "شماره شاسی خودرو — انتخاب یکی از چهار گزینه. فقط یک تصویر لازم است.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/spec-plate.webp",
            "instructions": [
              "از نزدیک روی پلاک مشخصات فوکوس کنید.",
              "تمام متن پلاک داخل کادر باشد.",
              "نوشته‌ها خوانا و بدون بازتاب نور باشند."
            ],
            "distance": "۳۰ سانتی‌متر",
            "height": "هم‌سطح پلاک",
            "orientation": "landscape",
            "choice": {
              "groupId": "vehicle-identification",
              "alternatives": [
                "pillar",
                "engine",
                "seat",
                "windshield"
              ]
            },
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "اطلاعات قابل خواندن است"
            ],
            "guidanceTopics": [
              "text",
              "frame",
              "glare"
            ]
          }
        ]
      },
      {
        "id": "roof",
        "title": "سقف",
        "order": 7,
        "photoRequirements": [
          {
            "id": "car-roof",
            "title": "نمای سقف",
            "description": "تمام سطح سقف خودرو را در تصویر نشان دهید.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/car-roof.webp",
            "instructions": [
              "از موقعیتی ایمن، گوشی را بالاتر بگیرید.",
              "بیشترین سطح سقف و گوشه‌های اصلی در کادر باشند.",
              "برای عکاسی روی خودرو نایستید."
            ],
            "distance": "۱ متر",
            "height": "بالاتر از سقف",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "سقف کامل در کادر"
            ],
            "guidanceTopics": [
              "roof",
              "frame",
              "steady"
            ]
          }
        ]
      }
    ],
    "captureRequirements": {
      "odometerRequirementId": "odometer-on",
      "video360Required": true
    }
  },
  "decisions": [
    {
      "id": "decision-example",
      "requirementId": "spec-plate",
      "revision": "client-revision-0002",
      "evidenceId": "11111111-1111-4111-8111-111111111111",
      "decision": "approved",
      "actorId": "staff-example",
      "at": "2026-10-27T08:30:00Z"
    }
  ],
  "fieldCorrections": []
}
```

### تعریف HistoryPage

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "items": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "eventId": {
            "type": "string",
            "minLength": 1,
            "maxLength": 160
          },
          "action": {
            "type": "string"
          },
          "actorId": {
            "type": "string",
            "minLength": 1,
            "maxLength": 160
          },
          "at": {
            "type": "string",
            "format": "date-time"
          },
          "resourceId": {
            "type": "string",
            "minLength": 1,
            "maxLength": 160
          }
        },
        "required": [
          "eventId",
          "action",
          "actorId",
          "at",
          "resourceId"
        ]
      }
    },
    "nextCursor": {
      "type": [
        "string",
        "null"
      ]
    }
  },
  "required": [
    "items",
    "nextCursor"
  ]
}
```

### مثال مستقل HistoryPage

```json
{
  "items": [],
  "nextCursor": null
}
```

### تعریف AdminWorkspace

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "templates": {
      "type": "array",
      "items": {
        "$ref": "#/$defs/AdminTemplate"
      }
    },
    "staff": {
      "type": "array",
      "items": {
        "$ref": "#/$defs/StaffMember"
      }
    },
    "version": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    },
    "audit": {
      "type": "array",
      "items": {
        "$ref": "#/$defs/AuditEntry"
      }
    },
    "webhooks": {
      "type": "array",
      "items": {
        "$ref": "#/$defs/Webhook"
      }
    },
    "assignmentPolicy": {
      "$ref": "#/$defs/ReviewerPolicy"
    }
  },
  "required": [
    "templates",
    "staff",
    "version",
    "audit",
    "webhooks",
    "assignmentPolicy"
  ]
}
```

### مثال مستقل AdminWorkspace

```json
{
  "templates": [
    {
      "id": "template-example",
      "title": "بازدید بدنه سدان نمونه",
      "partner": "کارگزاری نمونه",
      "currentPublishedId": "template-version-example",
      "versions": [
        {
          "id": "template-version-example",
          "version": 2,
          "revision": 1,
          "state": "published",
          "snapshot": {
            "photoPolicyVersion": 2,
            "templateId": "body-image-guided",
            "templateVersion": 2,
            "sections": [
              {
                "id": "right",
                "title": "نمای راست",
                "order": 1,
                "photoRequirements": [
                  {
                    "id": "front-45-right",
                    "title": "جلو ۴۵° راست",
                    "description": "جلوی خودرو و سمت راست به صورت کامل دیده شود.",
                    "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-right.webp",
                    "instructions": [
                      "جلوی خودرو و سمت راست به طور کامل داخل کادر باشد.",
                      "حدود ۳ متر از خودرو فاصله بگیرید.",
                      "از زاویه ۴۵ درجه سمت راست عکس بگیرید."
                    ],
                    "distance": "۳ متر",
                    "height": "کمر",
                    "orientation": "landscape",
                    "required": true,
                    "status": "pending",
                    "checks": [
                      "واضح",
                      "نور مناسب",
                      "خودرو کامل در کادر"
                    ],
                    "guidanceTopics": [
                      "frame",
                      "distance",
                      "angle"
                    ]
                  },
                  {
                    "id": "back-45-right",
                    "title": "عقب ۴۵° راست",
                    "description": "عقب خودرو و سمت راست به صورت کامل دیده شود.",
                    "sampleImage": "/assets/inspection-vehicle/photo-guides/back-45-right.webp",
                    "instructions": [
                      "تمام قسمت عقب و سمت راست خودرو داخل کادر باشد.",
                      "خودرو را از زاویه ۴۵ درجه ثبت کنید.",
                      "در نور کافی و بدون سایه شدید عکاسی کنید."
                    ],
                    "distance": "۳ متر",
                    "height": "کمر",
                    "orientation": "landscape",
                    "required": true,
                    "status": "pending",
                    "checks": [
                      "واضح",
                      "نور مناسب",
                      "خودرو کامل در کادر"
                    ],
                    "guidanceTopics": [
                      "frame",
                      "angle",
                      "glare"
                    ]
                  }
                ]
              },
              {
                "id": "left",
                "title": "نمای چپ",
                "order": 2,
                "photoRequirements": [
                  {
                    "id": "front-45-left",
                    "title": "جلو ۴۵° چپ",
                    "description": "جلوی خودرو و سمت چپ به صورت کامل دیده شود.",
                    "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-left.webp",
                    "instructions": [
                      "جلوی خودرو و سمت چپ به طور کامل داخل کادر باشد.",
                      "حدود ۳ متر از خودرو فاصله بگیرید.",
                      "از زاویه ۴۵ درجه سمت چپ عکس بگیرید."
                    ],
                    "distance": "۳ متر",
                    "height": "کمر",
                    "orientation": "landscape",
                    "required": true,
                    "status": "pending",
                    "checks": [
                      "واضح",
                      "نور مناسب",
                      "خودرو کامل در کادر"
                    ],
                    "guidanceTopics": [
                      "frame",
                      "distance",
                      "angle"
                    ]
                  },
                  {
                    "id": "back-45-left",
                    "title": "عقب ۴۵° چپ",
                    "description": "عقب خودرو و سمت چپ به صورت کامل دیده شود.",
                    "sampleImage": "/assets/inspection-vehicle/photo-guides/back-45-left.webp",
                    "instructions": [
                      "تمام قسمت عقب و سمت چپ خودرو داخل کادر باشد.",
                      "خودرو را از زاویه ۴۵ درجه ثبت کنید.",
                      "در نور کافی و بدون سایه شدید عکاسی کنید."
                    ],
                    "distance": "۳ متر",
                    "height": "کمر",
                    "orientation": "landscape",
                    "required": true,
                    "status": "pending",
                    "checks": [
                      "واضح",
                      "نور مناسب",
                      "خودرو کامل در کادر"
                    ],
                    "guidanceTopics": [
                      "frame",
                      "angle",
                      "glare"
                    ]
                  }
                ]
              },
              {
                "id": "front",
                "title": "جلو",
                "order": 3,
                "photoRequirements": [
                  {
                    "id": "front-plate",
                    "title": "نمای مستقیم جلو با پلاک",
                    "description": "یک عکس مستقیم از نمای جلوی خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.",
                    "sampleImage": "/assets/inspection-vehicle/photo-guides/front-plate.webp",
                    "instructions": [
                      "مستقیم روبه‌روی خودرو بایستید؛ خودرو وسط کادر باشد.",
                      "نمای کامل جلو را بدون برش و زاویه شدید ثبت کنید.",
                      "پلاک بدون بازتاب نور و کاملاً خوانا باشد."
                    ],
                    "distance": "۳ متر",
                    "height": "چراغ‌ها",
                    "orientation": "landscape",
                    "required": true,
                    "status": "pending",
                    "checks": [
                      "واضح",
                      "نور مناسب",
                      "پلاک خوانا است"
                    ],
                    "guidanceTopics": [
                      "angle",
                      "frame",
                      "text"
                    ]
                  }
                ]
              },
              {
                "id": "rear",
                "title": "عقب",
                "order": 4,
                "photoRequirements": [
                  {
                    "id": "rear-plate",
                    "title": "نمای مستقیم عقب با پلاک",
                    "description": "یک عکس مستقیم از نمای عقب خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.",
                    "sampleImage": "/assets/inspection-vehicle/photo-guides/rear-plate.webp",
                    "instructions": [
                      "مستقیم پشت خودرو بایستید؛ خودرو وسط کادر باشد.",
                      "تمام نمای عقب بدون برش و زاویه شدید داخل کادر باشد.",
                      "پلاک کاملاً خوانا و بدون بازتاب باشد."
                    ],
                    "distance": "۳ متر",
                    "height": "چراغ‌ها",
                    "orientation": "landscape",
                    "required": true,
                    "status": "pending",
                    "checks": [
                      "واضح",
                      "نور مناسب",
                      "پلاک خوانا است"
                    ],
                    "guidanceTopics": [
                      "angle",
                      "frame",
                      "text"
                    ]
                  }
                ]
              },
              {
                "id": "cabin",
                "title": "کابین",
                "order": 5,
                "photoRequirements": [
                  {
                    "id": "odometer-on",
                    "title": "کیلومترشمار",
                    "description": "خودرو را روشن کنید و تصویری واضح از کیلومترشمار بگیرید.",
                    "sampleImage": "/assets/inspection-vehicle/photo-guides/odometer-on.webp",
                    "instructions": [
                      "خودرو را روشن و در حالت توقف نگه دارید.",
                      "تمام صفحه کیلومترشمار در کادر باشد.",
                      "عدد کیلومتر خوانا باشد؛ از بازتاب نور جلوگیری کنید."
                    ],
                    "distance": "نزدیک",
                    "height": "داشبورد",
                    "orientation": "landscape",
                    "required": true,
                    "status": "pending",
                    "checks": [
                      "واضح",
                      "نور مناسب",
                      "عدد کیلومتر خوانا است"
                    ],
                    "guidanceTopics": [
                      "ignition",
                      "frame",
                      "glare"
                    ]
                  },
                  {
                    "id": "driver-interior",
                    "title": "نمای داخل کابین از سمت راننده",
                    "description": "از سمت راننده تصویری بگیرید که فضای داخلی خودرو به صورت واضح دیده شود.",
                    "sampleImage": "/assets/inspection-vehicle/photo-guides/driver-interior.webp",
                    "instructions": [
                      "درِ سمت راننده را باز کنید.",
                      "فرمان، داشبورد و صندلی‌ها دیده شوند.",
                      "خیلی نزدیک نشوید؛ فضای داخلی کامل دیده شود."
                    ],
                    "distance": "۱ متر",
                    "height": "درِ راننده",
                    "orientation": "landscape",
                    "required": true,
                    "status": "pending",
                    "checks": [
                      "واضح",
                      "نور مناسب",
                      "کابین کامل در کادر"
                    ],
                    "guidanceTopics": [
                      "interior",
                      "frame",
                      "distance"
                    ]
                  }
                ]
              },
              {
                "id": "engine-details",
                "title": "موتور و مشخصات",
                "order": 6,
                "photoRequirements": [
                  {
                    "id": "engine-bay",
                    "title": "محفظه موتور",
                    "description": "کاپوت را باز کنید و یک تصویر کامل و واضح از محفظه موتور بگیرید.",
                    "sampleImage": "/assets/inspection-vehicle/photo-guides/engine-bay.webp",
                    "instructions": [
                      "خودرو متوقف باشد؛ کاپوت را کاملاً و ایمن باز کنید.",
                      "تمام محفظه موتور دیده شود.",
                      "گوشی ثابت و تصویر بدون تاری باشد."
                    ],
                    "distance": "۱ متر",
                    "height": "سینه",
                    "orientation": "landscape",
                    "required": true,
                    "status": "pending",
                    "checks": [
                      "واضح",
                      "نور مناسب",
                      "محفظه کامل در کادر"
                    ],
                    "guidanceTopics": [
                      "hood",
                      "frame",
                      "steady"
                    ]
                  },
                  {
                    "id": "spec-plate",
                    "title": "محل شماره شاسی خودرو",
                    "description": "شماره شاسی خودرو — انتخاب یکی از چهار گزینه. فقط یک تصویر لازم است.",
                    "sampleImage": "/assets/inspection-vehicle/photo-guides/spec-plate.webp",
                    "instructions": [
                      "از نزدیک روی پلاک مشخصات فوکوس کنید.",
                      "تمام متن پلاک داخل کادر باشد.",
                      "نوشته‌ها خوانا و بدون بازتاب نور باشند."
                    ],
                    "distance": "۳۰ سانتی‌متر",
                    "height": "هم‌سطح پلاک",
                    "orientation": "landscape",
                    "choice": {
                      "groupId": "vehicle-identification",
                      "alternatives": [
                        "pillar",
                        "engine",
                        "seat",
                        "windshield"
                      ]
                    },
                    "required": true,
                    "status": "pending",
                    "checks": [
                      "واضح",
                      "نور مناسب",
                      "اطلاعات قابل خواندن است"
                    ],
                    "guidanceTopics": [
                      "text",
                      "frame",
                      "glare"
                    ]
                  }
                ]
              },
              {
                "id": "roof",
                "title": "سقف",
                "order": 7,
                "photoRequirements": [
                  {
                    "id": "car-roof",
                    "title": "نمای سقف",
                    "description": "تمام سطح سقف خودرو را در تصویر نشان دهید.",
                    "sampleImage": "/assets/inspection-vehicle/photo-guides/car-roof.webp",
                    "instructions": [
                      "از موقعیتی ایمن، گوشی را بالاتر بگیرید.",
                      "بیشترین سطح سقف و گوشه‌های اصلی در کادر باشند.",
                      "برای عکاسی روی خودرو نایستید."
                    ],
                    "distance": "۱ متر",
                    "height": "بالاتر از سقف",
                    "orientation": "landscape",
                    "required": true,
                    "status": "pending",
                    "checks": [
                      "واضح",
                      "نور مناسب",
                      "سقف کامل در کادر"
                    ],
                    "guidanceTopics": [
                      "roof",
                      "frame",
                      "steady"
                    ]
                  }
                ]
              }
            ],
            "captureRequirements": {
              "odometerRequirementId": "odometer-on",
              "video360Required": true
            }
          },
          "updatedAt": "2026-10-27T08:30:00Z",
          "updatedBy": "staff-example",
          "publishedAt": "2026-10-27T08:30:00Z"
        }
      ]
    }
  ],
  "staff": [
    {
      "staffId": "staff-example",
      "name": "کارشناس نمونه",
      "identifier": "source-subject-example",
      "role": "reviewer",
      "active": true,
      "capacity": 8
    }
  ],
  "version": "AAAAAAAAB9E=",
  "audit": [
    {
      "id": "audit-example",
      "at": "2026-10-27T08:30:00Z",
      "actor": "staff-example",
      "action": "template.published",
      "resource": "template-version-example"
    }
  ],
  "webhooks": [
    {
      "id": "webhook-example",
      "label": "اعلان ارسال بازدید",
      "endpoint": "https://brokerage.example.invalid/events/inspection",
      "event": "inspection.submitted",
      "enabled": false
    }
  ],
  "assignmentPolicy": {
    "mode": "manual",
    "capacities": [],
    "expectedVersion": "AAAAAAAAB9E="
  }
}
```

### تعریف TemplateDraftRequest

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "title": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    },
    "templateId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "baseVersion": {
      "type": "integer",
      "minimum": 1
    }
  },
  "required": [
    "title"
  ]
}
```

### مثال مستقل TemplateDraftRequest

```json
{
  "title": "نمونه قراردادی"
}
```

### تعریف TemplateSaveRequest

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "expectedVersion": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    },
    "template": {
      "$ref": "#/$defs/CapturePlan"
    }
  },
  "required": [
    "expectedVersion",
    "template"
  ]
}
```

### مثال مستقل TemplateSaveRequest

```json
{
  "expectedVersion": "AAAAAAAAB9E=",
  "template": {
    "photoPolicyVersion": 2,
    "templateId": "body-image-guided",
    "templateVersion": 2,
    "sections": [
      {
        "id": "right",
        "title": "نمای راست",
        "order": 1,
        "photoRequirements": [
          {
            "id": "front-45-right",
            "title": "جلو ۴۵° راست",
            "description": "جلوی خودرو و سمت راست به صورت کامل دیده شود.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-right.webp",
            "instructions": [
              "جلوی خودرو و سمت راست به طور کامل داخل کادر باشد.",
              "حدود ۳ متر از خودرو فاصله بگیرید.",
              "از زاویه ۴۵ درجه سمت راست عکس بگیرید."
            ],
            "distance": "۳ متر",
            "height": "کمر",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "خودرو کامل در کادر"
            ],
            "guidanceTopics": [
              "frame",
              "distance",
              "angle"
            ]
          },
          {
            "id": "back-45-right",
            "title": "عقب ۴۵° راست",
            "description": "عقب خودرو و سمت راست به صورت کامل دیده شود.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/back-45-right.webp",
            "instructions": [
              "تمام قسمت عقب و سمت راست خودرو داخل کادر باشد.",
              "خودرو را از زاویه ۴۵ درجه ثبت کنید.",
              "در نور کافی و بدون سایه شدید عکاسی کنید."
            ],
            "distance": "۳ متر",
            "height": "کمر",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "خودرو کامل در کادر"
            ],
            "guidanceTopics": [
              "frame",
              "angle",
              "glare"
            ]
          }
        ]
      },
      {
        "id": "left",
        "title": "نمای چپ",
        "order": 2,
        "photoRequirements": [
          {
            "id": "front-45-left",
            "title": "جلو ۴۵° چپ",
            "description": "جلوی خودرو و سمت چپ به صورت کامل دیده شود.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-left.webp",
            "instructions": [
              "جلوی خودرو و سمت چپ به طور کامل داخل کادر باشد.",
              "حدود ۳ متر از خودرو فاصله بگیرید.",
              "از زاویه ۴۵ درجه سمت چپ عکس بگیرید."
            ],
            "distance": "۳ متر",
            "height": "کمر",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "خودرو کامل در کادر"
            ],
            "guidanceTopics": [
              "frame",
              "distance",
              "angle"
            ]
          },
          {
            "id": "back-45-left",
            "title": "عقب ۴۵° چپ",
            "description": "عقب خودرو و سمت چپ به صورت کامل دیده شود.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/back-45-left.webp",
            "instructions": [
              "تمام قسمت عقب و سمت چپ خودرو داخل کادر باشد.",
              "خودرو را از زاویه ۴۵ درجه ثبت کنید.",
              "در نور کافی و بدون سایه شدید عکاسی کنید."
            ],
            "distance": "۳ متر",
            "height": "کمر",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "خودرو کامل در کادر"
            ],
            "guidanceTopics": [
              "frame",
              "angle",
              "glare"
            ]
          }
        ]
      },
      {
        "id": "front",
        "title": "جلو",
        "order": 3,
        "photoRequirements": [
          {
            "id": "front-plate",
            "title": "نمای مستقیم جلو با پلاک",
            "description": "یک عکس مستقیم از نمای جلوی خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/front-plate.webp",
            "instructions": [
              "مستقیم روبه‌روی خودرو بایستید؛ خودرو وسط کادر باشد.",
              "نمای کامل جلو را بدون برش و زاویه شدید ثبت کنید.",
              "پلاک بدون بازتاب نور و کاملاً خوانا باشد."
            ],
            "distance": "۳ متر",
            "height": "چراغ‌ها",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "پلاک خوانا است"
            ],
            "guidanceTopics": [
              "angle",
              "frame",
              "text"
            ]
          }
        ]
      },
      {
        "id": "rear",
        "title": "عقب",
        "order": 4,
        "photoRequirements": [
          {
            "id": "rear-plate",
            "title": "نمای مستقیم عقب با پلاک",
            "description": "یک عکس مستقیم از نمای عقب خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/rear-plate.webp",
            "instructions": [
              "مستقیم پشت خودرو بایستید؛ خودرو وسط کادر باشد.",
              "تمام نمای عقب بدون برش و زاویه شدید داخل کادر باشد.",
              "پلاک کاملاً خوانا و بدون بازتاب باشد."
            ],
            "distance": "۳ متر",
            "height": "چراغ‌ها",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "پلاک خوانا است"
            ],
            "guidanceTopics": [
              "angle",
              "frame",
              "text"
            ]
          }
        ]
      },
      {
        "id": "cabin",
        "title": "کابین",
        "order": 5,
        "photoRequirements": [
          {
            "id": "odometer-on",
            "title": "کیلومترشمار",
            "description": "خودرو را روشن کنید و تصویری واضح از کیلومترشمار بگیرید.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/odometer-on.webp",
            "instructions": [
              "خودرو را روشن و در حالت توقف نگه دارید.",
              "تمام صفحه کیلومترشمار در کادر باشد.",
              "عدد کیلومتر خوانا باشد؛ از بازتاب نور جلوگیری کنید."
            ],
            "distance": "نزدیک",
            "height": "داشبورد",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "عدد کیلومتر خوانا است"
            ],
            "guidanceTopics": [
              "ignition",
              "frame",
              "glare"
            ]
          },
          {
            "id": "driver-interior",
            "title": "نمای داخل کابین از سمت راننده",
            "description": "از سمت راننده تصویری بگیرید که فضای داخلی خودرو به صورت واضح دیده شود.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/driver-interior.webp",
            "instructions": [
              "درِ سمت راننده را باز کنید.",
              "فرمان، داشبورد و صندلی‌ها دیده شوند.",
              "خیلی نزدیک نشوید؛ فضای داخلی کامل دیده شود."
            ],
            "distance": "۱ متر",
            "height": "درِ راننده",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "کابین کامل در کادر"
            ],
            "guidanceTopics": [
              "interior",
              "frame",
              "distance"
            ]
          }
        ]
      },
      {
        "id": "engine-details",
        "title": "موتور و مشخصات",
        "order": 6,
        "photoRequirements": [
          {
            "id": "engine-bay",
            "title": "محفظه موتور",
            "description": "کاپوت را باز کنید و یک تصویر کامل و واضح از محفظه موتور بگیرید.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/engine-bay.webp",
            "instructions": [
              "خودرو متوقف باشد؛ کاپوت را کاملاً و ایمن باز کنید.",
              "تمام محفظه موتور دیده شود.",
              "گوشی ثابت و تصویر بدون تاری باشد."
            ],
            "distance": "۱ متر",
            "height": "سینه",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "محفظه کامل در کادر"
            ],
            "guidanceTopics": [
              "hood",
              "frame",
              "steady"
            ]
          },
          {
            "id": "spec-plate",
            "title": "محل شماره شاسی خودرو",
            "description": "شماره شاسی خودرو — انتخاب یکی از چهار گزینه. فقط یک تصویر لازم است.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/spec-plate.webp",
            "instructions": [
              "از نزدیک روی پلاک مشخصات فوکوس کنید.",
              "تمام متن پلاک داخل کادر باشد.",
              "نوشته‌ها خوانا و بدون بازتاب نور باشند."
            ],
            "distance": "۳۰ سانتی‌متر",
            "height": "هم‌سطح پلاک",
            "orientation": "landscape",
            "choice": {
              "groupId": "vehicle-identification",
              "alternatives": [
                "pillar",
                "engine",
                "seat",
                "windshield"
              ]
            },
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "اطلاعات قابل خواندن است"
            ],
            "guidanceTopics": [
              "text",
              "frame",
              "glare"
            ]
          }
        ]
      },
      {
        "id": "roof",
        "title": "سقف",
        "order": 7,
        "photoRequirements": [
          {
            "id": "car-roof",
            "title": "نمای سقف",
            "description": "تمام سطح سقف خودرو را در تصویر نشان دهید.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/car-roof.webp",
            "instructions": [
              "از موقعیتی ایمن، گوشی را بالاتر بگیرید.",
              "بیشترین سطح سقف و گوشه‌های اصلی در کادر باشند.",
              "برای عکاسی روی خودرو نایستید."
            ],
            "distance": "۱ متر",
            "height": "بالاتر از سقف",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "سقف کامل در کادر"
            ],
            "guidanceTopics": [
              "roof",
              "frame",
              "steady"
            ]
          }
        ]
      }
    ],
    "captureRequirements": {
      "odometerRequirementId": "odometer-on",
      "video360Required": true
    }
  }
}
```

### تعریف PublicationRequest

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "expectedVersion": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    },
    "action": {
      "enum": [
        "publish",
        "archive"
      ]
    }
  },
  "required": [
    "expectedVersion",
    "action"
  ]
}
```

### مثال مستقل PublicationRequest

```json
{
  "expectedVersion": "AAAAAAAAB9E=",
  "action": "publish"
}
```

### تعریف SettingsDraft

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "expectedVersion": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    },
    "identity": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "brokerageName": {
          "type": "string",
          "minLength": 1,
          "maxLength": 50
        },
        "appTitle": {
          "type": "string",
          "minLength": 1,
          "maxLength": 60
        },
        "logo": {
          "type": [
            "string",
            "null"
          ]
        },
        "publicEmail": {
          "type": "string"
        },
        "publicPhone": {
          "type": "string"
        },
        "favicon": {
          "type": [
            "string",
            "null"
          ]
        }
      },
      "required": [
        "brokerageName",
        "appTitle",
        "logo",
        "publicEmail",
        "publicPhone",
        "favicon"
      ]
    },
    "theme": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "primary": {
          "type": "string",
          "pattern": "^#[0-9a-fA-F]{6}$"
        },
        "secondary": {
          "type": "string",
          "pattern": "^#[0-9a-fA-F]{6}$"
        },
        "accent": {
          "type": "string",
          "pattern": "^#[0-9a-fA-F]{6}$"
        },
        "haloColor": {
          "type": "string",
          "pattern": "^#[0-9a-fA-F]{6}$"
        },
        "background": {
          "type": "string",
          "pattern": "^#[0-9a-fA-F]{6}$"
        },
        "neutral": {
          "type": "string",
          "pattern": "^#[0-9a-fA-F]{6}$"
        },
        "onPrimary": {
          "type": "string",
          "pattern": "^#[0-9a-fA-F]{6}$"
        },
        "onBackground": {
          "type": "string",
          "pattern": "^#[0-9a-fA-F]{6}$"
        },
        "haloIntensity": {
          "type": "integer",
          "minimum": 0,
          "maximum": 100
        }
      },
      "required": [
        "primary",
        "secondary",
        "background",
        "neutral",
        "onPrimary",
        "onBackground"
      ]
    },
    "images": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "landing": {
          "type": [
            "string",
            "null"
          ]
        },
        "referral": {
          "type": [
            "string",
            "null"
          ]
        },
        "otp": {
          "type": [
            "string",
            "null"
          ]
        },
        "readiness": {
          "type": [
            "string",
            "null"
          ]
        },
        "consent": {
          "type": [
            "string",
            "null"
          ]
        },
        "submission": {
          "type": [
            "string",
            "null"
          ]
        }
      },
      "required": []
    },
    "template": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "id": {
          "type": "string",
          "minLength": 1,
          "maxLength": 160
        },
        "version": {
          "type": "integer",
          "minimum": 1
        }
      },
      "required": [
        "id",
        "version"
      ]
    }
  },
  "required": [
    "expectedVersion",
    "identity",
    "theme",
    "images",
    "template"
  ]
}
```

### مثال مستقل SettingsDraft

```json
{
  "expectedVersion": "AAAAAAAAB9E=",
  "identity": {
    "brokerageName": "کارگزاری نمونه",
    "appTitle": "بازدید خودرو",
    "logo": null,
    "favicon": null,
    "publicEmail": "support@example.invalid",
    "publicPhone": "نمونه قراردادی"
  },
  "theme": {
    "primary": "#047857",
    "secondary": "#475569",
    "background": "#FFFFFF",
    "neutral": "#64748B",
    "onPrimary": "#FFFFFF",
    "onBackground": "#0F172A",
    "accent": "#F59E0B",
    "haloColor": "#10B981",
    "haloIntensity": 35
  },
  "images": {},
  "template": {
    "id": "body-image-guided",
    "version": 2
  }
}
```

### تعریف PublicSettings

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "schemaVersion": {
      "const": 1
    },
    "tenantId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "version": {
      "type": "integer",
      "minimum": 1
    },
    "publishedAt": {
      "type": "string",
      "format": "date-time"
    },
    "identity": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "brokerageName": {
          "type": "string",
          "minLength": 1,
          "maxLength": 50
        },
        "appTitle": {
          "type": "string",
          "minLength": 1,
          "maxLength": 60
        },
        "logo": {
          "type": [
            "string",
            "null"
          ]
        },
        "publicEmail": {
          "type": "string"
        },
        "publicPhone": {
          "type": "string"
        },
        "favicon": {
          "type": [
            "string",
            "null"
          ]
        }
      },
      "required": [
        "brokerageName",
        "appTitle",
        "logo",
        "publicEmail",
        "publicPhone",
        "favicon"
      ]
    },
    "theme": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "primary": {
          "type": "string",
          "pattern": "^#[0-9a-fA-F]{6}$"
        },
        "secondary": {
          "type": "string",
          "pattern": "^#[0-9a-fA-F]{6}$"
        },
        "accent": {
          "type": "string",
          "pattern": "^#[0-9a-fA-F]{6}$"
        },
        "haloColor": {
          "type": "string",
          "pattern": "^#[0-9a-fA-F]{6}$"
        },
        "background": {
          "type": "string",
          "pattern": "^#[0-9a-fA-F]{6}$"
        },
        "neutral": {
          "type": "string",
          "pattern": "^#[0-9a-fA-F]{6}$"
        },
        "onPrimary": {
          "type": "string",
          "pattern": "^#[0-9a-fA-F]{6}$"
        },
        "onBackground": {
          "type": "string",
          "pattern": "^#[0-9a-fA-F]{6}$"
        },
        "haloIntensity": {
          "type": "number",
          "minimum": 0,
          "maximum": 100
        }
      },
      "required": [
        "primary",
        "secondary",
        "background",
        "neutral",
        "onPrimary",
        "onBackground"
      ]
    },
    "images": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "landing": {
          "type": [
            "string",
            "null"
          ]
        },
        "referral": {
          "type": [
            "string",
            "null"
          ]
        },
        "otp": {
          "type": [
            "string",
            "null"
          ]
        },
        "readiness": {
          "type": [
            "string",
            "null"
          ]
        },
        "consent": {
          "type": [
            "string",
            "null"
          ]
        },
        "submission": {
          "type": [
            "string",
            "null"
          ]
        }
      },
      "required": [
        "landing",
        "referral",
        "otp",
        "readiness",
        "consent"
      ]
    },
    "application": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "apiBaseUrl": {
          "type": "string"
        },
        "contractVersion": {
          "const": "1"
        },
        "template": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "id": {
              "type": "string",
              "minLength": 1,
              "maxLength": 160
            },
            "version": {
              "type": "integer",
              "minimum": 1
            }
          },
          "required": [
            "id",
            "version"
          ]
        },
        "locationMap": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "enabled": {
              "type": "boolean"
            },
            "webMapKey": {
              "type": [
                "string",
                "null"
              ]
            },
            "mapType": {
              "enum": [
                "dreamy",
                "standard-night"
              ]
            },
            "reverseGeocoding": {
              "enum": [
                "api",
                "mock",
                "unavailable"
              ]
            },
            "initialViewport": {
              "type": "object",
              "additionalProperties": false,
              "properties": {
                "latitude": {
                  "type": "number"
                },
                "longitude": {
                  "type": "number"
                },
                "zoom": {
                  "type": "integer",
                  "minimum": 3,
                  "maximum": 18
                }
              },
              "required": [
                "latitude",
                "longitude",
                "zoom"
              ]
            }
          },
          "required": [
            "enabled",
            "webMapKey",
            "mapType",
            "reverseGeocoding",
            "initialViewport"
          ]
        },
        "features": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "nativeCaptureFallback": {
              "const": true
            },
            "additionalEvidence": {
              "const": true
            },
            "supportLink": {
              "type": "boolean"
            }
          },
          "required": [
            "nativeCaptureFallback",
            "additionalEvidence",
            "supportLink"
          ]
        }
      },
      "required": [
        "apiBaseUrl",
        "contractVersion",
        "template",
        "locationMap",
        "features"
      ]
    }
  },
  "required": [
    "schemaVersion",
    "tenantId",
    "version",
    "publishedAt",
    "identity",
    "theme",
    "images",
    "application"
  ]
}
```

### مثال مستقل PublicSettings

```json
{
  "schemaVersion": 1,
  "tenantId": "demo",
  "version": 2,
  "publishedAt": "2026-10-26T09:00:00Z",
  "identity": {
    "brokerageName": "کارگزاری نمونه",
    "appTitle": "بازدید خودرو",
    "logo": null,
    "favicon": null,
    "publicEmail": "support@example.invalid",
    "publicPhone": "نمونه قراردادی"
  },
  "theme": {
    "primary": "#047857",
    "secondary": "#475569",
    "background": "#FFFFFF",
    "neutral": "#64748B",
    "onPrimary": "#FFFFFF",
    "onBackground": "#0F172A",
    "accent": "#F59E0B",
    "haloColor": "#10B981",
    "haloIntensity": 35
  },
  "images": {
    "landing": null,
    "referral": null,
    "otp": null,
    "readiness": null,
    "consent": null,
    "submission": null
  },
  "application": {
    "apiBaseUrl": "/api/bazdid",
    "contractVersion": "1",
    "template": {
      "id": "body-image-guided",
      "version": 2
    },
    "features": {
      "nativeCaptureFallback": true,
      "additionalEvidence": true,
      "supportLink": false
    },
    "locationMap": {
      "enabled": true,
      "webMapKey": null,
      "mapType": "dreamy",
      "reverseGeocoding": "api",
      "initialViewport": {
        "latitude": 35.699739,
        "longitude": 51.338097,
        "zoom": 12
      }
    }
  }
}
```

### تعریف SettingsWorkspace

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "published": {
      "$ref": "#/$defs/PublicSettings"
    },
    "draft": {
      "$ref": "#/$defs/PublicSettings"
    },
    "version": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    }
  },
  "required": [
    "published",
    "draft",
    "version"
  ]
}
```

### مثال مستقل SettingsWorkspace

```json
{
  "published": {
    "schemaVersion": 1,
    "tenantId": "demo",
    "version": 2,
    "publishedAt": "2026-10-26T09:00:00Z",
    "identity": {
      "brokerageName": "کارگزاری نمونه",
      "appTitle": "بازدید خودرو",
      "logo": null,
      "favicon": null,
      "publicEmail": "support@example.invalid",
      "publicPhone": "نمونه قراردادی"
    },
    "theme": {
      "primary": "#047857",
      "secondary": "#475569",
      "background": "#FFFFFF",
      "neutral": "#64748B",
      "onPrimary": "#FFFFFF",
      "onBackground": "#0F172A",
      "accent": "#F59E0B",
      "haloColor": "#10B981",
      "haloIntensity": 35
    },
    "images": {
      "landing": null,
      "referral": null,
      "otp": null,
      "readiness": null,
      "consent": null,
      "submission": null
    },
    "application": {
      "apiBaseUrl": "/api/bazdid",
      "contractVersion": "1",
      "template": {
        "id": "body-image-guided",
        "version": 2
      },
      "features": {
        "nativeCaptureFallback": true,
        "additionalEvidence": true,
        "supportLink": false
      },
      "locationMap": {
        "enabled": true,
        "webMapKey": null,
        "mapType": "dreamy",
        "reverseGeocoding": "api",
        "initialViewport": {
          "latitude": 35.699739,
          "longitude": 51.338097,
          "zoom": 12
        }
      }
    }
  },
  "draft": {
    "schemaVersion": 1,
    "tenantId": "demo",
    "version": 2,
    "publishedAt": "2026-10-26T09:00:00Z",
    "identity": {
      "brokerageName": "کارگزاری نمونه",
      "appTitle": "بازدید خودرو",
      "logo": null,
      "favicon": null,
      "publicEmail": "support@example.invalid",
      "publicPhone": "نمونه قراردادی"
    },
    "theme": {
      "primary": "#047857",
      "secondary": "#475569",
      "background": "#FFFFFF",
      "neutral": "#64748B",
      "onPrimary": "#FFFFFF",
      "onBackground": "#0F172A",
      "accent": "#F59E0B",
      "haloColor": "#10B981",
      "haloIntensity": 35
    },
    "images": {
      "landing": null,
      "referral": null,
      "otp": null,
      "readiness": null,
      "consent": null,
      "submission": null
    },
    "application": {
      "apiBaseUrl": "/api/bazdid",
      "contractVersion": "1",
      "template": {
        "id": "body-image-guided",
        "version": 2
      },
      "features": {
        "nativeCaptureFallback": true,
        "additionalEvidence": true,
        "supportLink": false
      },
      "locationMap": {
        "enabled": true,
        "webMapKey": null,
        "mapType": "dreamy",
        "reverseGeocoding": "api",
        "initialViewport": {
          "latitude": 35.699739,
          "longitude": 51.338097,
          "zoom": 12
        }
      }
    }
  },
  "version": "AAAAAAAAB9E="
}
```

### تعریف BrandUpload

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "slot": {
      "type": "string"
    },
    "file": {
      "$ref": "#/$defs/BinaryTransfer"
    }
  },
  "required": [
    "slot",
    "file"
  ]
}
```

### مثال مستقل BrandUpload

```json
{
  "slot": "نمونه قراردادی",
  "file": "نمونه قراردادی"
}
```

### تعریف BrandAsset

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "assetId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "url": {
      "type": "string"
    },
    "mimeType": {
      "type": "string"
    },
    "byteSize": {
      "type": "integer",
      "minimum": 1
    },
    "width": {
      "type": "integer",
      "minimum": 1
    },
    "height": {
      "type": "integer",
      "minimum": 1
    }
  },
  "required": [
    "assetId",
    "url",
    "mimeType",
    "byteSize",
    "width",
    "height"
  ]
}
```

### مثال مستقل BrandAsset

```json
{
  "assetId": "11111111-1111-4111-8111-111111111111",
  "url": "/branding/example-brokerage-logo.webp",
  "mimeType": "image/jpeg",
  "byteSize": 420000,
  "width": 320,
  "height": 160
}
```

### تعریف StaffRolesRequest

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "roles": {
      "type": "array",
      "items": {
        "enum": [
          "platform-admin",
          "reviewer",
          "template-editor",
          "viewer"
        ]
      },
      "minItems": 1,
      "uniqueItems": true
    },
    "active": {
      "type": "boolean"
    },
    "expectedVersion": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    }
  },
  "required": [
    "roles",
    "active",
    "expectedVersion"
  ]
}
```

### مثال مستقل StaffRolesRequest

```json
{
  "roles": [
    "platform-admin"
  ],
  "active": true,
  "expectedVersion": "AAAAAAAAB9E="
}
```

### تعریف WebhookRequest

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "enabled": {
      "type": "boolean"
    },
    "expectedVersion": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    }
  },
  "required": [
    "enabled",
    "expectedVersion"
  ]
}
```

### مثال مستقل WebhookRequest

```json
{
  "enabled": true,
  "expectedVersion": "AAAAAAAAB9E="
}
```

### تعریف Health

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "state": {
      "enum": [
        "healthy",
        "degraded",
        "unavailable"
      ]
    },
    "checkedAt": {
      "type": "string",
      "format": "date-time"
    },
    "components": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "name": {
            "type": "string"
          },
          "state": {
            "type": "string"
          },
          "code": {
            "type": "string"
          }
        },
        "required": [
          "name",
          "state",
          "code"
        ]
      }
    }
  },
  "required": [
    "state",
    "checkedAt",
    "components"
  ]
}
```

### مثال مستقل Health

```json
{
  "state": "healthy",
  "checkedAt": "2026-10-26T09:00:00Z",
  "components": []
}
```

### تعریف ReverseAddress

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "formatted_address": {
      "type": "string",
      "minLength": 1,
      "maxLength": 500
    }
  },
  "required": [
    "formatted_address"
  ]
}
```

### مثال مستقل ReverseAddress

```json
{
  "formatted_address": "تهران، خیابان نمونه، محل بازدید"
}
```

### تعریف Problem

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "type": {
      "type": "string"
    },
    "title": {
      "type": "string"
    },
    "status": {
      "type": "integer",
      "minimum": 400,
      "maximum": 599
    },
    "code": {
      "type": "string"
    },
    "traceId": {
      "type": "string"
    },
    "errors": {
      "type": "object",
      "additionalProperties": {
        "type": "array",
        "items": {
          "type": "string"
        }
      }
    },
    "retryAfterSeconds": {
      "type": "integer",
      "minimum": 0,
      "maximum": 9007199254740991
    },
    "currentVersion": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    }
  },
  "required": [
    "type",
    "title",
    "status",
    "code",
    "traceId"
  ]
}
```

### مثال مستقل Problem

```json
{
  "type": "https://inspection.example.invalid/problems/UPLOAD_INCOMPLETE",
  "title": "برخی فایل‌ها هنوز ارسال نشده‌اند.",
  "status": 422,
  "code": "UPLOAD_INCOMPLETE",
  "traceId": "fixture-trace-001",
  "errors": {
    "evidence": [
      "نسخه انتخاب‌شده هنوز رسید پایدار ندارد."
    ]
  }
}
```

### تعریف InspectionOrNone

```json
{
  "oneOf": [
    {
      "$ref": "#/$defs/Inspection"
    },
    {
      "type": "null"
    }
  ]
}
```

### مثال مستقل InspectionOrNone

```json
{
  "inspectionId": "insp_contract_001",
  "sourceRequestId": "REQ-DEMO-001",
  "trackingCode": "BDI-8F31K2",
  "status": "DRAFT",
  "templateId": "body-image-guided",
  "templateVersion": 2,
  "photoPolicyVersion": 2,
  "version": "AAAAAAAAB9E="
}
```

### تعریف ReviewDecision

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "id": {
      "type": "string",
      "minLength": 1
    },
    "requirementId": {
      "type": "string",
      "minLength": 1
    },
    "revision": {
      "type": "string",
      "minLength": 1
    },
    "evidenceId": {
      "type": "string",
      "minLength": 1
    },
    "decision": {
      "enum": [
        "approved",
        "rejected"
      ]
    },
    "reason": {
      "type": "string",
      "minLength": 1,
      "maxLength": 2000
    },
    "actorId": {
      "type": "string",
      "minLength": 1
    },
    "at": {
      "type": "string",
      "format": "date-time"
    },
    "requestId": {
      "type": "string",
      "minLength": 1
    }
  },
  "required": [
    "id",
    "requirementId",
    "revision",
    "evidenceId",
    "decision",
    "actorId",
    "at"
  ],
  "allOf": [
    {
      "if": {
        "properties": {
          "decision": {
            "const": "rejected"
          }
        },
        "required": [
          "decision"
        ]
      },
      "then": {
        "properties": {
          "reason": {}
        },
        "required": [
          "reason"
        ]
      }
    }
  ]
}
```

### مثال مستقل ReviewDecision

```json
{
  "id": "decision-example",
  "requirementId": "spec-plate",
  "revision": "client-revision-0002",
  "evidenceId": "11111111-1111-4111-8111-111111111111",
  "decision": "approved",
  "actorId": "staff-example",
  "at": "2026-10-27T08:30:00Z"
}
```

### تعریف FieldCorrection

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "id": {
      "type": "string",
      "minLength": 1
    },
    "field": {
      "enum": [
        "plate",
        "color",
        "modelYear"
      ]
    },
    "customerReason": {
      "type": "string",
      "minLength": 1
    },
    "requestedAt": {
      "type": "string",
      "format": "date-time"
    },
    "requestedBy": {
      "type": "string",
      "minLength": 1
    },
    "state": {
      "enum": [
        "requested",
        "submitted",
        "approved"
      ]
    },
    "proposal": {
      "$ref": "#/$defs/FieldProposal"
    },
    "submittedAt": {
      "type": "string",
      "format": "date-time"
    },
    "reviewedAt": {
      "type": "string",
      "format": "date-time"
    },
    "reviewedBy": {
      "type": "string",
      "minLength": 1
    }
  },
  "required": [
    "id",
    "field",
    "customerReason",
    "requestedAt",
    "requestedBy",
    "state"
  ]
}
```

### مثال مستقل FieldCorrection

```json
{
  "id": "field-example",
  "field": "color",
  "customerReason": "رنگ بدنه با تصویر مطابقت ندارد.",
  "requestedAt": "2026-10-27T08:30:00Z",
  "requestedBy": "staff-example",
  "state": "requested"
}
```

### تعریف FinalReview

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "kind": {
      "enum": [
        "approved",
        "rejected"
      ]
    },
    "customerReason": {
      "type": "string",
      "minLength": 1,
      "maxLength": 2000
    },
    "actorId": {
      "type": "string",
      "minLength": 1
    },
    "at": {
      "type": "string",
      "format": "date-time"
    }
  },
  "required": [
    "kind",
    "actorId",
    "at"
  ],
  "allOf": [
    {
      "if": {
        "properties": {
          "kind": {
            "const": "rejected"
          }
        },
        "required": [
          "kind"
        ]
      },
      "then": {
        "properties": {
          "customerReason": {}
        },
        "required": [
          "customerReason"
        ]
      }
    }
  ]
}
```

### مثال مستقل FinalReview

```json
{
  "kind": "approved",
  "actorId": "staff-example",
  "at": "2026-10-27T08:30:00Z"
}
```

### تعریف Forwarding

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "phase": {
      "enum": [
        "ready",
        "sending",
        "retrying",
        "failed",
        "acknowledged"
      ]
    },
    "acknowledgementId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 160
    },
    "acknowledgedAt": {
      "type": "string",
      "format": "date-time"
    }
  },
  "required": [
    "phase"
  ],
  "allOf": [
    {
      "if": {
        "properties": {
          "phase": {
            "const": "acknowledged"
          }
        },
        "required": [
          "phase"
        ]
      },
      "then": {
        "properties": {
          "acknowledgementId": {},
          "acknowledgedAt": {}
        },
        "required": [
          "acknowledgementId",
          "acknowledgedAt"
        ]
      }
    }
  ]
}
```

### مثال مستقل Forwarding

```json
{
  "phase": "ready"
}
```

### تعریف TemplateVersion

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "id": {
      "type": "string",
      "minLength": 1
    },
    "version": {
      "type": "integer",
      "minimum": 1
    },
    "revision": {
      "type": "integer",
      "minimum": 1
    },
    "state": {
      "enum": [
        "draft",
        "published",
        "archived"
      ]
    },
    "snapshot": {
      "$ref": "#/$defs/CapturePlan"
    },
    "updatedAt": {
      "type": "string",
      "format": "date-time"
    },
    "updatedBy": {
      "type": "string",
      "minLength": 1
    },
    "publishedAt": {
      "type": "string",
      "format": "date-time"
    }
  },
  "required": [
    "id",
    "version",
    "revision",
    "state",
    "snapshot",
    "updatedAt",
    "updatedBy"
  ]
}
```

### مثال مستقل TemplateVersion

```json
{
  "id": "template-version-example",
  "version": 2,
  "revision": 1,
  "state": "published",
  "snapshot": {
    "photoPolicyVersion": 2,
    "templateId": "body-image-guided",
    "templateVersion": 2,
    "sections": [
      {
        "id": "right",
        "title": "نمای راست",
        "order": 1,
        "photoRequirements": [
          {
            "id": "front-45-right",
            "title": "جلو ۴۵° راست",
            "description": "جلوی خودرو و سمت راست به صورت کامل دیده شود.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-right.webp",
            "instructions": [
              "جلوی خودرو و سمت راست به طور کامل داخل کادر باشد.",
              "حدود ۳ متر از خودرو فاصله بگیرید.",
              "از زاویه ۴۵ درجه سمت راست عکس بگیرید."
            ],
            "distance": "۳ متر",
            "height": "کمر",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "خودرو کامل در کادر"
            ],
            "guidanceTopics": [
              "frame",
              "distance",
              "angle"
            ]
          },
          {
            "id": "back-45-right",
            "title": "عقب ۴۵° راست",
            "description": "عقب خودرو و سمت راست به صورت کامل دیده شود.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/back-45-right.webp",
            "instructions": [
              "تمام قسمت عقب و سمت راست خودرو داخل کادر باشد.",
              "خودرو را از زاویه ۴۵ درجه ثبت کنید.",
              "در نور کافی و بدون سایه شدید عکاسی کنید."
            ],
            "distance": "۳ متر",
            "height": "کمر",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "خودرو کامل در کادر"
            ],
            "guidanceTopics": [
              "frame",
              "angle",
              "glare"
            ]
          }
        ]
      },
      {
        "id": "left",
        "title": "نمای چپ",
        "order": 2,
        "photoRequirements": [
          {
            "id": "front-45-left",
            "title": "جلو ۴۵° چپ",
            "description": "جلوی خودرو و سمت چپ به صورت کامل دیده شود.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-left.webp",
            "instructions": [
              "جلوی خودرو و سمت چپ به طور کامل داخل کادر باشد.",
              "حدود ۳ متر از خودرو فاصله بگیرید.",
              "از زاویه ۴۵ درجه سمت چپ عکس بگیرید."
            ],
            "distance": "۳ متر",
            "height": "کمر",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "خودرو کامل در کادر"
            ],
            "guidanceTopics": [
              "frame",
              "distance",
              "angle"
            ]
          },
          {
            "id": "back-45-left",
            "title": "عقب ۴۵° چپ",
            "description": "عقب خودرو و سمت چپ به صورت کامل دیده شود.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/back-45-left.webp",
            "instructions": [
              "تمام قسمت عقب و سمت چپ خودرو داخل کادر باشد.",
              "خودرو را از زاویه ۴۵ درجه ثبت کنید.",
              "در نور کافی و بدون سایه شدید عکاسی کنید."
            ],
            "distance": "۳ متر",
            "height": "کمر",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "خودرو کامل در کادر"
            ],
            "guidanceTopics": [
              "frame",
              "angle",
              "glare"
            ]
          }
        ]
      },
      {
        "id": "front",
        "title": "جلو",
        "order": 3,
        "photoRequirements": [
          {
            "id": "front-plate",
            "title": "نمای مستقیم جلو با پلاک",
            "description": "یک عکس مستقیم از نمای جلوی خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/front-plate.webp",
            "instructions": [
              "مستقیم روبه‌روی خودرو بایستید؛ خودرو وسط کادر باشد.",
              "نمای کامل جلو را بدون برش و زاویه شدید ثبت کنید.",
              "پلاک بدون بازتاب نور و کاملاً خوانا باشد."
            ],
            "distance": "۳ متر",
            "height": "چراغ‌ها",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "پلاک خوانا است"
            ],
            "guidanceTopics": [
              "angle",
              "frame",
              "text"
            ]
          }
        ]
      },
      {
        "id": "rear",
        "title": "عقب",
        "order": 4,
        "photoRequirements": [
          {
            "id": "rear-plate",
            "title": "نمای مستقیم عقب با پلاک",
            "description": "یک عکس مستقیم از نمای عقب خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/rear-plate.webp",
            "instructions": [
              "مستقیم پشت خودرو بایستید؛ خودرو وسط کادر باشد.",
              "تمام نمای عقب بدون برش و زاویه شدید داخل کادر باشد.",
              "پلاک کاملاً خوانا و بدون بازتاب باشد."
            ],
            "distance": "۳ متر",
            "height": "چراغ‌ها",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "پلاک خوانا است"
            ],
            "guidanceTopics": [
              "angle",
              "frame",
              "text"
            ]
          }
        ]
      },
      {
        "id": "cabin",
        "title": "کابین",
        "order": 5,
        "photoRequirements": [
          {
            "id": "odometer-on",
            "title": "کیلومترشمار",
            "description": "خودرو را روشن کنید و تصویری واضح از کیلومترشمار بگیرید.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/odometer-on.webp",
            "instructions": [
              "خودرو را روشن و در حالت توقف نگه دارید.",
              "تمام صفحه کیلومترشمار در کادر باشد.",
              "عدد کیلومتر خوانا باشد؛ از بازتاب نور جلوگیری کنید."
            ],
            "distance": "نزدیک",
            "height": "داشبورد",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "عدد کیلومتر خوانا است"
            ],
            "guidanceTopics": [
              "ignition",
              "frame",
              "glare"
            ]
          },
          {
            "id": "driver-interior",
            "title": "نمای داخل کابین از سمت راننده",
            "description": "از سمت راننده تصویری بگیرید که فضای داخلی خودرو به صورت واضح دیده شود.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/driver-interior.webp",
            "instructions": [
              "درِ سمت راننده را باز کنید.",
              "فرمان، داشبورد و صندلی‌ها دیده شوند.",
              "خیلی نزدیک نشوید؛ فضای داخلی کامل دیده شود."
            ],
            "distance": "۱ متر",
            "height": "درِ راننده",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "کابین کامل در کادر"
            ],
            "guidanceTopics": [
              "interior",
              "frame",
              "distance"
            ]
          }
        ]
      },
      {
        "id": "engine-details",
        "title": "موتور و مشخصات",
        "order": 6,
        "photoRequirements": [
          {
            "id": "engine-bay",
            "title": "محفظه موتور",
            "description": "کاپوت را باز کنید و یک تصویر کامل و واضح از محفظه موتور بگیرید.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/engine-bay.webp",
            "instructions": [
              "خودرو متوقف باشد؛ کاپوت را کاملاً و ایمن باز کنید.",
              "تمام محفظه موتور دیده شود.",
              "گوشی ثابت و تصویر بدون تاری باشد."
            ],
            "distance": "۱ متر",
            "height": "سینه",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "محفظه کامل در کادر"
            ],
            "guidanceTopics": [
              "hood",
              "frame",
              "steady"
            ]
          },
          {
            "id": "spec-plate",
            "title": "محل شماره شاسی خودرو",
            "description": "شماره شاسی خودرو — انتخاب یکی از چهار گزینه. فقط یک تصویر لازم است.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/spec-plate.webp",
            "instructions": [
              "از نزدیک روی پلاک مشخصات فوکوس کنید.",
              "تمام متن پلاک داخل کادر باشد.",
              "نوشته‌ها خوانا و بدون بازتاب نور باشند."
            ],
            "distance": "۳۰ سانتی‌متر",
            "height": "هم‌سطح پلاک",
            "orientation": "landscape",
            "choice": {
              "groupId": "vehicle-identification",
              "alternatives": [
                "pillar",
                "engine",
                "seat",
                "windshield"
              ]
            },
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "اطلاعات قابل خواندن است"
            ],
            "guidanceTopics": [
              "text",
              "frame",
              "glare"
            ]
          }
        ]
      },
      {
        "id": "roof",
        "title": "سقف",
        "order": 7,
        "photoRequirements": [
          {
            "id": "car-roof",
            "title": "نمای سقف",
            "description": "تمام سطح سقف خودرو را در تصویر نشان دهید.",
            "sampleImage": "/assets/inspection-vehicle/photo-guides/car-roof.webp",
            "instructions": [
              "از موقعیتی ایمن، گوشی را بالاتر بگیرید.",
              "بیشترین سطح سقف و گوشه‌های اصلی در کادر باشند.",
              "برای عکاسی روی خودرو نایستید."
            ],
            "distance": "۱ متر",
            "height": "بالاتر از سقف",
            "orientation": "landscape",
            "required": true,
            "status": "pending",
            "checks": [
              "واضح",
              "نور مناسب",
              "سقف کامل در کادر"
            ],
            "guidanceTopics": [
              "roof",
              "frame",
              "steady"
            ]
          }
        ]
      }
    ],
    "captureRequirements": {
      "odometerRequirementId": "odometer-on",
      "video360Required": true
    }
  },
  "updatedAt": "2026-10-27T08:30:00Z",
  "updatedBy": "staff-example",
  "publishedAt": "2026-10-27T08:30:00Z"
}
```

### تعریف AdminTemplate

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "id": {
      "type": "string",
      "minLength": 1
    },
    "title": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    },
    "partner": {
      "type": "string",
      "minLength": 1
    },
    "currentPublishedId": {
      "type": "string",
      "minLength": 1
    },
    "versions": {
      "type": "array",
      "items": {
        "$ref": "#/$defs/TemplateVersion"
      }
    }
  },
  "required": [
    "id",
    "title",
    "partner",
    "versions"
  ]
}
```

### مثال مستقل AdminTemplate

```json
{
  "id": "template-example",
  "title": "بازدید بدنه سدان نمونه",
  "partner": "کارگزاری نمونه",
  "currentPublishedId": "template-version-example",
  "versions": [
    {
      "id": "template-version-example",
      "version": 2,
      "revision": 1,
      "state": "published",
      "snapshot": {
        "photoPolicyVersion": 2,
        "templateId": "body-image-guided",
        "templateVersion": 2,
        "sections": [
          {
            "id": "right",
            "title": "نمای راست",
            "order": 1,
            "photoRequirements": [
              {
                "id": "front-45-right",
                "title": "جلو ۴۵° راست",
                "description": "جلوی خودرو و سمت راست به صورت کامل دیده شود.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-right.webp",
                "instructions": [
                  "جلوی خودرو و سمت راست به طور کامل داخل کادر باشد.",
                  "حدود ۳ متر از خودرو فاصله بگیرید.",
                  "از زاویه ۴۵ درجه سمت راست عکس بگیرید."
                ],
                "distance": "۳ متر",
                "height": "کمر",
                "orientation": "landscape",
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "خودرو کامل در کادر"
                ],
                "guidanceTopics": [
                  "frame",
                  "distance",
                  "angle"
                ]
              },
              {
                "id": "back-45-right",
                "title": "عقب ۴۵° راست",
                "description": "عقب خودرو و سمت راست به صورت کامل دیده شود.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/back-45-right.webp",
                "instructions": [
                  "تمام قسمت عقب و سمت راست خودرو داخل کادر باشد.",
                  "خودرو را از زاویه ۴۵ درجه ثبت کنید.",
                  "در نور کافی و بدون سایه شدید عکاسی کنید."
                ],
                "distance": "۳ متر",
                "height": "کمر",
                "orientation": "landscape",
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "خودرو کامل در کادر"
                ],
                "guidanceTopics": [
                  "frame",
                  "angle",
                  "glare"
                ]
              }
            ]
          },
          {
            "id": "left",
            "title": "نمای چپ",
            "order": 2,
            "photoRequirements": [
              {
                "id": "front-45-left",
                "title": "جلو ۴۵° چپ",
                "description": "جلوی خودرو و سمت چپ به صورت کامل دیده شود.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/front-45-left.webp",
                "instructions": [
                  "جلوی خودرو و سمت چپ به طور کامل داخل کادر باشد.",
                  "حدود ۳ متر از خودرو فاصله بگیرید.",
                  "از زاویه ۴۵ درجه سمت چپ عکس بگیرید."
                ],
                "distance": "۳ متر",
                "height": "کمر",
                "orientation": "landscape",
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "خودرو کامل در کادر"
                ],
                "guidanceTopics": [
                  "frame",
                  "distance",
                  "angle"
                ]
              },
              {
                "id": "back-45-left",
                "title": "عقب ۴۵° چپ",
                "description": "عقب خودرو و سمت چپ به صورت کامل دیده شود.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/back-45-left.webp",
                "instructions": [
                  "تمام قسمت عقب و سمت چپ خودرو داخل کادر باشد.",
                  "خودرو را از زاویه ۴۵ درجه ثبت کنید.",
                  "در نور کافی و بدون سایه شدید عکاسی کنید."
                ],
                "distance": "۳ متر",
                "height": "کمر",
                "orientation": "landscape",
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "خودرو کامل در کادر"
                ],
                "guidanceTopics": [
                  "frame",
                  "angle",
                  "glare"
                ]
              }
            ]
          },
          {
            "id": "front",
            "title": "جلو",
            "order": 3,
            "photoRequirements": [
              {
                "id": "front-plate",
                "title": "نمای مستقیم جلو با پلاک",
                "description": "یک عکس مستقیم از نمای جلوی خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/front-plate.webp",
                "instructions": [
                  "مستقیم روبه‌روی خودرو بایستید؛ خودرو وسط کادر باشد.",
                  "نمای کامل جلو را بدون برش و زاویه شدید ثبت کنید.",
                  "پلاک بدون بازتاب نور و کاملاً خوانا باشد."
                ],
                "distance": "۳ متر",
                "height": "چراغ‌ها",
                "orientation": "landscape",
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "پلاک خوانا است"
                ],
                "guidanceTopics": [
                  "angle",
                  "frame",
                  "text"
                ]
              }
            ]
          },
          {
            "id": "rear",
            "title": "عقب",
            "order": 4,
            "photoRequirements": [
              {
                "id": "rear-plate",
                "title": "نمای مستقیم عقب با پلاک",
                "description": "یک عکس مستقیم از نمای عقب خودرو بگیرید، به طوری که پلاک کاملاً مشخص و خوانا باشد.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/rear-plate.webp",
                "instructions": [
                  "مستقیم پشت خودرو بایستید؛ خودرو وسط کادر باشد.",
                  "تمام نمای عقب بدون برش و زاویه شدید داخل کادر باشد.",
                  "پلاک کاملاً خوانا و بدون بازتاب باشد."
                ],
                "distance": "۳ متر",
                "height": "چراغ‌ها",
                "orientation": "landscape",
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "پلاک خوانا است"
                ],
                "guidanceTopics": [
                  "angle",
                  "frame",
                  "text"
                ]
              }
            ]
          },
          {
            "id": "cabin",
            "title": "کابین",
            "order": 5,
            "photoRequirements": [
              {
                "id": "odometer-on",
                "title": "کیلومترشمار",
                "description": "خودرو را روشن کنید و تصویری واضح از کیلومترشمار بگیرید.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/odometer-on.webp",
                "instructions": [
                  "خودرو را روشن و در حالت توقف نگه دارید.",
                  "تمام صفحه کیلومترشمار در کادر باشد.",
                  "عدد کیلومتر خوانا باشد؛ از بازتاب نور جلوگیری کنید."
                ],
                "distance": "نزدیک",
                "height": "داشبورد",
                "orientation": "landscape",
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "عدد کیلومتر خوانا است"
                ],
                "guidanceTopics": [
                  "ignition",
                  "frame",
                  "glare"
                ]
              },
              {
                "id": "driver-interior",
                "title": "نمای داخل کابین از سمت راننده",
                "description": "از سمت راننده تصویری بگیرید که فضای داخلی خودرو به صورت واضح دیده شود.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/driver-interior.webp",
                "instructions": [
                  "درِ سمت راننده را باز کنید.",
                  "فرمان، داشبورد و صندلی‌ها دیده شوند.",
                  "خیلی نزدیک نشوید؛ فضای داخلی کامل دیده شود."
                ],
                "distance": "۱ متر",
                "height": "درِ راننده",
                "orientation": "landscape",
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "کابین کامل در کادر"
                ],
                "guidanceTopics": [
                  "interior",
                  "frame",
                  "distance"
                ]
              }
            ]
          },
          {
            "id": "engine-details",
            "title": "موتور و مشخصات",
            "order": 6,
            "photoRequirements": [
              {
                "id": "engine-bay",
                "title": "محفظه موتور",
                "description": "کاپوت را باز کنید و یک تصویر کامل و واضح از محفظه موتور بگیرید.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/engine-bay.webp",
                "instructions": [
                  "خودرو متوقف باشد؛ کاپوت را کاملاً و ایمن باز کنید.",
                  "تمام محفظه موتور دیده شود.",
                  "گوشی ثابت و تصویر بدون تاری باشد."
                ],
                "distance": "۱ متر",
                "height": "سینه",
                "orientation": "landscape",
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "محفظه کامل در کادر"
                ],
                "guidanceTopics": [
                  "hood",
                  "frame",
                  "steady"
                ]
              },
              {
                "id": "spec-plate",
                "title": "محل شماره شاسی خودرو",
                "description": "شماره شاسی خودرو — انتخاب یکی از چهار گزینه. فقط یک تصویر لازم است.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/spec-plate.webp",
                "instructions": [
                  "از نزدیک روی پلاک مشخصات فوکوس کنید.",
                  "تمام متن پلاک داخل کادر باشد.",
                  "نوشته‌ها خوانا و بدون بازتاب نور باشند."
                ],
                "distance": "۳۰ سانتی‌متر",
                "height": "هم‌سطح پلاک",
                "orientation": "landscape",
                "choice": {
                  "groupId": "vehicle-identification",
                  "alternatives": [
                    "pillar",
                    "engine",
                    "seat",
                    "windshield"
                  ]
                },
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "اطلاعات قابل خواندن است"
                ],
                "guidanceTopics": [
                  "text",
                  "frame",
                  "glare"
                ]
              }
            ]
          },
          {
            "id": "roof",
            "title": "سقف",
            "order": 7,
            "photoRequirements": [
              {
                "id": "car-roof",
                "title": "نمای سقف",
                "description": "تمام سطح سقف خودرو را در تصویر نشان دهید.",
                "sampleImage": "/assets/inspection-vehicle/photo-guides/car-roof.webp",
                "instructions": [
                  "از موقعیتی ایمن، گوشی را بالاتر بگیرید.",
                  "بیشترین سطح سقف و گوشه‌های اصلی در کادر باشند.",
                  "برای عکاسی روی خودرو نایستید."
                ],
                "distance": "۱ متر",
                "height": "بالاتر از سقف",
                "orientation": "landscape",
                "required": true,
                "status": "pending",
                "checks": [
                  "واضح",
                  "نور مناسب",
                  "سقف کامل در کادر"
                ],
                "guidanceTopics": [
                  "roof",
                  "frame",
                  "steady"
                ]
              }
            ]
          }
        ],
        "captureRequirements": {
          "odometerRequirementId": "odometer-on",
          "video360Required": true
        }
      },
      "updatedAt": "2026-10-27T08:30:00Z",
      "updatedBy": "staff-example",
      "publishedAt": "2026-10-27T08:30:00Z"
    }
  ]
}
```

### تعریف StaffMember

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "staffId": {
      "type": "string",
      "minLength": 1
    },
    "name": {
      "type": "string",
      "minLength": 1
    },
    "identifier": {
      "type": "string",
      "minLength": 1
    },
    "role": {
      "enum": [
        "platform-admin",
        "reviewer",
        "template-editor",
        "viewer"
      ]
    },
    "active": {
      "type": "boolean"
    },
    "capacity": {
      "type": "integer",
      "minimum": 0,
      "maximum": 10000
    }
  },
  "required": [
    "staffId",
    "name",
    "identifier",
    "role",
    "active",
    "capacity"
  ]
}
```

### مثال مستقل StaffMember

```json
{
  "staffId": "staff-example",
  "name": "کارشناس نمونه",
  "identifier": "source-subject-example",
  "role": "reviewer",
  "active": true,
  "capacity": 8
}
```

### تعریف AuditEntry

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "id": {
      "type": "string",
      "minLength": 1
    },
    "at": {
      "type": "string",
      "format": "date-time"
    },
    "actor": {
      "type": "string",
      "minLength": 1
    },
    "action": {
      "type": "string",
      "minLength": 1
    },
    "resource": {
      "type": "string",
      "minLength": 1
    }
  },
  "required": [
    "id",
    "at",
    "actor",
    "action",
    "resource"
  ]
}
```

### مثال مستقل AuditEntry

```json
{
  "id": "audit-example",
  "at": "2026-10-27T08:30:00Z",
  "actor": "staff-example",
  "action": "template.published",
  "resource": "template-version-example"
}
```

### تعریف Webhook

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "id": {
      "type": "string",
      "minLength": 1
    },
    "label": {
      "type": "string",
      "minLength": 1
    },
    "endpoint": {
      "type": "string",
      "minLength": 1
    },
    "event": {
      "enum": [
        "inspection.submitted",
        "additional-evidence.resubmitted"
      ]
    },
    "enabled": {
      "type": "boolean"
    }
  },
  "required": [
    "id",
    "label",
    "endpoint",
    "event",
    "enabled"
  ]
}
```

### مثال مستقل Webhook

```json
{
  "id": "webhook-example",
  "label": "اعلان ارسال بازدید",
  "endpoint": "https://brokerage.example.invalid/events/inspection",
  "event": "inspection.submitted",
  "enabled": false
}
```

### تعریف NotificationEvent

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "id": {
      "type": "string",
      "minLength": 1
    },
    "tenantId": {
      "type": "string",
      "minLength": 1
    },
    "inspectionId": {
      "type": "string",
      "minLength": 1
    },
    "trackingCode": {
      "type": "string",
      "minLength": 1
    },
    "type": {
      "enum": [
        "submitted",
        "changes-requested",
        "rejected",
        "review-approved",
        "forwarded"
      ]
    },
    "at": {
      "type": "string",
      "format": "date-time"
    },
    "customerReason": {
      "type": "string",
      "maxLength": 2000
    }
  },
  "required": [
    "id",
    "tenantId",
    "inspectionId",
    "trackingCode",
    "type",
    "at"
  ],
  "allOf": [
    {
      "if": {
        "properties": {
          "type": {
            "const": "rejected"
          }
        },
        "required": [
          "type"
        ]
      },
      "then": {
        "properties": {
          "customerReason": {
            "minLength": 1,
            "type": "string"
          }
        },
        "required": [
          "customerReason"
        ]
      }
    }
  ]
}
```

### مثال مستقل NotificationEvent

```json
{
  "id": "event-example",
  "tenantId": "brokerage-example",
  "inspectionId": "insp_contract_001",
  "trackingCode": "BDI-8F31K2",
  "type": "review-approved",
  "at": "2026-10-27T08:30:00Z"
}
```

### تعریف ForwardingSnapshot

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "deliveryKey": {
      "type": "string",
      "minLength": 1
    },
    "submissionId": {
      "type": "string",
      "minLength": 1
    },
    "sourceRequestId": {
      "type": "string",
      "minLength": 1
    },
    "inspectionId": {
      "type": "string",
      "minLength": 1
    },
    "trackingCode": {
      "type": "string",
      "minLength": 1
    },
    "decision": {
      "const": "approved"
    },
    "approvedAt": {
      "type": "string",
      "format": "date-time"
    },
    "submittedAt": {
      "type": "string",
      "format": "date-time"
    },
    "templateId": {
      "type": "string",
      "minLength": 1
    },
    "templateVersion": {
      "type": "integer",
      "minimum": 1
    },
    "location": {
      "$ref": "#/$defs/Location"
    },
    "vehicle": {
      "$ref": "#/$defs/Vehicle"
    },
    "odometer": {
      "$ref": "#/$defs/Odometer"
    },
    "media": {
      "type": "array",
      "items": {
        "$ref": "#/$defs/Evidence"
      },
      "minItems": 1
    }
  },
  "required": [
    "deliveryKey",
    "submissionId",
    "sourceRequestId",
    "inspectionId",
    "trackingCode",
    "decision",
    "approvedAt",
    "submittedAt",
    "templateId",
    "templateVersion",
    "location",
    "vehicle",
    "odometer",
    "media"
  ]
}
```

### مثال مستقل ForwardingSnapshot

```json
{
  "deliveryKey": "delivery-example",
  "submissionId": "submission-example",
  "sourceRequestId": "REQ-DEMO-001",
  "inspectionId": "insp_contract_001",
  "trackingCode": "BDI-8F31K2",
  "decision": "approved",
  "approvedAt": "2026-10-27T08:30:00Z",
  "submittedAt": "2026-10-27T08:30:00Z",
  "templateId": "body-image-guided",
  "templateVersion": 2,
  "location": {
    "latitude": 35.699739,
    "longitude": 51.338097,
    "accuracyMeters": 8,
    "formattedAddress": "تهران، خیابان نمونه، محل بازدید",
    "buildingNumber": "نمونه قراردادی",
    "unitFloor": "نمونه قراردادی",
    "parkingDescription": "نمونه قراردادی"
  },
  "vehicle": {
    "id": "11111111-1111-4111-8111-111111111111",
    "make": "خودروی نمونه",
    "model": "سدان نمونه",
    "modelYear": 2024,
    "color": "سفید",
    "bodyColor": "#F1F5F9",
    "plate": {
      "firstTwoDigits": "12",
      "letter": "ب",
      "threeDigits": "345",
      "regionDigits": "67"
    },
    "maskedVin": "DEMO••••••3456",
    "confirmed": true,
    "version": "AAAAAAAAB9E="
  },
  "odometer": {
    "kilometers": 48320,
    "updatedAt": "2026-10-26T09:00:00Z"
  },
  "media": [
    {
      "evidenceId": "11111111-1111-4111-8111-111111111111",
      "evidenceVersionId": "22222222-2222-4222-8222-222222222222",
      "inspectionId": "insp_contract_001",
      "kind": "photo",
      "requirementId": "spec-plate",
      "alternativeId": "pillar",
      "revision": "client-revision-0002",
      "upload": "uploaded",
      "verification": "processing",
      "byteSize": 420000,
      "mimeType": "image/jpeg",
      "sha256": "0000000000000000000000000000000000000000000000000000000000000000",
      "current": true,
      "version": "AAAAAAAAB9E="
    }
  ]
}
```

### تعریف ForwardingJob

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "jobId": {
      "type": "string",
      "minLength": 1
    },
    "inspectionId": {
      "type": "string",
      "minLength": 1
    },
    "submissionId": {
      "type": "string",
      "minLength": 1
    },
    "deliveryKey": {
      "type": "string",
      "minLength": 1
    },
    "phase": {
      "enum": [
        "ready",
        "sending",
        "retrying",
        "failed",
        "acknowledged"
      ]
    },
    "attemptCount": {
      "type": "integer",
      "minimum": 0
    },
    "version": {
      "type": "string",
      "minLength": 1
    },
    "nextRetryAt": {
      "type": "string",
      "format": "date-time"
    }
  },
  "required": [
    "jobId",
    "inspectionId",
    "submissionId",
    "deliveryKey",
    "phase",
    "attemptCount",
    "version"
  ]
}
```

### مثال مستقل ForwardingJob

```json
{
  "jobId": "job-example",
  "inspectionId": "insp_contract_001",
  "submissionId": "submission-example",
  "deliveryKey": "delivery-example",
  "phase": "ready",
  "attemptCount": 0,
  "version": "version-example"
}
```

### تعریف DeliveryAcknowledgement

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "deliveryKey": {
      "type": "string",
      "minLength": 1
    },
    "inspectionId": {
      "type": "string",
      "minLength": 1
    },
    "submissionId": {
      "type": "string",
      "minLength": 1
    },
    "accepted": {
      "const": true
    },
    "acknowledgementId": {
      "type": "string",
      "minLength": 1
    },
    "acknowledgedAt": {
      "type": "string",
      "format": "date-time"
    }
  },
  "required": [
    "deliveryKey",
    "inspectionId",
    "submissionId",
    "accepted",
    "acknowledgementId",
    "acknowledgedAt"
  ]
}
```

### مثال مستقل DeliveryAcknowledgement

```json
{
  "deliveryKey": "delivery-example",
  "inspectionId": "insp_contract_001",
  "submissionId": "submission-example",
  "accepted": true,
  "acknowledgementId": "ack-example",
  "acknowledgedAt": "2026-10-27T08:30:00Z"
}
```
