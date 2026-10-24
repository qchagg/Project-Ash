"""Build the Asset Viewer: every character's art side by side, for judging whether it all looks like one person.

    python3 tools/asset-viewer.py OUT_DIR

Reads art/<character>/ (after tools/organize-art.py) and the keyed faces in game/art/, writes OUT_DIR/index.html
(from tools/asset-viewer.html) and OUT_DIR/media/: light previews only (images ≤ 720px as WebP, face clips as small
H.264 on the game's ink, keyed from the game's own clips so the viewer shows exactly what the game shows). Only what
changed is rebuilt. Publish OUT_DIR/index.html with media/ as its files.
"""
import json
import re
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
ART = ROOT / "art"
GAME = ROOT / "game" / "art"
INK = "0x16130f"
# The order the cast is shown in; anyone else follows, by name.
CAST = ["surya", "brann", "sorrel", "varuni", "basalt", "galeblade", "tidecaller", "seer", "golem", "snake", "smoke"]
KEYS = {"surya": "kaede", "varuni": "ilse", "galeblade": "leaf", "basalt": "rock", "tidecaller": "caller"}
NAMES = {"surya": "Surya", "brann": "Brann", "sorrel": "Sorrel", "varuni": "Varuni", "basalt": "Basalt",
    "galeblade": "Galeblade", "tidecaller": "Tidecaller", "seer": "Seer", "golem": "Basalt Golem", "snake": "Snake", "smoke": "Smoke"}


def stale(src, dst):
    return not dst.exists() or dst.stat().st_mtime < src.stat().st_mtime


def image(src, dst, edge=720):
    if stale(src, dst):
        im = Image.open(src)
        im = im.convert("RGBA" if im.mode in ("RGBA", "LA", "P") else "RGB")
        im.thumbnail((edge, edge), Image.LANCZOS)
        im.save(dst, "WEBP", quality=84, method=6)
    with Image.open(dst) as im:
        return im.size


def clip(src, dst):
    """A packed game clip (colour over transparency) laid on the ink, 360px, as H.264."""
    f = (f"[0]crop=iw:ih/2:0:0[c];[0]crop=iw:ih/2:0:ih/2,format=gray[a];[c][a]alphamerge[k];"
            f"color=c={INK}:s=576x576:r=24[bg];[bg][k]overlay=shortest=1,scale=360:360")
    if stale(src, dst):
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(src), "-filter_complex", f, "-c:v", "libx264", "-crf", "27",
            "-preset", "slow", "-pix_fmt", "yuv420p", "-movflags", "+faststart", "-an", str(dst)], check=True)
    # A VP9 copy for browsers without H.264 (Chromium builds, some Linux).
    webm = dst.with_suffix(".webm")
    if stale(src, webm):
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(src), "-filter_complex", f, "-c:v", "libvpx-vp9", "-crf", "38",
            "-b:v", "0", "-row-mt", "1", "-an", str(webm)], check=True)


def body_clip(src, dst):
    f = (f"[0]colorkey=0x10e070:0.32:0.12,scale=360:360[k];color=c={INK}:s=360x360:r=24[bg];"
        f"[bg][k]overlay=shortest=1")
    for out, codec in ((dst, ["-c:v", "libx264", "-crf", "27", "-preset", "slow", "-pix_fmt", "yuv420p", "-movflags", "+faststart"]),
            (dst.with_suffix(".webm"), ["-c:v", "libvpx-vp9", "-crf", "38", "-b:v", "0", "-row-mt", "1"])):
        if stale(src, out):
            subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(src), "-filter_complex", f, *codec, "-an", str(out)], check=True)


def kind_of(rest):
    if rest.startswith("face"):
        return "face"
    if rest.startswith(("sprite", "body")) or "full" in rest or "cutout" in rest:
        return "body"
    if rest in ("blank", "bg") or rest.startswith("card"):
        return "card"
    return "other"


def label_of(rest):
    names = {"face-blank": "face · still", "blank": "card art", "bg": "card art, painted ground", "sprite": "battle sprite",
        "full-cutout": "full body", "cutout": "cutout", "full-chat": "full body, chat pose", "body-idle": "battle sprite (new)",
        "body-movement": "battle idle (new)", "body-attack": "battle attack (new)", "card": "card art (new)", "sprite-old": "battle sprite (old)"}
    if rest in names:
        return names[rest]
    m = re.fullmatch(r"face-([a-z]+?)(\d*)", rest)
    if m:
        return f"face · {m.group(1)} {m.group(2)}".strip()
    return rest.replace("-", " ")


def build(out):
    media = out / "media"
    chars = []
    dirs = [d for d in ART.iterdir() if d.is_dir() and d.name != "_trash"]
    dirs.sort(key=lambda d: (CAST.index(d.name) if d.name in CAST else 99, d.name))
    for d in dirs:
        c = d.name
        (media / c).mkdir(parents=True, exist_ok=True)
        assets = []
        for src in sorted(d.iterdir()):
            stem, ext = src.stem, src.suffix.lower()
            rest = stem[len(c) + 1:] if stem.startswith(c + "-") else stem
            if "sprite-idle" in rest:
                continue  # a frame sheet, shown by the Battle Sprites viewer
            a = {"id": f"{c}/{rest}", "kind": kind_of(rest), "label": label_of(rest), "src": f"art/{c}/{src.name}"}
            if ext == ".mp4" and rest.startswith("body"):
                # A body clip, keyed straight from the upload onto the ink (the game shows it as a frame sheet).
                dst = media / c / f"{rest}.mp4"
                body_clip(src, dst)
                a.update(type="video", file=f"media/{c}/{rest}.mp4", w=360, h=360)
            elif ext == ".mp4":
                game_clip = GAME / "clips" / f"{c}-{rest[len('face-'):]}.ogv"
                if not game_clip.exists():
                    continue
                dst = media / c / f"{rest}.mp4"
                clip(game_clip, dst)
                a.update(type="video", file=f"media/{c}/{rest}.mp4", w=360, h=360)
            elif ext in (".png", ".webp", ".jpg", ".jpeg"):
                # A face still shows keyed, as the game has it.
                keyed = {"face-blank": GAME / "faces" / f"{c}.webp", "body-idle": GAME / "sprites" / f"{c}.webp",
                    "card": GAME / "cards" / f"{c}.webp"}.get(rest)
                use = keyed if keyed and keyed.exists() else src
                dst = media / c / f"{rest}.webp"
                w, h = image(use, dst)
                a.update(type="image", file=f"media/{c}/{rest}.webp", w=w, h=h)
            else:
                continue
            assets.append(a)
        if assets:
            chars.append({"key": c, "name": NAMES.get(c, c.title()), "game": KEYS.get(c, c), "assets": assets})
    page = (ROOT / "tools" / "asset-viewer.html").read_text().replace("/*MANIFEST*/null", json.dumps(chars))
    (out / "index.html").write_text(page)
    n = sum(len(c["assets"]) for c in chars)
    size = sum(p.stat().st_size for p in media.rglob("*") if p.is_file())
    print(f"{len(chars)} characters, {n} assets, media {size / 1e6:.1f} MB")


if __name__ == "__main__":
    build(Path(sys.argv[1]))
