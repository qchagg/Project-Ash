class_name Burst
extends Control
## A short spark of four-point stars and a ring, for weight: a skill chosen, a tile aimed at, a hero landing.
## Draws over everything and frees itself.

const LIFE := 0.55

var _t := 0.0
var _color := Forge.GOLD
var _r := 40.0
var _sparks: Array = []
## A slash instead of a spark: a bright tapered streak cut across the point, `_dir` the way it travels.
var _slash := false
var _dir := 1.0
var _life := LIFE


## Spawns at a point in `parent`'s coordinates.
static func at(parent: Control, point: Vector2, color := Forge.GOLD, radius := 40.0, count := 8) -> Burst:
	var b := Burst.new()
	b._color = color
	b._r = radius
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.position = point
	b.z_index = 50
	for i in count:
		var a := TAU * i / count + randf_range(-0.3, 0.3)
		b._sparks.append({"dir": Vector2(cos(a), sin(a)), "dist": randf_range(0.8, 1.4), "size": randf_range(4.0, 8.0)})
	parent.add_child(b)
	return b


## A blade's streak across the middle of a control: a tapered crescent that cuts through in a blink and fades.
## `dir` is the way the blow travels (1 to the right); a heavy one is longer and wider.
static func slash(c: Control, color := Forge.GOLD_LIGHT, dir := 1.0, heavy := false) -> Burst:
	var b := at(c, c.size / 2, color, minf(c.size.x, c.size.y) * (0.75 if heavy else 0.55), 0)
	b._slash = true
	b._dir = dir
	b._life = 0.26
	b.rotation = randf_range(-0.5, -0.2) * dir
	return b


## Spawns centred on a control.
static func on(c: Control, color := Forge.GOLD, radius := 40.0, count := 8) -> Burst:
	return at(c, c.size / 2, color, radius, count)


func _process(delta: float) -> void:
	_t += delta
	if _t >= _life:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	if _slash:
		_draw_slash()
		return
	var k := _t / LIFE
	var ease := 1.0 - pow(1.0 - k, 3)
	draw_arc(Vector2.ZERO, _r * (0.4 + ease * 0.9), 0, TAU, 40, Color(_color, 0.7 * (1 - k)), 3.0 * (1 - k) + 0.5, true)
	for s in _sparks:
		var p: Vector2 = s.dir * _r * s.dist * ease
		var rad: float = s.size * (1 - k * 0.7)
		var q := rad * 0.22
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -rad), p + Vector2(q, -q), p + Vector2(rad, 0), p + Vector2(q, q),
			p + Vector2(0, rad), p + Vector2(-q, q), p + Vector2(-rad, 0), p + Vector2(-q, -q)]), Color(_color.lightened(0.3), 1 - k))


func _draw_slash() -> void:
	var k := _t / _life
	# The cut runs through in the first third, then the streak thins and fades from its tail.
	var head := minf(1.0, k * 3.0)
	var tail := maxf(0.0, (k - 0.25) / 0.75)
	var top := PackedVector2Array()
	var bottom := PackedVector2Array()
	for i in 17:
		var f := lerpf(tail, head, i / 16.0)
		var x := (f * 2.0 - 1.0) * _r * _dir
		var y := -sin(f * PI) * _r * 0.28
		var w := sin(f * PI) * _r * 0.12 * (1.0 - k * 0.6)
		top.append(Vector2(x, y - w))
		bottom.insert(0, Vector2(x, y + w * 0.4))
	if head - tail > 0.02:
		draw_colored_polygon(top + bottom, Color(_color, 1.0 - k))
