class_name CharacterView
extends Control
## The hero out of the card: full art drifting over their element's backdrop, name, title and lore. A hero with faces
## (see Bust) is alive here: the zoom rail's face end is their live bust, and tapping them gets a line.
## The first page of a hero: the sheet sits one scroll below. Tags float their details on tap. A painted regional background can slot in under the backdrop.

const MODE := "four"

var app: App
var hero := ""
var uid := ""
var _art: Control
var _tex: Texture2D
## A full-body cutout, when the hero has one; otherwise the square portrait fills the page.
var _full: Texture2D
var _full_info := {}
var _tags: VBoxContainer
var _t := 0.0
## 0 shows the whole figure, 1 closes in on the face; the rail on the right sets it.
var _zoom := 0.0
var _rail: Control
## The live bust, for a hero with faces; the rail crossfades it with the full figure.
var _bust: Bust
var _speech: Speech

signal down_requested


func setup(a: App, hero_key: String, card_uid: String) -> CharacterView:
	app = a
	hero = hero_key
	uid = card_uid
	return self


func _ready() -> void:
	# The zoomed art is bigger than the page; keep it off the sheet below.
	clip_contents = true
	var h := Data.hero(hero)
	var c := app.col.by(uid)
	_tex = load(h.portrait.src)
	if h.has("full"):
		_full_info = h.full
		_full = load(h.full.src)
	# Heroes with a full-body cutout open wide; a square portrait opens close, as it always has.
	_zoom = app.zoom.get(hero, 0.0 if _full and not Bust.has_faces(hero) else 1.0)

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
	if Bust.has_faces(hero):
		_bust = Bust.new().setup(hero)
		_bust.melt = 0.2
		_bust.position = Vector2(-115, 150)
		_bust.size = Vector2(900, 900)
		add_child(_bust)
	var motes := Backdrop.new()
	motes.elem = h.elem
	motes.glow = false
	motes.set_anchors_preset(PRESET_FULL_RECT)
	add_child(motes)

	# Tapping the art plays the hero's cut-in, when they have one. It sits under the text and buttons.
	if _bust:
		var tap := Button.new()
		tap.flat = true
		tap.focus_mode = Control.FOCUS_NONE
		tap.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tap.tooltip_text = "Talk to %s" % h.name
		tap.position = Vector2(0, 110)
		tap.size = Vector2(640, 760)
		tap.pressed.connect(_talk)
		add_child(tap)

	var foot := Forge.margins(MarginContainer.new(), 44, 0, 44, 190)
	foot.set_anchors_preset(PRESET_BOTTOM_WIDE)
	foot.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(foot)
	var v := Forge.vbox(26)
	foot.add_child(v)
	# Title over name, then a line of bio.
	var names := Forge.vbox(4)
	v.add_child(names)
	names.add_child(Forge.sc(h.title, 28, Forge.GOLD))
	var nm := Forge.sc(h.name, 96, Forge.PARCHMENT, true, 0.08)
	nm.add_theme_color_override("font_shadow_color", Color.BLACK)
	nm.add_theme_constant_override("shadow_offset_y", 5)
	names.add_child(nm)
	var bio := Forge.label(h.get("bio", "[A line of bio goes here.]"), 30, Color("#e2d5b6"), Forge.SANS_ITALIC)
	bio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bio.custom_minimum_size.x = 580
	v.add_child(bio)
	_tags = Forge.vbox(18)
	v.add_child(_tags)
	_fill_tags()
	add_child(_arrow())
	_rail = _zoom_rail()
	add_child(_rail)


## The hero says a line while their talk clip plays; the face comes forward first if the figure was showing.
func _talk() -> void:
	if is_instance_valid(_speech) or _bust.playing() != "":
		return
	if _zoom < 0.5:
		_zoom = 1.0
		app.zoom[hero] = _zoom
		_rail.queue_redraw()
	var line := Speech.line_for(hero, "greet")
	if line == "":
		return
	# The talk clip plays when there is one; a hero with only a still says the line as it breathes.
	_bust.say()
	_speech = Speech.say(self, hero, line)
	_speech.position = Vector2(80, 790)


## A thin gold line down the right edge with a diamond on it: up closes in on the face, down shows the whole figure.
## Drag the diamond or tap the line.
func _zoom_rail() -> Control:
	var r := Control.new()
	r.position = Vector2(640, 360)
	r.size = Vector2(80, 520)
	r.mouse_default_cursor_shape = Control.CURSOR_VSIZE
	r.tooltip_text = "Zoom"
	var top := 40.0
	var bottom := r.size.y - 40.0
	r.draw.connect(func():
		var x := r.size.x / 2
		r.draw_line(Vector2(x, top), Vector2(x, bottom), Color(Forge.GOLD, 0.35), 2.0)
		for y in [top, bottom]:
			r.draw_line(Vector2(x - 8, y), Vector2(x + 8, y), Color(Forge.GOLD, 0.45), 2.0)
		# Small marks for what each end means: a face at the top, a figure at the bottom.
		r.draw_arc(Vector2(x, top - 22), 7, 0, TAU, 20, Color(Forge.GOLD, 0.5), 2.0, true)
		r.draw_arc(Vector2(x, bottom + 16), 4, 0, TAU, 12, Color(Forge.GOLD, 0.5), 2.0, true)
		r.draw_line(Vector2(x, bottom + 20), Vector2(x, bottom + 32), Color(Forge.GOLD, 0.5), 2.0)
		var y := lerpf(bottom, top, _zoom)
		Forge.diamond(r, Vector2(x, y), 11, Forge.INK)
		Forge.diamond(r, Vector2(x, y), 10, Forge.GOLD_LIGHT, false))
	var set_from := func(y: float):
		_zoom = clampf((bottom - y) / (bottom - top), 0.0, 1.0)
		app.zoom[hero] = _zoom
		r.queue_redraw()
	r.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			set_from.call(e.position.y)
			r.accept_event()
		elif e is InputEventMouseMotion and e.button_mask & MOUSE_BUTTON_MASK_LEFT:
			set_from.call(e.position.y)
			r.accept_event())
	return r


## The pager asks before taking a drag: drags that start on the zoom rail belong to it.
func blocks_drag(at: Vector2) -> bool:
	return is_instance_valid(_rail) and _rail.get_global_rect().grow(10).has_point(at)


func _arrow() -> Control:
	var b := DownArrow.make("stats")
	b.tooltip_text = "Stats and skills"
	b.position = Vector2(200, 1560 - 150)
	b.pressed.connect(func(): down_requested.emit())
	return b


func _fill_tags() -> void:
	for c in _tags.get_children():
		c.queue_free()
	var h := Data.hero(hero)
	var row := Forge.hbox(14)
	_tags.add_child(row)
	var elem := _tag(Data.ELEMS[h.elem].label, h.elem, Forge.ELEM[h.elem])
	elem.add_child(Forge.glyph("chevron", 18, Forge.GOLD))
	row.add_child(_tappable(_tag_panel(elem), "Matchups", _matchups))
	row.add_child(_tag_panel(_tag(h.range.capitalize(), "", Color.WHITE)))
	# The hero's favoured aptitudes, for trials. Tap one for what it covers.
	var apts := Forge.hbox(14)
	_tags.add_child(apts)
	for a in h.get("favored", []):
		apts.add_child(_tappable(_tag_panel(_tag("%s +%d" % [a, Data.FAVORED_BONUS], "", Color.WHITE)), Data.APTITUDES[a], _aptitude.bind(a)))


## Makes a tag a button that floats its details (see Tooltip) when tapped.
func _tappable(tag: PanelContainer, tip: String, fill: Callable) -> PanelContainer:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.tooltip_text = tip
	b.set_anchors_preset(PRESET_FULL_RECT)
	b.pressed.connect(func(): Tooltip.open(tag, fill))
	tag.add_child(b)
	return tag


func _matchups(lines: VBoxContainer) -> void:
	var h := Data.hero(hero)
	lines.add_child(Forge.sc("%s matchups" % Data.ELEMS[h.elem].label, 22, Forge.ELEM[h.elem].lightened(0.2)))
	var m := Forge.hbox(36)
	lines.add_child(m)
	for e in Data.ELEMS:
		if Data.beats(MODE, h.elem, e):
			m.add_child(_line("beats " + Data.ELEMS[e].label, e))
	for e in Data.ELEMS:
		if Data.beats(MODE, e, h.elem):
			m.add_child(_line("weak to " + Data.ELEMS[e].label, e))


func _aptitude(lines: VBoxContainer, a: String) -> void:
	lines.add_child(Forge.sc("%s · favored" % a, 22, Forge.GOLD))
	var l := Forge.label("d20 +%d, sparks on 19–20. %s" % [Data.FAVORED_BONUS, Data.APTITUDES[a]], 24, Forge.PARCHMENT, Forge.SANS_ITALIC)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 580
	lines.add_child(l)


func _tag(text: String, elem: String, tint: Color) -> HBoxContainer:
	var h := Forge.hbox(12)
	if elem != "":
		var g := TextureRect.new()
		g.texture = Forge.sigil(elem)
		g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		g.custom_minimum_size = Vector2(22, 22)
		g.modulate = tint
		h.add_child(g)
	h.add_child(Forge.sc(text, 22, Forge.PARCHMENT, false, 0.12))
	return h


func _tag_panel(inner: Control) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Forge.flat(Color(Forge.INK, 0.7), Color(Forge.GOLD_DEEP, 0.6), 2, Vector4(16, 8, 16, 8)))
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
	if _bust:
		_bust.modulate.a = smoothstep(0.25, 0.75, _zoom)



func _draw_art() -> void:
	if _full:
		_draw_full()
		return
	# Close: the slow 12-second drift and zoom across the face, like the mockup's Ken Burns pass.
	# Wide: the whole square portrait, a little wider than the page, its top edge faded into the dark.
	var k := 0.5 - 0.5 * cos(_t * TAU / 12.0)
	var z := smoothstep(0.0, 1.0, _zoom)
	var close := Rect2(Vector2(-275 - 15 * k, -11 * k), Vector2.ONE * 1270.0 * (1.06 + 0.04 * k))
	var wide := Rect2(Vector2(-140 - 6 * k, 150), Vector2.ONE * 1000.0 * (1.0 + 0.02 * k))
	var r := Rect2(wide.position.lerp(close.position, z), wide.size.lerp(close.size, z))
	_art.draw_texture_rect(_tex, r, false)
	if r.position.y > 0:
		_art.draw_rect(Rect2(0, 0, 720, r.position.y), Forge.INK)
		var e := r.position.y
		_art.draw_polygon(PackedVector2Array([Vector2(0, e), Vector2(720, e), Vector2(720, e + 160), Vector2(0, e + 160)]),
			PackedColorArray([Forge.INK, Forge.INK, Color(Forge.INK, 0), Color(Forge.INK, 0)]))
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
	# Wide: the figure (its x focus) a little right of the page centre, leaving the left for the name;
	# the cut at the hips lands below the fade, where the page is already solid ink.
	var cx := 400.0 + 6.0 * sway
	var wide := Rect2(Vector2(cx - size.x * _full_info.get("x", 50) / 100.0, 1310.0 - size.y), size)
	# Close: the face, enlarged, centred in the upper half of the page.
	var face: Array = _full_info.get("face", [50, 20])
	var big := size * 2.6
	var close := Rect2(Vector2(360 + 6.0 * sway, 560) - Vector2(big.x * face[0] / 100.0, big.y * face[1] / 100.0), big)
	var z := smoothstep(0.0, 1.0, _zoom)
	var tint := Color.WHITE
	if _bust:
		# The face end belongs to the live bust: the figure stays wide and fades out as the bust comes in.
		tint.a = 1.0 - smoothstep(0.25, 0.75, _zoom)
		z = 0.0
	_art.draw_texture_rect(_full, Rect2(wide.position.lerp(close.position, z), wide.size.lerp(close.size, z)), false, tint)
	# The image is cut at the hips: fade it into the ink under the name.
	var a := 1560.0 * 0.55
	var b := 1560.0 * 0.78
	_art.draw_polygon(PackedVector2Array([Vector2(0, a), Vector2(720, a), Vector2(720, b), Vector2(0, b)]),
		PackedColorArray([Color(Forge.INK, 0), Color(Forge.INK, 0), Forge.INK, Forge.INK]))
	_art.draw_rect(Rect2(0, b - 1, 720, 1560 - b + 1), Forge.INK)
