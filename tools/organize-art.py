"""Sort uploaded art into one folder per character, then build their faces for the game.

Upload anywhere under art/ (the root is fine) and run:

    python3 tools/organize-art.py

1. Sort: every file goes to art/<character>/<character>-<rest>, lower case, spaces as dashes. The character comes from
   the file's prefix (`fox-face-idle1.mp4`) or, failing that, its folder; old names map to the cast's names (fox and
   kaede → surya, ilse and mermaid → varuni, leaf → galeblade, rock → basalt). A name the cast doesn't know yet gets a
   folder of its own. Moves go through git, so nothing is lost. art/_trash and the README stay put.
2. Faces: `<character>-face-<kind><n>.mp4` clips (idle, talk, spell, or anything else) are keyed into
   game/art/clips/<character>-<kind><n>.ogv and `<character>-face-blank.png` into game/art/faces/<character>.webp
   (tools/face-clip.py); other `-face-<mood>.png` stills become expressions. Only what changed is rebuilt.
3. Writes game/core/faces.gd, the table the game reads (see Faces).
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
    "rock": "basalt", "caller": "tidecaller"}
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
        if not p.is_file() or p.name in KEEP or "_trash" in p.parts or p.name.startswith("."):
            continue
        rel = p.relative_to(ART)
        folder = rel.parts[0] if len(rel.parts) > 1 else ""
        stem, ext = os.path.splitext(tidy(p.name))
        head, _, rest = stem.partition("-")
        if folder == "sprites":
            char = ALIASES.get(head, head)
            rest = "sprite" + ("-" + rest if rest else "")
        elif ALIASES.get(head, head) in KEYS or ALIASES.get(head, head) == ALIASES.get(folder, folder) or not folder:
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


def build():
    faces = {}
    tool = ROOT / "tools" / "face-clip.py"
    for d in sorted(p for p in ART.iterdir() if p.is_dir() and p.name != "_trash"):
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
    lines += ["}", "", "", "## The face of a hero (by game key), or {} if they have none yet.",
        "static func of(key: String) -> Dictionary:", "\treturn FACES.get(key, {})", "", "",
        "## The clip a hero's skill plays as its cut-in (by slot: s0, s1), or \"\".",
        "static func skill_clip(key: String, slot: String) -> String:",
        "\tvar skills: Array = of(key).get(\"skills\", [])", "\tvar i := slot.substr(1).to_int()",
        "\treturn skills[i] if slot.begins_with(\"s\") and i < skills.size() else \"\"", ""]
    (GAME / "core" / "faces.gd").write_text("\n".join(lines))
    print(f"faces: {', '.join(faces)}")


def gd(v):
    if isinstance(v, dict):
        return "{" + ", ".join(f'"{k}": {gd(x)}' for k, x in v.items()) + "}"
    if isinstance(v, list):
        return "[" + ", ".join(gd(x) for x in v) + "]"
    return f'"{v}"'


if __name__ == "__main__":
    print(f"sorted {sort()} files")
    build()
