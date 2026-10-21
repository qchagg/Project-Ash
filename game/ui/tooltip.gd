class_name Tooltip
extends Control
## Tap-for-details, the one way the game shows more: a translucent panel floating over the screen with a notch
## pointing at what was tapped. It never moves the page under it. It opens below its anchor, or above when there
## is no room below, and the next tap anywhere closes it.

const W := 632.0
const SIDE := 44.0
const GAP := 14.0

signal closed

var _anchor: Rect2
var _point_x := -1.0
var _panel: PanelContainer
var _notch: Control
var _up := false


## Opens over the whole screen. `fill` gets the panel's VBoxContainer to add lines to; `point_x` (screen x) aims the
## notch somewhere other than the anchor's middle, such as one chip in a row.
static func open(anchor: Control, fill: Callable, point_x := -1.0) -> Tooltip:
	var t := Tooltip.new()
	t._anchor = anchor.get_global_rect()
	t._point_x = point_x
	anchor.get_tree().current_scene.add_child(t)
	t.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var lines := Forge.vbox(10)
	t._panel.add_child(lines)
	fill.call(lines)
	return t


func _init() -> void:
	# Any press closes it, before a drag can scroll the page out from under the notch.
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			close())
	_panel = PanelContainer.new()
	var st := Forge.flat(Color(Forge.INK, 0.92), Color(Forge.GOLD, 0.85), 2, Vector4(26, 18, 26, 20))
	st.shadow_color = Color(0, 0, 0, 0.45)
	st.shadow_size = 18
	st.shadow_offset = Vector2(0, 8)
	_panel.add_theme_stylebox_override("panel", st)
	_panel.custom_minimum_size.x = W
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.modulate.a = 0.0
	add_child(_panel)
	_notch = Control.new()
	_notch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notch.draw.connect(func():
		var d := 1.0 if _up else -1.0
		_notch.draw_colored_polygon(PackedVector2Array([Vector2(-12, -d), Vector2(0, 11 * d), Vector2(12, -d)]), Color(Forge.GOLD, 0.85)))
	add_child(_notch)


func _ready() -> void:
	# Wait a frame for the panel to take its size, then place it where it fits.
	await get_tree().process_frame
	var h := _panel.size.y
	var screen := get_viewport_rect().size.y
	var y := _anchor.end.y + GAP
	_up = y + h > screen - 24 and _anchor.position.y - GAP - h > 24
	if _up:
		y = _anchor.position.y - GAP - h
	_panel.position = Vector2(SIDE, clampf(y, 24, screen - 24 - h))
	var x := _point_x if _point_x >= 0 else _anchor.get_center().x
	_notch.position = Vector2(clampf(x, SIDE + 30, SIDE + W - 30), _panel.position.y + (h if _up else 0.0))
	_notch.queue_redraw()
	_panel.modulate.a = 1.0


func close() -> void:
	if is_queued_for_deletion():
		return
	queue_free()
	closed.emit()
