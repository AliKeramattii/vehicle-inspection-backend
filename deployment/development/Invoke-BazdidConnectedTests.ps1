<#
runner آزمون SQL متصل — فقط داخل task «BAZDID-Dev-ConnectedSqlTests» و با token واقعی BAZDIDDevWriter اجرا می‌شود.
اپراتور این فایل را همراه خروجی publish آزمون‌ها در C:\ProgramData\BAZDID\ConnectedTests\bin قرار می‌دهد.
خروجی: results\<RunId>\{run.json,console.log,connected.trx} و results\latest.json. هیچ رمز یا connection string محرمانه‌ای ثبت نمی‌شود.
#>
$ErrorActionPreference = 'Stop'
$bin = $PSScriptRoot
$root = Split-Path $bin -Parent
$rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
$bytes = New-Object byte[] 8; $rng.GetBytes($bytes); $rng.Dispose()
$runId = -join ($bytes | ForEach-Object { $_.ToString('x2') })
$out = Join-Path $root "results\$runId"
[void](New-Item -ItemType Directory -Path $out)
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$meta = [ordered]@{
    RunId = $runId; Identity = $identity.Name; Machine = $env:COMPUTERNAME
    IsAdministratorsMember = [bool]($identity.Groups | Where-Object { $_.Value -eq 'S-1-5-32-544' })
    StartedUtc = [DateTime]::UtcNow.ToString('o'); EndedUtc = $null; ExitCode = $null; Error = $null
}
function Save-Meta { $json = $meta | ConvertTo-Json; Set-Content -LiteralPath (Join-Path $out 'run.json') -Value $json -Encoding UTF8; Set-Content -LiteralPath (Join-Path $root 'results\latest.json') -Value $json -Encoding UTF8 }
Save-Meta
try {
    if ($identity.Name -ne "$env:COMPUTERNAME\BAZDIDDevWriter" -or $meta.IsAdministratorsMember) { throw 'runner فقط با token غیرمدیر BAZDIDDevWriter مجاز است.' }
    $dll = Join-Path $bin 'tests\Bazdid.IntegrationTests.dll'
    if (-not (Test-Path -LiteralPath $dll)) { throw 'خروجی publish آزمون‌ها یافت نشد.' }
    $env:BAZDID_CONNECTED_SQL = '1'
    $env:BAZDID_TEST_RUN_ID = $runId
    $env:DOTNET_SKIP_FIRST_TIME_EXPERIENCE = '1'
    $env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'
    $env:DOTNET_NOLOGO = '1'
    Push-Location $bin   # global.json همین پوشه SDK 2.1.818 را pin می‌کند.
    try {
        & "$env:ProgramFiles\dotnet\dotnet.exe" vstest $dll '/TestCaseFilter:FullyQualifiedName~Bazdid.IntegrationTests.SqlRepositoryConnectedTests' '/logger:trx;LogFileName=connected.trx' "/ResultsDirectory:$out" *> (Join-Path $out 'console.log')
        $meta.ExitCode = $LASTEXITCODE
    } finally { Pop-Location }
} catch {
    $meta.Error = $_.Exception.Message
    if ($null -eq $meta.ExitCode) { $meta.ExitCode = 2 }
} finally {
    $meta.EndedUtc = [DateTime]::UtcNow.ToString('o')
    Save-Meta
}
exit $meta.ExitCode
