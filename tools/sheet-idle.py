"""Turn a hero's transparent idle sheet into the game's sprite and frame sheet.

    python3 tools/sheet-idle.py source.webp source.json out_sprite.webp out_sheet.webp [mirror]

`body-clip.py` starts from a green-screen video; this starts from a sheet that is already keyed, such as a Gamelabs
spritesheet. source.json holds {"cols", "rows", "n", "fps", "lead"}: the grid of the sheet, how many cells hold frames,
the rate the loop plays at (each sprite keeps its own fps), and how many of the cells are run-up before the loop proper,
used to blend the join (see blend_join; 0 or absent for a sheet that loops as it is). An optional "key": "magenta" says
the clip was keyed on magenta rather than green.

Each frame loses any green the key left behind (specks in hair and gaps, and the green fringe on edges), gains a soft
dark edge so the figure sits on any ground, and is shifted so the feet stay on the spot of the first frame. All frames
share one crop with the feet on the bottom edge, FRAME_H tall and COLS across, which is what Figure's `anim` reads. The
sprite is the first frame, so swapping between it and the sheet never jumps.
With `mirror` every frame is flipped, for a sheet that faces right (MIRROR in organize-art).
Prints {"idle": anim, "foot_x": …, "drift": how far the feet moved before they were pinned, in cell pixels}.
"""
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).resolve().parent))
clip = __import__("body-clip")

FRAME_H, COLS, STILL_H = clip.FRAME_H, clip.COLS, clip.STILL_H
# The edge shadow, in pixels of a cell: how far it spreads, how soft it is, how dark, and its colour. The margin keeps
# it inside the cell.
EDGE_SPREAD, EDGE_BLUR, EDGE_DARK = 2, 2.0, 0.55
EDGE_COLOR = (14, 10, 8)
MARGIN = 8
# Green left by the key: how far green stands above red and blue before a pixel counts, and the share of it that goes.
SPILL_FROM = 12
GREEN_FLECK = 60
# How much of the figure's height, from the ground up, counts as its feet when placing it.
STANCE_BAND = 0.14


def cells(sheet, meta):
    a = np.asarray(sheet.convert("RGBA"))
    ch, cw = a.shape[0] // meta["rows"], a.shape[1] // meta["cols"]
    return [a[(i // meta["cols"]) * ch:(i // meta["cols"] + 1) * ch, (i % meta["cols"]) * cw:(i % meta["cols"] + 1) * cw]
        for i in range(meta["n"])]


def degreen(rgba, key="green"):
    """Clears leftover key: pure key-coloured specks go transparent, and a cast of it on what stays is pulled back to
    neutral. Green in the art itself is darker and greyer than the key, and only the cast above the others is removed.
    A hero who wears green is keyed on magenta (`key` in source.json), and the same goes for magenta."""
    out = rgba.astype(np.float32)
    r, g, b, a = out[..., 0], out[..., 1], out[..., 2], out[..., 3]
    if key == "magenta":
        over, bright = np.minimum(r, b) - g, np.minimum(r, b)
    else:
        over, bright = g - np.maximum(r, b), g
    edge = a < 250
    # Inside the figure a fleck can only be what's bright and saturated; on the edge a little is enough.
    fleck = (over > GREEN_FLECK) & (bright > 150)
    a[fleck] = 0
    near = ndimage.binary_dilation(a < 8, iterations=2)
    spill = (over > SPILL_FROM) & (edge | near)
    if key == "magenta":
        r[spill] = np.minimum(r, g)[spill]
        b[spill] = np.minimum(b, g)[spill]
    else:
        g[spill] = np.maximum(r, b)[spill]
    return np.clip(out + 0.5, 0, 255).astype(np.uint8)


def blend_join(seq, lead):
    """Closes the loop: the first `lead` frames are the run-up to the loop's start, so the last `lead` frames ease into
    them and then they are dropped. The last frame then leads into the first as any frame leads into the next."""
    if not lead:
        return seq
    out = list(seq[lead:])
    for k in range(lead):
        t = (k + 1) / (lead + 1)
        i = len(out) - lead + k
        a, b = out[i].astype(np.float32), seq[k].astype(np.float32)
        wa, wb = a[..., 3:] * (1 - t), b[..., 3:] * t
        alpha = wa + wb
        col = (a[..., :3] * wa + b[..., :3] * wb) / np.maximum(alpha, 1e-3)
        out[i] = np.clip(np.dstack([col, alpha]) + 0.5, 0, 255).astype(np.uint8)
    return out


def edge_shadow(rgba):
    """A soft dark rim under the figure, on the transparent side of its edge."""
    a = rgba[..., 3].astype(np.float32) / 255.0
    spread = ndimage.grey_dilation(a, size=EDGE_SPREAD * 2 + 1)
    rim = ndimage.gaussian_filter(spread, EDGE_BLUR) * EDGE_DARK
    out_a = a + rim * (1 - a)
    keep = out_a > 0.001
    out = np.zeros_like(rgba, np.float32)
    for c in range(3):
        over = rgba[..., c] * a + EDGE_COLOR[c] * rim * (1 - a)
        out[..., c][keep] = over[keep] / out_a[keep]
    out[..., 3] = out_a * 255
    return np.clip(out + 0.5, 0, 255).astype(np.uint8)


def stance(a):
    """Where the figure stands across a cell: the middle of what touches the ground, a low band deep enough to catch
    a back foot set higher in the picture than the front one."""
    ys, xs = np.nonzero(a > 24)
    low = xs[ys > ys.max() - (ys.max() - ys.min()) * STANCE_BAND]
    return (float(low.min()) + float(low.max()) + 1) / 2


def main(src, meta_src, sprite_dst, sheet_dst, mirror=""):
    meta = json.loads(Path(meta_src).read_text())
    seq = [degreen(c, meta.get("key", "green")) for c in cells(Image.open(src), meta)]
    seq = blend_join([clip.clean(c) for c in seq], meta.get("lead", 0))
    if mirror:
        seq = [c[:, ::-1].copy() for c in seq]
    # Pin the feet: each frame shifts by whole pixels back to the first frame's feet.
    fx0, fy0, _ = clip.feet(seq[0][..., 3])
    shifts = []
    for c in seq:
        fx, fy, _ = clip.feet(c[..., 3])
        shifts.append((round(fy0 - fy), round(fx0 - fx)))
    seq = [np.roll(c, s, (0, 1)) for c, s in zip(seq, shifts)]
    bx = clip.box([c[..., 3] for c in seq])
    crops = [Image.fromarray(clip.crop(c, bx)) for c in seq]
    k = (FRAME_H - MARGIN) / crops[0].height
    fw = round(crops[0].width * k)
    w, h = fw + MARGIN * 2, FRAME_H
    rows = (len(crops) + COLS - 1) // COLS
    sheet = Image.new("RGBA", (w * COLS, h * rows))
    first = None
    for i, c in enumerate(crops):
        cell = np.zeros((h, w, 4), np.uint8)
        cell[MARGIN:h, MARGIN:MARGIN + fw] = np.asarray(c.resize((fw, h - MARGIN), Image.LANCZOS))
        if i == 0:
            first = cell
        sheet.paste(Image.fromarray(edge_shadow(cell)), ((i % COLS) * w, (i // COLS) * h))
    sheet.save(sheet_dst, "WEBP", quality=82, method=6)
    Image.fromarray(edge_shadow(first)).save(sprite_dst, "WEBP", quality=88, method=6)
    drift = max(max(abs(a), abs(b)) for a, b in shifts) * k
    print(json.dumps({"idle": {"w": w, "h": h, "cols": COLS, "n": len(crops), "fps": meta["fps"]},
        "foot_x": round(stance(first[..., 3]) / w, 4), "drift": round(float(drift), 2)}))


if __name__ == "__main__":
    main(*sys.argv[1:6])
