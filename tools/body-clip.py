"""Key a hero's green-screen battle sprite and its idle clip into the game's sprite and frame sheet.

    python3 tools/body-clip.py still.png clip.mp4 out_sprite.webp out_sheet.webp [attack.mp4 out_attack.webp]
    python3 tools/body-clip.py still.png - out_sprite.webp - [attack.mp4 out_attack.webp]

With no idle clip (-) the still alone becomes the sprite, trimmed to the figure, and the game breathes it.

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
import shutil
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
# The longest a whole-move clip plays for (see `move`): a strike is quick, a skill takes its time.
ATTACK_FIT, SKILL_FIT = 1.3, 2.0
# The share of the frame's width (and height, at the top) over which a clip's edges fade out.
EDGE = 0.12


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


def decode(src, fps):
    """The clip's frames as RGB arrays at `fps`: through ffmpeg, or PyAV where ffmpeg isn't installed."""
    if shutil.which("ffmpeg"):
        w, h, _ = face.probe(src)
        dec = subprocess.run(["ffmpeg", "-v", "error", "-i", src, "-vf", f"fps={fps}", "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
            capture_output=True, check=True).stdout
        n = w * h * 3
        return [np.frombuffer(dec[i * n:(i + 1) * n], np.uint8).reshape(h, w, 3) for i in range(len(dec) // n)]
    import av
    out = []
    with av.open(src) as c:
        for fr in c.decode(video=0):
            while len(out) <= fr.time * fps:
                out.append(fr.to_ndarray(format="rgb24"))
    return out


def frames(src, fps=FPS, channel=False):
    """The clip keyed, frame by frame; with `channel`, also which backdrop it was shot on (see face.key_channel)."""
    out = []
    ch = None
    for rgb in decode(src, fps):
        ch = ch or face.key_channel(rgb)
        col, a = face.key(rgb, ch)
        out.append(clean(np.dstack([col, a])))
    return (out, ch) if channel else out


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


def fade_edges(f):
    """Fades the frame's alpha toward its sides and top, so an effect the clip cut off at the frame thins out instead of
    ending in a straight edge. The bottom stays, for the feet."""
    h, w = f.shape[:2]
    k = np.minimum(np.clip(np.arange(w) / (w * EDGE), 0, 1), np.clip((w - 1 - np.arange(w)) / (w * EDGE), 0, 1))
    f = f.copy()
    f[..., 3] = (f[..., 3] * k[None, :] * np.clip(np.arange(h) / (h * EDGE), 0, 1)[:, None]).astype(np.uint8)
    return f


def glow(f):
    """Takes the backdrop out of a see-through effect: flame glowing over green turns olive (green as strong as red, well
    above blue), so a half-clear pixel that olive fades and warms back to orange. Water (bluer than green) keeps its teal.
    Only for clips shot on green: a hero who wears green is shot on magenta and skips this."""
    rgb = f[..., :3].astype(np.float32)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    a = f[..., 3].astype(np.float32)
    # Thick glow keys as solid while still plainly greener than it is red or blue: clear it by how much greener.
    over = g - np.maximum(r, b)
    a *= np.clip(1 - over / 50, 0, 1)
    olive = np.clip((g / np.maximum(r, 1) - 0.7) / 0.3, 0, 1) * (a < 250) * (g > b + 20)
    a *= 1 - 0.85 * olive
    g = np.where((olive > 0) | (over > 0), np.minimum(g, np.maximum(r, b) * 0.75), g)
    return np.dstack([r, g, b, a]).clip(0, 255).astype(np.uint8)


def move(seq, fit):
    """The whole move in a clip that starts and ends in the standing pose, sped up to last at most `fit` seconds: from
    the first frame that leaves the pose to the one that settles back."""
    a0 = seq[0][..., 3].astype(np.float32)
    off = [float(np.abs(f[..., 3].astype(np.float32) - a0).mean()) for f in seq]
    busy = np.nonzero(np.array(off) > max(off) * 0.08)[0]
    lo, hi = max(0, busy[0] - 2), min(len(seq), busy[-1] + 3)
    keep = np.unique(np.linspace(lo, hi - 1, min(hi - lo, round(fit * ATTACK_FPS))).round().astype(int))
    return [seq[i] for i in keep]


def attack(src, dst, idle_h, idle_fx_px=0, idle_bx=None, still_shape=None, fit=None):
    """The swing as a sheet matched to the idle (see the module notes). With `fit` (seconds) the clip is a whole move
    made facing left, as Gamelabs clips are: all of it plays, sped up to fit, and its see-through effects are cleaned."""
    seq, ch = frames(src, ATTACK_FPS, channel=True)
    fx, fy, fh = feet(seq[0][..., 3])
    if fit:
        seq = [fade_edges(f) for f in move(seq, fit)]
        seq = [glow(f) for f in seq] if ch == 1 else seq
    left, right = [], []
    for f in seq:
        ys, xs = np.nonzero(f[..., 3] > 24)
        left.append(fx - xs.min())
        right.append(xs.max() - fx)
    # The swing faces whichever way it reaches furthest, and the blow is the frame reaching furthest that way.
    faces = "left" if fit or max(left) >= max(right) else "right"
    reach = left if faces == "left" else right
    blow = int(np.argmax(reach))
    if fit:
        # A cast may not reach ahead at all (a pillar, a veil): its peak is the frame furthest from the standing pose.
        a0 = seq[0][..., 3].astype(np.float32)
        blow = int(np.argmax([np.abs(f[..., 3].astype(np.float32) - a0).mean() for f in seq]))
    else:
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
        "foot_x": round((fx - l) / (r - l), 4), "hit": round(blow / ATTACK_FPS, 3), "faces": faces}


def main(still_src, clip_src, sprite_dst, sheet_dst, attack_src=None, attack_dst=None):
    im = np.asarray(Image.open(still_src).convert("RGB"))
    col, a = face.key(im, face.key_channel(im))
    still = clean(np.dstack([col, a]))
    if clip_src == "-":
        bx = box([still[..., 3]])
        s = Image.fromarray(crop(still, bx))
        s = s.resize((round(s.width * STILL_H / s.height), STILL_H), Image.LANCZOS) if s.height > STILL_H else s
        s.save(sprite_dst, "WEBP", quality=88, method=6)
        fx, _, fh = feet(np.asarray(s)[..., 3])
        out = {"foot_x": round(fx / s.width, 4)}
        if attack_src:
            # The figure fills the sprite, so it stands the whole height of an idle cell.
            out["attack"] = attack(attack_src, attack_dst, FRAME_H * fh / s.height, 0, bx, still.shape)
        print(json.dumps(out))
        return
    seq = frames(clip_src)
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


def swing(idle_sheet, idle_json, clip_src, dst, kind="attack"):
    """A move for a fighter whose idle is a ready sheet: matched to the height they stand in its first cell."""
    m = json.loads(Path(idle_json).read_text())["idle"]
    cell = np.asarray(Image.open(idle_sheet).convert("RGBA").crop((0, 0, m["w"], m["h"])))
    _, _, fh = feet(cell[..., 3])
    print(json.dumps(attack(clip_src, dst, fh, fit=SKILL_FIT if kind == "skill" else ATTACK_FIT)))


if __name__ == "__main__":
    if sys.argv[1] == "swing":
        swing(*sys.argv[2:7])
    else:
        main(*sys.argv[1:7])
