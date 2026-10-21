class_name HeroSheet
extends Control
## One hero's sheet: the card, stats that open on tap, skills and passives, and the copies you own.
## Feeding is a deliberate two-step commit: Feed, pick a copy (the stats preview the result), Confirm.

const PATTERNS := {
	"pierce": [1, 5, 9, 13], "all": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15], "single": [5], "cross": [1, 4, 5, 6, 9], "sweep": [4, 5, 6, 7],
}
const PATTERN_NAMES := {"pierce": "Pierce", "single": "Single", "cross": "Cross", "sweep": "Full row"}

var app: App
var hero := ""
var uid := ""
var tab := "skills"
var swapping := false
var open_stat := ""
var feeding := false
var fodder := ""
var status := ""
var _ui: Control


func setup(a: App, hero_key: String, card_uid: String) -> HeroSheet:
	app = a
	hero = hero_key
	uid = card_uid if card_uid != "" else app.copies(hero)[0].uid
	return self


func _ready() -> void:
	var bd := Backdrop.new()
	bd.elem = Data.hero(hero).elem
	bd.focus = Vector2(0.5, 0.2)
	bd.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bd)
	_build()


func _card() -> Dictionary:
	return app.col.by(uid)


func _build() -> void:
	if _ui:
		_ui.queue_free()
	var h := Data.hero(hero)
	var c := _card()
	var root := Forge.vbox(0)
	root.set_anchors_preset(PRESET_FULL_RECT)
	add_child(root)
	_ui = root

	var top := Forge.margins(MarginContainer.new(), 30, 12, 30, 0)
	root.add_child(top)
	var tb := Forge.hbox(0)
	top.add_child(tb)
	var back := Forge.link("roster")
	back.pressed.connect(app.show_roster)
	tb.add_child(back)
	var sp := Control.new()
	sp.size_flags_horizontal = SIZE_EXPAND_FILL
	tb.add_child(sp)
	tb.add_child(_round_button("character", "View %s as a character" % h.name, func(): app.show_character(hero, uid)))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	root.add_child(scroll)
	var body := Forge.margins(MarginContainer.new(), 44, 8, 44, 24)
	body.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(body)
	var col := Forge.vbox(34)
	body.add_child(col)

	var art := CardArt.new().setup(hero, c.stars)
	art.ornate = true
	art.custom_minimum_size = Vector2(330, 440)
	art.size_flags_horizontal = SIZE_SHRINK_CENTER
	col.add_child(art)

	var names := Forge.vbox(8)
	col.add_child(names)
	var nm := Forge.sc(h.name, 62, Forge.PARCHMENT, true, 0.1)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	names.add_child(nm)
	var tl := Forge.hbox(16)
	tl.alignment = BoxContainer.ALIGNMENT_CENTER
	names.add_child(tl)
	tl.add_child(_hairline(52))
	tl.add_child(Forge.sc(h.title, 24, Forge.GOLD))
	for i in c.stars:
		tl.add_child(Forge.glyph("star", 20, Data.TIER_COLORS[c.stars].lightened(0.15)))
	tl.add_child(_hairline(52))

	col.add_child(_stats(c))
	col.add_child(_kit(c))

	root.add_child(_footer(c))


func _stats(c: Dictionary) -> Control:
	var v := Forge.vbox(14)
	var row := Forge.hbox(14)
	v.add_child(row)
	var s := app.col.stats(c)
	var after := _preview()
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
		var gain: bool = not after.is_empty() and after[k] > s[k]
		b.text = str(after[k] if gain else s[k])
		b.add_theme_font_override("font", Forge.SANS_BOLD)
		b.add_theme_font_size_override("font_size", 30)
		for fc in ["font_color", "font_hover_color", "font_pressed_color"]:
			b.add_theme_color_override(fc, Forge.GAIN if gain else Forge.PARCHMENT)
		b.add_theme_constant_override("h_separation", 10)
		b.pressed.connect(func():
			open_stat = "" if open_stat == k else k
			_build())
		row.add_child(b)
	if open_stat != "":
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", Forge.flat(Color(Forge.PLAQUE, 0.92), Forge.GOLD, 2, Vector4(26, 18, 26, 18)))
		v.add_child(p)
		var lines := Forge.vbox(10)
		p.add_child(lines)
		lines.add_child(Forge.sc(Forge.STAT_NAME[open_stat], 22, Forge.GOLD))
		lines.add_child(_kv("This copy", str(s[open_stat]), Forge.PARCHMENT))
		lines.add_child(_kv("%s’s average" % Data.hero(hero).name, str(Data.hero(hero)[open_stat]), Forge.PARCHMENT))
		if not after.is_empty():
			lines.add_child(_kv("After feeding the chosen copy", "%d (%+d)" % [after[open_stat], after[open_stat] - s[open_stat]], Forge.GAIN))
	return v


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
		var open: int = c.stars - c.augs.size()
		if open > 0:
			var aug := Forge.hbox(16)
			var d := Control.new()
			d.custom_minimum_size = Vector2(24, 24)
			d.size_flags_vertical = SIZE_SHRINK_CENTER
			d.draw.connect(func(): Forge.diamond(d, Vector2(12, 12), 11, Forge.GOLD_DEEP, false))
			aug.add_child(d)
			aug.add_child(Forge.label("%d augment slot%s open" % [open, "" if open == 1 else "s"], 24, Forge.LABEL))
			v.add_child(aug)
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
	var grid := Control.new()
	grid.custom_minimum_size = Vector2(56, 44)
	grid.size_flags_vertical = SIZE_SHRINK_CENTER
	var cells: Array = PATTERNS.get(s.pattern, [])
	var tint: Color = Forge.ELEM[Data.hero(hero).elem]
	grid.draw.connect(func():
		for i in 16:
			grid.draw_rect(Rect2((i % 4) * 14, (i / 4) * 11, 12, 9), tint if i in cells else Color("#3a2c1a")))
	h.add_child(grid)
	var txt := Forge.vbox(2)
	txt.size_flags_horizontal = SIZE_EXPAND_FILL
	h.add_child(txt)
	txt.add_child(Forge.sc(s.name, 30, Forge.PARCHMENT, false, 0.08))
	txt.add_child(Forge.label(_meta(s), 24, Forge.MUTED))
	var cd := Forge.hbox(6)
	cd.size_flags_vertical = SIZE_SHRINK_CENTER
	cd.add_child(Forge.glyph("cooldown", 24, Forge.MUTED))
	cd.add_child(Forge.label(str(s.cd), 26, Forge.MUTED, Forge.SANS_BOLD))
	cd.tooltip_text = "Cooldown %d" % s.cd
	h.add_child(cd)
	if swapping:
		h.add_child(_round_button("swap", "Swap %s" % s.name, _no_swap, 66))
	return p


func _meta(s: Dictionary) -> String:
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


func _num(x: float) -> String:
	return str(snappedf(x, 0.01)).trim_suffix(".0")


func _footer(c: Dictionary) -> Control:
	var m := Forge.margins(MarginContainer.new(), 44, 16, 44, 44)
	var v := Forge.vbox(20)
	m.add_child(v)

	var row := Forge.hbox(16)
	v.add_child(row)
	var lab := Forge.vbox(2)
	lab.size_flags_vertical = SIZE_SHRINK_CENTER
	lab.custom_minimum_size.x = 120
	lab.add_child(Forge.sc("copies", 22, Forge.GOLD))
	var copies := app.copies(hero)
	lab.add_child(Forge.label("%d owned" % copies.size(), 22, Forge.LABEL))
	row.add_child(lab)
	for cp in copies:
		row.add_child(_thumb(cp))

	var msg := status
	if msg == "" and feeding:
		msg = "Choose a copy to feed into this one." if fodder == "" else "The stats above show the result. Confirm to feed."
	if msg != "":
		var l := Forge.label(msg, 24, Forge.GOLD, Forge.SANS_ITALIC)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l)

	var act := Forge.hbox(24)
	v.add_child(act)
	var field := Forge.ember("bench" if uid in app.col.squad else "field")
	field.pressed.connect(func():
		status = app.col.toggle_field(uid)
		_build())
	act.add_child(field)
	if feeding:
		var cancel := Forge.link("cancel", "")
		cancel.pressed.connect(_cancel_feed)
		act.add_child(cancel)
	var sp := Control.new()
	sp.size_flags_horizontal = SIZE_EXPAND_FILL
	act.add_child(sp)
	var commit := _commit(c, copies)
	if commit:
		act.add_child(commit)
	return m


## The one commit on this screen: feed below 3★, the Ashcrown at 3★, nothing at 4★.
func _commit(c: Dictionary, copies: Array) -> Button:
	if c.stars == 3:
		var b := Forge.studs("ashcrown")
		b.disabled = app.col.crowns < 1
		b.tooltip_text = "Spend an Ashcrown to take %s to 4★." % Data.hero(hero).name
		b.pressed.connect(func():
			if app.col.crown(uid):
				status = "The Ashcrown takes %s to 4★." % Data.hero(hero).name
			_build())
		return b
	if c.stars >= 4:
		return null
	var b := Forge.studs("confirm feed" if feeding and fodder != "" else "feed")
	if not feeding:
		b.disabled = not copies.any(func(o): return o.uid != uid and o.stars == c.stars)
		b.tooltip_text = "Needs another %d★ copy." % c.stars if b.disabled else ""
		b.pressed.connect(_start_feed)
	else:
		b.disabled = fodder == ""
		b.pressed.connect(func():
			var r := app.col.merge(uid, fodder)
			status = "%s rises to %d★." % [Data.hero(hero).name, _card().stars] if r.ok else r.msg
			feeding = false
			fodder = ""
			_build())
	return b


func _thumb(cp: Dictionary) -> Control:
	var t := Control.new()
	t.custom_minimum_size = Vector2(81, 107)
	t.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var tex: Texture2D = load(Data.hero(hero).portrait.src)
	var can_feed: bool = feeding and cp.uid != uid and cp.stars == _card().stars
	t.tooltip_text = "%d★%s" % [cp.stars, " · on the field" if cp.uid in app.col.squad else ""]
	t.draw.connect(func():
		var r := Rect2(Vector2.ZERO, t.size)
		Forge.portrait(t, tex, r, Data.hero(hero).portrait)
		if feeding and cp.uid != uid and not can_feed:
			t.draw_rect(r, Color(Forge.INK, 0.65))
		var ring: Color = Color(Forge.BRONZE, 0.8)
		var w := 2.0
		if cp.uid == uid:
			ring = Forge.GOLD
			w = 4.0
		elif cp.uid == fodder:
			ring = Forge.GAIN
			w = 4.0
		elif can_feed:
			ring = Color(Forge.GAIN, 0.6)
		t.draw_rect(r, ring, false, w)
		var cap := Rect2(0, t.size.y - 30, t.size.x, 30)
		t.draw_rect(cap, Color(Forge.INK, 0.85))
		var tag := "%d★" % cp.stars
		if cp.uid == uid: tag = "this"
		elif cp.uid == fodder: tag = "feed"
		elif cp.uid in app.col.squad: tag = "field"
		t.draw_string(Forge.tracked(Forge.SC, 2), Vector2(0, t.size.y - 8), tag, HORIZONTAL_ALIGNMENT_CENTER, t.size.x, 18,
			Forge.GOLD_LIGHT if cp.uid == uid else (Forge.GAIN if cp.uid == fodder else Forge.MUTED)))
	t.gui_input.connect(func(e: InputEvent):
		if not (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
			return
		status = ""
		if feeding:
			if can_feed:
				fodder = "" if fodder == cp.uid else cp.uid
			elif cp.uid != uid:
				status = "Only another %d★ copy can feed this one." % _card().stars
		elif cp.uid != uid:
			uid = cp.uid
			open_stat = ""
		_build())
	return t


## Runs the merge on a copy of the collection so the stats can show the result before you commit.
func _preview() -> Dictionary:
	if not feeding or fodder == "":
		return {}
	var copy := Collection.new()
	copy.cards = app.col.cards.duplicate(true)
	copy.loose = app.col.loose.duplicate()
	copy.squad = app.col.squad.duplicate()
	copy.merge_mode = app.col.merge_mode
	var r := copy.merge(uid, fodder)
	return r.after if r.ok else {}


func _show(t: String) -> void:
	tab = t
	if t != "skills":
		swapping = false
	_build()


func _toggle_swap() -> void:
	swapping = not swapping
	_build()


func _no_swap() -> void:
	status = "There are no other skills to swap to yet."
	_build()


func _start_feed() -> void:
	feeding = true
	status = ""
	_build()


func _cancel_feed() -> void:
	feeding = false
	fodder = ""
	status = ""
	_build()


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


func _hairline(w: int) -> Control:
	var r := ColorRect.new()
	r.color = Forge.GOLD_DEEP
	r.custom_minimum_size = Vector2(w, 2)
	r.size_flags_vertical = SIZE_SHRINK_CENTER
	return r


func _kv(k: String, val: String, color: Color) -> Control:
	var h := Forge.hbox(10)
	var a := Forge.label(k, 24, Forge.MUTED)
	a.size_flags_horizontal = SIZE_EXPAND_FILL
	h.add_child(a)
	h.add_child(Forge.label(val, 24, color, Forge.SANS_BOLD))
	return h
