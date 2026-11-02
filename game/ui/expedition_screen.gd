class_name ExpeditionScreen
extends Screen
## Expedition, the centre of the game. Between runs: one road fills the screen, with a strip of the others along the foot
## and next and back to walk through them, or a grid to see them all; check the party, set out. On the road: the map of the run, read from the start at the foot to the warden at the top (left to
## right on a wide screen). The nodes you can step to next are ringed and turning; tap one to go there. Fights open the
## battle; camps, boons, caches and trials open over the map. When the run ends, its embers go home to the town.

const NODE_R := 38.0
const LAYER := 150.0
const ROW := 120.0
## How tall a road card stands, on a phone and on a wide screen.
const CARD_H := 214.0
const CARD_H_WIDE := 200.0
## Road cards across a wide screen; the phone stacks them.
const ROAD_COLS_WIDE := 4
## A road's thumbnail in the strip at the foot of the big view.
const THUMB := Vector2(190, 92)
## The description's line spacing: tight, so the words stay low on the painting.
const ABOUT_LINES := -7

var _road := "basalt"
var _map: Control
## A choice's stage on a wide screen: where the offers stand, between the hero and the terms.
const STAGE_LEFT := 400.0
const STAGE_RIGHT := 300.0
const STAGE_TOP := 112.0
const STAGE_W := 800.0
## Terms a choice may use beyond the statuses in the Archive's glossary.
const STAGE_TERMS := [["Cooldown", "Rounds a skill waits before it can be used again."], ["Power", "How hard a skill lands, as a share of attack."]]

## Between runs, the big view: its layers from the art up, the road's words, and the strip.
var _land: Control
var _art_layer: Control
var _air_layer: Control
var _info: VBoxContainer
var _strip: HBoxContainer
var _strip_scroll: ScrollContainer
## Between runs, every road at once instead of the big view.
var _grid := false


func _init() -> void:
	tab = "expedition"
	title = "expedition"


func _build() -> void:
	app.music()
	if _land:
		_land.queue_free()
		_land = null
	frame.visible = app.run != null or _grid
	if app.run == null:
		if _grid:
			_choose_road()
		else:
			_landing()
	elif app.run.over != "":
		_summary()
	else:
		_on_the_road()


# ---------- between runs: choose a road ----------

func _landing() -> void:
	if app.road_pick != "":
		_road = app.road_pick
	var wide := Forge.wide()
	_land = Control.new()
	_land.clip_contents = true
	add_child(_land)
	_land.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_art_layer = Control.new()
	_art_layer.mouse_filter = MOUSE_FILTER_IGNORE
	_land.add_child(_art_layer)
	_art_layer.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_land.add_child(Forge.wash(Color(Forge.INK, 0.98), Vector2(0.5, 1.0), Vector2(0.5, 0.4)))
	_air_layer = Control.new()
	_air_layer.mouse_filter = MOUSE_FILTER_IGNORE
	_land.add_child(_air_layer)
	_air_layer.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var m := Forge.margins(MarginContainer.new(), 40, 26 if wide else 56, 40, 18 if wide else 28)
	m.mouse_filter = MOUSE_FILTER_IGNORE
	_land.add_child(m)
	m.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var col := Forge.vbox(14)
	col.mouse_filter = MOUSE_FILTER_IGNORE
	m.add_child(col)
	var top := Forge.hbox(14)
	col.add_child(top)
	var heading := Forge.sc("choose a road", 26 if wide else 32, Forge.GOLD_LIGHT, true, 0.16)
	heading.size_flags_horizontal = SIZE_EXPAND_FILL
	heading.add_theme_color_override("font_shadow_color", Color.BLACK)
	top.add_child(heading)
	top.add_child(_chip("gold", str(app.town.embers), "Gold in the caravan"))
	var all := Forge.link("all roads", "", 22)
	all.pressed.connect(func():
		_grid = true
		rebuild())
	top.add_child(all)
	top.add_child(Forge.sound_toggle())
	var gap := Control.new()
	gap.size_flags_vertical = SIZE_EXPAND_FILL
	gap.mouse_filter = MOUSE_FILTER_IGNORE
	col.add_child(gap)
	var row: BoxContainer = Forge.hbox(28) if wide else Forge.vbox(18)
	col.add_child(row)
	_info = Forge.vbox(2)
	_info.size_flags_horizontal = SIZE_EXPAND_FILL
	_info.size_flags_vertical = SIZE_SHRINK_END
	_info.mouse_filter = MOUSE_FILTER_IGNORE
	row.add_child(_info)
	var party: BoxContainer = Forge.hbox(16)
	party.alignment = BoxContainer.ALIGNMENT_END if wide else BoxContainer.ALIGNMENT_CENTER
	party.size_flags_vertical = SIZE_SHRINK_END
	row.add_child(party)
	if wide:
		party.add_child(_party_row(52))
	var edit := Forge.link("party", "tab_squad", 22)
	edit.pressed.connect(func(): app.show_tab("party"))
	party.add_child(edit)
	var go := Forge.studs("set out", true, 76)
	go.custom_minimum_size.x = 200
	go.size_flags_vertical = SIZE_SHRINK_CENTER
	go.pressed.connect(func():
		app.run = Expedition.new().begin(_road, randi() % 100000)
		rebuild())
	party.add_child(go)
	var foot := Forge.hbox(12)
	col.add_child(foot)
	foot.add_child(_step_button("back", -1))
	_strip_scroll = ScrollContainer.new()
	_strip_scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	_strip_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_strip_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_strip_scroll.custom_minimum_size.y = THUMB.y + 6
	foot.add_child(_strip_scroll)
	_strip = Forge.hbox(10)
	_strip_scroll.add_child(_strip)
	foot.add_child(_step_button("next", 1))
	_show_road()


func _step_button(text: String, by: int) -> Button:
	var b := Forge.ember(text, roundi(THUMB.y))
	b.size_flags_vertical = SIZE_SHRINK_CENTER
	b.pressed.connect(func(): _road = Expedition.road_step(_road, by); _show_road())
	return b


## Crossfades the big view to the chosen road: the new painting comes in over the last, which goes once it's covered.
func _show_road() -> void:
	var r: Dictionary = Expedition.ROADS[_road]
	var region: Dictionary = Data.REGIONS[r.region]
	for old in _art_layer.get_children():
		get_tree().create_timer(Painted.FADE + 0.1).timeout.connect(old.queue_free)
	var art := Painted.new().setup(r.art)
	_art_layer.add_child(art)
	art.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for c in _air_layer.get_children():
		c.queue_free()
	var tint := Forge.wash(Color(region.dark, 0.9), Vector2.ZERO, Vector2(0.5, 0.5), true)
	_air_layer.add_child(tint)
	var air := Weather.over(r.art)
	if air:
		_air_layer.add_child(air)
		air.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for c in _info.get_children():
		c.queue_free()
	var head := Forge.hbox(16)
	_info.add_child(head)
	var badge := Forge.region_badge(r.region, 64)
	badge.size_flags_vertical = SIZE_SHRINK_CENTER
	head.add_child(badge)
	var name := Forge.sc(r.name, 46 if Forge.wide() else 36, Forge.PARCHMENT, true, 0.08)
	name.add_theme_color_override("font_shadow_color", Color.BLACK)
	head.add_child(name)
	var where := Forge.hbox(10)
	_info.add_child(where)
	where.add_child(_danger(r.danger))
	where.add_child(Forge.glyph("elem_" + r.elem, 20, Forge.ELEM[r.elem]))
	where.add_child(Forge.sc("%s · %d stops" % [region.name, r.depth], 18, Forge.LABEL))
	var about := Forge.label(r.about, 20, Forge.MUTED, Forge.SANS_ITALIC)
	about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	about.custom_minimum_size.x = 440 if Forge.wide() else 600
	about.add_theme_constant_override("line_spacing", ABOUT_LINES)
	_info.add_child(about)
	var at := _strip_scroll.scroll_horizontal
	for c in _strip.get_children():
		_strip.remove_child(c)
		c.queue_free()
	var active: Control
	for key in Expedition.ROADS:
		var t := _thumb(key)
		_strip.add_child(t)
		if key == _road:
			active = t
	_strip_scroll.scroll_horizontal = at
	_strip_scroll.ensure_control_visible.call_deferred(active)


## A road in the strip: its painting and name. The active one wears the moving rim.
func _thumb(key: String) -> Control:
	var r: Dictionary = Expedition.ROADS[key]
	var t := Control.new()
	t.custom_minimum_size = THUMB
	t.clip_contents = true
	t.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	t.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and key != _road:
			_road = key
			_show_road.call_deferred())
	var art := Painted.new().setup(r.art)
	t.add_child(art)
	art.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	if key == _road:
		art.modulate = Color(1, 1, 1, 0)
	t.add_child(Forge.wash(Color(Forge.INK, 0.95), Vector2(0.5, 1.0), Vector2(0.5, 0.3)))
	var name := Forge.sc(r.name.trim_prefix("The "), 15, Forge.GOLD_LIGHT if key == _road else Forge.PARCHMENT)
	name.mouse_filter = MOUSE_FILTER_IGNORE
	t.add_child(name)
	name.set_anchors_and_offsets_preset(PRESET_BOTTOM_LEFT)
	name.position += Vector2(10, -6)
	if key == _road:
		Rim.on(t, "flow", Rim.elem(r.elem), 3.0)
	Forge.press_weight(t, 0.97)
	return t


func _choose_road() -> void:
	head_right.add_child(_chip("gold", str(app.town.embers), "Gold in the caravan"))
	var big := Forge.link("big view", "", 22)
	big.pressed.connect(func():
		_grid = false
		rebuild())
	head_right.add_child(big)
	body.add_child(_heading("choose a road"))
	var roads := GridContainer.new()
	roads.columns = ROAD_COLS_WIDE if Forge.wide() else 1
	roads.add_theme_constant_override("h_separation", 18)
	roads.add_theme_constant_override("v_separation", 18)
	roads.size_flags_horizontal = SIZE_EXPAND_FILL
	body.add_child(roads)
	for key in Expedition.ROADS:
		roads.add_child(_road_card(key))
	body.add_child(_heading("the party"))
	var row := Forge.hbox(16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	if Forge.wide():
		# One line on a wide screen: the party standing, then the way to change them, then the commit.
		row.add_child(_party_row(62))
		var gap := Control.new()
		gap.custom_minimum_size.x = 40
		row.add_child(gap)
	else:
		body.add_child(_party_row())
	body.add_child(row)
	var party := Forge.link("edit party", "tab_squad", 22)
	party.pressed.connect(func(): app.show_tab("party"))
	row.add_child(party)
	var go := Forge.studs("set out", true, 84)
	go.custom_minimum_size.x = 300
	go.size_flags_vertical = SIZE_SHRINK_CENTER
	go.pressed.connect(func():
		app.run = Expedition.new().begin(_road, randi() % 100000)
		rebuild())
	row.add_child(go)


func _road_card(key: String) -> Control:
	var r: Dictionary = Expedition.ROADS[key]
	var region: Dictionary = Data.REGIONS[r.region]
	var on := key == _road
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Forge.flat(Color(Forge.PLAQUE, 0.96), Color(Forge.BRONZE, 0.0 if on else 0.6), 0 if on else 2, Vector4(0, 0, 0, 0)))
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if Forge.wide():
		card.size_flags_horizontal = SIZE_EXPAND_FILL
	card.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_road = key
			_grid = false
			rebuild())
	Forge.press_weight(card, 0.97)
	# The road's painting is the card: the region's colour washes in from the badge's corner and under the words.
	var scene := Control.new()
	scene.custom_minimum_size.y = CARD_H_WIDE if Forge.wide() else CARD_H
	scene.clip_contents = true
	scene.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(scene)
	var art := Painted.new().setup(r.art)
	scene.add_child(art)
	art.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	if on:
		art.modulate = Color(1, 1, 1, 0)
	scene.add_child(Forge.wash(Color(region.dark, 0.9), Vector2.ZERO, Vector2(0.62, 0.62), true))
	scene.add_child(Forge.wash(Color(region.dark.darkened(0.7)), Vector2(0.5, 1.0), Vector2(0.5, 0.3)))
	var badge := Forge.region_badge(r.region, 48 if Forge.wide() else 58)
	badge.position = Vector2(16, 16)
	scene.add_child(badge)
	var m := Forge.margins(MarginContainer.new(), 18, 0, 18, 11)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	scene.add_child(m)
	var v := Forge.vbox(1)
	v.alignment = BoxContainer.ALIGNMENT_END
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(v)
	var top := Forge.hbox(10)
	v.add_child(top)
	var name := Forge.sc(r.name, 22 if Forge.wide() else 26, Forge.GOLD_LIGHT if on else Forge.GOLD, true)
	name.size_flags_horizontal = SIZE_EXPAND_FILL
	top.add_child(name)
	var where := Forge.hbox(8)
	v.add_child(where)
	where.add_child(Forge.glyph("elem_" + r.elem, 18, Forge.ELEM[r.elem]))
	var stops := Forge.sc("%s · %d stops" % [region.name, r.depth], 16, Forge.LABEL)
	stops.size_flags_horizontal = SIZE_EXPAND_FILL
	where.add_child(stops)
	var d := _danger(r.danger)
	d.size_flags_vertical = SIZE_SHRINK_CENTER
	where.add_child(d)
	if on:
		var about := Forge.label(r.about, 16 if Forge.wide() else 18, Forge.MUTED, Forge.SANS_ITALIC)
		about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		about.custom_minimum_size.x = 200 if Forge.wide() else 360
		about.add_theme_constant_override("line_spacing", ABOUT_LINES)
		v.add_child(about)
		Rim.on(card, "flow", Rim.elem(r.elem), 3.0)
	return card


func _danger(n: int) -> Control:
	var row := Forge.hbox(4)
	row.tooltip_text = "Danger %d of 3" % n
	for i in 3:
		var d := Control.new()
		d.custom_minimum_size = Vector2(18, 18)
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var lit := i < n
		d.draw.connect(func(): Forge.diamond(d, d.size / 2, 7, Forge.HARM if lit else Color(Forge.DIM, 0.5), lit))
		row.add_child(d)
	return row


## The squad as faces, each with its health on the road under it; the fallen greyed out.
func _party_row(px := 112) -> Control:
	var row := Forge.hbox(14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for uid in app.col.squad:
		row.add_child(_face(uid, px))
	return row


func _face(uid: String, px := 112) -> Control:
	if Forge.wide():
		return _figure(uid, px)
	var c := app.col.by(uid)
	var h := Data.hero(c.hero)
	var hp := app.run.health(uid) if app.run else 1.0
	var v := Forge.vbox(6)
	var face := Control.new()
	face.custom_minimum_size = Vector2(px, px)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex: Texture2D = load(h.portrait.src)
	face.draw.connect(func():
		var r := Rect2(Vector2.ZERO, face.size)
		Forge.portrait(face, tex, r.grow(-2), h.portrait, 0.75, "squad")
		if hp <= 0.0:
			face.draw_rect(r, Color(Forge.INK, 0.65))
		face.draw_rect(r.grow(-1), Forge.ELEM[h.elem].darkened(0.1) if hp > 0.0 else Color(Forge.DIM, 0.5), false, 2.0)
		var bar := Rect2(6, r.size.y - 12, r.size.x - 12, 6)
		face.draw_rect(bar, Color(Forge.INK, 0.9))
		face.draw_rect(Rect2(bar.position, Vector2(bar.size.x * hp, bar.size.y)), Forge.GAIN if hp > 0.35 else BattleTile.HP_LOW))
	v.add_child(face)
	var l := Forge.sc(h.name, 16, Forge.MUTED if hp > 0.0 else Forge.DIM)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	return v


## The wide build's party member: standing, with their health on the road under their feet.
func _figure(uid: String, px: int) -> Control:
	var c := app.col.by(uid)
	var hp := app.run.health(uid) if app.run else -1.0
	var v := Forge.vbox(2)
	var s := Stand.new().setup(c.hero, c.stars, hp)
	s.custom_minimum_size = Vector2(px * 1.3, px * 2.4)
	v.add_child(s)
	var l := Forge.sc(Data.hero(c.hero).name, 15, Forge.MUTED if hp != 0.0 else Forge.DIM)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	return v


# ---------- on the road ----------

func _on_the_road() -> void:
	var run := app.run
	head_right.add_child(_chip("gold", str(run.embers), "Gold gathered on this road. It goes home to the caravan when the run ends."))
	var top := Forge.hbox(14)
	body.add_child(top)
	var r := run.info()
	top.add_child(Forge.glyph("elem_" + r.elem, 26, Forge.ELEM[r.elem]))
	var nm := Forge.sc(r.name, 26, Forge.GOLD, true)
	nm.size_flags_horizontal = SIZE_EXPAND_FILL
	top.add_child(nm)
	var home := Forge.link("turn back", "back", 20)
	home.tooltip_text = "End the run now and bring everything gathered home"
	home.pressed.connect(func():
		run.head_home()
		rebuild())
	top.add_child(home)
	if Forge.wide():
		top.add_child(_party_row(46))
		top.move_child(home, top.get_child_count() - 1)
	else:
		body.add_child(_party_row())
	if not run.boons.is_empty() or not run.picks.is_empty():
		body.add_child(_boon_row())
	_map = _road_map()
	body.add_child(_map)
	# Start with the next step in view.
	_scroll_to_next.call_deferred()
	if not run.pick_now.is_empty():
		_hero_pick.call_deferred()


func _boon_row() -> Control:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 10)
	row.add_theme_constant_override("v_separation", 10)
	for b in app.run.boons:
		var col: Color = Forge.RARITY[b.rarity]
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", Forge.flat(Color(Forge.INK, 0.7), Color(col, 0.9), 2, Vector4(12, 4, 14, 4)))
		p.tooltip_text = Expedition.boon_text(b)
		var h := Forge.hbox(8)
		p.add_child(h)
		h.add_child(Forge.glyph("node_boon", 20, col))
		h.add_child(Forge.sc(Expedition.BOONS[b.key].name, 18, col))
		row.add_child(p)
	for uid in app.run.picks:
		var c := app.col.by(uid)
		var skills: Array = Data.hero(c.hero).skills
		for k in app.run.picks[uid]:
			var aug: Dictionary = Data.AUGS[k.aug]
			var col: Color = Forge.ELEM[aug.fam]
			var p := PanelContainer.new()
			p.add_theme_stylebox_override("panel", Forge.flat(Color(Forge.INK, 0.7), Color(col, 0.9), 2, Vector4(12, 4, 14, 4)))
			p.tooltip_text = "%s · %s: %s" % [Data.hero(c.hero).name, skills[k.skill].name, aug.desc]
			var h := Forge.hbox(8)
			p.add_child(h)
			h.add_child(Forge.glyph("character", 20, col))
			h.add_child(Forge.sc("%s · %s" % [Data.hero(c.hero).name, aug.name], 18, col))
			row.add_child(p)
	return row


## Where a node sits on the map: layers rise from the foot (or run left to right on a wide screen).
func _node_pos(i: int, x: float, size: Vector2) -> Vector2:
	var n := app.run.layers.size()
	if Forge.wide():
		return Vector2(70 + i * (size.x - 140) / maxf(1, n - 1), 50 + x * (size.y - 100))
	return Vector2(50 + x * (size.x - 100), size.y - 70 - i * LAYER)


func _road_map() -> Control:
	var run := app.run
	var m := Control.new()
	var n := run.layers.size()
	m.custom_minimum_size = Vector2(0, 440) if Forge.wide() else Vector2(0, 140 + (n - 1) * LAYER)
	m.mouse_filter = Control.MOUSE_FILTER_PASS
	var next := run.choices()
	m.draw.connect(func():
		# The paths: gold where you have walked, faint ahead.
		for i in n - 1:
			for j in run.layers[i].size():
				var a := _node_pos(i, run.layers[i][j].x, m.size)
				for k in run.layers[i][j].next:
					var b := _node_pos(i + 1, run.layers[i + 1][k].x, m.size)
					var walked := run.at == Vector2i(i + 1, k) and (i == run.at.x - 1)
					var from_here := Vector2i(i, j) == run.at and Vector2i(i + 1, k) in next
					var col := Color(Forge.GOLD, 0.9) if walked or from_here else Color(Forge.DIM, 0.28)
					_dashed(m, a, b, col, 3.0 if from_here else 2.0))
	for i in n:
		for j in run.layers[i].size():
			m.add_child(_node(Vector2i(i, j), Vector2i(i, j) in next))
	m.resized.connect(func():
		for c in m.get_children():
			if c is MapNode:
				c.position = _node_pos(c.at.x, run.layers[c.at.x][c.at.y].x, m.size) - Vector2(NODE_R, NODE_R) * 1.5)
	return m


func _dashed(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, w: float) -> void:
	var d := a.distance_to(b)
	var dir := (b - a) / d
	var t := NODE_R + 4.0
	while t < d - NODE_R - 4.0:
		ci.draw_line(a + dir * t, a + dir * minf(t + 10.0, d - NODE_R - 4.0), col, w, true)
		t += 18.0


func _node(p: Vector2i, open: bool) -> Control:
	var run := app.run
	var nd: Dictionary = run.node(p)
	var c := MapNode.new()
	c.at = p
	c.kind = nd.type
	c.rarity = nd.rarity
	c.open = open
	c.here = run.at == p
	c.past = p.x < run.at.x or (p.x == run.at.x and not c.here)
	c.custom_minimum_size = Vector2(NODE_R, NODE_R) * 3.0
	c.size = c.custom_minimum_size
	c.tooltip_text = "%s · %s" % [Expedition.NODES[nd.type].name, Expedition.NODES[nd.type].about]
	if open:
		c.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		c.gui_input.connect(func(e: InputEvent):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				Burst.on(c, Forge.GOLD_LIGHT, 50, 8)
				_go(p))
		Forge.press_weight(c, 0.9)
	return c


func _scroll_to_next() -> void:
	if Forge.wide() or _map == null:
		return
	var scroll := body.get_parent().get_parent() as ScrollContainer
	await get_tree().process_frame
	var y := _node_pos(maxi(app.run.at.x + 1, 0), 0.5, _map.size).y + _map.position.y
	scroll.scroll_vertical = int(maxf(0.0, y - scroll.size.y * 0.55))


## Step onto a node and do what it holds.
func _go(p: Vector2i) -> void:
	var run := app.run
	if not run.step(p):
		return
	var t: String = run.node(p).type
	match t:
		"battle", "elite", "boss":
			await get_tree().create_timer(0.25).timeout
			app.show_fight()
		"rest":
			var lvl := app.town.level("infirmary")
			var share := run.rest(lvl)
			_event("node_rest", "camp", 0, func(v: VBoxContainer):
				v.add_child(_para("The squad makes camp. Everyone still standing heals %d%% of their health." % roundi(share * 100)))
				_camp_talk(v)
				if lvl < Town.BUILDINGS.infirmary.max:
					v.add_child(_note("A higher Infirmary in the town makes camps heal more."))
				v.add_child(_party_row()))
		"boon":
			_boon_pick(p)
		"wayside":
			_wayside(p)
	if not t in ["battle", "elite", "boss"]:
		rebuild()
		app.music(t)


# ---------- what happens at a node ----------

## A panel over the screen for a node's event; the studs button closes it.
## Someone at the fire says something: a living squad member with a face and camp lines, at random.
func _camp_talk(v: VBoxContainer) -> void:
	var who := []
	for uid in app.col.squad:
		var key: String = app.col.by(uid).hero
		if app.run.health(uid) > 0.0 and Bust.has_faces(key) and Speech.line_for(key, "camp") != "":
			who.append(key)
	if who.is_empty():
		return
	var key: String = who.pick_random()
	var row := Forge.hbox(10)
	v.add_child(row)
	var bust := Bust.new().setup(key)
	bust.melt = 0.3
	bust.custom_minimum_size = Vector2(200, 200)
	row.add_child(bust)
	var line := Speech.say(row, key, Speech.line_for(key, "camp"), 310.0, true)
	line.size_flags_vertical = SIZE_SHRINK_CENTER
	bust.say.call_deferred()


func _event(icon_name: String, heading: String, rarity: int, fill: Callable, close_text := "go on", hero_key := "", words := []) -> void:
	var shade := Control.new()
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	app.add_child(shade)
	shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	# A choice on a wide screen is a stage of its own: the hero beside it, the title across the top, terms to the right.
	var stage := hero_key != "" and Forge.wide()
	shade.draw.connect(func(): shade.draw_rect(Rect2(Vector2.ZERO, shade.size), Color(Forge.INK, 0.9 if stage else 0.78)))
	var col: Color = Forge.RARITY[rarity] if rarity > 0 else Forge.GOLD
	if stage:
		_stage(shade, hero_key, heading, col, rarity, words)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	shade.add_child(center)
	if stage:
		center.offset_left = STAGE_LEFT
		center.offset_right = -STAGE_RIGHT
		center.offset_top = STAGE_TOP
	var panel := PanelContainer.new()
	if stage:
		panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	else:
		panel.add_theme_stylebox_override("panel", Forge.flat(Forge.PLAQUE, Color.TRANSPARENT, 0, Vector4(40, 36, 40, 36)))
		Rim.on(panel, "flow" if rarity >= 2 else "comet", [col, col.lightened(0.4), Forge.GOLD_LIGHT, col.darkened(0.3)] if rarity >= 2 else [col], 3.0).sparkles = rarity >= 3
	panel.custom_minimum_size.x = STAGE_W if stage else 600.0
	center.add_child(panel)
	var v := Forge.vbox(20)
	panel.add_child(v)
	if not stage:
		var head := Forge.hbox(14)
		v.add_child(head)
		head.add_child(Forge.glyph(icon_name, 44, col))
		head.add_child(Forge.sc(heading, 34, col, true, 0.16))
		if rarity > 0:
			var tag := Forge.sc(Expedition.RARITIES[rarity], 18, col)
			tag.size_flags_vertical = SIZE_SHRINK_CENTER
			head.add_child(tag)
	fill.call(v)
	if close_text != "":
		var done := Forge.studs(close_text, true, 76)
		done.pressed.connect(func():
			shade.queue_free()
			rebuild())
		v.add_child(done)
	panel.pivot_offset = Vector2(300, 200)
	panel.scale = Vector2(0.92, 0.92)
	panel.modulate.a = 0.0
	var tw := panel.create_tween().set_parallel()
	tw.tween_property(panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, 0.16)


## The parts of a choice's stage: the hero standing at the left, the title across the top, and the terms the offers use.
func _stage(shade: Control, hero_key: String, heading: String, col: Color, rarity: int, words: Array) -> void:
	var s := Stand.new().setup(hero_key, app.col.by(app.copies(hero_key)[0].uid).stars)
	s.tall = 0.96
	s.size = Vector2(430, 640)
	s.position = Vector2(-10, 76)
	shade.add_child(s)
	var band := ColorRect.new()
	band.color = Color(Forge.PLAQUE, 0.92)
	band.set_anchors_preset(PRESET_TOP_WIDE)
	band.offset_bottom = STAGE_TOP - 16.0
	shade.add_child(band)
	band.draw.connect(func():
		band.draw_line(Vector2(0, band.size.y - 1), Vector2(band.size.x, band.size.y - 1), Color(col, 0.8), 2.0))
	var title := Forge.sc(heading, 34, col if rarity > 0 else Forge.PARCHMENT, false, 0.3)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.set_anchors_preset(PRESET_FULL_RECT)
	band.add_child(title)
	var side := Forge.vbox(12)
	side.anchor_left = 1.0
	side.anchor_right = 1.0
	side.offset_left = -STAGE_RIGHT + 14.0
	side.offset_right = -24.0
	side.offset_top = STAGE_TOP + 20.0
	shade.add_child(side)
	for w in words:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", Forge.flat(Color(Forge.INK, 0.85), Color(Forge.GOLD_DEEP, 0.6), 1, Vector4(16, 12, 16, 12)))
		side.add_child(p)
		var t := Forge.vbox(4)
		p.add_child(t)
		t.add_child(Forge.sc(w[0], 18, Forge.GOLD_LIGHT, true))
		var d := Forge.label(w[1], 18, Forge.PARCHMENT)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.add_child(d)


## The terms that the offers' words use, explained for the side of the stage.
func _terms_in(texts: Array) -> Array:
	var all := " ".join(texts).to_lower()
	var out := []
	for s in CodexScreen.STATUSES + STAGE_TERMS:
		if s[0].to_lower() in all and out.size() < 3:
			out.append([s[0], s[-1]])
	return out


## Who stands beside a choice for the whole squad: the first hero still on their feet.
func _lead() -> String:
	for uid in app.col.squad:
		if app.run == null or app.run.health(uid) > 0.0:
			return app.col.by(uid).hero
	return app.col.by(app.col.squad[0]).hero


## The picture on a boon's card, by what it raises.
static func boon_glyph(key: String) -> String:
	return {"atk": "atk", "def": "def", "spd": "spd", "max_hp": "hp", "atk_elem": "atk", "embers": "gold"}.get(Expedition.BOONS[key].stat, "node_boon")


func _boon_pick(p: Vector2i) -> void:
	var run := app.run
	var offers := run.offers(p)
	var rarity: int = run.node(p).rarity
	var holder := [null]
	var words := _terms_in(offers.map(func(b): return Expedition.boon_text(b)))
	_event("node_boon", "choose a boon", rarity, func(v: VBoxContainer):
		v.add_child(_para("A blessing for the rest of this road. Take one."))
		for b in offers:
			var col: Color = Forge.RARITY[b.rarity]
			var card := _offer_card(boon_glyph(b.key), col, Expedition.BOONS[b.key].name, Expedition.boon_text(b), b.rarity)
			card.pressed.connect(func():
				run.take(b)
				Burst.on(card, col, 60, 10)
				await get_tree().create_timer(0.3).timeout
				_close_event(holder[0])
				rebuild())
			v.add_child(card)
		holder[0] = v, "", _lead(), words)


## One choice in an event: a glyph, a name and what it does. Rare ones turn a comet round the edge.
func _offer_card(glyph_name: String, col: Color, heading: String, text: String, rarity: int) -> Button:
	var card := Button.new()
	card.focus_mode = Control.FOCUS_NONE
	card.custom_minimum_size = Vector2(0, 124 if Forge.wide() else 104)
	card.add_theme_stylebox_override("normal", Forge.flat(Color(Forge.INK, 0.8), Color(col, 0.55), 2))
	card.add_theme_stylebox_override("hover", Forge.flat(Color(Forge.INK, 0.9), col, 2))
	card.add_theme_stylebox_override("pressed", Forge.flat(Color(Forge.INK, 0.9), col, 2))
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	Forge.press_weight(card, 0.96)
	var m := Forge.margins(MarginContainer.new(), 20, 12, 20, 12)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.set_anchors_preset(PRESET_FULL_RECT)
	card.add_child(m)
	var h := Forge.hbox(16)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(h)
	h.add_child(_offer_badge(glyph_name, col))
	var tv := Forge.vbox(2)
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.size_flags_horizontal = SIZE_EXPAND_FILL
	h.add_child(tv)
	tv.add_child(Forge.sc(heading, 24, col, true))
	var d := Forge.label(text, 21, Forge.PARCHMENT)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tv.add_child(d)
	if rarity >= 2:
		Rim.on(card, "comet", [col], 2.0)
	return card


## An offer's picture in a diamond of its rarity's colour.
func _offer_badge(glyph_name: String, col: Color) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(84, 84)
	c.size_flags_vertical = SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var m := c.size / 2.0
		var d := PackedVector2Array([m + Vector2(0, -40), m + Vector2(40, 0), m + Vector2(0, 40), m + Vector2(-40, 0)])
		c.draw_colored_polygon(d, Color(col, 0.16))
		c.draw_polyline(d + PackedVector2Array([d[0]]), col, 2.0, true)
		c.draw_texture_rect(Forge.icon(glyph_name), Rect2(m - Vector2(21, 21), Vector2(42, 42)), false, col))
	return c


## Closes the event whose content box is `v`.
func _close_event(v: Control) -> void:
	v.get_parent().get_parent().get_parent().queue_free()


# ---------- hero picks ----------

## After a won fight: one hero chooses an upgrade for the rest of the road, or rerolls, or skips for embers.
func _hero_pick() -> void:
	var run := app.run
	var uid: String = run.pick_now.uid
	var hero := Data.hero(app.col.by(uid).hero)
	var holder := [null]
	var words := _terms_in(run.pick_now.options.map(func(o): return _pick_text(o)))
	_event("character", "%s grows" % hero.name, 0, func(v: VBoxContainer):
		holder[0] = v
		var top := Forge.hbox(16)
		v.add_child(top)
		# A wide screen is short, and the heading already names them, so only the phone shows the face.
		if not Forge.wide():
			top.add_child(_face(uid, 92))
		var line := _para("A change that lasts for this road. It holds for %s alone." % hero.name)
		line.size_flags_horizontal = SIZE_EXPAND_FILL
		top.add_child(line)
		for o in run.pick_now.options:
			var col: Color = Forge.RARITY[o.rarity]
			var card := _offer_card("elem_" + Data.AUGS[o.aug].fam, col, run.pick_preview(o).name, _pick_text(o), o.rarity)
			card.pressed.connect(func():
				if run.picks_full(uid):
					_close_event(v)
					_replace_pick(o)
					return
				run.take_pick(o)
				Sfx.play("confirm")
				Burst.on(card, col, 60, 10)
				await get_tree().create_timer(0.3).timeout
				_close_event(v)
				rebuild())
			v.add_child(card)
		var foot := Forge.hbox(14)
		v.add_child(foot)
		var price := run.reroll_price()
		var again := Forge.ember("reroll · %s" % ("free (%d)" % run.rerolls if price == 0 else "%d gold" % price), 64)
		again.add_theme_font_size_override("font_size", 20)
		again.size_flags_horizontal = SIZE_EXPAND_FILL
		again.disabled = not run.can_reroll()
		again.pressed.connect(func():
			run.reroll_pick()
			Sfx.play("tap")
			_close_event(v)
			_hero_pick())
		foot.add_child(again)
		var skip := Forge.link("skip · +%d gold" % run.skip_share(), "chevron", 20)
		skip.pressed.connect(func():
			run.skip_pick()
			_close_event(v)
			rebuild())
		foot.add_child(skip), "", hero.key, words)


## What a pick does, and the numbers it moves on that skill.
func _pick_text(o: Dictionary) -> String:
	var run := app.run
	var was := run.pick_before(o)
	var now := run.pick_preview(o)
	var text: String = Data.AUGS[o.aug].desc.split(".")[0] + "."
	if now.cd != was.cd:
		text += " Cooldown %d → %d." % [was.cd, now.cd]
	if not is_equal_approx(now.power, was.power):
		text += " Power %d%% → %d%%." % [roundi(was.power * 100), roundi(now.power * 100)]
	return text


## A full hero gives up an old pick for the new one, or goes back to the offer.
func _replace_pick(o: Dictionary) -> void:
	var run := app.run
	var uid: String = run.pick_now.uid
	var c := app.col.by(uid)
	var skills: Array = Data.hero(c.hero).skills
	_event("character", "replace which?", 0, func(v: VBoxContainer):
		v.add_child(_para("%s holds %d picks on a road. %s takes the place of one." % [Data.hero(c.hero).name, Expedition.PICK_SLOTS, run.pick_preview(o).name]))
		var held: Array = run.picks[uid]
		for i in held.size():
			var aug: Dictionary = Data.AUGS[held[i].aug]
			var card := _offer_card("swap", Forge.ELEM[aug.fam], "%s · %s" % [skills[held[i].skill].name, aug.name], aug.desc.split(".")[0] + ".", 0)
			card.pressed.connect(func():
				run.take_pick(o, i)
				Sfx.play("confirm")
				_close_event(v)
				rebuild())
			v.add_child(card)
		var back := Forge.link("back to the offer", "back", 20)
		back.pressed.connect(func():
			_close_event(v)
			_hero_pick())
		v.add_child(back), "", c.hero)


# ---------- the wayside ----------

## A wayside stop: the event's scene and its choices, in the panel every stop uses. See design/events.md.
func _wayside(p: Vector2i) -> void:
	var run := app.run
	var key := run.draw_event(p)
	var ev: Dictionary = Events.LIST[key]
	_event("node_wayside", ev.title, run.node(p).rarity, func(v: VBoxContainer):
		# A wide screen is short, so the panel widens to keep the longest scene with four choices on it.
		v.custom_minimum_size.x = 900.0 if Forge.wide() else 0.0
		v.add_child(_para(ev.scene))
		var list := Forge.vbox(10)
		v.add_child(list)
		var squad := {}
		for uid in app.col.squad:
			squad[uid] = app.col.by(uid).hero
		for c in run.event_choices(key, squad):
			var b := Forge.ember(c.text, 60)
			b.add_theme_font_size_override("font_size", 22)
			b.disabled = not run.can_pay(c)
			b.pressed.connect(_choose_wayside.bind(c, v, list))
			list.add_child(b)
			var terms := run.event_terms(c)
			if terms != "":
				var t := Forge.sc(terms, 18, Forge.MUTED, true)
				t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				list.add_child(t), "")


## A choice is made: pay, then roll if it asks for a hero, flip if it's luck, or simply happen.
func _choose_wayside(c: Dictionary, v: VBoxContainer, list: Control) -> void:
	var run := app.run
	run.event_pay(c)
	list.queue_free()
	if c.has("roll"):
		_wayside_roll(c, v)
	elif c.has("luck"):
		_wayside_outcome(c.win if randi() % 2 == 0 else c.lose, "", v)
	else:
		_wayside_outcome(c.do, c.get("uid", ""), v)


## Who tries a roll: the standing squad, as a trial always was. The odds are on the buttons.
func _wayside_roll(c: Dictionary, v: VBoxContainer) -> void:
	var run := app.run
	var apt: String = c.roll
	var test := _note("A test of %s: %s. Choose who tries. Roll d20 and reach %d; a hero who favors %s adds +%d." % [
		apt, Data.APTITUDES[apt].to_lower(), Expedition.ROLL_DC, apt, Data.FAVORED_BONUS])
	v.add_child(test)
	var row := GridContainer.new()
	row.columns = 2
	row.add_theme_constant_override("h_separation", 12)
	row.add_theme_constant_override("v_separation", 12)
	v.add_child(row)
	for uid in app.col.squad:
		if run.fallen(uid):
			continue
		var hero := Data.hero(app.col.by(uid).hero)
		var fav: bool = apt in hero.get("favored", [])
		var b := Forge.ember(hero.name + (" +%d" % Data.FAVORED_BONUS if fav else ""), 64)
		b.add_theme_font_size_override("font_size", 20)
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.pressed.connect(func():
			row.queue_free()
			test.queue_free()
			var roll := randi() % 20 + 1
			var total := roll + (Data.FAVORED_BONUS if fav else 0)
			v.add_child(Forge.sc("d20 · %d%s = %d vs %d" % [roll, " + %d" % Data.FAVORED_BONUS if fav else "", total, Expedition.ROLL_DC], 26, Forge.GOLD_LIGHT, true))
			_wayside_outcome(c.win if Expedition.roll_wins(roll, fav) else c.lose, uid, v))
		row.add_child(b)


## What came of it, in place of the scene so the panel stays on a wide screen, then the one way on: back to the road,
## or into the fight it started.
func _wayside_outcome(o: Dictionary, uid: String, v: VBoxContainer) -> void:
	var run := app.run
	var got := run.event_apply(o, uid)
	v.get_child(1).queue_free()
	var key: String = app.col.by(uid).hero if uid != "" else ""
	if key != "" and Bust.has_faces(key) and not got.has("hurt"):
		var row := Forge.hbox(10)
		v.add_child(row)
		var bust := Bust.new().setup(key)
		bust.melt = 0.3
		bust.custom_minimum_size = Vector2(160, 160)
		row.add_child(bust)
		var words := _para(got.say)
		words.custom_minimum_size.x = 340
		words.size_flags_vertical = SIZE_SHRINK_CENTER
		row.add_child(words)
	else:
		v.add_child(_para(got.say))
	if got.get("gold", 0) > 0:
		v.add_child(_gain("gold", "+%d gold" % got.gold))
	if got.get("gold", 0) < 0:
		v.add_child(_note("%d gold gone." % -got.gold))
	if got.has("debt"):
		v.add_child(_note("%d gold owed when you bank." % got.debt))
	if got.has("heal"):
		v.add_child(_gain("role_healer", "the squad heals %d%%" % roundi(got.heal * 100)))
	if got.has("hurt"):
		v.add_child(_note("%s loses %d%% health." % [Data.hero(key).name, roundi(got.hurt * 100)]))
	if got.has("hurt_all"):
		v.add_child(_note("Everyone loses %d%% health." % roundi(got.hurt_all * 100)))
	if got.has("boon"):
		v.add_child(_gain("node_boon", "%s · %s" % [Expedition.BOONS[got.boon.key].name, Expedition.boon_text(got.boon)]))
	if got.has("augment"):
		app.col.loose.append(got.augment)
		v.add_child(_gain("augment", "+1 augment · %s" % Data.AUGS[got.augment].name))
	if got.has("rerolls"):
		v.add_child(_gain("node_boon", "+%d free rerolls" % got.rerolls))
	if got.has("raise"):
		v.add_child(_gain("role_healer", "%s stands at %d%% health" % [Data.hero(key).name, roundi(got.raise * 100)]))
	var done := Forge.studs("to arms" if got.has("fight") else "go on", true, 76)
	done.pressed.connect(func():
		_close_event(v)
		if got.has("fight"):
			app.show_fight()
		else:
			rebuild())
	v.add_child(done)


# ---------- the end of the road ----------

func _summary() -> void:
	var run := app.run
	var win := run.over == "win"
	var heading: String = {"win": "the road is cleared", "home": "home again", "lose": "the squad fell"}[run.over]
	body.add_child(_heading(run.info().name))
	var v := Forge.vbox(16)
	body.add_child(v)
	v.add_child(Forge.sc(heading, 44, Forge.GOLD if run.over != "lose" else Forge.MUTED, true, 0.14))
	var text: String = {"win": "The warden is down. Everything gathered goes home.", "home": "You turned for home with what you had.",
		"lose": "The squad was carried home. Half of what they gathered made it back."}[run.over]
	v.add_child(_para(text))
	v.add_child(_gain("gold", "%d gold to the caravan" % run.banked()))
	if not run.boons.is_empty() or not run.picks.is_empty():
		v.add_child(_note("Boons and hero picks fade when the road ends:"))
		v.add_child(_boon_row())
	var go := Forge.studs("bank and go home", true, 84)
	go.size_flags_horizontal = SIZE_SHRINK_CENTER
	go.pressed.connect(func():
		app.town.earn(run.banked())
		if win:
			app.town.felled += 1
		app.run = null
		app.show_tab("town"))
	v.add_child(go)
	if win:
		Burst.on(v, Forge.GOLD_LIGHT, 120, 14)


# ---------- small pieces ----------

func _heading(text: String) -> Control:
	var h := Forge.hbox(16)
	h.add_child(Forge.sc(text, 22, Forge.GOLD))
	var line := Control.new()
	line.size_flags_horizontal = SIZE_EXPAND_FILL
	line.custom_minimum_size.y = 28
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.draw.connect(func(): line.draw_line(Vector2(0, line.size.y / 2), Vector2(line.size.x, line.size.y / 2), Color(Forge.GOLD_DEEP, 0.5), 2.0))
	h.add_child(line)
	return h


func _chip(glyph_name: String, text: String, tip: String) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Forge.flat(Forge.PLAQUE, Color(Forge.BRONZE, 0.9), 2, Vector4(18, 6, 18, 6)))
	p.size_flags_vertical = SIZE_SHRINK_CENTER
	p.tooltip_text = tip
	var h := Forge.hbox(10)
	p.add_child(h)
	h.add_child(Forge.glyph(glyph_name, 26, Forge.GOLD_LIGHT))
	h.add_child(Forge.label(text, 26, Forge.PARCHMENT, Forge.SANS_BOLD))
	return p


func _para(text: String) -> Label:
	var l := Forge.label(text, 24, Forge.PARCHMENT)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 500
	return l


func _note(text: String) -> Label:
	var l := Forge.label(text, 21, Forge.DIM, Forge.SANS_ITALIC)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 500
	return l


func _gain(glyph_name: String, text: String) -> Control:
	var h := Forge.hbox(10)
	h.add_child(Forge.glyph(glyph_name, 26, Forge.GAIN))
	h.add_child(Forge.sc(text, 24, Forge.GAIN, true))
	return h


## A stop on the map: a disc with the node's icon. Open nodes wear a turning ring; where you stand is gold; the road
## behind you dims; boons show their rarity in the ring.
class MapNode extends Control:
	var at := Vector2i.ZERO
	var kind := "battle"
	var rarity := 0
	var open := false
	var here := false
	var past := false
	var _t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP if open else Control.MOUSE_FILTER_IGNORE
		_t = randf() * 3.0

	func _process(delta: float) -> void:
		if open or here:
			_t += delta
			queue_redraw()

	func _draw() -> void:
		var c := size / 2
		var r := ExpeditionScreen.NODE_R
		var big := kind == "boss"
		if big:
			r *= 1.3
		var tint: Color = Forge.RARITY[rarity] if kind == "boon" and rarity > 0 else (Forge.HARM if kind in ["elite", "boss"] else Forge.GOLD)
		var dim := past and not here
		if open:
			var k := 0.5 + 0.5 * sin(_t * TAU * 0.7)
			draw_circle(c, r + 10 + 4 * k, Color(tint, 0.12 + 0.1 * k))
		draw_circle(c, r, Forge.INK)
		draw_circle(c, r - 3, Forge.PLAQUE if not dim else Forge.PLAQUE_DEEP)
		var ring := Color(tint, 0.25 if dim else (0.95 if open or here else 0.5))
		draw_arc(c, r - 1.5, 0, TAU, 48, ring, 3.0, true)
		if open:
			var head := fposmod(_t * 0.5, 1.0) * TAU
			for i in 14:
				var k := i / 13.0
				draw_arc(c, r + 5, head - 0.9 * (1 - k) - 0.08, head - 0.9 * (1 - k), 4, Color(tint.lightened(0.3), k), 3.0, true)
		if here:
			draw_arc(c, r + 6, 0, TAU, 48, Forge.GOLD_LIGHT, 2.0, true)
		var g := r * 1.1
		draw_texture_rect(Forge.icon(Expedition.NODES[kind].icon), Rect2(c - Vector2(g, g) / 2, Vector2(g, g)), false,
			Color(tint.lightened(0.25) if not dim else Forge.DIM, 1.0 if not dim else 0.45))
