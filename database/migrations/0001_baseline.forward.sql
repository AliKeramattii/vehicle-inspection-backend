-- BAZDID migration 0001_baseline (forward) — Checkpoint 2G.
-- فقط اشیای BAZDID؛ جدول مبدأ یا کارگزاری لمس نمی‌شود. فقط از طریق database/tools/Invoke-BazdidMigration.ps1 اجرا شود؛
-- ابزار مقصد دقیق را preflight می‌کند و @AllowDdl/@ApprovalReference/@MigrationChecksum را فقط در حافظه مقدار می‌دهد.
-- DDL سه جدول عیناً از database/proposals/initial_tables.review.sql (خطوط ۴۱ تا ۱۲۳، نسخهٔ نهایی 2C) است.
-- رفتار: (۱) ردیف هم‌checksum وجود دارد => no-op؛ (۲) checksum متفاوت => خطا؛ (۳) هیچ جدولی نیست => ساخت؛
-- (۴) هر سه جدول با امضای دقیق 2C (۳۹ ستون، CHECKSUM_AGG=1193879634) => فقط ثبت baseline (adopt)؛ (۵) حالت جزئی => خطا.
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
DECLARE @MigrationChecksum char(64) = NULL;
DECLARE @MigrationId nvarchar(64) = N'0001_baseline';
IF COALESCE(@AllowDdl, 0) <> 1 OR NULLIF(LTRIM(RTRIM(@ApprovalReference)), N'') IS NULL
   OR @MigrationChecksum IS NULL OR @MigrationChecksum COLLATE Latin1_General_100_BIN2 LIKE '%[^0-9A-F]%' OR LEN(@MigrationChecksum) <> 64
BEGIN
    RAISERROR(N'migration بسته است؛ فقط ابزار بازبینی‌شده با مجوز و checksum اجرا می‌کند.', 16, 1);
    RETURN;
END;
IF DB_NAME() NOT IN (N'BAZDID_MigrationTest', N'BAZDID_Development') OR DB_ID() <= 4
   OR COALESCE(CONVERT(nvarchar(128), SERVERPROPERTY('InstanceName')), N'') <> N'SQLSERVER2019'
   OR COALESCE(CONVERT(int, SERVERPROPERTY('ProductMajorVersion')), 0) <> 15
   OR COALESCE(IS_SRVROLEMEMBER('sysadmin'), 0) <> 1
   OR COALESCE(CONVERT(nvarchar(128), CONNECTIONPROPERTY('net_transport')), N'') <> N'Shared memory'
   OR NOT EXISTS (SELECT 1 FROM sys.databases WHERE database_id = DB_ID()
                  AND compatibility_level = 150 AND collation_name = N'SQL_Latin1_General_CP1_CI_AS')
BEGIN
    RAISERROR(N'مقصد migration با instance/پایگاه/metadata مصوب برابر نیست.', 16, 1);
    RETURN;
END;
BEGIN TRY
    BEGIN TRANSACTION;
    IF OBJECT_ID(N'dbo.BAZDIDSchemaMigrations', N'U') IS NULL
        CREATE TABLE dbo.BAZDIDSchemaMigrations (
            MigrationId nvarchar(64) COLLATE Latin1_General_100_BIN2 NOT NULL,
            Checksum char(64) COLLATE Latin1_General_100_BIN2 NOT NULL,
            AppliedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_BAZDIDSchemaMigrations_Applied DEFAULT SYSUTCDATETIME(),
            AppliedBy nvarchar(128) NOT NULL CONSTRAINT DF_BAZDIDSchemaMigrations_By DEFAULT ORIGINAL_LOGIN(),
            ApprovalReference nvarchar(128) NOT NULL,
            Mode varchar(16) NOT NULL,
            CONSTRAINT PK_BAZDIDSchemaMigrations PRIMARY KEY CLUSTERED (MigrationId),
            CONSTRAINT CK_BAZDIDSchemaMigrations_Checksum CHECK (LEN(Checksum) = 64 AND Checksum NOT LIKE '%[^0-9A-F]%'),
            CONSTRAINT CK_BAZDIDSchemaMigrations_Mode CHECK (Mode IN ('Created', 'Adopted'))
        );
    DECLARE @Existing char(64) = (SELECT Checksum FROM dbo.BAZDIDSchemaMigrations WITH (UPDLOCK, HOLDLOCK) WHERE MigrationId = @MigrationId);
    IF @Existing IS NOT NULL
    BEGIN
        IF @Existing <> @MigrationChecksum THROW 51101, 'BAZDID_MIGRATION_CHECKSUM_MISMATCH', 1;
        COMMIT TRANSACTION;
        SELECT @MigrationId AS MigrationId, 'AlreadyApplied' AS Result;
        RETURN;
    END;
    DECLARE @Present int = (SELECT COUNT(*) FROM sys.tables WHERE schema_id = SCHEMA_ID(N'dbo')
        AND name IN (N'BAZDIDCustomerLinks', N'BAZDIDRequestContexts', N'BAZDIDAuditLogs'));
    IF @Present = 3
    BEGIN
        DECLARE @Columns int, @Signature int;
        SELECT @Columns = COUNT(*), @Signature = CHECKSUM_AGG(CHECKSUM(t.name, c.name, c.column_id, c.system_type_id, c.max_length, c.is_nullable))
        FROM sys.columns c JOIN sys.tables t ON t.object_id = c.object_id
        WHERE t.name IN (N'BAZDIDCustomerLinks', N'BAZDIDRequestContexts', N'BAZDIDAuditLogs');
        IF @Columns <> 39 OR @Signature <> 1193879634 THROW 51102, 'BAZDID_BASELINE_SIGNATURE_MISMATCH', 1;
        INSERT dbo.BAZDIDSchemaMigrations (MigrationId, Checksum, ApprovalReference, Mode) VALUES (@MigrationId, @MigrationChecksum, @ApprovalReference, 'Adopted');
        COMMIT TRANSACTION;
        SELECT @MigrationId AS MigrationId, 'Adopted' AS Result;
        RETURN;
    END;
    IF @Present <> 0 THROW 51103, 'BAZDID_BASELINE_PARTIAL_STATE', 1;
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
                LEN(BrokerageId) > 0 AND REPLACE(BrokerageId,N'-',N'') NOT LIKE N'%[^A-Za-z0-9_]%'
                AND LEN(SourceSystem) > 0 AND REPLACE(SourceSystem,N'-',N'') NOT LIKE N'%[^A-Za-z0-9_]%'),
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
                LEN(BrokerageId) > 0 AND REPLACE(BrokerageId,N'-',N'') NOT LIKE N'%[^A-Za-z0-9_]%'
                AND LEN(SourceSystem) > 0 AND REPLACE(SourceSystem,N'-',N'') NOT LIKE N'%[^A-Za-z0-9_]%'),
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
                LEN(BrokerageId) > 0 AND REPLACE(BrokerageId,N'-',N'') NOT LIKE N'%[^A-Za-z0-9_]%'
                AND LEN(SourceSystem) > 0 AND REPLACE(SourceSystem,N'-',N'') NOT LIKE N'%[^A-Za-z0-9_]%'),
            CONSTRAINT CK_BAZDIDAuditLogs_Actor CHECK (ActorType IN ('System', 'Anonymous', 'Customer', 'Staff')),
            CONSTRAINT CK_BAZDIDAuditLogs_Correlation CHECK (
                CorrelationId COLLATE Latin1_General_100_BIN2 NOT LIKE '%[^0-9a-f]%' AND LEN(CorrelationId) = 32)
        );
        CREATE INDEX IX_BAZDIDAuditLogs_RequestTime ON dbo.BAZDIDAuditLogs (RequestContextId, OccurredAtUtc, Id);
        CREATE INDEX IX_BAZDIDAuditLogs_Correlation ON dbo.BAZDIDAuditLogs (CorrelationId);
    INSERT dbo.BAZDIDSchemaMigrations (MigrationId, Checksum, ApprovalReference, Mode) VALUES (@MigrationId, @MigrationChecksum, @ApprovalReference, 'Created');
    COMMIT TRANSACTION;
    SELECT @MigrationId AS MigrationId, 'Created' AS Result;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
