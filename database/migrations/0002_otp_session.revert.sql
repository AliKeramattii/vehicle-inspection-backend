-- BAZDID migration 0002_otp_session (revert) — Checkpoint 3.
-- فقط سه جدول 0002 و ردیف تاریخچهٔ همان migration را حذف می‌کند؛ اشیای 0001 دست‌نخورده می‌مانند.
-- حفظ داده: وجود ردیف، migration بعدی یا وابستگی بیرونی، rollback را متوقف می‌کند. فقط روی BAZDID_MigrationTest.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @AllowDdl bit = 0;
DECLARE @ApprovalReference nvarchar(128) = NULL;
DECLARE @MigrationId nvarchar(64) = N'0002_otp_session';
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
    IF EXISTS (SELECT 1 FROM dbo.BAZDIDSchemaMigrations WHERE MigrationId > @MigrationId)
        THROW 51111, 'BAZDID_REVERT_LATER_MIGRATION_PRESENT', 1;
    IF EXISTS (SELECT 1 FROM dbo.BAZDIDCustomerSessions WITH (TABLOCKX, HOLDLOCK))
       OR EXISTS (SELECT 1 FROM dbo.BAZDIDOtpChallenges WITH (TABLOCKX, HOLDLOCK))
       OR EXISTS (SELECT 1 FROM dbo.BAZDIDAuthRateCounters WITH (TABLOCKX, HOLDLOCK))
        THROW 51112, 'BAZDID_REVERT_DATA_PRESENT', 1;
    IF EXISTS (SELECT 1 FROM sys.foreign_keys fk
               WHERE fk.referenced_object_id IN (OBJECT_ID(N'dbo.BAZDIDOtpChallenges'), OBJECT_ID(N'dbo.BAZDIDCustomerSessions'), OBJECT_ID(N'dbo.BAZDIDAuthRateCounters'))
                 AND fk.parent_object_id NOT IN (OBJECT_ID(N'dbo.BAZDIDOtpChallenges'), OBJECT_ID(N'dbo.BAZDIDCustomerSessions'), OBJECT_ID(N'dbo.BAZDIDAuthRateCounters')))
       OR EXISTS (SELECT 1 FROM sys.sql_expression_dependencies d JOIN sys.objects o ON o.object_id = d.referencing_id
               WHERE d.referenced_id IN (OBJECT_ID(N'dbo.BAZDIDOtpChallenges'), OBJECT_ID(N'dbo.BAZDIDCustomerSessions'), OBJECT_ID(N'dbo.BAZDIDAuthRateCounters'))
                 AND o.object_id NOT IN (OBJECT_ID(N'dbo.BAZDIDOtpChallenges'), OBJECT_ID(N'dbo.BAZDIDCustomerSessions'), OBJECT_ID(N'dbo.BAZDIDAuthRateCounters'))
                 AND o.parent_object_id NOT IN (OBJECT_ID(N'dbo.BAZDIDOtpChallenges'), OBJECT_ID(N'dbo.BAZDIDCustomerSessions'), OBJECT_ID(N'dbo.BAZDIDAuthRateCounters')))
        THROW 51113, 'BAZDID_REVERT_EXTERNAL_DEPENDENCY', 1;
    DROP TABLE dbo.BAZDIDCustomerSessions;
    DROP TABLE dbo.BAZDIDOtpChallenges;
    DROP TABLE dbo.BAZDIDAuthRateCounters;
    DELETE FROM dbo.BAZDIDSchemaMigrations WHERE MigrationId = @MigrationId;
    COMMIT TRANSACTION;
    SELECT @MigrationId AS MigrationId, 'Reverted' AS Result;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
