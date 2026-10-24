"""Sort uploaded art into one folder per character, then build their faces for the game.

Upload anywhere under art/ (the root is fine) and run:

    python3 tools/organize-art.py

1. Sort: every file goes to art/<character>/<character>-<rest>, lower case, spaces as dashes. The character comes from
   the file's prefix (`fox-face-idle1.mp4`) or, failing that, its folder; old names map to the cast's names (fox and
   kaede → surya, ilse and mermaid → varuni, leaf → galeblade, rock → basalt). A name the cast doesn't know yet gets a
   folder of its own. Moves go through git, so nothing is lost. art/_archive and the README stay put.
2. Faces: `<character>-face-<kind><n>.mp4` clips (idle, talk, spell, or anything else) are keyed into
   game/art/clips/<character>-<kind><n>.ogv and `<character>-face-blank.png` into game/art/faces/<character>.webp
   (tools/face-clip.py); other `-face-<mood>.png` stills become expressions. Only what changed is rebuilt.
3. Bodies: `<character>-body-<pose>.png` (a still, `idle` first) and `<character>-body-<pose>.mp4` (its loop) become the
   battle sprite game/art/sprites/<character>.webp and its frame sheet <character>-idle.webp (tools/body-clip.py);
   `<character>-body-attack.mp4` adds the swing, <character>-attack.webp. A still with no loop is sprite enough: the
   game breathes it.
4. Cards: `<character>-card.png` (the hero on green, for the phone build's cards) is keyed into game/art/cards/.
5. Writes game/core/faces.gd, the table the game reads (see Faces).
"""
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ART = ROOT / "art"
GAME = ROOT / "game"
ALIASES = {"fox": "surya", "kaede": "surya", "ilse": "varuni", "mermaid": "varuni", "leaf": "galeblade",
    "rock": "basalt", "caller": "tidecaller", "newcomer": "snake"}
# The game's key for each character who is already in it.
KEYS = {"surya": "kaede", "varuni": "ilse", "brann": "brann", "sorrel": "sorrel", "galeblade": "leaf", "basalt": "rock",
    "tidecaller": "caller", "seer": "seer", "golem": "golem"}
# Which spell clip plays which skill (by slot), where the default (spell1 → first skill, spell2 → second) is wrong.
# "chant" is the clip a hero sings when they evolve; by default their last spell beyond the skills, else their first.
SKILL_CLIPS = {"varuni": {"skills": ["spell3", "spell2"], "chant": "spell1"}}
KEEP = {"README.md"}


def git(*args):
    subprocess.run(["git", *args], cwd=ROOT, check=True)


def tidy(name):
    return re.sub(r"[\s_]+", "-", name.strip().lower())


def sort():
    moved = 0
    for p in sorted(ART.rglob("*")):
        if not p.is_file() or p.name in KEEP or "_archive" in p.parts or p.name.startswith("."):
            continue
        rel = p.relative_to(ART)
        folder = rel.parts[0] if len(rel.parts) > 1 else ""
        stem, ext = os.path.splitext(tidy(p.name))
        head, _, rest = stem.partition("-")
        if folder == "sprites":
            char = ALIASES.get(head, head)
            rest = "sprite" + ("-" + rest if rest else "")
        elif (ALIASES.get(head, head) in KEYS or ALIASES.get(head, head) == ALIASES.get(folder, folder) or not folder
                or (ART / ALIASES.get(head, head)).is_dir()):
            # The name says whose it is, even when it was dropped in someone else's folder.
            char = ALIASES.get(head, head)
        else:
            char = ALIASES.get(folder, folder)
            rest = stem
        dst = ART / char / (f"{char}-{rest}{ext}" if rest else f"{char}{ext}")
        if dst == p:
            continue
        dst.parent.mkdir(parents=True, exist_ok=True)
        if dst.exists():
            print(f"skip {rel}: {dst.relative_to(ART)} already exists")
            continue
        tracked = subprocess.run(["git", "ls-files", "--error-unmatch", str(p)], cwd=ROOT, capture_output=True).returncode == 0
        if tracked:
            git("mv", str(p), str(dst))
        else:
            p.rename(dst)
        print(f"{rel} → {dst.relative_to(ART)}")
        moved += 1
    for d in sorted(ART.rglob("*"), reverse=True):
        if d.is_dir() and not any(d.iterdir()):
            d.rmdir()
    return moved


def stale(src, dst):
    return not dst.exists() or dst.stat().st_mtime < src.stat().st_mtime


def body(d, char):
    """The battle sprite, idle sheet and attack sheet from the body uploads, or None. Rebuilt when an upload is newer.
    The idle loop is the clip named idle, else movement, else any clip that isn't an attack. With no loop, the still
    alone is the sprite and the game breathes it."""
    import json
    stills = sorted(d.glob(f"{char}-body-*.png"), key=lambda p: ("idle" not in p.stem, p.name))
    loops = sorted((p for p in d.glob(f"{char}-body-*.mp4") if "attack" not in p.stem),
        key=lambda p: ("idle" not in p.stem, "movement" not in p.stem, p.name))
    hits = sorted(d.glob(f"{char}-body-attack*.mp4"))
    if not stills:
        return None
    sprites = GAME / "art" / "sprites"
    sprite, sheet, meta = sprites / f"{char}.webp", sprites / f"{char}-idle.webp", sprites / f"{char}-idle.json"
    swing = sprites / f"{char}-attack.webp"
    srcs = [stills[0]] + loops[:1] + hits[:1]
    old = json.loads(meta.read_text()) if meta.exists() else {}
    if any(stale(p, meta) for p in srcs) or ("idle" in old) != bool(loops) or bool(hits) != ("attack" in old):
        args = [str(stills[0]), str(loops[0]) if loops else "-", str(sprite), str(sheet) if loops else "-"]
        args += [str(hits[0]), str(swing)] if hits else []
        out = subprocess.run([sys.executable, str(ROOT / "tools" / "body-clip.py"), *args], check=True,
            capture_output=True, text=True).stdout
        meta.write_text(out.strip().splitlines()[-1])
    m = json.loads(meta.read_text())
    b = {"src": f"res://art/sprites/{char}.webp", "foot_x": m["foot_x"]}
    if "idle" in m:
        b["anim"] = dict(m["idle"], src=f"res://art/sprites/{char}-idle.webp")
    if "attack" in m:
        b["attack"] = dict(m["attack"], src=f"res://art/sprites/{char}-attack.webp")
    return b


def card(d, char):
    """The keyed card art and where the figure stands across it (its centre, 0..1), or None."""
    src = next((p for p in sorted(d.glob(f"{char}-card.*")) if p.suffix in (".png", ".webp", ".jpg")), None)
    if not src:
        return None
    out = GAME / "art" / "cards" / f"{char}.webp"
    out.parent.mkdir(parents=True, exist_ok=True)
    if stale(src, out):
        subprocess.run([sys.executable, str(ROOT / "tools" / "face-clip.py"), "still", str(src), str(out)], check=True)
    from PIL import Image
    import numpy as np
    a = np.asarray(Image.open(out))[..., 3].astype(float)
    cx = float((a.sum(0) * np.arange(a.shape[1])).sum() / max(a.sum(), 1) / a.shape[1])
    return {"src": f"res://art/cards/{char}.webp", "cx": round(cx, 3)}


def build():
    faces = {}
    bodies = {}
    cards = {}
    tool = ROOT / "tools" / "face-clip.py"
    for d in sorted(p for p in ART.iterdir() if p.is_dir() and p.name != "_archive"):
        char = d.name
        f = {"clips": {}, "moods": {}}
        for src in sorted(d.glob(f"{char}-face-*")):
            kind = src.stem[len(char) + len("-face-"):]
            if src.suffix == ".mp4":
                out = GAME / "art" / "clips" / f"{char}-{kind}.ogv"
                if stale(src, out):
                    subprocess.run([sys.executable, str(tool), "clip", str(src), str(out)], check=True)
                f["clips"][kind] = f"{char}-{kind}"
            elif src.suffix in (".png", ".webp", ".jpg"):
                name = "" if kind == "blank" else "-" + kind
                out = GAME / "art" / "faces" / f"{char}{name}.webp"
                if stale(src, out):
                    subprocess.run([sys.executable, str(tool), "still", str(src), str(out)], check=True)
                if kind == "blank":
                    f["still"] = f"res://art/faces/{char}.webp"
                else:
                    f["moods"][kind] = f"res://art/faces/{char}{name}.webp"
        if "still" in f:
            faces[char] = f
        b = body(d, char)
        if b:
            bodies[KEYS.get(char, char)] = b
        c = card(d, char)
        if c:
            cards[KEYS.get(char, char)] = c
    lines = ['## Made by tools/organize-art.py from the art/ folder; run it again rather than editing this by hand.',
        "## Each character's live face: the still, the clips by kind, the clip for each skill slot and the evolve chant.",
        "class_name Faces", "extends RefCounted", "", "const FACES := {"]
    for char, f in faces.items():
        clips = f["clips"]
        by = lambda k: sorted(c for n, c in clips.items() if re.fullmatch(k + r"\d*", n))
        spells = sorted(n for n in clips if n.startswith("spell"))
        plan = SKILL_CLIPS.get(char, {})
        skills = plan.get("skills", spells[:2])
        chant = plan.get("chant", spells[2] if len(spells) > 2 else (spells[0] if spells else ""))
        other = sorted(c for n, c in clips.items() if not re.fullmatch(r"(idle|talk|spell)\d*", n))
        entry = {"char": char, "still": f["still"], "idle": by("idle"), "talk": by("talk"),
            "skills": [f"{char}-{s}" for s in skills], "chant": f"{char}-{chant}" if chant else "", "other": other,
            "moods": f["moods"]}
        key = KEYS.get(char, char)
        lines.append(f'\t"{key}": {gd(entry)},')
    lines += ["}", "", "## Battle sprites built from body uploads, by game key: they replace the src and idle in Data.SPRITES.",
        "const BODIES := {"]
    for key, b in bodies.items():
        lines.append(f'\t"{key}": {gdv(b)},')
    lines += ["}", "", "## Keyed card art, by game key: the phone build's cards show it over the element's glow, centred on the",
        "## figure (`cx`, its centre across the image).", "const CARDS := {"]
    for key, c in cards.items():
        lines.append(f'\t"{key}": {{"src": "{c["src"]}", "cx": {c["cx"]}}},')
    lines += ["}", "", "", "## The face of a hero (by game key), or {} if they have none yet.",
        "static func of(key: String) -> Dictionary:", "\treturn FACES.get(key, {})", "", "",
        "## The clip a hero's skill plays as its cut-in (by slot: s0, s1), or \"\".",
        "static func skill_clip(key: String, slot: String) -> String:",
        "\tvar skills: Array = of(key).get(\"skills\", [])", "\tvar i := slot.substr(1).to_int()",
        "\treturn skills[i] if slot.begins_with(\"s\") and i < skills.size() else \"\"", ""]
    (GAME / "core" / "faces.gd").write_text("\n".join(lines))
    # Battle sprites import lossy, so the game pack stays small; a new sprite gets that once Godot has imported it.
    for imp in (GAME / "art" / "sprites").glob("*.webp.import"):
        t = imp.read_text()
        if "compress/mode=0" in t:
            imp.write_text(t.replace("compress/mode=0", "compress/mode=1").replace("lossy_quality=0.7", "lossy_quality=0.8"))
    print(f"faces: {', '.join(faces)}")


def gdv(v):
    """Like gd, but numbers stay numbers."""
    if isinstance(v, dict):
        return "{" + ", ".join(f'"{k}": {gdv(x)}' for k, x in v.items()) + "}"
    if isinstance(v, str):
        return f'"{v}"'
    return str(v)


def gd(v):
    if isinstance(v, dict):
        return "{" + ", ".join(f'"{k}": {gd(x)}' for k, x in v.items()) + "}"
    if isinstance(v, list):
        return "[" + ", ".join(gd(x) for x in v) + "]"
    return f'"{v}"'


if __name__ == "__main__":
    print(f"sorted {sort()} files")
    build()
