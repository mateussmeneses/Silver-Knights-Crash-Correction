# Silver Knights 0.13 — Linux

**Status: NOT TESTED.**

No Linux execution has been performed. Nothing in this document is a claim of
compatibility. It is a *porting assessment* derived from the verified binary facts in
`docs/BINARY-ANALYSIS.md` and `docs/ARCHITECTURE.md`.

Per project rules, this platform must not be labelled compatible without recorded
execution evidence, and no such evidence exists yet.

---

## 1. What the target actually requires

From verified imports and runtime observation:

| Subsystem | Requirement | Notes |
|---|---|---|
| Graphics | **Direct3D 9** (`Direct3DCreate9`) | DXVK covers this API surface |
| Shaders | **Runtime D3DX9 effect compiler** | Embedded in the binary; **not** covered by DXVK |
| Audio (SFX) | **DirectSound 8** (`DirectSoundCreate8` by ordinal) | Wine/FAudio covers this |
| Audio (music) | **MCI + DirectShow** MPEG, and **DirectMusic** MIDI | Legacy; needs verification |
| Input | **DirectInput 8** | Wine covers this; 8-button joystick assumption |
| Network (game) | **DirectPlay 8** (`IDirectPlay8Peer/Server/Client`) | Deprecated; **not** provided by Wine |
| Network (lobby) | `WININET` HTTP to a dead 2000s CGI host | Degrades or hangs; unverified |
| Text input | **IME** (`ImmGetContext`) | Japanese input via Wine IME |
| Filesystem | Relative paths, ANSI names, case-insensitive | Case sensitivity is a real risk |
| Process model | `SK-Startup.exe` → mailslot → `SK-Main.exe` | Wine implements mailslots |

### The decisive constraint

**The embedded D3DX9 effect compiler is the dominant blocker.** The game does not ship
precompiled shaders; it compiles effect/HLSL source at runtime through the D3DX library
that is statically linked into `SK-Main.exe`. Wine's `d3dx9` implementation is incomplete,
and DXVK deliberately does **not** implement `d3dx9` (it implements `d3d9`, `d3d10`,
`d3d11`, `dxgi`). A working runtime path therefore needs *both* DXVK *and* a functional
`d3dx9` — either Wine's builtin, a native Microsoft `d3dx9_*.dll`, or a shim.

This is a materially harder requirement than for a D3D9 title with precompiled shaders,
and it must be the first thing tested on Linux. If the D3DX effect compilation path fails,
no amount of D3D9 translation helps. **HYPOTHESIS — untested.**

---

## 2. Prerequisite: the Windows fix must ship first

The Linux path has the same Windows defect. Anything that runs `SK-Main.exe` — Wine,
Proton, a VM — inherits it:

- Wine's builtin `winmm` exports `timeGetTime` as a normal function, not as a `jmp [IAT]`
  thunk.
- The game fingerprints the first 20 bytes of whatever `timeGetTime` resolves to.

Therefore **the Wine result depends entirely on which `winmm` implementation is loaded, and
on its exact machine code.** It is entirely possible that a particular Wine build happens to
match the Win9x prologue by luck, which would make the game "work on Linux but not
Windows" — the classic false-positive that must not be mistaken for Linux compatibility.

**Mandatory: use the patched `SK-Main.exe` (`RVA 0x1f4d50`, `7E`→`EB`) for all Linux
testing.** Otherwise results are not comparable to the Windows baseline.

Note also that the patch must be paired with a `SK-Startup.exe` whose integrity constants
match, per `docs/WINDOWS-11.md` §4.2. Running `SK-Main.exe` directly is unproven and
previously produced a silent exit.

---

## 3. Investigative plan (ordered, cheapest first)

Each step has a concrete pass criterion so the result is a fact, not an impression.

### L-1 — Does it launch under Wine at all?

```bash
# isolated prefix; do not touch the user's default prefix
export WINEPREFIX="$HOME/.local/share/silver-knights/prefix-wine-test"
export WINEARCH=win32
wineboot -i
cd /path/to/sandbox        # contains the PATCHED SK-Main.exe + matching SK-Startup.exe
wine SK-Startup.exe
```

**Pass:** `SK-Main.exe Start` appears in `SilverKnights.log` and the process survives 60 s.
**Fail:** any `Timer-API hook` dialog (means the wrong `winmm` was loaded), or an
immediate exit.

Record: `wine --version`, distro, kernel, GPU, driver, `WINEPREFIX` path.

### L-2 — Does D3D9 initialise?

Run with DXVK and capture the DXVK HUD:

```bash
export DXVK_HUD=devinfo,fps,frametimes,api
export DXVK_LOG_LEVEL=info
export DXVK_LOG_PATH="$HOME/.local/share/silver-knights/dxvk-logs"
wine SK-Startup.exe
```

**Pass:** a `D3D9` device is created and the title art renders.
**Fail:** a DXVK error log naming the failing call.

Note: the game window class is `UDX_CLASS` and at `RESOLUTION=4` it is 646×509. Use that
to confirm you are looking at the right window.

### L-3 — Does the D3DX effect compiler work? **This is the critical test.**

The moment the game leaves the title screen and enters a scene, it compiles effects. Watch
for DXVK or Wine logging a failed `D3DXCreateEffect*` / shader compile.

**Pass:** a `.bsp` map renders with its shaders.
**Fail:** black scene, missing post-processing, or a crash at scene load.

If this fails, the options are: install a native Microsoft `d3dx9_43.dll` (via `winetricks
d3dx9`), or supply an alternative. Note that `winetricks d3dx9` pulls Microsoft binaries —
that has licensing implications for anything distributed and must be an explicit,
documented user choice, never bundled.

### L-4 — Audio

Check all three paths independently:

- `DSOUND.dll` → FAudio or Wine's builtin. Confirm SFX.
- MCI/DirectShow MP3 via `mciqtz32.dll` → Wine's `quartz`. Confirm BGM.
- DirectMusic MIDI via `dmusic.dll`/`midimap.dll` → confirm or accept silence.

**Pass:** SFX and BGM both audible. Set `BGM_VOLUME=500` (the shipped value) and confirm
the volume slider in-game matches.

### L-5 — Input

DirectInput 8 with an 8+ button assumption. Test keyboard, then a real gamepad.
**Pass:** movement, fire, guard, boost, lock all respond per `ReadMe-English.txt` §Default
Game Controls.

### L-6 — Filesystem / case sensitivity

The engine opens `bsp\`, `mesh\`, `png\`, `logo\`, `se\`, `midi\`, `mp3\` as literal
lowercase relative paths, and also references `SKY16.bmp`, `INFINITY_OF_BASE_A.png`,
`AUDIOSES`-style mixed-case names. On a case-sensitive filesystem a mismatch is fatal.

Test on a case-**sensitive** filesystem (ext4 is fine; btrfs with `casefold` is not a valid
test). Then check:

```bash
# find assets referenced in mixed case that exist only in one casing
grep -ri "\.bmp\|\.png\|\.wav\|\.x\b" --include=*.ini . | head
```

**Pass:** all referenced assets resolve. If not, record every miss — a case-insensitive
mount (`ciopfs`, or a `vfat`/`ntfs` loopback) is an acceptable documented workaround for
preservation purposes, but it must be stated, not hidden.

### L-7 — Network mode

**Expected to fail.** `DirectPlay 8` is not implemented by Wine. Confirm empirically
rather than assuming, and record the exact failure point (does the game hang, crash, or
report an error?).

If network mode is a hard requirement, the realistic options are out of scope for a
compatibility layer and belong to the hybrid/native strategy discussion in
`docs/ROADMAP.md` §4.

### L-8 — Reproducibility

Pin everything:

- Wine version (exact),
- DXVK version (exact),
- `winetricks` verbs used (exact),
- GPU + driver version,
- distro + kernel.

A shell script that recreates the prefix from scratch must be committed. Nothing about the
result is credible without it.

---

## 4. Tooling comparison (for planning, not yet validated)

| Route | Strengths | Weaknesses for *this* title |
|---|---|---|
| **Wine** (vanilla) | Direct control, scriptable, easy to pin | Manual DXVK setup; `d3dx9` gap must be solved by hand |
| **Proton** (Steam) | Best-tuned Wine + DXVK + FAudio, ships `d3dx9` via its bundled libraries | Tied to Steam's update cadence; harder to pin a version for a plain executable |
| **Lutris** | Reproducible YAML recipes, version pinning, wrapper management | A thin orchestration layer; inherits Wine's limitations |
| **Bottles** | Flatpak-sandboxed prefixes, per-bottle config, easy rollback | Sandbox can complicate file access; Flatpak runtime versioning adds a variable |

**Initial recommendation: vanilla Wine + DXVK + FAudio, driven by a committed script**, because
it is the most pinnable and the most auditable. Proton is the fallback if its bundled
`d3dx9` turns out to be the only working one.

**Do not select a route before L-1 through L-3 have been run.** The choice hinges on which
`d3dx9` actually compiles the game's effects, and that is an empirical question.

### Graphics translation layer notes

- **DXVK** — D3D9/10/11 → Vulkan. The correct choice here (API is D3D9).
- **D8VK** — D3D8 → Vulkan. **Not applicable**: this game imports `d3d9.dll`, not `d3d8.dll`.
  Verified from the unpacked import table. Do not install it.
- **wined3d** — Wine's own D3D implementation (OpenGL-backed). A useful fallback and a
  useful diagnostic comparison against DXVK, but generally slower and less accurate for
  post-processing-heavy titles.

---

## 5. Known risks, ranked

| # | Risk | Class | Impact |
|---|---|---|---|
| 1 | D3DX9 runtime effect compilation fails | **HYPOTHESIS** | Fatal — no scene rendering |
| 2 | Wrong `winmm` prologue trips the anti-hook check | **VERIFIED mechanism** | Fatal — self-termination in 8 s |
| 3 | DirectPlay 8 absent | **INFERRED** | Network mode unusable |
| 4 | Case-sensitivity asset misses | **HYPOTHESIS** | Fatal at load, or missing textures |
| 5 | MCI/DirectShow MP3 silence | **HYPOTHESIS** | Degraded (no music) |
| 6 | DirectMusic MIDI silence | **HYPOTHESIS** | Degraded (no MIDI music) |
| 7 | 8-button joystick mapping | **HYPOTHESIS** | Degraded input |
| 8 | IME/Japanese font (`MS Gothic`) unavailable | **HYPOTHESIS** | Untranslated text or tofu glyphs |
| 9 | `1033.ini` missing → locale fallback undefined | **VERIFIED absent** | Possibly unreadable UI on non-JP locale |

Item 9 deserves emphasis: the repository ships **only** `1041.ini` (Japanese). On a Linux
system with a non-Japanese locale, the game's `%d.ini` lookup for the system language code
has no matching file. What the game does then was **not determined**. This may already be a
visible defect on Windows for non-Japanese users and is not Linux-specific.

---

## 6. Status ledger

| Scenario | Status |
|---|---|
| L-1 Launch under Wine | **NOT TESTED** |
| L-2 D3D9 initialisation | **NOT TESTED** |
| L-3 D3DX effect compilation | **NOT TESTED** |
| L-4 Audio (SFX / MP3 / MIDI) | **NOT TESTED** |
| L-5 Input (keyboard / gamepad) | **NOT TESTED** |
| L-6 Filesystem / case sensitivity | **NOT TESTED** |
| L-7 Network mode | **NOT TESTED** (expected FAIL) |
| L-8 Reproducible prefix script | **NOT TESTED** |

No scenario in this table passed, failed, or was investigated. They are all unstarted.
