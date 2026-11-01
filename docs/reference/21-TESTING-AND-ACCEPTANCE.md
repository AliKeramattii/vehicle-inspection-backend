# آزمون و پذیرش Backend و اتصال

این معیارها برای آزمون آینده Backend هستند؛ ادعای اجرای SQL یا API تولیدی در این task نیستند. صحت syntax مستندات جای تست تراکنش، امنیت یا دستگاه را نمی‌گیرد. هر endpoint فصل ۵ باید تست موفقیت، validation، احراز هویت، مالکیت، نسخه و retry داشته باشد.

| حوزه | سناریوهای الزامی |
|---|---|
| هویت | بلیت نامعتبر/منقضی/replay، issuer/audience/nonce اشتباه، شماره یا tracking دلخواه، خروج، انقضا و چند درخواست یک مشتری |
| tenant | ID یکسان در نصب دیگر، tenant/host جعلی، staff خارج scope و API بدون fallback HTML |
| سیاست عکس | ده fixed همراه هر یک از pillar، engine، seat، windshield جداگانه کامل شوند؛ نبود engine-bay همیشه مانع باشد |
| VIN | guide بدون عکس، Blob با metadata نامعتبر، گزینه‌های اضافی، ID تکراری، alternative خارج قالب و accepted A همراه draft B |
| تاریخچه | نسخه ۱ دوازده‌عکسی حفظ؛ نسخه ۲ یازده‌عکسی؛ publish/resume بدون migrate؛ تلاش تازه پس از رد با history محفوظ |
| کیلومتر | صفر، 48320، missing، منفی، اعشار، overflow، تعویض عکس بدون پاک‌شدن عدد و scope فیلد |
| ویدیو | MIME/اندازه/مدت، Range/416، دوام فایل، replacement محفوظ و همان pipeline مشترک |
| انتقال | register replay، قطع PUT، expiry مجوز، complete دوباره، hash/size نامعتبر، processing جدا از verified و فایل مفقود |
| هم‌زمانی | دوبار submit، دو tab، reassign هم‌زمان decision، دو publication، job دیررس و کلید یکسان با payload متفاوت |
| اصلاح | فقط item/task فعال، requestVersion کهنه، اصل خواندنی و resubmit فقط با receipt همان دور |
| کارشناس | تصمیم مدرک با تصمیم کل جدا، همه نسخه‌های لازم و فیلدها، دلیل رد اجباری و notes خارج DTO مشتری |
| فایل | traversal/encoding/UNC/reparse، collision، MIME spoof، decode bomb، quota، حریم thumbnail/history و منع public root |
| بازیابی | crash میان file/SQL، receipt گم‌شده، orphan/missing، backup/restore سازگار و retention hold |
| تحویل | approval+outbox اتمیک، timeout نامطمئن، همان DeliveryKey، ۲۰۲ بدون ack و عدم retry بی‌پایان auth failure |
| تنظیمات | public projection، provider واحد، draft/publish، contrast/asset validation و راز نشان خارج برندینگ |
| میزبانی/دستگاه | runtime ID، deep link/refresh، بدون Node، safe area/keyboard، camera/codec/quota/offline و عدم GLB در ۲D |

fixtures تازه باید ۱۱ عکس، ویدیوی جدا و عدد کیلومتر داشته باشند. تست نباید برای موفقیت ۱۴ یا ۱۳ عکس جعل کند. uploaded+processing می‌تواند threshold باینری را برآورده کند ولی verified و تصمیم Reviewer جدا هستند. خطا نباید اصل پذیرفته‌شده را حذف کند.

## پایگاه و فایل

پس از تصویب، تیم Backend باید migration را در SQL disposable اجرا و FK، unique فیلترشده، CHECK، رفتار NULL، query plan و locking را با هم‌زمانی واقعی آزمایش کند. در این task هیچ دستور SQL به پایگاه فرستاده نمی‌شود؛ ScriptDom فقط syntax را parse می‌کند. rule چندجدولی، ACL و محتوای فایل از syntax اثبات نمی‌شوند؛ تلاش برای reference متقاطع و دورزدن guard باید تست شود.

## خروجی لازم برای پذیرش

OpenAPI نسخه‌دار، schema/مثال، خطا، idempotency/CAS، مجوز، pagination، حد فایل، fixture ساختگی، rollback و health همراه اجرای موفق CI ارائه شود. قبولی Frontend با mock، امنیت ASP.NET را ثابت نمی‌کند. نتایج JSON/SQL/Mermaid مستندات و آزمون واقعی سیستم باید جدا گزارش شوند.
