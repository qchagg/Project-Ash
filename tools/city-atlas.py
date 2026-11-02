"""Builds the City Atlas: every hero's home, city and ruin, with what is painted, playable and missing.

    python3 tools/city-atlas.py <out.html>

Rebuild and republish it (https://claude.ai/artifact/NyPDCgSz2TGwhSjF9ar2kA) whenever a background, road or home changes.
The rows below are written by hand; the counts and what is playable are read from the game, so they cannot go stale.
"""
import base64, datetime, html, io, re, sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
G = str(ROOT / "game" / "art" / "backgrounds") + "/"
exp = (ROOT / "game" / "core" / "expedition.gd").read_text(encoding="utf8")
ROADS = re.findall(r'^\t"\w+": \{"name": "([^"]+)", "region"', exp, re.M)
ART = sorted(p.stem for p in Path(G).glob("*.webp"))
REGIONS = re.findall(r'^\t"\w+": \{"name": "[^"]+", "dark"', (ROOT / "game" / "core" / "data.gd").read_text(encoding="utf8"), re.M)
STYLE = 'painted fantasy background, soft atmospheric depth, muted colours, crisp ink linework --ar 2:1'

def thumb(n):
    i = Image.open(G + n + '.webp').convert('RGB').resize((400, 200), Image.LANCZOS)
    b = io.BytesIO(); i.save(b, 'WEBP', quality=68)
    return 'data:image/webp;base64,' + base64.b64encode(b.getvalue()).decode()

# hero, element, game home, what the home says, city art, ruin name, ruin art or None, why they pair, prompt
GROUPS = [
 ('Desert and delta', [
  ('Surya', 'fire', 'Marusthal', 'Salt-white dunes and red palace cities', ['city'], 'The Saltglass Road', ['saltglass-1', 'saltglass-2'],
   'The palace city stands. The road out of it is the glass scar of the fire that burned his oasis.', None),
  ('Varuni', 'water', 'Jaladesh', 'A delta under the domes of the Lotus Palace', ['lotus-1'], 'The Aqueduct', ['lotus-2'],
   'The domed Lotus Palace is the city of Jaladesh. Below it the flooded arches of the old aqueduct are the road, and both show on her page.', None),
 ]),
 ('Volcanic highlands', [
  ('Basalt', 'earth', 'Hraunvald', 'Lava fields and a volcano city lit by hot springs', ['basalt-city'], 'The Basalt Steps', ['basalt-steps'],
   'The living city glows with hot springs inside the volcano. The black stairs outside are the old road its masons cut.', None),
  ('Seer', 'fire', 'Mehfil', 'A travelling village of lanterns and silk', ['lantern-village'], 'The Empty Pavilions', ['empty-pavilions-1', 'empty-pavilions-2'],
   'The lantern village travels. This is the camp it left behind: silk still hanging, lanterns burned out, something living in the tents.',
   'an abandoned camp of a travelling lantern village at dusk, vast silk pavilions torn and rippling among giant mushroom-canopy trees, thousands of burned-out red lanterns, spilled cushions and overgrown stages, a few embers still glowing, wild flowers through the silk, long violet shadows, soft pink haze, dark roots and fallen silk in the centre foreground, strange and beautiful, ' + STYLE),
  ('Smoke', 'fire', 'Velata', 'A veiled baroque city of black domes and silk', ['silk-highlands', 'silk-street'], 'The Veiled Undercroft', ['undercroft'],
   'Above is the silk city of secrets. Below is the old city it was built on, where the real business happens.',
   'a vast baroque undercroft beneath a secretive city, black stone vaults and domed cisterns lit by ember vents, walls hung with dark silk curtains, hidden market stalls and locked iron doors, narrow bridges over glowing lava channels, long crimson shadows, soft smoke haze, stacked silk bales and carved pillars in the centre foreground, secret and bustling, ' + STYLE),
 ]),
 ('Forest and plains', [
  ('Sorrel', 'wind', 'Gwyntmoor', 'Golden grasslands rising to windy moors', ['plains-1', 'plains-2'], 'The Standing Stones', ['standing-stones'],
   'The plains run up into the old moor, where the herds still will not graze inside the ring.',
   'a colossal ring of ancient standing stones on a high windswept moor at late afternoon, carved monoliths wrapped in vines, herds grazing beyond the ring, broken ceremonial stairways, kites of cloth tied to the stones by travellers, racing cloud shadows, soft haze, tall grass and heather in the centre foreground, wild and alive, ' + STYLE),
  ('Galeblade', 'wind', 'Vetrolés', 'A forest whose paths rearrange overnight', ['plains-2', 'plains-1'], 'The Walking Wood', ['walking-wood'],
   'The same forest edge, further in: an old forest city the trees have taken back and keep moving.',
   'an ancient forest city swallowed by colossal walking trees, moss-covered towers lifted into the branches, rope bridges and wooden shrines, paths winding between giant roots, drifting seed pods and green light, long emerald shadows, soft haze, ferns and carved stone in the centre foreground, alive and watchful, ' + STYLE),
 ]),
 ('Imperial capital', [
  ('Aurelia', 'earth', 'New home, no hero yet', 'A marble capital above a broad river', ['imperial', 'avenue'], 'The Fallen Triumph', None,
   'The capital marches out along its grandest road. Out on the steppe, that road ends at a gate the empire no longer talks about.',
   'a shattered triumphal gate and ruined imperial highway on an endless grass steppe at sunrise, toppled marble statues of horsemen half sunk in the grass, tattered purple banners, wild horse herds running between broken arches, distant white citadel on the horizon, long blue shadows, soft haze, cracked paving and tall grass in the centre foreground, grand and proud, ' + STYLE),
 ]),
 ('Jade mountains', [
  ('Snake', 'wind', 'Yuling', 'Jade peaks and cliff monasteries', ['jade'], 'The Serpent Archive', ['serpent-archive'],
   'He is the Archive Serpent, so his ruin is the library under the monastery, cut into the cliff and winding down to the river.',
   'an immense cliffside archive beneath a jade mountain monastery at dawn, spiralling galleries of scroll shelves carved into pale stone, a great river winding far below, serpent carvings along the stairs, paper lanterns and hanging bamboo, long teal shadows, soft mist, moss-covered stone and fallen scrolls in the centre foreground, quiet and wise, ' + STYLE),
 ]),
 ('Ice coast', [
  ('Tidecaller', 'water', 'Sikuvik, new home', 'A frozen coral coast of ice cathedrals', ['ice'], 'The Whale Cathedral', ['whale-cathedral'],
   'The living ice city faces a holy ruin out on the frozen sea, built inside the bones of something enormous.',
   'an immense whale skeleton frozen into a glassy sea at blue hour, a sacred cathedral built within its ribs, pale ice arches and glowing sea lanterns, pilgrim boats moored along the bones, shafts of moonlight through drifting snow, long indigo shadows, soft haze, frosted coral and dark kelp in the centre foreground, serene and holy, ' + STYLE),
 ]),
 ('Steppe and warm coast', [
  ('Brann', 'earth', 'Khorvan Steppe', 'An ocean of grass and horse herds', ['steppe'], 'The Ashgate', None,
   'His story turns on this pass. Three thousand riders held it and one came back, and the steppe grass stops at its gates.',
   'a colossal ruined mountain pass fortress at the edge of an endless grass steppe at dusk, broken gate towers and a shattered wall across the pass, thousands of rusted spears standing in the grass, tattered war banners, wild horses grazing among fallen stones, fires of distant watchmen, long ember shadows, soft haze, tall grass and old shields in the centre foreground, solemn and enduring, ' + STYLE),
  ('Mwambao', 'wind', 'No hero yet', 'A warm coral coast of dhow harbours', ['coast'], 'The Monsoon Wrecks', None,
   'The port trades on what the monsoon allows. Around the headland lies everything the monsoon kept.',
   'a vast graveyard of great wooden dhows wrecked on a coral reef at golden hour, tilted hulls and torn lateen sails, salvagers on rope bridges between the masts, a coral-stone lighthouse, turquoise shallows full of life, long warm shadows, soft sea haze, carved doors and coral in the centre foreground, warm and bustling, ' + STYLE),
 ]),
]
ROWS = []
for gname, rows in GROUPS:
    ROWS.append(f'<h2>{gname}</h2>')
    for hero, elem, home, says, cities, ruin, ruin_art, why, prompt in rows:
        city = ''.join(f'<img src="{thumb(c)}" alt="{c} background">' for c in cities) or '<div class="blank">No city painted yet</div>'
        if ruin_art:
            art = ''.join(f'<img src="{thumb(r)}" alt="{r} background">' for r in ruin_art)
            state = '<span class="tag live">Playable road</span>' if ruin in ROADS else '<span class="tag idea">Painted, no road yet</span>'
            ask = ''
        else:
            art = '<div class="blank">To paint</div>'
            state = '<span class="tag idea">Proposed</span>' if prompt else ''
            ask = f'<details><summary>Midjourney prompt</summary><p class="prompt">{html.escape(prompt)}</p><button type="button" class="copy">Copy prompt</button></details>' if prompt else ''
        ROWS.append(f'''<article class="row">
<div class="who"><span class="el {elem}">{elem}</span><h3>{hero}</h3><p>{home}</p><p class="say">{says}</p></div>
<div class="stop"><div class="label">City</div><div class="pics">{city}</div></div>
<div class="arrow" aria-hidden="true"></div>
<div class="stop"><div class="label">Ruin {state}</div><div class="pics">{art}</div><h4>{ruin}</h4><p>{why}</p>{ask}</div>
</article>''')
CITY = [
]
CITYROWS = [f'<article class="city"><h3>{html.escape(n)}</h3><p class="prompt">{html.escape(q)}</p><button type="button" class="copy">Copy prompt</button></article>' for n, q in CITY]
proposed = sum(1 for g in GROUPS for r in g[1] if r[6] is None)
ruins = sum(1 for g in GROUPS for r in g[1])
grounds = len(re.findall(r'^\t"\w+": \{"art": "\w+", "shade"', (ROOT / "game" / "ui" / "backdrop.gd").read_text(encoding="utf8"), re.M))
stats = f'<div class="stats"><p><b>{len(ART)}</b> paintings</p><p><b>{len(ROADS)}</b> playable roads</p><p><b>{grounds}</b> of {len(ROADS)} roads with a battle ground</p><p><b>{len(REGIONS)}</b> homes</p><p><b>{proposed}</b> of {ruins} ruins still to paint</p></div><p class="stamp">Updated {datetime.datetime.now().strftime("%d %b %Y, %H:%M")}</p>'
page = (ROOT / 'tools' / 'city-atlas.html').read_text(encoding='utf8').replace('<!--STATS-->', stats).replace('<!--ROWS-->', '\n'.join(ROWS)).replace('<!--CITY-->', '\n'.join(CITYROWS))
Path(sys.argv[1]).write_text(page, encoding='utf8')
print(len(page) // 1024, 'kb')
