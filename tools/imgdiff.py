#!/usr/bin/env python
"""
Pixel-diff two PNGs and report WHERE they differ (bounding box + row/column profile).

Read-only. Used to distinguish "the game is animating" from "the menu selection moved".

Usage:
    python tools/imgdiff.py A.png B.png [--out diff.png] [--threshold 8]
"""
from __future__ import annotations

import argparse
import struct
import sys
import zlib


def read_png(path: str):
    """Minimal PNG reader for 8-bit RGB/RGBA non-interlaced images."""
    data = open(path, "rb").read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"{path}: not a PNG")
    pos = 8
    width = height = bitdepth = colortype = None
    idat = bytearray()
    while pos < len(data):
        (length,) = struct.unpack(">I", data[pos:pos + 4])
        ctype = data[pos + 4:pos + 8]
        chunk = data[pos + 8:pos + 8 + length]
        pos += 12 + length
        if ctype == b"IHDR":
            width, height, bitdepth, colortype, comp, filt, interlace = struct.unpack(">IIBBBBB", chunk)
            if bitdepth != 8 or colortype not in (2, 6) or interlace != 0:
                raise ValueError(
                    f"{path}: unsupported PNG (bitdepth={bitdepth} colortype={colortype} interlace={interlace}); "
                    "only 8-bit RGB/RGBA non-interlaced is supported"
                )
        elif ctype == b"IDAT":
            idat += chunk
        elif ctype == b"IEND":
            break
    channels = 3 if colortype == 2 else 4
    raw = zlib.decompress(bytes(idat))
    stride = width * channels
    out = bytearray(width * height * channels)
    prev = bytearray(stride)
    p = 0
    for y in range(height):
        f = raw[p]
        p += 1
        line = bytearray(raw[p:p + stride])
        p += stride
        if f == 1:
            for i in range(channels, stride):
                line[i] = (line[i] + line[i - channels]) & 0xFF
        elif f == 2:
            for i in range(stride):
                line[i] = (line[i] + prev[i]) & 0xFF
        elif f == 3:
            for i in range(stride):
                left = line[i - channels] if i >= channels else 0
                line[i] = (line[i] + ((left + prev[i]) >> 1)) & 0xFF
        elif f == 4:
            for i in range(stride):
                a = line[i - channels] if i >= channels else 0
                b = prev[i]
                c = prev[i - channels] if i >= channels else 0
                pp = a + b - c
                pa, pb, pc = abs(pp - a), abs(pp - b), abs(pp - c)
                pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[i] = (line[i] + pr) & 0xFF
        out[y * stride:(y + 1) * stride] = line
        prev = line
    return width, height, channels, out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("a")
    ap.add_argument("b")
    ap.add_argument("--threshold", type=int, default=8, help="per-channel delta that counts as a difference")
    ap.add_argument("--out", default=None)
    args = ap.parse_args()

    wa, ha, ca, da = read_png(args.a)
    wb, hb, cb, db = read_png(args.b)
    if (wa, ha) != (wb, hb):
        print(f"size mismatch: {wa}x{ha} vs {wb}x{hb}")
        return 1
    w, h = wa, ha
    ch = min(ca, cb)
    t = args.threshold

    xmin, ymin, xmax, ymax = w, h, -1, -1
    diff_count = 0
    rows = [0] * h
    cols = [0] * w
    for y in range(h):
        ro = y * w
        for x in range(w):
            i = (ro + x) * ch
            d = max(abs(da[i] - db[i]), abs(da[i + 1] - db[i + 1]), abs(da[i + 2] - db[i + 2]))
            if d > t:
                diff_count += 1
                rows[y] += 1
                cols[x] += 1
                if x < xmin: xmin = x
                if x > xmax: xmax = x
                if y < ymin: ymin = y
                if y > ymax: ymax = y

    total = w * h
    print(f"image        : {w}x{h} ({ch} channels)")
    print(f"threshold    : {t}")
    print(f"changed px   : {diff_count} / {total} ({100.0 * diff_count / total:.2f}%)")
    if diff_count:
        print(f"bbox         : x={xmin}..{xmax}  y={ymin}..{ymax}   ({xmax - xmin + 1}x{ymax - ymin + 1})")
        band = [y for y in range(h) if rows[y] > max(3, w * 0.01)]
        if band:
            # compress to contiguous ranges
            ranges = []
            start = band[0]
            prev = band[0]
            for y in band[1:]:
                if y != prev + 1:
                    ranges.append((start, prev))
                    start = y
                prev = y
            ranges.append((start, prev))
            print("changed rows : " + ", ".join(f"y{a}-{b}" for a, b in ranges[:12]))
        else:
            print("changed rows : (diffuse, no row exceeds 1% of width)")
    else:
        print("RESULT       : identical within threshold")

    if args.out:
        out = bytearray(da)
        for y in range(h):
            ro = y * w
            for x in range(w):
                i = (ro + x) * ch
                d = max(abs(da[i] - db[i]), abs(da[i + 1] - db[i + 1]), abs(da[i + 2] - db[i + 2]))
                if d > t:
                    out[i] = 255
                    out[i + 1] = 0
                    out[i + 2] = 255
        write_png(args.out, w, h, ca, bytes(out))
        print(f"diff image   : {args.out}")
    return 0


def write_png(path: str, w: int, h: int, ch: int, data: bytes) -> None:
    ctype = 2 if ch == 3 else 6
    raw = bytearray()
    stride = w * ch
    for y in range(h):
        raw.append(0)
        raw += data[y * stride:(y + 1) * stride]

    def chunk(tag, payload):
        return (struct.pack(">I", len(payload)) + tag + payload
                + struct.pack(">I", zlib.crc32(tag + payload) & 0xFFFFFFFF))

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, ctype, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 6))
    png += chunk(b"IEND", b"")
    open(path, "wb").write(png)


if __name__ == "__main__":
    sys.exit(main())
