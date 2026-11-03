using System;
using System.Data;
using System.Data.SqlClient;
using Bazdid.Api.Domain.Brokerage;
using Bazdid.Api.Domain.Persistence;

namespace Bazdid.Api.Infrastructure.Sql
{
    internal static class SqlCommands
    {
        internal const string CustomerColumns = "Id,BrokerageId,SourceSystem,SourceCustomerId,CreatedAtUtc,UpdatedAtUtc,RowVersion";
        internal const string ContextColumns = "Id,BrokerageId,SourceSystem,SourceRequestId,CustomerLinkId,EligibilityStatus,SourceVersion,SourceRetrievedAtUtc,ReferralLookupHmac,ReferralKeyId,IdentityHmac,IdentityKeyId,PreviousIdentityHmac,PreviousIdentityKeyId,RowVersion";
        private const string CustomerKey = "BrokerageId=@Brokerage AND SourceSystem=@Source AND SourceCustomerIdKey=@CustomerKey";
        private const string RequestKey = "BrokerageId=@Brokerage AND SourceSystem=@Source AND SourceRequestIdKey=@RequestKey";

        internal static SqlParameter Parameter(SqlCommand command, string name, SqlDbType type, int size, bool nullable, object value)
        {
            var parameter = command.Parameters.Add(name, type, size);
            parameter.IsNullable = nullable;
            parameter.Value = value ?? DBNull.Value;
            if (type == SqlDbType.DateTime2) parameter.Scale = 3;
            return parameter;
        }
        private static void Scope(SqlCommand command, BrokerageScope scope)
        {
            if (scope == null) throw new ArgumentNullException(nameof(scope));
            Parameter(command,"@Brokerage",SqlDbType.NVarChar,32,false,scope.BrokerageId);
            Parameter(command,"@Source",SqlDbType.NVarChar,32,false,scope.SourceSystem);
        }
        internal static SqlCommand Customer(BrokerageScope scope, string customerId, bool create)
        {
            var key = PersistenceInput.SourceKey(customerId);
            var command = new SqlCommand();
            Scope(command,scope);
            Parameter(command,"@CustomerKey",SqlDbType.VarBinary,256,false,key);
            if (create)
            {
                Parameter(command,"@Id",SqlDbType.UniqueIdentifier,16,false,Guid.NewGuid());
                Parameter(command,"@CustomerId",SqlDbType.NVarChar,128,false,customerId);
                command.CommandText = @"SET NOCOUNT ON; DECLARE @Created bit=0;
IF NOT EXISTS (SELECT 1 FROM dbo.BAZDIDCustomerLinks WITH (UPDLOCK,HOLDLOCK) WHERE " + CustomerKey + @")
BEGIN
 INSERT dbo.BAZDIDCustomerLinks (Id,BrokerageId,SourceSystem,SourceCustomerId) VALUES (@Id,@Brokerage,@Source,@CustomerId);
 SET @Created=1;
END;
SELECT " + CustomerColumns + ",@Created AS Created FROM dbo.BAZDIDCustomerLinks WHERE " + CustomerKey + ";";
            }
            else command.CommandText = "SELECT " + CustomerColumns + " FROM dbo.BAZDIDCustomerLinks WHERE " + CustomerKey + ";";
            return command;
        }
        private static SqlCommand ContextKey(BrokerageRequestReference request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));
            var key = PersistenceInput.SourceKey(request.SourceRequestId);
            var command = new SqlCommand();
            Scope(command,request.Scope);
            Parameter(command,"@RequestKey",SqlDbType.VarBinary,256,false,key);
            return command;
        }
        internal static SqlCommand FindContext(BrokerageRequestReference request)
        {
            var command = ContextKey(request);
            command.CommandText = "SELECT " + ContextColumns + " FROM dbo.BAZDIDRequestContexts WHERE " + RequestKey + ";";
            return command;
        }
        private static void Owner(SqlCommand command, BrokerageRequestReference request, CustomerLinkRecord customer)
        {
            if (customer == null) throw new ArgumentNullException(nameof(customer));
            if (!request.Scope.Equals(customer.Scope)) throw new PersistenceException(PersistenceFailure.OwnershipConflict);
            Parameter(command,"@CustomerLinkId",SqlDbType.UniqueIdentifier,16,false,customer.Id);
            Parameter(command,"@CustomerKey",SqlDbType.VarBinary,256,false,PersistenceInput.SourceKey(customer.SourceCustomerId));
        }
        private const string OwnerGuard = @"IF NOT EXISTS (SELECT 1 FROM dbo.BAZDIDCustomerLinks WITH (HOLDLOCK)
 WHERE BrokerageId=@Brokerage AND SourceSystem=@Source AND Id=@CustomerLinkId AND SourceCustomerIdKey=@CustomerKey)
 THROW 51001, 'BAZDID_OWNER_CONFLICT', 1; ";
        private static void Hmac(SqlCommand command, string digestName, string keyName, HmacReference value)
        {
            Parameter(command,digestName,SqlDbType.Binary,32,true,value?.ToArray());
            Parameter(command,keyName,SqlDbType.VarChar,32,true,value?.KeyId);
        }
        private static void Metadata(SqlCommand command, RequestMetadata metadata)
        {
            if (metadata == null) throw new ArgumentNullException(nameof(metadata));
            Parameter(command,"@Eligibility",SqlDbType.VarChar,16,false,metadata.Eligibility.ToString());
            Parameter(command,"@SourceVersion",SqlDbType.NVarChar,128,true,metadata.SourceVersion);
            Parameter(command,"@Retrieved",SqlDbType.DateTime2,8,false,metadata.RetrievedAtUtc.UtcDateTime);
            Hmac(command,"@ReferralHmac","@ReferralKey",metadata.Referral);
            Hmac(command,"@IdentityHmac","@IdentityKey",metadata.Identity);
            Hmac(command,"@PreviousHmac","@PreviousKey",metadata.PreviousIdentity);
        }
        internal static SqlCommand CreateContext(BrokerageRequestReference request, CustomerLinkRecord customer, RequestMetadata metadata)
        {
            var command = ContextKey(request);
            try
            {
                Owner(command,request,customer); Metadata(command,metadata);
                Parameter(command,"@Id",SqlDbType.UniqueIdentifier,16,false,Guid.NewGuid());
                Parameter(command,"@RequestId",SqlDbType.NVarChar,128,false,request.SourceRequestId);
                command.CommandText = @"SET NOCOUNT ON; " + OwnerGuard + @"DECLARE @Created bit=0;
IF NOT EXISTS (SELECT 1 FROM dbo.BAZDIDRequestContexts WITH (UPDLOCK,HOLDLOCK) WHERE " + RequestKey + @")
BEGIN
 INSERT dbo.BAZDIDRequestContexts (Id,BrokerageId,SourceSystem,CustomerLinkId,SourceRequestId,EligibilityStatus,SourceVersion,SourceRetrievedAtUtc,
 ReferralLookupHmac,ReferralKeyId,IdentityHmac,IdentityKeyId,PreviousIdentityHmac,PreviousIdentityKeyId)
 VALUES (@Id,@Brokerage,@Source,@CustomerLinkId,@RequestId,@Eligibility,@SourceVersion,@Retrieved,@ReferralHmac,@ReferralKey,@IdentityHmac,@IdentityKey,@PreviousHmac,@PreviousKey);
 SET @Created=1;
END;
IF EXISTS (SELECT 1 FROM dbo.BAZDIDRequestContexts WHERE " + RequestKey + @" AND CustomerLinkId<>@CustomerLinkId)
 THROW 51001, 'BAZDID_OWNER_CONFLICT', 1;
SELECT " + ContextColumns + ",@Created AS Created FROM dbo.BAZDIDRequestContexts WHERE " + RequestKey + ";";
                return command;
            }
            catch { command.Dispose(); throw; }
        }
        internal static SqlCommand UpdateContext(Guid id, BrokerageRequestReference request, CustomerLinkRecord customer, RowVersionToken expected, RequestMetadata metadata)
        {
            PersistenceInput.Id(id);
            if (expected == null) throw new ArgumentNullException(nameof(expected));
            var command = ContextKey(request);
            try
            {
                Owner(command,request,customer); Metadata(command,metadata);
                Parameter(command,"@Id",SqlDbType.UniqueIdentifier,16,false,id);
                Parameter(command,"@ExpectedVersion",SqlDbType.Binary,8,false,expected.ToArray());
                command.CommandText = "SET NOCOUNT ON; " + OwnerGuard + @"
UPDATE dbo.BAZDIDRequestContexts SET EligibilityStatus=@Eligibility,SourceVersion=@SourceVersion,SourceRetrievedAtUtc=@Retrieved,
 ReferralLookupHmac=@ReferralHmac,ReferralKeyId=@ReferralKey,IdentityHmac=@IdentityHmac,IdentityKeyId=@IdentityKey,
 PreviousIdentityHmac=@PreviousHmac,PreviousIdentityKeyId=@PreviousKey,UpdatedAtUtc=SYSUTCDATETIME()
WHERE Id=@Id AND " + RequestKey + @" AND CustomerLinkId=@CustomerLinkId AND RowVersion=@ExpectedVersion;
IF @@ROWCOUNT=0 THROW 51002, 'BAZDID_VERSION_CONFLICT', 1;
SELECT " + ContextColumns + " FROM dbo.BAZDIDRequestContexts WHERE Id=@Id AND " + RequestKey + " AND CustomerLinkId=@CustomerLinkId;";
                return command;
            }
            catch { command.Dispose(); throw; }
        }
        internal static SqlCommand Audit(ContextAuditEvent auditEvent)
        {
            if (auditEvent == null) throw new ArgumentNullException(nameof(auditEvent));
            var command = new SqlCommand();
            Scope(command,auditEvent.Scope);
            Parameter(command,"@ContextId",SqlDbType.UniqueIdentifier,16,false,auditEvent.RequestContextId);
            Parameter(command,"@Action",SqlDbType.VarChar,64,false,auditEvent.Action.ToString());
            Parameter(command,"@Correlation",SqlDbType.Char,32,false,auditEvent.CorrelationId);
            command.CommandText = @"SET NOCOUNT ON;
IF NOT EXISTS (SELECT 1 FROM dbo.BAZDIDRequestContexts WHERE Id=@ContextId AND BrokerageId=@Brokerage AND SourceSystem=@Source)
 THROW 51001, 'BAZDID_OWNER_CONFLICT', 1;
INSERT dbo.BAZDIDAuditLogs (BrokerageId,SourceSystem,RequestContextId,ActorType,ActorId,ActionCode,OutcomeCode,ResourceType,ResourceId,CorrelationId,MetadataCode)
 VALUES (@Brokerage,@Source,@ContextId,'System',NULL,@Action,'Succeeded','RequestContext',@ContextId,@Correlation,NULL);";
            return command;
        }
    }
}
