# Silver Knights 0.13 — Roadmap

Prioritised, independently verifiable milestones. Each task has an owner, a deliverable, and
a pass criterion that can be checked without trusting the implementer.

**Governing rule:** a task is complete only when its pass criterion is demonstrated by an
artifact in `docs/evidence/`. Not by a description of the work.

---

## Phase 0 — Baseline (COMPLETE)

| ID | Task | Owner | Status |
|---|---|---|---|
| T-00.1 | Repository and history intake | Hermes | **DONE** — commit `747f22e`, 1170 files, single commit |
| T-00.2 | AI-Workbench capability inspection | Hermes | **DONE** — `aiwh` CLI inspected; `game-port` triage run; capabilities catalogued |
| T-00.3 | Binary identity + hashes | Hermes | **DONE** — `docs/BINARY-ANALYSIS.md` §1 |
| T-00.4 | PE metadata, imports, exports, ordinals | Hermes | **DONE** — `.pe.json` evidence files |
| T-00.5 | UPX unpacking of analysis copies | Hermes | **DONE** — `.analysis/` (gitignored) |
| T-00.6 | Windows 11 crash reproduction | Hermes | **DONE** — deterministic, 4/4 |
| T-00.7 | Root cause of the fatal defect | Hermes | **DONE** — `docs/CRASH-ANALYSIS.md` §3 |
| T-00.8 | Experimental fix validated | Hermes | **DONE** — 4/4 patched runs survive |
| T-00.9 | Portable evidence + tooling | Hermes | **DONE** — 17 harness scripts, 17 evidence files |

**Exit criterion met:** the exact cause of the Windows 11 failure is established and a
reproducible baseline exists.

---

## Phase 1 — Windows 11: prove the game is actually playable

This is the current phase. Nothing else may start until M1.6 passes.

| ID | Task | Owner | Deliverable | Pass criterion |
|---|---|---|---|---|
| **T-01** | ~~Prove interactivity past the title screen~~ | Codex | — | ✅ **PASS** — `run-19`, `run-24`. Menu reached; navigation verified (Story→Battle→Network→Battle) |
| **T-01b** | ~~Reach a playable match with in-game HUD~~ | Codex | `tools/t01h-start-match.ps1` | ✅ **PASS** — `run-27`. "Battle Start" → timer `00:10.912`, live HUD, mech took damage. Key insight: **F3 starts the match**, not Enter |
| **T-05b** | **Exercise the high-end renderer** (`EFFECT_LEVEL`, `HDR_LIGHTING`, `DEPTH_OF_FIELD`, `BLUR_2_5D`, `OUTLINE`, `MOTION_BLUR`) | Codex | `tools/t05b-render-reference.ps1` | ✅ **PASS (compiles/runs)** — `run-28`. 4 profiles at 1280×960, no D3DX failure, no dialog, threads 33→45, INI restored |
| **T-05c** | **Matched effect comparison via replay** — prove each effect visibly changes the image | Codex | Screenshots at a **fixed replay timestamp** across profiles | Same camera pose, effect-on vs effect-off differ in an attributable region. Removes the camera confound that invalidated `run-28`'s pixel-diff |
| **T-02** | ~~Same-length patch pipeline~~ | Codex | `tools/build_patched.py` | ✅ **PASS** — `run-25`. Repacked to exactly 1,464,320 bytes; only the MD5 constant edited; game launched and navigated |
| **T-03** | **Suppress the two startup dialogs** | Codex | `SK-Startup.exe` patch replacing the `ProductId` read with the documented fallback | Zero `Error Massage` dialogs on launch; `UserID` field populated; launcher proceeds |
| **T-04** | Audio verification (SFX / MP3 / MIDI) | Codex | Recorded session notes + which path produced sound | SFX audible in menu; BGM audible; MIDI either audible or documented silent |
| **T-05** | Full `.bsp` map render with D3DX effects | Codex | Screenshot of in-game geometry + effects | Non-title-screen geometry renders; no D3DX compile failure |
| **T-06** | Controller verification | Codex | Mapping table: game action → button pressed → observed result | All 12 actions from `ReadMe-English.txt` respond |
| **T-07** | Network mode investigation | Codex | Report: does DirectPlay8 initialise? Where exactly does it fail? | A definitive answer, either pass or a named failure point |
| **T-08** | 30-minute stability + memory growth | Codex | Timeline of working set and thread count | No crash, no unbounded growth, no dialog appears |
| **T-09** | Locale / `1033.ini` behaviour | Codex | Report on what the game does with no matching `%d.ini` | Documented behaviour on a non-Japanese locale |

**T-05b is done as far as it can go without a replay.** Confirmed: the high-end D3DX shader
paths **compile and run** on Windows at 1280×960 with no failure. What is *not* proven is that
each effect **visibly** changes the image, because `run-28` compared different gameplay moments.

**T-05c is the honest follow-up.** `imgdiff` reported 73–77 % pixel change between profiles, but
that number is worthless as effect evidence — different frames of the *same* settings also
differ by that much. To isolate an effect you need the same camera pose across profiles. The
game ships a replay system (`replay\sk-%02d.rep`, `F2_REP_ON`/`F2_REP_OFF`,
`"Silver Knights - Replay File"`), which is the natural way to hold the camera fixed.

This matters for the mission: the cross-platform yardstick is "does the translated shader
produce the same picture?", and that question is unanswerable until a matched reference frame
exists.

**T-02 is done and is the shippable form.** `tools/build_patched.py` performs
unpack → 1-byte patch → re-pack → pad to exactly 1,464,320 bytes. Because the length is
preserved, only the MD5 constant in `SK-Startup.exe` changes; the size constant at `0x12554`
is untouched. Validated end-to-end in `run-25`.

---

## Phase 2 — Independent review

| ID | Task | Owner | Deliverable |
|---|---|---|---|
| **R-01** | **Adversarial review of the root-cause claim** | Claude | Independently reproduce `winmm!timeGetTime` prologue vs. the fingerprint in `0x5f4ee0`; confirm or refute the `0x1FF` arithmetic. Must not accept Hermes' conclusion on trust. |
| **R-02** | **Review the patch for unintended behavioural change** | Claude | Enumerate what else `0x5f4d50` gates. Is the `jle`→`jmp` reachable from any other call path? Does the global flag at `0x21428a4` gate anything besides shutdown? |
| **R-03** | **`SKGuard.dll` risk assessment** | Claude | Full reversal of the `WH_GETMESSAGE` callback body. Answer: does it modify game state? Does it survive UIPI? Is removing it safe and necessary? |
| **R-04** | **DirectPlay 8 feasibility** | Claude | Determine whether `dpnet.dll` can provide `IDirectPlay8Peer` on Windows 11 26300, and what a replacement transport would require |
| **R-05** | **Strategy selection review (Phase 5)** | Claude | Challenge the A/B/C recommendation in §4 with evidence, not preference |
| **R-06** | **Review T-02 and T-03 patches** | Claude | Line-by-line review of the same-length patch pipeline and the `SK-Startup.exe` change |

R-01 and R-02 must complete before any patch is treated as the project's canonical fix.
R-03 gates any decision about `SKGuard.dll`.

---

## Phase 3 — Linux

**Blocked until Phase 1 T-01 and T-05 pass.** See `docs/LINUX.md` for the full protocol.

| ID | Task | Owner | Pass criterion |
|---|---|---|---|
| **T-10** | Reproducible Wine prefix script | Codex | Script recreates the prefix from scratch; version-pinned; committed |
| **T-10a** | **Case-mismatch remediation plan** for the 12 verified references | Codex | A per-file decision table (12 known: `blast`/`blast2`/`bullet`/`force`/`giga-bazooka`/`mist`/`philo-gun-emb`/`philo-option`/`shaft.bsp`/`shaft.wad`/`smoke`/`smoke2`), with a documented reason for each direction |
| **T-10b** | **Characterise the consequence** of each case mismatch on ext4 | Codex | For each: crash / missing model / untextured / silent fallback — one row each |
| T-11 | L-1: launch under Wine | Codex | `SK-Main.exe Start` logged, 60 s survival |
| T-12 | L-2: D3D9 via DXVK | Codex | Title art renders; DXVK HUD shows a D3D9 device |
| T-13 | **L-3: D3DX effect compilation** | Codex | A `.bsp` scene renders with effects — **the critical unknown** |
| T-14 | L-4/5/6: audio, input, case sensitivity | Codex | Per-item matrix rows move off NOT TESTED |
| T-15 | L-7: network mode | Codex | Definitive answer; expected BLOCKED |

---

## Phase 4 — macOS

**Blocked until Phase 3 T-13 answers whether D3DX works under translation.** If D3DX cannot
compile the game's effects on Linux, macOS is strictly harder and should not be attempted.

| ID | Task | Owner | Pass criterion |
|---|---|---|---|
| T-20 | CrossOver bottle on Apple Silicon | Codex (needs hardware) | Title art renders in a D3D9→Vulkan→Metal stack |
| T-21 | D3DX effect compilation under CrossOver | Codex (needs hardware) | Scene renders correctly |
| T-22 | Packaging feasibility + signing cost | Codex | Documented cost, with the licence constraint from `ReadMe-English.txt` respected (personal use only) |

Both tasks require hardware that does not exist in this environment. They are recorded so the
work is well-defined when it does.

---

## Phase 5 — Long-term architecture

### The three strategies, assessed against verified facts

#### A. Existing executable + compatibility layers

Run the patched PE under Wine/Proton/CrossOver.

| Dimension | Assessment |
|---|---|
| Engineering complexity | **Low.** The Windows fix is 1 byte; the rest is configuration. |
| Performance | **Medium.** Inherent layer cost, but the game is from 2012 and GPU-bound work is trivial for a 2026 GPU. Rosetta-era CPU translation is negligible here. |
| Rendering accuracy | **Medium–Low.** Depends entirely on D3DX effect fidelity across DXVK/MoltenVK. Post-processing (HDR, bloom, DoF) is the most translation-sensitive part of any renderer. |
| Audio fidelity | **Medium.** DirectSound maps well; DirectShow/MCI MP3 and DirectMusic MIDI are the weak points. |
| Input handling | **Good.** DirectInput8 is well covered. |
| Multiplayer | **Poor.** DirectPlay 8 is unavailable on Linux/macOS and deprecated on Windows. |
| Maintainability | **Good.** No code to maintain, but also no code to fix. Brittle to Wine/DXVK updates. |
| Distribution | **Poor, and legally constrained.** The author's licence (`ReadMe-English.txt` lines 20–29) forbids distribution. Any layer bundle is also a redistributable-assembly problem. |

#### B. Hybrid — replace only incompatible components

Keep the original binary; supply replacement implementations for the parts that cannot work
(e.g. a `DSOUND`/`D3DX`/DirectPlay shim DLL, or a launcher that patches at run time).

| Dimension | Assessment |
|---|---|
| Engineering complexity | **Medium–High.** Requires implementing actual interfaces (`IDirectPlay8Peer`, D3DX effect compiler) against a binary you cannot see the source of. |
| Performance | **Good** — only the replaced subsystems pay a cost. |
| Rendering accuracy | **Good** if D3DX is replaced with a faithful implementation; **unknown** effort. |
| Audio fidelity | **Good.** |
| Input handling | **Unchanged.** |
| Multiplayer | **Best available route** if a DirectPlay replacement is built, but that is effectively writing a new network layer and requires the peer to run the same shim. |
| Maintainability | **Medium.** You own the shims. |
| Distribution | **Better than A** — shims are your own code, though the game itself still cannot be distributed. |

#### C. Native reconstruction / recompilation

| Dimension | Assessment |
|---|---|
| Engineering complexity | **Very high.** 3.1 MB of `.text`, no source, no symbols, no PDB, packed binary, anti-tamper, custom BSP renderer, `.x` model pipeline, D3DX effects, DirectPlay. |
| Performance | Best possible outcome. |
| Rendering accuracy | Only as accurate as the reimplementation effort allows. |
| Audio fidelity | Same. |
| Input handling | Requires rebuild. |
| Multiplayer | Requires rebuild. |
| Maintainability | Best long-term, worst to achieve. |
| Distribution | Still legally constrained by the original licence. |
| **Feasibility** | **Not justified.** Static recompilation is the wrong tool: the game is already x86, so there is no ISA to translate. This is Win32→POSIX + D3D9→Metal work, which is what Wine already does. |

### Recommendation

**Strategy A as the primary route; Strategy B only for specific, proven blockers.**

Rationale, tied to evidence:

1. The Windows defect is a 1-byte implementation fingerprint, not an architectural problem.
   That favours A over a rewrite.
2. **Strategy C is disqualified**, not by preference but by structure: static recompilation
   solves ISA translation, and this binary needs none. Choosing C on a 287 MB packed
   commercial binary with no symbols would be an unjustified multi-year commitment.
3. **Strategy B becomes necessary only if T-13 (D3DX under DXVK) fails.** That single
   experiment decides between "A is sufficient" and "B is required". It must be run before
   any strategy is committed to.
4. **Multiplayer is the one area where B is unavoidable**, because DirectPlay 8 has no modern
   replacement. If network play is a hard requirement, scope it as a separate project with its
   own risk assessment — do not let it block single-player preservation.

**This recommendation is provisional and is explicitly submitted to Claude for challenge
(R-05).** It must not be treated as settled until that review completes.

---

## Phase 6 — Quality gates and release

| ID | Gate | Requirement |
|---|---|---|
| Q-01 | Reproducible build | Patched binary produced from the reference by a committed script; output hash recorded |
| Q-02 | Evidence complete | Every PASS row in `docs/COMPATIBILITY-MATRIX.md` cites an evidence file |
| Q-03 | No overclaiming | No platform marked compatible without execution evidence for gameplay |
| Q-04 | Original artifacts immutable | `SK-Main.exe`, `SK-Startup.exe`, `SKGuard.dll`, the DLLs and all data files unchanged from commit `747f22e` |
| Q-05 | Licence respected | No distribution of game binaries; the author's restriction honoured |
| Q-06 | Regression set | The Phase 0 harness scripts still reproduce the baseline failure identically |
| Q-07 | Release audit | Independent release-auditor sign-off (Claude) before any tag |

**Q-04 is checkable and should be checked in CI:** compare `git hash-object` of the tracked
binaries against the commit. Any accidental modification of an original is a build failure.

---

## Immediate next actions

| # | Action | Agent | Why now |
|---|---|---|---|
| 1 | **T-01b — reach a playable match** | Codex branch `codex/t01b-gameplay` | ✅ T-01 unblocked the path; a playable match is the last Windows gate. All input mechanics are now documented in `docs/DELEGATION.md` |
| 2 | **R-01 — independent root-cause review** | Claude | The fix's validity rests on one arithmetic chain; it needs a second pair of eyes before it becomes canonical |
| 3 | **R-02 — patch blast-radius review** | Claude | Confirms `0x1f4d50` gates only the anti-hook verdict |
| 4 | **T-03 — registry-dialog fix** | Codex branch `codex/t03-startup-registry` | Removes two user-visible defects; independent of the fatal one |
| 5 | **T-04 — audio verification** | Codex branch `codex/t04-audio` | All three paths are loaded but unheard |

Branches are disjoint by file ownership: T-01b/T-04/T-05 touch only `tools/` + `docs/evidence/`,
T-03 touches `tools/patch_startup.py` (new). No task edits an original game binary in the
working tree.

**Complete briefs for every open task are in `docs/DELEGATION.md`.** They include the
verified input mechanics (E0-extended DIK scancodes + `AttachThreadInput` focus forcing) so
Codex does not have to rediscover the focus problem that cost four failed attempts.
