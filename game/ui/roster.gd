class_name Roster
extends Control
## The roster: one tile per hero with its copies stacked (×3), name below the art. Tap a hero to open their sheet;
## merging happens there, not here. A wide screen lines the cast up as tall strips with the filters down the left, and
## a small switch shows them standing as fighters instead.

const TILE_W := 299
## Cards stand 2:3, taller than the 3:4 they started at, so the art has room above the face.
const ART_H := 448
## Cards across a wide screen and their size, still 2:3.
const WIDE_COLS := 6
const WIDE_W := 192
const WIDE_H := 288
## The wide strips: tall, narrow, and running off the edge when the whole cast is showing.
const STRIP := Vector2(200, 548)
const SIDE_W := 200.0

## Wide only: show the cast as standing fighters rather than cards; kept while you move between screens.
static var models := false

var app: App
var tab := "heroes"
var _grid: GridContainer
var _strips: ScrollContainer


func setup(a: App) -> Roster:
	app = a
	return self


func _ready() -> void:
	if Forge.wide():
		_wide()
		return
	var root := Forge.vbox(0)
	root.set_anchors_preset(PRESET_FULL_RECT)
	add_child(root)

	var head := Forge.margins(MarginContainer.new(), 56, 34, 56, 0) if Forge.wide() else Forge.margins(MarginContainer.new(), 44, 56, 44, 0)
	root.add_child(head)
	var hv := Forge.vbox(30)
	head.add_child(hv)
	var top := Forge.hbox(14)
	hv.add_child(top)
	top.add_child(Forge.sc("Heroes", 40 if Forge.wide() else 52, Forge.GOLD, true, 0.16))
	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	top.add_child(spacer)
	top.add_child(_chip("augment", Forge.GOLD_LIGHT, app.col.loose.size(), "Loose augments", "Augments not fitted to any hero. Fit them to a skill on a hero's Equip page."))
	top.add_child(Forge.sound_toggle())

	var filters := Forge.hbox(16 if Forge.wide() else 8)
	hv.add_child(filters)
	if Forge.wide():
		hv.add_theme_constant_override("separation", 22)
	filters.add_child(_filter("", "star", Forge.GOLD))
	for e in ["fire", "water", "earth", "wind"]:
		filters.add_child(_filter(e, e, Forge.ELEM[e]))
	var gap := Control.new()
	gap.size_flags_horizontal = SIZE_EXPAND_FILL
	filters.add_child(gap)
	var count := Forge.sc("%d heroes" % Data.HEROES.size(), 18, Forge.DIM)
	count.size_flags_vertical = SIZE_SHRINK_CENTER
	filters.add_child(count)
	if Forge.wide():
		var sep := Control.new()
		sep.custom_minimum_size.x = 40
		filters.add_child(sep)
		filters.add_child(_view_switch())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	root.add_child(scroll)
	var pad := Forge.margins(MarginContainer.new(), 56, 24, 56, 40) if Forge.wide() else Forge.margins(MarginContainer.new(), 44, 48, 44, 48)
	pad.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(pad)
	_grid = GridContainer.new()
	# Wide: cards across the screen, or the cast standing as fighters. Phone: cards, two across.
	_grid.columns = WIDE_COLS if Forge.wide() else 2
	_grid.add_theme_constant_override("h_separation", 24 if Forge.wide() else 34)
	_grid.add_theme_constant_override("v_separation", 36 if Forge.wide() else 56)
	pad.add_child(_grid)
	_fill()


## Filters down the left, the title along the top, and the cast filling the rest.
func _wide() -> void:
	var row := Forge.hbox(0)
	row.set_anchors_preset(PRESET_FULL_RECT)
	add_child(row)
	var side := Forge.margins(MarginContainer.new(), 40, 118, 10, 30)
	side.custom_minimum_size.x = SIDE_W
	row.add_child(side)
	var list := Forge.vbox(14)
	side.add_child(list)
	list.add_child(_side_filter("", "star", Forge.GOLD, "all"))
	for e in ["fire", "water", "earth", "wind"]:
		list.add_child(_side_filter(e, e, Forge.ELEM[e], Data.ELEMS[e].label))
	var main := Forge.vbox(24)
	main.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(main)
	var head := Forge.margins(MarginContainer.new(), 10, 34, 40, 0)
	main.add_child(head)
	var top := Forge.hbox(26)
	head.add_child(top)
	top.add_child(Forge.sc("Heroes", 40, Forge.GOLD, true, 0.16))
	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	top.add_child(spacer)
	var count := Forge.sc("%d heroes" % Data.HEROES.size(), 18, Forge.DIM)
	count.size_flags_vertical = SIZE_SHRINK_CENTER
	top.add_child(count)
	top.add_child(_view_switch())
	top.add_child(_chip("augment", Forge.GOLD_LIGHT, app.col.loose.size(), "Loose augments", "Augments not fitted to any hero. Fit them to a skill on a hero's Equip page."))
	top.add_child(Forge.sound_toggle())
	if models:
		var scroll := ScrollContainer.new()
		scroll.size_flags_vertical = SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		main.add_child(scroll)
		_grid = GridContainer.new()
		_grid.columns = WIDE_COLS
		_grid.add_theme_constant_override("h_separation", 24)
		_grid.add_theme_constant_override("v_separation", 36)
		scroll.add_child(_grid)
		_fill()
		return
	_strips = ScrollContainer.new()
	_strips.size_flags_vertical = SIZE_EXPAND_FILL
	_strips.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_strips.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	main.add_child(_strips)
	var line := Forge.hbox(20)
	_strips.add_child(line)
	for h in Data.HEROES:
		if app.filter != "" and h.elem != app.filter:
			continue
		var copies := app.copies(h.key)
		if not copies.is_empty():
			line.add_child(_strip(h, copies[0]))
	var tail := Control.new()
	tail.custom_minimum_size.x = 28
	line.add_child(tail)


## A filter with its name beside it, for the side column.
func _side_filter(elem: String, glyph: String, tint: Color, label: String) -> Control:
	var row := Forge.hbox(14)
	var b := _filter(elem, glyph, tint)
	row.add_child(b)
	var l := Forge.sc(label, 18, Forge.GOLD_LIGHT if app.filter == elem else Forge.DIM)
	l.size_flags_vertical = SIZE_SHRINK_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(l)
	l.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	l.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			b.pressed.emit())
	return row


func _strip(h: Dictionary, card: Dictionary) -> Control:
	var s := Strip.new()
	s.hero = h
	s.stars = card.stars
	s.fielded = card.uid in app.col.squad
	s.custom_minimum_size = STRIP
	s.gui_input.connect(func(e: InputEvent):
		if not e is InputEventMouseButton or not e.pressed:
			return
		if e.button_index == MOUSE_BUTTON_LEFT:
			app.show_hero(h.key)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_strips.scroll_horizontal += 80
		elif e.button_index == MOUSE_BUTTON_WHEEL_UP:
			_strips.scroll_horizontal -= 80)
	var v := Forge.vbox(6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_END
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_bottom = -20
	s.add_child(v)
	var name := Forge.sc(h.name, 20, Forge.PARCHMENT, true, 0.1)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(name)
	var title := Forge.sc(h.title, 13, Forge.LABEL, false, 0.08)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var stars := Forge.stars(card.stars, 14)
	v.add_child(stars)
	for c in [name, title, stars]:
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.add_child(_star(h.key, Vector2(8, 8)))
	return s


## A star in a hero's corner: tap it to have home feature them between the roads.
func _star(hero_key: String, at: Vector2) -> Button:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.tooltip_text = "Star to feature on home"
	b.custom_minimum_size = Vector2(44, 44)
	b.size = b.custom_minimum_size
	b.position = at
	b.draw.connect(func():
		var c := b.size / 2.0
		b.draw_colored_polygon(MainMenu.star(c, 19), Color(Forge.INK, 0.7))
		var pts := MainMenu.star(c, 14)
		if hero_key in app.starred:
			b.draw_colored_polygon(pts, Forge.GOLD_LIGHT)
		else:
			b.draw_polyline(pts + PackedVector2Array([pts[0]]), Color(Forge.PARCHMENT, 0.85), 2.0, true))
	b.pressed.connect(func():
		if hero_key in app.starred:
			app.starred.erase(hero_key)
		else:
			app.starred.append(hero_key)
		b.queue_redraw())
	return b


func _fill() -> void:
	for c in _grid.get_children():
		c.queue_free()
	for h in Data.HEROES:
		if app.filter != "" and h.elem != app.filter:
			continue
		var copies := app.copies(h.key)
		if copies.is_empty():
			continue
		_grid.add_child(_tile(h, copies))


func _tile(h: Dictionary, copies: Array) -> Control:
	var best: Dictionary = copies[0]
	var fielded := copies.any(func(c): return c.uid in app.col.squad)
	var tile := Forge.vbox(22)
	tile.custom_minimum_size.x = TILE_W
	tile.mouse_filter = Control.MOUSE_FILTER_STOP
	tile.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tile.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			app.show_hero(h.key))

	if Forge.wide() and models:
		return _figure_tile(h, copies, best, fielded)
	if Forge.wide():
		tile.custom_minimum_size.x = WIDE_W
		tile.add_theme_constant_override("separation", 14)
	var art := CardArt.new().setup(h.key, best.stars)
	art.custom_minimum_size = Vector2(WIDE_W, WIDE_H) if Forge.wide() else Vector2(TILE_W, ART_H)
	tile.add_child(art)
	art.add_child(_star(h.key, Vector2(12, art.custom_minimum_size.y - 58)))
	art.overlay = func(ci: Control):
		if fielded:
			# The squad pennant, top right.
			var x := ci.size.x - 58
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 40, 0), Vector2(x + 40, 52),
				Vector2(x + 20, 41), Vector2(x, 52)]), Forge.GOLD)
		if copies.size() > 1:
			var t := "×%d" % copies.size()
			var f := Forge.SANS_BOLD
			var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x + 28
			var r := Rect2(ci.size.x - w - 16, ci.size.y - 58, w, 42)
			ci.draw_rect(r.grow(5), Forge.INK)
			ci.draw_rect(r.grow(1), Forge.GOLD_DEEP, false, 2.0)
			# Centre on the glyphs' real height, not a hand-set baseline.
			var base := r.position.y + (r.size.y + f.get_ascent(26) - f.get_descent(26)) / 2.0
			ci.draw_string(f, Vector2(r.position.x, base), t, HORIZONTAL_ALIGNMENT_CENTER, w, 26, Forge.PARCHMENT)

	var plate := Forge.vbox(6)
	tile.add_child(plate)
	var name := Forge.sc(h.name, 24 if Forge.wide() else 35, Forge.PARCHMENT, true, 0.12)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate.add_child(name)
	var title := Forge.sc(h.title, 15 if Forge.wide() else 20, Forge.LABEL)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate.add_child(title)
	var stars := Forge.stars(best.stars, 18)
	plate.add_child(stars)
	for c in [art, plate, name, title, stars]:
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tile


## The wide build's hero: standing in their light, name and stars beneath, copies and the squad pennant beside them.
func _figure_tile(h: Dictionary, copies: Array, best: Dictionary, fielded: bool) -> Control:
	var tile := Forge.vbox(8)
	tile.custom_minimum_size.x = 196
	tile.mouse_filter = Control.MOUSE_FILTER_STOP
	tile.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tile.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			app.show_hero(h.key))
	Forge.press_weight(tile, 0.96)
	var stand := Stand.new().setup(h.key, best.stars)
	stand.custom_minimum_size = Vector2(196, 300)
	tile.add_child(stand)
	stand.add_child(_star(h.key, Vector2(0, 252)))
	stand.draw.connect(func():
		if fielded:
			var x := stand.size.x - 34
			stand.draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 26, 0), Vector2(x + 26, 34),
				Vector2(x + 13, 27), Vector2(x, 34)]), Forge.GOLD)
		if copies.size() > 1:
			stand.draw_string(Forge.SANS_BOLD, Vector2(0, 22), "×%d" % copies.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Forge.MUTED))
	var name := Forge.sc(h.name, 26, Forge.PARCHMENT, true, 0.12)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile.add_child(name)
	var title := Forge.sc(h.title, 16, Forge.LABEL)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile.add_child(title)
	var stars := Forge.stars(best.stars, 16)
	tile.add_child(stars)
	for c in [name, title, stars]:
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tile


## The small cards / models switch beside the filters.
func _view_switch() -> Control:
	var row := Forge.hbox(44)
	row.size_flags_vertical = SIZE_SHRINK_CENTER
	for on in [false, true]:
		row.add_child(Forge.seg("models" if on else "cards", models == on, func():
			models = on
			app.show_roster()))
	return row


## A resource count; tapping it floats what the resource is for.
func _chip(glyph: String, tint: Color, n: int, title: String, about: String) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Forge.flat(Forge.PLAQUE, Color(Forge.BRONZE, 0.9), 2, Vector4(18, 6, 18, 6)))
	p.size_flags_vertical = SIZE_SHRINK_CENTER
	var h := Forge.hbox(10)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(h)
	h.add_child(Forge.glyph(glyph, 26, tint))
	var l := Forge.label(str(n), 26, Forge.PARCHMENT, Forge.SANS_BOLD)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(l)
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.tooltip_text = title
	b.set_anchors_preset(PRESET_FULL_RECT)
	b.pressed.connect(func(): Tooltip.open(p, func(lines: VBoxContainer):
		lines.add_child(Forge.sc("%s · %d" % [title, n], 22, Forge.GOLD))
		var d := Forge.label(about, 24, Forge.PARCHMENT, Forge.SANS_ITALIC)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size.x = 580
		lines.add_child(d)))
	p.add_child(b)
	return p


func _filter(elem: String, glyph: String, tint: Color) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(56, 56) if Forge.wide() else Vector2(80, 80)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.tooltip_text = "All" if elem == "" else Data.ELEMS[elem].label
	var on := app.filter == elem
	var s := StyleBoxFlat.new()
	s.set_corner_radius_all(40)
	s.bg_color = Forge.PLAQUE if on else Color.TRANSPARENT
	s.border_color = Forge.GOLD
	s.set_border_width_all(2 if on else 0)
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, s)
	b.draw.connect(func():
		var tex := Forge.icon("star") if glyph == "star" else Forge.sigil(glyph)
		b.draw_texture_rect(tex, Rect2(b.size / 2 - Vector2(17, 17), Vector2(34, 34)), false, tint))
	b.pressed.connect(func():
		app.filter = elem
		app.show_roster())
	return b


## One hero as a tall strip: their face in their element's light, fading into the name at the foot, a bar in their tier's
## colour under it. Lifts to gold under the cursor.
class Strip extends Control:
	var hero := {}
	var stars := 1
	var fielded := false
	var _tex: Texture2D
	var _over := false

	func _ready() -> void:
		_tex = load(hero.portrait.src)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		mouse_entered.connect(func():
			_over = true
			queue_redraw())
		mouse_exited.connect(func():
			_over = false
			queue_redraw())

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var c: Color = Forge.ELEM[hero.elem]
		draw_rect(r, Forge.PLAQUE_DEEP)
		draw_polygon(PackedVector2Array([r.position, Vector2(size.x, 0), size, Vector2(0, size.y)]),
			PackedColorArray([Color(c, 0.3), Color(c, 0.3), Color(c, 0.0), Color(c, 0.0)]))
		Forge.portrait(self, _tex, r, hero.portrait, 0.5, "strip")
		var from := size.y * 0.66
		draw_polygon(PackedVector2Array([Vector2(0, from), Vector2(size.x, from), size, Vector2(0, size.y)]),
			PackedColorArray([Color(Forge.INK, 0), Color(Forge.INK, 0), Color(Forge.INK, 0.98), Color(Forge.INK, 0.98)]))
		draw_rect(Rect2(0, size.y - 5, size.x, 5), Data.TIER_COLORS[stars])
		if fielded:
			var x := size.x - 40
			draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 26, 0), Vector2(x + 26, 34), Vector2(x + 13, 26), Vector2(x, 34)]), Forge.GOLD)
		if _over:
			draw_rect(r.grow(-1), Forge.GOLD_LIGHT, false, 2.0)
