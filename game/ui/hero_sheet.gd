class_name HeroSheet
extends Control
## The second page of a hero: the showcase card, stats, and skills or passives, with buttons to evolve and equip.
## Tapping a stat or a skill floats a translucent card over the page with the numbers, so nothing below it moves.

const PATTERNS := {
	"pierce": [1, 5, 9, 13], "all": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15], "single": [5], "cross": [1, 4, 5, 6, 9], "sweep": [4, 5, 6, 7],
}
const PAGE_H := 1560.0
const PATTERN_NAMES := {"pierce": "Pierce", "single": "Single", "cross": "Cross", "sweep": "Full row"}
const MODE := "four"

var app: App
var hero := ""
var uid := ""
var tab := "skills"
var swapping := false
var open_stat := ""
var open_skill := -1
var status := ""
var _ui: Control
var _row: Control
var _skill_rows: Array = []
var _pop: Control

signal height_changed(h: float)
signal down_requested
## Evolve or equip was tapped ("evolve" or "equip").
signal open_requested(mode: String)


func setup(a: App, hero_key: String, card_uid: String) -> HeroSheet:
	app = a
	hero = hero_key
	uid = card_uid if card_uid != "" else app.copies(hero)[0].uid
	return self


func _ready() -> void:
	var bd := Backdrop.new()
	bd.elem = Data.hero(hero).elem
	bd.focus = Vector2(0.5, 0.0)
	bd.strength = 0.6
	bd.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bd)
	refresh()


func _card() -> Dictionary:
	return app.col.by(uid)


## Rebuilds the page from the collection (after a merge, a new copy viewed, a tab switched).
func refresh() -> void:
	for n in [_ui, _pop]:
		if n:
			n.queue_free()
	_pop = null
	_skill_rows = []
	var h := Data.hero(hero)
	var c := _card()
	var root := Forge.vbox(0)
	root.custom_minimum_size = Vector2(720, PAGE_H)
	add_child(root)
	_ui = root

	# Room at the top for the pager's roster link and hero dots.
	var body := Forge.margins(MarginContainer.new(), 44, 150, 44, 24)
	root.add_child(body)
	var col := Forge.vbox(34)
	body.add_child(col)

	# The card, standing tilted like the Gilded Forge sheet, with the name centred beneath.
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(632, 480)
	col.add_child(stage)
	var art := CardArt.new().setup(hero, c.stars)
	art.ornate = true
	art.showcase = true
	art.drift = 1.6
	art.size = Vector2(330, 440)
	art.position = Vector2((632 - 330) / 2.0, 10)
	art.pivot_offset = art.size / 2
	art.rotation_degrees = -2.5
	stage.add_child(art)

	var names := Forge.vbox(10)
	col.add_child(names)
	var nm := Forge.sc(h.name, 62, Forge.PARCHMENT, true, 0.1)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_color_override("font_shadow_color", Color.BLACK)
	nm.add_theme_constant_override("shadow_offset_y", 4)
	names.add_child(nm)
	var tl := Forge.hbox(16)
	tl.alignment = BoxContainer.ALIGNMENT_CENTER
	names.add_child(tl)
	tl.add_child(_hairline(52))
	tl.add_child(Forge.sc(h.title, 24, Forge.GOLD))
	for i in c.stars:
		tl.add_child(Forge.glyph("star", 20, Data.TIER_COLORS[c.stars].lightened(0.15)))
	tl.add_child(_hairline(52))
	var kind := Forge.sc("%s · %s" % [Data.ELEMS[h.elem].label, h.range], 20, Forge.LABEL)
	kind.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	names.add_child(kind)

	col.add_child(_stats(c))
	var acts := Forge.hbox(20)
	col.add_child(acts)
	for m in [["evolve", "Copies, feeding and the Ashcrown"], ["equip", "Augment slots"]]:
		var b := Forge.ember(m[0], 72)
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.tooltip_text = m[1]
		b.pressed.connect(func(): open_requested.emit(m[0]))
		acts.add_child(b)
	col.add_child(_kit(c))
	if status != "":
		var l := Forge.label(status, 24, Forge.GOLD, Forge.SANS_ITALIC)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(l)

	var push := Control.new()
	push.size_flags_vertical = SIZE_EXPAND_FILL
	root.add_child(push)
	var foot := CenterContainer.new()
	foot.custom_minimum_size.y = 170
	root.add_child(foot)
	var arrow := DownArrow.make("chronicle")
	arrow.tooltip_text = "History and bio"
	arrow.pressed.connect(func(): down_requested.emit())
	foot.add_child(arrow)
	_fit.call_deferred()
	if open_stat != "":
		_stat_pop.call_deferred(c)
	elif open_skill >= 0:
		_skill_pop.call_deferred(c)


## Grows the page to its content (at least one screen) and tells the pager.
func _fit() -> void:
	if not is_instance_valid(_ui):
		return
	var hgt := maxf(PAGE_H, _ui.get_combined_minimum_size().y)
	_ui.size = Vector2(720, hgt)
	custom_minimum_size = Vector2(720, hgt)
	size = Vector2(720, hgt)
	height_changed.emit(hgt)


## Four chips, icon and number centred together in each.
func _stats(c: Dictionary) -> Control:
	var row := Forge.hbox(14)
	_row = row
	var s := app.col.stats(c)
	for k in Data.STATS:
		var b := Button.new()
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 72
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.tooltip_text = Forge.STAT_NAME[k].capitalize()
		var on: bool = open_stat == k
		var st := Forge.flat(Color("#2a1f15") if on else Color(Forge.PLAQUE, 0.85), Forge.GOLD if on else Color(Forge.BRONZE, 0.8), 2)
		for state in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(state, st)
		var inner := CenterContainer.new()
		inner.set_anchors_preset(PRESET_FULL_RECT)
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(inner)
		var h := Forge.hbox(10)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(h)
		h.add_child(Forge.glyph(Forge.STAT_ICON[k], 28, Forge.STAT_TINT[k]))
		var n := Forge.label(str(s[k]), 30, Forge.PARCHMENT, Forge.SANS_BOLD)
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(n)
		b.pressed.connect(func():
			open_skill = -1
			open_stat = "" if open_stat == k else k
			refresh())
		row.add_child(b)
	return row


## Details for a tapped stat or skill, floating over the page (see Tooltip), its notch at `point_x` on screen.
func _float(anchor: Control, point_x: float, fill: Callable) -> void:
	if not is_instance_valid(anchor):
		return
	_pop = Tooltip.open(anchor, fill, point_x)
	_pop.closed.connect(func():
		_pop = null
		open_stat = ""
		open_skill = -1
		refresh())


func _stat_pop(c: Dictionary) -> void:
	var s := app.col.stats(c)
	var chip: Control = _row.get_child(Data.STATS.find(open_stat))
	var x := chip.get_global_rect().get_center().x
	_float(_row, x, func(lines: VBoxContainer):
		lines.add_child(Forge.sc(Forge.STAT_NAME[open_stat], 22, Forge.GOLD))
		lines.add_child(_kv("This copy", str(s[open_stat]), Forge.PARCHMENT))
		lines.add_child(_kv("%s’s average" % Data.hero(hero).name, str(Data.hero(hero)[open_stat]), Forge.PARCHMENT))
		if c.stars > 1:
			lines.add_child(_kv("Star bonus (%d★)" % c.stars, "+%d%%" % roundi(Collection.STAR_BONUS * (c.stars - 1) * 100), Forge.GAIN)))


## A skill's numbers: element and matchups, the target pattern, power and effects, cooldown, augments.
func _skill_pop(c: Dictionary) -> void:
	if open_skill >= _skill_rows.size():
		return
	var s: Dictionary = app.col.skills(c)[open_skill]
	var h := Data.hero(hero)
	var row: Control = _skill_rows[open_skill]
	_float(row, row.global_position.x + 76.0, func(lines: VBoxContainer):
		var head := Forge.hbox(14)
		lines.add_child(head)
		var g := TextureRect.new()
		g.texture = Forge.sigil(h.elem)
		g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		g.custom_minimum_size = Vector2(26, 26)
		g.modulate = Forge.ELEM[h.elem]
		head.add_child(g)
		head.add_child(Forge.sc("%s skill" % Data.ELEMS[h.elem].label, 22, Forge.ELEM[h.elem].lightened(0.2)))
		var vs := []
		for e in Data.ELEMS:
			if Data.beats(MODE, h.elem, e):
				vs.append("strong against " + Data.ELEMS[e].label)
			elif Data.beats(MODE, e, h.elem):
				vs.append("weak to " + Data.ELEMS[e].label)
		var sp := Control.new()
		sp.size_flags_horizontal = SIZE_EXPAND_FILL
		head.add_child(sp)
		head.add_child(Forge.label(" · ".join(vs), 20, Forge.MUTED))
		var mid := Forge.hbox(22)
		lines.add_child(mid)
		mid.add_child(pattern_grid(s.pattern, Forge.ELEM[h.elem]))
		var t := Forge.vbox(4)
		mid.add_child(t)
		t.add_child(Forge.label(meta(s), 26, Forge.PARCHMENT, Forge.SANS_BOLD))
		t.add_child(Forge.label("Cooldown %d round%s" % [s.cd, "" if s.cd == 1 else "s"], 22, Forge.MUTED))
		if s.get("augs", []).size() > 0:
			lines.add_child(Forge.label("Augments: " + ", ".join(s.augs.map(func(a): return Data.AUGS[a].name)), 22, Forge.GAIN)))


func _kit(c: Dictionary) -> Control:
	var v := Forge.vbox(14)
	var head := Forge.hbox(36)
	v.add_child(head)
	head.add_child(_seg("Skills", tab == "skills", _show.bind("skills")))
	head.add_child(_seg("Passives", tab == "passives", _show.bind("passives")))
	var sp := Control.new()
	sp.size_flags_horizontal = SIZE_EXPAND_FILL
	head.add_child(sp)
	if tab == "skills":
		var sw := Forge.link("done" if swapping else "swap", "swap", 22)
		sw.pressed.connect(_toggle_swap)
		head.add_child(sw)
		var skills := app.col.skills(c)
		for i in skills.size():
			var row := _slot(skills[i], i)
			_skill_rows.append(row)
			v.add_child(row)
	else:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", Forge.flat(Color(Forge.PLAQUE, 0.85), Color(Forge.BRONZE, 0.8), 2, Vector4(24, 20, 24, 20)))
		var l := Forge.label("Passives arrive with the combat port.", 24, Forge.MUTED, Forge.SANS_ITALIC)
		p.add_child(l)
		v.add_child(p)
	return v


## A skill row: name and flavour, cooldown at the side. Tapping it floats the numbers over the page.
func _slot(s: Dictionary, i: int) -> Control:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.tooltip_text = "Details"
	var on := open_skill == i
	var st := Forge.flat(Color("#2a1f15") if on else Color(Forge.PLAQUE, 0.85), Forge.GOLD if on else Color(Forge.BRONZE, 0.8), 2)
	for state in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(state, st)
	b.pressed.connect(func():
		open_stat = ""
		open_skill = -1 if open_skill == i else i
		refresh())
	var m := Forge.margins(MarginContainer.new(), 32, 28, 32, 28)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.set_anchors_preset(PRESET_FULL_RECT)
	b.add_child(m)
	var h := Forge.hbox(26)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(h)
	h.add_child(pattern_grid(s.pattern, Forge.ELEM[Data.hero(hero).elem]))
	var txt := Forge.vbox(0)
	txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	txt.size_flags_horizontal = SIZE_EXPAND_FILL
	txt.size_flags_vertical = SIZE_SHRINK_CENTER
	h.add_child(txt)
	txt.add_child(Forge.sc(s.name, 32, Forge.PARCHMENT, false, 0.08))
	var fl := Forge.label(s.get("flavor", s.desc), 24, Color("#e2d5b6"), Forge.SANS_ITALIC)
	fl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fl.custom_minimum_size.x = 420
	fl.add_theme_constant_override("line_spacing", -2)
	txt.add_child(fl)
	# The cooldown sits faint in the top-right corner; the numbers are one tap away.
	var cd := Forge.hbox(4)
	cd.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cd.add_child(Forge.glyph("cooldown", 18, Color(Forge.DIM, 0.7)))
	cd.add_child(Forge.label(str(s.cd), 20, Color(Forge.DIM, 0.8), Forge.SANS_BOLD))
	b.add_child(cd)
	cd.set_anchors_and_offsets_preset(PRESET_TOP_RIGHT, PRESET_MODE_MINSIZE, 14)
	if swapping:
		h.add_child(_round_button("swap", "Swap %s" % s.name, _no_swap, 66))
	# A button doesn't grow to its children, so follow the content's height.
	b.custom_minimum_size.y = 120
	m.minimum_size_changed.connect(func(): b.custom_minimum_size.y = m.get_combined_minimum_size().y)
	return b


## The 4×4 target pattern a skill hits, tinted in the hero's element.
static func pattern_grid(pattern: String, tint: Color) -> Control:
	var grid := Control.new()
	grid.custom_minimum_size = Vector2(56, 44)
	grid.size_flags_vertical = SIZE_SHRINK_CENTER
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cells: Array = PATTERNS.get(pattern, [])
	grid.draw.connect(func():
		for i in 16:
			grid.draw_rect(Rect2((i % 4) * 14, (i / 4) * 11, 12, 9), tint if i in cells else Color("#3a2c1a")))
	return grid


static func meta(s: Dictionary) -> String:
	var parts := []
	if s.pattern == "all":
		parts.append("Every enemy" if s.kind == "dmg" else "Every ally")
	else:
		parts.append(PATTERN_NAMES.get(s.pattern, s.pattern.capitalize()))
	match s.kind:
		"dmg": parts.append("%s× ATK" % _num(s.power))
		"heal": parts.append("Heals %s×" % _num(s.power))
		"shield": parts.append("Shields %s×" % _num(s.power))
	var fx: Dictionary = s.get("fx", {})
	if fx.get("burn", 0): parts.append("Burn %d" % fx.burn)
	if fx.get("stun", 0): parts.append("Stun %d" % fx.stun)
	if fx.get("cleanse", false): parts.append("Cleanse")
	return " · ".join(parts)


static func _num(x: float) -> String:
	return str(snappedf(x, 0.01)).trim_suffix(".0")


func _show(t: String) -> void:
	tab = t
	open_skill = -1
	if t != "skills":
		swapping = false
	status = ""
	refresh()


func _toggle_swap() -> void:
	swapping = not swapping
	status = ""
	refresh()


func _no_swap() -> void:
	status = "There are no other skills to swap to yet."
	refresh()


func _seg(text: String, on: bool, cb: Callable) -> Button:
	var b := Forge.link(text, "", 24)
	b.custom_minimum_size.y = 64
	for k in ["font_color", "font_hover_color"]:
		b.add_theme_color_override(k, Forge.GOLD_LIGHT if on else Forge.DIM)
	if on:
		b.draw.connect(func(): b.draw_rect(Rect2(0, b.size.y - 4, b.size.x, 4), Forge.GOLD))
	b.pressed.connect(cb)
	return b


func _round_button(glyph: String, tip: String, cb: Callable, px := 80) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(px, px)
	b.size_flags_vertical = SIZE_SHRINK_CENTER
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.tooltip_text = tip
	var s := Forge.flat(Color(Forge.INK, 0.6), Color(Forge.GOLD_DEEP, 0.7), 2)
	s.set_corner_radius_all(px / 2)
	for st in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(st, s)
	b.draw.connect(func():
		var g := px * 0.45
		b.draw_texture_rect(Forge.icon(glyph), Rect2(b.size / 2 - Vector2(g, g) / 2, Vector2(g, g)), false, Forge.GOLD_LIGHT))
	b.pressed.connect(cb)
	return b


func _kv(k: String, val: String, color: Color) -> Control:
	var h := Forge.hbox(10)
	var a := Forge.label(k, 24, Forge.MUTED)
	a.size_flags_horizontal = SIZE_EXPAND_FILL
	h.add_child(a)
	h.add_child(Forge.label(val, 24, color, Forge.SANS_BOLD))
	return h


func _hairline(w: int) -> Control:
	var r := ColorRect.new()
	r.color = Forge.GOLD_DEEP
	r.custom_minimum_size = Vector2(w, 2)
	r.size_flags_vertical = SIZE_SHRINK_CENTER
	return r
