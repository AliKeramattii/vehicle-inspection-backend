-- BAZDID migration 0001_baseline (revert) — Checkpoint 2G.
-- فقط سه جدول baseline و ردیف تاریخچهٔ همان migration را حذف می‌کند؛ جدول BAZDIDSchemaMigrations می‌ماند.
-- حفظ داده: اگر هر یک از سه جدول ردیف داشته باشد، migration بعدی ثبت شده باشد یا وابستگی بیرونی وجود داشته باشد، متوقف می‌شود.
-- فقط روی پایگاه یک‌بارمصرف BAZDID_MigrationTest اجرا می‌شود (guard)؛ هرگز روی BAZDID_Development.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @AllowDdl bit = 0;
DECLARE @ApprovalReference nvarchar(128) = NULL;
DECLARE @MigrationId nvarchar(64) = N'0001_baseline';
IF COALESCE(@AllowDdl, 0) <> 1 OR NULLIF(LTRIM(RTRIM(@ApprovalReference)), N'') IS NULL
BEGIN
    RAISERROR(N'rollback بسته است؛ فقط ابزار بازبینی‌شده با مجوز اجرا می‌کند.', 16, 1);
    RETURN;
END;
IF DB_NAME() <> N'BAZDID_MigrationTest'
   OR COALESCE(CONVERT(nvarchar(128), SERVERPROPERTY('InstanceName')), N'') <> N'SQLSERVER2019'
   OR COALESCE(IS_SRVROLEMEMBER('sysadmin'), 0) <> 1
   OR COALESCE(CONVERT(nvarchar(128), CONNECTIONPROPERTY('net_transport')), N'') <> N'Shared memory'
BEGIN
    RAISERROR(N'rollback فقط روی پایگاه یک‌بارمصرف BAZDID_MigrationTest مجاز است.', 16, 1);
    RETURN;
END;
BEGIN TRY
    BEGIN TRANSACTION;
    IF OBJECT_ID(N'dbo.BAZDIDSchemaMigrations', N'U') IS NULL
       OR NOT EXISTS (SELECT 1 FROM dbo.BAZDIDSchemaMigrations WITH (UPDLOCK, HOLDLOCK) WHERE MigrationId = @MigrationId)
    BEGIN
        COMMIT TRANSACTION;
        SELECT @MigrationId AS MigrationId, 'NotApplied' AS Result;
        RETURN;
    END;
    IF EXISTS (SELECT 1 FROM dbo.BAZDIDSchemaMigrations WHERE MigrationId <> @MigrationId)
        THROW 51111, 'BAZDID_REVERT_LATER_MIGRATION_PRESENT', 1;
    IF EXISTS (SELECT 1 FROM dbo.BAZDIDCustomerLinks WITH (TABLOCKX, HOLDLOCK))
       OR EXISTS (SELECT 1 FROM dbo.BAZDIDRequestContexts WITH (TABLOCKX, HOLDLOCK))
       OR EXISTS (SELECT 1 FROM dbo.BAZDIDAuditLogs WITH (TABLOCKX, HOLDLOCK))
        THROW 51112, 'BAZDID_REVERT_DATA_PRESENT', 1;
    IF EXISTS (SELECT 1 FROM sys.foreign_keys fk
               WHERE fk.referenced_object_id IN (OBJECT_ID(N'dbo.BAZDIDCustomerLinks'), OBJECT_ID(N'dbo.BAZDIDRequestContexts'), OBJECT_ID(N'dbo.BAZDIDAuditLogs'))
                 AND fk.parent_object_id NOT IN (OBJECT_ID(N'dbo.BAZDIDCustomerLinks'), OBJECT_ID(N'dbo.BAZDIDRequestContexts'), OBJECT_ID(N'dbo.BAZDIDAuditLogs')))
       -- وابستگی‌های درونی خود سه جدول (computed column و CHECK) بیرونی نیستند؛ فقط اشیای دیگر مانع‌اند.
       OR EXISTS (SELECT 1 FROM sys.sql_expression_dependencies d JOIN sys.objects o ON o.object_id = d.referencing_id
               WHERE d.referenced_id IN (OBJECT_ID(N'dbo.BAZDIDCustomerLinks'), OBJECT_ID(N'dbo.BAZDIDRequestContexts'), OBJECT_ID(N'dbo.BAZDIDAuditLogs'))
                 AND o.object_id NOT IN (OBJECT_ID(N'dbo.BAZDIDCustomerLinks'), OBJECT_ID(N'dbo.BAZDIDRequestContexts'), OBJECT_ID(N'dbo.BAZDIDAuditLogs'))
                 AND o.parent_object_id NOT IN (OBJECT_ID(N'dbo.BAZDIDCustomerLinks'), OBJECT_ID(N'dbo.BAZDIDRequestContexts'), OBJECT_ID(N'dbo.BAZDIDAuditLogs')))
        THROW 51113, 'BAZDID_REVERT_EXTERNAL_DEPENDENCY', 1;
    DROP TABLE dbo.BAZDIDAuditLogs;
    DROP TABLE dbo.BAZDIDRequestContexts;
    DROP TABLE dbo.BAZDIDCustomerLinks;
    DELETE FROM dbo.BAZDIDSchemaMigrations WHERE MigrationId = @MigrationId;
    COMMIT TRANSACTION;
    SELECT @MigrationId AS MigrationId, 'Reverted' AS Result;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
