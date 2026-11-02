"""Find the lights in a painted background: bright, saturated pixels such as lanterns, lava and lit windows.

    python3 tools/glow-spots.py game/art/backgrounds/city.webp

Prints a JSON list of up to SPOTS lights, each [x, y, radius, colour], with x, y and radius as fractions of the image's
width. organize-art writes them into Faces.GLOWS, and Weather makes them flicker. Sky and snow are bright but pale, so
saturation keeps them out; a sunset sky is saturated but wide, so a blob that covers too much of the picture is skipped.
"""
import json
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

SPOTS = 14
WIDTH = 448
BRIGHT = 0.72
SATURATED = 0.42
# Above this share of the picture a blob is sky or a glowing field, not a light.
TOO_BIG = 0.004
# A light stands this much brighter than its neighbourhood, and its neighbourhood is dark: sunlit daytime paintings get none.
GAP = 0.24
DARK_AROUND = 0.46
MAX_RADIUS = 0.028
MIN_PIXELS = 3


def spots(path):
    im = Image.open(path).convert("RGB")
    im = im.resize((WIDTH, WIDTH * im.height // im.width), Image.LANCZOS)
    a = np.asarray(im).astype(float) / 255
    top, low = a.max(2), a.min(2)
    sat = (top - low) / np.maximum(top, 1e-3)
    # Dark surroundings are what make a light a light: compare each pixel to its neighbourhood.
    around = ndimage.uniform_filter(top, 31)
    lit = (top > BRIGHT) & (sat > SATURATED) & (top - around > GAP) & (around < DARK_AROUND)
    lab, n = ndimage.label(lit)
    found = []
    limit = TOO_BIG * lit.size
    for i in range(1, n + 1):
        ys, xs = np.nonzero(lab == i)
        if not MIN_PIXELS <= len(xs) <= limit:
            continue
        col = a[ys, xs].mean(0)
        col = col / max(col.max(), 1e-3)
        rad = max(np.ptp(xs), np.ptp(ys), 2) / WIDTH
        found.append((len(xs), [round(float(xs.mean()) / WIDTH, 4), round(float(ys.mean()) / WIDTH, 4), round(min(float(rad) * 1.6, MAX_RADIUS), 4),
            "#%02x%02x%02x" % tuple(int(v * 255) for v in col)]))
    found.sort(key=lambda f: -f[0])
    return [f[1] for f in found[:SPOTS]]


if __name__ == "__main__":
    print(json.dumps(spots(sys.argv[1])))
