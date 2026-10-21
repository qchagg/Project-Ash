class_name Forge
extends RefCounted
## The Ashgrid look in one place: palette, type, icons and the three button roles.
## Every screen builds from these so the game reads as one system (see the Ashgrid Mobile UI canvas).
## Buttons have jobs: studs commit (merge, feed, begin battle; at most one per screen),
## ember is for everyday reversible actions, links move between screens.

const INK := Color("#120e0a")
const PLAQUE := Color("#1d1610")
const PLAQUE_DEEP := Color("#18120c")
const GOLD := Color("#e3c278")
const GOLD_LIGHT := Color("#f6dc94")
const GOLD_DEEP := Color("#c9a24f")
const BRONZE := Color("#8a6a2c")
const PARCHMENT := Color("#f3e6c4")
const MUTED := Color("#cbbd9f")
const LABEL := Color("#b39c6a")
const DIM := Color("#9d8a63")
const GAIN := Color("#a9dd92")
const ELEM := {"fire": Color("#ff7b47"), "water": Color("#43b8de"), "earth": Color("#c4925f"), "wind": Color("#8ad46f")}
const STAT_TINT := {"max_hp": Color("#e86a5a"), "atk": Color("#f6dc94"), "def": Color("#9fb3c8"), "spd": Color("#8ad46f")}
const STAT_ICON := {"max_hp": "hp", "atk": "atk", "def": "def", "spd": "spd"}
const STAT_NAME := {"max_hp": "health", "atk": "attack", "def": "defense", "spd": "speed"}

# Alegreya Sans SC, always set in lowercase so every letter is a small capital of the same height.
const SC := preload("res://fonts/alegreya-sans-sc-bold.woff")
const SC_HEAVY := preload("res://fonts/alegreya-sans-sc-extrabold.woff")
const SANS := preload("res://fonts/alegreya-sans-medium.woff")
const SANS_BOLD := preload("res://fonts/alegreya-sans-bold.woff")
const SANS_ITALIC := preload("res://fonts/alegreya-sans-medium-italic.woff")
# The text fonts have no ★; this subset of Noto Sans Symbols 2 fills in ★ ✦ → ◆.
const SYMBOLS := preload("res://fonts/symbols.woff")

static var _tracked := {}
static var _icons := {}


static func setup() -> void:
	for f in [SC, SC_HEAVY, SANS, SANS_BOLD, SANS_ITALIC]:
		f.fallbacks = [SYMBOLS]


## A small-caps label with the wide tracking of the mockups.
static func sc(text: String, px: int, color := PARCHMENT, heavy := false, track := 0.14) -> Label:
	return label(text.to_lower(), px, color, tracked(SC_HEAVY if heavy else SC, roundi(px * track)))


static func label(text: String, px: int, color := PARCHMENT, font: Font = SANS) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", px)
	l.add_theme_color_override("font_color", color)
	return l


static func tracked(font: Font, spacing: int) -> Font:
	var key := "%s:%d" % [font.resource_path, spacing]
	if not _tracked.has(key):
		var v := FontVariation.new()
		v.base_font = font
		v.spacing_glyph = spacing
		_tracked[key] = v
	return _tracked[key]


static func icon(name: String) -> Texture2D:
	if not _icons.has(name):
		_icons[name] = load("res://art/icons/ui/%s.svg" % name)
	return _icons[name]


static func sigil(elem: String) -> Texture2D:
	return icon("elem_" + elem)


## An icon tinted to a colour, sized in a fixed box.
static func glyph(name: String, px: int, color: Color) -> TextureRect:
	var t := TextureRect.new()
	t.texture = icon(name)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(px, px)
	t.modulate = color
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


static func flat(bg: Color, border := Color.TRANSPARENT, width := 0, pad := Vector4.ZERO) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.content_margin_left = pad.x
	s.content_margin_top = pad.y
	s.content_margin_right = pad.z
	s.content_margin_bottom = pad.w
	return s


static func _button(text: String, px: int, styles: Dictionary, colors: Dictionary) -> Button:
	var b := Button.new()
	b.text = text.to_lower()
	b.add_theme_font_override("font", tracked(SC, roundi(px * 0.16)))
	b.add_theme_font_size_override("font_size", px)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(state, styles.get(state, styles.normal))
	for k in colors:
		b.add_theme_color_override(k, colors[k])
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.focus_mode = Control.FOCUS_NONE
	return b


## Commit: a hairline gold frame with a diamond stud at each end. Filled gold studs mark the primary commit.
static func studs(text: String, primary := true, height := 80) -> Button:
	var edge := GOLD if primary else GOLD_DEEP
	var bg := Color("#3e2810") if primary else Color("#201811")
	var styles := {
		"normal": flat(bg, edge, 2, Vector4(40, 0, 40, 0)),
		"hover": flat(bg.lightened(0.08), edge, 2, Vector4(40, 0, 40, 0)),
		"pressed": flat(bg.darkened(0.2), edge, 2, Vector4(40, 0, 40, 0)),
		"disabled": flat(Color("#1a130d"), Color(GOLD_DEEP, 0.35), 2, Vector4(40, 0, 40, 0)),
	}
	var b := _button(text, 26, styles, {"font_color": GOLD_LIGHT if primary else PARCHMENT, "font_hover_color": GOLD_LIGHT,
		"font_pressed_color": GOLD_LIGHT, "font_disabled_color": Color(PARCHMENT, 0.35)})
	b.custom_minimum_size.y = height
	b.draw.connect(func():
		var y := b.size.y / 2
		var c := Color(GOLD_DEEP, 0.35) if b.disabled else edge
		for x in [0.0, b.size.x]:
			var d := PackedVector2Array([Vector2(x - 7, y), Vector2(x, y - 7), Vector2(x + 7, y), Vector2(x, y + 7)])
			b.draw_colored_polygon(d, c if primary and not b.disabled else INK)
			b.draw_polyline(d + PackedVector2Array([d[0]]), c, 2.0))
	return b


## Everyday: a soft bevel, warm fill and bronze edge. Never louder than studs.
static func ember(text: String, height := 80) -> Button:
	var mk := func(bg: Color, edge: Color) -> StyleBoxFlat:
		var s := flat(bg, edge, 2, Vector4(36, 0, 36, 0))
		s.border_width_top = 2
		s.shadow_color = Color(0, 0, 0, 0.35)
		s.shadow_size = 0
		return s
	var styles := {
		"normal": mk.call(Color("#261c13"), Color(BRONZE, 0.95)),
		"hover": mk.call(Color("#2f2318"), BRONZE.lightened(0.15)),
		"pressed": mk.call(Color("#1a130d"), BRONZE),
		"disabled": mk.call(Color("#1a130d"), Color(BRONZE, 0.4)),
	}
	var b := _button(text, 26, styles, {"font_color": PARCHMENT, "font_hover_color": PARCHMENT,
		"font_pressed_color": PARCHMENT, "font_disabled_color": Color(PARCHMENT, 0.35)})
	b.custom_minimum_size.y = height
	b.draw.connect(func():
		if not b.disabled:
			b.draw_line(Vector2(3, 3), Vector2(b.size.x - 3, 3), Color(GOLD_LIGHT, 0.22), 2.0))
	return b


## Move: gold small caps and a glyph, no frame.
static func link(text: String, glyph_name := "back", px := 24) -> Button:
	var empty := StyleBoxEmpty.new()
	var b := _button(text, px, {"normal": empty}, {"font_color": GOLD, "font_hover_color": GOLD_LIGHT,
		"font_pressed_color": GOLD_LIGHT, "font_disabled_color": Color(GOLD, 0.35)})
	b.add_theme_font_override("font", tracked(SC, roundi(px * 0.14)))
	if glyph_name != "":
		b.icon = icon(glyph_name)
		b.add_theme_constant_override("icon_max_width", roundi(px * 1.3))
		b.add_theme_color_override("icon_normal_color", GOLD)
		b.add_theme_color_override("icon_hover_color", GOLD_LIGHT)
		b.add_theme_color_override("icon_pressed_color", GOLD_LIGHT)
		b.add_theme_constant_override("h_separation", 10)
	b.custom_minimum_size.y = 80
	return b


## The tier frame and inner hairline every card wears; 4★ cards get a turning rim in their element's colours.
static func card_frame(ci: CanvasItem, r: Rect2, stars: int, elem: String, t: float) -> void:
	var tier: Color = Data.TIER_COLORS[stars]
	if stars == 4:
		var pal: Array = Data.ELEM_COLORS[elem]
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		for i in 65:
			var f := i / 64.0
			pts.append(perimeter(r.grow(-2), f))
			var k := fposmod(f * 4.0 - t * 0.66, 4.0)
			cols.append(pal[int(k) % 4].lerp(pal[(int(k) + 1) % 4], k - floorf(k)))
		ci.draw_polyline_colors(pts, cols, 5.0)
	else:
		ci.draw_rect(r.grow(-2), tier, false, 5.0)
	ci.draw_rect(r.grow(-11), Color(tier.lightened(0.2), 0.6), false, 1.5)


## Filigree corners from the Gilded Forge menus.
static func filigree(ci: CanvasItem, r: Rect2, color: Color, s := 56.0) -> void:
	for corner in [[r.position, Vector2(1, 1)], [Vector2(r.end.x, r.position.y), Vector2(-1, 1)],
			[Vector2(r.position.x, r.end.y), Vector2(1, -1)], [r.end, Vector2(-1, -1)]]:
		var o: Vector2 = corner[0] - corner[1] * 9.0
		var d: Vector2 = corner[1]
		var k := s / 48.0
		var arc := PackedVector2Array()
		arc.append(o + d * Vector2(3, 45) * k)
		for i in 9:
			var a := PI + i * (PI / 2) / 8
			arc.append(o + d * (Vector2(14, 14) + Vector2(cos(a), sin(a)) * 11) * k)
		arc.append(o + d * Vector2(45, 3) * k)
		ci.draw_polyline(arc, color, 2.0, true)


static func perimeter(r: Rect2, f: float) -> Vector2:
	var d := f * 2 * (r.size.x + r.size.y)
	if d < r.size.x: return r.position + Vector2(d, 0)
	d -= r.size.x
	if d < r.size.y: return r.position + Vector2(r.size.x, d)
	d -= r.size.y
	if d < r.size.x: return r.position + Vector2(r.size.x - d, r.size.y)
	d -= r.size.x
	return r.position + Vector2(0, r.size.y - d)


## Crops the square portrait to a rect around its focus point, zoomed toward the face.
static func portrait(ci: CanvasItem, tex: Texture2D, r: Rect2, p: Dictionary, zoom := 0.62) -> void:
	var ts := tex.get_size()
	var z := maxf(1.0, p.zoom * zoom)
	var region := Vector2(ts.y / z * r.size.x / r.size.y, ts.y / z)
	if region.x > ts.x:
		region = Vector2(ts.x, ts.x * r.size.y / r.size.x)
	var c := Vector2(ts.x * p.x / 100.0, ts.y * p.y / 100.0)
	var pos := (c - region / 2).clamp(Vector2.ZERO, ts - region)
	ci.draw_texture_rect_region(tex, r, Rect2(pos, region))


static func diamond(ci: CanvasItem, c: Vector2, r: float, color: Color, filled := true) -> void:
	var d := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
	if filled:
		ci.draw_colored_polygon(d, color)
	else:
		ci.draw_polyline(d + PackedVector2Array([d[0]]), color, 2.0)


## A thin gold rule with a diamond in the middle.
static func rule() -> Control:
	var r := Control.new()
	r.custom_minimum_size.y = 16
	r.draw.connect(func():
		var y := r.size.y / 2
		r.draw_line(Vector2(0, y), Vector2(r.size.x / 2 - 14, y), GOLD_DEEP, 2.0)
		r.draw_line(Vector2(r.size.x / 2 + 14, y), Vector2(r.size.x, y), GOLD_DEEP, 2.0)
		diamond(r, Vector2(r.size.x / 2, y), 7, GOLD))
	return r


static func margins(m: MarginContainer, l: int, t: int, r: int, b: int) -> MarginContainer:
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_bottom", b)
	return m


static func vbox(sep: int) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep: int) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h
