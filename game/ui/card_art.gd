class_name CardArt
extends Control
## A hero's portrait in its tier frame, with the element sigil. Name plates sit below it, never on it.

var hero := ""
var stars := 1
## Draw the filigree corners from the menus (hero sheet only; tiles stay clean).
var ornate := false
## The hero sheet's showpiece: a hard drop shadow and sparkles that twinkle around the frame.
var showcase := false
## Extra marks (squad pennant, copy count) drawn on top of the card.
var overlay := Callable()
## How far the card floats and sways on its idle drift (0 keeps it still).
var drift := 1.0
var _tex: Texture2D
var _full: Texture2D
var _full_info := {}
var _t := 0.0


func setup(hero_key: String, star_count: int) -> CardArt:
	hero = hero_key
	stars = star_count
	var h := Data.hero(hero)
	_tex = load(h.portrait.src)
	# The break-out needs a cutout cut from the same image as the portrait, with its offset.
	if h.has("full") and h.full.has("origin"):
		_full_info = h.full
		_full = load(h.full.src)
	_t = float(hash(hero) % 1000) / 100.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()
	return self


func _process(delta: float) -> void:
	if stars == 4 or showcase or drift > 0:
		_t += delta
		queue_redraw()


func _draw() -> void:
	var h := Data.hero(hero)
	var r := Rect2(Vector2.ZERO, size)
	# The idle drift: a slow float and a fraction of a degree of sway, each card on its own beat.
	if drift > 0:
		var pivot := size / 2
		var bob := sin(_t * TAU / 4.2) * 3.0 * drift
		var sway := sin(_t * TAU / 6.5) * deg_to_rad(0.45) * drift
		draw_set_transform_matrix(Transform2D(sway, pivot + Vector2(0, bob)) * Transform2D(0, -pivot))
	if showcase:
		draw_rect(Rect2(r.position + Vector2(18, 18), r.size), Color(0, 0, 0, 0.55))
	draw_rect(r, Color("#1f1812"))
	var src := Forge.portrait(self, _tex, r.grow(-3), h.portrait)
	Forge.card_frame(self, r, stars, h.elem, _t)
	if ornate:
		Forge.filigree(self, r, Color("#d9a777"), 60.0)
	if stars == 4 and showcase and _full:
		_break_out(r.grow(-3), src)
	var s := minf(size.x * 0.16, 56.0)
	var c := Vector2(s * 0.5 + 16, s * 0.5 + 16)
	draw_circle(c, s * 0.5 + 4, Forge.INK)
	draw_circle(c, s * 0.5 + 2, Forge.GOLD)
	draw_circle(c, s * 0.5 - 1, Forge.ELEM[h.elem])
	draw_texture_rect(Forge.sigil(h.elem), Rect2(c - Vector2(s, s) * 0.3, Vector2(s, s) * 0.6), false, Forge.INK)
	if showcase:
		_sparkles(r)
	if overlay.is_valid():
		overlay.call(self)


## At 4★ the hero breaks out of the card: the cutout, lined up with the portrait crop, is drawn only where it
## rises above the frame's top edge (and a little over it, so the head covers the border).
func _break_out(dest: Rect2, src: Rect2) -> void:
	var scale := dest.size / src.size
	var origin := Vector2(_full_info.origin[0], _full_info.origin[1])
	var cut := _full.get_size()
	var at := dest.position + (origin - src.position) * scale
	var limit := dest.position.y + 34.0
	var rows := clampf((limit - at.y) / scale.y, 0.0, cut.y)
	if rows <= 0:
		return
	draw_texture_rect_region(_full, Rect2(at, Vector2(cut.x, rows) * scale), Rect2(Vector2.ZERO, Vector2(cut.x, rows)))


## Four-point sparkles on the frame, each fading in and out on its own beat, like the Gilded Forge menus.
func _sparkles(r: Rect2) -> void:
	var col: Color = Data.ELEM_COLORS[Data.hero(hero).elem][1] if stars == 4 else Color("#fff1c4")
	for sp in [[Vector2(r.end.x - 4, r.size.y * 0.2), 0.0], [Vector2(r.position.x + 2, r.size.y * 0.55), 0.9], [Vector2(r.size.x * 0.48, r.end.y - 2), 1.8]]:
		var k := 0.5 + 0.5 * sin((_t + sp[1]) * TAU / 2.8)
		var rad := 6.0 + 8.0 * k
		var q := rad * 0.22
		var c: Vector2 = sp[0]
		var a := sin(k * PI / 2) * PI / 4
		var pts := PackedVector2Array()
		for i in 8:
			var ang := a + i * PI / 4
			pts.append(c + Vector2(cos(ang), sin(ang)) * (rad if i % 2 == 0 else q))
		draw_colored_polygon(pts, Color(col, 0.15 + 0.85 * k))
