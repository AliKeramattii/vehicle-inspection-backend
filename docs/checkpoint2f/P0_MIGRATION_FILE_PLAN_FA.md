# نقشهٔ فایل‌به‌فایل مهاجرت پیشنهادی پس از P0

تاریخ `2026-11-03`؛ بررسی روی `ce2d6c6f2be103b34135561cb81c5a4210b8e56d`. **این ماتریس برنامه است، نه diff اجراشده یا مجوز مهاجرت.** کد اصلی/lockfileها تغییر نکردند. [walkthrough و نتایج P0](../implementation/CHECKPOINT-02F-P0-MIGRATION-FEASIBILITY_FA.md) دامنه و شواهد را توضیح می‌دهد. سختی کم/متوسط/زیاد، برآورد نسبی مهندسی است؛ «حفظ» یعنی رفتار بیرونی/تجاری باید ثابت بماند، نه اینکه همین فایل روی .NET10 آزموده شده باشد.

## ریشه، project و بسته‌ها

| فایل واقعی | تغییر لازم و دلیل | سختی | آزمون پذیرش | امنیت و رفتار قابل حفظ |
|---|---|---|---|---|
| `global.json` | پس از تصویب pin SDK10 با patch جاری و runner مبتنی بر MTP؛ رفع SDK2.1 | متوسط | انتخاب SDK از ریشه/CI و restore/test واقعی | بدون تنظیم سراسری محیط؛ رفتار domain حفظ |
| `Directory.Build.props` | net10 در پروژه‌ها، Runtime10 servicing؛ audit و lock حفظ؛ تصمیم صریح LangVersion؛ C# 7.3 برای API ممکن است | متوسط | ارزیابی props هر سه project و RID | بدون suppress advisory؛ بازنویسی source زبان لازم نیست |
| `Bazdid.sln` | همان سه project؛ تغییر ساختار لازم نیست | کم | build/test کل solution | بدون service/مخزن جدید |
| `src/Bazdid.Api/Bazdid.Api.csproj` | net10؛ حذف PackageReference App2.1، استفاده FrameworkReference ضمنی SDK.Web؛ MDS6.1.7/Pkcs10.0.14/MVC.Newtonsoft10.0.14/Newtonsoft13.0.4؛ Swagger جدید پس از gate | زیاد | restore/audit/build/publish و قیود dependency | OutOfProcess/XML docs حفظ؛ عدم کپی DLL یا افزودن namespace قدیمی |
| `tests/Bazdid.UnitTests/Bazdid.UnitTests.csproj` | net10، xUnit/MTP pin و TRX؛ حذف TestSdk/runner قدیمی مطابق تصمیم runner | متوسط | حفظ تمام ۱۰۹ case و discovery/TRX | تعداد caseها بدون دلیل کم نشود؛ پروژهٔ exe فقط ابزار آزمون |
| `tests/Bazdid.IntegrationTests/Bazdid.IntegrationTests.csproj` | net10، TestHost10 servicing، runner سازگار؛ reference همان API | زیاد | ۵۰ آفلاین موفق؛ ۸ SQL همچنان Skip تا تصویب | TestServer جای IIS/SQL نباشد |
| `src/Bazdid.Api/packages.lock.json` | فقط restore گراف مصوب و بازبینی همهٔ انتقالی‌ها | زیاد | locked restore، audit همهٔ بسته‌ها، RID assets | هیچ قید ناسازگار یا advisory پذیرفته‌نشده |
| `tests/Bazdid.UnitTests/packages.lock.json` | بازتولید گراف runner/API مصوب | متوسط | locked restore مستقل و solution | حذف وابستگی‌های EOL، حفظ integrity |
| `tests/Bazdid.IntegrationTests/packages.lock.json` | بازتولید گراف TestHost/runner/API | متوسط | locked restore و audit | assetهای native در test و publish یکسان بررسی شوند |

## API، host و middleware

نام‌های این جدول نسبت به `src/Bazdid.Api/` هستند؛ هر ردیف یک فایل واقعی است.

| فایل | تغییر لازم و دلیل | سختی | آزمون پذیرش | امنیت و رفتار قابل حفظ |
|---|---|---|---|---|
| `Program.cs` | Generic Host با ConfigureWebHostDefaults/UseStartup به‌جای WebHost منسوخ؛ حفظ entrypoint | متوسط | start/stop، config، shutdown و loopback | binding production جدا؛ MinimalAPI لازم نیست |
| `Startup.cs` | IWebHostEnvironment؛ AddControllers/Newtonsoft؛ routing؛ API جدید Swagger جدید؛ بررسی ترتیب security | زیاد | آزمون‌های FoundationHttp، OpenAPI snapshot و PathBase واقعی در IIS بعداً | prefix یک‌بار، رد mock در Production، احراز هویت خاموش، CORS دقیق/بدون credentials، HTTPS/HSTS حفظ |
| `Configuration/FoundationOptions.cs` | عمدتاً بدون تغییر؛ مرور binder/validation نسل جدید | کم | تمام تنظیم نامعتبر، environment و حالت origin ها | default بسته و عدم قبول secret در URL حفظ |
| `Controllers/HealthController.cs` | route/controller حفظ؛ مرور API/attribute ها | کم | JSON دقیق/status/no-store، prefix/root/double | فقط liveness؛ جزئیات DB/هویت ندهد |
| `Contracts/ApiError.cs` | بدون تغییر domain؛ کنترل سازگاری JSON | کم | camelCase/code/message/correlation/null | عدم جزئیات exception/PII حفظ |
| `Contracts/LivenessResponse.cs` | بدون تغییر ضروری | کم | JSON دقیق status | عدم افزودن readiness حساس |
| `Middleware/CorrelationMiddleware.cs` | مرور header/context/API ثبت log؛ رفتار حفظ | کم | correlation معتبر و ثبت log آزمون | ورودی correlation دلخواه هویت ایجاد نکند |
| `Middleware/ExceptionMiddleware.cs` | مرور ILogger/response-start/abort نسل جدید | متوسط | ۵۰۰ایمن و ResponseStarted/cancel | متن exception/SQL/secret ثبت نشود |
| `Middleware/JsonErrorWriter.cs` | Newtonsoft و WriteAsync overload/token؛ رفتار یکسان | متوسط | 400/404/405/500 JSON/headers | MaxDepth/TypeNameHandling.None؛ عدم formatter پیش‌فرض ناخواسته |

حفظ hosting موجود هم ارزیابی شد: نمونهٔ WebHost build شد ولی ASPDEPR008 داد؛ تغییر پیشنهادی فقط لایهٔ host است. حفظ Startup/DI/moduleها هزینهٔ بازنویسی و خطر تغییر رفتار را کم می‌کند. Swagger جدید تنها candidate است و بر خلاف host/JSON، در نمونه build نشده است.

## domain، application و adapterها

همهٔ مسیرها نسبت به `src/Bazdid.Api/` هستند.

| فایل | تغییر لازم و دلیل | سختی | آزمون پذیرش | امنیت و رفتار قابل حفظ |
|---|---|---|---|---|
| `Domain/Brokerage/BrokerageContracts.cs` | تغییر ضروری ندارد؛ async/token قرارداد حفظ | کم | compile و قرارداد reader | منبع معتبر/referral مجوز نمی‌شود |
| `Domain/Brokerage/BrokerageField.cs` | مدل immutable حفظ؛ فقط سازگاری serializer | کم | وضعیت فیلد/provenance/zero | Brokerage/معنای Manual حفظ |
| `Domain/Brokerage/BrokerageRequestSnapshot.cs` | بدون بازطراحی؛ constraint های جاری حفظ | کم | snapshot/multipleRequests/version | owner/محدودهٔ درخواست حفظ؛ پیشنهاد 2E اعمال نشود |
| `Domain/Persistence/PersistenceContracts.cs` | قرارداد فعلی مستقل از provider است و تغییر ضروری ندارد | کم | قرارداد repository/service و compile | owner/tenant/request/rowversion بدون تغییر |
| `Application/BrokerageRequestService.cs` | عمدتاً حفظ؛ env/provider نباید به domain نشت کند | کم | موبایل معتبر/normalization/unavailable/cancel | ورودی مشتری هویت ایجاد نکند |
| `Application/LinkagePersistenceService.cs` | جریان transaction/idempotence حفظ؛ type های SQL داخل adapter بمانند | متوسط | ایجاد اتمیک link/context/audit،rollback/stale/race | عدم mutation پس از خطا، audit فقط افزایشی؛ commit ناهمگام بازطراحی اجباری نیست |
| `Fixtures/SyntheticBrokerageFixtures.cs` | تغییر ضروری ندارد؛ دادهٔ ساختگی حفظ | کم | همهٔ fixtureها و ۱۸ سناریو | فقط Development/Testing؛ رد تنظیم نامصوب Production |
| `Infrastructure/Brokerage/BrokerageServiceCollectionExtensions.cs` | IHostingEnvironment به IWebHostEnvironment یا abstraction محدود | متوسط | DI Disabled/Synthetic/SqlUnavailable و رد تنظیم نامصوب Production | defaultDisabled و بدون fallback حفظ |
| `Infrastructure/Brokerage/SyntheticBrokerageRequestReader.cs` | تغییر ضروری ندارد؛ کنترل token/API | کم | lookup/snapshot/مالکیت درخواست/cancel | فقط synthetic و بدون SMS |
| `Infrastructure/Brokerage/SqlBrokerageRequestReader.cs` | unconfigured بماند؛ mapping ساخته نشود | کم | SourceNotConfigured/Unavailable | هیچ query/SELECT مبدأ بدون تصویب |

## زیرساخت SQL؛ بدون اتصال در port آفلاین

مسیرها نسبت به `src/Bazdid.Api/` هستند.

| فایل | تغییر لازم و دلیل | سختی | آزمون پذیرش | امنیت و رفتار قابل حفظ |
|---|---|---|---|---|
| `Infrastructure/Sql/SqlRuntimeOptions.cs` | namespace جدید و Encrypt دارای نوع جدید؛ مرور builder/token/parser | متوسط | الزام Mandatory،IntegratedSecurity،رد credential/endpoint نامصوب | Runtime.Enabled=false و gate=false؛ عدم bypass گواهی |
| `Infrastructure/Sql/SqlConnections.cs` | همهٔ نوع‌ها MDS؛ OpenAsync/catch/disposal و SqlErrors.Map مرور | زیاد | آفلاین guard؛ سپس native/SSPI/identity/TLS/pooling/cancel | guard query فعلی/پارامترها حفظ؛ تغییر LPC/TCP تصویب مستقل |
| `Infrastructure/Sql/SqlCommands.cs` | SqlCommand/Parameter/Reader/namespace مربوط به Transaction؛ API هم‌معنا | متوسط | type/size/null/timeout/token tests؛ بعداً execution | SQL پارامتری و محدودیت query حفظ؛ عدم AddWithValue حدسی |
| `Infrastructure/Sql/SqlRepositories.cs` | نوع adapterها MDS؛ mapping/rowversion/transaction همان | زیاد | قرارداد repository؛ متصل ownership/stale/rollback/race بعداً | فقط سه BAZDID،audit INSERT؛ schema/query تجاری تغییر نکند |
| `Infrastructure/Sql/SqlRegistration.cs` | namespace/امضای factory سازگار؛ DI گیت حفظ | متوسط | registration/lifetime/failclosed | هیچ configuration راه عبور از gate نباشد |
| `Infrastructure/Sql/AssemblyAccess.cs` | تغییر ضروری ندارد؛ نام friend assembly با runner چک | کم | دسترسی آزمون به internal و build | دسترسی عمومی صرفاً برای test اضافه نشود |

بررسی کد موجود: connection factory خود principal/instance/DB/permission را guard و SET option های لازم را اعمال می‌کند؛ command layer token/timeout/parameter و repos مرز owner/context را نگه می‌دارند. انتخاب MDS جای بررسی خطاهای 1205/timeout/permission، rollback، انتظار lock، rowversion و commit نامعلوم را نمی‌گیرد. هیچکدام در P0 با DB اجرا نشدند. امکان CommitAsync دلیل تغییر اجباری معنا/مرز transaction نیست.

## آزمون‌های موجود

مسیرها نسبت به `tests/` هستند؛ baseline واقعی این مرحله ۱۰۹unit+۵۰offline و۸ SQLSkip است.

| فایل | تغییر لازم و دلیل | سختی | آزمون پذیرش | امنیت و رفتار قابل حفظ |
|---|---|---|---|---|
| `Bazdid.UnitTests/FoundationOptionsTests.cs` | API مربوط به xUnit/runner مرور؛ داده/قواعد حفظ | کم | تمام حالت config ها | URL ساختگی fixture دادهٔ واقعی نیست؛ reject همچنان لازم |
| `Bazdid.UnitTests/BrokerageReaderTests.cs` | محیط آزمایشی جایگزین جدید؛ assertion ناهمگام مرور | متوسط | تمام reader/حالت مدل ها | رد mock در Productionion/owner/provenance حفظ |
| `Bazdid.UnitTests/SqlPersistenceTests.cs` | namespace مربوط به MDS و builderEncrypt دارای نوع جدید | متوسط | پارامتر command/options/errors و gate | بازنکردن اتصال؛ تست bool قدیمی Encrypt به typed تبدیل |
| `Bazdid.UnitTests/LinkageTransactionTests.cs` | جایگزین آزمایشی/API ناهمگام سازگار؛ معنا حفظ | متوسط | begin/commit/rollback/idempotence/conflict | سناریوها حذف/ضعیف نشوند |
| `Bazdid.IntegrationTests/FoundationHttpTests.cs` | Generic Host با UseTestServer؛ Build/assertion زمان Start؛ Swagger مدل جدید | زیاد | health/error/CORS/HTTPS/pathbase/Swagger تمام caseها | شبیه‌سازی IIS جای میزبان واقعی معرفی نشود |
| `Bazdid.IntegrationTests/BrokerageIntegrationTests.cs` | Generic Host/محیط آزمایشی جایگزین جدید | متوسط | محیط‌های DI و رفتار service | source بدون پیکربندی و fixture فقط تست |
| `Bazdid.IntegrationTests/SqlRuntimeRegistrationTests.cs` | host/MDS/builder با نوع جدید و تست startup زمان Build | متوسط | SQL=false/gate=false/principal نامعتبر/DI | بازنشدن gate و عدم fallback |
| `Bazdid.IntegrationTests/SqlRepositoryConnectedTests.cs` | در port فقط namespace/runner؛ ۸Skip حفظ؛ بعداً gap ها تحت approval | زیاد | بعداً cancel/timeout/locks/race/rowversion/permissions با SQL واقعی | Skip قبولی نیست؛ هیچ sysadmin/دادهٔ واقعی/DDL خودکار |

پیش از پذیرش مهاجرت واقعی، mapping تک‌تک caseهای قدیم به runner جدید لازم است؛ افزایش/تغییر شمار theory discovery توضیح می‌خواهد. نمونهٔ۱۴case جای۱۵۹regression اصلی یا۸connected را نمی‌گیرد.

## تنظیمات، deployment و اسناد

| فایل | تغییر لازم و دلیل | سختی | آزمون پذیرش | امنیت و رفتار قابل حفظ |
|---|---|---|---|---|
| `src/Bazdid.Api/appsettings.json` | اصولاً حفظ؛ مرور binding/default ها | کم | پیش‌فرض بسته/basepath/آزمون‌های config | بدون connection string/secret؛ SQL خاموش |
| `src/Bazdid.Api/appsettings.Development.json` | حفظ Synthetic صریح/SQL=false | کم | محیط و DI/startup | اتصال فقط با approval جدید |
| `src/Bazdid.Api/appsettings.Testing.json` | حفظ fixture/تنظیمات میزبان | کم | TestServer/config | بدون مبدأ واقعی |
| `src/Bazdid.Api/appsettings.Production.example.json` | نام کلیدها حفظ؛ مرور مثال runtime10 فقط در صورت نیاز | متوسط | اعتبارسنجی تنظیمات و رد تنظیم نامصوب Production | authentication/SQL/mock هرگز بی‌صدا فعال نشوند |
| `src/Bazdid.Api/Properties/launchSettings.json` | فایل شخصی untracked؛ تغییر/commit نشود | کم | فقط hash قبل/بعد | محتوا خوانده/منتشر نشود |
| `deployment/iis/web.config.example` | پس از port با publish حاصل از SDK10 مقایسه؛ OutOfProcess حفظ | متوسط | ANCM واقعی در staging/subapplication/recycle | محیط/identity/secret جدا؛ نصب اکنون مجاز نیست |
| `deployment/iis/README.md` | پس از تصویب اجرایی، SDK/runtime/bundle و rollback را همسو کند | متوسط | بازبینی همکار و در آینده hosting واقعی | هشدار EOL و قید مجوز حفظ |
| `database/proposals/development_logins.review.sql` | در مهاجرت آفلاین بدون تغییر؛ P1/P2 پیش‌شرط مستقل | زیاد | بعداً SID/guard/هویت واقعی | hash ثبت‌شده/AllowDdl0 حفظ |
| `database/proposals/permissions.review.sql` | بدون تغییر؛ با query/repo فعلی هم‌خوان | زیاد | بعداً allow/deny/column/group و verifier | Reader بدون مجوز مبدأ؛ Writer بدون audit read یا Customer UPDATE |
| سایر `database/` و `docs/reference/` | تغییر معنایی لازم نیست؛ SQL مرجع اجرا نشود | کم | hash/diff و تفکیک شاهد تاریخی | عدم DDL/seed/backup/آرشیو خصوصی |
| `src/Bazdid.Api/Application/README.md` | در صورت تغییر نام API زیرساخت، فقط ارجاع به‌روز | کم | پیوند/سازگاری | قرارداد domain بدون تغییر |
| `src/Bazdid.Api/Domain/README.md` | قواعد domain حفظ؛ ارتقای runtime به‌عنوان قاعدهٔ تجاری عرضه نشود | کم | پیوند/قواعد | درخواست‌محوری/provenance قفل حفظ |
| `src/Bazdid.Api/Infrastructure/README.md` | بعد از port، provider/host/gate واقعی را شرح دهد | متوسط | walkthrough با کد هم‌خوان | طراحی به‌عنوان اجرای SQL گزارش نشود |
| `AGENTS.md`, `PLAN.md`, `README.md` | فقط با مجوز واقعی target قطعی را اصلاح و پیشرفت بدون امتیاز ساختگی ثبت کند | متوسط | consistency/links/دامنهٔ مصوب | P0 مجوز تغییر canonical نیست |
| `docs/ARCHITECTURE_FA.md`, `docs/IIS_DEPLOYMENT_FA.md`, `docs/TESTING_STRATEGY_FA.md` | پس از port شرح اجرایی با host/runner واقعی؛ طرح اینجا مرجع است | متوسط | تطبیق کد/فرمان/شاهد میزبان | بدون ادعای IIS/SQL آزموده‌نشده |
| `docs/AI_CONTINUATION_FA.md`, `docs/OPEN_DECISIONS_FA.md`, `docs/SOURCE_REFERENCES_FA.md` | مرز تأیید/P0/مهاجرت/connected و قرارداد حفظ | کم | پیوند/منابع/تعارض | O24/O26 تا پذیرش واقعی باز |
| `docs/implementation/README.md` و walkthrough های مرتبط | ثبت فرایند واقعی، تست، خطا، commit و گام بعد | متوسط | بازآزمایی فرمان و consistency | سابقهٔ تاریخی بازنویسی نشود |
| `docs/GITHUB_SYNC_FA.md` | ثبت SHA/push/HEAD/blob های واقعی پس از هر انتشار | کم | fetch/lsremote/خواندن فایل در GitHub | اصل خصوصی/ZIP/artifacts ارسال نشود |

برای مهاجرت واقعی، فایل جدیدی از پیش الزامی نیست؛ helper سازگار تست ممکن است بعد از بررسی diff لازم شود. P0 پروژهٔ Production دوم یا schema جایگزین پیشنهاد نمی‌کند. gateهای باز: Swagger/Newtonsoft graph و parity، همهٔ تست‌های canonical روی target جدید، native/SSPI/TLS، مجوزهای مؤثر، transaction/concurrency واقعی و IIS/OS مقصد. progress این طرح **20+0=20%** است.
