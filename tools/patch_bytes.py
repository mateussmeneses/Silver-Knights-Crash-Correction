#!/usr/bin/env python
"""
Byte-level patcher for PE files with an audit trail.

The input file is NEVER modified. Output goes to --out.

Every edit is verified against the expected original bytes BEFORE anything is
written; if any edit does not match, no output file is produced.

Records, for every edit: file offset, RVA, VA, containing section, the expected
and observed original bytes, the replacement bytes and a reason string. The PE
checksum is recomputed so the result is self-consistent.

Usage:
    python tools/patch_bytes.py IN.exe --out OUT.exe \
        --edit 0x1f4d50:7e:eb --reason "why this change is correct"
    python tools/patch_bytes.py IN.exe --out OUT.exe --edit-file edits.json
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys

import pefile


def sha256_file(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def build_geometry(path: str):
    """Read only the PE geometry, then fully release the file handle."""
    pe = pefile.PE(path, fast_load=True)
    sections = [
        {
            "name": s.Name.rstrip(b"\x00").decode("latin-1"),
            "virtual_address": s.VirtualAddress,
            "raw_pointer": s.PointerToRawData,
            "raw_size": s.SizeOfRawData,
        }
        for s in pe.sections
    ]
    geometry = {
        "image_base": pe.OPTIONAL_HEADER.ImageBase,
        "checksum": pe.OPTIONAL_HEADER.CheckSum,
        "checksum_offset": pe.OPTIONAL_HEADER.get_field_absolute_offset("CheckSum"),
        "machine": pe.FILE_HEADER.Machine,
        "sections": sections,
    }
    pe.close()
    return geometry


def offset_to_rva(sections, off: int):
    for s in sections:
        if s["raw_pointer"] <= off < s["raw_pointer"] + s["raw_size"]:
            return s["virtual_address"] + (off - s["raw_pointer"]), s["name"]
    return None, None


def compute_pe_checksum(data: bytes, checksum_offset: int) -> int:
    """Microsoft PE image checksum algorithm."""
    buf = bytearray(data)
    buf[checksum_offset:checksum_offset + 4] = b"\x00\x00\x00\x00"
    if len(buf) % 2:
        buf.append(0)
    total = 0
    for i in range(0, len(buf), 2):
        total += buf[i] | (buf[i + 1] << 8)
        total = (total & 0xFFFF) + (total >> 16)
    total = (total & 0xFFFF) + (total >> 16)
    return (total + len(data)) & 0xFFFFFFFF


def load_edits(specs, edit_file, reason) -> list:
    edits = []
    for spec in specs:
        parts = spec.split(":")
        if len(parts) != 3:
            raise SystemExit(f"bad --edit {spec!r}; want OFFSET:OLDHEX:NEWHEX")
        edits.append({
            "offset": int(parts[0], 0),
            "old": bytes.fromhex(parts[1]),
            "new": bytes.fromhex(parts[2]),
            "reason": reason,
        })
    if edit_file:
        with open(edit_file) as fh:
            for e in json.load(fh):
                off = int(e["offset"], 0) if isinstance(e["offset"], str) else int(e["offset"])
                edits.append({
                    "offset": off,
                    "old": bytes.fromhex(e["old"]),
                    "new": bytes.fromhex(e["new"]),
                    "reason": e.get("reason", ""),
                })
    return edits


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("input")
    ap.add_argument("--out", required=True)
    ap.add_argument("--edit", action="append", default=[], metavar="OFFSET:OLDHEX:NEWHEX")
    ap.add_argument("--edit-file", default=None)
    ap.add_argument("--reason", default="")
    ap.add_argument("--no-checksum", action="store_true")
    args = ap.parse_args()

    if os.path.abspath(args.input) == os.path.abspath(args.out):
        raise SystemExit("refusing to overwrite the input file; choose a different --out")

    edits = load_edits(args.edit, args.edit_file, args.reason)
    if not edits:
        raise SystemExit("no edits given")

    geo = build_geometry(args.input)
    data = bytearray(open(args.input, "rb").read())

    record = []
    failures = []
    for e in edits:
        off, old, new = e["offset"], e["old"], e["new"]
        rva, secname = offset_to_rva(geo["sections"], off)
        actual = bytes(data[off:off + len(old)])
        matched = (actual == old) and (len(old) == len(new))
        record.append({
            "file_offset": f"0x{off:x}",
            "rva": f"0x{rva:x}" if rva is not None else None,
            "va": f"0x{geo['image_base'] + rva:x}" if rva is not None else None,
            "section": secname,
            "expected_old": old.hex(),
            "actual_old": actual.hex(),
            "new": new.hex(),
            "reason": e["reason"],
            "matched": matched,
        })
        if len(old) != len(new):
            failures.append(f"0x{off:x}: length mismatch {len(old)} -> {len(new)}")
        elif actual != old:
            failures.append(f"0x{off:x}: expected {old.hex()}, found {actual.hex()}")
        else:
            data[off:off + len(new)] = new

    if failures:
        print("PRECONDITION FAILED - no output written:", file=sys.stderr)
        for f in failures:
            print("  " + f, file=sys.stderr)
        print(json.dumps(record, indent=2), file=sys.stderr)
        return 1

    new_sum = None
    if not args.no_checksum:
        new_sum = compute_pe_checksum(bytes(data), geo["checksum_offset"])
        data[geo["checksum_offset"]:geo["checksum_offset"] + 4] = new_sum.to_bytes(4, "little")

    with open(args.out, "wb") as fh:
        fh.write(data)

    check = pefile.PE(args.out, fast_load=True)
    parses = check.FILE_HEADER.Machine == geo["machine"]
    check.close()

    print(json.dumps({
        "input": args.input,
        "input_size": os.path.getsize(args.input),
        "input_sha256": sha256_file(args.input),
        "output": args.out,
        "output_size": len(data),
        "output_sha256": sha256_file(args.out),
        "pe_checksum_original": f"0x{geo['checksum']:08x}",
        "pe_checksum_written": f"0x{new_sum:08x}" if new_sum is not None else None,
        "output_parses_as_pe": parses,
        "edits": record,
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
