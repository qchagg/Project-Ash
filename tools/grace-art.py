#!/usr/bin/env python3
"""Cuts the Graces of Mehfil out of the user's gold dancer sheets into game/art/graces/<grace>.webp.

The sheets are kept local in art/_archive/restyled/ (read them from the main folder):
    python3 tools/grace-art.py <folder with the sheets>
Each sheet holds four tall figures on dark green; the ground is keyed away and the gold keeps its own colour.
The files ship beside the page in sheets/, outside the game pack. Needs Pillow and numpy.
"""
import os
import sys

import numpy as np
from PIL import Image

# Grace (or the order's crest) -> (sheet, column). Both sheets have four columns.
GRACES = {
    "crest": ("dancers-a.png", 0),
    "ashvini": ("dancers-a.png", 1),
    "jvala": ("dancers-a.png", 3),
    "lehra": ("dancers-b.png", 1),
    "tarini": ("dancers-b.png", 2),
    "sthira": ("dancers-b.png", 3),
}

TALL = 640
OUT = os.path.join(os.path.dirname(__file__), "..", "game", "art", "graces")


def cut(sheet, col):
    """One figure, keyed off its ground by brightness and trimmed to what is left."""
    w, h = sheet.size
    q = np.asarray(sheet.crop((w * col // 4, 0, w * (col + 1) // 4, h))).astype(float)
    a = np.clip((q.max(axis=2) - 48.0) / 110.0, 0, 1) ** 1.3
    a[a < 0.08] = 0
    ys, xs = np.where(a > 0.2)
    rgba = np.dstack([q, a * 255]).astype("uint8")
    im = Image.fromarray(rgba, "RGBA").crop((xs.min() - 8, ys.min() - 8, xs.max() + 9, ys.max() + 9))
    return im.resize((round(im.width * TALL / im.height), TALL), Image.LANCZOS)


def main():
    src = sys.argv[1]
    sheets = {}
    os.makedirs(OUT, exist_ok=True)
    for name, (file, col) in GRACES.items():
        if file not in sheets:
            sheets[file] = Image.open(os.path.join(src, file)).convert("RGB")
        cut(sheets[file], col).save(os.path.join(OUT, name + ".webp"), quality=86, method=6)
    print("%d figures, %d KB" % (len(GRACES), sum(os.path.getsize(os.path.join(OUT, f)) for f in os.listdir(OUT) if f.endswith(".webp")) // 1024))


main()
