# راهنمای SQL Server در VS Code برای توسعهٔ بازدید

این آموزش برای Windows محلی و بررسی **فقط‌خواندنی** است؛ تاریخ `2026-11-01`. طبق [اجرای واقعی 2C](../implementation/CHECKPOINT-02C-DATABASE-CREATION_FA.md)، `BAZDID_Development` اکنون روی SQL Server Standard `15.0.2000.5` ساخته شده و فقط سه جدول BAZDID دارد؛ metadata و ۳۵ آزمون rollback-only تأیید شدند و هیچ ردیفی باقی نماند. نبود پایگاه در [کشف تاریخی 2A/2B](../CHECKPOINT2A_2B_REPORT_FA.md) مربوط به قبل از این ساخت است. افزونهٔ `ms-mssql.mssql@1.47.0` در نگهداری قبلی با CLI تأیید شد؛ اتصال/نمایش VS Code در 2C آزمایش نشده و SQL مجاز آن با ابزار PowerShell اجرا شد. وضعیت زنده را پیش از کار دوباره احراز کنید.

## ۱. افزونهٔ رسمی و بازکردن Explorer

در VS Code کلید `Ctrl+Shift+X` را بزنید و `@id:ms-mssql.mssql` را جست‌وجو کنید. افزونهٔ **SQL Server (mssql)** با ناشر **Microsoft** را انتخاب کنید. اگر نصب نیست، دکمهٔ Install آن را بزنید؛ در میزبان بررسی‌شده از قبل نصب است. این افزونه client است و نصب آن، نصب SQL Server یا ساخت پایگاه نیست. [صفحهٔ رسمی افزونه](https://marketplace.visualstudio.com/items?itemName=ms-mssql.mssql).

از نوار کناری، نمای MSSQL/SQL Server را باز کنید؛ بخش Connections یا Object Explorer اتصال‌ها را نشان می‌دهد. اگر آیکن پنهان است، از `Ctrl+Shift+P` فرمان `MS SQL: Add Connection` را جست‌وجو کنید. نام‌ها ممکن است با زبان/نسخهٔ افزونه کمی تفاوت داشته باشند. [راهنمای رسمی رابط و Explorer](https://learn.microsoft.com/en-us/sql/tools/visual-studio-code-extensions/mssql/mssql-extension-visual-studio-code).

## ۲. اتصال اولیه به master

یک اتصال با مشخصات زیر بسازید؛ VS Code را روی Windows محلی استفاده کنید و اتصال را با نام روشنِ محیط ذخیره کنید:

| گزینه | مقدار این پروژه |
|---|---|
| نام نمایشی پیشنهادی | `BAZDID LOCAL DEV - master` |
| Server name | `localhost\SQLSERVER2019` |
| Authentication type | `Windows Authentication` یا `Integrated` |
| Database | `master`؛ انتخاب Default ممکن است پایگاه پیش‌فرض دیگری باز کند |
| User/Password | برای حساب جاری Windows چیزی وارد نمی‌شود |
| Encrypt | روشن؛ برای اتصال شبکه‌ای گواهی معتبر و `Trust Server Certificate=False` لازم است |

Windows Authentication از هویت جاری Windows استفاده می‌کند؛ همان حساب باید در SQL مجوز داشته باشد. پس از کنترل مقصد، با Test connection و سپس Connect می‌توان اتصال را بررسی کرد. این اتصالِ VS Code در 2C اجرا/ثبت نشده است. [تنظیم اتصال و احراز Windows در مستندات Microsoft](https://learn.microsoft.com/en-us/sql/tools/visual-studio-code-extensions/mssql/mssql-database-connections).

در کشف قبلی، اتصال موفقِ اثبات‌شده **`lpc:.\SQLSERVER2019`** روی Shared memory با PowerShell بود؛ اتصال `localhost\SQLSERVER2019` از VS Code هنوز شاهد اجرای ثبت‌شده ندارد. برای تکرار دقیق مقصد محلی می‌توان پروفایل جدا با همین مقدار lpc ساخت. [server_inventory.sql](../../database/discovery/server_inventory.sql) فقط در master با Shared memory اجازهٔ خواندن می‌دهد؛ پروفایل localhost ممکن است transport دیگری انتخاب کند و guard آن را رد کند. guard را حذف نکنید.

اگر گواهی self-signed محلی خطا داد، ابتدا مقصد و گواهی را بررسی کنید. تنها استثنای ثبت‌شدهٔ 2A/2B، `Encrypt=True` و `TrustServerCertificate=True` برای metadata روی **lpc محلی** بود. اعتماد موقت به گواهی فقط در پروفایل اختصاصیِ تست محلی و با همان محدودیت بازبینی شود؛ این تنظیم به اتصال شبکه‌ای، Production یا config عمومی برنامه منتقل نمی‌شود. حساب کشف فعلی sysadmin بود؛ account برنامه باید مستقل و کم‌اختیار باشد.

## ۳. اولین query فقط‌خواندنی

از Explorer روی اتصال، New Query را انتخاب کنید؛ فایل باید در حالت زبان SQL باشد. نام اتصال و پایگاهِ editor را بررسی کنید، فقط بلوک موردنظر را انتخاب و فرمان Execute Query (در نسخهٔ نصب‌شده با عنوان `Execute Query (MSSQL)`، در مستندات با `MS SQL: Execute Query`) یا `Ctrl+Shift+E` را بزنید. نتیجه در Results ظاهر می‌شود؛ انتخاب‌نکردن متن ممکن است تمام فایل را اجرا کند. این بلوک‌ها راه اجرای دستی‌اند و خروجی VS Code برای آن‌ها در این مرحله ثبت نشده است. [روش رسمی اجرای query](https://learn.microsoft.com/en-us/sql/tools/visual-studio-code-extensions/mssql/mssql-run-first-query).

ابتدا زمینهٔ اتصال را ببینید:

```sql
SELECT DB_NAME() AS DatabaseName,
       CONVERT(nvarchar(128), SERVERPROPERTY('InstanceName')) AS InstanceName,
       CONVERT(nvarchar(128), SERVERPROPERTY('ProductVersion')) AS ProductVersion,
       CONVERT(nvarchar(128), CONNECTIONPROPERTY('net_transport')) AS NetTransport;
```

برای این مرحله، DatabaseName باید master و InstanceName باید SQLSERVER2019 باشد. نتیجهٔ متفاوت نیازمند بررسی مقصد است؛ query بعدی را روی مقصد ناشناس اجرا نکنید.

فهرست metadata و وجود پایگاه تست را بررسی کنید:

```sql
SELECT name, compatibility_level, collation_name, state_desc
FROM sys.databases
WHERE database_id <= 4 OR name = N'BAZDID_Development'
ORDER BY database_id;

SELECT DB_ID(N'BAZDID_Development') AS TestDatabaseId;
```

در اجرای تاریخی 2A/2B مقدار TestDatabaseId برابر NULL بود؛ پس از ساخت 2C مقدار مشاهده‌شده ۵ و پایگاه دارای compatibility ۱۵۰ و collation برابر `SQL_Latin1_General_CP1_CI_AS` بود. شناسهٔ عددی روی نصب دیگر ثابت فرض نشود. NULL با حساب محدود می‌تواند از نبود دید metadata نیز ناشی شود؛ به‌تنهایی همیشه اثبات نبود پایگاه نیست. حساب بررسی sysadmin و دارای دید کامل catalog بود؛ account برنامه نخواهد بود.

## ۴. Databases، Refresh و انتخاب پایگاه تست

در Object Explorer اتصال را باز و Databases را expand کنید. برای دریافت فهرست تازه، روی گره اتصال/Databases راست‌کلیک و Refresh را انتخاب کنید؛ فیلتر فعال هم ممکن است نام‌ها را پنهان کند. Refresh فقط نمای ابزار را تازه می‌کند و پایگاه نمی‌سازد.

ساخت مصوب در 2C انجام شده است؛ `BAZDID_Development` را انتخاب و New Query را از همان گره باز کنید یا با `MS SQL: Use Database` زمینه را تغییر دهید. با `SELECT DB_NAME()` انتخاب را دوباره احراز کنید. مسیر مورد انتظار `SQLSERVER2019 > Databases > BAZDID_Development > Tables` است. اگر دیده نمی‌شود، اتصال/مجوز/Refresh را بررسی کنید؛ با CREATE، Publish یا Import دوباره‌سازی خودکار انجام ندهید.

فایل‌های [ساخت پایگاه](../../database/proposals/create_development_database.review.sql)، [جدول‌ها](../../database/proposals/initial_tables.review.sql) و repair در repository همچنان `@AllowDdl=0` و approval برابر NULL دارند. در 2C فقط نسخهٔ حافظه‌ایِ مجاز و hashشده اجرا شد؛ [مجوزها](../../database/proposals/permissions.review.sql) اصلاً اجرا نشده‌اند. بازکردن فایل مجوز Execute یا تغییر flag نیست و پایگاه موجود نباید خودسرانه بازسازی شود. [راهنمای پایگاه](../../database/README.md) وضعیت دقیق فایل‌ها و ابزار محدود را دارد.

## ۵. مشاهدهٔ جدول‌ها، ستون‌ها، کلیدها و داده

سه جدول `dbo.BAZDIDCustomerLinks`، `dbo.BAZDIDRequestContexts` و `dbo.BAZDIDAuditLogs` با metadata مستقیم تأیید شده‌اند. از گره پایگاه Tables را باز و جدول را expand کنید تا Columns و بخش‌های کلید/index/رابطهٔ موجود در نسخهٔ افزونه دیده شوند. برای فهرست مستقل از ظاهر ابزار، در **پایگاه تست مصوب** queryهای زیر را اجرا کنید:

```sql
SELECT s.name AS SchemaName, t.name AS TableName
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE t.name LIKE N'BAZDID%'
ORDER BY s.name, t.name;

SELECT c.column_id, c.name AS ColumnName, ty.name AS TypeName,
       c.max_length, c.is_nullable, c.is_identity, c.is_computed
FROM sys.columns AS c
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID(N'dbo.BAZDIDRequestContexts', N'U')
ORDER BY c.column_id;
```

max_length در metadata برحسب **بایت** است؛ برای nvarchar الزاماً تعداد نویسه نیست. dbo در این مثال، پیشنهاد تست محلی است؛ اگر schema نهایی فرق کرد، نام مصوب را جایگزین کنید. خروجی خالی می‌تواند از نبود جدول، schema اشتباه یا فقدان دید metadata باشد.

کلید/index و رابطهٔ داخلی را بدون خواندن ردیف مشتری بررسی کنید:

```sql
SELECT i.name AS IndexName, i.is_primary_key, i.is_unique,
       c.name AS ColumnName, ic.key_ordinal, ic.is_included_column
FROM sys.indexes AS i
JOIN sys.index_columns AS ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns AS c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'dbo.BAZDIDRequestContexts', N'U')
ORDER BY i.index_id, ic.index_column_id;

SELECT fk.name AS ForeignKeyName,
       OBJECT_SCHEMA_NAME(fk.parent_object_id) AS ParentSchema,
       OBJECT_NAME(fk.parent_object_id) AS ParentTable,
       OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS ReferencedSchema,
       OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable
FROM sys.foreign_keys AS fk
WHERE fk.parent_object_id = OBJECT_ID(N'dbo.BAZDIDRequestContexts', N'U');
```

برای مشاهدهٔ دادهٔ synthetic بعدی، پس از احراز مجوز SELECT حساب بازبین، از projection محدود استفاده کنید. در تحویل 2C هر سه جدول صفر ردیف دارند و نتیجهٔ این SELECT خالی است؛ seed یا رکورد دائمی تست ایجاد نشده:

```sql
SELECT TOP (20) Id, OccurredAtUtc, ActionCode, OutcomeCode
FROM dbo.BAZDIDAuditLogs
ORDER BY Id DESC;
```

اکانت writer پیشنهادی فقط INSERT روی audit دارد؛ نمایش داده نیازمند account بازبینِ مصوب است و این راهنما به آن مجوز اضافه نمی‌کند. برای مشاهده، query SELECT کافی است؛ فرمان Edit Table Data امکان تغییر و ذخیرهٔ داده دارد. پنجرهٔ Designer/Schema Compare نیز Publish دارد؛ از آن برای اعمال schema در این مرحله استفاده نشود. [توضیح رسمی امکانات مشاهده و ویرایش](https://learn.microsoft.com/en-us/sql/tools/visual-studio-code-extensions/mssql/mssql-extension-visual-studio-code).

## ۶. خطاهای رایج

| نشانه | بررسی عملی |
|---|---|
| instance پیدا نمی‌شود؛ خطای 26/40 یا timeout | املای `localhost\SQLSERVER2019`، اجرای سرویس و مقصد محلی را بررسی کنید؛ پورت 1433 را برای named instance فرض نکنید. lpc نام اثبات‌شدهٔ کشف قبلی است؛ firewall/پروتکل سرور را خودکار تغییر ندهید |
| Login failed / 18456 | Windows Authentication و هویت جاری را کنترل کنید؛ DBA باید مجوز همان حساب را تأیید کند؛ رمز آرشیو یا SQL Login حدسی وارد نکنید |
| Cannot open database / 4060 | برای بررسی اولیه master را صریح انتخاب کنید؛ ممکن است BAZDID_Development هنوز وجود نداشته یا account دسترسی نداشته باشد |
| certificate یا target principal | نام مقصد، گواهی و تنظیم Encrypt را بررسی کنید؛ استثنای TrustServerCertificate فقط همان lpc تست محلیِ محدود است |
| Invalid object / 208 | `SELECT DB_NAME()`، schema، نام جدول و وضعیت اجرای مصوب schema را بررسی کنید؛ وجود فایل SQL، وجود جدول نیست |
| Permission denied / 229 یا Explorer خالی | مجوز SELECT/دید metadata را از DBA پیگیری کنید؛ غیبت در Explorer اثبات نبود شیء نیست و درخواست db_owner راه‌حل کم‌اختیار محسوب نمی‌شود |
| guard فایل inventory رد شد | اتصال باید master/instance مصوب و Shared memory باشد؛ روی localhost ممکن است TCP انتخاب شده باشد؛ guard را باز نکنید |

این‌ها راه‌های تشخیص‌اند، نه خطاهایی که در این وظیفه رخ داده‌اند. خروجی خطا یا connection string ممکن است اطلاعات میزبان/حساب داشته باشد؛ برای گزارش، فقط error code و شرح پاک‌شده کافی است.

## ۷. مرز Development و Production

اتصال تست را با نام و گروه واضح نگه دارید و پیش از Execute، اتصال editor و DatabaseName را ببینید. Application Intent یا رنگ پروفایل، جای مجوز واقعی فقط‌خواندنی نیست. این راهنما هیچ دسترسی Production ایجاد نمی‌کند؛ جدول‌های مشتری/درخواست کارگزاری و دادهٔ واقعی باز/کپی/ویرایش نشوند.

پروفایل را در تنظیمات شخصی ابزار نگه دارید؛ password، token، connection string محرمانه، فایل export نتایج یا `.vscode/settings.json` دارای اتصال واقعی وارد Git نشود. نمونه‌های این سند credential ندارند. 2C کامل و پیشرفت کل **17%** است؛ گام بعد 2D در درخواست جداگانه و با بررسی مستقل پیش‌نیازهاست و این راهنما آن را شروع نمی‌کند.
