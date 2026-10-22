extends SceneTree
## Acceptance checks, ported from the sandbox's CHECKS. Run with tools/godot-checks.sh.
## Each check returns [pass, detail]; the process exits 1 if any fail.


func _init() -> void:
	var checks := [
		["Cards · best-of merge: two 1★ copies make a 2★ with the higher of each stat +10%; the fodder augment carries and is set", _best_merge],
		["Cards · sum merge: stats add up, like the Undine example", _sum_merge],
		["Cards · a fodder augment with no matching skill goes loose", _fodder_loose],
		["Cards · free augments swap until a merge; set ones stay put", _swap_until_merge],
		["Cards · only the same star level merges, 3★ is the cap, and an Ashcrown makes a 4★", _star_rules],
		["Cards · the seeded collection rolls the same stats as the sandbox", _seeded_rolls],
		["Augments · Keen and Wellspring add up; Lingering does not and stun caps at 2; Hasten stops at cooldown 1; Kindling adds Burn", _aug_math],
		["Elements · four-way cycle: each element beats one, loses to one, and is neutral with its opposite", _four_way],
		["Visuals · augments name the skill and pick the aura: most augments wins, ties go to the first slotted", _aura_names],
		["Celerity · fits damage, heal and shield skills, renames with Fleet, and marks the skill as an opener", _celerity_fits],
		["Squad · formation: placing moves a card, a taken tile swaps, off-grid and benched cards are refused, a joining card never stacks", _formation],
		["Regions · every hero's home is a region with a dark and a light colorway and its own sigil", _regions],
		["Lore · thirty archetypes, every region has two or more, every element at least seven, each linked hero exists", _archetypes],
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
		["Plan · a hero steps then acts: Brann steps to the front row and Rockfall lands, though he planned it from the second row", _b_step_then_act],
		["Plan · queue order holds: Varuni's heal lands on Sorrel before he steps away; he then casts from his new tile", _b_step_order],
		["Plan · steps reach 2 tiles, never onto a unit or a tile another hero has claimed; stepping home cancels", _b_step_tiles],
		["Forecast · matches what the action then does, target by target, and changes nothing in the fight", _b_forecast],
		["Forecast · counts the chain the skill would carry at the back of the queue, and marks a knockout", _b_forecast_chain],
		["Intents · each foe's preview is the action and area it then uses when nothing changes first", _b_intents],
		["Crops · a crop set for one view wins there, and every other view keeps the eye-line rule", _b_crop_override],
		["Expedition · every road is connected start to warden, with a camp before the warden", _x_map],
		["Expedition · fights send the road's home foe, more and tougher further down the road", _x_foes],
		["Expedition · health carries between fights, camps heal the standing, the fallen stay down", _x_health],
		["Expedition · boons stack by rarity and boost the squad; a loss banks half the embers", _x_boons],
		["Expedition · a fight can field only the named foes, scaled", _x_battle_subset],
	]
	var failed := 0
	for i in checks.size():
		var r: Array = checks[i][1].call()
		if not r[0]:
			failed += 1
		print("[check %d] %s %s: %s" % [i + 1, "PASS" if r[0] else "FAIL", checks[i][0], r[1]])
	print("%d/%d passed" % [checks.size() - failed, checks.size()])
	quit(1 if failed else 0)


func _other(col: Collection, hero: String, not_uid: String) -> Dictionary:
	for c in col.cards:
		if c.hero == hero and c.uid != not_uid:
			return c
	return {}


func _best_merge() -> Array:
	var col := Collection.new()
	var k1 := col.by("kaede")
	var k2 := _other(col, "kaede", "kaede")
	col.slot_aug(k2.uid, 0, "keen")
	var want := {}
	for s in Data.STATS:
		want[s] = roundi(maxi(k1.base[s], k2.base[s]) * 1.1)
	var r := col.merge("kaede", k2.uid)
	var got := col.stats(k1)
	var ok: bool = r.ok and k1.stars == 2 and got == want and col.by(k2.uid).is_empty() \
		and k1.augs.size() == 1 and k1.augs[0].aug == "keen" and k1.augs[0].skill == 0 and k1.augs[0].locked and not "keen" in col.loose
	return [ok, "2★ Surya %s (expected %s)" % [got, want]]


func _sum_merge() -> Array:
	var col := Collection.new()
	col.merge_mode = "sum"
	var i1 := col.by("ilse")
	var i2 := _other(col, "ilse", "ilse")
	var a := col.stats(i1)
	var b := col.stats(i2)
	col.merge("ilse", i2.uid)
	var got := col.stats(i1)
	var ok: bool = i1.stars == 2
	for s in Data.STATS:
		ok = ok and got[s] == a[s] + b[s]
	return [ok, "(%d ATK, %d HP) + (%d ATK, %d HP) = (%d ATK, %d HP)" % [a.atk, a.max_hp, b.atk, b.max_hp, got.atk, got.max_hp]]


func _fodder_loose() -> Array:
	var col := Collection.new()
	var ilse := _other(col, "ilse", "ilse")
	col.slot_aug(ilse.uid, 1, "wellspring")
	var before := col.loose.count("wellspring")
	col.merge("kaede", ilse.uid)
	var after := col.loose.count("wellspring")
	return [before == 0 and after == 1 and col.by("kaede").augs.is_empty(), "Wellspring loose: %d before, %d after" % [before, after]]


func _swap_until_merge() -> Array:
	var col := Collection.new()
	var slotted := col.slot_aug("kaede", 0, "keen")
	var free_out := col.unslot_aug("kaede", 0)
	var back := col.slot_aug("kaede", 0, "keen")
	var full := col.slot_aug("kaede", 1, "hasten")   # 1★ holds one augment
	col.merge("kaede", _other(col, "kaede", "kaede").uid)
	var set_out := col.unslot_aug("kaede", 0)
	var second := col.slot_aug("kaede", 1, "hasten")
	var second_out := col.unslot_aug("kaede", 1)
	var ok: bool = slotted and free_out and back and not full and not set_out and second and second_out
	return [ok, "slot %s, unslot %s, 2nd on a 1★ %s · after merge: unslot set %s, new slot %s, unslot it %s" % [slotted, free_out, full, set_out, second, second_out]]


func _star_rules() -> Array:
	var col := Collection.new()
	var kc := col.cards.filter(func(c): return c.hero == "kaede")
	var ic := col.cards.filter(func(c): return c.hero == "ilse")
	col.merge(kc[0].uid, kc[1].uid)
	var mixed: bool = col.merge(kc[0].uid, kc[2].uid).ok   # 2★ + 1★
	col.merge(ic[0].uid, ic[1].uid)
	col.merge(kc[0].uid, ic[0].uid)
	var three: int = kc[0].stars
	var k3 := col.new_card("kaede", true)
	k3.stars = 3
	col.cards.append(k3)
	var past: bool = col.merge(kc[0].uid, k3.uid).ok
	var crowned := col.crown(kc[0].uid)
	var again := col.crown(k3.uid)
	var ok: bool = not mixed and three == 3 and not past and crowned and kc[0].stars == 4 and not again and col.crowns == 0
	return [ok, "2★+1★ %s · reached %d★ · 3★+3★ %s · crown %s → %d★ · second crown %s" % [mixed, three, past, crowned, kc[0].stars, again]]


# Values printed by the sandbox's newCollection() with seed 7; a drift here means the port's dice changed.
func _seeded_rolls() -> Array:
	var col := Collection.new()
	var got := {}
	for c in col.cards:
		got[c.uid] = [c.base.max_hp, c.base.atk, c.base.def, c.base.spd]
	var want := SEEDED
	return [got == want, str(got)]


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
	var ok := Lore.ARCHETYPES.size() == 30
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


const SEEDED := {"kaede": [820, 150, 40, 92], "brann": [1400, 100, 95, 70], "sorrel": [900, 135, 45, 105], "ilse": [850, 95, 50, 88],
	"rock": [1500, 115, 85, 60], "leaf": [950, 145, 40, 110],
	"kaede-1": [700, 169, 37, 84], "kaede-2": [880, 151, 38, 99], "ilse-3": [920, 96, 53, 92], "ilse-4": [930, 88, 48, 93],
	"brann-5": [1480, 87, 100, 69], "sorrel-6": [1010, 147, 40, 105]}


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
	var x := Expedition.new().begin("ghats", 7)
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


func _x_battle_subset() -> Array:
	var b := Battle.new()
	b.start(b.pristine_heroes(), {}, ["golem", "seer"], 1.5)
	var foes := b.units.filter(func(u): return u.side == "E")
	var golem := b.unit("E-golem")
	return [foes.size() == 2 and golem.max_hp == 2250 and golem.hp == 2250 and golem.atk == 173, "%d foes · golem %d hp, %d atk" % [foes.size(), golem.max_hp, golem.atk]]
