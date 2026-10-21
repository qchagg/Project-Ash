class_name App
extends Control
## The game's root: owns the collection and switches between screens.
## Roster → a hero (character view, sheet below, swipe for the next), each built from the Forge kit.

var col := Collection.new()
## The town between fights; kept for the session while you move between tabs.
var town := Town.new()
## The roster's element filter, kept while you visit a hero.
var filter := ""
## Each hero's zoom on the character view (0 full body, 1 face), kept between visits.
var zoom := {}
var _screen: Control


func _ready() -> void:
	Forge.setup()
	_showcase()
	var bg := ColorRect.new()
	bg.color = Forge.INK
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	show_roster()


## Playtest only: Varuni's starter card is a 4★ Ashcrown so the top tier can be seen without grinding.
## The rules and checks build their own collections, so they are unaffected.
func _showcase() -> void:
	var c := col.by("ilse")
	if not c.is_empty():
		c.stars = 4


func show_roster() -> void:
	_open(Roster.new().setup(self))


## The tab bar's destinations.
func show_tab(tab: String) -> void:
	match tab:
		"roster": show_roster()
		"squad": _open(SquadScreen.new().setup(self))
		"town": _open(TownScreen.new().setup(self))
		"battle": _open(BattleScreen.new().setup(self))
		"codex": _open(CodexScreen.new().setup(self))


## A hero opens on the character view; the sheet and evolve pages are below, other heroes a swipe away.
func show_hero(hero_key: String, uid := "", page := 0) -> void:
	_open(HeroPager.new().setup(self, hero_key, uid, page))


func _open(screen: Control) -> void:
	if _screen:
		_screen.queue_free()
	_screen = screen
	screen.set_anchors_preset(PRESET_FULL_RECT)
	add_child(screen)


## The copies of a hero, best first: most stars, then the one on the field.
func copies(hero_key: String) -> Array:
	var out := col.cards.filter(func(c): return c.hero == hero_key)
	out.sort_custom(func(a, b):
		if a.stars != b.stars:
			return a.stars > b.stars
		return (a.uid in col.squad) and not (b.uid in col.squad))
	return out
