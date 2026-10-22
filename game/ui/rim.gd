class_name Rim
extends Control
## The living border from the 4★ cards, for anything that deserves attention: lay it over a control and it draws on the
## control's edge. Three moods, quietest first:
##   "comet": a hairline with one bright segment orbiting it, for what you can act on (a building ready to rise).
##   "flow":  the 4★ rim, colours turning round the edge, for what is chosen (the current tab, the picked road).
##   "pulse": the hairline breathing brighter and dimmer, for what is waiting on you (the commit before a fight).
## It never takes input.

var mood := "comet"
## The colours a flow turns through, or the comet's head (first colour).
var colors: Array = [Forge.GOLD_LIGHT]
var width := 3.0
## How far inside the control's edge the rim runs.
var inset := 0.0
## Laps per second for a comet, palette turns per second for a flow.
var speed := 0.16
## Add twinkling four-point sparkles at three points of the rim (the hero sheet's showcase).
var sparkles := false
var _t := 0.0


## Lays a rim over `c` and returns it.
static func on(c: Control, mood_name := "comet", cols: Array = [Forge.GOLD_LIGHT], w := 3.0, ins := 0.0) -> Rim:
	var r := Rim.new()
	r.mood = mood_name
	r.colors = cols
	r.width = w
	r.inset = ins
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r._t = randf() * 10.0
	c.add_child(r)
	r.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	return r


## An element's four flow colours (the 4★ palette).
static func elem(e: String) -> Array:
	return Data.ELEM_COLORS.get(e, [Forge.GOLD_DEEP, Forge.GOLD, Forge.GOLD_LIGHT, Forge.GOLD])


func _process(delta: float) -> void:
	if is_visible_in_tree():
		_t += delta
		queue_redraw()


func _draw() -> void:
	# A rim on a disabled button goes quiet.
	var host := get_parent()
	if host is BaseButton and host.disabled:
		return
	var r := Rect2(Vector2.ZERO, size).grow(-inset - width / 2)
	if r.size.x <= 0 or r.size.y <= 0:
		return
	var head: Color = colors[0]
	match mood:
		"flow":
			Rim.flow(self, r, colors, _t * speed * 4.0, width)
		"pulse":
			var k := 0.5 + 0.5 * sin(_t * TAU * 0.55)
			draw_rect(r, Color(head, 0.35 + 0.55 * k), false, width)
			draw_rect(r.grow(2 + 3 * k), Color(head, 0.12 * (1.0 - k)), false, 2.0)
		_:
			draw_rect(r, Color(head, 0.22), false, maxf(1.0, width * 0.5))
			Rim.comet(self, r, head, fposmod(_t * speed, 1.0), 0.16, width)
	if sparkles:
		Rim.twinkle(self, r, head, _t)


## A turning band of colours round the rect's edge.
static func flow(ci: CanvasItem, r: Rect2, pal: Array, phase: float, w: float) -> void:
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var n := pal.size()
	for i in 97:
		var f := i / 96.0
		pts.append(Forge.perimeter(r, f))
		var k := fposmod(f * n - phase, float(n))
		cols.append((pal[int(k) % n] as Color).lerp(pal[(int(k) + 1) % n], k - floorf(k)))
	ci.draw_polyline_colors(pts, cols, w)


## One bright segment of the edge, fading out behind its head at `at` (0..1 round the rect).
static func comet(ci: CanvasItem, r: Rect2, col: Color, at: float, length: float, w: float) -> void:
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for i in 25:
		var k := i / 24.0
		pts.append(Forge.perimeter(r, fposmod(at - length * (1.0 - k), 1.0)))
		cols.append(Color(col, k * k))
	# Split where the path wraps past the start, so no chord cuts across the rect.
	var seg := PackedVector2Array()
	var sc := PackedColorArray()
	for i in pts.size():
		if i > 0 and pts[i].distance_to(pts[i - 1]) > r.size.length() * 0.25:
			if seg.size() > 1:
				ci.draw_polyline_colors(seg, sc, w)
			seg = PackedVector2Array()
			sc = PackedColorArray()
		seg.append(pts[i])
		sc.append(cols[i])
	if seg.size() > 1:
		ci.draw_polyline_colors(seg, sc, w)
	ci.draw_circle(pts[pts.size() - 1], w * 0.9, col)


## Four-point sparkles at three spots on the edge, each fading in and out on its own beat.
static func twinkle(ci: CanvasItem, r: Rect2, col: Color, t: float) -> void:
	for sp in [[Vector2(r.end.x, r.position.y + r.size.y * 0.2), 0.0], [Vector2(r.position.x, r.position.y + r.size.y * 0.55), 0.9],
			[Vector2(r.position.x + r.size.x * 0.48, r.end.y), 1.8]]:
		var k := 0.5 + 0.5 * sin((t + sp[1]) * TAU / 2.8)
		var rad := 6.0 + 8.0 * k
		var q := rad * 0.22
		var c: Vector2 = sp[0]
		var a := sin(k * PI / 2) * PI / 4
		var pts := PackedVector2Array()
		for i in 8:
			var ang := a + i * PI / 4
			pts.append(c + Vector2(cos(ang), sin(ang)) * (rad if i % 2 == 0 else q))
		ci.draw_colored_polygon(pts, Color(col, 0.15 + 0.85 * k))
