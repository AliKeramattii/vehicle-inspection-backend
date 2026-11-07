-- BAZDID migration 0002_otp_session (forward) — Checkpoint 3.
-- اشیای تازه فقط با پیشوند BAZDID: BAZDIDOtpChallenges، BAZDIDCustomerSessions، BAZDIDAuthRateCounters.
-- هیچ handle، کد OTP یا موبایل خامی ذخیره نمی‌شود: فقط SHA-256 handle، MAC کد (با secret جدا) و hash nonce مرورگر.
-- پیش‌شرط نسخه: 0001_baseline باید ثبت شده باشد. اجرای تکراری با همان checksum no-op است؛ checksum متفاوت یا حالت جزئی خطاست.
-- فقط از طریق database/tools/Invoke-BazdidMigration.ps1؛ اجرا روی BAZDID_Development مجوز جدا لازم دارد.
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
DECLARE @MigrationId nvarchar(64) = N'0002_otp_session';
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
BEGIN
    RAISERROR(N'مقصد migration با instance/پایگاه مصوب برابر نیست.', 16, 1);
    RETURN;
END;
BEGIN TRY
    BEGIN TRANSACTION;
    IF OBJECT_ID(N'dbo.BAZDIDSchemaMigrations', N'U') IS NULL
       OR NOT EXISTS (SELECT 1 FROM dbo.BAZDIDSchemaMigrations WITH (UPDLOCK, HOLDLOCK) WHERE MigrationId = N'0001_baseline')
        THROW 51201, 'BAZDID_PREREQUISITE_0001_MISSING', 1;
    DECLARE @Existing char(64) = (SELECT Checksum FROM dbo.BAZDIDSchemaMigrations WITH (UPDLOCK, HOLDLOCK) WHERE MigrationId = @MigrationId);
    IF @Existing IS NOT NULL
    BEGIN
        IF @Existing <> @MigrationChecksum THROW 51101, 'BAZDID_MIGRATION_CHECKSUM_MISMATCH', 1;
        COMMIT TRANSACTION;
        SELECT @MigrationId AS MigrationId, 'AlreadyApplied' AS Result;
        RETURN;
    END;
    IF OBJECT_ID(N'dbo.BAZDIDOtpChallenges', N'U') IS NOT NULL OR OBJECT_ID(N'dbo.BAZDIDCustomerSessions', N'U') IS NOT NULL
       OR OBJECT_ID(N'dbo.BAZDIDAuthRateCounters', N'U') IS NOT NULL
        THROW 51103, 'BAZDID_0002_PARTIAL_STATE', 1;

    CREATE TABLE dbo.BAZDIDOtpChallenges (
        Id uniqueidentifier NOT NULL,
        HandleHash binary(32) NOT NULL,
        BrokerageId nvarchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL,
        SourceSystem nvarchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL,
        RequestContextId uniqueidentifier NOT NULL,
        BrowserNonceHash binary(32) NOT NULL,
        State varchar(16) NOT NULL,
        Generation int NOT NULL CONSTRAINT DF_BAZDIDOtpChallenges_Generation DEFAULT 0,
        CodeMac binary(32) NULL,
        CodeExpiresAtUtc datetime2(3) NULL,
        ContextExpiresAtUtc datetime2(3) NOT NULL,
        FailedAttempts int NOT NULL CONSTRAINT DF_BAZDIDOtpChallenges_Failed DEFAULT 0,
        LastSentAtUtc datetime2(3) NULL,
        SendWindowStartUtc datetime2(3) NULL,
        SendsInWindow int NOT NULL CONSTRAINT DF_BAZDIDOtpChallenges_Sends DEFAULT 0,
        ConsumedAtUtc datetime2(3) NULL,
        CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_BAZDIDOtpChallenges_Created DEFAULT SYSUTCDATETIME(),
        RowVersion rowversion NOT NULL,
        CONSTRAINT PK_BAZDIDOtpChallenges PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_BAZDIDOtpChallenges_Handle UNIQUE (HandleHash),
        CONSTRAINT FK_BAZDIDOtpChallenges_Context FOREIGN KEY (RequestContextId) REFERENCES dbo.BAZDIDRequestContexts (Id),
        CONSTRAINT CK_BAZDIDOtpChallenges_Tenant CHECK (
            LEN(BrokerageId) > 0 AND REPLACE(BrokerageId,N'-',N'') NOT LIKE N'%[^A-Za-z0-9_]%'
            AND LEN(SourceSystem) > 0 AND REPLACE(SourceSystem,N'-',N'') NOT LIKE N'%[^A-Za-z0-9_]%'),
        CONSTRAINT CK_BAZDIDOtpChallenges_State CHECK (State IN ('Resolved','PendingSend','Sent','Consumed','Expired','Locked','SendFailed','Superseded')),
        CONSTRAINT CK_BAZDIDOtpChallenges_Counters CHECK (Generation >= 0 AND FailedAttempts BETWEEN 0 AND 20 AND SendsInWindow BETWEEN 0 AND 50),
        CONSTRAINT CK_BAZDIDOtpChallenges_Code CHECK ((CodeMac IS NULL) OR (CodeExpiresAtUtc IS NOT NULL AND Generation > 0)),
        CONSTRAINT CK_BAZDIDOtpChallenges_Consumed CHECK ((State = 'Consumed' AND ConsumedAtUtc IS NOT NULL AND CodeMac IS NULL) OR (State <> 'Consumed' AND ConsumedAtUtc IS NULL))
    );
    CREATE INDEX IX_BAZDIDOtpChallenges_Context ON dbo.BAZDIDOtpChallenges (RequestContextId, CreatedAtUtc);
    CREATE INDEX IX_BAZDIDOtpChallenges_Expiry ON dbo.BAZDIDOtpChallenges (ContextExpiresAtUtc);

    CREATE TABLE dbo.BAZDIDCustomerSessions (
        Id uniqueidentifier NOT NULL,
        HandleHash binary(32) NOT NULL,
        BrokerageId nvarchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL,
        SourceSystem nvarchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL,
        RequestContextId uniqueidentifier NOT NULL,
        CustomerLinkId uniqueidentifier NOT NULL,
        OtpChallengeId uniqueidentifier NOT NULL,
        AuthenticatedAtUtc datetime2(3) NOT NULL,
        LastSeenAtUtc datetime2(3) NOT NULL,
        IdleExpiresAtUtc datetime2(3) NOT NULL,
        AbsoluteExpiresAtUtc datetime2(3) NOT NULL,
        RevokedAtUtc datetime2(3) NULL,
        RevokeReason varchar(16) NULL,
        RowVersion rowversion NOT NULL,
        CONSTRAINT PK_BAZDIDCustomerSessions PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_BAZDIDCustomerSessions_Handle UNIQUE (HandleHash),
        -- replay: هر چالش مصرف‌شده حداکثر یک نشست می‌سازد.
        CONSTRAINT UQ_BAZDIDCustomerSessions_Challenge UNIQUE (OtpChallengeId),
        CONSTRAINT FK_BAZDIDCustomerSessions_Context FOREIGN KEY (RequestContextId) REFERENCES dbo.BAZDIDRequestContexts (Id),
        CONSTRAINT FK_BAZDIDCustomerSessions_Customer FOREIGN KEY (BrokerageId, SourceSystem, CustomerLinkId)
            REFERENCES dbo.BAZDIDCustomerLinks (BrokerageId, SourceSystem, Id),
        CONSTRAINT FK_BAZDIDCustomerSessions_Challenge FOREIGN KEY (OtpChallengeId) REFERENCES dbo.BAZDIDOtpChallenges (Id),
        CONSTRAINT CK_BAZDIDCustomerSessions_Tenant CHECK (
            LEN(BrokerageId) > 0 AND REPLACE(BrokerageId,N'-',N'') NOT LIKE N'%[^A-Za-z0-9_]%'
            AND LEN(SourceSystem) > 0 AND REPLACE(SourceSystem,N'-',N'') NOT LIKE N'%[^A-Za-z0-9_]%'),
        CONSTRAINT CK_BAZDIDCustomerSessions_Time CHECK (AbsoluteExpiresAtUtc > AuthenticatedAtUtc AND IdleExpiresAtUtc <= AbsoluteExpiresAtUtc
            AND LastSeenAtUtc >= AuthenticatedAtUtc),
        CONSTRAINT CK_BAZDIDCustomerSessions_Revoke CHECK ((RevokedAtUtc IS NULL AND RevokeReason IS NULL)
            OR (RevokedAtUtc IS NOT NULL AND RevokeReason IN ('Logout','Expired','Admin','Superseded')))
    );
    CREATE INDEX IX_BAZDIDCustomerSessions_Context ON dbo.BAZDIDCustomerSessions (RequestContextId) WHERE RevokedAtUtc IS NULL;
    CREATE INDEX IX_BAZDIDCustomerSessions_Expiry ON dbo.BAZDIDCustomerSessions (AbsoluteExpiresAtUtc);

    CREATE TABLE dbo.BAZDIDAuthRateCounters (
        Scope varchar(16) NOT NULL,
        KeyHash binary(32) NOT NULL,
        WindowStartUtc datetime2(3) NOT NULL,
        Hits int NOT NULL,
        RowVersion rowversion NOT NULL,
        CONSTRAINT PK_BAZDIDAuthRateCounters PRIMARY KEY CLUSTERED (Scope, KeyHash),
        CONSTRAINT CK_BAZDIDAuthRateCounters_Scope CHECK (Scope IN ('referral','otp-request','otp-verify','ip','tenant')),
        CONSTRAINT CK_BAZDIDAuthRateCounters_Hits CHECK (Hits >= 0)
    );

    INSERT dbo.BAZDIDSchemaMigrations (MigrationId, Checksum, ApprovalReference, Mode) VALUES (@MigrationId, @MigrationChecksum, @ApprovalReference, 'Created');
    COMMIT TRANSACTION;
    SELECT @MigrationId AS MigrationId, 'Created' AS Result;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
