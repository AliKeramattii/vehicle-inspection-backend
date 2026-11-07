<#
Checkpoint 2G — اجرای کنترل‌شدهٔ migrationهای BAZDID روی پایگاه یک‌بارمصرف BAZDID_MigrationTest.
مقصد تغییر، ثابت BAZDID_MigrationTest است و ورودی دلخواه نمی‌پذیرد. BAZDID_Development فقط خوانده می‌شود
(مرجع مقایسهٔ schema و snapshot قبل/بعد). اتصال: lpc:localhost\SQLSERVER2019، Integrated Security،
Encrypt=true، TrustServerCertificate=false، Shared memory؛ هویت اجرا login مالک (sysadmin)، نه هویت برنامه.
حالت‌ها:
  -Action Preflight                     فقط‌خواندنی
  -Action Accept   -ApproveDisposableDatabase -ApprovalReference <ref>
                   ساخت پایگاه، forward، تکرار، checksum نادرست، rollback، تکرار rollback، بازاعمال، guard داده،
                   adopt، حذف پایگاه پس از اثبات یک‌بارمصرف‌بودن؛ شاهد JSON در -EvidencePath
  -Action Cleanup  -ApproveDisposableDatabase -ApprovalReference <ref>
                   فقط حذف BAZDID_MigrationTest در صورت اثبات کامل نشانهٔ یک‌بارمصرف
#>
[CmdletBinding()]
param(
    [ValidateSet('Preflight', 'Accept', 'Cleanup')][string]$Action = 'Preflight',
    [switch]$ApproveDisposableDatabase,
    [ValidatePattern('^[A-Za-z0-9._-]{1,64}$')][string]$ApprovalReference,
    [string]$EvidencePath
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
Add-Type -AssemblyName System.Data

$TestDatabase = 'BAZDID_MigrationTest'
$ReferenceDatabase = 'BAZDID_Development'
$DisposableProperty = 'BAZDID.Disposable'
$DisposableValue = 'BAZDID_MigrationTest;Checkpoint2G;disposable'
$BaselineTables = @('BAZDIDCustomerLinks', 'BAZDIDRequestContexts', 'BAZDIDAuditLogs')
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$migrations = [ordered]@{
    Forward = @{ Path = 'migrations\0001_baseline.forward.sql'; Sha = '2568AA10017953AA0FA45BFBF15AF2F590B24E1B12E50EDCFCFCED47A16BD667' }
    Revert  = @{ Path = 'migrations\0001_baseline.revert.sql'; Sha = 'E97734D7170BFB1B6E960BC188198854285147BAD7C9429563D773865F6DB5FC' }
    Forward2 = @{ Path = 'migrations\0002_otp_session.forward.sql'; Sha = '544D33CB343DC9A6DCF3503603553D66F3F3AABC3648C800933DFF6173A00248' }
    Revert2  = @{ Path = 'migrations\0002_otp_session.revert.sql'; Sha = '66DDDD5A6129E1B425ED8E8540B18D056AAA06BAFAB1BBE16347FC997956F71C' }
}
$AuthTables = @('BAZDIDOtpChallenges', 'BAZDIDCustomerSessions', 'BAZDIDAuthRateCounters')
foreach ($m in $migrations.Values) {
    $full = Join-Path $root $m.Path
    $hash = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
    if ($hash -ne $m.Sha) { throw "hash فایل $($m.Path) با نسخهٔ بازبینی‌شده برابر نیست." }
    $m.Text = [IO.File]::ReadAllText($full, [Text.Encoding]::UTF8)
}
if ($Action -ne 'Preflight' -and (-not $ApproveDisposableDatabase -or -not $ApprovalReference)) {
    throw 'تغییر فقط با -ApproveDisposableDatabase و -ApprovalReference مجاز است.'
}

function Open-Db([string]$db) {
    if ($db -notin @('master', $TestDatabase, $ReferenceDatabase)) { throw 'پایگاه خارج از دامنه است.' }
    $b = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
    $b['Data Source'] = 'lpc:localhost\SQLSERVER2019'; $b['Initial Catalog'] = $db
    $b['Integrated Security'] = $true; $b['Encrypt'] = $true; $b['TrustServerCertificate'] = $false
    $b['Connect Timeout'] = 5; $b['Pooling'] = $false; $b['Application Name'] = 'BAZDID-2G-migration'
    $c = New-Object System.Data.SqlClient.SqlConnection($b.ConnectionString); $c.Open(); return $c
}
function Get-Rows([string]$db, [string]$sql, [hashtable]$p = @{}) {
    $c = Open-Db $db
    try {
        $cmd = $c.CreateCommand(); $cmd.CommandTimeout = 60; $cmd.CommandText = $sql
        foreach ($k in $p.Keys) { [void]$cmd.Parameters.AddWithValue($k, $p[$k]) }
        $t = New-Object System.Data.DataTable; $r = $cmd.ExecuteReader(); try { $t.Load($r) } finally { $r.Dispose() }
        return ,$t
    } finally { $c.Dispose() }
}
function Invoke-Sql([string]$db, [string]$sql) {
    $c = Open-Db $db
    try {
        $cmd = $c.CreateCommand(); $cmd.CommandTimeout = 120; $cmd.CommandText = $sql
        $t = New-Object System.Data.DataTable; $r = $cmd.ExecuteReader(); try { $t.Load($r) } finally { $r.Dispose() }
        if ($t.Columns.Contains('Result') -and $t.Rows.Count) { return [string]$t.Rows[0].Result }
        return ''
    } finally { $c.Dispose() }
}
function Get-Executable([string]$text, [hashtable]$values) {
    foreach ($k in $values.Keys) {
        if (([regex]::Matches($text, [regex]::Escape($k))).Count -ne 1) { throw "خط DECLARE دقیقاً یک بار یافت نشد: $k" }
        $text = $text.Replace($k, $values[$k])
    }
    return $text
}
function Get-ForwardSql([string]$checksum, [string]$text = $migrations.Forward.Text) {
    Get-Executable $text @{
        'DECLARE @AllowDdl bit = 0;'                       = 'DECLARE @AllowDdl bit = 1;'
        'DECLARE @ApprovalReference nvarchar(128) = NULL;' = "DECLARE @ApprovalReference nvarchar(128) = N'$ApprovalReference';"
        'DECLARE @MigrationChecksum char(64) = NULL;'      = "DECLARE @MigrationChecksum char(64) = '$checksum';"
    }
}
function Get-RevertSql([string]$text = $migrations.Revert.Text) {
    Get-Executable $text @{
        'DECLARE @AllowDdl bit = 0;'                       = 'DECLARE @AllowDdl bit = 1;'
        'DECLARE @ApprovalReference nvarchar(128) = NULL;' = "DECLARE @ApprovalReference nvarchar(128) = N'$ApprovalReference';"
    }
}

function Get-Target {
    (Get-Rows 'master' @"
SELECT CONVERT(nvarchar(128),SERVERPROPERTY('InstanceName')) AS Instance, CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) AS Major,
 CONVERT(nvarchar(128),SERVERPROPERTY('MachineName')) AS Machine, CONVERT(int,SERVERPROPERTY('IsClustered')) AS IsClustered, CONVERT(int,SERVERPROPERTY('IsHadrEnabled')) AS Hadr,
 CONVERT(nvarchar(128),CONNECTIONPROPERTY('net_transport')) AS Transport, (SELECT encrypt_option FROM sys.dm_exec_connections WHERE session_id=@@SPID) AS Encrypt,
 IS_SRVROLEMEMBER('sysadmin') AS Sysadmin, (SELECT COUNT(*) FROM sys.servers WHERE is_linked=1) AS Linked,
 DB_ID(N'$ReferenceDatabase') AS ReferenceId, DB_ID(N'$TestDatabase') AS TestId,
 (SELECT STRING_AGG(name, N',') WITHIN GROUP (ORDER BY name) FROM sys.databases WHERE database_id>4) AS UserDatabases;
"@).Rows[0]
}
function Assert-Target($t) {
    if ($t.Instance -ne 'SQLSERVER2019' -or $t.Major -ne 15 -or $t.Machine -ne $env:COMPUTERNAME -or $t.IsClustered -ne 0 -or $t.Hadr -ne 0 -or
        $t.Transport -ne 'Shared memory' -or $t.Encrypt -ne 'TRUE' -or $t.Sysadmin -ne 1 -or $t.Linked -ne 0 -or $t.ReferenceId -is [DBNull]) {
        throw 'preflight مقصد ناموفق: instance/transport/TLS/هویت/پایگاه مرجع برابر شرط 2G نیست.'
    }
    $unexpected = @("$($t.UserDatabases)".Split(',') | Where-Object { $_ -and $_ -notin @($ReferenceDatabase, $TestDatabase) })
    if ($unexpected.Count) { throw "پایگاه کاربری غیرمنتظره وجود دارد: $($unexpected -join ',')" }
}
function Test-Disposable {
    # اثبات مثبت یک‌بارمصرف‌بودن پیش از هر استفادهٔ مجدد یا حذف.
    $problems = New-Object System.Collections.Generic.List[string]
    $db = (Get-Rows 'master' "SELECT d.database_id, d.owner_sid, SUSER_SID() AS me, d.state_desc, d.collation_name, d.compatibility_level FROM sys.databases d WHERE d.name=@N" @{ '@N' = $TestDatabase })
    if ($db.Rows.Count -ne 1) { return [pscustomobject]@{ Exists = $false; Proven = $false; Problems = @() } }
    $row = $db.Rows[0]
    if ([Convert]::ToBase64String([byte[]]$row.owner_sid) -ne [Convert]::ToBase64String([byte[]]$row.me)) { $problems.Add('مالک پایگاه login جاری نیست.') }
    if ($row.state_desc -ne 'ONLINE') { $problems.Add("وضعیت پایگاه $($row.state_desc)") }
    if ($problems.Count -eq 0) {
        $c = Get-Rows $TestDatabase @"
SELECT (SELECT CONVERT(nvarchar(256),value) FROM sys.extended_properties WHERE class=0 AND name=@P) AS Marker,
 (SELECT STRING_AGG(name, N',') FROM sys.objects WHERE is_ms_shipped=0 AND type IN ('U','V','P','FN','IF','TF','TR','SN','SO')
    AND name NOT IN (N'BAZDIDSchemaMigrations',N'BAZDIDCustomerLinks',N'BAZDIDRequestContexts',N'BAZDIDAuditLogs',
                     N'BAZDIDOtpChallenges',N'BAZDIDCustomerSessions',N'BAZDIDAuthRateCounters')) AS ForeignObjects,
 (SELECT COUNT(*) FROM sys.database_principals WHERE principal_id>4 AND is_fixed_role=0 AND type NOT IN ('R')) AS Users,
 (SELECT COUNT(*) FROM sys.database_principals WHERE type='R' AND is_fixed_role=0 AND principal_id>0 AND name<>N'public') AS Roles
"@ @{ '@P' = $DisposableProperty }
        $r = $c.Rows[0]
        if ("$($r.Marker)" -ne $DisposableValue) { $problems.Add('نشانهٔ BAZDID.Disposable وجود ندارد یا برابر نیست.') }
        if ("$($r.ForeignObjects)") { $problems.Add("شیء ناشناخته: $($r.ForeignObjects)") }
        if ($r.Users -ne 0 -or $r.Roles -ne 0) { $problems.Add('user یا نقش پایگاه وجود دارد.') }
        foreach ($tbl in ($BaselineTables + $AuthTables)) {
            $n = (Get-Rows $TestDatabase "SELECT CASE WHEN OBJECT_ID(N'dbo.$tbl',N'U') IS NULL THEN 0 ELSE 1 END AS E").Rows[0].E
            if ($n -eq 1) {
                $rows = (Get-Rows $TestDatabase "SELECT COUNT_BIG(*) AS N FROM dbo.$tbl").Rows[0].N
                if ($rows -ne 0) { $problems.Add("داده در $tbl ($rows ردیف)") }
            }
        }
    }
    [pscustomobject]@{ Exists = $true; Proven = ($problems.Count -eq 0); Problems = @($problems) }
}
function Remove-TestDatabase {
    $proof = Test-Disposable
    if (-not $proof.Exists) { return 'NotPresent' }
    if (-not $proof.Proven) { throw ('حذف رد شد؛ اثبات یک‌بارمصرف ناقص است: ' + ($proof.Problems -join '; ')) }
    [void](Invoke-Sql 'master' "ALTER DATABASE [$TestDatabase] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$TestDatabase];")
    if ((Get-Rows 'master' "SELECT DB_ID(N'$TestDatabase') AS Id").Rows[0].Id -isnot [DBNull]) { throw 'پایگاه آزمون پس از DROP هنوز وجود دارد.' }
    return 'Dropped'
}
function New-TestDatabase {
    [void](Invoke-Sql 'master' @"
CREATE DATABASE [$TestDatabase] COLLATE SQL_Latin1_General_CP1_CI_AS;
ALTER DATABASE [$TestDatabase] SET COMPATIBILITY_LEVEL = 150;
ALTER DATABASE [$TestDatabase] SET RECOVERY SIMPLE;
"@)
    [void](Invoke-Sql $TestDatabase "EXEC sys.sp_addextendedproperty @name=N'$DisposableProperty', @value=N'$DisposableValue';")
}

$SignatureQueries = [ordered]@{
    COL = @"
SELECT t.name AS T, c.column_id AS I, c.name AS N, TYPE_NAME(c.user_type_id) AS Ty, c.max_length AS L, c.precision AS P, c.scale AS S,
 c.is_nullable AS Nu, c.is_identity AS Id, c.collation_name AS Co, cc.definition AS Def, cc.is_persisted AS Pe
FROM sys.tables t JOIN sys.columns c ON c.object_id=t.object_id LEFT JOIN sys.computed_columns cc ON cc.object_id=c.object_id AND cc.column_id=c.column_id
WHERE t.schema_id=SCHEMA_ID(N'dbo') AND t.name IN (N'BAZDIDCustomerLinks',N'BAZDIDRequestContexts',N'BAZDIDAuditLogs')
"@
    DF = @"
SELECT t.name AS T, d.name AS N, COL_NAME(d.parent_object_id,d.parent_column_id) AS C, d.definition AS Def
FROM sys.tables t JOIN sys.default_constraints d ON d.parent_object_id=t.object_id
WHERE t.schema_id=SCHEMA_ID(N'dbo') AND t.name IN (N'BAZDIDCustomerLinks',N'BAZDIDRequestContexts',N'BAZDIDAuditLogs')
"@
    CK = @"
SELECT t.name AS T, k.name AS N, k.definition AS Def, k.is_not_trusted AS Nt, k.is_disabled AS Di
FROM sys.tables t JOIN sys.check_constraints k ON k.parent_object_id=t.object_id
WHERE t.schema_id=SCHEMA_ID(N'dbo') AND t.name IN (N'BAZDIDCustomerLinks',N'BAZDIDRequestContexts',N'BAZDIDAuditLogs')
"@
    IX = @"
SELECT t.name AS T, i.name AS N, i.type_desc AS Ty, i.is_unique AS U, i.is_primary_key AS Pk, i.is_unique_constraint AS Uc, i.filter_definition AS F,
 ic.key_ordinal AS K, ic.is_included_column AS Inc, ic.is_descending_key AS Dsc, COL_NAME(ic.object_id,ic.column_id) AS C
FROM sys.tables t JOIN sys.indexes i ON i.object_id=t.object_id JOIN sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id
WHERE i.type>0 AND t.schema_id=SCHEMA_ID(N'dbo') AND t.name IN (N'BAZDIDCustomerLinks',N'BAZDIDRequestContexts',N'BAZDIDAuditLogs')
"@
    FK = @"
SELECT t.name AS T, f.name AS N, OBJECT_NAME(f.referenced_object_id) AS R, f.delete_referential_action_desc AS D, f.update_referential_action_desc AS U,
 f.is_not_trusted AS Nt, fc.constraint_column_id AS O, COL_NAME(fc.parent_object_id,fc.parent_column_id) AS Pc, COL_NAME(fc.referenced_object_id,fc.referenced_column_id) AS Rc
FROM sys.tables t JOIN sys.foreign_keys f ON f.parent_object_id=t.object_id JOIN sys.foreign_key_columns fc ON fc.constraint_object_id=f.object_id
WHERE t.schema_id=SCHEMA_ID(N'dbo') AND t.name IN (N'BAZDIDCustomerLinks',N'BAZDIDRequestContexts',N'BAZDIDAuditLogs')
"@
}
# امضای کامل schema سه جدول baseline (ستون، computed، default، check، index با ستون/ترتیب/فیلتر، FK)؛ الحاق در PowerShell
# انجام می‌شود تا تعارض collation کاتالوگ پیش نیاید. هر سطر یک ویژگی است و مجموعهٔ مرتب‌شده مقایسه می‌شود.
function Get-Signature([string]$db) {
    $items = foreach ($k in $SignatureQueries.Keys) {
        foreach ($row in (Get-Rows $db $SignatureQueries[$k]).Rows) {
            $k + '|' + (($row.ItemArray | ForEach-Object { if ($_ -is [DBNull]) { '' } elseif ($_ -is [bool]) { [int]$_ } else { "$_" } }) -join '|')
        }
    }
    @($items) | Sort-Object
}
function Get-ReferenceSnapshot {
    $r = (Get-Rows $ReferenceDatabase @"
SELECT (SELECT COUNT_BIG(*) FROM dbo.BAZDIDCustomerLinks) AS Customers, (SELECT COUNT_BIG(*) FROM dbo.BAZDIDRequestContexts) AS Requests,
 (SELECT COUNT_BIG(*) FROM dbo.BAZDIDAuditLogs) AS Audit, (SELECT COUNT(*) FROM sys.tables) AS Tables,
 (SELECT COUNT(*) FROM sys.database_principals WHERE principal_id>4 AND is_fixed_role=0) AS Principals,
 (SELECT COUNT(*) FROM sys.database_permissions) AS Permissions,
 (SELECT CHECKSUM_AGG(CHECKSUM(p.grantee_principal_id,p.major_id,p.permission_name,p.state)) FROM sys.database_permissions p) AS PermissionChecksum,
 (SELECT modify_date FROM sys.objects WHERE name=N'BAZDIDCustomerLinks') AS CustomerModified;
"@).Rows[0]
    $sig = Get-Signature $ReferenceDatabase
    [pscustomobject]@{
        Rows = "$($r.Customers)/$($r.Requests)/$($r.Audit)"; Tables = $r.Tables; Principals = $r.Principals; Permissions = $r.Permissions
        PermissionChecksum = $r.PermissionChecksum; CustomerModified = ([datetime]$r.CustomerModified).ToString('o')
        SignatureItems = $sig.Count; SignatureHash = (Get-StringHash ($sig -join "`n"))
    }
}
function Get-StringHash([string]$s) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try { -join ($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($s)) | ForEach-Object { $_.ToString('x2') }) } finally { $sha.Dispose() }
}
# نام دقیق اشیای 0002 (جدول، PK/UQ/FK/CHECK/DEFAULT، index) برای راستی‌آزمایی وجود/نبود.
$Expected0002 = 'BAZDIDAuthRateCounters:CK_BAZDIDAuthRateCounters_Hits,CK_BAZDIDAuthRateCounters_Scope,PK_BAZDIDAuthRateCounters;' +
  'BAZDIDCustomerSessions:CK_BAZDIDCustomerSessions_Revoke,CK_BAZDIDCustomerSessions_Tenant,CK_BAZDIDCustomerSessions_Time,FK_BAZDIDCustomerSessions_Challenge,FK_BAZDIDCustomerSessions_Context,FK_BAZDIDCustomerSessions_Customer,IX_BAZDIDCustomerSessions_Context,IX_BAZDIDCustomerSessions_Expiry,PK_BAZDIDCustomerSessions,UQ_BAZDIDCustomerSessions_Challenge,UQ_BAZDIDCustomerSessions_Handle;' +
  'BAZDIDOtpChallenges:CK_BAZDIDOtpChallenges_Code,CK_BAZDIDOtpChallenges_Consumed,CK_BAZDIDOtpChallenges_Counters,CK_BAZDIDOtpChallenges_State,CK_BAZDIDOtpChallenges_Tenant,DF_BAZDIDOtpChallenges_Created,DF_BAZDIDOtpChallenges_Failed,DF_BAZDIDOtpChallenges_Generation,DF_BAZDIDOtpChallenges_Sends,FK_BAZDIDOtpChallenges_Context,IX_BAZDIDOtpChallenges_Context,IX_BAZDIDOtpChallenges_Expiry,PK_BAZDIDOtpChallenges,UQ_BAZDIDOtpChallenges_Handle'
function Get-AuthObjects {
    $rows = Get-Rows $TestDatabase @"
SELECT t.name AS T, o.name AS N FROM sys.tables t JOIN sys.objects o ON o.parent_object_id=t.object_id
WHERE t.name IN (N'BAZDIDOtpChallenges',N'BAZDIDCustomerSessions',N'BAZDIDAuthRateCounters') AND o.type IN ('PK','UQ','F','C','D')
UNION ALL SELECT t.name, i.name FROM sys.tables t JOIN sys.indexes i ON i.object_id=t.object_id
WHERE t.name IN (N'BAZDIDOtpChallenges',N'BAZDIDCustomerSessions',N'BAZDIDAuthRateCounters') AND i.is_primary_key=0 AND i.is_unique_constraint=0 AND i.type>0
"@
    (@($rows.Rows | Group-Object T | Sort-Object Name | ForEach-Object { $_.Name + ':' + ((@($_.Group | ForEach-Object { $_.N }) | Sort-Object) -join ',') })) -join ';'
}
function Get-AuthRowCount {
    (Get-Rows $TestDatabase "SELECT (SELECT COUNT_BIG(*) FROM dbo.BAZDIDOtpChallenges)+(SELECT COUNT_BIG(*) FROM dbo.BAZDIDCustomerSessions)+(SELECT COUNT_BIG(*) FROM dbo.BAZDIDAuthRateCounters)+(SELECT COUNT_BIG(*) FROM dbo.BAZDIDCustomerLinks)+(SELECT COUNT_BIG(*) FROM dbo.BAZDIDRequestContexts)+(SELECT COUNT_BIG(*) FROM dbo.BAZDIDAuditLogs) AS N").Rows[0].N
}
function Invoke-StoreTests {
    # آزمون‌های store SQL فقط با انتخاب صریح و روی همین پایگاه یک‌بارمصرف (هویت مالک؛ نه هویت برنامه).
    $project = Join-Path (Split-Path $root -Parent) 'tests\Bazdid.IntegrationTests\Bazdid.IntegrationTests.csproj'
    $env:BAZDID_DISPOSABLE_SQL = '1'
    # در PS 5.1 خط‌های stderr فرمان native با Stop به خطای پایان‌دهنده تبدیل می‌شوند؛ فقط همین فراخوانی Continue است.
    $previous = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try { $output = & dotnet test $project --configuration Release --no-build --no-restore --filter 'FullyQualifiedName~SqlAuthStoreDisposableTests' 2>&1 | Out-String }
    finally { $ErrorActionPreference = $previous; Remove-Item Env:BAZDID_DISPOSABLE_SQL -ErrorAction SilentlyContinue }
    function N([string]$label) { if ($output -match "$label\s*:\s*(\d+)") { [int]$Matches[1] } else { 0 } }
    [pscustomobject]@{ Total = (N 'Total tests'); Passed = (N 'Passed'); Failed = (N 'Failed'); Skipped = (N 'Skipped'); ExitCode = $LASTEXITCODE
        FailureLines = @(($output -split "`r?`n") | Where-Object { $_ -match '\[FAIL\]|Error Message|Assert|Exception|Expected|Actual|at Bazdid' } | Select-Object -First 40) }
}
function Get-TestState {
    $r = (Get-Rows $TestDatabase @"
SELECT (SELECT STRING_AGG(name, N',') WITHIN GROUP (ORDER BY name) FROM sys.tables WHERE is_ms_shipped=0) AS Tables,
 (SELECT STRING_AGG(MigrationId+':'+(Mode COLLATE Latin1_General_100_BIN2)+':'+Checksum, N',') FROM dbo.BAZDIDSchemaMigrations) AS History
"@).Rows[0]
    [pscustomobject]@{ Tables = "$($r.Tables)"; History = "$($r.History)" }
}

$target = Get-Target
Assert-Target $target
$evidence = [ordered]@{
    Date = (Get-Date).ToUniversalTime().ToString('o'); Action = $Action; ApprovalReference = $ApprovalReference
    Target = [ordered]@{ Instance = $target.Instance; Major = $target.Major; Transport = $target.Transport; Encrypt = $target.Encrypt; UserDatabasesAtStart = "$($target.UserDatabases)" }
    MigrationSha256 = [ordered]@{ Forward = $migrations.Forward.Sha; Revert = $migrations.Revert.Sha }
    Steps = New-Object System.Collections.Generic.List[object]
}
function Step([string]$name, $expected, $actual) {
    $ok = "$expected" -eq "$actual"
    $evidence.Steps.Add([ordered]@{ Step = $name; Expected = "$expected"; Actual = "$actual"; Pass = $ok })
    Write-Host ('{0,-44} {1}  ({2})' -f $name, $(if ($ok) { 'PASS' } else { 'FAIL' }), $actual)
    if (-not $ok) { throw "گام ناموفق: $name — انتظار '$expected'، مشاهده '$actual'" }
}

if ($Action -eq 'Preflight') {
    $proof = Test-Disposable
    [pscustomobject]@{ Target = $evidence.Target; TestDatabaseExists = $proof.Exists; DisposableProven = $proof.Proven; Problems = $proof.Problems; Reference = (Get-ReferenceSnapshot) } | ConvertTo-Json -Depth 4
    return
}
if ($Action -eq 'Cleanup') { Write-Host ('Cleanup: ' + (Remove-TestDatabase)); return }

# ---------------- Accept ----------------
$referenceBefore = Get-ReferenceSnapshot
$referenceSignature = Get-Signature $ReferenceDatabase
$evidence.ReferenceBefore = $referenceBefore
$existing = Test-Disposable
if ($existing.Exists -and -not $existing.Proven) { throw ('BAZDID_MigrationTest از قبل وجود دارد و اثبات یک‌بارمصرف ندارد؛ متوقف شد: ' + ($existing.Problems -join '; ')) }
if ($existing.Exists) { Step 'pre-existing disposable test DB removed' 'Dropped' (Remove-TestDatabase) }
$forwardSha = $migrations.Forward.Sha
$forward2Sha = $migrations.Forward2.Sha
try {
    New-TestDatabase
    Step '01 create disposable DB + marker' 'True' (Test-Disposable).Proven
    Step '02 forward (fresh)' 'Created' (Invoke-Sql $TestDatabase (Get-ForwardSql $forwardSha))
    Step '03 schema equals BAZDID_Development' ($referenceSignature -join "`n" | ForEach-Object { Get-StringHash $_ }) ((Get-Signature $TestDatabase) -join "`n" | ForEach-Object { Get-StringHash $_ })
    Step '04 history after forward' "0001_baseline:Created:$forwardSha" (Get-TestState).History
    Step '05 forward repeat is no-op' 'AlreadyApplied' (Invoke-Sql $TestDatabase (Get-ForwardSql $forwardSha))
    $tampered = try { [void](Invoke-Sql $TestDatabase (Get-ForwardSql ('0' * 64))); 'NoError' } catch { if ($_.Exception.Message -match 'BAZDID_MIGRATION_CHECKSUM_MISMATCH') { 'ChecksumMismatch' } else { $_.Exception.Message } }
    Step '06 forward with wrong checksum rejected' 'ChecksumMismatch' $tampered
    Step '07 schema unchanged after repeats' (Get-StringHash ($referenceSignature -join "`n")) (Get-StringHash ((Get-Signature $TestDatabase) -join "`n"))
    Step '08 revert' 'Reverted' (Invoke-Sql $TestDatabase (Get-RevertSql))
    $s = Get-TestState
    Step '09 rollback state: only history table' 'BAZDIDSchemaMigrations' $s.Tables
    Step '10 rollback state: empty history' '' $s.History
    Step '11 revert repeat is no-op' 'NotApplied' (Invoke-Sql $TestDatabase (Get-RevertSql))
    $pre = try { [void](Invoke-Sql $TestDatabase (Get-ForwardSql $forward2Sha $migrations.Forward2.Text)); 'NoError' } catch { if ($_.Exception.Message -match 'BAZDID_PREREQUISITE_0001_MISSING') { 'Prerequisite' } else { $_.Exception.Message } }
    Step '11b 0002 refused without 0001' 'Prerequisite' $pre
    Step '12 forward re-apply' 'Created' (Invoke-Sql $TestDatabase (Get-ForwardSql $forwardSha))
    Step '13 schema equals reference after re-apply' (Get-StringHash ($referenceSignature -join "`n")) (Get-StringHash ((Get-Signature $TestDatabase) -join "`n"))
    Step '14 history after re-apply' "0001_baseline:Created:$forwardSha" (Get-TestState).History
    # حفظ داده: rollback با داده باید رد شود؛ ردیف ساختگی سپس حذف می‌شود (فقط در پایگاه یک‌بارمصرف).
    [void](Invoke-Sql $TestDatabase "INSERT dbo.BAZDIDCustomerLinks (Id,BrokerageId,SourceSystem,SourceCustomerId) VALUES (NEWID(),N'TEST-2G',N'TEST-2G',N'TEST-2G-ROW'); SELECT 'Inserted' AS Result;")
    $guard = try { [void](Invoke-Sql $TestDatabase (Get-RevertSql)); 'NoError' } catch { if ($_.Exception.Message -match 'BAZDID_REVERT_DATA_PRESENT') { 'DataPresent' } else { $_.Exception.Message } }
    Step '15 revert refused while data present' 'DataPresent' $guard
    Step '16 data and schema intact after refusal' '1' (Get-Rows $TestDatabase "SELECT COUNT_BIG(*) AS N FROM dbo.BAZDIDCustomerLinks").Rows[0].N
    [void](Invoke-Sql $TestDatabase "DELETE FROM dbo.BAZDIDCustomerLinks WHERE BrokerageId=N'TEST-2G' AND SourceSystem=N'TEST-2G'; SELECT 'Deleted' AS Result;")
    # adopt: سه جدول موجود با امضای 2C و بدون ردیف تاریخچه (مسیر آیندهٔ ثبت baseline روی BAZDID_Development).
    [void](Invoke-Sql $TestDatabase "DELETE FROM dbo.BAZDIDSchemaMigrations WHERE MigrationId=N'0001_baseline'; SELECT 'HistoryCleared' AS Result;")
    Step '17 forward adopts existing exact schema' 'Adopted' (Invoke-Sql $TestDatabase (Get-ForwardSql $forwardSha))
    Step '18 history after adopt' "0001_baseline:Adopted:$forwardSha" (Get-TestState).History
    Step '19 final schema equals reference' (Get-StringHash ($referenceSignature -join "`n")) (Get-StringHash ((Get-Signature $TestDatabase) -join "`n"))
    $evidence.SignatureItems = $referenceSignature.Count
    # ---------------- 0002_otp_session ----------------
    Step '23 0002 forward' 'Created' (Invoke-Sql $TestDatabase (Get-ForwardSql $forward2Sha $migrations.Forward2.Text))
    Step '24 0002 objects present' $Expected0002 (Get-AuthObjects)
    Step '25 0002 repeat is no-op' 'AlreadyApplied' (Invoke-Sql $TestDatabase (Get-ForwardSql $forward2Sha $migrations.Forward2.Text))
    $tampered2 = try { [void](Invoke-Sql $TestDatabase (Get-ForwardSql ('0' * 64) $migrations.Forward2.Text)); 'NoError' } catch { if ($_.Exception.Message -match 'BAZDID_MIGRATION_CHECKSUM_MISMATCH') { 'ChecksumMismatch' } else { $_.Exception.Message } }
    Step '26 0002 wrong checksum rejected' 'ChecksumMismatch' $tampered2
    $later = try { [void](Invoke-Sql $TestDatabase (Get-RevertSql)); 'NoError' } catch { if ($_.Exception.Message -match 'BAZDID_REVERT_LATER_MIGRATION_PRESENT') { 'LaterMigration' } else { $_.Exception.Message } }
    Step '27 0001 revert refused while 0002 present' 'LaterMigration' $later
    $tests = Invoke-StoreTests
    $evidence.StoreTests = $tests
    if ($tests.Failed -ne 0 -or $tests.Total -eq 0) { $tests.FailureLines | ForEach-Object { Write-Host "  $_" } }
    Step '28 SQL store tests on disposable DB' 'Failed=0 Skipped=0' ("Failed=$($tests.Failed) Skipped=$($tests.Skipped)")
    Step '29 store tests left no rows' '0' (Get-AuthRowCount)
    [void](Invoke-Sql $TestDatabase "INSERT dbo.BAZDIDAuthRateCounters (Scope,KeyHash,WindowStartUtc,Hits) VALUES ('ip',HASHBYTES('SHA2_256',N'TEST-2G'),SYSUTCDATETIME(),1); SELECT 'Inserted' AS Result;")
    $guard2 = try { [void](Invoke-Sql $TestDatabase (Get-RevertSql $migrations.Revert2.Text)); 'NoError' } catch { if ($_.Exception.Message -match 'BAZDID_REVERT_DATA_PRESENT') { 'DataPresent' } else { $_.Exception.Message } }
    Step '30 0002 revert refused while data present' 'DataPresent' $guard2
    [void](Invoke-Sql $TestDatabase "DELETE FROM dbo.BAZDIDAuthRateCounters WHERE Scope='ip' AND KeyHash=HASHBYTES('SHA2_256',N'TEST-2G'); SELECT 'Deleted' AS Result;")
    Step '31 0002 revert' 'Reverted' (Invoke-Sql $TestDatabase (Get-RevertSql $migrations.Revert2.Text))
    Step '32 0002 objects absent after revert' '' (Get-AuthObjects)
    Step '33 0001 schema intact after 0002 revert' (Get-StringHash ($referenceSignature -join "`n")) (Get-StringHash ((Get-Signature $TestDatabase) -join "`n"))
    Step '34 0002 revert repeat is no-op' 'NotApplied' (Invoke-Sql $TestDatabase (Get-RevertSql $migrations.Revert2.Text))
    Step '35 0002 re-apply' 'Created' (Invoke-Sql $TestDatabase (Get-ForwardSql $forward2Sha $migrations.Forward2.Text))
    Step '36 0002 objects present after re-apply' $Expected0002 (Get-AuthObjects)
    Step '37 history has both migrations' "0001_baseline:Adopted:$forwardSha,0002_otp_session:Created:$forward2Sha" (Get-TestState).History
}
finally {
    $cleanup = try { Remove-TestDatabase } catch { 'FAILED: ' + $_.Exception.Message }
    $evidence.Cleanup = $cleanup
    Write-Host "cleanup: $cleanup"
    # شاهد جزئی حتی در شکست ثبت می‌شود؛ در موفقیت پایین‌تر بازنویسی می‌شود.
    if ($EvidencePath) { $evidence.Result = 'INCOMPLETE'; ($evidence | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $EvidencePath -Encoding UTF8 }
}
Step '20 disposable DB removed' 'Dropped' $cleanup
Step '21 disposable DB absent' 'True' ((Get-Rows 'master' "SELECT CASE WHEN DB_ID(N'$TestDatabase') IS NULL THEN 'True' ELSE 'False' END AS A").Rows[0].A)
$referenceAfter = Get-ReferenceSnapshot
$evidence.ReferenceAfter = $referenceAfter
Step '22 BAZDID_Development unchanged' ($referenceBefore | ConvertTo-Json -Compress) ($referenceAfter | ConvertTo-Json -Compress)
$evidence.Result = 'PASS'
if ($EvidencePath) { ($evidence | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $EvidencePath -Encoding UTF8 }
Write-Host 'پذیرش migration 2G: PASS'
