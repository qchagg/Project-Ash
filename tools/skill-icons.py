#!/usr/bin/env python3
"""Cuts each skill's icon out of the gold icon sheets into game/art/skills/<skill-name>.webp.

The sheets are the user's own gold-on-dark art, kept local in art/_archive/restyled/ (read them from the main folder):
    python3 tools/skill-icons.py <folder with the sheets>
Only the gold survives, as the alpha of a white image; Forge.skill_icon tints it by element in a shader. Needs Pillow and numpy.
"""
import os
import sys

import numpy as np
from PIL import Image

# Sheet: file, rows, columns, and the part of the page its grid fills (left, right, top, bottom).
SHEETS = {
    "v": ("icons-vfx.png", 5, 7, (0.15, 0.85, 0.10, 0.90)),
    "a": ("icons-emblems-a.png", 3, 7, (0.02, 0.98, 0.03, 0.97)),
    "b": ("icons-emblems-b.png", 3, 7, (0.02, 0.98, 0.03, 0.97)),
    "m": ("icons-mermaid.png", 2, 5, (0.0, 1.0, 0.0, 1.0)),
    "d": ("icons-dancer.png", 3, 7, (0.0, 1.0, 0.0, 1.0)),
}

# Skill -> (sheet, row, column). A skill new to the game gets a cell here; a check fails until it has an icon.
ICONS = {
    "Foxfire Lance": ("v", 1, 0), "Ninefold Blaze": ("a", 1, 0),
    "Rockfall": ("b", 0, 4), "Breakwater": ("m", 1, 1),
    "Crosswind": ("b", 0, 1), "Pinning Shot": ("b", 0, 3),
    "Riptide": ("m", 0, 2), "Rain of Renewal": ("v", 3, 5),
    "Magma Fist": ("b", 1, 2), "Quake": ("v", 4, 6),
    "Gust Step": ("d", 0, 3), "Cyclone Cut": ("d", 0, 6),
    "Coil Lash": ("b", 1, 4), "Molt": ("v", 0, 0),
    "Smother": ("b", 1, 6), "Ash Veil": ("v", 2, 4),
    "Ember Rain": ("v", 1, 1), "Flare": ("d", 0, 2),
    "Mend": ("m", 1, 2), "Tidal Pillar": ("m", 1, 3),
}

SIZE = 112
OUT = os.path.join(os.path.dirname(__file__), "..", "game", "art", "skills")


def cell(red, sheet, row, col):
    """The gold of one grid cell, squared up around its bounding box. Red alone tells gold from the green or black ground."""
    _, rows, cols, (left, right, top, bottom) = SHEETS[sheet]
    h, w = red.shape
    x0, x1 = int(w * left), int(w * right)
    y0, y1 = int(h * top), int(h * bottom)
    box = red[y0 + (y1 - y0) * row // rows:y0 + (y1 - y0) * (row + 1) // rows, x0 + (x1 - x0) * col // cols:x0 + (x1 - x0) * (col + 1) // cols]
    gold = np.clip((box - 45.0) / 170.0, 0, 1) ** 0.75
    ys, xs = np.where(gold > 0.25)
    t = Image.fromarray((gold * 255).astype("uint8")).crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
    side = max(t.size)
    square = Image.new("L", (side, side), 0)
    square.paste(t, ((side - t.width) // 2, (side - t.height) // 2))
    return square.resize((SIZE, SIZE), Image.LANCZOS)


def main():
    src = sys.argv[1]
    red = {k: np.asarray(Image.open(os.path.join(src, v[0])).convert("RGB"))[:, :, 0].astype(float) for k, v in SHEETS.items()}
    os.makedirs(OUT, exist_ok=True)
    for skill, (sheet, row, col) in ICONS.items():
        im = Image.new("RGBA", (SIZE, SIZE), (255, 255, 255, 0))
        im.putalpha(cell(red[sheet], sheet, row, col))
        im.save(os.path.join(OUT, skill.lower().replace(" ", "-") + ".webp"), lossless=True, method=6, exact=False)
    print("%d icons, %d KB" % (len(ICONS), sum(os.path.getsize(os.path.join(OUT, f)) for f in os.listdir(OUT) if f.endswith(".webp")) // 1024))


main()
