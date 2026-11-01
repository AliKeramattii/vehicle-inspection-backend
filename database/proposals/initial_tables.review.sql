-- فقط پیش‌نویس سه جدول برای تست محلی؛ migration یا قرارداد Production نیست.
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
SET NUMERIC_ROUNDABORT OFF;
DECLARE @AllowDdl bit = 0;
DECLARE @ApprovalReference nvarchar(128) = NULL;
DECLARE @ExpectedInstance sysname = N'SQLSERVER2019';
DECLARE @TestDatabase sysname = N'BAZDID_Development';
IF COALESCE(@AllowDdl, 0) <> 1 OR NULLIF(LTRIM(RTRIM(@ApprovalReference)), N'') IS NULL
BEGIN
    RAISERROR(N'ایجاد جدول بسته است؛ schema و مجوز اجرا باید جداگانه تصویب شوند.', 16, 1);
    RETURN;
END;
IF DB_NAME() <> @TestDatabase OR DB_ID() <= 4 OR @TestDatabase NOT LIKE N'BAZDID[_]%'
   OR @TestDatabase IS NULL OR @ExpectedInstance IS NULL
   OR COALESCE(IS_SRVROLEMEMBER('sysadmin'), 0) <> 1
   OR CONVERT(int, SERVERPROPERTY('IsClustered')) <> 0
   OR CONVERT(int, SERVERPROPERTY('IsHadrEnabled')) <> 0
   OR COALESCE(CONVERT(nvarchar(128), SERVERPROPERTY('InstanceName')), N'') <> @ExpectedInstance
   OR COALESCE(CONVERT(nvarchar(128), CONNECTIONPROPERTY('net_transport')), N'') <> N'Shared memory'
   OR EXISTS (SELECT 1 FROM sys.servers WHERE is_linked = 1)
   OR EXISTS (SELECT 1 FROM sys.databases WHERE database_id > 4 AND name <> @TestDatabase)
   OR EXISTS (SELECT 1 FROM sys.tables WHERE is_ms_shipped = 0)
   OR NOT EXISTS (SELECT 1 FROM sys.databases WHERE database_id = DB_ID()
                 AND compatibility_level = 150 AND collation_name = N'SQL_Latin1_General_CP1_CI_AS')
BEGIN
    RAISERROR(N'پایگاه خالیِ تست با مقصد و metadata بازبینی‌شده لازم است.', 16, 1);
    RETURN;
END;
-- dbo فقط پیشنهاد این تست محلی است؛ schema کارگزاری هنوز تصمیم DBA است.
BEGIN TRY
    BEGIN TRANSACTION;
    CREATE TABLE dbo.BAZDIDCustomerLinks (
        Id uniqueidentifier NOT NULL,
        BrokerageId nvarchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL,
        SourceSystem nvarchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL,
        SourceCustomerId nvarchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,
        SourceCustomerIdKey AS CONVERT(varbinary(256), SourceCustomerId) PERSISTED,
        CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_BAZDIDCustomerLinks_Created DEFAULT SYSUTCDATETIME(),
        UpdatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_BAZDIDCustomerLinks_Updated DEFAULT SYSUTCDATETIME(),
        RowVersion rowversion NOT NULL,
        CONSTRAINT PK_BAZDIDCustomerLinks PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_BAZDIDCustomerLinks_Source UNIQUE (BrokerageId, SourceSystem, SourceCustomerIdKey),
        CONSTRAINT UQ_BAZDIDCustomerLinks_TenantId UNIQUE (BrokerageId, SourceSystem, Id),
        CONSTRAINT CK_BAZDIDCustomerLinks_Source CHECK (DATALENGTH(SourceCustomerId) > 0),
        CONSTRAINT CK_BAZDIDCustomerLinks_Tenant CHECK (
            LEN(BrokerageId) > 0 AND BrokerageId NOT LIKE N'%[^A-Za-z0-9_-]%'
            AND LEN(SourceSystem) > 0 AND SourceSystem NOT LIKE N'%[^A-Za-z0-9_-]%'),
        CONSTRAINT CK_BAZDIDCustomerLinks_Time CHECK (UpdatedAtUtc >= CreatedAtUtc)
    );
    CREATE TABLE dbo.BAZDIDRequestContexts (
        Id uniqueidentifier NOT NULL,
        BrokerageId nvarchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL,
        SourceSystem nvarchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL,
        CustomerLinkId uniqueidentifier NOT NULL,
        SourceRequestId nvarchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,
        SourceRequestIdKey AS CONVERT(varbinary(256), SourceRequestId) PERSISTED,
        ReferralLookupHmac binary(32) NULL,
        ReferralKeyId varchar(32) NULL,
        IdentityHmac binary(32) NULL,
        IdentityKeyId varchar(32) NULL,
        PreviousIdentityHmac binary(32) NULL,
        PreviousIdentityKeyId varchar(32) NULL,
        EligibilityStatus varchar(16) NOT NULL,
        SourceVersion nvarchar(128) NULL,
        SourceRetrievedAtUtc datetime2(3) NOT NULL,
        CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_BAZDIDRequestContexts_Created DEFAULT SYSUTCDATETIME(),
        UpdatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_BAZDIDRequestContexts_Updated DEFAULT SYSUTCDATETIME(),
        RowVersion rowversion NOT NULL,
        CONSTRAINT PK_BAZDIDRequestContexts PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_BAZDIDRequestContexts_Source UNIQUE (BrokerageId, SourceSystem, SourceRequestIdKey),
        CONSTRAINT FK_BAZDIDRequestContexts_Customer FOREIGN KEY (BrokerageId, SourceSystem, CustomerLinkId)
            REFERENCES dbo.BAZDIDCustomerLinks (BrokerageId, SourceSystem, Id),
        CONSTRAINT CK_BAZDIDRequestContexts_Source CHECK (DATALENGTH(SourceRequestId) > 0),
        CONSTRAINT CK_BAZDIDRequestContexts_Tenant CHECK (
            LEN(BrokerageId) > 0 AND BrokerageId NOT LIKE N'%[^A-Za-z0-9_-]%'
            AND LEN(SourceSystem) > 0 AND SourceSystem NOT LIKE N'%[^A-Za-z0-9_-]%'),
        CONSTRAINT CK_BAZDIDRequestContexts_Eligibility CHECK (EligibilityStatus IN ('Eligible', 'Ineligible', 'Unknown')),
        CONSTRAINT CK_BAZDIDRequestContexts_Referral CHECK (
            (ReferralLookupHmac IS NULL AND ReferralKeyId IS NULL) OR (ReferralLookupHmac IS NOT NULL AND ReferralKeyId IS NOT NULL)),
        CONSTRAINT CK_BAZDIDRequestContexts_Identity CHECK (
            (IdentityHmac IS NULL AND IdentityKeyId IS NULL) OR (IdentityHmac IS NOT NULL AND IdentityKeyId IS NOT NULL)),
        CONSTRAINT CK_BAZDIDRequestContexts_PreviousIdentity CHECK (
            (PreviousIdentityHmac IS NULL AND PreviousIdentityKeyId IS NULL) OR (PreviousIdentityHmac IS NOT NULL AND PreviousIdentityKeyId IS NOT NULL)),
        CONSTRAINT CK_BAZDIDRequestContexts_Time CHECK (UpdatedAtUtc >= CreatedAtUtc)
    );
    CREATE INDEX IX_BAZDIDRequestContexts_Customer ON dbo.BAZDIDRequestContexts (CustomerLinkId);
    -- یکتایی referral تا تعیین قرارداد واقعی فرض نمی‌شود؛ نتیجهٔ چندگانه باید Ambiguous بماند.
    CREATE INDEX IX_BAZDIDRequestContexts_Referral ON dbo.BAZDIDRequestContexts
        (BrokerageId, SourceSystem, ReferralKeyId, ReferralLookupHmac)
        WHERE ReferralLookupHmac IS NOT NULL;
    CREATE TABLE dbo.BAZDIDAuditLogs (
        Id bigint IDENTITY(1,1) NOT NULL,
        OccurredAtUtc datetime2(3) NOT NULL CONSTRAINT DF_BAZDIDAuditLogs_Occurred DEFAULT SYSUTCDATETIME(),
        BrokerageId nvarchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL,
        SourceSystem nvarchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL,
        RequestContextId uniqueidentifier NULL,
        ActorType varchar(16) NOT NULL,
        ActorId uniqueidentifier NULL,
        ActionCode varchar(64) NOT NULL,
        OutcomeCode varchar(32) NOT NULL,
        ResourceType varchar(32) NOT NULL,
        ResourceId uniqueidentifier NULL,
        CorrelationId char(32) NOT NULL,
        MetadataCode varchar(64) NULL,
        CONSTRAINT PK_BAZDIDAuditLogs PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT CK_BAZDIDAuditLogs_Tenant CHECK (
            LEN(BrokerageId) > 0 AND BrokerageId NOT LIKE N'%[^A-Za-z0-9_-]%'
            AND LEN(SourceSystem) > 0 AND SourceSystem NOT LIKE N'%[^A-Za-z0-9_-]%'),
        CONSTRAINT CK_BAZDIDAuditLogs_Actor CHECK (ActorType IN ('System', 'Anonymous', 'Customer', 'Staff')),
        CONSTRAINT CK_BAZDIDAuditLogs_Correlation CHECK (
            CorrelationId COLLATE Latin1_General_100_BIN2 NOT LIKE '%[^0-9a-f]%' AND LEN(CorrelationId) = 32)
    );
    CREATE INDEX IX_BAZDIDAuditLogs_RequestTime ON dbo.BAZDIDAuditLogs (RequestContextId, OccurredAtUtc, Id);
    CREATE INDEX IX_BAZDIDAuditLogs_Correlation ON dbo.BAZDIDAuditLogs (CorrelationId);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
