#!/usr/bin/env python
"""
PE metadata extraction for the Silver Knights recovery project.

Reads PE headers, sections, imports, exports, resources and version info from
one or more PE files and emits stable JSON. Read-only: never modifies inputs.

Usage:
    python tools/pe_report.py SK-Main.exe SK-Startup.exe > docs/evidence/pe.json

Requires: pefile
"""
from __future__ import annotations

import hashlib
import json
import os
import sys

import pefile

MACHINE = {
    0x014C: "i386",
    0x8664: "AMD64",
    0x01C0: "ARM",
    0xAA64: "ARM64",
    0x0200: "IA64",
}

SUBSYSTEM = {
    1: "NATIVE",
    2: "WINDOWS_GUI",
    3: "WINDOWS_CUI",
    5: "OS2_CUI",
    7: "POSIX_CUI",
    9: "WINDOWS_CE_GUI",
    10: "EFI_APPLICATION",
    11: "EFI_BOOT_SERVICE_DRIVER",
    12: "EFI_RUNTIME_DRIVER",
    13: "EFI_ROM",
    14: "XBOX",
    16: "WINDOWS_BOOT_APPLICATION",
}


def sha256_file(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def section_entropy(data: bytes) -> float:
    if not data:
        return 0.0
    counts = [0] * 256
    for b in data:
        counts[b] += 1
    total = len(data)
    import math

    ent = 0.0
    for c in counts:
        if c:
            p = c / total
            ent -= p * math.log2(p)
    return round(ent, 4)


def parse(path: str) -> dict:
    pe = pefile.PE(path, fast_load=True)
    pe.parse_data_directories(
        directories=[
            pefile.DIRECTORY_ENTRY["IMAGE_DIRECTORY_ENTRY_IMPORT"],
            pefile.DIRECTORY_ENTRY["IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT"],
            pefile.DIRECTORY_ENTRY["IMAGE_DIRECTORY_ENTRY_EXPORT"],
            pefile.DIRECTORY_ENTRY["IMAGE_DIRECTORY_ENTRY_RESOURCE"],
            pefile.DIRECTORY_ENTRY["IMAGE_DIRECTORY_ENTRY_LOAD_CONFIG"],
            pefile.DIRECTORY_ENTRY["IMAGE_DIRECTORY_ENTRY_BASERELOC"],
            pefile.DIRECTORY_ENTRY["IMAGE_DIRECTORY_ENTRY_TLS"],
        ]
    )

    fh = pe.OPTIONAL_HEADER
    out: dict = {
        "file": os.path.basename(path),
        "path_relative": path.replace("\\", "/"),
        "size_bytes": os.path.getsize(path),
        "sha256": sha256_file(path),
        "machine": MACHINE.get(pe.FILE_HEADER.Machine, hex(pe.FILE_HEADER.Machine)),
        "machine_raw": hex(pe.FILE_HEADER.Machine),
        "is_64bit": pe.FILE_HEADER.Machine == 0x8664,
        "characteristics": hex(pe.FILE_HEADER.Characteristics),
        "is_dll": bool(pe.FILE_HEADER.Characteristics & 0x2000),
        "timestamp": pe.FILE_HEADER.TimeDateStamp,
        "subsystem": SUBSYSTEM.get(fh.Subsystem, str(fh.Subsystem)),
        "subsystem_raw": fh.Subsystem,
        "os_version": f"{fh.MajorOperatingSystemVersion}.{fh.MinorOperatingSystemVersion}",
        "subsystem_version": f"{fh.MajorSubsystemVersion}.{fh.MinorSubsystemVersion}",
        "image_version": f"{fh.MajorImageVersion}.{fh.MinorImageVersion}",
        "linker_version": f"{fh.MajorLinkerVersion}.{fh.MinorLinkerVersion}",
        "dll_characteristics": hex(fh.DllCharacteristics),
        "checksum_stored": hex(fh.CheckSum),
        "checksum_computed": hex(pe.generate_checksum()),
        "image_base": hex(fh.ImageBase),
        "entry_point_rva": hex(fh.AddressOfEntryPoint),
        "size_of_image": fh.SizeOfImage,
        "size_of_headers": fh.SizeOfHeaders,
        "size_of_code": fh.SizeOfCode,
        "size_of_initialized_data": fh.SizeOfInitializedData,
        "size_of_uninitialized_data": fh.SizeOfUninitializedData,
        "section_alignment": fh.SectionAlignment,
        "file_alignment": fh.FileAlignment,
        "dll_characteristics_flags": [],
        "sections": [],
        "imports": {},
        "delay_imports": {},
        "exports": [],
        "resources": [],
        "version_info": {},
        "load_config": {},
        "tls": None,
        "relocations_present": False,
        "has_manifest": False,
        "manifest_text": None,
        "security_directory": {},
        "debug_directory": {},
    }

    DLC = {
        0x0020: "HIGH_ENTROPY_VA",
        0x0040: "DYNAMIC_BASE",
        0x0080: "FORCE_INTEGRITY",
        0x0100: "NX_COMPAT",
        0x0200: "NO_ISOLATION",
        0x0400: "NO_SEH",
        0x0800: "NO_BIND",
        0x1000: "APPCONTAINER",
        0x2000: "WDM_DRIVER",
        0x4000: "GUARD_CF",
        0x8000: "TERMINAL_SERVER_AWARE",
    }
    for bit, name in DLC.items():
        if fh.DllCharacteristics & bit:
            out["dll_characteristics_flags"].append(name)

    for s in pe.sections:
        name = s.Name.rstrip(b"\x00").decode("latin-1")
        data = s.get_data()
        out["sections"].append(
            {
                "name": name,
                "virtual_address": hex(s.VirtualAddress),
                "virtual_size": s.Misc_VirtualSize,
                "raw_pointer": hex(s.PointerToRawData),
                "raw_size": s.SizeOfRawData,
                "characteristics": hex(s.Characteristics),
                "entropy": section_entropy(data),
                "md5": s.get_hash_md5(),
            }
        )

    def collect(directory):
        result = {}
        for entry in getattr(pe, directory, []) or []:
            dll = entry.dll.decode("latin-1")
            names = []
            for imp in entry.imports:
                if imp.name:
                    names.append(imp.name.decode("latin-1"))
                elif imp.ordinal is not None:
                    names.append(f"ordinal_{imp.ordinal}")
            result[dll] = sorted(names)
        return result

    out["imports"] = collect("DIRECTORY_ENTRY_IMPORT")
    out["delay_imports"] = collect("DIRECTORY_ENTRY_DELAY_IMPORT")

    if hasattr(pe, "DIRECTORY_ENTRY_EXPORT") and pe.DIRECTORY_ENTRY_EXPORT:
        for exp in pe.DIRECTORY_ENTRY_EXPORT.symbols:
            out["exports"].append(
                {
                    "ordinal": exp.ordinal,
                    "address_rva": hex(exp.address) if exp.address else None,
                    "name": exp.name.decode("latin-1") if exp.name else None,
                }
            )

    if hasattr(pe, "DIRECTORY_ENTRY_RESOURCE"):
        def walk(entries, prefix):
            for e in entries:
                if e.name:
                    label = e.name.string.decode("latin-1", "replace") if isinstance(e.name.string, bytes) else str(e.name)
                    sub = f"{prefix}/{label}"
                else:
                    sub = f"{prefix}/{e.id}"
                if hasattr(e, "directory"):
                    walk(e.directory.entries, sub)
                elif hasattr(e, "data"):
                    d = e.data.struct
                    entry = {
                        "path": sub,
                        "size": d.Size,
                        "rva": hex(d.OffsetToData),
                    }
                    out["resources"].append(entry)
                    low = sub.lower()
                    if "manifest" in low or sub.endswith("/24/1") or sub.endswith("/24/1033"):
                        try:
                            raw = pe.get_data(d.OffsetToData, d.Size)
                            out["has_manifest"] = True
                            out["manifest_text"] = raw.decode("utf-8", "replace")
                        except Exception:
                            pass

        walk(pe.DIRECTORY_ENTRY_RESOURCE.entries, "")

    try:
        for fileinfo in pe.FileInfo or []:
            for entry in fileinfo:
                if hasattr(entry, "StringTable"):
                    for st in entry.StringTable:
                        for k, v in st.entries.items():
                            key = k.decode("latin-1", "replace")
                            val = v.decode("latin-1", "replace")
                            out["version_info"][key] = val
                elif hasattr(entry, "Var"):
                    for fi in entry.Var:
                        if hasattr(fi, "Entry"):
                            for k, v in fi.Entry.items():
                                key = k.decode("latin-1", "replace")
                                val = v.decode("latin-1", "replace") if isinstance(v, bytes) else str(v)
                                out["version_info"][key] = val
    except Exception:
        pass

    if hasattr(pe, "DIRECTORY_ENTRY_LOAD_CONFIG") and pe.DIRECTORY_ENTRY_LOAD_CONFIG:
        lc = pe.DIRECTORY_ENTRY_LOAD_CONFIG.struct
        out["load_config"] = {
            "size": lc.Size,
            "security_cookie_rva": hex(getattr(lc, "SecurityCookie", 0) or 0),
            "seh_handler_table": hex(getattr(lc, "SEHandlerTable", 0) or 0),
            "seh_handler_count": getattr(lc, "SEHandlerCount", 0),
            "guard_cf_check_function": hex(getattr(lc, "GuardCFCheckFunctionPointer", 0) or 0),
        }

    if hasattr(pe, "DIRECTORY_ENTRY_TLS") and pe.DIRECTORY_ENTRY_TLS:
        t = pe.DIRECTORY_ENTRY_TLS.struct
        out["tls"] = {
            "start_va": hex(t.StartAddressOfRawData),
            "end_va": hex(t.EndAddressOfRawData),
            "index_va": hex(t.AddressOfIndex),
            "callbacks_va": hex(t.AddressOfCallBacks),
        }

    out["relocations_present"] = hasattr(pe, "DIRECTORY_ENTRY_BASERELOC")

    if fh.DATA_DIRECTORY:
        sec = fh.DATA_DIRECTORY[4]
        if sec.VirtualAddress and sec.Size:
            out["security_directory"] = {
                "rva": hex(sec.VirtualAddress),
                "size": sec.Size,
                "note": "Authenticode certificate table (file offset, not RVA)",
            }
        dbg = fh.DATA_DIRECTORY[6]
        if dbg.VirtualAddress and dbg.Size:
            out["debug_directory"] = {"rva": hex(dbg.VirtualAddress), "size": dbg.Size}

    out["packer_hints"] = detect_packer(pe, path)
    pe.close()
    return out


def detect_packer(pe, path: str) -> list:
    hints = []
    names = [s.Name.rstrip(b"\x00").decode("latin-1") for s in pe.sections]
    if any(n.startswith("UPX") for n in names):
        hints.append("UPX section names present: " + ", ".join(n for n in names if n.startswith("UPX")))
    with open(path, "rb") as fh:
        head = fh.read(8192)
    for marker in (b"UPX!", b"UPX0", b"UPX1", b"MPRESS1", b"ASPack", b".aspack"):
        if marker in head:
            hints.append(f"marker {marker.decode('latin-1')} at offset {head.find(marker)}")
    return sorted(set(hints))


def main(argv: list) -> int:
    if len(argv) < 2:
        print(__doc__)
        return 2
    records = []
    for path in argv[1:]:
        try:
            records.append(parse(path))
        except Exception as exc:  # noqa: BLE001
            records.append({"file": os.path.basename(path), "error": f"{type(exc).__name__}: {exc}"})
    json.dump(records if len(records) > 1 else records[0], sys.stdout, indent=2)
    print()
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
