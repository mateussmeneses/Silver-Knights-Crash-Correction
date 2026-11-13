# Project Handoff — Silver Knights 0.13 Recovery

**Session date:** 2026-11-13
**Branch:** `001-recovery-foundation`
**Base commit:** `747f22e220bafe93d487161a8c7ab85d09119e31` (`main`, "first commit")
**Agent:** Hermes (Principal Coordinator)

---

## 1. Completed tasks

| ID | Task | Result |
|---|---|---|
| T-00.1 | Repository + history intake | Done — 1170 tracked files, single commit, no prior branches |
| T-00.2 | AI-Workbench CLI + capability inspection | Done — `aiwh` 0.3.0-era CLI; `game-port` triage run; 54 skills / 21 roles / 29 profiles catalogued |
| T-00.3 | Binary identity and hashes | Done — 6 PE files, full SHA-256 recorded |
| T-00.4 | PE metadata / imports / exports / ordinal resolution | Done — real imports recovered post-UPX |
| T-00.5 | UPX unpacking of analysis copies | Done — `.analysis/unpacked/` (gitignored) |
| T-00.6 | Windows 11 failure reproduction | Done — deterministic 4/4 |
| T-00.7 | Root cause | Done — proven, not hypothesised |
| T-00.8 | Experimental fix validated | Done — 4/4 patched runs survive |
| T-00.9 | Tooling and evidence | Done — 24 scripts, 25 execution records |
| T-01 | Menu reachability + navigation | **DONE** — menu reached, navigation proven |
| T-02 | Same-length shippable patch | **DONE** — `tools/build_patched.py`, validated |

---

## 2. Technical findings

### 2.0 Two root causes, not one

There were **two independent defects**, and the second one cost four failed attempts:

| # | Defect | Root cause | Fix |
|---|---|---|---|
| 1 | Fatal self-termination at ~8 s | `winmm!timeGetTime` fingerprint expecting a Win9x prologue | `SK-Main.exe` RVA `0x1f4d50` `7E`→`EB` |
| 2 | Menu input not registering | `SetForegroundWindow` **refused** for a background process | `AttachThreadInput` + ALT tap + **E0-extended** DIK scancodes |

Defect 2 was **not** an input-protocol problem. `PostMessage`, `keybd_event`, `SendInput`
with virtual keys, and `SendInput` with plain scancodes all failed — each looked like "the
game ignores input". The real fault was focus: DirectInput8 polls the keyboard attached to
**the foreground thread**, and the PowerShell console kept focus because Windows' foreground
lock refuses `SetForegroundWindow` from a process that did not receive the last input event.
`GetForegroundWindow() == target` was the check that exposed it.

The correct mechanics, for reuse:

```
AttachThreadInput(selfThread, foregroundThread, true)
keybd_event(VK_MENU down/up)              // ALT tap unlocks the foreground change
SetForegroundWindow(target)
AttachThreadInput(selfThread, foregroundThread, false)

// arrow keys are E0-extended Set-1 scancodes
SendInput(KEYEVENTF_SCANCODE | KEYEVENTF_EXTENDEDKEY, wScan=0x50)   // DIK_DOWN
SendInput(KEYEVENTF_SCANCODE | KEYEVENTF_EXTENDEDKEY, wScan=0x48)   // DIK_UP
```

The scancode contract is confirmed by `SilverKnights.ini [KEYBOARD]`: `UP=200`, `DOWN=208`,
`LEFT=203`, `RIGHT=205` are `0x80|scancode` DIK codes. The game reads DirectInput
scancodes, never virtual keys.

### 2.1 The fatal defect (VERIFIED)

`SK-Main.exe` RVA `0x1f4ee0` fingerprints the first 20 bytes of `winmm!timeGetTime` against a
hard-coded Windows 9x/2000 prologue:

```
expected: 83 3D <abs32> 00  0F 85 <rel32>     ; cmp [abs32],0 ; jne
actual  : FF 25 D8 72 02 10                   ; jmp [IAT]     (modern winmm thunk)
```

Return encoding on mismatch is `0x100 + byte[0]`; `0x100 + 0xFF = 0x1FF`, which is exactly
the `(01ff)` printed in the dialog `Timer-API hook was detected.(01ff)`.

Control flow at `0x1f4d43`: `cmp eax,-1` / `jle → clean`; anything `> 5` takes the
`Timer-API` branch, sets the cheat flag at `0x21428a4`, and calls shutdown `0x5fd640`.

**Fix:** RVA `0x1f4d50`, `7E` → `EB` (`jle` → `jmp`). One byte, same length.

### 2.2 The launcher integrity check (VERIFIED)

`SK-Startup.exe` refuses to launch `SK-Main.exe` unless:
- file size == `0x00165800` (1,464,320) — constant at `0x12554`
- MD5 == `84a321d3035de0e2f03539123667f3d6` — constant at `0x12558`

Patching `SK-Main.exe` therefore requires either updating both constants (used in the
experiment, needs an unpacked binary) or a same-length pack-then-patch pipeline
(**T-02, not yet done**).

### 2.3 The cosmetic defect (VERIFIED)

`SK-Startup.exe` reads `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ProductId`, which does
not exist on Windows 11 build 26300 (it lives under `Windows NT\CurrentVersion`). Result: two
`Error Massage` dialogs, then a fallback to `1234567890`. Not fatal. **T-03**.

### 2.4 Architecture facts that were previously unknown

- Main and launcher are **UPX-packed**; the shipped import table is the UPX stub's. Any
  analysis of the packed imports would be wrong.
- Graphics is **D3D9** with a **statically linked D3DX9 runtime effect compiler**. Shaders are
  compiled at runtime; there is no shader cache on disk. This is the dominant cross-platform
  blocker.
- Audio uses **three** paths: DirectSound 8 (`DirectSoundCreate8` by ordinal 11), MCI +
  DirectShow for MP3, DirectMusic for MIDI.
- Network gameplay is **DirectPlay 8** (`IDirectPlay8Peer/Server/Client`) — deprecated.
- `SKGuard.dll` installs a **global `WH_GETMESSAGE` hook** via `SetWindowsHookExA(idHook=3)`.
- The window class is **`UDX_CLASS`**.
- `ssleay32.dll` is **never loaded** (open question closed).
- `SKGuard.dll` loads **relocated** at `0x02500000`, not its preferred `0x10000000`.

---

## 3. Modified files

**No game binary in the repository was modified.** All originals remain byte-identical to
commit `747f22e`.

Added:
```
docs/ARCHITECTURE.md  docs/BINARY-ANALYSIS.md  docs/CRASH-ANALYSIS.md
docs/WINDOWS-11.md    docs/LINUX.md            docs/MACOS.md
docs/COMPATIBILITY-MATRIX.md  docs/ROADMAP.md  docs/CHANGELOG.md
docs/HANDOFF.md (this file)
docs/evidence/        (20 records + screenshots)
tools/                (21 scripts)
```

Modified:
```
.gitignore   — added .analysis/, unpacked binaries, dumps, Python caches
```

Gitignored (must stay local):
```
.analysis/           — unpacked + patched binaries (derived from the original)
```

---

## 4. Tests performed and actual results

| # | Test | Result | Evidence |
|---|---|---|---|
| 1 | Direct `SK-Main.exe` launch | Exit 0, 13 s, no log line | session log |
| 2 | `SK-Startup.exe` monitor | `Error Massage` dialog at T+0.4 s | `run-02` |
| 3 | Dialog text capture | `RegQueryValueEx … (REsult:2)` then `Failed to acquire the user ID.` | `run-03` |
| 4 | Drive to game window | window at T+5.0 s, dialog at T+10.2 s | `run-04` |
| 5 | Capture SK-Main dialog text | **`Timer-API hook was detected.(01ff)`** | `run-06` |
| 6 | Swapped unpacked binary | Rejected: `'SK-Main.exe' file is corrupted.` | `run-07` |
| 7 | Patch SK-Main only | Rejected: same corruption message | `run-08` |
| 8 | Patch both binaries | No dialog for 43 s | `run-09` |
| 9 | Screenshot title screen | Title art rendered | `run-10` + `.png` |
| 10 | Second patched run | Alive at end | `run-11` |
| 11 | 180 s soak | Alive 178 s, 27 threads, ~72 MB, zero dialogs | `run-12` |
| 12 | Verbose trace + modules | `UDX_CLASS`, `FilterGraphWindow`, full window inventory | `run-15` |
| 13 | Clean shutdown (`WM_CLOSE`) | Exits, writes `SK-Main.exe End` — **PASS** | `run-16` |
| 14 | 32-bit module list | `ssleay32` absent, DirectPlay absent, `SKGuard` relocated | `run-17` |
| 15 | Frame hashing over 90 s | **8 distinct frames** → animated; **menu reached** | `run-19` |
| 16 | Hardware key injection (VK+plain scancode) | 7 distinct frames but selection bar **did not move** | `run-20` |
| 17 | Scancode injection, no extended flag | Failed — `0x50` without `EXTENDEDKEY` is NumPad-2 | `run-21` |
| 18 | Extended scancode, focus unchecked | Failed — `fg != target`, focus refused | `run-22` |
| 19 | Enumerate all windows + focus retry | **Exactly one `UDX_CLASS`** window; `SetForegroundWindow` still refused | `run-23` |
| 20 | **`AttachThreadInput` + ALT tap** | **Focus acquired (`match=True`)**; navigation works | `run-24` |
| 21 | Same-length re-packed build | **1,464,320 bytes, launched, integrity passed, navigated** | `run-25` |
| 22 | Battle setup via Enter | Reached setup screen; Enter only moves slot focus | `run-26` |
| 23 | **F3 to start the match** | **"Battle Start" → timer `00:10.912` → live HUD** | `run-27` |

### Verified PASS

Launch · launcher UI · D3D9 init · title screen · **main menu** · **menu navigation**
(Story→Battle→Network→Battle) · **Battle Mode setup** · **playable match with live HUD**
(timer advanced 10.9 s, mech took damage, `Caution ! Minor damage...` fired) · **3D map
geometry** (walled textured arena, both mechs) · live render loop · 180 s stability · clean
shutdown · **same-length shippable patch**.

### Verified FAIL

Registry read (cosmetic) · UserID acquisition (cosmetic) · anti-cheat integrity (neutralised
by design).

### NOT TESTED

Post-processing effects at higher `EFFECT_LEVEL` · all audio · controller · network ·
every Linux row · every macOS row.

---

## 5. Remaining blockers

| # | Blocker | Severity | Owner |
|---|---|---|---|
| B-1 | **High-end renderer unexercised.** Shipped `EFFECT_LEVEL=1` never runs HDR/bloom/DoF/2.5D-blur/outline/motion-blur — the exact paths a translation layer breaks first. | **High** | Codex (T-05b) |
| B-2 | Root cause has not been independently reviewed. | High | Claude (R-01) |
| B-3 | Patch blast radius unknown — does `0x1f4d50` gate anything besides the anti-hook verdict? | High | Claude (R-02) |
| B-4 | `SKGuard.dll` hook body not reversed; behaviour on Win11 unknown. | Medium | Claude (R-03) |
| B-5 | Two cosmetic startup dialogs remain. | Medium | Codex (T-03) |
| B-6 | All three audio paths loaded but unheard. | Medium | Codex (T-04) |
| B-7 | DirectPlay 8 availability on Windows 11 unconfirmed; expected to block network play everywhere. | Medium | Claude (R-04) |
| B-8 | Linux and macOS entirely unstarted. | Deferred | — |

---

## 6. Next task

**T-05b — exercise the high-end renderer and capture the visual reference.**

Set `EFFECT_LEVEL` to its maximum in `SilverKnights.ini` (and enable `HDR_LIGHTING`,
`DEPTH_OF_FIELD`, `BLUR_2_5D`, `OUTLINE`, `MOTION_BLUR` one at a time), start a match with
`tools/t01h-start-match.ps1`, and capture the same view at each setting. Then restore the
shipped values.

**Why this is the next gate:** every cross-platform question reduces to "do the D3DX effect
shaders compile and produce the same image?" On Windows they use the embedded D3DX9 compiler
directly. On Linux (DXVK) and macOS (MoltenVK) they go through a translation layer that is
most fragile exactly here. A verified high-effect reference on Windows is the yardstick.

**T-05b is incomplete until the effect-on and effect-off frames differ visibly and no D3DX
compile failure occurs.**

---

## 7. Assigned agents

| Agent | Branch | Task |
|---|---|---|
| **Codex** | `codex/t05b-render-reference` | Raise `EFFECT_LEVEL` and each effect toggle; capture the visual reference set |
| **Codex** | `codex/t03-startup-registry` | Patch `SK-Startup.exe`'s `ProductId` read path to eliminate the two dialogs |
| **Codex** | `codex/t04-audio` | Verify SFX / MP3 / MIDI audibly; PASS-FAIL-BLOCKED per path |
| **Claude** | n/a | R-01 independently reproduce the `0x1FF` arithmetic; R-02 enumerate what `0x1f4d50` gates; R-03 reverse the `SKGuard` hook body; R-05 challenge the strategy choice |

File ownership is disjoint. No task modifies a tracked game binary.

---

## 8. Cautions for the next session

1. **Do not trust `SilverKnights.log`.** An `End` line proves the shutdown handler ran, not
   that the session was healthy. The original defect produced a clean `Start`/`End` pair after
   8 seconds.
2. **Do not analyse the packed binary's imports.** They are the UPX stub's. Unpack first.
3. **Do not run `SK-Main.exe` directly.** It exits 0 with no log line; the mailslot peer
   `SK-Startup.exe` is required.
4. **A 64-bit module walk of a WOW64 process shows only `ntdll` + `wow64*`.** Use a 32-bit
   enumerator.
5. **`Add-Type` silently fails** if the C# helper references `System.Drawing` types inside the
   type definition. Keep GDI work in PowerShell, not in the P/Invoke type.
6. **`pefile` holds a file lock.** Close the PE object before writing to the same path, or
   write to a different path.
7. **Do not enable Windows XP compatibility mode as a fix.** It cannot change
   `winmm!timeGetTime` machine code.
8. **Attaching a debugger produces a different failure** (`Debugger process was detected.`).
   Use the observable window trace harness, not a debugger, to reproduce the baseline.
9. **Never commit `.analysis/`.** Unpacked binaries are derived from a copyrighted game the
   author forbids distributing.
10. **The title's licence forbids distribution.** Any packaging effort must be personal-use
    only.
