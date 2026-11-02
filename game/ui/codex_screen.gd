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
## A region plate's width on a phone and on a wide screen, set two across, and the height of its painting.
const PLATE_W := Vector2(632, 620)
const BAND_H := 176.0
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
	tab = "town"
	title = "archive"
	black = true


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
	# A wide screen sets the regions two across, so each keeps the shape it has on a phone.
	var grid := GridContainer.new()
	grid.columns = 2 if Forge.wide() else 1
	grid.add_theme_constant_override("h_separation", 64)
	grid.add_theme_constant_override("v_separation", 64)
	body.add_child(grid)
	for key in Data.REGIONS:
		grid.add_child(_region_plate(key))


## A region as a plate: one of its paintings across the top, its dark washing in from the left under its sigil and its
## light cut along the foot, then its name and a line about it.
func _region_plate(key: String) -> Control:
	var r: Dictionary = Data.REGIONS[key]
	var b := _plate()
	var v := Forge.vbox(0)
	v.mouse_filter = MOUSE_FILTER_IGNORE
	b.add_child(v)
	var w: float = PLATE_W.y if Forge.wide() else PLATE_W.x
	var top := Control.new()
	top.custom_minimum_size = Vector2(w, BAND_H)
	top.clip_contents = true
	top.mouse_filter = MOUSE_FILTER_IGNORE
	v.add_child(top)
	var arts: Array = Backdrop.ART.get(key, [])
	if arts.is_empty():
		top.add_child(Forge.region_swatch(key, Vector2(w, BAND_H)))
	else:
		top.add_child(Painted.new().setup(arts[0], Color(0.85, 0.85, 0.85)))
		top.add_child(Forge.wash(Color(r.dark, 0.95), Vector2(0.0, 0.5), Vector2(0.62, 0.5)))
	var cut := Control.new()
	cut.mouse_filter = MOUSE_FILTER_IGNORE
	top.add_child(cut)
	cut.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	cut.draw.connect(func():
		var s := cut.size
		cut.draw_colored_polygon(PackedVector2Array([Vector2(0, s.y), Vector2(s.x, s.y - 18), s]), r.light))
	var badge := Forge.region_badge(key, 84)
	badge.position = Vector2(28, (BAND_H - 84) / 2.0 - 8)
	top.add_child(badge)
	var count := Forge.sc("%d archetypes" % Lore.in_region(key).size(), 18, Forge.PARCHMENT)
	count.add_theme_color_override("font_outline_color", Color(Forge.INK, 0.7))
	count.add_theme_constant_override("outline_size", 4)
	count.position = Vector2(132, BAND_H / 2.0 - 20)
	top.add_child(count)
	var text := Forge.margins(MarginContainer.new(), 28, 20, 28, 28)
	text.mouse_filter = MOUSE_FILTER_IGNORE
	v.add_child(text)
	var t := Forge.vbox(10)
	t.mouse_filter = MOUSE_FILTER_IGNORE
	text.add_child(t)
	t.add_child(Forge.sc(r.name, 30, Forge.GOLD, true, 0.14))
	t.add_child(_para(r.desc, 22, Forge.PARCHMENT, w - 56.0))
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
	body.add_child(_group("heroes", func(v: VBoxContainer):
		v.add_child(_term("stars", "Every hero has four stars and arrives at 1★. Each new copy lights the next star, adding 10% to each stat and one augment slot. Copies past 4★ turn into gold.", ""))
		v.add_child(_term("augments", "Bound elemental spirits slotted into a skill. They rename it and give the hero an aura.", ""))
		for k in Data.AUGS:
			var g: Dictionary = Data.AUGS[k]
			v.add_child(_term(g.name, g.desc, g.fam))))
	body.add_child(_group("aptitudes", func(v: VBoxContainer):
		v.add_child(_para("Rolled on a d20 on the road. A hero's two favoured aptitudes add +%d and spark on 19–20." % Data.FAVORED_BONUS, 22, Forge.PARCHMENT, 632))
		for k in Data.APTITUDES:
			v.add_child(_term(k, Data.APTITUDES[k], ""))))
	body.add_child(_group("roles", func(v: VBoxContainer):
		for k in Lore.ROLES:
			v.add_child(_term(k, Lore.ROLES[k], ""))))


func _settings() -> void:
	body.add_child(_intro("Settings for the playtest. Most are placeholders until the systems behind them exist."))
	# Sound lives here alone, rather than in a corner of every screen.
	var sound := Forge.hbox(16)
	sound.add_child(Forge.sound_toggle())
	var words := _term("sound", "Music and effects, on or off.", "")
	words.size_flags_vertical = SIZE_SHRINK_CENTER
	sound.add_child(words)
	body.add_child(sound)
	for row in [["motion", "Reduce card drift and backdrops", "not wired yet"],
			["language", "English · Français later", "not wired yet"]]:
		body.add_child(_term(row[0], "%s (%s)" % [row[1], row[2]], ""))
	body.add_child(Forge.rule())
	body.add_child(_para("Start the playtest heroes over: the starting stars, every augment loose.", 22, Forge.MUTED, 632))
	var reset := Forge.studs("reset collection")
	reset.pressed.connect(func():
		app.col = Collection.new()
		app.showcase()
		app.show_tab("heroes"))
	body.add_child(reset)
	body.add_child(Forge.rule())
	body.add_child(_para("Hero voices are from the Super Dialogue Audio Pack by Dillon Becker (dillonbecker.com), licensed under CC BY 4.0: creativecommons.org/licenses/by/4.0. They have been shortened, resampled and pitched.", 20, Forge.MUTED, 620.0))


func _group(heading: String, fill: Callable) -> Control:
	var v := Forge.vbox(22)
	v.add_child(Forge.sc(heading, 24, Forge.GOLD, true, 0.16))
	v.add_child(Forge.rule())
	fill.call(v)
	return v


## A glossary term: the word, with its element sigil on the same line where it has one, and its meaning under it.
func _term(word: String, meaning: String, elem: String) -> Control:
	var t := Forge.vbox(4)
	t.size_flags_horizontal = SIZE_EXPAND_FILL
	var line := Forge.hbox(10)
	t.add_child(line)
	if elem != "":
		var g := Forge.glyph("elem_" + elem, 22, Forge.ELEM[elem])
		g.size_flags_vertical = SIZE_SHRINK_CENTER
		line.add_child(g)
	var w := Forge.sc(word, 20, Forge.GOLD_LIGHT)
	w.size_flags_vertical = SIZE_SHRINK_CENTER
	line.add_child(w)
	t.add_child(_para(meaning, 21, Forge.PARCHMENT, 600))
	return t


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
