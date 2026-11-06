#Requires -Version 5.1
<#
پیش‌نویس بازبینی P3 برای Checkpoint 2F (بازنگری 2026-11-07) — عامل آن را اجرا نکرده است.
هدف: certificate اختصاصی TLS برای instance محلی SQLSERVER2019 تا اتصال برنامه با Encrypt=true و
TrustServerCertificate=false اعتبارسنجی شود. هیچ bypass اعتبارسنجی ندارد و تنظیم کلاینت یا
ForceEncryption را تغییر نمی‌دهد.

حالت‌ها (همه فقط در PowerShell elevated):
- بدون سوئیچ: اجرای آزمایشی؛ وضعیت فعلی، پیش‌شرط‌ها و برنامه را چاپ می‌کند.
- -Execute [-RestartSqlService]: ساخت و تنظیم؛ هر شکست، همهٔ تغییرهای همین اجرا را به ترتیب معکوس برمی‌گرداند.
- -VerifyOnly: خواندن و مقایسهٔ دقیق certificate، registry، ACL کلید، trust و بارگذاری در ERRORLOG.
- -RollbackThumbprint <thumb> [-Execute] [-RestartSqlService]: حذف فقط certificate دارای نشانهٔ BAZDID.

certificate: CN=<نام DNS میزبان یا FQDN>، SAN شامل نام NetBIOS، نام DNS، FQDN (در صورت وجود) و localhost؛
EKU فقط serverAuth؛ BasicConstraints بحرانی با CA=false؛ KeyUsage فقط DigitalSignature و KeyEncipherment
(بدون keyCertSign، پس نمی‌تواند certificate دیگری را امضا کند)؛ RSA 2048 با KeySpec=KeyExchange در
«Microsoft RSA SChannel Cryptographic Provider»؛ کلید غیرقابل‌export؛ اعتبار یک‌ساله.
trust: فقط بخش عمومی همین certificate در LocalMachine\Root. چون کلاینت‌های آزمون با حساب‌های جدا
(Writer/Reader) اجرا می‌شوند، store کاربر کافی نیست؛ محدودیت‌های بالا گسترهٔ این trust را به همین نام‌ها
و همین کلید غیرقابل‌export محدود می‌کنند.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ExpectedMachine,
    [Parameter(Mandatory = $true)][ValidatePattern('^[A-Za-z0-9._-]{1,32}$')][string]$ApprovalReference,
    [switch]$Execute,
    [switch]$RestartSqlService,
    [switch]$VerifyOnly,
    [ValidatePattern('^[0-9A-Fa-f]{40}$')][string]$RollbackThumbprint
)
$ErrorActionPreference = 'Stop'
$serviceName = 'MSSQL$SQLSERVER2019'
$serviceAccount = 'NT Service\MSSQL$SQLSERVER2019'
$instanceKey = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL15.SQLSERVER2019\MSSQLServer'
$netKey = "$instanceKey\SuperSocketNetLib"
$paramsKey = "$instanceKey\Parameters"
$marker = 'BAZDID Development SQL TLS'
$serverAuthOid = '1.3.6.1.5.5.7.3.1'
$restartTimeout = [TimeSpan]::FromSeconds(120)

if ($VerifyOnly -and ($Execute -or $RestartSqlService -or $RollbackThumbprint)) { throw '-VerifyOnly با سوئیچ تغییر ترکیب نمی‌شود.' }
if ($RestartSqlService -and -not $Execute) { throw '-RestartSqlService فقط همراه -Execute معتبر است.' }

$principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'این script فقط در PowerShell elevated اجرا می‌شود.' }
if ($env:COMPUTERNAME -ne $ExpectedMachine) { throw 'نام ماشین با مقدار تصویب‌شده برابر نیست.' }
if (-not (Test-Path $netKey)) { throw 'instance MSSQL15.SQLSERVER2019 یافت نشد.' }
$service = Get-CimInstance Win32_Service -Filter "Name='MSSQL`$SQLSERVER2019'"
if ($null -eq $service -or $service.StartName -ne $serviceAccount) { throw 'حساب سرویس SQL با مقدار انتظاری برابر نیست.' }
$serviceSid = (New-Object Security.Principal.NTAccount($serviceAccount)).Translate([Security.Principal.SecurityIdentifier])

# ---------- نام‌ها ----------
$ipProperties = [Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()
$dnsHost = $ipProperties.HostName
$fqdn = if ([string]::IsNullOrEmpty($ipProperties.DomainName)) { $null } else { "$dnsHost.$($ipProperties.DomainName)" }
$commonName = if ($fqdn) { $fqdn } else { $dnsHost }
$dnsNames = New-Object System.Collections.Generic.List[string]
foreach ($n in @($commonName, $dnsHost, $env:COMPUTERNAME, 'localhost')) { if ($n -and -not ($dnsNames -contains $n)) { $dnsNames.Add($n) } }

# ---------- توابع کمکی ----------
function Get-BazdidMarkedCertificates([string]$StoreName) {
    @(Get-ChildItem "Cert:\LocalMachine\$StoreName" | Where-Object { "$($_.FriendlyName)".StartsWith($marker) })
}

function Get-BazdidKeyFile([Security.Cryptography.X509Certificates.X509Certificate2]$Certificate) {
    $container = $Certificate.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
    $path = Join-Path $env:ProgramData "Microsoft\Crypto\RSA\MachineKeys\$container"
    if (-not (Test-Path -LiteralPath $path)) { throw 'فایل کلید خصوصی در MachineKeys یافت نشد.' }
    return $path
}

function Test-BazdidServiceKeyRead([string]$Path) {
    $acl = [IO.File]::GetAccessControl($Path, [Security.AccessControl.AccessControlSections]::Access)
    $read = [Security.AccessControl.FileSystemRights]::Read
    @($acl.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier]) | Where-Object {
        $_.IdentityReference -eq $serviceSid -and $_.AccessControlType -eq 'Allow' -and (($_.FileSystemRights -band $read) -eq $read)
    }).Count -gt 0
}

function Get-BazdidErrorLogPath {
    $parameters = Get-ItemProperty $paramsKey
    foreach ($property in $parameters.PSObject.Properties) {
        if ($property.Name -like 'SQLArg*' -and "$($property.Value)" -like '-e*') { return "$($property.Value)".Substring(2) }
    }
    throw 'مسیر ERRORLOG در Parameters یافت نشد.'
}

function Get-BazdidErrorLogStatus([string]$Thumbprint) {
    $stream = [IO.File]::Open((Get-BazdidErrorLogPath), 'Open', 'Read', 'ReadWrite')
    try { $text = (New-Object IO.StreamReader($stream, [Text.Encoding]::Unicode, $true)).ReadToEnd() } finally { $stream.Dispose() }
    [pscustomobject]@{
        Loaded = ($text -match ('Cert Hash\(sha1\) "' + [regex]::Escape($Thumbprint) + '"\] was successfully loaded for encryption'))
        LoadFailed = ($text -match 'Unable to load user-specified certificate')
    }
}

function Wait-BazdidCertificateLoad([string]$Thumbprint) {
    # ERRORLOG با هر ری‌استارت چرخش می‌کند، پس فقط پیام‌های همین اجرای سرویس بررسی می‌شوند.
    $deadline = (Get-Date).AddSeconds(60)
    do {
        $log = Get-BazdidErrorLogStatus $Thumbprint
        if ($log.Loaded -or $log.LoadFailed) { return $log }
        Start-Sleep -Seconds 2
    } while ((Get-Date) -lt $deadline)
    return $log
}

function Test-BazdidCertificate([string]$Thumbprint) {
    # فهرست مشکل‌ها را برمی‌گرداند؛ فهرست خالی یعنی certificate با همهٔ الزام‌ها برابر است.
    $problems = New-Object System.Collections.Generic.List[string]
    $path = "Cert:\LocalMachine\My\$Thumbprint"
    if (-not (Test-Path $path)) { $problems.Add('certificate در LocalMachine\My نیست'); return $problems }
    $cert = Get-Item $path
    $now = Get-Date
    if (-not $cert.HasPrivateKey) { $problems.Add('کلید خصوصی ندارد') }
    else {
        $info = $cert.PrivateKey.CspKeyContainerInfo
        if ($info.KeyNumber -ne [Security.Cryptography.KeyNumber]::Exchange) { $problems.Add('KeySpec برابر KeyExchange نیست') }
        if ($info.Exportable) { $problems.Add('کلید خصوصی قابل export است') }
        if ($cert.PublicKey.Key.KeySize -lt 2048) { $problems.Add('طول کلید کمتر از 2048 است') }
        if (-not (Test-BazdidServiceKeyRead (Get-BazdidKeyFile $cert))) { $problems.Add('حساب سرویس SQL مجوز Read کلید را ندارد') }
    }
    if ($cert.NotBefore -gt $now -or $cert.NotAfter -lt $now) { $problems.Add('خارج از بازهٔ اعتبار است') }
    $eku = @($cert.Extensions | Where-Object { $_ -is [Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension] })
    if (($eku.Count -ne 1) -or ((@($eku[0].EnhancedKeyUsages | ForEach-Object Value) -join ',') -ne $serverAuthOid)) { $problems.Add('EKU دقیقاً serverAuth نیست') }
    $basic = @($cert.Extensions | Where-Object { $_ -is [Security.Cryptography.X509Certificates.X509BasicConstraintsExtension] })
    if ($basic.Count -ne 1 -or $basic[0].CertificateAuthority -or -not $basic[0].Critical) { $problems.Add('BasicConstraints بحرانی با CA=false ندارد') }
    $usage = @($cert.Extensions | Where-Object { $_ -is [Security.Cryptography.X509Certificates.X509KeyUsageExtension] })
    $certSign = [Security.Cryptography.X509Certificates.X509KeyUsageFlags]::KeyCertSign
    $keyEnc = [Security.Cryptography.X509Certificates.X509KeyUsageFlags]::KeyEncipherment
    if (($usage.Count -ne 1) -or ([int]($usage[0].KeyUsages -band $certSign) -ne 0) -or ([int]($usage[0].KeyUsages -band $keyEnc) -eq 0)) { $problems.Add('KeyUsage باید KeyEncipherment داشته باشد و KeyCertSign نداشته باشد') }
    $san = @($cert.DnsNameList | ForEach-Object Unicode)
    foreach ($n in $dnsNames) { if (-not ($san -contains $n)) { $problems.Add("SAN شامل $n نیست") } }
    if ($cert.Subject -ne "CN=$commonName") { $problems.Add("Subject برابر CN=$commonName نیست") }
    $rootPath = "Cert:\LocalMachine\Root\$Thumbprint"
    if (-not (Test-Path $rootPath)) { $problems.Add('بخش عمومی در LocalMachine\Root نیست') }
    else {
        $rootCopy = Get-Item $rootPath
        if ($rootCopy.HasPrivateKey) { $problems.Add('نسخهٔ Root کلید خصوصی دارد') }
        if (-not "$($rootCopy.FriendlyName)".StartsWith($marker)) { $problems.Add('نسخهٔ Root نشانهٔ BAZDID ندارد') }
    }
    $chain = New-Object Security.Cryptography.X509Certificates.X509Chain
    $chain.ChainPolicy.RevocationMode = [Security.Cryptography.X509Certificates.X509RevocationMode]::NoCheck
    [void]$chain.ChainPolicy.ApplicationPolicy.Add((New-Object Security.Cryptography.Oid($serverAuthOid)))
    if (-not $chain.Build($cert)) { $problems.Add("زنجیره معتبر نیست: $(($chain.ChainStatus | ForEach-Object Status) -join ', ')") }
    $chain.Reset()
    return $problems
}

function Get-BazdidRunningDependents {
    @((Get-Service -Name $serviceName).DependentServices | Where-Object { $_.Status -ne 'Stopped' } | ForEach-Object Name)
}

function Assert-BazdidRestartPrerequisites {
    $svc = Get-Service -Name $serviceName
    if ($svc.Status -ne 'Running') { throw "سرویس $serviceName در وضعیت Running نیست ($($svc.Status)); ری‌استارت خودکار انجام نمی‌شود." }
    if ($service.StartMode -eq 'Disabled') { throw 'سرویس SQL غیرفعال است.' }
    $dependents = @(Get-BazdidRunningDependents)
    if ($dependents.Count -gt 0) { throw "سرویس‌های وابستهٔ در حال اجرا: $($dependents -join ', ')؛ ابتدا آن‌ها را با بازبینی متوقف کنید." }
}

function Restart-BazdidSql {
    Restart-Service -Name $serviceName
    (Get-Service -Name $serviceName).WaitForStatus('Running', $restartTimeout)
}

function Get-BazdidRegistryCertificate { "$((Get-ItemProperty $netKey).Certificate)" }

function Remove-BazdidCertificateState([string]$Thumbprint, [string]$RestoreRegistryValue) {
    # بازگشت به ترتیب معکوس: registry، Root، My. هر گام مستقل گزارش می‌شود تا بازگشت ناقص پنهان نماند.
    $remaining = New-Object System.Collections.Generic.List[string]
    try {
        if ((Get-BazdidRegistryCertificate) -eq $Thumbprint.ToLowerInvariant()) { Set-ItemProperty -Path $netKey -Name Certificate -Value $RestoreRegistryValue }
    } catch { $remaining.Add("registry Certificate: $($_.Exception.Message)") }
    try { if (Test-Path "Cert:\LocalMachine\Root\$Thumbprint") { Remove-Item "Cert:\LocalMachine\Root\$Thumbprint" } } catch { $remaining.Add("Root: $($_.Exception.Message)") }
    try { if (Test-Path "Cert:\LocalMachine\My\$Thumbprint") { Remove-Item "Cert:\LocalMachine\My\$Thumbprint" -DeleteKey } } catch { $remaining.Add("My: $($_.Exception.Message)") }
    return $remaining
}

# ---------- وضعیت فعلی ----------
$registryCertificate = Get-BazdidRegistryCertificate
$state = [pscustomobject]@{
    Machine = $env:COMPUTERNAME; Service = $serviceName; ServiceAccount = $serviceAccount
    ServiceStatus = (Get-Service -Name $serviceName).Status; RunningDependents = ((Get-BazdidRunningDependents) -join ', ')
    RegistryCertificate = $registryCertificate; ForceEncryption = (Get-ItemProperty $netKey).ForceEncryption
    MarkedInMy = ((Get-BazdidMarkedCertificates 'My' | ForEach-Object Thumbprint) -join ', ')
    MarkedInRoot = ((Get-BazdidMarkedCertificates 'Root' | ForEach-Object Thumbprint) -join ', ')
    CommonName = $commonName; DnsNames = ($dnsNames -join ', ')
}
$state | Format-List

# ---------- -VerifyOnly ----------
if ($VerifyOnly) {
    if ([string]::IsNullOrEmpty($registryCertificate)) { throw 'مقدار Certificate در registry خالی است؛ P3 اعمال نشده است.' }
    $thumb = $registryCertificate.ToUpperInvariant()
    $problems = @(Test-BazdidCertificate $thumb)
    if (-not "$((Get-Item "Cert:\LocalMachine\My\$thumb" -ErrorAction SilentlyContinue).FriendlyName)".StartsWith($marker)) { $problems += 'certificate تنظیم‌شده نشانهٔ BAZDID ندارد' }
    $log = Get-BazdidErrorLogStatus $thumb
    if (-not $log.Loaded) { $problems += 'ERRORLOG فعلی بارگذاری همین certificate را نشان نمی‌دهد (ری‌استارت انجام نشده یا بارگذاری شکست خورده)' }
    [pscustomobject]@{ Thumbprint = $thumb; LoadedPerErrorLog = $log.Loaded; LoadFailureInErrorLog = $log.LoadFailed; Problems = ($problems -join '؛ ') } | Format-List
    if ($problems.Count -gt 0) { throw 'راستی‌آزمایی P3 ناموفق است.' }
    Write-Output 'راستی‌آزمایی P3: PASS'
    return
}

# ---------- -RollbackThumbprint ----------
if ($RollbackThumbprint) {
    $thumb = $RollbackThumbprint.ToUpperInvariant()
    $inMy = Get-Item "Cert:\LocalMachine\My\$thumb" -ErrorAction SilentlyContinue
    $inRoot = Get-Item "Cert:\LocalMachine\Root\$thumb" -ErrorAction SilentlyContinue
    foreach ($c in @($inMy, $inRoot) | Where-Object { $_ }) {
        if (-not "$($c.FriendlyName)".StartsWith($marker)) { throw 'certificate نشانهٔ BAZDID ندارد؛ این script آن را حذف نمی‌کند.' }
    }
    if ($registryCertificate -and $registryCertificate -ne $thumb.ToLowerInvariant()) { throw 'registry به certificate دیگری اشاره می‌کند؛ بازگشت متوقف شد.' }
    [pscustomobject]@{ Thumbprint = $thumb; InMy = [bool]$inMy; InRoot = [bool]$inRoot; RegistryPointsHere = ($registryCertificate -eq $thumb.ToLowerInvariant()); Restart = [bool]$RestartSqlService } | Format-List
    if (-not $Execute) { Write-Output 'اجرای آزمایشی بازگشت: هیچ تغییری انجام نشد.'; return }
    if ($RestartSqlService) { Assert-BazdidRestartPrerequisites }
    $remaining = @(Remove-BazdidCertificateState $thumb '')
    if ($remaining.Count -gt 0) { throw "بازگشت ناقص ماند: $($remaining -join ' | ')" }
    if ($RestartSqlService) { Restart-BazdidSql; Write-Output 'سرویس با تنظیم بدون certificate اختصاصی دوباره اجرا شد.' }
    else { Write-Output 'بازگشت پیکربندی انجام شد؛ تا ری‌استارت بعدی، سرویس در حال اجرا certificate قبلی را در حافظه دارد.' }
    return
}

# ---------- ساخت: پیش‌شرط‌ها ----------
if (-not [string]::IsNullOrEmpty($registryCertificate)) { throw 'برای instance از قبل certificate تنظیم شده است؛ جایگزینی بدون بازبینی جدا مجاز نیست.' }
if ($state.MarkedInMy -or $state.MarkedInRoot) { throw 'certificate باقی‌ماندهٔ BAZDID از اجرای قبلی وجود دارد؛ ابتدا با -RollbackThumbprint بازبینی و حذف کنید.' }
if ($RestartSqlService) { Assert-BazdidRestartPrerequisites; [void](Get-BazdidErrorLogPath) }
if (-not $Execute) {
    Write-Output 'اجرای آزمایشی: هیچ تغییری انجام نشد. پیش‌شرط‌ها برقرارند.'
    if (-not $RestartSqlService) { Write-Output 'برای بارگذاری certificate، اجرای واقعی با -RestartSqlService لازم است (بررسی پیش‌شرط ری‌استارت در همان اجرا).' }
    return
}

# ---------- ساخت: اجرا با بازگشت خودکار ----------
$thumb = $null
$restarted = $false
try {
    $basic = New-Object Security.Cryptography.X509Certificates.X509BasicConstraintsExtension($false, $false, 0, $true)
    $oids = New-Object Security.Cryptography.OidCollection
    [void]$oids.Add((New-Object Security.Cryptography.Oid($serverAuthOid)))
    $eku = New-Object Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension($oids, $false)
    $cert = New-SelfSignedCertificate -Type Custom -Subject "CN=$commonName" -DnsName $dnsNames.ToArray() `
        -CertStoreLocation 'Cert:\LocalMachine\My' -KeyExportPolicy NonExportable -KeySpec KeyExchange `
        -Provider 'Microsoft RSA SChannel Cryptographic Provider' -KeyAlgorithm RSA -KeyLength 2048 -HashAlgorithm SHA256 `
        -KeyUsage DigitalSignature, KeyEncipherment -Extension @($basic, $eku) `
        -NotBefore (Get-Date).AddMinutes(-5) -NotAfter (Get-Date).AddYears(1) `
        -FriendlyName "$marker ($ApprovalReference)"
    $thumb = $cert.Thumbprint

    $keyPath = Get-BazdidKeyFile (Get-Item "Cert:\LocalMachine\My\$thumb")
    $acl = [IO.File]::GetAccessControl($keyPath, [Security.AccessControl.AccessControlSections]::Access)
    $acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule($serviceSid, [Security.AccessControl.FileSystemRights]::Read, 'Allow')))
    [IO.File]::SetAccessControl($keyPath, $acl)

    $root = New-Object Security.Cryptography.X509Certificates.X509Store('Root', 'LocalMachine')
    $root.Open('ReadWrite')
    try {
        $publicCopy = New-Object Security.Cryptography.X509Certificates.X509Certificate2(, $cert.RawData)
        $publicCopy.FriendlyName = "$marker ($ApprovalReference)"
        $root.Add($publicCopy)
    } finally { $root.Close() }

    $problems = @(Test-BazdidCertificate $thumb)
    if ($problems.Count -gt 0) { throw "certificate با الزام‌ها برابر نیست: $($problems -join '؛ ')" }

    Set-ItemProperty -Path $netKey -Name Certificate -Value $thumb.ToLowerInvariant()
    if ((Get-BazdidRegistryCertificate) -ne $thumb.ToLowerInvariant()) { throw 'مقدار registry پس از نوشتن برابر نیست.' }

    if ($RestartSqlService) {
        $restarted = $true
        Restart-BazdidSql
        $log = Wait-BazdidCertificateLoad $thumb
        if (-not $log.Loaded) { throw 'سرویس اجرا شد ولی ERRORLOG در ۶۰ ثانیه بارگذاری certificate را تأیید نکرد.' }
    }
} catch {
    $failure = $_
    Write-Warning 'شکست P3؛ تغییرهای همین اجرا برگردانده می‌شوند.'
    if ($thumb) {
        $remaining = @(Remove-BazdidCertificateState $thumb '')
        if ($remaining.Count -gt 0) { Write-Warning "بازگشت ناقص؛ با -RollbackThumbprint $thumb ادامه دهید: $($remaining -join ' | ')" }
    }
    if ($restarted) {
        try { Restart-BazdidSql; Write-Warning 'سرویس SQL با پیکربندی قبلی دوباره اجرا شد.' }
        catch { Write-Warning "اجرای دوبارهٔ سرویس SQL ناموفق بود؛ ERRORLOG و Event Log را بررسی کنید: $($_.Exception.Message)" }
    }
    throw $failure
}

[pscustomobject]@{
    Thumbprint = $thumb; Subject = "CN=$commonName"; DnsNames = ($dnsNames -join ', ')
    NotAfter = (Get-Item "Cert:\LocalMachine\My\$thumb").NotAfter.ToString('yyyy-MM-dd'); Restarted = $restarted
} | Format-List
if ($RestartSqlService) { Write-Output 'P3: certificate بارگذاری شد؛ برای شاهد مستقل -VerifyOnly را اجرا کنید.' }
else { Write-Output 'P3: پیکربندی نوشته شد ولی بارگذاری نشده است؛ پس از ری‌استارت بازبینی‌شده، -VerifyOnly را اجرا کنید.' }
