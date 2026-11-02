class_name ExpeditionScreen
extends RunChoices
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
	_road = app.road_pick if app.road_pick != "" else app.scene_road
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
	# As on a map: the region lit beside its name, small and spaced, and the road named large below it.
	var head := Forge.hbox(12)
	_info.add_child(head)
	var glow := Forge.region_glow(r.region, 96)
	glow.size_flags_vertical = SIZE_SHRINK_CENTER
	head.add_child(glow)
	var land := Forge.sc(region.name, 20, Forge.GOLD, false, 0.4)
	land.add_theme_color_override("font_shadow_color", Color.BLACK)
	land.size_flags_vertical = SIZE_SHRINK_CENTER
	head.add_child(land)
	var name := Forge.sc(r.name, 46 if Forge.wide() else 36, Forge.PARCHMENT, true, 0.08)
	name.add_theme_color_override("font_shadow_color", Color.BLACK)
	_info.add_child(name)
	var where := Forge.hbox(10)
	_info.add_child(where)
	where.add_child(_danger(r.danger))
	where.add_child(Forge.glyph("elem_" + r.elem, 20, Forge.ELEM[r.elem]))
	where.add_child(Forge.sc("%d stops" % r.depth, 18, Forge.LABEL))
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
	if not run.boons.is_empty() or not run.picks.is_empty() or run.grace != "":
		var row := _boon_row()
		if Forge.wide():
			# A wide screen is short: the row shares the road's line, beside its name, so the map keeps its height.
			nm.size_flags_horizontal = SIZE_FILL
			row.size_flags_horizontal = SIZE_EXPAND_FILL
			row.size_flags_vertical = SIZE_SHRINK_CENTER
			top.add_child(row)
			top.move_child(row, 2)
		else:
			body.add_child(row)
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
	var g := Graces.by(app.run.grace)
	if not g.is_empty():
		# The Grace who blesses the run leads the row, in gold, with her blessing on hover.
		var gp := PanelContainer.new()
		gp.add_theme_stylebox_override("panel", Forge.flat(Color(Forge.PLAQUE, 0.9), Forge.GOLD_LIGHT, 2, Vector4(12, 4, 14, 4)))
		gp.tooltip_text = g.blessing
		var gh := Forge.hbox(8)
		gp.add_child(gh)
		gh.add_child(Forge.glyph("node_shrine", 20, Forge.ELEM.get(g.elem, Forge.GOLD_LIGHT)))
		gh.add_child(Forge.sc("%s's blessing" % g.name, 18, Forge.GOLD_LIGHT))
		row.add_child(gp)
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
		"shrine":
			_shrine(p)
	if not t in ["battle", "elite", "boss"]:
		rebuild()
		app.music(t)


# ---------- what happens at a node ----------

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
	if not run.boons.is_empty() or not run.picks.is_empty() or run.grace != "":
		v.add_child(_note("Blessings, boons and hero picks fade when the road ends:"))
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
