class_name CutIn
extends Control
## A hero's cut-in: their video loop fills the screen, fades in, plays once and fades out.
## Tapping the character art plays it; combat will play the same node when a hero uses a skill.
## Tap during it to skip.

signal finished

const FADE := 0.25

var _player: VideoStreamPlayer
var _done := false


static func play(parent: Control, src: String) -> CutIn:
	var c := CutIn.new()
	c.set_anchors_preset(PRESET_FULL_RECT)
	c.size = parent.size
	parent.add_child(c)
	c._start(src)
	return c


func _start(src: String) -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Forge.INK
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_player = VideoStreamPlayer.new()
	_player.stream = load(src)
	_player.expand = true
	_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player.finished.connect(_close)
	add_child(_player)
	modulate.a = 0.0
	_player.play()
	_cover()
	create_tween().tween_property(self, "modulate:a", 1.0, FADE)


## Scales the video to cover the screen, cropping the overflow, whatever its shape.
func _cover() -> void:
	var tex := _player.get_video_texture()
	var vs := tex.get_size() if tex else Vector2.ZERO
	if vs.x <= 0:
		_cover.call_deferred()
		return
	var k := maxf(size.x / vs.x, size.y / vs.y)
	_player.size = vs * k
	_player.position = (size - _player.size) / 2


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
