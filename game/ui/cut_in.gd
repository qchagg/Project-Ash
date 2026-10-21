class_name CutIn
extends Control
## A hero's cut-in: their video loop fills the screen, fades in, plays once and fades out.
## Tapping the character art plays it; combat will play the same node when a hero uses a skill.
## Tap during it to skip.

signal finished

const FADE := 0.25
## The black the hero videos are rendered on, so the frame melts into the page.
const VOID := Color("#030303")
## Where the frame centres on a tall screen, as a fraction of the height.
const CENTRE := 0.46

var _player: VideoStreamPlayer
var _edges: Control
var _done := false


static func play(parent: Control, src: String) -> CutIn:
	var c := CutIn.new()
	# Join the parent first, then fill it: anchoring before entering the tree doubles the size.
	parent.add_child(c)
	c.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	c._start(src)
	return c


func _start(src: String) -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = VOID
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_player = VideoStreamPlayer.new()
	_player.stream = load(src)
	_player.expand = true
	_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player.finished.connect(_close)
	add_child(_player)
	var edges := Control.new()
	edges.set_anchors_preset(PRESET_FULL_RECT)
	edges.mouse_filter = Control.MOUSE_FILTER_IGNORE
	edges.draw.connect(_draw_edges.bind(edges))
	add_child(edges)
	_edges = edges
	modulate.a = 0.0
	_player.play()
	_cover()
	create_tween().tween_property(self, "modulate:a", 1.0, FADE)


## Shows the whole frame: full width, centred a little above the middle; a frame taller than the screen
## is cropped top and bottom instead. Nothing is cut from the sides, where the action usually is.
func _cover() -> void:
	var tex := _player.get_video_texture()
	var vs := tex.get_size() if tex else Vector2.ZERO
	if vs.x <= 0:
		_cover.call_deferred()
		return
	var k := size.x / vs.x
	_player.size = vs * k
	_player.position = Vector2(0, clampf(size.y * CENTRE - _player.size.y / 2, size.y - _player.size.y, 0.0) if _player.size.y > size.y else size.y * CENTRE - _player.size.y / 2)
	_edges.queue_redraw()


## Soft fades over the frame's top and bottom edges so it has no hard line against the black.
func _draw_edges(ci: Control) -> void:
	if not _player or _player.size.y >= size.y:
		return
	var r := Rect2(_player.position, _player.size)
	var f := r.size.y * 0.16
	for band in [[r.position.y, r.position.y + f, true], [r.end.y - f, r.end.y, false]]:
		var a := Color(VOID, 1.0 if band[2] else 0.0)
		var b := Color(VOID, 0.0 if band[2] else 1.0)
		ci.draw_polygon(PackedVector2Array([Vector2(0, band[0]), Vector2(size.x, band[0]), Vector2(size.x, band[1]), Vector2(0, band[1])]),
			PackedColorArray([a, a, b, b]))


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_close()


func _close() -> void:
	if _done:
		return
	_done = true
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, FADE)
	t.tween_callback(func():
		finished.emit()
		queue_free())
