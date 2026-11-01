-- پیش‌نویس نقش‌ها؛ هیچ login، رمز یا حساب Windows ساخته نمی‌شود.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @AllowDdl bit = 0;
DECLARE @ApprovalReference nvarchar(128) = NULL;
DECLARE @TestDatabase sysname = N'BAZDID_Development';
DECLARE @ReaderLogin sysname = NULL;
DECLARE @WriterLogin sysname = NULL;
DECLARE @SyntheticSourceSchema sysname = NULL;
DECLARE @SyntheticSourceTable sysname = NULL;
IF COALESCE(@AllowDdl, 0) <> 1 OR NULLIF(LTRIM(RTRIM(@ApprovalReference)), N'') IS NULL
BEGIN
    RAISERROR(N'تغییر مجوز بسته است؛ مقصد، دو حساب و script باید تصویب شوند.', 16, 1);
    RETURN;
END;
IF DB_NAME() <> @TestDatabase OR DB_ID() <= 4
   OR @TestDatabase IS NULL OR @TestDatabase NOT LIKE N'BAZDID[_]%'
   OR COALESCE(IS_SRVROLEMEMBER('sysadmin'), 0) <> 1
   OR CONVERT(int, SERVERPROPERTY('IsClustered')) <> 0
   OR CONVERT(int, SERVERPROPERTY('IsHadrEnabled')) <> 0
   OR COALESCE(CONVERT(nvarchar(128), SERVERPROPERTY('InstanceName')), N'') <> N'SQLSERVER2019'
   OR COALESCE(CONVERT(nvarchar(128), CONNECTIONPROPERTY('net_transport')), N'') <> N'Shared memory'
   OR EXISTS (SELECT 1 FROM sys.servers WHERE is_linked = 1)
   OR EXISTS (SELECT 1 FROM sys.databases WHERE database_id > 4 AND name <> @TestDatabase)
   OR @ReaderLogin IS NULL OR @WriterLogin IS NULL OR @ReaderLogin = @WriterLogin
   OR NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @ReaderLogin AND type IN ('U', 'G'))
   OR NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @WriterLogin AND type IN ('U', 'G'))
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
IF (@SyntheticSourceSchema IS NULL AND @SyntheticSourceTable IS NOT NULL)
   OR (@SyntheticSourceSchema IS NOT NULL AND @SyntheticSourceTable IS NULL)
BEGIN
    RAISERROR(N'نام schema و جدول ساختگی باید با هم تعیین شوند.', 16, 1);
    RETURN;
END;
DECLARE @SourceObject nvarchar(517) = QUOTENAME(@SyntheticSourceSchema) + N'.' + QUOTENAME(@SyntheticSourceTable);
IF @SourceObject IS NOT NULL AND
   (OBJECT_ID(@SourceObject, N'U') IS NULL OR @SyntheticSourceTable LIKE N'BAZDID%')
BEGIN
    RAISERROR(N'شیء مبدأ تست معتبر نیست؛ به جدول‌های BAZDID مجوز مبدأ داده نمی‌شود.', 16, 1);
    RETURN;
END;
BEGIN TRY
    BEGIN TRANSACTION;
    CREATE ROLE BAZDIDSourceReader AUTHORIZATION dbo;
    CREATE ROLE BAZDIDWriter AUTHORIZATION dbo;
    DECLARE @Sql nvarchar(max) = N'CREATE USER ' + QUOTENAME(@ReaderLogin) + N' FOR LOGIN ' + QUOTENAME(@ReaderLogin) + N';'
        + N'CREATE USER ' + QUOTENAME(@WriterLogin) + N' FOR LOGIN ' + QUOTENAME(@WriterLogin) + N';'
        + N'ALTER ROLE BAZDIDSourceReader ADD MEMBER ' + QUOTENAME(@ReaderLogin) + N';'
        + N'ALTER ROLE BAZDIDWriter ADD MEMBER ' + QUOTENAME(@WriterLogin) + N';';
    EXEC sys.sp_executesql @Sql;
    GRANT SELECT, INSERT, UPDATE ON OBJECT::dbo.BAZDIDCustomerLinks TO BAZDIDWriter;
    GRANT SELECT, INSERT, UPDATE ON OBJECT::dbo.BAZDIDRequestContexts TO BAZDIDWriter;
    GRANT INSERT ON OBJECT::dbo.BAZDIDAuditLogs TO BAZDIDWriter;
    DENY UPDATE, DELETE, ALTER ON OBJECT::dbo.BAZDIDAuditLogs TO BAZDIDWriter;
    IF @SourceObject IS NOT NULL
    BEGIN
        SET @Sql = N'GRANT SELECT ON OBJECT::' + @SourceObject + N' TO BAZDIDSourceReader;'
            + N'DENY INSERT, UPDATE, DELETE, ALTER ON OBJECT::' + @SourceObject + N' TO BAZDIDSourceReader;'
            + N'DENY SELECT, INSERT, UPDATE, DELETE, ALTER ON OBJECT::' + @SourceObject + N' TO BAZDIDWriter;';
        EXEC sys.sp_executesql @Sql;
    END;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
-- با مبدأ NULL نقش خواننده هنوز هیچ SELECT ندارد؛ موفقیت ایجاد نقش، تأیید adapter نیست.
-- عضویت‌های ارثی Windows/public و مجوز مؤثر هر حساب باید جداگانه آزموده شوند.
