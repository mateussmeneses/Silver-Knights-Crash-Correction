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
| Playable match | **PASS** (`run-27`) |
| Same-length shippable build | **PASS** (`tools/build_patched.py`) |
| Audio / controller / network | **OPEN** |
| High-end renderer (`EFFECT_LEVEL`) | **OPEN — next gate** |
| Linux / macOS | **NOT STARTED** |

---

# CODEX BRIEF 1 — `codex/t05b-render-reference`

**Goal:** exercise and photograph the high-end renderer. This is the yardstick every other
platform will be judged against.

**Why it matters more than it looks**
`SilverKnights.ini` ships `EFFECT_LEVEL=1` — the lowest setting — and the verified match in
`run-27` used exactly that. So the heavy D3DX effect paths were **never run**. Every
cross-platform question reduces to "do these shaders compile and produce the same image?",
and those are precisely the paths a translation layer (DXVK, MoltenVK) breaks first.

**Verified working harness — do not re-derive**

- Build: `python tools/build_patched.py --game-dir . --upx <upx.exe>` → same-length
  `SK-Main.exe` (1,464,320 bytes) + `SK-Startup.exe` with only the MD5 constant edited.
- Launch + navigation: `tools/t01h-start-match.ps1`. This is the **only known-good sequence**:

  | Step | Key | Scancode | Extended |
  |---|---|---|---|
  | main menu → Battle Mode | `DIK_DOWN` | `0x50` | **yes** |
  | open Battle setup | `ENTER` | `0x1C` | no |
  | **start the match** | **`F3`** | **`0x3D`** | **no** |
  | confirm | `ENTER` | `0x1C` | no |

  `Enter` at the setup screen only moves slot focus. **`F3` starts the match** — from
  `1041.ini [FUNCTION] F3_START =F3 Start`.
- Focus: `AttachThreadInput` + synthetic ALT tap, then verify
  `GetForegroundWindow() == target` **before every injection**. Another window can steal focus
  mid-run (observed: `XamlExplorerHostIslandWindow`).

**Acceptance criteria**

1. A reference set: the same gameplay view captured at `EFFECT_LEVEL` = 1, then each of
   `HDR_LIGHTING=1`, `DEPTH_OF_FIELD=1`, `BLUR_2_5D=1`, `OUTLINE=1`, `MOTION_BLUR=1`,
   then `EFFECT_LEVEL` at maximum.
2. For at least three of those, the frame must **visibly differ** from the `EFFECT_LEVEL=1`
   baseline, demonstrated with `python tools/imgdiff.py` (bounding box + % changed pixels).
3. **No D3DX compile failure** and no `Error Massage` dialog at any setting.
4. `SilverKnights.ini` restored to its shipped values afterwards, and that restoration
   verified (`git diff` clean on that file).
5. Record the exact INI values used alongside each image.

**Do not** leave `SilverKnights.ini` modified. It is user data; the project must not ship a
changed configuration.

**Deliverable:** `docs/evidence/t05b-render/` (images + a settings-to-image table) and a row
proposal for `docs/COMPATIBILITY-MATRIX.md`.

---

# CODEX BRIEF 1b — `codex/t01b-gameplay` (ARCHIVED, COMPLETE)

Superseded by `run-27`, which reached a playable match. Kept only as history: the lesson is
that **`F3` starts a match, not `Enter`**.

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

> **STATUS: still open, and now higher-value than when first written.** Since this brief was
> drafted, the coordinator re-derived the entire chain from the disassembly in
> `docs/evidence/r02-fingerprint-cascade-verified.txt`. That document is *still the same
> author*, so it does not satisfy independence — but it gives you the exact addresses and
> expected instruction sequences to check, which makes refutation cheap. If the chain is
> sound you should be able to reproduce it in minutes; if it is not, the specific wrong step
> will be obvious.

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
5. **NEW — check the claim in `CRASH-ANALYSIS.md` §3.3.1**, that this whole function is
   debugger detection. The evidence offered is the set of string references
   (`0x72b09c` `SetThreadContext`; `0x72b0b0` / `0x72b0c4` `OLLYDBG`, `FindWindowA`,
   `GetCurrentThread`; `\\.\RE...`). Decide whether that establishes intent, or whether it is
   coincidence. This affects how the fix must be described (anti-cheat removal vs. bug fix).
6. **NEW — already answered by the coordinator, please re-check it:** "is `0x1f4ee0` called
   anywhere other than `0x1f4d48`?" An E8/xref scan found **exactly one call site
   (`0x5f4d48`) and zero immediate references** to the function. The method cannot see a call
   through a register or a run-time-computed address. If you can construct such a path — or
   confirm none exists — that closes the last gap in the patch's justification.

**Deliverable:** an explicit PASS/REFUTE on each of the six points, with the disassembly and
byte dumps you used. If any point is wrong, say so plainly — the patch's justification depends
on this chain.

---

# CLAUDE BRIEF 2 — `R-02` patch blast-radius audit

> **STATUS: ANSWERED statically, 2026-11-13. This brief is retained for independent re-check,
> not as outstanding work.**
>
> Findings (evidence: `docs/evidence/r02-fingerprint-cascade-verified.txt`):
> - `0x1f4ee0` has **exactly one call site**, `0x5f4d48`, immediately before the patched
>   branch. Zero immediate references to the function address anywhere in the image.
> - The patched branch is the **sole consumer** of the return value: `cmp eax,-1` / `jle` /
>   `cmp eax,ebp` / `je` / `cmp eax,5` / `jg` then report-and-shutdown.
> - The global at `0x21428a4` is a "shutting down" flag, read only at `0x5f4da4`.
> - The enclosing function's string references (`FindWindowA`/`OLLYDBG`,
>   `Get`/`SetThreadContext`, `\\.\RE...`) identify it as debugger detection, so the timer
>   check is one arm of the anti-tamper gate.
>
> Remaining ask: **try to break it.** The xref method used cannot see a call through a register
> or a run-time-computed address. If such a path exists, the patch is incomplete and the game
> can still self-terminate. Also worth checking: whether `0x1f4ee0` is reached more than once
> in a session (a loop), which a single 29.7-minute soak cannot rule out.

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

# CODEX BRIEF 4 — `T-11b` locate and characterise the 1800-second session cap

**Branch:** `codex/t11b-session-cap`
**Prerequisite:** read `docs/evidence/run-48-analysis.txt` and
`docs/evidence/t11-time-cap-search-analysis.txt` first. Both save you hours.

**Established facts (do not re-derive)**

- The game self-terminates at **exactly 1800.067 s** in a live match, writing a clean
  `SK-Main.exe End` line. No dialog, no WER event. `run-48`.
- There is **no `1800000` ms immediate** and no `1800.0` float/double anywhere in the image.
  So the cap is almost certainly a timestamp difference against a computed or stored limit.
- `SilverKnights.ini` (17 sections) and `1041.ini` expose **no** time, duration, round or
  match-limit key. The value is compiled in.
- Open question: is the cap **per-match** or **per-process-age**? `run-53` is running to
  settle it by idling in the menu. **Check its result before you start** - it may already
  answer your question and you would then only need the static side.

**What to do**

1. Read `run-53`'s verdict. It is only valid if the log shows a **matched `Start`/`End`
  pair**. A `Start` with no `End` means the process was killed and the run is void.
2. Find the shutdown routine `0x5fd640` (called from the anti-hook path) and enumerate its
   callers. One of them should be guarded by a time comparison. That is the cap site.
3. Do **not** byte-search for constants. That was already tried and produced only
   misaligned-decode false positives.
4. Once located, answer: does the cap read a stored variable that could be patched, or is it
   a bare immediate comparison? Report the address, the encoding, and whether a same-length
   patch is possible (the project requires same-length patches for the launcher's MD5/size
   integrity check - see `tools/build_patched.py`).

**Acceptance criteria**

- Named code address for the cap comparison, with disassembly.
- Explicit statement of per-match vs per-process-age, backed by a valid `run-53` log pair.
- If a patch is proposed: same length, no new imports, and a documented reason plus expected
  behaviour. Do **not** apply it to a tracked binary; the original must stay byte-identical.

**Do not:** kill game processes by name (see `tools/lib-teardown.ps1` - this mistake already
invalidated two experiments), and do not run this concurrently with another game harness.

---

# CODEX BRIEF 5 — `T-07b` human-assisted network probe

**Branch:** `codex/t07b-network-human`
**Prerequisite:** `run-37`/`38`/`39`.

**Why a human is needed.** Network Mode is reachable and stable - the screen renders
"Enter your name. (12 Letters Max)" and the process stays healthy. But the name field accepts
**neither** `SendInput` scancodes **nor** `PostMessage(WM_CHAR)`. The binary imports no
`GetKeyboardState`/`ToAscii`/`ToUnicode`/`MapVirtualKey`/`GetAsyncKeyState`, so it almost
certainly reads characters from its own DirectInput poll and renders the field itself. Three
automation attempts failed; stop trying to automate it and use a person.

**Procedure (about two minutes of human time)**

1. Launch, navigate to Network Mode, and **type a name by hand** at the keyboard.
2. While the name-entry screen is up, capture the module list from a **32-bit** PowerShell
   (`probe-32bit-modules.ps1` shows the pattern; 64-bit cannot see WOW64 modules).
3. Record whether `dpnet.dll`, `dplayx.dll`, `dpwsockx.dll`, `ws2_32.dll` load.
4. Advance past the name and screenshot whatever appears (lobby, host/join, error).
5. If a lobby appears, attempt to host a session and record the result.

**Acceptance criteria**

- Definitive answer to "does `IDirectPlay8Peer` initialise on Windows 11 build 26300?"
- Either a named failure point with the verbatim dialog text, or evidence of a working lobby.
- Module list captured **before and after** the name is accepted, so the load is attributable.

**Why this matters beyond Windows.** DirectPlay 8 is unimplemented in Wine. If it fails here,
network play is dead on every platform and the mission's "preserve network functionality"
objective needs a replacement transport (a much larger project). If it works here, the Linux
question becomes "can Wine be given a working DirectPlay", which is a different problem. Either
answer is valuable; do not leave it unknown.

---

# Sequencing rules

0. **Never run two game harnesses at once.** `tools/lib-teardown.ps1` exists because this
   destroyed a 33-minute experiment twice and fabricated a false verdict. If a harness needs
   to refuse rather than proceed, let it throw. Any long runtime experiment (T-11, soaks)
   must be the only thing touching the game for its whole duration.
1. `codex/t01b-gameplay` first — nothing on Linux or macOS is meaningful without a playable
   Windows reference.
2. `R-01` and `R-02` may run in parallel with T-01b; they are read-only. `R-02` is answered;
   only an adversarial re-check remains.
3. `codex/t03-startup-registry` and `codex/t04-audio` are independent and may run in parallel.
4. `R-03` gates any decision to touch `SKGuard.dll`.
5. Linux (`T-10`…`T-15`) starts only after a playable match exists.
6. macOS starts only after Linux `T-13` (D3DX under DXVK) has an answer.
7. `T-07b` needs a human at the keyboard. Schedule it when one is available; it cannot be
   automated and should not block other work.
