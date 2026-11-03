-- فقط پیشنهاد loginهای Windows محلی؛ مجوز اجرا یا ایجاد حساب Windows نیست.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @AllowDdl bit = 0;
DECLARE @ApprovalReference nvarchar(128) = NULL;
DECLARE @ExpectedMachine sysname = NULL;
DECLARE @WriterLogin sysname = NULL;
DECLARE @ReaderLogin sysname = NULL;
DECLARE @ExpectedWriterSid varbinary(85) = NULL;
DECLARE @ExpectedReaderSid varbinary(85) = NULL;
IF COALESCE(@AllowDdl,0) <> 1 OR NULLIF(LTRIM(RTRIM(@ApprovalReference)),N'') IS NULL
BEGIN
    RAISERROR(N'ایجاد login بسته است؛ نام/SID حساب‌ها و script باید جداگانه تصویب شوند.',16,1);
    RETURN;
END;
IF DB_NAME() <> N'master' OR COALESCE(IS_SRVROLEMEMBER('sysadmin'),0) <> 1
 OR @ExpectedMachine IS NULL OR CONVERT(nvarchar(128),SERVERPROPERTY('MachineName')) <> @ExpectedMachine
 OR CONVERT(nvarchar(128),SERVERPROPERTY('InstanceName')) <> N'SQLSERVER2019'
 OR CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) <> 15
 OR CONVERT(int,SERVERPROPERTY('IsClustered')) <> 0 OR CONVERT(int,SERVERPROPERTY('IsHadrEnabled')) <> 0
 OR COALESCE(CONVERT(nvarchar(128),CONNECTIONPROPERTY('net_transport')),N'') <> N'Shared memory'
 OR COALESCE(CONVERT(nvarchar(128),CONNECTIONPROPERTY('auth_scheme')),N'') NOT IN (N'NTLM',N'KERBEROS')
 OR EXISTS (SELECT 1 FROM sys.servers WHERE is_linked=1)
 OR EXISTS (SELECT 1 FROM sys.databases WHERE database_id>4 AND name<>N'BAZDID_Development')
 OR DB_ID(N'BAZDID_Development') IS NULL
 OR @WriterLogin IS NULL OR @ReaderLogin IS NULL OR @WriterLogin=@ReaderLogin
 OR @WriterLogin <> @ExpectedMachine + N'\BAZDIDDevWriter'
 OR @ReaderLogin <> @ExpectedMachine + N'\BAZDIDDevReader'
 OR @ExpectedWriterSid IS NULL OR @ExpectedReaderSid IS NULL OR @ExpectedWriterSid=@ExpectedReaderSid
 OR EXISTS (SELECT 1 FROM sys.server_principals WHERE name IN (@WriterLogin,@ReaderLogin) OR sid IN (@ExpectedWriterSid,@ExpectedReaderSid))
BEGIN
    RAISERROR(N'پیش‌شرط مقصد یا دو login تازهٔ مصوب برقرار نیست؛ هیچ تغییر اجرا نشد.',16,1);
    RETURN;
END;
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @Sql nvarchar(max)=N'CREATE LOGIN '+QUOTENAME(@WriterLogin)+N' FROM WINDOWS WITH DEFAULT_DATABASE=[BAZDID_Development];'
        +N'CREATE LOGIN '+QUOTENAME(@ReaderLogin)+N' FROM WINDOWS WITH DEFAULT_DATABASE=[BAZDID_Development];';
    EXEC sys.sp_executesql @Sql;
    IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name=@WriterLogin AND type='U' AND sid=@ExpectedWriterSid)
       OR NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name=@ReaderLogin AND type='U' AND sid=@ExpectedReaderSid)
       OR COALESCE(IS_SRVROLEMEMBER('sysadmin',@WriterLogin),1)<>0
       OR COALESCE(IS_SRVROLEMEMBER('sysadmin',@ReaderLogin),1)<>0
        THROW 51020,'BAZDID_PRINCIPAL_MISMATCH',1;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
-- هیچ SQL password، server-role grant یا Windows user ایجاد نمی‌شود.
-- تا اجرای جداگانهٔ permissions مصوب، این loginها user برنامه در پایگاه ندارند.
