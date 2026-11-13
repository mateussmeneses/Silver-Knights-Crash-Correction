# Silver Knights 0.13 — Architecture

Derived from the shipped binaries. Where a claim is inferred rather than read
directly from the artifact it is marked. See `docs/BINARY-ANALYSIS.md` for the
raw evidence and reproduction commands.

---

## 1. What this software is

A 32-bit Windows native game, built 2003–2012, last modified **2012-07-29**.
There is **no source code** in the repository and no evidence one was ever
published. The deliverable is therefore a **binary** and all engineering must
proceed from static and dynamic analysis of that binary.

| Fact | Value |
|---|---|
| Title | Silver Knights |
| Version | 0.13 ("The Trial-Production Version") |
| Author | Haruo Teshima (TESHIMA); art by Moongate; audio by Kei Tokusa; anim by EOS |
| Last build | 2012-07-29 (PE timestamp of `SK-Main.exe` / `SK-Startup.exe`) |
| Platform target | Windows 2000/2003/XP/Vista (per `ReadMe-English.txt`) |
| Architecture | 32-bit x86, PE32, GUI subsystem |
| Toolchain era | Linker 6.0 image, VC7.1 (`msvcr71` 7.10.3052.4) runtime |
| Packaging | UPX-compressed main and launcher executables |
| Source availability | **None** |

---

## 2. Process architecture

Two executables cooperate. They are not independent programs.

```
  ┌────────────────────────────┐          ┌───────────────────────────────┐
  │  SK-Startup.exe            │          │  SK-Main.exe                  │
  │  (launcher / front-end)    │          │  (game / renderer)            │
  ├────────────────────────────┤          ├───────────────────────────────┤
  │ • reads ProductId from     │          │ • creates UDX_CLASS window    │
  │   HKLM\...\CurrentVersion  │          │ • D3D9 device + D3DX effects  │
  │ • derives UserID           │          │ • DirectSound8 + MCI/DirectShow│
  │ • enumerates processes     │          │ • DirectInput8                │
  │   (NTVDM/VDMDBG/PSAPI)     │          │ • DirectPlay8 (network)       │
  │ • verifies SK-Main.exe     │          │ • anti-debug / anti-hook      │
  │   size + MD5               │          │ • writes SilverKnights.log    │
  │ • presents resolution dialog│         │ • mailslot IPC peer           │
  │ • spawns SK-Main.exe       │◄────────►│                               │
  └────────────────────────────┘ mailslot └───────────────────────────────┘
              │                                      │
              └────────── SKGuard.dll ───────────────┘
                   global WH_GETMESSAGE hook
```

### 2.1 `SK-Startup.exe`

Responsibilities, all **VERIFIED** from imports and strings:

1. `GetVersionExA` — OS version gate.
2. `RegOpenKeyExA` / `RegQueryValueExA` / `RegCloseKey` on
   `SOFTWARE\Microsoft\Windows\CurrentVersion` for `ProductId`
   (string `ProductId` @ `0x1217c`). **This value no longer exists on Windows 11.**
3. `CreateToolhelp32Snapshot` + `Process32First/Next`, `EnumProcesses`,
   `EnumProcessModules`, `GetModuleBaseNameA`, plus `VDMDBG.DLL` /
   `VDMEnumTaskWOWEx` and a check for `NTVDM.EXE` — a 16-bit-process /
   debugger-enumeration check.
4. `CreateMailslotA` + `\\%s\mailslot\%s` — establishes the IPC endpoint.
5. `CreateProcessA` to spawn `SK-Main.exe`.
6. Integrity verification: `SK-Main.exe` **size** (`0x12554` = 1,464,320) and
   **MD5** (`0x12558` = `84a321d3035de0e2f03539123667f3d6`).
7. UI: a `#32770` dialog titled `SK Startup - Version 0.13` with buttons
   `Full Screen`, `Window`, `Scene Editor`, `Resolution1/4`, and a `UserID`
   static field.
8. Command-line switches it recognises (**VERIFIED** strings):
   `-quarter`, `-640`, `-800`, `-1024`, `-1152`, `-1280`, `-full`, `-scedit`, `-dbf`.

`SK-Startup.exe` also writes `debug.txt` (string @ `0x12768`).

### 2.2 `SK-Main.exe`

The game. 225 imported symbols across 14 DLLs. Responsibilities:

- **Windowing:** `RegisterClassExA`/`CreateWindowExA`/`PeekMessageA`. Window class
  is **`UDX_CLASS`** (**VERIFIED** by runtime window enumeration, run-15).
- **Rendering:** `Direct3DCreate9` → D3D9 device. Ships a statically linked
  **D3DX9 effect compiler** and compiles shaders at runtime from source.
  Effect/technique names present: `Technique_OnlyHDR`, `Technique_GausForBlur4x4`,
  `Technique_2_5DAndHDRAndSpeed`, `Technique_Specular`, `Technique_CreateVMap`, …
- **Post-processing:** HDR, bloom, depth-of-field, 2.5D blur, motion blur,
  outline/edge, colour grading — all switchable through the INI.
- **Audio:** `DirectSoundCreate8` (imported by **ordinal 11**), `mciSendStringA`
  for MP3/MIDI, `mmio*` for WAV. Creates a **DirectShow** `FilterGraphWindow`
  (`ActiveMovie Window`) for MPEG audio (**VERIFIED** at runtime, run-15).
- **Input:** `DirectInput8Create`.
- **Network:** `IDirectPlay8Peer/Server/Client`, plus `InternetOpenUrlA`/`InternetReadFile`
  against a CGI scoreboard (`%sIpManage2.cgi?`, `%sUpdateScore2.cgi?`).
- **Persistence:** `SilverKnights.ini`, `%d.ini`, `SilverKnights.log`, `temp\user%d.bmp`,
  `replay\sk-%02d.rep`.
- **Anti-tamper:** anti-debugger, anti-hook, anti-debugger-device checks (see below).

### 2.3 `SKGuard.dll`

A 32-bit DLL exporting `_API_Hook_AllApps_Start@4` and `_API_Hook_AllApps_Stop@0`.
It installs a **global `WH_GETMESSAGE` Windows hook** (`SetWindowsHookExA` with
`idHook = 3`) using its own module handle. Because it is a global hook, the DLL is
mapped into every message-pumping process on the desktop, not only the game.
**VERIFIED** by disassembly of `_API_Hook_AllApps_Start@4` at RVA `0x1120`.

The DLL also contains a full statically linked MSVCRT. It is called by `SK-Main.exe`
via its two exports at startup and shutdown.

---

## 3. Rendering architecture

```
  INI [ENVIRONMENT]
        │
        ▼
  D3D9 device  ──► render targets: g_TargetBloomA/B, g_TargetSpeedMap,
        │                          g_TargetDepthOfField, g_TargetBlurBloom,
        │                          g_TargetEdge, g_TargetGaus, g_DispTarget
        ▼
  D3DX9 effect compiler (embedded) ──► technique selection
        │        Technique_OnlyHDR / _OnlyEdge / _OnlyBlur / _Only2_5D /
        │        _DownSample / _Gaus / _GausForBlur4x4 / _2Render / _CreateVMap
        ▼
  scene: .bsp + .wad  +  mesh\*.x (DirectX .x models)  +  png\*.png / bmp
```

**Verified graphics facts:**

- API is **Direct3D 9** (`d3d9.dll` → `Direct3DCreate9`). Not D3D8, not DXGI.
- Models are **DirectX `.x`** files — the binary embeds the `.x` text-format
  templates (`xof 0303txt 0032`, `XSkinMeshHeader`, `SkinWeights`, …).
- Levels are **Quake-lineage BSP + WAD** (`bsp/*.bsp`, `bsp/*.wad`), with
  entity strings such as `"classname" "player_start"`, `"classname" "light"`,
  `"classname" "func_water"`, `"classname" "tree"`.
- Shaders are **compiled at runtime by the embedded D3DX compiler**. There is no
  precompiled shader cache on disk.

That last point dominates every porting decision: a compatibility layer must
provide a functioning D3DX9 effect compiler, not merely a D3D9 device. This is a
materially harder requirement than for a title that ships precompiled shaders
(**INFERRED** from the verified strings and the absence of any shader cache on disk).

---

## 4. Audio architecture

Three parallel paths, all **VERIFIED** by imports and strings:

| Path | API | Used for |
|---|---|---|
| Sampled effects | **DirectSound 8** (`DirectSoundCreate8`, ordinal import) | `se\*.wav` — 60+ named effects |
| Music | **MCI** (`mciSendStringA`: `open %s type MPEGVideo`, `play`, `setaudio … volume`) | `mp3\*.mp3` |
| Music (alt) | **MIDI** via MCI | `midi\*.mid` |

At runtime a DirectShow `FilterGraphWindow` class window titled `ActiveMovie Window`
is created (**VERIFIED**, run-15), i.e. MP3 playback goes through DirectShow's MPEG
audio filter graph. That is a legacy codec dependency worth flagging for Linux/macOS.

Volume is controlled by `BGM_VOLUME` in `SilverKnights.ini` (shipped value `500`).

---

## 5. Network architecture

Two unrelated mechanisms:

1. **Gameplay:** Microsoft **DirectPlay 8** — `IDirectPlay8Peer`, `…Server`, `…Client`.
   Modes exposed in the UI strings: `PeerToPeer`, `Serv/Cliant` (sic).
   Ports documented in `ReadMe-English.txt`: **UDP 6073**, **TCP/UDP 2300–2400**,
   **TCP 80** (web).
2. **Lobby / scoreboard:** plain **HTTP CGI** over `InternetOpenUrlA`. Endpoints are
   built from `CGI_URL` in the active language INI
   (`1041.ini` → `http://philo.rosx.net/cgi-bin/`) with paths
   `%sIpManage2.cgi?`, `%sUpdateScore2.cgi?`.

DirectPlay 8 is a **deprecated** Windows component, shipped only as an optional legacy
feature. The assumption that it is simply missing from Windows 11 turned out to be wrong
for this install: `run-37` verified that **all the 32-bit DirectPlay binaries are present
in `SysWOW64`** (`dpnet.dll`, `dplayx.dll`, `dpwsockx.dll`, `dpnaddr.dll`, `dplaysvr.exe`,
`dpnsvr.exe`). Whether the optional feature is formally enabled could not be queried —
`Get-WindowsOptionalFeature` requires elevation.

**However, DirectPlay was never actually loaded.** Entering Network Mode reaches a
player-name entry screen, and the process stops there: no `dpnet.dll`, `dplayx.dll` or
even `ws2_32.dll` appears in the module list. So the transport layer is **completely
untested** on Windows 11 — the binaries exist, but nothing has exercised them.

Status: **BLOCKED at name entry.** The field did not accept automated input by either
`SendInput` scancodes or `PostMessage(WM_CHAR)`, so the flow could not be advanced. The
binary imports no message-based text helpers (`GetKeyboardState`, `ToAscii`, `ToUnicode`,
`MapVirtualKey`, `GetAsyncKeyState`), which suggests the field is rendered by the game and
fed from its own DirectInput poll (**INFERRED**).

This remains the largest risk to the "preserve network functionality" objective, and it is
now a *proven unknown* rather than an assumption in either direction.

The CGI host `philo.rosx.net` is a 2000s-era community server. Whether it still
resolves or responds was **NOT TESTED**; the game is expected to degrade gracefully
when it does not (**HYPOTHESIS**).

`RC4` / `RC4_set_key` are the only crypto symbols `SK-Main.exe` imports from
`libeay32.dll` (OpenSSL 0.9.8a). Their purpose was **not determined**.

---

## 6. Configuration architecture

Three layers:

1. **`SilverKnights.ini`** — engine/gameplay settings. `[ENVIRONMENT]`, `[MESSAGE]`,
   `[KEYBOARD]`, `[JOYSTICK]`, `[COLOR]`, plus per-character `[PHILOTES]`…`[KAGEROU]`
   colour blocks. Read with `GetPrivateProfileStringA`, written with
   `WritePrivateProfileStringA`.
2. **`%d.ini`** — localisation, chosen by the OS language code. Contains `[URL]`
   (`CGI_URL`), `[FONT]` (`FONT_NAME`), `[KNIGHTS_NAME]` (`K%02d`). Only `1041.ini`
   (Japanese) ships. `1033.ini` (English) is **absent**.
3. **`Scene.ini` / `.\original.ini`** — scene-editor data.

Any port must keep this contract byte-compatible; these files are user data and
**must not be rewritten**.

---

## 7. Anti-tamper architecture

Three cooperating mechanisms. All **VERIFIED**.

| Mechanism | Location | Behaviour |
|---|---|---|
| Timer-API fingerprint | `SK-Main.exe` RVA `0x1f4ee0` | Reads 20 bytes of `winmm!timeGetTime`, compares against a hard-coded Win9x prologue. |
| Anti-debugger | `SK-Main.exe` RVA `0x1f4960`+ | `IsDebuggerPresent`, `FindWindowA("OLLYDBG")`, opens `\\.\NTICE`, `\\.\SICE`, `\\.\TRW`, `\\.\REGMON`, `\\.\FILEMON`, `\\.\REGVXD`, `\\.\FILEVXD`. |
| Anti-hook (thread context) | `SK-Main.exe` RVA `0x1f4c65`+ | Resolves `GetThreadContext` / `SetThreadContext` and inspects the copied `CONTEXT` fields against range limits (`0x10000` … `0x3f000000`). |
| Global API hook | `SKGuard.dll` RVA `0x1120` | Installs `WH_GETMESSAGE` system-wide. |

Verdicts are collected into a global flag at `0x21428a4`; a positive verdict
formats `Illegal access was detected.(%s)`, `Timer-API hook was detected.(%04x)` or
`Debugger process was detected.(%d)` and calls the shutdown path at `0x5fd640`.

**The timer fingerprint is the cause of the Windows 11 failure.** Full analysis in
`docs/CRASH-ANALYSIS.md`.

This architecture is inseparable from the gameplay code path — it runs on a timer
during normal play, not only at startup. Any port must remove or neutralise it
deliberately rather than work around it.

---

## 8. Data layout

| Path | Size | Contents |
|---|---|---|
| `bsp/` | 85 MB | ~40 `.bsp` maps + matching `.wad` texture archives, plus `bsp/data/` shared skyboxes, sea/sky `.x` models, `light.png`, `limit.png` |
| `mesh/` | 4.2 MB | DirectX `.x` character and mech models |
| `mp3/` | 17 MB | Music |
| `png/` | 5.0 MB | UI art, `black.bmp`, `EnvMap.png`, `question.png`, mech portraits |
| `se/` | 1.3 MB | `.wav` effects |
| `logo/` | 492 KB | `.bmp` logos |
| `midi/` | 284 KB | `.mid` music |
| `replay/`, `temp/` | ~1 KB | Runtime scratch (contain only `dummy.txt`) |
| **Total** | **~287 MB** | Whole repository working tree |

File-count: **1170 tracked files**.

---

## 9. Portability assessment

Ranked by difficulty, based **only** on verified facts.

### Hard blockers

1. **Runtime D3DX9 effect compilation.** A port cannot simply forward D3D9 calls;
   it must supply a working HLSL/effect compiler matching D3DX9 semantics.
   This is the dominant cost.
2. **DirectPlay 8.** Deprecated; no modern equivalent with the same peer/server
   object model. Network mode likely requires a replacement transport, which is
   new engineering, not a shim.
3. **Anti-tamper.** Must be neutralised (and the neutralisation documented).

### Moderate

4. **DirectShow MPEG audio** for MP3 playback.
5. **MCI** for MIDI.
6. **DirectInput 8** with a fixed 8+ button joystick assumption.
7. **ANSI Win32 + IME** (`ImmGetContext`) for Japanese text input.

### Low

8. **Filesystem:** relative paths, ANSI filenames, case-insensitive assumptions.
   Only real portability issue is case sensitivity on Linux/macOS.
9. **DirectSound 8** — well supported by Wine/Proton.

### Platform matrix implication

- **Windows 11:** reachable today with a small binary patch (proven). Remaining work
  is verification, not discovery.
- **Linux:** the D3D9 subset maps onto **DXVK**. The blockers are the **embedded D3DX
  effect compiler** (DXVK does not implement `d3dx9`), **DirectPlay 8**, and
  **DirectShow MPEG**. DXVK alone is therefore **not** sufficient.
- **macOS:** the same D3D9→Vulkan path applies, and then **Vulkan→Metal** via
  MoltenVK. Apple Silicon adds an x86→ARM translation layer (Rosetta 2 for Intel
  binaries). This stacks *two* translation layers plus an ISA translator before
  reaching the D3DX and DirectPlay blockers. **DXVK does not run natively on macOS**;
  any claim otherwise must be rejected until demonstrated.

Detailed strategy comparison: `docs/ROADMAP.md` §4.
