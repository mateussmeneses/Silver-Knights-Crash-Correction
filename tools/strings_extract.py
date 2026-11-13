#!/usr/bin/env python
"""
Extract printable strings from a binary, with optional keyword filtering.

Read-only. Emits "offset<TAB>string" lines (offset is the file offset, not an RVA).

Usage:
    python tools/strings_extract.py <file> [--min N] [--grep KW1,KW2] [--encoding ascii|utf16]
"""
from __future__ import annotations

import argparse
import re
import sys

ASCII_RE = re.compile(rb"[\x20-\x7e]{%d,}")
UTF16_RE = re.compile(rb"(?:[\x20-\x7e]\x00){%d,}")


def extract(path: str, min_len: int, encoding: str):
    data = open(path, "rb").read()
    if encoding == "utf16":
        pattern = UTF16_RE
        for m in pattern.finditer(data):
            yield m.start(), m.group().decode("utf-16-le", "replace")
    else:
        pattern = re.compile(rb"[\x20-\x7e]{%d,}" % min_len)
        for m in pattern.finditer(data):
            yield m.start(), m.group().decode("latin-1")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("path")
    ap.add_argument("--min", type=int, default=5)
    ap.add_argument("--grep", default=None, help="comma-separated substrings, case-insensitive")
    ap.add_argument("--encoding", default="ascii", choices=["ascii", "utf16"])
    ap.add_argument("--limit", type=int, default=0)
    args = ap.parse_args()

    kws = [k.strip().lower() for k in args.grep.split(",")] if args.grep else None
    n = 0
    for off, s in extract(args.path, args.min, args.encoding):
        if kws and not any(k in s.lower() for k in kws):
            continue
        print(f"0x{off:x}\t{s}")
        n += 1
        if args.limit and n >= args.limit:
            break
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
