#!/usr/bin/env python
"""
Disassemble a VA range of a PE (x86/x64) with capstone, annotating call targets.

Read-only.

Usage:
    python tools/disasm_range.py file.exe --va 0x5f4d00 --length 0x400
    python tools/disasm_range.py file.exe --rva 0x1f4d00 --length 0x400
"""
from __future__ import annotations

import argparse

import capstone
import pefile


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("path")
    ap.add_argument("--va", default=None)
    ap.add_argument("--rva", default=None)
    ap.add_argument("--length", default="0x300")
    args = ap.parse_args()

    pe = pefile.PE(args.path, fast_load=True)
    pe.parse_data_directories(
        directories=[
            pefile.DIRECTORY_ENTRY["IMAGE_DIRECTORY_ENTRY_IMPORT"],
            pefile.DIRECTORY_ENTRY["IMAGE_DIRECTORY_ENTRY_EXPORT"],
        ]
    )
    base = pe.OPTIONAL_HEADER.ImageBase
    img = pe.get_memory_mapped_image()
    is64 = pe.FILE_HEADER.Machine == 0x8664
    md = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_64 if is64 else capstone.CS_MODE_32)

    rva = int(args.rva, 0) if args.rva else int(args.va, 0) - base
    length = int(args.length, 0)
    print(f"VA=0x{base + rva:x} RVA=0x{rva:x} length=0x{length:x}")

    # Build import IAT label map
    iat = {}
    for entry in getattr(pe, "DIRECTORY_ENTRY_IMPORT", []) or []:
        dll = entry.dll.decode("latin-1")
        for imp in entry.imports:
            if imp.address:
                nm = imp.name.decode("latin-1") if imp.name else f"ordinal_{imp.ordinal}"
                iat[imp.address] = f"{dll}!{nm}"

    code = img[rva:rva + length]
    for insn in md.disasm(code, base + rva):
        note = ""
        # call/jmp [abs]
        if insn.mnemonic in ("call", "jmp") and "dword ptr [" in insn.op_str:
            try:
                inner = insn.op_str.split("[")[1].split("]")[0]
                addr = int(inner, 16)
                if addr in iat:
                    note = f"   ; {iat[addr]}"
            except Exception:
                pass
        print(f"  0x{insn.address - base:08x}  {insn.bytes.hex():<22} {insn.mnemonic:<8} {insn.op_str}{note}")

    pe.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
