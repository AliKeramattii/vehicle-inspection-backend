# خطا، HTTP و بازیابی

قرارداد زیر **پیشنهادی** و بر پایه Problem Details است؛ باید در OpenAPI نهایی تثبیت شود. Frontend DTO را به خطای دامنه/فیلد تبدیل می‌کند؛ متن امن Backend نباید همواره با پیام عمومی بی‌فایده جایگزین شود. stack/SQL/root/credential هرگز به مشتری برنگردد.

```json
{
  "type": "https://inspection.example.invalid/problems/UPLOAD_INCOMPLETE",
  "title": "برخی فایل‌ها هنوز ارسال نشده‌اند.",
  "status": 422,
  "code": "UPLOAD_INCOMPLETE",
  "traceId": "fixture-trace-001",
  "errors": { "evidence": ["نسخه انتخاب‌شده هنوز رسید پایدار ندارد."] }
}
```

| HTTP | معنا و رفتار Frontend |
|---|---|
| 400 | ساختار/field/encoding/header نامعتبر؛ خطا کنار ورودی، بدون retry خودکار همان داده |
| 401 | نشست/هویت منقضی یا نامعتبر؛ بازیابی ورود، حفظ داده محلی، بدون redirect HTML داخل API |
| 403 | نقش/مالکیت/ارجاع/قلم اصلاح مجاز نیست؛ retry مجوز نمی‌سازد |
| 404 | منبع نیست یا نمایش وجود آن مجاز نیست؛ پیام امن، نه افشای tenant دیگر |
| 409 | rowversion/قالب/درخواست/state یا payload متفاوت با همان key؛ reload و تصمیم تازه، نه overwrite |
| 410 | نسخه طبق retention واقعاً حذف شده؛ فقط به عامل مجاز و بدون افشای دیگران |
| 412 | If-Match با نسخه جاری نمی‌خواند، اگر پروتکل header تصویب شود؛ معنا با 409 یکسان‌سازی شود |
| 413 | فایل/درخواست بزرگ؛ limits مجاز روشن، اصل خوب حفظ؛ retry همان اندازه راه‌حل نیست |
| 415 | signature/MIME/codec غیرمجاز؛ راهنمای ضبط سازگار، نه تغییر جعلی پسوند |
| 416 | Range خارج از فایل؛ بازخوانی metadata/درخواست معتبر، نه failure کل inspection |
| 422 | قاعده دامنه مثل alternative نامعتبر، مدرک ناقص، عدد منفی یا نسخه غیرمجاز |
| 428 | precondition/version لازم داده نشده است |
| 429 | rate/quota؛ Retry-After معتبر؛ بدون حلقه فوری |
| 500/502/503/504 | خطای سرویس/شبکه/timeout؛ retry محدود فقط با هویت/کلید ثابت و حفظ accepted data |

requestId/correlation امن برای پشتیبانی مجاز است. errors نام فیلد DTO دارد؛ adapter مسیر را به فرم فعلی map می‌کند. کدهای نمونه لازم: AUTH_EXPIRED، FORBIDDEN_SCOPE، VERSION_CONFLICT، IDEMPOTENCY_CONFLICT، TEMPLATE_POLICY_MISMATCH، INVALID_ALTERNATIVE، UPLOAD_INCOMPLETE، MEDIA_TYPE_UNSUPPORTED، MEDIA_MISSING و FORWARDING_ACK_PENDING. enum نهایی باید توافق شود؛ کد نمونه به معنی سرویس پیاده‌شده نیست.

GET پاسخ JSON معتبر یا binary توافق‌شده دارد؛ HTML login یا body نامعتبر با ۲۰۰ موفقیت نیست. پاسخ ۲۰۲ برای فرمان درحال‌اجرا، نتیجه نهایی نیست و باید Location/status recovery و Retry-After تعریف شود. binary PUT staged، upload complete، processing، verified و Reviewer approved جدا هستند. Forwarding ۲۰۰ بدون ack معتبر موفقیت تحویل نیست.

خطای Neshan، مجوز GPS یا reverse lookup نباید آدرس دستی موجود را پاک کند. خطای Blob/فایل یک مدرک بقیه صف را از بین نمی‌برد. retry پس از پاسخ نامطمئن همان فرمان/نسخه را replay می‌کند؛ ID جدید به معنی بازیابی نیست. offline رسمی submit را مسدود می‌کند، نه اینکه موفقیت background جعل کند.
