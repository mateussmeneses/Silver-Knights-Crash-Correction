# Distribution and Release Policy

**Status:** no binary release exists, and none can be published from this repository under the
current licence. This file records why, so the question is not re-litigated every session.

---

## 1. What the game's licence actually says

From `ReadMe-English.txt` (shipped with the game, © 2003–2012 Haruo Teshima), verbatim:

> "Silver Knights" all copyrights reserved to TESHIMA.
> The author of this software will not take a responsibility for any damages that may result
> from using this software.
> **Do not change any datas in this software without permission from the author of this game.**
> If you need to do so, please ask TESHIMA.
> **Do not use this software for any commercial using.**
>
> This software is still under development, so **do not distribute or upload this software** and
> any movies of this software.
> You are able to introduce this software on the other HP. In this case, **you can use screan
> shots freely.**

Three separate clauses bear on a release:

| Clause | What it prohibits |
|---|---|
| "Do not change any datas" | The **patch itself** is a modification. Unmodified, the game does not run. |
| "do not distribute or upload this software" | A zip containing the game — the entire ask of a "release". |
| "Do not use ... commercial" | Rules out paid distribution, and by extension most storefronts. |

Granted, explicitly: **screenshots**, for the purpose of introducing the game. That is the only
permission this project relies on, and it is why the tutorial can contain images.

## 2. What that means concretely

**Not permitted, and not done:**

- publishing a zip of the game, patched or not;
- attaching the patched binaries to a GitHub release;
- committing `SK-Main.exe` / `SK-Startup.exe` to this repository (they are gitignored);
- mirroring the game anywhere.

**Permitted, and done:**

- the patch **tooling**, which contains no game code and operates on files the user supplies;
- documentation, analysis and disassembly-derived findings;
- screenshots introducing the game;
- a build script that produces patched files **in the user's own tree**.

The distinction that makes the tooling defensible: `tools/build_patched.py` is a program that
transforms bytes you already own. It is not a copy of the game, and running it creates a derived
work in your own environment rather than a redistribution by this project.

## 3. What a user should do instead

`docs/SETUP-WINDOWS.md` walks through:

1. obtaining the original from the author's site (http://philotes.sv1.sp-land.net/);
2. verifying the SHA-256 / MD5 of their copy;
3. running `tools/build_patched.py` locally;
4. copying the two patched executables into their own game folder.

This is functionally identical to the release that was requested, minus the redistribution step,
which is the part the licence forbids.

## 4. If the situation changes

A redistribution becomes possible only with the author's permission. If that is obtained, the
release should contain:

```
SK-Main.exe            patched, 1,464,320 bytes
SK-Startup.exe         patched,   102,400 bytes
SKGuard.dll            original
libeay32.dll           original
msvcr71.dll            original
SilverKnights.ini      original
1041.ini               original
mesh/ bsp/ png/ se/ logo/ mp3/ midi/ replay/    original
ReadMe-English.txt     original, unmodified — the licence must travel with the game
README.md              this policy, so recipients know what they have
```

And it must **not** contain: `docs/`, `tools/`, `.analysis/`, `.git/`, `SilverKnights.log`,
`temp/`, or any build scratch directory.

## 5. Verified state of the build this policy governs

Recorded so a future release decision rests on facts:

- `run-59` / `run-60`: a freshly built patched pair was installed over a full game tree and
  reached a **live match** (timer advancing, HUD rendering, no error dialog). Two independent
  builds reproduced identical hashes:
  - `SK-Main.exe` md5 `0c4de1d940cf176f87bf86b4c7777d38`, 1,464,320 bytes
  - `SK-Startup.exe` md5 `721641895cc342df9607e55b63d426b7`
- The originals in the repository are **byte-identical to base commit `747f22e`**, verified
  before and after every experiment.
- What is still untested, and therefore must not be claimed in any release note: network play,
  controller support, Linux, macOS, Story Mode, replay recording.

### The archive, and its canonical hash

`tools/build_release.py` produces the distributable package. **This is the canonical artefact:**

```
build-release/SilverKnights-0.13-Windows11.zip
  63,889,891 bytes
  sha256 11e40b9adfc627c63ed0a968d24b3c68f86f37a5181158f48c861ec2cc4acea8
  md5    7fe3122b11208f2ab966f782ed76cd95
  782 entries · zip integrity OK · manifest self-consistent (781/781 verified)
```

**It is byte-for-byte reproducible.** Two builds from identical inputs produced the identical
hash, which means a published hash can be re-derived by anyone who has the source tree and the
original game. That required pinning every zip entry's timestamp — without that, zip stores
per-entry mtime and two builds minutes apart necessarily differ.

Making it reproducible exposed three real bugs in my own tooling, each caught by measuring
rather than assuming:

| Symptom | Actual cause |
|---|---|
| Two builds, different SHA-256 (148 bytes apart) | the pre-fix manifest had a bare title line a verifier parses as a filename |
| Archive 66 MB instead of 64 MB | `writestr()` ignores `ZipFile`-level `compresslevel` **and** `ZipInfo.compress_level`; the level must be passed as an argument. I first misdiagnosed this as leaked build files. |
| Risk of shipping build machinery | `build_patched.py` writes `build-patched/` **inside** `game-dir`, so a naive copy of the game folder would ship it. Now `EXCLUDE_DIRS` plus a post-staging sweep that strips and reports anything non-shippable. |

The superseded archives were **deleted** rather than kept. Two zips in circulation with different
hashes is how a release loses trust: a recipient checking a hash against the wrong build would
conclude the download had been tampered with.

Note the earlier, pre-fix archive differed from its successor in **exactly one file** —
`MANIFEST.md5` — which an entry-by-entry comparison proved. Every game file was identical, so the
difference was cosmetic; it was still discarded, because "cosmetic" is not a thing a recipient
can verify.

## 6. One honest caveat about the patch itself

The patch disables an anti-tamper check. That is the point of it — the check misfires on modern
Windows — but it means this build cannot be used where cheat detection matters. Any release note
must say so plainly rather than presenting the patch as a pure improvement. For archival and
single-player use it is appropriate; for anything competitive it is not.
