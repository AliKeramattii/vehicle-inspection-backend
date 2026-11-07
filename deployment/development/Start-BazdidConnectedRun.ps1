<#
اپراتور (غیرمدیر) — اجرای کامل پذیرش متصل P4/P5:
  1) publish آزمون‌های integration به C:\ProgramData\BAZDID\ConnectedTests\bin (بدون وابستگی به cache NuGet کاربر)؛
  2) baseline مستقل DBA (schema، ردیف‌های خارج از دامنهٔ آزمون)؛
  3) اجرای task «BAZDID-Dev-ConnectedSqlTests» با هویت Writer و انتظار برای پایان؛
  4) خلاصهٔ TRX؛ 5) verifier: تعداد دقیق ردیف‌های RunId هر برچسب، audit برچسب‌های rollback، عدم تغییر بیرونی؛
  6) cleanup محدود به BrokerageId=TEST-BROKERAGE و SourceSystem LIKE 'R<RunId>[_]%' با شمارش دقیق در transaction.
verifier با login مالک (sysadmin) فقط می‌خواند و فقط ردیف‌های همان RunId را حذف می‌کند؛ هویت runtime نیست.
حالت‌ها: پیش‌فرض اجرای کامل؛ -PrepareOnly؛ -VerifyRunId <id> [-Cleanup]؛ -NoCleanup.
#>
[CmdletBinding()]
param(
    [switch]$PrepareOnly,
    [ValidatePattern('^[0-9a-f]{16}$')][string]$VerifyRunId,
    [switch]$Cleanup,
    [switch]$NoCleanup,
    [int]$TimeoutSeconds = 900
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$root = 'C:\ProgramData\BAZDID\ConnectedTests'
$taskName = 'BAZDID-Dev-ConnectedSqlTests'
$brokerage = 'TEST-BROKERAGE'
$schemaColumns = 39
$schemaChecksum = 1193879634
# manifest انتظار: برچسب‌های commitشده و تعداد دقیق؛ همهٔ برچسب‌های دیگر باید صفر بمانند.
$expected = @{
    CIDEM  = @{ Customers = 1; Requests = 1; Audit = 1 }
    CCONC  = @{ Customers = 1; Requests = 0; Audit = 0 }
    CTENA  = @{ Customers = 1; Requests = 0; Audit = 0 }
    CTENB  = @{ Customers = 1; Requests = 0; Audit = 0 }
    CSTALE = @{ Customers = 1; Requests = 1; Audit = 0 }
}
$zeroTags = 'KEYS', 'KEYS2', 'RELINK', 'STALE', 'RBACK', 'LOCK', 'AUDX', 'AUDY', 'CTENC'

function Open-Local {
    $b = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
    $b['Data Source'] = 'lpc:localhost\SQLSERVER2019'; $b['Initial Catalog'] = 'BAZDID_Development'
    $b['Integrated Security'] = $true; $b['Encrypt'] = $true; $b['TrustServerCertificate'] = $false
    $b['Connect Timeout'] = 5; $b['Pooling'] = $false; $b['Application Name'] = 'BAZDID-2F-P5-verifier'
    $c = New-Object System.Data.SqlClient.SqlConnection($b.ConnectionString); $c.Open()
    $cmd = $c.CreateCommand()
    $cmd.CommandText = "SELECT DB_NAME(), CONVERT(nvarchar(128),SERVERPROPERTY('InstanceName')), CONVERT(nvarchar(128),CONNECTIONPROPERTY('net_transport')), (SELECT encrypt_option FROM sys.dm_exec_connections WHERE session_id=@@SPID)"
    $r = $cmd.ExecuteReader(); [void]$r.Read()
    $ok = $r[0] -eq 'BAZDID_Development' -and $r[1] -eq 'SQLSERVER2019' -and $r[2] -eq 'Shared memory' -and $r[3] -eq 'TRUE'
    $r.Dispose()
    if (-not $ok) { $c.Dispose(); throw 'مقصد verifier برابر نیست.' }
    return $c
}
function Get-Table($c, [string]$sql, [hashtable]$p = @{}) {
    $cmd = $c.CreateCommand(); $cmd.CommandTimeout = 30; $cmd.CommandText = $sql
    foreach ($k in $p.Keys) { [void]$cmd.Parameters.AddWithValue($k, $p[$k]) }
    $t = New-Object System.Data.DataTable; $r = $cmd.ExecuteReader(); try { $t.Load($r) } finally { $r.Dispose() }
    return ,$t
}
function Get-Baseline {
    $c = Open-Local
    try {
        (Get-Table $c @"
SELECT (SELECT COUNT(*) FROM sys.columns c JOIN sys.tables t ON t.object_id=c.object_id WHERE t.name LIKE N'BAZDID%') AS Columns,
 (SELECT CHECKSUM_AGG(CHECKSUM(t.name,c.name,c.column_id,c.system_type_id,c.max_length,c.is_nullable)) FROM sys.columns c JOIN sys.tables t ON t.object_id=c.object_id WHERE t.name LIKE N'BAZDID%') AS ColumnChecksum,
 (SELECT COUNT(*) FROM sys.tables) AS Tables,
 (SELECT COUNT_BIG(*) FROM dbo.BAZDIDCustomerLinks WHERE NOT (BrokerageId=@B AND SourceSystem LIKE N'R%[_]%')) AS OtherCustomers,
 (SELECT COUNT_BIG(*) FROM dbo.BAZDIDRequestContexts WHERE NOT (BrokerageId=@B AND SourceSystem LIKE N'R%[_]%')) AS OtherRequests,
 (SELECT COUNT_BIG(*) FROM dbo.BAZDIDAuditLogs WHERE NOT (BrokerageId=@B AND SourceSystem LIKE N'R%[_]%')) AS OtherAudit,
 (SELECT COUNT_BIG(*) FROM dbo.BAZDIDCustomerLinks) AS AllCustomers,
 (SELECT COUNT_BIG(*) FROM dbo.BAZDIDRequestContexts) AS AllRequests,
 (SELECT COUNT_BIG(*) FROM dbo.BAZDIDAuditLogs) AS AllAudit;
"@ @{ '@B' = $brokerage }).Rows[0]
    } finally { $c.Dispose() }
}
function Test-Run([string]$runId, $baseline) {
    $problems = New-Object System.Collections.Generic.List[string]
    $prefix = "R$runId" + '_'
    $c = Open-Local
    try {
        $rows = Get-Table $c @"
SELECT SUBSTRING(SourceSystem,LEN(@P)+1,32) AS Tag, 'Customers' AS K, COUNT_BIG(*) AS N FROM dbo.BAZDIDCustomerLinks WHERE BrokerageId=@B AND LEFT(SourceSystem,LEN(@P))=@P GROUP BY SourceSystem
UNION ALL SELECT SUBSTRING(SourceSystem,LEN(@P)+1,32), 'Requests', COUNT_BIG(*) FROM dbo.BAZDIDRequestContexts WHERE BrokerageId=@B AND LEFT(SourceSystem,LEN(@P))=@P GROUP BY SourceSystem
UNION ALL SELECT SUBSTRING(SourceSystem,LEN(@P)+1,32), 'Audit', COUNT_BIG(*) FROM dbo.BAZDIDAuditLogs WHERE BrokerageId=@B AND LEFT(SourceSystem,LEN(@P))=@P GROUP BY SourceSystem;
"@ @{ '@B' = $brokerage; '@P' = $prefix }
        $actual = @{}
        foreach ($r in $rows.Rows) { $actual["$($r.Tag)|$($r.K)"] = [int64]$r.N }
        foreach ($tag in $expected.Keys) { foreach ($k in 'Customers', 'Requests', 'Audit') {
            $want = [int64]$expected[$tag][$k]; $have = if ($actual.ContainsKey("$tag|$k")) { $actual["$tag|$k"] } else { 0 }
            if ($want -ne $have) { $problems.Add("$tag/$k انتظار $want، مشاهده $have") }
        } }
        foreach ($key in $actual.Keys) { $tag = $key.Split('|')[0]; if (-not $expected.ContainsKey($tag)) { $problems.Add("ردیف پایدار برای برچسب rollback/ناشناخته: $key=$($actual[$key])") } }
        $audit = (Get-Table $c "SELECT COUNT_BIG(*) AS N FROM dbo.BAZDIDAuditLogs a JOIN dbo.BAZDIDRequestContexts r ON r.Id=a.RequestContextId AND r.BrokerageId=a.BrokerageId AND r.SourceSystem=a.SourceSystem WHERE a.BrokerageId=@B AND LEFT(a.SourceSystem,LEN(@P))=@P" @{ '@B' = $brokerage; '@P' = $prefix }).Rows[0].N
        if ([int64]$audit -ne 1) { $problems.Add("audit متصل به context همان tenant: $audit") }
        $versions = (Get-Table $c "SELECT SourceVersion FROM dbo.BAZDIDRequestContexts WHERE BrokerageId=@B AND SourceSystem=@S" @{ '@B' = $brokerage; '@S' = ($prefix + 'CSTALE') }).Rows
        if ($versions.Count -ne 1 -or $versions[0].SourceVersion -ne 'TEST-V2') { $problems.Add('نسخهٔ نهایی CSTALE برابر TEST-V2 نیست.') }
    } finally { $c.Dispose() }
    $after = Get-Baseline
    if ($after.Columns -ne $schemaColumns -or $after.ColumnChecksum -ne $schemaChecksum) { $problems.Add("schema تغییر کرده است: $($after.Columns)/$($after.ColumnChecksum)") }
    if ($baseline) {
        foreach ($k in 'Tables', 'OtherCustomers', 'OtherRequests', 'OtherAudit') { if ("$($after.$k)" -ne "$($baseline.$k)") { $problems.Add("تغییر بیرون از دامنه: $k $($baseline.$k) -> $($after.$k)") } }
    }
    [pscustomobject]@{ RunId = $runId; RunRows = ($actual.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join ', '; Problems = @($problems); Pass = ($problems.Count -eq 0) }
}
function Remove-RunRows([string]$runId) {
    $prefix = "R$runId" + '_'
    $wantC = ($expected.Values | ForEach-Object { $_.Customers } | Measure-Object -Sum).Sum
    $wantR = ($expected.Values | ForEach-Object { $_.Requests } | Measure-Object -Sum).Sum
    $wantA = ($expected.Values | ForEach-Object { $_.Audit } | Measure-Object -Sum).Sum
    $c = Open-Local
    try {
        $cmd = $c.CreateCommand(); $cmd.CommandTimeout = 30
        $cmd.CommandText = @"
SET XACT_ABORT ON;
IF LEN(@P)<>18 OR LEFT(@P,1)<>N'R' OR RIGHT(@P,1)<>N'_' THROW 51040,'BAZDID_CLEANUP_SCOPE',1;
BEGIN TRAN;
DELETE FROM dbo.BAZDIDAuditLogs WHERE BrokerageId=@B AND LEFT(SourceSystem,LEN(@P))=@P; DECLARE @A int=@@ROWCOUNT;
DELETE FROM dbo.BAZDIDRequestContexts WHERE BrokerageId=@B AND LEFT(SourceSystem,LEN(@P))=@P; DECLARE @R int=@@ROWCOUNT;
DELETE FROM dbo.BAZDIDCustomerLinks WHERE BrokerageId=@B AND LEFT(SourceSystem,LEN(@P))=@P; DECLARE @C int=@@ROWCOUNT;
IF @A<>@WA OR @R<>@WR OR @C<>@WC BEGIN ROLLBACK; THROW 51041,'BAZDID_CLEANUP_COUNT_MISMATCH',1; END;
COMMIT;
SELECT @A AS Audit,@R AS Requests,@C AS Customers;
"@
        foreach ($kv in @{ '@B' = $brokerage; '@P' = $prefix; '@WA' = $wantA; '@WR' = $wantR; '@WC' = $wantC }.GetEnumerator()) { [void]$cmd.Parameters.AddWithValue($kv.Key, $kv.Value) }
        $r = $cmd.ExecuteReader(); [void]$r.Read(); $deleted = "Audit=$($r[0]) Requests=$($r[1]) Customers=$($r[2])"; $r.Dispose()
        $left = (Get-Table $c "SELECT (SELECT COUNT_BIG(*) FROM dbo.BAZDIDCustomerLinks WHERE LEFT(SourceSystem,LEN(@P))=@P)+(SELECT COUNT_BIG(*) FROM dbo.BAZDIDRequestContexts WHERE LEFT(SourceSystem,LEN(@P))=@P)+(SELECT COUNT_BIG(*) FROM dbo.BAZDIDAuditLogs WHERE LEFT(SourceSystem,LEN(@P))=@P) AS N" @{ '@P' = $prefix }).Rows[0].N
        [pscustomobject]@{ Deleted = $deleted; Remaining = $left }
    } finally { $c.Dispose() }
}
function Publish-Tests {
    $bin = Join-Path $root 'bin'
    if (-not (Test-Path -LiteralPath $bin)) { throw 'پوشهٔ ConnectedTests وجود ندارد؛ ابتدا Register-BazdidConnectedTestTask.review.ps1 (مدیر) اجرا شود.' }
    $tests = Join-Path $bin 'tests'
    if (Test-Path -LiteralPath $tests) { Remove-Item -LiteralPath $tests -Recurse -Force }
    Push-Location $repo
    try {
        & dotnet publish 'tests\Bazdid.IntegrationTests\Bazdid.IntegrationTests.csproj' --configuration Release --no-restore -o $tests | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'publish آزمون‌ها شکست خورد.' }
    } finally { Pop-Location }
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Invoke-BazdidConnectedTests.ps1') -Destination $bin -Force
    Copy-Item -LiteralPath (Join-Path $repo 'global.json') -Destination $bin -Force
    if (Test-Path -LiteralPath (Join-Path $tests 'Bazdid.IntegrationTests.runtimeconfig.dev.json')) { throw 'خروجی publish هنوز به cache کاربر وابسته است.' }
    Write-Host "publish آماده: $tests"
}
function Read-Trx([string]$path) {
    [xml]$x = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    $ns = @{ t = 'http://microsoft.com/schemas/VisualStudio/TeamTest/2010' }
    $counters = (Select-Xml -Xml $x -XPath '//t:ResultSummary/t:Counters' -Namespace $ns).Node
    $results = @(Select-Xml -Xml $x -XPath '//t:UnitTestResult' -Namespace $ns | ForEach-Object { $_.Node })
    [pscustomobject]@{
        Total = [int]$counters.total; Executed = [int]$counters.executed; Passed = [int]$counters.passed; Failed = [int]$counters.failed; NotExecuted = [int]$counters.notExecuted
        Tests = @($results | ForEach-Object { "$($_.outcome) $($_.testName.Split('.')[-1])" })
        Failures = @($results | Where-Object { $_.outcome -ne 'Passed' } | ForEach-Object { "$($_.testName.Split('.')[-1]): $(($_.Output.ErrorInfo.Message) -replace '\s+',' ')" })
    }
}

if ($VerifyRunId) {
    $v = Test-Run $VerifyRunId $null; $v | Format-List
    if ($Cleanup) { if (-not $v.Pass) { throw 'verifier شکست خورد؛ cleanup خودکار انجام نمی‌شود.' }; Remove-RunRows $VerifyRunId | Format-List }
    return
}
Publish-Tests
if ($PrepareOnly) { return }

$baseline = Get-Baseline
if ($baseline.Columns -ne $schemaColumns -or $baseline.ColumnChecksum -ne $schemaChecksum) { throw 'schema پیش از اجرا با مبنا برابر نیست.' }
$latest = Join-Path $root 'results\latest.json'
$previous = if (Test-Path -LiteralPath $latest) { (Get-Content -LiteralPath $latest -Raw | ConvertFrom-Json).RunId } else { '' }
Start-ScheduledTask -TaskName $taskName -TaskPath '\'
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
do {
    Start-Sleep -Seconds 3
    $meta = if (Test-Path -LiteralPath $latest) { try { Get-Content -LiteralPath $latest -Raw | ConvertFrom-Json } catch { $null } } else { $null }
    $done = $meta -and $meta.RunId -ne $previous -and $meta.EndedUtc
} until ($done -or (Get-Date) -gt $deadline)
if (-not $done) { $info = Get-ScheduledTaskInfo -TaskName $taskName -TaskPath '\'; throw "اجرای task در مهلت تمام نشد (LastTaskResult=$($info.LastTaskResult))." }
$runDir = Join-Path $root "results\$($meta.RunId)"
$summary = [ordered]@{ RunId = $meta.RunId; Identity = $meta.Identity; IsAdministratorsMember = $meta.IsAdministratorsMember; ExitCode = $meta.ExitCode; RunnerError = $meta.Error }
$trx = Get-ChildItem -LiteralPath $runDir -Filter *.trx -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if ($trx) { $summary.Tests = Read-Trx $trx.FullName } else { $summary.Tests = $null; $summary.Console = (Get-Content -LiteralPath (Join-Path $runDir 'console.log') -ErrorAction SilentlyContinue | Select-Object -Last 30) -join "`n" }
$summary.Verification = Test-Run $meta.RunId $baseline
if (-not $NoCleanup) {
    if ($summary.Verification.Pass) { $summary.Cleanup = Remove-RunRows $meta.RunId }
    else { $summary.Cleanup = 'انجام نشد: verifier شکست خورد؛ ردیف‌ها برای بررسی حفظ شدند (-VerifyRunId).' }
}
$summary.After = Get-Baseline | Select-Object Columns, ColumnChecksum, Tables, AllCustomers, AllRequests, AllAudit
($summary | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath (Join-Path $runDir 'verification.json') -Encoding UTF8
$summary | ConvertTo-Json -Depth 5
$pass = $summary.Tests -and $summary.Tests.Failed -eq 0 -and $summary.Tests.NotExecuted -eq 0 -and $summary.Tests.Passed -eq $summary.Tests.Total -and $summary.Verification.Pass
if ($pass) { Write-Host 'پذیرش متصل P4/P5: PASS' } else { Write-Host 'پذیرش متصل P4/P5: FAIL'; exit 1 }
