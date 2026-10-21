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


## The battle cut-in: the board dims, a band in the hero's element sweeps across, and the hero pops in over it with
## the skill's name. The video's black is keyed out, so the hero stands on the band rather than in a black box.
## The keying is a stand-in: a video with its own transparency would also keep the darkest hair strands.
static func pop(parent: Control, src: String, skill: String, who: String, elem: String) -> CutIn:
	var c := CutIn.new()
	parent.add_child(c)
	c.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	c._pop(src, skill, who, elem)
	return c


const KEY_SHADER := """
shader_type canvas_item;
// Black to clear, softly; the frame's bottom edge melts away so the cut at the waist never shows.
uniform float lo = 0.025;
uniform float hi = 0.085;
uniform float melt = 0.22;
void fragment() {
	float m = max(COLOR.r, max(COLOR.g, COLOR.b));
	COLOR.a *= smoothstep(lo, hi, m) * smoothstep(1.0, 1.0 - melt, UV.y);
}
"""

## How long the band holds once open (seconds); the clip is longer, so it closes mid-motion, like a cut-in should.
const POP_HOLD := 2.4

var _band := 0.0
var _tint := Forge.GOLD
var _skill := ""
var _who := ""


func _pop(src: String, skill: String, who: String, elem: String) -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_tint = Forge.ELEM.get(elem, Forge.GOLD)
	_skill = skill
	_who = who
	_player = VideoStreamPlayer.new()
	_player.stream = load(src)
	_player.expand = true
	_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = KEY_SHADER
	mat.shader = sh
	_player.material = mat
	# The band keeps its own time: in the web build the video can report it has finished before it has.
	add_child(_player)
	# The hero stands left of centre on the band, cut at the band's foot; the name sits to the right.
	var side := minf(size.x * 0.95, 680.0)
	_player.size = Vector2(side, side)
	var foot := size.y * 0.5 + 250
	_player.position = Vector2(-side * 0.12 - 140, foot - side)
	_player.modulate.a = 0.0
	_player.play()
	var t := create_tween()
	t.tween_method(func(v): _band = v; queue_redraw(), 0.0, 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(_player, "position:x", -side * 0.12, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(_player, "modulate:a", 1.0, 0.2)
	t.tween_interval(POP_HOLD)
	t.tween_callback(_close)


func _draw() -> void:
	if _who == "":
		return
	var k := _band
	draw_rect(Rect2(Vector2.ZERO, size), Color(Forge.INK, 0.62 * k))
	# The band: a slanted strip in the element's colour, gold rules on its edges, speed streaks across it.
	var mid := size.y * 0.5
	var h := 420.0 * k
	var tilt := 70.0
	var top_l := Vector2(0, mid - h / 2 + tilt)
	var top_r := Vector2(size.x, mid - h / 2 - tilt)
	var bot_r := Vector2(size.x, mid + h / 2 - tilt)
	var bot_l := Vector2(0, mid + h / 2 + tilt)
	draw_polygon(PackedVector2Array([top_l, top_r, bot_r, bot_l]),
		PackedColorArray([_tint.darkened(0.75), _tint.darkened(0.25), _tint.darkened(0.35), _tint.darkened(0.8)]))
	for i in 9:
		var y := mid - h / 2 + 30 + i * h / 9
		var x := size.x * (0.35 + 0.07 * (i % 3))
		draw_line(Vector2(x, y + tilt * 0.4), Vector2(x + 260, y - tilt * 0.4), Color(_tint.lightened(0.6), 0.16 * k), 2.0)
	draw_line(top_l, top_r, Color(Forge.GOLD, k), 4.0)
	draw_line(bot_l, bot_r, Color(Forge.GOLD, k), 4.0)
	if k < 0.9:
		return
	var x0 := size.x * 0.6
	draw_string(Forge.tracked(Forge.SC, 4), Vector2(x0, mid - 34), _who.to_lower(), HORIZONTAL_ALIGNMENT_LEFT, size.x - x0 - 24, 24, Forge.PARCHMENT)
	var f := Forge.tracked(Forge.SC_HEAVY, 3)
	var words := _skill.to_lower().split(" ")
	var y := mid + 18
	for line in [" ".join(words.slice(0, (words.size() + 1) / 2)), " ".join(words.slice((words.size() + 1) / 2))]:
		if line == "":
			continue
		draw_string_outline(f, Vector2(x0, y), line, HORIZONTAL_ALIGNMENT_LEFT, size.x - x0 - 20, 40, 8, Forge.INK)
		draw_string(f, Vector2(x0, y), line, HORIZONTAL_ALIGNMENT_LEFT, size.x - x0 - 20, 40, Forge.GOLD_LIGHT)
		y += 44


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
