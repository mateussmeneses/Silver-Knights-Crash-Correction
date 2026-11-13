#!/usr/bin/env python
"""
Find the shutdown path positively, by locating the "End" log-string writer (T-11 mechanism).

Rationale: a byte search for the 1800 s constant failed (tools/find_time_cap.py) because x86
gives too many false positives and the value is probably a timestamp difference, not a
literal. A far better anchor is the game's own orderly-shutdown log line:

    "SK-Main.exe End   <------------------------"

That string is in the binary, it is written exactly once per orderly exit, and the function
that writes it is therefore the tail of the shutdown path. Walking that function's CALLERS
backwards is a positive identification of who decides to shut down - including any time
comparison - rather than a guess at constants.

This tool:
  1. locates the End-string literal and the Start-string literal,
  2. finds which .text address references each (push <addr> / mov reg, <addr>),
  3. disassembles a window around each reference so the log-write site is visible,
  4. prints the enclosing call targets so the next step (walking callers) is concrete.

Read-only.

Usage:
    python tools/find_shutdown_path.py --exe .analysis/unpacked/SK-Main.unpacked.exe
"""
from __future__ import annotations

import argparse
import struct

import pefile
from capstone import CS_ARCH_X86, CS_MODE_32, Cs


MAIN = 0x400000


def strings_with_offsets(data: bytes):
    """Yield (file_offset, text) for printable NUL/CR-terminated runs."""
    i = 0
    n = len(data)
    while i < n:
        if 32 <= data[i] < 127:
            j = i
            while j < n and (32 <= data[j] < 127 or data[j] in (0x09,)):
                j += 1
            yield i, data[i:j].decode("latin-1", "replace")
            i = j
        else:
            i += 1


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--exe", required=True)
    args = ap.parse_args()

    data = open(args.exe, "rb").read()
    pe = pefile.PE(args.exe, fast_load=True)
    secs = []
    for s in pe.sections:
        name = s.Name.rstrip(b"\x00").decode("latin-1", "replace")
        secs.append((name, s.VirtualAddress, s.PointerToRawData,
                     s.Misc_VirtualSize, s.SizeOfRawData))
    pe.close()

    def off_to_rva(off: int):
        for name, va, raw, vsize, rsize in secs:
            if raw <= off < raw + rsize:
                return name, va + (off - raw)
        return None, None

    print("# Shutdown-path anchor search")
    print()
    print("The orderly-shutdown log line is the most reliable anchor in this binary: it is")
    print("written once per clean exit, and we can observe it happen (`run-48`).")
    print()

    wanted = {
        "End line":   "SK-Main.exe End",
        "Start line": "SK-Main.exe Start",
        "mailslot":   "mailslot",
    }

    found = {}
    for off, text in strings_with_offsets(data):
        for label, needle in wanted.items():
            if needle in text and label not in found:
                sec, rva = off_to_rva(off)
                if sec is None:
                    continue
                found[label] = (off, sec, rva, text.strip())

    for label in wanted:
        if label not in found:
            print(f"## {label} - NOT FOUND")
            print()
            continue
        off, sec, rva, text = found[label]
        va = MAIN + rva
        print(f"## {label}")
        print()
        print(f"- file offset `0x{off:x}` · section `{sec}` · RVA `0x{rva:x}` · VA `0x{va:x}`")
        print(f"- text: `{text[:80]}`")
        print()

        # find references to this VA: push imm32 (0x68) or mov reg, imm32 (0xB8+r or 0xC7 /0)
        refs = []
        needle_push = b"\x68" + struct.pack("<I", va)
        pos = 0
        while True:
            pos = data.find(needle_push, pos)
            if pos < 0:
                break
            s2, r2 = off_to_rva(pos)
            if s2 is not None:
                refs.append(("push", pos, r2))
            pos += 1
        # mov r32, imm32  -> B8..BF
        for reg in range(8):
            needle_mov = bytes([0xB8 + reg]) + struct.pack("<I", va)
            pos = 0
            while True:
                pos = data.find(needle_mov, pos)
                if pos < 0:
                    break
                s2, r2 = off_to_rva(pos)
                if s2 is not None:
                    refs.append((f"mov r{reg}", pos, r2))
                pos += 1

        if not refs:
            print("  no `push`/`mov` immediate reference found - the address may be computed")
            print("  (base register + offset) or the string is referenced via a wrapper.")
            print()
            continue

        md = Cs(CS_ARCH_X86, CS_MODE_32)
        for kind, roff, rrva in refs[:6]:
            print(f"### referenced by `{kind}` at file `0x{roff:x}` · RVA `0x{rrva:x}` · VA `0x{MAIN + rrva:x}`")
            start_rva = max(0, rrva - 64)
            code = data[roff - (rrva - start_rva): roff + 96]
            print("```")
            calls = []
            shown = 0
            for ins in md.disasm(code, MAIN + start_rva):
                marker = ""
                if ins.address <= MAIN + rrva < ins.address + ins.size:
                    marker = " <== string ref"
                if ins.mnemonic == "call":
                    calls.append(ins.op_str)
                print(f"  0x{ins.address:08x}  {ins.mnemonic:<7} {ins.op_str}{marker}")
                shown += 1
                if shown >= 26:
                    break
            print("```")
            if calls:
                print(f"  call targets in window: {', '.join(calls)}")
            print()

    print("## Next step (not done by this tool)")
    print()
    print("1. Take the enclosing function's start address for the reference above.")
    print("2. Find its CALLERS with `tools/disasm_exports.py`-style xref scanning, or in REA:")
    print("     mcp__rea__procedure_callers at that address")
    print("3. Walk up until a caller is guarded by a time comparison. That caller is the cap.")
    print()
    print("This is the positive route. A byte search for 1800000 was already tried and found")
    print("nothing, which is itself a useful negative - see")
    print("docs/evidence/t11-time-cap-search-analysis.txt.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
