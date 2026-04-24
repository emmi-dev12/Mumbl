#!/usr/bin/env python3
"""Generate Mumbl app icon PNGs: 5-bar waveform suggesting an M, lime on near-black."""
import struct, zlib, math, os

def write_png(path, rows_rgba, w, h):
    raw = b''.join(b'\x00' + bytes(px for rgba in row for px in rgba) for row in rows_rgba)
    def chunk(t, d):
        return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
    data = (b'\x89PNG\r\n\x1a\n'
            + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0))
            + chunk(b'IDAT', zlib.compress(raw, 6))
            + chunk(b'IEND', b''))
    with open(path, 'wb') as f:
        f.write(data)

def make_icon(size):
    w = h = size
    # Pixel buffer: list of rows, each row is list of (r,g,b,a)
    buf = [[(0, 0, 0, 0)] * w for _ in range(h)]

    BG   = (10, 10, 10, 255)
    LIME = (181, 255, 0, 255)

    corner_r = int(size * 0.215)
    corner_r2 = corner_r * corner_r

    # ── Background rounded rect ─────────────────────────────────────────────
    for y in range(h):
        for x in range(w):
            in_tl = x < corner_r and y < corner_r
            in_tr = x >= w - corner_r and y < corner_r
            in_bl = x < corner_r and y >= h - corner_r
            in_br = x >= w - corner_r and y >= h - corner_r
            skip = False
            if in_tl:
                dx = x - corner_r; dy = y - corner_r
                skip = dx*dx + dy*dy > corner_r2
            elif in_tr:
                dx = x - (w - corner_r - 1); dy = y - corner_r
                skip = dx*dx + dy*dy > corner_r2
            elif in_bl:
                dx = x - corner_r; dy = y - (h - corner_r - 1)
                skip = dx*dx + dy*dy > corner_r2
            elif in_br:
                dx = x - (w - corner_r - 1); dy = y - (h - corner_r - 1)
                skip = dx*dx + dy*dy > corner_r2
            if not skip:
                buf[y][x] = BG

    # ── 5 waveform bars (M-shape heights: tall-mid-short-mid-tall) ──────────
    bar_w  = max(2, int(size * 0.082))
    gap    = max(2, int(size * 0.066))
    bar_r  = bar_w // 2
    bar_r2 = bar_r * bar_r

    # Heights as fraction of icon size
    fracs  = [0.56, 0.40, 0.25, 0.40, 0.56]
    heights = [max(4, int(size * f)) for f in fracs]

    total_w = 5 * bar_w + 4 * gap
    sx = (w - total_w) // 2
    cy = h // 2

    for i, bh in enumerate(heights):
        bx0 = sx + i * (bar_w + gap)
        bx1 = bx0 + bar_w
        by0 = cy - bh // 2
        by1 = by0 + bh

        for y in range(by0, by1):
            for x in range(bx0, bx1):
                if 0 <= x < w and 0 <= y < h:
                    # Pill-shaped: rounded top and bottom
                    in_tc = y < by0 + bar_r
                    in_bc = y >= by1 - bar_r
                    skip = False
                    if in_tc:
                        dx = x - (bx0 + bar_r); dy = y - (by0 + bar_r)
                        skip = dx*dx + dy*dy > bar_r2
                    elif in_bc:
                        dx = x - (bx0 + bar_r); dy = y - (by1 - bar_r - 1)
                        skip = dx*dx + dy*dy > bar_r2
                    if not skip:
                        buf[y][x] = LIME
    return buf

SIZES = {
    'icon_16x16.png':     16,
    'icon_16x16@2x.png':  32,
    'icon_32x32.png':     32,
    'icon_32x32@2x.png':  64,
    'icon_128x128.png':   128,
    'icon_128x128@2x.png': 256,
    'icon_256x256.png':   256,
    'icon_256x256@2x.png': 512,
    'icon_512x512.png':   512,
    'icon_512x512@2x.png': 1024,
}

out_dir = os.path.join(os.path.dirname(__file__),
    'Mumbl', 'Resources', 'Assets.xcassets', 'AppIcon.appiconset')

cache = {}
for fname, sz in SIZES.items():
    if sz not in cache:
        print(f'Rendering {sz}x{sz}…', flush=True)
        cache[sz] = make_icon(sz)
    write_png(os.path.join(out_dir, fname), cache[sz], sz, sz)
    print(f'  wrote {fname}')

print('Done.')
