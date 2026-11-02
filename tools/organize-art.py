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
   `<character>-sheet-idle.webp` (already keyed, with `<character>-sheet-idle.json` holding cols, rows, n and fps) takes
   their place: tools/sheet-idle.py makes the sprite and frame sheet from it alone. Beside it, `-body-attack.mp4` and
   `-body-skill.mp4` (whole moves facing left) become <character>-attack.webp and <character>-skill.webp.
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
# Every sprite is stored facing left, the one default; the game mirrors heroes to face right and leaves foes facing
# left. These are the body stills uploaded facing right, mirrored when they're built (an idle loop isn't, so a hero
# here who comes off HOLD_CLIPS needs their loop flipped too). Attack clips find their own facing from the swing.
# Judge this from the still itself (where the face points), never from an older upload: a new still can face the
# other way.
MIRROR = set()
# Heroes whose body clips are on hold: their idle loops and attack clips stay in art/ but the game uses the still,
# auto-rigged like everyone else's, so the whole cast moves the same way. A transparent `<character>-sheet-idle.webp`
# is not a clip: it comes after the hold, and a hero who has one plays it whether or not they are listed here.
HOLD_CLIPS = {"surya", "brann", "sorrel", "varuni"}


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


def sheet_body(d, char):
    """The battle sprite and idle sheet from a transparent `<character>-sheet-idle.webp`, or None. Rebuilt when it's newer."""
    import json
    src, grid = d / f"{char}-sheet-idle.webp", d / f"{char}-sheet-idle.json"
    if not (src.exists() and grid.exists()):
        return None
    sprites = GAME / "art" / "sprites"
    sprite, sheet, meta = sprites / f"{char}.webp", sprites / f"{char}-idle.webp", sprites / f"{char}-idle.json"
    if stale(src, meta) or stale(grid, meta) or "drift" not in json.loads(meta.read_text()):
        args = [str(src), str(grid), str(sprite), str(sheet)] + (["mirror"] if char in MIRROR else [])
        out = subprocess.run([sys.executable, str(ROOT / "tools" / "sheet-idle.py"), *args], check=True,
            capture_output=True, text=True).stdout
        meta.write_text(out.strip().splitlines()[-1])
    m = json.loads(meta.read_text())
    b = {"src": f"res://art/sprites/{char}.webp", "foot_x": m["foot_x"],
        "anim": dict(m["idle"], src=f"res://art/sprites/{char}-idle.webp")}
    # Their moves: `<character>-body-attack.mp4` and `-body-skill.mp4`, whole moves made facing left (Gamelabs clips),
    # each played through and matched to the height they stand in the idle.
    for kind in ("attack", "skill"):
        clip, out, made = d / f"{char}-body-{kind}.mp4", sprites / f"{char}-{kind}.webp", sprites / f"{char}-{kind}.json"
        if not clip.exists():
            continue
        if stale(clip, made) or stale(src, made):
            res = subprocess.run([sys.executable, str(ROOT / "tools" / "body-clip.py"), "swing", str(sheet), str(meta),
                str(clip), str(out), kind], check=True, capture_output=True, text=True).stdout
            made.write_text(res.strip().splitlines()[-1])
        b[kind] = dict(json.loads(made.read_text()), src=f"res://art/sprites/{char}-{kind}.webp")
    return b


def body(d, char):
    """The battle sprite, idle sheet and attack sheet from the body uploads, or None. Rebuilt when an upload is newer.
    The idle loop is the clip named idle, else movement, else any clip that isn't an attack. With no loop, the still
    alone is the sprite, rigged so the game can bring it to life. A transparent idle sheet (with its .json) beats them
    all: it makes both the sprite and the frames (tools/sheet-idle.py), so it carries no attack of its own."""
    import json
    made = sheet_body(d, char)
    if made:
        return made
    stills = sorted(d.glob(f"{char}-body-*.png"), key=lambda p: ("idle" not in p.stem, p.name))
    loops = sorted((p for p in d.glob(f"{char}-body-*.mp4") if "attack" not in p.stem and "skill" not in p.stem),
        key=lambda p: ("idle" not in p.stem, "movement" not in p.stem, p.name))
    hits = sorted(d.glob(f"{char}-body-attack*.mp4"))
    if char in HOLD_CLIPS:
        loops, hits = [], []
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
        m = json.loads(out.strip().splitlines()[-1])
        if char in MIRROR:
            from PIL import Image
            Image.open(sprite).transpose(Image.FLIP_LEFT_RIGHT).save(sprite, "WEBP", quality=88, method=6)
            m["foot_x"] = round(1 - m["foot_x"], 4)
        meta.write_text(json.dumps(m))
    m = json.loads(meta.read_text())
    b = {"src": f"res://art/sprites/{char}.webp", "foot_x": m["foot_x"]}
    if "idle" in m:
        b["anim"] = dict(m["idle"], src=f"res://art/sprites/{char}-idle.webp")
    if "attack" in m:
        b["attack"] = dict(m["attack"], src=f"res://art/sprites/{char}-attack.webp")
    if "idle" not in m:
        # A still with no loop is rigged so the game can move it (tools/auto-rig.py).
        if stale(sprite, sprites / f"{char}-rig.json"):
            out = subprocess.run([sys.executable, str(ROOT / "tools" / "auto-rig.py"), str(sprite)], check=True,
                capture_output=True, text=True).stdout
            (sprites / f"{char}-rig.json").write_text(out.strip())
        b["rig"] = json.loads((sprites / f"{char}-rig.json").read_text())
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


def sheets_stamp():
    """A short fingerprint of everything the web build ships in sheets/."""
    import hashlib
    h = hashlib.sha1()
    sprites = GAME / "art" / "sprites"
    painted = (GAME / "art" / "backgrounds").glob("*.webp")
    grounds = list((GAME / "art" / "grounds").glob("*.webp")) + list((GAME / "art" / "foregrounds").glob("*.webp"))
    moves = list(sprites.glob("*-attack.webp")) + list(sprites.glob("*-skill.webp"))
    for p in sorted(list(sprites.glob("*-idle.webp")) + moves + list(painted) + list(grounds)):
        h.update(p.name.encode() + p.read_bytes())
    return h.hexdigest()[:12]


def build():
    import json
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
    lines += ["}", "", "## Changes with the idle and attack sheets, so a player's kept copies are replaced (Clips.refresh_sheets).",
        f'const SHEETS_STAMP := "{sheets_stamp()}"']
    lines += ["", "## The lights in each painted background, found by tools/glow-spots.py: [x, y, radius, colour], as shares of its width.",
        "const GLOWS := {"]
    for p in sorted((GAME / "art" / "backgrounds").glob("*.webp")):
        spots = json.loads(subprocess.run([sys.executable, str(ROOT / "tools" / "glow-spots.py"), str(p)], check=True,
            capture_output=True, text=True).stdout)
        lines.append(f'\t"{p.stem}": {spots},'.replace("'", '"'))
    lines += ["}"]
    lines += ["", "## Keyed card art, by game key: the phone build's cards show it over the element's glow, centred on the",
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
    if isinstance(v, list):
        return "[" + ", ".join(gdv(x) for x in v) + "]"
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
