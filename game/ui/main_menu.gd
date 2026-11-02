class_name MainMenu
extends Control
## Home, the first place after the title: the menu of places on the left over the app's scene, and on the right a quiet
## line naming what is on show with a diamond for each slide. The scene turns slowly through the roads (on the road it
## holds on yours) with the heroes you have starred woven between them, each standing on their home's painting.
## Whatever is showing when you leave goes with you to every place, its music too.

## How long each slide stays before the next comes in, and how long its words take to change.
const HOLD := 12.0
## A starred hero comes up after every this many roads.
const HERO_EVERY := 2
const WORDS_FADE := 0.4
## How tall a starred hero stands on home, against the screen's height.
const HERO_TALL := Vector2(0.9, 0.62)
## The region's lit sigil beside its name; most of the square is its halo.
const GLOW_PX := 84

var app: App
var tab := "menu"
## What home turns through ({"road": key} or {"hero": key}), the one on show, and how long it has been there.
var _slides: Array = []
var _at := 0
var _t := 0.0
var _words: VBoxContainer
var _dots: Control
var _hero_layer: Control


func setup(a: App) -> MainMenu:
	app = a
	return self


## The roads home features: the one you're on, or all of them between runs.
static func slides(on_road: String) -> Array:
	return [on_road] if on_road != "" else Expedition.ROADS.keys()


## The slides home turns through: the roads, with a starred hero after every HERO_EVERY of them (and any left over at
## the end), so a hero you star comes up soon.
static func weave(roads: Array, heroes: Array) -> Array:
	var out := []
	var left := heroes.duplicate()
	for i in roads.size():
		out.append({"road": roads[i]})
		if (i + 1) % HERO_EVERY == 0 and not left.is_empty():
			out.append({"hero": left.pop_front()})
	for h in left:
		out.append({"hero": h})
	return out


## The road whose music goes with a hero's home, or "" when their home has no road.
static func home_road(home: String) -> String:
	for key in Expedition.ROADS:
		if Expedition.ROADS[key].region == home:
			return key
	return ""


func _ready() -> void:
	clip_contents = true
	var wide := Forge.wide()
	_slides = weave(slides(app.run.road if app.run else ""), app.starred.filter(func(h): return Backdrop.ART.has(Data.hero(h).get("home", ""))))
	_at = maxi(0, _slides.find({"road": app.scene_road}))
	_hero_layer = Control.new()
	_hero_layer.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_hero_layer)
	_hero_layer.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	# The painting stays bright on the right and falls away under the menu.
	if wide:
		add_child(Forge.wash(Color(Forge.INK, 0.9), Vector2(0.0, 0.5), Vector2(0.5, 0.5)))
	add_child(Forge.wash(Color(Forge.INK, 0.94), Vector2(0.5, 1.0), Vector2(0.5, 0.7 if wide else 0.35)))
	var side := int(Screen.SIDE.x if wide else Screen.SIDE.y)
	var m := Forge.margins(MarginContainer.new(), side, 36 if wide else 56, side, 40 if wide else 64)
	m.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(m)
	m.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var col := Forge.vbox(0)
	col.mouse_filter = MOUSE_FILTER_IGNORE
	m.add_child(col)
	col.add_child(_top())
	col.add_child(_gap())
	if wide:
		# The menu on the left and what is on show on the right, balanced across the painting.
		var row := Forge.hbox(0)
		row.mouse_filter = MOUSE_FILTER_IGNORE
		col.add_child(row)
		row.add_child(_menu())
		var mid := Control.new()
		mid.size_flags_horizontal = SIZE_EXPAND_FILL
		mid.mouse_filter = MOUSE_FILTER_IGNORE
		row.add_child(mid)
		var cap := _caption()
		cap.size_flags_vertical = SIZE_SHRINK_END
		row.add_child(cap)
	else:
		col.add_child(_caption())
		var space := Control.new()
		space.custom_minimum_size.y = 48
		col.add_child(space)
		col.add_child(_menu())
	col.add_child(_gap())
	_show()
	# Home is the menu, so the app's own row of links stays away.
	app.show_nav.call_deferred(false)


func _gap() -> Control:
	var g := Control.new()
	g.size_flags_vertical = SIZE_EXPAND_FILL
	g.mouse_filter = MOUSE_FILTER_IGNORE
	return g


func _process(delta: float) -> void:
	if _slides.size() < 2:
		return
	_t += delta
	if _t >= HOLD:
		_feature((_at + 1) % _slides.size())


## The corner: what you hold, on the right.
func _top() -> Control:
	var row := Forge.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_END
	row.custom_minimum_size.y = 40
	var gold := Forge.glyph("gold", 22, Forge.GOLD_LIGHT)
	gold.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(gold)
	var n := Forge.label(str(app.town.embers), 20, Forge.PARCHMENT, Forge.SANS_BOLD)
	n.size_flags_vertical = SIZE_SHRINK_CENTER
	_readable(n)
	row.add_child(n)
	return row


## The places, large, one above the next: home's whole purpose.
func _menu() -> Control:
	var wide := Forge.wide()
	var v := Forge.vbox(4 if wide else 10)
	for place in NavBar.PLACES:
		if place[1] == "menu":
			continue
		var b := Forge.link(place[0], "", 30 if wide else 34)
		b.custom_minimum_size.y = 50 if wide else 64
		b.size_flags_horizontal = SIZE_SHRINK_BEGIN if wide else SIZE_SHRINK_CENTER
		b.add_theme_color_override("font_color", Forge.PARCHMENT)
		b.add_theme_color_override("font_outline_color", Color(Forge.INK, 0.7))
		b.add_theme_constant_override("outline_size", 5)
		b.pressed.connect(app.show_tab.bind(place[1]))
		v.add_child(b)
	return v


## The quiet line naming what is on show, with a diamond for each slide.
func _caption() -> Control:
	var v := Forge.vbox(6)
	v.mouse_filter = MOUSE_FILTER_IGNORE
	_words = Forge.vbox(4)
	_words.mouse_filter = MOUSE_FILTER_IGNORE
	v.add_child(_words)
	if _slides.size() > 1:
		v.add_child(_dot_row())
	return v


## Small diamonds, one a slide; the lit one is on show, and a tap goes to another.
func _dot_row() -> Control:
	var step := 22.0
	_dots = Control.new()
	_dots.custom_minimum_size = Vector2(step * _slides.size(), 26)
	_dots.size_flags_horizontal = SIZE_SHRINK_END if Forge.wide() else SIZE_SHRINK_CENTER
	_dots.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	_dots.draw.connect(func():
		for i in _slides.size():
			var lit := i == _at
			var col := Forge.GOLD_LIGHT if lit else Color(Forge.PARCHMENT, 0.4)
			if _slides[i].has("hero"):
				# A starred hero's diamond is a small star.
				_dots.draw_colored_polygon(star(Vector2(step * (i + 0.5), 16), 6.5), col)
			else:
				Forge.diamond(_dots, Vector2(step * (i + 0.5), 16), 4, col, lit))
	_dots.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			_feature(clampi(int(e.position.x / step), 0, _slides.size() - 1)))
	return _dots


## Changes the slide on show: its words fade through, and its painting comes slowly in over the last.
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
	var slide: Dictionary = _slides[_at]
	for c in _words.get_children():
		_words.remove_child(c)
		c.queue_free()
	for c in _hero_layer.get_children():
		var out := c.create_tween()
		out.tween_property(c, "modulate:a", 0.0, App.SCENE_FADE * 0.5)
		out.tween_callback(c.queue_free)
	var wide := Forge.wide()
	var lines := []
	var region := ""
	if slide.has("road"):
		var r: Dictionary = Expedition.ROADS[slide.road]
		app.set_scene(slide.road, "", false)
		region = r.region
		lines = [Forge.sc("on the road" if app.run else Data.REGIONS[r.region].name, 16, Forge.GOLD, false, 0.4),
			Forge.sc(r.name, 30 if wide else 28, Forge.PARCHMENT, true, 0.06)]
	else:
		var h := Data.hero(slide.hero)
		var road := home_road(h.home)
		app.set_scene(road if road != "" else app.scene_road, Backdrop.ART[h.home][0], false)
		_stand(slide.hero)
		region = h.home
		lines = [Forge.sc("starred · " + Data.REGIONS[h.home].name, 16, Forge.GOLD, false, 0.4),
			Forge.sc(h.name, 30 if wide else 28, Forge.PARCHMENT, true, 0.06)]
	for l in lines:
		_readable(l)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if wide else HORIZONTAL_ALIGNMENT_CENTER
		_words.add_child(l)
	# The region lights up beside its name, like a province on a map; it fades through with the words.
	var head := Forge.hbox(10)
	head.alignment = BoxContainer.ALIGNMENT_BEGIN if wide else BoxContainer.ALIGNMENT_CENTER
	head.mouse_filter = MOUSE_FILTER_IGNORE
	var glow := Forge.region_glow(region, GLOW_PX)
	glow.size_flags_vertical = SIZE_SHRINK_CENTER
	_words.remove_child(lines[0])
	head.add_child(glow)
	head.add_child(lines[0])
	_words.add_child(head)
	_words.move_child(head, 0)


## A starred hero standing big on their home: to the right of the menu on a wide screen, behind it on a phone.
func _stand(hero_key: String) -> void:
	var owned := app.copies(hero_key)
	var s := Stand.new().setup(hero_key, owned[0].stars if not owned.is_empty() else 1)
	var wide := Forge.wide()
	var area := size if size.y > 0.0 else get_viewport_rect().size
	var tall: float = area.y * (HERO_TALL.x if wide else HERO_TALL.y)
	s.tall = 0.98
	s.size = Vector2(tall * 0.8, tall)
	s.position = Vector2(area.x * 0.68 - s.size.x / 2.0, area.y * 0.97 - tall) if wide else Vector2((area.x - s.size.x) / 2.0, area.y * 0.06)
	s.mouse_filter = MOUSE_FILTER_IGNORE
	s.modulate.a = 0.0
	_hero_layer.add_child(s)
	s.create_tween().tween_property(s, "modulate:a", 1.0, App.SCENE_FADE * 0.5)


## A five-pointed star of radius `r` around `c`, the mark of a starred hero.
static func star(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
	return pts


## Words over a painting: a soft dark edge keeps them readable on any of them.
func _readable(l: Label) -> void:
	l.add_theme_color_override("font_outline_color", Color(Forge.INK, 0.7))
	l.add_theme_constant_override("outline_size", 5)
