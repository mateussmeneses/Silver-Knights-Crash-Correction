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

### Fixed (navigation / harness, not game defects)

- **Match would not start (navigation error, not a game defect).**
  The Battle setup screen was reachable but inert because `Enter` only moves slot focus.
  The start control is **`F3`**, from `1041.ini [FUNCTION] F3_START =F3 Start`.
  Fix: press `F3` (scancode `0x3D`, non-extended). See `tools/t01h-start-match.ps1`.

### Verified — playable match

- A **live match runs**: "Battle Start" banner → timer advances `00:00.000` → `00:10.912`.
- **Full HUD renders**: Philotes health 1160, Military Potential gauge, Radar, Altimeter,
  `Danger` overlay, and the `Caution ! Minor damage...` message (which is
  `SilverKnights.ini [MESSAGE] DAMAGE25` — so the damage system is live, not a static screen).
- **3D map geometry renders**: a walled, textured arena with both mechs.
- `SK-Main.exe` stayed alive throughout (106 MB, 35 threads), no error dialog.

### Verified — audio (measured, not inferred)

- `run-33` attached to the Windows default render endpoint via WASAPI
  (`IAudioMeterInformation::GetPeakValue`) and sampled the endpoint peak while the game ran.
- **Control:** idle with no game running → peak `0.00000`. The instrument is trustworthy.
- **Menu BGM:** peak `0.04986`, **24/24 samples non-zero** — continuous, low-level signal,
  exactly what looping background music looks like on a peak meter.
- **In-match:** peak `1.00000`, 24/24 non-zero — the DirectSound8 path plus music bed.
- Audio previously recorded as "loaded but unheard" is now **measured**.

Not proven: MIDI specifically (`dmusic.dll` path), per-effect attribution, gain staging and
clipping (a sustained 1.0 peak may indicate clipping), and anything a peak meter cannot see —
distortion, channel swap, wrong pitch. This does **not** replace a human listening test.

### Verified — effect comparison (partial)

- `run-35` established a **negative** result that corrected an earlier plan: the Battle setup
  screen does **not** apply post-processing (effects-off vs effects-on produced byte-identical
  PNGs, 0/1228800 px). It is UI, not a rendered scene, and cannot serve as the comparison
  surface.
- `run-34`: replay recording via `F2` produced **no** `.rep` file, so the camera could not be
  frozen.
- `run-36` therefore used a burst of 4 frames per profile from the deterministic spawn pose.
  Matched first-frame diff = **3.67 %**, concentrated in the upper 3D scene band (y61–372)
  including a large arc-shaped region — not HUD-only. Effects-on burst file sizes cluster
  tightly (1.35–1.40 MB) vs off (1.31–1.83 MB), the expected signature of smoothing.
- **Not proven:** which effect causes which change (all six toggles flipped together), and
  camera drift cannot be excluded without a replay.

### Verified — high-end renderer

- Four effect profiles (`EFFECT_LEVEL` 1 → 3, HDR + depth-of-field, all effects including
  2.5D blur / outline / motion blur) each reached a **live 1280×960 match** with **no D3DX
  compile failure and no error dialog**. Thread count rose 33 → 45 under full effects.
- `SilverKnights.ini` was restored byte-identically after the sweep, verified by content
  comparison.
- **Not proven:** that each effect *visibly* changes the image. The pixel diff (73–77 %) is
  confounded because each profile was a different gameplay moment. Needs a fixed-camera replay
  comparison (T-05c).

### Fixed (genuine binary defect)

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

- **Match would not start (navigation error, not a game defect).**
  The Battle setup screen was reachable but inert because `Enter` only moves slot focus.
  The start control is **`F3`**, from `1041.ini [FUNCTION] F3_START =F3 Start`.
  Fix: press `F3` (scancode `0x3D`, non-extended). See `tools/t01h-start-match.ps1`.

### Verified — playable match

- A **live match runs**: "Battle Start" banner → timer advances `00:00.000` → `00:10.912`.
- **Full HUD renders**: Philotes health 1160, Military Potential gauge, Radar, Altimeter,
  `Danger` overlay, and the `Caution ! Minor damage...` message (which is
  `SilverKnights.ini [MESSAGE] DAMAGE25` — so the damage system is live, not a static screen).
- **3D map geometry renders**: a walled, textured arena with both mechs.
- `SK-Main.exe` stayed alive throughout (106 MB, 35 threads), no error dialog.

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
- `tools/t01g-gameplay.ps1`, `t01h-start-match.ps1` — the match-start harness that reached
  gameplay.
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
