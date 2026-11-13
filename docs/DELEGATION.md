# Delegation Briefs

Concrete, self-contained task specifications. Each brief is written so the receiving agent
needs no access to the coordinating session's context.

**File ownership is disjoint.** No two briefs write the same path. No brief permits modifying
a tracked game binary in the working tree.

---

## Status at time of writing

| Blocker | State |
|---|---|
| Windows 11 fatal self-termination | **FIXED — root cause proven, patch validated** |
| Menu navigation | **FIXED — was a focus problem, not an input-protocol problem** |
| Main menu reached | **PASS** |
| Battle Mode setup screen reached | **PASS** |
| Playable match | **OPEN** |
| Same-length shippable build | **PASS** (`tools/build_patched.py`) |
| Audio / controller / network | **OPEN** |
| Linux / macOS | **NOT STARTED** |

---

# CODEX BRIEF 1 — `codex/t01b-gameplay`

**Goal:** prove the game is playable. This is the last gate before any platform comparison.

**Acceptance criteria**

1. From a launched build, reachable in one scripted run: main menu → Battle Mode setup →
   **an actual match**, captured as a screenshot showing in-game HUD (armor gauge, boost
   gauge, radar, weapon labels).
2. Frame-diff evidence that gameplay is live, not a frozen frame: at least 3 captures during
   movement, all distinct in the region of the HUD/geometry (not only the background).
3. No `Error Massage` dialog appears at any point.
4. The run is reproducible by one committed command.

**Known-good starting point (do not re-derive)**

- Patched build: `tools/build_patched.py` → same-length `SK-Main.exe` (1,464,320 bytes) plus
  `SK-Startup.exe` with only the MD5 constant edited.
- **Input requires real foreground focus.** `SetForegroundWindow` alone is *refused* for a
  background process. Use the working technique in `tools/t01f-force-focus.ps1`:
  `AttachThreadInput(self, foregroundThread, true)` → synthetic ALT tap →
  `SetForegroundWindow` → `AttachThreadInput(..., false)`.
- **Keys are DirectInput scancodes.** Arrows are **E0-extended**: `DIK_DOWN = 0x50` **with**
  `KEYEVENTF_EXTENDEDKEY`; `DIK_UP = 0x48` extended. Plain scancode `0x50` is NumPad-2 and
  will not navigate. `Enter = 0x1C` plain, `Esc = 0x01` plain.
- Config confirms the scancode contract: `SilverKnights.ini [KEYBOARD]` has `UP=200`,
  `DOWN=208`, `LEFT=203`, `RIGHT=205` — these are `0x80|scancode` DIK codes.
- Window class is `UDX_CLASS`. There is exactly one; verify with
  `GetForegroundWindow() == target` before injecting, and retry focus if it is refused.
- A competing window can steal focus mid-run (observed: `XamlExplorerHostIslandWindow`).
  Re-assert focus immediately before each injection, not once at the start.

**Do not**

- Use `PostMessage(WM_KEYDOWN)` — a polling DirectInput app never sees it.
- Use `keybd_event` with virtual-key codes — DirectInput reads scancodes.
- Modify any tracked binary. Copy the game tree to a scratch directory first.

**Deliverable:** `tools/t01b-gameplay.ps1` + `docs/evidence/t01b-gameplay/` + a row update
proposal for `docs/COMPATIBILITY-MATRIX.md`.

---

# CODEX BRIEF 2 — `codex/t03-startup-registry`

**Goal:** remove the two spurious dialogs `SK-Startup.exe` shows on Windows 11.

**Root cause (verified — do not re-investigate)**
`SK-Startup.exe` calls `RegOpenKeyExA`/`RegQueryValueExA` on
`SOFTWARE\Microsoft\Windows\CurrentVersion` for `ProductId` (string @ RVA `0x1217c`).
That value was moved to `...\Windows NT\CurrentVersion` in modern Windows, so the read
returns `ERROR_FILE_NOT_FOUND` (2). The launcher shows `RegQueryValueEx function failed.
(REsult:2)`, then fails to derive a `UserID` and shows `Failed to acquire the user ID.`,
then falls back to the literal `1234567890` (RVA `0x126f4`) and continues.

**Acceptance criteria**

1. Launching `SK-Startup.exe` produces **zero** `Error Massage` dialogs.
2. The launcher window still appears with its four buttons and a populated `UserID` field.
3. `SK-Main.exe` still launches and reaches the main menu.
4. The change is same-length (no size change) so no other constant needs updating.
5. A documented reason and validation result are recorded.

**Constraint:** patch a **copy**; never edit the tracked `SK-Startup.exe`.

**Suggested approach:** patch the failure branch so the code takes the existing
`1234567890` fallback path without the two `MessageBoxA` calls, rather than injecting a
registry shim. A registry shim changes the host machine and is not acceptable as the
project's fix.

---

# CODEX BRIEF 3 — `codex/t04-audio`

**Goal:** establish whether all three audio paths actually produce sound.

**Verified starting state**
Three independent paths are loaded at the menu (`docs/evidence/run-17-32bit-modules.txt`):

| Path | DLLs confirmed loaded | Verification needed |
|---|---|---|
| SFX | `DSOUND.dll` | Audible effect on menu move / attack |
| BGM MP3 | `QUARTZ.dll`, `devenum.dll`, `l3codeca.acm`, `msmpeg2adec.dll`, `mciqtz32.dll` | Music audible |
| MIDI | `dmusic.dll`, `dmloader.dll`, `midimap.dll` | Music audible, or documented silent |

**Acceptance criteria**

1. For each of the three paths: PASS (heard) / FAIL (silent with a named cause) /
   BLOCKED. No "probably works".
2. `BGM_VOLUME=500` (shipped default) confirmed to take effect.
3. Record whether a DirectShow `FilterGraphWindow` appears at runtime, since that indicates
   the MP3 graph was built.

**Do not** claim audio works from module-load evidence alone. Loaded ≠ audible.

---

# CLAUDE BRIEF 1 — `R-01` independent root-cause verification

**Goal:** independently confirm or refute the root-cause claim. Do not accept it on trust.

**Claim under review**
`SK-Main.exe` RVA `0x1f4ee0` copies 20 bytes of `winmm!timeGetTime` and fingerprints them
against the Windows 9x/2000 prologue `83 3D <abs32> 00 0F 85 <rel32>`. Mismatch returns
`0x100 + byte[0]`. Modern `winmm` exports `FF 25 <abs32>` (`jmp [IAT]`), so
`0x100 + 0xFF = 0x1FF`, which appears in the dialog as `Timer-API hook was detected.(01ff)`.
Control flow at `0x1f4d43` treats any verdict `> 5` as a detected hook.

**Required verification steps**

1. Reproduce the disassembly at `0x1f4ee0` (0x140 bytes) and at `0x1f4d00` (0x60 bytes).
2. Read the actual first 20 bytes of `timeGetTime` from **`SysWOW64\winmm.dll`** (32-bit —
   the game is a WOW64 process). Confirm or refute `FF 25`.
3. Confirm or refute the return-value ladder (`0x100`, `0x200`, `0x600`, `0x700`, `0x800`,
   `0x1100`, `0x1200`, `0xFFFFFFFF`).
4. Confirm the `cmp eax,-1` / `jle` / `cmp eax,ebp` / `je` / `jg` branch structure.

**Deliverable:** an explicit PASS/REFUTE on each of the four points, with the disassembly and
byte dumps you used. If any point is wrong, say so plainly — the patch's justification depends
on this chain.

---

# CLAUDE BRIEF 2 — `R-02` patch blast-radius audit

**Goal:** determine exactly what the 1-byte change affects.

**The change:** RVA `0x1f4d50`, `7E` (`jle 0x5f4da4`) → `EB` (`jmp 0x5f4da4`).

**Questions that must be answered with evidence**

1. Enumerate every call site of `0x5f4ee0` (the fingerprint routine). Is `0x1f4d48` the only
   one?
2. Enumerate every reader of the global flag at `0x21428a4`. What else does that flag gate
   besides the shutdown path at `0x5fd640`?
3. Does forcing the jump skip any *functional* work, or only the diagnostic/report path?
4. The caller at `0x1f4960` has its own detection ladder (verdicts 1–5). Does the
   `0x1f4d50` edit interact with it?
5. Is the timer check on a periodic timer during gameplay, or one-shot at init? If periodic,
   the change is continuously active and its blast radius is larger.

**Deliverable:** a written answer to 1–5 plus a verdict: *safe / safe-with-caveats /
unsafe*. Do not approve the patch merely because it works.

---

# CLAUDE BRIEF 3 — `R-03` `SKGuard.dll` hook audit

**Goal:** decide whether `SKGuard.dll` is safe, necessary, or harmful on Windows 11.

**Verified**
`_API_Hook_AllApps_Start@4` (RVA `0x1120`, stdcall, `ret 4`) calls
`SetWindowsHookExA` with `idHook = 3` (`WH_GETMESSAGE`) and `hMod = 0x10001120` — a
**system-wide** hook, so the DLL is mapped into every message-pumping process on the desktop.
The callback at `0x11e0` re-resolves `CallNextHookEx` per invocation and chains.

**Observed at runtime:** `SKGuard.dll` loads **relocated at `0x02500000`**, not at its
preferred base `0x10000000`.

**Questions**

1. What does the hook callback body actually do? Full reversal required — only the
   trampoline has been read.
2. Does it modify game memory, or only inspect?
3. Does it survive UIPI (a lower-integrity process cannot hook a higher one)? The relocation
   is suspicious and may indicate the loader changed its behaviour.
4. Are the two exports only called at init/shutdown, or during play?
5. If the game runs correctly with `SKGuard.dll` absent, what is lost?

**Deliverable:** the callback's semantics, the risk verdict, and an explicit recommendation
on whether the project should keep, stub, or remove `SKGuard.dll`. Do not recommend disabling
it without showing what it does.

---

# CLAUDE BRIEF 4 — `R-05` strategy challenge (Phase 5)

**Goal:** challenge `docs/ROADMAP.md` §4, which recommends **Strategy A** (existing executable
plus compatibility layers) with B (hybrid) only for proven blockers, and disqualifies C
(native reconstruction).

**The argument to attack**

1. "C is disqualified because static recompilation solves ISA translation and this binary is
   already x86." Is that reasoning sound, or does it conflate static recompilation with
   decompilation?
2. "B becomes necessary only if D3DX under DXVK fails." Is the D3DX dependency really the
   deciding factor, or is DirectPlay 8 the harder one?
3. "Multiplayer will be impossible on every route." Is that overstated?

**Deliverable:** a written challenge with evidence. If the recommendation stands, say so and
say why. If it does not, propose the alternative and the experiment that would distinguish
them.

---

# Sequencing rules

1. `codex/t01b-gameplay` first — nothing on Linux or macOS is meaningful without a playable
   Windows reference.
2. `R-01` and `R-02` may run in parallel with T-01b; they are read-only.
3. `codex/t03-startup-registry` and `codex/t04-audio` are independent and may run in parallel.
4. `R-03` gates any decision to touch `SKGuard.dll`.
5. Linux (`T-10`…`T-15`) starts only after a playable match exists.
6. macOS starts only after Linux `T-13` (D3DX under DXVK) has an answer.
