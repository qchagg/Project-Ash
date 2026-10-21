class_name App
extends Control
## The game's root: owns the collection and switches between screens.
## Roster → hero sheet → character view, each built from the Forge kit.

var col := Collection.new()
## The roster's element filter, kept while you visit a hero.
var filter := ""
var _screen: Control


func _ready() -> void:
	Forge.setup()
	var bg := ColorRect.new()
	bg.color = Forge.INK
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	show_roster()


func show_roster() -> void:
	_open(Roster.new().setup(self))


func show_hero(hero_key: String, uid := "") -> void:
	_open(HeroSheet.new().setup(self, hero_key, uid))


func show_character(hero_key: String, uid: String) -> void:
	_open(CharacterView.new().setup(self, hero_key, uid))


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
