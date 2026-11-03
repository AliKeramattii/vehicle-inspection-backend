-- پیش‌نویس اصلاح‌شدهٔ 2F؛ اجرا نشده است. ایجاد حساب Windows/login در این فایل وجود ندارد.
-- مجوز بعدی باید نام دو حساب، SIDهای تازه‌تأییدشده، مقصد و همین نسخهٔ script را مشخص کند.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @AllowDdl bit = 0;
DECLARE @ApprovalReference nvarchar(128) = NULL;
DECLARE @TestDatabase sysname = N'BAZDID_Development';
DECLARE @ExpectedMachine sysname = NULL;
DECLARE @ReaderLogin sysname = NULL;
DECLARE @WriterLogin sysname = NULL;
DECLARE @ExpectedReaderSid varbinary(85) = NULL;
DECLARE @ExpectedWriterSid varbinary(85) = NULL;
IF COALESCE(@AllowDdl, 0) <> 1 OR NULLIF(LTRIM(RTRIM(@ApprovalReference)), N'') IS NULL
BEGIN
    RAISERROR(N'تغییر مجوز بسته است؛ مقصد، دو حساب و script باید تصویب شوند.', 16, 1);
    RETURN;
END;
IF DB_NAME() <> @TestDatabase OR DB_ID() <= 4
   OR @TestDatabase IS NULL OR @TestDatabase NOT LIKE N'BAZDID[_]%'
   OR @ExpectedMachine IS NULL
   OR CONVERT(nvarchar(128), SERVERPROPERTY('MachineName')) <> @ExpectedMachine
   OR CONVERT(int, SERVERPROPERTY('ProductMajorVersion')) <> 15
   OR COALESCE(IS_SRVROLEMEMBER('sysadmin'), 0) <> 1
   OR CONVERT(int, SERVERPROPERTY('IsClustered')) <> 0
   OR CONVERT(int, SERVERPROPERTY('IsHadrEnabled')) <> 0
   OR COALESCE(CONVERT(nvarchar(128), SERVERPROPERTY('InstanceName')), N'') <> N'SQLSERVER2019'
   OR COALESCE(CONVERT(nvarchar(128), CONNECTIONPROPERTY('net_transport')), N'') <> N'Shared memory'
   OR COALESCE(CONVERT(nvarchar(128), CONNECTIONPROPERTY('auth_scheme')), N'') NOT IN (N'NTLM',N'KERBEROS')
   OR EXISTS (SELECT 1 FROM sys.servers WHERE is_linked = 1)
   OR EXISTS (SELECT 1 FROM sys.databases WHERE database_id > 4 AND name <> @TestDatabase)
   OR @ReaderLogin IS NULL OR @WriterLogin IS NULL OR @ReaderLogin = @WriterLogin
   OR @ReaderLogin <> @ExpectedMachine + N'\BAZDIDDevReader'
   OR @WriterLogin <> @ExpectedMachine + N'\BAZDIDDevWriter'
   OR @ExpectedReaderSid IS NULL OR @ExpectedWriterSid IS NULL OR @ExpectedReaderSid = @ExpectedWriterSid
   OR NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @ReaderLogin AND type = 'U' AND sid = @ExpectedReaderSid AND is_disabled = 0)
   OR NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @WriterLogin AND type = 'U' AND sid = @ExpectedWriterSid AND is_disabled = 0)
   OR COALESCE(IS_SRVROLEMEMBER('sysadmin', @ReaderLogin), 1) <> 0
   OR COALESCE(IS_SRVROLEMEMBER('sysadmin', @WriterLogin), 1) <> 0
   OR USER_ID(@ReaderLogin) IS NOT NULL OR USER_ID(@WriterLogin) IS NOT NULL
   OR DATABASE_PRINCIPAL_ID(N'BAZDIDSourceReader') IS NOT NULL
   OR DATABASE_PRINCIPAL_ID(N'BAZDIDWriter') IS NOT NULL
   OR OBJECT_ID(N'dbo.BAZDIDCustomerLinks', N'U') IS NULL
   OR OBJECT_ID(N'dbo.BAZDIDRequestContexts', N'U') IS NULL
   OR OBJECT_ID(N'dbo.BAZDIDAuditLogs', N'U') IS NULL
BEGIN
    RAISERROR(N'پیش‌شرط تست، جدول‌ها یا حساب‌های تازه و کم‌اختیار برقرار نیست.', 16, 1);
    RETURN;
END;
-- هیچ مبدأ واقعی یا ساختگی تصویب نشده است؛ این نسخه هیچ مجوز SELECT مبدأ صادر نمی‌کند.
BEGIN TRY
    BEGIN TRANSACTION;
    CREATE ROLE BAZDIDSourceReader AUTHORIZATION dbo;
    CREATE ROLE BAZDIDWriter AUTHORIZATION dbo;
    DECLARE @Sql nvarchar(max) = N'CREATE USER ' + QUOTENAME(@ReaderLogin) + N' FOR LOGIN ' + QUOTENAME(@ReaderLogin) + N';'
        + N'CREATE USER ' + QUOTENAME(@WriterLogin) + N' FOR LOGIN ' + QUOTENAME(@WriterLogin) + N';'
        + N'ALTER ROLE BAZDIDSourceReader ADD MEMBER ' + QUOTENAME(@ReaderLogin) + N';'
        + N'ALTER ROLE BAZDIDWriter ADD MEMBER ' + QUOTENAME(@WriterLogin) + N';';
    EXEC sys.sp_executesql @Sql;
    GRANT SELECT, INSERT ON OBJECT::dbo.BAZDIDCustomerLinks TO BAZDIDWriter;
    DENY UPDATE, DELETE, ALTER ON OBJECT::dbo.BAZDIDCustomerLinks TO BAZDIDWriter;
    GRANT SELECT, INSERT, UPDATE ON OBJECT::dbo.BAZDIDRequestContexts TO BAZDIDWriter;
    DENY DELETE, ALTER ON OBJECT::dbo.BAZDIDRequestContexts TO BAZDIDWriter;
    GRANT INSERT ON OBJECT::dbo.BAZDIDAuditLogs TO BAZDIDWriter;
    DENY SELECT, UPDATE, DELETE, ALTER ON OBJECT::dbo.BAZDIDAuditLogs TO BAZDIDWriter;
    DENY SELECT, INSERT, UPDATE, DELETE, ALTER ON OBJECT::dbo.BAZDIDCustomerLinks TO BAZDIDSourceReader;
    DENY SELECT, INSERT, UPDATE, DELETE, ALTER ON OBJECT::dbo.BAZDIDRequestContexts TO BAZDIDSourceReader;
    DENY SELECT, INSERT, UPDATE, DELETE, ALTER ON OBJECT::dbo.BAZDIDAuditLogs TO BAZDIDSourceReader;
    DENY CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE FUNCTION, CREATE SCHEMA TO BAZDIDWriter;
    DENY CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE FUNCTION, CREATE SCHEMA TO BAZDIDSourceReader;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
-- نقش خواننده هیچ SELECT مبدأ ندارد؛ موفقیت ساخت نقش، تأیید adapter یا effective permission نیست.
-- عضویت‌های ارثی Windows/public و مجوز مؤثر هر حساب باید جداگانه آزموده شوند.
