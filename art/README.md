# Art

Upload new art into this folder (GitHub's "Add file → Upload files" works, including from a phone). Claude converts it, sets the face focus point and wires it into the sandbox.

## Portrait specs

- **Aspect:** 9:16, ideally 1152×2048. One tall image serves every card shape (tall cards show it whole; square tiles crop it).
- **Framing:** face in the upper third, centered; leave room at the bottom for the name plate.
- **Format:** PNG or WebP, no text or frames baked in. The game draws frames, element glyphs and augment auras itself.
- **Naming:** the hero's key, lowercase: `kaede.png`, `brann.png`, `sorrel.png`, `ilse.png`; enemies `golem`, `blade`, `caller`, `seer`.

## Living cards

A 3★ card breathes and a 4★ card comes alive and breaks out of its frame. Each needs a short portrait loop: an MP4 of the head and shoulders on a flat background, about 5 seconds. `tools/living-card.sh loop.mp4 <hero> art/<hero>` turns it into a transparent animated cutout, a breathing loop and a still cutout. Ilse's are in `art/ilse/`.

## Element palette

Fire `#ff7b47` · Water `#43b8de` · Earth `#c4925f` · Wind `#8ad46f`. Character art should lean toward its element; Brann is now Earth and the Basalt Golem is the Earth enemy.

## Battle sprites

Full-body figures on a flat background, any size. `python3 tools/sprite-cutout.py in.webp art/sprites/<name>.webp` cuts the figure out, drops watermarks and trims to the figure, feet at the bottom edge. `art/sprites/` holds the cast; `varuni-idle.webp` is her dance loop as a sheet of 61 frames (10 across, 435×560 each, 12 fps). Size, placement and idles are set in the Battle Sprites viewer (https://claude.ai/artifact/BuXzmq7z7Hm4ZgpFvQ2Stj).
