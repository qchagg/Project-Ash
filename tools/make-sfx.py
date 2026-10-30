"""Synthesise the game's placeholder sounds into game/audio/sfx/<cue>.ogg (and <cue>-2, -3 for variations).

    python3 tools/make-sfx.py

Placeholders until real packs arrive: drop a pack's file at game/audio/sfx/<cue>.ogg (or <cue>-2.ogg…) and it
replaces the synthetic one; this script only writes cues that have no file yet (pass --force to rewrite them all).
Each sound is short, mono, 32 kHz Vorbis, so the whole set stays well under 200 KB in the pack.
"""
import subprocess
import sys
import tempfile
import wave
from pathlib import Path

import numpy as np
from scipy.signal import lfilter

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "game" / "audio" / "sfx"
SR = 32000
rng = np.random.default_rng(7)


def t(sec):
    return np.arange(int(sec * SR)) / SR


def env(n, attack=0.004, decay=0.2, curve=4.0):
    """A plucked envelope: a quick rise, then an exponential fall that reaches silence at the end."""
    x = np.arange(n) / SR
    a = np.clip(x / attack, 0, 1)
    d = np.exp(-x / decay) * (1 - x / x[-1]) ** (curve / 4)
    return a * d


def noise(sec):
    return rng.uniform(-1, 1, int(sec * SR))


def lowpass(x, cut):
    """One-pole low-pass, run twice for a gentler 12 dB slope."""
    k = np.exp(-2 * np.pi * cut / SR)
    for _ in range(2):
        x = lfilter([1 - k], [1, -k], x)
    return x


def highpass(x, cut):
    return x - lowpass(x, cut)


def sweep(f0, f1, sec, shape="exp"):
    """A sine gliding from f0 to f1."""
    x = t(sec)
    f = f0 * (f1 / f0) ** (x / sec) if shape == "exp" else f0 + (f1 - f0) * x / sec
    return np.sin(2 * np.pi * np.cumsum(f) / SR)


def bell(freq, sec, decay=0.5, partials=((1, 1), (2.76, 0.4), (5.4, 0.18), (8.9, 0.06))):
    x = t(sec)
    out = sum(a * np.sin(2 * np.pi * freq * p * x) * np.exp(-x / (decay / p ** 0.6)) for p, a in partials)
    return out * np.clip(x / 0.003, 0, 1)


def pad(x, sec):
    n = int(sec * SR)
    return np.pad(x, (0, max(0, n - len(x))))[:n] if len(x) < n else x


def mix(*parts):
    n = max(len(p) for p in parts)
    return sum(np.pad(p, (0, n - len(p))) for p in parts)


def at(x, sec):
    return np.pad(x, (int(sec * SR), 0))


# ---------- the cues ----------

def tap():
    """A soft wooden tick: a short, high, damped knock."""
    x = bell(1900, 0.08, 0.018, ((1, 1), (2.3, 0.3))) + lowpass(noise(0.08), 3000) * env(int(0.08 * SR), 0.001, 0.006) * 0.5
    return x * 0.55


def confirm():
    """The commit: two bright notes, a fifth apart, the second ringing."""
    return mix(bell(880, 0.5, 0.12) * 0.5, at(bell(1320, 0.7, 0.25) * 0.55, 0.07)) * 0.8


def page():
    """Moving between places: a short airy whisk."""
    n = noise(0.18)
    return highpass(lowpass(n, 5000), 900) * env(len(n), 0.04, 0.06) * 0.6


def hit():
    """A blow landing: a body thump that drops in pitch under a short crack."""
    body = sweep(150, 55, 0.22) * env(int(0.22 * SR), 0.002, 0.07)
    crack = highpass(noise(0.06), 1800) * env(int(0.06 * SR), 0.001, 0.012)
    return np.tanh(mix(body * 1.2, crack * 0.7) * 1.6) * 0.75


def crit():
    """A heavy hit: a deeper thump, a longer crack and a ringing edge."""
    body = sweep(120, 38, 0.4) * env(int(0.4 * SR), 0.002, 0.13)
    crack = highpass(noise(0.12), 1400) * env(int(0.12 * SR), 0.001, 0.03)
    ring = bell(620, 0.5, 0.18, ((1, 1), (2.4, 0.5), (4.1, 0.25))) * 0.25
    return np.tanh(mix(body * 1.4, crack * 0.9, ring) * 1.8) * 0.8


def swing():
    """The air a blade moves: noise swept up through a band, rising and falling."""
    n = noise(0.24)
    x = np.arange(len(n)) / SR
    shaped = np.concatenate([highpass(lowpass(n[i:i + 640], 700 + 5000 * (i / len(n))), 400) for i in range(0, len(n), 640)])
    return shaped[:len(x)] * np.sin(np.pi * x / x[-1]) ** 2 * 0.9


def cast():
    """A spell gathering: a shimmer of detuned sines rising."""
    x = t(0.6)
    s = sum(np.sin(2 * np.pi * np.cumsum(f * (1 + 0.9 * x / 0.6) * (1 + 0.004 * np.sin(2 * np.pi * 6 * x))) / SR)
        for f in (520, 523, 780, 1040))
    return s * np.sin(np.pi * x / 0.6) ** 1.5 * 0.18


def mend():
    """Healing: a soft rising major arpeggio of bells."""
    return mix(*[at(bell(f, 0.8, 0.35) * 0.32, i * 0.07) for i, f in enumerate((660, 830, 990, 1320))])


def shield():
    """A ward going up: a bright metallic ping with a short glide."""
    return mix(bell(1250, 0.7, 0.3, ((1, 1), (1.5, 0.5), (2.9, 0.3), (4.7, 0.15))) * 0.5, sweep(400, 900, 0.12) * env(int(0.12 * SR), 0.002, 0.05) * 0.2)


def burn():
    """A flare catching: a puff of low noise with crackles in it."""
    n = lowpass(noise(0.45), 1800) * env(int(0.45 * SR), 0.03, 0.15)
    crackle = np.zeros_like(n)
    for p in rng.integers(0, len(n) - 400, 14):
        crackle[p:p + 200] += highpass(noise(200 / SR), 2500) * np.exp(-np.arange(200) / 30)
    return (n * 0.8 + crackle * 0.5) * 0.7


def stun():
    """Dazed: a wobbling, falling chirp."""
    x = t(0.45)
    f = 1400 * (0.5 ** (x / 0.45)) * (1 + 0.08 * np.sin(2 * np.pi * 18 * x))
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * env(len(x), 0.005, 0.18) * 0.35


def ko():
    """A fall: a low boom with a long tail and a breath of dust."""
    boom = sweep(90, 30, 0.9) * env(int(0.9 * SR), 0.004, 0.3)
    dust = lowpass(noise(0.7), 900) * env(int(0.7 * SR), 0.05, 0.25) * 0.4
    return np.tanh(mix(boom * 1.5, dust) * 1.4) * 0.8


def step():
    """A footfall on stone."""
    return lowpass(noise(0.07), 700) * env(int(0.07 * SR), 0.002, 0.015) * 0.7


def banner():
    """A turn called: a struck gong, low and wide."""
    g = bell(196, 1.4, 0.7, ((1, 1), (1.47, 0.6), (2.09, 0.45), (2.76, 0.3), (3.9, 0.15)))
    thud = sweep(110, 60, 0.15) * env(int(0.15 * SR), 0.002, 0.05)
    return mix(g * 0.42, thud * 0.5)


def cutin():
    """A skill's cut-in: a rush of air rising into a strike."""
    n = noise(0.35)
    x = np.arange(len(n)) / SR
    rush = highpass(n, 1200) * (x / x[-1]) ** 2 * 0.6
    return mix(rush, at(crit() * 0.9, 0.3))


def victory():
    """A win: a short rising fanfare of bells landing on a held chord."""
    notes = [(523, 0.0), (659, 0.12), (784, 0.24)]
    chord = mix(*[bell(f, 1.6, 0.7) * 0.22 for f in (523, 659, 784, 1046)])
    return mix(*[at(bell(f, 0.5, 0.2) * 0.4, s) for f, s in notes], at(chord, 0.38))


def defeat():
    """A loss: three falling notes, low and slow."""
    return mix(*[at(bell(f, 1.2, 0.5, ((1, 1), (2.0, 0.3))) * 0.35, i * 0.28) for i, f in enumerate((392, 311, 262))])


def summon():
    """A card revealed: a rising sweep breaking into a ringing chord."""
    x = t(0.5)
    rise = sweep(200, 1600, 0.5) * (x / 0.5) ** 2 * 0.25
    return mix(rise, at(mix(*[bell(f, 1.4, 0.6) * 0.2 for f in (784, 988, 1175, 1568)]), 0.48))


CUES = {"tap": [tap], "confirm": [confirm], "page": [page], "hit": [hit, hit, hit], "crit": [crit], "swing": [swing, swing],
    "cast": [cast], "mend": [mend], "shield": [shield], "burn": [burn], "stun": [stun], "ko": [ko], "step": [step, step],
    "banner": [banner], "cutin": [cutin], "victory": [victory], "defeat": [defeat], "summon": [summon]}


def write(x, dst):
    x = x / max(1e-6, np.abs(x).max()) * 0.89 * min(1.0, np.abs(x).max() / 0.6 + 0.4)
    fade = min(len(x), int(0.004 * SR))
    x[-fade:] *= np.linspace(1, 0, fade)
    with tempfile.NamedTemporaryFile(suffix=".wav") as tmp:
        with wave.open(tmp.name, "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes((np.clip(x, -1, 1) * 32767).astype(np.int16).tobytes())
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", tmp.name, "-c:a", "libvorbis", "-q:a", "3", str(dst)], check=True)


def main(force=False):
    OUT.mkdir(parents=True, exist_ok=True)
    for cue, makers in CUES.items():
        for i, make in enumerate(makers):
            dst = OUT / (f"{cue}.ogg" if i == 0 else f"{cue}-{i + 1}.ogg")
            if dst.exists() and not force:
                continue
            write(make(), dst)
    size = sum(p.stat().st_size for p in OUT.glob("*.ogg"))
    print(f"{len(list(OUT.glob('*.ogg')))} sounds, {size / 1e3:.0f} KB")


if __name__ == "__main__":
    main("--force" in sys.argv)
