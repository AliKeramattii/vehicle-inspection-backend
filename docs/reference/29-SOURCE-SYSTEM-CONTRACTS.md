# وابستگی‌های سامانه بیمه و سرویس‌های بیرونی

این فصل interface موردنیاز را مشخص می‌کند؛ نام HTTP یا سرویس موجود مبدأ را جعل نمی‌کند. آدرس، auth، نسخه، SLA و نمونه sandbox باید از تیم مبدأ دریافت و تصویب شوند. مثال‌های شناسه/دامنه ساختگی‌اند. Backend بازدید این وابستگی‌ها را پشت adapter سروری مصرف می‌کند، نه مستقیماً از مرورگر با service secret.

| مسئول | قابلیت لازم | ورودی منطقی | خروجی لازم | خطا و امنیت |
|---|---|---|---|---|
| هویت مبدأ | تحویل مشتری | ticket محدود +state/nonce یا OIDCcode | issuer/subject، sourceRequestId، mobile معتبر و expiry | یک‌بارمصرف، audience/tenant/host، replay، عدم log ticket |
| درخواست بیمه مبدأ | خواندن درخواست مالک | subject و externalRequestId معتبر | شناسه مشتری/خودرو، وضعیت درخواست و snapshot مجاز | نه lookup با phone تنها؛ ۴۰۳/۴۰۴ بدون افشا؛ CAS منبع در صورت نیاز |
| خودرو مبدأ | خواندن حقایق معتبر | request/vehicle reference scoped | make/model/year/color/plate و VIN projection مجاز | Backend بازدید حق تغییر master را ضمنی ندارد |
| هویت کارکنان | ورود و خروج سازمانی | code+PKCE یا بلیت trusted | issuer/subject، گروه/نقش، expiry/revocation | روش نهایی D01؛ secret فقط Backend؛ mock نقش تولیدی نیست |
| پیامک مبدأ یا gateway مصوب | صدور/تأیید چالش | شماره trusted و challenge زمینه‌دار | challengeId، cooldown، نتیجه مصرف | rate/attempt/expiry؛ طول تولیدی هنوز تصویب نشده |
| مقصد بیمه | دریافت نتیجه تأییدشده | DeliveryKey، sourceRequest، tracking، snapshot approved، نسخه‌های دقیق ومراجع رسانه مجاز | acknowledgementId، receivedAt، وضعیت پذیرش و query نتیجه نامطمئن |۲۰۰/۲۰۲/۲۰۴ بدون semantics مصوب، دلیل FORWARDED نیست |
| مقصد بیمه | استعلام دریافت | همان DeliveryKey تحت serverauth | همان receipt یا not-found/pending دقیق | timeout بعد ازموفقیت نباید ارسال تجاری تکراری بسازد |
| Neshan مرکزی | reverse مختصات | lat/lng معتبر و quota | نشانی فارسی امن | private service key مرکزی؛ public web key فقط origin مجاز |
| اعلان اختیاری | ابلاغ رویداد | eventId/recipientreference/template | receipt کانال یاخطای طبقه‌بندی‌شده | رضایت، dedupe، عدم نشت mediaURL/PII؛ اختیاری |

## تحویل نهایی

payload پیشنهادی دسته‌داده‌ها شامل sourceRequestId، inspectionId/trackingCode، تصمیم نهایی، زمان submit/review، location، vehicle/plate، odometer عددی، template/version و required evidence references با kind/requirement/alternative/revision/hash/MIME/size است. بایت رسانه باید با stream یاپروتکل موردتوافق منتقل شود، نه Base64 JSON. یادداشت خصوصی، کوکی، کلید، absolute root و draft نامعتبر وارد payload نشوند. شکل نهایی با API بیمه تصویب می‌شود؛ هیچ secret یا URL مقصد آزاد ازمشتری پذیرفته نشود.

در زمان approval، snapshot و outbox همان تصمیم درتراکنش ثبت شوند. worker بیرونتراکنش SQL با lease می‌فرستد؛ پاسخ گم‌شده با DeliveryKey استعلام/replay می‌شود. فقط receipt معتبرهمان submission اجازه FORWARDED می‌دهد. failure هرگز customer را مجبور به عکاسی دوباره نمی‌کند. credentials مقصد خراب، خطای validation و failure موقت سیاست retry متفاوت دارند.
