class_name Bust
extends Control
## A hero from the chest up, alive: their idle clips loop one into the next, and on cue they talk or cast and settle
## back into the idle. Every clip of a hero starts and ends on the same pose as their still, so the swaps never show.
## Clips are packed (colour over transparency, see tools/face-clip.py); the still is a keyed image of that pose and
## stands in whenever no frame is up yet, between clips or while a clip is still downloading (see Clips).

signal clip_finished(clip: String)

const SHADER := """
shader_type canvas_item;
// packed: the texture is colour over its transparency (as grey); put them back together.
uniform bool packed = false;
// How much of the height melts away at the foot, so the cut at the chest never shows.
uniform float melt = 0.0;
void fragment() {
	vec4 c = COLOR;
	if (packed) {
		float px = 1.0 / float(textureSize(TEXTURE, 0).y);
		vec2 top = vec2(UV.x, min(UV.y * 0.5, 0.5 - px));
		vec2 low = vec2(UV.x, max(UV.y * 0.5 + 0.5, 0.5 + px));
		// The video itself is opaque, so COLOR's alpha here is just the node's own fade.
		c = vec4(texture(TEXTURE, top).rgb, texture(TEXTURE, low).r * COLOR.a);
	}
	if (melt > 0.0) {
		c.a *= smoothstep(1.0, 1.0 - melt, UV.y);
	}
	COLOR = c;
}
"""

var hero := ""
## The fraction of the height that fades out at the foot.
var melt := 0.18
var _faces := {}
var _still: Texture2D
var _player: VideoStreamPlayer
var _clip := ""
var _idle := true
var _since := 0.0
var _wait := 0.0


func setup(hero_key: String) -> Bust:
	hero = hero_key
	_faces = Data.hero(hero).get("faces", {})
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	return self


static func has_faces(hero_key: String) -> bool:
	return not Data.hero(hero_key).get("faces", {}).is_empty()


func _ready() -> void:
	_still = load(_faces.still)
	material = _material(false)
	_player = VideoStreamPlayer.new()
	_player.expand = true
	_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player.material = _material(true)
	_player.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_player.visible = false
	_player.finished.connect(_ended)
	add_child(_player)
	idle()


func _material(packed: bool) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("packed", packed)
	m.set_shader_parameter("melt", melt)
	return m


## Loops the idles, picking the next one at random as each ends.
func idle() -> void:
	_idle = true
	var idles: Array = _faces.get("idle", [])
	if idles.is_empty() or not _start(idles.pick_random()):
		_wait = 1.0


## Talks once (a random talk clip), then idles. False if no talk clip is ready.
func say() -> bool:
	return play(_faces.get("talk", []).pick_random() if _faces.has("talk") else "")


## Plays one clip, then idles. False if it isn't ready (the bust carries on as it was).
func play(clip: String) -> bool:
	if clip == "" or not Clips.ready(clip):
		return false
	_idle = false
	return _start(clip)


func playing() -> String:
	return "" if _idle else _clip


func _start(clip: String) -> bool:
	var s := Clips.stream(clip)
	if s == null:
		return false
	_clip = clip
	_since = 0.0
	_player.stream = s
	_player.play()
	return true


func _ended() -> void:
	var was := _clip
	if not _idle:
		clip_finished.emit(was)
	idle()


func _process(delta: float) -> void:
	_since += delta
	if _wait > 0.0:
		_wait -= delta
		if _wait <= 0.0:
			idle()
	# Show the video only once it has a frame up; until then (and between clips) the still holds the pose.
	var up := _player.is_playing() and _player.stream_position > 0.03
	if up != _player.visible:
		_player.visible = up
		queue_redraw()
	# A guard in case the end of a clip is never reported.
	var length := _player.get_stream_length()
	if _player.is_playing() and length > 0.0 and _since > length + 0.5:
		_player.stop()
		_ended()


func _draw() -> void:
	if not _player.visible:
		draw_texture_rect(_still, Rect2(Vector2.ZERO, size), false)
