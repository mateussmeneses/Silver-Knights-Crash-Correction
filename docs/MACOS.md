# Silver Knights 0.13 — macOS

**Status: NOT TESTED.** No macOS hardware was available in this session. Nothing here is a
compatibility claim. It is a feasibility assessment built from the verified facts in
`docs/BINARY-ANALYSIS.md` and `docs/ARCHITECTURE.md`.

Hardware-specific questions (Intel vs Apple Silicon) are marked as needing a specific
machine. They cannot be answered by reasoning alone.

---

## 1. The fundamental problem: translation depth

The game is a **32-bit x86 Windows PE**. Reaching a native macOS process requires
**four** independent translation layers, not one:

```
32-bit x86 PE  ──1──►  x86_64 process     (Wine 32-bit ↔ 64-bit, or a 32-bit-only Wine)
               ──2──►  D3D9 → Vulkan      (DXVK)
               ──3──►  Vulkan → Metal     (MoltenVK)
               ──4──►  Win32 → POSIX      (Wine)
```

On **Apple Silicon** a fifth layer is added: x86_64 → ARM64 (Rosetta 2).

Each layer is a place where correctness can be lost. Compare with the Windows fix, which was
**1 byte**.

### Layer 1 is the first hard problem

Modern macOS (Catalina 10.15 onward) **cannot execute 32-bit x86 binaries at all**. Apple
removed 32-bit support entirely. Consequences:

- Rosetta 2 translates **x86_64 → ARM64**. It does **not** translate 32-bit x86.
- Therefore a 32-bit game **cannot** be run by Rosetta 2 directly. Rosetta 2 is not the
  relevant layer for the guest; it is only relevant for *Wine's own* binaries.
- **INFERRED, and important:** this means the 32-bit guest must be handled *inside* Wine
  (Wine's own 32-bit-on-64-bit support, i.e. a WoW64 build), not by the OS.

This distinction is routinely confused. "Rosetta 2 will run old games" is **false** for
32-bit-only titles. Any plan that assumes otherwise is invalid.

### Layer 3 does not exist on macOS the way it does on Linux

**DXVK does not run natively on macOS.** DXVK targets Vulkan; macOS has no native Vulkan
driver. Vulkan on macOS exists only through **MoltenVK** (Vulkan → Metal). So a D3D9 title on
macOS needs DXVK **on top of** MoltenVK — a double translation — and this is what CrossOver
does internally for some titles.

Claims that DXVK "works on macOS" must be rejected until demonstrated on the specific
hardware. The project rule in the mission statement is explicit on this point.

---

## 2. Verified blocker inventory

Carried over unchanged from the Windows analysis; these do not get easier on macOS.

| # | Blocker | Status | macOS severity |
|---|---|---|---|
| 1 | **Runtime D3DX9 effect compiler** | **VERIFIED present** | **Worst.** D3DX → D3D9 → Vulkan → Metal. CrossOver has partial `d3dx9` support; completeness unknown. |
| 2 | **DirectPlay 8** for gameplay networking | **VERIFIED import** | **Fatal** for network mode. No macOS implementation exists, and Wine does not implement it. |
| 3 | **MCI + DirectShow** MP3 playback | **VERIFIED runtime** (`QUARTZ.dll`, `l3codeca.acm`, `mciqtz32.dll`) | Wine's `quartz` on macOS is weakly tested. Expect silence. |
| 4 | **DirectMusic** MIDI | **VERIFIED runtime** (`dmusic.dll`, `midimap.dll`) | Likely silent. |
| 5 | **IME** for Japanese input | **VERIFIED import** | Wine-on-macOS IME support is limited. |
| 6 | **`1033.ini` missing** | **VERIFIED absent** | Locale lookup may fail → unreadable UI. |
| 7 | **OpenSSL 0.9.8a** shipped | **VERIFIED** | Only `RC4` used; low practical risk but must not be exposed. |
| 8 | **Anti-tamper (timer fingerprint)** | **VERIFIED** | Same defect; requires the patch. |

---

## 3. Route evaluation

### Route A — CrossOver (recommended first attempt)

CrossOver is the commercial Wine distribution with the most work invested specifically in
running 32-bit Windows games on macOS, including on Apple Silicon, and it ships its own
`d3dx9` and graphics translation.

**Why it is first:** it is the only route where all four translation layers are already
assembled and commercially supported.

**How to test:** CrossOver bottle, **Windows 10 64-bit** bottle type (needed for 32-bit
support), install the **patched** `SK-Main.exe` + matching `SK-Startup.exe`, launch
`SK-Startup.exe`.

**Pass criterion:** identical to Linux L-1/L-2/L-3 — a `D3D9` device, rendered title art, and
a scene that compiles its effects.

**Costs:** commercial licence; not open; version pinning is possible but not scriptable the
way Wine on Linux is.

### Route B — Wine via Homebrew / MacPorts

Possible but weakly supported for 32-bit games on modern macOS. Wine's own macOS builds have
had repeated regressions around 32-bit support and MoltenVK. Requires manually assembling
DXVK + MoltenVK + a `d3dx9` source.

**Why it is second:** the assembly work is significant and the support surface is thin.
Worth attempting only if Route A fails and the failure is *not* the D3DX compiler.

### Route C — Whisky / Game Porting Toolkit (Apple Silicon only)

Apple's **Game Porting Toolkit** is a D3D→Metal translation layer derived from CrossOver
technology, aimed at developers evaluating Windows games. It is explicitly a *development*
tool, not a distribution mechanism, and Apple's licence terms constrain redistribution.

**Status: NOT EVALUATED.** Whether GPTK's D3D9 and D3DX coverage is sufficient for this
title is unknown. It is worth a timeboxed experiment on Apple Silicon, with the explicit
understanding that it is not a legitimate distribution path for a preserved game.

### Route D — Full native reconstruction

Would require reimplementing the engine (BSP renderer, D3DX effect system, DirectPlay
transport) from binary analysis. For a 287 MB title with no source, this is a multi-year
effort and is **not recommended** (see `docs/ROADMAP.md` §4, strategy C).

### Route E — Static recompilation

Not applicable in the usual sense. Static recompilers (N64Recomp, XenonRecomp, …) translate a
*console* ISA to a host ISA. This game is already **x86**, so there is no ISA translation to
perform — the work is Win32 → POSIX and D3D9 → Metal, which is exactly what Wine does. A
static-recompilation track adds nothing here.

This is a place where a generic playbook would produce a wrong answer; the AI-Workbench
game-porting catalog correctly routes an x86 Windows PE to *triage*, not to static
recompilation.

---

## 4. Architecture-specific questions

These **cannot** be answered without the respective hardware. They are listed so the
experiment is well-defined when hardware is available.

### Intel Mac (x86_64)

- **Layer 5 is absent** (no Rosetta needed for a 64-bit host process).
- The 32-bit guest still cannot run natively (Apple removed 32-bit), so Wine's WoW64 is
  still required.
- GPU will be **Intel Iris/UHD** or **AMD**. Metal feature support and driver quality vary
  substantially by model. MoltenVK on Intel GPUs is the weakest combination for
  post-processing-heavy titles.
- Last macOS able to run Intel binaries: macOS Sonoma era. Newer releases deprecate Intel.

**Question to answer:** does the D3DX effect compiler produce working Metal shaders on this
GPU? **UNKNOWN.**

### Apple Silicon (arm64)

- **Layer 5 present**: Wine's x86_64 components run under Rosetta 2.
- `nvgpucomp32`-style vendor driver shims do not exist; the whole graphics stack is
  MoltenVK → Metal on Apple GPU.
- Memory model and shader precision differences can surface as visual artifacts in
  post-processing (HDR, bloom, depth-of-field) — exactly the features this game uses heavily.
- The game's `SCOPE_NEAR=0.03` / `SCOPE_FAR=0.001` inverted-looking depth range is a
  precision-sensitive configuration; watch for z-fighting.

**Question to answer:** does Rosetta 2 + Wine + DXVK + MoltenVK produce correct output for
this title? **UNKNOWN.** Rosetta 2 does not translate 32-bit code, so this only works if
Wine's WoW64 path is functioning.

### Both

- **Packaging and signing:** a `.app` bundle wrapping the Wine prefix would need
  codesigning and notarisation for distribution. Hardened Runtime and the
  `com.apple.security.cs.allow-jit` / `allow-unsigned-executable-memory` entitlements are
  typically required for Wine. This is a real, non-trivial distribution cost.
- **The title's own licence forbids distribution.** `ReadMe-English.txt` lines 20–29 state
  the software is still under development and must not be distributed or uploaded. Any macOS
  packaging must therefore be **personal-use only** and must not be published. This is a
  legal constraint on the whole project, not a macOS-specific one.

---

## 5. Status ledger

| Scenario | Intel Mac | Apple Silicon |
|---|---|---|
| Startup (patched build) | **NOT TESTED** | **NOT TESTED** |
| Main menu | **NOT TESTED** | **NOT TESTED** |
| Graphics initialisation (D3D9→Vulkan→Metal) | **NOT TESTED** | **NOT TESTED** |
| D3DX effect compilation | **NOT TESTED** | **NOT TESTED** |
| Audio (SFX / MP3 / MIDI) | **NOT TESTED** | **NOT TESTED** |
| Input (keyboard / gamepad) | **NOT TESTED** | **NOT TESTED** |
| Network mode | **NOT TESTED** (expected FAIL) | **NOT TESTED** (expected FAIL) |
| Shutdown | **NOT TESTED** | **NOT TESTED** |

Compatibility layer version, graphics backend, and audio/input backend are all
**undetermined** because no layer has been installed.

---

## 6. Recommendation

1. **Do not start macOS work yet.** The Windows baseline is not finished: gameplay, audio,
   and network are all unverified there (see `docs/COMPATIBILITY-MATRIX.md`). Debugging four
   translation layers simultaneously against an unverified reference is the single most
   expensive mistake available.
2. When macOS work begins, start with **Route A (CrossOver)** on **Apple Silicon**, because
   that is where the vendor investment and the user base are, and it is the route where all
   layers already exist.
3. **Expect network mode to be impossible** on every macOS route. Plan for single-player and
   local play only, and record that as a scoped limitation rather than a bug.
4. Treat any "it runs" report as unverified until a `.bsp` scene renders with its
   post-processing effects intact. The title screen proves almost nothing.
