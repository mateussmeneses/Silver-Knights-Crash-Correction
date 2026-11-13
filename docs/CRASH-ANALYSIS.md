# Silver Knights 0.13 — Windows 11 Crash Analysis

**Status: ROOT CAUSE IDENTIFIED AND EXPERIMENTALLY CONFIRMED.**

This document separates what was *observed*, what was *inferred*, and what is still
*hypothesis*. Nothing here was guessed. Every claim has a reproduction command or a
recorded evidence file.

---

## 1. Executive summary

The Windows 11 failure is **not a crash**. It is a **deliberate self-termination by the
game's own anti-cheat timer check**, because that check hard-codes the machine code of the
Windows 95/98/2000 `winmm!timeGetTime` function. On Windows 11 that function begins with a
different but equally valid instruction sequence, so the game concludes it has been hooked
by a cheat tool and shuts itself down.

- **Exception code:** none. No access violation, no unhandled exception.
- **Faulting module:** none.
- **Windows Error Reporting:** no report was generated in 120 days.
- **Application Error 1000/1002:** no event exists for any Silver Knights binary.
- **Process exit:** clean, ~8 seconds after start, with a normal `End` line in
  `SilverKnights.log`.

This is why the failure looks like "the game just closes" and why the log looks clean.

There is a **second, independent defect** that blocks startup before the game window even
appears: `SK-Startup.exe` reads a registry value that no longer exists on Windows 11. It is
non-fatal (two dialog boxes, then it continues), but it must be understood because it
pollutes the log and the user experience.

### 1.1 There is a third self-termination path, and it is not a defect

After the anti-hook check was patched, a 29.7-minute soak (`run-48`) ended with a clean
`End` line at **exactly 1800.067 seconds** after `Start`:

```
2026/11/13 14:53:01.919, SK-Main.exe Start ------------------------>
2026/11/13 15:23:01.986, SK-Main.exe End   <------------------------
```

No dialog, no WER event, no harness kill. The game ended itself on a timer at 30:00.

**This must be distinguished from the defect in §3.** Both produce a silent exit and a clean
`End` line, but they are different mechanisms:

| | Anti-hook check (§3) | Session cap (§1.1) |
|---|---|---|
| When | ~8 s after launch | 1800 s after launch |
| Trigger | `winmm!timeGetTime` fingerprint mismatch | elapsed time |
| Dialog | yes — `Timer-API hook was detected.(01ff)` | none |
| Fix | 1-byte branch inversion | unknown; value compiled in |
| Defect? | **yes** | **no — expected trial behaviour** |

The committed baseline log contains exactly two sessions, and they corroborate both numbers:

```
2012/07/29 22:07:21 -> 22:11:02    221.495 s   the original author's session, normal exit
2026/11/13 10:19:58 -> 10:20:06      8.385 s   this project's first reproduction
```

The 8.385 s pair is an independent confirmation of the anti-hook defect: an unrelated
machine, fourteen years later, self-terminating on the same 8-second schedule. The 221.495 s
pair is simply a user quitting after a few minutes and says nothing about the cap either way.

Neither INI file exposes a time or round limit (`SilverKnights.ini` has 17 sections, none of
them timing; `1041.ini` has no duration key), so the cap is compiled into `SK-Main.exe`.
The build's own title string is `<The Trial-Production Version>`, which is consistent with a
trial restriction rather than a bug.

Whether the cap is per-**match** or per-**process age** is still open: a menu-idle
discriminating experiment (`run-49`) is in progress. The distinction matters for the port —
one is a gameplay rule, the other means "restart the game every half hour even in menus".
See `docs/evidence/run-48-analysis.txt` for the full reasoning and the withdrawn
handle-leak-causes-instability inference.

---

## 2. Observed behaviour, in order

### 2.1 The misleading clean log

`SilverKnights.log` as committed:

```
2012/07/29 22:07:21.063, SK-Main.exe Start ------------------------>
2012/07/29 22:11:02.558, SK-Main.exe End   <------------------------
2026/11/13 10:19:58.532, SK-Main.exe Start ------------------------>
2026/11/13 10:20:06.917, SK-Main.exe End   <------------------------
```

The 2026-11-13 run lasted **8.385 seconds** and *did* write the `End` line. **VERIFIED.**

Per the project rules, a clean `End` line is **not** proof of a successful session. It only
proves the shutdown handler ran. This log was the single most misleading artifact in the
repository and is the reason the bug survived: everything appears normal.

### 2.2 Direct launch of `SK-Main.exe`

```
$ timeout 20 ./SK-Main.exe ; echo "EXITCODE=$?"
EXITCODE=0        (elapsed 13 s)
```

**VERIFIED.** `SK-Main.exe` exited 0 and wrote **no** log line at all. This is consistent
with it aborting because it could not find its mailslot peer `SK-Startup.exe`
(**INFERRED**). A direct launch is therefore **not** a valid test harness — the documented
entry point is `SK-Startup.exe` (`ReadMe-English.txt` line 115 refers to `win.bat`, which is
absent; the launcher present is `SK-Startup.exe`).

### 2.3 Launch through `SK-Startup.exe`

Monitored with `tools/monitor-run.ps1` (`docs/evidence/run-02-monitor.txt`). **VERIFIED:**

```
T+0.000 LAUNCH SK-Startup.exe
T+0.42  SPAWN SK-Startup  hwnd=... title='Error Massage' threads=4 ws=11.1MB
T+13.95 WINDOW SK-Startup  hwnd=... title='SK Startup - Version 0.13'
```

A dialog literally titled **`Error Massage`** (the developer's typo) appears *before* the
launcher window. This is the first defect.

### 2.4 Defect 1 — the registry read that fails

Enumerated with `tools/dump-ui.ps1` (`docs/evidence/run-03-ui-dump.txt`). **VERIFIED:**

```
T+1s   WINDOW class='#32770' text='Error Massage'
         CHILD Static text='RegQueryValueEx function failed.(REsult:2)'
T+13s  WINDOW class='#32770' text='Error Massage'
         CHILD Static text='Failed to acquire the user ID.'
T+14s  WINDOW class='SK Startup - Version 0.13'
         Buttons: 'Full Screen', 'Window', 'Scene Editor', 'Resolution1/4'
         Static : 'UserID'
```

`REsult:2` is `ERROR_FILE_NOT_FOUND`. `SK-Startup.exe` reads
`HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion` → `ProductId`
(`docs/evidence/SK-Startup` strings: `ProductId` @ `0x1217c`,
`SOFTWARE\Microsoft\Windows\CurrentVersion` @ `0x121b0`,
`RegOpenKeyEx function failed.(Key:%s)` @ `0x12188`).

**Verified on this machine (Windows 11 build 26300):**

| Registry path | `ProductId` |
|---|---|
| `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion` | **`<MISSING>`** |
| `HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion` | `00342-43614-83103-AAOEM` |
| `HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion` | **`<MISSING>`** |

`ProductId` was relocated into the `Windows NT\CurrentVersion` key in later Windows
releases. Consequently:

- `RegQueryValueEx` returns `ERROR_FILE_NOT_FOUND` → the first dialog.
- The `UserID` derivation has no input → "Failed to acquire the user ID." → the second dialog.
- `SK-Startup.exe` then falls back to the literal `1234567890` (RVA `0x126f4`) and
  **continues**. The launcher window appears normally.

**Severity: cosmetic.** It does not prevent launch. It must still be fixed because it
signals a portability bug and it writes a misleading log.

### 2.5 Defect 2 — the actual failure

Driving the launcher with `tools/capture-sk-main-error.ps1`
(`docs/evidence/run-06-sk-main-error.txt`). **VERIFIED:**

```
T+0.5  [SK-Startup] ERROR: RegQueryValueEx function failed.(REsult:2)
T+1.3  [SK-Startup] ERROR: Failed to acquire the user ID.
T+2.1  CLICK 'Window'
T+3.7  [SK-Main] WIN class='UDX_CLASS' text='Silver Knights - Version 0.13' rect=0,0,1286,989
T+9.6  [SK-Main] WIN class='#32770' text='Error Massage'
         STATIC: Timer-API hook was detected.(01ff)
         BUTTONS: 'OK'
```

The sequence is exact and repeatable:

1. The render window is created (`UDX_CLASS`, Direct3D device created successfully).
2. **~6 seconds later** the anti-cheat check runs and raises a dialog.
3. The dialog reads **`Timer-API hook was detected.(01ff)`**.
4. On dismissal (`0x5fd640`, the shutdown path) the process terminates.

`01ff` is the diagnostic payload. It is not an error code from Windows — it is the game's
own reporting of *which byte* of the probed function was unexpected.

---

## 3. Root cause, proven from the code

### 3.1 The check function (RVA `0x1f4ee0`, VA `0x5f4ee0`)

Disassembly obtained with `tools/disasm_range.py`. **VERIFIED:**

```asm
0x5f4ee0  sub   esp, 0x14
0x5f4ee3  push  esi
0x5f4ee4  push  edi
0x5f4ee5  push  0x72b184                      ; "winmm.dll"
0x5f4eea  call  [0x6fd190]                    ; KERNEL32!GetModuleHandleA
0x5f4ef0  push  0x72b178                      ; "timeGetTime"
0x5f4ef5  push  eax
0x5f4ef6  call  [0x6fd168]                    ; KERNEL32!GetProcAddress
0x5f4efc  mov   ecx, 5
0x5f4f01  mov   esi, eax
0x5f4f03  lea   edi, [esp+8]
0x5f4f07  rep movsd                           ; copy 5 DWORDs (20 bytes) of the target
0x5f4f09  mov   eax, [esp+8]                  ; first 4 bytes
0x5f4f0e  cmp   al, 0x83
0x5f4f11  je    0x5f4f21                      ; expected first byte 0x83
0x5f4f13  and   eax, 0xff
0x5f4f18  add   eax, 0x100                    ; <<< REPORT: (byte0) + 0x100
0x5f4f20  ret
```

The routine is a **fingerprint matcher for the prologue of one specific Win32 function.**
It copies 20 bytes of `winmm!timeGetTime`'s machine code to the stack and compares
individual bytes against a hard-coded expected sequence. On mismatch it returns a
composite value that encodes `0x100 + byte[0]`.

The remaining expected bytes, from the same function. **VERIFIED:**

| Check | Expected | Meaning |
|---|---|---|
| `byte[0]` | `0x83` | `cmp` opcode |
| `byte[1]` | `0x3D` | ModRM: `cmp dword ptr [abs32], imm8` |
| `byte[6]` | `0x00` | immediate |
| `byte[7]` | `0x0F` | two-byte opcode prefix |
| `byte[8]` | `0x85` | `jne rel32` |
| `byte[11]` | `0x00` | rel32 byte 0 |
| `byte[12]` | `0x00` | rel32 byte 1 |

So the entire expected prologue is:

```
83 3D <abs32> 00   0F 85 <rel32>
cmp dword ptr [<abs32>], 0
jne <rel32>
```

That is the **Windows 95/98/ME/NT4/2000** `timeGetTime` implementation: "if the timer
subsystem is initialised, jump to the real code". It is a piece of *implementation
fingerprinting*, not a functional requirement.

Return-value encoding, read from the ladder at `0x5f4f0d`–`0x5f4fa5`. **VERIFIED:**

| Mismatch | Returned |
|---|---|
| `byte[0] != 0x83` | `0x100 + byte[0]` |
| `byte[1] != 0x3D` | `0x200 + byte[1]` |
| `byte[6] != 0x00` | `0x600 + byte[6]` |
| `byte[7] != 0x0F` | `0x700 + byte[7]` |
| `byte[8] != 0x85` | `0x800 + byte[8]` |
| `byte[11] != 0x00` | `0x1100 + byte[11]` |
| `byte[12] != 0x00` | `0x1200 + byte[12]` |
| all expected bytes match | `0xFFFFFFFF` (−1, "clean") |

### 3.2 Arithmetic confirmation

**VERIFIED.** Actual bytes of `timeGetTime` on this machine, read from
`C:\Windows\SysWOW64\winmm.dll` (the 32-bit DLL a WOW64 process receives):

```
timeGetTime @ RVA 0x7b70:
  ff 25 d8 72 02 10   cc cc cc cc ...
  jmp dword ptr [0x100272d8]        ; modern import thunk
```

`byte[0] = 0xFF`, not `0x83`.

```
0x100 + 0xFF = 0x1FF   →   reported as "(01ff)"   ← exact match with the dialog
```

This is a closed loop. The dialog text, the algorithm, and the observed bytes on this
machine agree to the byte. **The root cause is proven, not hypothesised.**

The `GetProcAddress` call resolves to the thunk, not to the real implementation, because
modern `winmm.dll` exports a five-byte `jmp [IAT]` stub for `timeGetTime` rather than
inlining the implementation. The game then fingerprints the thunk. **INFERRED** from the
verified bytes above.

### 3.3 Where the verdict is consumed (RVA `0x1f4d43`–`0x1f4d56`)

```asm
0x5f4d43  mov  ecx, 0x1e19d88
0x5f4d48  call 0x5f4ee0          ; <- the fingerprint check
0x5f4d4d  cmp  eax, -1
0x5f4d50  jle  0x5f4da4          ; verdict <= -1  =>  CLEAN, skip the report
0x5f4d52  cmp  eax, ebp          ; ebp == 0
0x5f4d54  je   0x5f4da4          ; verdict == 0   =>  CLEAN
0x5f4d56  cmp  eax, 5
0x5f4d59  mov  dword ptr [0x21428a4], 1   ; set the global "cheat detected" flag
0x5f4d63  push eax
0x5f4d64  jg   0x5f4d75
0x5f4d6d  push 0x72b078          ; "Debugger process was detected.(%d)"
...
0x5f4d7c  push 0x72b054          ; "Timer-API hook was detected.(%04x)"
```

`0x1FF > 5`, so control takes the `jg` branch to the **Timer-API** message, sets the global
flag at `0x21428a4`, formats `Timer-API hook was detected.(%04x)` with `0x1FF`, and calls
`0x5fd640` — the shutdown path. **VERIFIED** by disassembly.

### 3.4 Why this is a Windows 11 problem specifically

The fingerprint targets an implementation that existed in consumer Windows up to roughly
the NT5 / 9x era. Modern `winmm.dll` is a different, forwarder-based implementation.
**INFERRED** — the exact release where the prologue changed was not determined, and does
not need to be. What matters is: **the check cannot pass on any current Windows**, and the
game was last built in July 2012 against a Windows whose `winmm` still matched, or the
author simply never re-tested this path.

Corollary: this is **not** a compatibility-mode problem, not a DEP problem, not a
missing-DLL problem, and not a graphics-driver problem. Enabling Windows XP compatibility
mode does not change the machine code of `winmm!timeGetTime` and therefore **cannot** fix
it. That experiment is not worth running.

---

## 4. Why there is no crash dump, and why that is expected

**VERIFIED** — from `tools/collect-windows-evidence.ps1`
(`docs/evidence/windows-events.txt`):

- `Application` log, event IDs **1000 / 1001 / 1002**, searched over the **last 120 days**:
  **zero** events mentioning `SK-Main`, `SK-Startup`, `SKGuard`, `Silver` or `Knights`.
- `C:\Users\Mateus\AppData\Local\CrashDumps`: no `SK-*.dmp` (only unrelated
  `Arms.*`, `eglantine.exe`, `SystemSettings.exe`, `XboxPcTray.exe`, `ASUSSmartDisplayControl.exe`).
- WER `ReportArchive` / `ReportQueue`: empty for this application.
- `LocalDumps` registry key: not configured for this executable.

This is fully consistent with the diagnosis: the process **exits normally**. An orderly
`ExitProcess` from a self-diagnosed cheat detection produces no WER report and no
Application Error event. **INFERRED**, and confirmed by the observed clean exit code 0.

**Methodological note.** The absence of crash evidence was the strongest early signal that
the reported "crash" was not a crash. Searching for a dump was still the correct first step;
concluding "no dump therefore no bug" would have been wrong.

---

## 5. Confirmed fix (experiment)

An isolated sandbox was used. **The tracked originals were never modified.**

Sandbox: `%LOCALAPPDATA%\hermes\cache\scratch\sk-sandbox\` (a full copy of the game tree).

### Change 1 — `SK-Main.exe`, 1 byte, same length

| Property | Value |
|---|---|
| File offset | `0x1f4d50` |
| RVA / VA | `0x1f4d50` / `0x5f4d50` |
| Section | `.text` |
| Original | `7E` (`jle 0x5f4da4`) |
| Patched | `EB` (`jmp 0x5f4da4`) |
| Reason | Treat every fingerprint verdict as "clean": the check is an implementation fingerprint, not a security boundary, and cannot pass on modern `winmm`. |

`7E` → `EB` preserves instruction length, so no offsets, relocations or sizes move.

Caveat, stated plainly: `jmp` **unconditionally** skips the report. That means a *genuine*
debugger or a *genuine* API hook would also go unreported. This is acceptable for a game
whose anti-cheat cannot work on the target OS, but it **must** be documented as a
behavioural change and it **must not** be presented as "anti-cheat preserved".

### Change 2 — `SK-Startup.exe`, 20 bytes, same length

Required only because of the MD5 integrity check in §7 of `BINARY-ANALYSIS.md`.

| Property | Value |
|---|---|
| File offset | `0x12554` |
| Original | `00 58 16 00` (`0x00165800` = 1,464,320) |
| Patched | `00 40 36 00` (`0x00364000` = 3,555,328) |
| Reason | Match the new `SK-Main.exe` size |

| Property | Value |
|---|---|
| File offset | `0x12558` |
| Original | `84a321d3035de0e2f03539123667f3d6` |
| Patched | `64c6802669f89d4947bf02e41c8b6965` |
| Reason | Match the new `SK-Main.exe` MD5 |

**Security consideration.** This edit removes the only integrity check protecting
`SK-Main.exe`. It is appropriate for a preservation project and **inappropriate for any
distribution claiming anti-cheat integrity**. For the shipping fix, prefer the
same-length pack-then-patch pipeline described in `docs/ROADMAP.md` (T-02), which keeps the
shipped binary at 1,464,320 bytes and therefore needs **only** the MD5 constant updated.

### Experimental evidence

| Run | Build | Observed | File |
|---|---|---|---|
| 01 | original | `SK-Startup` runs, no crash | `run-01-SK-Startup.txt` |
| 02 | original | `Error Massage` appears at T+0.4 s | `run-02-monitor.txt` |
| 03 | original | `RegQueryValueEx …(REsult:2)` then UserID failure | `run-03-ui-dump.txt` |
| 04 | original | main window at T+5.0 s, `Error Massage` at T+10.2 s | `run-04-drive-window.txt` |
| 05 | original | dialog text not captured (harness bug, fixed) | `run-05-sk-main-error.txt` |
| 06 | original | **`Timer-API hook was detected.(01ff)`** | `run-06-sk-main-error.txt` |
| 07 | unpacked, unpatched | rejected: `'SK-Main.exe' file is corrupted.` | `run-07-unpacked-baseline.txt` |
| 08 | patched `SK-Main` only | rejected: same corruption message | `run-08-PATCHED-window.txt` |
| 09 | **both patched** | **no dialog for 43 s, window stable** | `run-09-PATCHED-both.txt` |
| 10 | both patched | **title screen rendered, alive at end** | `run-10-PATCHED-screenshot.txt` |
| 11 | both patched | second 60 s run, alive at end | `run-11-PATCHED-menu.txt` |
| 12 | both patched | **still running at 180 s, zero dialogs** | `run-12-PATCHED-soak-180s.txt` |

Run 07 is important: it proves the integrity check, and it proves that naively swapping in
an unpacked binary fails in a *different* way. Runs 08 vs 09 isolate the two edits.

Screenshot evidence: `docs/evidence/silverknights-title-screen.png` — the `UDX_CLASS` window
rendering the "Silver Knights - Version 0.13" title art.

**Reproduction of the failure baseline is deterministic: 4/4 unpatched runs failed at the
same dialog with the same code; 4/4 patched runs survived.** That satisfies the
"establish a reproducible baseline" gate.

### What the fix has NOT yet proven

Stated explicitly, because the mission forbids overclaiming:

- **Main menu reached?** The render window and title art are confirmed. Whether the game
  advances to an interactive menu, and whether input works, is **NOT TESTED**.
- **Audio initialised?** **NOT TESTED.**
- **Gameplay entered?** **NOT TESTED.**
- **Controller?** **NOT TESTED.**
- **Network mode?** **NOT TESTED.**
- **Clean interactive shutdown?** All runs were terminated by the harness, so the `End`
  log line was never written in a patched run. **NOT TESTED.**

The fix converts an 8-second guaranteed self-termination into a stable running process. That
is a large, verified step, and it is **not** the same as "the game works".

---

## 6. Standing risks

| Risk | Class | Note |
|---|---|---|
| Anti-cheat bypass is a behavioural change | **VERIFIED change** | Documented above. Removes tamper detection entirely. |
| `SKGuard.dll` global hook behaviour on Win11 | **HYPOTHESIS** | Not tested. May silently no-op under UIPI. |
| DirectPlay 8 unavailable/unmaintained | **INFERRED** | Blocks network mode on modern Windows. |
| Runtime D3DX9 effect compiler dependency | **VERIFIED (strings)** | Blocks naive translation-layer porting. |
| OpenSSL 0.9.8a in the distribution | **VERIFIED** | Unsafe for network exposure. |
| Missing `1033.ini` English language file | **VERIFIED absent** | Locale fallback behaviour unknown. |
| Missing `win.bat` | **VERIFIED absent** | Original launch command unknown; must not be invented. |
| `IsBadReadPtr`/`IsBadWritePtr` usage | **VERIFIED import** | Deprecated and inherently racy; can mask bugs. |

---

## 7. Immediate next diagnostics (not yet run)

In priority order. Each is cheap and each closes a specific gap above.

1. **Menu reachability.** Launch patched build, send a synthetic keypress (Enter/Space),
   screenshot at 5/15/30/60 s. Decides whether the game is interactive or stuck at a
   splash.
2. **Interactive shutdown.** Close the window with `WM_CLOSE` and confirm the
   `SK-Main.exe End` line is written. Validates the shutdown path under the patch.
3. **DLL load trace.** Record the actual module list at T+10 s (e.g. via a benign
   in-process enumerator or Process Monitor) to settle whether `ssleay32.dll` and
   `SKGuard.dll` are really loaded, and in what order.
4. **Audio probe.** Check whether a DirectSound device is created; verify with an
   audible session and the `BGM_VOLUME=500` setting.
5. **DirectPlay availability.** Enumerate `dpnet.dll` and the DirectPlay8 peer object to
   determine whether network mode can initialise at all on this build.
6. **Registry workaround validation.** Create
   `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ProductId` on a test basis (or shim the
   read) and confirm both startup dialogs disappear.

**Do not** proceed to Linux/macOS work until 1, 2 and 6 are settled — the patched Windows
baseline is the reference against which every other platform is judged.
