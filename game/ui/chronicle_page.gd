class_name ChroniclePage
extends Control
## The third page of a hero: their history and bio. Lore, home region, bonds and scars.
## Bonds and scars fold open on tap; tapping a bond goes to that hero.

const PAGE_H := 1560.0

var app: App
var hero := ""
var uid := ""
var _show_bonds := false
var _show_scars := false
var _ui: Control

signal height_changed(h: float)
## Go to another hero (from a bond).
signal visit(hero_key: String)


func setup(a: App, hero_key: String, card_uid: String) -> ChroniclePage:
	app = a
	hero = hero_key
	uid = card_uid
	return self


func _ready() -> void:
	var bd := Backdrop.new()
	bd.elem = Data.hero(hero).elem
	bd.focus = Vector2(0.5, 0.0)
	bd.strength = 0.4
	var home: String = Data.hero(hero).get("home", "")
	if home != "":
		bd.tint = Data.REGIONS[home].light.darkened(0.2)
	bd.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bd)
	refresh()


func refresh() -> void:
	if _ui:
		_ui.queue_free()
	var h := Data.hero(hero)
	var root := Forge.margins(MarginContainer.new(), 44, 150, 44, 80)
	root.custom_minimum_size = Vector2(720, PAGE_H)
	add_child(root)
	_ui = root
	var col := Forge.vbox(36)
	root.add_child(col)

	var head := Forge.vbox(8)
	col.add_child(head)
	head.add_child(Forge.sc("chronicle", 52, Forge.GOLD, true, 0.12))
	head.add_child(Forge.label("%s, %s" % [h.name, h.title], 26, Forge.MUTED))
	col.add_child(Forge.rule())

	var lore := Forge.label(h.get("lore", "[%s’s story goes here: where they come from, what they want, what they hide.]" % h.name),
		27, Color("#e2d5b6"), Forge.SANS_ITALIC)
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore.custom_minimum_size.x = 632
	lore.add_theme_constant_override("line_spacing", 6)
	col.add_child(lore)

	col.add_child(_home(h))
	var bonds := Data.bonds(hero)
	col.add_child(_fold("bonds", bonds.size(), _show_bonds, func():
		_show_bonds = not _show_bonds
		refresh()))
	if _show_bonds:
		if bonds.is_empty():
			col.add_child(_note("None yet. Friends, rivals and lovers form on runs."))
		for b in bonds:
			col.add_child(_bond(b))
	col.add_child(_fold("scars", 0, _show_scars, func():
		_show_scars = not _show_scars
		refresh()))
	if _show_scars:
		col.add_child(_note("None. Dying twice back to back leaves a scar that only specific means can heal."))
	_fit.call_deferred()


func _fit() -> void:
	if not is_instance_valid(_ui):
		return
	var hgt := maxf(PAGE_H, _ui.get_combined_minimum_size().y)
	_ui.size = Vector2(720, hgt)
	custom_minimum_size = Vector2(720, hgt)
	size = Vector2(720, hgt)
	height_changed.emit(hgt)


## Home region as a tag with its sigil; tapping it floats the region's colorway and a line about the place.
func _home(h: Dictionary) -> Control:
	var row := Forge.hbox(18)
	var l := Forge.sc("home", 22, Forge.GOLD)
	l.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(l)
	var key: String = h.get("home", "")
	if key == "":
		row.add_child(Forge.label("Not decided yet.", 24, Forge.MUTED, Forge.SANS_ITALIC))
		return row
	var r: Dictionary = Data.REGIONS[key]
	var b := Forge.ember(r.name, 64)
	b.icon = Forge.icon("region_" + key)
	b.add_theme_constant_override("icon_max_width", 30)
	for st in ["icon_normal_color", "icon_hover_color", "icon_pressed_color"]:
		b.add_theme_color_override(st, r.light)
	b.add_theme_constant_override("h_separation", 12)
	b.pressed.connect(func(): Tooltip.open(b, func(lines: VBoxContainer):
		var art := Control.new()
		art.custom_minimum_size = Vector2(580, 170)
		lines.add_child(art)
		var sw := Forge.region_swatch(key, Vector2(580, 110))
		art.add_child(sw)
		var badge := Forge.region_badge(key, 104)
		badge.position = Vector2(290 - 52, 62)
		art.add_child(badge)
		var title := Forge.sc(r.name, 30, Forge.GOLD, true, 0.14)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lines.add_child(title)
		var d := Forge.label(r.desc, 24, Forge.PARCHMENT, Forge.SANS_ITALIC)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		d.custom_minimum_size.x = 580
		lines.add_child(d)))
	row.add_child(b)
	return row


## A section heading that folds open: name, count and a chevron.
func _fold(title: String, n: int, open: bool, cb: Callable) -> Control:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.custom_minimum_size = Vector2(632, 64)
	b.pressed.connect(cb)
	b.draw.connect(func():
		var f := Forge.tracked(Forge.SC, 3)
		b.draw_string(f, Vector2(0, 40), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Forge.GOLD)
		var w := f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
		b.draw_string(Forge.SANS_BOLD, Vector2(w + 16, 40), str(n), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Forge.LABEL)
		b.draw_line(Vector2(w + 50, 32), Vector2(b.size.x - 40, 32), Color(Forge.BRONZE, 0.6), 1.0)
		var c := Vector2(b.size.x - 14, 32)
		var d := -1.0 if open else 1.0
		b.draw_polyline(PackedVector2Array([c + Vector2(-10, -5 * d), c + Vector2(0, 5 * d), c + Vector2(10, -5 * d)]), Forge.GOLD, 2.5, true))
	return b


## A bond: the bondmate's small portrait, their name and the kind of bond, then this hero's line about them.
func _bond(b: Dictionary) -> Control:
	var other := Data.hero(b.other)
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.tooltip_text = "Go to %s" % other.name
	var st := Forge.flat(Color(Forge.PLAQUE, 0.85), Color(Forge.BRONZE, 0.8), 2)
	for state in ["normal", "hover", "pressed"]:
		btn.add_theme_stylebox_override(state, st if state != "hover" else Forge.flat(Color("#241b13"), Forge.GOLD_DEEP, 2))
	btn.pressed.connect(func(): visit.emit(b.other))
	var m := Forge.margins(MarginContainer.new(), 22, 20, 26, 20)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.set_anchors_preset(PRESET_FULL_RECT)
	btn.add_child(m)
	var h := Forge.hbox(22)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(h)
	var face := Control.new()
	face.custom_minimum_size = Vector2(96, 96)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex: Texture2D = load(other.portrait.src)
	var c := app.copies(b.other)
	var stars: int = c[0].stars if not c.is_empty() else 1
	face.draw.connect(func():
		var r := Rect2(Vector2.ZERO, face.size)
		Forge.portrait(face, tex, r, other.portrait, 0.75)
		face.draw_rect(r.grow(-1.5), Data.TIER_COLORS[stars], false, 3.0))
	h.add_child(face)
	var t := Forge.vbox(6)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.size_flags_horizontal = SIZE_EXPAND_FILL
	t.size_flags_vertical = SIZE_SHRINK_CENTER
	h.add_child(t)
	var top := Forge.hbox(14)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.add_child(top)
	top.add_child(Forge.sc(other.name, 28, Forge.PARCHMENT, true, 0.1))
	var kind := Forge.sc(b.kind, 20, Forge.GOLD)
	kind.size_flags_vertical = SIZE_SHRINK_CENTER
	top.add_child(kind)
	var line := Forge.label(b.line, 24, Color("#e2d5b6"), Forge.SANS_ITALIC)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.custom_minimum_size.x = 440
	t.add_child(line)
	btn.custom_minimum_size.y = 136
	m.minimum_size_changed.connect(func(): btn.custom_minimum_size.y = m.get_combined_minimum_size().y)
	return btn


func _note(text: String) -> Label:
	var l := Forge.label(text, 24, Forge.MUTED, Forge.SANS_ITALIC)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 632
	return l
