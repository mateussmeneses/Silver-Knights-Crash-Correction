#!/usr/bin/env python
"""
Locate code cross-references to a string/VA inside a PE image.

Maps a file offset to an RVA (and VA), then searches .text for 4-byte
little-endian occurrences of that VA (the `push imm32` idiom used by VC6).

Read-only.

Usage:
    python tools/find_xrefs.py .analysis/unpacked/SK-Main.unpacked.exe --file-offset 0x32b054
    python tools/find_xrefs.py file.exe --rva 0x2b054
"""
from __future__ import annotations

import argparse

import pefile


def file_off_to_rva(pe, off: int):
    for s in pe.sections:
        start = s.PointerToRawData
        end = start + s.SizeOfRawData
        if start <= off < end:
            return s.VirtualAddress + (off - start)
    return None


def rva_to_section(pe, rva: int):
    for s in pe.sections:
        vsize = max(s.Misc_VirtualSize, s.SizeOfRawData)
        if s.VirtualAddress <= rva < s.VirtualAddress + vsize:
            return s
    return None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("path")
    ap.add_argument("--file-offset", default=None)
    ap.add_argument("--rva", default=None)
    ap.add_argument("--ascii", default=None, help="find the string first, then xref it")
    args = ap.parse_args()

    pe = pefile.PE(args.path, fast_load=True)
    base = pe.OPTIONAL_HEADER.ImageBase
    img = pe.get_memory_mapped_image()

    if args.ascii:
        needle = args.ascii.encode("latin-1")
        idx = open(args.path, "rb").read().find(needle)
        if idx < 0:
            print(f"string {args.ascii!r} not found")
            return 1
        rva = file_off_to_rva(pe, idx)
        print(f"string {args.ascii!r} file_offset=0x{idx:x} rva=0x{rva:x} va=0x{base + rva:x}")
    elif args.file_offset:
        rva = file_off_to_rva(pe, int(args.file_offset, 0))
        print(f"file_offset=0x{int(args.file_offset,0):x} rva=0x{rva:x} va=0x{base + rva:x}")
    elif args.rva:
        rva = int(args.rva, 0)
        print(f"rva=0x{rva:x} va=0x{base + rva:x}")
    else:
        ap.error("need --file-offset, --rva or --ascii")

    target = base + rva
    needle = target.to_bytes(4, "little")

    text = rva_to_section(pe, rva)
    print(f"containing section: {text.Name.rstrip(chr(0).encode()).decode('latin-1') if text else '?'}")

    hits = []
    for s in pe.sections:
        name = s.Name.rstrip(b"\x00").decode("latin-1")
        if not (s.Characteristics & 0x20000000):  # IMAGE_SCN_MEM_EXECUTE
            continue
        data = s.get_data()
        pos = 0
        while True:
            pos = data.find(needle, pos)
            if pos < 0:
                break
            hits.append((name, s.VirtualAddress + pos))
            pos += 1

    print(f"\n{len(hits)} reference(s) to 0x{target:x}:")
    for name, hit_rva in hits:
        print(f"  {name}  rva=0x{hit_rva:x}  va=0x{base + hit_rva:x}")

    pe.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
