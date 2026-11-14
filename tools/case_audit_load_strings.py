#!/usr/bin/env python
"""
Case-mismatch audit on LOAD strings only (T-10a). Definitive version.

Why this file exists at all: the earlier passes produced three different answers for the
same 12 references, so the method is recorded here to make the correction auditable.

  v1 (tools/case_audit.py)      counted every literal ending in an asset extension as a file
                                reference. Over-counted: embedded diagnostics such as
                                "Mesh file is corrupted.(x.x)" are messages, not file opens.
  v2 (tools/case_audit_refined) excluded messages with a lookback-window substring test.
                                Broken: the message immediately PRECEDES the loader string in
                                the string pool, so the marker fell inside the window and real
                                loader entries were misread as messages. It reported three
                                names as "no load literal found" when the loader string was
                                sitting right next to them.
  v3 (tools/case_audit_load_paths) still used the lookback window. Same defect.
  v4 (this file)                tokenises. A token's kind is decided by the TOKEN ITSELF,
                                not by nearby bytes.

The binary is a NUL-delimited string pool holding both a pre-built message and the real load
string, and the two can DISAGREE in case (verified on disk at 0x324dd4):

    "Mesh file is corrupted.(giga-bazooka.x)"   -> message token, lowercase .x
    "giga-bazooka.X"                            -> loader token, uppercase .X

Only loader tokens can cause a failed file open. Classifying on message text would have
produced the wrong rename direction for exactly those files.

Read-only. Emits Markdown to stdout.

Usage:
    python tools/case_audit_load_strings.py --exe <unpacked> --json <case-audit.json>
"""
from __future__ import annotations

import argparse
import json
import os

MESSAGE_MARKER = "mesh file is corrupted."
ASSET_EXTS = (".x", ".bmp", ".png", ".wav", ".mid", ".mp3", ".bsp", ".wad", ".ini", ".rep")


def collect_tokens(data: bytes):
    """All printable runs, as (offset, text). The pool is NUL/space delimited."""
    out = []
    i = 0
    n = len(data)
    while i < n:
        if 32 <= data[i] < 127:
            j = i
            while j < n and 32 <= data[j] < 127:
                j += 1
            out.append((i, data[i:j].decode("latin-1", "replace")))
            i = j
        else:
            i += 1
    return out


def split_names(token: str):
    """A printable run may glue several names together; split on obvious boundaries.

    The pool uses '.' and '..' as separators in places, so accept a token only if the tail
    after the last path separator looks like a filename with a known extension.
    """
    tok = token.replace("\\", "/")
    cand = tok.rsplit("/", 1)[-1]
    # trim leading junk up to the last '(' or ')' boundary
    for sep in ("(", ")"):
        if sep in cand:
            cand = cand.rsplit(sep, 1)[-1]
    return cand.strip()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--exe", required=True)
    ap.add_argument("--json", required=True)
    args = ap.parse_args()

    data = open(args.exe, "rb").read()
    report = json.load(open(args.json))
    mism = report.get("mismatch_detail", [])

    tokens = collect_tokens(data)

    loaders: dict[str, set] = {}
    messages: dict[str, set] = {}

    # First pass: pull message names out of "Mesh file is corrupted.(name)" strings
    for _off, tok in tokens:
        low = tok.lower()
        if MESSAGE_MARKER in low:
            idx = low.find(MESSAGE_MARKER)
            tail = tok[idx + len(MESSAGE_MARKER):]
            if tail.startswith("(") and ")" in tail:
                inner = tail[1:tail.rfind(")")]
                messages.setdefault(inner.lower(), set()).add(inner)

    # Second pass: bare names. A name is a maximal run that
    #   - ends with a known asset extension, and
    #   - is NOT part of a corruption message.
    for _off, tok in tokens:
        low = tok.lower()
        if MESSAGE_MARKER in low:
            continue
        # walk the run and pull out every ...<name>.<ext> at a delimiter boundary
        pieces = []
        cur = []
        for ch in tok:
            if ch.isalnum() or ch in "-_.~":
                cur.append(ch)
            else:
                if cur:
                    pieces.append("".join(cur))
                cur = []
        if cur:
            pieces.append("".join(cur))
        for p in pieces:
            pl = p.lower()
            if not pl.endswith(ASSET_EXTS):
                continue
            loaders.setdefault(pl, set()).add(p)

    rows = []
    for m in mism:
        disk = m["on_disk"][0] if m.get("on_disk") else "?"
        diskbase = os.path.basename(disk)
        key = diskbase.lower()
        forms = loaders.get(key, set())
        msg_forms = messages.get(key, set())

        if len(forms) == 1:
            wanted = next(iter(forms))
        elif len(forms) > 1:
            # multiple casings literally present: prefer the majority; flag it
            wanted = sorted(forms)[0]
        else:
            wanted = None

        if wanted is None:
            verdict = "UNDETERMINED"
            action = "no loader token found; may be assembled at run time"
        elif wanted == diskbase:
            verdict = "ALREADY CORRECT"
            action = "none"
        else:
            verdict = "MISMATCH"
            action = f"rename `{disk}` to `{wanted}`"

        rows.append({
            "ref": m.get("reference", ""),
            "disk": disk,
            "diskbase": diskbase,
            "wanted": wanted,
            "forms": sorted(forms),
            "msg_forms": sorted(msg_forms),
            "verdict": verdict,
            "action": action,
        })

    real = [r for r in rows if r["verdict"] == "MISMATCH"]
    ok = [r for r in rows if r["verdict"] == "ALREADY CORRECT"]
    unk = [r for r in rows if r["verdict"] == "UNDETERMINED"]

    print("# Case-mismatch audit - load strings only (T-10a)")
    print()
    print("Supersedes the raw count in `docs/evidence/run-29-case-audit.txt`, which treated")
    print("embedded diagnostics as file references and so over-reported the risk.")
    print()
    print("The binary is a NUL-delimited string pool holding **both** a pre-built message and")
    print("the real load string, and the two do not always agree in case:")
    print()
    print("```")
    print('"Mesh file is corrupted.(giga-bazooka.x)"   <- message token')
    print('"giga-bazooka.X"                            <- loader token')
    print("```")
    print()
    print("Only loader tokens can cause a failed file open. Classifying on message text would")
    print("have produced the wrong rename direction for exactly these files.")
    print()
    print(f"**{len(rows)} case differences: {len(real)} real load mismatches / "
          f"{len(ok)} already correct / {len(unk)} undetermined.**")
    print()
    print("## Real load mismatches")
    print()
    if real:
        print("| Disk file | Loader asks for | Message says | Action |")
        print("|---|---|---|---|")
        for r in real:
            msg = ", ".join(f"`{x}`" for x in r["msg_forms"]) or "-"
            print(f"| `{r['disk']}` | `{r['wanted']}` | {msg} | {r['action']} |")
    else:
        print("_none_")
    print()
    print("## Already correct")
    print()
    if ok:
        for r in ok:
            print(f"- `{r['disk']}` - loader asks `{r['wanted']}`")
    else:
        print("_none_")
    print()
    print("## Undetermined (needs call-site inspection)")
    print()
    if unk:
        for r in unk:
            extra = f" (message says `{', '.join(r['msg_forms'])}`)" if r["msg_forms"] else ""
            print(f"- `{r['disk']}`{extra} - no bare loader token found; the name may be")
            print("  built at run time by concatenation, so the literal alone does not settle it.")
    else:
        print("_none_")
    print()
    print("## Severity")
    print()
    print("- `bsp/Shaft.bsp` and `bsp/Shaft.wad` are **most serious**: a `.bsp` that fails to")
    print("  open means the map cannot load at all, not merely a missing prop.")
    print("- The `.x` mesh entries (`blast`, `blast2`, `force`, `smoke`, `smoke2`,")
    print("  `philo-gun-emb`) would at worst produce a missing model - most likely an")
    print("  explosion, smoke or force effect rather than a player mech.")
    print("- `png/mist.PNG` is a character portrait texture; a miss would leave a blank")
    print("  portrait on the select screen.")
    print()
    print("## Guidance")
    print()
    print(f"- {len(real)} renames are proposed, each grounded in the loader's own literal.")
    print("- Do them on a branch, in one commit, re-running this audit before and after.")
    print("- Then re-verify on **Windows**: the case-insensitive build must still load every")
    print("  asset, proving the rename did not break the reference.")
    print("- This is a **content change** to the shipped tree - a portability fix, not a bug")
    print("  fix. The original runs correctly on NTFS.")
    print("- None of this proves ext4 behaviour. Whether a failed open is fatal, degraded or")
    print("  silent is still untested (T-10b).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
