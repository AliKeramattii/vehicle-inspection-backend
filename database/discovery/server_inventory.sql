-- فقط metadata محلی؛ در master و با Windows Authentication روی lpc اجرا شود.
-- هیچ پایگاه کاربری باز یا تغییری در اشیای پایدار ایجاد نمی‌شود.
SET NOCOUNT ON;
DECLARE @ExpectedInstance sysname = N'SQLSERVER2019';
DECLARE @ApprovedTestDatabase sysname = N'BAZDID_Development';
IF DB_NAME() <> N'master'
   OR COALESCE(CONVERT(nvarchar(128), SERVERPROPERTY('InstanceName')), N'') <> @ExpectedInstance
   OR COALESCE(CONVERT(nvarchar(128), CONNECTIONPROPERTY('net_transport')), N'') <> N'Shared memory'
BEGIN
    RAISERROR(N'فقط master روی instance محلی مصوب و shared memory مجاز است.', 16, 1);
    RETURN;
END;
SELECT CONVERT(nvarchar(128), SERVERPROPERTY('ProductVersion')) AS ProductVersion,
       CONVERT(nvarchar(128), SERVERPROPERTY('ProductLevel')) AS ProductLevel,
       CONVERT(nvarchar(128), SERVERPROPERTY('Edition')) AS Edition,
       CONVERT(int, SERVERPROPERTY('EngineEdition')) AS EngineEdition,
       CONVERT(nvarchar(128), SERVERPROPERTY('InstanceName')) AS InstanceName,
       CONVERT(nvarchar(128), SERVERPROPERTY('Collation')) AS ServerCollation,
       CONVERT(nvarchar(128), CONNECTIONPROPERTY('net_transport')) AS NetTransport,
       CONVERT(nvarchar(128), CONNECTIONPROPERTY('auth_scheme')) AS AuthenticationScheme,
       CONVERT(int, SERVERPROPERTY('IsClustered')) AS IsClustered,
       CONVERT(int, SERVERPROPERTY('IsHadrEnabled')) AS IsHadrEnabled,
       HAS_PERMS_BY_NAME(NULL, NULL, 'VIEW ANY DATABASE') AS CanViewAnyDatabase,
       IS_SRVROLEMEMBER('sysadmin') AS CurrentIdentityIsSysadmin;
SELECT name, compatibility_level, collation_name, state_desc, is_read_only, source_database_id
FROM sys.databases ORDER BY database_id;
SELECT COUNT(*) AS LinkedServerCount FROM sys.servers WHERE is_linked = 1;
SELECT DB_ID(@ApprovedTestDatabase) AS ApprovedTestDatabaseId;
