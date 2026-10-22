class_name TownScreen
extends Screen
## The town: the Hearth along the top, the buildings in a grid beneath it. Each building rises level by level on
## embers brought home from expeditions, and the ones with a door (the Forge, the Archive, the Training Grounds) open
## onto their part of the game. A building that can rise now wears a turning comet on its border; the one you picked
## wears the full flowing rim. Tap a building for its panel (what it does, what the next level brings, the way in).

const GRID := ["forge", "archive", "infirmary", "grounds", "caravanserai", "bazaar", "envoys"]
const TILE := Vector2(300, 268)

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
		bd.focus = Vector2(0.5, 0.08)
		bd.strength = 0.35
		bd.set_anchors_preset(PRESET_FULL_RECT)
		add_child(bd)
		move_child(bd, 0)
	var t := app.town
	head_right.add_child(_embers_chip())
	body.add_child(_hearth())
	var grid := GridContainer.new()
	grid.columns = 4 if Forge.wide() else 2
	grid.add_theme_constant_override("h_separation", 32)
	grid.add_theme_constant_override("v_separation", 32)
	body.add_child(grid)
	for k in GRID:
		grid.add_child(_tile(k))
	var foot := Forge.hbox(18)
	body.add_child(foot)
	var note := Forge.label("Playtest: embers come home from expeditions. This adds some for trying the buildings.", 20, Forge.DIM, Forge.SANS_ITALIC)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.size_flags_horizontal = SIZE_EXPAND_FILL
	foot.add_child(note)
	var gather := Forge.link("+%d embers" % (t.battle_reward() * 2), "ember", 20)
	gather.pressed.connect(func():
		t.earn(t.battle_reward() * 2)
		_refresh())
	foot.add_child(gather)
	# Room to scroll the last row clear of the open panel.
	var room := Control.new()
	room.custom_minimum_size.y = 440 if _sel != "" else 0
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
		var d := Forge.label("The town's one resource. Expeditions bring them home: everything gathered on a road, or half if the squad falls. Buildings rise on them.",
			24, Forge.PARCHMENT, Forge.SANS_ITALIC)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size.x = 580
		lines.add_child(d)))
	p.add_child(b)
	return p


## The Hearth: a wide plate across the top, its fire in a medallion and its level, which caps every other building.
func _hearth() -> Control:
	var t := app.town
	var lvl := t.level("hearth")
	var b := _tap("hearth")
	b.custom_minimum_size = Vector2(0, 168)
	b.draw.connect(func():
		var on := _sel == "hearth"
		var r := Rect2(Vector2.ZERO, b.size)
		b.draw_rect(r, Color(Forge.PLAQUE, 0.94))
		b.draw_rect(r, Forge.GOLD_LIGHT if on else Forge.GOLD_DEEP, false, 2.0)
		var c := Vector2(92, r.size.y / 2)
		b.draw_circle(c, 62, Forge.INK)
		b.draw_circle(c, 58, Forge.GOLD_DEEP)
		b.draw_circle(c, 55, Forge.PLAQUE_DEEP)
		b.draw_circle(c, 46, Color(Forge.ELEM.fire, 0.14))
		b.draw_texture_rect(Forge.icon("bld_hearth"), Rect2(c - Vector2(34, 36), Vector2(68, 68)), false, Forge.GOLD_LIGHT)
		_pips(b, Vector2(180 + 6 * 12, r.size.y - 40), lvl, Town.BUILDINGS.hearth.max, Town.BUILDINGS.hearth.max))
	var v := Forge.vbox(4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.position = Vector2(180, 30)
	b.add_child(v)
	v.add_child(Forge.sc(Town.BUILDINGS.hearth.name, 30, Forge.GOLD, true))
	v.add_child(Forge.sc("level %d · caps every building" % lvl, 18, Forge.LABEL))
	_rim(b, "hearth")
	return b


## One building: its glyph on a medallion, its name, level pips, and its regions where it has them.
func _tile(key: String) -> Control:
	var t := app.town
	var info: Dictionary = Town.BUILDINGS[key]
	var lvl := t.level(key)
	var b := _tap(key)
	b.custom_minimum_size = TILE
	b.draw.connect(func():
		var on := _sel == key
		var built := lvl > 0
		var r := Rect2(Vector2.ZERO, b.size)
		b.draw_rect(r, Color(Forge.PLAQUE, 0.94) if built else Color(Forge.INK, 0.7))
		if not on and t.blocked(key) != "":
			b.draw_rect(r, Forge.GOLD_DEEP if built else Color(Forge.DIM, 0.4), false, 2.0)
		var c := Vector2(r.size.x / 2, 78)
		b.draw_circle(c, 48, Forge.INK)
		b.draw_circle(c, 45, Forge.GOLD_DEEP if built else Color(Forge.DIM, 0.5))
		b.draw_circle(c, 42, Forge.PLAQUE_DEEP)
		b.draw_texture_rect(Forge.icon(info.icon), Rect2(c - Vector2(28, 28), Vector2(56, 56)), false,
			Forge.GOLD_LIGHT if built else Color(Forge.DIM, 0.75))
		_pips(b, Vector2(r.size.x / 2, r.size.y - 30), lvl, t.cap(key), info.max))
	var v := Forge.vbox(6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.position = Vector2(0, 140)
	v.size = Vector2(TILE.x, 80)
	b.add_child(v)
	var nm := Forge.sc(info.name, 24, Forge.GOLD if lvl > 0 else Forge.MUTED, true)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(nm)
	var regions := t.routes() if key == "caravanserai" else (t.envoys() if key == "envoys" else [])
	if not regions.is_empty():
		var row := Forge.hbox(6)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for k in regions.slice(0, 5):
			row.add_child(Forge.region_badge(k, 30))
		v.add_child(row)
	else:
		var status := Forge.sc("unbuilt · %d embers" % t.cost(key) if lvl == 0 else "level %d" % lvl, 18,
			Forge.DIM if lvl == 0 else Forge.LABEL)
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(status)
	_rim(b, key)
	return b


## The living border: the full flow on the picked building, a comet on one that can rise now.
func _rim(b: Control, key: String) -> void:
	if _sel == key:
		Rim.on(b, "flow", [Forge.GOLD_DEEP, Forge.GOLD_LIGHT, Forge.GOLD, Color("#fff1c4")], 3.0)
	elif app.town.blocked(key) == "":
		Rim.on(b, "comet", [Forge.GAIN], 2.5)


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
	if key == "infirmary":
		v.add_child(_level_line("camp", "On the road, a camp heals %d%% of health." % roundi(Expedition.CAMP_HEAL[lvl] * 100), Forge.PARCHMENT))

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
		var go := Forge.link(info.enter, "chevron")
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
