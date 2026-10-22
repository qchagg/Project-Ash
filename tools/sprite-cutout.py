"""Cut a figure out of a flat background: key by colour from the border, keep the figure's own pieces, trim."""
import sys, numpy as np
from PIL import Image
from scipy import ndimage

def bg_of(a):
    e = np.concatenate([a[:12].reshape(-1, 3), a[-12:].reshape(-1, 3), a[:, :12].reshape(-1, 3), a[:, -12:].reshape(-1, 3)])
    return np.median(e, 0)

def cut(a, bg=None, tol=24):
    a = a.astype(np.float32)
    bg = bg_of(a) if bg is None else bg
    d = np.sqrt(((a - bg) ** 2).sum(-1))
    near = d < tol
    lab, _ = ndimage.label(near)
    border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    out = np.isin(lab, list(border))
    # Pockets of background enclosed by the figure (between arm and body): only exact background colour.
    out |= d < 7
    alpha = np.where(out, np.clip((d - 5) / (tol - 5), 0, 1), 1.0)
    # Keep the figure: big opaque pieces only (drops watermarks and specks).
    solid = alpha > 0.5
    lab2, n = ndimage.label(solid)
    if n:
        sizes = ndimage.sum(solid, lab2, range(1, n + 1))
        keep = np.isin(lab2, [i + 1 for i, s in enumerate(sizes) if s > sizes.max() * 0.02])
        keep = ndimage.binary_dilation(keep, iterations=3)
        alpha = alpha * keep
    al = np.clip(alpha, 1e-3, 1)[..., None]
    rgb = np.clip((a - bg * (1 - al)) / al, 0, 255)
    return np.dstack([rgb, alpha * 255]).astype(np.uint8), bg

def bbox(rgba, pad=6):
    ys, xs = np.where(rgba[..., 3] > 8)
    return max(0, xs.min() - pad), max(0, ys.min() - pad), min(rgba.shape[1], xs.max() + pad + 1), min(rgba.shape[0], ys.max() + pad + 1)

if __name__ == "__main__":
    src, dst = sys.argv[1], sys.argv[2]
    rgba, bg = cut(np.asarray(Image.open(src).convert("RGB")))
    x0, y0, x1, y1 = bbox(rgba)
    im = Image.fromarray(rgba).crop((x0, y0, x1, y1))
    if im.height > 900:
        im = im.resize((round(im.width * 900 / im.height), 900), Image.LANCZOS)
    im.save(dst, quality=90, method=6)
    print(dst, im.size, "bg", bg.round())
