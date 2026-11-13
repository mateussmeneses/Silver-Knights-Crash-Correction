# T-08b part 3: identify WHICH files the leaking File handles refer to.
#
# run-57 resolved the leaking object type: type index 42 == "File", and the process held 79 of
# them 2.5 minutes after launch, growing at ~+20/min. But the object names came back empty,
# because NtQueryObject(ObjectNameInformation) blocks or fails for handles opened for
# synchronous I/O - which is exactly how most files are opened.
#
# The reliable way to learn which files are open is not to query the object name, but to
# enumerate the process's open files from the outside. Restart Manager (rstrtmgr.dll) does this
# for a given pid and returns full paths. That answers the question that matters:
#
#   is this a small set of files reopened in a loop (a leak with an obvious fix),
#   or hundreds of distinct files (a different problem entirely)?
#
# Read-only. Emits counts per path.
param(
    [string]$WorkDir = "C:\Users\Mateus\AppData\Local\hermes\cache\scratch\sk-sandbox5",
    [int]$FirstSampleSec = 60,
    [int]$SecondSampleSec = 300
)
$ErrorActionPreference = 'Stop'

# Restart Manager cannot list another process's open files directly, so use the handle table
# plus a name query with the async-friendly flag. NtQueryObject on File handles can hang, so run
# each query on a short-timeout worker and accept blanks.
Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Collections.Generic;
using System.Threading;
using System.Runtime.InteropServices;

public class FileNameProbe {
    [StructLayout(LayoutKind.Sequential)]
    public struct ENTRY64 {
        public IntPtr Object; public IntPtr UniqueProcessId; public IntPtr HandleValue;
        public uint GrantedAccess; public ushort CreatorBackTraceIndex; public ushort ObjectTypeIndex;
        public uint HandleAttributes; public uint Reserved;
    }
    [StructLayout(LayoutKind.Sequential)]
    public struct ENTRY32 {
        public IntPtr Object; public IntPtr UniqueProcessId; public IntPtr HandleValue;
        public uint GrantedAccess; public ushort CreatorBackTraceIndex; public ushort ObjectTypeIndex;
        public uint HandleAttributes;
    }
    [StructLayout(LayoutKind.Sequential)]
    public struct UNICODE_STRING { public ushort Length; public ushort MaximumLength; public IntPtr Buffer; }

    [DllImport("ntdll.dll")] static extern int NtQuerySystemInformation(int cls, IntPtr info, int len, out int retLen);
    [DllImport("ntdll.dll")] static extern int NtQueryObject(IntPtr h, int cls, IntPtr info, int len, out int retLen);
    [DllImport("kernel32.dll", SetLastError=true)] static extern IntPtr OpenProcess(uint access, bool inherit, int pid);
    [DllImport("kernel32.dll", SetLastError=true)] static extern bool DuplicateHandle(IntPtr sp, IntPtr sh, IntPtr dp, out IntPtr dh, uint access, bool inherit, uint opts);
    [DllImport("kernel32.dll")] static extern IntPtr GetCurrentProcess();
    [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr h);

    const int SystemExtendedHandleInformation = 64;
    const int ObjectTypeInformation = 2;
    const int ObjectNameInformation = 1;

    static string Query(IntPtr h, int cls, int len) {
        IntPtr b = Marshal.AllocHGlobal(len);
        try {
            int need = 0;
            int st = NtQueryObject(h, cls, b, len, out need);
            if (st != 0) return null;
            UNICODE_STRING us = (UNICODE_STRING)Marshal.PtrToStructure(b, typeof(UNICODE_STRING));
            if (us.Buffer == IntPtr.Zero || us.Length == 0) return "";
            return Marshal.PtrToStringUni(us.Buffer, us.Length / 2);
        } catch { return null; } finally { Marshal.FreeHGlobal(b); }
    }

    // Query with a hard timeout, because NtQueryObject can block forever on some handles.
    static string QueryWithTimeout(IntPtr h, int cls, int ms) {
        string res = null;
        Thread t = new Thread(new ThreadStart(delegate { res = Query(h, cls, 2048); }));
        t.IsBackground = true;
        t.Start();
        if (!t.Join(ms)) { return "(timeout)"; }
        return res;
    }

    public static List<string> FileNames(int pid) {
        List<string> names = new List<string>();
        int len = 1 << 22;
        IntPtr buf = IntPtr.Zero;
        int status = -1, needed = 0;
        for (int a = 0; a < 8; a++) {
            buf = Marshal.AllocHGlobal(len);
            status = NtQuerySystemInformation(SystemExtendedHandleInformation, buf, len, out needed);
            if (status == 0) break;
            Marshal.FreeHGlobal(buf); buf = IntPtr.Zero;
            int nxt = needed + (1 << 16); if (nxt <= len) nxt = len * 2; len = nxt;
        }
        if (buf == IntPtr.Zero) return names;

        IntPtr proc = OpenProcess(0x0040, false, pid);
        if (proc == IntPtr.Zero) { Marshal.FreeHGlobal(buf); return names; }
        try {
            long count = (IntPtr.Size == 8) ? (long)Marshal.ReadInt64(buf) : (long)Marshal.ReadInt32(buf);
            int stride = (IntPtr.Size == 8) ? Marshal.SizeOf(typeof(ENTRY64)) : Marshal.SizeOf(typeof(ENTRY32));
            long baseOff = (IntPtr.Size == 8) ? 16L : 8L;
            for (long i = 0; i < count; i++) {
                long off = baseOff + i * stride;
                int tIdx; IntPtr hVal; bool mine;
                if (IntPtr.Size == 8) {
                    ENTRY64 e = (ENTRY64)Marshal.PtrToStructure(new IntPtr(buf.ToInt64() + off), typeof(ENTRY64));
                    mine = (int)e.UniqueProcessId.ToInt64() == pid; tIdx = e.ObjectTypeIndex; hVal = e.HandleValue;
                } else {
                    ENTRY32 e = (ENTRY32)Marshal.PtrToStructure(new IntPtr(buf.ToInt64() + off), typeof(ENTRY32));
                    mine = e.UniqueProcessId.ToInt32() == pid; tIdx = e.ObjectTypeIndex; hVal = e.HandleValue;
                }
                if (!mine || tIdx != 42) continue;
                IntPtr dup;
                if (!DuplicateHandle(proc, hVal, GetCurrentProcess(), out dup, 0, false, 0x2)) continue;
                try {
                    string tp = QueryWithTimeout(dup, ObjectTypeInformation, 250);
                    if (tp != "File") continue;   // only real files, not event/section aliases
                    string nm = QueryWithTimeout(dup, ObjectNameInformation, 250);
                    if (!string.IsNullOrEmpty(nm)) names.Add(nm);
                } finally { CloseHandle(dup); }
            }
        } finally { CloseHandle(proc); Marshal.FreeHGlobal(buf); }
        return names;
    }
}
'@
if(-not ("FileNameProbe" -as [type])){ Write-Host "FATAL: FileNameProbe failed"; exit 1 }
Write-Host "probes compiled OK"

Add-Type -TypeDefinition @'
using System; using System.Text; using System.Runtime.InteropServices;
public class Wn2 {
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
function Get-Wins([int]$procId){ $r=New-Object System.Collections.ArrayList
  [Wn2]::EnumWindows({param($h,$z) $o=0;[void][Wn2]::GetWindowThreadProcessId($h,[ref]$o)
    if($o -eq $procId){[void]$r.Add([pscustomobject]@{H=$h;Cls=[Wn2]::C($h);Text=[Wn2]::T($h)})}
    return $true},[IntPtr]::Zero)|Out-Null; return $r }
function Get-Kids([IntPtr]$h){ $r=New-Object System.Collections.ArrayList
  [Wn2]::EnumChildWindows($h,{param($c,$z) [void]$r.Add([pscustomobject]@{H=$c;Cls=[Wn2]::C($c);Text=[Wn2]::T($c)}); return $true},[IntPtr]::Zero)|Out-Null; return $r }

$psi=New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName=Join-Path $WorkDir 'SK-Startup.exe'; $psi.WorkingDirectory=$WorkDir; $psi.UseShellExecute=$false
$sp=New-Object System.Diagnostics.Process; $sp.StartInfo=$psi
$script:SKStartedAt=(Get-Date).AddSeconds(-5)
[void]$sp.Start()
Write-Host "launched - dismissing dialogs"
$t0=Get-Date; $clicked=$false
while(((Get-Date)-$t0).TotalSeconds -lt 45){
  Start-Sleep -Milliseconds 400
  foreach($w in (Get-Wins $sp.Id)){
    if($w.Text -eq 'Error Massage'){
      $ok=(Get-Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'OK'}|Select-Object -First 1
      if($ok){[void][Wn2]::SendMessageW($ok.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); Start-Sleep -Milliseconds 250}
    } elseif($w.Text -like 'SK Startup*' -and -not $clicked){
      $b=(Get-Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'Window'}|Select-Object -First 1
      if($b){[void][Wn2]::SendMessageW($b.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); $clicked=$true; Start-Sleep -Milliseconds 400}
    }
  }
  $mm=Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
  if($mm -and ((Get-Date)-$t0).TotalSeconds -gt 20){ break }
}
$m=Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue|Select-Object -First 1
if(-not $m){ Write-Host "FATAL: SK-Main not running"; exit 1 }
$gamePid=$m.Id
Write-Host ("game pid={0}  - sampling open files twice" -f $gamePid)

function SampleFiles($label){
    $names = @([FileNameProbe]::FileNames([int]$gamePid))
    Write-Host ""
    Write-Host ("=== {0}: {1} named File handle(s) ===" -f $label, $names.Count)
    $g = $names | Group-Object | Sort-Object -Property Count -Descending
    $g | Select-Object -First 15 | ForEach-Object { Write-Host ("    x{0,-4} {1}" -f $_.Count, $_.Name) }
    if($g.Count -gt 15){ Write-Host ("    ... {0} more distinct paths" -f ($g.Count - 15)) }
    Write-Host ("distinct paths: {0}" -f $g.Count)
    return ,$names
}

Start-Sleep -Seconds $FirstSampleSec
$a = SampleFiles "SAMPLE 1"
$gap = $SecondSampleSec - $FirstSampleSec
if($gap -gt 0){ Start-Sleep -Seconds $gap }
$b = SampleFiles "SAMPLE 2"

Write-Host ""
Write-Host "=== GROWTH PER PATH ==="
$ca = @{}; foreach($n in $a){ if(-not $ca.ContainsKey($n)){$ca[$n]=0}; $ca[$n]++ }
$cb = @{}; foreach($n in $b){ if(-not $cb.ContainsKey($n)){$cb[$n]=0}; $cb[$n]++ }
$all = @($ca.Keys) + @($cb.Keys) | Sort-Object -Unique
$any = $false
foreach($k in $all){
    $x = 0; if($ca.ContainsKey($k)){ $x = $ca[$k] }
    $y = 0; if($cb.ContainsKey($k)){ $y = $cb[$k] }
    if($y -ne $x){
        $any = $true
        Write-Host ("    {0,4} -> {1,4}   {2}" -f $x, $y, $k)
    }
}
if(-not $any){ Write-Host "    (no per-path growth observed between samples)" }
Write-Host ("totals: {0} -> {1} named File handles" -f $a.Count, $b.Count)

Write-Host ""
Write-Host "=== teardown ==="
$mine = @(Get-Process -Name 'SK-Main','SK-Startup' -ErrorAction SilentlyContinue |
          Where-Object { $_.Path -and $_.Path.StartsWith($WorkDir, [System.StringComparison]::OrdinalIgnoreCase) })
$mine | ForEach-Object { Write-Host ("killing {0} {1}" -f $_.ProcessName,$_.Id); try{$_.Kill()}catch{} }
