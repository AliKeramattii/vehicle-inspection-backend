#Requires -Version 5.1
<#
پیش‌نویس بازبینی P3 برای Checkpoint 2F — در مخزن اجرا نشده است.
هدف: certificate اختصاصی TLS برای instance محلی SQLSERVER2019 تا اتصال برنامه با
Encrypt=true و TrustServerCertificate=false قابل اعتبارسنجی باشد. هیچ bypass اعتبارسنجی ندارد.

اثرها (فقط با -Execute): ساخت certificate با کلید غیرقابل‌export در LocalMachine\My،
مجوز Read کلید خصوصی برای حساب سرویس، افزودن بخش عمومی همان certificate به LocalMachine\Root،
ثبت thumbprint در SuperSocketNetLib\Certificate. ری‌استارت سرویس فقط با -RestartSqlService.
بدون -Execute فقط پیش‌شرط‌ها و برنامه چاپ می‌شوند.

بازگشت: مقدار Certificate را خالی کنید، certificate را از LocalMachine\Root و LocalMachine\My
حذف کنید و سرویس را ری‌استارت کنید. هیچ رمز یا کلید خصوصی خروجی گرفته نمی‌شود.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ExpectedMachine,
    [Parameter(Mandatory = $true)][string]$ApprovalReference,
    [switch]$Execute,
    [switch]$RestartSqlService
)
$ErrorActionPreference = 'Stop'
$serviceName = 'MSSQL$SQLSERVER2019'
$serviceAccount = 'NT Service\MSSQL$SQLSERVER2019'
$netKey = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL15.SQLSERVER2019\MSSQLServer\SuperSocketNetLib'

$principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'این script فقط در PowerShell elevated اجرا می‌شود.' }
if ($env:COMPUTERNAME -ne $ExpectedMachine) { throw 'نام ماشین با مقدار تصویب‌شده برابر نیست.' }
if ([string]::IsNullOrWhiteSpace($ApprovalReference) -or $ApprovalReference.Length -gt 64) { throw 'مرجع تصویب معتبر لازم است.' }
if (-not (Test-Path $netKey)) { throw 'instance MSSQL15.SQLSERVER2019 یافت نشد.' }
$current = (Get-ItemProperty $netKey).Certificate
if (-not [string]::IsNullOrEmpty($current)) { throw 'برای instance از قبل certificate تنظیم شده است؛ جایگزینی بدون بازبینی جدا مجاز نیست.' }
$service = Get-CimInstance Win32_Service -Filter "Name='MSSQL`$SQLSERVER2019'"
if ($null -eq $service -or $service.StartName -ne $serviceAccount) { throw 'حساب سرویس SQL با مقدار انتظاری برابر نیست.' }

$dnsNames = @($env:COMPUTERNAME, 'localhost')
$fqdn = [Net.Dns]::GetHostEntry('').HostName
if ($fqdn -and ($dnsNames -notcontains $fqdn)) { $dnsNames += $fqdn }

[pscustomobject]@{
    Machine = $env:COMPUTERNAME; Service = $serviceName; ServiceAccount = $serviceAccount
    DnsNames = ($dnsNames -join ', '); ValidityYears = 1; Execute = [bool]$Execute; RestartSqlService = [bool]$RestartSqlService
} | Format-List
if (-not $Execute) { Write-Output 'اجرای آزمایشی: هیچ تغییری انجام نشد.'; return }

$cert = New-SelfSignedCertificate -Subject "CN=$env:COMPUTERNAME" -DnsName $dnsNames `
    -CertStoreLocation 'Cert:\LocalMachine\My' -KeyExportPolicy NonExportable -KeySpec KeyExchange `
    -Provider 'Microsoft RSA SChannel Cryptographic Provider' -KeyLength 2048 -HashAlgorithm SHA256 `
    -NotAfter (Get-Date).AddYears(1) -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.1') `
    -FriendlyName "BAZDID Development SQL TLS ($ApprovalReference)"

$container = $cert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
$keyPath = Join-Path $env:ProgramData "Microsoft\Crypto\RSA\MachineKeys\$container"
$acl = Get-Acl $keyPath
$acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule($serviceAccount, 'Read', 'Allow')))
Set-Acl -Path $keyPath -AclObject $acl

$root = New-Object Security.Cryptography.X509Certificates.X509Store('Root', 'LocalMachine')
$root.Open('ReadWrite')
try { $root.Add((New-Object Security.Cryptography.X509Certificates.X509Certificate2(, $cert.RawData))) } finally { $root.Close() }

Set-ItemProperty -Path $netKey -Name Certificate -Value $cert.Thumbprint.ToLowerInvariant()

if ($RestartSqlService) { Restart-Service -Name $serviceName } else { Write-Output 'برای بارگذاری certificate، ری‌استارت سرویس لازم است.' }
[pscustomobject]@{ Thumbprint = $cert.Thumbprint; NotAfter = $cert.NotAfter.ToString('yyyy-MM-dd'); DnsNames = ($dnsNames -join ', ') } | Format-List
