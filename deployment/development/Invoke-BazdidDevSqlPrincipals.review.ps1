<#
P2 — loginها، userها و نقش‌های SQL برای دو حساب Windows ساخته‌شده در P1.
فقط instance محلی SQLSERVER2019 و پایگاه BAZDID_Development. دو script بازبینی‌شدهٔ
database/proposals را با hash ثابت می‌خواند و فقط خطوط DECLARE دقیق را با مقادیر واقعی جایگزین می‌کند.
اتصال: lpc:localhost\SQLSERVER2019، Integrated Security، Encrypt=true، TrustServerCertificate=false.
هویت اجرا: login مالک که sysadmin است؛ elevation ویندوز لازم نیست. هیچ رمز، SQL login یا server role ساخته نمی‌شود.
حالت‌ها: بدون سوئیچ = dry run فقط‌خواندنی؛ -Execute؛ -VerifyOnly؛ -RemoveForRecovery [-Execute].
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidatePattern('^[A-Za-z0-9-]{1,15}$')][string]$ExpectedMachine,
    [Parameter(Mandatory = $true)][ValidatePattern('^[A-Za-z0-9._-]{1,32}$')][string]$ApprovalReference,
    [switch]$Execute,
    [switch]$VerifyOnly,
    [switch]$RemoveForRecovery
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
if ($VerifyOnly -and ($Execute -or $RemoveForRecovery)) { throw '-VerifyOnly با -Execute یا -RemoveForRecovery ترکیب نمی‌شود.' }
if ($env:COMPUTERNAME -ne $ExpectedMachine) { throw 'نام ماشین با مقدار مورد انتظار برابر نیست.' }

$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$scripts = [ordered]@{
    Logins      = @{ Path = 'database\proposals\development_logins.review.sql'; Sha = '9099DE3DCE8E77FC037D1BDC6D5B8649BA835253DF067E6B0E8D89B121B5B15F'; Db = 'master' }
    Permissions = @{ Path = 'database\proposals\permissions.review.sql'; Sha = '9888862C6997EB2AB0FC2EFFAAC6559E6399905E1290FEC506100AD46609A396'; Db = 'BAZDID_Development' }
}
foreach ($s in $scripts.Values) {
    $full = Join-Path $repo $s.Path
    $hash = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
    if ($hash -ne $s.Sha) { throw "hash فایل $($s.Path) با نسخهٔ بازبینی‌شده برابر نیست." }
    $s.Text = [IO.File]::ReadAllText($full, [Text.Encoding]::UTF8)
}

function Get-Account([string]$name) {
    $u = Get-LocalUser -Name $name -ErrorAction Stop
    if (-not $u.Enabled -or $u.Description -notlike 'BAZDID-DEV-SQL *') { throw "حساب $name با نشانهٔ P1 مطابقت ندارد." }
    $adsi = [ADSI]"WinNT://$env:COMPUTERNAME/$name,user"
    $groups = @($adsi.psbase.Invoke('Groups'))
    if ($groups.Count -ne 0) { throw "حساب $name عضویت مستقیم گروه دارد." }
    $bytes = New-Object byte[] $u.SID.BinaryLength
    $u.SID.GetBinaryForm($bytes, 0)
    [pscustomobject]@{ Name = $name; Login = "$ExpectedMachine\$name"; Sid = $u.SID.Value; SidHex = '0x' + (($bytes | ForEach-Object { $_.ToString('X2') }) -join '') }
}
$writer = Get-Account 'BAZDIDDevWriter'
$reader = Get-Account 'BAZDIDDevReader'

function Open-Local([string]$db) {
    if ($db -notin @('master', 'BAZDID_Development')) { throw 'پایگاه خارج از دامنه است.' }
    $b = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
    $b['Data Source'] = 'lpc:localhost\SQLSERVER2019'
    $b['Initial Catalog'] = $db
    $b['Integrated Security'] = $true
    $b['Encrypt'] = $true
    $b['TrustServerCertificate'] = $false
    $b['Connect Timeout'] = 5
    $b['Pooling'] = $false
    $b['Application Name'] = 'BAZDID-2F-P2'
    $c = New-Object System.Data.SqlClient.SqlConnection($b.ConnectionString)
    $c.Open()
    return $c
}
function Invoke-Rows($conn, [string]$sql, [hashtable]$p = @{}) {
    $cmd = $conn.CreateCommand(); $cmd.CommandTimeout = 30; $cmd.CommandText = $sql
    foreach ($k in $p.Keys) { [void]$cmd.Parameters.AddWithValue($k, $p[$k]) }
    $t = New-Object System.Data.DataTable
    $r = $cmd.ExecuteReader(); try { $t.Load($r) } finally { $r.Dispose() }
    return ,$t
}
$sidW = [byte[]](New-Object Security.Principal.SecurityIdentifier($writer.Sid) | ForEach-Object { $b = New-Object byte[] $_.BinaryLength; $_.GetBinaryForm($b, 0); $b })
$sidR = [byte[]](New-Object Security.Principal.SecurityIdentifier($reader.Sid) | ForEach-Object { $b = New-Object byte[] $_.BinaryLength; $_.GetBinaryForm($b, 0); $b })

function Get-State {
    $c = Open-Local 'BAZDID_Development'
    try {
        $row = (Invoke-Rows $c @"
SELECT DB_NAME() AS Db, CONVERT(nvarchar(128),SERVERPROPERTY('MachineName')) AS Machine,
 CONVERT(nvarchar(128),SERVERPROPERTY('InstanceName')) AS Instance,
 CONVERT(nvarchar(128),CONNECTIONPROPERTY('net_transport')) AS Transport,
 (SELECT encrypt_option FROM sys.dm_exec_connections WHERE session_id=@@SPID) AS Encrypt,
 IS_SRVROLEMEMBER('sysadmin') AS CallerSysadmin,
 (SELECT COUNT(*) FROM sys.databases WHERE database_id>4) AS UserDatabases,
 (SELECT COUNT(*) FROM sys.servers WHERE is_linked=1) AS LinkedServers,
 (SELECT COUNT(*) FROM sys.server_principals WHERE name=@WL AND sid=@WS AND type='U' AND is_disabled=0) AS WriterLogin,
 (SELECT COUNT(*) FROM sys.server_principals WHERE name=@RL AND sid=@RS AND type='U' AND is_disabled=0) AS ReaderLogin,
 (SELECT COUNT(*) FROM sys.server_principals WHERE name LIKE N'%BAZDID%' OR sid IN (@WS,@RS)) AS AnyBazdidLogins,
 (SELECT COUNT(*) FROM sys.server_role_members m JOIN sys.server_principals p ON p.principal_id=m.member_principal_id WHERE p.sid IN (@WS,@RS)) AS ServerRoleMemberships,
 (SELECT COUNT(*) FROM sys.database_principals WHERE sid IN (@WS,@RS)) AS DbUsers,
 (SELECT COUNT(*) FROM sys.database_principals WHERE name IN (N'BAZDIDWriter',N'BAZDIDSourceReader') AND type='R') AS DbRoles;
"@ @{ '@WL' = $writer.Login; '@RL' = $reader.Login; '@WS' = $sidW; '@RS' = $sidR }).Rows[0]
        return $row
    } finally { $c.Dispose() }
}
function Assert-Target($s) {
    if ($s.Machine -ne $ExpectedMachine -or $s.Instance -ne 'SQLSERVER2019' -or $s.Transport -ne 'Shared memory' -or
        $s.Encrypt -ne 'TRUE' -or $s.CallerSysadmin -ne 1 -or $s.UserDatabases -ne 1 -or $s.LinkedServers -ne 0) {
        throw 'مقصد یا هویت اجراکننده با شرط P2 برابر نیست.'
    }
}
function Get-Executable([string]$text) {
    $map = [ordered]@{
        'DECLARE @AllowDdl bit = 0;'                          = 'DECLARE @AllowDdl bit = 1;'
        'DECLARE @ApprovalReference nvarchar(128) = NULL;'    = "DECLARE @ApprovalReference nvarchar(128) = N'$ApprovalReference';"
        'DECLARE @ExpectedMachine sysname = NULL;'            = "DECLARE @ExpectedMachine sysname = N'$ExpectedMachine';"
        'DECLARE @WriterLogin sysname = NULL;'                = "DECLARE @WriterLogin sysname = N'$($writer.Login)';"
        'DECLARE @ReaderLogin sysname = NULL;'                = "DECLARE @ReaderLogin sysname = N'$($reader.Login)';"
        'DECLARE @ExpectedWriterSid varbinary(85) = NULL;'    = "DECLARE @ExpectedWriterSid varbinary(85) = $($writer.SidHex);"
        'DECLARE @ExpectedReaderSid varbinary(85) = NULL;'    = "DECLARE @ExpectedReaderSid varbinary(85) = $($reader.SidHex);"
    }
    foreach ($k in $map.Keys) {
        $n = ([regex]::Matches($text, [regex]::Escape($k))).Count
        if ($n -ne 1) { throw "خط DECLARE مورد انتظار دقیقاً یک بار یافت نشد: $k" }
        $text = $text.Replace($k, $map[$k])
    }
    return $text
}
function Invoke-Batch([string]$db, [string]$sql) {
    $c = Open-Local $db
    try {
        $cmd = $c.CreateCommand(); $cmd.CommandTimeout = 60; $cmd.CommandText = $sql
        [void]$cmd.ExecuteNonQuery()
    } finally { $c.Dispose() }
}

# انتظار دقیق مجوزها (همان script بازبینی‌شده) برای راستی‌آزمایی کاتالوگ.
$expected = @(
    'BAZDIDWriter|GRANT|SELECT|BAZDIDCustomerLinks', 'BAZDIDWriter|GRANT|INSERT|BAZDIDCustomerLinks',
    'BAZDIDWriter|DENY|UPDATE|BAZDIDCustomerLinks', 'BAZDIDWriter|DENY|DELETE|BAZDIDCustomerLinks', 'BAZDIDWriter|DENY|ALTER|BAZDIDCustomerLinks',
    'BAZDIDWriter|GRANT|SELECT|BAZDIDRequestContexts', 'BAZDIDWriter|GRANT|INSERT|BAZDIDRequestContexts', 'BAZDIDWriter|GRANT|UPDATE|BAZDIDRequestContexts',
    'BAZDIDWriter|DENY|DELETE|BAZDIDRequestContexts', 'BAZDIDWriter|DENY|ALTER|BAZDIDRequestContexts',
    'BAZDIDWriter|GRANT|INSERT|BAZDIDAuditLogs',
    'BAZDIDWriter|DENY|SELECT|BAZDIDAuditLogs', 'BAZDIDWriter|DENY|UPDATE|BAZDIDAuditLogs', 'BAZDIDWriter|DENY|DELETE|BAZDIDAuditLogs', 'BAZDIDWriter|DENY|ALTER|BAZDIDAuditLogs'
)
foreach ($t in 'BAZDIDCustomerLinks', 'BAZDIDRequestContexts', 'BAZDIDAuditLogs') { foreach ($p in 'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'ALTER') { $expected += "BAZDIDSourceReader|DENY|$p|$t" } }
foreach ($r in 'BAZDIDWriter', 'BAZDIDSourceReader') { foreach ($p in 'CREATE TABLE', 'CREATE VIEW', 'CREATE PROCEDURE', 'CREATE FUNCTION', 'CREATE SCHEMA') { $expected += "$r|DENY|$p|" } }

function Test-Principals {
    $problems = New-Object System.Collections.Generic.List[string]
    $s = Get-State; Assert-Target $s
    if ($s.WriterLogin -ne 1 -or $s.ReaderLogin -ne 1) { $problems.Add('login یا SID برابر نیست.') }
    if ($s.AnyBazdidLogins -ne 2) { $problems.Add("تعداد login مرتبط $($s.AnyBazdidLogins) است.") }
    if ($s.ServerRoleMemberships -ne 0) { $problems.Add('login عضو server role است.') }
    if ($s.DbUsers -ne 2 -or $s.DbRoles -ne 2) { $problems.Add('user یا نقش پایگاه کامل نیست.') }
    $c = Open-Local 'BAZDID_Development'
    try {
        $perm = Invoke-Rows $c @"
SELECT pr.name AS P, pe.state_desc AS S, pe.permission_name AS N, COALESCE(OBJECT_NAME(pe.major_id),N'') AS O
FROM sys.database_permissions pe JOIN sys.database_principals pr ON pr.principal_id=pe.grantee_principal_id
WHERE pr.name IN (N'BAZDIDWriter',N'BAZDIDSourceReader') OR pr.sid IN (@WS,@RS);
"@ @{ '@WS' = $sidW; '@RS' = $sidR }
        $actual = @($perm.Rows | ForEach-Object {
            $state = if ($_.S -eq 'GRANT_WITH_GRANT_OPTION') { 'GRANT*' } else { $_.S }
            if ($_.P -eq $writer.Login -or $_.P -eq $reader.Login) { if ($_.N -eq 'CONNECT' -and $state -eq 'GRANT') { return } }
            "$($_.P)|$state|$($_.N)|$($_.O)"
        })
        $extra = @($actual | Where-Object { $_ -notin $expected })
        $missing = @($expected | Where-Object { $_ -notin $actual })
        if ($extra.Count) { $problems.Add('مجوز اضافه: ' + ($extra -join '; ')) }
        if ($missing.Count) { $problems.Add('مجوز ناموجود: ' + ($missing -join '; ')) }
        $members = Invoke-Rows $c @"
SELECT r.name AS R, m.name AS M FROM sys.database_role_members rm
JOIN sys.database_principals r ON r.principal_id=rm.role_principal_id
JOIN sys.database_principals m ON m.principal_id=rm.member_principal_id
WHERE m.sid IN (@WS,@RS) OR r.name IN (N'BAZDIDWriter',N'BAZDIDSourceReader');
"@ @{ '@WS' = $sidW; '@RS' = $sidR }
        $memberSet = @($members.Rows | ForEach-Object { "$($_.R)|$($_.M)" }) | Sort-Object
        $wantMembers = @("BAZDIDSourceReader|$($reader.Login)", "BAZDIDWriter|$($writer.Login)") | Sort-Object
        if (($memberSet -join ';') -ne ($wantMembers -join ';')) { $problems.Add('عضویت نقش‌ها دقیق نیست: ' + ($memberSet -join '; ')) }
        # verifier مستقل DBA: مجوز مؤثر از دید هر login (شامل public و گروه‌های Windows) بدون اجرای DML.
        $eff = @{}
        foreach ($acct in $writer, $reader) {
            $cmd = $c.CreateCommand(); $cmd.CommandTimeout = 30
            $cmd.CommandText = @"
EXECUTE AS LOGIN=@L;
SELECT IS_SRVROLEMEMBER('sysadmin') AS SA, IS_MEMBER('db_owner') AS DBO,
 HAS_PERMS_BY_NAME(N'dbo.BAZDIDCustomerLinks',N'OBJECT',N'SELECT') AS CL_S, HAS_PERMS_BY_NAME(N'dbo.BAZDIDCustomerLinks',N'OBJECT',N'INSERT') AS CL_I,
 HAS_PERMS_BY_NAME(N'dbo.BAZDIDCustomerLinks',N'OBJECT',N'UPDATE') AS CL_U, HAS_PERMS_BY_NAME(N'dbo.BAZDIDCustomerLinks',N'OBJECT',N'DELETE') AS CL_D,
 HAS_PERMS_BY_NAME(N'dbo.BAZDIDRequestContexts',N'OBJECT',N'SELECT') AS RC_S, HAS_PERMS_BY_NAME(N'dbo.BAZDIDRequestContexts',N'OBJECT',N'INSERT') AS RC_I,
 HAS_PERMS_BY_NAME(N'dbo.BAZDIDRequestContexts',N'OBJECT',N'UPDATE') AS RC_U, HAS_PERMS_BY_NAME(N'dbo.BAZDIDRequestContexts',N'OBJECT',N'DELETE') AS RC_D,
 HAS_PERMS_BY_NAME(N'dbo.BAZDIDAuditLogs',N'OBJECT',N'SELECT') AS AL_S, HAS_PERMS_BY_NAME(N'dbo.BAZDIDAuditLogs',N'OBJECT',N'INSERT') AS AL_I,
 HAS_PERMS_BY_NAME(N'dbo.BAZDIDAuditLogs',N'OBJECT',N'UPDATE') AS AL_U, HAS_PERMS_BY_NAME(N'dbo.BAZDIDAuditLogs',N'OBJECT',N'DELETE') AS AL_D,
 HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE TABLE') AS DDL, HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CONTROL') AS CTRL,
 HAS_PERMS_BY_NAME(NULL,NULL,N'CONTROL SERVER') AS CS;
REVERT;
"@
            [void]$cmd.Parameters.AddWithValue('@L', $acct.Login)
            $t = New-Object System.Data.DataTable; $r = $cmd.ExecuteReader(); try { $t.Load($r) } finally { $r.Dispose() }
            $row = $t.Rows[0]; $eff[$acct.Name] = (($t.Columns | ForEach-Object { "$($_.ColumnName)=$($row[$_.ColumnName])" }) -join ' ')
        }
        $wantW = 'SA=0 DBO=0 CL_S=1 CL_I=1 CL_U=0 CL_D=0 RC_S=1 RC_I=1 RC_U=1 RC_D=0 AL_S=0 AL_I=1 AL_U=0 AL_D=0 DDL=0 CTRL=0 CS=0'
        $wantR = 'SA=0 DBO=0 CL_S=0 CL_I=0 CL_U=0 CL_D=0 RC_S=0 RC_I=0 RC_U=0 RC_D=0 AL_S=0 AL_I=0 AL_U=0 AL_D=0 DDL=0 CTRL=0 CS=0'
        if ($eff['BAZDIDDevWriter'] -ne $wantW) { $problems.Add('مجوز مؤثر Writer: ' + $eff['BAZDIDDevWriter']) }
        if ($eff['BAZDIDDevReader'] -ne $wantR) { $problems.Add('مجوز مؤثر Reader: ' + $eff['BAZDIDDevReader']) }
    } finally { $c.Dispose() }
    [pscustomobject]@{
        WriterLogin = $writer.Login; WriterSid = $writer.Sid; ReaderLogin = $reader.Login; ReaderSid = $reader.Sid
        CatalogPermissions = $actual.Count; ExpectedPermissions = $expected.Count
        EffectiveWriter = $eff['BAZDIDDevWriter']; EffectiveReader = $eff['BAZDIDDevReader']
        Problems = @($problems); Pass = ($problems.Count -eq 0)
    }
}

$state = Get-State
Assert-Target $state

if ($VerifyOnly) {
    $v = Test-Principals; $v | Format-List
    if ($v.Pass) { Write-Host 'راستی‌آزمایی P2: PASS' } else { Write-Host 'راستی‌آزمایی P2: FAIL'; exit 1 }
    return
}

if ($RemoveForRecovery) {
    $drop = @"
SET XACT_ABORT ON;
IF DB_NAME()<>N'BAZDID_Development' OR IS_SRVROLEMEMBER('sysadmin')<>1 THROW 51030,'BAZDID_RECOVERY_TARGET',1;
IF EXISTS (SELECT 1 FROM sys.database_role_members rm JOIN sys.database_principals r ON r.principal_id=rm.role_principal_id
           JOIN sys.database_principals m ON m.principal_id=rm.member_principal_id
           WHERE r.name IN (N'BAZDIDWriter',N'BAZDIDSourceReader') AND m.sid NOT IN (@WS,@RS))
    THROW 51031,'BAZDID_RECOVERY_FOREIGN_MEMBER',1;
BEGIN TRAN;
DECLARE @Sql nvarchar(max)=N'';
SELECT @Sql+=N'DROP USER '+QUOTENAME(name)+N';' FROM sys.database_principals WHERE sid IN (@WS,@RS) AND type='U';
EXEC sys.sp_executesql @Sql;
IF DATABASE_PRINCIPAL_ID(N'BAZDIDWriter') IS NOT NULL DROP ROLE BAZDIDWriter;
IF DATABASE_PRINCIPAL_ID(N'BAZDIDSourceReader') IS NOT NULL DROP ROLE BAZDIDSourceReader;
COMMIT;
SET @Sql=N'';
SELECT @Sql+=N'DROP LOGIN '+QUOTENAME(name)+N';' FROM sys.server_principals WHERE sid IN (@WS,@RS) AND type='U';
EXEC sys.sp_executesql @Sql;
"@
    Write-Host "بازگشت P2: user/نقش‌های BAZDID و loginهای SID $($writer.Sid) و $($reader.Sid)."
    if (-not $Execute) { Write-Host 'اجرای آزمایشی: هیچ تغییری انجام نشد.'; return }
    $c = Open-Local 'BAZDID_Development'
    try { $cmd = $c.CreateCommand(); $cmd.CommandText = $drop; [void]$cmd.Parameters.AddWithValue('@WS', $sidW); [void]$cmd.Parameters.AddWithValue('@RS', $sidR); [void]$cmd.ExecuteNonQuery() } finally { $c.Dispose() }
    Get-State | Format-List WriterLogin, ReaderLogin, AnyBazdidLogins, DbUsers, DbRoles
    return
}

$plan = @()
if ($state.WriterLogin -eq 1 -and $state.ReaderLogin -eq 1 -and $state.AnyBazdidLogins -eq 2) { $plan += 'Logins:skip(exists)' }
elseif ($state.AnyBazdidLogins -eq 0) { $plan += 'Logins:create' }
else { throw 'وضعیت loginها جزئی یا ناسازگار است؛ ابتدا -VerifyOnly و در صورت لزوم -RemoveForRecovery.' }
if ($state.DbUsers -eq 2 -and $state.DbRoles -eq 2) { $plan += 'Permissions:skip(exists)' }
elseif ($state.DbUsers -eq 0 -and $state.DbRoles -eq 0) { $plan += 'Permissions:create' }
else { throw 'وضعیت user/نقش‌ها جزئی است؛ ابتدا -VerifyOnly و در صورت لزوم -RemoveForRecovery.' }

[pscustomobject]@{
    Target = 'lpc:localhost\SQLSERVER2019 / BAZDID_Development'; Transport = $state.Transport; Encrypt = $state.Encrypt
    WriterLogin = $writer.Login; WriterSid = $writer.Sid; ReaderLogin = $reader.Login; ReaderSid = $reader.Sid
    Plan = ($plan -join ', ')
} | Format-List
# اعتبارسنجی جایگزینی پیش از هر اجرا (در dry run هم).
$exec = @{}
foreach ($k in $scripts.Keys) { $exec[$k] = Get-Executable $scripts[$k].Text }

if (-not $Execute) { Write-Host 'اجرای آزمایشی: هیچ تغییری انجام نشد. پیش‌شرط‌ها برقرارند.'; return }

if ($plan -contains 'Logins:create') { Invoke-Batch 'master' $exec['Logins']; Write-Host 'loginها ساخته شدند.' }
if ($plan -contains 'Permissions:create') { Invoke-Batch 'BAZDID_Development' $exec['Permissions']; Write-Host 'user، نقش و مجوزها اعمال شدند.' }
$v = Test-Principals; $v | Format-List
if ($v.Pass) { Write-Host 'P2 اجرا و راستی‌آزمایی شد: PASS' } else { Write-Host 'P2: FAIL — برای بازگشت از -RemoveForRecovery استفاده کنید.'; exit 1 }
