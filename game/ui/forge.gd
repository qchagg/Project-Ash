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
# Battle colour language, shared with Enchanted Arms and Fire Emblem: blue is where you can move, red is what an attack
# will hit, green is what a heal or shield will cover; gold stays the colour of your own choice.
const MOVE := Color("#4f8dff")
const HARM := Color("#ec4a3c")
const MEND := Color("#5fd38a")
# Saturated enough to read apart from the gold everywhere they appear; earth leans clay so it isn't mistaken for gold.
const ELEM := {"fire": Color("#ff5a1f"), "water": Color("#22b4ff"), "earth": Color("#c8602e"), "wind": Color("#52e06a")}
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


## A home region's badge: its sigil in the region's light, on a disc of its dark, ringed in gold.
static func region_badge(key: String, px: int) -> Control:
	var r: Dictionary = Data.REGIONS[key]
	var c := Control.new()
	c.custom_minimum_size = Vector2(px, px)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var m := c.size / 2
		var rad := minf(m.x, m.y)
		c.draw_circle(m, rad, r.dark)
		c.draw_arc(m, rad - 1.5, 0, TAU, 48, GOLD_DEEP, 3.0, true)
		c.draw_arc(m, rad - 6, 0, TAU, 48, Color(r.light, 0.35), 1.5, true)
		var s := rad * 1.2
		c.draw_texture_rect(icon("region_" + key), Rect2(m - Vector2(s, s) / 2, Vector2(s, s)), false, r.light))
	return c


## A region's colorway as a panel: the dark, cut by a diagonal of the light rising to the top-right corner.
static func region_swatch(key: String, size: Vector2) -> Control:
	var r: Dictionary = Data.REGIONS[key]
	var c := Control.new()
	c.custom_minimum_size = size
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		c.draw_rect(Rect2(Vector2.ZERO, c.size), r.dark)
		c.draw_colored_polygon(PackedVector2Array([Vector2(c.size.x, 0), c.size, Vector2(0, c.size.y)]), r.light))
	return c


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
	press_weight(b)
	return b


## Gives a control a physical press: it sinks and brightens while held, then springs back past its size.
## Every Forge button has it; tiles and cards call it for themselves.
static func press_weight(c: Control, depth := 0.93) -> void:
	var tw := [null]
	var go := func(scale: float, glow: float, t: float, spring: bool):
		if not c.is_inside_tree():
			return
		c.pivot_offset = c.size / 2
		if tw[0]:
			tw[0].kill()
		var t2 := c.create_tween().set_parallel()
		t2.tween_property(c, "scale", Vector2.ONE * scale, t).set_trans(Tween.TRANS_BACK if spring else Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t2.tween_property(c, "modulate", Color(glow, glow, glow * 0.95), t)
		tw[0] = t2
	if c is BaseButton:
		c.button_down.connect(func(): go.call(depth, 1.25, 0.06, false))
		c.button_up.connect(func(): go.call(1.0, 1.0, 0.28, true))
	else:
		c.gui_input.connect(func(e: InputEvent):
			if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
				go.call(depth if e.pressed else 1.0, 1.25 if e.pressed else 1.0, 0.06 if e.pressed else 0.28, not e.pressed))


# ---------- skills: type, temporary icons, roles ----------

const TYPE_NAME := {"ranged": "ranged", "physical": "physical", "support": "support"}


## What kind of action a skill is, for its type icon: support (heals, shields, buffs, guard), physical (melee) or ranged.
static func skill_type(s: Dictionary) -> String:
	if s.get("kind", "dmg") in ["heal", "shield", "buff", "guard"]:
		return "support"
	return "physical" if s.get("range", "ranged") == "melee" else "ranged"


static func type_glyph(s: Dictionary, px: int, color := LABEL) -> TextureRect:
	var g := glyph("type_" + skill_type(s), px, color)
	g.tooltip_text = TYPE_NAME[skill_type(s)]
	return g


## A placeholder skill icon until the painted ones exist: an element-lit diamond with the skill's initials,
## its type glyph in the corner. Initials skip small words ("Rain of Renewal" → RR).
static func skill_icon(s: Dictionary, elem: String, px := 64) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(px, px)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var words: Array = s.get("base_name", s.name).split(" ")
	var initials := "".join(words.filter(func(w): return not w.to_lower() in ["of", "the", "and", "a"]).map(func(w): return w.left(1))).left(2)
	var tint: Color = ELEM.get(elem, GOLD)
	c.draw.connect(func():
		var m := c.size / 2
		var r := minf(m.x, m.y) - 2
		diamond(c, m, r, tint.darkened(0.55))
		diamond(c, m, r * 0.78, tint.darkened(0.25))
		diamond(c, m + Vector2(0, -r * 0.1), r * 0.5, Color(tint.lightened(0.35), 0.35))
		diamond(c, m, r, GOLD_DEEP, false)
		var f := tracked(SC_HEAVY, 1)
		var fs := roundi(r * 0.62)
		c.draw_string_outline(f, Vector2(0, m.y + fs * 0.36), initials.to_lower(), HORIZONTAL_ALIGNMENT_CENTER, c.size.x, fs, 6, Color(INK, 0.8))
		c.draw_string(f, Vector2(0, m.y + fs * 0.36), initials.to_lower(), HORIZONTAL_ALIGNMENT_CENTER, c.size.x, fs, PARCHMENT)
		var b := Vector2(c.size.x - r * 0.42, c.size.y - r * 0.42)
		c.draw_circle(b, r * 0.34, INK)
		c.draw_arc(b, r * 0.34, 0, TAU, 20, GOLD_DEEP, 1.5, true)
		var g := r * 0.4
		c.draw_texture_rect(icon("type_" + skill_type(s)), Rect2(b - Vector2(g, g) / 2, Vector2(g, g)), false, GOLD_LIGHT))
	return c


## Roles a kit can fill. A hero holds a role while a skill that fills it is equipped.
const ROLES := {"healer": {"glyph": "role_healer", "kinds": ["heal"], "desc": "Mends allies. Only heroes with a healing skill equipped are healers."}}


static func has_role(skills: Array, role: String) -> bool:
	return skills.any(func(s): return s.get("kind", "") in ROLES[role].kinds)


## A role tag: lit when the kit fills the role, greyed (a slot the kit could fill) when it doesn't.
static func role_tag(role: String, on: bool, px := 20) -> Control:
	var p := PanelContainer.new()
	var col := GAIN if on else Color(DIM, 0.45)
	p.add_theme_stylebox_override("panel", flat(Color(INK, 0.6), Color(col, 0.8 if on else 0.4), 1, Vector4(10, 3, 12, 3)))
	p.tooltip_text = ROLES[role].desc
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var h := hbox(6)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(h)
	h.add_child(glyph(ROLES[role].glyph, px, col))
	h.add_child(sc(role, px, col, true))
	return p


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


## A segmented-control tab: a quiet link, gold and underlined when it is the current one.
static func seg(text: String, on: bool, cb: Callable) -> Button:
	var b := link(text, "", 24)
	b.custom_minimum_size.y = 64
	for k in ["font_color", "font_hover_color"]:
		b.add_theme_color_override(k, GOLD_LIGHT if on else DIM)
	if on:
		b.draw.connect(func(): b.draw_rect(Rect2(0, b.size.y - 4, b.size.x, 4), GOLD))
	b.pressed.connect(cb)
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


## Every card crops to the same eye line, taken from Brann's card: the eyes sit EYE_LINE down the crop, the eyes-to-chin
## drop fills FACE of its height, and the eyes sit LOOK across. A portrait gives its eyes and chin as % of the image.
const EYE_LINE := 0.46
const FACE := 0.335
const LOOK := 0.53


## Draws the portrait cropped to the eye-line rule; `zoom` above the card's 0.62 pulls in closer (bond thumbnails).
## `view` names where it shows ("card", "tile", "squad", "face"), so a crop set for that view alone wins.
## Returns the part of the image it drew.
static func portrait(ci: CanvasItem, tex: Texture2D, r: Rect2, p: Dictionary, zoom := 0.62, view := "") -> Rect2:
	var src := crop(tex.get_size(), r.size, p, zoom, view)
	ci.draw_texture_rect_region(tex, r, src)
	return src


## The part of an image of size `ts` that the eye-line rule shows in a rect of size `size`. A portrait's `crops` can
## set one view by itself as [x, y, height] in %, chosen in the portrait crop tool.
static func crop(ts: Vector2, size: Vector2, p: Dictionary, zoom := 0.62, view := "") -> Rect2:
	if p.has("crops") and p.crops.has(view):
		var o: Array = p.crops[view]
		var oh: float = ts.y * o[2] / 100.0
		return Rect2(ts.x * o[0] / 100.0, ts.y * o[1] / 100.0, oh * size.x / size.y, oh)
	var eyes := Vector2(ts.x * p.eyes[0] / 100.0, ts.y * p.eyes[1] / 100.0)
	var h := minf(ts.y, ts.y * (p.chin - p.eyes[1]) / 100.0 / FACE * 0.62 / zoom)
	var region := Vector2(h * size.x / size.y, h)
	if region.x > ts.x:
		region = Vector2(ts.x, ts.x * size.y / size.x)
	return Rect2((eyes - Vector2(LOOK, EYE_LINE) * region).clamp(Vector2.ZERO, ts - region), region)


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
