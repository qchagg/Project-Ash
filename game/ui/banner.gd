class_name Banner
extends Control
## A turn call sweeping across the battle: an ink band between gold rules opens, the words slide in from the
## right, hold, then leave to the left. "battle start", "your turn", "enemy turn". Tap to hurry it.

signal finished

const HOLD := 0.6
const BAND_H := 132.0

var _text := ""
var _sub := ""
var _tint := Forge.GOLD
var _open := 0.0
var _slide := 1.0
var _done := false


## Plays over `parent` and returns the banner; await its `finished`.
static func play(parent: Control, text: String, sub := "", tint := Forge.GOLD) -> Banner:
	var b := Banner.new()
	b._text = text
	b._sub = sub
	b._tint = tint
	parent.add_child(b)
	b.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	b._run()
	return b


func _run() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var t := create_tween()
	t.tween_method(func(v): _open = v; queue_redraw(), 0.0, 1.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_method(func(v): _slide = v; queue_redraw(), 1.0, 0.0, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(HOLD)
	t.tween_method(func(v): _slide = v; queue_redraw(), 0.0, -1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_method(func(v): _open = v; queue_redraw(), 1.0, 0.0, 0.12)
	t.tween_callback(_close)


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		accept_event()
		_close()


func _close() -> void:
	if _done:
		return
	_done = true
	finished.emit()
	queue_free()


func _draw() -> void:
	var mid := size.y * 0.46
	var h := BAND_H * _open
	draw_rect(Rect2(0, 0, size.x, size.y), Color(Forge.INK, 0.35 * _open))
	draw_rect(Rect2(0, mid - h / 2, size.x, h), Color(Forge.INK, 0.94))
	for y in [mid - h / 2, mid + h / 2]:
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(_tint, 0.9), 2.0)
	if _open < 0.6:
		return
	var dx := _slide * size.x * 0.8
	# Speed streaks trailing the words.
	for i in 5:
		var y := mid - 40 + i * 20
		var x := size.x * 0.5 + dx + 160 + i * 23
		draw_line(Vector2(x, y), Vector2(x + 120 - i * 14, y), Color(_tint, 0.25), 2.0)
	var f := Forge.tracked(Forge.SC_HEAVY, 8)
	var at := Vector2(dx, mid + (14 if _sub == "" else 4))
	draw_string_outline(f, at, _text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 58, 10, Forge.INK)
	draw_string(f, at, _text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 58, _tint)
	if _sub != "":
		draw_string(Forge.tracked(Forge.SC, 4), Vector2(-dx * 0.6, mid + 42), _sub, HORIZONTAL_ALIGNMENT_CENTER, size.x, 22, Forge.MUTED)
	for x in [size.x / 2 - 210 + dx, size.x / 2 + 210 + dx]:
		Forge.diamond(self, Vector2(x, mid - 6), 7, _tint)
