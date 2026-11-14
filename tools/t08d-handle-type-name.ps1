# T-08b part 2: resolve handle object-type INDEX to a NAME, and sample names of the leaking type.
#
# run-56 isolated the leak to one object type: the handle table went 671 -> 754 over ~4 min,
# and of that, type index 42 contributed +89 (42 -> 131) while every other type was flat, +2,
# or negative. Type INDICES are assigned per boot and are not stable identifiers, so an index
# alone is not a finding. This resolves the index to a real type name, then samples the actual
# object names of that type so the leaking object is identifiable (a file? a section? an event
# with a telltale name?).
#
# Method: NtQuerySystemInformation(SystemExtendedHandleInformation) to enumerate, then for each
# candidate handle: OpenProcess + DuplicateHandle into this process, and
# NtQueryObject(ObjectTypeInformation) to read the type name, plus
# NtQueryObject(ObjectNameInformation) to read the object name.
#
# Written to C# 5 (PS 5.1 compiles C# 5 only - inline out-declarations are a parse failure)
# and all diagnostics go to the host, never the pipeline.
param(
    [string]$WorkDir  = "C:\Users\Mateus\AppData\Local\hermes\cache\scratch\sk-sandbox5",
    [int]$TargetTypeIndex = 42,
    [int]$SettleSeconds = 150,
    [switch]$AttachToExisting
)
$ErrorActionPreference = 'Stop'

Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public class HandleNames {
    [StructLayout(LayoutKind.Sequential)]
    public struct ENTRY64 {
        public IntPtr Object;
        public IntPtr UniqueProcessId;
        public IntPtr HandleValue;
        public uint   GrantedAccess;
        public ushort CreatorBackTraceIndex;
        public ushort ObjectTypeIndex;
        public uint   HandleAttributes;
        public uint   Reserved;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct ENTRY32 {
        public IntPtr Object;
        public IntPtr UniqueProcessId;
        public IntPtr HandleValue;
        public uint   GrantedAccess;
        public ushort CreatorBackTraceIndex;
        public ushort ObjectTypeIndex;
        public uint   HandleAttributes;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct UNICODE_STRING {
        public ushort Length;
        public ushort MaximumLength;
        public IntPtr Buffer;
    }

    [DllImport("ntdll.dll")]
    static extern int NtQuerySystemInformation(int cls, IntPtr info, int len, out int retLen);
    [DllImport("ntdll.dll")]
    static extern int NtQueryObject(IntPtr handle, int cls, IntPtr info, int len, out int retLen);
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern IntPtr OpenProcess(uint access, bool inherit, int pid);
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern bool DuplicateHandle(IntPtr srcProc, IntPtr src, IntPtr dstProc,
                                       out IntPtr dst, uint access, bool inherit, uint options);
    [DllImport("kernel32.dll")]
    static extern IntPtr GetCurrentProcess();
    [DllImport("kernel32.dll")]
    static extern bool CloseHandle(IntPtr h);

    const int SystemExtendedHandleInformation = 64;
    const int ObjectTypeInformation = 2;
    const int ObjectNameInformation = 1;

    public class Hit { public int TypeIndex; public string TypeName; public string ObjectName; }

    // Returns every handle of the target type in the process, with resolved names where possible.
    public static List<Hit> Find(int pid, int wantType, int maxOut) {
        List<Hit> hits = new List<Hit>();
        int len = 1 << 22;
        IntPtr buf = IntPtr.Zero;
        int status = -1;
        int needed = 0;
        for (int attempt = 0; attempt < 8; attempt++) {
            buf = Marshal.AllocHGlobal(len);
            status = NtQuerySystemInformation(SystemExtendedHandleInformation, buf, len, out needed);
            if (status == 0) { break; }
            Marshal.FreeHGlobal(buf);
            buf = IntPtr.Zero;
            int next = needed + (1 << 16);
            if (next <= len) { next = len * 2; }
            len = next;
        }
        if (buf == IntPtr.Zero) { return hits; }

        IntPtr proc = OpenProcess(0x0040 /*PROCESS_DUP_HANDLE*/, false, pid);
        if (proc == IntPtr.Zero) { Marshal.FreeHGlobal(buf); return hits; }

        try {
            IntPtr countPtr = buf;
            // On x64 the count is an IntPtr (8 bytes) followed by padding; entries are 8-aligned.
            long count = (IntPtr.Size == 8) ? (long)Marshal.ReadInt64(countPtr)
                                            : (long)Marshal.ReadInt32(countPtr);
            int stride = (IntPtr.Size == 8) ? Marshal.SizeOf(typeof(ENTRY64))
                                            : Marshal.SizeOf(typeof(ENTRY32));
            long baseOff = (IntPtr.Size == 8) ? 16L : 8L;

            for (long i = 0; i < count; i++) {
                long off = baseOff + i * stride;
                int tIdx;
                IntPtr hVal;
                if (IntPtr.Size == 8) {
                    ENTRY64 e = (ENTRY64)Marshal.PtrToStructure(new IntPtr(buf.ToInt64() + off), typeof(ENTRY64));
                    if ((int)e.UniqueProcessId.ToInt64() != pid) { continue; }
                    tIdx = (int)e.ObjectTypeIndex;
                    hVal = e.HandleValue;
                    _pid = (int)e.UniqueProcessId.ToInt64();
                } else {
                    ENTRY32 e = (ENTRY32)Marshal.PtrToStructure(new IntPtr(buf.ToInt64() + off), typeof(ENTRY32));
                    if (e.UniqueProcessId.ToInt32() != pid) { continue; }
                    tIdx = (int)e.ObjectTypeIndex;
                    hVal = e.HandleValue;
                }
                if (tIdx != wantType) { continue; }
                if (hits.Count >= maxOut) { break; }

                Hit hit = new Hit();
                hit.TypeIndex = tIdx;
                IntPtr dup = IntPtr.Zero;
                if (DuplicateHandle(proc, hVal, GetCurrentProcess(), out dup, 0, false, 0x2 /*DUPLICATE_SAME_ACCESS*/)) {
                    try {
                        hit.TypeName = QueryTypeName(dup);
                        if (string.IsNullOrEmpty(hit.TypeName)) {
                            hit.ObjectName = "";
                        } else if (hit.TypeName != "File" && hit.TypeName != "Section") {
                            hit.ObjectName = QueryObjectName(dup);
                        }
                    } finally { CloseHandle(dup); }
                }
                hits.Add(hit);
            }
        } finally {
            CloseHandle(proc);
            Marshal.FreeHGlobal(buf);
        }
        return hits;
    }
    static int _pid;

    static string QueryTypeName(IntPtr h) {
        int len = 1024;
        IntPtr b = Marshal.AllocHGlobal(len);
        try {
            int need = 0;
            int st = NtQueryObject(h, ObjectTypeInformation, b, len, out need);
            if (st != 0) { return null; }
            UNICODE_STRING us = (UNICODE_STRING)Marshal.PtrToStructure(b, typeof(UNICODE_STRING));
            if (us.Buffer == IntPtr.Zero || us.Length == 0) { return null; }
            return Marshal.PtrToStringUni(us.Buffer, us.Length / 2);
        } catch { return null; }
        finally { Marshal.FreeHGlobal(b); }
    }

    static string QueryObjectName(IntPtr h) {
        int len = 4096;
        IntPtr b = Marshal.AllocHGlobal(len);
        try {
            int need = 0;
            int st = NtQueryObject(h, ObjectNameInformation, b, len, out need);
            if (st != 0) { return ""; }
            UNICODE_STRING us = (UNICODE_STRING)Marshal.PtrToStructure(b, typeof(UNICODE_STRING));
            if (us.Buffer == IntPtr.Zero || us.Length == 0) { return ""; }
            return Marshal.PtrToStringUni(us.Buffer, us.Length / 2);
        } catch { return ""; }
        finally { Marshal.FreeHGlobal(b); }
    }
}
'@
if(-not ("HandleNames" -as [type])){ Write-Host "FATAL: Add-Type failed"; exit 1 }
Write-Host "HandleNames compiled OK"

if($AttachToExisting){
    $m = Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue | Select-Object -First 1
    if(-not $m){ Write-Host "FATAL: no SK-Main running"; exit 1 }
    $gamePid = $m.Id
    Write-Host ("attached pid={0}" -f $gamePid)
} else {
    Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class WnProbe {
    public delegate bool EnumProc(IntPtr h, IntPtr p);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr p);
    [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr h, EnumProc cb, IntPtr p);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr SendMessageW(IntPtr h, uint m, IntPtr w, IntPtr l);
    public static string T(IntPtr h){ var s=new StringBuilder(512); GetWindowTextW(h,s,512); return s.ToString(); }
    public static string C(IntPtr h){ var s=new StringBuilder(256); GetClassNameW(h,s,256); return s.ToString(); }
}
'@
    function Get-Wins([int]$procId){
        $r = New-Object System.Collections.ArrayList
        [WnProbe]::EnumWindows({param($h,$z) $o=0;[void][WnProbe]::GetWindowThreadProcessId($h,[ref]$o)
            if($o -eq $procId){[void]$r.Add([pscustomobject]@{H=$h;Cls=[WnProbe]::C($h);Text=[WnProbe]::T($h)})}
            return $true},[IntPtr]::Zero) | Out-Null
        return $r
    }
    function Get-Kids([IntPtr]$h){
        $r = New-Object System.Collections.ArrayList
        [WnProbe]::EnumChildWindows($h,{param($c,$z) [void]$r.Add([pscustomobject]@{H=$c;Cls=[WnProbe]::C($c);Text=[WnProbe]::T($c)}); return $true},[IntPtr]::Zero) | Out-Null
        return $r
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = Join-Path $WorkDir 'SK-Startup.exe'
    $psi.WorkingDirectory = $WorkDir
    $psi.UseShellExecute = $false
    $sp = New-Object System.Diagnostics.Process
    $sp.StartInfo = $psi
    $script:SKStartedAt = (Get-Date).AddSeconds(-5)
    [void]$sp.Start()
    Write-Host "launched - dismissing launcher dialogs"

    $t0 = Get-Date
    $clicked = $false
    while(((Get-Date)-$t0).TotalSeconds -lt 45){
        Start-Sleep -Milliseconds 400
        foreach($w in (Get-Wins $sp.Id)){
            if($w.Text -eq 'Error Massage'){
                $ok = (Get-Kids $w.H) | Where-Object { $_.Cls -eq 'Button' -and $_.Text -eq 'OK' } | Select-Object -First 1
                if($ok){ [void][WnProbe]::SendMessageW($ok.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); Start-Sleep -Milliseconds 250 }
            } elseif($w.Text -like 'SK Startup*' -and -not $clicked){
                $b = (Get-Kids $w.H) | Where-Object { $_.Cls -eq 'Button' -and $_.Text -eq 'Window' } | Select-Object -First 1
                if($b){ [void][WnProbe]::SendMessageW($b.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); $clicked = $true; Start-Sleep -Milliseconds 400 }
            }
        }
        $mm = Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
        if($mm -and ((Get-Date)-$t0).TotalSeconds -gt 20){ break }
    }
    $m = Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue | Select-Object -First 1
    if(-not $m){ Write-Host "FATAL: SK-Main not running"; exit 1 }
    $gamePid = $m.Id
    Write-Host ("game pid={0}" -f $gamePid)
    Write-Host ("letting the game settle {0}s before sampling" -f $SettleSeconds)
    Start-Sleep -Seconds $SettleSeconds
}

Write-Host ""
Write-Host ("=== resolving type index {0} in pid {1} ===" -f $TargetTypeIndex, $gamePid)
$hits = [HandleNames]::Find([int]$gamePid, [int]$TargetTypeIndex, 400)
Write-Host ("handles of that type found: {0}" -f $hits.Count)

$names = @{}
$types = @{}
foreach($h in $hits){
    if($h.TypeName){ if(-not $types.ContainsKey($h.TypeName)){ $types[$h.TypeName]=0 }; $types[$h.TypeName]++ }
    $n = if($h.ObjectName){ $h.ObjectName } else { "(unnamed)" }
    if(-not $names.ContainsKey($n)){ $names[$n]=0 }
    $names[$n]++
}

Write-Host ""
Write-Host "=== type names seen for this index ==="
if($types.Count -gt 0){
    $types.GetEnumerator() | Sort-Object -Property Value -Descending | ForEach-Object { Write-Host ("    {0,-24} x{1}" -f $_.Key,$_.Value) }
} else {
    Write-Host "    (could not resolve - handles may deny duplicate access)"
}

Write-Host ""
Write-Host "=== object names of that type (top 20 by count) ==="
$names.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 20 | ForEach-Object {
    Write-Host ("    x{0,-5} {1}" -f $_.Value, $_.Key)
}

Write-Host ""
Write-Host "=== teardown ==="
# Find the game by PATH under our own WorkDir - ownership by launch time failed here because
# the launcher and SK-Main both start inside the boundary slack, and Get-Process StartTime has
# 1-second resolution. Matching the executable path is unambiguous.
$mine = @(Get-Process -Name 'SK-Main','SK-Startup' -ErrorAction SilentlyContinue |
          Where-Object { $_.Path -and $_.Path.StartsWith($WorkDir, [System.StringComparison]::OrdinalIgnoreCase) })
if($mine.Count -gt 0){
  $mine | ForEach-Object { Write-Host ("killing {0} {1}" -f $_.ProcessName,$_.Id); try{$_.Kill()}catch{} }
} else { Write-Host "nothing from this sandbox to kill" }
