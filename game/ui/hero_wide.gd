class_name HeroWide
extends Control
## A hero on a wide screen: the roster down the left, the character large in the middle, and their details on the
## right. Details and skills show them as their animated fighter, close up, with the backdrop fading to black behind
## their head; the story shows their portrait; equip and evolve stand them in full beside the page.
##
## right under a row of tabs. The nav steps aside here and an arrow leads back. A background for the hero's home region
## goes behind them when art/backgrounds/<region>.webp exists. Evolve and equip open the phone's page in a column over
## it. The phone build keeps HeroPager.

const LIST_W := 130.0
const PANEL_W := 560.0
## The column equip and evolve open in, beside the standing hero.
const PAGE_W := 780.0
## How tall the fighter stands against the screen, and how far and fast the views slide.
const FIGURE_TALL := 0.84
## The close-up: how much bigger than standing, the room over their head, and how far down the backdrop's black reaches.
const FIGURE_ZOOM := 1.5
const HEAD_ROOM := 34.0
const TOP_FADE := 0.42
const TURN := 36.0
const TURN_TIME := 0.32
const TABS := ["details", "skills", "story"]
const STAT_NAMES := {"max_hp": ["hp", "Health"], "atk": ["atk", "Attack"], "def": ["def", "Defense"], "spd": ["spd", "Speed"]}

var app: App
var tab := ""
var hero := ""
var uid := ""
## Which tab of the right panel is showing; kept when moving between heroes.
var page := "details"
var heroes: Array = []
var _ui: Control
var _art: Control
var _tex: Texture2D
## The tall standing art a hero's profile shows when they have one; the portrait stands in until it arrives.
var _stand: Texture2D
## Which view the art was last drawn in, so a change between portrait and fighter can turn rather than cut.
var _was_figure := false
## Where the hero list was scrolled, kept when the page is rebuilt.
var _list: ScrollContainer
var _list_at := 0
var _t := 0.0
var _modal: Control


func setup(a: App, hero_key: String, card_uid := "", start_level := 0) -> HeroWide:
	app = a
	for h in Data.HEROES:
		if (app.filter == "" or h.elem == app.filter) and not app.copies(h.key).is_empty():
			heroes.append(h.key)
	if not hero_key in heroes:
		heroes.append(hero_key)
	page = TABS[clampi(start_level, 0, TABS.size() - 1)]
	_pick(hero_key, card_uid)
	return self


func _pick(hero_key: String, card_uid := "") -> void:
	hero = hero_key
	uid = card_uid if card_uid != "" and app.col.by(card_uid).get("hero", "") == hero_key else app.copies(hero_key)[0].uid


func _ready() -> void:
	clip_contents = true
	_refresh()


func _process(delta: float) -> void:
	_t += delta
	var want: String = Data.hero(hero).portrait.get("stand", "")
	if want != "" and _stand == null:
		_stand = Clips.sheet(want)
	if _art:
		_art.queue_redraw()


func _refresh() -> void:
	if _ui:
		_ui.queue_free()
	if _list:
		_list_at = _list.scroll_vertical
	var h := Data.hero(hero)
	_tex = load(h.portrait.src)
	_stand = null
	if h.portrait.has("stand"):
		Clips.hurry(h.portrait.stand)
	_ui = Control.new()
	_ui.set_anchors_preset(PRESET_FULL_RECT)
	add_child(_ui)
	move_child(_ui, 0)
	var bd := Backdrop.new()
	bd.elem = h.elem
	bd.focus = Vector2(0.42, 0.4)
	bd.strength = 1.4
	bd.set_anchors_preset(PRESET_FULL_RECT)
	_ui.add_child(bd)
	var bg := Backdrop.painted(h.get("home", ""))
	if bg:
		_ui.add_child(bg)
		var air := Weather.over(bg.art)
		if air:
			_ui.add_child(air)
	_art = Control.new()
	_art.set_anchors_preset(PRESET_FULL_RECT)
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.draw.connect(_draw_art)
	_ui.add_child(_art)
	var row := Forge.hbox(0)
	row.set_anchors_preset(PRESET_FULL_RECT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(row)
	row.add_child(_hero_list())
	row.add_child(_centre(h))
	row.add_child(_panel(h))
	_hold_list.call_deferred()
	_turn()


## The list only knows how far it can scroll once it is laid out.
func _hold_list() -> void:
	await get_tree().process_frame
	if _list:
		_list.scroll_vertical = _list_at


## True on the pages that show the hero as a fighter rather than a portrait.
func _shows_figure() -> bool:
	return page != "story" or is_instance_valid(_modal)


## Moving between the portrait and the fighter: the new view slides in as it fades up.
func _turn() -> void:
	var figure := _shows_figure()
	if figure == _was_figure or _art == null:
		return
	_was_figure = figure
	_art.modulate.a = 0.0
	_art.position.x = TURN if figure else -TURN
	var tw := _art.create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_art, "modulate:a", 1.0, TURN_TIME)
	tw.tween_property(_art, "position:x", 0.0, TURN_TIME)


## The character, large and breathing, standing on the foot of the screen between the list and the panel.
func _draw_art() -> void:
	var left := LIST_W
	var room := _art.size.x - LIST_W - PANEL_W
	if _shows_figure():
		var spr := Data.sprite_for({"hero": hero})
		var tall := Figure.height(spr, _art.size.y * FIGURE_TALL)
		var opts := {"t": _t, "breathe": 1.0, "flip": true}
		if is_instance_valid(_modal):
			# With a page open beside them they stand in full in the room it leaves.
			Figure.draw(_art, spr, Vector2((_art.size.x - PAGE_W) / 2.0, _art.size.y - 36.0), tall, opts)
			return
		# Close up, running off the foot of the screen, the top of the head against the black.
		var y := _art.size.y * TOP_FADE
		_art.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(_art.size.x, 0), Vector2(_art.size.x, y), Vector2(0, y)]),
			PackedColorArray([Color(Forge.INK, 0.98), Color(Forge.INK, 0.98), Color(Forge.INK, 0), Color(Forge.INK, 0)]))
		tall *= FIGURE_ZOOM
		Figure.draw(_art, spr, Vector2(left + room / 2.0, HEAD_ROOM + tall), tall, opts)
		_fade_foot(left, room)
		return
	var p: Dictionary = Data.hero(hero).portrait
	var crops: Dictionary = p.get("crops", {})
	var has_crop: bool = crops.has("profile") and (_stand or not p.has("stand"))
	# A portrait may run off the top; a crop fills the room edge to edge, so the edges of the crop never show.
	var side := room * 1.04 if has_crop else minf(_art.size.y * 1.12, room * 1.15)
	side *= 1.0 + 0.008 * sin(_t * TAU / 5.0)
	var r := Rect2(left + room / 2.0 - side / 2.0, 0.0 if has_crop else _art.size.y - side, side, side)
	var tex := _stand if _stand else _tex
	var ts := tex.get_size()
	var part := Rect2(Vector2.ZERO, ts)
	if has_crop:
		var c: Array = crops.profile
		part = Rect2(ts * Vector2(c[0], c[1]) / 100.0, ts * c[2] / 100.0)
	_art.draw_texture_rect_region(tex, r, part)
	_fade_foot(left, room)


## Faded at the foot, where the name sits.
func _fade_foot(left: float, room: float) -> void:
	var y := _art.size.y
	_art.draw_polygon(PackedVector2Array([Vector2(left, y - 240), Vector2(left + room, y - 240), Vector2(left + room, y), Vector2(left, y)]),
		PackedColorArray([Color(Forge.INK, 0), Color(Forge.INK, 0), Color(Forge.INK, 0.95), Color(Forge.INK, 0.95)]))


func _hero_list() -> Control:
	var bg := PanelContainer.new()
	bg.add_theme_stylebox_override("panel", Forge.flat(Color(Forge.INK, 0.82), Color.TRANSPARENT, 0, Vector4(20, 24, 20, 24)))
	bg.custom_minimum_size.x = LIST_W
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	bg.add_child(scroll)
	_list = scroll
	var v := Forge.vbox(14)
	scroll.add_child(v)
	for key in heroes:
		v.add_child(_hero_button(key))
	return bg


func _hero_button(key: String) -> Control:
	var h := Data.hero(key)
	var on: bool = key == hero
	var tex: Texture2D = load(h.portrait.src)
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(90, 90)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.tooltip_text = h.name
	b.draw.connect(func():
		var r := Rect2(Vector2.ZERO, b.size)
		b.draw_rect(r, Color("#2a241d"))
		Forge.portrait(b, tex, r.grow(-2), h.portrait, 0.75, "squad")
		if not on:
			b.draw_rect(r, Color(Forge.INK, 0.4))
		b.draw_rect(r.grow(-1), Forge.GOLD_LIGHT if on else Color(Forge.ELEM[h.elem], 0.7), false, 3.0 if on else 2.0))
	b.pressed.connect(func():
		if key != hero:
			Sfx.play("page")
			_pick(key)
			_refresh())
	Forge.press_weight(b, 0.95)
	return b


## The way back at the top, the hero's name at the foot; the art shows through between them.
func _centre(h: Dictionary) -> Control:
	var m := Forge.margins(MarginContainer.new(), 40, 30, 40, 34)
	m.size_flags_horizontal = SIZE_EXPAND_FILL
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := Forge.vbox(0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(v)
	var top := Forge.hbox(0)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(top)
	var back := Forge.link("heroes", "back", 20)
	back.pressed.connect(app.show_roster)
	top.add_child(back)
	var gap := Control.new()
	gap.size_flags_vertical = SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(gap)
	var c := app.col.by(uid)
	var stars := Forge.stars(c.stars, 20)
	stars.alignment = BoxContainer.ALIGNMENT_BEGIN
	v.add_child(stars)
	v.add_child(Forge.sc(h.title, 20, Forge.GOLD))
	var nm := Forge.sc(h.name, 58, Forge.PARCHMENT, true, 0.08)
	nm.add_theme_color_override("font_shadow_color", Color.BLACK)
	nm.add_theme_constant_override("shadow_offset_y", 3)
	v.add_child(nm)
	for n in v.get_children() + stars.get_children():
		if n != top:
			n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return m


func _panel(h: Dictionary) -> Control:
	var bg := PanelContainer.new()
	bg.add_theme_stylebox_override("panel", Forge.flat(Color(Forge.INK, 0.86), Color(Forge.GOLD_DEEP, 0.35), 0, Vector4(44, 30, 44, 34)))
	bg.custom_minimum_size.x = PANEL_W
	var v := Forge.vbox(26)
	bg.add_child(v)
	var tabs := Forge.hbox(48)
	v.add_child(tabs)
	for t in TABS:
		tabs.add_child(Forge.seg(t, t == page, func():
			page = t
			_refresh()))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	v.add_child(scroll)
	var body := Forge.vbox(24)
	body.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(body)
	match page:
		"details": _details(h, body)
		"skills": _skills(h, body)
		"story": _story(h, body)
	var foot := Forge.hbox(16)
	v.add_child(foot)
	for m in ["equip", "evolve"]:
		var b := Forge.ember(m, 60)
		b.add_theme_font_size_override("font_size", 20)
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.pressed.connect(_open_modal.bind(m))
		foot.add_child(b)
	return bg


func _details(h: Dictionary, body: VBoxContainer) -> void:
	var bio := Forge.label(h.get("bio", ""), 22, Color("#e2d5b6"), Forge.SANS_ITALIC)
	bio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(bio)
	var tags := Forge.hbox(10)
	body.add_child(tags)
	tags.add_child(Forge.glyph("elem_" + h.elem, 26, Forge.ELEM[h.elem]))
	tags.add_child(Forge.sc("%s · %s" % [Data.ELEMS[h.elem].label, h.range], 20, Forge.LABEL))
	var stats := app.col.stats(app.col.by(uid))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	body.add_child(grid)
	for k in Data.STATS:
		var p := PanelContainer.new()
		p.size_flags_horizontal = SIZE_EXPAND_FILL
		p.add_theme_stylebox_override("panel", Forge.flat(Color(Forge.PLAQUE, 0.9), Color.TRANSPARENT, 0, Vector4(18, 14, 18, 14)))
		var r := Forge.hbox(12)
		p.add_child(r)
		r.add_child(Forge.glyph(STAT_NAMES[k][0], 24, Forge.GOLD))
		var l := Forge.sc(STAT_NAMES[k][1], 18, Forge.LABEL)
		l.size_flags_horizontal = SIZE_EXPAND_FILL
		r.add_child(l)
		r.add_child(Forge.label(str(stats[k]), 24, Forge.PARCHMENT, Forge.SANS_BOLD))
		grid.add_child(p)
	if h.get("favored", []).size():
		body.add_child(Forge.sc("favored on the road · " + ", ".join(h.favored), 18, Forge.LABEL))


func _skills(h: Dictionary, body: VBoxContainer) -> void:
	for s in app.col.skills(app.col.by(uid)):
		var r := Forge.hbox(20)
		body.add_child(r)
		var icon := Forge.skill_icon(s, h.elem, 60)
		icon.size_flags_vertical = SIZE_SHRINK_BEGIN
		r.add_child(icon)
		var v := Forge.vbox(8)
		v.size_flags_horizontal = SIZE_EXPAND_FILL
		r.add_child(v)
		v.add_child(Forge.sc(s.name, 22, Forge.GOLD_LIGHT, true))
		var d := Forge.label(s.desc, 20, Forge.PARCHMENT)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(d)
		v.add_child(Forge.sc("cooldown %d" % s.cd, 16, Forge.LABEL))


func _story(h: Dictionary, body: VBoxContainer) -> void:
	var l := Forge.label(h.get("lore", ""), 21, Color("#e2d5b6"))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(l)


## Evolve and equip are built for a column: they open as one over the screen. Changes there refresh this page.
func _open_modal(m: String) -> void:
	if is_instance_valid(_modal):
		return
	_modal = Control.new()
	_modal.set_anchors_preset(PRESET_FULL_RECT)
	_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_modal)
	var dim := ColorRect.new()
	dim.color = Color(Forge.INK, 0.45)
	dim.set_anchors_preset(PRESET_FULL_RECT)
	_modal.add_child(dim)
	var shade := ColorRect.new()
	shade.color = Color(Forge.INK, 0.94)
	shade.anchor_left = 1.0
	shade.anchor_right = 1.0
	shade.anchor_bottom = 1.0
	shade.offset_left = -PAGE_W
	_modal.add_child(shade)
	var scroll := ScrollContainer.new()
	scroll.anchor_left = 1.0
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_left = -PAGE_W + 30.0
	scroll.offset_right = -30.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_modal.add_child(scroll)
	var p := EvolvePage.new().setup(app, hero, uid, m)
	p.changed.connect(_refresh)
	p.closed.connect(func():
		_modal.queue_free()
		_modal = null
		_refresh())
	scroll.add_child(p)
	_turn()
