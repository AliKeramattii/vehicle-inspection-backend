# اتصال GitHub و سیاست انتشار امن

گزارش اولیه در `2026-11-01` فقط Git و مستندات بود؛ در آن زمان Checkpoint 1 تکمیل و Checkpoint 2 شروع نشده بود. بخش‌های اولیه شاهد تاریخی همان انتشارند؛ وضعیت تأییدشدهٔ 2C، 2D و سپس طراحی 2E در انتهای این سند ثبت شده است.

## مقصد و نتیجهٔ بررسی اولیه

مخزن موجود و عمومی [AliKeramattii/vehicle-inspection-backend](https://github.com/AliKeramattii/vehicle-inspection-backend) مقصد مجاز است؛ مخزن دیگری ساخته نشده است. `origin` به `https://github.com/AliKeramattii/vehicle-inspection-backend.git` وصل شد. fetch و `ls-remote` موفق و فاقد refs بودند؛ remote در آغاز خالی و default branch معرفی‌شدهٔ GitHub برابر `main` بود.

HEAD اولیه `3c52503b345d3bc782feda8a5ca6effadb4ce65a` و branch محلی `main` بود؛ worktree پاک بود. هر چهار commit `196c000`، `1029465`، `2187316` و `3c52503` در زنجیرهٔ تاریخچه وجود داشتند.

اتصال GitHub حساب `AliKeramattii` و metadata دسترسی push/admin به همین مخزن را تأیید کرد. endpoint جداگانهٔ permission collaborator با محدودیت integration، 403 داد؛ این خطا با نبود دسترسی مخزن یکسان نیست. `gh auth status` ورود CLI را تأیید نکرد؛ نتیجهٔ واقعی transport Git باید مستقل بررسی شود. هیچ token یا credential در متن/فرمان/گزارش ذخیره نمی‌شود.

dry-run امنِ `main` با Git و credential manager موجود موفق شد؛ بنابراین نبود ورود در `gh` مانع transport Git نیست. dry-run هیچ object یا branchی را روی remote منتشر نکرد و با push واقعی اشتباه گرفته نمی‌شود.

## تعارض تاریخچه و مجوز صریح کاربر

در commit اولیه، `docs/reference/BACKEND_HANDOVER_ESSENTIAL_FA.zip` وجود دارد؛ blob آن `9a0bf21f6dc0cfa1288e4070ecda04270863e5cd` است. انتشار کامل همان تاریخچه، با منع ZIP در درخواست جدید ناسازگار بود. حذف فایل فقط در HEAD یا افزودن ignore، نسخهٔ تاریخی را از push حذف نمی‌کند.

پس از توضیح این تعارض، کاربر صریحاً انتخاب کرد: **«تاریخچهٔ ارسالی پاک‌سازی شود؛ نسخهٔ اصلی فقط محلی بماند»**. بنابراین SHAهای اصلی قرار نیست روی GitHub باقی بمانند. نسخهٔ اصلی در branch محلی `local-original-history-2026-11-01` نگهداری می‌شود؛ این branch هرگز push نمی‌شود. نسخهٔ ارسالی فقط ZIP را از tree تمام commitها حذف می‌کند و پیام، ترتیب، author/committer و تاریخ commitهای اصلی را حفظ می‌کند. `main` جدید، نسخهٔ قابل انتشار خواهد بود؛ force push یا بازنویسی remote لازم نیست چون remote خالی است.

export اجرا شد و [نقشهٔ کامل SHAها](GIT_HISTORY_EXPORT.json) ثبت شد. branch اصلی `local-original-history-2026-11-01` در `7e2d83ddeb33475d07f70f4471cd09e466f853a4` باقی ماند؛ main پاک‌شده پیش از ثبت manifest برابر `870be97f1fac406d98c3416403716a66dbe3581c` بود. در تک‌تک treeها فقط ZIP حذف شد و سایر بایت‌های پروژه و metadata/پیام commitها حفظ شدند. خود ZIP در مسیر محلی ignored با همان بایت‌ها باقی است.

| commit اصلی، فقط محلی | معادل پاک‌شده برای انتشار |
|---|---|
| `196c000` | `2ddf17a` |
| `1029465` | `2c9195c` |
| `2187316` | `613d351` |
| `3c52503` | `dafb037` |

وجود original SHA در یک سند، به معنی وجود آن commit یا blob خصوصی در GitHub نیست. هیچ force push، reset مخرب، worktree یا مخزن تازه‌ای ایجاد نشده است.

## بررسی امنیت پیش از انتشار

چهار commit اولیه، ۱۱۳ blob یکتا، نام فایل‌ها و محتوای متنی ۱۲ عضو ZIP بدون استخراج بررسی شدند. هیچ private key، provider token، SQL password، مقدار واقعی HMAC/API secret، فایل env واقعی، certificate خصوصی، media، backup یا bin/obj شناسایی نشد. تنها candidate مربوط به credential URI، مقدار ساختگی `user:password` در آزمون `FoundationOptionsTests.cs` روی دامنهٔ `.invalid` است؛ credential عملیاتی نیست.

شماره‌های موبایلِ شبیه PII فقط در mapping توسعه و مثال‌های مرجع دیده شدند؛ mapping آن را fixture و `contracts/examples.json` همهٔ مثال‌ها را ساختگی معرفی می‌کند. دادهٔ واقعی مشتری یا source اختصاصی Backend کارگزاری در این مخزن تحویل نشده است؛ فایل‌های SQL مرجع proposal هستند. این بررسی مبتنی بر الگو و بازبینی context است و تضمین مطلقِ نبود همهٔ انواع راز نیست.

ریسک آسیب‌پذیری dependencyهای پشتهٔ EOL قبلاً در [گزارش امنیت Checkpoint 1](checkpoint1/DEPENDENCY_SECURITY_FA.md) ثبت شده و با این کار رفع نمی‌شود. عمومی‌شدن source، تأیید عمومی‌بودن سرویس Production نیست.

## وضعیت اجرا

- [x] تاریخچه، branch، status، ignore و گزارش‌ها بررسی شدند.
- [x] origin تنظیم و remote خالی fetch شد.
- [x] سیاست اجباری گزارش نهایی فارسی با ۱۳ دسته در AGENTS، README و ادامهٔ AI ثبت شد.
- [x] مجوز پاک‌سازی تاریخچهٔ ارسالی با حفظ اصل فقط محلی دریافت شد.
- [x] export پاک‌شده و نقشهٔ SHAها ساخته و بررسی شد؛ اصل فقط محلی است.
- [x] main پاک‌شده با پنج commit و ۱۱۷ blob یکتا دوباره اسکن شد؛ archive یا مسیر ممنوع نداشت و تنها candidate همان fixture آزمون بود. commitهای مستندات افزوده نیز پیش از ارسال بررسی می‌شوند.
- [x] push عادی فقط `main` با exit code صفر انجام شد؛ upstream برابر `origin/main` است و remote فقط branch `main` دارد.

## نتیجهٔ واقعی انتشار و راستی‌آزمایی

نخستین push واقعی در `2026-11-01` موفق بود و پس از fetch، HEAD محلی و `origin/main` هر دو برابر `0537ae642241ca0f2012d59e4d433f6cd3e86a7a` بودند. این SHA مربوط به اولین انتشار بررسی‌شده است؛ این گزارش نیز در commit مستندات بعدی تکمیل می‌شود و آخرین SHA را باید از `git log -1` و `git ls-remote origin refs/heads/main` خواند تا ارجاع دوری به commit خود سند ایجاد نشود.

شش commit نخستِ ارسال‌شده: `2ddf17a`، `2c9195c`، `613d351`، `dafb037`، `870be97` و `0537ae6`. commit نهاییِ همین گزارش به‌صورت fast-forward معمولی ارسال می‌شود. هیچ force push، حذف commit remote، ارسال tag یا branch اصلی انجام نشده است. اصل تمام پنج commit محلی قبل از export در branch نگهداری اصل موجود و از `main` منتشرشده غیرقابل‌دسترسی از مسیر ancestry است.

راستی‌آزمایی مستقل:

- fetch و `ls-remote --symref`، branch پیش‌فرض و upstream `main` را تأیید کردند؛ tree منتشرشده ۱۰۲ فایل tracked دارد.
- با ابزار GitHub، `AGENTS.md`، `PLAN.md`، `README.md`، `Bazdid.sln` و فایل نمایندهٔ هرکدام از `src/Bazdid.Api/`، `tests/`، `docs/` و `deployment/iis/` از SHA منتشرشده خوانده شدند.
- درخواست مستقیم GitHub برای ZIP در همان SHA، پاسخ 404 داد؛ blob ZIP در هیچ commit reachable از `origin/main` وجود ندارد.
- tree/history منتشرشده archive، env واقعی، certificate، رسانه، backup یا bin/obj/artifacts ندارد؛ هر نگاشت SHA از روی ancestry کنترل شد.
- مقایسهٔ `main` با branch اصل برای `src/`، `tests/`، solution، SDK/config ساخت، `database/` و `deployment/` هیچ تفاوتی نداشت. هیچ endpoint، SQL، migration یا رفتار برنامه تغییر نکرده است.

آزمون اجرایی/build/runtime در این وظیفه دوباره اجرا نشد؛ فقط کنترل Git، اسکن تاریخچه و اعتبارسنجی اسناد انجام شد. نتیجهٔ ۴۳ آزمون و build موفق مربوط به Checkpoint 1 است. نگرانی‌های امنیت dependencyهای EOL و وابستگی پایگاه تست برای Checkpoint 2 همچنان باقی‌اند؛ مانع احراز هویت Git برای این انتشار وجود نداشت.

## ادامهٔ امن

checkpointهای بعدیِ مجاز و اعتبارسنجی‌شده به همین مخزن commit/push شوند. پیش از ارسال، fetch، URL، تغییرات و تمام تاریخچهٔ reachable **همان branch ارسالی** بررسی شوند؛ branch اصلیِ صرفاً محلی نباید وارد بررسی به‌عنوان محتوای مجاز ارسال شود. `git push --all`، `git push --mirror` و ارسال branch `local-original-history-2026-11-01` ممنوع‌اند. هیچ tag یا ref حامل تاریخچهٔ خصوصی منتشر نشود.

force push، حذف commit remote، reset مخرب، ایجاد مخزن دیگر و شروع Checkpoint 2 مجاز نیستند. در تعارض تاریخچهٔ تازهٔ remote، ابتدا آن را حفظ و راهکار امن branch/PR یا merge را بررسی کنید. گزارش نهایی هر وظیفه فارسی و دارای نتیجهٔ واقعی Git/test/build و وضعیت مرحله باشد. این وظیفه چون فقط Git/مستندات است، تست اجرایی تازه نمی‌طلبد؛ ۴۳ آزمون Checkpoint 1 نتیجهٔ تاریخی است، نه اجرای دوبارهٔ این وظیفه.

## انتشار تأییدشدهٔ Checkpoint 2C

مجوز مستقل `553dc9cd-5abe-4eb0-9856-ee1763d5250b` فقط provisioning محلی 2C را پوشش داد؛ منع شروع Checkpoint 2 در گزارش تاریخی بالا، وضعیت این مجوز جدید نیست. commit پیاده‌سازی `bf1c3c759d163ee716947af46f074b20d60fc043` شامل ۲۳ فایل بررسی‌شده به `origin/main` در همین مقصد مجاز با push عادی ارسال شد. پس از ارسال، `ls-remote` و `origin/main` و HEAD محلی همین SHA را نشان دادند و اختلاف ancestry برابر `0/0` بود. remote فقط `main` داشت؛ branch اصلِ محلی ارسال نشد.

با ابزار GitHub در همین commit، [walkthrough 2C](implementation/CHECKPOINT-02C-DATABASE-CREATION_FA.md) و [شاهد schema](checkpoint2c/SCHEMA_VERIFICATION.json) خوانده شدند. blob SHAهای remote به‌ترتیب `8879b0fef32ac56cfc91a9e8afc1fff98f89cb8a` و `017aaeda77c65d50b350310775b98cee909d6db7` دقیقاً با Git محلی برابر بودند؛ بنابراین مشاهدهٔ فایل‌ها جدا از موفقیت transport احراز شد. SHA اول مربوط به نسخهٔ walkthrough در commit پیاده‌سازی است؛ این گزارش تکمیلی، متن آن را به‌روز می‌کند.

پیش از انتشار، مقصد/refs، محتوای بسته و تاریخچهٔ reachable بررسی شدند؛ blob ZIP خصوصی از ancestry ارسالی قابل دسترسی نبود و هیچ archive، فایل پایگاه/backup، credential یا خروجی bin/obj به بسته اضافه نشد. branch `local-original-history-2026-11-01` بدون تغییر روی `7e2d83ddeb33475d07f70f4471cd09e466f853a4` ماند. فایل untracked کاربر `src/Bazdid.Api/Properties/launchSettings.json` با همان hash اولیه حفظ شد و جزو commit نیست؛ worktree کاملاً خالی گزارش نمی‌شود.

نتیجهٔ اجرایی تازهٔ این checkpoint: ۳۵ آزمون SQL rollback-only، چهار آزمون guard و ۴۳ آزمون برنامه موفق؛ build صفر warning/error. [شواهد تجمیعی](checkpoint2c/PROVISIONING_SUMMARY.json) تفکیک آن‌ها را ثبت می‌کند. پیشرفت **15% + 2 = 17%** است؛ 2D شروع نشده و O24 و حساب‌های runtime کم‌اختیار بازند. این ثبت نهاییِ صرفاً مستنداتی با commit جدا ارسال می‌شود؛ SHA همان commit و آخرین تطبیق remote در گزارش تحویل از Git واقعی خوانده می‌شوند تا سند به SHA خودش ارجاع دوری ندهد.

## انتشار تأییدشدهٔ Checkpoint 2D

در `2026-11-02` با مجوز `2df8399e-d511-49b7-af28-a075f801dd57`، commit پیاده‌سازی `30112f104d9def9a5ea91cfd56b78d21e581685a` شامل ۳۲ فایل بررسی‌شده از مبنای `b495b10`، با push عادی به همان origin/main ارسال شد. پس از ارسال، HEAD محلی، origin/main و ls-remote همین SHA را داشتند و اختلاف ancestry برابر `0/0` بود. remote فقط main داشت؛ هیچ force، tag یا branch اصل خصوصی ارسال نشد.

ابزار متصل GitHub در خواندن فایل‌ها خطای transport داد؛ بنابراین API عمومی GitHub برای همان commit خوانده شد و محتوای base64 هر سه فایل در دسترس بود. blob SHAهای زیر با Git محلی برابر بودند:

| فایل | blob SHA تأییدشده در commit پیاده‌سازی |
|---|---|
| [قرارداد reader](../src/Bazdid.Api/Domain/Brokerage/BrokerageContracts.cs) | `06a677d6ee34c3244995df439ea908da34921a55` |
| [walkthrough 2D](implementation/CHECKPOINT-02D-BROKERAGE-READER_FA.md) | `5e312789a9c068d6adffd99743006e0f53a0756f` |
| [شاهد آزمون برنامه](checkpoint2d/APPLICATION_VALIDATION.json) | `6f2665946a759e739b6fbe6b191535d8de53bcfc` |

این SHAهای blob به نسخهٔ commit پیاده‌سازی اشاره دارند؛ walkthrough و این گزارش در commit مستنداتی بعدی تکمیل می‌شوند. آخرین SHA و تطبیق HEAD پس از آن از Git واقعی در گزارش نهایی ثبت می‌شوند تا ارجاع دوری به SHA خود سند ایجاد نشود.

کنترل پیش از commit پیاده‌سازی: ۳۲ فایل، ۱۳ Markdown، ۱۴۲ پیوند محلی/یک anchor، اسکن ۱۳۶ فایل فعلی و ۱۷۶ blob تاریخی main، بدون هشدار راز باقی‌مانده؛ fixture URL آزمون قدیمی origin جدا تأیید شد. ZIP خصوصی از ancestry قابل ارسال غایب، branch اصل محلی روی SHA قبلی و فایل untracked کاربر با hash اولیه محفوظ بود. هیچ source اختصاصی، backup، فایل پایگاه، credential یا دادهٔ واقعی اضافه نشد؛ package/lockfile/target و SQL scriptها تغییر نکردند.

نتیجهٔ 2D: restore/build موفق با صفر warning/error؛ **۶۵ unit + ۴۳ integration = ۱۰۸ موفق**؛ smoke Kestrel واقعی و verification خواندنی DB قبل/بعد موفق. integration حافظه‌ای/DI/TestServer با SQL واقعی متفاوت است؛ آزمون‌های SQL 2C دوباره اجرا نشدند. [فرایند و محدودیت‌ها](implementation/CHECKPOINT-02D-BROKERAGE-READER_FA.md). **17% + 2 = 19%**؛ O24/O26 و mapping واقعی بازند؛ 2E–2G و auth/OTP/Session/Info/media شروع نشدند. تکمیل این ثبت Git سهم پیشرفت تازه ندارد.

## انتشار تأییدشدهٔ طرح Checkpoint 2E

در `2026-11-02`، مجوز `20acc386-4be3-48e7-84da-a7457cf34b6f` فقط طراحی را پوشش داد. commit طرح `9f5f7df94dc6f1dd6e854af8d52e2d4818fd3d06` شامل ۱۵ فایل مستنداتی بررسی‌شده از مبنای `d704ad2` با push عادی به همان origin/main ارسال شد. پس از ارسال، HEAD، origin/main و ls-remote همین SHA را نشان دادند و اختلاف `0/0` بود؛ remote فقط main داشت. branch اصل خصوصی روی `7e2d83ddeb33475d07f70f4471cd09e466f853a4` محفوظ و ارسال نشد؛ force یا tag در کار نبود.

با ابزار GitHub فایل‌های زیر در همان commit خوانده و blob SHA آن‌ها با Git محلی تطبیق داده شدند:

| فایل | blob SHA در commit طرح |
|---|---|
| [manifest پیشنهادی schema](design/BAZDIDINFO_SCHEMA_PROPOSAL.json) | `e8cc3e9d0616293ab1bdccb80ba50432c046b498` |
| [راهنمای طراحی 2E](implementation/CHECKPOINT-02E-INFO-PERSISTENCE-DESIGN_FA.md) | `3638c2b5a0f4d4f66c773df3f9f52d524cb230e5` |
| [کنترل طراحی/مخزن](checkpoint2e/DESIGN_VALIDATION.json) | `75e83dce53412bacdd853ad16a8f320a56703ab1` |

این hashها مربوط به commit طرح‌اند؛ راهنما و گزارش کنترل در commit تکمیل انتشار به‌روز می‌شوند. SHA نهایی آن ثبت و تطبیق remote در گزارش تحویل از Git واقعی خوانده می‌شود تا سند به SHA خودش ارجاع دوری ندهد.

کنترل پیش از commit طرح: ۱۵ فایل، ۱۱ Markdown، ۱۷۰ پیوند محلی/یک anchor، دو مثال JSON و اسکن ۱۴۱ فایل فعلی/۲۱۱ blob تاریخی main بدون هشدار راز باقی‌مانده. fixture URL آزمون قدیمی جدا تأیید شد. ZIP خصوصی از ancestry قابل ارسال غایب بود؛ هیچ archive، دادهٔ واقعی، credential، فایل پایگاه یا backup اضافه نشد. ۲۶ فایل Frontend و ۲۲۶ ورودی تغییر قبلی آن با hash/status ثابت حفظ شدند؛ فایل untracked کاربر Backend نیز بدون تغییر و خارج commit ماند. runtime/test/dependency/SQL/deployment diff صفر است.

baseline برنامه در همین مرحله تازه restore/build/test شد: exit صفر، build صفر warning/error و **۶۵ unit + ۴۳ integration = ۱۰۸ موفق**. این نتیجه، اجرای schema/DTO/crypto/refresh طراحی‌شده نیست؛ SQL زنده و smoke Kestrel در 2E اجرا نشدند. manifest ۱۳۱ ستون و ۱۹ قاعدهٔ constraint فقط پیشنهاد آینده است و ۲۴ سناریوی طراحی اجرا نشده‌اند. **19% + 1 = 20%** فقط بابت طراحی مجاز 2E؛ Info/Inspections و API عملیاتی ساخته نشدند. O24/O26 و O27–O30 بازند؛ مرحلهٔ بعد با مجوز جدا و بدون امتیاز فعلی است.

## انتشار تأییدشدهٔ تحویل آفلاین Checkpoint 2F

در `2026-11-03`، مجوز `ea650fd0-47e2-4d02-bf9b-0fb87f03a254` فقط 2F و در صورت نبود provider/هویت مجاز، بخش مستقل آفلاین را پوشش داد. commit `f3bf660cc640eebd20ed348cdda181b041d0d799` از مبنای `228d3769fc3471a2e3d597b9272c9629fa9ebe28` شامل ۳۴ فایل مرتبط ثبت و با push عادی به `refs/heads/main` همان مقصد مجاز منتشر شد. URL دریافت و URL ارسال هر دو کنترل شدند؛ refs تازه پیش از commit اختلاف `0/0` داشتند و تاریخچهٔ remote حفظ شد.

پس از push، fetch تازه، HEAD، origin/main و `ls-remote --heads origin` همگی SHA پیاده‌سازی بالا را نشان دادند؛ اختلاف `0/0` و remote فقط main بود. هیچ force، tag، `--all` یا `--mirror` استفاده نشد. branch اصل محلی همچنان `7e2d83ddeb33475d07f70f4471cd09e466f853a4` بود و نه merge و نه push شد.

فایل‌های زیر با ابزار متصل GitHub در ref کامل commit خوانده شدند و blob SHA محلی/remote برابر بود:

| فایل | blob SHA در commit پیاده‌سازی |
|---|---|
| [سه repository](../src/Bazdid.Api/Infrastructure/Sql/SqlRepositories.cs) | `7c68cec54ec44227ca7ae0235be57a4174de360c` |
| [راهنمای 2F](implementation/CHECKPOINT-02F-SQL-REPOSITORIES_FA.md) | `253e04076c7f3f78701373ae5d4e7c29b990ea48` |
| [نتیجهٔ SQL مجزا](checkpoint2f/SQL_TEST_RESULTS.json) | `bbd3fde6546286c9cc17bf16b408a169bdad8aee` |

این SHAهای blob مربوط به نسخهٔ پیاده‌سازی هستند؛ راهنما، فهرست، PLAN و همین گزارش در commit تکمیل مستندات به‌روز می‌شوند. آخرین SHA و تطبیق HEAD آن از Git واقعی در گزارش نهایی ثبت می‌شود تا ارجاع دوری به SHA خود سند ایجاد نشود.

کنترل پیش از ثبت: ۳۳ فایل پیش از تولید خود شاهد کنترل، سپس شاهد افزوده شد و بسته ۳۴ فایل شد؛ ۱۳ Markdown، ۲۱۰ پیوند محلی/یک anchor و ۱۶۰ فایل فعلی بررسی شدند. ۲۳۱ blob تاریخی مبنا و پس از commit **۲۶۵ blob reachable main** بدون هشدار راز باقی‌مانده اسکن شدند. fixture مشخص URL نامعتبر در تست قدیمی، ساختگی و جداگانه تأیید شد؛ ZIP ممنوع از ancestry main غایب بود. هیچ archive، credential، دادهٔ واقعی، فایل پایگاه/backup یا bin/obj ارسال نشد. فایل شخصی untracked کاربر با hash اولیه حفظ و خارج commit ماند؛ تنها همین فایل پس از commit در status باقی بود. Frontend استفاده/تغییر نشد؛ dependency/lockfile/target، SQL script و reader/fixture/HTTP/auth/CORS قبلی تغییر نکردند.

نتیجهٔ واقعی همین تحویل: restore و build exit صفر، build صفر warning/error، **۱۰۹ unit + ۵۰ integration آفلاین = ۱۵۹ موفق، صفر شکست و ۸ SQL Skipped**. تمام ۱۰۸ baseline و ۵۱ case تازه موفق‌اند. Kestrel با SQL خاموش، health/Swagger 200 و PathBase صحیح داشت؛ فرآیند متوقف شد. verification خواندنی قبل/بعد، schema برابر و صفر ردیف را نشان داد. **هیچ SQL runtime connection، DML repository، effective permission با runtime principal، DDL/grant یا آزمون متصل اجرا نشد.** O24/O26 بازند؛ [walkthrough و شواهد](implementation/CHECKPOINT-02F-SQL-REPOSITORIES_FA.md).

**20 + 0 = 20%؛ باقی 80%.** این انتشار، پذیرش کامل 2F یا امتیاز ۲۲٪ نیست؛ ادامهٔ همین 2F بعد از تصمیم provider، تصویب دو principal/permissions و آزمون واقعی لازم است. 2G و OTP/Session/Info/media/Production شروع نشدند؛ تکمیل گزارش Git سهم تازه ندارد.

## انتشار تأییدشدهٔ بستهٔ تصمیم و تصویب ادامهٔ 2F

مجوز `e252dad0-0bb1-4058-ab9b-f757dd2b272a` در `2026-11-03` فقط تحلیل/آماده‌سازی را تا تصویب provider و حساب/permissions مجاز کرد. commit `19ac050f885a6cd77dbbf11d740ab45bf1d9d11a` از مبنای `3b5e78dd8c35d7da6b0550d92220b782ac1acc12` شامل ۱۶ فایل بررسی‌شده بود: اسناد/شواهد و دو پیشنهاد SQL بسته؛ کد runtime، تست‌ها، package/lockfile، target و تعریف جدول‌ها تغییر نکردند.

URL fetch و push همان مقصد مصوب و refs تازه پیش از commit برابر بودند. push عادی فقط `refs/heads/main` ارسال کرد؛ پس از آن fetch، HEAD، origin/main و ls-remote همگی SHA بالا و اختلاف `0/0` را نشان دادند؛ remote فقط main بود. نه force/tag/branch اصل ارسال شد و نه تاریخچهٔ remote حذف شد. branch اصل محلی روی `7e2d83ddeb33475d07f70f4471cd09e466f853a4` محفوظ ماند.

سه فایل در ref کامل این commit با ابزار GitHub خوانده و blob SHA آن‌ها با Git محلی برابر شد:

| فایل | blob SHA در commit بسته |
|---|---|
| [بستهٔ تصمیم/تصویب](checkpoint2f/CONTINUATION_APPROVAL_FA.md) | `362a9d4b381022dc1febd48db5546bb6a7f5a198` |
| [permissions پیشنهادی اصلاح‌شده](../database/proposals/permissions.review.sql) | `0a2d68e2572b5ab58cf5c0099f4015fc6614f95d` |
| [شاهد تازهٔ ادامه](checkpoint2f/CONTINUATION_REVIEW.json) | `4829b3ce3ad5e32b237583090e20bc42ffc975ec` |

این hashها به نسخهٔ اول بسته اشاره دارند؛ همین گزارش، PLAN، walkthrough و بند Git بسته در commit تکمیل مستندات به‌روز می‌شوند. SHA نهایی آن و تطبیق remote از Git واقعی در گزارش نهایی خوانده می‌شود تا ارجاع دوری به SHA خود سند ایجاد نشود.

کنترل اولیه: ۱۵ فایل پیش از تولید خود شاهد کنترل و سپس بستهٔ ۱۶فایلی؛ ۱۱ Markdown، ۲۱۴ پیوند محلی/یک anchor و ۱۶۵ فایل فعلی بررسی شدند. ۲۶۹ blob تاریخی مبنا و سپس **۲۸۵ blob reachable main** بدون هشدار راز باقی‌مانده اسکن شدند. fixture قدیمی URL نامعتبر جداگانه تأیید شد؛ ZIP ممنوع از ancestry main غایب بود. هیچ credential، archive خصوصی، customer data، فایل DB/backup یا خروجی bin/obj ارسال نشد. تنها untracked باقی‌مانده فایل شخصی launchSettings کاربر با همان hash اولیه بود؛ Frontend خوانده/تغییر نشد.

خروجی بسته: نه nuspec رسمی، منشأ قید App2.1.30 و تعارضهای CodePages/Caching/Pkcs/Channels، ماتریس provider، دو نام Windows پیشنهادی، حداقل حقوق/مجوز و روش اجرا/ابطال، hash دو SQL proposal با guard صفر و approval/SIDهای NULL. دو فایل و دو template فقط آفلاین parse شدند؛ هیچ CREATE/GRANT/DENY یا account/ACL/TLS/registry تغییر نکرد. نام‌های پیشنهادی موجود/مصوب نیستند و توصیهٔ طرح مهاجرت جداگانه مجوز ارتقای target نیست.

regression تازه همان baseline بود: restore/build exit صفر، warning/error صفر، **۱۰۹ unit + ۵۰ integration آفلاین موفق، صفر شکست، ۸ SQL Skipped و صفر اجرای connected/effective permission**. تست جدید ساخته نشد؛ native/اتصال/TLS نامزدها آزمایش نشدند و audit همان ۹ بستهٔ دارای هشدار را نشان داد. schema قبل/بعد برابر و سه جدول خالی‌اند؛ SQL Server metadata خواندنی با runtime برنامه متفاوت است. smoke Kestrel/IIS در این ادامه تکرار نشد.

**20 + 0 = 20%؛ باقی80%.** O24/O26 و approvalهای P0–P5 در [بستهٔ تصویب](checkpoint2f/CONTINUATION_APPROVAL_FA.md) بازند. توقف قبل از provider/account/SQL/TLS/activation نامصوب و بدون شروع2G؛ همگام‌سازی این بسته پذیرش2F یا امتیاز22% نیست.

## انتشار تأییدشدهٔ P0 امکان‌سنجی مهاجرت

مجوز `700bf7eb-76b8-4b84-ad87-1096b3eb12dd` فقط مطالعه و prototype مستقل ignored را پوشش داد. commit `55573fda0c2741f103760c3e959c7ff108e10431` با والد `ce2d6c6f2be103b34135561cb81c5a4210b8e56d` در `2026-11-03` ثبت و با push عادی فقط `refs/heads/main` به مقصد مصوب فرستاده شد. پیش از ارسال، URLهای fetch/push، refs تازه و ancestry بررسی شدند؛ force، tag، branch اصل و ZIP خصوصی ارسال نشدند.

پس از push، fetch تازه، `rev-parse HEAD origin/main` و `ls-remote --heads origin` همگی `55573fda0c2741f103760c3e959c7ff108e10431` را نشان دادند؛ اختلاف `0/0` و تنها branch دوردست main بود. سه فایل با ابزار GitHub در ref کامل همان commit خوانده و SHA blob با Git محلی برابر شدند:

| فایل | SHA blob تأییدشده |
|---|---|
| [walkthrough P0](implementation/CHECKPOINT-02F-P0-MIGRATION-FEASIBILITY_FA.md) | `0526c03d7008898dbfd937140562e13a14f23e9c` |
| [نتایج امن](checkpoint2f/P0_FEASIBILITY_RESULTS.json) | `6b4ec09cc85ab1a38a8a3e841262fff8407795d8` |
| [ماتریس مهاجرت](checkpoint2f/P0_MIGRATION_FILE_PLAN_FA.md) | `16826e0b7da187f6c4a0d3f353eadb766015159f` |

چهار فایل تازهٔ این بسته: walkthrough، ماتریس، JSON نتایج و [شاهد کنترل](checkpoint2f/P0_DELIVERY_VALIDATION.json). یازده فایل قبلی تغییر کردند: AGENTS، PLAN، README، ادامهٔ AI، IIS_DEPLOYMENT، OPEN_DECISIONS، SOURCE_REFERENCES، TESTING_STRATEGY، بستهٔ CONTINUATION_APPROVAL، walkthrough قبلی2F و فهرست implementation. این گزارش، ارجاع commit در walkthrough/PLAN و فهرست در ثبت تکمیلی به‌روز می‌شوند؛ hashهای جدول بالا برای نسخهٔ نخست بسته‌اند. SHA ثبت تکمیلی و تطبیق نهایی از Git واقعی در گزارش نهایی خوانده می‌شود تا سند به SHA خودش ارجاع دوری ندهد.

کنترل نخست شامل۱۴فایل پیش از ساخت خود شاهد و سپس بستهٔ۱۵فایلی،۱۳Markdown،۲۳۰پیوند محلی/یک anchor و پوشش هر۳۳فایل C# در ماتریس بود. hash هر۶۴فایل محافظت‌شده یکسان ماند. اسکن **۳۰۴blob reachable main** پس از commit، هشدار راز باقی‌مانده نداشت؛ دو fixture URL نامعتبر تاریخی جدا شناخته شدند و blob ZIP ممنوع از main غایب بود. branch اصل محلی همچنان روی `7e2d83ddeb33475d07f70f4471cd09e466f853a4` بود. تنها untracked بعد از commit، launchSettings شخصی با hash قبلی بود؛ prototype، cache، raw logs/TRX، bin/obj و سورس آن ignored و خارج commit ماندند.

regression اصلی تازه: build بدون warning/error،۱۰۹unit+۵۰integration آفلاین موفق، صفر شکست و۸SQL Skipped. نمونهٔ .NET10/MDS6.1.7 مستقل: build بدون warning/error،۱۴موفق/صفرشکست/صفرskip، سهHTTP smoke موفق، managed-load و PE x64، audit نهایی صفر بستهٔ flagged بعد از pin سازگار Pkcs10.0.14. این نتایج با هم یک suite نیستند. کد اصلی/package/lockfile/SDK/SQL/deployment و فایل کاربر تغییر نکردند؛ هیچ SQL metadata/connect، native execution/SSPI/TLS، account/task/right/ACL/certificate یا IIS در P0 اجرا نشد.

**قبلی20 + سهم P0 صفر = فعلی20%؛ باقی80%.** پذیرش کامل2F تحت مجوز مستقل هدف مشروط22% دارد؛2G شروع نشد. P0 مجوز مهاجرت canonical نیست؛ port واقعی، P1/P2، TLS/activation و استقرار تصویب‌های مستقل می‌خواهند.

## انتشار تأییدشدهٔ بررسی 2F-L1

commit `069f55ca190dfa2fd908c826f8aea67d9cca5984` (والد `dbdd6ee6ebead440af6d4dc58371f7ef407375d2`) با `git push origin main:main` و بدون force منتشر شد. شواهد:

- خروجی push برابر `dbdd6ee..069f55c  main -> main` بود.
- پس از fetch، HEAD محلی و `refs/heads/main` روی remote هر دو `069f55c` بودند.
- blob سه فایل در GitHub API با `HEAD` محلی برابر بود:
  - walkthrough: `07a7db79…`؛
  - `LEGACY_SECURITY_PINS.json`: `ef81d03c…`؛
  - `LEGACY_PROVIDER_RESULTS.json`: `8c18e182…`.
- اشیای تازه فقط ۱۲ فایل مستند همان commit بودند. پیش از commit، اسکن راز/مسیر شخصی و بررسی ۲۲۲ پیوند نسبی (صفر شکسته) انجام شد.

آزمایش‌ها، logها، `bin/obj`، cache بسته‌ها و `src/Bazdid.Api/Properties/` منتشر نشدند. فقط `main` push شد و ref تاریخچهٔ اصلی محلی ارسال نشد. این ثبت تکمیلی سهم پیشرفت ندارد؛ پیشرفت 20% است.

## انتشار تأییدشدهٔ L1-A

commit `c3739aec312b67b41741d083f9f739d6acee96e5` (والد `0eda1f3e08d1184caafbf706751cfbd9ea61b67a`) با `git push origin main:main` و بدون force منتشر شد. شواهد:

- خروجی push برابر `0eda1f3..c3739ae  main -> main` بود.
- پس از fetch، HEAD محلی و `refs/heads/main` روی remote هر دو `c3739ae` بودند.
- blob چهار فایل در GitHub API با `HEAD` محلی برابر بود:
  - `Bazdid.Api.csproj`: `b8a63b55…`؛
  - `src/Bazdid.Api/packages.lock.json`: `04225ee7…`؛
  - walkthrough L1-A: `2b9d7431…`؛
  - `L1A_VALIDATION.json`: `f0b1ebf1…`.
- ۱۳ فایل تغییر کرد: csproj، سه lockfile و مستندات.

پیش از commit، اسکن راز و مسیر شخصی و بررسی ۲۰۲ پیوند نسبی (صفر شکسته) انجام شد. خروجی publish، logها، `bin/obj`، آزمایش‌ها و `src/Bazdid.Api/Properties/` منتشر نشدند. فقط `main` push شد. این ثبت تکمیلی سهم پیشرفت ندارد؛ پیشرفت 20% است.

## انتشار تأییدشدهٔ گزارش P1–P5

commit `b3b7c686a503024fb267ca7cafa9d4213e7ccaf2` (والد `c17e5183b53b91cb7aa20d50f86604da7760360c`) با `git push origin main:main` و بدون force منتشر شد. شواهد:

- خروجی push برابر `c17e518..b3b7c68  main -> main` بود.
- پس از fetch، HEAD محلی و `refs/heads/main` روی remote هر دو `b3b7c68` بودند.
- blob چهار فایل در GitHub API با `HEAD` محلی برابر بود: گزارش پذیرش متصل `1430ee56…`، `CONNECTED_PREFLIGHT.json` `af05baab…` و دو script مدیر `a61cb803…` و `6827b752…`.
- SHA-256 دو script پس از commit با مقدار ثبت‌شده برابر ماند، چون `.gitattributes` برای آن‌ها `eol=crlf` را pin کرده است.

پیش از commit، اسکن راز و نام ماشین و کاربر و بررسی ۲۲۲ پیوند (صفر شکسته) انجام شد. probe، logها و `src/Bazdid.Api/Properties/` منتشر نشدند. پیشرفت 20% است.

## انتشار تأییدشدهٔ بازنگری scriptهای P1 و P3 (2026-11-07)

commit `5a192a8d9fbb74babbef4432daa0b6ded364aead` (والد `9c2775e025e18908defa9e89861071ecaf9c8503`) با `git push origin main:main` و بدون force منتشر شد. شواهد:

- خروجی push برابر `9c2775e..5a192a8  main -> main` بود.
- پس از fetch، HEAD محلی و `origin/main` هر دو `5a192a8` بودند.
- blob سه فایل در GitHub API عمومی (در همان commit) با HEAD محلی برابر بود: script P3 `fdbf7ead…`، script P1 `27513bdc…` و گزارش پذیرش متصل `428a96d8…`.
- SHA-256 دو script در checkout تازه (`git checkout-index`) با مقدار مستند برابر بود: P3 `07383213…49ec` و P1 `351227f2…838a`.

پیش از commit، اسکن راز، نام ماشین و SID انجام شد و نتیجه‌ای نداشت. هیچ script اجرا نشد. پیشرفت 20% است.

## انتشار تأییدشدهٔ راستی‌آزمایی P3 (2026-11-07)

commit `2af6bf2982c13a7b79cfbbd88095a32b196d2e28` (والد `51c921697e40a3c090706d2e3d2eeeff24da6c1c`) با `git push origin main` و بدون force منتشر شد. شواهد:

- خروجی push برابر `51c9216..2af6bf2  main -> main` بود.
- پس از fetch، HEAD محلی، `origin/main` و `ls-remote` هر سه `2af6bf2` بودند.
- `P3_TLS_VERIFICATION.json` و گزارش پذیرش متصل از raw.githubusercontent در همان commit با HTTP 200 خوانده شدند. anchor `p3-verification-20261107` در نسخهٔ GitHub وجود داشت. `gh` احراز نشده بود، پس تطبیق blob با API انجام نشد.

پیش از commit، نام ماشین و login در فایل‌های منتشرشده جست‌وجو شد و نتیجه‌ای نداشت. probe ignored و `src/Bazdid.Api/Properties/` منتشر نشدند. پیشرفت 20% است.

## انتشار تأییدشدهٔ D-P3-NAME، P2 و P4/P5 (2026-11-07)

commit کد `fd1e992d98a30d7021b7e2d09968da197408c0bc` (والد `773584d`) با `git push origin main` و بدون force منتشر شد. خروجی push برابر `773584d..fd1e992  main -> main` بود و `ls-remote` و HEAD محلی هر دو `fd1e992` بودند. پیش از commit، جست‌وجوی نام ماشین، SID و `password=` در فایل‌های staged نتیجه‌ای نداشت. رمز Writer در هیچ فایلی وجود ندارد. commit مستندات بعدی در همین بخش با SHA واقعی تکمیل می‌شود.

commit مستندات `5ca987634e077043e87c5330769e76ec46674b0c` با push عادی منتشر شد (`fd1e992..5ca9876`) و `ls-remote` با HEAD محلی برابر بود.

## اصلاح اشکال ثبت task در P4 (2026-11-07)

اصلاح تداخل نام `$action` در `Register-BazdidConnectedTestTask.review.ps1` و بررسی trigger در `-VerifyOnly`. SHA و نتیجهٔ push این commit در گزارش نهایی همان وظیفه و پس از راستی‌آزمایی `ls-remote` ثبت می‌شود. hash script: `3EB982D0792078E18BF56AFE2B3A174EEA0CC40A5ACCF4271B063CDFD025ADF1`.

commit اصلاح P4 (`1601325`) با push عادی منتشر شد و `ls-remote` با HEAD محلی برابر بود.

## پذیرش نهایی 2F (2026-11-07)

commit پذیرش 2F شامل اصلاح آزمون لغو، راستی‌آزمایی معنایی task و مستندات است. پیش از commit، جست‌وجوی نام ماشین، SID و رمز در فایل‌های staged انجام شد. SHA و نتیجهٔ push در گزارش نهایی همان وظیفه ثبت می‌شوند. TRX و لاگ‌های اجرا منتشر نمی‌شوند.

## همگام‌سازی پیش از 2G و commit پذیرش 2G (2026-11-07)

- push اول commit `3fbad78` با `Recv failure: Connection was reset` شکست خورد. push دوم عادی موفق بود (`cb38d74..3fbad78`). fetch بعدی نشان داد HEAD محلی و `origin/main` هر دو `3fbad78` هستند.
- commit پذیرش 2G شامل migrationها، runner، شاهد و مستندات است. SHA و نتیجهٔ push آن در گزارش نهایی همان وظیفه ثبت می‌شوند. پیش از commit، جست‌وجوی نام ماشین و SID در فایل‌های تازه نتیجه‌ای نداشت.
