-- PROPOSED — REQUIRES BACKEND APPROVAL; documentation only; never executed.
-- پیشنهاد صرفاً برای بررسی Backend؛ روی هیچ پایگاهی اجرا نشده است.
-- نیازمند تصویب نسخه SQL Server، migration، حقوق دسترسی و سیاست نگهداری.
-- بایت عکس/ویدیو فقط filesystem خصوصی؛ SQL فقط metadata و hash دارد.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
-- نگاشت حداقلی هویت مبدأ؛ بدون رمز یا تکثیر پروفایل بیمه
CREATE TABLE [dbo].[Customers] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_Customers_Id] DEFAULT (NEWSEQUENTIALID()),
    [SourceIssuer] nvarchar(200) NOT NULL,
    [SourceSubjectId] nvarchar(128) NOT NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Customers_CreatedAt] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_Customers] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_Customers_1] UNIQUE ([SourceIssuer], [SourceSubjectId])
);
GO
-- درخواست بیمه متعلق به مشتری
CREATE TABLE [dbo].[SourceInsuranceRequests] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_SourceInsuranceRequests_Id] DEFAULT (NEWSEQUENTIALID()),
    [CustomerId] uniqueidentifier NOT NULL,
    [SourceSystem] nvarchar(80) NOT NULL,
    [ExternalRequestId] nvarchar(128) NOT NULL,
    [SourceVehicleReference] nvarchar(128) NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_SourceInsuranceRequests_CreatedAt] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_SourceInsuranceRequests] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_SourceInsuranceRequests_1] UNIQUE ([SourceSystem], [ExternalRequestId]),
    CONSTRAINT [FK_SourceInsuranceRequests_1] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customers] ([Id]) ON DELETE NO ACTION
);
GO
-- نسخه مستقل قالب؛ پس از انتشار تغییرناپذیر
CREATE TABLE [dbo].[InspectionTemplates] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_InspectionTemplates_Id] DEFAULT (NEWSEQUENTIALID()),
    [TemplateKey] nvarchar(80) NOT NULL,
    [Version] int NOT NULL,
    [PhotoPolicyVersion] int NOT NULL,
    [State] varchar(16) NOT NULL,
    [SnapshotJson] nvarchar(max) NOT NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_InspectionTemplates_CreatedAt] DEFAULT (SYSUTCDATETIME()),
    [PublishedAt] datetime2(3) NULL,
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_InspectionTemplates] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_InspectionTemplates_1] UNIQUE ([TemplateKey], [Version]),
    CONSTRAINT [CK_InspectionTemplates_1] CHECK ([Version]>0),
    CONSTRAINT [CK_InspectionTemplates_2] CHECK ([PhotoPolicyVersion] IN (1,2)),
    CONSTRAINT [CK_InspectionTemplates_3] CHECK ([State] IN ('draft','published','archived')),
    CONSTRAINT [CK_InspectionTemplates_4] CHECK (ISJSON([SnapshotJson])=1)
);
GO
-- جایگاه الزام؛ عکس و ویدیو جدا هستند
CREATE TABLE [dbo].[EvidenceRequirements] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_EvidenceRequirements_Id] DEFAULT (NEWSEQUENTIALID()),
    [TemplateId] uniqueidentifier NOT NULL,
    [RequirementKey] nvarchar(80) NOT NULL,
    [Kind] varchar(16) NOT NULL,
    [SectionKey] nvarchar(80) NULL,
    [Required] bit NOT NULL CONSTRAINT [DF_EvidenceRequirements_Required] DEFAULT (1),
    [HasChoice] bit NOT NULL CONSTRAINT [DF_EvidenceRequirements_HasChoice] DEFAULT (0),
    [SortOrder] int NOT NULL,
    CONSTRAINT [PK_EvidenceRequirements] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_EvidenceRequirements_1] UNIQUE ([TemplateId], [RequirementKey]),
    CONSTRAINT [UQ_EvidenceRequirements_2] UNIQUE ([Id], [TemplateId]),
    CONSTRAINT [UQ_EvidenceRequirements_3] UNIQUE ([Id], [HasChoice]),
    CONSTRAINT [FK_EvidenceRequirements_1] FOREIGN KEY ([TemplateId]) REFERENCES [dbo].[InspectionTemplates] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_EvidenceRequirements_1] CHECK ([Kind] IN ('photo','video-360')),
    CONSTRAINT [CK_EvidenceRequirements_2] CHECK ([SortOrder]>0),
    CONSTRAINT [CK_EvidenceRequirements_3] CHECK (([Kind]='photo' AND [SectionKey] IS NOT NULL) OR ([Kind]='video-360' AND [SectionKey] IS NULL AND [HasChoice]=0))
);
GO
-- چهار محل مجاز همان یک الزام VIN
CREATE TABLE [dbo].[RequirementAlternatives] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_RequirementAlternatives_Id] DEFAULT (NEWSEQUENTIALID()),
    [RequirementId] uniqueidentifier NOT NULL,
    [AlternativeKey] varchar(20) NOT NULL,
    [TitleFa] nvarchar(250) NOT NULL,
    CONSTRAINT [PK_RequirementAlternatives] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_RequirementAlternatives_1] UNIQUE ([RequirementId], [AlternativeKey]),
    CONSTRAINT [UQ_RequirementAlternatives_2] UNIQUE ([Id], [RequirementId]),
    CONSTRAINT [FK_RequirementAlternatives_1] FOREIGN KEY ([RequirementId]) REFERENCES [dbo].[EvidenceRequirements] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_RequirementAlternatives_1] CHECK ([AlternativeKey] IN ('pillar','engine','seat','windshield'))
);
GO
-- هر ردیف یک تلاش مستقل و دارای سابقه
CREATE TABLE [dbo].[Inspections] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_Inspections_Id] DEFAULT (NEWSEQUENTIALID()),
    [PublicId] nvarchar(80) NOT NULL,
    [SourceRequestId] uniqueidentifier NOT NULL,
    [TemplateId] uniqueidentifier NOT NULL,
    [AttemptNumber] int NOT NULL,
    [PreviousInspectionId] uniqueidentifier NULL,
    [TrackingCode] nvarchar(80) NOT NULL,
    [Status] varchar(24) NOT NULL,
    [IsCurrent] bit NOT NULL CONSTRAINT [DF_Inspections_IsCurrent] DEFAULT (1),
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Inspections_CreatedAt] DEFAULT (SYSUTCDATETIME()),
    [UpdatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Inspections_UpdatedAt] DEFAULT (SYSUTCDATETIME()),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_Inspections] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_Inspections_1] UNIQUE ([PublicId]),
    CONSTRAINT [UQ_Inspections_2] UNIQUE ([TrackingCode]),
    CONSTRAINT [UQ_Inspections_3] UNIQUE ([SourceRequestId], [AttemptNumber]),
    CONSTRAINT [UQ_Inspections_4] UNIQUE ([Id], [TemplateId]),
    CONSTRAINT [UQ_Inspections_5] UNIQUE ([Id], [SourceRequestId]),
    CONSTRAINT [FK_Inspections_1] FOREIGN KEY ([SourceRequestId]) REFERENCES [dbo].[SourceInsuranceRequests] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Inspections_2] FOREIGN KEY ([TemplateId]) REFERENCES [dbo].[InspectionTemplates] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Inspections_3] FOREIGN KEY ([PreviousInspectionId], [SourceRequestId]) REFERENCES [dbo].[Inspections] ([Id], [SourceRequestId]) ON DELETE NO ACTION,
    CONSTRAINT [CK_Inspections_1] CHECK ([AttemptNumber]>0),
    CONSTRAINT [CK_Inspections_2] CHECK ([Status] IN ('DRAFT','UPLOAD_PENDING','SUBMITTED','UNDER_REVIEW','CHANGES_REQUESTED','REJECTED','REVIEW_APPROVED','FORWARD_PENDING','FORWARDED','FORWARD_FAILED')),
    CONSTRAINT [CK_Inspections_3] CHECK ([PreviousInspectionId] IS NULL OR [PreviousInspectionId]<>[Id])
);
GO
-- تصویر اطلاعاتی خودرو همان تلاش؛ منبع بیمه بازنویسی نمی‌شود
CREATE TABLE [dbo].[Vehicles] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_Vehicles_Id] DEFAULT (NEWSEQUENTIALID()),
    [InspectionId] uniqueidentifier NOT NULL,
    [SourceVehicleReference] nvarchar(128) NULL,
    [Make] nvarchar(100) NOT NULL,
    [Model] nvarchar(100) NOT NULL,
    [ModelYear] int NOT NULL,
    [BodyColor] nvarchar(80) NOT NULL,
    [PlateFirstTwo] char(2) NOT NULL,
    [PlateLetter] nvarchar(3) NOT NULL,
    [PlateThree] char(3) NOT NULL,
    [PlateRegion] char(2) NOT NULL,
    [MaskedVin] nvarchar(80) NOT NULL,
    [ConfirmedAt] datetime2(3) NULL,
    [RowVersion] rowversion NOT NULL,
    [BodyColorHex] char(7) NULL,
    CONSTRAINT [PK_Vehicles] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_Vehicles_1] UNIQUE ([InspectionId]),
    CONSTRAINT [FK_Vehicles_1] FOREIGN KEY ([InspectionId]) REFERENCES [dbo].[Inspections] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_Vehicles_1] CHECK ([ModelYear] BETWEEN 1000 AND 3000),
    CONSTRAINT [CK_Vehicles_2] CHECK ([PlateFirstTwo] NOT LIKE '%[^0-9]%' AND [PlateThree] NOT LIKE '%[^0-9]%' AND [PlateRegion] NOT LIKE '%[^0-9]%')
);
GO
-- محل تأییدشده بازدید
CREATE TABLE [dbo].[InspectionLocations] (
    [InspectionId] uniqueidentifier NOT NULL,
    [Latitude] decimal(9,6) NOT NULL,
    [Longitude] decimal(9,6) NOT NULL,
    [AccuracyMeters] decimal(9,2) NULL,
    [FormattedAddress] nvarchar(500) NOT NULL,
    [BuildingNumber] nvarchar(40) NULL,
    [UnitFloor] nvarchar(80) NULL,
    [ParkingDescription] nvarchar(500) NULL,
    [ConfirmedAt] datetime2(3) NOT NULL CONSTRAINT [DF_InspectionLocations_ConfirmedAt] DEFAULT (SYSUTCDATETIME()),
    [RowVersion] rowversion NOT NULL,
    [SelectionSource] varchar(10) NULL,
    [ClientRecordedAt] datetime2(3) NULL,
    CONSTRAINT [PK_InspectionLocations] PRIMARY KEY ([InspectionId]),
    CONSTRAINT [FK_InspectionLocations_1] FOREIGN KEY ([InspectionId]) REFERENCES [dbo].[Inspections] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_InspectionLocations_1] CHECK ([Latitude] BETWEEN -90 AND 90),
    CONSTRAINT [CK_InspectionLocations_2] CHECK ([Longitude] BETWEEN -180 AND 180),
    CONSTRAINT [CK_InspectionLocations_3] CHECK ([AccuracyMeters]>=0),
    CONSTRAINT [CK_InspectionLocations_4] CHECK ([SelectionSource] IS NULL OR [SelectionSource] IN ('gps','manual'))
);
GO
-- رسید پذیرش نسخه شرایط
CREATE TABLE [dbo].[InspectionConsents] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_InspectionConsents_Id] DEFAULT (NEWSEQUENTIALID()),
    [InspectionId] uniqueidentifier NOT NULL,
    [TermsVersion] nvarchar(80) NOT NULL,
    [AcceptedBySubject] nvarchar(128) NOT NULL,
    [AcceptedAt] datetime2(3) NOT NULL CONSTRAINT [DF_InspectionConsents_AcceptedAt] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_InspectionConsents] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_InspectionConsents_1] UNIQUE ([InspectionId], [TermsVersion]),
    CONSTRAINT [FK_InspectionConsents_1] FOREIGN KEY ([InspectionId]) REFERENCES [dbo].[Inspections] ([Id]) ON DELETE NO ACTION
);
GO
-- کیلومتر عددی، مستقل از رسانه
CREATE TABLE [dbo].[OdometerReadings] (
    [InspectionId] uniqueidentifier NOT NULL,
    [Kilometers] bigint NOT NULL,
    [EvidenceVersionId] uniqueidentifier NULL,
    [UpdatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_OdometerReadings_UpdatedAt] DEFAULT (SYSUTCDATETIME()),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_OdometerReadings] PRIMARY KEY ([InspectionId]),
    CONSTRAINT [FK_OdometerReadings_1] FOREIGN KEY ([InspectionId]) REFERENCES [dbo].[Inspections] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_OdometerReadings_1] CHECK ([Kilometers] BETWEEN 0 AND 9007199254740991)
);
GO
-- جایگاه مدرک و اشاره‌گر نسخه خوب/جایگزین منتظر
CREATE TABLE [dbo].[InspectionEvidence] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_InspectionEvidence_Id] DEFAULT (NEWSEQUENTIALID()),
    [InspectionId] uniqueidentifier NOT NULL,
    [TemplateId] uniqueidentifier NOT NULL,
    [RequirementId] uniqueidentifier NOT NULL,
    [CurrentVersionId] uniqueidentifier NULL,
    [PendingVersionId] uniqueidentifier NULL,
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_InspectionEvidence] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_InspectionEvidence_1] UNIQUE ([InspectionId], [RequirementId]),
    CONSTRAINT [UQ_InspectionEvidence_2] UNIQUE ([Id], [InspectionId]),
    CONSTRAINT [UQ_InspectionEvidence_3] UNIQUE ([Id], [RequirementId]),
    CONSTRAINT [FK_InspectionEvidence_1] FOREIGN KEY ([InspectionId], [TemplateId]) REFERENCES [dbo].[Inspections] ([Id], [TemplateId]) ON DELETE NO ACTION,
    CONSTRAINT [FK_InspectionEvidence_2] FOREIGN KEY ([RequirementId], [TemplateId]) REFERENCES [dbo].[EvidenceRequirements] ([Id], [TemplateId]) ON DELETE NO ACTION
);
GO
-- نسخه مستقل با هویت واقعی گزینه و بایت‌ها
CREATE TABLE [dbo].[EvidenceVersions] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_EvidenceVersions_Id] DEFAULT (NEWSEQUENTIALID()),
    [EvidenceId] uniqueidentifier NOT NULL,
    [InspectionId] uniqueidentifier NOT NULL,
    [RequirementId] uniqueidentifier NOT NULL,
    [HasChoice] bit NOT NULL,
    [AlternativeId] uniqueidentifier NULL,
    [RevisionKey] nvarchar(160) NOT NULL,
    [ReplacesVersionId] uniqueidentifier NULL,
    [UploadStatus] varchar(16) NOT NULL,
    [VerificationStatus] varchar(24) NOT NULL,
    [CapturedAtClaim] datetime2(3) NOT NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_EvidenceVersions_CreatedAt] DEFAULT (SYSUTCDATETIME()),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_EvidenceVersions] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_EvidenceVersions_1] UNIQUE ([EvidenceId], [RevisionKey]),
    CONSTRAINT [UQ_EvidenceVersions_2] UNIQUE ([Id], [EvidenceId]),
    CONSTRAINT [UQ_EvidenceVersions_3] UNIQUE ([Id], [InspectionId]),
    CONSTRAINT [FK_EvidenceVersions_1] FOREIGN KEY ([EvidenceId], [InspectionId]) REFERENCES [dbo].[InspectionEvidence] ([Id], [InspectionId]) ON DELETE NO ACTION,
    CONSTRAINT [FK_EvidenceVersions_2] FOREIGN KEY ([EvidenceId], [RequirementId]) REFERENCES [dbo].[InspectionEvidence] ([Id], [RequirementId]) ON DELETE NO ACTION,
    CONSTRAINT [FK_EvidenceVersions_3] FOREIGN KEY ([RequirementId], [HasChoice]) REFERENCES [dbo].[EvidenceRequirements] ([Id], [HasChoice]) ON DELETE NO ACTION,
    CONSTRAINT [FK_EvidenceVersions_4] FOREIGN KEY ([AlternativeId], [RequirementId]) REFERENCES [dbo].[RequirementAlternatives] ([Id], [RequirementId]) ON DELETE NO ACTION,
    CONSTRAINT [CK_EvidenceVersions_1] CHECK ([UploadStatus] IN ('queued','uploading','uploaded','failed','cancelled')),
    CONSTRAINT [CK_EvidenceVersions_2] CHECK ([VerificationStatus] IN ('not-started','processing','verified','retake-requested')),
    CONSTRAINT [CK_EvidenceVersions_3] CHECK (([HasChoice]=1 AND [AlternativeId] IS NOT NULL) OR ([HasChoice]=0 AND [AlternativeId] IS NULL))
);
GO
-- فقط فراداده و مسیر فایل خصوصی؛ بدون باینری رسانه
CREATE TABLE [dbo].[MediaFiles] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_MediaFiles_Id] DEFAULT (NEWSEQUENTIALID()),
    [EvidenceVersionId] uniqueidentifier NOT NULL,
    [Variant] varchar(16) NOT NULL,
    [GeneratedFilename] nvarchar(200) NOT NULL,
    [RelativePath] nvarchar(450) NOT NULL,
    [MimeType] varchar(127) NOT NULL,
    [ByteSize] bigint NOT NULL,
    [Sha256] binary(32) NULL,
    [Width] int NULL,
    [Height] int NULL,
    [DurationMs] bigint NULL,
    [StorageState] varchar(16) NOT NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_MediaFiles_CreatedAt] DEFAULT (SYSUTCDATETIME()),
    [RetentionUntil] datetime2(3) NULL,
    [LegalHold] bit NOT NULL CONSTRAINT [DF_MediaFiles_LegalHold] DEFAULT (0),
    [DeletedAt] datetime2(3) NULL,
    [RowVersion] rowversion NOT NULL,
    [DerivedFromFileId] uniqueidentifier NULL,
    [ProfileVersion] nvarchar(80) NULL,
    CONSTRAINT [PK_MediaFiles] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_MediaFiles_1] UNIQUE ([RelativePath]),
    CONSTRAINT [UQ_MediaFiles_2] UNIQUE ([Id], [EvidenceVersionId]),
    CONSTRAINT [FK_MediaFiles_1] FOREIGN KEY ([EvidenceVersionId]) REFERENCES [dbo].[EvidenceVersions] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_MediaFiles_2] FOREIGN KEY ([DerivedFromFileId], [EvidenceVersionId]) REFERENCES [dbo].[MediaFiles] ([Id], [EvidenceVersionId]) ON DELETE NO ACTION,
    CONSTRAINT [CK_MediaFiles_1] CHECK ([Variant] IN ('original','thumbnail','preview','transcode')),
    CONSTRAINT [CK_MediaFiles_2] CHECK ([StorageState] IN ('staging','durable','submitted','finalized','historical','missing','deleted')),
    CONSTRAINT [CK_MediaFiles_3] CHECK ([ByteSize]>0),
    CONSTRAINT [CK_MediaFiles_4] CHECK ([Width] IS NULL OR [Width]>0),
    CONSTRAINT [CK_MediaFiles_5] CHECK ([Height] IS NULL OR [Height]>0),
    CONSTRAINT [CK_MediaFiles_6] CHECK ([DurationMs] IS NULL OR [DurationMs]>0),
    CONSTRAINT [CK_MediaFiles_7] CHECK ([RelativePath] NOT LIKE '%..%' AND [RelativePath] NOT LIKE '/%' AND [RelativePath] NOT LIKE '%:%' AND CHARINDEX(NCHAR(92),[RelativePath])=0),
    CONSTRAINT [CK_MediaFiles_8] CHECK ([DerivedFromFileId] IS NULL OR [DerivedFromFileId]<>[Id])
);
GO
-- مجوز و انتقال قابل بازیابی همان فایل
CREATE TABLE [dbo].[UploadSessions] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_UploadSessions_Id] DEFAULT (NEWSEQUENTIALID()),
    [MediaFileId] uniqueidentifier NOT NULL,
    [State] varchar(16) NOT NULL,
    [ExpectedBytes] bigint NOT NULL,
    [BytesReceived] bigint NOT NULL CONSTRAINT [DF_UploadSessions_BytesReceived] DEFAULT (0),
    [IsActive] bit NOT NULL CONSTRAINT [DF_UploadSessions_IsActive] DEFAULT (1),
    [ExpiresAt] datetime2(3) NOT NULL,
    [AcknowledgedAt] datetime2(3) NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_UploadSessions_CreatedAt] DEFAULT (SYSUTCDATETIME()),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_UploadSessions] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_UploadSessions_1] FOREIGN KEY ([MediaFileId]) REFERENCES [dbo].[MediaFiles] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_UploadSessions_1] CHECK ([State] IN ('registered','receiving','staged','acknowledged','expired','cancelled')),
    CONSTRAINT [CK_UploadSessions_2] CHECK ([ExpectedBytes]>0 AND [BytesReceived]>=0 AND [BytesReceived]<=[ExpectedBytes])
);
GO
-- کار اعتبارسنجی و تولید مشتق اختیاری
CREATE TABLE [dbo].[MediaProcessingJobs] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_MediaProcessingJobs_Id] DEFAULT (NEWSEQUENTIALID()),
    [MediaFileId] uniqueidentifier NOT NULL,
    [JobKind] varchar(24) NOT NULL,
    [ProfileVersion] nvarchar(80) NOT NULL,
    [Status] varchar(16) NOT NULL,
    [AttemptCount] int NOT NULL CONSTRAINT [DF_MediaProcessingJobs_AttemptCount] DEFAULT (0),
    [LeaseUntil] datetime2(3) NULL,
    [NextRetryAt] datetime2(3) NULL,
    [FailureCode] varchar(80) NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_MediaProcessingJobs_CreatedAt] DEFAULT (SYSUTCDATETIME()),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_MediaProcessingJobs] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_MediaProcessingJobs_1] UNIQUE ([MediaFileId], [JobKind], [ProfileVersion]),
    CONSTRAINT [FK_MediaProcessingJobs_1] FOREIGN KEY ([MediaFileId]) REFERENCES [dbo].[MediaFiles] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_MediaProcessingJobs_1] CHECK ([JobKind] IN ('validate','thumbnail','transcode')),
    CONSTRAINT [CK_MediaProcessingJobs_2] CHECK ([Status] IN ('queued','running','completed','failed')),
    CONSTRAINT [CK_MediaProcessingJobs_3] CHECK ([AttemptCount]>=0)
);
GO
-- نگاشت کارکنان SSO؛ بدون حساب/رمز تکراری
CREATE TABLE [dbo].[StaffUsers] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_StaffUsers_Id] DEFAULT (NEWSEQUENTIALID()),
    [ExternalIssuer] nvarchar(200) NOT NULL,
    [ExternalSubject] nvarchar(128) NOT NULL,
    [DisplayName] nvarchar(160) NOT NULL,
    [Active] bit NOT NULL CONSTRAINT [DF_StaffUsers_Active] DEFAULT (1),
    [Capacity] int NOT NULL CONSTRAINT [DF_StaffUsers_Capacity] DEFAULT (10),
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_StaffUsers_CreatedAt] DEFAULT (SYSUTCDATETIME()),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_StaffUsers] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_StaffUsers_1] UNIQUE ([ExternalIssuer], [ExternalSubject]),
    CONSTRAINT [CK_StaffUsers_1] CHECK ([Capacity]>=0)
);
GO
-- نقش کارکنان در همان نصب
CREATE TABLE [dbo].[StaffRoleAssignments] (
    [StaffId] uniqueidentifier NOT NULL,
    [RoleCode] varchar(32) NOT NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_StaffRoleAssignments_CreatedAt] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_StaffRoleAssignments] PRIMARY KEY ([StaffId], [RoleCode]),
    CONSTRAINT [FK_StaffRoleAssignments_1] FOREIGN KEY ([StaffId]) REFERENCES [dbo].[StaffUsers] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_StaffRoleAssignments_1] CHECK ([RoleCode] IN ('platform-admin','reviewer','template-editor','viewer'))
);
GO
-- سیاست ارجاع مستقل از برند
CREATE TABLE [dbo].[StaffOperationsSettings] (
    [Id] tinyint NOT NULL CONSTRAINT [DF_StaffOperationsSettings_Id] DEFAULT (1),
    [AssignmentMode] varchar(16) NOT NULL,
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_StaffOperationsSettings] PRIMARY KEY ([Id]),
    CONSTRAINT [CK_StaffOperationsSettings_1] CHECK ([Id]=1),
    CONSTRAINT [CK_StaffOperationsSettings_2] CHECK ([AssignmentMode] IN ('manual','random'))
);
GO
-- سابقه ارجاع؛ یک ارجاع فعال هر پرونده
CREATE TABLE [dbo].[ReviewerAssignments] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_ReviewerAssignments_Id] DEFAULT (NEWSEQUENTIALID()),
    [InspectionId] uniqueidentifier NOT NULL,
    [ReviewerId] uniqueidentifier NOT NULL,
    [AssignedBy] uniqueidentifier NOT NULL,
    [Active] bit NOT NULL CONSTRAINT [DF_ReviewerAssignments_Active] DEFAULT (1),
    [AssignedAt] datetime2(3) NOT NULL CONSTRAINT [DF_ReviewerAssignments_AssignedAt] DEFAULT (SYSUTCDATETIME()),
    [RevokedAt] datetime2(3) NULL,
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_ReviewerAssignments] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_ReviewerAssignments_1] UNIQUE ([Id], [InspectionId]),
    CONSTRAINT [FK_ReviewerAssignments_1] FOREIGN KEY ([InspectionId]) REFERENCES [dbo].[Inspections] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_ReviewerAssignments_2] FOREIGN KEY ([ReviewerId]) REFERENCES [dbo].[StaffUsers] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_ReviewerAssignments_3] FOREIGN KEY ([AssignedBy]) REFERENCES [dbo].[StaffUsers] ([Id]) ON DELETE NO ACTION
);
GO
-- رسید و نسخه ثابت ارسال اولیه/اصلاح
CREATE TABLE [dbo].[InspectionSubmissions] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_InspectionSubmissions_Id] DEFAULT (NEWSEQUENTIALID()),
    [InspectionId] uniqueidentifier NOT NULL,
    [SubmissionNumber] int NOT NULL,
    [CorrectionRequestId] uniqueidentifier NULL,
    [SnapshotJson] nvarchar(max) NOT NULL,
    [SubmittedBySubject] nvarchar(128) NOT NULL,
    [SubmittedAt] datetime2(3) NOT NULL CONSTRAINT [DF_InspectionSubmissions_SubmittedAt] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_InspectionSubmissions] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_InspectionSubmissions_1] UNIQUE ([InspectionId], [SubmissionNumber]),
    CONSTRAINT [UQ_InspectionSubmissions_2] UNIQUE ([Id], [InspectionId]),
    CONSTRAINT [FK_InspectionSubmissions_1] FOREIGN KEY ([InspectionId]) REFERENCES [dbo].[Inspections] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_InspectionSubmissions_1] CHECK ([SubmissionNumber]>0),
    CONSTRAINT [CK_InspectionSubmissions_2] CHECK (ISJSON([SnapshotJson])=1)
);
GO
-- نسخه دقیق هر مدرک در رسید ارسال
CREATE TABLE [dbo].[SubmissionEvidence] (
    [SubmissionId] uniqueidentifier NOT NULL,
    [InspectionId] uniqueidentifier NOT NULL,
    [EvidenceId] uniqueidentifier NOT NULL,
    [EvidenceVersionId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_SubmissionEvidence] PRIMARY KEY ([SubmissionId], [EvidenceId]),
    CONSTRAINT [FK_SubmissionEvidence_1] FOREIGN KEY ([SubmissionId], [InspectionId]) REFERENCES [dbo].[InspectionSubmissions] ([Id], [InspectionId]) ON DELETE NO ACTION,
    CONSTRAINT [FK_SubmissionEvidence_2] FOREIGN KEY ([EvidenceId], [InspectionId]) REFERENCES [dbo].[InspectionEvidence] ([Id], [InspectionId]) ON DELETE NO ACTION,
    CONSTRAINT [FK_SubmissionEvidence_3] FOREIGN KEY ([EvidenceVersionId], [EvidenceId]) REFERENCES [dbo].[EvidenceVersions] ([Id], [EvidenceId]) ON DELETE NO ACTION
);
GO
-- رویداد تغییرناپذیر تصمیم یک نسخه
CREATE TABLE [dbo].[EvidenceReviews] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_EvidenceReviews_Id] DEFAULT (NEWSEQUENTIALID()),
    [InspectionId] uniqueidentifier NOT NULL,
    [EvidenceVersionId] uniqueidentifier NOT NULL,
    [AssignmentId] uniqueidentifier NOT NULL,
    [Decision] varchar(16) NOT NULL,
    [CustomerReason] nvarchar(2000) NULL,
    [DecidedAt] datetime2(3) NOT NULL CONSTRAINT [DF_EvidenceReviews_DecidedAt] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_EvidenceReviews] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_EvidenceReviews_1] FOREIGN KEY ([EvidenceVersionId], [InspectionId]) REFERENCES [dbo].[EvidenceVersions] ([Id], [InspectionId]) ON DELETE NO ACTION,
    CONSTRAINT [FK_EvidenceReviews_2] FOREIGN KEY ([AssignmentId], [InspectionId]) REFERENCES [dbo].[ReviewerAssignments] ([Id], [InspectionId]) ON DELETE NO ACTION,
    CONSTRAINT [CK_EvidenceReviews_1] CHECK ([Decision] IN ('approved','rejected')),
    CONSTRAINT [CK_EvidenceReviews_2] CHECK ([Decision]<>'rejected' OR ([CustomerReason] IS NOT NULL AND LEN(LTRIM(RTRIM([CustomerReason])))>0))
);
GO
-- تصمیم کل مستقل از تحویل به مقصد
CREATE TABLE [dbo].[InspectionReviews] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_InspectionReviews_Id] DEFAULT (NEWSEQUENTIALID()),
    [InspectionId] uniqueidentifier NOT NULL,
    [AssignmentId] uniqueidentifier NOT NULL,
    [SubmissionId] uniqueidentifier NOT NULL,
    [Decision] varchar(16) NOT NULL,
    [CustomerReason] nvarchar(2000) NULL,
    [DecidedAt] datetime2(3) NOT NULL CONSTRAINT [DF_InspectionReviews_DecidedAt] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_InspectionReviews] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_InspectionReviews_1] UNIQUE ([InspectionId]),
    CONSTRAINT [UQ_InspectionReviews_2] UNIQUE ([Id], [InspectionId]),
    CONSTRAINT [UQ_InspectionReviews_3] UNIQUE ([Id], [InspectionId], [SubmissionId]),
    CONSTRAINT [FK_InspectionReviews_1] FOREIGN KEY ([AssignmentId], [InspectionId]) REFERENCES [dbo].[ReviewerAssignments] ([Id], [InspectionId]) ON DELETE NO ACTION,
    CONSTRAINT [FK_InspectionReviews_2] FOREIGN KEY ([SubmissionId], [InspectionId]) REFERENCES [dbo].[InspectionSubmissions] ([Id], [InspectionId]) ON DELETE NO ACTION,
    CONSTRAINT [CK_InspectionReviews_1] CHECK ([Decision] IN ('approved','rejected')),
    CONSTRAINT [CK_InspectionReviews_2] CHECK ([Decision]<>'rejected' OR ([CustomerReason] IS NOT NULL AND LEN(LTRIM(RTRIM([CustomerReason])))>0))
);
GO
-- دور اصلاح نسخه‌دار با حفظ اصل
CREATE TABLE [dbo].[CorrectionRequests] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_CorrectionRequests_Id] DEFAULT (NEWSEQUENTIALID()),
    [InspectionId] uniqueidentifier NOT NULL,
    [OriginalSubmissionId] uniqueidentifier NOT NULL,
    [RequestedByAssignmentId] uniqueidentifier NOT NULL,
    [RequestVersion] int NOT NULL,
    [RoundNumber] int NOT NULL,
    [Status] varchar(24) NOT NULL,
    [Active] bit NOT NULL CONSTRAINT [DF_CorrectionRequests_Active] DEFAULT (1),
    [RequestedAt] datetime2(3) NOT NULL CONSTRAINT [DF_CorrectionRequests_RequestedAt] DEFAULT (SYSUTCDATETIME()),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_CorrectionRequests] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_CorrectionRequests_1] UNIQUE ([Id], [InspectionId]),
    CONSTRAINT [UQ_CorrectionRequests_2] UNIQUE ([InspectionId], [RoundNumber]),
    CONSTRAINT [FK_CorrectionRequests_1] FOREIGN KEY ([OriginalSubmissionId], [InspectionId]) REFERENCES [dbo].[InspectionSubmissions] ([Id], [InspectionId]) ON DELETE NO ACTION,
    CONSTRAINT [FK_CorrectionRequests_2] FOREIGN KEY ([RequestedByAssignmentId], [InspectionId]) REFERENCES [dbo].[ReviewerAssignments] ([Id], [InspectionId]) ON DELETE NO ACTION,
    CONSTRAINT [CK_CorrectionRequests_1] CHECK ([RequestVersion]>0 AND [RoundNumber]>0),
    CONSTRAINT [CK_CorrectionRequests_2] CHECK ([Status] IN ('requested','resubmitting','resubmitted','resubmit-failed','resolved','superseded'))
);
GO
-- قلم مشخص رسانه یا فیلد در درخواست
CREATE TABLE [dbo].[CorrectionItems] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_CorrectionItems_Id] DEFAULT (NEWSEQUENTIALID()),
    [RequestId] uniqueidentifier NOT NULL,
    [InspectionId] uniqueidentifier NOT NULL,
    [Kind] varchar(16) NOT NULL,
    [EvidenceId] uniqueidentifier NULL,
    [OriginalVersionId] uniqueidentifier NULL,
    [CandidateVersionId] uniqueidentifier NULL,
    [FieldName] varchar(20) NULL,
    [ProposalJson] nvarchar(max) NULL,
    [CustomerReason] nvarchar(2000) NOT NULL,
    [State] varchar(16) NOT NULL,
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_CorrectionItems] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_CorrectionItems_1] FOREIGN KEY ([RequestId], [InspectionId]) REFERENCES [dbo].[CorrectionRequests] ([Id], [InspectionId]) ON DELETE NO ACTION,
    CONSTRAINT [FK_CorrectionItems_2] FOREIGN KEY ([EvidenceId], [InspectionId]) REFERENCES [dbo].[InspectionEvidence] ([Id], [InspectionId]) ON DELETE NO ACTION,
    CONSTRAINT [FK_CorrectionItems_3] FOREIGN KEY ([OriginalVersionId], [EvidenceId]) REFERENCES [dbo].[EvidenceVersions] ([Id], [EvidenceId]) ON DELETE NO ACTION,
    CONSTRAINT [FK_CorrectionItems_4] FOREIGN KEY ([CandidateVersionId], [EvidenceId]) REFERENCES [dbo].[EvidenceVersions] ([Id], [EvidenceId]) ON DELETE NO ACTION,
    CONSTRAINT [CK_CorrectionItems_1] CHECK ([Kind] IN ('photo','video-360','field')),
    CONSTRAINT [CK_CorrectionItems_2] CHECK (([Kind]='field' AND [FieldName] IS NOT NULL AND [FieldName] IN ('plate','color','modelYear') AND [EvidenceId] IS NULL AND [OriginalVersionId] IS NULL AND [CandidateVersionId] IS NULL) OR ([Kind] IN ('photo','video-360') AND [FieldName] IS NULL AND [EvidenceId] IS NOT NULL AND [OriginalVersionId] IS NOT NULL AND [ProposalJson] IS NULL)),
    CONSTRAINT [CK_CorrectionItems_3] CHECK ([ProposalJson] IS NULL OR ISJSON([ProposalJson])=1),
    CONSTRAINT [CK_CorrectionItems_4] CHECK (LEN(LTRIM(RTRIM([CustomerReason])))>0),
    CONSTRAINT [CK_CorrectionItems_5] CHECK ([State] IN ('requested','submitted','approved'))
);
GO
-- یادداشت خصوصی کارکنان، خارج از DTO مشتری
CREATE TABLE [dbo].[InternalNotes] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_InternalNotes_Id] DEFAULT (NEWSEQUENTIALID()),
    [InspectionId] uniqueidentifier NOT NULL,
    [AssignmentId] uniqueidentifier NOT NULL,
    [Text] nvarchar(4000) NOT NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_InternalNotes_CreatedAt] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_InternalNotes] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_InternalNotes_1] FOREIGN KEY ([AssignmentId], [InspectionId]) REFERENCES [dbo].[ReviewerAssignments] ([Id], [InspectionId]) ON DELETE NO ACTION,
    CONSTRAINT [CK_InternalNotes_1] CHECK (LEN(LTRIM(RTRIM([Text])))>0)
);
GO
-- تاریخچه تغییر چرخه عمر
CREATE TABLE [dbo].[InspectionStatusHistory] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_InspectionStatusHistory_Id] DEFAULT (NEWSEQUENTIALID()),
    [InspectionId] uniqueidentifier NOT NULL,
    [FromStatus] varchar(24) NULL,
    [ToStatus] varchar(24) NOT NULL,
    [ActorReference] nvarchar(160) NOT NULL,
    [ReasonCode] varchar(80) NOT NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_InspectionStatusHistory_CreatedAt] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_InspectionStatusHistory] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_InspectionStatusHistory_1] FOREIGN KEY ([InspectionId]) REFERENCES [dbo].[Inspections] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_InspectionStatusHistory_1] CHECK ([FromStatus] IS NULL OR [FromStatus] IN ('DRAFT','UPLOAD_PENDING','SUBMITTED','UNDER_REVIEW','CHANGES_REQUESTED','REJECTED','REVIEW_APPROVED','FORWARD_PENDING','FORWARDED','FORWARD_FAILED')),
    CONSTRAINT [CK_InspectionStatusHistory_2] CHECK ([ToStatus] IN ('DRAFT','UPLOAD_PENDING','SUBMITTED','UNDER_REVIEW','CHANGES_REQUESTED','REJECTED','REVIEW_APPROVED','FORWARD_PENDING','FORWARDED','FORWARD_FAILED'))
);
GO
-- رزرو و نتیجه پایدار فرمان
CREATE TABLE [dbo].[IdempotencyRecords] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_IdempotencyRecords_Id] DEFAULT (NEWSEQUENTIALID()),
    [ScopeKey] nvarchar(200) NOT NULL,
    [CommandKey] varchar(100) NOT NULL,
    [RequestHash] binary(32) NOT NULL,
    [State] varchar(16) NOT NULL,
    [ResponseStatus] smallint NULL,
    [ResponseJson] nvarchar(max) NULL,
    [LeaseUntil] datetime2(3) NULL,
    [ExpiresAt] datetime2(3) NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_IdempotencyRecords_CreatedAt] DEFAULT (SYSUTCDATETIME()),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_IdempotencyRecords] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_IdempotencyRecords_1] UNIQUE ([ScopeKey], [CommandKey]),
    CONSTRAINT [CK_IdempotencyRecords_1] CHECK ([State] IN ('reserved','completed','failed')),
    CONSTRAINT [CK_IdempotencyRecords_2] CHECK ([ResponseJson] IS NULL OR ISJSON([ResponseJson])=1),
    CONSTRAINT [CK_IdempotencyRecords_3] CHECK ([ResponseStatus] IS NULL OR [ResponseStatus] BETWEEN 100 AND 599)
);
GO
-- outbox پایدار نسخه تأییدشده
CREATE TABLE [dbo].[ForwardingJobs] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_ForwardingJobs_Id] DEFAULT (NEWSEQUENTIALID()),
    [InspectionId] uniqueidentifier NOT NULL,
    [InspectionReviewId] uniqueidentifier NOT NULL,
    [SubmissionId] uniqueidentifier NOT NULL,
    [DestinationKey] nvarchar(80) NOT NULL,
    [DeliveryKey] uniqueidentifier NOT NULL,
    [State] varchar(16) NOT NULL,
    [AttemptCount] int NOT NULL CONSTRAINT [DF_ForwardingJobs_AttemptCount] DEFAULT (0),
    [NextRetryAt] datetime2(3) NULL,
    [LeaseUntil] datetime2(3) NULL,
    [AcknowledgementId] nvarchar(160) NULL,
    [AcknowledgedAt] datetime2(3) NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_ForwardingJobs_CreatedAt] DEFAULT (SYSUTCDATETIME()),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_ForwardingJobs] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_ForwardingJobs_1] UNIQUE ([InspectionReviewId], [DestinationKey]),
    CONSTRAINT [UQ_ForwardingJobs_2] UNIQUE ([DeliveryKey]),
    CONSTRAINT [FK_ForwardingJobs_1] FOREIGN KEY ([InspectionReviewId], [InspectionId], [SubmissionId]) REFERENCES [dbo].[InspectionReviews] ([Id], [InspectionId], [SubmissionId]) ON DELETE NO ACTION,
    CONSTRAINT [FK_ForwardingJobs_2] FOREIGN KEY ([SubmissionId], [InspectionId]) REFERENCES [dbo].[InspectionSubmissions] ([Id], [InspectionId]) ON DELETE NO ACTION,
    CONSTRAINT [CK_ForwardingJobs_1] CHECK ([State] IN ('ready','sending','retrying','acknowledged','failed')),
    CONSTRAINT [CK_ForwardingJobs_2] CHECK ([AttemptCount]>=0),
    CONSTRAINT [CK_ForwardingJobs_3] CHECK ([State]<>'acknowledged' OR ([AcknowledgementId] IS NOT NULL AND [AcknowledgedAt] IS NOT NULL))
);
GO
-- تلاش‌های تحویل مستقل و محفوظ
CREATE TABLE [dbo].[ForwardingAttempts] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_ForwardingAttempts_Id] DEFAULT (NEWSEQUENTIALID()),
    [JobId] uniqueidentifier NOT NULL,
    [AttemptNumber] int NOT NULL,
    [StartedAt] datetime2(3) NOT NULL CONSTRAINT [DF_ForwardingAttempts_StartedAt] DEFAULT (SYSUTCDATETIME()),
    [FinishedAt] datetime2(3) NULL,
    [HttpStatus] smallint NULL,
    [FailureCode] varchar(80) NULL,
    CONSTRAINT [PK_ForwardingAttempts] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_ForwardingAttempts_1] UNIQUE ([JobId], [AttemptNumber]),
    CONSTRAINT [FK_ForwardingAttempts_1] FOREIGN KEY ([JobId]) REFERENCES [dbo].[ForwardingJobs] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_ForwardingAttempts_1] CHECK ([AttemptNumber]>0),
    CONSTRAINT [CK_ForwardingAttempts_2] CHECK ([HttpStatus] IS NULL OR [HttpStatus] BETWEEN 100 AND 599)
);
GO
-- دارایی عمومی ایمن برند، جدا از شواهد
CREATE TABLE [dbo].[BrandingAssets] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_BrandingAssets_Id] DEFAULT (NEWSEQUENTIALID()),
    [SlotCode] nvarchar(80) NOT NULL,
    [PublicRelativePath] nvarchar(450) NOT NULL,
    [MimeType] varchar(127) NOT NULL,
    [ByteSize] bigint NOT NULL,
    [Width] int NOT NULL,
    [Height] int NOT NULL,
    [Sha256] binary(32) NOT NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_BrandingAssets_CreatedAt] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_BrandingAssets] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_BrandingAssets_1] UNIQUE ([PublicRelativePath]),
    CONSTRAINT [CK_BrandingAssets_1] CHECK ([ByteSize]>0 AND [Width]>0 AND [Height]>0)
);
GO
-- نسخه draft یا عمومی، بدون راز زیرساخت
CREATE TABLE [dbo].[SiteSettingsVersions] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_SiteSettingsVersions_Id] DEFAULT (NEWSEQUENTIALID()),
    [Version] int NOT NULL,
    [State] varchar(16) NOT NULL,
    [SchemaVersion] int NOT NULL,
    [SettingsJson] nvarchar(max) NOT NULL,
    [CreatedBy] uniqueidentifier NOT NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_SiteSettingsVersions_CreatedAt] DEFAULT (SYSUTCDATETIME()),
    [PublishedAt] datetime2(3) NULL,
    CONSTRAINT [PK_SiteSettingsVersions] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_SiteSettingsVersions_1] UNIQUE ([Version]),
    CONSTRAINT [FK_SiteSettingsVersions_1] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[StaffUsers] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_SiteSettingsVersions_1] CHECK ([Version]>0 AND [SchemaVersion]>0),
    CONSTRAINT [CK_SiteSettingsVersions_2] CHECK ([State] IN ('draft','published','archived')),
    CONSTRAINT [CK_SiteSettingsVersions_3] CHECK (ISJSON([SettingsJson])=1)
);
GO
-- اشاره‌گر تنها ارائه‌دهنده تنظیمات
CREATE TABLE [dbo].[SiteSettings] (
    [Id] tinyint NOT NULL CONSTRAINT [DF_SiteSettings_Id] DEFAULT (1),
    [PublishedVersionId] uniqueidentifier NULL,
    [DraftVersionId] uniqueidentifier NULL,
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_SiteSettings] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_SiteSettings_1] FOREIGN KEY ([PublishedVersionId]) REFERENCES [dbo].[SiteSettingsVersions] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_SiteSettings_2] FOREIGN KEY ([DraftVersionId]) REFERENCES [dbo].[SiteSettingsVersions] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_SiteSettings_1] CHECK ([Id]=1)
);
GO
-- ارجاع نسخه تنظیمات به دارایی برند
CREATE TABLE [dbo].[SiteSettingsAssetLinks] (
    [SettingsVersionId] uniqueidentifier NOT NULL,
    [SlotCode] nvarchar(80) NOT NULL,
    [BrandingAssetId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_SiteSettingsAssetLinks] PRIMARY KEY ([SettingsVersionId], [SlotCode]),
    CONSTRAINT [FK_SiteSettingsAssetLinks_1] FOREIGN KEY ([SettingsVersionId]) REFERENCES [dbo].[SiteSettingsVersions] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_SiteSettingsAssetLinks_2] FOREIGN KEY ([BrandingAssetId]) REFERENCES [dbo].[BrandingAssets] ([Id]) ON DELETE NO ACTION
);
GO
-- رویداد و مقصد سروری شناخته‌شده
CREATE TABLE [dbo].[WebhookSubscriptions] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_WebhookSubscriptions_Id] DEFAULT (NEWSEQUENTIALID()),
    [EventCode] varchar(80) NOT NULL,
    [DestinationKey] nvarchar(80) NOT NULL,
    [Enabled] bit NOT NULL CONSTRAINT [DF_WebhookSubscriptions_Enabled] DEFAULT (0),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_WebhookSubscriptions] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_WebhookSubscriptions_1] UNIQUE ([EventCode], [DestinationKey])
);
GO
-- audit سرور، بدون راز یا رسانه
CREATE TABLE [dbo].[AuditLogs] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [ActorReference] nvarchar(160) NOT NULL,
    [InspectionId] uniqueidentifier NULL,
    [ActionCode] varchar(100) NOT NULL,
    [ResourceType] varchar(80) NOT NULL,
    [ResourceId] nvarchar(160) NOT NULL,
    [CorrelationId] varchar(80) NOT NULL,
    [MetadataJson] nvarchar(max) NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_AuditLogs_CreatedAt] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_AuditLogs] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_AuditLogs_1] FOREIGN KEY ([InspectionId]) REFERENCES [dbo].[Inspections] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_AuditLogs_1] CHECK ([MetadataJson] IS NULL OR ISJSON([MetadataJson])=1)
);
GO
-- اعلان اختیاری مصوب؛ نه جایگزین وضعیت سامانه
CREATE TABLE [dbo].[NotificationOutbox] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_NotificationOutbox_Id] DEFAULT (NEWSEQUENTIALID()),
    [InspectionId] uniqueidentifier NOT NULL,
    [EventId] uniqueidentifier NOT NULL,
    [ChannelCode] varchar(16) NOT NULL,
    [RecipientReference] nvarchar(160) NOT NULL,
    [TemplateKey] nvarchar(80) NOT NULL,
    [State] varchar(16) NOT NULL,
    [AttemptCount] int NOT NULL CONSTRAINT [DF_NotificationOutbox_AttemptCount] DEFAULT (0),
    [NextRetryAt] datetime2(3) NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_NotificationOutbox_CreatedAt] DEFAULT (SYSUTCDATETIME()),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_NotificationOutbox] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_NotificationOutbox_1] UNIQUE ([EventId], [ChannelCode]),
    CONSTRAINT [FK_NotificationOutbox_1] FOREIGN KEY ([InspectionId]) REFERENCES [dbo].[Inspections] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_NotificationOutbox_1] CHECK ([State] IN ('queued','sending','sent','failed')),
    CONSTRAINT [CK_NotificationOutbox_2] CHECK ([AttemptCount]>=0)
);
GO
ALTER TABLE [dbo].[EvidenceVersions] ADD CONSTRAINT [FK_Deferred_1] FOREIGN KEY ([ReplacesVersionId], [EvidenceId]) REFERENCES [dbo].[EvidenceVersions] ([Id], [EvidenceId]) ON DELETE NO ACTION;
GO
ALTER TABLE [dbo].[InspectionEvidence] ADD CONSTRAINT [FK_Deferred_2] FOREIGN KEY ([CurrentVersionId], [Id]) REFERENCES [dbo].[EvidenceVersions] ([Id], [EvidenceId]) ON DELETE NO ACTION;
GO
ALTER TABLE [dbo].[InspectionEvidence] ADD CONSTRAINT [FK_Deferred_3] FOREIGN KEY ([PendingVersionId], [Id]) REFERENCES [dbo].[EvidenceVersions] ([Id], [EvidenceId]) ON DELETE NO ACTION;
GO
ALTER TABLE [dbo].[OdometerReadings] ADD CONSTRAINT [FK_Deferred_4] FOREIGN KEY ([EvidenceVersionId], [InspectionId]) REFERENCES [dbo].[EvidenceVersions] ([Id], [InspectionId]) ON DELETE NO ACTION;
GO
ALTER TABLE [dbo].[InspectionSubmissions] ADD CONSTRAINT [FK_Deferred_5] FOREIGN KEY ([CorrectionRequestId], [InspectionId]) REFERENCES [dbo].[CorrectionRequests] ([Id], [InspectionId]) ON DELETE NO ACTION;
GO
CREATE NONCLUSTERED INDEX [IX_SourceInsuranceRequests_1] ON [dbo].[SourceInsuranceRequests] ([CustomerId], [CreatedAt]);
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_Inspections_1] ON [dbo].[Inspections] ([SourceRequestId]) WHERE [IsCurrent] = 1;
GO
CREATE NONCLUSTERED INDEX [IX_Inspections_2] ON [dbo].[Inspections] ([Status], [UpdatedAt]) INCLUDE ([SourceRequestId], [TrackingCode]);
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_MediaFiles_1] ON [dbo].[MediaFiles] ([EvidenceVersionId], [Variant]) WHERE [DeletedAt] IS NULL;
GO
CREATE NONCLUSTERED INDEX [IX_MediaFiles_2] ON [dbo].[MediaFiles] ([StorageState], [RetentionUntil]);
GO
CREATE NONCLUSTERED INDEX [IX_MediaFiles_3] ON [dbo].[MediaFiles] ([EvidenceVersionId], [Variant], [ProfileVersion]) INCLUDE ([MimeType], [ByteSize]);
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_UploadSessions_1] ON [dbo].[UploadSessions] ([MediaFileId]) WHERE [IsActive] = 1;
GO
CREATE NONCLUSTERED INDEX [IX_UploadSessions_2] ON [dbo].[UploadSessions] ([State], [ExpiresAt]);
GO
CREATE NONCLUSTERED INDEX [IX_MediaProcessingJobs_1] ON [dbo].[MediaProcessingJobs] ([Status], [NextRetryAt]);
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_ReviewerAssignments_1] ON [dbo].[ReviewerAssignments] ([InspectionId]) WHERE [Active] = 1;
GO
CREATE NONCLUSTERED INDEX [IX_ReviewerAssignments_2] ON [dbo].[ReviewerAssignments] ([ReviewerId], [Active]);
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_InspectionSubmissions_1] ON [dbo].[InspectionSubmissions] ([InspectionId]) WHERE [CorrectionRequestId] IS NULL;
GO
CREATE NONCLUSTERED INDEX [IX_EvidenceReviews_1] ON [dbo].[EvidenceReviews] ([InspectionId], [DecidedAt]);
GO
CREATE NONCLUSTERED INDEX [IX_EvidenceReviews_2] ON [dbo].[EvidenceReviews] ([EvidenceVersionId], [DecidedAt]);
GO
CREATE NONCLUSTERED INDEX [IX_CorrectionRequests_1] ON [dbo].[CorrectionRequests] ([InspectionId], [Active]);
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_CorrectionItems_1] ON [dbo].[CorrectionItems] ([RequestId], [EvidenceId]) WHERE [EvidenceId] IS NOT NULL;
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_CorrectionItems_2] ON [dbo].[CorrectionItems] ([RequestId], [FieldName]) WHERE [FieldName] IS NOT NULL;
GO
CREATE NONCLUSTERED INDEX [IX_InternalNotes_1] ON [dbo].[InternalNotes] ([InspectionId], [CreatedAt]);
GO
CREATE NONCLUSTERED INDEX [IX_InspectionStatusHistory_1] ON [dbo].[InspectionStatusHistory] ([InspectionId], [CreatedAt]);
GO
CREATE NONCLUSTERED INDEX [IX_IdempotencyRecords_1] ON [dbo].[IdempotencyRecords] ([State], [LeaseUntil]);
GO
CREATE NONCLUSTERED INDEX [IX_ForwardingJobs_1] ON [dbo].[ForwardingJobs] ([State], [NextRetryAt]);
GO
CREATE NONCLUSTERED INDEX [IX_AuditLogs_1] ON [dbo].[AuditLogs] ([InspectionId], [CreatedAt]);
GO
CREATE NONCLUSTERED INDEX [IX_AuditLogs_2] ON [dbo].[AuditLogs] ([ActionCode], [CreatedAt]);
GO
CREATE NONCLUSTERED INDEX [IX_NotificationOutbox_1] ON [dbo].[NotificationOutbox] ([State], [NextRetryAt]);
GO
