# Silver Knights 0.13 — Linux

**Status: NOT TESTED.**

No Linux execution has been performed. Nothing in this document is a claim of
compatibility. It is a *porting assessment* derived from the verified binary facts in
`docs/BINARY-ANALYSIS.md` and `docs/ARCHITECTURE.md`.

Per project rules, this platform must not be labelled compatible without recorded
execution evidence, and no such evidence exists yet.

### Why nothing was executed here

The coordinating machine is Windows 11 with no usable Linux target:

- **WSL** has only a `docker-desktop` distro, and the Docker daemon is stopped.
- **No Hyper-V VMs** exist and no Linux ISO/VHD is present.
- Even if WSL were present, **WSL2's Vulkan is `dzn` (Vulkan-on-D3D12), not a real Vulkan
  driver.** Running Wine+DXVK there would produce evidence that does not represent Linux
  and would be worse than no evidence, because it would look like a result.

Recording "could not test" is the correct outcome. Fabricating a Linux result from a WSL
proxy would violate the mission's evidence rule.

### What *was* determined statically

One concrete Linux defect was found without needing a Linux host: **12 asset references
differ from the on-disk filename only by letter case**, and will not resolve on ext4 or
case-sensitive APFS. See §L-6. That is a proven risk with an unproven consequence.

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
`d3dx9` — either Wine's builtin, a native Microsoft `d3dx_*.dll`, or a shim.

This is a materially harder requirement than for a D3D9 title with precompiled shaders,
and it must be the first thing tested on Linux. If the D3DX effect compilation path fails,
no amount of D3D9 translation helps. **HYPOTHESIS — untested on Linux.**

### What is now established on Windows (relevant to the above)

`run-28` verified on Windows 11 that the high-end effect profiles **compile and run**: four
profiles (`EFFECT_LEVEL` 1 → 3, HDR + depth-of-field, and all effects including 2.5D blur,
outline and motion blur) each reached a live 1280×960 match with **no D3DX compile failure and
no error dialog**, and thread count rose from 33 to 45.

That is a *working baseline*, which is exactly what was missing. It means:

- The shaders are real and they do compile through the embedded D3DX9 compiler on Windows.
- A Linux failure at this stage is therefore a **translation-layer** failure, not a
  misdiagnosis of the game.
- Conversely, a Linux run that renders the *low*-effect path but fails at high effects
  localises the problem precisely to the D3DX shader surface.

Caveat, stated plainly: `run-28` did **not** prove the effects visibly change the image (its
pixel diff was confounded by comparing different gameplay moments). So the Windows reference
is "the shaders compile and the game runs", not "here is the exact expected picture". A
matched-camera reference (T-05c) is still needed before claiming render parity.

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

**This one has already been audited statically, and a real risk was found.** See
`docs/evidence/run-29-case-audit.txt` and `tools/case_audit.py`.

Method: every literal asset filename referenced by `SK-Main.exe` (645 references across
`.x/.bmp/.png/.wav/.mid/.mp3/.ini/.rep/.bsp/.wad`) was resolved case-sensitively against the
1595 files on disk. 553 matched exactly; **12 did not**, differing only by letter case:

| Reference in binary | On disk |
|---|---|
| `blast.x` | `mesh/blast.X` |
| `blast2.x` | `mesh/blast2.X` |
| `bullet.x` | `mesh/icarus/bullet.X`, `mesh/thor/bullet.X` |
| `force.x` | `mesh/force.X` |
| `giga-bazooka.X` | `mesh/giga/giga-bazooka.x` ← **reverse direction** |
| `mist.png` | `png/mist.PNG` |
| `philo-gun-emb.X` | `mesh/philo/philo-gun-emb.x` ← **reverse direction** |
| `philo-option.x` | `mesh/philo/philo-option.X` |
| `shaft.bsp` | `bsp/Shaft.bsp` |
| `shaft.wad` | `bsp/Shaft.wad` |
| `smoke.x` | `mesh/smoke.X` |
| `smoke2.x` | `mesh/smoke2.X` |

The casing direction is **inconsistent**, so a blanket rename in either direction is wrong —
each name has to be decided individually.

`Shaft.bsp` / `Shaft.wad` is the most serious pair: a `.bsp` that fails to open means the map
cannot load at all. The rest are meshes and textures, where failure may be a missing model or
an untextured surface instead of a crash.

**Status: INVESTIGATING.** The risk is proven statically; the *consequence* is not. Whether the
game crashes, degrades, or falls back must be observed on a case-sensitive filesystem. Calling
it FAIL would overclaim; calling it NOT TESTED would understate a proven defect.

**How to test:** run on ext4 (ext4 is fine; btrfs `casefold` is not a valid test), watch for
file-open failures, and check specifically whether `Shaft` loads. Do **not** paper over it with a
case-insensitive mount before recording the native behaviour — the mount is an acceptable
documented workaround for preservation, but only after the failure is characterised.

### A content gap that is NOT a porting defect

The audit also found five character mesh sets referenced by the binary but absent from disk:
`joker` (24 occurrences), `kaede` (22), `maikaze`/`mai1`, and `sieg`. `1041.ini` defines
K01–K16 and a second tier K20–K26 (Siegfried, 楓, 闘龍, 舞風, 不知火, Joker), but only 15 mech
directories ship.

**This is a content gap in the original 0.13 release, not a compatibility bug.** It will behave
identically on every platform. It is recorded here so a future engineer does not misdiagnose
`missing kaede-body.X` as a Linux failure. What the game does when such a knight is selected is
**NOT TESTED**.

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
| 6 | DirectMusic MIDI silence | **HYPOTHESIS — and now less concerning** | Degraded (no MIDI music). **Note:** MIDI is proven working on Windows (`run-52`/`54`/`55`), so this is a Wine-specific risk, not a game defect. Because the game has TWO independent music paths (MP3/DirectShow and MIDI/DirectMusic), a Wine config that breaks one may still have the other — test **both** explicitly rather than assuming music is either working or broken. |
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
