-- فقط metadata و شمار ردیف سه جدول مصوب؛ برای پایگاه تست محلی موجود.
SET NOCOUNT ON;
IF DB_NAME()<>N'BAZDID_Development'
 OR COALESCE(CONVERT(nvarchar(128),SERVERPROPERTY('InstanceName')),N'')<>N'SQLSERVER2019'
 OR COALESCE(CONVERT(nvarchar(128),CONNECTIONPROPERTY('net_transport')),N'')<>N'Shared memory'
BEGIN
 RAISERROR(N'مقصد تأییدشدهٔ تست محلی لازم است.',16,1);
 RETURN;
END;
SELECT name,compatibility_level,collation_name,recovery_model_desc,state_desc,
 is_read_only,is_auto_close_on,is_auto_shrink_on,page_verify_option_desc
FROM sys.databases WHERE database_id=DB_ID();
SELECT s.name AS SchemaName,t.name AS TableName FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id=t.schema_id WHERE t.is_ms_shipped=0 ORDER BY t.name;
SELECT t.name AS TableName,c.column_id AS Ordinal,c.name AS ColumnName,ty.name AS TypeName,
 c.max_length AS MaxLength,c.precision AS Precision,c.scale AS Scale,c.is_nullable AS IsNullable,
 c.is_identity AS IsIdentity,c.is_computed AS IsComputed,c.collation_name AS CollationName,
 cc.is_persisted AS IsPersisted,cc.definition AS ComputedDefinition,dc.definition AS DefaultDefinition
FROM sys.tables AS t JOIN sys.columns AS c ON c.object_id=t.object_id
JOIN sys.types AS ty ON ty.user_type_id=c.user_type_id
LEFT JOIN sys.computed_columns AS cc ON cc.object_id=c.object_id AND cc.column_id=c.column_id
LEFT JOIN sys.default_constraints AS dc ON dc.object_id=c.default_object_id
WHERE t.is_ms_shipped=0 ORDER BY t.name,c.column_id;
SELECT t.name AS TableName,i.name AS IndexName,i.type_desc AS TypeDescription,
 i.is_unique AS IsUnique,i.is_primary_key AS IsPrimaryKey,i.is_unique_constraint AS IsUniqueConstraint,
 i.is_disabled AS IsDisabled,i.filter_definition AS FilterDefinition,
 c.name AS ColumnName,ic.key_ordinal AS KeyOrdinal,ic.is_descending_key AS IsDescending,
 ic.is_included_column AS IsIncluded
FROM sys.tables AS t JOIN sys.indexes AS i ON i.object_id=t.object_id
JOIN sys.index_columns AS ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id
JOIN sys.columns AS c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
WHERE t.is_ms_shipped=0 AND i.index_id>0 ORDER BY t.name,i.name,ic.index_column_id;
SELECT fk.name AS ForeignKeyName,pt.name AS ParentTable,pc.name AS ParentColumn,
 rt.name AS ReferencedTable,rc.name AS ReferencedColumn,fkc.constraint_column_id AS Ordinal,
 fk.is_disabled AS IsDisabled,fk.is_not_trusted AS IsNotTrusted,
 fk.delete_referential_action_desc AS DeleteAction,fk.update_referential_action_desc AS UpdateAction
FROM sys.foreign_keys AS fk JOIN sys.foreign_key_columns AS fkc ON fkc.constraint_object_id=fk.object_id
JOIN sys.tables AS pt ON pt.object_id=fk.parent_object_id
JOIN sys.columns AS pc ON pc.object_id=pt.object_id AND pc.column_id=fkc.parent_column_id
JOIN sys.tables AS rt ON rt.object_id=fk.referenced_object_id
JOIN sys.columns AS rc ON rc.object_id=rt.object_id AND rc.column_id=fkc.referenced_column_id
ORDER BY fk.name,fkc.constraint_column_id;
SELECT t.name AS TableName,ck.name AS ConstraintName,ck.is_disabled AS IsDisabled,
 ck.is_not_trusted AS IsNotTrusted,ck.definition AS Definition
FROM sys.check_constraints AS ck JOIN sys.tables AS t ON t.object_id=ck.parent_object_id
ORDER BY t.name,ck.name;
SELECT N'BAZDIDCustomerLinks' AS TableName,COUNT_BIG(*) AS [RowCount] FROM dbo.BAZDIDCustomerLinks
UNION ALL SELECT N'BAZDIDRequestContexts',COUNT_BIG(*) FROM dbo.BAZDIDRequestContexts
UNION ALL SELECT N'BAZDIDAuditLogs',COUNT_BIG(*) FROM dbo.BAZDIDAuditLogs;
SELECT name AS LogicalName,type_desc AS FileType,size/128.0 AS SizeMb,
 growth/128.0 AS GrowthMb,is_percent_growth AS IsPercentGrowth,max_size/128.0 AS MaxSizeMb
FROM sys.database_files ORDER BY file_id;
