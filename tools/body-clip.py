"""Key a hero's green-screen battle sprite and its idle clip into the game's sprite and frame sheet.

    python3 tools/body-clip.py still.png clip.mp4 out_sprite.webp out_sheet.webp

The still and every frame share one crop (the union of the figure across the clip, feet on the bottom edge), so the
still and the sheet line up and the figure never jumps when the game swaps between them. The sheet is the clip at
12 fps, frames FRAME_H tall, COLS across, which is what Figure's `anim` reads. Prints the `anim` entry.
"""
import json
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).resolve().parent))
face = __import__("face-clip")

FPS = 12
FRAME_H = 560
COLS = 9
STILL_H = 1000


def clean(rgba):
    """Clears specks the key left behind (compression noise in the corners), keeping the figure and any piece of it
    at least 2% the size of its largest part."""
    lab, n = ndimage.label(rgba[..., 3] > 24)
    if n > 1:
        sizes = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))
        keep = np.isin(lab, 1 + np.nonzero(sizes >= sizes.max() * 0.02)[0])
        rgba = rgba.copy()
        rgba[..., 3] = np.where(ndimage.binary_dilation(keep, iterations=2), rgba[..., 3], 0)
    return rgba


def frames(src):
    w, h, _ = face.probe(src)
    dec = subprocess.run(["ffmpeg", "-v", "error", "-i", src, "-vf", f"fps={FPS}", "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
        capture_output=True, check=True).stdout
    n = w * h * 3
    out = []
    ch = None
    for i in range(len(dec) // n):
        rgb = np.frombuffer(dec[i * n:(i + 1) * n], np.uint8).reshape(h, w, 3)
        ch = ch or face.key_channel(rgb)
        col, a = face.key(rgb, ch)
        out.append(clean(np.dstack([col, a])))
    return out


def box(alphas):
    """The union of where the figure is, as fractions of the frame: left, top, right, bottom."""
    l, t, r, b = 1.0, 1.0, 0.0, 0.0
    for a in alphas:
        ys, xs = np.nonzero(a > 24)
        if len(xs) == 0:
            continue
        h, w = a.shape
        l, t = min(l, xs.min() / w), min(t, ys.min() / h)
        r, b = max(r, (xs.max() + 1) / w), max(b, (ys.max() + 1) / h)
    pad = 0.01
    return max(0.0, l - pad), max(0.0, t - pad), min(1.0, r + pad), b


def crop(rgba, bx):
    h, w = rgba.shape[:2]
    return rgba[int(bx[1] * h):int(round(bx[3] * h)), int(bx[0] * w):int(round(bx[2] * w))]


def main(still_src, clip_src, sprite_dst, sheet_dst):
    seq = frames(clip_src)
    im = np.asarray(Image.open(still_src).convert("RGB"))
    col, a = face.key(im, face.key_channel(im))
    still = clean(np.dstack([col, a]))
    bx = box([f[..., 3] for f in seq] + [still[..., 3]])
    s = Image.fromarray(crop(still, bx))
    s = s.resize((round(s.width * STILL_H / s.height), STILL_H), Image.LANCZOS) if s.height > STILL_H else s
    s.save(sprite_dst, "WEBP", quality=88, method=6)
    cells = [Image.fromarray(crop(f, bx)) for f in seq]
    fw = round(cells[0].width * FRAME_H / cells[0].height)
    rows = (len(cells) + COLS - 1) // COLS
    sheet = Image.new("RGBA", (fw * COLS, FRAME_H * rows))
    for i, c in enumerate(cells):
        sheet.paste(c.resize((fw, FRAME_H), Image.LANCZOS), ((i % COLS) * fw, (i // COLS) * FRAME_H))
    sheet.save(sheet_dst, "WEBP", quality=82, method=6)
    print(json.dumps({"w": fw, "h": FRAME_H, "cols": COLS, "n": len(cells), "fps": FPS}))


if __name__ == "__main__":
    main(*sys.argv[1:5])
