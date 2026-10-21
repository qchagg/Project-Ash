class_name CharacterView
extends Control
## The hero out of the card: full art drifting over their element's backdrop, name, title and lore.
## The first page of a hero: the sheet sits one scroll below. Matchups fold away under the element tag. A painted regional background can slot in under the backdrop.

const MODE := "four"

var app: App
var hero := ""
var uid := ""
var _matchups := false
var _art: Control
var _tex: Texture2D
## A full-body cutout, when the hero has one; otherwise the square portrait fills the page.
var _full: Texture2D
var _full_info := {}
var _tags: VBoxContainer
var _t := 0.0
var _arrow_btn: Button

signal down_requested


func setup(a: App, hero_key: String, card_uid: String) -> CharacterView:
	app = a
	hero = hero_key
	uid = card_uid
	return self


func _ready() -> void:
	var h := Data.hero(hero)
	var c := app.col.by(uid)
	_tex = load(h.portrait.src)
	if h.has("full"):
		_full_info = h.full
		_full = load(h.full.src)

	var bd := Backdrop.new()
	bd.elem = h.elem
	bd.focus = Vector2(0.6, 0.36)
	bd.strength = 1.4
	bd.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bd)

	# The art, drifting slowly and fading out above the text.
	_art = Control.new()
	_art.set_anchors_preset(PRESET_FULL_RECT)
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.draw.connect(_draw_art)
	add_child(_art)
	var motes := Backdrop.new()
	motes.elem = h.elem
	motes.glow = false
	motes.set_anchors_preset(PRESET_FULL_RECT)
	add_child(motes)

	var foot := Forge.margins(MarginContainer.new(), 44, 0, 44, 190)
	foot.set_anchors_preset(PRESET_BOTTOM_WIDE)
	foot.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(foot)
	var v := Forge.vbox(26)
	foot.add_child(v)
	var names := Forge.vbox(10)
	v.add_child(names)
	if c.stars < 4:
		names.add_child(Forge.sc("%d★ · steps out of the frame at 4★" % c.stars, 20, Forge.LABEL))
	var nm := Forge.sc(h.name, 96, Forge.PARCHMENT, true, 0.08)
	nm.add_theme_color_override("font_shadow_color", Color.BLACK)
	nm.add_theme_constant_override("shadow_offset_y", 5)
	names.add_child(nm)
	var tl := Forge.hbox(18)
	names.add_child(tl)
	tl.add_child(Forge.sc(h.title, 28, Forge.GOLD))
	var fade := Control.new()
	fade.size_flags_horizontal = SIZE_EXPAND_FILL
	fade.custom_minimum_size.y = 2
	fade.size_flags_vertical = SIZE_SHRINK_CENTER
	fade.draw.connect(func():
		fade.draw_polyline_colors(PackedVector2Array([Vector2.ZERO, Vector2(fade.size.x, 0)]),
			PackedColorArray([Forge.GOLD_DEEP, Color(Forge.GOLD_DEEP, 0)]), 2.0))
	tl.add_child(fade)
	var lore := Forge.label("[A line or two of %s’s voice or lore goes here.]" % h.name, 30, Color("#e2d5b6"), Forge.SANS_ITALIC)
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(lore)
	_tags = Forge.vbox(18)
	v.add_child(_tags)
	_fill_tags()
	add_child(_arrow())


## The bobbing arrow at the foot of the page: the sheet is one scroll (or one tap) below.
func _arrow() -> Control:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.tooltip_text = "Stats and skills"
	b.custom_minimum_size = Vector2(200, 130)
	b.position = Vector2(260, 1560 - 150)
	b.size = Vector2(200, 130)
	b.pressed.connect(func(): down_requested.emit())
	b.draw.connect(func():
		var bob := 8.0 * sin(_t * TAU / 1.6)
		var f := Forge.tracked(Forge.SC, 3)
		b.draw_string(f, Vector2(0, 34), "stats", HORIZONTAL_ALIGNMENT_CENTER, b.size.x, 22, Forge.GOLD)
		var c := Vector2(b.size.x / 2, 74 + bob)
		b.draw_polyline(PackedVector2Array([c + Vector2(-20, -8), c + Vector2(0, 12), c + Vector2(20, -8)]), Forge.GOLD_LIGHT, 3.0, true)
		b.draw_polyline(PackedVector2Array([c + Vector2(-14, 10), c + Vector2(0, 24), c + Vector2(14, 10)]), Color(Forge.GOLD, 0.45), 2.0, true))
	_arrow_btn = b
	return b


func _fill_tags() -> void:
	for c in _tags.get_children():
		c.queue_free()
	var h := Data.hero(hero)
	var row := Forge.hbox(16)
	_tags.add_child(row)
	var elem := _tag(Data.ELEMS[h.elem].label, h.elem, Forge.ELEM[h.elem])
	elem.add_child(Forge.glyph("chevron", 22, Forge.GOLD))
	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.tooltip_text = "Matchups"
	btn.set_anchors_preset(PRESET_FULL_RECT)
	btn.pressed.connect(_toggle_matchups)
	var wrap := _tag_panel(elem)
	wrap.add_child(btn)
	row.add_child(wrap)
	row.add_child(_tag_panel(_tag(h.range.capitalize(), "", Color.WHITE)))
	if _matchups:
		var m := Forge.hbox(36)
		_tags.add_child(m)
		for e in Data.ELEMS:
			if Data.beats(MODE, h.elem, e):
				m.add_child(_line("beats " + Data.ELEMS[e].label, e))
		for e in Data.ELEMS:
			if Data.beats(MODE, e, h.elem):
				m.add_child(_line("weak to " + Data.ELEMS[e].label, e))


func _toggle_matchups() -> void:
	_matchups = not _matchups
	_fill_tags()


func _tag(text: String, elem: String, tint: Color) -> HBoxContainer:
	var h := Forge.hbox(12)
	if elem != "":
		var g := TextureRect.new()
		g.texture = Forge.sigil(elem)
		g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		g.custom_minimum_size = Vector2(26, 26)
		g.modulate = tint
		h.add_child(g)
	h.add_child(Forge.sc(text, 26, Forge.PARCHMENT, false, 0.12))
	return h


func _tag_panel(inner: Control) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Forge.flat(Color(Forge.INK, 0.7), Color(Forge.GOLD_DEEP, 0.6), 2, Vector4(20, 10, 20, 10)))
	p.add_child(inner)
	for c in [inner] + inner.get_children():
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func _line(text: String, elem: String) -> Control:
	var h := Forge.hbox(10)
	var g := TextureRect.new()
	g.texture = Forge.sigil(elem)
	g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	g.custom_minimum_size = Vector2(24, 24)
	g.modulate = Forge.ELEM[elem]
	h.add_child(g)
	h.add_child(Forge.sc(text, 24, Color("#e2d5b6"), false, 0.12))
	return h


func _process(delta: float) -> void:
	_t += delta
	_art.queue_redraw()
	if _arrow_btn:
		_arrow_btn.queue_redraw()


func _draw_art() -> void:
	if _full:
		_draw_full()
		return
	# A slow 12-second drift and zoom, like the mockup's Ken Burns pass.
	var k := 0.5 - 0.5 * cos(_t * TAU / 12.0)
	var s := 1270.0 * (1.06 + 0.04 * k)
	var pos := Vector2(-275 - 15 * k, -11 * k)
	var r := Rect2(pos, Vector2(s, s))
	_art.draw_texture_rect(_tex, r, false)
	# Fade the art into the ink so the text sits on darkness.
	var top := 1560.0 * 0.48
	var bottom := 1560.0 * 0.8
	_art.draw_polygon(PackedVector2Array([Vector2(0, top), Vector2(720, top), Vector2(720, bottom), Vector2(0, bottom)]),
		PackedColorArray([Color(Forge.INK, 0), Color(Forge.INK, 0), Forge.INK, Forge.INK]))
	_art.draw_rect(Rect2(0, bottom - 1, 720, 1560 - bottom + 1), Forge.INK)
	# A soft shade under the top bar so the links read over light art.
	_art.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(720, 0), Vector2(720, 220), Vector2(0, 220)]),
		PackedColorArray([Color(Forge.INK, 0.75), Color(Forge.INK, 0.75), Color(Forge.INK, 0), Color(Forge.INK, 0)]))


## The cutout stands over the backdrop and breathes: a slow rise and fall, a little sway, anchored at the hips.
func _draw_full() -> void:
	var ts := _full.get_size()
	var w: float = 720.0 * _full_info.get("w", 1.5)
	var h := w * ts.y / ts.x
	var breathe := sin(_t * TAU / 5.0)
	var sway := sin(_t * TAU / 9.0)
	var scale := 1.0 + 0.012 * breathe
	var size := Vector2(w, h) * scale
	# Centre the figure (its x focus) a little right of the page centre, leaving the left for the name.
	var cx := 400.0 + 6.0 * sway
	# The cut at the hips lands below the fade, where the page is already solid ink.
	var top := 1310.0 - size.y
	var pos := Vector2(cx - size.x * _full_info.get("x", 50) / 100.0, top)
	_art.draw_texture_rect(_full, Rect2(pos, size), false)
	# The image is cut at the hips: fade it into the ink under the name.
	var a := 1560.0 * 0.55
	var b := 1560.0 * 0.78
	_art.draw_polygon(PackedVector2Array([Vector2(0, a), Vector2(720, a), Vector2(720, b), Vector2(0, b)]),
		PackedColorArray([Color(Forge.INK, 0), Color(Forge.INK, 0), Forge.INK, Forge.INK]))
	_art.draw_rect(Rect2(0, b - 1, 720, 1560 - b + 1), Forge.INK)
