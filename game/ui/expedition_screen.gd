class_name ExpeditionScreen
extends Screen
## Expedition, the centre of the game. Between runs: pick a road (each a region, an element and a danger), check the
## party, set out. On the road: the map of the run, read from the start at the foot to the warden at the top (left to
## right on a wide screen). The nodes you can step to next are ringed and turning; tap one to go there. Fights open the
## battle; camps, boons, caches and trials open over the map. When the run ends, its embers go home to the town.

const NODE_R := 38.0
const LAYER := 150.0
const ROW := 120.0

var _road := "basalt"
var _map: Control


func _init() -> void:
	tab = "expedition"
	title = "expedition"


func _build() -> void:
	if app.run == null:
		_choose_road()
	elif app.run.over != "":
		_summary()
	else:
		_on_the_road()


# ---------- between runs: choose a road ----------

func _choose_road() -> void:
	head_right.add_child(_chip("ember", str(app.town.embers), "Embers in the town"))
	body.add_child(_heading("choose a road"))
	var roads: BoxContainer = Forge.hbox(18) if Forge.wide() else Forge.vbox(18)
	body.add_child(roads)
	for key in Expedition.ROADS:
		roads.add_child(_road_card(key))
	body.add_child(_heading("the party"))
	body.add_child(_party_row())
	var row := Forge.hbox(16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(row)
	var party := Forge.link("edit party", "tab_squad", 22)
	party.pressed.connect(func(): app.show_tab("party"))
	row.add_child(party)
	var go := Forge.studs("set out", true, 84)
	go.custom_minimum_size.x = 300
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
			rebuild())
	Forge.press_weight(card, 0.97)
	var h := Forge.hbox(0)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(h)
	# The region's colours down the left edge, its sigil on them.
	var band := Forge.region_swatch(r.region, Vector2(110, 0))
	band.size_flags_vertical = SIZE_EXPAND_FILL
	h.add_child(band)
	var badge := Forge.region_badge(r.region, 64)
	badge.position = Vector2(23, 20)
	band.add_child(badge)
	var m := Forge.margins(MarginContainer.new(), 26, 20, 26, 22)
	m.size_flags_horizontal = SIZE_EXPAND_FILL
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(m)
	var v := Forge.vbox(8)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(v)
	var top := Forge.hbox(10)
	v.add_child(top)
	var name := Forge.sc(r.name, 26, Forge.GOLD_LIGHT if on else Forge.GOLD, true)
	name.size_flags_horizontal = SIZE_EXPAND_FILL
	top.add_child(name)
	top.add_child(_danger(r.danger))
	var where := Forge.hbox(8)
	v.add_child(where)
	where.add_child(Forge.glyph("elem_" + r.elem, 20, Forge.ELEM[r.elem]))
	where.add_child(Forge.sc("%s · %d stops" % [region.name, r.depth], 18, Forge.LABEL))
	var about := Forge.label(r.about, 20, Forge.MUTED, Forge.SANS_ITALIC)
	about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	about.custom_minimum_size.x = 360
	v.add_child(about)
	if on:
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
func _party_row() -> Control:
	var row := Forge.hbox(14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for uid in app.col.squad:
		row.add_child(_face(uid))
	return row


func _face(uid: String) -> Control:
	var c := app.col.by(uid)
	var h := Data.hero(c.hero)
	var hp := app.run.health(uid) if app.run else 1.0
	var v := Forge.vbox(6)
	var face := Control.new()
	face.custom_minimum_size = Vector2(112, 112)
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


# ---------- on the road ----------

func _on_the_road() -> void:
	var run := app.run
	head_right.add_child(_chip("ember", str(run.embers), "Embers gathered on this road. They go home to the town when the run ends."))
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
	body.add_child(_party_row())
	if not run.boons.is_empty():
		body.add_child(_boon_row())
	_map = _road_map()
	body.add_child(_map)
	# Start with the next step in view.
	_scroll_to_next.call_deferred()


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
				if lvl < Town.BUILDINGS.infirmary.max:
					v.add_child(_note("A higher Infirmary in the town makes camps heal more."))
				v.add_child(_party_row()))
		"boon":
			_boon_pick(p)
		"cache":
			var got := run.open_cache()
			var aug := ""
			if got.augment:
				var keys := Data.AUGS.keys()
				aug = keys[randi() % keys.size()]
				app.col.loose.append(aug)
			_event("node_cache", "cache", run.node(p).rarity, func(v: VBoxContainer):
				v.add_child(_para("Something left on the road."))
				v.add_child(_gain("ember", "+%d embers" % got.embers))
				if aug != "":
					v.add_child(_gain("augment", "+1 augment · %s" % Data.AUGS[aug].name)))
		"trial":
			_trial(p)
	if not t in ["battle", "elite", "boss"]:
		rebuild()


# ---------- what happens at a node ----------

## A panel over the screen for a node's event; the studs button closes it.
func _event(icon_name: String, heading: String, rarity: int, fill: Callable, close_text := "go on") -> void:
	var shade := Control.new()
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	app.add_child(shade)
	shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	shade.draw.connect(func(): shade.draw_rect(Rect2(Vector2.ZERO, shade.size), Color(Forge.INK, 0.78)))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	shade.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Forge.flat(Forge.PLAQUE, Color.TRANSPARENT, 0, Vector4(40, 36, 40, 36)))
	panel.custom_minimum_size.x = 600
	center.add_child(panel)
	var col: Color = Forge.RARITY[rarity] if rarity > 0 else Forge.GOLD
	Rim.on(panel, "flow" if rarity >= 2 else "comet", [col, col.lightened(0.4), Forge.GOLD_LIGHT, col.darkened(0.3)] if rarity >= 2 else [col], 3.0).sparkles = rarity >= 3
	var v := Forge.vbox(20)
	panel.add_child(v)
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


func _boon_pick(p: Vector2i) -> void:
	var run := app.run
	var offers := run.offers(p)
	var rarity: int = run.node(p).rarity
	var holder := [null]
	_event("node_boon", "choose a boon", rarity, func(v: VBoxContainer):
		v.add_child(_para("A blessing for the rest of this road. Take one."))
		for b in offers:
			var col: Color = Forge.RARITY[b.rarity]
			var card := Button.new()
			card.focus_mode = Control.FOCUS_NONE
			card.custom_minimum_size = Vector2(0, 104)
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
			h.add_child(Forge.glyph("node_boon", 40, col))
			var tv := Forge.vbox(2)
			tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
			h.add_child(tv)
			tv.add_child(Forge.sc(Expedition.BOONS[b.key].name, 24, col, true))
			var d := Forge.label(Expedition.boon_text(b), 21, Forge.PARCHMENT)
			d.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tv.add_child(d)
			if b.rarity >= 2:
				Rim.on(card, "comet", [col], 2.0)
			card.pressed.connect(func():
				run.take(b)
				Burst.on(card, col, 60, 10)
				await get_tree().create_timer(0.3).timeout
				holder[0].get_parent().get_parent().get_parent().queue_free()
				rebuild())
			v.add_child(card)
		holder[0] = v, "")


func _trial(p: Vector2i) -> void:
	var run := app.run
	var apt := run.trial_aptitude(p)
	_event("node_trial", "trial", run.node(p).rarity, func(v: VBoxContainer):
		v.add_child(_para("A test of %s: %s. Choose who tries. Roll d20 and reach %d; a hero who favors %s adds +%d." % [
			apt, Data.APTITUDES[apt].to_lower(), Expedition.TRIAL_DC, apt, Data.FAVORED_BONUS]))
		var row := Forge.hbox(12)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_child(row)
		var result := Forge.vbox(8)
		v.add_child(result)
		for uid in app.col.squad:
			if run.fallen(uid):
				continue
			var hero := Data.hero(app.col.by(uid).hero)
			var fav: bool = apt in hero.get("favored", [])
			var b := Forge.ember(hero.name + (" +%d" % Data.FAVORED_BONUS if fav else ""), 64)
			b.add_theme_font_size_override("font_size", 20)
			b.pressed.connect(func():
				for x in row.get_children():
					x.disabled = true
				var roll := randi() % 20 + 1
				var ok := run.trial(roll, fav)
				var total := roll + (Data.FAVORED_BONUS if fav else 0)
				result.add_child(Forge.sc("d20 · %d%s = %d vs %d" % [roll, " + %d" % Data.FAVORED_BONUS if fav else "", total, Expedition.TRIAL_DC], 26, Forge.GOLD_LIGHT, true))
				result.add_child(_gain("ember", "Success · +%d embers" % run.purse("trial")) if ok else _note("%s falls short. Nothing gained, nothing lost." % hero.name)))
			row.add_child(b))


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
	v.add_child(_gain("ember", "%d embers to the town" % run.banked()))
	if not run.boons.is_empty():
		v.add_child(_note("Boons fade when the road ends:"))
		v.add_child(_boon_row())
	var go := Forge.studs("bank and go home", true, 84)
	go.size_flags_horizontal = SIZE_SHRINK_CENTER
	go.pressed.connect(func():
		app.town.earn(run.banked())
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
## behind you dims; boons and caches show their rarity in the ring.
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
		var tint: Color = Forge.RARITY[rarity] if kind in ["boon", "cache"] and rarity > 0 else (Forge.HARM if kind in ["elite", "boss"] else Forge.GOLD)
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
