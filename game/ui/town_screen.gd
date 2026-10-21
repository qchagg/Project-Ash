class_name TownScreen
extends Screen
## The town: the Ashen Hearth burning at the top, its buildings strung down a road below it.
## Tap a building for its panel (what it does, what the next level brings); the panel holds the screen's one commit.

const MAP_W := 632.0
const HEARTH_H := 380.0
const PLATE := Vector2(360, 230)
const STEP := 250.0
const STREET := ["forge", "archive", "caravanserai", "grounds", "bazaar", "envoys"]
const NAV_H := 136.0

## The building whose panel is open, or "".
var _sel := ""
var _drawer: Control
var _lit := false


func _init() -> void:
	tab = "town"
	title = "town"


func _build() -> void:
	if not _lit:
		_lit = true
		var bd := Backdrop.new()
		bd.elem = "fire"
		bd.focus = Vector2(0.5, 0.12)
		bd.strength = 0.45
		bd.set_anchors_preset(PRESET_FULL_RECT)
		add_child(bd)
		move_child(bd, 0)
	var t := app.town
	head_right.add_child(_embers_chip())
	body.add_child(_map())
	var foot := Forge.vbox(14)
	body.add_child(foot)
	var note := Forge.label("Playtest: battles aren't wired to the town yet. Gather embers here to try the buildings.", 22, Forge.DIM, Forge.SANS_ITALIC)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size.x = MAP_W
	foot.add_child(note)
	var gather := Forge.ember("gather %d embers" % (t.battle_reward() * 2), 72)
	gather.pressed.connect(func():
		t.earn(t.battle_reward() * 2)
		_refresh())
	foot.add_child(gather)
	# Room to scroll the last building clear of the open panel.
	var room := Control.new()
	room.custom_minimum_size.y = 460 if _sel != "" else 0
	body.add_child(room)
	_open_drawer()


func _refresh() -> void:
	rebuild()


## The resource count; tapping it says where embers come from.
func _embers_chip() -> Control:
	var t := app.town
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Forge.flat(Forge.PLAQUE, Color(Forge.BRONZE, 0.9), 2, Vector4(18, 6, 18, 6)))
	p.size_flags_vertical = SIZE_SHRINK_CENTER
	var h := Forge.hbox(10)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(h)
	h.add_child(Forge.glyph("ember", 26, Forge.GOLD_LIGHT))
	var l := Forge.label(str(t.embers), 26, Forge.PARCHMENT, Forge.SANS_BOLD)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(l)
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.tooltip_text = "Embers"
	b.set_anchors_preset(PRESET_FULL_RECT)
	b.pressed.connect(func(): Tooltip.open(p, func(lines: VBoxContainer):
		lines.add_child(Forge.sc("embers · %d" % t.embers, 22, Forge.GOLD))
		var d := Forge.label("The town's one resource. Each won battle brings home %d, more as the Hearth grows. Buildings rise on them." % t.battle_reward(),
			24, Forge.PARCHMENT, Forge.SANS_ITALIC)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size.x = 580
		lines.add_child(d)))
	p.add_child(b)
	return p


## The hearth on its skyline, then the street of buildings winding down from it.
func _map() -> Control:
	var map := Control.new()
	map.custom_minimum_size = Vector2(MAP_W, HEARTH_H + STREET.size() * STEP + 20)
	var centers := [Vector2(MAP_W / 2, 170)]
	for i in STREET.size():
		centers.append(_plate_pos(i) + PLATE / 2)
	map.draw.connect(func():
		# Rooftops behind the hearth: a low skyline of domes, towers and gables.
		var sky := PackedVector2Array([Vector2(0, 300), Vector2(0, 220), Vector2(40, 220), Vector2(40, 180), Vector2(70, 160),
			Vector2(100, 180), Vector2(100, 230), Vector2(150, 230), Vector2(150, 200)])
		for k in 9:
			var a := PI + PI * k / 8.0
			sky.append(Vector2(185, 200) + Vector2(cos(a), sin(a)) * 35)
		sky.append_array([Vector2(220, 240), Vector2(412, 240), Vector2(412, 190), Vector2(432, 150), Vector2(452, 190),
			Vector2(452, 215), Vector2(500, 215), Vector2(530, 185), Vector2(560, 215), Vector2(590, 215), Vector2(590, 170),
			Vector2(612, 170), Vector2(612, 235), Vector2(MAP_W, 235), Vector2(MAP_W, 300)])
		map.draw_colored_polygon(sky, Color(Forge.PLAQUE, 0.9))
		map.draw_polyline(sky, Color(Forge.GOLD_DEEP, 0.25), 2.0)
		# The road: gold studs from the hearth down past every building.
		for i in centers.size() - 1:
			var a: Vector2 = centers[i]
			var b: Vector2 = centers[i + 1]
			var n := int(a.distance_to(b) / 26)
			for j in n:
				var p := a.lerp(b, (j + 0.5) / n)
				Forge.diamond(map, p, 4, Color(Forge.GOLD_DEEP, 0.45))
	)
	map.add_child(_hearth())
	for i in STREET.size():
		var p := _plate(STREET[i])
		p.position = _plate_pos(i)
		map.add_child(p)
	return map


func _plate_pos(i: int) -> Vector2:
	return Vector2(0.0 if i % 2 == 0 else MAP_W - PLATE.x, HEARTH_H + i * STEP)


## The Ashen Hearth: a raised medallion with the town fire, its level beneath.
func _hearth() -> Control:
	var t := app.town
	var b := _tap("hearth")
	b.position = Vector2(MAP_W / 2 - 160, 40)
	b.size = Vector2(320, 320)
	b.draw.connect(func():
		var c := Vector2(160, 130)
		var on := _sel == "hearth"
		b.draw_circle(c, 104, Forge.INK)
		b.draw_circle(c, 100, Forge.GOLD_LIGHT if on else Forge.GOLD_DEEP)
		b.draw_circle(c, 96, Forge.PLAQUE_DEEP)
		b.draw_circle(c, 80, Color(Forge.ELEM.fire, 0.12))
		b.draw_arc(c, 88, 0, TAU, 64, Color(Forge.GOLD, 0.35), 1.5, true)
		b.draw_texture_rect(Forge.icon("bld_hearth"), Rect2(c - Vector2(52, 56), Vector2(104, 104)), false, Forge.GOLD_LIGHT)
		_pips(b, Vector2(160, 300), t.level("hearth"), Town.BUILDINGS.hearth.max, Town.BUILDINGS.hearth.max)
		if t.blocked("hearth") == "":
			_ready_mark(b, c + Vector2(76, -76)))
	var nm := Forge.sc("ashen hearth", 28, Forge.GOLD, true)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.position = Vector2(0, 244)
	nm.size = Vector2(320, 34)
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(nm)
	return b


## One building on the street: an arched plate with its glyph, name, level and (for routes and envoys) region sigils.
func _plate(key: String) -> Control:
	var t := app.town
	var info: Dictionary = Town.BUILDINGS[key]
	var lvl := t.level(key)
	var b := _tap(key)
	b.size = PLATE
	b.draw.connect(func():
		var on := _sel == key
		var built := lvl > 0
		var r := Rect2(0, 46, PLATE.x, PLATE.y - 46)
		var edge := Forge.GOLD_LIGHT if on else (Forge.GOLD_DEEP if built else Color(Forge.DIM, 0.45))
		b.draw_rect(r, Color(Forge.PLAQUE, 0.94) if built else Color(Forge.INK, 0.75))
		b.draw_rect(r, edge, false, 3.0 if on else 2.0)
		if built:
			Forge.filigree(b, r.grow(-8), Color(Forge.GOLD_DEEP, 0.35), 30)
		var c := Vector2(PLATE.x / 2, 46)
		b.draw_circle(c, 46, Forge.INK)
		b.draw_circle(c, 43, edge)
		b.draw_circle(c, 40, Forge.PLAQUE_DEEP)
		b.draw_texture_rect(Forge.icon(info.icon), Rect2(c - Vector2(28, 28), Vector2(56, 56)), false,
			Forge.GOLD_LIGHT if built else Color(Forge.DIM, 0.7))
		_pips(b, Vector2(PLATE.x / 2, PLATE.y - 26), lvl, t.cap(key), info.max)
		if t.blocked(key) == "":
			_ready_mark(b, Vector2(PLATE.x - 22, 68)))
	var v := Forge.vbox(6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.position = Vector2(0, 102)
	v.size = Vector2(PLATE.x, 80)
	b.add_child(v)
	var nm := Forge.sc(info.name, 26, Forge.GOLD if lvl > 0 else Forge.MUTED, true)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(nm)
	var regions := t.routes() if key == "caravanserai" else (t.envoys() if key == "envoys" else [])
	if not regions.is_empty():
		var row := Forge.hbox(6)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for k in regions:
			row.add_child(Forge.region_badge(k, 34))
		v.add_child(row)
	else:
		var status := Forge.sc("unbuilt · %d embers" % t.cost(key) if lvl == 0 else "level %d" % lvl, 20,
			Forge.DIM if lvl == 0 else Forge.LABEL)
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(status)
	return b


## A flat button that selects a building (tap again to put its panel away).
func _tap(key: String) -> Button:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.tooltip_text = Town.BUILDINGS[key].name
	b.pressed.connect(func():
		_sel = "" if _sel == key else key
		_refresh())
	return b


## A row of level diamonds: gold for built levels, outlined up to what the Hearth allows, faint beyond.
static func _pips(ci: CanvasItem, center: Vector2, lvl: int, cap: int, top: int) -> void:
	for i in top:
		var p := center + Vector2((i - (top - 1) / 2.0) * 24, 0)
		if i < lvl:
			Forge.diamond(ci, p, 7, Forge.GOLD)
		else:
			Forge.diamond(ci, p, 6, Color(Forge.GOLD_DEEP, 0.75 if i < cap else 0.25), false)


## A small glowing diamond on a building that can rise right now.
static func _ready_mark(ci: CanvasItem, at: Vector2) -> void:
	ci.draw_circle(at, 16, Color(Forge.GAIN, 0.18))
	Forge.diamond(ci, at, 9, Forge.GAIN)


## The selected building's panel, docked above the tab bar so it never pushes the town around.
func _open_drawer() -> void:
	if is_instance_valid(_drawer):
		_drawer.queue_free()
	_drawer = null
	if _sel == "":
		return
	var t := app.town
	var key := _sel
	var info: Dictionary = Town.BUILDINGS[key]
	var lvl := t.level(key)
	var p := PanelContainer.new()
	var st := Forge.flat(Forge.INK, Color(Forge.GOLD_DEEP, 0.9), 0, Vector4(44, 28, 44, 74))
	st.border_width_top = 2
	st.shadow_color = Color(0, 0, 0, 0.5)
	st.shadow_size = 24
	p.add_theme_stylebox_override("panel", st)
	add_child(p)
	p.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
	p.grow_vertical = Control.GROW_DIRECTION_BEGIN
	p.offset_bottom = -NAV_H
	p.offset_top = -NAV_H
	_drawer = p
	var v := Forge.vbox(16)
	p.add_child(v)

	var head := Forge.hbox(18)
	v.add_child(head)
	head.add_child(Forge.glyph(info.icon, 52, Forge.GOLD_LIGHT))
	var names := Forge.vbox(2)
	head.add_child(names)
	names.add_child(Forge.sc(info.name, 30, Forge.GOLD, true))
	names.add_child(Forge.sc("unbuilt" if lvl == 0 else "level %d of %d" % [lvl, info.max], 20, Forge.LABEL))
	var sp := Control.new()
	sp.size_flags_horizontal = SIZE_EXPAND_FILL
	head.add_child(sp)
	var close := Forge.link("close", "")
	close.custom_minimum_size.y = 56
	close.pressed.connect(func():
		_sel = ""
		_refresh())
	head.add_child(close)

	v.add_child(_para(info.about, Forge.MUTED))
	if lvl > 0:
		v.add_child(_level_line("now", t.gives(key, lvl), Forge.PARCHMENT))
	if lvl < info.max:
		v.add_child(_level_line("next", t.gives(key, lvl + 1), Forge.GAIN if t.blocked(key) == "" else Forge.MUTED))
	if key == "envoys" and lvl > 0:
		v.add_child(_envoy_row())

	var why := t.blocked(key)
	var row := Forge.hbox(20)
	v.add_child(row)
	if lvl < info.max:
		var up := Forge.studs("%s · %d embers" % ["build" if lvl == 0 else "raise to level %d" % (lvl + 1), t.cost(key)], true, 72)
		up.size_flags_horizontal = SIZE_EXPAND_FILL
		up.disabled = why != ""
		up.pressed.connect(func():
			if t.upgrade(key):
				_refresh())
		row.add_child(up)
	if info.link != "" and lvl > 0:
		var go := Forge.link("to %s" % info.link, "")
		go.custom_minimum_size.y = 72
		go.pressed.connect(func(): app.show_tab(info.link))
		row.add_child(go)
	if why != "" and lvl < info.max:
		v.add_child(Forge.label(why, 22, Forge.DIM, Forge.SANS_ITALIC))


func _level_line(tag: String, text: String, color: Color) -> Control:
	var h := Forge.hbox(16)
	var l := Forge.sc(tag, 20, Forge.GOLD)
	l.custom_minimum_size.x = 64
	h.add_child(l)
	var t := _para(text, color)
	t.custom_minimum_size.x = 552
	h.add_child(t)
	return h


func _para(text: String, color: Color) -> Label:
	var l := Forge.label(text, 24, color, Forge.SANS_ITALIC)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 632
	return l


## The seated envoys' sigils; tap one for that region's favor.
func _envoy_row() -> Control:
	var row := Forge.hbox(12)
	for k in app.town.envoys():
		var badge := Forge.region_badge(k, 56)
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.custom_minimum_size = Vector2(56, 56)
		b.tooltip_text = Data.REGIONS[k].name
		b.add_child(badge)
		b.pressed.connect(func(): Tooltip.open(b, func(lines: VBoxContainer):
			lines.add_child(Forge.sc("%s envoy" % Data.REGIONS[k].name, 22, Data.REGIONS[k].light))
			var d := Forge.label(Town.favor(k), 24, Forge.PARCHMENT, Forge.SANS_ITALIC)
			d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			d.custom_minimum_size.x = 580
			lines.add_child(d)))
		row.add_child(b)
	return row
