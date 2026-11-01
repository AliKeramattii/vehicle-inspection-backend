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
   OR @TestDatabase <> N'BAZDID_Development' OR @ExpectedInstance <> N'SQLSERVER2019'
   OR COALESCE(CONVERT(int,SERVERPROPERTY('ProductMajorVersion')),0) <> 15
   OR COALESCE(IS_SRVROLEMEMBER('sysadmin'), 0) <> 1
   OR COALESCE(CONVERT(nvarchar(128), SERVERPROPERTY('InstanceName')), N'') <> @ExpectedInstance
   OR COALESCE(CONVERT(nvarchar(128), CONNECTIONPROPERTY('net_transport')), N'') <> N'Shared memory'
   OR CONVERT(int, SERVERPROPERTY('IsClustered')) <> 0
   OR CONVERT(int, SERVERPROPERTY('IsHadrEnabled')) <> 0
   OR EXISTS (SELECT 1 FROM sys.servers WHERE is_linked = 1)
   OR EXISTS (SELECT 1 FROM sys.databases WHERE database_id > 4 AND name <> @TestDatabase)
   OR EXISTS (SELECT 1 FROM model.sys.objects WHERE is_ms_shipped = 0)
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
DECLARE @DataDirectory nvarchar(4000) = CONVERT(nvarchar(4000),SERVERPROPERTY('InstanceDefaultDataPath'));
DECLARE @LogDirectory nvarchar(4000) = CONVERT(nvarchar(4000),SERVERPROPERTY('InstanceDefaultLogPath'));
IF @DataDirectory IS NULL OR @LogDirectory IS NULL OR @@TRANCOUNT <> 0
   OR EXISTS (SELECT 1 FROM sys.master_files WHERE database_id=3 AND size>2048)
BEGIN
    RAISERROR(N'مسیر فایل، اندازهٔ model یا وضعیت transaction قابل تأیید نیست.',16,1);
    RETURN;
END;
-- ظرفیت و عدم وجود فایل‌های مقصد در ابزار محلی پیش از اجرا دوباره کنترل می‌شوند.
DECLARE @DataFile nvarchar(4000) = @DataDirectory + N'BAZDID_Development.mdf';
DECLARE @LogFile nvarchar(4000) = @LogDirectory + N'BAZDID_Development_log.ldf';
-- CREATE DATABASE خارج transaction است؛ حذف/جایگزینی خودکار پایگاه موجود انجام نمی‌شود.
DECLARE @Sql nvarchar(max) = N'CREATE DATABASE ' + QUOTENAME(@TestDatabase)
 + N' ON PRIMARY (NAME=N''BAZDID_Development'',FILENAME=N''' + REPLACE(@DataFile,N'''',N'''''')
 + N''',SIZE=16MB,FILEGROWTH=16MB,MAXSIZE=512MB)'
 + N' LOG ON (NAME=N''BAZDID_Development_log'',FILENAME=N''' + REPLACE(@LogFile,N'''',N'''''')
 + N''',SIZE=16MB,FILEGROWTH=16MB,MAXSIZE=256MB) COLLATE ' + @TestCollation + N';';
EXEC sys.sp_executesql @Sql;
SET @Sql = N'ALTER DATABASE ' + QUOTENAME(@TestDatabase) + N' SET COMPATIBILITY_LEVEL = 150;';
EXEC sys.sp_executesql @Sql;
SET @Sql = N'ALTER DATABASE ' + QUOTENAME(@TestDatabase) + N' SET RECOVERY SIMPLE;';
EXEC sys.sp_executesql @Sql;
