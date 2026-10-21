class_name HeroSheet
extends Control
## The second page of a hero: the showcase card, stats, and skills or passives.
## A stat's breakdown floats over the page when tapped, so nothing below it moves.
## Copies, feeding, the Ashcrown and equipment live one page further down (EvolvePage).

const PATTERNS := {
	"pierce": [1, 5, 9, 13], "all": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15], "single": [5], "cross": [1, 4, 5, 6, 9], "sweep": [4, 5, 6, 7],
}
const PAGE_H := 1560.0
const PATTERN_NAMES := {"pierce": "Pierce", "single": "Single", "cross": "Cross", "sweep": "Full row"}

var app: App
var hero := ""
var uid := ""
var tab := "skills"
var swapping := false
var open_stat := ""
var status := ""
var _ui: Control
var _row: Control
var _pop: Control

signal height_changed(h: float)
signal down_requested


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
	var h := Data.hero(hero)
	var c := _card()
	var root := Forge.vbox(0)
	root.custom_minimum_size = Vector2(720, PAGE_H)
	add_child(root)
	_ui = root

	# Room at the top for the pager's roster link and hero dots.
	var body := Forge.margins(MarginContainer.new(), 44, 120, 44, 24)
	root.add_child(body)
	var col := Forge.vbox(34)
	body.add_child(col)

	# The card, standing tilted like the Gilded Forge sheet, with the name centred beneath.
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(632, 500)
	col.add_child(stage)
	var art := CardArt.new().setup(hero, c.stars)
	art.ornate = true
	art.showcase = true
	art.size = Vector2(330, 440)
	art.position = Vector2((632 - 330) / 2.0, 22)
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
	var arrow := DownArrow.make("evolve · equip")
	arrow.tooltip_text = "Copies, evolution and equipment"
	arrow.pressed.connect(func(): down_requested.emit())
	foot.add_child(arrow)
	_fit.call_deferred()
	if open_stat != "":
		_open_pop.call_deferred(c)


## Grows the page to its content (at least one screen) and tells the pager.
func _fit() -> void:
	if not is_instance_valid(_ui):
		return
	var hgt := maxf(PAGE_H, _ui.get_combined_minimum_size().y)
	_ui.size = Vector2(720, hgt)
	custom_minimum_size = Vector2(720, hgt)
	size = Vector2(720, hgt)
	height_changed.emit(hgt)


func _stats(c: Dictionary) -> Control:
	var row := Forge.hbox(14)
	_row = row
	var s := app.col.stats(c)
	for k in Data.STATS:
		var b := Button.new()
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 70
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.tooltip_text = Forge.STAT_NAME[k].capitalize()
		var on: bool = open_stat == k
		var st := Forge.flat(Color("#2a1f15") if on else Color(Forge.PLAQUE, 0.85), Forge.GOLD if on else Color(Forge.BRONZE, 0.8), 2)
		for state in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(state, st)
		b.icon = Forge.icon(Forge.STAT_ICON[k])
		b.add_theme_constant_override("icon_max_width", 26)
		for ic in ["icon_normal_color", "icon_hover_color", "icon_pressed_color"]:
			b.add_theme_color_override(ic, Forge.STAT_TINT[k])
		b.text = str(s[k])
		b.add_theme_font_override("font", Forge.SANS_BOLD)
		b.add_theme_font_size_override("font_size", 30)
		for fc in ["font_color", "font_hover_color", "font_pressed_color"]:
			b.add_theme_color_override(fc, Forge.PARCHMENT)
		b.add_theme_constant_override("h_separation", 10)
		b.pressed.connect(func():
			open_stat = "" if open_stat == k else k
			refresh())
		row.add_child(b)
	return row


## The stat breakdown, floating just under the chips over whatever is below. A tap anywhere closes it.
func _open_pop(c: Dictionary) -> void:
	if not is_instance_valid(_row):
		return
	var s := app.col.stats(c)
	var at := _row.global_position - global_position + Vector2(0, _row.size.y + 12)
	_pop = Control.new()
	_pop.set_anchors_preset(PRESET_FULL_RECT)
	add_child(_pop)
	var catcher := Button.new()
	catcher.flat = true
	catcher.focus_mode = Control.FOCUS_NONE
	catcher.set_anchors_preset(PRESET_FULL_RECT)
	catcher.pressed.connect(func():
		open_stat = ""
		refresh())
	_pop.add_child(catcher)
	var p := PanelContainer.new()
	var st := Forge.flat(Color("#1d1610"), Forge.GOLD, 2, Vector4(26, 18, 26, 20))
	st.shadow_color = Color(0, 0, 0, 0.6)
	st.shadow_size = 18
	st.shadow_offset = Vector2(0, 8)
	p.add_theme_stylebox_override("panel", st)
	p.position = at
	p.custom_minimum_size.x = _row.size.x
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	_pop.add_child(p)
	var lines := Forge.vbox(10)
	p.add_child(lines)
	lines.add_child(Forge.sc(Forge.STAT_NAME[open_stat], 22, Forge.GOLD))
	lines.add_child(_kv("This copy", str(s[open_stat]), Forge.PARCHMENT))
	lines.add_child(_kv("%s’s average" % Data.hero(hero).name, str(Data.hero(hero)[open_stat]), Forge.PARCHMENT))
	if c.stars > 1:
		lines.add_child(_kv("Star bonus (%d★)" % c.stars, "+%d%%" % roundi(Collection.STAR_BONUS * (c.stars - 1) * 100), Forge.GAIN))
	# A little notch pointing at the chip it belongs to.
	var chip: Control = _row.get_child(Data.STATS.find(open_stat))
	var notch := Control.new()
	notch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notch.position = at + Vector2(chip.position.x + chip.size.x / 2, 0)
	notch.draw.connect(func():
		notch.draw_colored_polygon(PackedVector2Array([Vector2(-12, 1), Vector2(0, -11), Vector2(12, 1)]), Forge.GOLD))
	_pop.add_child(notch)


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
		for s in app.col.skills(c):
			v.add_child(_slot(s))
	else:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", Forge.flat(Color(Forge.PLAQUE, 0.85), Color(Forge.BRONZE, 0.8), 2, Vector4(24, 20, 24, 20)))
		var l := Forge.label("Passives arrive with the combat port.", 24, Forge.MUTED, Forge.SANS_ITALIC)
		p.add_child(l)
		v.add_child(p)
	return v


func _slot(s: Dictionary) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Forge.flat(Color(Forge.PLAQUE, 0.85), Color(Forge.BRONZE, 0.8), 2, Vector4(22, 16, 22, 16)))
	var h := Forge.hbox(22)
	p.add_child(h)
	h.add_child(pattern_grid(s.pattern, Forge.ELEM[Data.hero(hero).elem]))
	var txt := Forge.vbox(2)
	txt.size_flags_horizontal = SIZE_EXPAND_FILL
	h.add_child(txt)
	txt.add_child(Forge.sc(s.name, 30, Forge.PARCHMENT, false, 0.08))
	txt.add_child(Forge.label(meta(s), 24, Forge.MUTED))
	var cd := Forge.hbox(6)
	cd.size_flags_vertical = SIZE_SHRINK_CENTER
	cd.add_child(Forge.glyph("cooldown", 24, Forge.MUTED))
	cd.add_child(Forge.label(str(s.cd), 26, Forge.MUTED, Forge.SANS_BOLD))
	cd.tooltip_text = "Cooldown %d" % s.cd
	h.add_child(cd)
	if swapping:
		h.add_child(_round_button("swap", "Swap %s" % s.name, _no_swap, 66))
	return p


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
