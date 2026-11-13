#!/usr/bin/env python
"""
Build the Silver Knights Windows release archive.

WHAT THIS PRODUCES
  A single zip containing a ready-to-run, patched copy of the game plus the guides, so a
  recipient can unzip and play without a build step.

WHY IT IS NOT PUBLISHED AUTOMATICALLY
  The game's ReadMe forbids redistribution and modification without the author's permission:

      "Do not change any datas in this software without permission from the author."
      "do not distribute or upload this software"
      "Do not use this software for any commercial using."

  This script therefore writes the archive LOCALLY and never uploads, tags or attaches
  anything. Publishing is a separate, deliberate act by the repository owner, who is the only
  party able to decide whether they hold that permission. See docs/DISTRIBUTION.md.

  The mission brief also states: "Do not publish binaries or releases without authorization."
  Building is not publishing. This split is deliberate.

USAGE
  python tools/build_release.py --game-dir . --upx <upx.exe> \
      --out build-release/SilverKnights-0.13-Windows11.zip

  Then, if you have the right to distribute:
      gh release create v0.13-win11 <archive> --title ... --notes-file docs/RELEASE-NOTES.md
"""

from __future__ import annotations

import argparse
import hashlib
import os
import shutil
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

# What ships to a player. Order does not matter; the set does.
ASSET_DIRS = ["bsp", "mesh", "png", "se", "logo", "mp3", "midi", "replay"]
ASSET_FILES = [
    "SilverKnights.ini", "1041.ini", "SKGuard.dll", "libeay32.dll", "msvcr71.dll",
    "emblem.bmp", "ToonMap.bmp",
    "ReadMe-English.txt", "ReadMe-Japanese.txt",   # the licence must travel with the game
]
# Patched by build_patched.py, not copied.
PATCHED = ["SK-Main.exe", "SK-Startup.exe"]
# Guides, at the archive root so they are impossible to miss.
DOCS = [
    ("docs/HOW-TO-PLAY.md", "HOW-TO-PLAY.md"),
    ("docs/SETUP-WINDOWS.md", "SETUP-WINDOWS.md"),
    ("docs/DISTRIBUTION.md", "LICENCE-AND-DISTRIBUTION.md"),
    ("docs/images", "images"),
]
# A runnable launcher. The original ReadMe says to use win.bat but the file was never shipped.
LAUNCHER_BAT = """@echo off
REM Silver Knights 0.13 - Windows launcher
REM The game is SK-Startup.exe; SK-Main.exe is its renderer and cannot run alone.
cd /d "%~dp0"
start "" "SK-Startup.exe"
REM The launcher window appears. Click the "Window" button in it to start the game.
"""


def sha256(p: Path) -> str:
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def md5(p: Path) -> str:
    h = hashlib.md5()
    with open(p, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def run(cmd, **kw):
    print("  $ " + " ".join(str(c) for c in cmd))
    r = subprocess.run(cmd, capture_output=True, text=True, **kw)
    if r.returncode != 0:
        print(r.stdout[-3000:])
        print(r.stderr[-3000:], file=sys.stderr)
        raise SystemExit(f"command failed ({r.returncode})")
    return r


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--game-dir", required=True)
    ap.add_argument("--upx", required=True)
    ap.add_argument("--out", required=True, help="output .zip path")
    ap.add_argument("--skip-build", action="store_true",
                    help="reuse build-patched/ instead of rebuilding")
    args = ap.parse_args()

    game = Path(args.game_dir).resolve()
    out_zip = Path(args.out).resolve()
    out_zip.parent.mkdir(parents=True, exist_ok=True)

    print("== 1. verify the originals ==")
    sk_main = game / "SK-Main.exe"
    if not sk_main.exists():
        raise SystemExit(f"SK-Main.exe not found in {game}")
    expect_md5 = "84a321d3035de0e2f03539123667f3d6"
    got_md5 = md5(sk_main)
    print(f"  SK-Main.exe md5 = {got_md5}")
    if got_md5 != expect_md5:
        print(f"  WARNING: expected {expect_md5} for the known 0.13 build.")
        print("           This release is pinned to that build; offsets may not apply.")
        if input("  continue anyway? [y/N] ").strip().lower() != "y":
            raise SystemExit("aborted by user")

    print("\n== 2. build the patched executables ==")
    staged = game / "build-patched"
    if args.skip_build and staged.exists():
        print(f"  reusing {staged}")
    else:
        if staged.exists():
            shutil.rmtree(staged)
        run([sys.executable, str(game / "tools" / "build_patched.py"),
             "--game-dir", str(game), "--upx", args.upx, "--out-dir", str(staged)])

    for name in PATCHED:
        p = staged / name
        if not p.exists():
            raise SystemExit(f"missing build output: {p}")
        print(f"  {name:18} {p.stat().st_size:>9,} bytes  md5={md5(p)}")

    print("\n== 3. stage the release tree ==")
    work = Path(tempfile.mkdtemp(prefix="sk-release-"))
    try:
        root = work / "SilverKnights-0.13-Windows11"
        root.mkdir()

        for name in PATCHED:
            shutil.copy2(staged / name, root / name)
            print(f"  patched  {name}")

        missing = []
        for name in ASSET_FILES:
            src = game / name
            if src.exists():
                shutil.copy2(src, root / name)
            else:
                missing.append(name)
        for d in ASSET_DIRS:
            src = game / d
            if src.is_dir():
                shutil.copytree(src, root / d, ignore=shutil.ignore_patterns("*.log"))
            else:
                missing.append(d + "/")
        if missing:
            print(f"  WARNING: absent from the source tree: {', '.join(missing)}")

        for src, dst in DOCS:
            s = game / src
            if not s.exists():
                print(f"  WARNING: doc not found: {src}")
                continue
            if s.is_dir():
                shutil.copytree(s, root / dst)
            else:
                shutil.copy2(s, root / dst)

        (root / "PLAY.bat").write_text(LAUNCHER_BAT, encoding="ascii", newline="\r\n")
        print("  added    PLAY.bat")

        # A manifest so a recipient can verify what they received without trusting the zip.
        lines = [
            "# Release manifest - Silver Knights 0.13, Windows 11 compatibility build",
            "#",
            "# Verify with:  md5sum -c MANIFEST.md5      (Linux/Git Bash)",
            "#          or:  certutil -hashfile <file> MD5    (Windows)",
            "#",
            "# Lines are: <md5>  <size>  <relative path>",
            "",
        ]
        for p in sorted(root.rglob("*")):
            if p.is_file():
                rel = p.relative_to(root).as_posix()
                lines.append(f"{md5(p)}  {p.stat().st_size:>10}  {rel}")
        (root / "MANIFEST.md5").write_text("\n".join(lines) + "\n", encoding="utf-8")

        print("\n== 4. write the archive ==")
        with zipfile.ZipFile(out_zip, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
            for p in sorted(root.rglob("*")):
                if p.is_file():
                    z.write(p, p.relative_to(work).as_posix())
        print(f"  wrote {out_zip}")
        print(f"  size  {out_zip.stat().st_size:,} bytes")
        print(f"  sha256 {sha256(out_zip)}")
    finally:
        shutil.rmtree(work, ignore_errors=True)

    print("\n== done ==")
    print("  NOT published. Publishing is your decision; see docs/DISTRIBUTION.md.")
    print(f"  to publish:  gh release create v0.13-win11 \"{out_zip}\" \\")
    print("                   --title 'Silver Knights 0.13 — Windows 11 build' \\")
    print("                   --notes-file docs/RELEASE-NOTES.md")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
