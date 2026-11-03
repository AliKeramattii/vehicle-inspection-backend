# پایگاه داده

در Checkpoint 2C و با مجوز صریح مالک، `BAZDID_Development` و فقط سه جدول dbo روی SQL Server 2019 محلی ایجاد و تأیید شدند. compatibility برابر ۱۵۰، collation برابر `SQL_Latin1_General_CP1_CI_AS`، recovery برابر SIMPLE و شمار ردیف هر سه جدول پس از ۳۵ آزمون rollback-only صفر است. هیچ role/login/user/grant، journal، Info یا جدول auth/media ایجاد نشد. فایل‌های `docs/reference/sql/` تاریخی‌اند و اجرا نشده‌اند.

| فایل | وضعیت و کاربرد |
|---|---|
| [server_inventory.sql](discovery/server_inventory.sql) | فقط‌خواندنی؛ روی master محلی مصوب اجرا و خروجی آن ثبت شد |
| [source_object_metadata.sql](discovery/source_object_metadata.sql) | فقط‌خواندنی و بسته تا تعیین نام/مجوز واقعی؛ روی کارگزاری اجرا نشده |
| [create_development_database.review.sql](proposals/create_development_database.review.sql) | ساخت DB فقط با نسخهٔ حافظه‌ای مجاز اجرا شد؛ فایل همچنان بسته است |
| [initial_tables.review.sql](proposals/initial_tables.review.sql) | نسخهٔ final سه جدول و CHECKهای اصلاح‌شده؛ اجرا از ابتدا و اصلاح محدود در walkthrough ثبت است؛ فایل بسته می‌ماند |
| [repair_tenant_checks.review.sql](proposals/repair_tenant_checks.review.sql) | شاهد اصلاح سه CHECK tenant در همین 2C، با WITH CHECK و transaction؛ فایل بسته است |
| [permissions.review.sql](proposals/permissions.review.sql) | پیش‌نویس دو نقش و حساب‌های Windows ازپیش‌مصوب؛ اجرا نشده |
| [Invoke-BazdidDevelopmentDatabase.ps1](tools/Invoke-BazdidDevelopmentDatabase.ps1) | ابزار محدود Inspect/CreateDatabase/CreateTables/RepairTenantChecks/Verify/Test؛ بدون SQL یا مقصد دلخواه |
| [schema_expected.json](verification/schema_expected.json) و [checkpoint2c_metadata.sql](verification/checkpoint2c_metadata.sql) | قرارداد و تطبیق مستقیم schema واقعی، index/FK/CHECK/column و شمار صفر |
| [checkpoint2c_rollback_cases.sql](verification/checkpoint2c_rollback_cases.sql) | ۳۵ CASE ساختگی؛ فقط از ابزار با transaction/rollback مستقل اجرا شود، نه مستقیم |

تمام `.review.sql`ها با `@AllowDdl = 0` و approval NULL بسته‌اند. ابزار برای DDL فقط با switch صریح، شناسهٔ مجوز و hash فایل بازبینی‌شده، دو مقدار را در حافظه مجاز می‌کند؛ فایل source باز نمی‌شود. هویت همان ماشین/Windows/Shared memory، major version ۱۵، instance دقیق، نبود linked server/Cluster/HADR/DB کاربری دیگر و defaults/دیسک دوباره کنترل می‌شوند. هیچ DROP/overwrite/attach یا reset خودکار وجود ندارد. روی پایگاه موجود CreateDatabase و روی schema موجود CreateTables متوقف می‌شوند؛ تغییر flag، مجوز جدید نمی‌سازد. هیچ فایل از startup برنامه فراخوانی نمی‌شود.

برای کشف فقط‌خواندنی، در SSMS با Windows Authentication به `lpc:.\SQLSERVER2019` و پایگاه `master` متصل شوید و فقط فایل inventory را اجرا کنید. مسیر نصب موجود `sqlcmd` برابر `C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\SQLCMD.EXE` است؛ در صورت استفاده، همین مقصد/پایگاه و Windows Authentication و توقف روی خطا انتخاب شوند. گزینهٔ ApplicationIntent جای مجوز SELECT را نمی‌گیرد.

برای بررسی تحویل 2C از ریشهٔ مخزن:

```powershell
.\database\tools\Invoke-BazdidDevelopmentDatabase.ps1 -Action Inspect
.\database\tools\Invoke-BazdidDevelopmentDatabase.ps1 -Action Verify
```

Verify این مرحله، پایگاه خالیِ تحویل 2C را انتظار دارد و هیچ دادهٔ موجودی پاک نمی‌کند. برای Test، فایل CASEها باید بازبینی و hash آن به ابزار همراه switch ApproveRollbackTests و مرجع مجوز داده شود؛ تست مستقیم مجاز نیست. counterهای identity/rowversion با rollback ممکن است جلو بروند؛ ردیفی باقی نمانده و reseed لازم نیست.

پیش‌نیاز SQL runtime آینده: دو هویت Windows مستقل و کم‌اختیارِ مصوب، آزمون permission مؤثر، secret store/ACL، TLS معتبر و حل سازگاری client در O24. این هویت‌ها تحویل نشده‌اند؛ sysadmin provisioning برای برنامه ممنوع است. patch موتور RTM باید توسط DBA بازبینی شود. هیچ نرم‌افزار یا سرویسی نصب/تغییر نشد؛ روی میزبان تازه نصب نیازمند تصویب جداست.

[walkthrough 2C](../docs/implementation/CHECKPOINT-02C-DATABASE-CREATION_FA.md) توالی واقعی، hashها، خطا و رفع آن، تنظیم فایل‌ها، فرمان‌های بازتولید و VS Code را دارد؛ [schema واقعی](../docs/checkpoint2c/SCHEMA_VERIFICATION.json) و [نتایج rollback](../docs/checkpoint2c/ROLLBACK_TEST_RESULTS.json) شاهدند. [طراحی داده](../docs/DATABASE_DESIGN_FA.md) بقیهٔ جدول‌های آینده را از سه جدول ساخته‌شده تفکیک می‌کند. ارتقای migration/repository و آزمون permission runtime هنوز انجام نشده؛ در پایان 2C توقف می‌شود و 2D شروع نشده است.


## وضعیت 2F در 2026-11-03

schema و همهٔ scriptهای این پوشه بدون تغییر ماندند. verification خواندنی قبل/بعد همان سه جدول و صفر ردیف را تأیید کرد؛ [شاهد 2F](../docs/checkpoint2f/DATABASE_VERIFICATION.json). repositoryها در برنامه نوشته شده‌اند ولی gate اتصال کد بسته است؛ هیچ عملیات SQL آن‌ها یا DDL/role/user/grant اجرا نشد. [راهنمای 2F](../docs/implementation/CHECKPOINT-02F-SQL-REPOSITORIES_FA.md) جریان، پارامترها، transaction و موانع را شرح می‌دهد.

metadata نقش‌ها/Windows user صفر و نام دو principal مصوب موجود نیست. permissions.review.sql هنوز پیش‌نویس بسته است و حداقل دسترسی Writer فعلی حتی UPDATE CustomerLinks نیاز ندارد؛ قبل از اجرای احتمالی باید دوباره بازبینی و با نام‌ها/مجوزهای مشخص تصویب شود. SourceReader هیچ mapping/شیء مصوب ندارد. sysadmin فقط metadata خوانده و account برنامه نشده است.

۸ تست واقعی SQL در SqlRepositoryConnectedTests با دلیل O24/O26 Skip هستند؛ صفر تست متصل، ۱۵۹ موفق آفلاین و پیشرفت ۲۰٪. از ابزار Verify فقط برای مشاهدهٔ مقصد مصوب استفاده شد؛ EvidencePath ابزار 2C محدود است و نباید برای 2F باز شود، stdout را جدا ثبت کنید. اجرای ۳۵ CASE قدیمی، DDL یا بازسازی خودکار مجاز نیست؛ 2G شروع نشده است.
