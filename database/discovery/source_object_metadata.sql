-- نمونهٔ فقط‌خواندنی برای DBA؛ تا تعیین مقصد و شیء مصوب، بسته می‌ماند.
-- این فایل روی کارگزاری یا پایگاه Production در وظیفهٔ 2A/2B اجرا نشده است.
SET NOCOUNT ON;
DECLARE @ApprovedReadOnlyMetadata bit = 0;
DECLARE @ExpectedDatabase sysname = NULL;
DECLARE @SourceSchema sysname = NULL;
DECLARE @SourceTable sysname = NULL;
IF COALESCE(@ApprovedReadOnlyMetadata, 0) <> 1 OR @ExpectedDatabase IS NULL
   OR DB_NAME() <> @ExpectedDatabase OR DB_ID() <= 4
   OR @SourceSchema IS NULL OR @SourceTable IS NULL
BEGIN
    RAISERROR(N'مجوز خواندن metadata و نام دقیق پایگاه/schema/table لازم است.', 16, 1);
    RETURN;
END;
DECLARE @QualifiedObject nvarchar(517) = QUOTENAME(@SourceSchema) + N'.' + QUOTENAME(@SourceTable);
DECLARE @ObjectId int = OBJECT_ID(@QualifiedObject, N'U');
IF @ObjectId IS NULL OR COALESCE(HAS_PERMS_BY_NAME(@QualifiedObject, 'OBJECT', 'VIEW DEFINITION'), 0) <> 1
BEGIN
    RAISERROR(N'شیء یا مجوز metadata قابل تأیید نیست؛ نبود نتیجه اثبات نبود جدول نیست.', 16, 1);
    RETURN;
END;
SELECT name, compatibility_level, collation_name, state_desc
FROM sys.databases WHERE database_id = DB_ID();
SELECT s.name AS SchemaName, t.name AS TableName, t.object_id
FROM sys.tables AS t JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE t.object_id = @ObjectId;
SELECT c.column_id, c.name AS ColumnName, ts.name AS TypeSchema, ty.name AS TypeName,
       c.max_length, c.precision, c.scale, c.is_nullable, c.is_identity,
       c.is_computed, c.collation_name
FROM sys.columns AS c
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
JOIN sys.schemas AS ts ON ts.schema_id = ty.schema_id
WHERE c.object_id = @ObjectId ORDER BY c.column_id;
SELECT fk.name AS ForeignKeyName, ps.name AS ParentSchema, pt.name AS ParentTable,
       pc.name AS ParentColumn, rs.name AS ReferencedSchema, rt.name AS ReferencedTable,
       rc.name AS ReferencedColumn, fkc.constraint_column_id,
       fk.is_disabled, fk.is_not_trusted, fk.delete_referential_action_desc
FROM sys.foreign_keys AS fk
JOIN sys.foreign_key_columns AS fkc ON fkc.constraint_object_id = fk.object_id
JOIN sys.tables AS pt ON pt.object_id = fk.parent_object_id
JOIN sys.schemas AS ps ON ps.schema_id = pt.schema_id
JOIN sys.columns AS pc ON pc.object_id = pt.object_id AND pc.column_id = fkc.parent_column_id
JOIN sys.tables AS rt ON rt.object_id = fk.referenced_object_id
JOIN sys.schemas AS rs ON rs.schema_id = rt.schema_id
JOIN sys.columns AS rc ON rc.object_id = rt.object_id AND rc.column_id = fkc.referenced_column_id
WHERE fk.parent_object_id = @ObjectId OR fk.referenced_object_id = @ObjectId
ORDER BY fk.name, fkc.constraint_column_id;
SELECT i.name AS IndexName, i.type_desc, i.is_unique, i.is_primary_key,
       i.is_unique_constraint, i.is_disabled, i.has_filter,
       c.name AS ColumnName, ic.key_ordinal, ic.is_descending_key, ic.is_included_column
FROM sys.indexes AS i
JOIN sys.index_columns AS ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns AS c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
WHERE i.object_id = @ObjectId AND i.index_id > 0
ORDER BY i.index_id, ic.index_column_id;
-- definition، default literal، credential و هیچ ردیف تجاری خروجی داده نمی‌شود.
