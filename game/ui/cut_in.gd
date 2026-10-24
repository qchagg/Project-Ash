class_name CutIn
extends Control
## A hero's moment on the whole screen, played by their live Bust (see bust.gd).
## `pop` is the battle cut-in: the board dims, a band in the hero's element sweeps across, and the hero rises onto it
## with the skill's name, playing that skill's clip. `play` gives the screen to one clip (a chant when a hero evolves)
## over their element's glow. Tap either to skip.

signal finished

const FADE := 0.25
## Where the bust centres on a tall screen, as a fraction of the height.
const CENTRE := 0.42

var _bust: Bust
var _done := false


static func play(parent: Control, hero_key: String, clip: String) -> CutIn:
	var c := CutIn.new()
	# Join the parent first, then fill it: anchoring before entering the tree doubles the size.
	parent.add_child(c)
	c.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	c._start(hero_key, clip)
	return c


static func pop(parent: Control, hero_key: String, clip: String, skill: String, who: String, elem: String) -> CutIn:
	var c := CutIn.new()
	parent.add_child(c)
	c.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	c._pop(hero_key, clip, skill, who, elem)
	return c


## How long the band holds once open (seconds); the clip is longer, so it closes mid-motion, like a cut-in should.
const POP_HOLD := 3.0

var _band := 0.0
var _tint := Forge.GOLD
var _skill := ""
var _who := ""


func _pop(hero_key: String, clip: String, skill: String, who: String, elem: String) -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_tint = Forge.ELEM.get(elem, Forge.GOLD)
	_skill = skill
	_who = who
	_bust = Bust.new().setup(hero_key)
	_bust.melt = 0.24
	add_child(_bust)
	_bust.play(clip)
	# The hero stands left of centre on the band, cut at the band's foot; the name sits to the right.
	var side := minf(size.x * 0.95, 680.0)
	_bust.size = Vector2(side, side)
	var foot := size.y * 0.5 + 250
	_bust.position = Vector2(-side * 0.12 - 140, foot - side)
	_bust.modulate.a = 0.0
	var t := create_tween()
	t.tween_method(func(v): _band = v; queue_redraw(), 0.0, 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(_bust, "position:x", -side * 0.12, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(_bust, "modulate:a", 1.0, 0.2)
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


func _start(hero_key: String, clip: String) -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var h := Data.hero(hero_key)
	var bg := ColorRect.new()
	bg.color = Color(Forge.INK, 0.94)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var glow := Backdrop.new()
	glow.elem = h.elem
	glow.focus = Vector2(0.5, CENTRE)
	glow.set_anchors_preset(PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)
	_bust = Bust.new().setup(hero_key)
	_bust.melt = 0.22
	add_child(_bust)
	var side := minf(size.x, size.y * 0.8)
	_bust.size = Vector2(side, side)
	_bust.position = Vector2((size.x - side) / 2, size.y * CENTRE - side / 2)
	if not _bust.play(clip):
		_close.call_deferred()
		return
	_bust.clip_finished.connect(func(_c): _close())
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, FADE)


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
