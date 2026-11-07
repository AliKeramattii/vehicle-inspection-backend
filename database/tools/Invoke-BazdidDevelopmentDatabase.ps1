[CmdletBinding()]
param(
    [ValidateSet('Inspect','CreateDatabase','CreateTables','RepairTenantChecks','Verify','Test')]
    [string]$Action = 'Inspect',
    [switch]$ApproveLocalDdl,
    [switch]$ApproveRollbackTests,
    [string]$AuthorizationReference,
    [string]$ReviewedScriptSha256,
    [string]$EvidencePath
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Data
$databaseRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$approvedReference = '553dc9cd-5abe-4eb0-9856-ee1763d5250b'
$approvedDatabase = 'BAZDID_Development'

function Open-LocalConnection([string]$databaseName) {
    if ($databaseName -notin @('master',$approvedDatabase)) { throw 'پایگاه خارج از دامنهٔ مصوب است.' }
    $builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
    # D-P3-NAME (2026-11-07): certificate معتبر P3 نام localhost را دارد؛ استثنای قبلی TrustServerCertificate حذف شد.
    $builder['Data Source'] = 'lpc:localhost\SQLSERVER2019'
    $builder['Initial Catalog'] = $databaseName
    $builder['Integrated Security'] = $true
    $builder['Encrypt'] = $true
    $builder['TrustServerCertificate'] = $false
    $builder['Connect Timeout'] = 5
    $builder['Application Name'] = 'BAZDID-Checkpoint2C-ControlledLocal'
    $connection = New-Object System.Data.SqlClient.SqlConnection($builder.ConnectionString)
    $connection.Open()
    return $connection
}

function Read-SqlSets($connection, [string]$sql, $parameters = @{}) {
    $command = $connection.CreateCommand()
    $command.CommandTimeout = 15
    $command.CommandText = $sql
    foreach ($name in $parameters.Keys) {
        $parameter = $command.Parameters.Add($name, [System.Data.SqlDbType]::NVarChar, 128)
        $parameter.Value = $parameters[$name]
    }
    $reader = $null
    try {
        $reader = $command.ExecuteReader()
        $sets = New-Object 'System.Collections.Generic.List[object]'
        do {
            $rows = New-Object 'System.Collections.Generic.List[object]'
            while ($reader.Read()) {
                $row = [ordered]@{}
                for ($column = 0; $column -lt $reader.FieldCount; $column++) {
                    $row[$reader.GetName($column)] = if ($reader.IsDBNull($column)) { $null } else { $reader.GetValue($column) }
                }
                $rows.Add([pscustomobject]$row)
            }
            $sets.Add($rows.ToArray())
        } while ($reader.NextResult())
        return [pscustomobject]@{ Sets = $sets.ToArray() }
    } finally {
        if ($reader) { $reader.Dispose() }
        $command.Dispose()
    }
}

function Get-VerifiedTarget($connection) {
    $query = @'
SELECT CONVERT(nvarchar(128),SERVERPROPERTY('InstanceName')) AS InstanceName,
 CONVERT(nvarchar(128),SERVERPROPERTY('ProductVersion')) AS ProductVersion,
 CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) AS ProductMajorVersion,
 CONVERT(nvarchar(128),SERVERPROPERTY('Edition')) AS Edition,
 CONVERT(nvarchar(128),CONNECTIONPROPERTY('net_transport')) AS NetTransport,
 CONVERT(nvarchar(128),CONNECTIONPROPERTY('auth_scheme')) AS AuthenticationScheme,
 CASE WHEN CONVERT(nvarchar(128),SERVERPROPERTY('MachineName'))=@ExpectedMachine THEN 1 ELSE 0 END AS MachineMatchesLocal,
 CONVERT(int,SERVERPROPERTY('IsClustered')) AS IsClustered,
 CONVERT(int,SERVERPROPERTY('IsHadrEnabled')) AS IsHadrEnabled,
 IS_SRVROLEMEMBER('sysadmin') AS ProvisionerIsSysadmin,
 (SELECT COUNT(*) FROM sys.servers WHERE is_linked=1) AS LinkedServers,
 (SELECT COUNT(*) FROM sys.databases WHERE database_id>4 AND name<>N'BAZDID_Development') AS UnexpectedUserDatabases,
 (SELECT COUNT(*) FROM model.sys.objects WHERE is_ms_shipped=0) AS ModelUserObjects,
 DB_ID(N'BAZDID_Development') AS DevelopmentDatabaseId,
 CONVERT(nvarchar(4000),SERVERPROPERTY('InstanceDefaultDataPath')) AS DefaultDataPath,
 CONVERT(nvarchar(4000),SERVERPROPERTY('InstanceDefaultLogPath')) AS DefaultLogPath;
SELECT name,compatibility_level,collation_name,recovery_model_desc,state_desc,is_read_only,
 is_auto_close_on,is_auto_shrink_on,page_verify_option_desc
FROM sys.databases ORDER BY database_id;
SELECT name,type_desc,physical_name,size/128.0 AS SizeMb,
 CASE WHEN is_percent_growth=1 THEN NULL ELSE growth/128.0 END AS GrowthMb,is_percent_growth
FROM sys.master_files WHERE database_id=3 ORDER BY file_id;
'@
    $result = Read-SqlSets $connection $query @{'@ExpectedMachine'=$env:COMPUTERNAME}
    $target = $result.Sets[0][0]
    if ($target.InstanceName -ne 'SQLSERVER2019' -or $target.ProductMajorVersion -ne 15 -or
        $target.NetTransport -ne 'Shared memory' -or $target.AuthenticationScheme -notin @('NTLM','KERBEROS') -or
        $target.MachineMatchesLocal -ne 1 -or $target.IsClustered -ne 0 -or $target.IsHadrEnabled -ne 0 -or
        $target.ProvisionerIsSysadmin -ne 1 -or $target.LinkedServers -ne 0 -or $target.UnexpectedUserDatabases -ne 0 -or
        $target.ModelUserObjects -ne 0) {
        throw 'هویت/جداسازی مقصد محلی با مجوز Checkpoint 2C مطابقت ندارد؛ DDL اجرا نشد.'
    }
    if (-not $target.DefaultDataPath -or -not $target.DefaultLogPath) { throw 'مسیر پیش‌فرض فایل‌ها قابل تأیید نیست.' }
    $volumes = @()
    foreach ($path in @($target.DefaultDataPath,$target.DefaultLogPath) | Select-Object -Unique) {
        if (-not [IO.Path]::IsPathRooted($path) -or -not (Test-Path -LiteralPath $path -PathType Container)) { throw 'پوشهٔ محلی فایل SQL تأیید نشد.' }
        $drive = New-Object System.IO.DriveInfo([IO.Path]::GetPathRoot($path))
        if ($drive.DriveType -ne [IO.DriveType]::Fixed -or $drive.AvailableFreeSpace -lt 2GB) { throw 'دیسک ثابت محلی با حداقل دو گیگابایت فضای آزاد لازم است.' }
        $volumes += [pscustomobject]@{Root=$drive.Name;AvailableFreeBytes=$drive.AvailableFreeSpace;TotalBytes=$drive.TotalSize}
    }
    return [pscustomobject]@{Target=$target;Databases=$result.Sets[1];ModelFiles=$result.Sets[2];Volumes=$volumes}
}

function Invoke-ApprovedDdl($connection,[string]$fileName) {
    if (-not $ApproveLocalDdl -or $AuthorizationReference -ne $approvedReference -or
        $ReviewedScriptSha256 -notmatch '^[0-9a-fA-F]{64}$') { throw 'مجوز محدود DDL و hash پیش‌نویس بازبینی‌شده لازم است.' }
    $scriptPath = Join-Path $databaseRoot ('proposals\'+$fileName)
    if ((Get-FileHash -LiteralPath $scriptPath -Algorithm SHA256).Hash -ne $ReviewedScriptSha256) { throw 'پیش‌نویس پس از بازبینی تغییر کرده است؛ اجرا متوقف شد.' }
    $sql = [IO.File]::ReadAllText($scriptPath)
    if ([regex]::Matches($sql,'DECLARE @AllowDdl bit = 0;').Count -ne 1 -or
        [regex]::Matches($sql,'DECLARE @ApprovalReference nvarchar\(128\) = NULL;').Count -ne 1) { throw 'guard پیش‌فرض پیش‌نویس معتبر نیست.' }
    # تنها دو مقدار در نسخهٔ حافظه‌ای عوض می‌شوند؛ فایل review همچنان بسته می‌ماند.
    $sql = $sql.Replace('DECLARE @AllowDdl bit = 0;','DECLARE @AllowDdl bit = 1;')
    $sql = $sql.Replace('DECLARE @ApprovalReference nvarchar(128) = NULL;',"DECLARE @ApprovalReference nvarchar(128) = N'$approvedReference';")
    $command = $connection.CreateCommand()
    try {
        $command.CommandTimeout = 60
        $command.CommandText = $sql
        $null = $command.ExecuteNonQuery()
    } finally { $command.Dispose() }
}

function Normalize-SqlExpression($value) {
    return ([regex]::Replace([string]$value,'[\[\]\s(),]','')).ToUpperInvariant()
}

function Get-VerifiedSchema($connection) {
    $contract = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $databaseRoot 'verification\schema_expected.json') | ConvertFrom-Json
    $metadata = Read-SqlSets $connection ([IO.File]::ReadAllText((Join-Path $databaseRoot 'verification\checkpoint2c_metadata.sql')))
    $configuration = $metadata.Sets[0][0]
    if ($configuration.name -ne $approvedDatabase -or $configuration.compatibility_level -ne $contract.Compatibility -or
        $configuration.collation_name -ne $contract.Collation -or $configuration.recovery_model_desc -ne $contract.Recovery -or
        $configuration.state_desc -ne 'ONLINE' -or $configuration.is_read_only -or $configuration.is_auto_close_on -or
        $configuration.is_auto_shrink_on -or $configuration.page_verify_option_desc -ne 'CHECKSUM') { throw 'تنظیمات واقعی پایگاه با قرارداد تست برابر نیست.' }
    $tableNames = @($contract.Tables.PSObject.Properties.Name | Sort-Object)
    if ((@($metadata.Sets[1].TableName | Sort-Object) -join '|') -ne ($tableNames -join '|') -or
        @($metadata.Sets[1] | Where-Object {$_.SchemaName -ne 'dbo'}).Count -ne 0) { throw 'فهرست جدول‌ها دقیقاً همان سه شیء مصوب نیست.' }
    $expectedColumnCount = 0
    $expectedIndexCount = 0
    $expectedCheckCount = 0
    foreach ($table in $tableNames) {
        $expected = $contract.Tables.$table
        $columns = @($metadata.Sets[2] | Where-Object {$_.TableName -eq $table} | Sort-Object Ordinal)
        if ($columns.Count -ne $expected.Columns.Count) { throw ('تعداد ستون نامعتبر: '+$table) }
        for ($columnIndex = 0; $columnIndex -lt $columns.Count; $columnIndex++) {
            $actualColumn = $columns[$columnIndex]
            $expectedColumn = $expected.Columns[$columnIndex]
            if ($actualColumn.ColumnName -ne $expectedColumn.Name -or $actualColumn.TypeName -ne $expectedColumn.Type -or
                $actualColumn.MaxLength -ne $expectedColumn.MaxLength -or $actualColumn.IsComputed -ne $expectedColumn.IsComputed -or
                $actualColumn.IsIdentity -ne $expectedColumn.IsIdentity) { throw ('تعریف ستون با قرارداد فرق دارد: '+$table+'.'+$expectedColumn.Name) }
            if ($expectedColumn.PSObject.Properties.Name -contains 'IsNullable') {
                if ($actualColumn.IsNullable -ne $expectedColumn.IsNullable) { throw ('nullability ستون فرق دارد: '+$table+'.'+$expectedColumn.Name) }
            }
            if ($expectedColumn.PSObject.Properties.Name -contains 'Scale') {
                if ($actualColumn.Scale -ne $expectedColumn.Scale) { throw 'scale زمان معتبر نیست.' }
            }
            if ($expectedColumn.PSObject.Properties.Name -contains 'Collation') {
                if ($actualColumn.CollationName -ne $expectedColumn.Collation) { throw 'collation ستون معتبر نیست.' }
            }
            if ((Normalize-SqlExpression $actualColumn.DefaultDefinition) -ne (Normalize-SqlExpression $expectedColumn.Default)) { throw 'default ستون با قرارداد برابر نیست.' }
            if ($expectedColumn.IsComputed -and
                (-not $actualColumn.IsPersisted -or (Normalize-SqlExpression $actualColumn.ComputedDefinition) -ne (Normalize-SqlExpression $expectedColumn.Expression))) { throw 'computed key پایدار/دقیق نیست.' }
        }
        $indexRows = @($metadata.Sets[3] | Where-Object {$_.TableName -eq $table})
        if (@($indexRows.IndexName | Sort-Object -Unique).Count -ne $expected.Indexes.Count) { throw 'تعداد indexها با قرارداد برابر نیست.' }
        foreach ($index in $expected.Indexes) {
            $rows = @($indexRows | Where-Object {$_.IndexName -eq $index.Name})
            $keys = @($rows | Where-Object {$_.KeyOrdinal -gt 0} | Sort-Object KeyOrdinal | ForEach-Object {$_.ColumnName})
            if ($rows.Count -eq 0 -or ($keys -join '|') -ne ($index.Keys -join '|') -or
                $rows[0].IsUnique -ne $index.Unique -or $rows[0].IsPrimaryKey -ne $index.PrimaryKey -or
                $rows[0].IsUniqueConstraint -ne $index.UniqueConstraint -or @($rows | Where-Object {$_.IsDisabled -or $_.IsDescending -or $_.IsIncluded}).Count -ne 0 -or
                (Normalize-SqlExpression $rows[0].FilterDefinition) -ne (Normalize-SqlExpression $index.Filter)) { throw ('index با قرارداد برابر نیست: '+$index.Name) }
            $expectedType = if ($index.PrimaryKey) {'CLUSTERED'} else {'NONCLUSTERED'}
            if ($rows[0].TypeDescription -ne $expectedType) { throw 'نوع index معتبر نیست.' }
        }
        $checks = @($metadata.Sets[5] | Where-Object {$_.TableName -eq $table})
        if ((@($checks.ConstraintName | Sort-Object) -join '|') -ne (@($expected.Checks | Sort-Object) -join '|') -or
            @($checks | Where-Object {$_.IsDisabled -or $_.IsNotTrusted}).Count -ne 0) { throw 'CHECKهای فعال/مورد اعتماد کامل نیستند.' }
        # SQL Server عبارت NOT LIKE را در definition به NOT expression LIKE بازنویسی می‌کند.
        $tenantExpression = "LEN(BrokerageId)>0 AND NOT REPLACE(BrokerageId,N'-',N'') LIKE N'%[^A-Za-z0-9_]%' AND LEN(SourceSystem)>0 AND NOT REPLACE(SourceSystem,N'-',N'') LIKE N'%[^A-Za-z0-9_]%'"
        $tenantCheck = @($checks | Where-Object {$_.ConstraintName -eq ('CK_'+$table+'_Tenant')})
        if ($tenantCheck.Count -ne 1 -or (Normalize-SqlExpression $tenantCheck[0].Definition) -ne (Normalize-SqlExpression $tenantExpression)) { throw 'عبارت اصلاح‌شدهٔ CHECK tenant تأیید نشد.' }
        $expectedColumnCount += $columns.Count
        $expectedIndexCount += $expected.Indexes.Count
        $expectedCheckCount += $checks.Count
    }
    $foreignKey = $contract.ForeignKey
    $foreignRows = @($metadata.Sets[4] | Sort-Object Ordinal)
    if ($foreignRows.Count -ne 3 -or @($foreignRows.ForeignKeyName | Select-Object -Unique).Count -ne 1 -or
        $foreignRows[0].ForeignKeyName -ne $foreignKey.Name -or $foreignRows[0].ParentTable -ne $foreignKey.Parent -or
        $foreignRows[0].ReferencedTable -ne $foreignKey.Referenced -or
        ($foreignRows.ParentColumn -join '|') -ne ($foreignKey.ParentColumns -join '|') -or
        ($foreignRows.ReferencedColumn -join '|') -ne ($foreignKey.ReferencedColumns -join '|') -or
        @($foreignRows | Where-Object {$_.IsDisabled -or $_.IsNotTrusted -or $_.DeleteAction -ne 'NO_ACTION' -or $_.UpdateAction -ne 'NO_ACTION'}).Count -ne 0) { throw 'FK ترکیبی داخلی با قرارداد برابر نیست.' }
    if (@($metadata.Sets[6] | Where-Object {$_.RowCount -ne 0}).Count -ne 0) { throw 'پایگاه تست خالی نیست؛ دادهٔ موجود لمس نمی‌شود.' }
    if ($metadata.Sets[7].Count -ne 2) { throw 'تعداد فایل‌های پایگاه با طرح تست برابر نیست.' }
    foreach ($file in $metadata.Sets[7]) {
        $expectedMax = if ($file.FileType -eq 'ROWS') {512} else {256}
        $expectedName = if ($file.FileType -eq 'ROWS') {$approvedDatabase} else {$approvedDatabase+'_log'}
        if ($file.LogicalName -ne $expectedName -or $file.SizeMb -lt 16 -or $file.GrowthMb -ne 16 -or
            $file.IsPercentGrowth -or $file.MaxSizeMb -ne $expectedMax) { throw 'تعریف فایل پایگاه با طرح تست برابر نیست.' }
    }
    return [pscustomobject]@{
        Status='Passed';Database=$approvedDatabase;Tables=3;Columns=$expectedColumnCount;Indexes=$expectedIndexCount;
        PrimaryKeys=3;UniqueConstraints=3;ForeignKeys=1;CheckConstraints=$expectedCheckCount;
        RowVersionColumns=2;PersistedComputedKeys=2;RowCounts=$metadata.Sets[6];Metadata=$metadata.Sets
    }
}

function Save-VerificationEvidence($evidence) {
    if (-not $EvidencePath) { return }
    $projectRoot = [IO.Path]::GetFullPath((Join-Path $databaseRoot '..'))
    $approvedEvidenceRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot 'docs\checkpoint2c'))+[IO.Path]::DirectorySeparatorChar
    $outputPath = [IO.Path]::GetFullPath((Join-Path (Get-Location).Path $EvidencePath))
    if (-not $outputPath.StartsWith($approvedEvidenceRoot,[StringComparison]::OrdinalIgnoreCase) -or
        [IO.Path]::GetExtension($outputPath) -ne '.json') { throw 'خروجی شاهد فقط در docs/checkpoint2c و با پسوند JSON مجاز است.' }
    $null = [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($outputPath))
    [IO.File]::WriteAllText($outputPath,($evidence | ConvertTo-Json -Depth 20), (New-Object Text.UTF8Encoding($false)))
}

function Invoke-RollbackVerification($connection) {
    if (-not $ApproveRollbackTests -or $AuthorizationReference -ne $approvedReference -or
        $ReviewedScriptSha256 -notmatch '^[0-9a-fA-F]{64}$') { throw 'مجوز تست rollback-only و hash فایل بازبینی‌شده لازم است.' }
    $casePath = Join-Path $databaseRoot 'verification\checkpoint2c_rollback_cases.sql'
    if ((Get-FileHash -LiteralPath $casePath -Algorithm SHA256).Hash -ne $ReviewedScriptSha256) { throw 'فایل آزمون پس از بازبینی تغییر کرده است.' }
    $caseText = [IO.File]::ReadAllText($casePath)
    $headers = [regex]::Matches($caseText,'(?m)^-- CASE: (\w+) EXPECT: (NONE|[0-9,]+)\s*\r?\n')
    if ($headers.Count -eq 0) { throw 'فهرست CASEها خالی است.' }
    $fixture = $caseText.Substring(0,$headers[0].Index)
    $null = Get-VerifiedSchema $connection
    $settings = $connection.CreateCommand()
    try {
        $settings.CommandText = 'SET NOCOUNT ON; SET XACT_ABORT OFF; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET CONCAT_NULL_YIELDS_NULL ON; SET ARITHABORT ON; SET NUMERIC_ROUNDABORT OFF;'
        $null = $settings.ExecuteNonQuery()
    } finally { $settings.Dispose() }
    $results = New-Object 'System.Collections.Generic.List[object]'
    for ($caseIndex = 0; $caseIndex -lt $headers.Count; $caseIndex++) {
        $header = $headers[$caseIndex]
        $caseName = $header.Groups[1].Value
        $expectedErrors = if ($header.Groups[2].Value -eq 'NONE') { @() } else { @($header.Groups[2].Value.Split(',') | ForEach-Object {[int]$_}) }
        $start = $header.Index+$header.Length
        $end = if ($caseIndex+1 -lt $headers.Count) {$headers[$caseIndex+1].Index} else {$caseText.Length}
        $sql = $fixture+[Environment]::NewLine+$caseText.Substring($start,$end-$start)
        $transaction = $connection.BeginTransaction([System.Data.IsolationLevel]::ReadCommitted)
        $command = $connection.CreateCommand()
        $observed = @()
        $observedConstraints = @()
        try {
            $command.Transaction = $transaction
            $command.CommandTimeout = 15
            $command.CommandText = $sql
            try { $null = $command.ExecuteNonQuery() }
            catch {
                $failure = $_.Exception
                while ($failure -and -not ($failure -is [System.Data.SqlClient.SqlException])) { $failure = $failure.InnerException }
                if (-not $failure) { throw }
                $observed = @($failure.Errors | ForEach-Object {$_.Number} | Sort-Object -Unique)
                $observedConstraints = @($failure.Errors | ForEach-Object {
                    [regex]::Matches($_.Message,'(?:CK|FK|UQ|PK)_BAZDID[A-Za-z0-9_]+') | ForEach-Object {$_.Value}
                } | Sort-Object -Unique)
            }
        } finally {
            $command.Dispose()
            try { $transaction.Rollback() } finally { $transaction.Dispose() }
        }
        $matched = if ($expectedErrors.Count -eq 0) { $observed.Count -eq 0 } else {
            @($observed | Where-Object {$_ -in $expectedErrors}).Count -gt 0 -and
            @($observed | Where-Object {$_ -notin $expectedErrors -and $_ -ne 3621}).Count -eq 0
        }
        if (-not $matched) { throw ('CASE ناموفق: '+$caseName+'؛ کدهای SQL: '+($observed -join ',')+'؛ قیود: '+($observedConstraints -join ',')) }
        $cleanup = Read-SqlSets $connection 'SELECT (SELECT COUNT_BIG(*) FROM dbo.BAZDIDCustomerLinks) AS Links,(SELECT COUNT_BIG(*) FROM dbo.BAZDIDRequestContexts) AS Contexts,(SELECT COUNT_BIG(*) FROM dbo.BAZDIDAuditLogs) AS AuditRows,@@TRANCOUNT AS TransactionCount;'
        $counts = $cleanup.Sets[0][0]
        if ($counts.Links -ne 0 -or $counts.Contexts -ne 0 -or $counts.AuditRows -ne 0 -or $counts.TransactionCount -ne 0) { throw 'rollback کامل نیست؛ تست متوقف شد.' }
        $results.Add([pscustomobject]@{Name=$caseName;Status='Passed';ExpectedErrorNumbers=@($expectedErrors);ObservedErrorNumbers=$observed;ConstraintNames=$observedConstraints;RolledBack=$true})
    }
    $finalVerification = Get-VerifiedSchema $connection
    return [pscustomobject]@{Status='Passed';Database=$approvedDatabase;TestCount=$results.Count;
        Cases=$results.ToArray();RollbackVerifiedAfterEveryCase=$true;FinalRowCounts=$finalVerification.RowCounts;
        IdentityAndRowVersionCountersMayAdvance=$true;ApplicationSqlIntegrationTested=$false}
}

$masterConnection = $null
try {
    $masterConnection = Open-LocalConnection 'master'
    $inspection = Get-VerifiedTarget $masterConnection
    if ($Action -eq 'Inspect') {
        $inspection | ConvertTo-Json -Depth 10
    } elseif ($Action -eq 'CreateDatabase') {
        if ($null -ne $inspection.Target.DevelopmentDatabaseId) { throw 'پایگاه از قبل موجود است؛ جایگزینی خودکار مجاز نیست.' }
        foreach ($targetFile in @(
            (Join-Path $inspection.Target.DefaultDataPath 'BAZDID_Development.mdf'),
            (Join-Path $inspection.Target.DefaultLogPath 'BAZDID_Development_log.ldf'))) {
            if (Test-Path -LiteralPath $targetFile) { throw 'فایل مقصد از قبل موجود است؛ حذف یا اتصال خودکار مجاز نیست.' }
        }
        Invoke-ApprovedDdl $masterConnection 'create_development_database.review.sql'
        [pscustomobject]@{Action=$Action;Database=$approvedDatabase;Status='Created';ReviewScriptStillGuarded=$true} | ConvertTo-Json -Compress
    } elseif ($Action -eq 'CreateTables') {
        if ($null -eq $inspection.Target.DevelopmentDatabaseId) { throw 'پایگاه تست هنوز وجود ندارد.' }
        $developmentConnection = Open-LocalConnection $approvedDatabase
        try { Invoke-ApprovedDdl $developmentConnection 'initial_tables.review.sql' }
        finally { $developmentConnection.Dispose() }
        [pscustomobject]@{Action=$Action;Database=$approvedDatabase;Status='ThreeTablesCreated';ReviewScriptStillGuarded=$true} | ConvertTo-Json -Compress
    } elseif ($Action -eq 'RepairTenantChecks') {
        if ($null -eq $inspection.Target.DevelopmentDatabaseId) { throw 'پایگاه تست وجود ندارد.' }
        $developmentConnection = Open-LocalConnection $approvedDatabase
        try { Invoke-ApprovedDdl $developmentConnection 'repair_tenant_checks.review.sql' }
        finally { $developmentConnection.Dispose() }
        [pscustomobject]@{Action=$Action;Database=$approvedDatabase;Status='ThreeChecksRevalidated';ReviewScriptStillGuarded=$true} | ConvertTo-Json -Compress
    } elseif ($Action -eq 'Verify') {
        if ($null -eq $inspection.Target.DevelopmentDatabaseId) { throw 'پایگاه تست وجود ندارد.' }
        $developmentConnection = Open-LocalConnection $approvedDatabase
        try { $verification = Get-VerifiedSchema $developmentConnection }
        finally { $developmentConnection.Dispose() }
        Save-VerificationEvidence $verification
        $verification | Select-Object Status,Database,Tables,Columns,Indexes,PrimaryKeys,UniqueConstraints,ForeignKeys,CheckConstraints,RowVersionColumns,PersistedComputedKeys,RowCounts | ConvertTo-Json -Depth 5
    } elseif ($Action -eq 'Test') {
        if ($null -eq $inspection.Target.DevelopmentDatabaseId) { throw 'پایگاه تست وجود ندارد.' }
        $developmentConnection = Open-LocalConnection $approvedDatabase
        try { $testResults = Invoke-RollbackVerification $developmentConnection }
        finally { $developmentConnection.Dispose() }
        Save-VerificationEvidence $testResults
        $testResults | Select-Object Status,Database,TestCount,RollbackVerifiedAfterEveryCase,FinalRowCounts,IdentityAndRowVersionCountersMayAdvance,ApplicationSqlIntegrationTested | ConvertTo-Json -Depth 5
    } else {
        throw 'این action هنوز آمادهٔ اجرا نیست؛ فقط بررسی خواندنی انجام شد.'
    }
} finally {
    if ($masterConnection) { $masterConnection.Dispose() }
}
