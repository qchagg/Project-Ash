class_name Expedition
extends RefCounted
## An expedition: one run down a branching road, like Honkai: Star Rail's Simulated Universe. The road is a map of
## layers; each step you pick one of the nodes the last one leads to. Fights wear the squad down (HP carries from fight
## to fight), camps patch them up, boons make them stronger for the rest of the run, and a warden waits at the end.
## Embers gathered on the road are banked in the town when the run ends: all of them on a win or a turn for home, half
## if the squad falls.

## Where you can go. `danger` scales the foes and the rewards; `elem` is the road's home element.
const ROADS := {
	"basalt": {"name": "The Basalt Steps", "region": "hraunvald", "elem": "earth", "danger": 1, "depth": 7,
		"about": "Black stairs cut into a cooling lava field. The golems that guard them were masons once."},
	"ghats": {"name": "The Drowned Ghats", "region": "jaladesh", "elem": "water", "danger": 2, "depth": 8,
		"about": "River steps that go down further than the river does. Lamps still float where the shrines sank."},
	"saltglass": {"name": "The Saltglass Road", "region": "marusthal", "elem": "fire", "danger": 3, "depth": 9,
		"about": "A caravan road fused to glass by an old fire. It still shows the footprints of the people who ran."},
}

## Each road's home foe, always among the fights there.
const HOME_FOE := {"earth": "golem", "water": "caller", "fire": "seer", "wind": "blade"}

## What a node is. Weights pick the middle of the road; the first layer is always fights, the warden is always last
## and a camp always comes before it.
const NODES := {
	"battle": {"name": "Skirmish", "icon": "node_battle", "weight": 40, "about": "A fight. Win to go on, and bring the embers home."},
	"elite": {"name": "Elite", "icon": "node_elite", "weight": 12, "about": "A harder fight, with a rarer boon for the winner."},
	"rest": {"name": "Camp", "icon": "node_rest", "weight": 11, "about": "Rest: the squad heals. A higher Infirmary heals more."},
	"boon": {"name": "Boon", "icon": "node_boon", "weight": 15, "about": "Choose one of three blessings for the rest of the run."},
	"cache": {"name": "Cache", "icon": "node_cache", "weight": 11, "about": "Something left on the road: embers, sometimes an augment."},
	"trial": {"name": "Trial", "icon": "node_trial", "weight": 11, "about": "A test on the road. A hero rolls d20 on an aptitude; succeed for a reward."},
	"boss": {"name": "Warden", "icon": "node_boss", "weight": 0, "about": "The road's warden. Beat them to finish the expedition."},
}

const RARITIES := ["common", "rare", "epic", "legendary"]
## How likely each rarity is from a plain boon node; elites and wardens shift it up one step.
const RARITY_WEIGHTS := [60, 28, 10, 2]

## Blessings for the run. `amount` is the bonus at each rarity, common to legendary.
const BOONS := {
	"whetstone": {"name": "Whetstone", "stat": "atk", "amount": [0.06, 0.10, 0.15, 0.24], "about": "Attack +%d%% for the whole squad."},
	"bulwark": {"name": "Bulwark", "stat": "def", "amount": [0.08, 0.13, 0.20, 0.30], "about": "Defense +%d%% for the whole squad."},
	"fleetfoot": {"name": "Fleetfoot", "stat": "spd", "amount": [0.05, 0.08, 0.12, 0.18], "about": "Speed +%d%% for the whole squad."},
	"heartwood": {"name": "Heartwood", "stat": "max_hp", "amount": [0.08, 0.12, 0.18, 0.28], "about": "Max health +%d%% for the whole squad."},
	"kinfire": {"name": "Kinfire", "stat": "atk_elem", "amount": [0.10, 0.16, 0.24, 0.36], "about": "Heroes of the road's element: attack +%d%%."},
	"tithe": {"name": "Pilgrim's Tithe", "stat": "embers", "amount": [0.10, 0.18, 0.28, 0.45], "about": "Embers found on this road +%d%%."},
}

## Embers per node at danger 1; more danger, more embers.
const PURSE := {"battle": 40, "elite": 80, "boss": 160, "cache": 50, "trial": 45}
## Share of max health a camp restores, by Infirmary level (0 = no Infirmary yet).
const CAMP_HEAL := [0.30, 0.40, 0.50, 0.60, 0.75, 1.00]
## A trial's difficulty: roll d20 (+3 on a favored aptitude) at least this.
const TRIAL_DC := 12

var road := ""
var run_seed := 0
## layers[i] is an array of nodes {type, rarity, x (0..1 across the road), next (indices into layer i + 1)}.
var layers: Array = []
## The node you stand on (layer, index); layer -1 before the first step.
var at := Vector2i(-1, -1)
## Each card's health as a share of its max (missing = full). 0 means fallen for the rest of the run.
var hp := {}
var boons: Array = []
var embers := 0
## "" while the road goes on, then "win", "lose" or "home" (turned back).
var over := ""
var _rng := RandomNumberGenerator.new()


## A new run down `road_key`, its map drawn from `seed_value`.
func begin(road_key: String, seed_value: int) -> Expedition:
	road = road_key
	run_seed = seed_value
	_rng.seed = seed_value
	_draw_map()
	return self


func info() -> Dictionary:
	return ROADS[road]


## The road's layers: two or three nodes across, a camp before the warden, the warden alone at the end.
func _draw_map() -> void:
	layers = []
	var depth: int = ROADS[road].depth
	for i in depth:
		var n := 1 if i == depth - 1 else (2 if i == 0 or i == depth - 2 else 2 + _rng.randi() % 2)
		var layer := []
		for j in n:
			var t := "boss" if i == depth - 1 else ("rest" if i == depth - 2 else ("battle" if i == 0 else _pick_type(i)))
			layer.append({"type": t, "rarity": _roll_rarity(t), "x": (j + 0.5) / n, "next": []})
		layers.append(layer)
	# Each node leads to the nearest node ahead, sometimes a neighbour too; nothing ahead is left unreachable.
	for i in depth - 1:
		var here: Array = layers[i]
		var ahead: Array = layers[i + 1]
		for node in here:
			var best := _nearest(ahead, node.x)
			node.next.append(best)
			var side := best + (1 if node.x > ahead[best].x else -1)
			if side >= 0 and side < ahead.size() and _rng.randf() < 0.45:
				node.next.append(side)
		for k in ahead.size():
			if not here.any(func(nd): return k in nd.next):
				here[_nearest(here, ahead[k].x)].next.append(k)
		for node in here:
			node.next.sort()


func _nearest(layer: Array, x: float) -> int:
	var best := 0
	for k in layer.size():
		if absf(layer[k].x - x) < absf(layer[best].x - x):
			best = k
	return best


func _pick_type(layer_i: int) -> String:
	var pool := []
	for k in NODES:
		if k == "boss" or (k in ["elite", "rest"] and layer_i < 2):
			continue
		pool.append(k)
	var total := 0
	for k in pool:
		total += NODES[k].weight
	var roll := _rng.randi() % total
	for k in pool:
		roll -= NODES[k].weight
		if roll < 0:
			return k
	return "battle"


## A rarity for what a node gives: elites and wardens give one step better.
func _roll_rarity(t: String) -> int:
	var roll := _rng.randi() % 100
	var r := 0
	var acc := 0
	for i in RARITY_WEIGHTS.size():
		acc += RARITY_WEIGHTS[i]
		if roll < acc:
			r = i
			break
	if t in ["elite", "boss"]:
		r = mini(r + 1, RARITIES.size() - 1)
	return r


func node(p: Vector2i) -> Dictionary:
	return layers[p.x][p.y]


## The nodes you can step to next.
func choices() -> Array:
	if over != "":
		return []
	if at.x < 0:
		var out := []
		for j in layers[0].size():
			out.append(Vector2i(0, j))
		return out
	if at.x >= layers.size() - 1:
		return []
	return node(at).next.map(func(j): return Vector2i(at.x + 1, j))


func can_step(p: Vector2i) -> bool:
	return p in choices()


## Step onto a node. What happens there is up to the screen: a fight, a camp, a boon choice.
func step(p: Vector2i) -> bool:
	if not can_step(p):
		return false
	at = p
	return true


# ---------- fights ----------

## The foes a fight node sends, and how much tougher than base they are.
func foes_for(p: Vector2i) -> Dictionary:
	var t: String = node(p).type
	var danger: int = ROADS[road].danger
	var home: String = HOME_FOE[ROADS[road].elem]
	var others: Array = ["golem", "blade", "caller", "seer"].filter(func(k): return k != home)
	var r := RandomNumberGenerator.new()
	r.seed = run_seed * 31 + p.x * 7 + p.y
	for i in range(others.size() - 1, 0, -1):
		var j := r.randi() % (i + 1)
		var tmp = others[i]
		others[i] = others[j]
		others[j] = tmp
	var count: int = {"battle": 2 if p.x < 2 else 3, "elite": 3, "boss": 4}[t]
	var keys := [home] + others.slice(0, count - 1)
	var scale: float = 1.0 + 0.12 * (danger - 1) + 0.04 * p.x + {"battle": 0.0, "elite": 0.2, "boss": 0.35}[t]
	return {"keys": keys, "scale": snappedf(scale, 0.01)}


## After a fight: the survivors' health carries on; the fallen stay down for the run. A loss ends the expedition.
func finish_fight(won: bool, health: Dictionary) -> void:
	for uid in health:
		hp[uid] = clampf(health[uid], 0.0, 1.0)
	if not won:
		over = "lose"
		return
	embers += purse(node(at).type)
	if node(at).type == "boss":
		over = "win"


func health(uid: String) -> float:
	return hp.get(uid, 1.0)


func fallen(uid: String) -> bool:
	return health(uid) <= 0.0


# ---------- the other nodes ----------

## Embers a node pays, with the road's danger and any Tithe.
func purse(t: String) -> int:
	var base: int = PURSE.get(t, 0)
	return roundi(base * (1.0 + 0.35 * (ROADS[road].danger - 1)) * (1.0 + bonus("embers")))


## A camp: everyone standing heals a share of their max health. The fallen don't get up.
func rest(infirmary_level: int) -> float:
	var share: float = CAMP_HEAL[clampi(infirmary_level, 0, CAMP_HEAL.size() - 1)]
	for uid in hp:
		if hp[uid] > 0.0:
			hp[uid] = minf(1.0, hp[uid] + share)
	return share


## Three different boons at the node's rarity.
func offers(p: Vector2i) -> Array:
	var r := RandomNumberGenerator.new()
	r.seed = run_seed * 53 + p.x * 11 + p.y
	var keys: Array = BOONS.keys()
	for i in range(keys.size() - 1, 0, -1):
		var j := r.randi() % (i + 1)
		var tmp = keys[i]
		keys[i] = keys[j]
		keys[j] = tmp
	return keys.slice(0, 3).map(func(k): return {"key": k, "rarity": node(p).rarity})


func take(boon: Dictionary) -> void:
	boons.append(boon)


## The run's total bonus to a stat from its boons (0.1 = +10%).
func bonus(stat: String) -> float:
	var total := 0.0
	for b in boons:
		if BOONS[b.key].stat == stat:
			total += BOONS[b.key].amount[b.rarity]
	return total


static func boon_text(b: Dictionary) -> String:
	return BOONS[b.key].about % roundi(BOONS[b.key].amount[b.rarity] * 100)


## A cache: embers, scaled by the node's rarity. Rare or better also leaves an augment (the screen picks which).
func open_cache() -> Dictionary:
	var n := roundi(purse("cache") * (1.0 + 0.5 * node(at).rarity))
	embers += n
	return {"embers": n, "augment": node(at).rarity >= 1}


## A trial: a d20 roll, +3 when the aptitude is one the hero favors. Success pays the trial's purse.
func trial(roll: int, favored: bool) -> bool:
	var ok := roll + (Data.FAVORED_BONUS if favored else 0) >= TRIAL_DC
	if ok:
		embers += purse("trial")
	return ok


## The aptitude a trial node tests, fixed per node.
func trial_aptitude(p: Vector2i) -> String:
	var keys: Array = Data.APTITUDES.keys()
	return keys[(run_seed + p.x * 5 + p.y * 3) % keys.size()]


## Turn for home with what you've gathered.
func head_home() -> void:
	if over == "":
		over = "home"


## The embers the town receives when the run ends: all of them, or half if the squad fell.
func banked() -> int:
	return embers / 2 if over == "lose" else embers


## Applies the run's boons to a unit about to fight.
func boost(u: Dictionary) -> void:
	for stat in ["atk", "def", "spd", "max_hp"]:
		var k := bonus(stat)
		if stat == "atk" and u.elem == ROADS[road].elem:
			k += bonus("atk_elem")
		if k > 0.0:
			u[stat] = roundi(u[stat] * (1.0 + k))
	u.hp = u.max_hp
