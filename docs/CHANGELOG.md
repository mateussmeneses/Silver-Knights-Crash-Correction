# Changelog

All notable changes to this project. Format follows Keep a Changelog.
This project does not yet have releases; no game binaries have been published or modified
in the repository.

---

## [Unreleased]

### Added

- `docs/ARCHITECTURE.md` — verified architecture of the shipped binaries: process model,
  rendering pipeline, audio paths, network stack, configuration contract, anti-tamper design.
- `docs/BINARY-ANALYSIS.md` — authoritative binary record. Full SHA-256 for all six PE files,
  PE metadata, real (post-UPX) import surface with ordinal resolution, `SKGuard.dll` hook
  mechanism, `SK-Startup.exe` integrity check, and the anti-debug/anti-hook routines.
- `docs/CRASH-ANALYSIS.md` — root cause of the Windows 11 failure, proven from disassembly
  and confirmed by arithmetic against the live `winmm.dll`.
- `docs/WINDOWS-11.md` — the Windows 11 defect record, the validated fix, verified runtime
  facts, and the remaining verification backlog.
- `docs/LINUX.md` — Linux porting assessment and an ordered, falsifiable test protocol.
- `docs/MACOS.md` — macOS feasibility assessment, including the 32-bit/Rosetta 2 constraint
  and the DXVK-on-macOS misconception.
- `docs/COMPATIBILITY-MATRIX.md` — per-scenario status for Windows 11, Linux and macOS.
- `docs/ROADMAP.md` — phased milestones with pass criteria, Codex tasks, and Claude review
  tasks.
- `tools/` — 18 reproducible diagnostic and analysis scripts (see below).
- `docs/evidence/` — 20 execution records and 3 screenshots.

#### Tooling

| Script | Purpose |
|---|---|
| `pe_report.py` | PE headers, sections, imports, exports, resources, packer hints → JSON |
| `strings_extract.py` | Printable strings with file offsets, keyword filtering, UTF-16 support |
| `find_xrefs.py` | Resolve a string/offset to RVA/VA and locate code references |
| `disasm_range.py` | Disassemble an RVA range with IAT symbol annotation |
| `disasm_exports.py` | Disassemble a DLL's exported functions |
| `patch_bytes.py` | Audited byte patching with byte-level preconditions and checksum repair |
| `imgdiff.py` | PNG pixel diff with bounding box and row profile |
| `collect-windows-evidence.ps1` | Event log, WER and LocalDumps survey |
| `launch-controlled.ps1` | Launch with exit code and elapsed time |
| `monitor-run.ps1` | Process/window/log timeline |
| `dump-ui.ps1` | Enumerate a process's windows and child control text |
| `drive-launch.ps1` | Dismiss dialogs, click a launch button, monitor |
| `capture-sk-main-error.ps1` | Primary harness — reads SK-Main dialogs verbatim |
| `capture-screenshot.ps1` | Screen capture of the render window |
| `probe-interaction.ps1` | Key injection with successive frame capture |
| `capture-printwindow.ps1` | `PrintWindow` capture (occlusion-independent) |
| `trace-run.ps1` | Verbose per-second window/class/text trace plus end state |
| `probe-modules-shutdown.ps1` | Module list and clean-shutdown verification |
| `probe-32bit-modules.ps1` | 32-bit module enumeration of a WOW64 process |
| `t01-interactivity.ps1` | Title → menu progression with frame hashing |
| `t01b-menu-nav.ps1` | Hardware-level input injection for menu navigation |

### Changed

- `.gitignore` — now excludes `.analysis/`, unpacked/patched binaries, crash dumps, Python
  caches and editor noise. Analysis derivatives of the original executable must never be
  committed.

### Fixed (experimentally validated, not yet shipped)

- **Windows 11 self-termination after ~8 seconds.** Cause: `SK-Main.exe` at RVA `0x1f4ee0`
  fingerprints the machine code of `winmm!timeGetTime` against a hard-coded Windows 9x/2000
  prologue (`83 3D … 0F 85`). Modern `winmm.dll` exports a `jmp [IAT]` thunk (`FF 25 …`), so
  the check returns `0x100 + 0xFF = 0x1FF` and the game reports
  `Timer-API hook was detected.(01ff)` and exits.
  Fix: RVA `0x1f4d50`, `7E` → `EB` (`jle` → `jmp`), forcing the verdict to "clean".
  Validated: 4/4 unpatched runs failed at the identical dialog; 4/4 patched runs survived
  (up to 180 s verified).

- **Menu input not registering (test-harness defect, not a game defect).**
  `SetForegroundWindow` is refused for a background process, so DirectInput8 — which polls the
  keyboard attached to the foreground thread — never saw injected keys. Four injection
  strategies failed before this was identified. Fix: `AttachThreadInput` + synthetic ALT tap to
  acquire real foreground, plus **E0-extended DIK scancodes** for arrow keys. See
  `tools/t01f-force-focus.ps1`.

### Added

- `tools/build_patched.py` — reproducible same-length patched build.
  Pipeline: verify reference hash → `upx -d` → patch RVA `0x1f4d50` → `upx -9` re-pack → pad
  to exactly **1,464,320 bytes** → report the new MD5 for `SK-Startup.exe`.
  Because the length is preserved, the size constant at `0x12554` needs **no** edit; only the
  MD5 constant at `0x12558` changes. Validated end-to-end.
- `tools/imgdiff.py` — PNG pixel diff with bounding box and row profile, used to distinguish
  background animation from UI state changes.
- `tools/t01-interactivity.ps1`, `t01b-menu-nav.ps1`, `t01c-scancode-input.ps1`,
  `t01d-extended-scancode.ps1`, `t01e-focus-target.ps1`, `t01f-force-focus.ps1` — the
  progressive input-injection investigation that isolated the focus defect.
- `docs/DELEGATION.md` — complete, self-contained briefs for every open Codex and Claude task.

### Verified

- The game reaches its **main menu** with all five options rendered
  (`Story Mode`, `Battle Mode`, `Network Mode`, `Replay Mode`, `Option`).
- The **render loop is live** — consecutive frames differ across 70–84 % of pixels.
- **Clean shutdown** works under the patch: `WM_CLOSE` → exit → `SK-Main.exe End` written.
- **Stability**: 180 s, 27 threads, ~72 MB working set, zero error dialogs.
- **D3D9 initialisation** succeeds (`UDD_CLASS` window, `d3d9.dll` + `nvd3dum.dll` loaded).
- `ssleay32.dll` is **never loaded** (resolves an open question).
- DirectPlay DLLs are **absent** from the module list at the menu.
- `SKGuard.dll` loads but is **relocated** to `0x02500000`, not its preferred `0x10000000`.

### Known issues

- **Playable match not yet reached.** Menu and Battle Mode setup screen are confirmed; an
  actual in-game session with HUD is not.
- **`SK-Startup.exe` shows two spurious dialogs** on Windows 11 because it reads
  `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ProductId`, which no longer exists.
  Cosmetic; the launcher continues via a `1234567890` fallback. Not yet patched.
- **Full `.bsp` map rendering with D3DX effects, audio (SFX/MP3/MIDI), controller and network
  mode are all unverified** on every platform. A rendered stage *preview* thumbnail is
  confirmed on the Battle Mode setup screen, which proves the map/texture path is live but not
  that full geometry with post-processing works.
- **Linux and macOS: nothing has been executed.** All rows are `NOT TESTED`.
- Fixing the timer check **removes the game's anti-cheat tamper detection**. Documented as an
  accepted behavioural change; not appropriate for any competitive-integrity use.
- The repository ships **only `1041.ini`** (Japanese). No English `1033.ini` exists; the
  locale fallback behaviour is unknown.
- `win.bat`, referenced by `ReadMe-English.txt`, **is absent** from the repository.

### Not done

- No game binary in the repository was modified. The patch exists only as a documented
  byte-level change and as analysis copies under the gitignored `.analysis/` tree.
- No release, tag, or binary distribution. The author's licence
  (`ReadMe-English.txt` lines 20–29) forbids distribution.

---

## [0.1.0] — initial investigation baseline

### Added

- Repository and binary intake for Silver Knights 0.13.
- AI-Workbench capability inspection (`aiwh` CLI, game-port triage, capabilities catalogue).
- Binary identity record for all six PE files.
- UPX unpacking of analysis copies.
- Windows 11 reproduction harness and event-log evidence collection.

No prior history. This repository began at commit `747f22e` ("first commit").
