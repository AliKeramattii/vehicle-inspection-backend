#Requires -Version 5.1
<#
پیش‌نویس بازبینی P1 برای Checkpoint 2F — در مخزن اجرا نشده است.
هدف: دو حساب Windows محلی و کم‌اختیار BAZDIDDevWriter و BAZDIDDevReader برای Development.

رفتار (فقط با -Execute):
- اگر هرکدام از حساب‌ها وجود داشته باشد، متوقف می‌شود و هیچ حسابی reset یا جایگزین نمی‌شود.
- رمز تصادفی ۲۵۶ بیتی فقط در حافظه ساخته می‌شود و هرگز نمایش، ثبت یا ذخیره نمی‌شود. اجرای بعدی
  به‌نام این حساب‌ها (P4) رمز را در همان لحظهٔ ثبت task مستقیماً از Task Scheduler تنظیم می‌کند.
- حساب‌ها عضو Administrators، Users یا Remote Desktop Users نمی‌شوند؛ ورود تعاملی/RDP ندارند.
خروجی فقط نام کامل و SID است. بازگشت: Remove-LocalUser برای همین دو نام، پس از حذف login/user SQL.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ExpectedMachine,
    [Parameter(Mandatory = $true)][string]$ApprovalReference,
    [switch]$Execute
)
$ErrorActionPreference = 'Stop'
$names = @('BAZDIDDevWriter', 'BAZDIDDevReader')
$forbiddenGroups = @('S-1-5-32-544', 'S-1-5-32-545', 'S-1-5-32-555')

$principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'این script فقط در PowerShell elevated اجرا می‌شود.' }
if ($env:COMPUTERNAME -ne $ExpectedMachine) { throw 'نام ماشین با مقدار تصویب‌شده برابر نیست.' }
if ([string]::IsNullOrWhiteSpace($ApprovalReference) -or $ApprovalReference.Length -gt 64) { throw 'مرجع تصویب معتبر لازم است.' }
foreach ($name in $names) {
    if (Get-LocalUser -Name $name -ErrorAction SilentlyContinue) { throw "حساب $name از قبل وجود دارد؛ این script آن را تغییر یا reset نمی‌کند." }
}
[pscustomobject]@{ Machine = $env:COMPUTERNAME; Accounts = ($names -join ', '); Execute = [bool]$Execute } | Format-List
if (-not $Execute) { Write-Output 'اجرای آزمایشی: هیچ حسابی ساخته نشد.'; return }

$rng = [Security.Cryptography.RandomNumberGenerator]::Create()
try {
    foreach ($name in $names) {
        $bytes = New-Object byte[] 32
        $rng.GetBytes($bytes)
        $secure = New-Object Security.SecureString
        foreach ($c in ([Convert]::ToBase64String($bytes) + 'aA1!').ToCharArray()) { $secure.AppendChar($c) }
        [Array]::Clear($bytes, 0, $bytes.Length)
        $secure.MakeReadOnly()
        New-LocalUser -Name $name -Password $secure -PasswordNeverExpires -UserMayNotChangePassword -AccountNeverExpires `
            -Description "BAZDID Development SQL identity ($ApprovalReference); non-interactive" | Out-Null
        $secure.Dispose()
    }
} finally { $rng.Dispose() }

foreach ($name in $names) {
    $user = Get-LocalUser -Name $name
    foreach ($group in $forbiddenGroups) {
        $members = Get-LocalGroupMember -SID $group -ErrorAction SilentlyContinue
        if ($members | Where-Object { $_.SID -eq $user.SID }) { throw "حساب $name عضو گروه غیرمجاز $group است." }
    }
    [pscustomobject]@{ Account = "$env:COMPUTERNAME\$name"; Sid = $user.SID.Value; Enabled = $user.Enabled } | Format-List
}
