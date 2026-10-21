class_name Burst
extends Control
## A short spark of four-point stars and a ring, for weight: a skill chosen, a tile aimed at, a hero landing.
## Draws over everything and frees itself.

const LIFE := 0.55

var _t := 0.0
var _color := Forge.GOLD
var _r := 40.0
var _sparks: Array = []


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


## Spawns centred on a control.
static func on(c: Control, color := Forge.GOLD, radius := 40.0, count := 8) -> Burst:
	return at(c, c.size / 2, color, radius, count)


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _t / LIFE
	var ease := 1.0 - pow(1.0 - k, 3)
	draw_arc(Vector2.ZERO, _r * (0.4 + ease * 0.9), 0, TAU, 40, Color(_color, 0.7 * (1 - k)), 3.0 * (1 - k) + 0.5, true)
	for s in _sparks:
		var p: Vector2 = s.dir * _r * s.dist * ease
		var rad: float = s.size * (1 - k * 0.7)
		var q := rad * 0.22
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -rad), p + Vector2(q, -q), p + Vector2(rad, 0), p + Vector2(q, q),
			p + Vector2(0, rad), p + Vector2(-q, q), p + Vector2(-rad, 0), p + Vector2(-q, -q)]), Color(_color.lightened(0.3), 1 - k))
