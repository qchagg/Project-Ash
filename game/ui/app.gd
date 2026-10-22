class_name App
extends Control
## The game's root: owns the collection, the town and the expedition on the road, and switches between screens.
## The nav (Heroes · Expedition · Town) belongs to the app, not the screens: a bar along the foot, or a rail down the
## left on a wide screen. Screens fill the space beside it; a screen with no `tab` (a hero's pages) takes it all.

const VERSION := "v0.45"

var col := Collection.new()
## The town between expeditions; kept for the session while you move between tabs.
var town := Town.new()
## The expedition on the road, or null between runs.
var run: Expedition
## The roster's element filter, kept while you visit a hero.
var filter := ""
## Each hero's zoom on the character view (0 full body, 1 face), kept between visits.
var zoom := {}
var nav: Control
var _frame: BoxContainer
var _content: Control
var _screen: Control


func _ready() -> void:
	Forge.setup()
	_showcase()
	var bg := ColorRect.new()
	bg.color = Forge.INK
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_frame = Forge.hbox(0) if Forge.wide() else Forge.vbox(0)
	_frame.set_anchors_preset(PRESET_FULL_RECT)
	add_child(_frame)
	_content = Control.new()
	_content.size_flags_horizontal = SIZE_EXPAND_FILL
	_content.size_flags_vertical = SIZE_EXPAND_FILL
	_frame.add_child(_content)
	show_tab("expedition")
	_deep_link.call_deferred()


## Playtest shortcut: a link ending #event-boon (or camp, cache, trial, fight, warden) starts a run and steps straight
## onto that kind of stop, so a reviewer can see each one without walking the road. #town and #heroes open those tabs.
func _deep_link() -> void:
	if not OS.has_feature("web"):
		return
	var hash := str(JavaScriptBridge.eval("location.hash", true)).trim_prefix("#")
	if hash in ["town", "heroes"]:
		show_tab(hash)
		return
	if not hash.begins_with("event-"):
		return
	var want: String = {"camp": "rest", "fight": "battle", "warden": "boss"}.get(hash.trim_prefix("event-"), hash.trim_prefix("event-"))
	for sd in 200:
		var x := Expedition.new().begin("ghats", sd)
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


## Playtest only: Varuni's starter card is a 4★ so the top tier can be seen without grinding.
## The rules and checks build their own collections, so they are unaffected.
func _showcase() -> void:
	var c := col.by("ilse")
	if not c.is_empty():
		c.stars = 4


func show_roster() -> void:
	_open(Roster.new().setup(self))


## The nav's destinations, and the places inside them (the party, the archive) that other screens link to.
func show_tab(tab: String) -> void:
	match tab:
		"heroes", "roster": show_roster()
		"expedition": _open(ExpeditionScreen.new().setup(self))
		"party", "squad": _open(SquadScreen.new().setup(self))
		"town": _open(TownScreen.new().setup(self))
		"codex", "archive": _open(CodexScreen.new().setup(self))


## A hero opens on the character view; the sheet and evolve pages are below, other heroes a swipe away.
func show_hero(hero_key: String, uid := "", page := 0) -> void:
	_open(HeroPager.new().setup(self, hero_key, uid, page))


## Into a fight at the expedition's current node.
func show_fight() -> void:
	_open(BattleScreen.new().setup(self))


func _open(screen: Control) -> void:
	if _screen:
		_screen.queue_free()
	_screen = screen
	_content.add_child(screen)
	screen.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	if nav:
		nav.queue_free()
		nav = null
	var tab: String = screen.get("tab") if screen.get("tab") != null else ""
	if tab == "" and Forge.wide():
		# A hero's pages are built for a phone: on a wide screen they stand as a column in the middle.
		var side := maxf(0.0, (size.x - 720.0) / 2.0)
		screen.offset_left = side
		screen.offset_right = -side
	if tab != "":
		nav = NavBar.make(self, tab)
		_frame.add_child(nav)
		if Forge.wide():
			_frame.move_child(nav, 0)


## Hide the nav while a fight is on: nothing in it is needed mid-battle.
func show_nav(on: bool) -> void:
	if nav:
		nav.visible = on


## The copies of a hero, best first: most stars, then the one on the field.
func copies(hero_key: String) -> Array:
	var out := col.cards.filter(func(c): return c.hero == hero_key)
	out.sort_custom(func(a, b):
		if a.stars != b.stars:
			return a.stars > b.stars
		return (a.uid in col.squad) and not (b.uid in col.squad))
	return out
