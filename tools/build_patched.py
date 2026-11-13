# T-02: reproducible patched build.
#
# Produces a patched SK-Main.exe whose LENGTH IS UNCHANGED (1,464,320 bytes), so the
# size constant that SK-Startup.exe checks at RVA 0x12554 does not need editing - only
# the MD5 constant at 0x12558 does.
#
# Why this matters: unpacking SK-Main.exe with `upx -d` yields 3,555,328 bytes, which
# forces TWO edits to SK-Startup.exe and ships a decompressed executable. Patching the
# PACKED image in place keeps the shipped binary byte-for-byte the same size.
#
# Problem: the byte at RVA 0x1f4d50 lives in the compressed UPX1 stream. Patching it
# before decompression corrupts the stream. Therefore the patch MUST be applied to the
# decompressed image at load time, not to the file on disk.
#
# Strategy implemented here: a same-length PE transformation.
#   1. Unpack SK-Main.exe to get the real code.
#   2. Apply the 1-byte code edit.
#   3. Re-pack and PAD the result back to exactly 1,464,320 bytes.
#   4. Report the new MD5 so SK-Startup.exe's constant can be updated.
#
# Usage:
#   python tools/build_patched.py --game-dir <dir> --upx <path-to-upx.exe> [--dry-run]
from __future__ import annotations

import argparse
import hashlib
import os
import shutil
import subprocess
import sys
import tempfile

TARGET_SIZE = 1_464_320          # 0x165800, from SK-Startup.exe RVA 0x12554
PATCH_RVA = 0x1F4D50             # RVA == file offset in the unpacked .text
PATCH_OLD = bytes([0x7E])        # jle 0x5f4da4
PATCH_NEW = bytes([0xEB])        # jmp 0x5f4da4
SK_STARTUP_MD5_RVA = 0x12558
SK_STARTUP_SIZE_RVA = 0x12554
ORIGINAL_SKMAIN_SHA256 = "cd54b002cf465a5fa63c57b9e1d7f5e348dc86ba55304d90ddc88ef03a009bab"
ORIGINAL_SKMAIN_MD5 = "84a321d3035de0e2f03539123667f3d6"


def sha256(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


def md5(path: str) -> str:
    h = hashlib.md5()
    with open(path, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


def run(cmd, **kw):
    p = subprocess.run(cmd, capture_output=True, text=True, **kw)
    if p.returncode != 0:
        raise SystemExit(f"command failed ({p.returncode}): {' '.join(map(str, cmd))}\n{p.stdout}\n{p.stderr}")
    return p.stdout


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--game-dir", required=True, help="directory containing the original SK-Main.exe / SK-Startup.exe")
    ap.add_argument("--upx", required=True, help="path to upx executable")
    ap.add_argument("--out-dir", default=None, help="output directory (default: <game-dir>/build-patched)")
    ap.add_argument("--dry-run", action="store_true", help="report the plan without writing anything")
    args = ap.parse_args()

    src_main = os.path.join(args.game_dir, "SK-Main.exe")
    src_start = os.path.join(args.game_dir, "SK-Startup.exe")
    for p in (src_main, src_start):
        if not os.path.isfile(p):
            raise SystemExit(f"missing: {p}")
    if not os.path.isfile(args.upx):
        raise SystemExit(f"missing upx: {args.upx}")

    print("== reference verification ==")
    s_hash = sha256(src_main)
    s_md5 = md5(src_main)
    s_size = os.path.getsize(src_main)
    print(f"SK-Main.exe size   : {s_size} (expected {TARGET_SIZE})")
    print(f"SK-Main.exe sha256 : {s_hash}")
    print(f"SK-Main.exe md5    : {s_md5}")
    ok_ref = (s_hash == ORIGINAL_SKMAIN_SHA256)
    print(f"matches reference  : {ok_ref}")
    if not ok_ref:
        print("WARNING: input is not the recorded reference binary; continuing but results are not comparable.")

    print("\n== plan ==")
    print(f"1. unpack SK-Main.exe (upx -d)")
    print(f"2. patch decompressed image at offset 0x{PATCH_RVA:x}: {PATCH_OLD.hex()} -> {PATCH_NEW.hex()}")
    print(f"3. re-pack and pad to exactly {TARGET_SIZE} bytes")
    print(f"4. recompute MD5; write new value for SK-Startup.exe RVA 0x{SK_STARTUP_MD5_RVA:x}")

    if args.dry_run:
        print("\n(dry run: no files written)")
        return 0

    out_dir = args.out_dir or os.path.join(args.game_dir, "build-patched")
    work = tempfile.mkdtemp(prefix="skbuild_")
    try:
        packed = os.path.join(work, "SK-Main.packed.exe")
        unpacked = os.path.join(work, "SK-Main.unpacked.exe")
        shutil.copy2(src_main, packed)
        print("\n== unpack ==")
        run([args.upx, "-d", "-o", unpacked, packed])
        print(f"unpacked size: {os.path.getsize(unpacked)}")

        print("\n== patch ==")
        data = bytearray(open(unpacked, "rb").read())
        actual = bytes(data[PATCH_RVA:PATCH_RVA + 1])
        print(f"byte at 0x{PATCH_RVA:x}: {actual.hex()} (expected {PATCH_OLD.hex()})")
        if actual != PATCH_OLD:
            raise SystemExit("precondition failed: decompressed byte does not match the expected value")
        data[PATCH_RVA:PATCH_RVA + 1] = PATCH_NEW
        patched = os.path.join(work, "SK-Main.patched.exe")
        open(patched, "wb").write(data)
        print(f"patched size : {os.path.getsize(patched)}")

        print("\n== re-pack ==")
        repacked = os.path.join(work, "SK-Main.repacked.exe")
        try:
            run([args.upx, "-9", "-o", repacked, patched])
            rp_size = os.path.getsize(repacked)
            print(f"repacked size: {rp_size}")
            if rp_size > TARGET_SIZE:
                print(f"WARNING: repacked ({rp_size}) exceeds target ({TARGET_SIZE}); cannot pad-down.")
                print("         Falling back to the decompressed patched binary.")
                raise RuntimeError("too large")
            final = repacked
        except Exception as exc:  # noqa: BLE001
            print(f"re-pack unavailable ({exc}); using decompressed patched binary")
            final = patched
            rp_size = os.path.getsize(final)

        print("\n== pad to target size ==")
        blob = bytearray(open(final, "rb").read())
        if len(blob) > TARGET_SIZE:
            raise SystemExit(
                f"cannot reach {TARGET_SIZE} bytes: produced {len(blob)}. "
                "This binary cannot be shipped same-length; use the two-constant approach."
            )
        pad = TARGET_SIZE - len(blob)
        blob += b"\x00" * pad
        print(f"padded {pad} bytes -> {len(blob)}")

        os.makedirs(out_dir, exist_ok=True)
        out_main = os.path.join(out_dir, "SK-Main.exe")
        open(out_main, "wb").write(blob)
        new_md5 = md5(out_main)
        new_sha = sha256(out_main)
        print(f"\nwrote {out_main}")
        print(f"  size   : {os.path.getsize(out_main)}")
        print(f"  md5    : {new_md5}")
        print(f"  sha256 : {new_sha}")

        print("\n== SK-Startup.exe patch requirement ==")
        print(f"  size constant at 0x{SK_STARTUP_SIZE_RVA:x} stays 0x{TARGET_SIZE:x}  (no edit needed)")
        print(f"  MD5 constant  at 0x{SK_STARTUP_MD5_RVA:x}: {ORIGINAL_SKMAIN_MD5} -> {new_md5}")
        print(f"  command:")
        print(f"    python tools/patch_bytes.py SK-Startup.exe --out {out_dir}/SK-Startup.exe \\")
        print(f"        --edit 0x{SK_STARTUP_MD5_RVA:x}:{ORIGINAL_SKMAIN_MD5}:{new_md5} \\")
        print(f"        --reason \"accept the patched SK-Main.exe\"")
        return 0
    finally:
        shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
