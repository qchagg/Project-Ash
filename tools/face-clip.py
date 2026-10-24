"""Key a hero's green-screen clips and stills for the game.

A clip comes out as a Theora video twice as tall as it is wide: the colour on top, its transparency (as grey) below.
Theora has no alpha channel, so the game's Bust shader puts the two halves back together. Keying here, frame by frame,
is far cleaner than keying live: spill is taken out of hair and water, and the colour under the transparent parts is
filled from the nearest opaque pixel so the video's colour blur can't bleed green into the edges.

    python3 tools/face-clip.py clip in.mp4 out.ogv [--size 576]
    python3 tools/face-clip.py still in.png out.webp [--size 1024]

Shoot on flat green; a hero who wears green goes on magenta, and the key follows whichever the border shows.
"""
import subprocess
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

# Greenness (the key channel over the larger of the other two) at which a pixel starts and finishes turning clear.
SOFT, HARD = 34.0, 88.0


def key_channel(rgb):
    """Which channel the backdrop lives in, from the frame's border: 1 for green, or -1 for magenta (red and blue)."""
    b = np.concatenate([rgb[:8].reshape(-1, 3), rgb[:, :8].reshape(-1, 3), rgb[:, -8:].reshape(-1, 3)])
    m = np.median(b, 0)
    return 1 if m[1] > max(m[0], m[2]) else -1


def key(rgb, ch=1):
    """Straight RGBA from an RGB frame: clear where the backdrop shows, spill taken out where it bled."""
    f = rgb.astype(np.float32)
    r, g, b = f[..., 0], f[..., 1], f[..., 2]
    if ch == 1:
        over = g - np.maximum(r, b)
    else:
        over = np.minimum(r, b) - g
    a = 1.0 - np.clip((over - SOFT) / (HARD - SOFT), 0.0, 1.0)
    a = ndimage.gaussian_filter(a, 0.6)
    a[a < 0.04] = 0.0
    # Despill where the backdrop can reach: see-through parts and a few pixels in from every edge. There the key
    # channel never rises above the others, so fringes turn neutral (or teal, on water); solid green inside the
    # figure (beads, trim) keeps its colour.
    near = ndimage.binary_dilation(a < 0.98, iterations=3)
    if ch == 1:
        g = np.where(near, np.minimum(g, np.maximum(r, b)), g)
    else:
        lim = g + np.maximum(0, over)
        r = np.where(near, np.minimum(r, np.maximum(g, lim * 0.5)), r)
        b = np.where(near, np.minimum(b, np.maximum(g, lim * 0.5)), b)
    out = np.stack([r, g, b], -1)
    # Fill the clear parts with the nearest solid colour.
    solid = a > 0.5
    if solid.any():
        idx = ndimage.distance_transform_edt(~solid, return_distances=False, return_indices=True)
        fill = out[idx[0], idx[1]]
        out = np.where((a < 0.98)[..., None], fill * (1 - a[..., None]) + out * a[..., None], out)
    return np.clip(out, 0, 255).astype(np.uint8), (a * 255).astype(np.uint8)


def probe(src):
    o = subprocess.check_output(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries",
        "stream=width,height,r_frame_rate", "-of", "csv=p=0", src]).decode().strip().split(",")
    return int(o[0]), int(o[1]), o[2]


def clip(src, dst, size=576):
    w, h, rate = probe(src)
    sh = size * h // w // 2 * 2
    dec = subprocess.Popen(["ffmpeg", "-v", "error", "-i", src, "-vf", f"scale={size}:{sh}:flags=lanczos",
        "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], stdout=subprocess.PIPE)
    enc = subprocess.Popen(["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{size}x{sh * 2}",
        "-r", rate, "-i", "-", "-an", "-c:v", "libtheora", "-q:v", "5", "-pix_fmt", "yuv420p", dst], stdin=subprocess.PIPE)
    n = size * sh * 3
    ch = None
    frames = 0
    while True:
        buf = dec.stdout.read(n)
        if len(buf) < n:
            break
        rgb = np.frombuffer(buf, np.uint8).reshape(sh, size, 3)
        ch = ch or key_channel(rgb)
        col, a = key(rgb, ch)
        enc.stdin.write(np.concatenate([col, np.repeat(a[..., None], 3, -1)], 0).tobytes())
        frames += 1
    enc.stdin.close()
    enc.wait()
    dec.wait()
    print(f"{dst}: {frames} frames, {size}x{sh} packed to {size}x{sh * 2}")


def still(src, dst, size=1024):
    im = Image.open(src).convert("RGB")
    im = im.resize((size, size * im.height // im.width), Image.LANCZOS)
    rgb = np.asarray(im)
    col, a = key(rgb, key_channel(rgb))
    Image.fromarray(np.dstack([col, a])).save(dst, "WEBP", quality=88, method=6)
    print(f"{dst}: {im.width}x{im.height}")


if __name__ == "__main__":
    args = sys.argv[1:]
    size = None
    if "--size" in args:
        i = args.index("--size")
        size = int(args[i + 1])
        del args[i:i + 2]
    mode, src, dst = args
    if mode == "clip":
        clip(src, dst, size or 576)
    else:
        still(src, dst, size or 1024)
