#!/usr/bin/env python
"""
Locate the mailslot open that leaks (T-08c).

Established by runtime evidence (run-58):
    \Device\Mailslot\SK-Startup.exe   27 -> 119 handles in 4.5 min   LEAKS
    \Device\Mailslot\SK-Main.exe       1 ->   1                     does NOT leak
    every other open path                                           static

So one code path opens the launcher mailslot repeatedly without closing it, while its peer is
opened once. This tool finds both call sites statically so the asymmetry can be read in the
code rather than only measured at runtime.

Method: the format string `\\\\.\\mailslot\\%s` lives at RVA 0x32a858 (VA 0x72a858, .data).
Find every instruction that references that VA, disassemble around it, and identify the API
call it feeds (CreateMailslotA or CreateFileA). Then do the same for the SK-Main.exe variant.

Read-only.

Usage:
    python tools/find_mailslot_calls.py --exe .analysis/unpacked/SK-Main.unpacked.exe
"""
from __future__ import annotations

import argparse
import struct

import pefile
from capstone import CS_ARCH_X86, CS_MODE_32, Cs

MAIN = 0x400000
MAILSLOT_FMT = 0x72A858   # "\\.\mailslot\%s" — confirmed in earlier string extraction


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--exe", required=True)
    args = ap.parse_args()

    data = open(args.exe, "rb").read()
    pe = pefile.PE(args.exe, fast_load=True)
    secs = []
    for s in pe.sections:
        secs.append((s.Name.rstrip(b"\x00").decode("latin-1", "replace"),
                     s.VirtualAddress, s.PointerToRawData, s.SizeOfRawData))

    # Resolve IAT slots for the mailslot-relevant imports, so a `call [slot]` can be named.
    iat = {}
    try:
        for entry in pe.DIRECTORY_ENTRY_IMPORT:
            for imp in entry.imports:
                if imp.name and imp.address:
                    iat[imp.address] = imp.name.decode("latin-1", "replace")
    except AttributeError:
        pass
    pe.close()

    def off_of_rva(rva: int):
        for name, va, raw, size in secs:
            if va <= rva < va + size:
                return raw + (rva - va)
        return None

    def sec_of_rva(rva: int):
        for name, va, raw, size in secs:
            if va <= rva < va + size:
                return name
        return None

    print("# Mailslot call-site search (T-08c)")
    print()
    print("Runtime evidence says the launcher mailslot leaks and its peer does not. This finds")
    print("both sites so the difference is visible in code.")
    print()

    wanted = {
        "launcher channel (LEAKS)": MAILSLOT_FMT,
    }
    # The peer string may be a separate literal; find any other "\\.\mailslot\" occurrence.
    for off, text in _iter_strings(data):
        if "mailslot" in text.lower():
            sec = None
            for name, va, raw, size in secs:
                if raw <= off < raw + size:
                    sec = (name, va + (off - raw))
            if sec:
                wanted.setdefault(f'"{text.strip()[:40]}" @ RVA 0x{sec[1]:x}', MAIN + sec[1])

    md = Cs(CS_ARCH_X86, CS_MODE_32)

    for label, va_target in wanted.items():
        rva_target = va_target - MAIN
        print(f"## {label}")
        print(f"VA `0x{va_target:x}` · RVA `0x{rva_target:x}` · section `{sec_of_rva(rva_target)}`")

        refs = []
        # push imm32
        pat = b"\x68" + struct.pack("<I", va_target)
        pos = 0
        while True:
            pos = data.find(pat, pos)
            if pos < 0:
                break
            for name, va, raw, size in secs:
                if raw <= pos < raw + size:
                    refs.append(("push", pos, va + (pos - raw)))
            pos += 1
        # mov r32, imm32
        for reg in range(8):
            pat = bytes([0xB8 + reg]) + struct.pack("<I", va_target)
            pos = 0
            while True:
                pos = data.find(pat, pos)
                if pos < 0:
                    break
                for name, va, raw, size in secs:
                    if raw <= pos < raw + size:
                        refs.append((f"mov r{reg}", pos, va + (pos - raw)))
                pos += 1

        if not refs:
            print("  no immediate reference found (address may be computed)\n")
            continue

        for kind, foff, rva in refs[:4]:
            print(f"### referenced by `{kind}` at RVA `0x{rva:x}` (file `0x{foff:x}`)")
            start = max(0, rva - 72)
            code = data[foff - (rva - start): foff + 110]
            print("```")
            shown = 0
            for ins in md.disasm(code, MAIN + start):
                marker = ""
                if ins.address <= MAIN + rva < ins.address + ins.size:
                    marker = "  <== format string"
                note = ""
                if ins.mnemonic == "call":
                    op = ins.op_str.strip()
                    if op.startswith("dword ptr ["):
                        try:
                            slot = int(op.split("[")[1].split("]")[0], 16)
                            if slot in iat:
                                note = f"   -> {iat[slot]}"
                        except ValueError:
                            pass
                print(f"  0x{ins.address:08x}  {ins.mnemonic:<7} {ins.op_str}{marker}{note}")
                shown += 1
                if shown >= 30:
                    break
            print("```")
            print()
        print()

    print("## What to look for")
    print()
    print("- A `call [CreateMailslotA]` or `call [CreateFileA]` near the launcher format string")
    print("  identifies the leaking open.")
    print("- A matching `call [CloseHandle]` dominated by it would mean the handle IS closed and the")
    print("  leak has another cause; its ABSENCE within the same function supports the reopen theory.")
    print("- The peer channel's site should hold its handle in a global and never re-open it. That")
    print("  difference is the model for the fix.")
    return 0


def _iter_strings(data: bytes):
    i = 0
    n = len(data)
    while i < n:
        if 32 <= data[i] < 127:
            j = i
            while j < n and 32 <= data[j] < 127:
                j += 1
            if j - i >= 5:
                yield i, data[i:j].decode("latin-1", "replace")
            i = j
        else:
            i += 1


if __name__ == "__main__":
    raise SystemExit(main())
