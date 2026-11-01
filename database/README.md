# پایگاه داده

در Checkpoint 2A/2B، فقط کشف محلی و آماده‌سازی برای بازبینی مجاز است. هیچ پایگاه، جدول، نقش یا migration اجرا نشده است. فایل‌های `docs/reference/sql/` پیشنهاد تاریخی‌اند و نباید اجرا شوند.

| فایل | وضعیت و کاربرد |
|---|---|
| [server_inventory.sql](discovery/server_inventory.sql) | فقط‌خواندنی؛ روی master محلی مصوب اجرا و خروجی آن ثبت شد |
| [source_object_metadata.sql](discovery/source_object_metadata.sql) | فقط‌خواندنی و بسته تا تعیین نام/مجوز واقعی؛ روی کارگزاری اجرا نشده |
| [create_development_database.review.sql](proposals/create_development_database.review.sql) | پیش‌نویس ساخت پایگاه تست؛ اجرا نشده |
| [initial_tables.review.sql](proposals/initial_tables.review.sql) | پیش‌نویس سه جدول BAZDID، بدون seed یا migration اجرایی؛ اجرا نشده |
| [permissions.review.sql](proposals/permissions.review.sql) | پیش‌نویس دو نقش و حساب‌های Windows ازپیش‌مصوب؛ اجرا نشده |

تمام فایل‌های `.review.sql` با `@AllowDdl = 0` و مرجع تصویب NULL بسته‌اند. تغییر flag مجوز ایجاد نمی‌کند؛ بازبینی schema، تأیید تازهٔ مالک، احراز دوبارهٔ مقصد و حساب اجرای DDL لازم است. این فایل‌ها از startup برنامه فراخوانی نمی‌شوند.

برای کشف فقط‌خواندنی، در SSMS با Windows Authentication به `lpc:.\SQLSERVER2019` و پایگاه `master` متصل شوید و فقط فایل inventory را اجرا کنید. مسیر نصب موجود `sqlcmd` برابر `C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\SQLCMD.EXE` است؛ در صورت استفاده، همین مقصد/پایگاه و Windows Authentication و توقف روی خطا انتخاب شوند. گزینهٔ ApplicationIntent جای مجوز SELECT را نمی‌گیرد.

پیش‌نیاز مرحلهٔ بعد: SQL instance محلی تأییدشده، بررسی patch/مجوز استفاده/فضای دیسک و model توسط DBA، تعیین recovery و schema تست، دو هویت Windows مستقلِ کم‌اختیار، secret store/ACL و TLS مصوب، schema بازبینی‌شده و مجوز صریح DDL. در این میزبان ابزارها نصب‌اند؛ نصب یا شروع خودکار سرویس انجام نمی‌شود. روی میزبان تازه، نسخه/edition، پیش‌نیاز سیستم‌عامل، مجوز استفاده، patch و ابزار رسمی باید پیش از نصب توسط زیرساخت تصویب شوند.

[گزارش 2A/2B](../docs/CHECKPOINT2A_2B_REPORT_FA.md) نتایج واقعی و [طراحی داده](../docs/DATABASE_DESIGN_FA.md) ستون‌ها، اتصال‌ها، fixture، قیود و محدودیت‌ها را ثبت می‌کنند. rollback اجرایی و آزمایش مجوزها به 2C–2G و تصویب بعدی تعلق دارند؛ این بسته هیچ DROP یا cleanup پایگاه ندارد.
