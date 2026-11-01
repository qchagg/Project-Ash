"""Rig a still battle sprite so the game can bring it to life without an idle clip.

    python3 tools/auto-rig.py game/art/sprites/snake.webp [preview.png]

Reads the cutout's transparency and finds, with no help from the art:
  pin    where the figure stands: near the pixels that touch the ground (the feet never move);
  head   the topmost mass of the figure, which nods about its neck;
  chest  the middle of the torso's mass, which breathes;
  loose  whatever hangs off the body's core (a braid, a hand, a sash end, a tassel): the parts too thin for a disc
         about a third of the body's thickness to fit in, more so the further they reach; and a hem, the lower body
         away from the feet.
It prints a rig for Figure (ui/figure.gd): a grid of COLS×ROWS cells over the sprite, and for each of its vertices
a weight 0–9 per channel, as strings, plus the head's neck point and the chest's centre (as shares of the sprite's
width and height). Figure deforms the sprite as a mesh over that grid. A preview PNG shows the channels in colour.
"""
import json
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

COLS, ROWS = 16, 28
# Analysis happens at this height (the shape matters, not the detail).
WORK_H = 240


def disc(r):
    y, x = np.ogrid[-r:r + 1, -r:r + 1]
    return x * x + y * y <= r * r


def norm(a):
    m = a.max()
    return a / m if m > 0 else a


def rig(path):
    im = Image.open(path).convert("RGBA")
    W, H = im.size
    k = WORK_H / H
    small = im.resize((max(8, round(W * k)), WORK_H), Image.BILINEAR)
    a = np.asarray(small)[..., 3] > 40
    a = ndimage.binary_closing(a, disc(1))
    h, w = a.shape
    ys, xs = np.nonzero(a)
    top, bottom = ys.min(), ys.max()
    tall = bottom - top + 1

    # Pin: the ground contact is the figure's lowest rows; everything near it stays put.
    # Each column's lowest pixel is ground if it reaches the bottom eighth of the figure (a foot set a little higher
    # than the other still stands).
    contact = np.zeros_like(a)
    for x in range(w):
        col = np.nonzero(a[:, x])[0]
        if len(col) and col.max() >= bottom - tall * 0.12:
            contact[max(0, col.max() - 2):col.max() + 1, x] = True
    d_feet = ndimage.distance_transform_edt(~contact)
    pin = np.clip(np.exp(-d_feet / (tall * 0.18)) * 1.5, 0, 1)

    # The core: the body's thick mass (what's left after opening with a disc). Loose: how far outside it a pixel reaches.
    thick = ndimage.distance_transform_edt(a)
    r = max(3, round(np.percentile(thick[a], 92) * 0.35))
    core = ndimage.binary_opening(a, disc(r))
    core = core if core.sum() > a.sum() * 0.25 else ndimage.binary_opening(a, disc(max(2, r // 2)))
    d_core = ndimage.distance_transform_edt(~core)
    loose = np.clip(d_core / (tall * 0.07), 0, 1) ** 0.7
    loose[~ndimage.binary_dilation(a, disc(3))] = 0
    # A hem sways too: the lower body away from the feet.
    yy, xx = np.mgrid[0:h, 0:w]
    hem = np.clip((yy - (top + tall * 0.5)) / (tall * 0.3), 0, 1) * 0.45 * a
    loose = np.maximum(loose, hem)

    # Head: the topmost tenth of the figure's mass; its neck sits just below it.
    head_band = a & (np.arange(h)[:, None] < top + tall * 0.13)
    hy, hx = np.nonzero(head_band)
    head_c = np.array([hx.mean(), hy.mean()])
    neck = np.array([head_c[0], top + tall * 0.17])
    head = 1.0 - np.clip((yy - (top + tall * 0.12)) / (tall * 0.08), 0, 1)
    head *= np.exp(-((xx - head_c[0]) ** 2) / (2 * (tall * 0.12) ** 2))

    # Chest: the centre of the core's mass between the neck and the hips.
    band = core & (yy > top + tall * 0.2) & (yy < top + tall * 0.45)
    cy, cx = np.nonzero(band) if band.any() else np.nonzero(a & (yy > top + tall * 0.2) & (yy < top + tall * 0.45))
    chest_c = np.array([cx.mean(), cy.mean()])
    chest = np.exp(-(((xx - chest_c[0]) / (tall * 0.14)) ** 2 + ((yy - chest_c[1]) / (tall * 0.1)) ** 2) / 2)
    chest *= core | ndimage.binary_dilation(core, disc(2))

    # Smooth every field (so the mesh bends rather than tears) and sample it at the grid's vertices.
    def grid(f, blur):
        f = ndimage.gaussian_filter(f.astype(float), blur)
        gy = np.linspace(0, h - 1, ROWS + 1)
        gx = np.linspace(0, w - 1, COLS + 1)
        return ndimage.map_coordinates(f, np.meshgrid(gy, gx, indexing="ij"), order=1)

    blur = tall * 0.03
    fields = {"pin": grid(pin, blur), "head": grid(head, blur), "chest": grid(norm(chest), blur), "loose": grid(loose, blur * 1.5)}
    fields["loose"] = norm(fields["loose"] * (1 - fields["pin"]) * (1 - fields["head"] * 0.7))
    out = {"cols": COLS, "rows": ROWS}
    for name, f in fields.items():
        out[name] = "".join(str(int(round(v))) for v in np.clip(f, 0, 1).ravel() * 9)
    out["neck"] = [round(neck[0] / w, 3), round(neck[1] / h, 3)]
    out["chest_at"] = [round(chest_c[0] / w, 3), round(chest_c[1] / h, 3)]
    return out, small, fields


def preview(small, fields, dst):
    """The sprite with its channels laid over it: loose red, chest green, head blue, pin as a dark veil."""
    base = small.convert("RGBA")
    w, h = base.size
    up = lambda f: np.asarray(Image.fromarray((np.clip(f, 0, 1) * 255).astype(np.uint8)).resize((w, h), Image.BILINEAR)) / 255.0
    rgb = np.zeros((h, w, 3))
    rgb[..., 0] = up(fields["loose"])
    rgb[..., 1] = up(fields["chest"])
    rgb[..., 2] = up(fields["head"])
    over = Image.fromarray((rgb * 255).astype(np.uint8)).convert("RGBA")
    over.putalpha(Image.fromarray((np.clip(rgb.max(2), 0, 1) * 210).astype(np.uint8)))
    pin = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    pin.putalpha(Image.fromarray((up(fields["pin"]) * 150).astype(np.uint8)))
    bg = Image.new("RGBA", (w, h), (30, 30, 36, 255))
    bg.alpha_composite(base)
    bg.alpha_composite(over)
    bg.alpha_composite(pin)
    bg.convert("RGB").resize((w * 2, h * 2), Image.NEAREST).save(dst)


if __name__ == "__main__":
    r, small, fields = rig(sys.argv[1])
    if len(sys.argv) > 2:
        preview(small, fields, sys.argv[2])
    print(json.dumps(r))
