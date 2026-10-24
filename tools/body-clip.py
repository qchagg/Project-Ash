"""Key a hero's green-screen battle sprite and its idle clip into the game's sprite and frame sheet.

    python3 tools/body-clip.py still.png clip.mp4 out_sprite.webp out_sheet.webp [attack.mp4 out_attack.webp]

The still and every frame share one crop (the union of the figure across the clip, feet on the bottom edge), so the
still and the sheet line up and the figure never jumps when the game swaps between them. The sheet is the clip at
12 fps, frames FRAME_H tall, COLS across, which is what Figure's `anim` reads.

An attack clip becomes a second sheet of just the swing (the frames that move, at 24 fps), scaled so the fighter
stands as tall as in the idle and anchored at the same feet, so the game can cut idle → attack → idle without a jump.
Its cells are as tall and wide as the swing needs (`tall` is its height against the idle's, `foot_x` where the feet
stand across it), and `hit` is when the blow lands (the frame reaching furthest ahead of the feet).
Prints {"idle": anim, "foot_x": …, "attack": anim or absent}.
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
# The swing: this many frames a second, this long either side of the blow, at this share of the idle's resolution
# (a strike is on screen for a second; it needn't be as sharp as the idle you look at all fight).
ATTACK_FPS = 16
ATTACK_BEFORE, ATTACK_AFTER = 0.45, 0.6
ATTACK_RES = 0.6


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


def frames(src, fps=FPS):
    w, h, _ = face.probe(src)
    dec = subprocess.run(["ffmpeg", "-v", "error", "-i", src, "-vf", f"fps={fps}", "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
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


def feet(a):
    """Where the figure stands in a frame: the centre of its lowest rows (x) and its lowest row (y), in pixels, and its
    height."""
    ys, xs = np.nonzero(a > 24)
    bottom, top = ys.max(), ys.min()
    low = xs[ys > bottom - (bottom - top) * 0.08]
    return float(low.mean()), float(bottom + 1), float(bottom + 1 - top)


def attack(src, dst, idle_h, idle_fx_px, idle_bx, still_shape):
    """The swing as a sheet matched to the idle (see the module notes)."""
    seq = frames(src, ATTACK_FPS)
    fx, fy, fh = feet(seq[0][..., 3])
    reach = []
    for f in seq:
        ys, xs = np.nonzero(f[..., 3] > 24)
        # Sprites face screen-left, so the blow is the frame reaching furthest that way.
        reach.append(fx - xs.min())
    blow = int(np.argmax(reach))
    lo = max(0, blow - round(ATTACK_BEFORE * ATTACK_FPS))
    hi = min(len(seq), blow + round(ATTACK_AFTER * ATTACK_FPS) + 1)
    seq, blow = seq[lo:hi], blow - lo
    # Pixels of the idle cell per pixel of this clip, so the fighter stands the same height in both.
    k = idle_h / fh * ATTACK_RES
    l, t, r = seq[0].shape[1], seq[0].shape[0], 0
    for f in seq:
        ys, xs = np.nonzero(f[..., 3] > 24)
        l, t, r = min(l, xs.min()), min(t, ys.min()), max(r, xs.max() + 1)
    l, t, r = max(0, l - 4), max(0, t - 4), min(seq[0].shape[1], r + 4)
    cw, ch = round((r - l) * k), round((fy - t) * k)
    cols = 8
    rows = (len(seq) + cols - 1) // cols
    sheet = Image.new("RGBA", (cw * cols, ch * rows))
    for i, f in enumerate(seq):
        c = Image.fromarray(f[t:int(fy), l:r]).resize((cw, ch), Image.LANCZOS)
        sheet.paste(c, ((i % cols) * cw, (i // cols) * ch))
    sheet.save(dst, "WEBP", quality=82, method=6)
    return {"w": cw, "h": ch, "cols": cols, "n": len(seq), "fps": ATTACK_FPS, "tall": round(ch / ATTACK_RES / FRAME_H, 4),
        "foot_x": round((fx - l) / (r - l), 4), "hit": round(blow / ATTACK_FPS, 3)}


def main(still_src, clip_src, sprite_dst, sheet_dst, attack_src=None, attack_dst=None):
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
    # Where the feet stand across the idle cell, and how tall the fighter stands in it.
    c0 = np.asarray(cells[0].resize((fw, FRAME_H), Image.LANCZOS))[..., 3]
    fx, _, fh = feet(c0)
    out = {"idle": {"w": fw, "h": FRAME_H, "cols": COLS, "n": len(cells), "fps": FPS}, "foot_x": round(fx / fw, 4)}
    if attack_src:
        out["attack"] = attack(attack_src, attack_dst, fh, fx, bx, still.shape)
    print(json.dumps(out))


if __name__ == "__main__":
    main(*sys.argv[1:7])
