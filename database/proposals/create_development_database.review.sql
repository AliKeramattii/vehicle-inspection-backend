-- پیش‌نویس برای بازبینی؛ هیچ مجوز اجرایی از نام فایل یا وجود آن ایجاد نمی‌شود.
SET NOCOUNT ON;
DECLARE @AllowDdl bit = 0;
DECLARE @ApprovalReference nvarchar(128) = NULL;
DECLARE @ExpectedInstance sysname = N'SQLSERVER2019';
DECLARE @TestDatabase sysname = N'BAZDID_Development';
DECLARE @TestCollation sysname = N'SQL_Latin1_General_CP1_CI_AS';
DECLARE @CompatibilityLevel int = 150;
IF COALESCE(@AllowDdl, 0) <> 1 OR NULLIF(LTRIM(RTRIM(@ApprovalReference)), N'') IS NULL
BEGIN
    RAISERROR(N'اجرای DDL بسته است؛ تصویب صریح و بازبینی مقصد لازم است.', 16, 1);
    RETURN;
END;
IF DB_NAME() <> N'master'
   OR @TestDatabase IS NULL OR @ExpectedInstance IS NULL
   OR COALESCE(IS_SRVROLEMEMBER('sysadmin'), 0) <> 1
   OR COALESCE(CONVERT(nvarchar(128), SERVERPROPERTY('InstanceName')), N'') <> @ExpectedInstance
   OR COALESCE(CONVERT(nvarchar(128), CONNECTIONPROPERTY('net_transport')), N'') <> N'Shared memory'
   OR CONVERT(int, SERVERPROPERTY('IsClustered')) <> 0
   OR CONVERT(int, SERVERPROPERTY('IsHadrEnabled')) <> 0
   OR EXISTS (SELECT 1 FROM sys.servers WHERE is_linked = 1)
   OR EXISTS (SELECT 1 FROM sys.databases WHERE database_id > 4 AND name <> @TestDatabase)
   OR @TestDatabase NOT LIKE N'BAZDID[_]%' OR LEN(@TestDatabase) > 128
   OR @CompatibilityLevel <> 150
   OR NOT EXISTS (SELECT 1 FROM sys.fn_helpcollations() WHERE name = @TestCollation)
   OR @TestCollation COLLATE Latin1_General_100_BIN2 LIKE N'%[^A-Za-z0-9_]%'
BEGIN
    RAISERROR(N'پیش‌شرط instance محلیِ جدا، نام تست، collation یا compatibility برقرار نیست.', 16, 1);
    RETURN;
END;
IF DB_ID(@TestDatabase) IS NOT NULL
BEGIN
    RAISERROR(N'پایگاه از قبل وجود دارد؛ به‌جای تغییر خودکار، metadata و مالکیت آن بازبینی شود.', 16, 1);
    RETURN;
END;
-- CREATE DATABASE در transaction صریح اجرا نمی‌شود؛ این پیش‌نویس حذف خودکار ندارد.
DECLARE @Sql nvarchar(max) = N'CREATE DATABASE ' + QUOTENAME(@TestDatabase) + N' COLLATE ' + @TestCollation + N';';
EXEC sys.sp_executesql @Sql;
SET @Sql = N'ALTER DATABASE ' + QUOTENAME(@TestDatabase) + N' SET COMPATIBILITY_LEVEL = 150;';
EXEC sys.sp_executesql @Sql;
-- recovery و اندازه/مسیر فایل‌ها قبل از تصویب با DBA تعیین شوند؛ model معتبر پیش‌نیاز است.
