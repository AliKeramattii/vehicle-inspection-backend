-- اصلاح ریشهٔ خطای CHECK در همین اجرای 2C؛ فقط سه قید موجودِ جدول‌های مصوب و پایگاه خالی.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @AllowDdl bit = 0;
DECLARE @ApprovalReference nvarchar(128) = NULL;
IF COALESCE(@AllowDdl,0)<>1 OR NULLIF(LTRIM(RTRIM(@ApprovalReference)),N'') IS NULL
BEGIN
 RAISERROR(N'اصلاح CHECK بدون تصویب و بازبینی مجاز نیست.',16,1);
 RETURN;
END;
IF DB_NAME()<>N'BAZDID_Development'
 OR COALESCE(CONVERT(nvarchar(128),SERVERPROPERTY('InstanceName')),N'')<>N'SQLSERVER2019'
 OR COALESCE(CONVERT(int,SERVERPROPERTY('ProductMajorVersion')),0)<>15
 OR COALESCE(CONVERT(nvarchar(128),CONNECTIONPROPERTY('net_transport')),N'')<>N'Shared memory'
 OR COALESCE(IS_SRVROLEMEMBER('sysadmin'),0)<>1
 OR COALESCE(CONVERT(int,SERVERPROPERTY('IsClustered')),1)<>0
 OR COALESCE(CONVERT(int,SERVERPROPERTY('IsHadrEnabled')),1)<>0
 OR EXISTS (SELECT 1 FROM sys.servers WHERE is_linked=1)
 OR EXISTS (SELECT 1 FROM sys.databases WHERE database_id>4 AND name<>N'BAZDID_Development')
 OR (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0)<>3
 OR EXISTS (SELECT 1 FROM dbo.BAZDIDCustomerLinks)
 OR EXISTS (SELECT 1 FROM dbo.BAZDIDRequestContexts)
 OR EXISTS (SELECT 1 FROM dbo.BAZDIDAuditLogs)
BEGIN
 RAISERROR(N'مقصد یا خالی‌بودن سه جدول تأیید نشد؛ اصلاح متوقف شد.',16,1);
 RETURN;
END;
BEGIN TRY
 BEGIN TRANSACTION;
 ALTER TABLE dbo.BAZDIDCustomerLinks DROP CONSTRAINT CK_BAZDIDCustomerLinks_Tenant;
 ALTER TABLE dbo.BAZDIDCustomerLinks WITH CHECK ADD CONSTRAINT CK_BAZDIDCustomerLinks_Tenant CHECK (
  LEN(BrokerageId)>0 AND REPLACE(BrokerageId,N'-',N'') NOT LIKE N'%[^A-Za-z0-9_]%'
  AND LEN(SourceSystem)>0 AND REPLACE(SourceSystem,N'-',N'') NOT LIKE N'%[^A-Za-z0-9_]%');
 ALTER TABLE dbo.BAZDIDRequestContexts DROP CONSTRAINT CK_BAZDIDRequestContexts_Tenant;
 ALTER TABLE dbo.BAZDIDRequestContexts WITH CHECK ADD CONSTRAINT CK_BAZDIDRequestContexts_Tenant CHECK (
  LEN(BrokerageId)>0 AND REPLACE(BrokerageId,N'-',N'') NOT LIKE N'%[^A-Za-z0-9_]%'
  AND LEN(SourceSystem)>0 AND REPLACE(SourceSystem,N'-',N'') NOT LIKE N'%[^A-Za-z0-9_]%');
 ALTER TABLE dbo.BAZDIDAuditLogs DROP CONSTRAINT CK_BAZDIDAuditLogs_Tenant;
 ALTER TABLE dbo.BAZDIDAuditLogs WITH CHECK ADD CONSTRAINT CK_BAZDIDAuditLogs_Tenant CHECK (
  LEN(BrokerageId)>0 AND REPLACE(BrokerageId,N'-',N'') NOT LIKE N'%[^A-Za-z0-9_]%'
  AND LEN(SourceSystem)>0 AND REPLACE(SourceSystem,N'-',N'') NOT LIKE N'%[^A-Za-z0-9_]%');
 COMMIT TRANSACTION;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
