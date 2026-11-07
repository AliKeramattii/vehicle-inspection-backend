<#
P4 — provisioning اجرای آزمون SQL متصل با هویت واقعی BAZDIDDevWriter (فقط Development محلی).
نیازمند PowerShell با Run as Administrator. کارها:
  1) پوشهٔ C:\ProgramData\BAZDID\ConnectedTests با ACL محافظت‌شده (Writer فقط خواندن/اجرا؛ نوشتن فقط در results).
  2) رمز تصادفی ۲۴۰ بیتی درون حافظه، اعمال روی حساب Writer و ثبت در task (LSA secrets). رمز هرگز نمایش/ذخیره/لاگ نمی‌شود.
  3) task درخواستی (بدون trigger) با RunLevel=Limited که فقط runner ثابت را اجرا می‌کند؛ اپراتور غیرمدیر فقط حق خواندن/اجرا دارد.
حالت‌ها: بدون سوئیچ = dry run؛ -Execute؛ -VerifyOnly؛ -Rotate -Execute (چرخش رمز)؛ -Remove -Execute.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidatePattern('^[A-Za-z0-9-]{1,15}$')][string]$ExpectedMachine,
    [Parameter(Mandatory = $true)][ValidatePattern('^[A-Za-z0-9._-]{1,32}$')][string]$ApprovalReference,
    [string]$OperatorAccount = "$env:USERDOMAIN\$env:USERNAME",
    [switch]$Execute,
    [switch]$VerifyOnly,
    [switch]$Rotate,
    [switch]$Remove
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
$taskName = 'BAZDID-Dev-ConnectedSqlTests'
$root = 'C:\ProgramData\BAZDID\ConnectedTests'
$runner = Join-Path $root 'bin\Invoke-BazdidConnectedTests.ps1'
$writerName = 'BAZDIDDevWriter'

if ($env:COMPUTERNAME -ne $ExpectedMachine) { throw 'نام ماشین با مقدار مورد انتظار برابر نیست.' }
if (@($VerifyOnly, $Rotate, $Remove | Where-Object { $_ }).Count -gt 1) { throw 'فقط یکی از -VerifyOnly، -Rotate یا -Remove مجاز است.' }
if ($VerifyOnly -and $Execute) { throw '-VerifyOnly با -Execute ترکیب نمی‌شود.' }
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
# -VerifyOnly فقط می‌خواند و از نشست غیرمدیر اپراتور هم قابل اجراست؛ هر تغییر به token مدیر نیاز دارد.
if (-not $isAdmin -and -not $VerifyOnly) { throw 'این script به PowerShell با Run as Administrator نیاز دارد.' }

$writer = Get-LocalUser -Name $writerName -ErrorAction Stop
if (-not $writer.Enabled -or $writer.Description -notlike 'BAZDID-DEV-SQL *') { throw 'حساب Writer با نشانهٔ P1 مطابقت ندارد.' }
$writerAccount = "$ExpectedMachine\$writerName"
$operatorSid = (New-Object Security.Principal.NTAccount($OperatorAccount)).Translate([Security.Principal.SecurityIdentifier]).Value
if ($OperatorAccount -match 'BAZDIDDev(Writer|Reader)$') { throw 'اپراتور نباید حساب Writer/Reader باشد.' }

function New-Secret {
    $alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_'.ToCharArray()
    $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
    $buffer = New-Object byte[] 40
    $rng.GetBytes($buffer)
    $secure = New-Object System.Security.SecureString
    foreach ($b in $buffer) { $secure.AppendChar($alphabet[$b % 64]) }
    [Array]::Clear($buffer, 0, $buffer.Length); $rng.Dispose()
    $secure.MakeReadOnly()
    return $secure
}
function Invoke-WithPlain([Security.SecureString]$secure, [scriptblock]$operation) {
    # Register/Set-ScheduledTask رمز را به‌صورت string می‌گیرند؛ فقط لحظه‌ای در همین فرایند و بدون خروجی.
    # نام پارامتر نباید با متغیرهای script (مانند $action) یکی باشد؛ callback با dynamic scope آن‌ها را می‌خواند.
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { & $operation ([Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}
function Set-FolderAcl {
    foreach ($d in (Split-Path $root -Parent), $root, (Join-Path $root 'bin'), (Join-Path $root 'results')) {
        if (-not (Test-Path -LiteralPath $d)) { [void](New-Item -ItemType Directory -Path $d) }
    }
    $inherit = [Security.AccessControl.InheritanceFlags]'ContainerInherit,ObjectInherit'
    $none = [Security.AccessControl.PropagationFlags]::None
    function Rule($id, $rights) { New-Object Security.AccessControl.FileSystemAccessRule($id, [Security.AccessControl.FileSystemRights]$rights, $inherit, $none, 'Allow') }
    $acl = New-Object Security.AccessControl.DirectorySecurity
    $acl.SetAccessRuleProtection($true, $false)
    $acl.AddAccessRule((Rule (New-Object Security.Principal.SecurityIdentifier('S-1-5-18')) 'FullControl'))
    $acl.AddAccessRule((Rule (New-Object Security.Principal.SecurityIdentifier('S-1-5-32-544')) 'FullControl'))
    $acl.AddAccessRule((Rule (New-Object Security.Principal.SecurityIdentifier($operatorSid)) 'Modify'))
    $acl.AddAccessRule((Rule (New-Object Security.Principal.SecurityIdentifier($writer.SID.Value)) 'ReadAndExecute'))
    [IO.Directory]::SetAccessControl($root, $acl)
    foreach ($child in 'bin', 'results') {
        $c = New-Object Security.AccessControl.DirectorySecurity
        $c.SetAccessRuleProtection($false, $false)
        if ($child -eq 'results') { $c.AddAccessRule((Rule (New-Object Security.Principal.SecurityIdentifier($writer.SID.Value)) 'Modify')) }
        [IO.Directory]::SetAccessControl((Join-Path $root $child), $c)
    }
}
# Task Scheduler حق generic را به mask نگاشت‌شده تبدیل می‌کند (GRGX -> 0x1200a9)؛ پس ACE معنایی بررسی می‌شود، نه رشتهٔ خام.
$readExecuteMask = 0x001200A9          # FILE_GENERIC_READ | FILE_GENERIC_EXECUTE
$genericReadExecute = [int64]2684354560 # 0xA0000000 = GENERIC_READ | GENERIC_EXECUTE؛ literal هگز در PS 5.1 منفی می‌شود
$forbiddenMask = 0x500D0116            # GENERIC_ALL|GENERIC_WRITE|WRITE_OWNER|WRITE_DAC|DELETE|WriteData|AppendData|WriteEA|WriteAttributes
$broadSids = 'S-1-1-0', 'S-1-5-11', 'S-1-5-32-545', 'S-1-5-4', 'S-1-5-7', 'S-1-5-2'
function Get-TaskAccess([string]$sddl) {
    $sd = New-Object Security.AccessControl.RawSecurityDescriptor($sddl)
    $allow = 0L; $deny = $false; $broad = @()
    foreach ($ace in $sd.DiscretionaryAcl) {
        if ($ace -isnot [Security.AccessControl.CommonAce]) { continue }
        $sid = $ace.SecurityIdentifier.Value; $mask = ([int64]$ace.AccessMask) -band [int64]4294967295   # AccessMask از نوع Int32 است و برای حق generic منفی می‌شود
        if ($sid -eq $operatorSid) {
            if ($ace.AceQualifier -eq 'AccessAllowed') { $allow = $allow -bor $mask } else { $deny = $true }
        }
        if ($sid -in $broadSids -and $ace.AceQualifier -eq 'AccessAllowed') { $broad += $sid }
    }
    [pscustomobject]@{
        OperatorMask = ('0x{0:x}' -f $allow)
        CanReadRun   = (-not $deny) -and ((($allow -band $readExecuteMask) -eq $readExecuteMask) -or (($allow -band $genericReadExecute) -eq $genericReadExecute))
        OverGranted  = ($allow -band $forbiddenMask) -ne 0
        BroadSids    = $broad
    }
}
function Grant-OperatorRun {
    $svc = New-Object -ComObject Schedule.Service; $svc.Connect()
    $task = $svc.GetFolder('\').GetTask($taskName)
    $sddl = $task.GetSecurityDescriptor(4)
    if (-not (Get-TaskAccess $sddl).CanReadRun) { $task.SetSecurityDescriptor($sddl + "(A;;GRGX;;;$operatorSid)", 0) }
}
function Test-Provisioning {
    $problems = New-Object System.Collections.Generic.List[string]
    $operatorMask = ''
    $t = Get-ScheduledTask -TaskName $taskName -TaskPath '\' -ErrorAction SilentlyContinue
    if (-not $t) { $problems.Add('task وجود ندارد.') }
    else {
        $principalSid = try { (New-Object Security.Principal.NTAccount($t.Principal.UserId)).Translate([Security.Principal.SecurityIdentifier]).Value } catch { '' }
        if ($principalSid -ne $writer.SID.Value) { $problems.Add("هویت task برابر SID Writer نیست: $($t.Principal.UserId)") }
        if ("$($t.Principal.LogonType)" -ne 'Password') { $problems.Add("LogonType: $($t.Principal.LogonType)") }
        if ("$($t.Principal.RunLevel)" -ne 'Limited') { $problems.Add("RunLevel: $($t.Principal.RunLevel)") }
        if (@($t.Triggers | Where-Object { $_ }).Count -ne 0) { $problems.Add('task نباید trigger داشته باشد.') }
        $a = @($t.Actions)
        if ($a.Count -ne 1 -or $a[0].Execute -notmatch 'powershell\.exe$' -or $a[0].Arguments -notlike "*-File `"$runner`"*") { $problems.Add('action task برابر runner ثابت نیست.') }
        $svc = New-Object -ComObject Schedule.Service; $svc.Connect()
        $access = Get-TaskAccess ($svc.GetFolder('\').GetTask($taskName).GetSecurityDescriptor(4))
        if (-not $access.CanReadRun) { $problems.Add("اپراتور حق خواندن/اجرای task را ندارد (mask=$($access.OperatorMask)).") }
        if ($access.OverGranted) { $problems.Add("اپراتور حق بیش از خواندن/اجرا دارد (mask=$($access.OperatorMask)).") }
        if (@($access.BroadSids).Count) { $problems.Add('ACE عمومی روی task: ' + ($access.BroadSids -join ',')) }
        $operatorMask = $access.OperatorMask
    }
    if (Test-Path -LiteralPath $root) {
        $writerSid = $writer.SID.Value
        foreach ($d in $root, (Join-Path $root 'bin')) {
            $bad = @((Get-Acl -LiteralPath $d).Access | Where-Object { $_.IdentityReference.Translate([Security.Principal.SecurityIdentifier]).Value -eq $writerSid -and ($_.FileSystemRights -band [Security.AccessControl.FileSystemRights]'Write,Delete,ChangePermissions,TakeOwnership') })
            if ($bad.Count) { $problems.Add("Writer روی $d حق نوشتن دارد.") }
            if ((Get-Acl -LiteralPath $d).Access | Where-Object { $_.IdentityReference.Value -in 'Everyone', 'BUILTIN\Users', 'NT AUTHORITY\Authenticated Users' }) { $problems.Add("ACL عمومی روی $d.") }
        }
    } else { $problems.Add('پوشهٔ ConnectedTests وجود ندارد.') }
    [pscustomobject]@{ Task = $taskName; WriterAccount = $writerAccount; Operator = $OperatorAccount; OperatorTaskMask = $operatorMask; Root = $root; Problems = @($problems); Pass = ($problems.Count -eq 0) }
}

if ($VerifyOnly) {
    $v = Test-Provisioning; $v | Format-List
    if ($v.Pass) { Write-Host 'راستی‌آزمایی P4: PASS' } else { Write-Host 'راستی‌آزمایی P4: FAIL'; exit 1 }
    return
}
$existing = Get-ScheduledTask -TaskName $taskName -TaskPath '\' -ErrorAction SilentlyContinue
if ($Remove) {
    Write-Host "حذف task $taskName (پوشه و نتایج حفظ می‌شوند)."
    if (-not $Execute) { Write-Host 'اجرای آزمایشی: هیچ تغییری انجام نشد.'; return }
    if ($existing) { Unregister-ScheduledTask -TaskName $taskName -TaskPath '\' -Confirm:$false }
    return
}
if ($Rotate) {
    if (-not $existing) { throw 'task برای چرخش رمز وجود ندارد.' }
    if (-not $Execute) { Write-Host 'اجرای آزمایشی چرخش: هیچ تغییری انجام نشد.'; return }
    $secret = New-Secret
    Set-LocalUser -Name $writerName -Password $secret
    Invoke-WithPlain $secret { param($p) [void](Set-ScheduledTask -TaskName $taskName -TaskPath '\' -User $writerAccount -Password $p) }
    $secret.Dispose()
    Write-Host 'رمز Writer چرخانده و در task به‌روز شد (نمایش داده نمی‌شود).'
    return
}
[pscustomobject]@{ Task = $taskName; WriterAccount = $writerAccount; Operator = "$OperatorAccount ($operatorSid)"; Root = $root; TaskExists = [bool]$existing } | Format-List
if ($existing) { throw 'task از قبل وجود دارد؛ برای تغییر رمز -Rotate و برای بازسازی ابتدا -Remove.' }
if (-not $Execute) { Write-Host 'اجرای آزمایشی: هیچ تغییری انجام نشد. پیش‌شرط‌ها برقرارند.'; return }

Set-FolderAcl
$secret = New-Secret
Set-LocalUser -Name $writerName -Password $secret
$action = New-ScheduledTaskAction -Execute "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$runner`"" -WorkingDirectory (Join-Path $root 'bin')
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 30) -MultipleInstances IgnoreNew -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
try {
    Invoke-WithPlain $secret { param($p) [void](Register-ScheduledTask -TaskName $taskName -TaskPath '\' -Action $action -Settings $settings -User $writerAccount -Password $p -RunLevel Limited -Description "BAZDID-DEV $ApprovalReference connected SQL tests (on demand)") }
    Grant-OperatorRun
} catch {
    if (Get-ScheduledTask -TaskName $taskName -TaskPath '\' -ErrorAction SilentlyContinue) { Unregister-ScheduledTask -TaskName $taskName -TaskPath '\' -Confirm:$false }
    throw
} finally { $secret.Dispose() }
$v = Test-Provisioning; $v | Format-List
if ($v.Pass) { Write-Host 'P4 provisioning: PASS' } else { Write-Host 'P4 provisioning: FAIL'; exit 1 }
