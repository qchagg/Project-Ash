class_name MainMenu
extends Control
## Home, the first place after the title: one painting fills the screen and one road is featured on it, with its name, a
## line about it and a single commit. Between runs the roads take turns; on the road it holds on yours. Everything else
## stays quiet: the gold and the sound in the corners, plain links along the foot in place of the nav.

## How long a road stays featured, in seconds, and how long its words take to change.
const HOLD := 8.0
const WORDS_FADE := 0.25

var app: App
var tab := "menu"
## The roads on show, the one featured now, and how long it has been there.
var _keys: Array = []
var _at := 0
var _t := 0.0
var _art_layer: Control
var _air_layer: Control
var _words: VBoxContainer
var _dots: Control


func setup(a: App) -> MainMenu:
	app = a
	return self


## The roads home features: the one you're on, or all of them between runs.
static func slides(on_road: String) -> Array:
	return [on_road] if on_road != "" else Expedition.ROADS.keys()


func _ready() -> void:
	clip_contents = true
	var wide := Forge.wide()
	_keys = slides(app.run.road if app.run else "")
	_at = randi() % _keys.size()
	_art_layer = _layer()
	# The painting stays bright where the road is and falls away under the words.
	if wide:
		add_child(Forge.wash(Color(Forge.INK, 0.94), Vector2(0.0, 0.5), Vector2(0.62, 0.5)))
	add_child(Forge.wash(Color(Forge.INK, 0.96), Vector2(0.5, 1.0), Vector2(0.5, 0.74 if wide else 0.4)))
	_air_layer = _layer()
	var m := Forge.margins(MarginContainer.new(), 56 if wide else 44, 18 if wide else 40, 40 if wide else 44, 18 if wide else 40)
	m.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(m)
	m.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var col := Forge.vbox(0)
	col.mouse_filter = MOUSE_FILTER_IGNORE
	m.add_child(col)
	col.add_child(_top())
	var above := _gap()
	# A phone's words sit low, where the painting falls to dark; a wide screen keeps them in the middle.
	above.size_flags_stretch_ratio = 1.0 if wide else 4.0
	col.add_child(above)
	_words = Forge.vbox(8)
	_words.mouse_filter = MOUSE_FILTER_IGNORE
	col.add_child(_words)
	var go := Forge.studs("continue" if app.run else "set out", true, 56, 22)
	go.custom_minimum_size.x = 190
	go.size_flags_horizontal = SIZE_SHRINK_BEGIN if wide else SIZE_SHRINK_CENTER
	go.pressed.connect(_go)
	var space := Control.new()
	space.custom_minimum_size.y = 26
	col.add_child(space)
	col.add_child(go)
	if _keys.size() > 1:
		col.add_child(_dot_row())
	col.add_child(_gap())
	col.add_child(NavBar.links(app, "menu"))
	_show()
	# The app builds the nav after this screen comes in; home has its own links.
	app.show_nav.call_deferred(false)


func _layer() -> Control:
	var c := Control.new()
	c.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(c)
	c.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	return c


func _gap() -> Control:
	var g := Control.new()
	g.size_flags_vertical = SIZE_EXPAND_FILL
	g.mouse_filter = MOUSE_FILTER_IGNORE
	return g


func _process(delta: float) -> void:
	if _keys.size() < 2:
		return
	_t += delta
	if _t >= HOLD:
		_feature((_at + 1) % _keys.size())


## The corners: what you hold, and the sound.
func _top() -> Control:
	var row := Forge.hbox(10)
	var gold := Forge.glyph("gold", 22, Forge.GOLD_LIGHT)
	gold.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(gold)
	var n := Forge.label(str(app.town.embers), 20, Forge.PARCHMENT, Forge.SANS_BOLD)
	n.size_flags_horizontal = SIZE_EXPAND_FILL
	n.size_flags_vertical = SIZE_SHRINK_CENTER
	_readable(n)
	row.add_child(n)
	row.add_child(Forge.sound_toggle())
	return row


## Small diamonds, one a road; the lit one is on show, and a tap goes to another.
func _dot_row() -> Control:
	var step := 26.0
	_dots = Control.new()
	_dots.custom_minimum_size = Vector2(step * _keys.size(), 34)
	_dots.size_flags_horizontal = SIZE_SHRINK_BEGIN if Forge.wide() else SIZE_SHRINK_CENTER
	_dots.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	_dots.draw.connect(func():
		for i in _keys.size():
			Forge.diamond(_dots, Vector2(step * (i + 0.5), 22), 5, Forge.GOLD_LIGHT if i == _at else Color(Forge.PARCHMENT, 0.4), i == _at))
	_dots.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			_feature(clampi(int(e.position.x / step), 0, _keys.size() - 1)))
	return _dots


## Changes the road on show: its words fade through, and its painting comes in over the last.
func _feature(i: int) -> void:
	_t = 0.0
	if i == _at:
		return
	_at = i
	if _dots:
		_dots.queue_redraw()
	var tw := create_tween()
	tw.tween_property(_words, "modulate:a", 0.0, WORDS_FADE)
	tw.tween_callback(_show)
	tw.tween_property(_words, "modulate:a", 1.0, WORDS_FADE)


func _show() -> void:
	var r: Dictionary = Expedition.ROADS[_keys[_at]]
	for old in _art_layer.get_children():
		get_tree().create_timer(Painted.FADE + 0.1).timeout.connect(old.queue_free)
	var art := Painted.new().setup(r.art, BattleScreen.SCENE)
	_art_layer.add_child(art)
	art.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for c in _air_layer.get_children():
		c.queue_free()
	var air := Weather.over(r.art)
	if air:
		_air_layer.add_child(air)
		air.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for c in _words.get_children():
		_words.remove_child(c)
		c.queue_free()
	var wide := Forge.wide()
	var where := Forge.sc("on the road" if app.run else Data.REGIONS[r.region].name, 18, Forge.GOLD)
	var name := Forge.sc(r.name, 54 if wide else 44, Forge.PARCHMENT, true, 0.06)
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.custom_minimum_size.x = 900 if wide else 632
	var about := Forge.label(r.about, 22, Forge.PARCHMENT, Forge.SANS_ITALIC)
	about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	about.custom_minimum_size.x = 580 if wide else 632
	for l in [where, name, about]:
		_readable(l)
		if not wide:
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_words.add_child(l)


## Words over a painting: a soft dark edge keeps them readable on any of them.
func _readable(l: Label) -> void:
	l.add_theme_color_override("font_outline_color", Color(Forge.INK, 0.7))
	l.add_theme_constant_override("outline_size", 5)


## The commit: back to the road, or to the road on show, ready to set out on it.
func _go() -> void:
	if not app.run:
		app.road_pick = _keys[_at]
	app.show_tab("expedition")
