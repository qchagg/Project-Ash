class_name DownArrow
extends Button
## The bobbing arrow at the foot of a hero page: the next page is one scroll, or one tap, below.

var label := "stats"
var _t := 0.0


static func make(text: String) -> DownArrow:
	var b := DownArrow.new()
	b.label = text
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.custom_minimum_size = Vector2(320, 130)
	b.size = Vector2(320, 130)
	return b


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var bob := 8.0 * sin(_t * TAU / 1.6)
	draw_string(Forge.tracked(Forge.SC, 3), Vector2(0, 34), label.to_lower(), HORIZONTAL_ALIGNMENT_CENTER, size.x, 22, Forge.GOLD)
	var c := Vector2(size.x / 2, 74 + bob)
	draw_polyline(PackedVector2Array([c + Vector2(-20, -8), c + Vector2(0, 12), c + Vector2(20, -8)]), Forge.GOLD_LIGHT, 3.0, true)
	draw_polyline(PackedVector2Array([c + Vector2(-14, 10), c + Vector2(0, 24), c + Vector2(14, 10)]), Color(Forge.GOLD, 0.45), 2.0, true)
