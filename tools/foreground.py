"""Key a battle foreground (plants, roots, rocks framing the foot of the screen) off its flat backdrop for the wide board.

    python3 tools/foreground.py art/_archive/restyled/fore-<name>.png game/art/foregrounds/fore-<name>.webp

Midjourney paints these on a flat pale backdrop with no alpha. The backdrop colour is read from the top corners; each
pixel turns clear by how close it is to it, so the misty shapes behind go part see-through, and the backdrop is taken
back out of the colour that remains. The layer stands nearest the camera, in front of the fighters, so it is darkened
well below the painting and softened a touch, which keeps the inked line art from pulling the eye off the fight.
"""
import sys

import numpy as np
from PIL import Image, ImageFilter

WIDTH = 2048
# Distance from the backdrop (0..441 in RGB) at which a pixel starts and finishes turning solid.
SOFT, HARD = 14.0, 90.0
# How dark the layer stands against the scene, and how much it is softened (pixels at WIDTH).
SHADE = 0.42
BLUR = 1.2


def main(src, dst):
    im = Image.open(src).convert("RGB")
    im = im.resize((WIDTH, round(im.height * WIDTH / im.width)), Image.LANCZOS)
    f = np.asarray(im).astype(np.float32)
    corners = np.concatenate([f[:24, :24].reshape(-1, 3), f[:24, -24:].reshape(-1, 3)])
    bg = np.median(corners, 0)
    d = np.linalg.norm(f - bg, axis=2)
    a = np.clip((d - SOFT) / (HARD - SOFT), 0, 1)
    # The colour with the backdrop taken out: what, at this alpha, laid over the backdrop gives the pixel.
    col = (f - (1 - a[..., None]) * bg) / np.maximum(a[..., None], 0.05)
    col = np.clip(col * SHADE, 0, 255)
    out = Image.fromarray(np.dstack([col, a * 255]).astype(np.uint8), "RGBA")
    out = out.filter(ImageFilter.GaussianBlur(BLUR))
    out.save(dst, "WEBP", quality=80, method=6)
    print(dst, out.size)


if __name__ == "__main__":
    main(*sys.argv[1:3])
