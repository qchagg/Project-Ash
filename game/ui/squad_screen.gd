class_name SquadScreen
extends Screen
## The squad tab: who takes the field, where they stand, and what the team covers.
## Tap a hero on the field to pick them, then tap a tile to move them or a bench card to swap them out.
## Four take the field for now; the design target is five, six in rare cases, so a fifth seat shows locked.

## Seats drawn on the field row: the playable ones plus the planned fifth, locked.
const PLANNED_SEATS := 5
const ROW_NAMES := ["front", "mid", "deep", "back"]
const W := 632.0
const GAP := 14.0

## The fielded card picked for a move or a swap, if any.
var _sel := ""


func _init() -> void:
	tab = "squad"
	title = "squad"


func _build() -> void:
	if _sel != "" and not _sel in app.col.squad:
		_sel = ""
	var n := Forge.sc("%d of %d" % [app.col.squad.size(), Collection.MAX_SQUAD], 22, Forge.LABEL)
	n.size_flags_vertical = SIZE_SHRINK_CENTER
	head_right.add_child(n)

	body.add_child(_heading("the field"))
	body.add_child(_seats())
	body.add_child(_hint())
	body.add_child(_heading("formation"))
	body.add_child(_grid())
	body.add_child(_heading("bench"))
	body.add_child(_bench())
	body.add_child(_heading("the team"))
	body.add_child(_readout())
	var go := Forge.studs("to battle")
	go.size_flags_horizontal = SIZE_SHRINK_CENTER
	go.pressed.connect(func(): app.show_tab("battle"))
	body.add_child(go)


func _heading(text: String) -> Control:
	var h := Forge.hbox(16)
	var l := Forge.sc(text, 22, Forge.GOLD)
	h.add_child(l)
	var line := Control.new()
	line.size_flags_horizontal = SIZE_EXPAND_FILL
	line.custom_minimum_size.y = 28
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.draw.connect(func(): line.draw_line(Vector2(0, line.size.y / 2), Vector2(line.size.x, line.size.y / 2), Color(Forge.GOLD_DEEP, 0.5), 2.0))
	h.add_child(line)
	return h


# --- the field ---------------------------------------------------------------------------------

func _seats() -> Control:
	var row := Forge.hbox(int(GAP))
	var w := (W - GAP * (PLANNED_SEATS - 1)) / PLANNED_SEATS
	for i in PLANNED_SEATS:
		if i < app.col.squad.size():
			row.add_child(_seat(app.col.squad[i], w))
		elif i < Collection.MAX_SQUAD:
			row.add_child(_empty_seat(w, false))
		else:
			row.add_child(_empty_seat(w, true))
	return row


func _seat(uid: String, w: float) -> Control:
	var c := app.col.by(uid)
	var h := Data.hero(c.hero)
	var v := _card(c, w)
	var art: CardArt = v.get_child(0)
	var picked := uid == _sel
	art.overlay = func(ci: Control):
		if picked:
			ci.draw_rect(Rect2(Vector2.ZERO, ci.size).grow(4), Forge.GOLD_LIGHT, false, 4.0)
	_tap(v, func():
		_sel = "" if picked else uid
		rebuild())
	v.tooltip_text = h.name
	return v


## An open seat, or the planned fifth seat (locked).
func _empty_seat(w: float, locked: bool) -> Control:
	var v := Forge.vbox(8)
	var s := Control.new()
	s.custom_minimum_size = Vector2(w, w * 1.3)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.draw.connect(func():
		var r := Rect2(Vector2.ZERO, s.size)
		s.draw_rect(r, Color(Forge.PLAQUE, 0.35 if locked else 0.6))
		s.draw_rect(r.grow(-1), Color(Forge.BRONZE, 0.35 if locked else 0.7), false, 2.0)
		var g := 40.0
		s.draw_texture_rect(Forge.icon("lock" if locked else "character"), Rect2(r.get_center() - Vector2(g, g) / 2, Vector2(g, g)), false,
			Color(Forge.DIM, 0.5 if locked else 0.8)))
	v.add_child(s)
	var l := Forge.sc("planned" if locked else "open", 16, Color(Forge.DIM, 0.6 if locked else 0.9))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	_tap(v, func():
		if locked:
			_say(v, "a fifth seat is planned", "Teams are planned to grow to five, and six in rare cases. Four take the field for now.")
		else:
			_say(v, "an open seat", "Tap a card on the bench to field it."))
	return v


## What a tap does next, under the field.
func _hint() -> Control:
	var row := Forge.hbox(18)
	if _sel == "":
		var l := Forge.label("Tap a hero on the field to move them or swap them out.", 24, Forge.MUTED, Forge.SANS_ITALIC)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = W
		row.add_child(l)
		return row
	var h := Data.hero(app.col.by(_sel).hero)
	var l := Forge.label("%s: tap a tile to move, or a bench card to swap in." % h.name, 24, Forge.PARCHMENT, Forge.SANS_ITALIC)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(l)
	var b := Forge.ember("bench", 60)
	b.size_flags_vertical = SIZE_SHRINK_CENTER
	b.pressed.connect(func():
		var err := app.col.toggle_field(_sel)
		if err != "":
			_say(b, "can't bench", err)
			return
		_sel = ""
		rebuild())
	row.add_child(b)
	return row


# --- formation ---------------------------------------------------------------------------------

func _grid() -> Control:
	var v := Forge.vbox(8)
	var foe := Forge.sc("the enemy is this way", 16, Forge.DIM)
	foe.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(foe)
	var label_w := 64.0
	var t := (W - label_w - 8 * (Collection.COLS - 1)) / Collection.COLS
	var want := _wanted_rows()
	for r in Collection.ROWS:
		var row := Forge.hbox(8)
		v.add_child(row)
		var l := Forge.sc(ROW_NAMES[r] if r < ROW_NAMES.size() else str(r + 1), 16, Forge.DIM)
		l.custom_minimum_size.x = label_w
		l.size_flags_vertical = SIZE_SHRINK_CENTER
		row.add_child(l)
		for c in Collection.COLS:
			row.add_child(_tile(Vector2i(r, c), t, r in want))
	v.add_child(_range_note())
	return v


## The rows the picked hero wants: melee the front, ranged anywhere behind it.
func _wanted_rows() -> Array:
	if _sel == "":
		return []
	if Data.hero(app.col.by(_sel).hero).range == "melee":
		return [0]
	return range(1, Collection.ROWS)


func _tile(at: Vector2i, t: float, wanted: bool) -> Control:
	var uid := app.col.at(at)
	var tile := Control.new()
	tile.custom_minimum_size = Vector2(t, t)
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex: Texture2D = null
	var h := {}
	if uid != "":
		h = Data.hero(app.col.by(uid).hero)
		tex = load(h.portrait.src)
	tile.draw.connect(func():
		var r := Rect2(Vector2.ZERO, tile.size)
		tile.draw_rect(r, Color(Forge.GOLD, 0.12) if wanted else Color(Forge.PLAQUE, 0.6))
		if tex:
			Forge.portrait(tile, tex, r.grow(-4), h.portrait, 0.75, "squad")
			# Element sigil, bottom left, and the range under it.
			var c := Vector2(24, r.size.y - 24)
			tile.draw_circle(c, 17, Forge.INK)
			tile.draw_arc(c, 16, 0, TAU, 32, Forge.GOLD_DEEP, 2.0, true)
			tile.draw_texture_rect(Forge.sigil(h.elem), Rect2(c - Vector2(10, 10), Vector2(20, 20)), false, Forge.GOLD)
		elif wanted:
			Forge.diamond(tile, r.get_center(), 6, Color(Forge.GOLD, 0.5))
		var edge := Forge.GOLD_LIGHT if uid != "" and uid == _sel else (Color(Forge.GOLD, 0.6) if wanted else Color(Forge.BRONZE, 0.55))
		tile.draw_rect(r.grow(-1), edge, false, 4.0 if uid != "" and uid == _sel else 2.0))
	_tap(tile, func():
		if _sel == "":
			if uid != "":
				_sel = uid
				rebuild()
			return
		if uid == _sel:
			_sel = ""
			rebuild()
			return
		var err := app.col.place(_sel, at)
		if err != "":
			_say(tile, "can't move there", err)
			return
		rebuild())
	if uid != "":
		tile.tooltip_text = "%s · %s" % [h.name, h.range]
	return tile


## What the picked hero's range asks of the formation.
func _range_note() -> Control:
	var text := "Melee heroes want the front row; ranged heroes can stand deeper, out of melee's reach."
	if _sel != "":
		var h := Data.hero(app.col.by(_sel).hero)
		if h.range == "melee":
			text = "%s is melee and wants the front row. Under the coming Reach rule, melee hits a single target only from the front of a lane with an enemy in it." % h.name
		else:
			text = "%s is ranged and works from any row. Deeper rows sit out of melee's reach, which only touches the front-most unit in a lane." % h.name
	var l := Forge.label(text, 22, Forge.MUTED, Forge.SANS_ITALIC)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = W
	return l


# --- bench -------------------------------------------------------------------------------------

func _bench() -> Control:
	var cards := app.col.cards.filter(func(c): return not c.uid in app.col.squad)
	var order := Data.HEROES.map(func(h): return h.key)
	cards.sort_custom(func(a, b):
		if a.hero != b.hero:
			return order.find(a.hero) < order.find(b.hero)
		return a.stars > b.stars)
	if cards.is_empty():
		return Forge.label("Every card is on the field.", 24, Forge.MUTED, Forge.SANS_ITALIC)
	var cols := 4
	var g := GridContainer.new()
	g.columns = cols
	g.add_theme_constant_override("h_separation", int(GAP))
	g.add_theme_constant_override("v_separation", 24)
	var w := (W - GAP * (cols - 1)) / cols
	var fielded_heroes := app.col.squad.map(func(u): return app.col.by(u).hero)
	for c in cards:
		var v := _card(c, w)
		# A hero already on the field can only come in for that same hero.
		var blocked: bool = c.hero in fielded_heroes and (_sel == "" or app.col.by(_sel).hero != c.hero)
		if blocked:
			v.modulate = Color(1, 1, 1, 0.45)
		_tap(v, _bench_tap.bind(c.uid, v))
		g.add_child(v)
	return g


func _bench_tap(uid: String, anchor: Control) -> void:
	var col := app.col
	if _sel == "":
		var err := col.toggle_field(uid)
		if err != "":
			_say(anchor, "can't field", err)
			return
		rebuild()
		return
	# Swap: the picked hero steps out, this card takes their tile.
	var out := _sel
	var spot := col.tile(out)
	var err := col.toggle_field(out)
	if err == "":
		err = col.toggle_field(uid)
		if err != "":
			col.toggle_field(out)
	if err != "":
		_say(anchor, "can't swap", err)
		return
	col.place(uid, spot)
	_sel = uid
	rebuild()


# --- the team ----------------------------------------------------------------------------------

func _readout() -> Control:
	var v := Forge.vbox(18)
	var elems := {}
	for u in app.col.squad:
		elems[Data.hero(app.col.by(u).hero).elem] = true
	var beats := []
	var weak := []
	for e in Data.ELEMS:
		for mine in elems:
			if Data.beats("four", mine, e) and not e in beats:
				beats.append(e)
			if Data.beats("four", e, mine) and not e in weak:
				weak.append(e)
	v.add_child(_tag_row("beats", beats.map(func(e): return _elem_tag(e))))
	v.add_child(_tag_row("weak to", weak.map(func(e): return _elem_tag(e))))
	var open := Data.ELEMS.keys().filter(func(e): return not e in beats)
	if open.is_empty():
		v.add_child(_note("Between them, they have an answer for every element."))
	else:
		v.add_child(_note("Nothing here beats %s." % " or ".join(open.map(func(e): return Data.ELEMS[e].label))))

	var homes := []
	for u in app.col.squad:
		var k: String = Data.hero(app.col.by(u).hero).get("home", "")
		if k != "" and not k in homes:
			homes.append(k)
	v.add_child(_tag_row("homes", homes.map(func(k): return _region_tag(k))))

	var keys := app.col.squad.map(func(u): return app.col.by(u).hero)
	var pairs := []
	for k in keys:
		for b in Data.bonds(k):
			if b.other in keys and keys.find(k) < keys.find(b.other):
				pairs.append("%s & %s · %s" % [Data.hero(k).name, Data.hero(b.other).name, b.kind])
	if pairs.is_empty():
		v.add_child(_tag_row("bonds", [_plain_tag("none on the field")]))
	else:
		v.add_child(_tag_row("bonds", pairs.map(func(p): return _plain_tag(p))))
	return v


func _tag_row(label: String, tags: Array) -> Control:
	var row := Forge.hbox(14)
	var l := Forge.sc(label, 18, Forge.LABEL)
	l.custom_minimum_size.x = 120
	l.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(l)
	var flow := HFlowContainer.new()
	flow.size_flags_horizontal = SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 10)
	flow.add_theme_constant_override("v_separation", 10)
	row.add_child(flow)
	if tags.is_empty():
		flow.add_child(_plain_tag("none"))
	for t in tags:
		flow.add_child(t)
	return row


func _panel(inner: Control) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Forge.flat(Color(Forge.INK, 0.7), Color(Forge.GOLD_DEEP, 0.6), 2, Vector4(14, 6, 14, 6)))
	p.add_child(inner)
	return p


func _elem_tag(e: String) -> Control:
	var h := Forge.hbox(8)
	h.add_child(Forge.glyph("elem_" + e, 20, Forge.ELEM[e]))
	h.add_child(Forge.sc(Data.ELEMS[e].label, 18, Forge.PARCHMENT))
	return _panel(h)


func _region_tag(k: String) -> Control:
	var r: Dictionary = Data.REGIONS[k]
	var h := Forge.hbox(8)
	h.add_child(Forge.glyph("region_" + k, 22, r.light))
	h.add_child(Forge.sc(r.name, 18, Forge.PARCHMENT))
	var p := _panel(h)
	_tap(p, func(): _say(p, r.name, r.desc))
	return p


func _plain_tag(text: String) -> Control:
	return _panel(Forge.sc(text, 18, Forge.PARCHMENT))


func _note(text: String) -> Label:
	var l := Forge.label(text, 22, Forge.MUTED, Forge.SANS_ITALIC)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = W
	return l


# --- shared ------------------------------------------------------------------------------------

## A card in its frame with its name and stars below, `w` wide.
func _card(c: Dictionary, w: float) -> VBoxContainer:
	var h := Data.hero(c.hero)
	var v := Forge.vbox(8)
	var art := CardArt.new().setup(c.hero, c.stars)
	art.drift = 0.0
	art.custom_minimum_size = Vector2(w, w * 1.3)
	v.add_child(art)
	var n := Forge.sc(h.name, 18, Forge.PARCHMENT, true, 0.1)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(n)
	var stars := Forge.hbox(2)
	stars.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in c.stars:
		stars.add_child(Forge.glyph("star", 12, Data.TIER_COLORS[c.stars].lightened(0.15)))
	v.add_child(stars)
	for ch in [art, n, stars]:
		ch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return v


## Makes `c` tappable: a left press runs `cb`. Drags still scroll the screen.
func _tap(c: Control, cb: Callable) -> void:
	c.mouse_filter = Control.MOUSE_FILTER_PASS
	c.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	c.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
			cb.call())


## Floats a short message over `anchor` (see Tooltip).
func _say(anchor: Control, head: String, text: String) -> void:
	Tooltip.open(anchor, func(lines: VBoxContainer):
		lines.add_child(Forge.sc(head, 22, Forge.GOLD))
		var l := Forge.label(text, 24, Forge.PARCHMENT, Forge.SANS_ITALIC)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 580
		lines.add_child(l))
