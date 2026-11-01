-- این فایل مستقیم اجرا نشود؛ ابزار 2C هر CASE را در transaction مستقل و فقط rollback اجرا می‌کند.
-- FIXTURE زیر در ابتدای هر CASE تکرار می‌شود؛ همهٔ شناسه‌ها و مقدارها ساختگی‌اند.
IF @@TRANCOUNT<>1 OR DB_NAME()<>N'BAZDID_Development'
 OR COALESCE(CONVERT(nvarchar(128),SERVERPROPERTY('InstanceName')),N'')<>N'SQLSERVER2019'
 OR COALESCE(CONVERT(nvarchar(128),CONNECTIONPROPERTY('net_transport')),N'')<>N'Shared memory'
BEGIN
 THROW 51000,N'CASE فقط در transaction مستقل ابزار و پایگاه تست محلی مجاز است.',1;
END;
DECLARE @Link uniqueidentifier=NEWID(),@Context uniqueidentifier=NEWID();
INSERT dbo.BAZDIDCustomerLinks (Id,BrokerageId,SourceSystem,SourceCustomerId)
VALUES (@Link,N'TEST-BROKERAGE',N'SYNTHETIC-SQL',N'TEST-CUSTOMER-001');
INSERT dbo.BAZDIDRequestContexts (Id,BrokerageId,SourceSystem,CustomerLinkId,SourceRequestId,EligibilityStatus,SourceRetrievedAtUtc)
VALUES (@Context,N'TEST-BROKERAGE',N'SYNTHETIC-SQL',@Link,N'TEST-REQUEST-001','Eligible',SYSUTCDATETIME());

-- CASE: ValidInsertsAndDefaults EXPECT: NONE
INSERT dbo.BAZDIDAuditLogs (BrokerageId,SourceSystem,RequestContextId,ActorType,ActionCode,OutcomeCode,ResourceType,CorrelationId)
VALUES (N'TEST-BROKERAGE',N'SYNTHETIC-SQL',@Context,'System','SCHEMA_TEST','PASS','Schema','0123456789abcdef0123456789abcdef');
IF (SELECT COUNT(*) FROM dbo.BAZDIDCustomerLinks)<>1 OR (SELECT COUNT(*) FROM dbo.BAZDIDRequestContexts)<>1
 OR (SELECT COUNT(*) FROM dbo.BAZDIDAuditLogs)<>1 THROW 51000,N'درج معتبر کامل نیست.',1;
IF EXISTS (SELECT 1 FROM dbo.BAZDIDCustomerLinks WHERE DATALENGTH(RowVersion)<>8
 OR SourceCustomerIdKey<>CONVERT(varbinary(256),SourceCustomerId)
 OR ABS(DATEDIFF(second,CreatedAtUtc,SYSUTCDATETIME()))>10) THROW 51000,N'default یا computed معتبر نیست.',1;
IF EXISTS (SELECT 1 FROM dbo.BAZDIDRequestContexts WHERE DATALENGTH(RowVersion)<>8
 OR SourceRequestIdKey<>CONVERT(varbinary(256),SourceRequestId)) THROW 51000,N'computed درخواست معتبر نیست.',1;

-- CASE: DuplicateCustomerPrimaryKey EXPECT: 2627
INSERT dbo.BAZDIDCustomerLinks (Id,BrokerageId,SourceSystem,SourceCustomerId)
VALUES (@Link,N'TEST-BROKERAGE',N'SYNTHETIC-SQL',N'OTHER-CUSTOMER');

-- CASE: DuplicateCustomerSourceKey EXPECT: 2601,2627
INSERT dbo.BAZDIDCustomerLinks (Id,BrokerageId,SourceSystem,SourceCustomerId)
VALUES (NEWID(),N'TEST-BROKERAGE',N'SYNTHETIC-SQL',N'TEST-CUSTOMER-001');

-- CASE: DuplicateRequestPrimaryKey EXPECT: 2627
INSERT dbo.BAZDIDRequestContexts (Id,BrokerageId,SourceSystem,CustomerLinkId,SourceRequestId,EligibilityStatus,SourceRetrievedAtUtc)
VALUES (@Context,N'TEST-BROKERAGE',N'SYNTHETIC-SQL',@Link,N'OTHER-REQUEST','Eligible',SYSUTCDATETIME());

-- CASE: DuplicateRequestSourceKey EXPECT: 2601,2627
INSERT dbo.BAZDIDRequestContexts (Id,BrokerageId,SourceSystem,CustomerLinkId,SourceRequestId,EligibilityStatus,SourceRetrievedAtUtc)
VALUES (NEWID(),N'TEST-BROKERAGE',N'SYNTHETIC-SQL',@Link,N'TEST-REQUEST-001','Eligible',SYSUTCDATETIME());

-- CASE: MissingCustomerForeignKey EXPECT: 547
INSERT dbo.BAZDIDRequestContexts (Id,BrokerageId,SourceSystem,CustomerLinkId,SourceRequestId,EligibilityStatus,SourceRetrievedAtUtc)
VALUES (NEWID(),N'TEST-BROKERAGE',N'SYNTHETIC-SQL',NEWID(),N'OTHER-REQUEST','Eligible',SYSUTCDATETIME());

-- CASE: CrossTenantForeignKey EXPECT: 547
INSERT dbo.BAZDIDRequestContexts (Id,BrokerageId,SourceSystem,CustomerLinkId,SourceRequestId,EligibilityStatus,SourceRetrievedAtUtc)
VALUES (NEWID(),N'OTHER-BROKERAGE',N'SYNTHETIC-SQL',@Link,N'OTHER-REQUEST','Eligible',SYSUTCDATETIME());

-- CASE: CrossSourceForeignKey EXPECT: 547
INSERT dbo.BAZDIDRequestContexts (Id,BrokerageId,SourceSystem,CustomerLinkId,SourceRequestId,EligibilityStatus,SourceRetrievedAtUtc)
VALUES (NEWID(),N'TEST-BROKERAGE',N'OTHER-SOURCE',@Link,N'OTHER-REQUEST','Eligible',SYSUTCDATETIME());

-- CASE: MultipleRequestsForOneCustomer EXPECT: NONE
INSERT dbo.BAZDIDRequestContexts (Id,BrokerageId,SourceSystem,CustomerLinkId,SourceRequestId,EligibilityStatus,SourceRetrievedAtUtc)
VALUES (NEWID(),N'TEST-BROKERAGE',N'SYNTHETIC-SQL',@Link,N'TEST-REQUEST-002','Eligible',SYSUTCDATETIME());
IF (SELECT COUNT(*) FROM dbo.BAZDIDRequestContexts WHERE CustomerLinkId=@Link)<>2 THROW 51000,N'چند درخواست برای یک مشتری مجاز نیست.',1;

-- CASE: SameSourceIdentityAcrossTenants EXPECT: NONE
DECLARE @OtherLink uniqueidentifier=NEWID();
INSERT dbo.BAZDIDCustomerLinks (Id,BrokerageId,SourceSystem,SourceCustomerId)
VALUES (@OtherLink,N'OTHER-BROKERAGE',N'SYNTHETIC-SQL',N'TEST-CUSTOMER-001');
INSERT dbo.BAZDIDRequestContexts (Id,BrokerageId,SourceSystem,CustomerLinkId,SourceRequestId,EligibilityStatus,SourceRetrievedAtUtc)
VALUES (NEWID(),N'OTHER-BROKERAGE',N'SYNTHETIC-SQL',@OtherLink,N'TEST-REQUEST-001','Eligible',SYSUTCDATETIME());
IF (SELECT COUNT(*) FROM dbo.BAZDIDRequestContexts)<>2 THROW 51000,N'حوزهٔ یکتایی tenant نادرست است.',1;

-- CASE: CustomerIdentifierCasePreserved EXPECT: NONE
INSERT dbo.BAZDIDCustomerLinks (Id,BrokerageId,SourceSystem,SourceCustomerId)
VALUES (NEWID(),N'TEST-BROKERAGE',N'SYNTHETIC-SQL',N'test-customer-001');
IF (SELECT COUNT(*) FROM dbo.BAZDIDCustomerLinks)<>2 THROW 51000,N'case شناسه حفظ نشد.',1;

-- CASE: CustomerIdentifierTrailingSpacePreserved EXPECT: NONE
INSERT dbo.BAZDIDCustomerLinks (Id,BrokerageId,SourceSystem,SourceCustomerId)
VALUES (NEWID(),N'TEST-BROKERAGE',N'SYNTHETIC-SQL',N'TEST-CUSTOMER-001 ');
IF (SELECT COUNT(*) FROM dbo.BAZDIDCustomerLinks)<>2 THROW 51000,N'فاصلهٔ انتهایی شناسه حفظ نشد.',1;

-- CASE: RequestIdentifierCaseAndSpacePreserved EXPECT: NONE
INSERT dbo.BAZDIDRequestContexts (Id,BrokerageId,SourceSystem,CustomerLinkId,SourceRequestId,EligibilityStatus,SourceRetrievedAtUtc)
VALUES (NEWID(),N'TEST-BROKERAGE',N'SYNTHETIC-SQL',@Link,N'test-request-001','Eligible',SYSUTCDATETIME()),
 (NEWID(),N'TEST-BROKERAGE',N'SYNTHETIC-SQL',@Link,N'TEST-REQUEST-001 ','Eligible',SYSUTCDATETIME());
IF (SELECT COUNT(*) FROM dbo.BAZDIDRequestContexts)<>3 THROW 51000,N'شناسهٔ دقیق درخواست حفظ نشد.',1;

-- CASE: LargeSourceIdentifierRoundTrip EXPECT: NONE
UPDATE dbo.BAZDIDRequestContexts SET SourceRequestId=N'9223372036854775807' WHERE Id=@Context;
IF NOT EXISTS (SELECT 1 FROM dbo.BAZDIDRequestContexts WHERE Id=@Context
 AND SourceRequestIdKey=CONVERT(varbinary(256),N'9223372036854775807')) THROW 51000,N'دقت شناسهٔ بزرگ از دست رفت.',1;

-- CASE: CustomerRowVersionAndStaleUpdate EXPECT: NONE
DECLARE @Before binary(8)=(SELECT RowVersion FROM dbo.BAZDIDCustomerLinks WHERE Id=@Link);
UPDATE dbo.BAZDIDCustomerLinks SET UpdatedAtUtc=SYSUTCDATETIME() WHERE Id=@Link AND RowVersion=@Before;
IF @@ROWCOUNT<>1 THROW 51000,N'UPDATE نسخهٔ جاری موفق نبود.',1;
IF EXISTS (SELECT 1 FROM dbo.BAZDIDCustomerLinks WHERE Id=@Link AND RowVersion=@Before) THROW 51000,N'rowversion تغییر نکرد.',1;
UPDATE dbo.BAZDIDCustomerLinks SET UpdatedAtUtc=SYSUTCDATETIME() WHERE Id=@Link AND RowVersion=@Before;
IF @@ROWCOUNT<>0 THROW 51000,N'نسخهٔ کهنه پذیرفته شد.',1;

-- CASE: RequestRowVersionAndStaleUpdate EXPECT: NONE
DECLARE @Before binary(8)=(SELECT RowVersion FROM dbo.BAZDIDRequestContexts WHERE Id=@Context);
UPDATE dbo.BAZDIDRequestContexts SET UpdatedAtUtc=SYSUTCDATETIME() WHERE Id=@Context AND RowVersion=@Before;
IF @@ROWCOUNT<>1 THROW 51000,N'UPDATE نسخهٔ جاری درخواست موفق نبود.',1;
IF EXISTS (SELECT 1 FROM dbo.BAZDIDRequestContexts WHERE Id=@Context AND RowVersion=@Before) THROW 51000,N'rowversion درخواست تغییر نکرد.',1;
UPDATE dbo.BAZDIDRequestContexts SET UpdatedAtUtc=SYSUTCDATETIME() WHERE Id=@Context AND RowVersion=@Before;
IF @@ROWCOUNT<>0 THROW 51000,N'نسخهٔ کهنهٔ درخواست پذیرفته شد.',1;

-- CASE: EmptyCustomerIdentifierRejected EXPECT: 547
INSERT dbo.BAZDIDCustomerLinks (Id,BrokerageId,SourceSystem,SourceCustomerId)
VALUES (NEWID(),N'TEST-BROKERAGE',N'SYNTHETIC-SQL',N'');

-- CASE: NullCustomerIdentifierRejected EXPECT: 515
INSERT dbo.BAZDIDCustomerLinks (Id,BrokerageId,SourceSystem,SourceCustomerId)
VALUES (NEWID(),N'TEST-BROKERAGE',N'SYNTHETIC-SQL',NULL);

-- CASE: InvalidTenantAlphabetRejected EXPECT: 547
INSERT dbo.BAZDIDCustomerLinks (Id,BrokerageId,SourceSystem,SourceCustomerId)
VALUES (NEWID(),N'TEST BROKERAGE',N'SYNTHETIC-SQL',N'OTHER-CUSTOMER');

-- CASE: TenantUnderscoresAcceptedInAllTables EXPECT: NONE
DECLARE @UnderscoreLink uniqueidentifier=NEWID(),@UnderscoreContext uniqueidentifier=NEWID();
INSERT dbo.BAZDIDCustomerLinks (Id,BrokerageId,SourceSystem,SourceCustomerId)
VALUES (@UnderscoreLink,N'TEST_BROKERAGE',N'SYNTHETIC_SQL',N'OTHER-CUSTOMER');
INSERT dbo.BAZDIDRequestContexts (Id,BrokerageId,SourceSystem,CustomerLinkId,SourceRequestId,EligibilityStatus,SourceRetrievedAtUtc)
VALUES (@UnderscoreContext,N'TEST_BROKERAGE',N'SYNTHETIC_SQL',@UnderscoreLink,N'OTHER-REQUEST','Eligible',SYSUTCDATETIME());
INSERT dbo.BAZDIDAuditLogs (BrokerageId,SourceSystem,ActorType,ActionCode,OutcomeCode,ResourceType,CorrelationId)
VALUES (N'TEST_BROKERAGE',N'SYNTHETIC_SQL','System','SCHEMA_TEST','PASS','Schema','0123456789abcdef0123456789abcdef');

-- CASE: UnicodeTenantRejected EXPECT: 547
INSERT dbo.BAZDIDCustomerLinks (Id,BrokerageId,SourceSystem,SourceCustomerId)
VALUES (NEWID(),N'نام',N'SYNTHETIC-SQL',N'OTHER-CUSTOMER');

-- CASE: UnicodeOpaqueSourceIdentifierPreserved EXPECT: NONE
INSERT dbo.BAZDIDCustomerLinks (Id,BrokerageId,SourceSystem,SourceCustomerId)
VALUES (NEWID(),N'TEST-BROKERAGE',N'SYNTHETIC-SQL',N'شناسه-آزمایشی');
IF NOT EXISTS (SELECT 1 FROM dbo.BAZDIDCustomerLinks
 WHERE SourceCustomerIdKey=CONVERT(varbinary(256),N'شناسه-آزمایشی')) THROW 51000,N'شناسهٔ Unicode حفظ نشد.',1;

-- CASE: InvalidEligibilityRejected EXPECT: 547
UPDATE dbo.BAZDIDRequestContexts SET EligibilityStatus='ForcedEligible' WHERE Id=@Context;

-- CASE: CustomerTimestampOrderRejected EXPECT: 547
UPDATE dbo.BAZDIDCustomerLinks SET UpdatedAtUtc=DATEADD(second,-1,CreatedAtUtc) WHERE Id=@Link;

-- CASE: RequestTimestampOrderRejected EXPECT: 547
UPDATE dbo.BAZDIDRequestContexts SET UpdatedAtUtc=DATEADD(second,-1,CreatedAtUtc) WHERE Id=@Context;

-- CASE: ReferralHmacWithoutKeyRejected EXPECT: 547
UPDATE dbo.BAZDIDRequestContexts SET ReferralLookupHmac=CONVERT(binary(32),0x01) WHERE Id=@Context;

-- CASE: IdentityKeyWithoutHmacRejected EXPECT: 547
UPDATE dbo.BAZDIDRequestContexts SET IdentityKeyId='TEST-KEY' WHERE Id=@Context;

-- CASE: PreviousIdentityHmacWithoutKeyRejected EXPECT: 547
UPDATE dbo.BAZDIDRequestContexts SET PreviousIdentityHmac=CONVERT(binary(32),0x01) WHERE Id=@Context;

-- CASE: PairedSyntheticHmacFieldsAccepted EXPECT: NONE
UPDATE dbo.BAZDIDRequestContexts SET ReferralLookupHmac=CONVERT(binary(32),0x01),ReferralKeyId='TEST-REFERRAL',
 IdentityHmac=CONVERT(binary(32),0x02),IdentityKeyId='TEST-IDENTITY',
 PreviousIdentityHmac=CONVERT(binary(32),0x03),PreviousIdentityKeyId='TEST-PREVIOUS' WHERE Id=@Context;

-- CASE: ReferralHashNotAssumedUnique EXPECT: NONE
UPDATE dbo.BAZDIDRequestContexts SET ReferralLookupHmac=CONVERT(binary(32),0x01),ReferralKeyId='TEST-KEY' WHERE Id=@Context;
INSERT dbo.BAZDIDRequestContexts (Id,BrokerageId,SourceSystem,CustomerLinkId,SourceRequestId,EligibilityStatus,SourceRetrievedAtUtc,ReferralLookupHmac,ReferralKeyId)
VALUES (NEWID(),N'TEST-BROKERAGE',N'SYNTHETIC-SQL',@Link,N'TEST-REQUEST-002','Eligible',SYSUTCDATETIME(),CONVERT(binary(32),0x01),'TEST-KEY');
IF (SELECT COUNT(*) FROM dbo.BAZDIDRequestContexts WHERE ReferralLookupHmac=CONVERT(binary(32),0x01))<>2 THROW 51000,N'یکتایی referral حدس زده شده است.',1;

-- CASE: AuditInvalidActorRejected EXPECT: 547
INSERT dbo.BAZDIDAuditLogs (BrokerageId,SourceSystem,ActorType,ActionCode,OutcomeCode,ResourceType,CorrelationId)
VALUES (N'TEST-BROKERAGE',N'SYNTHETIC-SQL','Invalid','SCHEMA_TEST','PASS','Schema','0123456789abcdef0123456789abcdef');

-- CASE: AuditInvalidCorrelationRejected EXPECT: 547
INSERT dbo.BAZDIDAuditLogs (BrokerageId,SourceSystem,ActorType,ActionCode,OutcomeCode,ResourceType,CorrelationId)
VALUES (N'TEST-BROKERAGE',N'SYNTHETIC-SQL','System','SCHEMA_TEST','PASS','Schema','g123456789abcdef0123456789abcdef');

-- CASE: AuditShortCorrelationRejected EXPECT: 547
INSERT dbo.BAZDIDAuditLogs (BrokerageId,SourceSystem,ActorType,ActionCode,OutcomeCode,ResourceType,CorrelationId)
VALUES (N'TEST-BROKERAGE',N'SYNTHETIC-SQL','System','SCHEMA_TEST','PASS','Schema','0123456789abcdef0123456789abcde');

-- CASE: AnonymousAuditWithoutContextAccepted EXPECT: NONE
INSERT dbo.BAZDIDAuditLogs (BrokerageId,SourceSystem,ActorType,ActionCode,OutcomeCode,ResourceType,CorrelationId)
VALUES (N'TEST-BROKERAGE',N'SYNTHETIC-SQL','Anonymous','SCHEMA_TEST','PASS','Schema','0123456789abcdef0123456789abcdef');

-- CASE: ParentDeleteDoesNotCascade EXPECT: 547
DELETE dbo.BAZDIDCustomerLinks WHERE Id=@Link;
