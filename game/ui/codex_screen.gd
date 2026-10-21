class_name CodexScreen
extends Screen
## The codex: the world (regions and their archetypes), the archetypes on their own, a glossary of the rules, and
## settings. Everything taps for details in a floating Tooltip.

const SECTIONS := ["world", "archetypes", "glossary", "settings"]
const STATUSES := [
	["burn", "fire", "Takes damage at the end of each round it lasts. Cleanse clears it."],
	["stun", "earth", "Skips its next action. Caps at 2 rounds."],
	["shield", "earth", "Absorbs damage until broken; holds until then."],
	["cleanse", "water", "Clears Burn from whoever it heals."],
]
const PATTERNS := [
	["single", "One exposed enemy."],
	["pierce", "A whole lane, front to back."],
	["sweep", "A whole row."],
	["cross", "A tile and its four neighbours."],
	["all", "Everyone on a side."],
]

var section := "world"
var elem_filter := ""


func _init() -> void:
	tab = "codex"
	title = "codex"


func _build() -> void:
	var segs := Forge.hbox(30)
	body.add_child(segs)
	for s in SECTIONS:
		segs.add_child(Forge.seg(s.capitalize(), s == section, func():
			section = s
			rebuild()))
	match section:
		"world": _world()
		"archetypes": _archetypes()
		"glossary": _glossary()
		"settings": _settings()


func _world() -> void:
	body.add_child(_intro("Eleven regions, drawn from cultures around the world. Tap one for where it comes from and who lives there."))
	for key in Data.REGIONS:
		body.add_child(_region_plate(key))


## A region as a plate: its colorway, its sigil riding the edge, its name and a line about it.
func _region_plate(key: String) -> Control:
	var r: Dictionary = Data.REGIONS[key]
	var b := _plate()
	var v := Forge.vbox(0)
	v.mouse_filter = MOUSE_FILTER_IGNORE
	b.add_child(v)
	var top := Control.new()
	top.custom_minimum_size = Vector2(632, 120)
	top.mouse_filter = MOUSE_FILTER_IGNORE
	v.add_child(top)
	top.add_child(Forge.region_swatch(key, Vector2(632, 84)))
	var badge := Forge.region_badge(key, 88)
	badge.position = Vector2(28, 36)
	top.add_child(badge)
	var names := Lore.in_region(key).map(func(a): return a.name)
	var count := Forge.sc("%d archetypes" % names.size(), 18, Forge.DIM)
	count.position = Vector2(136, 92)
	top.add_child(count)
	var text := Forge.margins(MarginContainer.new(), 28, 10, 28, 24)
	text.mouse_filter = MOUSE_FILTER_IGNORE
	v.add_child(text)
	var t := Forge.vbox(8)
	t.mouse_filter = MOUSE_FILTER_IGNORE
	text.add_child(t)
	t.add_child(Forge.sc(r.name, 30, Forge.GOLD, true, 0.14))
	t.add_child(_para(r.desc, 22, Forge.PARCHMENT, 576))
	_tap(b, func(lines: VBoxContainer):
		var head := Forge.hbox(16)
		lines.add_child(head)
		head.add_child(Forge.region_badge(key, 56))
		head.add_child(Forge.sc(r.name, 26, r.light, true, 0.14))
		lines.add_child(Forge.sc("drawn from", 16, Forge.DIM))
		lines.add_child(_para(r.inspired, 22, Forge.MUTED, 580))
		for a in Lore.in_region(key):
			lines.add_child(_archetype_line(a)))
	return b


func _archetypes() -> void:
	var filters := Forge.hbox(8)
	body.add_child(filters)
	filters.add_child(_filter("", "star", Forge.GOLD))
	for e in Data.ELEMS:
		filters.add_child(_filter(e, "elem_" + e, Forge.ELEM[e]))
	for a in Lore.ARCHETYPES:
		if elem_filter == "" or a.elem == elem_filter:
			body.add_child(_archetype_row(a))


func _archetype_row(a: Dictionary) -> Control:
	var b := _plate()
	var m := Forge.margins(MarginContainer.new(), 28, 22, 28, 22)
	m.mouse_filter = MOUSE_FILTER_IGNORE
	b.add_child(m)
	var h := Forge.hbox(22)
	h.mouse_filter = MOUSE_FILTER_IGNORE
	m.add_child(h)
	var badge := Forge.region_badge(a.region, 64)
	badge.size_flags_vertical = SIZE_SHRINK_CENTER
	h.add_child(badge)
	var t := Forge.vbox(4)
	t.mouse_filter = MOUSE_FILTER_IGNORE
	t.size_flags_horizontal = SIZE_EXPAND_FILL
	h.add_child(t)
	var line := Forge.hbox(12)
	line.mouse_filter = MOUSE_FILTER_IGNORE
	t.add_child(line)
	line.add_child(Forge.glyph("elem_" + a.elem, 22, Forge.ELEM[a.elem]))
	line.add_child(Forge.sc(a.name, 24, Forge.GOLD_LIGHT, true, 0.12))
	t.add_child(Forge.sc("%s · %s%s" % [a.role, Data.REGIONS[a.region].name, " · playable" if a.hero != "" else ""], 18, Forge.DIM))
	t.add_child(_para(a.hook, 21, Forge.PARCHMENT, 470))
	_tap(b, func(lines: VBoxContainer): _archetype_detail(lines, a))
	return b


func _archetype_detail(lines: VBoxContainer, a: Dictionary) -> void:
	var head := Forge.hbox(14)
	lines.add_child(head)
	head.add_child(Forge.glyph("elem_" + a.elem, 26, Forge.ELEM[a.elem]))
	head.add_child(Forge.sc(a.name, 26, Forge.GOLD, true, 0.12))
	lines.add_child(Forge.sc("%s · %s" % [a.role, Lore.ROLES[a.role]], 18, Forge.LABEL))
	lines.add_child(_para("On the grid (idea): " + a.plays, 22, Forge.PARCHMENT, 580))
	lines.add_child(Forge.sc("favored · " + " · ".join(a.favored), 18, Forge.GOLD_LIGHT))
	lines.add_child(Forge.sc("drawn from", 16, Forge.DIM))
	lines.add_child(_para(a.inspired + ".", 21, Forge.MUTED, 580))
	if a.hero != "":
		lines.add_child(Forge.sc("playable as " + Data.hero(a.hero).name, 18, Forge.GAIN))


## One archetype as a line in a region's details.
func _archetype_line(a: Dictionary) -> Control:
	var h := Forge.hbox(12)
	h.add_child(Forge.glyph("elem_" + a.elem, 20, Forge.ELEM[a.elem]))
	h.add_child(Forge.sc(a.name, 20, Forge.PARCHMENT))
	h.add_child(Forge.sc(a.role + (" · " + Data.hero(a.hero).name if a.hero != "" else ""), 16, Forge.DIM))
	return h


func _glossary() -> void:
	body.add_child(_group("elements", func(v: VBoxContainer):
		v.add_child(_para("Water douses Fire, Fire consumes Wind, Wind erodes Earth, Earth dams Water. Opposites are even.", 22, Forge.PARCHMENT, 632))
		for e in Data.ELEMS:
			var beat := ""
			var lose := ""
			for o in Data.ELEMS:
				if Data.beats("four", e, o):
					beat = Data.ELEMS[o].label
				elif Data.beats("four", o, e):
					lose = Data.ELEMS[o].label
			v.add_child(_term(Data.ELEMS[e].label, "beats %s · weak to %s · spirit: %s" % [beat, lose, Data.ELEMS[e].spirit], e))))
	body.add_child(_group("statuses", func(v: VBoxContainer):
		for s in STATUSES:
			v.add_child(_term(s[0], s[2], s[1]))))
	body.add_child(_group("patterns", func(v: VBoxContainer):
		for p in PATTERNS:
			var h := Forge.hbox(20)
			h.add_child(HeroSheet.pattern_grid(p[0], Forge.GOLD_LIGHT))
			var t := Forge.vbox(2)
			t.add_child(Forge.sc(p[0], 20, Forge.GOLD_LIGHT))
			t.add_child(_para(p[1], 21, Forge.PARCHMENT, 480))
			h.add_child(t)
			v.add_child(h)))
	body.add_child(_group("cards", func(v: VBoxContainer):
		v.add_child(_term("stars", "Merge two copies of the same star level to rise one star, up to 3★. Every star adds 10% to each stat.", ""))
		v.add_child(_term("ashcrown", "Raises a 3★ card to 4★, the top tier.", ""))
		v.add_child(_term("augments", "Bound elemental spirits slotted into a skill. They rename it and give the card an aura.", ""))
		for k in Data.AUGS:
			var g: Dictionary = Data.AUGS[k]
			v.add_child(_term(g.name, g.desc, g.fam))))
	body.add_child(_group("aptitudes", func(v: VBoxContainer):
		v.add_child(_para("Rolled on a d20 for trials. A hero's two favoured aptitudes add +%d and spark on 19–20." % Data.FAVORED_BONUS, 22, Forge.PARCHMENT, 632))
		for k in Data.APTITUDES:
			v.add_child(_term(k, Data.APTITUDES[k], ""))))
	body.add_child(_group("roles", func(v: VBoxContainer):
		for k in Lore.ROLES:
			v.add_child(_term(k, Lore.ROLES[k], ""))))


func _settings() -> void:
	body.add_child(_intro("Settings for the playtest. Most are placeholders until the systems behind them exist."))
	for row in [["sound", "Music and effects", "not wired yet"], ["motion", "Reduce card drift and backdrops", "not wired yet"],
			["language", "English · Français later", "not wired yet"]]:
		body.add_child(_term(row[0], "%s (%s)" % [row[1], row[2]], ""))
	body.add_child(Forge.rule())
	body.add_child(_para("Start the playtest collection over: the seeded cards, one Ashcrown, every augment loose.", 22, Forge.MUTED, 632))
	var reset := Forge.studs("reset collection")
	reset.pressed.connect(func():
		app.col = Collection.new()
		app.show_tab("roster"))
	body.add_child(reset)


func _group(heading: String, fill: Callable) -> Control:
	var v := Forge.vbox(16)
	v.add_child(Forge.sc(heading, 24, Forge.GOLD, true, 0.16))
	v.add_child(Forge.rule())
	fill.call(v)
	return v


## A glossary term: the word, an optional element sigil, and its meaning.
func _term(word: String, meaning: String, elem: String) -> Control:
	var h := Forge.hbox(16)
	if elem != "":
		var g := Forge.glyph("elem_" + elem, 22, Forge.ELEM[elem])
		g.size_flags_vertical = SIZE_SHRINK_BEGIN
		h.add_child(g)
	var t := Forge.vbox(2)
	t.size_flags_horizontal = SIZE_EXPAND_FILL
	t.add_child(Forge.sc(word, 20, Forge.GOLD_LIGHT))
	t.add_child(_para(meaning, 21, Forge.PARCHMENT, 580 if elem == "" else 540))
	h.add_child(t)
	return h


func _filter(elem: String, glyph: String, tint: Color) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(72, 72)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.tooltip_text = "All" if elem == "" else Data.ELEMS[elem].label
	var on := elem_filter == elem
	var s := StyleBoxFlat.new()
	s.set_corner_radius_all(36)
	s.bg_color = Forge.PLAQUE if on else Color.TRANSPARENT
	s.border_color = Forge.GOLD
	s.set_border_width_all(2 if on else 0)
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, s)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(PRESET_FULL_RECT)
	cc.mouse_filter = MOUSE_FILTER_IGNORE
	cc.add_child(Forge.glyph(glyph, 30, tint))
	b.add_child(cc)
	b.pressed.connect(func():
		elem_filter = elem
		rebuild())
	return b


## A plate behind a region or an archetype; it sizes to its content. tap() lays a button over it.
func _plate() -> PanelContainer:
	var p := PanelContainer.new()
	p.clip_contents = true
	p.add_theme_stylebox_override("panel", Forge.flat(Color(Forge.PLAQUE, 0.85), Color(Forge.BRONZE, 0.8), 2))
	return p


## Makes a plate tappable: a flat button over it that floats `fill` in a Tooltip.
func _tap(p: PanelContainer, fill: Callable) -> void:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(func(): Tooltip.open(p, fill))
	p.add_child(b)


func _intro(text: String) -> Label:
	return _para(text, 22, Forge.MUTED, 632)


func _para(text: String, px: int, color: Color, width: float) -> Label:
	var l := Forge.label(text, px, color, Forge.SANS_ITALIC if color == Forge.MUTED else Forge.SANS)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = width
	l.mouse_filter = MOUSE_FILTER_IGNORE
	return l
