class_name CardTile
extends Control
## One card in the Collection grid, drawn in the Gilded Forge style: tier frame, portrait, name plate, star sparkles.

signal pressed(uid: String)

const PLATE := Color("#0a0e14")
const GOLD := Color("#e3c278")
const PARCHMENT := Color("#ece0c4")
const CORMORANT := preload("res://fonts/cormorant-sc-bold.woff")
const SANS_SC := preload("res://fonts/alegreya-sans-sc-bold.woff")

var card: Dictionary
var role := ""         # "base", "fodder" or ""
var on_field := false
var _tex: Texture2D
var _sigil: Texture2D
var _t := 0.0


func setup(c: Dictionary) -> void:
	card = c
	var h := Data.hero(c.hero)
	_tex = load(h.portrait.src)
	_sigil = load("res://art/icons/%s.svg" % h.elem)
	custom_minimum_size = Vector2(212, 340)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	queue_redraw()


func _process(delta: float) -> void:
	# Only 4★ rims and selected cards move, so only they redraw every frame.
	if card.stars == 4 or role != "":
		_t += delta
		queue_redraw()


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit(card.uid)
		accept_event()


func _draw() -> void:
	var h := Data.hero(card.hero)
	var r := Rect2(Vector2.ZERO, size)
	var tier: Color = Data.TIER_COLORS[card.stars]
	var pal: Array = Data.ELEM_COLORS[h.elem]

	if role != "":
		var pulse := 0.55 + 0.25 * sin(_t * 4.0)
		draw_rect(r.grow(7), Color(GOLD, pulse * 0.35))
		draw_rect(r.grow(4), Color(GOLD, pulse), false, 2.0)

	draw_rect(r, Color("#0f1218"))
	_draw_portrait(r.grow(-3), h.portrait)

	# Name plate: a dark fade up from the bottom edge.
	var top := size.y * 0.62
	draw_polygon(PackedVector2Array([Vector2(3, top), Vector2(size.x - 3, top), Vector2(size.x - 3, size.y - 3), Vector2(3, size.y - 3)]),
		PackedColorArray([Color(PLATE, 0), Color(PLATE, 0), Color(PLATE, 0.97), Color(PLATE, 0.97)]))
	draw_string(CORMORANT, Vector2(14, size.y - 40), h.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, PARCHMENT)
	draw_string(SANS_SC, Vector2(14, size.y - 18), h.title.to_lower(), HORIZONTAL_ALIGNMENT_LEFT, size.x - 28, 15, Color(PARCHMENT, 0.7))
	for i in card.stars:
		var c: Color = pal[(i + int(_t * 2)) % 4] if card.stars == 4 else tier.lightened(0.15)
		_sparkle(Vector2(size.x - 18 - i * 17, size.y - 46), 8.0, c)

	# Element sigil, top left, on a dark disc.
	draw_circle(Vector2(26, 26), 17, Color(PLATE, 0.85))
	draw_texture_rect(_sigil, Rect2(14, 14, 24, 24), false, pal[0])

	# Augment pips, top right: one slot per star, filled when used.
	for i in card.stars:
		var p := Vector2(size.x - 20 - i * 16, 22)
		if i < card.augs.size():
			draw_circle(p, 5.5, Data.ELEM_COLORS[Data.AUGS[card.augs[i].aug].fam][0])
		else:
			draw_arc(p, 5.0, 0, TAU, 16, Color(PARCHMENT, 0.6), 1.5)

	_draw_frame(r, tier, pal)

	if on_field:
		draw_string(SANS_SC, Vector2(0, 66), "on the field", HORIZONTAL_ALIGNMENT_CENTER, size.x, 14, Color(GOLD, 0.9))
	if role != "":
		var label := role.to_upper()
		var w := 96.0
		var rib := Rect2((size.x - w) / 2, -12, w, 24)
		draw_rect(rib, GOLD)
		draw_string(SANS_SC, Vector2(rib.position.x, rib.position.y + 18), label, HORIZONTAL_ALIGNMENT_CENTER, w, 16, Color("#120e0a"))


# Crops the square portrait to the card's shape around its focus point, zoomed toward the face.
func _draw_portrait(r: Rect2, p: Dictionary) -> void:
	var ts := _tex.get_size()
	var z := maxf(1.0, p.zoom * 0.62)
	var region := Vector2(ts.y / z * r.size.x / r.size.y, ts.y / z)
	var c := Vector2(ts.x * p.x / 100.0, ts.y * p.y / 100.0)
	var pos := (c - region / 2).clamp(Vector2.ZERO, ts - region)
	draw_texture_rect_region(_tex, r, Rect2(pos, region))


# 1★ bronze, 2★ silver with corner studs, 3★ gold with a hairline, 4★ a spinning prismatic rim in the element's colours.
func _draw_frame(r: Rect2, tier: Color, pal: Array) -> void:
	if card.stars == 4:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var n := 64
		for i in n + 1:
			var f := float(i) / n
			pts.append(_perimeter(r.grow(-1.5), f))
			var k := fposmod(f * 4.0 - _t * 0.66, 4.0)
			cols.append(pal[int(k) % 4].lerp(pal[(int(k) + 1) % 4], k - floorf(k)))
		draw_polyline_colors(pts, cols, 3.5)
		draw_rect(r.grow(-7), Color(pal[1], 0.5), false, 1.0)
		return
	draw_rect(r.grow(-1.5), tier, false, 3.0)
	if card.stars == 2:
		for p in [Vector2.ZERO, Vector2(r.size.x, 0), Vector2(0, r.size.y), r.size]:
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -6), p + Vector2(6, 0), p + Vector2(0, 6), p + Vector2(-6, 0)]), Color("#e6ebf0"))
	if card.stars == 3:
		draw_rect(r.grow(-7), Color(tier, 0.8), false, 1.0)


func _perimeter(r: Rect2, f: float) -> Vector2:
	var total := 2 * (r.size.x + r.size.y)
	var d := f * total
	if d < r.size.x: return r.position + Vector2(d, 0)
	d -= r.size.x
	if d < r.size.y: return r.position + Vector2(r.size.x, d)
	d -= r.size.y
	if d < r.size.x: return r.position + Vector2(r.size.x - d, r.size.y)
	d -= r.size.x
	return r.position + Vector2(0, r.size.y - d)


func _sparkle(c: Vector2, rad: float, col: Color) -> void:
	var q := rad * 0.22
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -rad), c + Vector2(q, -q), c + Vector2(rad, 0), c + Vector2(q, q),
		c + Vector2(0, rad), c + Vector2(-q, q), c + Vector2(-rad, 0), c + Vector2(-q, -q)]), col)
