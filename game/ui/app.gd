class_name App
extends Control
## The game's root: owns the collection, the town and the expedition on the road, and switches between screens.
## The nav (the row of places along the foot) belongs to the app, not the screens: a bar along the foot, or a rail down the
## left on a wide screen. Screens fill the space beside it; a screen with no `tab` (a hero's pages) takes it all.

const VERSION := "v0.75"
## Moving between screens: how long the new one takes to come in, and how far it rises as it does.
const FADE := 0.2
const RISE := 18.0
## How long the stroke of ink takes to cross when moving between places.
const WIPE := 0.5
const INK_WIPE: Shader = preload("res://ui/ink_wipe.gdshader")
## How dark the scene sits behind a place, against home's full light, and how slowly one road's scene gives way to the next.
const SCENE_DIM := 0.6
const SCENE_FADE := 1.8

var col := Collection.new()
## The town between expeditions; kept for the session while you move between tabs.
var town := Town.new()
## The expedition on the road, or null between runs.
var run: Expedition
## The roster's element filter, kept while you visit a hero.
var filter := ""
## The road home last sent you to, for the road choice to open on ("" for none).
var road_pick := ""
## The road chosen on the road choice, while the party lines up to set out on it ("" otherwise).
var setting_out := ""
## The road home has on show, or the road you're on. Its painting and air stand behind every place, and off the road
## its music plays everywhere, so moving between places never changes the scene.
var scene_road := ""
## The painting the scene shows: the road's own, or a starred hero's home that home is featuring.
var scene_art := ""
## The heroes you have starred on the heroes screen, which home features between the roads.
var starred: Array = []
## Each hero's zoom on the character view (0 full body, 1 face), kept between visits.
var zoom := {}
var nav: Control
var _frame: BoxContainer
var _content: Control
var _screen: Control
var _scene: Control
var _scene_dim: ColorRect


func _ready() -> void:
	Forge.setup()
	Sfx.warm()
	Music.warm()
	Clips.fetch_all(self)
	Music.fetch_all(self)
	showcase()
	var bg := ColorRect.new()
	bg.color = Forge.INK
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_scene = Control.new()
	_scene.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_scene)
	_scene.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_scene_dim = ColorRect.new()
	_scene_dim.color = Color(Forge.INK, 0.0)
	_scene_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_scene_dim)
	_scene_dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	set_scene(Expedition.ROADS.keys().pick_random())
	_frame = Forge.vbox(0)
	_frame.set_anchors_preset(PRESET_FULL_RECT)
	add_child(_frame)
	_content = Control.new()
	_content.size_flags_horizontal = SIZE_EXPAND_FILL
	_content.size_flags_vertical = SIZE_EXPAND_FILL
	_frame.add_child(_content)
	show_tab("menu" if _link() == "" else "expedition")
	if _link() == "":
		add_child(TitleScreen.new())
	_deep_link.call_deferred()


## What the page's link ends with after the #, if anything.
func _link() -> String:
	return str(JavaScriptBridge.eval("location.hash", true)).trim_prefix("#") if OS.has_feature("web") else ""


## Playtest shortcut: a link ending #event-boon (or camp, wayside, shrine, fight, warden) starts a run and steps straight
## onto that kind of stop, so a reviewer can see each one without walking the road. #town, #heroes and #graces open those screens.
func _deep_link() -> void:
	var hash := _link()
	if hash in ["town", "heroes", "graces"]:
		show_tab(hash)
		return
	if hash == "event-pick":
		run = Expedition.new().begin("lotus", 7)
		run.step(Vector2i(0, 0))
		run.finish_fight(true, {})
		run.offer_pick(squad_kit())
		_open(ExpeditionScreen.new().setup(self))
		return
	if not hash.begins_with("event-"):
		return
	var want: String = {"camp": "rest", "fight": "battle", "warden": "boss"}.get(hash.trim_prefix("event-"), hash.trim_prefix("event-"))
	for sd in 200:
		var x := Expedition.new().begin("lotus", sd)
		for i in x.layers.size():
			for j in x.layers[i].size():
				if x.layers[i][j].type != want:
					continue
				# Stand on a node that leads here (or at the start), then step.
				if i > 0:
					for k in x.layers[i - 1].size():
						if j in x.layers[i - 1][k].next:
							x.at = Vector2i(i - 1, k)
							break
				run = x
				var screen := ExpeditionScreen.new().setup(self)
				_open(screen)
				await get_tree().process_frame
				screen._go(Vector2i(i, j))
				return


## The music for a slot ("map" or a kind of stop): the road's while a run is on, the shared default otherwise.
## Off the road, the scene's road plays its own theme in every place.
func music(slot := "map") -> void:
	var on_road := run != null and run.over == ""
	if not on_road and scene_road != "":
		Music.play(Expedition.music_for(scene_road, "map"))
		return
	Music.play(Expedition.music_for(run.road if on_road else "", "menu" if slot == "map" and not on_road else slot))


## The squad as hero picks read it: {uid: {skills, augs}}, in squad order.
func squad_kit() -> Dictionary:
	var kit := {}
	for uid in col.squad:
		var c := col.by(uid)
		kit[uid] = {"skills": Data.hero(c.hero).skills, "augs": c.augs}
	return kit


## Playtest only: nothing hands out copies yet, so a few heroes start with stars lit, Varuni at the top tier.
## The rules and checks build their own collections, so they are unaffected.
func showcase() -> void:
	for copy in ["ilse", "ilse", "ilse", "kaede", "kaede", "brann", "sorrel"]:
		col.add_copy(copy)


## Takes a Travel Log milestone. A star goes to the lead hero, or the next hero on the field if they are already full.
func claim_log(i: int) -> void:
	if not town.claim_log(i).get("star", false):
		return
	for uid in col.squad:
		if col.by(uid).stars < Collection.MAX_STARS:
			col.add_copy(col.by(uid).hero)
			return
	town.earn(Collection.SPARE_EMBERS)


func show_roster() -> void:
	_open(Roster.new().setup(self))


## The nav's destinations, and the places inside them (the party, the archive) that other screens link to.
func show_tab(tab: String) -> void:
	match tab:
		"menu": _open(MainMenu.new().setup(self))
		"log": _open(TravelLog.new().setup(self))
		"graces": _open(GracesScreen.new().setup(self))
		"heroes", "roster": show_roster()
		"expedition": _open(ExpeditionScreen.new().setup(self))
		"party", "squad": _open(SquadScreen.new().setup(self))
		"town": _open(TownScreen.new().setup(self))
		"codex", "archive": _open(CodexScreen.new().setup(self))


## A hero opens on the character view; the sheet and evolve pages are below, other heroes a swipe away.
func show_hero(hero_key: String, uid := "", page := 0) -> void:
	# A wide screen lays a hero out side by side; a phone stacks their pages.
	_open(HeroWide.new().setup(self, hero_key, uid, page) if Forge.wide() else HeroPager.new().setup(self, hero_key, uid, page))


## Into a fight at the expedition's current node.
func show_fight() -> void:
	_open(BattleScreen.new().setup(self))


## The music slot of a screen outside the road. A slot with no track falls back like any other.
func _menu_slot(screen: Control) -> String:
	if screen is TownScreen:
		return "town"
	if screen is Roster or screen is HeroPager or screen is HeroWide or screen is SquadScreen:
		return "heroes"
	return "map"


## Swaps in a screen. The old one stops (no input, no clocks) and fades while the new one rises in over it, so moving
## between places reads as a move rather than a cut.
func _open(screen: Control) -> void:
	if _screen:
		var old := _screen
		old.process_mode = Node.PROCESS_MODE_DISABLED
		old.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var out := create_tween()
		out.tween_property(old, "modulate:a", 0.0, FADE * 0.8)
		out.tween_callback(old.queue_free)
		Sfx.play("page")
		if screen.get("tab") and not screen is BattleScreen:
			_ink_wipe()
	_screen = screen
	if not screen is SquadScreen:
		setting_out = ""
	_content.add_child(screen)
	screen.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	if _content.get_child_count() > 1:
		screen.modulate.a = 0.0
		var rise := create_tween().set_parallel()
		rise.tween_property(screen, "modulate:a", 1.0, FADE).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		var settle := screen.position
		screen.position.y += RISE
		rise.tween_property(screen, "position:y", settle.y, FADE * 1.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if run and run.over == "" and (run.road != scene_road or scene_art != Expedition.ROADS[run.road].art):
		set_scene(run.road)
	# Home shows the scene in full light; every other place dims it so what stands on it reads.
	create_tween().tween_property(_scene_dim, "color:a", 0.0 if screen is MainMenu else SCENE_DIM, SCENE_FADE * 0.5)
	var fight := screen is BattleScreen and run != null and run.over == ""
	music(run.stop_kind() if fight else _menu_slot(screen))
	if nav:
		nav.queue_free()
		nav = null
	var tab: String = screen.get("tab") if screen.get("tab") != null else ""
	if tab == "" and Forge.wide() and not screen is HeroWide:
		# A hero's pages are built for a phone: on a wide screen they stand as a column in the middle.
		var side := maxf(0.0, (size.x - 720.0) / 2.0)
		screen.offset_left = side
		screen.offset_right = -side
	if tab != "":
		nav = NavBar.make(self, screen)
		_frame.add_child(nav)


## Puts a road's painting (or `art` in its place) and air behind every place, slowly coming in over the last, and with
## `play` its theme on. Home turns through its slides without `play`, so the music only follows when you leave.
func set_scene(road: String, art := "", play := true) -> void:
	if art == "":
		art = Expedition.ROADS[road].art
	var changed := road != scene_road or art != scene_art
	scene_road = road
	scene_art = art
	if not changed and _scene.get_child_count() > 0:
		return
	for old in _scene.get_children():
		var out := old.create_tween()
		out.tween_property(old, "modulate:a", 0.0, SCENE_FADE)
		out.tween_callback(old.queue_free)
	var layer := Control.new()
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scene.add_child(layer)
	layer.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	layer.add_child(Painted.new().setup(art, BattleScreen.SCENE))
	var air := Weather.over(art)
	if air:
		layer.add_child(air)
	if _scene.get_child_count() > 1:
		layer.modulate.a = 0.0
		layer.create_tween().tween_property(layer, "modulate:a", 1.0, SCENE_FADE).set_trans(Tween.TRANS_SINE)
	if _screen and play:
		music()


## A stroke of ink across the screen, over the change from one place to the next.
func _ink_wipe() -> void:
	var ink := ColorRect.new()
	ink.color = Forge.INK
	ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = INK_WIPE
	ink.material = m
	add_child(ink)
	ink.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var tw := ink.create_tween()
	tw.tween_method(func(p: float): m.set_shader_parameter("progress", p), 0.0, 1.0, WIPE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(ink.queue_free)


## Hide the nav while a fight is on: nothing in it is needed mid-battle.
func show_nav(on: bool) -> void:
	if nav:
		nav.visible = on


## Sets out on the road chosen on the road choice, with the party as it stands.
func set_out() -> void:
	run = Expedition.new().begin(setting_out, randi() % 100000)
	show_tab("expedition")


## A hero's card, in a list so a hero not owned yet comes back empty.
func copies(hero_key: String) -> Array:
	return col.cards.filter(func(c): return c.hero == hero_key)
