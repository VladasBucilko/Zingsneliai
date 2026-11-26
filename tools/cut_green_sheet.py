#!/usr/bin/env python3
"""Cut a green-screen sheet of characters/objects into separate transparent PNGs.

Removes the bright chroma-key green (keeps muted greens like the owl's glasses
or a green book), cleans the green fringe on soft edges, finds each separate
figure by its shape, and names them in reading order (left→right, top→bottom
using a rows × cols grid).

Usage (from the project folder):
  python3 -I tools/cut_green_sheet.py sheet.png out_dir prefix name1 name2 … [--cols 4 --rows 2]
e.g.
  python3 -I tools/cut_green_sheet.py owl_sheet.png assets/characters owl \
      wave thumbs_up point cheer think listen read sleepy
Needs Pillow and numpy.
"""
import argparse
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

KEY_LOW, KEY_HIGH = 45, 95   # "greenness" (G - max(R,B)) where transparency starts / is full
MIN_BLOCKS = 1500            # figures smaller than this (in 4×4 blocks) are specks


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("sheet", type=Path)
    ap.add_argument("out_dir", type=Path)
    ap.add_argument("prefix")
    ap.add_argument("names", nargs="+")
    ap.add_argument("--cols", type=int, default=4)
    ap.add_argument("--rows", type=int, default=2)
    args = ap.parse_args()

    a = np.asarray(Image.open(args.sheet).convert("RGB")).astype(float)
    R, G, B = a[..., 0], a[..., 1], a[..., 2]
    greenness = G - np.maximum(R, B)
    alpha = 1 - np.clip((greenness - KEY_LOW) / (KEY_HIGH - KEY_LOW), 0, 1)
    G = np.where(alpha < 0.999, np.minimum(G, np.maximum(R, B) * 1.02 + 4), G)  # despill
    H, W = alpha.shape

    # Label separate figures on a 4× smaller mask (fast enough in plain Python).
    f = 4
    small = alpha[::f, ::f] > 0.05
    h, w = small.shape
    lab = np.zeros((h, w), int)
    figures = []
    for y in range(h):
        for x in range(w):
            if small[y, x] and not lab[y, x]:
                k = len(figures) + 1
                q = deque([(y, x)])
                lab[y, x] = k
                n = sy = sx = 0
                while q:
                    cy, cx = q.popleft()
                    n += 1; sy += cy; sx += cx
                    for dy in (-1, 0, 1):
                        for dx in (-1, 0, 1):
                            ny, nx = cy + dy, cx + dx
                            if 0 <= ny < h and 0 <= nx < w and small[ny, nx] and not lab[ny, nx]:
                                lab[ny, nx] = k
                                q.append((ny, nx))
                figures.append((k, n, sy / n * f, sx / n * f))
    figures = [fi for fi in figures if fi[1] >= MIN_BLOCKS]
    labfull = np.kron(lab, np.ones((f, f), int))[:H, :W]

    args.out_dir.mkdir(parents=True, exist_ok=True)
    cw, ch = W / args.cols, H / args.rows
    for k, _, cy, cx in figures:
        idx = int(cy // ch) * args.cols + int(cx // cw)
        if idx >= len(args.names):
            print(f"  skipped a figure in cell {idx + 1} (no name for it)")
            continue
        m = Image.fromarray(((labfull == k) * 255).astype("uint8")).filter(ImageFilter.MaxFilter(9))
        al = np.where(np.asarray(m) > 0, alpha, 0)
        img = Image.fromarray(np.dstack([R, G, B, al * 255]).astype("uint8"), "RGBA")
        img.putalpha(img.getchannel("A").filter(ImageFilter.GaussianBlur(0.5)))
        img = img.crop(img.getbbox())
        out = args.out_dir / f"{args.prefix}_{args.names[idx]}.png"
        img.save(out)
        print(f"  {out}  {img.size[0]}×{img.size[1]}")
    print(f"{len(figures)} figure(s) found, {len(args.names)} name(s) given.")


if __name__ == "__main__":
    main()
