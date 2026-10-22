class_name Roster
extends Control
## The roster: one tile per hero with its copies stacked (×3), name below the art.
## Tap a hero to open their sheet; merging happens there, not here.

const TILE_W := 299
## Cards stand 2:3, taller than the 3:4 they started at, so the art has room above the face.
const ART_H := 448

var app: App
var tab := "heroes"
var _grid: GridContainer


func setup(a: App) -> Roster:
	app = a
	return self


func _ready() -> void:
	var root := Forge.vbox(0)
	root.set_anchors_preset(PRESET_FULL_RECT)
	add_child(root)

	var head := Forge.margins(MarginContainer.new(), 44, 56, 44, 0)
	root.add_child(head)
	var hv := Forge.vbox(30)
	head.add_child(hv)
	var top := Forge.hbox(14)
	hv.add_child(top)
	top.add_child(Forge.sc("Heroes", 52, Forge.GOLD, true, 0.16))
	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	top.add_child(spacer)
	top.add_child(_chip("crown", Forge.GOLD, app.col.crowns, "Ashcrowns", "Raise a 3★ card to 4★ on its Evolve page."))
	top.add_child(_chip("augment", Forge.GOLD_LIGHT, app.col.loose.size(), "Loose augments", "Augments not slotted on any card. Fit them to a skill on a card's Equip page."))

	var filters := Forge.hbox(8)
	hv.add_child(filters)
	filters.add_child(_filter("", "star", Forge.GOLD))
	for e in ["fire", "water", "earth", "wind"]:
		filters.add_child(_filter(e, e, Forge.ELEM[e]))
	var gap := Control.new()
	gap.size_flags_horizontal = SIZE_EXPAND_FILL
	filters.add_child(gap)
	var count := Forge.sc("%d heroes" % Data.HEROES.size(), 18, Forge.DIM)
	count.size_flags_vertical = SIZE_SHRINK_CENTER
	filters.add_child(count)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	root.add_child(scroll)
	var pad := Forge.margins(MarginContainer.new(), 44, 48, 44, 48)
	pad.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(pad)
	_grid = GridContainer.new()
	_grid.columns = 4 if Forge.wide() else 2
	_grid.add_theme_constant_override("h_separation", 34)
	_grid.add_theme_constant_override("v_separation", 56)
	pad.add_child(_grid)
	_fill()


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

	var art := CardArt.new().setup(h.key, best.stars)
	art.custom_minimum_size = Vector2(TILE_W, ART_H)
	tile.add_child(art)
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
	var name := Forge.sc(h.name, 35, Forge.PARCHMENT, true, 0.12)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate.add_child(name)
	var title := Forge.sc(h.title, 20, Forge.LABEL)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate.add_child(title)
	var stars := Forge.hbox(4)
	stars.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in best.stars:
		stars.add_child(Forge.glyph("star", 18, Data.TIER_COLORS[best.stars].lightened(0.15)))
	plate.add_child(stars)
	for c in [art, plate, name, title, stars]:
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tile


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
	b.custom_minimum_size = Vector2(80, 80)
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
