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
		["Regions · every hero's home is a region with a dark and a light colorway and its own sigil", _regions],
		["Town · every level costs more than the last, in tens; the Hearth raises the battle reward", _town_costs],
		["Town · nothing rises without the embers or above the Hearth, and a blocked upgrade changes nothing", _town_blocked],
		["Town · buildings stop at their top level; routes open two then one a level; envoys sit in region order", _town_caps],
		["Cards · every portrait crops to Brann's eye line: eyes at the same height, the face the same size", _eye_line],
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
	var broke := t.upgrade("archive")
	var same: bool = t.level("archive") == 0 and t.embers == 0
	t.earn(10000)
	var built := t.upgrade("archive")
	var above := t.upgrade("archive")   # Hearth 1 holds it at 1
	var why := t.blocked("archive")
	var hearth := t.upgrade("hearth")
	var after := t.upgrade("archive")
	var ok: bool = not broke and same and built and not above and why == "Raise the Ashen Hearth first." and hearth and after \
		and t.level("archive") == 2 and t.embers == 10000 - 100 - 320 - 160
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
