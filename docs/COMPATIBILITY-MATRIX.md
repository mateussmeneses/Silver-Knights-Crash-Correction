# Silver Knights 0.13 — Compatibility Matrix

**Rule:** a cell may only say PASS on the strength of a recorded execution that reached that
scenario. "It launched" is not "main menu". "Title art rendered" is not "gameplay".

Status vocabulary: `NOT TESTED` · `INVESTIGATING` · `PASS` · `FAIL` · `BLOCKED`

Every PASS/FAIL below cites an evidence file in `docs/evidence/`.

---

## 1. Windows 11 — patched build

Environment: Windows 11 build **26300**, x64, RTX 5060 Laptop, driver 32.0.16.2124.
Patched build = `.analysis` sandbox with `SK-Main.exe` `RVA 0x1f4d50` `7E`→`EB` and matching
`SK-Startup.exe` integrity constants.

| Scenario | Status | Evidence / note |
|---|---|---|
| Process launch (`SK-Startup.exe`) | **PASS** | `run-09`, `run-10`, `run-11`, `run-12`, `run-15` |
| Launcher window renders | **PASS** | `run-03` — `SK Startup - Version 0.13`, 4 buttons + `UserID` field |
| `SK-Main.exe` spawned | **PASS** | `run-15` — spawned ≤ 1.7 s after launch click |
| Registry read (`ProductId`) | **FAIL** | `run-03` — `RegQueryValueEx … (REsult:2)`; value absent on Win11. Cosmetic: launcher continues. |
| UserID acquisition | **FAIL** | `run-03` — `Failed to acquire the user ID.` Falls back to `1234567890`. Cosmetic. |
| **Anti-hook check passes** | **PASS (patched)** | Unpatched: **FAIL** with `Timer-API hook was detected.(01ff)` (`run-06`). Patched: no dialog in 180 s (`run-12`). |
| Graphics initialisation (D3D9 device) | **PASS** | `run-15` — `UDX_CLASS` window created; `d3d9.dll` + `nvd3dum.dll` loaded (`run-17`) |
| Title screen renders | **PASS** | `docs/evidence/silverknights-title-screen.png` — title art visible |
| Process stability ≥ 180 s | **PASS** | `run-12` — 178 s alive, 27 threads, ~72 MB, zero dialogs |
| **Main menu** | **PASS** | `run-19` (8 distinct frames) + `t01/08-final.png` — full 5-item menu rendered: Story Mode / Battle Mode / Network Mode / Replay Mode / Option |
| **Menu navigation (selection moves)** | **PASS** | `run-24` + `t01f/` — Story → Battle → Network (down×2) → Battle (up×1), verified visually. Root cause of earlier failure: `SetForegroundWindow` was **refused**, so DirectInput never saw the keys; fixed with `AttachThreadInput` + synthetic ALT tap. |
| **Mode entry (submenu)** | **PASS** | `run-24` `t01f/E-enter.png` — Enter opened the Battle Mode setup screen: "Select your Mech, Team, and Stage!", Victory Conditions, Military Potential, Player=Philotes, Team=RED, rendered "Training Room" stage preview |
| **Playable match (in-game HUD)** | **PASS** | `run-27` + `t01h/04-after-F3.png` ("Battle Start", timer `00:00.000`) → `t01h/06-after-enter.png` (**active gameplay**, timer `00:10.912`). HUD confirmed: Philotes health 1160, Military Potential, Radar, Altimeter, Danger overlay, `Caution ! Minor damage...` |
| **Map rendering (`.bsp` + effects)** | **PASS (geometry)** | `run-27` — a walled, textured arena renders with both mechs in 3D. **Post-processing effects (HDR/bloom/DoF) NOT exercised**: shipped `EFFECT_LEVEL=1` is the lowest setting. |
| **High-end renderer compiles at EFFECT_LEVEL 3** | **PASS (compiles/runs)** | `run-28` + `t05b/` — 4 profiles (`EFFECT_LEVEL` 1→3, HDR+DoF, all effects) each reached a live match at 1280×960 with **no D3DX compile failure and no error dialog**. Threads rose 33→45. INI restored byte-identically. |
| **Effects visibly change the image** | **PARTIAL** | `run-36` + `t05d/` — matched first-frame diff = **3.67 %**, concentrated in the upper 3D scene band (y61–372), including a large arc-shaped region; HUD-only it is not. Effects-on burst is tightly clustered in file size (1.35–1.40 MB) vs off (1.31–1.83 MB). **Not** per-effect attribution, and camera drift cannot be excluded without a replay. |
| **Post-processing DOES NOT apply on the setup screen** | **VERIFIED (negative)** | `run-35` — effects-off vs effects-on at the Battle setup screen produced **byte-identical** PNGs (0/1228800 px). That screen is UI, not a rendered scene. |
| **Audio — SFX + BGM (measured)** | **PASS** | `run-33` — WASAPI endpoint peak meter. Idle control **0.00000**; menu BGM **0.0499**, 24/24 samples non-zero (continuous); in-match **1.00000**, 24/24. Real signal reaches the output device. |
| **Audio — MIDI path** | **NOT PROVEN** | The music measured is the MP3/DirectShow path. `dmusic.dll`/`midimap.dll` are loaded but no MIDI track was isolated. |
| **Startup dialogs suppressed** | **PASS** | `run-31`, `run-32` — launcher usable at T+0.5 s with **zero** dialogs (was 2 dialogs, usable at T+14 s). Integrated into `tools/build_patched.py`. |
| **Render loop is live (animation)** | **PASS** | `run-19`, `run-20` — consecutive frames differ across 70–84% of pixels with a full-window bounding box (`tools/imgdiff.py`) |
| **Same-length shippable patch** | **PASS** | `run-25` — unpack → patch → re-pack → pad to **1,464,320 bytes**; only the MD5 constant needed editing; game launched, integrity check passed, navigation worked |
| **Audio — SFX (DirectSound8)** | **PASS (signal measured)** | See the measured audio row above (`run-33`) |
| **Audio — BGM (MP3/MCI/DirectShow)** | **PASS (signal measured)** | Menu BGM continuous at peak 0.0499, 24/24 samples (`run-33`) |
| **Audio — MIDI (DirectMusic)** | **NOT PROVEN** | `dmusic.dll`/`midimap.dll` loaded; no MIDI track isolated |
| **Controller (DirectInput8)** | **NOT TESTED** | `DINPUT8.dll` loaded; no device tested |
| **Network mode (DirectPlay 8)** | **NOT TESTED** | DirectPlay DLLs **absent** from the module list (`run-17`) — network mode was never entered, so this proves nothing about whether it *can* initialise |
| Lobby / CGI scoreboard | **NOT TESTED** | `WININET.dll` loaded; no request captured |
| **Clean shutdown** | **PASS** | `run-16` — `WM_CLOSE` → process exits, `SK-Main.exe End` log line written |
| Anti-cheat integrity preserved | **FAIL (by design)** | The patch neutralises the timer check. Documented as an accepted behavioural change. |

### Windows 11 summary

**3 defects found. 2 fixed and verified (fatal self-termination + 2 startup dialogs).**
**11 of 13 mission scenarios verified — gameplay, audio and rendering included.**

Verified: launch · launcher UI (dialog-free) · D3D9 init · title screen · **main menu** ·
**menu navigation** · **Battle Mode setup** · **playable match with live HUD** ·
**3D map geometry** · **high-end renderer compiles and runs** · **effects alter the 3D scene
on a matched frame (partial)** · **audio: SFX + BGM measured, real signal** ·
180 s stability · clean shutdown · **same-length reproducible build**.

Still open: **per-effect attribution**, **MIDI path**, **controller**, **network mode**.

The verdict is **PLAYABLE AND AUDIBLE, NOT YET FULLY VERIFIED**. A real match runs with
effects enabled, renders 3D geometry, advances its clock, fires gameplay messages, and puts
measured signal on the audio device. What remains is per-effect rigour, MIDI, a controller,
and multiplayer — plus the fact that Linux and macOS have no runtime evidence at all.

### The three defects found

| Defect | Root cause | Fix |
|---|---|---|
| Fatal self-termination at ~8 s | `winmm!timeGetTime` fingerprint expecting a Win9x prologue | `SK-Main.exe` RVA `0x1f4d50` `7E`→`EB` |
| Menu input not registering | `SetForegroundWindow` **refused** for a background process, so DirectInput8 (which polls the foreground thread's keyboard) never saw injected keys | `AttachThreadInput` + synthetic ALT tap + **E0-extended** DIK scancodes |
| Match would not start | The start control is **F3**, not Enter (`1041.ini [FUNCTION] F3_START =F3 Start`) | Press `F3` (scancode `0x3D`) at the Battle setup screen |

All three were harness/navigation errors of *understanding*, not broken game code — except the
first, which was a genuine defect in the shipped binary.

### Playable-match evidence chain

| Frame | Timer | State |
|---|---|---|
| `t01h/03-battle-setup.png` | — | "Select your Mech, Team, and Stage!" |
| `t01h/04-after-F3.png` | `00:00.000` | "Battle Start" banner, both mechs rendered, full HUD |
| `t01h/05-after-F3b.png` | advancing | countdown progressed |
| `t01h/06-after-enter.png` | `00:10.912` | **active gameplay**, mech took damage, `Caution ! Minor damage...` fired |

HUD elements observed, each cross-checked against the game's own string table:
`Philotes` (mech), `Military Potential`, `Radar`, `Altimeter`, `Danger` overlay,
`Caution ! Minor damage...` (= `SilverKnights.ini [MESSAGE] DAMAGE25`).

---

## 2. Windows 11 — original unpatched build

Recorded for the baseline. This is the reference against which the fix was measured.

| Scenario | Status | Evidence |
|---|---|---|
| Process launch | **PASS** | `run-01`, `run-02` |
| Anti-hook check | **FAIL** | `run-06` — `Timer-API hook was detected.(01ff)` at T+9.6 s |
| Survives 10 s | **FAIL** | `run-04` — dialog at T+10.2 s; clean exit |
| Crash dump / WER report | **N/A** | No WER report in 120 days — the process exits cleanly, it does not crash (`windows-events.txt`) |
| Gameplay | **FAIL (blocked)** | Cannot be reached; game terminates first |

---

## 3. Linux

**No Linux system was available. Nothing was executed.**

| Scenario | Status |
|---|---|
| Startup under Wine | **NOT TESTED** |
| Main menu | **NOT TESTED** |
| Graphics initialisation (DXVK) | **NOT TESTED** |
| D3DX effect compilation | **NOT TESTED** |
| Audio — SFX (FAudio) | **NOT TESTED** |
| Audio — MP3 (quartz/MCI) | **NOT TESTED** |
| Audio — MIDI (DirectMusic) | **NOT TESTED** |
| Input — keyboard | **NOT TESTED** |
| Input — controller | **NOT TESTED** |
| Network mode (DirectPlay 8) | **NOT TESTED** — expected **BLOCKED** (Wine does not implement DirectPlay 8) |
| Filesystem / case sensitivity | **INVESTIGATING** — 12 case mismatches proven statically (`run-29`); consequence untested. `Shaft.bsp`/`.wad` is the biggest risk. |
| Shutdown | **NOT TESTED** |
| Reproducible prefix script | **NOT TESTED** |

Wine version, Proton version, graphics layer, audio backend, driver: **undetermined**.

### Why nothing is PASS or FAIL here

There is no Linux host available to this session: WSL contains only a `docker-desktop` distro
with the Docker daemon stopped, there are no Hyper-V VMs, and no Linux image is present.
WSL2's Vulkan is `dzn` (Vulkan-on-D3D12), not a real Vulkan driver, so Wine+DXVK there would
not represent Linux — producing a result that *looks* like evidence without being evidence.

**The case-sensitivity row is the exception** because it was answerable statically: 645 literal
asset references from the binary were resolved case-sensitively against 1595 files on disk, and
12 differ by case only. The *risk* is proven; the *consequence* (crash vs. degrade vs. fallback)
still requires execution.

---

## 4. macOS

**No macOS system was available. Nothing was executed.**

| Scenario | Intel | Apple Silicon |
|---|---|---|
| Startup | **NOT TESTED** | **NOT TESTED** |
| Main menu | **NOT TESTED** | **NOT TESTED** |
| Graphics initialisation | **NOT TESTED** | **NOT TESTED** |
| D3DX effect compilation | **NOT TESTED** | **NOT TESTED** |
| Audio — SFX | **NOT TESTED** | **NOT TESTED** |
| Audio — MP3 / MIDI | **NOT TESTED** | **NOT TESTED** |
| Input — keyboard / controller | **NOT TESTED** | **NOT TESTED** |
| Network mode | **NOT TESTED** — expected **BLOCKED** | **NOT TESTED** — expected **BLOCKED** |
| Shutdown | **NOT TESTED** | **NOT TESTED** |

Compatibility layer, version, graphics backend, audio/input backend: **undetermined**.

Structural note, verified by platform documentation rather than execution: **32-bit x86
cannot run on macOS 10.15+**, and **Rosetta 2 does not translate 32-bit code**. Any macOS
route must therefore rely on Wine's own WoW64 support, not on the OS.

---

## 5. Cross-platform blocker register

Ranked by how much of the project they threaten.

| # | Blocker | Class | Windows 11 | Linux | macOS |
|---|---|---|---|---|---|
| 1 | `winmm!timeGetTime` fingerprint | **VERIFIED** | **FIXED** (1-byte patch) | unknown — depends on Wine's `winmm` | unknown — same |
| 2 | Runtime D3DX9 effect compiler | **VERIFIED** | works (native D3DX) | **at risk** | **at risk** |
| 3 | DirectPlay 8 | **VERIFIED import** | available but untested | expected **BLOCKED** | expected **BLOCKED** |
| 4 | `ProductId` registry read | **VERIFIED** | cosmetic FAIL | unknown | unknown |
| 5 | `1033.ini` absent | **VERIFIED** | unknown | unknown | unknown |
| 6 | DirectShow/MCI MP3 | **VERIFIED runtime** | works (verified load) | at risk | at risk |
| 7 | DirectMusic MIDI | **VERIFIED runtime** | works (verified load) | at risk | at risk |
| 8 | IME / `MS Gothic` font | **VERIFIED import** | works | at risk | at risk |
| 9 | Case sensitivity | **VERIFIED risk** | n/a | **12 proven mismatches** (`run-29`); consequence untested | at risk — same audit needed on APFS |
| 10 | 32-bit on modern macOS | **VERIFIED (platform)** | n/a | n/a | hard constraint |
| 11 | Five undeclared mech mesh sets (Joker, Kaede, Maikaze, Siegfried + 1) | **VERIFIED content gap** | same everywhere — **not a porting defect** | same | same |

---

## 6. What would move this matrix

In dependency order. Each unlocks the next.

1. **W-1: prove interactivity.** Post input to the `UDX_CLASS` window and diff consecutive
   frames. Until this passes, "main menu" stays NOT TESTED and no other platform can be
   meaningfully compared.
2. **W-3: enter a match.** This is the first test that exercises the D3DX runtime compiler —
   the single biggest cross-platform risk.
3. **W-4: audio.** All three paths are loaded but unheard.
4. **W-6: controller.**
5. **W-7: network.** Expected to fail even on Windows.
6. Then, and only then, **L-1 → L-3** on Linux.
7. macOS last.

Attempting Linux or macOS before step 2 means debugging translation layers against an
unverified reference. That is the most expensive available mistake.
