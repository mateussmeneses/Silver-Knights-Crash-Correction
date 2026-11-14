#!/usr/bin/env python
"""
Case-sensitivity audit for a Windows game tree, for Linux/macOS portability.

Extracts every asset filename the executable references as a literal string, then checks
whether that exact casing resolves against the files on disk. On a case-insensitive
filesystem (NTFS) a mismatch is invisible; on ext4/APFS-case-sensitive it is fatal.

Read-only. Emits a report of:
  * referenced names that do not exist at all          -> missing asset
  * referenced names that exist only with different case -> CASE MISMATCH (Linux blocker)
  * files on disk never referenced by any literal      -> informational

Usage:
    python tools/case_audit.py --exe <unpacked exe> --root <game dir> [--json out.json]
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys

# Extensions the engine loads from disk as literal names.
ASSET_EXT = {
    ".x", ".bmp", ".png", ".wav", ".mid", ".mp3", ".ini", ".rep",
    ".bsp", ".wad", ".txt", ".log", ".jpg",
}

# Strings that look like a path/asset: has an asset extension and no format specifiers,
# no spaces at the ends, and is plausible as a filename.
PRINTABLE = re.compile(rb"[\x20-\x7e]{4,}")


def extract_refs(exe_path: str) -> set:
    data = open(exe_path, "rb").read()
    refs = set()
    for m in PRINTABLE.finditer(data):
        try:
            s = m.group().decode("latin-1")
        except Exception:
            continue
        s = s.strip()
        if not s or " " in s or "%" in s or "\t" in s:
            continue
        _, ext = os.path.splitext(s.lower())
        if ext in ASSET_EXT:
            # discard obvious non-filenames
            if len(s) > 120 or s.count("/") > 4 or s.count("\\") > 4:
                continue
            refs.add(s)
    return refs


def build_disk_index(root: str):
    """Map lowercase relative path -> list of actual relative paths."""
    index = {}
    all_files = []
    for dirpath, _dirnames, filenames in os.walk(root):
        for fn in filenames:
            full = os.path.join(dirpath, fn)
            rel = os.path.relpath(full, root).replace("\\", "/")
            all_files.append(rel)
            index.setdefault(rel.lower(), []).append(rel)
    return index, all_files


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--exe", required=True, help="unpacked SK-Main.exe (literal strings are in plaintext there)")
    ap.add_argument("--root", required=True, help="game directory to audit")
    ap.add_argument("--json", default=None)
    ap.add_argument("--show-ok", action="store_true", help="also list references that resolve exactly")
    args = ap.parse_args()

    refs = extract_refs(args.exe)
    index, all_files = build_disk_index(args.root)
    have_exact = set(all_files)

    exact, mismatch, missing = [], [], []
    for r in sorted(refs):
        cand = r.replace("\\", "/")
        if cand in have_exact:
            exact.append(cand)
            continue
        hits = index.get(cand.lower())
        if hits:
            mismatch.append({"reference": cand, "on_disk": hits})
        else:
            # try matching by basename anywhere (engine may resolve via search path)
            base = os.path.basename(cand).lower()
            bm = [f for f in all_files if os.path.basename(f).lower() == base]
            if bm:
                if os.path.basename(cand) not in {os.path.basename(x) for x in bm}:
                    mismatch.append({"reference": cand, "on_disk": bm[:5],
                                     "note": "basename matches but casing differs (different directory)"})
                else:
                    exact.append(cand + "  (resolved by basename)")
            else:
                missing.append(cand)

    report = {
        "exe": args.exe,
        "root": args.root,
        "references_total": len(refs),
        "exact_matches": len(exact),
        "case_mismatches": len(mismatch),
        "missing": len(missing),
        "mismatch_detail": mismatch,
        "missing_detail": missing,
        "disk_files": len(all_files),
    }

    print("=" * 72)
    print("CASE-SENSITIVITY AUDIT")
    print("=" * 72)
    print(f"executable analysed : {args.exe}")
    print(f"game root           : {args.root}")
    print(f"literal asset refs  : {report['references_total']}")
    print(f"files on disk       : {report['disk_files']}")
    print()
    print(f"exact-case match    : {report['exact_matches']}")
    print(f"CASE MISMATCHES     : {report['case_mismatches']}   <-- would FAIL on ext4/APFS")
    print(f"missing entirely    : {report['missing']}")
    print()

    if mismatch:
        print("-" * 72)
        print("CASE MISMATCHES (Linux/macOS blocker if the engine uses exact names)")
        print("-" * 72)
        for m in mismatch:
            print(f"  ref : {m['reference']}")
            for d in m["on_disk"]:
                print(f"  disk: {d}")
            if m.get("note"):
                print(f"        {m['note']}")
            print()

    if missing:
        print("-" * 72)
        print("MISSING (not on disk at all; may be optional or generated at runtime)")
        print("-" * 72)
        for m in missing[:60]:
            print(f"  {m}")
        if len(missing) > 60:
            print(f"  ... and {len(missing) - 60} more")
        print()

    if args.show_ok:
        print("-" * 72)
        print("EXACT MATCHES")
        print("-" * 72)
        for e in exact[:200]:
            print(f"  {e}")
        print()

    # verdict
    print("=" * 72)
    if mismatch or missing:
        print("VERDICT: case-sensitivity risk PRESENT - see mismatches above.")
        print("         These references may fail to open on a case-sensitive filesystem.")
    else:
        print("VERDICT: no case-sensitivity risk found for the audited references.")
    print("=" * 72)

    if args.json:
        with open(args.json, "w", encoding="utf-8") as fh:
            json.dump(report, fh, indent=2)
        print(f"\nJSON -> {args.json}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
