#!/usr/bin/env python
"""
Locate candidate code for the 1800-second session cap (T-11 static side).

Runtime evidence (run-48) proves the cap fires at exactly 1800.067 s. This tool looks for
the constant in the executable's code so the mechanism can be named statically, independently
of the runtime observation.

Candidate encodings:
    1800000   = 0x1B7740  as a 32-bit immediate   (ms, the tick unit this engine uses)
    1800      = 0x000708  as a 32-bit immediate   (seconds)
    1800.0f   = 0x44E10000                        (float)
    1800.0    = 0x409C200000000000                (double)
    30        = 0x1E                              (minutes; too common to be useful alone)

For each hit the tool reports the containing section, the RVA, and disassembles a window
around it so the comparison and the branch that follows are visible. A hit is only
interesting when it sits inside a cmp/sub/add and is followed by a conditional jump.

Read-only. Emits a report to stdout.

Usage:
    python tools/find_time_cap.py --exe .analysis/unpacked/SK-Main.unpacked.exe
"""
from __future__ import annotations

import argparse
import struct

import pefile
from capstone import CS_ARCH_X86, CS_MODE_32, Cs


ENCODINGS = {
    "1800000 (u32 ms)": struct.pack("<I", 1800000),
    "1800000 (i32)":    struct.pack("<i", 1800000),
    "1800 (u32)":       struct.pack("<I", 1800),
    "1800.0f":          struct.pack("<f", 1800.0),
    "1800.0d":          struct.pack("<d", 1800.0),
}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--exe", required=True)
    ap.add_argument("--window", type=int, default=14, help="instructions of context")
    args = ap.parse_args()

    data = open(args.exe, "rb").read()
    pe = pefile.PE(args.exe, fast_load=True)

    # Build a file-offset -> RVA map from the section table
    sections = []
    for s in pe.sections:
        name = s.Name.rstrip(b"\x00").decode("latin-1", "replace")
        sections.append((name, s.VirtualAddress, s.PointerToRawData,
                         s.Misc_VirtualSize, s.SizeOfRawData))
    pe.close()

    def locate(off: int):
        for name, va, raw, vsize, rsize in sections:
            if raw <= off < raw + rsize:
                return name, va + (off - raw)
        return None, None

    md = Cs(CS_ARCH_X86, CS_MODE_32)

    print("# Static search for the 1800-second cap constant")
    print()
    print("Runtime evidence (run-48) fixes the cap at **1800.067 s**. This search asks whether")
    print("the constant is present in code, which would confirm it is compiled in rather than")
    print("read from a file, and would name the comparison.")
    print()

    grand = 0
    for label, pat in ENCODINGS.items():
        hits = []
        pos = 0
        while True:
            pos = data.find(pat, pos)
            if pos < 0:
                break
            sec, rva = locate(pos)
            if sec is not None:
                hits.append((pos, sec, rva))
            pos += 1
        print(f"## {label} - {len(hits)} hit(s) inside sections")
        print()
        if not hits:
            print("_none_")
            print()
            continue
        for off, sec, rva in hits[:12]:
            print(f"### file 0x{off:x} · {sec} · RVA 0x{rva:x} · VA 0x{0x400000 + rva:x}")
            # disassemble a small lead-in so the comparison context is visible
            start = max(0, rva - 40)
            code = data[off - (rva - start): off + 48]
            print("```")
            shown = 0
            for ins in md.disasm(code, 0x400000 + start):
                mark = " <== constant here" if ins.address <= 0x400000 + rva < ins.address + ins.size else ""
                print(f"  0x{ins.address:08x}  {ins.mnemonic:<7} {ins.op_str}{mark}")
                shown += 1
                if shown >= args.window:
                    break
            print("```")
            print()
            grand += 1
        if len(hits) > 12:
            print(f"_... and {len(hits) - 12} more_")
            print()

    print("## Reading the result")
    print()
    print(f"Total code sites disassembled: {grand}")
    print()
    print("- A hit inside `cmp`/`sub` followed by `jae`/`jbe`/`jb`/`ja` is a plausible limit test.")
    print("- A hit in `.rdata`/`.data` is a stored value, not a comparison - it would have to be")
    print("  loaded first, so look for the `mov`/`fld` that references it.")
    print("- **Absence is also informative**: if no immediate 1800000 or 1800 appears in code,")
    print("  the cap is probably computed (start tick vs current tick against a stored limit) or")
    print("  encoded as a float constant that this search did not guess correctly. That would")
    print("  not weaken the runtime finding, only leave its mechanism unnamed.")
    print("- This tool does NOT prove which site is the cap. `run-51` and a targeted breakpoint")
    print("  experiment would. Treat any single hit as a candidate, not a conclusion.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
