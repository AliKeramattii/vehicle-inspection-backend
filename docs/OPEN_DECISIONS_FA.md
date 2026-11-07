# دفتر تصمیم‌های واقعاً باز

این دفتر پرسش تکراری دربارهٔ الزامات قطعی نیست. target 2.1، IIS، پایگاه موجود، پیشوندها و قواعد کسب‌وکار قطعی‌اند. وضعیت `2026-11-03`: تحویل آفلاین 2F طبق مجوز `ea650fd0-47e2-4d02-bf9b-0fb87f03a254` انجام شد؛ پذیرش متصل O24/O26 باز و پیشرفت **20%** است. [راهنمای تازه](implementation/CHECKPOINT-02F-SQL-REPOSITORIES_FA.md). هیچ role/login/user/grant، DDL، DML repository، SQL کارگزاری یا 2G اجرا نشد. پاسخ تصمیم‌ها با مسئول، تاریخ، محیط و مرجع تأیید ثبت شود.

| شناسه | تصمیم/دادهٔ لازم و پیشنهاد فعلی | مسئول | زمان نیاز و اثر |
|---|---|---|---|
| O01 | نگاشت source-only برای `Duber.OrderSales`، رابطهٔ CustomerId و candidateهای موبایل یافت شد؛ تأیید schema/ستون/join جاری، eligibility و نسخهٔ منبع لازم است؛ جزئیات در ماتریس mapping و O20 تا O22 | کارگزاری و DBA | adapter واقعی؛ fixture مانع برنامه‌ریزی نیست |
| O02 | بخش provisioning محلی پاسخ داده شد: `(local)\SQLSERVER2019`، Windows، موتور `15.0.2000.5 / RTM`؛ DB ساخته‌شده با `150 / SQL_Latin1_General_CP1_CI_AS` و SIMPLE، داده/log اولیه ۱۶ MiB، رشد ۱۶ و سقف ۵۱۲/۲۵۶ MiB. schema محلی dbo و سه جدول تأیید شدند. حساب runtime/patch/TLS و مشخصات Production همچنان بازند | مالک/DBA/زیرساخت | مرجع جدید: مجوز `553dc9cd-5abe-4eb0-9856-ee1763d5250b` و شواهد 2C؛ قبل از SQL runtime/استقرار |
| O03 | نسخه Windows Server/IIS/ANCM و Runtime، effective child application path و اثر Hosting Bundle بر برنامه‌های موجود | زیرساخت IIS | smoke واقعی؛ Checkpoint 1 محلی مستقل پیش می‌رود |
| O04 | دامنه‌های واقعی HTTPS، origin/port مجاز و same-site/cross-site بودن، گواهی و proxy trusted | زیرساخت و امنیت | اتصال مرورگر و Checkpoint 9 |
| O05 | secret store، اختیار pool، key ring، گواهی/DPAPI، rotation/backup و چند instance | امنیت/زیرساخت | طراحی توسعه در Checkpoint 3؛ Production پیش از نشر |
| O06 | قرارداد SMS موجود: endpoint/auth، ارسال کد تولیدشدهٔ BAZDID، timeout، dedupe/receipt، sandbox و ظرفیت؛ Kavenegar در سورس قدیمی مشاهده شد و قرارداد مصوب BAZDID محسوب نمی‌شود | تیم سرویس کارگزاری | adapter واقعی؛ verify همچنان مسئول BAZDID؛ بدون انتقال کلید آرشیو |
| O07 | TTL چالش/نشست، attempts، cooldown و سقف پنجره/IP؛ پیشنهاد تست: OTP ۱۲۰ثانیه/۵تلاش/۶۰ثانیه، نشست idle۳۰دقیقه/absolute۸ساعت | مالک/امنیت | قبل از Checkpoint 3 در همان محیط؛ Production جدا |
| O08 | طول/قدرت OTP Production و UX؛ پنج‌رقمی بودن فقط fixture/Front current است | امنیت/محصول/Frontend | قبل از adapter Production؛ تغییر طول نیاز به قرارداد UI |
| O09 | سال از `CarYearSakht.Name` رشته است، نه FK عددی؛ تقویم/تجزیه، تفاوت `VinNumber/ShasiNumber`، نیاز full VIN، رنگ، پلاک رشته‌ای، سقف کیلومتر، InvalidSource و ZeroMeansMissing هر فیلد باید مصوب شوند | مالک محصول و کارگزاری | mapping پیش از reader واقعی؛ قرارداد Checkpoint 4/5؛ صفر کیلومتر معتبر است |
| O10 | DTO اطلاعات ناقص/منشأدار، جایگزینی mobile در auth mock، colorId/discrepancy، status mapping و نسخهٔ contract | Frontend/Backend | پیش از اتصال checkpointهای 3/4؛ هیچ تغییر Frontend اینجا انجام نمی‌شود |
| O11 | محدودیت عکس/ویدیو/مدت/codec/ابعاد/quota و ابزار validation/scan مصوب | محصول/امنیت/زیرساخت | policy تست پیش از Checkpoint 6؛ policy Production پیش از نشر |
| O12 | drive/root واقعی storage، same volume، ACL، ظرفیت، shared storage و روش اجرای reconcile خارج وابستگی IIS timer | زیرساخت | قبل از upload محیط مربوط |
| O13 | retention، legal hold، حذف، log/IP، backup هماهنگ، RPO/RTO و آزمون restore | حقوقی/محصول/زیرساخت | پیش از پاک‌سازی یا Production؛ اکنون TTL قانونی اختراع نمی‌شود |
| O14 | نسخهٔ شرایط رضایت و scope پذیرش، متن خطا/receipt/tracking و سیاست freshness منبع | محصول/کارگزاری | قبل از Checkpoint 5/7؛ نسخهٔ جاری Front `2026-10` صرفاً شاهد کد |
| O15 | bootstrap اولیه Admin، credential محلی/SSO کارکنان، MFA، password policy و بازیابی آخرین مدیر | امنیت/مالک | Checkpoint 8؛ وجود مدیر و جدول `BAZDIDAdmin` قطعی است |
| O16 | assignment/capacity/correction و contract مقصد بیمه/ack/query/idempotency؛ اعلان و SLA در صورت نیاز | عملیات/تیم بیمه | Checkpoint 8؛ blocker مشتری نیست |
| O17 | انتخاب foundation انجام شد: App 2.1.30، Newtonsoft 13.0.4، Swagger 4.0.1 و ابزار تست نسخه‌دار؛ restore/build/run و ۴۳ آزمون موفق؛ audit با هشدار باقی است | Backend/امنیت | سازگاری محلی بسته شد؛ remediation/پذیرش امنیت Production همچنان باز و مرتبط با O18 |
| O18 | risk acceptance رسمی EOL و برنامه/مسئول/موعد مهاجرت به پشتهٔ دارای پشتیبانی | مالک/امنیت/زیرساخت | الزام پیش از انتشار عمومی |
| O19 | وضعیت static export کامل Frontend و reverse map مرکزی در topology واقعی | تیم Frontend/زیرساخت مرکزی | پذیرش integration؛ خارج تغییرات این مخزن |
| O20 | کدام context/پایگاه authoritative است؟ `DuberContext` و `irisdbContext` هر دو `Duber.OrderSales` دارند؛ schema/table مشتری و lookupها، نوع/nullability فیزیکی و حوزهٔ یکتایی شناسه‌ها تأیید نشده‌اند | DBA/کارگزاری | پیش از SQL reader؛ metadata حداقلی و دسترسی SELECT مصوب، بدون fallback حدسی |
| O21 | کد معرفی درخواست کجا صادر و نگهداری می‌شود و چگونه منتقل/حل می‌شود؟ شش‌کاراکتری بودن، case، uniqueness، انقضا و رابطهٔ دقیق آن با Id باید تعیین شوند؛ تخفیف/پرداخت/پست/نمایش verifyOrder پاسخ این پرسش نیست | مالک محصول/کارگزاری | پیش از resolver واقعی؛ `A4K9P2` فقط fixture مستقل باقی می‌ماند |
| O22 | کدام‌یک از `Customer.Mobile/OrderSales.Mobile` مرجع معتبر OTP است؟ اولویت، verified بودن، درخواست فاقد مشتری، شمارهٔ متعارض، تغییر مالک و سیاست freshness باید مصوب شوند | کارگزاری/امنیت/محصول | قبل از OTP واقعی؛ موبایل ورودی مشتری جایگزین نمی‌شود و وضعیت مبهم fail-closed است |
| O23 | بررسی امنِ اعتبار و لزوم گردش credentialهای موجود در آرشیو، به‌ویژه اتصال‌ها و تنظیمات پیامک؛ وضعیت فعال‌بودن معلوم نیست و هیچ مقدار منتقل یا آزمایش آنلاین نشده است | مالک سامانه/امنیت | رسیدگی جداگانه از طریق کانال امن؛ انتشار سورس یا راز برای تکمیل ممیزی لازم نیست |
| O24 | بررسی تازهٔ گراف/SNI/API/advisory انجام شد؛ System.Data.SqlClient 4.5.3 انتقالی و قید [4.5.3,4.6.0) ثابت است. 4.8.6 override نشد؛ Microsoft.Data.SqlClient 2.1.7 نیز پایان پشتیبانی دارد و انتخاب/نصب نشد. managed assembly در host x64 بارگذاری شد و SNI x64 موجود است؛ اتصال واقعی provider/native/TLS تأیید نشده و audit Moderate/High باقی است. گراف فعلی فقط آفلاین، gate اتصال در کد بسته؛ [شاهد](checkpoint2f/PROVIDER_AUDIT.json) | Backend/امنیت/مالک | پیش از پذیرش متصل 2F، تصمیم provider/ریسک و آزمون واقعی با principal مجاز؛ PowerShell جای runtime نیست |
| O25 | بخش schema/provisioning محلی بسته شد: مجوز صریح همان سه جدول dbo؛ DB واقعی و ۳۹ ستون/۱۰ index/۱۳ CHECK/یک FK و رفتار ۳۵ CASE تأیید شدند. خطای CHECK tenant با WITH CHECK رفع شد. فایل‌های review همچنان guarded هستند. نقش/حساب برنامه جداگانه در O26 باقی است | مالک/DBA/امنیت | تأیید فقط محیط محلی/همان اشیا در مجوز `553dc9cd-5abe-4eb0-9856-ee1763d5250b`؛ تغییر دامنه، بازسازی و Production مجوز ندارند |
| O26 | metadata تازه: صفر Windows user پایگاه، صفر دو نقش پیشنهادی و عضو، صفر login غیرسرویسی کم‌اختیار طبق فیلتر؛ نام دو principal مصوب تحویل نشده. نام دقیق Windows SourceReader/Writer، روش اجرای مستقل و permissions حداقلی تصویب شوند؛ Writer این نسخه UPDATE CustomerLinks نمی‌خواهد و script تاریخی باید پیش از اجرای احتمالی بازبینی شود. sysadmin فقط metadata خواند؛ هیچ دسترسی ساخته/اعمال نشد؛ [شاهد](checkpoint2f/RUNTIME_PRINCIPALS.json) | مالک/DBA/زیرساخت | پیش از اتصال برنامه و effective permission test؛ role definition یا نام تنظیماتی هویت واقعی نیست؛ مجوز role/user/grant مستقل لازم است |
| O27 | تصویب پروفایل پلاک/دستهٔ خودرو: UI فقط چهار بخش 2/letter/3/2 و ۱۵ حرف مشخص دارد؛ category یا اعتبار قانونی region را تعیین نمی‌کند. normalization ارقام و ي به ی، برخورد با special/unsupported و شرط atomic plate باید با محصول/کارگزاری تصویب شوند؛ enum UI به‌تنهایی قانون ملی نیست | محصول/کارگزاری/امنیت | قبل از validation و DDL/API اطلاعات در Checkpoint 4؛ قالب پشتیبانی‌نشده Missing نمی‌شود |
| O28 | لزوم نگهداری full VIN/chassis، assurance ماسک/کامل، masking، provider حفاظت‌شدهٔ سازگار 2.1، purpose binding به owner/inspection، طول envelope، key retention/rotation/backup/recovery و حریم خصوصی hash مقایسه؛ plaintext fallback ممنوع است | امنیت/زیرساخت/محصول | مکمل O05/O13؛ قبل از persistence حساس و migration Checkpoint 4؛ رمزنگاری placeholder ساخته نشده |
| O29 | تصویب ValidationProfileVersion و required fields، سال/تقویم/بازه، کاتالوگ رنگ/hex، VIN/chassis، سقف کیلومتر و حالت Manual Pending/Invalid بازاعتبارسنجی؛ روش رفع/پس‌گرفتن گزارش مغایرت و DTO nullable/overposting با Frontend توافق شود. FK owner/context و ۱۳۱ ستون/۱۹ قاعدهٔ پیشنهادی نیازمند بازبینی DBA هستند | محصول/Backend/Frontend/DBA | تکمیل اجرایی O09/O10 قبل از Checkpoint 4؛ manifest طراحی، تصویب schema Production یا مجوز DDL نیست |
| O30 | source بدون version چگونه پشتیبانی شود؟ 2D فعلی نسخهٔ غیرخالی لازم دارد؛ پیشنهاد mode/nullable version، hash خصوصی، refresh پیش از mutation/submit، TTL/outage و رفتار تغییر مالک/موبایل و عدم اتصال شخص جدید به تلاش قبلی نیازمند تأیید است؛ timestamp نسخهٔ منبع نیست | کارگزاری/امنیت/Backend | قبل از adapter واقعی و Checkpoint 4؛ تغییر آگاهانهٔ قرارداد داخلی با آزمون، نه تغییر پنهان در 2E؛ تضمین اتمیک بین SQL محلی و source فرض نمی‌شود |

## پیشنهادهای معماری منتظر بازبینی بستهٔ Phase 0

یک پروژهٔ API با دو پروژهٔ تست، ADO.NET پارامتری، ۱۷ جدول تدریجی، manifest قالب ثابت و snapshot به‌جای مدیریت قالب کامل، منشأهای ستونی Info، cookie با SQL ticket store، ادغام فرمان‌های ویرایش خودرو در information و whole-file retry پیشنهاد شده‌اند. این‌ها الزامات ازپیش‌تأییدشده معرفی نمی‌شوند. اگر بازبینی آن‌ها را تغییر داد، PLAN و docs مرتبط در یک تغییر همسو اصلاح شوند.

2E در دامنهٔ طراحی تکمیل شد و 2F اکنون فقط آفلاین تحویل شده است؛ **20%** باقی ماند. O24/O26 و mapping واقعی بازند؛ O27–O30 همچنان برای اجرای امن Info لازم‌اند. audit گراف پاک نشده، ۱۵۹ موفق آفلاین و ۸ SQL Skipped تازه ثبت شده‌اند؛ جدول/DTO پیشنهادی Info هنوز اجرا نشده است. گام بعد رفع موانع و ادامهٔ همین 2F با هدف مشروط ۲۲٪ است؛ 2G، OTP/Session/Info/media و Production شروع نشده‌اند.

## ادامهٔ بررسی O24/O26 — تصویب‌ها هنوز باز

در `e252dad0-0bb1-4058-ab9b-f757dd2b272a`، نه nuspec رسمی و قیود گراف موجود بررسی شدند: خود App2.1.30 بالاسقف SQL Client و CodePages را تحمیل می‌کند؛ candidateهای جدید هم Caching/Pkcs/Channels را نقض می‌کنند. package change، native connection و TLS مصوب/آزموده نشده‌اند. پیشنهاد تصمیم O24، **اجازهٔ تهیهٔ طرح مهاجرت جداگانهٔ .NET10 LTS با ارزیابی Microsoft.Data.SqlClient6.1.7 LTS** است؛ امکان آزمایش legacy با گراف بازطراحی‌شده رد فنی کلی نشده، اما هیچ آزمایشی تصویب نشده و runtime2.1 دارای پشتیبانی نیست. [ماتریس و شواهد](checkpoint2f/CONTINUATION_APPROVAL_FA.md).

O26: دو نام `.\BAZDIDDevWriter` و `.\BAZDIDDevReader` با Batch logon/task محدود و بدون admin/RDP فقط پیشنهادند؛ metadata نبود آن‌ها و نقش/userهای SQL را تازه تأیید کرد. login/permissions بسته برای تصویب نام/SID و hash script آماده است؛ UPDATE CustomerLinks حذف و SELECT audit منع شد. source grant یا جدول فرضی وجود ندارد. هیچ CREATE/GRANT/DENY، account، ACL یا registry تغییر نکرد. P0–P5 در همان بسته، approvalهای provider، OS/SQL، TLS، activation/verifier و fixture/cleanup را تفکیک می‌کنند. O24/O26 بسته نشده‌اند؛ **20%** و توقف پیش از عملیات نامصوب.

## نتیجهٔ P0؛ O24/O26 هنوز بسته نشده‌اند

مجوز `700bf7eb-76b8-4b84-ad87-1096b3eb12dd` برای نمونهٔ مستقل اجرا شد. [walkthrough P0](implementation/CHECKPOINT-02F-P0-MIGRATION-FEASIBILITY_FA.md) امکان compile/managed-load و حفظ Startup روی.NET10 را نشان داد؛۱۴تست و سهHTTP موفق‌اند. Pkcs انتقالی9.0.11 دارای دو advisory بود؛ pin10.0.14 در محدودهٔ dependency، audit نمونه را بدون flagged کرد. canonical و advisoryهایش تغییر نکردند؛ پشتیبانی/امنیت Production یا اتصال SQL اثبات نشد.

تصمیم باز O24: تصویب تغییر الزام2.1 و مهاجرت واقعی آفلاین، گراف Swagger/Newtonsoft و parity قرارداد، سپس native/SSPI/TLS و provider متصل. تصمیم باز O26: نام/SID/حقوق دو حساب، hash scriptهای P1/P2، verifier مستقل و effective permission. چک‌لیست دقیق در walkthrough آمده و proposalها بدون تغییرند. metadata حساب/DB این بار خوانده نشد؛ گزاره‌های نبود آن‌ها در بخش قبلی تاریخی‌اند. درصد20، هدف مشروط پذیرش کامل2F برابر22 و2G شروع‌نشده است.

## 2F-L1؛ قید الزامی 2.1 و تصمیم‌های L1-A/L1-R

در `2026-11-03` کارفرما `netcoreapp2.1` را الزامی اعلام کرد. پیشنهاد مهاجرت O24 در P0، گام مصوب نیست و فقط پژوهش آینده است. [walkthrough L1](implementation/CHECKPOINT-02F-LEGACY-SQLCLIENT-FEASIBILITY_FA.md) نشان داد:

- metapackage هیچ SqlClient وصله‌شده‌ای را نمی‌پذیرد.
- تنها نامزد فنی، `System.Data.SqlClient 4.8.6` روی گراف ریز با pinهای امنیتی است: build و ۱۵۹ آزمون کپی canonical موفق، audit ۲ بستهٔ flagged.
- `Kestrel.Core 2.1.25` (CVE-2025-55315، Critical) در خط 2.1 وصله ندارد.

| شناسه | تصمیم باز | صاحب |
|---|---|---|
| L1-A | تغییر بستهٔ canonical از `Microsoft.AspNetCore.App` به گراف ریز + SDS 4.8.6؛ target و کد ثابت | کارفرما + مالک |
| L1-R | پذیرش مکتوب و زمان‌دار ریسک Kestrel/EOL، کنترل‌های جبرانی و تاریخ بازبینی | کارفرما/امنیت |
| D | اجازهٔ runtime/سرویس دادهٔ جدا؛ فقط در صورت رد L1-R | زیرساخت |

O26 (P1/P2) بدون تغییر و منتظر تصویب جدا است. بدون L1-A، gate بسته می‌ماند. بدون L1-R، فعال‌سازی متصل یا Production مجاز نیست. درصد 20 است.

## L1-A تصویب و اعمال شد؛ L1-R باز است

در `2026-11-06` مالک پروژه L1-A را فقط برای تغییر آفلاین بسته تصویب کرد و [اعمال آن](implementation/CHECKPOINT-02F-L1A-CANONICAL-DEPENDENCIES_FA.md) با ۱۵۹ آزمون موفق، ۸ Skipped و Swagger بدون تغییر انجام شد. سند جدای کارفرما در مخزن ثبت نشده است و مبنای مجوز همان دستور مالک است.

تصمیم‌های باز به ترتیب:

- **L1-R** (پذیرش ریسک `Kestrel.Core 2.1.25`/CVE-2025-55315، `SwaggerUI 4.0.1` و runtime EOL)
- P1 و P2 (O26)
- P3 (TLS)
- P4/P5
- D، فقط در صورت رد L1-R

بدون L1-R هیچ فعال‌سازی متصل یا Production مجاز نیست. درصد 20 است.

## P1–P5 در 2026-11-06؛ مانع TLS و token مدیر

- اعلام مالک دربارهٔ تفویض اختیار Development محلی ثبت شد. این اعلام L1-R رسمی برای Production نیست.
- P3 مانع اصلی است: instance برای `Encrypt=true` و `TrustServerCertificate=false` certificate معتبر ندارد.
- تصمیم باز: اجرای script بازبینی P3 توسط مدیر محلی و ری‌استارت `MSSQL$SQLSERVER2019`. اگر PKI سازمانی وجود دارد، certificate صادرشده از CA سازمان ترجیح دارد.
- سپس P1 و P2 و پس از آن‌ها P4/P5. جزئیات در [گزارش پذیرش متصل](implementation/CHECKPOINT-02F-CONNECTED-ACCEPTANCE_FA.md). درصد 20 است.

## D-P3-NAME — نام مقصد اتصال پس از P3 (باز از 2026-11-07)

- P3 اجرا شد و certificate اعتماد می‌شود. مقصد pin‌شده `lpc:.\SQLSERVER2019` با `SEC_E_WRONG_PRINCIPAL` رد می‌شود، چون `.` در CN/SAN نیست.
- پیشنهاد: تغییر pin در `SqlRuntimeOptions` و آزمون‌ها به `lpc:localhost\SQLSERVER2019`. Shared Memory و guard بدون تغییر می‌مانند.
- جایگزین: نام میزبان، که به ماشین وابسته است.
- رد: bypass اعتبارسنجی، افزودن `.` به SAN، و `HostNameInCertificate` (در 4.8.6 وجود ندارد).
- این تصمیم پیش از P2 و P4 لازم است. [بخش ۲۰](implementation/CHECKPOINT-02F-CONNECTED-ACCEPTANCE_FA.md#p3-verification-20261107).
