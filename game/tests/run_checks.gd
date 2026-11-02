extends SceneTree
## Acceptance checks, ported from the sandbox's CHECKS. Run with tools/godot-checks.sh.
## Each check returns [pass, detail]; the process exits 1 if any fail.


func _init() -> void:
	var checks := [
		["Stars · every hero is one card at 1★, with their own stats", _one_card_each],
		["Stars · each copy lights a star up to 4★, and each star adds 10% and an augment slot", _copies_add_stars],
		["Stars · a copy past 4★ pays embers and changes nothing else", _spare_copies],
		["Augments · a hero holds one per star, and they swap freely", _aug_slots],
		["Augments · Keen and Wellspring add up; Lingering does not and stun caps at 2; Hasten stops at cooldown 1; Kindling adds Burn", _aug_math],
		["Elements · four-way cycle: each element beats one, loses to one, and is neutral with its opposite", _four_way],
		["Visuals · augments name the skill and pick the aura: most augments wins, ties go to the first slotted", _aura_names],
		["Celerity · fits damage, heal and shield skills, renames with Fleet, and marks the skill as an opener", _celerity_fits],
		["Squad · formation: placing moves a card, a taken tile swaps, off-grid and benched cards are refused, a joining card never stacks", _formation],
		["Regions · every hero's home is a region with a dark and a light colorway and its own sigil", _regions],
		["Lore · forty archetypes, every region has two or more, every element at least seven, each linked hero exists", _archetypes],
		["Town · every level costs more than the last, in tens; the Hearth raises the battle reward", _town_costs],
		["Town · nothing rises without the embers or above the Hearth, and a blocked upgrade changes nothing", _town_blocked],
		["Town · buildings stop at their top level; routes open two then one a level; envoys sit in region order", _town_caps],
		["Cards · every portrait crops to Brann's eye line: eyes at the same height, the face the same size", _eye_line],
		["Engine · ignoresFalloff: same damage to the back row as the front", _b_falloff],
		["Engine · stacks: two still, unhit rounds give +50%, then reset", _b_stacks],
		["Engine · stacks: one hit clears them", _b_stacks_hit],
		["Engine · team buff: melee reaches the back row; without it, the front-most", _b_team_buff],
		["Engine · a team-buff skill counts as a chain link", _b_buff_chain],
		["Engine · chain-neutral move: far tile, chain and stacks kept, mark boosts next basic", _b_leap],
		["Engine · tile effect onAct: damage and Burn when the unit acts, then gone", _b_trap_act],
		["Engine · tile effect onEnter: triggers when a unit steps on", _b_trap_enter],
		["Engine · an untriggered tile effect expires after 3 rounds", _b_trap_expire],
		["Formation · place on an empty tile, swap onto a hero, and the layout carries into the next battle", _b_formation],
		["Formation · enemies start spread over the 4×4 grid, every tile in bounds and unique", _b_foe_spread],
		["Baseline · on 3×3 with the v0.1 element triangle and every rule off, the fixed fight matches v0.1", _b_baseline],
		["Shapes · scaled on 4×4 (2 lanes, 2 rows, cross reach 2), identical to v0.1 on 3×3", _b_shapes],
		["Reference · on 4×4 with the v0.1 element triangle, unscaled shapes and every rule off, the fixed fight matches the recorded snapshot", _b_reference],
		["Rule · Sightline: a back-row shooter loses its own depth; ignoresFalloff is untouched", _b_sightline],
		["Rule · Screening: each unit already hit in the lane cuts the next by 25%", _b_screening],
		["Rule · Kindred: a same-element hit deals ×0.85", _b_kindred],
		["Rule · Focus: a link on the same target as the previous link gets +5%", _b_focus],
		["Rule · Shatter: a big enough overshoot shatters; a bare kill does not", _b_shatter],
		["Rule · Last Stand: downed for 2 rounds, a heal revives at 25%, too late means gone", _b_last_stand],
		["Rule · Ashfall: nothing before round 8, then every unit burns once a round", _b_ashfall],
		["Rule · Reach: single-target melee hits only across its own lane from the front row; a melee foe steps up to strike", _b_reach],
		["Augments · in battle, Keen adds 15% to a real hit", _b_keen],
		["Elements · Brann is Earth: his Rockfall hits Water ×1.5, and the v0.1 triangle restores him to Water", _b_brann_earth],
		["Celerity · fires before round 1, not as a chain link; then locked at 1★, double cooldown at 2★, normal at 3★, ready at 4★", _b_celerity],
		["Celerity · an opener stun lasts 1 round even with Lingering; the same skill in the queue keeps its 2", _b_celerity_stun],
		["Rule · Ground: a ranged cross aimed at an empty tile hits above and below it; the AI still aims at units", _b_ground],
		["Rule · Ground: single-target and melee skills still need a unit; an area stays put when its unit falls first", _b_ground_limits],
		["Playback · a round marks the ally and enemy turns, and Varuni's Rain of Renewal cues her cut-in", _b_turn_marks],
		["Faces · every clip, still and body sheet a hero names is in the project", _faces_exist],
		["Facing · heroes face right and foes face left, whichever way their art was drawn", _facing],
		["Facing · every sprite is stored facing the same way; only an attack swing keeps its own direction", _facing_default],
		["Sound · every cue the game plays has a sound file, and a cue with none is silent rather than an error", _sounds],
		["Sound · the button click and page turn stay silent", _muted_cues],
		["Roads · every road shows a painting the game carries", _road_art],
		["Skills · every skill has its own icon", _skill_icons],
		["Stands · a hero's standing art has its file, travels with the sheets, and their profile crop stays on the art", _hero_stands],
		["Travel Log · a milestone locks until enough wardens fall and pays once", _travel_log],
		["Voices · every voice has an actor, every clip has its file, and the web build fetches them", _voices],
		["Choices · every boon\'s stat has a picture on its card", _boon_glyphs],
		["Air · what tumbles rides gusts that stay in bounds, and only paintings that exist have moving light", _air_light],
		["Title · it draws from every background the game carries, each with its file", _title_art],
		["Roads · next and back walk every road and wrap, and the screens' paintings travel with the rest", _road_steps],
		["Title · the art drifts both ways but never shows an edge, on a phone or a wide screen, and every background has its air", _title_pan],
		["Music · every road names a map track, slots are the map or a stop, and the files on disk are exactly the tracks in use", _road_music],
		["Music · a slot plays the road's track, then the shared default, then the road's map; off the road plays the default map", _music_fallback],
		["Music · the player keeps wanting a track while sound is off, plays nothing, loops what it loads, and a missing file is silent", _music_player],
		["Health bars · a hit drops the bar at once and leaves a pale chunk that drains; a heal fills it", _hp_lag],
		["Rig · every still with no idle loop is rigged; its feet stay planted while its loose parts sway", _rig],
		["Backgrounds · every hero has a home with art on file, a home picks among its own, and one without any falls back to the glow", _backgrounds],
		["Grounds · each belongs to a road and is on file, every file is used, they tile, travel in sheets/ and stay out of the pack", _grounds],
		["Sheets · a device keeps its sheets only while the art is unchanged, then fetches them fresh", _sheets_refresh],
		["Sound · the web page suspends all audio while the game isn't in front", _sound_in_front],
		["Weather · every painted background has its air, its motes loop inside the screen, and an unknown one has none", _weather],
		["Title · a painting plays its road's music, or its home's road, and one with no road leaves the music alone", _art_music],
		["Status effects · each status shows on the body, and a fighter with none shows nothing", _status_fx],
		["Lights · every painted background has its lights on file, inside the picture", _glows],
		["Idle sheets · each holds every frame it names at about 560 tall and its own rate, the feet stay planted, and no key colour is left", _idle_sheets],
		["Plan · a hero steps then acts: Brann steps to the front row and Rockfall lands, though he planned it from the second row", _b_step_then_act],
		["Plan · queue order holds: Varuni's heal lands on Sorrel before he steps away; he then casts from his new tile", _b_step_order],
		["Plan · steps reach 2 tiles, never onto a unit or a tile another hero has claimed; stepping home cancels", _b_step_tiles],
		["Forecast · matches what the action then does, target by target, and changes nothing in the fight", _b_forecast],
		["Forecast · counts the chain the skill would carry at the back of the queue, and marks a knockout", _b_forecast_chain],
		["Intents · each foe's preview is the action and area it then uses when nothing changes first", _b_intents],
		["Crops · a crop set for one view wins there, and every other view keeps the eye-line rule", _b_crop_override],
		["Forecast · the face is the battle tile's close crop, in a tile's shape", _b_forecast_crop],
		["Home · every road can be featured between runs, with a painting and words; on the road it holds on yours", _h_slides],
		["Scene · the places stand on home's road, with no painting of their own, and each road has a theme to play there", _h_scene],
		["Wide board · the floor fits above the skills, the two grids stay apart, and it closes up toward the far lane", _b_wide_floor],
		["Expedition · every road is connected start to warden, with a camp before the warden", _x_map],
		["Expedition · fights send the road's home foe, more and tougher further down the road", _x_foes],
		["Expedition · health carries between fights, camps heal the standing, the fallen stay down", _x_health],
		["Expedition · boons stack by rarity and boost the squad; a loss banks half the embers", _x_boons],
		["Expedition · a fight can field only the named foes, scaled", _x_battle_subset],
		["Wayside · the stop has replaced Cache and Trial, and no event repeats on a run", _w_stops],
		["Wayside · every event is well formed, with its last choice free and safe", _w_events],
		["Wayside · every cost and risk is shown, and a price you can't meet is refused", _w_terms],
		["Wayside · an event never fells a hero; hero and fallen choices appear only when they should", _w_health],
		["Wayside · rewards follow the stop's rarity, a started fight pays by its kind, and debts come out of the bank", _w_rewards],
		["Hero picks · a won fight offers three different upgrades that fit, round the squad, past the fallen", _x_pick_offer],
		["Hero picks · nothing useless is offered: no second Celerity, no Hasten at cooldown 1, no Kindling on a burn", _x_pick_useful],
		["Hero picks · no offer after a loss or the warden; an elite steps the odds up", _x_pick_when],
		["Hero picks · a free reroll is earned and saved, then embers at a doubling price up to the cap", _x_pick_reroll],
		["Hero picks · a pick changes the skill in a fight; a full hero must replace one; a skip pays embers", _x_pick_take],
	]
	var failed := 0
	for i in checks.size():
		var r: Array = checks[i][1].call()
		if not r[0]:
			failed += 1
		print("[check %d] %s %s: %s" % [i + 1, "PASS" if r[0] else "FAIL", checks[i][0], r[1]])
	print("%d/%d passed" % [checks.size() - failed, checks.size()])
	quit(1 if failed else 0)


func _one_card_each() -> Array:
	var col := Collection.new()
	var keys: Array = col.cards.map(func(c): return c.uid)
	var plain := col.cards.all(func(c):
		var h := Data.hero(c.hero)
		return c.stars == 1 and c.uid == c.hero and c.base.atk == h.atk and c.base.def == h.def and c.base.spd == h.spd)
	return [keys == Data.HEROES.map(func(h): return h.key) and plain, "%d heroes" % keys.size()]


func _copies_add_stars() -> Array:
	var col := Collection.new()
	var k := col.by("kaede")
	var base: Dictionary = k.base
	var seen := [k.stars]
	var paid := 0
	for i in 3:
		paid += col.add_copy("kaede")
		seen.append(k.stars)
	var got := col.stats(k)
	var ok: bool = seen == [1, 2, 3, 4] and paid == 0 and got.atk == roundi(base.atk * 1.3) and got.max_hp == roundi(base.max_hp * 1.3)
	var fitted := 0
	for aug in ["keen", "hasten", "lingering", "kindling", "keen"]:
		fitted += 1 if col.slot_aug("kaede", 0, aug) else 0
	return [ok and fitted == 4, "stars %s · attack %d → %d · %d augments fit" % [seen, base.atk, got.atk, fitted]]


func _spare_copies() -> Array:
	var col := Collection.new()
	var k := col.by("kaede")
	for i in 3:
		col.add_copy("kaede")
	var before := col.stats(k)
	var paid := col.add_copy("kaede")
	return [paid == Collection.SPARE_EMBERS and k.stars == 4 and col.stats(k) == before, "%d embers · still %d★" % [paid, k.stars]]


func _aug_slots() -> Array:
	var col := Collection.new()
	var slotted := col.slot_aug("kaede", 0, "keen")
	var full := col.slot_aug("kaede", 1, "hasten")
	var out := col.unslot_aug("kaede", 0)
	var back := col.slot_aug("kaede", 0, "keen")
	col.add_copy("kaede")
	var second := col.slot_aug("kaede", 1, "hasten")
	var out_again := col.unslot_aug("kaede", 0)
	return [slotted and not full and out and back and second and out_again, "2nd on a 1★ %s · 2nd on a 2★ %s" % [full, second]]


func _aug_math() -> Array:
	var brann: Dictionary = Data.apply_augs(Data.hero("brann").skills, [{"aug": "lingering", "skill": 0}, {"aug": "lingering", "skill": 0}, {"aug": "hasten", "skill": 0}, {"aug": "hasten", "skill": 0}, {"aug": "hasten", "skill": 0}])[0]
	var ilse: Dictionary = Data.apply_augs(Data.hero("ilse").skills, [{"aug": "wellspring", "skill": 1}, {"aug": "wellspring", "skill": 1}])[1]
	var kaede: Dictionary = Data.apply_augs(Data.hero("kaede").skills, [{"aug": "keen", "skill": 0}, {"aug": "keen", "skill": 0}, {"aug": "lingering", "skill": 0}])[0]
	var sorrel: Dictionary = Data.apply_augs(Data.hero("sorrel").skills, [{"aug": "kindling", "skill": 0}])[0]
	var ok: bool = brann.fx.stun == 2 and brann.cd == 1 and absf(ilse.power - 2.24) < 1e-9 and absf(kaede.power - 1.625) < 1e-9 and kaede.fx.burn == 3 and sorrel.fx.burn == 1
	return [ok, "Rockfall stun %d, CD %d · Rain ×%s · Foxfire ×%s, burn %d · Crosswind burn %d" % [brann.fx.stun, brann.cd, ilse.power, kaede.power, kaede.fx.burn, sorrel.fx.burn]]


func _four_way() -> Array:
	var els := Data.ELEMS.keys()
	var opp := {"fire": "earth", "earth": "fire", "wind": "water", "water": "wind"}
	var ok := true
	var lines := []
	for a in els:
		var up := els.filter(func(b): return Data.elem_mult("four", a, b) > 1)
		var down := els.filter(func(b): return Data.elem_mult("four", a, b) < 1)
		var even := els.filter(func(b): return b != a and Data.elem_mult("four", a, b) == 1)
		ok = ok and up.size() == 1 and down.size() == 1 and even.size() == 1 and even[0] == opp[a]
		lines.append("%s beats %s · loses to %s · even with %s" % [a, up, down, even])
	return [ok, " | ".join(lines)]


func _aura_names() -> Array:
	var s := Data.apply_augs(Data.hero("kaede").skills, [{"aug": "kindling", "skill": 0}, {"aug": "hasten", "skill": 0}])
	var a1 := Data.aura(["hasten", "kindling"])
	var a2 := Data.aura(["hasten", "keen", "kindling"])
	var ok: bool = s[0].name == "Kindled Foxfire Lance" and s[1].name == "Ninefold Blaze" and a1.fam == "wind" and a1.lvl == 1 and a2.fam == "fire" and a2.lvl == 2
	return [ok, "%s / %s · Hasten then Kindling → %s %d · plus Keen → %s %d" % [s[0].name, s[1].name, a1.fam, a1.lvl, a2.fam, a2.lvl]]


func _celerity_fits() -> Array:
	var k := Data.apply_augs(Data.hero("kaede").skills, [{"aug": "celerity", "skill": 1}])
	var fits_all := true
	for h in ["kaede", "brann", "ilse"]:
		for s in Data.hero(h).skills:
			fits_all = fits_all and Data.fits("celerity", s)
	return [k[1].get("celerity", false) and not k[0].has("celerity") and k[1].name == "Fleet Ninefold Blaze" and fits_all, "%s · fits every starter skill %s" % [k[1].name, fits_all]]


func _formation() -> Array:
	var col := Collection.new()
	var moved := col.place("kaede", Vector2i(2, 3)) == "" and col.tile("kaede") == Vector2i(2, 3)
	var b := col.tile("brann")
	var swapped := col.place("kaede", b) == "" and col.tile("kaede") == b and col.tile("brann") == Vector2i(2, 3)
	var off := col.place("kaede", Vector2i(Collection.ROWS, 0)) != "" and col.tile("kaede") == b
	var benched := col.place("rock", Vector2i(2, 0)) != ""
	# Basalt's own spot (0, 2): put Sorrel there first, then field Basalt in Varuni's seat.
	col.place("sorrel", Vector2i(0, 2))
	col.toggle_field("ilse")
	col.toggle_field("rock")
	var tiles := {}
	for u in col.squad:
		tiles[col.tile(u)] = true
	var apart: bool = tiles.size() == col.squad.size() and col.tile("rock") != Vector2i(0, 2)
	var ok: bool = moved and swapped and off and benched and apart
	return [ok, "move %s · swap %s · off-grid refused %s · benched refused %s · joiner on a free tile %s (%s)" % [moved, swapped, off, benched, apart, col.tile("rock")]]


func _regions() -> Array:
	var ok := true
	var lines := []
	for h in Data.HEROES:
		var r: Dictionary = Data.REGIONS.get(h.get("home", ""), {})
		var good: bool = not r.is_empty() and r.dark.get_luminance() < 0.15 and r.light.get_luminance() > 0.5 \
			and ResourceLoader.exists("res://art/icons/ui/region_%s.svg" % h.home)
		ok = ok and good
		lines.append("%s → %s" % [h.name, r.get("name", "none")])
	return [ok, " · ".join(lines)]


func _archetypes() -> Array:
	var per_region := {}
	var per_elem := {}
	var ok := Lore.ARCHETYPES.size() == 40
	for a in Lore.ARCHETYPES:
		ok = ok and Data.REGIONS.has(a.region) and Data.ELEMS.has(a.elem) and Lore.ROLES.has(a.role) \
			and a.favored.all(func(x): return Data.APTITUDES.has(x)) and (a.hero == "" or not Data.hero(a.hero).is_empty())
		per_region[a.region] = per_region.get(a.region, 0) + 1
		per_elem[a.elem] = per_elem.get(a.elem, 0) + 1
	for r in Data.REGIONS:
		ok = ok and per_region.get(r, 0) >= 2 and ResourceLoader.exists("res://art/icons/ui/region_%s.svg" % r)
	for e in Data.ELEMS:
		ok = ok and per_elem.get(e, 0) >= 7
	return [ok, "%d archetypes · %s" % [Lore.ARCHETYPES.size(), per_elem]]
func _town_costs() -> Array:
	var t := Town.new()
	var ok := true
	var lines := []
	for k in Town.BUILDINGS:
		var costs := []
		for lvl in Town.BUILDINGS[k].max:
			t.levels[k] = lvl
			costs.append(t.cost(k))
		for i in costs.size():
			ok = ok and costs[i] % 10 == 0 and (i == 0 or costs[i] > costs[i - 1])
		lines.append("%s %s" % [k, costs])
	t.reset()
	var base := t.battle_reward()
	t.levels.hearth = 3
	ok = ok and base == Town.BATTLE_EMBERS and t.battle_reward() == roundi(Town.BATTLE_EMBERS * 1.2)
	return [ok, " · ".join(lines) + " · reward %d → %d at Hearth 3" % [base, t.battle_reward()]]


func _town_blocked() -> Array:
	var t := Town.new()
	t.embers = 0
	var broke := t.upgrade("grounds")
	var same: bool = t.level("grounds") == 0 and t.embers == 0
	t.earn(10000)
	var built := t.upgrade("grounds")
	var above := t.upgrade("grounds")   # Hearth 1 holds it at 1
	var why := t.blocked("grounds")
	var hearth := t.upgrade("hearth")
	var after := t.upgrade("grounds")
	var ok: bool = not broke and same and built and not above and why == "Raise the Ashen Hearth first." and hearth and after \
		and t.level("grounds") == 2 and t.embers == 10000 - 100 - 320 - 160
	return [ok, "broke %s · built %s · above the Hearth %s (%s) · Hearth up %s · then %s · %d embers left" % [broke, built, above, why, hearth, after, t.embers]]


func _town_caps() -> Array:
	var t := Town.new()
	t.earn(1000000)
	for i in 10:
		t.upgrade("hearth")
	for k in Town.BUILDINGS:
		for i in 10:
			t.upgrade(k)
	var ok := true
	for k in Town.BUILDINGS:
		ok = ok and t.level(k) == Town.BUILDINGS[k].max and t.blocked(k) == "At its highest level."
	var regions := Data.REGIONS.keys()
	ok = ok and t.routes_at(1) == regions.slice(0, 2) and t.routes_at(2).size() == 3 and t.routes() == regions \
		and t.envoys() == regions.slice(0, mini(Town.BUILDINGS.envoys.max, regions.size()))
	return [ok, "levels %s · routes at 1: %s · envoys: %s" % [t.levels, t.routes_at(1), t.envoys()]]


func _eye_line() -> Array:
	var card := Vector2(293, 378)
	var ok := true
	var lines := []
	for h in Data.HEROES:
		var ts: Vector2 = load(h.portrait.src).get_size()
		var r := Forge.crop(ts, card, h.portrait)
		var eye: float = (ts.y * h.portrait.eyes[1] / 100.0 - r.position.y) / r.size.y
		var face: float = ts.y * (h.portrait.chin - h.portrait.eyes[1]) / 100.0 / r.size.y
		ok = ok and absf(eye - Forge.EYE_LINE) < 0.01 and absf(face - Forge.FACE) < 0.01
		lines.append("%s eyes %d%%, face %d%%" % [h.name, roundi(eye * 100), roundi(face * 100)])
	return [ok, " · ".join(lines)]


# ---------- battle (ported from the sandbox's combat checks) ----------

const POST := {"key": "post", "name": "Training Post", "short": "Post", "elem": "fire", "range": "melee", "max_hp": 6000, "atk": 100, "def": 40, "spd": 50, "r": 0, "c": 0, "skills": []}
## A neutral test unit carrying one of each general engine system, so the checks exercise the engine without a real character.
const PROBE := {"key": "probe", "name": "Probe", "elem": "fire", "range": "ranged", "max_hp": 720, "atk": 155, "def": 38, "spd": 95, "r": 2, "c": 1,
	"basic": {"name": "Probe shot", "ignores_falloff": true},
	"stacks": {"steady": {"label": "STK", "name": "Steady", "max": 2, "per_stack": 0.25, "gain": "still_unhit", "clear_on": ["damaged", "moved"]}},
	"skills": [
		{"name": "Probe leap", "kind": "move", "reach": "any", "breaks_chain": false, "keeps_stacks": true, "cd": 3, "mark": {"name": "Mark", "label": "MRK", "dmg_bonus": 0.2, "only": "basic", "rounds": 2}, "desc": ""},
		{"name": "Probe trap", "kind": "tile", "pattern": "single", "cd": 3, "effect": {"kind": "trap", "label": "TRP", "rounds": 3, "triggers": ["on_act", "on_enter"], "once": true, "payload": {"power": 0.6, "elem": "fire", "fx": {"burn": 2}}}, "desc": ""},
		{"name": "Probe beacon", "kind": "buff", "pattern": "all", "cd": 5, "team_buff": {"name": "Beacon", "rounds": 1, "flags": {"ignores_falloff": true, "melee_reach_all": true}}, "desc": ""},
	]}
# HP after each round of a fixed fight with the starter four, recorded from the original v0.1 build.
const BASELINE := ["P-kaede:584,P-brann:1039,P-sorrel:777,P-ilse:773,E-golem:1031,E-blade:778,E-caller:900,E-seer:641","P-kaede:667,P-brann:1191,P-sorrel:367,P-ilse:850,E-golem:884,E-blade:608,E-caller:568,E-seer:531","P-kaede:667,P-brann:1191,P-sorrel:273,P-ilse:850,E-golem:690,E-blade:586,E-caller:718,E-seer:522","P-kaede:574,P-brann:1186,P-sorrel:0,P-ilse:850,E-golem:409,E-blade:425,E-caller:592,E-seer:474","P-kaede:356,P-brann:840,P-sorrel:0,P-ilse:799,E-golem:57,E-blade:378,E-caller:592,E-seer:315","P-kaede:248,P-brann:880,P-sorrel:0,P-ilse:850,E-golem:0,E-blade:208,E-caller:495,E-seer:205","P-kaede:248,P-brann:768,P-sorrel:0,P-ilse:850,E-golem:0,E-blade:100,E-caller:645,E-seer:0","P-kaede:248,P-brann:768,P-sorrel:0,P-ilse:850,E-golem:0,E-blade:0,E-caller:586,E-seer:0","P-kaede:169,P-brann:768,P-sorrel:0,P-ilse:850,E-golem:0,E-blade:0,E-caller:323,E-seer:0","P-kaede:321,P-brann:920,P-sorrel:0,P-ilse:850,E-golem:0,E-blade:0,E-caller:120,E-seer:0","P-kaede:321,P-brann:920,P-sorrel:0,P-ilse:850,E-golem:0,E-blade:0,E-caller:0,E-seer:0"]
# The same fight on 4×4 with the spread enemy start, first 15 rounds, recorded 2026-10-18 with every rule off.
const REFERENCE_4X4 := ["P-kaede:584,P-brann:1039,P-sorrel:777,P-ilse:773,E-golem:1222,E-blade:520,E-caller:900,E-seer:800","P-kaede:667,P-brann:1191,P-sorrel:367,P-ilse:850,E-golem:1075,E-blade:350,E-caller:598,E-seer:698","P-kaede:661,P-brann:1191,P-sorrel:273,P-ilse:850,E-golem:922,E-blade:0,E-caller:598,E-seer:698","P-kaede:661,P-brann:1191,P-sorrel:72,P-ilse:850,E-golem:800,E-blade:0,E-caller:636,E-seer:800","P-kaede:425,P-brann:1107,P-sorrel:0,P-ilse:799,E-golem:440,E-blade:0,E-caller:513,E-seer:800","P-kaede:317,P-brann:1259,P-sorrel:0,P-ilse:850,E-golem:212,E-blade:0,E-caller:420,E-seer:698","P-kaede:109,P-brann:1259,P-sorrel:0,P-ilse:850,E-golem:0,E-blade:0,E-caller:420,E-seer:614","P-kaede:109,P-brann:1259,P-sorrel:0,P-ilse:850,E-golem:0,E-blade:0,E-caller:515,E-seer:690","P-kaede:0,P-brann:1175,P-sorrel:0,P-ilse:799,E-golem:0,E-blade:0,E-caller:392,E-seer:502","P-kaede:0,P-brann:1327,P-sorrel:0,P-ilse:850,E-golem:0,E-blade:0,E-caller:338,E-seer:346","P-kaede:0,P-brann:1258,P-sorrel:0,P-ilse:850,E-golem:0,E-blade:0,E-caller:338,E-seer:165","P-kaede:0,P-brann:1258,P-sorrel:0,P-ilse:850,E-golem:0,E-blade:0,E-caller:488,E-seer:241","P-kaede:0,P-brann:1258,P-sorrel:0,P-ilse:850,E-golem:0,E-blade:0,E-caller:488,E-seer:8","P-kaede:0,P-brann:1397,P-sorrel:0,P-ilse:850,E-golem:0,E-blade:0,E-caller:488,E-seer:0","P-kaede:0,P-brann:1333,P-sorrel:0,P-ilse:850,E-golem:0,E-blade:0,E-caller:369,E-seer:0"]


## A test fight: heroes as [key, r, c] (the probe counts as a hero), training posts as [r, c] named E-post0, E-post1…
## Every rule starts off; `on` switches some on.
func _scenario(heroes: Array, posts: Array, on := []) -> Battle:
	var b := Battle.new()
	for k in on:
		b.rules[k] = true
	var us := []
	for h in heroes:
		var d: Dictionary = PROBE if h[0] == "probe" else Data.hero(h[0])
		var u := b.mk(d, "P")
		u.r = h[1]
		u.c = h[2]
		us.append(u)
	for i in posts.size():
		var u := b.mk(POST, "E")
		u.id = "E-post%d" % i
		u.short = "Post %d" % (i + 1)
		u.r = posts[i][0]
		u.c = posts[i][1]
		us.append(u)
	b.units = us
	return b


static func _lost(u: Dictionary) -> int:
	return u.max_hp - u.hp


static func _near(x: float, y: float) -> bool:
	return absf(x - y) <= 1


func _hit(b: Battle, u: Dictionary, t: Dictionary, key := "basic") -> int:
	var before: int = t.hp
	b.perform(u, b.act(u, key), t.r, t.c, 0)
	return before - t.hp


func _next_round(b: Battle) -> void:
	b.end_of_round()
	b.round_num += 1


func _base_shot() -> int:
	var b := _scenario([["probe", 2, 1]], [[0, 1]])
	b.phase = "run"
	return _hit(b, b.unit("P-probe"), b.unit("E-post0"))


func _b_falloff() -> Array:
	var b := _scenario([["probe", 2, 1], ["sorrel", 1, 0]], [[0, 0], [2, 2]])
	b.phase = "run"
	var p := b.unit("P-probe")
	var front := b.unit("E-post0")
	var back := b.unit("E-post1")
	var f := _hit(b, p, front)
	var bk := _hit(b, p, back)
	var sf := _hit(b, b.unit("P-sorrel"), front)
	var sb := _hit(b, b.unit("P-sorrel"), back)
	return [f == bk and f > 0 and sb < sf, "probe front %d, back %d · Sorrel's Bolt front %d, back %d" % [f, bk, sf, sb]]


func _b_stacks() -> Array:
	var d0 := _base_shot()
	var b := _scenario([["probe", 2, 1]], [[0, 1]])
	var p := b.unit("P-probe")
	_next_round(b)
	_next_round(b)
	var n: int = p.stacks.steady.n
	b.phase = "run"
	var d2 := _hit(b, p, b.unit("E-post0"))
	return [n == 2 and _near(d2, d0 * 1.5) and p.stacks.steady.n == 0, "stacks %d, base %d, stacked %d, after %d" % [n, d0, d2, p.stacks.steady.n]]


func _b_stacks_hit() -> Array:
	var b := _scenario([["probe", 2, 1]], [[0, 1]])
	var p := b.unit("P-probe")
	_next_round(b)
	_next_round(b)
	var n: int = p.stacks.steady.n
	b.phase = "run"
	var post := b.unit("E-post0")
	b.perform(post, b.act(post, "basic"), p.r, p.c, 0)
	return [n == 2 and _lost(p) > 0 and p.stacks.steady.n == 0, "stacks %d → %d after taking %d" % [n, p.stacks.steady.n, _lost(p)]]


func _b_team_buff() -> Array:
	var b := _scenario([["probe", 2, 1], ["brann", 0, 1]], [[0, 1], [2, 1]])
	var can_plan: bool = Vector2i(2, 1) in b.targets(b.unit("P-brann"), b.act(b.unit("P-brann"), "s0")).tiles
	b.queue = [{"id": "P-probe", "key": "s2", "r": 1, "c": 1}]
	var can_with: bool = Vector2i(2, 1) in b.targets(b.unit("P-brann"), b.act(b.unit("P-brann"), "s0")).tiles
	b.queue.append({"id": "P-brann", "key": "s0", "r": 2, "c": 1})
	b.phase = "run"
	b.run_queue()
	var with_b := [_lost(b.unit("E-post0")), _lost(b.unit("E-post1"))]
	b = _scenario([["probe", 2, 1], ["brann", 0, 1]], [[0, 1], [2, 1]])
	b.queue = [{"id": "P-brann", "key": "s0", "r": 2, "c": 1}]
	b.phase = "run"
	b.run_queue()
	var without := [_lost(b.unit("E-post0")), _lost(b.unit("E-post1"))]
	return [not can_plan and can_with and with_b[0] == 0 and with_b[1] > 0 and without[0] > 0 and without[1] == 0,
		"targetable while planning %s → %s · with buff front/back %s · without %s" % [can_plan, can_with, with_b, without]]


func _b_buff_chain() -> Array:
	var b := _scenario([["probe", 2, 1], ["kaede", 1, 1]], [[0, 1]])
	b.queue = [{"id": "P-probe", "key": "s2", "r": 1, "c": 1}, {"id": "P-kaede", "key": "s0", "r": 0, "c": 1}]
	b.phase = "run"
	b.run_queue()
	var k: Dictionary = b.trace.filter(func(x): return x.id == "P-kaede")[0]
	return [absf(k.chain_mult - (1 + b.tune.chain)) < 1e-9, "Surya's Foxfire Lance chain ×%.2f" % k.chain_mult]


func _leap_run(key: String) -> Battle:
	var b := _scenario([["probe", 2, 1], ["kaede", 1, 1], ["ilse", 2, 2]], [[0, 1]])
	b.unit("P-probe").stacks.steady.n = 2
	var to := Vector2i(0, 0) if key == "s0" else Vector2i(2, 0)
	b.queue = [{"id": "P-kaede", "key": "s0", "r": 0, "c": 1}, {"id": "P-probe", "key": key, "r": to.x, "c": to.y}, {"id": "P-ilse", "key": "s0", "r": 0, "c": 1}]
	b.phase = "run"
	b.run_queue()
	return b


func _b_leap() -> Array:
	var d0 := _base_shot()
	var b := _leap_run("s0")
	var ilse: float = b.trace.filter(func(x): return x.id == "P-ilse")[0].chain_mult
	var p := b.unit("P-probe")
	var pos := Vector2i(p.r, p.c)
	var kept: int = p.stacks.steady.n
	_next_round(b)
	b.phase = "run"
	var d := _hit(b, p, b.unit("E-post0"))
	var plain: float = _leap_run("move").trace.filter(func(x): return x.id == "P-ilse")[0].chain_mult
	var ok: bool = pos == Vector2i(0, 0) and absf(ilse - (1 + b.tune.chain)) < 1e-9 and absf(plain - 1) < 1e-9 and kept == 2 \
		and _near(d, d0 * 1.5 * 1.2) and p.marks.is_empty()
	return [ok, "landed %s, Varuni chain ×%.2f (×%.2f after a normal move), stacks kept %d, next shot ×%.2f" % [b.lane(pos.x, pos.y), ilse, plain, kept, float(d) / d0]]


func _b_trap_act() -> Array:
	var b := _scenario([["probe", 2, 1]], [[0, 1]])
	var post := b.unit("E-post0")
	b.queue = [{"id": "P-probe", "key": "s1", "r": 0, "c": 1}]
	b.phase = "run"
	b.run_queue()
	var placed := b.tiles.size()
	b.enemy_turn(post)
	return [placed == 1 and _lost(post) > 0 and post.st.burn == 2 and b.tiles.is_empty() and _lost(b.unit("P-probe")) > 0,
		"placed %d, post took %d, burn %d, left %d, post still attacked: %s" % [placed, _lost(post), post.st.burn, b.tiles.size(), _lost(b.unit("P-probe")) > 0]]


func _b_trap_enter() -> Array:
	var b := _scenario([["probe", 2, 1]], [[0, 1]])
	var post := b.unit("E-post0")
	b.queue = [{"id": "P-probe", "key": "s1", "r": 1, "c": 0}]
	b.phase = "run"
	b.run_queue()
	b.move_unit(post, 1, 0, {})
	return [_lost(post) > 0 and post.st.burn == 2 and b.tiles.is_empty(), "post took %d, burn %d, left %d" % [_lost(post), post.st.burn, b.tiles.size()]]


func _b_trap_expire() -> Array:
	var b := _scenario([["probe", 2, 1]], [[0, 1]])
	b.queue = [{"id": "P-probe", "key": "s1", "r": 2, "c": 2}]
	b.phase = "run"
	b.run_queue()
	var seen := [b.tiles.size()]
	for i in 3:
		_next_round(b)
		seen.append(b.tiles.size())
	return [seen == [1, 1, 1, 0], "on the board: placed %d, after each round end %s" % [seen[0], seen.slice(1)]]


func _b_formation() -> Array:
	var b := Battle.new()
	b.start(b.pristine_heroes())
	b.phase = "form"
	var k := b.unit("P-kaede")
	var br := b.unit("P-brann")
	b.place_hero(k.id, 3, 3)
	var moved: bool = k.r == 3 and k.c == 3
	var from := Vector2i(br.r, br.c)
	b.place_hero(k.id, br.r, br.c)
	var swapped: bool = Vector2i(k.r, k.c) == from and br.r == 3 and br.c == 3
	var saved := b.formation()
	var b2 := Battle.new()
	b2.start(b2.pristine_heroes(), saved)
	var kept: bool = Vector2i(b2.unit("P-kaede").r, b2.unit("P-kaede").c) == from and b2.unit("P-brann").r == 3 and b2.unit("P-brann").c == 3
	return [moved and swapped and kept, "moved %s, swapped %s, kept next battle %s" % [moved, swapped, kept]]


func _b_foe_spread() -> Array:
	var b := Battle.new()
	b.start(b.pristine_heroes())
	var foes := b.units.filter(func(u): return u.side == "E")
	var tiles := {}
	var rws := {}
	var lanes := {}
	for u in foes:
		tiles[Vector2i(u.r, u.c)] = true
		rws[u.r] = true
		lanes[u.c] = true
	var ok: bool = tiles.size() == foes.size() and foes.all(func(u): return b.in_b(u.r, u.c)) and rws.size() >= 3 and lanes.size() == 4
	return [ok, ", ".join(foes.map(func(u): return "%s %s" % [Battle.name_of(u), b.lane(u.r, u.c)])) + " · %d rows, %d lanes" % [rws.size(), lanes.size()]]


## The fixed fight: each round, every hero queues its first ready skill on the AI's preferred target.
func _scripted(b: Battle) -> Array:
	b.start(b.pristine_heroes())
	var snap := []
	for i in 15:
		if b.phase != "plan":
			break
		for u in b.living("P"):
			if u.st.stun:
				continue
			var idx := -1
			for j in u.skills.size():
				if u.cd[j] == 0:
					idx = j
					break
			if idx < 0:
				continue
			var key := "s%d" % idx
			var a := b.act(u, key)
			if a.pattern == "all":
				b.enqueue(u.id, key, u.r, u.c)
			else:
				var p: Variant = b.pick(u, a)
				if p != null:
					b.enqueue(u.id, key, p.x, p.y)
		b.run_round()
		snap.append(",".join(b.units.map(func(u): return "%s:%d" % [u.id, u.hp])))
	return snap


func _replay(b: Battle, want: Array, label: String) -> Array:
	b.elem_mode = "triangle"
	var snap := _scripted(b)
	var bad := -1
	for i in snap.size():
		if i >= want.size() or snap[i] != want[i]:
			bad = i
			break
	var ok := snap.size() == want.size() and bad < 0
	if ok:
		return [true, "%d rounds match the %s" % [snap.size(), label]]
	return [false, "round %d differs: %s" % [bad + 1, snap[bad]] if bad >= 0 else "%d rounds, expected %d" % [snap.size(), want.size()]]


func _b_baseline() -> Array:
	var b := Battle.new()
	b.rows = 3
	b.cols = 3
	return _replay(b, BASELINE, "v0.1 snapshot")


func _b_reference() -> Array:
	var b := Battle.new()
	b.scaled = false
	return _replay(b, REFERENCE_4X4, "4×4 reference")


static func _distinct(t: Array, axis: int) -> String:
	var seen := []
	for v in t:
		var s := str(v[axis])
		if not s in seen:
			seen.append(s)
	return "".join(seen)


func _b_shapes() -> Array:
	var b := Battle.new()
	var lane := b.pattern("pierce", 0, 3)
	var row := b.pattern("sweep", 3, 0)
	var big := [lane.size(), _distinct(lane, 1), row.size(), _distinct(row, 0), b.pattern("cross", 1, 1).size()]
	b.rows = 3
	b.cols = 3
	var small := [b.pattern("pierce", 0, 2).size(), b.pattern("sweep", 2, 0).size(), b.pattern("cross", 1, 1).size()]
	var ok: bool = big == [8, "32", 8, "32", 7] and small == [3, 3, 5]
	return [ok, "4×4: lane %d tiles (lanes %s), row %d (rows %s), cross %d · 3×3: lane %d, row %d, cross %d" % (big + small)]


func _b_sightline() -> Array:
	var b := _scenario([["kaede", 0, 0], ["probe", 0, 2]], [[1, 1]], ["sightline"])
	b.phase = "run"
	var k := b.unit("P-kaede")
	var p := b.unit("P-probe")
	var post := b.unit("E-post0")
	var k0 := _hit(b, k, post)
	var p0 := _hit(b, p, post)
	k.r = 2
	p.r = 2
	var k2 := _hit(b, k, post)
	var p2 := _hit(b, p, post)
	var want: float = k0 * (1 - b.tune.fall - Battle.RULE_DEFS.sightline.per_row * 2) / (1 - b.tune.fall)
	return [_near(k2, want) and p0 == p2, "Surya's Bolt front row %d → back row %d (expected ≈%.1f) · probe %d → %d" % [k0, k2, want, p0, p2]]


func _lane3(on: Array) -> Array:
	var b := _scenario([["kaede", 1, 1]], [[0, 1], [1, 1], [2, 1]], on)
	b.phase = "run"
	b.perform(b.unit("P-kaede"), b.act(b.unit("P-kaede"), "s0"), 0, 1, 0)
	return [0, 1, 2].map(func(i): return _lost(b.unit("E-post%d" % i)))


func _b_screening() -> Array:
	var off := _lane3([])
	var on := _lane3(["screening"])
	var ok := _near(on[0], off[0]) and _near(on[1], off[1] * 0.75) and _near(on[2], off[2] * 0.5)
	return [ok, "Foxfire Lance front to back: off %s · on %s" % [off, on]]


func _kindred_shot(on: Array) -> int:
	var b := _scenario([["kaede", 1, 1]], [[0, 1]], on)
	b.phase = "run"
	return _hit(b, b.unit("P-kaede"), b.unit("E-post0"))


func _b_kindred() -> Array:
	var off := _kindred_shot([])
	var on := _kindred_shot(["kindred"])
	return [_near(on, off * Battle.RULE_DEFS.kindred.mult), "Surya (Fire) on a Fire post: off %d · on %d" % [off, on]]


func _focus_run(target: Vector2i) -> float:
	var b := _scenario([["kaede", 1, 1], ["sorrel", 1, 0]], [[0, 1], [0, 0]], ["focus"])
	b.queue = [{"id": "P-kaede", "key": "s0", "r": 0, "c": 1}, {"id": "P-sorrel", "key": "s1", "r": target.x, "c": target.y}]
	b.phase = "run"
	b.run_queue()
	return b.trace.filter(func(x): return x.id == "P-sorrel")[0].chain_mult


func _b_focus() -> Array:
	var same := _focus_run(Vector2i(0, 1))
	var other := _focus_run(Vector2i(0, 0))
	var ok := absf(same - (1 + 0.10 + Battle.RULE_DEFS.focus.per_link)) < 1e-9 and absf(other - 1.10) < 1e-9
	return [ok, "Sorrel's Pinning Shot after Surya: same target ×%.2f · other target ×%.2f" % [same, other]]


func _b_shatter() -> Array:
	var b := _scenario([["kaede", 1, 1]], [[0, 0], [0, 2]], ["shatter"])
	b.phase = "run"
	var small := b.unit("E-post0")
	var big := b.unit("E-post1")
	small.max_hp = 100
	small.hp = 10
	big.max_hp = 1000
	big.hp = 10
	_hit(b, b.unit("P-kaede"), small)
	_hit(b, b.unit("P-kaede"), big)
	var ok: bool = small.get("shattered", false) and not big.get("shattered", false) and b.shatters.P == 1
	return [ok, "100-HP post shattered: %s · 1000-HP post shattered: %s · count %d" % [small.get("shattered", false), big.get("shattered", false), b.shatters.P]]


func _b_last_stand() -> Array:
	var b := _scenario([["brann", 0, 1], ["sorrel", 0, 0], ["ilse", 2, 2]], [[0, 1]], ["last_stand"])
	b.phase = "run"
	var brann := b.unit("P-brann")
	var sorrel := b.unit("P-sorrel")
	var post := b.unit("E-post0")
	brann.hp = 1
	b.perform(post, b.act(post, "basic"), brann.r, brann.c, 0)
	var downed: int = brann.downed
	b.perform(b.unit("P-ilse"), b.act(b.unit("P-ilse"), "s1"), 2, 2, 0)
	var back := [brann.alive, brann.hp]
	sorrel.hp = 1
	b.perform(post, b.act(post, "basic"), sorrel.r, sorrel.c, 0)
	_next_round(b)
	var after1: int = sorrel.downed
	_next_round(b)
	b.phase = "run"
	b.unit("P-ilse").cd = [0.0, 0.0]
	b.perform(b.unit("P-ilse"), b.act(b.unit("P-ilse"), "s1"), 2, 2, 0)
	var ok: bool = downed == 2 and back[0] and back[1] == roundi(brann.max_hp * 0.25) and after1 == 1 and sorrel.get("fallen", false) and not sorrel.alive
	return [ok, "Brann downed %d rds, revived %s at %d HP · Sorrel %d rd left after a round, fallen %s, revived late %s" % [downed, back[0], back[1], after1, sorrel.get("fallen", false), sorrel.alive]]


func _b_ashfall() -> Array:
	var b := _scenario([["kaede", 1, 1], ["brann", 0, 1]], [[0, 1]], ["ashfall"])
	var us := [b.unit("P-kaede"), b.unit("P-brann"), b.unit("E-post0")]
	us[1].st.burn = 3   # already burning: should still tick once, not twice
	b.round_num = 7
	b.end_of_round()
	var at7 := us.map(func(u): return _lost(u))
	b.round_num = 8
	b.end_of_round()
	var at8 := us.map(func(u): return _lost(u))
	var ok: bool = at7[0] == 0 and at7[2] == 0 and at7[1] == roundi(us[1].max_hp * 0.06)
	for i in us.size():
		ok = ok and at8[i] - at7[i] == roundi(us[i].max_hp * 0.06)
	return [ok, "HP lost after round 7: %s (Brann was already burning) · after round 8: %s" % [at7, at8]]


func _b_reach() -> Array:
	# Brann one row back can't reach anything; on the front row he reaches only across his own lane.
	var b := _scenario([["brann", 1, 1]], [[0, 1], [0, 2]], ["reach"])
	var br := b.unit("P-brann")
	var rock := b.act(br, "s0")
	var back_row: Array = b.targets(br, rock).tiles
	var why := b.blocked_reason(br, rock)
	br.r = 0
	var front: Array = b.targets(br, rock).tiles
	var basic: Array = b.targets(br, b.act(br, "basic")).tiles
	b.rules.reach = false
	var off: Array = b.targets(br, rock).tiles
	# A melee foe with nobody across its lane steps toward one instead of standing idle.
	var e := _scenario([["sorrel", 0, 2]], [[0, 0]], ["reach"])
	var post := e.unit("E-post0")
	e.phase = "run"
	e.enemy_turn(post)
	var stepped := Vector2i(post.r, post.c)
	var ok: bool = back_row.is_empty() and why != "" and front == [Vector2i(0, 1)] and basic == [Vector2i(0, 1)] and off.size() == 2 \
		and stepped == Vector2i(0, 1)
	return [ok, "from the second row %s (%s) · from the front %s, basic %s · rule off %s · idle post steps to %s" % [back_row, why, front, basic, off, e.lane(stepped.x, stepped.y)]]


func _keen_shot(augs: Array) -> int:
	var b := _scenario([["kaede", 1, 1]], [[0, 1]])
	var k := b.unit("P-kaede")
	k.skills = Data.apply_augs(Data.hero("kaede").skills, augs)
	b.phase = "run"
	return _hit(b, k, b.unit("E-post0"), "s0")


func _b_keen() -> Array:
	var d0 := _keen_shot([])
	var d1 := _keen_shot([{"aug": "keen", "skill": 0}])
	return [_near(d1, d0 * 1.15), "Foxfire Lance %d → %d with Keen (×%.3f)" % [d0, d1, float(d1) / d0]]


func _b_brann_earth() -> Array:
	var b := _scenario([["brann", 0, 1]], [[0, 1]])
	b.unit("E-post0").elem = "water"
	b.phase = "run"
	var br := b.unit("P-brann")
	var vs_water := _hit(b, br, b.unit("E-post0"), "s0")
	b.unit("E-post0").elem = "fire"
	br.cd = [0.0, 0.0]
	var vs_fire := _hit(b, br, b.unit("E-post0"), "s0")
	var t := Battle.new()
	t.elem_mode = "triangle"
	var old: String = t.mk(Data.hero("brann"), "P").elem
	return [br.elem == "earth" and _near(vs_water, vs_fire * 1.5) and old == "water", "Rockfall on Water %d, on Fire %d · triangle-mode Brann is %s" % [vs_water, vs_fire, old]]


func _b_celerity() -> Array:
	var out := []
	for stars in [1, 2, 3, 4]:
		var b := _scenario([["kaede", 1, 1]], [[0, 1]])
		var k := b.unit("P-kaede")
		k.stars = stars
		k.skills = Data.apply_augs(Data.hero("kaede").skills, [{"aug": "celerity", "skill": 1}])
		b.run_openers()
		out.append({"stars": stars, "hit": _lost(b.unit("E-post0")) > 0, "cd": k.cd[1], "chain": b.trace[0].chain_mult if b.trace.size() else 0.0, "phase": b.phase})
	var want := [INF, 8.0, 4.0, 0.0]
	var ok := true
	for i in out.size():
		ok = ok and out[i].hit and out[i].cd == want[i] and out[i].chain == 1.0 and out[i].phase == "plan"
	return [ok, " · ".join(out.map(func(o): return "%d★ cooldown %s" % [o.stars, "locked" if o.cd == INF else str(o.cd)]))]


func _b_celerity_stun() -> Array:
	var b := _scenario([["brann", 0, 1]], [[0, 1]])
	var br := b.unit("P-brann")
	var post := b.unit("E-post0")
	br.stars = 4
	br.skills = Data.apply_augs(Data.hero("brann").skills, [{"aug": "celerity", "skill": 0}, {"aug": "lingering", "skill": 0}])
	b.run_openers()
	var opened: int = post.st.stun
	post.st.stun = 0
	b.phase = "run"
	b.perform(br, b.act(br, "s0"), post.r, post.c, 0)
	return [opened == 1 and post.st.stun == 2, "%s: opener stun %d, queued stun %d" % [br.skills[0].name, opened, post.st.stun]]


func _b_ground() -> Array:
	# Posts above and below B·Mid; Sorrel's Crosswind aimed at the empty tile between them.
	var b := _scenario([["sorrel", 1, 1]], [[0, 1], [2, 1]], ["ground"])
	var so := b.unit("P-sorrel")
	var cross := b.act(so, "s0")
	var aim: bool = Vector2i(1, 1) in b.aim_tiles(so, cross).tiles
	var ai: bool = Vector2i(1, 1) in b.targets(so, cross).tiles
	b.phase = "run"
	var a0 := _lost(b.unit("E-post0"))
	b.perform(so, cross, 1, 1, 0)
	var hit := [_lost(b.unit("E-post0")) > a0, _lost(b.unit("E-post1")) > 0]
	b.rules.ground = false
	var off: bool = Vector2i(1, 1) in b.aim_tiles(so, cross).tiles
	return [aim and not ai and hit == [true, true] and not off, "aim at empty B·Mid %s · AI aims there %s · hits above and below %s · rule off %s" % [aim, ai, hit, off]]


func _b_ground_limits() -> Array:
	var b := _scenario([["sorrel", 1, 1], ["brann", 0, 0]], [[0, 1]], ["ground"])
	var so := b.unit("P-sorrel")
	var single: bool = Vector2i(2, 2) in b.aim_tiles(so, b.act(so, "s1")).tiles
	var br := b.unit("P-brann")
	var melee: bool = Vector2i(2, 2) in b.aim_tiles(br, b.act(br, "s0")).tiles
	# Aimed at Post 1, which falls before the cross lands: the cross stays on A·Front instead of chasing.
	var c := _scenario([["sorrel", 1, 1]], [[0, 0], [3, 3]], ["ground"])
	var s2 := c.unit("P-sorrel")
	c.unit("E-post0").alive = false
	c.phase = "run"
	c.perform(s2, c.act(s2, "s0"), 0, 0, 0)
	var far := _lost(c.unit("E-post1"))
	return [not single and not melee and far == 0, "single shot on an empty tile %s · melee on an empty tile %s · far post hit for %d" % [single, melee, far]]


## Every clip and still a hero names is in the project, so a face never asks for art that isn't there.
func _faces_exist() -> Array:
	var missing := []
	for f in Faces.FACES.values():
		if not ResourceLoader.exists(f.still):
			missing.append(f.still)
	for c in Clips.wanted():
		if not ResourceLoader.exists(Clips.DIR + c + ".ogv"):
			missing.append(c)
	for b in Faces.BODIES.values():
		for src in [b.src, b.get("anim", {}).get("src", b.src), b.get("attack", {}).get("src", b.src)]:
			if not ResourceLoader.exists(src):
				missing.append(src)
	return [missing.is_empty(), "%d clips named · missing %s" % [Clips.wanted().size(), missing]]


## One default: no sprite says it faces its own way.
func _facing_default() -> Array:
	var odd := []
	for key in Data.SPRITES:
		if Data.sprite_for({"key": key}).has("faces") or Data.SPRITES[key].has("faces"):
			odd.append(key)
	return [odd.is_empty(), "%d sprites · odd %s" % [Data.SPRITES.size(), odd]]


## Heroes face right and foes face left whichever way their art was drawn: every hero's and foe's sprite (and
## swing) is mirrored exactly when its art faces the other way.
func _facing() -> Array:
	var wrong := []
	for key in Data.SPRITES:
		var spr := Data.sprite_for({"key": key})
		var hero := not Data.hero(key).is_empty()
		for art in [spr, spr.get("attack", {})]:
			if art.is_empty():
				continue
			var right: bool = (art.get("faces", "left") == "right") != Figure.mirrored(art, hero)
			if right != hero:
				wrong.append(key)
	return [wrong.is_empty() and Figure.mirrored({"faces": "right"}, false) and not Figure.mirrored({}, false),
		"%d sprites · facing wrong %s" % [Data.SPRITES.size(), wrong]]


func _muted_cues() -> Array:
	var was := Sfx.on()
	Sfx._on = 1
	Sfx._last.erase("tap")
	Sfx.play("tap")
	Sfx.play("page")
	var quiet := not Sfx._last.has("tap") and not Sfx._last.has("page")
	Sfx._on = 1 if was else 0
	return [quiet, "silent: %s" % quiet]


func _skill_icons() -> Array:
	var kits := {}
	for u in Data.HEROES + Battle.FOES:
		for s in u.skills:
			kits[Forge.skill_art(s)] = kits.get(Forge.skill_art(s), {})
			kits[Forge.skill_art(s)][s.name] = true
	var bad := kits.keys().filter(func(art): return not ResourceLoader.exists(art) or kits[art].size() > 1)
	# An augmented skill keeps its icon, and every element has its shine.
	var grown: Dictionary = Data.apply_augs(Data.hero("kaede").skills, [{"aug": "keen", "skill": 0}])[0]
	var kept: bool = grown.name != "Foxfire Lance" and Forge.skill_art(grown) == "res://art/skills/foxfire-lance.webp"
	var lit: bool = Data.ELEMS.keys().all(func(e): return Forge.SKILL_SHINE.has(e) and Forge.ELEM.has(e))
	return [bad.is_empty() and kept and lit, "%d skills · missing %s · augmented keeps its icon: %s" % [kits.size(), bad, kept]]


func _road_art() -> Array:
	var missing := []
	for key in Expedition.ROADS:
		var road: Dictionary = Expedition.ROADS[key]
		# A road is a ruin of a real home: its painting is one of that home's, and its element has a home foe.
		if not Data.REGIONS.has(road.region) or road.art not in Backdrop.ART.get(road.region, []) or not Expedition.HOME_FOE.has(road.elem):
			missing.append(key + " home")
		var art: String = Expedition.ROADS[key].art
		if art not in Backdrop.all_art() or not FileAccess.file_exists(Backdrop.art_path(art)):
			missing.append(key)
	return [missing.is_empty() and Expedition.ROADS.size() == 9, "%d roads · missing %s" % [Expedition.ROADS.size(), missing]]


func _hero_stands() -> Array:
	var n := 0
	var ok := true
	for h in Data.HEROES:
		if not h.portrait.has("stand"):
			continue
		n += 1
		var c: Array = h.portrait.crops.get("profile", [0, 0, 100])
		ok = ok and ResourceLoader.exists(h.portrait.stand) and h.portrait.stand in Clips.wanted_sheets()
		ok = ok and c[0] >= 0 and c[1] >= 0 and c[0] + c[2] <= 100 and c[1] + c[2] <= 100
	return [ok and n > 0, "%d heroes stand" % n]


func _road_steps() -> Array:
	var seen := {}
	var at: String = Expedition.ROADS.keys()[0]
	for i in Expedition.ROADS.size():
		seen[at] = true
		var there := Expedition.road_step(at, 1)
		if Expedition.road_step(there, -1) != at:
			seen.clear()
			break
		at = there
	var wrapped: bool = at == Expedition.ROADS.keys()[0] and seen.size() == Expedition.ROADS.size()
	var shipped := Backdrop.SCREEN_ART.all(func(a): return Backdrop.art_path(a) in Clips.wanted_sheets() and FileAccess.file_exists(Backdrop.art_path(a)))
	return [wrapped and shipped, "%d roads · wraps %s · screen art ships %s" % [seen.size(), wrapped, shipped]]


func _travel_log() -> Array:
	var town := Town.new()
	var locked: bool = town.log_state(0) == "locked" and town.claim_log(0).is_empty()
	town.felled = 1
	var before := town.embers
	var paid: bool = town.claim_log(0).get("gold", 0) == 200 and town.embers == before + 200
	var once: bool = town.claim_log(0).is_empty() and town.log_state(0) == "claimed"
	return [locked and paid and once, "locked · pays %d · once only" % (town.embers - before)]


func _voices() -> Array:
	var ok := true
	for key in Voice.CAST:
		ok = ok and Voice.CAST[key][0] in Voice.ACTORS
	for src in Voice.files():
		ok = ok and FileAccess.file_exists(src) and src in Clips.wanted_sheets()
	return [ok, "%d clips for %d voices" % [Voice.files().size(), Voice.CAST.size()]]


func _boon_glyphs() -> Array:
	var ok := true
	for key in Expedition.BOONS:
		ok = ok and FileAccess.file_exists("res://art/icons/ui/%s.svg" % RunChoices.boon_glyph(key))
	return [ok, "%d boons" % Expedition.BOONS.size()]


func _air_light() -> Array:
	var w := Weather.over("lotus-1")
	var lo := 99.0
	var hi := 0.0
	for i in 2000:
		w.step(0.05)
		lo = minf(lo, w.gust())
		hi = maxf(hi, w.gust())
	w.free()
	var strays: Array = Painted.SKY.keys().filter(func(a): return not a in Backdrop.all_art() and a != "caravan")
	return [lo >= 1.0 and hi <= Weather.GUST and hi > lo and strays.is_empty(), "wind %.1f to %.1f · %d skies · strays %s" % [lo, hi, Painted.SKY.size(), strays]]


func _title_art() -> Array:
	var arts := Backdrop.all_art()
	var bare := arts.filter(func(art): return not FileAccess.file_exists(Backdrop.art_path(art)))
	var on_disk := Array(DirAccess.get_files_at("res://art/backgrounds/")).filter(func(f): return f.ends_with(".webp"))
	var unlisted := on_disk.filter(func(f): return f.get_basename() not in arts and f.get_basename() not in Backdrop.SCREEN_ART)
	return [not arts.is_empty() and bare.is_empty() and unlisted.is_empty(), "%d backgrounds · no file %s · unlisted %s" % [arts.size(), bare, unlisted]]


func _title_pan() -> Array:
	var edges := 0
	var reach := 0.0
	for view in [Vector2(720, 1560), Vector2(1560, 720)]:
		var full: Vector2 = Vector2(1792, 896) * maxf(view.x / 1792.0, view.y / 896.0) * TitleScreen.ZOOM
		for i in 400:
			var at := TitleScreen.pan(full, view, i * 0.5)
			if at.x > 0.0 or at.y > 0.0 or at.x + full.x < view.x or at.y + full.y < view.y:
				edges += 1
			reach = maxf(reach, absf(at.x + (full.x - view.x) / 2.0))
	var airless := Backdrop.all_art().filter(func(a): return not Weather.AIR.has(a))
	return [edges == 0 and reach > 100.0 and airless.is_empty(), "edges shown %d · reach %d px · no air %s" % [edges, reach, airless]]


func _road_music() -> Array:
	var bad := []
	var sets := {"default": Expedition.MUSIC_DEFAULT}
	for key in Expedition.ROADS:
		sets[key] = Expedition.ROADS[key].music
		if sets[key].get("map", "") == "":
			bad.append(key + " has no map track")
	for key in sets:
		for slot in sets[key]:
			var menu: bool = key == "default" and slot in Expedition.MENU_SLOTS
			if slot != "map" and not Expedition.NODES.has(slot) and not menu:
				bad.append("%s slot %s" % [key, slot])
	var used := Expedition.music_tracks()
	# The files are licensed and stay out of git, so a fresh checkout has none; the export fails if any is missing.
	var files := Array(DirAccess.get_files_at(Music.DIR)).filter(func(f): return f.ends_with(".ogg"))
	if not files.is_empty():
		for t in used:
			if t + ".ogg" not in files:
				bad.append("no file for " + t)
		for f in files:
			if f.get_basename() not in used:
				bad.append("unused file " + f)
	return [bad.is_empty() and used[0] == Expedition.MUSIC_DEFAULT.map, "%d tracks · %d files · %s" % [used.size(), files.size(), bad]]


func _music_fallback() -> Array:
	var own: String = Expedition.ROADS.lotus.music.elite
	var map: String = Expedition.ROADS.lotus.music.map
	var d := Expedition.MUSIC_DEFAULT
	return [Expedition.music_for("lotus", "elite") == own and Expedition.music_for("lotus", "map") == map
		and Expedition.music_for("lotus", "rest") == map and Expedition.music_for("", "map") == d.map
		and Expedition.music_for("", "elite") == d.elite and Expedition.music_for("", "rest") == d.map
		and Expedition.music_for("", "town") == d.get("town", d.map) and Expedition.music_for("", "menu") == d.get("menu", d.map)
		and Expedition.music_for("lotus", "heroes") == d.get("heroes", map), "%s · %s" % [own, map]]


func _music_player() -> Array:
	var was := Sfx.on()
	Sfx._on = 0
	Music.play(Expedition.MUSIC_DEFAULT.map)
	var quiet := Music.wanted() == Expedition.MUSIC_DEFAULT.map and Music.sounding() == ""
	Sfx._on = 1 if was else 0
	var s := Music.stream(Expedition.MUSIC_DEFAULT.map)
	return [quiet and Music.stream("no_such_track") == null and (s == null or s.loop), "off: %s · stream %s" % [quiet, s]]


func _sounds() -> Array:
	var cues := {}
	var re := RegEx.create_from_string("Sfx\\.play(?:\\.bind)?\\(\"([a-z_]+)\"")
	var missing := []
	for dir in ["res://ui/", "res://core/"]:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".gd"):
				for m in re.search_all(FileAccess.get_file_as_string(dir + f)):
					cues[m.get_string(1)] = true
	# Cues chosen from a table at playback.
	for c in ["crit", "hit", "shield", "mend", "burn", "stun", "victory", "defeat", "cast", "swing"]:
		cues[c] = true
	for c in cues:
		if Sfx.variants(c).is_empty():
			missing.append(c)
	return [missing.is_empty() and Sfx.variants("no_such_cue").is_empty() and cues.size() >= 15,
		"%d cues · %d variations of hit · missing %s" % [cues.size(), Sfx.variants("hit").size(), missing]]


func _hp_lag() -> Array:
	var s := BattleScreen.new()
	var full := s.hp_fx("P-x", 100, 100)
	var hit := s.hp_fx("P-x", 60, 100)
	s._process(0.2)
	var held := s.hp_fx("P-x", 60, 100)
	for i in 20:
		s._process(0.1)
	var drained := s.hp_fx("P-x", 60, 100)
	var heal := s.hp_fx("P-x", 90, 100)
	for i in 10:
		s._process(0.1)
	var filled := s.hp_fx("P-x", 90, 100)
	s.free()
	var ok: bool = full.lead == 1.0 and hit.lead == 0.6 and hit.lag == 1.0 and held.lag == 1.0 \
		and is_equal_approx(drained.lag, 0.6) and heal.gain and heal.lead == 0.6 and is_equal_approx(filled.lead, 0.9) and not filled.gain
	return [ok, "hit 100→60: bar %.2f, chunk %.2f, still %.2f after 0.2s, %.2f after 2.2s · heal to 90 fills %.2f → %.2f" % [
		hit.lead, hit.lag, held.lag, drained.lag, heal.lead, filled.lead]]


func _rig() -> Array:
	var unrigged := []
	var worst_foot := 0.0
	var best_sway := {}
	var rigged := {}
	for key in Data.SPRITES:
		var spr := Data.sprite_for({"key": key})
		if spr.has("rig"):
			rigged[key] = spr
		elif not spr.has("anim") and Faces.BODIES.has(key):
			unrigged.append(key)
	# The rig waits for the next still with no loop: while the whole cast has idle sheets, a rig on file stands in.
	if rigged.is_empty():
		rigged["on file"] = {"src": "rig-on-file", "rig": JSON.parse_string(FileAccess.get_file_as_string("res://art/sprites/seer-rig.json"))}
	for key in rigged:
		var rig := Figure.rig_of(rigged[key])
		var cols: int = rig.cols
		var rows: int = rig.rows
		var sway := 0.0
		for i in (cols + 1) * (rows + 1):
			var u := float(i % (cols + 1)) / cols
			var v := float(i / (cols + 1)) / rows
			var most := 0.0
			for k in 24:
				most = maxf(most, Figure.rig_offset(rig, i, u, v, 0.7, k * 0.37, 1.0).length())
			if v == 1.0 and rig.pin[i] > 0.6:
				worst_foot = maxf(worst_foot, most * (1.0 - 0.0))
			if rig.loose[i] > 0.8:
				sway = maxf(sway, most)
		best_sway[key] = snappedf(sway, 0.001)
	var swaying := best_sway.values().all(func(x): return x > 0.008)
	return [unrigged.is_empty() and not best_sway.is_empty() and worst_foot < 0.004 and swaying,
		"rigged %s · loose parts reach %s of their height · planted feet move at most %.4f · unrigged %s" % [
		best_sway.keys(), best_sway.values(), worst_foot, unrigged]]


func _sheets_refresh() -> Array:
	var dir := "user://sheets-check/"
	DirAccess.make_dir_recursive_absolute(dir)
	Clips.refresh_sheets(dir, "one")
	var keep := FileAccess.open(dir + "a-idle.webp", FileAccess.WRITE)
	keep.store_string("x")
	keep.close()
	Clips.refresh_sheets(dir, "one")
	var kept := FileAccess.file_exists(dir + "a-idle.webp")
	Clips.refresh_sheets(dir, "two")
	var cleared := not FileAccess.file_exists(dir + "a-idle.webp")
	var stamped := FileAccess.get_file_as_string(dir + "stamp") == "two"
	DirAccess.remove_absolute(dir + "stamp")
	DirAccess.remove_absolute(dir)
	return [kept and cleared and stamped and Faces.SHEETS_STAMP.length() == 12, "same art keeps %s · new art clears %s · stamp %s" % [kept, cleared, Faces.SHEETS_STAMP]]


func _sound_in_front() -> Array:
	var shell := FileAccess.get_file_as_string("res://web/shell.html")
	var ok := shell.contains("c.suspend()") and shell.contains("document.hasFocus()") and shell.contains("visibilitychange")
	return [ok, "shell suspends audio: %s" % ok]


func _weather() -> Array:
	var bare := []
	var strayed := 0
	for art in Backdrop.all_art():
		var w := Weather.over(art)
		if w == null:
			bare.append(art)
			continue
		w.size = Vector2(720, 1560)
		w.fill()
		for i in 600:
			w.step(0.1)
		for m in w.motes():
			if m.p.x < 0.0 or m.p.x >= 1.0 or m.p.y < 0.0 or m.p.y >= 1.0:
				strayed += 1
		if w.motes().is_empty():
			bare.append(art)
		w.free()
	var none := Weather.over("nowhere") == null
	return [bare.is_empty() and strayed == 0 and none, "%d backgrounds · no air %s · strayed %d" % [Backdrop.all_art().size(), bare, strayed]]


func _grounds() -> Array:
	var wrong := []
	var files := []
	for road in Backdrop.GROUNDS:
		var src := Backdrop.ground_path(Backdrop.GROUNDS[road].art)
		files.append(src.get_file())
		if not Expedition.ROADS.has(road) or not ResourceLoader.exists(src) or src not in Clips.wanted_sheets():
			wrong.append(road)
	for f in DirAccess.get_files_at("res://art/grounds/"):
		if f.ends_with(".webp") and f not in files:
			wrong.append(f)
	var g := Backdrop.ground("basalt")
	var tiles := g.stretch_mode == TextureRect.STRETCH_TILE
	g.free()
	var left_out := FileAccess.get_file_as_string("res://export_presets.cfg").count("art/grounds/*") == 2
	return [wrong.is_empty() and tiles and left_out and Backdrop.ground("nowhere") == null, "%d grounds · wrong %s · tiles %s · out of the pack %s" % [files.size(), wrong, tiles, left_out]]


func _backgrounds() -> Array:
	var wrong := []
	for home in Backdrop.ART:
		if not Data.REGIONS.has(home):
			wrong.append(home)
	for h in Data.HEROES:
		var p := Backdrop.painted(h.home)
		if p == null:
			wrong.append(h.key)
		else:
			p.free()
	var arts := Backdrop.all_art()
	for art in arts:
		if not ResourceLoader.exists(Backdrop.art_path(art)):
			wrong.append(art)
	for f in DirAccess.get_files_at("res://art/backgrounds/"):
		if f.ends_with(".webp") and f.get_basename() not in arts and f.get_basename() not in Backdrop.SCREEN_ART:
			wrong.append(f)
	# A home with several shows each of them over enough visits, and a home without any falls back to the glow.
	var seen := {}
	for i in 60:
		var p := Backdrop.painted("jaladesh")
		seen[p.art] = true
		p.free()
	var ok: bool = seen.size() == Backdrop.ART.jaladesh.size() and Backdrop.painted("nowhere") == null
	var travels: bool = Backdrop.art_path(arts[0]) in Clips.wanted_sheets()
	return [ok and travels and wrong.is_empty(), "%d backgrounds · %d of Jaladesh's shown · wrong %s" % [arts.size(), seen.size(), wrong]]


func _art_music() -> Array:
	var wrong := []
	for key in Expedition.ROADS:
		if Backdrop.music_of(Expedition.ROADS[key].art) != Expedition.ROADS[key].music.map:
			wrong.append(key)
	var near: bool = Backdrop.music_of("basalt-city") == Expedition.ROADS.basalt.music.map
	return [wrong.is_empty() and near and Backdrop.music_of("coast") == "" and Backdrop.music_of("nowhere") == "", "wrong %s" % [wrong]]


func _status_fx() -> Array:
	var all := StatusFx.active({"burn": 3, "stun": 1, "shield": 40, "guard": true})
	var none := StatusFx.active({"burn": 0, "stun": 0, "shield": 0, "guard": false})
	return [all == ["guard", "shield", "burn", "stun"] and none.is_empty(), "all %s · none %s" % [all, none]]


func _glows() -> Array:
	var bad := []
	var lit := 0
	for art in Backdrop.all_art():
		if not Faces.GLOWS.has(art):
			bad.append(art)
			continue
		for l in Faces.GLOWS[art]:
			lit += 1
			if l[0] < 0.0 or l[0] > 1.0 or l[1] < 0.0 or l[1] > 0.5 or l[2] <= 0.0:
				bad.append(art)
	return [bad.is_empty() and lit >= 25, "%d lights across %d backgrounds · bad %s" % [lit, Backdrop.all_art().size(), bad]]


## Idle sheets are built whole: every cell the sprite names is on the sheet, about 560 tall, at the sprite's own rate;
## the feet hold still from frame to frame (the loop's first frame against the rest, in pixels of a cell); no pure key
## colour is left on the figure.
func _idle_sheets() -> Array:
	var wrong := []
	var worst_foot := 0.0
	var sheets := 0
	for key in Faces.BODIES:
		var anim: Dictionary = Faces.BODIES[key].get("anim", {})
		if anim.is_empty():
			continue
		var im := Image.load_from_file(ProjectSettings.globalize_path(anim.src))
		im.convert(Image.FORMAT_RGBA8)
		var w: int = anim.w
		var h: int = anim.h
		var cols: int = anim.cols
		var n: int = anim.n
		var fit: bool = im.get_width() == w * cols and im.get_height() == h * ceili(float(n) / cols)
		if not fit or absi(h - 560) > 20 or anim.fps <= 0 or n < 12:
			wrong.append(key + " size")
			continue
		sheets += 1
		var first := Vector2(-1.0, -1.0)
		var key_left := 0
		for f in n:
			var ox := (f % cols) * w
			var oy := (f / cols) * h
			var low := -1
			var sum := 0.0
			var count := 0
			for y in range(h - 1, h - 40, -1):
				for x in range(0, w, 2):
					if im.get_pixel(ox + x, oy + y).a > 0.7:
						low = maxi(low, y)
						sum += x
						count += 1
			var feet := Vector2(sum / maxi(count, 1), low)
			first = feet if first.x < 0.0 else first
			worst_foot = maxf(worst_foot, absf(feet.y - first.y))
			for y in range(0, h, 7):
				for x in range(0, w, 7):
					var c := im.get_pixel(ox + x, oy + y)
					if c.a > 0.8 and ((c.g > 0.75 and c.r < 0.25 and c.b < 0.35) or (c.r > 0.8 and c.b > 0.7 and c.g < 0.2)):
						key_left += 1
		if key_left > 0:
			wrong.append("%s key %d" % [key, key_left])
	return [wrong.is_empty() and worst_foot <= 2.0 and sheets >= 1,
		"%d sheets · feet rise at most %.0f px · wrong %s" % [sheets, worst_foot, wrong]]


func _b_turn_marks() -> Array:
	var b := Battle.new()
	b.start(b.pristine_heroes())
	var v := b.unit("P-ilse")
	b.enqueue(v.id, "s1", v.r, v.c)
	b.run_round()
	var kinds := b.take_events().filter(func(e): return e.t in ["phase", "cutin"]).map(func(e): return e.get("name", e.t))
	var ok: bool = kinds.size() >= 3 and kinds[0] == "ally" and kinds[1] == "Rain of Renewal" and "enemy" in kinds
	return [ok, " → ".join(kinds)]


func _b_step_then_act() -> Array:
	var b := _scenario([["brann", 1, 1]], [[0, 1]], ["reach"])
	var br := b.unit("P-brann")
	var rock := b.act(br, "s0")
	var from_here: bool = b.targets(br, rock).tiles.is_empty()
	b.plan_step(br.id, Vector2i(0, 1))
	var aimed: Array = b.targets(b.as_planned(br), rock).tiles
	b.enqueue(br.id, "s0", 0, 1)
	b.phase = "plan"
	b.run_round()
	var post := b.unit("E-post0")
	var ok: bool = from_here and aimed == [Vector2i(0, 1)] and Vector2i(br.r, br.c) == Vector2i(0, 1) and _lost(post) > 0
	return [ok, "blocked from row 2 %s · aim after the planned step %s · Brann ends on %s · post lost %d" % [from_here, aimed, b.lane(br.r, br.c), _lost(post)]]


func _b_step_order() -> Array:
	var b := _scenario([["ilse", 2, 2], ["sorrel", 1, 0]], [[0, 1], [3, 3]], ["ground"])
	var so := b.unit("P-sorrel")
	so.hp -= 300
	b.enqueue("P-ilse", "s1", 2, 2)
	b.plan_step(so.id, Vector2i(0, 0))
	b.enqueue(so.id, "s0", 0, 1)
	b.phase = "plan"
	b.run_round()
	var ev := b.take_events()
	var logs: Array = ev.filter(func(e): return e.t == "log").map(func(e): return e.text)
	# The heal's number rises off Sorrel's starting tile: he was still standing there when it landed.
	var healed_home: bool = ev.any(func(e): return e.t == "float" and e.cls == "mend" and e.side == "P" and e.r == 1 and e.c == 0)
	var heal := logs.find_custom(func(t): return t.contains("Rain of Renewal"))
	var walk := logs.find_custom(func(t): return t.contains("Sorrel steps"))
	var cast := logs.find_custom(func(t): return t.contains("Crosswind"))
	var ok: bool = heal >= 0 and heal < walk and walk < cast and healed_home and Vector2i(so.r, so.c) == Vector2i(0, 0)
	return [ok, "heal at line %d, step at %d, Crosswind at %d · healed on his first tile %s · ends on %s" % [heal, walk, cast, healed_home, b.lane(so.r, so.c)]]


func _b_step_tiles() -> Array:
	var b := _scenario([["sorrel", 1, 0], ["brann", 0, 0], ["ilse", 2, 3]], [[0, 1]])
	var so := b.unit("P-sorrel")
	var t: Array = b.step_tiles(so)
	var far := Vector2i(3, 1) in t
	var onto := Vector2i(0, 0) in t
	var reach2 := Vector2i(1, 2) in t and Vector2i(2, 1) in t
	b.plan_step("P-ilse", Vector2i(1, 2))
	var claimed := not Vector2i(1, 2) in b.step_tiles(so)
	b.plan_step(so.id, Vector2i(2, 0))
	b.plan_step(so.id, Vector2i(1, 0))
	var cancelled := not b.steps.has(so.id)
	var ok: bool = not far and not onto and reach2 and claimed and cancelled
	return [ok, "3 away %s · onto Brann %s · 2 away %s · claimed by Varuni blocked %s · home cancels %s" % [far, onto, reach2, claimed, cancelled]]


func _b_forecast() -> Array:
	var b := _scenario([["sorrel", 1, 1]], [[0, 1], [2, 1], [1, 3]], ["ground"])
	var so := b.unit("P-sorrel")
	var before := b.snapshot()
	var fc := b.forecast(so.id, "s0", 1, 1)
	var untouched: bool = b.snapshot() == before and b.events.is_empty()
	b.phase = "run"
	b.perform(so, b.act(so, "s0"), 1, 1, 0)
	var ok := untouched and fc.size() == 3
	for e in fc:
		ok = ok and b.unit(e.id).hp == e.after
	return [ok, "untouched %s · %s" % [untouched, ", ".join(fc.map(func(e): return "%s %d→%d" % [e.id, e.before, e.after]))]]


func _b_forecast_chain() -> Array:
	var b := _scenario([["kaede", 1, 1], ["sorrel", 1, 0]], [[0, 1]])
	var post := b.unit("E-post0")
	var alone: int = b.forecast("P-sorrel", "s1", 0, 1)[0].after
	b.enqueue("P-kaede", "s0", 0, 1)
	var linked: int = b.forecast("P-sorrel", "s1", 0, 1)[0].after
	post.hp = 50
	var ko: bool = b.forecast("P-sorrel", "s1", 0, 1)[0].ko
	return [linked < alone and ko and b.links_if_queued("P-sorrel") == 1, "Pinning Shot alone leaves %d, after Kaede's skill %d · knockout flagged %s" % [alone, linked, ko]]


func _b_intents() -> Array:
	var b := Battle.new()
	b.start(b.pristine_heroes())
	var want := {}
	for i in b.intents():
		if not i.stunned:
			want[i.id] = i.name
	# Let the foes really act, with nothing queued before them, and read what each one used from the log.
	var c := b.clone()
	c.phase = "run"
	var used := {}
	for u in c._by_speed(c.living("E")):
		c.take_events()
		c.enemy_turn(u)
		var said: String = " ".join(c.take_events().filter(func(e): return e.t == "log").map(func(e): return e.text))
		for k in want:
			if k == u.id and said.contains(want[k]):
				used[k] = want[k]
	return [want == used and want.size() == 4, str(want)]


func _b_crop_override() -> Array:
	var p := {"eyes": [50, 40], "chin": 62, "crops": {"tile": [10, 20, 50]}}
	var ts := Vector2(1000, 1000)
	var tile := Forge.crop(ts, Vector2(152, 112), p, 0.62, "tile")
	var card := Forge.crop(ts, Vector2(3, 4), p, 0.62, "card")
	var plain := Forge.crop(ts, Vector2(3, 4), {"eyes": [50, 40], "chin": 62}, 0.62, "card")
	var want := Rect2(100, 200, 500 * 152.0 / 112.0, 500)
	return [tile.is_equal_approx(want) and card.is_equal_approx(plain), "tile %s · card %s" % [tile, card]]


func _x_map() -> Array:
	var bad := []
	for road in Expedition.ROADS:
		for sd in 40:
			var x := Expedition.new().begin(road, sd)
			var n := x.layers.size()
			if x.layers[n - 1].size() != 1 or x.layers[n - 1][0].type != "boss":
				bad.append("%s/%d warden" % [road, sd])
			if not x.layers[n - 2].all(func(nd): return nd.type == "rest"):
				bad.append("%s/%d camp" % [road, sd])
			# Walk forward from every first node: each layer must be fully reachable.
			var seen := {}
			for j in x.layers[0].size():
				seen[Vector2i(0, j)] = true
			for i in n - 1:
				for j in x.layers[i].size():
					if x.layers[i][j].next.is_empty():
						bad.append("%s/%d dead end" % [road, sd])
					for k in x.layers[i][j].next:
						seen[Vector2i(i + 1, k)] = true
				for k in x.layers[i + 1].size():
					if not seen.has(Vector2i(i + 1, k)):
						bad.append("%s/%d unreachable %d,%d" % [road, sd, i + 1, k])
	return [bad.is_empty(), "120 maps · " + (", ".join(bad.slice(0, 3)) if bad.size() else "all connected")]


func _x_foes() -> Array:
	var x := Expedition.new().begin("lotus", 7)
	var first := x.foes_for(Vector2i(0, 0))
	var last := x.foes_for(Vector2i(x.layers.size() - 1, 0))
	var ok: bool = first.keys[0] == "caller" and last.keys[0] == "caller" and first.keys.size() == 2 and last.keys.size() == 4 \
		and last.scale > first.scale and first.keys == x.foes_for(Vector2i(0, 0)).keys
	return [ok, "first %s ×%s · warden %s ×%s" % [first.keys, first.scale, last.keys, last.scale]]


func _x_health() -> Array:
	var x := Expedition.new().begin("basalt", 3)
	x.step(Vector2i(0, 0))
	x.finish_fight(true, {"kaede": 0.4, "brann": 0.0, "sorrel": 1.0})
	var paid := x.embers
	var healed := x.rest(2)
	var after := x.health("kaede")
	var ok := is_equal_approx(after, 0.4 + healed) and x.fallen("brann") and x.health("sorrel") == 1.0 and x.health("ilse") == 1.0 and paid > 0 and x.over == ""
	x.finish_fight(false, {"kaede": 0.0})
	return [ok and x.over == "lose", "Surya 0.4 → %.2f after camp · Brann stays down · %d embers from the fight" % [after, paid]]


func _x_boons() -> Array:
	var x := Expedition.new().begin("saltglass", 5)
	x.take({"key": "whetstone", "rarity": 0})
	x.take({"key": "whetstone", "rarity": 3})
	x.take({"key": "kinfire", "rarity": 1})
	var u := {"atk": 100, "def": 50, "spd": 80, "max_hp": 1000, "hp": 1000, "elem": "fire"}
	var v := {"atk": 100, "def": 50, "spd": 80, "max_hp": 1000, "hp": 1000, "elem": "water"}
	x.boost(u)
	x.boost(v)
	x.embers = 101
	x.over = "lose"
	return [u.atk == 146 and v.atk == 130 and u.def == 50 and x.banked() == 50, "fire hero atk %d · water hero atk %d · 101 embers bank %d on a loss" % [u.atk, v.atk, x.banked()]]


func _h_slides() -> Array:
	var all := MainMenu.slides("")
	var ok: bool = all == Expedition.ROADS.keys() and MainMenu.slides("lotus") == ["lotus"]
	for key in all:
		var r: Dictionary = Expedition.ROADS[key]
		ok = ok and r.about != "" and Weather.AIR.has(r.art) and Data.REGIONS.has(r.region)
	return [ok, "%d roads" % all.size()]


func _h_scene() -> Array:
	var own := []
	for s in [TownScreen.new(), CodexScreen.new(), SquadScreen.new(), ExpeditionScreen.new()]:
		if s.backdrop != "" or s.ground != "":
			own.append(s.title)
		s.free()
	var silent: Array = Expedition.ROADS.keys().filter(func(k): return Expedition.music_for(k, "map") != Expedition.ROADS[k].music.map)
	return [own.is_empty() and silent.is_empty(), "own paintings %s · roads without their theme %s" % [own, silent]]


func _b_wide_floor() -> Array:
	var rows := Collection.ROWS
	var cols := Collection.COLS
	var ok := true
	for side in ["P", "E"]:
		for r in rows:
			for c in cols:
				for p in BattleScreen.floor_quad(side, r, c, rows, cols):
					ok = ok and Rect2(Vector2.ZERO, BattleScreen.FIELD).has_point(p) and p.y <= BattleScreen.FLOOR_BOTTOM + 0.5
	var near_p := BattleScreen.floor_quad("P", 0, cols - 1, rows, cols)
	var near_e := BattleScreen.floor_quad("E", 0, cols - 1, rows, cols)
	var far := BattleScreen.floor_quad("P", 0, 0, rows, cols)
	var gap: float = near_e[3].x - near_p[2].x
	var closes: bool = (far[1] - far[0]).x < (near_p[2] - near_p[3]).x and (far[3] - far[0]).y < (near_p[3] - near_p[0]).y
	return [ok and gap > 40.0 and closes, "gap %d px · closes up %s" % [gap, closes]]


func _x_battle_subset() -> Array:
	var b := Battle.new()
	b.start(b.pristine_heroes(), {}, ["golem", "seer"], 1.5)
	var foes := b.units.filter(func(u): return u.side == "E")
	var golem := b.unit("E-golem")
	return [foes.size() == 2 and golem.max_hp == 2250 and golem.hp == 2250 and golem.atk == 173, "%d foes · golem %d hp, %d atk" % [foes.size(), golem.max_hp, golem.atk]]


## The squad's kit as hero picks read it, for four heroes from the base data.
func _pick_kit() -> Dictionary:
	var kit := {}
	for k in ["kaede", "brann", "sorrel", "ilse"]:
		kit[k] = {"skills": Data.hero(k).skills, "augs": []}
	return kit


## A run standing on its first stop, with `hp` as the squad's health, for the wayside checks.
func _wayside_run(hp: Dictionary, rarity := 0) -> Expedition:
	var x := Expedition.new().begin("lotus", 7)
	x.step(Vector2i(0, 0))
	x.hp = hp
	x.node(x.at).rarity = rarity
	return x


func _w_stops() -> Array:
	var bad := []
	var met := 0
	if Expedition.NODES.has("cache") or Expedition.NODES.has("trial") or not FileAccess.file_exists("res://art/icons/ui/%s.svg" % Expedition.NODES.wayside.icon):
		bad.append("stops")
	for road in Expedition.ROADS:
		if Events.pool(road, []).size() < 3:
			bad.append("%s pool" % road)
		for sd in 40:
			var x := Expedition.new().begin(road, sd)
			for layer in x.layers:
				for nd in layer:
					met += 1 if nd.type == "wayside" else 0
			var before := []
			for i in Events.pool(road, []).size() + Events.pool("any", []).size():
				var k := x.draw_event(Vector2i(i, 0))
				if k in before or (Events.LIST[k].road != road and Events.LIST[k].road != "any"):
					bad.append("%s/%d %s" % [road, sd, k])
				before.append(k)
	return [bad.is_empty() and met > 0, "%d events · %d wayside stops on 360 maps · %s" % [Events.LIST.size(), met, bad.slice(0, 3)]]


func _w_events() -> Array:
	var bad := []
	var roads: Array = Expedition.ROADS.keys() + ["any"]
	for key in Events.LIST:
		var ev: Dictionary = Events.LIST[key]
		var choices: Array = ev.choices
		if not ev.road in roads or ev.title != ev.title.to_lower() or choices.size() < 2 or choices.size() > 4:
			bad.append(key)
		for c in choices:
			var how := ["do", "roll", "luck"].filter(func(k): return c.has(k))
			if how.size() != 1 or (c.has("do") == c.has("win")) or c.has("win") != c.has("lose"):
				bad.append("%s shape" % key)
			if c.has("roll") and not Data.APTITUDES.has(c.roll):
				bad.append("%s aptitude" % key)
			if c.has("hero") and Data.HEROES.all(func(h): return h.key != c.hero):
				bad.append("%s hero" % key)
			for o in [c.get("do", {}), c.get("win", {}), c.get("lose", {})]:
				if not o.is_empty() and o.get("say", "") == "":
					bad.append("%s silent" % key)
				if o.has("boon") and not Expedition.BOONS.has(o.boon):
					bad.append("%s boon" % key)
				if o.has("fight") and not o.fight in ["battle", "elite"]:
					bad.append("%s fight" % key)
		var last: Dictionary = choices[-1]
		var plain: Dictionary = last.get("do", {"fight": true})
		if last.has("pay") or last.has("half") or last.has("hero") or last.has("needs") or plain.has("fight") or plain.has("hurt") or plain.has("loan") or plain.get("gold", 0.0) < 0.0:
			bad.append("%s unsafe" % key)
	return [bad.is_empty(), "%d events · %s" % [Events.LIST.size(), bad.slice(0, 4)]]


func _w_terms() -> Array:
	var bad := []
	var x := _wayside_run({"a": 1.0})
	for key in Events.LIST:
		for c in Events.LIST[key].choices:
			var o: Dictionary = c.get("lose", c.get("do", {}))
			var costly: bool = c.has("pay") or c.has("half") or c.has("roll") or o.has("hurt") or o.has("hurt_all") or o.has("fight") or o.has("loan") or o.get("gold", 0.0) < 0.0
			if costly == (x.event_terms(c) == ""):
				bad.append("%s %s" % [key, c.text])
	var c := {"pay": 2.0}
	x.embers = 89
	var refused := not x.can_pay(c)
	x.embers = x.event_price(c)
	var met := x.can_pay(c)
	x.event_pay(c)
	var odds := Expedition.roll_wins(12, false) and not Expedition.roll_wins(11, false) and Expedition.roll_wins(9, true) and not Expedition.roll_wins(8, true)
	return [bad.is_empty() and refused and met and x.embers == 0 and odds, "price %d · %s" % [x.event_price(c), bad.slice(0, 3)]]


func _w_health() -> Array:
	var x := _wayside_run({"a": 0.05, "b": 0.5, "c": 0.0})
	x.event_apply({"hurt": 0.2}, "a")
	var floored := x.health("a") > 0.0 and not x.fallen("a")
	x.event_apply({"hurt_all": 0.1})
	var all := x.health("a") > 0.0 and is_equal_approx(x.health("b"), 0.4) and x.fallen("c")
	x.event_apply({"heal": 0.3})
	var stays := x.fallen("c") and is_equal_approx(x.health("b"), 0.7)
	var squad := {"a": "rock", "b": "seer", "c": "ilse"}
	var stair := x.event_choices("unfinished_stair", squad)
	var gone := x.event_choices("unfinished_stair", {"b": "seer", "c": "rock"})
	var lamp := x.event_choices("lamp_upstream", squad)
	var safe := x.event_choices("lamp_upstream", {"a": "rock"})
	var hero: bool = stair.size() == 4 and gone.size() == 3 and lamp.size() == 3 and lamp[0].uid == "c" and Data.hero("ilse").name in lamp[0].text and safe.size() == 2
	x.embers = 101
	var c: Dictionary = lamp[0]
	x.event_pay(c)
	x.event_apply(c.do, c.uid)
	return [floored and all and stays and hero and x.embers == 51 and is_equal_approx(x.health("c"), 0.30), "fallen raised at %.0f%% for half the gold" % (x.health("c") * 100)]


func _w_rewards() -> Array:
	var plain := _wayside_run({})
	var rare := _wayside_run({}, 2)
	var a := plain.event_apply({"gold": 2.0})
	var b := rare.event_apply({"gold": 2.0, "boon": "bulwark", "up": 1, "augment": true, "rerolls": 2})
	var scaled: bool = a.gold == plain.event_gold(2.0) and b.gold == plain.event_gold(4.0) and b.boon.rarity == 3 and Data.AUGS.has(b.augment) and rare.rerolls == 2
	var loss := plain.event_apply({"gold": -100.0})
	var kept: bool = loss.gold == -a.gold and plain.embers == 0
	var x := _wayside_run({})
	x.event_apply({"fight": "elite"})
	var foes := x.foes_for(x.at)
	var plain_foes := plain.foes_for(plain.at)
	var harder: bool = x.stop_kind() == "elite" and foes.keys.size() == 3 and foes.scale > plain_foes.scale
	x.finish_fight(true, {})
	var paid := x.embers == x.purse("elite")
	x.step(x.choices()[0])
	var cleared := x.ambush == ""
	var debt := _wayside_run({})
	debt.event_apply({"loan": [3.0, 5.0]})
	var lent := debt.embers == debt.event_gold(3.0)
	debt.over = "win"
	var bankrupt := debt.banked() == 0
	debt.embers = debt.debt + 75
	return [scaled and kept and harder and paid and cleared and lent and bankrupt and debt.banked() == 75, "2 purses pay %d, or %d at epic · a loan owes %d" % [a.gold, b.gold, debt.debt]]


func _pick_run(road := "lotus", sd := 7) -> Expedition:
	var x := Expedition.new().begin(road, sd)
	x.step(Vector2i(0, 0))
	return x


func _x_pick_offer() -> Array:
	var bad := []
	var seen := []
	for sd in 40:
		var x := _pick_run("lotus", sd)
		x.hp["kaede"] = 0.0
		for i in 3:
			x.offer_pick(_pick_kit())
			var o: Dictionary = x.pick_now
			if o.is_empty() or o.uid == "kaede":
				bad.append("seed %d offer %d: %s" % [sd, i, o.get("uid", "none")])
				continue
			seen.append(o.uid)
			var pairs: Array = o.options.map(func(p): return "%s/%d" % [p.aug, p.skill])
			for p in o.options:
				if pairs.count("%s/%d" % [p.aug, p.skill]) != 1 or not Data.fits(p.aug, Data.hero(o.uid).skills[p.skill]):
					bad.append("seed %d %s" % [sd, pairs])
			if o.options.size() != Expedition.PICK_OFFERS:
				bad.append("seed %d %d options" % [sd, o.options.size()])
			x.skip_pick()
	var turns := ["brann", "sorrel", "ilse"].all(func(k): return seen.count(k) == 40)
	return [bad.is_empty() and turns, "120 offers · brann %d, sorrel %d, ilse %d · %s" % [seen.count("brann"), seen.count("sorrel"), seen.count("ilse"), ", ".join(bad.slice(0, 2)) if bad.size() else "all fit"]]


func _x_pick_useful() -> Array:
	var x := _pick_run()
	var uid := "kaede"
	var skills: Array = [Data.hero("kaede").skills[0].duplicate(true), Data.hero("kaede").skills[1].duplicate(true)]
	skills[0].cd = 1
	x.picks[uid] = [{"aug": "celerity", "skill": 1}]
	var opts := x.pick_options(uid, skills)
	var has := func(aug, i): return opts.any(func(o): return o.aug == aug and o.skill == i)
	var ok: bool = not has.call("celerity", 0) and not has.call("hasten", 0) and has.call("hasten", 1) \
		and not has.call("kindling", 0) and not has.call("kindling", 1) and has.call("keen", 0) and not has.call("wellspring", 0)
	x.picks[uid].append({"aug": "lingering", "skill": 0})
	var again := x.pick_options(uid, skills)
	var ok2: bool = not again.any(func(o): return o.aug == "lingering" and o.skill == 0) and again.any(func(o): return o.aug == "lingering" and o.skill == 1)
	return [ok and ok2, "%d options for Surya, then %d" % [opts.size(), again.size()]]


func _x_pick_when() -> Array:
	var lost := _pick_run()
	lost.finish_fight(false, {"kaede": 0.0})
	lost.offer_pick(_pick_kit())
	var boss := _pick_run()
	boss.at = Vector2i(boss.layers.size() - 1, 0)
	boss.finish_fight(true, {"kaede": 1.0})
	boss.offer_pick(_pick_kit())
	var rarities := {"battle": 0, "elite": 0}
	for t in rarities:
		for sd in 200:
			var x := _pick_run("lotus", sd)
			x.layers[0][0].type = t
			x.offer_pick(_pick_kit())
			for o in x.pick_now.options:
				rarities[t] += o.rarity
	return [lost.pick_now.is_empty() and boss.pick_now.is_empty() and boss.rerolls == 0 and rarities.elite > rarities.battle, "rarity total, skirmish %d · elite %d" % [rarities.battle, rarities.elite]]


func _x_pick_reroll() -> Array:
	var x := _pick_run()
	x.offer_pick(_pick_kit())
	x.skip_pick()
	x.offer_pick(_pick_kit())
	var saved := x.rerolls
	var before: Array = x.pick_now.options.duplicate()
	var who: String = x.pick_now.uid
	x.embers = 1000
	x.reroll_pick()
	var free_ok: bool = x.rerolls == 1 and x.embers == 1000 and x.pick_now.uid == who
	x.reroll_pick()
	var prices := []
	for i in 6:
		prices.append(x.reroll_price())
		x.reroll_pick()
	var fresh := _pick_run()
	fresh.offer_pick(_pick_kit())
	fresh.rerolls = 0
	fresh.embers = 19
	var broke: bool = not fresh.can_reroll() and not fresh.reroll_pick() and fresh.embers == 19
	x.skip_pick()
	x.offer_pick(_pick_kit())
	return [saved == 2 and free_ok and prices == [20, 40, 80, 160, 320, 320] and broke and x.reroll_price() == 0 and before.size() == 3,
		"two saved · prices %s · 19 embers can't pay" % [prices]]


func _x_pick_take() -> Array:
	var col := Collection.new()
	var c := col.by("kaede")
	var x := _pick_run()
	var base: float = Data.hero("kaede").skills[0].power
	var kit := {"kaede": {"skills": Data.hero("kaede").skills, "augs": []}}
	x.pick_turns = {}
	x.offer_pick(kit)
	x.pick_now.options = [{"aug": "keen", "skill": 0, "rarity": 0}]
	var first: Dictionary = x.pick_now.options[0]
	var preview: float = x.pick_preview(first).power
	x.take_pick(first)
	var b := Battle.new()
	var u := Battle.card_unit(col, "kaede", b)
	x.fit_out(u, c)
	var hits: bool = is_equal_approx(u.skills[0].power, preview) and u.skills[0].power > base
	x.picks.kaede.append({"aug": "hasten", "skill": 1})
	x.offer_pick(kit)
	x.pick_now.options = [{"aug": "kindling", "skill": 0, "rarity": 1}]
	var o: Dictionary = x.pick_now.options[0]
	var refused: bool = not x.take_pick(o) and x.picks.kaede.size() == 2
	var swapped: bool = x.take_pick(o, 0) and x.picks.kaede.size() == 2 and x.picks.kaede.any(func(p): return p.aug == "kindling") and not x.picks.kaede.any(func(p): return p.aug == "keen")
	var held := Expedition.new().begin("lotus", 1)
	held.step(Vector2i(0, 0))
	var slotted := [{"aug": "keen", "skill": 0, "locked": false}]
	held.offer_pick({"kaede": {"skills": Data.hero("kaede").skills, "augs": slotted}})
	var stacked: float = held.pick_preview({"aug": "keen", "skill": 0}).power
	var bare := Expedition.new().begin("lotus", 1)
	var plain := Battle.card_unit(col, "brann", b)
	var kept: Array = plain.skills
	bare.fit_out(plain, col.by("brann"))
	x.offer_pick(kit)
	var had := x.embers
	var share := x.skip_share()
	x.skip_pick()
	var both: float = Data.apply_augs(Data.hero("kaede").skills, [{"aug": "keen", "skill": 0}, {"aug": "keen", "skill": 0}])[0].power
	return [is_equal_approx(stacked, both) and hits and refused and swapped and plain.skills == kept and share > 0 and x.embers == had + share and x.pick_now.is_empty(),
		"Foxfire Lance power %.3f → %.3f · full hero refused without a choice · skip +%d" % [base, u.skills[0].power, share]]


func _b_forecast_crop() -> Array:
	var bad := []
	for h in Data.HEROES:
		var ts: Vector2 = load(h.portrait.src).get_size()
		var tile := Forge.crop(ts, Vector2(152, 112), h.portrait, 0.62, "tile")
		var face := Forge.crop(ts, BattleScreen.HEAD_SIZE, h.portrait, 0.85, "tile")
		if h.portrait.get("crops", {}).has("face") or not face.size.is_equal_approx(tile.size) and h.portrait.get("crops", {}).has("tile"):
			bad.append(h.name)
	return [bad.is_empty(), "%d heroes · %s" % [Data.HEROES.size(), ", ".join(bad) if bad.size() else "all share the tile crop"]]
