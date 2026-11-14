# Silver Knights 0.13 — Binary Analysis

All statements below are marked with an evidence class:

- **VERIFIED** — read directly from the binary or produced by a recorded command.
- **INFERRED** — follows from verified facts plus documented Windows/PE behaviour.
- **HYPOTHESIS** — plausible, not yet proven. Must not be acted on as fact.

Every offset in this document is reproducible with a command in
`docs/evidence/` and the scripts in `tools/`. No offset or identifier in this
file was guessed.

---

## 1. Reference artifacts (immutable)

Recorded at repository commit `747f22e220bafe93d487161a8c7ab85d09119e31`
(`main`, sole commit, 1170 tracked files).

| File | Size (bytes) | SHA-256 |
|---|---|---|
| `SK-Main.exe` | 1,464,320 | `cd54b002cf465a5fa63c57b9e1d7f5e348dc86ba55304d90ddc88ef03a009bab` |
| `SK-Startup.exe` | 47,616 | `9adb707007c992a6bb75447a090cbbc8a0f4db63e0f2c61f21bd4fba1634f27b` |
| `SKGuard.dll` | 57,344 | `3b9d0346ac6dae3e5b85604f53de5e5231c2792721180003c28b9b6d57e1b576` |
| `libeay32.dll` | 1,028,096 | `015fea5afd56a3e1a4205ed614d9e8054eb52a8df435f83aaf2b9f6e06dc6bb3` |
| `ssleay32.dll` | 196,608 | `e4ae9d113898ea7802f5cc93faaaaf9b7e0dc0886e2b717ab4c3dbc655889417` |
| `msvcr71.dll` | 348,160 | `8094af5ee310714caebccaeee7769ffb08048503ba478b879edfef5f1a24fefe` |

**VERIFIED.** Command: `sha256sum SK-Main.exe SK-Startup.exe SKGuard.dll libeay32.dll ssleay32.dll msvcr71.dll`

`win.bat` — referenced by `ReadMe-English.txt` line 115 ("Please perform 'win.bat' file.") —
**does not exist in the repository**. **VERIFIED** by `find . -iname "*.bat"` (no results).
Its original contents are unknown and must not be invented.

### PE-derived build identity

| Property | `SK-Main.exe` | `SK-Startup.exe` | `SKGuard.dll` |
|---|---|---|---|
| Machine | i386 (`0x014C`) | i386 | i386 |
| Bitness | 32-bit | 32-bit | 32-bit |
| Subsystem | `WINDOWS_GUI` (2) | `WINDOWS_GUI` (2) | `WINDOWS_GUI` (2) |
| OS version | 4.0 | 4.0 | 4.0 |
| Subsystem version | 4.0 | 4.0 | 4.0 |
| Linker version | 6.0 | 6.0 | 6.0 |
| Image base | `0x00400000` | `0x00400000` | `0x10000000` |
| Characteristics | none set | none set | none set |
| `DllCharacteristics` | `0x0000` | `0x0000` | `0x0000` |
| Relocations | **absent** | **absent** | present |
| Manifest | **absent** | **absent** | absent |
| Version resource | **absent** | **absent** | absent |
| Debug directory | **absent** | **absent** | absent |
| Security directory (Authenticode) | **absent** | **absent** | absent |

**VERIFIED.** Source: `docs/evidence/main-exe.pe.json`, `docs/evidence/multi.pe.json`.

Consequences of the empty `DllCharacteristics` (**INFERRED**, standard PE semantics):

- `DYNAMIC_BASE` (0x40) clear → the image **cannot be relocated**. It must load at its
  preferred base `0x400000`, or the loader fails outright.
- `NX_COMPAT` (0x100) clear → the loader does **not** enable DEP for this process by default.
  This is load-bearing: the anti-cheat routine writes to code and the engine uses
  self-modifying/generated code paths.
- `GUARD_CF`, `HIGH_ENTROPY_VA`, `TERMINATOR_SERVER_AWARE` all clear.
- Linker 6.0 with `SizeOfImage` 30,945,280 for `SK-Main.exe` and a 27.5 MB `.data`
  section is the Visual C++ 6.0 / Visual Studio .NET (VC7) era layout. The presence of
  `msvcr71.dll` (7.10.3052.4, "Visual Studio .NET") pins the CRT to **VC7.1-era runtime**
  with a **VC6-linker** image header. **VERIFIED** for the CRT version from
  `docs/evidence/crypto-crt.pe.json`; the compiler attribution is **INFERRED**.

### Compiler / packer

`SK-Main.exe` and `SK-Startup.exe` are **UPX-compressed**. **VERIFIED**:

```
$ file SK-Main.exe
SK-Main.exe: PE32 executable for MS Windows 4.00 (GUI), Intel i386, UPX compressed, 3 sections

sections: UPX0 (.text-equivalent, raw_size 0, entropy 0.0), UPX1 (entropy 7.94), .rsrc
markers: "UPX!" @ 0x3e0, "UPX0" @ 0x240, "UPX1" @ 0x268
```

`SKGuard.dll` is **not** packed (5 normal sections, `.text` entropy 6.42).

Because the shipped binaries are packed, **the on-disk import table is the UPX stub's, not
the game's**: 14 DLLs with exactly 1–3 symbols each (`LoadLibraryA`, `GetProcAddress`,
`ExitProcess`, …). Analysing those imports would be a serious error. All real imports below
were obtained after lossless unpacking.

### Unpacking (analysis copies only)

`upx -d` (UPX 4.2.4) was applied to **copies** under `.analysis/unpacked/`. The tracked
originals were not modified.

| | Packed | Unpacked | Ratio |
|---|---|---|---|
| `SK-Main.exe` | 1,464,320 | 3,555,328 | 41.19 % |
| `SK-Startup.exe` | 47,616 | 102,400 | 46.50 % |

Unpacked `SK-Main.exe` SHA-256: `0042db844e1f07e2c05e25180840cabb85029d0d0339ab21333862d5ed95dfd1`.
Unpacked `SK-Startup.exe` SHA-256: `f642fa6e1f088da4d00563dbfd6f205fc42d008976fb1f839b451816669c642b`.

**These are analysis derivatives, not distributable artifacts.** They are not the reference
binaries and must never be treated as such.

---

## 2. Real import surface (after unpacking)

**VERIFIED.** Source: `docs/evidence/unpacked.pe.json`.
`SK-Main.exe`: 14 DLLs, **225 imported symbols**.

| DLL | Symbols | Significance |
|---|---|---|
| `KERNEL32.DLL` | 121 | Win32 base; includes `IsBadReadPtr`/`IsBadWritePtr`/`IsBadCodePtr`, `SetUnhandledExceptionFilter` |
| `USER32.dll` | 42 | ANSI windowing (`CreateWindowExA`, `RegisterClassExA`, `PeekMessageA`) |
| `GDI32.dll` | 31 | DIB sections, bitmap fonts, `GetGlyphOutlineA` |
| `WINMM.dll` | 8 | `timeGetTime` (**the crash trigger**, see CRASH-ANALYSIS), `mciSendStringA`, `mmio*` |
| `WININET.dll` | 5 | `InternetOpenA`/`InternetOpenUrlA`/`InternetReadFile` — HTTP scoreboard/CGI |
| `ADVAPI32.dll` | 3 | `RegOpenKeyA`, `RegQueryValueExA`, `RegCloseKey` |
| `ole32.dll` | 3 | `CoInitialize`, `CoCreateInstance`, `CoUninitialize` |
| `IMM32.dll` | 3 | IME (`ImmGetContext`, `ImmSetOpenStatus`) — Japanese input |
| **`d3d9.dll`** | **1** | **`Direct3DCreate9`** |
| **`DSOUND.dll`** | **1** | **`DirectSoundCreate8` (imported by ordinal 11)** |
| `DINPUT8.dll` | 1 | `DirectInput8Create` |
| `comdlg32.dll` | 2 | File open/save dialogs |
| `LIBEAY32.dll` | 2 | `RC4` (ord. 477), `RC4_set_key` (ord. 479) |
| `SKGuard.dll` | 2 | `_API_Hook_AllApps_Start@4`, `_API_Hook_AllApps_Stop@0` |

### Ordinal resolution

The two ordinal imports resolve as follows. **VERIFIED** by reading the export tables of the
*local* DLLs:

| Import | Resolves to | Source |
|---|---|---|
| `DSOUND.dll` ordinal **11** | `DirectSoundCreate8` | `C:\Windows\System32\dsound.dll` export table (12 functions, 12 names) |
| `LIBEAY32.dll` ordinal **477** | `RC4` | shipped `libeay32.dll` export table (3781 functions, 2963 names, base 1) |
| `LIBEAY32.dll` ordinal **479** | `RC4_set_key` | same |

`SK-Main.exe` imports `DirectSoundCreate8` **by ordinal**, not by name. This matters for
compatibility layers that shim `DSOUND.dll` by name only (**INFERRED**).

### Graphics API determination

The game links against **`d3d9.dll`** and calls **`Direct3DCreate9`**. It does *not* import
`d3d8.dll`, `dxgi.dll`, `d3d11.dll` or `opengl32.dll`. **VERIFIED.**

However, the binary embeds a **statically linked D3DX9 effect compiler** — the full
`D3DX` shader assembler/compiler strings are present (`ID3DXEffectCompiler: …`,
`D3DX: (WARN) …`, `Technique_OnlyHDR`, `Technique_GausForBlur4x4`, `Shader Model:%d.%d`).
**VERIFIED** (`docs/evidence/silverknights-main-strings.txt`).

Consequence (**INFERRED**, important for porting): shaders are compiled **at runtime** from
effect/text source through the embedded D3DX compiler. There is no on-disk shader cache to
pre-translate. Any translation layer must therefore provide a *working D3DX9 effect compiler*
or shader translator, not merely a D3D9 device implementation. This is a materially harder
requirement than a plain D3D9 title.

The engine additionally uses **`IDirectPlay8Peer/Server/Client`** for networking.
**VERIFIED** — the literal string `IDirectPlay8Peer/Server/Client` is present, together with
`PeerToPeer`, `SERVER_CLIANT`, port strings `TCP/IP`, and UDP `6073` / TCP+UDP `2300–2400`
documented in `ReadMe-English.txt`. DirectPlay 8 is a **deprecated** component; it is present
in modern Windows only as an optional legacy feature. This is the largest known risk to the
"preserve network functionality" objective (**INFERRED** — no runtime network test performed).

### DirectSound / DirectInput / audio

- `DirectSoundCreate8` (ordinal) — DirectSound 8, not DS3D or XAudio2. **VERIFIED.**
- `DirectInput8Create` — DirectInput 8, polled joystick. **VERIFIED.**
- Music is delivered through **`mciSendStringA`** with `open %s type MPEGVideo`, `play %s`,
  `setaudio %s volume to %d`, plus `midi\` + `.mid` and `mp3\` + `.mp3` paths.
  **VERIFIED** (strings at `0x328db4`–`0x328e24`). MCI MPEG audio is a legacy codec path.

---

## 3. `SKGuard.dll` — the anti-debug/anti-hook enforcer

**VERIFIED.** Not packed. Image base `0x10000000`, 5 sections.

Imports: `KERNEL32.dll` (63), `USER32.dll` (5), `dbghelp.dll` (1).
Exports: `_API_Hook_AllApps_Start@4`, `_API_Hook_AllApps_Stop@0`.

The two exports are **stdcall** (`@4` = one 4-byte argument, `@0` = none), confirmed by the
`ret 4` / `ret` epilogues in the disassembly. **VERIFIED.**

`_API_Hook_AllApps_Start@4` (RVA `0x1120`) does the following, in order. **VERIFIED** by
`tools/disasm_exports.py`:

1. Returns 0 immediately if the global hook handle at `0x1000e000` is already non-zero
   (idempotent).
2. `GetModuleHandleA("user32.dll")`, `GetProcAddress(..., "SetWindowsHookExA")`.
3. Calls it with `idHook = 3` (`WH_GETMESSAGE`), `hMod = 0x10001120` (its own image), and the
   thread id taken from its single argument → **a global, system-wide message hook**.
4. Stores the handle; returns success as a boolean.

`_API_Hook_AllApps_Stop@0` (RVA `0x1240`) calls `UnhookWindowsHookEx` and clears the handle.

The hook callback (RVA `0x11e0`) re-resolves `CallNextHookEx` on every invocation and chains.

`SKGuard.dll` also embeds a full **static MSVCRT** (the `R6016`–`R6028` runtime-error strings
and a `Microsoft Visual C++ Runtime Library` message box are present). **VERIFIED.**

**Safety assessment.**
- This is a **global `WH_GETMESSAGE` hook**, which means the DLL is injected into *every*
  message-pumping process on the desktop, not just the game. **INFERRED** from the
  `WH_GETMESSAGE` semantics.
- Global hooks are subject to **UIPI**: a hooked process at a lower integrity level cannot
  hook a higher one. On Windows 11 with default settings this silently reduces hook coverage.
  **INFERRED.**
- Combined with `SK-Main.exe`'s own anti-debug checks, `SKGuard.dll` is the most likely
  candidate for *behavioural* differences on modern Windows that do **not** produce a crash
  entry (see `docs/CRASH-ANALYSIS.md` §4).
- **No evidence was found that `SKGuard.dll` causes the observed failure.** It is a suspect,
  not a culprit. Do not disable it on the basis of this document.

---

## 4. Shipped crypto and CRT (attack-surface notes)

| File | Version evidence | Notes |
|---|---|---|
| `libeay32.dll` | **OpenSSL 0.9.8a** (`FileVersion`/`ProductVersion`), "Copyright © 1998-2005" | 2005-era. Multiple CVEs. Links `WSOCK32.dll` (25) and `MSVCR71.dll` (62). **VERIFIED.** |
| `ssleay32.dll` | **OpenSSL 0.9.8a** | Depends on `LIBEAY32.dll` (237 imports). **VERIFIED.** |
| `msvcr71.dll` | **7.10.3052.4**, "Visual Studio .NET" | App-local copy of the VC7.1 CRT. **VERIFIED.** |

The game ships its own `msvcr71.dll` next to the executable. On modern Windows the loader
resolves `MSVCR71.dll` **from the application directory first** (standard DLL search order),
so the app-local copy wins over any system copy. **INFERRED**, standard behaviour.

`ssleay32.dll` is present on disk but is **not** in `SK-Main.exe`'s import table — it is a
dependency of `libeay32.dll`-adjacent code paths only if loaded dynamically. **VERIFIED**
that `SK-Main.exe` does not import it. Whether the game calls `SSL_*` at runtime was
**not determined**.

Security note for later phases: OpenSSL 0.9.8a is end-of-life and unsafe for any network
exposure. Because the game talks to a **plain HTTP CGI** endpoint (`%sIpManage2.cgi?`,
`%sUpdateScore2.cgi?`, `InternetOpenUrlA`), TLS is likely unused on the scoreboard path;
`RC4`/`RC4_set_key` are the only crypto symbols the game actually imports. **INFERRED** —
no network capture was taken.

---

## 5. Embedded configuration contract

The game's own INI keys are present as literal strings. **VERIFIED**
(`docs/evidence/silverknights-main-strings.txt`). They define the configuration surface that any
port must preserve:

```
[ENVIRONMENT]  RESOLUTION ONE_QUARTER NAME WAVE MIDI RENDER_HALF RADAR EFFECT_LEVEL
               GAME_LEVEL KEY_REVERSE YAW_REVERSE FIRE_REVERSE BODY_EFFECT HDR_LIGHTING
               WATER_SURFACE WATER_NUM WATER_BASE WATER_RATE BGM_VOLUME
               VERTTEX_TEXTURE DEPTH_OF_FIELD BLUR_2_5D MAP_SHADER PICTURE_COLOR_BASE
               PICTURE_COLOR_RATE MOTION_BLUR OUTLINE THICKNESS COLOR_DIFF
               SCOPE_NEAR SCOPE_FAR CAMERA_VIBRATION
[MESSAGE]      SUPPORT START DAMAGE25 DAMAGE50 DAMAGE75 BREAKDOWN VANQUISH MISS SPARE
[KEYBOARD]     UP DOWN LEFT RIGHT ATTACK1 ATTACK2 GUARD BOOST LOCK SUPPORT
               CALLSUPP CALLSPEAR
[JOYSTICK]     same key set
[COLOR]        BACK_RED BACK_GREEN BACK_BLUE RECT_RED RECT_GREEN RECT_BLUE
[FONT]         FONT_NAME           (in the language file)
[URL]          CGI_URL             (in the language file)
[KNIGHTS_NAME] K%02d               (in the language file)
```

Language files are `%d.ini` (**VERIFIED** string at `0x32a4c8`), selected by OS language code
— matching `ReadMe-English.txt` lines 140–152 (`1033.ini` English, `1041.ini` Japanese).
Only `1041.ini` ships; **`1033.ini` (English) is absent from the repository.** **VERIFIED**
by directory listing.

The live `SilverKnights.ini` uses `RESOLUTION= 4`, `EFFECT_LEVEL= 1`, `GAME_LEVEL= 2`,
`BGM_VOLUME= 500`, `SCOPE_NEAR= 0.030000`, `SCOPE_FAR= 0.001000`. **VERIFIED.**
`1041.ini` sets `CGI_URL=http://philo.rosx.net/cgi-bin/` and `FONT_NAME=MS Gothic`.
**VERIFIED.**

Note `SCOPE_NEAR > SCOPE_FAR` in the shipped INI. That is the reverse of the usual
depth-buffer convention and is likely intentional for this engine's projection mapping
(**HYPOTHESIS** — not validated).

---

## 6. Filesystem and working-directory contract

Relative paths proven present in the binary. **VERIFIED:**

```
SilverKnights.ini   %d.ini            SilverKnights.log   debug.txt
Scene.ini           .\original.ini    bsp\  mesh\  png\  logo\  se\  midi\  mp3\
temp\user%d.bmp     replay\sk-%02d.rep
```

Because these are relative and opened with ANSI APIs, **the process working directory must
be the game directory**. **INFERRED.** Launching `SK-Main.exe` from another directory changes
which data files are found.

### Process model and IPC

`SK-Main.exe` and `SK-Startup.exe` communicate over a **Win32 mailslot**. **VERIFIED** —
format strings `\\%s\mailslot\%s` and `\\.\mailslot\%s`, plus `CreateMailslotA`,
`GetMailslotInfo`, `CreateFileA` in `SK-Startup.exe`'s imports.

`SK-Main.exe` emits these diagnostics. **VERIFIED:**

```
Failed to link with 'SK-Startup.exe' process.
Failure during the preparation to link with 'SK-Startup.exe' process.
Silver Knights - Version 0.13      Version 0.13      <The Trial-Production Version>
```

`SK-Startup.exe` emits these. **VERIFIED:**

```
RegQueryValueEx function failed.(REsult:%x)
Failed to acquire the user ID.
Failed to link with 'SK-Main.exe' process.
Failure during the preparation to link with 'SK-Main.exe' process.
Failed to execute 'SK-Main.exe'.
'SK-Main.exe' file is corrupted.
'SK-Startup.exe' is already running.
Failed to create the dialog box.
GetVersionEx function failed.
```

---

## 7. `SK-Startup.exe` integrity check on `SK-Main.exe`

This is a confirmed, fully reversed mechanism and it constrains every future patch.
**VERIFIED.**

At `SK-Startup.exe` RVA `0x2600` the launcher:

1. Opens `SK-Main.exe` (`0x12543`, string at `0x12758`).
2. Reads the file and computes an **MD5** over its full contents.
3. Compares the 16-byte digest against a constant at **RVA `0x12558`**
   (file offset `0x12558`): `84 a3 21 d3 03 5d e0 e2 f0 35 39 12 36 67 f3 d6`.
4. Compares the file length against a `DWORD` at **RVA `0x12554`**: `0x00165800` =
   **1,464,320** — exactly the shipped `SK-Main.exe` size.
5. On any mismatch: `MessageBox("SK-Main.exe", "'SK-Main.exe' file is corrupted.")` and
   returns 0 without launching.

Proof that the constant is MD5 of the shipped file: **VERIFIED**

```
md5(SK-Main.exe) = 84a321d3035de0e2f03539123667f3d6
md5 constant @0x12558 = 84a321d3035de0e2f03539123667f3d6   ← exact match
size constant @0x12554 = 0x165800 = 1464320                ← exact match
```

**Engineering consequence.** Any change to `SK-Main.exe` — including a one-byte bug fix —
makes `SK-Startup.exe` refuse to launch it. There are only three legitimate strategies:

- **A.** Patch `SK-Main.exe` **in place, same length**, and update both the size constant
  (unchanged if length is preserved) and the MD5 constant in `SK-Startup.exe`.
- **B.** Launch `SK-Main.exe` directly, bypassing `SK-Startup.exe`, and reproduce the
  mailslot handshake — **not yet proven to work**; a direct launch in this session exited 0
  in ~13 s without writing a log line (see `docs/CRASH-ANALYSIS.md` §2), which is consistent
  with `SK-Main.exe` waiting for or aborting on the missing peer.
- **C.** Ship a launcher that computes and injects the pair at run time.

Strategy A is the lowest-risk and is what the successful experiment used.

Related: `SK-Main.exe` performs its own `MD5`-independent anti-debug/anti-hook checks and
writes results to `SilverKnights.log` and `debug.txt`. `SK-Startup.exe` also contains
`1234567890` as a `UserID` fallback (RVA `0x126f4`) reached from the
`Failed to acquire the user ID.` path. **VERIFIED.**

---

## 8. Anti-debug / anti-hook (`SK-Main.exe`)

`SK-Main.exe` contains three checks and three messages. **VERIFIED** —
strings and exactly one `push imm32` reference each:

| Message string | String VA | Sole code reference |
|---|---|---|
| `Illegal access was detected.(%s)` | `0x72b030` | RVA `0x1f4949` |
| `Timer-API hook was detected.(%04x)` | `0x72b054` | RVA `0x1f4d7d` |
| `Debugger process was detected.(%d)` | `0x72b078` | RVA `0x1f4d6e` |

Supporting artifacts, all **VERIFIED** as strings:

```
SetThreadContext  GetThreadContext  GetCurrentThread  FindWindowA  user32.dll  OLLYDBG
CreateFileA  \\.\REGMON  \\.\REGVXD  \\.\FILEMON  \\.\FILEVXD  \\.\NTICE  \\.\SICE  \\.\TRW
IsDebuggerPresent  RaiseException  timeGetTime  winmm.dll
```

Detected-debugger window class names include `OLLYDBG` with `FindWindowA`, and open attempts
on legacy ring-3 debugger device names (`\\.\NTICE` = SoftICE, `\\.\SICE`, `\\.\TRW` =
TRW2000, `\\.\REGMON`/`\\.\FILEMON` = Sysinternals-era filter drivers).

A global flag is set at `0x21428a4` on any positive detection, and a routine at RVA
`0x1f4d87`/`0x1f4949` formats the message and calls a reporting function (`0x5c94b0`) before
`0x5fd640`. **VERIFIED** by disassembly.

**This anti-cheat code is the direct cause of the Windows 11 failure.** See
`docs/CRASH-ANALYSIS.md`.

---

## 9. What remains unknown

Stated explicitly so no later session mistakes absence of evidence for absence of a problem:

- Whether `SKGuard.dll`'s global hook actually installs successfully on Windows 11 under
  UIPI, and what it does when it does not. **NOT TESTED.**
- The full set of functions the `WH_GETMESSAGE` callback performs. Only the control flow of
  the exported start/stop and the callback trampoline was read. The hook body was **not**
  fully reversed.
- Whether the network stack (DirectPlay 8 + CGI scoreboard) functions at all on Windows 11.
  **NOT TESTED.**
- Whether `ssleay32.dll` is loaded at runtime. **NOT TESTED.**
- What `win.bat` contained. **UNKNOWN — file absent.**
- Whether `1033.ini` (English language file) existed and is required for non-Japanese
  locales. `SK-Startup.exe` reads `GetSystemDefaultLangID`/`GetUserDefaultLCID`, and
  `1041.ini` is the only language file shipped.
- The exact original compiler for `SK-Main.exe`. Linker 6.0 + `msvcr71` is suggestive of
  VC6 with a later CRT, or a VC6-era toolchain with `/MD` against VC7.1. **HYPOTHESIS only.**
