-- پیش‌نویس بازبینی‌شدهٔ GRANT برای جدول‌های migration 0002 (Checkpoint 3) — اجرا نشده است.
-- پیش‌شرط: 0002_otp_session روی BAZDID_Development اعمال و در BAZDIDSchemaMigrations ثبت شده باشد، و نقش‌های P2 موجود باشند.
-- حداقل اختیار: Writer فقط SELECT/INSERT/UPDATE روی سه جدول تازه؛ DELETE و ALTER صریحاً DENY. خواننده هیچ دسترسی ندارد.
-- هیچ login، user، عضویت یا server role تازه‌ای ساخته نمی‌شود. اجرای این فایل مجوز جدا با مرجع تصویب لازم دارد.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @AllowDdl bit = 0;
DECLARE @ApprovalReference nvarchar(128) = NULL;
IF COALESCE(@AllowDdl, 0) <> 1 OR NULLIF(LTRIM(RTRIM(@ApprovalReference)), N'') IS NULL
BEGIN
    RAISERROR(N'تغییر مجوز 0002 بسته است؛ مرجع تصویب جدا لازم است.', 16, 1);
    RETURN;
END;
IF DB_NAME() <> N'BAZDID_Development'
   OR COALESCE(CONVERT(nvarchar(128), SERVERPROPERTY('InstanceName')), N'') <> N'SQLSERVER2019'
   OR COALESCE(IS_SRVROLEMEMBER('sysadmin'), 0) <> 1
   OR COALESCE(CONVERT(nvarchar(128), CONNECTIONPROPERTY('net_transport')), N'') <> N'Shared memory'
   OR NOT EXISTS (SELECT 1 FROM dbo.BAZDIDSchemaMigrations WHERE MigrationId = N'0002_otp_session')
   OR DATABASE_PRINCIPAL_ID(N'BAZDIDWriter') IS NULL OR DATABASE_PRINCIPAL_ID(N'BAZDIDSourceReader') IS NULL
   OR OBJECT_ID(N'dbo.BAZDIDOtpChallenges', N'U') IS NULL OR OBJECT_ID(N'dbo.BAZDIDCustomerSessions', N'U') IS NULL
   OR OBJECT_ID(N'dbo.BAZDIDAuthRateCounters', N'U') IS NULL
BEGIN
    RAISERROR(N'پیش‌شرط مقصد، migration 0002 یا نقش‌های P2 برقرار نیست.', 16, 1);
    RETURN;
END;
BEGIN TRY
    BEGIN TRANSACTION;
    GRANT SELECT, INSERT, UPDATE ON OBJECT::dbo.BAZDIDOtpChallenges TO BAZDIDWriter;
    DENY DELETE, ALTER ON OBJECT::dbo.BAZDIDOtpChallenges TO BAZDIDWriter;
    GRANT SELECT, INSERT, UPDATE ON OBJECT::dbo.BAZDIDCustomerSessions TO BAZDIDWriter;
    DENY DELETE, ALTER ON OBJECT::dbo.BAZDIDCustomerSessions TO BAZDIDWriter;
    GRANT SELECT, INSERT, UPDATE ON OBJECT::dbo.BAZDIDAuthRateCounters TO BAZDIDWriter;
    DENY DELETE, ALTER ON OBJECT::dbo.BAZDIDAuthRateCounters TO BAZDIDWriter;
    DENY SELECT, INSERT, UPDATE, DELETE, ALTER ON OBJECT::dbo.BAZDIDOtpChallenges TO BAZDIDSourceReader;
    DENY SELECT, INSERT, UPDATE, DELETE, ALTER ON OBJECT::dbo.BAZDIDCustomerSessions TO BAZDIDSourceReader;
    DENY SELECT, INSERT, UPDATE, DELETE, ALTER ON OBJECT::dbo.BAZDIDAuthRateCounters TO BAZDIDSourceReader;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
-- انتظار پس از اجرا: ۳۰ ردیف مجوز تازه (Writer: ۹ GRANT + ۶ DENY؛ Reader: ۱۵ DENY)؛ کاتالوگ P2 از ۴۰ به ۷۰.
-- مجوز مؤثر Writer روی هر جدول: SELECT/INSERT/UPDATE=1، DELETE/ALTER=0؛ Reader: همه ۰. CONTROL/DDL بدون تغییر ۰.
