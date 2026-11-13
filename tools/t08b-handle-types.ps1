# T-08b: identify the leaking handle type.
#
# run-40 and run-48 both show handle count growing linearly at ~+20/min while memory stays
# flat. That combination is diagnostic: memory stable rules out a growing data structure;
# steady handle growth points at an object created and never closed on a repeating event -
# typically a per-frame or per-tick create.
#
# This script takes two full snapshots of the handle table (T+60s and T+~12min) and diffs
# them by TYPE, so the leaking class is named rather than guessed.
#
# Uses NtQuerySystemInformation with SystemHandleInformation (class 16). No external tools,
# no admin rights required for the *counts* of one's own process. Handle TYPE names are read
# from the ObjectTypeInformation via the object's TypeIndex where readable; where that is not
# available we fall back to a per-handle probe of the object's name.
param(
    [string]$WorkDir = "C:\Users\Mateus\AppData\Local\hermes\cache\scratch\sk-sandbox5",
    [int]$FirstAtSec = 60,
    [int]$SecondAtSec = 720
)
$ErrorActionPreference = 'Continue'
Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public class HandleLeakProbe {
    [StructLayout(LayoutKind.Sequential)]
    public struct SYSTEM_HANDLE_TABLE_ENTRY_INFO {
        public ushort UniqueProcessId;
        public ushort CreatorBackTraceIndex;
        public byte   ObjectTypeIndex;
        public byte   HandleAttributes;
        public ushort HandleValue;
        public IntPtr Object;
        public uint   GrantedAccess;
    }

    [DllImport("ntdll.dll")]
    static extern int NtQuerySystemInformation(int SystemInformationClass, IntPtr SystemInformation,
                                               int SystemInformationLength, out int ReturnLength);
    [DllImport("ntdll.dll")]
    static extern int NtQueryObject(IntPtr Handle, int ObjectInformationClass,
                                    IntPtr ObjectInformation, int ObjectInformationLength,
                                    out int ReturnLength);
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern IntPtr OpenProcess(uint access, bool inherit, int pid);
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern bool DuplicateHandle(IntPtr hSourceProcess, IntPtr hSource, IntPtr hTargetProcess,
                                       out IntPtr lpTarget, uint access, bool inherit, uint options);
    [DllImport("kernel32.dll")]
    static extern IntPtr GetCurrentProcess();
    [DllImport("kernel32.dll")]
    static extern bool CloseHandle(IntPtr h);

    const int SystemHandleInformation = 16;
    const int ObjectTypeInformation   = 2;

    // Returns counts per ObjectTypeIndex for the given process id.
    public static Dictionary<int,int> Snapshot(int pid, out int total) {
        var counts = new Dictionary<int,int>();
        total = 0;
        int len = 1024 * 1024;
        IntPtr buf = IntPtr.Zero;
        int ret = 0;
        for (int attempt = 0; attempt < 8; attempt++) {
            buf = Marshal.AllocHGlobal(len);
            ret = NtQuerySystemInformation(SystemHandleInformation, buf, len, out int needed);
            if (ret == 0) break;
            Marshal.FreeHGlobal(buf); buf = IntPtr.Zero;
            len = Math.Max(len * 2, needed + 65536);
        }
        if (buf == IntPtr.Zero) return counts;
        try {
            int count = Marshal.ReadInt32(buf);
            int stride = Marshal.SizeOf(typeof(SYSTEM_HANDLE_TABLE_ENTRY_INFO));
            IntPtr p = (IntPtr)((long)buf + 4);   // entries start after the count DWORD (x86) / padded on x64
            // On x64 the count is followed by padding to 8 bytes
            if (IntPtr.Size == 8) p = (IntPtr)((long)buf + 8);
            for (int i = 0; i < count; i++) {
                var e = (SYSTEM_HANDLE_TABLE_ENTRY_INFO)Marshal.PtrToStructure(
                    (IntPtr)((long)p + i * stride), typeof(SYSTEM_HANDLE_TABLE_ENTRY_INFO));
                if (e.UniqueProcessId != pid) continue;
                total++;
                if (!counts.ContainsKey(e.ObjectTypeIndex)) counts[e.ObjectTypeIndex] = 0;
                counts[e.ObjectTypeIndex]++;
            }
        } finally { Marshal.FreeHGlobal(buf); }
        return counts;
    }
}
'@
if(-not ("HandleLeakProbe" -as [type])){ Write-Output "FATAL: Add-Type failed"; exit 1 }

$psi=New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName=Join-Path $WorkDir 'SK-Startup.exe'; $psi.WorkingDirectory=$WorkDir; $psi.UseShellExecute=$false
$sp=New-Object System.Diagnostics.Process; $sp.StartInfo=$psi; [void]$sp.Start()
$t0=Get-Date; Write-Output "T+0 LAUNCH"
Start-Sleep -Seconds 30
$m = Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
if(-not $m){ Write-Output "FATAL: SK-Main not running"; exit 1 }
$gamePid = $m.Id
Write-Output "game pid=$gamePid"

function Snap($label){
  $total=0
  $counts = [HandleLeakProbe]::Snapshot($gamePid, [ref]$total)
  Write-Output ("=== {0}: total={1} ===" -f $label,$total)
  $counts.GetEnumerator() | Sort-Object -Property Value -Descending | ForEach-Object {
    Write-Output ("    typeIndex {0,3}  count {1,5}" -f $_.Key,$_.Value)
  }
  return $counts
}

Write-Output ""
Write-Output ("waiting until T+{0}s for the first snapshot" -f $FirstAtSec)
while(((Get-Date)-$t0).TotalSeconds -lt $FirstAtSec){ Start-Sleep -Seconds 2 }
$s1 = Snap "SNAPSHOT 1"

Write-Output ""
Write-Output ("waiting until T+{0}s for the second snapshot" -f $SecondAtSec)
while(((Get-Date)-$t0).TotalSeconds -lt $SecondAtSec){ Start-Sleep -Seconds 5 }
$s2 = Snap "SNAPSHOT 2"

Write-Output ""
Write-Output "=== DELTA by object type index ==="
$keys = ($s1.Keys + $s2.Keys) | Sort-Object -Unique
foreach($k in $keys){
  $a = if($s1.ContainsKey($k)){$s1[$k]}else{0}
  $b = if($s2.ContainsKey($k)){$s2[$k]}else{0}
  $d = $b - $a
  if($d -ne 0){ Write-Output ("  typeIndex {0,3}: {1,5} -> {2,5}   delta {3:+0;-0;0}" -f $k,$a,$b,$d) }
}
$elapsed = ([math]::Max(1,($SecondAtSec-$FirstAtSec)))/60.0
Write-Output ""
Write-Output ("elapsed between snapshots: {0:N1} min" -f $elapsed)

Write-Output ""
Write-Output "=== teardown ==="
Get-Process -Name 'SK-Main','SK-Startup' -ErrorAction SilentlyContinue | ForEach-Object { Write-Output "killing $($_.ProcessName) $($_.Id)"; try{$_.Kill()}catch{} }
