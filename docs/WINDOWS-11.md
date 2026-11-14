# Silver Knights 0.13 — Windows 11

**Current status: PARTIAL PASS.** The game launches, renders and stays alive
indefinitely with a two-edit patch. Gameplay is **NOT TESTED**.
See `docs/COMPATIBILITY-MATRIX.md` for the per-scenario verdicts.

---

## 1. Test machine

**VERIFIED** (`docs/evidence/windows-events.txt`):

| Item | Value |
|---|---|
| OS | Microsoft Windows 11 Home Single Language |
| Version | 10.0.26300 |
| Build | 26300 |
| Architecture | 64-bit (x64 host, WOW64 for the game) |
| GPU | NVIDIA GeForce RTX 5060 Laptop GPU |
| Driver | 32.0.16.2124, dated 2026-11-11 |
| Display at test time | game window 646×509 (Window mode, `RESOLUTION=4`) |

The game is **32-bit**; it runs under **WOW64** and therefore receives
`C:\Windows\SysWOW64` DLLs, not `System32`. Several checks in this document depend
on that distinction.

---

## 2. Two independent defects

| # | Defect | Severity | Status |
|---|---|---|---|
| 1 | `SK-Startup.exe` reads `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ProductId`, which no longer exists | Cosmetic (two dialogs, then continues) | Diagnosed, **not fixed** |
| 2 | `SK-Main.exe` fingerprints `winmm!timeGetTime` and self-terminates when it does not match Win9x | **Fatal (guaranteed exit at ~8 s)** | Diagnosed, **fixed in experiment** |

Full mechanism: `docs/CRASH-ANALYSIS.md`.

---

## 3. What the user sees, before the fix

1. Launch `SK-Startup.exe`.
2. A dialog titled **`Error Massage`** with text
   **`RegQueryValueEx function failed.(REsult:2)`**.
3. Dismiss it. A second dialog: **`Failed to acquire the user ID.`**
4. Dismiss that. The launcher appears: `SK Startup - Version 0.13`, with
   `Full Screen` / `Window` / `Scene Editor` / `Resolution1/4` buttons.
5. Click `Window`. The render window opens and shows the Silver Knights title art.
6. **~6 seconds later** a third dialog: **`Timer-API hook was detected.(01ff)`**.
7. The game exits.

**VERIFIED** — `docs/evidence/run-06-sk-main-error.txt`,
`docs/evidence/run-15-trace-with-keys.txt`.

There is no Windows Error Reporting dialog, no "application has stopped working",
no event-log entry. The process exits cleanly. This is why the failure was hard to
attribute and why a crash dump hunt found nothing.

---

## 4. The fix

Two byte edits, applied to **copies**. The tracked originals are untouched.

### 4.1 Mandatory — `SK-Main.exe` RVA `0x1f4d50`: `7E` → `EB`

| | |
|---|---|
| Meaning | `jle 0x5f4da4` → `jmp 0x5f4da4` |
| Effect | The anti-hook verdict is always treated as "clean" |
| Length change | **None** (1 byte → 1 byte) |
| Files affected | `SK-Main.exe` only |
| Reason | The check fingerprints the Win9x `timeGetTime` prologue. Modern `winmm` is a `jmp [IAT]` thunk, so the check can never pass. |

**Behavioural consequence, stated explicitly:** the anti-cheat timer check is now
inert. A genuine API hook on `timeGetTime` would no longer be reported. This is
acceptable for preservation and unacceptable for any competitive-integrity claim.

### 4.2 Required by the launcher's integrity check — `SK-Startup.exe`

Editing `SK-Main.exe` invalidates the MD5 and size constants that
`SK-Startup.exe` verifies. Two options:

**Option A — patch both constants** (used in the experiment; requires an unpacked
`SK-Main.exe`, which changes the size):

| File offset | Original | Patched | Field |
|---|---|---|---|
| `0x12554` | `00 58 16 00` | `00 40 36 00` | expected size (1,464,320 → 3,555,328) |
| `0x12558` | `84a321d3…3667f3d6` | `64c68026…1c8b6965` | expected MD5 |

**Option B — same-length patch pipeline** (preferred for a distributable build):

1. Apply the 1-byte edit to the **packed** `SK-Main.exe` at the corresponding
   location, keeping the file exactly 1,464,320 bytes.
2. Recompute the MD5 of the resulting file.
3. Update **only** `0x12558` in `SK-Startup.exe`.

This keeps the shipped binary the same size, so the size constant at `0x12554`
does not need to change, and it avoids shipping a decompressed executable.

**Note:** Option B requires locating the packed-image equivalent of RVA `0x1f4d50`,
which was **not attempted** in this session. The packer's decompression stub must
run before the byte has meaning, so the packed-file offset is **not** `0x1f4d50`.
This is an open task (`docs/ROADMAP.md` T-02).

### 4.3 Optional — cosmetic registry fix

Until `SK-Startup.exe` is patched, the two startup dialogs can be suppressed by
creating the registry value it looks for:

```
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion
    ProductId  (REG_SZ) = <any non-empty string>
```

**This was NOT tested** in this session. It modifies a machine-wide registry key and
requires administrator rights; it must be evaluated deliberately, ideally inside a
disposable VM, before being recommended to users. A code patch to `SK-Startup.exe`
is preferable because it does not touch the host.

The exact read site and the `Failed to acquire the user ID.` fallback
(`1234567890` @ RVA `0x126f4`) are documented in `docs/BINARY-ANALYSIS.md` §7.

---

## 5. Verified runtime facts (patched build)

From `docs/evidence/run-15-trace-with-keys.txt` and `run-12-PATCHED-soak-180s.txt`:

| Observation | Value |
|---|---|
| Render window class | **`UDX_CLASS`** |
| Render window title | `Silver Knights - Version 0.13` |
| Window client size at `RESOLUTION=4` | 646 × 509 |
| Stability | alive at **180 s**, 27 threads, ~72 MB working set, zero dialogs |
| DirectShow graph window | `FilterGraphWindow` / `ActiveMovie Window` created at T+7.8 s |
| IME windows | `IME` / `MSCTFIME UI` present (Japanese input support active) |
| Log behaviour | `SK-Main.exe Start` written; `End` only on clean shutdown |

The log "Start without End" state is **correct and expected** for a running process.
It is the *inverse* of the original defect, where "Start + End 8 s later" looked
healthy but was a self-termination.

---

## 6. What is still unverified on Windows 11

Each line is a concrete, cheap test. None was performed in this session.

| # | Test | Why it matters |
|---|---|---|
| W-1 | Send input and confirm the game advances past the title art to a menu | ✅ **DONE — menu reached** (`run-19`). ❌ Navigation still fails (`run-20`): the selection bar does not move. |
| W-2 | Close the window cleanly and confirm the `SK-Main.exe End` log line | ✅ **PASS** (`run-16`) |
| W-3 | Enter an actual match; confirm rendering of a `.bsp` map | Blocked by W-1 navigation |
| W-4 | Confirm audio output (BGM + effects) | DirectSound/MCI/DirectShow all unverified |
| W-5 | Enumerate the loaded module list at T+10 s | ✅ **DONE** (`run-17`) — see §5.1 |
| W-6 | Test a controller | DirectInput8 fixed 8-button assumption |
| W-7 | Test network mode | DirectPlay 8 availability on this build |
| W-8 | Test the registry workaround (§4.3) in a VM | Cosmetic fix validation |
| W-9 | Test with `EFFECT_LEVEL` raised from `1` to maximum | The shipped setting is low; max settings exercise more shader paths |
| W-10 | Run 30+ minutes | Long-session stability and memory growth |
| W-11 | **Fix menu input** — the game polls DirectInput8, so `PostMessage` and `keybd_event` do not drive the menu | Highest priority; blocks all gameplay verification |

### 5.1 Verified module list (closes W-5)

**VERIFIED** — `docs/evidence/run-17-32bit-modules.txt`, captured with a **32-bit**
enumerator (a 64-bit module walk only sees `ntdll` + `wow64*` stubs; that trap was hit
first and is worth remembering).

| Observation | Detail |
|---|---|
| `SKGuard.dll` | Loaded, but at **`0x02500000`** — *not* its preferred base `0x10000000`. It was relocated, which means the loader did not place it where the DLL expected. Worth understanding before any assumptions about the hook. |
| `ssleay32.dll` | **ABSENT.** The open question in `BINARY-ANALYSIS.md` §9 is answered: it is never loaded. |
| `LIBEAY32.dll` | Loaded at `0x10000000`, version 0.9.8a. |
| `MSVCR71.dll` | Loaded at `0x7c340000`, version 7.10.3052.4 — the **app-local** copy wins, as predicted. |
| Graphics | `d3d9.dll` 10.0.26100.9818 + `nvd3dum.dll` 32.0.16.2124 (NVIDIA UMD) |
| Audio | `DSOUND.dll`, `QUARTZ.dll`, `devenum.dll`, `l3codeca.acm` (MP3 codec), `msmpeg2adec.dll`, `mciqtz32.dll`, `MSACM32.dll`, `dmusic.dll`, `dmloader.dll`, `midimap.dll` |
| Network | `WS2_32.dll`, `WSOCK32.dll`, `WININET.dll` loaded |
| **DirectPlay** | **ABSENT** — no `dpnet.dll`, `dpwsockx.dll` or `dplayx.dll`. Network mode was never entered, so this proves nothing about whether it *can* initialise. |

**Do not mark Windows 11 "compatible" on the strength of §5.** §5 proves the fatal
defect is fixed. It does not prove the game is playable.

---

## 7. Reproducing this work

All commands assume the repository root as working directory and
`PYTHON=python` with `pefile` + `capstone` installed.

```bash
# 1. Reference hashes
sha256sum SK-Main.exe SK-Startup.exe SKGuard.dll libeay32.dll ssleay32.dll msvcr71.dll

# 2. PE metadata (imports of the packed stub are misleading; see BINARY-ANALYSIS)
python tools/pe_report.py SK-Main.exe > docs/evidence/main-exe.pe.json

# 3. Unpack analysis copies (NEVER the tracked originals)
cp SK-Main.exe .analysis/unpacked/SK-Main.packed.exe
upx -d -o .analysis/unpacked/SK-Main.unpacked.exe .analysis/unpacked/SK-Main.packed.exe
python tools/pe_report.py .analysis/unpacked/SK-Main.unpacked.exe

# 4. Locate the defect
python tools/find_xrefs.py .analysis/unpacked/SK-Main.unpacked.exe --ascii "Timer-API hook was detected."
python tools/disasm_range.py .analysis/unpacked/SK-Main.unpacked.exe --rva 0x1f4ee0 --length 0x140
python tools/disasm_range.py .analysis/unpacked/SK-Main.unpacked.exe --rva 0x1f4d00 --length 0x60

# 5. Build a patched copy in a sandbox (never in the repo tree)
#    (copy the whole game tree to a scratch dir first)
python tools/patch_bytes.py <sandbox>/SK-Main.exe --out <sandbox>/SK-Main.exe.patched \
    --edit 0x1f4d50:7e:eb --reason "neutralise Win9x timeGetTime fingerprint"

# 6. Launch and observe
powershell -ExecutionPolicy Bypass -File tools/trace-run.ps1 -WorkDir <sandbox> \
    -Seconds 60 -DismissErrors -LaunchWindow -KeyAt 15
```

### Harness scripts (all read-only w.r.t. game files)

| Script | Purpose |
|---|---|
| `tools/pe_report.py` | PE headers, sections, imports, exports, resources → JSON |
| `tools/strings_extract.py` | Printable strings with file offsets, optional keyword filter |
| `tools/find_xrefs.py` | Map a string/offset to RVA/VA and find `push imm32` xrefs in executable sections |
| `tools/disasm_range.py` | Disassemble an RVA range with IAT annotation |
| `tools/disasm_exports.py` | Disassemble exported functions of a DLL |
| `tools/patch_bytes.py` | Audited, precondition-checked byte patching to a **new** output file |
| `tools/collect-windows-evidence.ps1` | Event log, WER, LocalDumps survey |
| `tools/launch-controlled.ps1` | Launch with exit code and elapsed time |
| `tools/monitor-run.ps1` | Process/window/log timeline |
| `tools/dump-ui.ps1` | Enumerate a process's windows and child control text |
| `tools/drive-launch.ps1` | Dismiss dialogs, click a launch button, monitor |
| `tools/capture-sk-main-error.ps1` | **Primary harness** — reads SK-Main dialogs verbatim |
| `tools/capture-screenshot.ps1` | Screen-region capture of the render window |
| `tools/probe-interaction.ps1` | Send keys, capture successive frames |
| `tools/capture-printwindow.ps1` | `PrintWindow` capture (occlusion-independent) |
| `tools/trace-run.ps1` | **Most detailed** — logs every window/class/text seen, end state, WER |

`capture-sk-main-error.ps1` and `trace-run.ps1` are the two entry points that
reproduce the baseline failure reliably.

---

## 8. Anti-patterns confirmed useless on this defect

Recorded so no future session wastes time:

| Attempt | Why it cannot work |
|---|---|
| Windows XP / Vista compatibility mode | Does not change `winmm!timeGetTime` machine code |
| Running as administrator | Not a privilege issue |
| Reinstalling DirectX 9 / `d3dx9_*.dll` | D3D9 initialises fine; the failure is after the window appears |
| Disabling DEP / adding `/NX:OFF` | The image already clears `NX_COMPAT` |
| GPU driver rollback | Rendering works; the failure is an API fingerprint |
| Replacing `winmm.dll` with a Win9x copy | Would break the OS; and the fingerprint reads whatever DLL is loaded, so this is not a supportable fix |
| Debugger-based tracing as the primary method | Trips the anti-debug checks and produces a *different* failure (`Debugger process was detected.`) that masks the real one |

The last row matters practically: if you attach a debugger to reproduce, expect a
different dialog. The `Timer-API` dialog is reached **without** a debugger, and that
is the correct baseline to compare against.
