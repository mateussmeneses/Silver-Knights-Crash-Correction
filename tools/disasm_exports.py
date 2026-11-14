#!/usr/bin/env python
"""
Disassemble exported functions of a PE (x86/x64) using capstone.

Read-only. Prints address, bytes and mnemonic per instruction for each export.

Usage:
    python tools/disasm_exports.py SKGuard.dll
    python tools/disasm_exports.py SKGuard.dll --export _API_Hook_AllApps_Start@4 --max 400
"""
from __future__ import annotations

import argparse
import sys

import capstone
import pefile


def build_disassembler(is64: bool):
    if is64:
        md = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_64)
    else:
        md = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_32)
    md.detail = False
    return md


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("path")
    ap.add_argument("--export", default=None)
    ap.add_argument("--max", type=int, default=250)
    args = ap.parse_args()

    pe = pefile.PE(args.path, fast_load=True)
    pe.parse_data_directories(
        directories=[pefile.DIRECTORY_ENTRY["IMAGE_DIRECTORY_ENTRY_EXPORT"]]
    )
    is64 = pe.FILE_HEADER.Machine == 0x8664
    md = build_disassembler(is64)
    base = pe.OPTIONAL_HEADER.ImageBase

    exports = []
    if hasattr(pe, "DIRECTORY_ENTRY_EXPORT") and pe.DIRECTORY_ENTRY_EXPORT:
        for s in pe.DIRECTORY_ENTRY_EXPORT.symbols:
            name = s.name.decode("latin-1") if s.name else f"ordinal_{s.ordinal}"
            exports.append((name, s.address))

    if args.export:
        exports = [e for e in exports if e[0] == args.export]
        if not exports:
            print(f"export {args.export!r} not found", file=sys.stderr)
            return 1

    for name, rva in exports:
        print(f"\n===== {name}  RVA=0x{rva:x}  VA=0x{base + rva:x} =====")
        # Bound the dump to the containing section
        section = None
        for s in pe.sections:
            if s.VirtualAddress <= rva < s.VirtualAddress + max(s.Misc_VirtualSize, s.SizeOfRawData):
                section = s
                break
        if section is None:
            print("  (no containing section)")
            continue
        end = section.VirtualAddress + max(section.Misc_VirtualSize, section.SizeOfRawData)
        code = pe.get_memory_mapped_image()[rva:end]
        count = 0
        for insn in md.disasm(code, base + rva):
            print(f"  0x{insn.address - base:08x}  {insn.bytes.hex():<20} {insn.mnemonic:<8} {insn.op_str}")
            count += 1
            if count >= args.max:
                print("  ... (truncated)")
                break
    pe.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
