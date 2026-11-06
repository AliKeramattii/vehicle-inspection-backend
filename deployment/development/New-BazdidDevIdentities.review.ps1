#Requires -Version 5.1
<#
پیش‌نویس بازبینی P1 برای Checkpoint 2F (بازنگری 2026-11-07) — عامل آن را اجرا نکرده است.
هدف: دو حساب Windows محلی و کم‌اختیار BAZDIDDevWriter و BAZDIDDevReader برای اجرای
آزمون‌های SQL متصل Development به‌صورت task غیرتعاملی (batch).

حالت‌ها (همه فقط در PowerShell elevated):
- بدون سوئیچ: اجرای آزمایشی ساخت؛ فقط پیش‌شرط‌ها و برنامه را چاپ می‌کند.
- -Execute: ساخت حساب‌ها، اعطای دقیق حق‌های LSA و راستی‌آزمایی. شکست در هر گام فقط حساب‌ها و
  حق‌هایی را برمی‌گرداند که همین اجرا ساخته است؛ هیچ حساب موجودی تغییر یا reset نمی‌شود.
- -VerifyOnly: فقط خواندن و مقایسهٔ وضعیت با انتظار؛ در عدم تطابق خطا می‌دهد.
- -RemoveForRecovery: برنامهٔ حذف؛ با -Execute -SqlLoginsAbsent فقط حساب‌های دارای نشانهٔ BAZDID را حذف می‌کند.

حق‌های LSA هر حساب، دقیقاً:
- SeBatchLogonRight: اجرای task با «Run whether user is logged on or not»؛
- SeDenyInteractiveLogonRight، SeDenyRemoteInteractiveLogonRight، SeDenyServiceLogonRight.
SeDenyNetworkLogonRight عمداً داده نمی‌شود: احراز Windows در SQL Server (SSPI، حتی روی Shared Memory)
یک network logon در سمت سرور است و این deny اتصال آزمون را می‌شکند.

رمز: ۲۴۰ بیت تصادفی، فقط در SecureString درون حافظه، هرگز نمایش/ثبت/ذخیره نمی‌شود. پس از ساخت، رمز
برای هیچ‌کس معلوم نیست و حساب تا گام provisioning قابل استفاده نیست. provisioning و چرخش رمز در P4 با
یک رمز تازهٔ درون‌حافظه انجام می‌شوند که هم‌زمان روی حساب و task ثبت می‌شود (سند پذیرش، بخش P1).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ExpectedMachine,
    [Parameter(Mandatory = $true)][ValidatePattern('^[A-Za-z0-9._-]{1,32}$')][string]$ApprovalReference,
    [switch]$Execute,
    [switch]$VerifyOnly,
    [switch]$RemoveForRecovery,
    [switch]$SqlLoginsAbsent
)
$ErrorActionPreference = 'Stop'
$names = @('BAZDIDDevWriter', 'BAZDIDDevReader')
$marker = 'BAZDID-DEV-SQL'
$description = "$marker $ApprovalReference"
$grantRights = @('SeBatchLogonRight')
$denyRights = @('SeDenyInteractiveLogonRight', 'SeDenyRemoteInteractiveLogonRight', 'SeDenyServiceLogonRight')
$expectedRights = @($grantRights + $denyRights | Sort-Object)

if ($description.Length -gt 48) { throw 'توضیح حساب از سقف ۴۸ نویسهٔ New-LocalUser بلندتر است.' }
if ($VerifyOnly -and ($Execute -or $RemoveForRecovery)) { throw '-VerifyOnly با -Execute یا -RemoveForRecovery ترکیب نمی‌شود.' }
if ($SqlLoginsAbsent -and -not $RemoveForRecovery) { throw '-SqlLoginsAbsent فقط با -RemoveForRecovery معنا دارد.' }

$principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'این script فقط در PowerShell elevated اجرا می‌شود.' }
if ($env:COMPUTERNAME -ne $ExpectedMachine) { throw 'نام ماشین با مقدار تصویب‌شده برابر نیست.' }

if (-not ('BazdidLsaRights' -as [type])) {
    Add-Type -Language CSharp -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Security.Principal;

public static class BazdidLsaRights
{
    [StructLayout(LayoutKind.Sequential)]
    private struct LsaUnicodeString { public ushort Length; public ushort MaximumLength; public IntPtr Buffer; }

    [StructLayout(LayoutKind.Sequential)]
    private struct LsaObjectAttributes { public int Length; public IntPtr RootDirectory; public IntPtr ObjectName; public uint Attributes; public IntPtr SecurityDescriptor; public IntPtr SecurityQualityOfService; }

    [DllImport("advapi32.dll")] private static extern uint LsaOpenPolicy(IntPtr systemName, ref LsaObjectAttributes attributes, uint access, out IntPtr handle);
    [DllImport("advapi32.dll")] private static extern uint LsaAddAccountRights(IntPtr handle, byte[] sid, LsaUnicodeString[] rights, uint count);
    [DllImport("advapi32.dll")] private static extern uint LsaRemoveAccountRights(IntPtr handle, byte[] sid, [MarshalAs(UnmanagedType.U1)] bool allRights, LsaUnicodeString[] rights, uint count);
    [DllImport("advapi32.dll")] private static extern uint LsaEnumerateAccountRights(IntPtr handle, byte[] sid, out IntPtr rights, out uint count);
    [DllImport("advapi32.dll")] private static extern uint LsaFreeMemory(IntPtr buffer);
    [DllImport("advapi32.dll")] private static extern uint LsaClose(IntPtr handle);
    [DllImport("advapi32.dll")] private static extern int LsaNtStatusToWinError(uint status);

    private const uint PolicyLookupNames = 0x00000800;
    private const uint PolicyCreateAccount = 0x00000010;
    private const uint StatusObjectNameNotFound = 0xC0000034;

    private static IntPtr Open(uint access)
    {
        LsaObjectAttributes attributes = new LsaObjectAttributes();
        attributes.Length = Marshal.SizeOf(typeof(LsaObjectAttributes));
        IntPtr handle;
        uint status = LsaOpenPolicy(IntPtr.Zero, ref attributes, access, out handle);
        if (status != 0) throw new Win32Exception(LsaNtStatusToWinError(status));
        return handle;
    }

    private static byte[] SidBytes(string sid)
    {
        SecurityIdentifier identifier = new SecurityIdentifier(sid);
        byte[] bytes = new byte[identifier.BinaryLength];
        identifier.GetBinaryForm(bytes, 0);
        return bytes;
    }

    public static string[] Get(string sid)
    {
        IntPtr handle = Open(PolicyLookupNames);
        try
        {
            IntPtr buffer;
            uint count;
            uint status = LsaEnumerateAccountRights(handle, SidBytes(sid), out buffer, out count);
            if (status == StatusObjectNameNotFound) return new string[0];
            if (status != 0) throw new Win32Exception(LsaNtStatusToWinError(status));
            try
            {
                string[] result = new string[count];
                int size = Marshal.SizeOf(typeof(LsaUnicodeString));
                for (int i = 0; i < count; i++)
                {
                    LsaUnicodeString item = (LsaUnicodeString)Marshal.PtrToStructure(new IntPtr(buffer.ToInt64() + (long)i * size), typeof(LsaUnicodeString));
                    result[i] = Marshal.PtrToStringUni(item.Buffer, item.Length / 2);
                }
                return result;
            }
            finally { LsaFreeMemory(buffer); }
        }
        finally { LsaClose(handle); }
    }

    public static void Add(string sid, string right) { Change(sid, right, true); }
    public static void Remove(string sid, string right) { Change(sid, right, false); }

    private static void Change(string sid, string right, bool add)
    {
        IntPtr handle = Open(PolicyLookupNames | PolicyCreateAccount);
        IntPtr text = Marshal.StringToHGlobalUni(right);
        try
        {
            LsaUnicodeString[] rights = new LsaUnicodeString[1];
            rights[0].Buffer = text;
            rights[0].Length = (ushort)(right.Length * 2);
            rights[0].MaximumLength = (ushort)(right.Length * 2 + 2);
            uint status = add
                ? LsaAddAccountRights(handle, SidBytes(sid), rights, 1)
                : LsaRemoveAccountRights(handle, SidBytes(sid), false, rights, 1);
            if (status != 0 && !(!add && status == StatusObjectNameNotFound)) throw new Win32Exception(LsaNtStatusToWinError(status));
        }
        finally
        {
            Marshal.FreeHGlobal(text);
            LsaClose(handle);
        }
    }
}
'@
}

function New-BazdidRandomSecret {
    # ۴۰ نویسه از الفبای ۶۴تایی (بدون سوگیری، ۲۴۰ بیت) مستقیم در SecureString؛ هیچ string میانی ساخته نمی‌شود.
    $alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_'.ToCharArray()
    $bytes = New-Object byte[] 40
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
    $secure = New-Object Security.SecureString
    foreach ($b in $bytes) { $secure.AppendChar($alphabet[$b % 64]) }
    foreach ($c in 'aA1!'.ToCharArray()) { $secure.AppendChar($c) }
    [Array]::Clear($bytes, 0, $bytes.Length)
    $secure.MakeReadOnly()
    return $secure
}

function Get-BazdidDirectGroups([string]$Name) {
    # عضویت مستقیم از دید خود حساب؛ شکست خواندن، خطا است و هرگز «عضو نیست» تعبیر نمی‌شود.
    $user = [ADSI]"WinNT://$env:COMPUTERNAME/$Name,user"
    @($user.psbase.Invoke('Groups') | ForEach-Object { $_.GetType().InvokeMember('Name', 'GetProperty', $null, $_, $null) })
}

function Get-BazdidAccountReport([string]$Name) {
    $user = Get-LocalUser -Name $Name -ErrorAction SilentlyContinue
    if ($null -eq $user) { return [pscustomobject]@{ Account = $Name; Exists = $false; Pass = $false; Problems = 'حساب وجود ندارد' } }
    $sid = $user.SID.Value
    $groups = @(Get-BazdidDirectGroups $Name)
    $rights = @([BazdidLsaRights]::Get($sid) | Sort-Object)
    $problems = New-Object System.Collections.Generic.List[string]
    if (-not $user.Enabled) { $problems.Add('حساب غیرفعال است') }
    if (-not "$($user.Description)".StartsWith($marker)) { $problems.Add('نشانهٔ BAZDID در توضیح حساب نیست') }
    if ($null -ne $user.PasswordExpires) { $problems.Add('رمز تاریخ انقضا دارد') }
    if ($user.UserMayChangePassword) { $problems.Add('کاربر می‌تواند رمز را تغییر دهد') }
    if ($groups.Count -ne 0) { $problems.Add("عضویت گروه غیرمنتظره: $($groups -join ', ')") }
    if (($rights -join ',') -ne ($expectedRights -join ',')) { $problems.Add("حق‌های LSA برابر انتظار نیست: $($rights -join ', ')") }
    [pscustomobject]@{
        Account = "$env:COMPUTERNAME\$Name"; Exists = $true; Sid = $sid; Enabled = $user.Enabled
        DirectGroups = ($groups -join ', '); LsaRights = ($rights -join ', ')
        Pass = ($problems.Count -eq 0); Problems = ($problems -join '؛ ')
    }
}

function Get-BazdidTasksFor([string]$Name) {
    @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { "$($_.Principal.UserId)" -match "(^|\\)$Name$" })
}

# پیش‌شرط‌های مشترک: SeNetworkLogonRight برای SSPI در SQL لازم است و DisableDomainCreds ثبت task با رمز را می‌بندد.
$networkHolders = @('S-1-1-0', 'S-1-5-32-545', 'S-1-5-11') | Where-Object { [BazdidLsaRights]::Get($_) -contains 'SeNetworkLogonRight' }
$disableDomainCreds = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name DisableDomainCreds -ErrorAction SilentlyContinue).DisableDomainCreds
$environment = [pscustomobject]@{
    Machine = $env:COMPUTERNAME; Accounts = ($names -join ', '); Description = $description
    PlannedLsaRights = ($expectedRights -join ', ')
    NetworkLogonViaGroup = (@($networkHolders).Count -gt 0)
    StoredTaskPasswordAllowed = ($disableDomainCreds -ne 1)
}
$environment | Format-List
if (-not $environment.NetworkLogonViaGroup) { Write-Warning 'هیچ‌کدام از Everyone، Users یا Authenticated Users حق SeNetworkLogonRight ندارند؛ احراز Windows در SQL شکست می‌خورد. پیش از P2 بررسی شود.' }
if (-not $environment.StoredTaskPasswordAllowed) { Write-Warning 'DisableDomainCreds=1 است؛ ثبت task با رمز ذخیره‌شده در P4 ممکن نیست. این script آن را تغییر نمی‌دهد.' }

if ($VerifyOnly) {
    $reports = @($names | ForEach-Object { Get-BazdidAccountReport $_ })
    $reports | Format-List
    if (@($reports | Where-Object { -not $_.Pass }).Count -gt 0) { throw 'راستی‌آزمایی P1 ناموفق است.' }
    Write-Output 'راستی‌آزمایی P1: PASS'
    return
}

if ($RemoveForRecovery) {
    $targets = @($names | ForEach-Object { Get-LocalUser -Name $_ -ErrorAction SilentlyContinue } | Where-Object { $_ })
    foreach ($user in $targets) {
        if (-not "$($user.Description)".StartsWith($marker)) { throw "حساب $($user.Name) نشانهٔ BAZDID ندارد؛ این script آن را حذف نمی‌کند." }
        $tasks = Get-BazdidTasksFor $user.Name
        if ($tasks.Count -gt 0) { throw "برای $($user.Name) task ثبت‌شده وجود دارد ($(($tasks | ForEach-Object TaskName) -join ', '))؛ ابتدا آن‌ها را بازبینی و حذف کنید." }
    }
    $targets | ForEach-Object { [pscustomobject]@{ RemoveAccount = $_.Name; Sid = $_.SID.Value } } | Format-List
    if ($targets.Count -eq 0) { Write-Output 'هیچ حساب BAZDID برای حذف وجود ندارد.'; return }
    if (-not $Execute) { Write-Output 'اجرای آزمایشی حذف: هیچ تغییری انجام نشد.'; return }
    if (-not $SqlLoginsAbsent) { throw 'پیش از حذف حساب، login/user SQL همین SIDها باید حذف شده یا هرگز ساخته نشده باشند؛ پس از احراز، -SqlLoginsAbsent را بدهید.' }
    foreach ($user in $targets) {
        $sid = $user.SID.Value
        foreach ($right in $expectedRights) { [BazdidLsaRights]::Remove($sid, $right) }
        Remove-LocalUser -SID $user.SID
        Get-CimInstance Win32_UserProfile -Filter "SID='$sid'" | Where-Object { -not $_.Loaded } | Remove-CimInstance
        Write-Output "حذف شد: $($user.Name) ($sid)"
    }
    return
}

foreach ($name in $names) {
    if (Get-LocalUser -Name $name -ErrorAction SilentlyContinue) { throw "حساب $name از قبل وجود دارد؛ این script آن را تغییر یا reset نمی‌کند. وضعیت را با -VerifyOnly یا -RemoveForRecovery بررسی کنید." }
    if (Get-LocalGroup -Name $name -ErrorAction SilentlyContinue) { throw "گروه محلی هم‌نام $name وجود دارد." }
}
if (-not $Execute) { Write-Output 'اجرای آزمایشی: هیچ حسابی ساخته نشد.'; return }

$created = New-Object System.Collections.Generic.List[object]
try {
    foreach ($name in $names) {
        $secret = New-BazdidRandomSecret
        try {
            $user = New-LocalUser -Name $name -Password $secret -Description $description `
                -PasswordNeverExpires -UserMayNotChangePassword -AccountNeverExpires
        } finally { $secret.Dispose() }
        $created.Add($user)
    }
    foreach ($user in $created) {
        foreach ($right in $expectedRights) { [BazdidLsaRights]::Add($user.SID.Value, $right) }
    }
    $reports = @($names | ForEach-Object { Get-BazdidAccountReport $_ })
    $failed = @($reports | Where-Object { -not $_.Pass })
    if ($failed.Count -gt 0) { throw "راستی‌آزمایی پس از ساخت ناموفق: $(($failed | ForEach-Object { "$($_.Account): $($_.Problems)" }) -join ' | ')" }
} catch {
    $failure = $_
    Write-Warning 'شکست P1؛ فقط حساب‌ها و حق‌هایی که همین اجرا ساخته بود برگردانده می‌شوند.'
    for ($i = $created.Count - 1; $i -ge 0; $i--) {
        $user = $created[$i]
        try {
            foreach ($right in $expectedRights) { [BazdidLsaRights]::Remove($user.SID.Value, $right) }
            Remove-LocalUser -SID $user.SID
            Write-Warning "برگردانده شد: $($user.Name)"
        } catch {
            Write-Warning "بازگشت $($user.Name) ناموفق بود؛ با -RemoveForRecovery ادامه دهید: $($_.Exception.Message)"
        }
    }
    throw $failure
}
$reports | Format-List
Write-Output 'P1: PASS — رمز حساب‌ها برای هیچ‌کس معلوم نیست؛ provisioning فقط در P4 با چرخش رمز انجام می‌شود.'
