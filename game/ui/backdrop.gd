class_name Backdrop
extends Control
## The looping element backdrop behind a hero: a slow breathing glow and drifting motes.
## Fire rises as embers, water as bubbles, earth hangs as dust, wind streaks sideways.
## A painted regional background can sit under this later; the motes stay code-driven.

const LOOKS := {
	"fire": {"glow": Color("#c44616"), "mote": Color("#ffc58a"), "vel": Vector2(10, -110), "size": 5.0, "count": 16},
	"water": {"glow": Color("#1d6c8c"), "mote": Color("#c9f4ff"), "vel": Vector2(0, -60), "size": 6.0, "count": 12},
	"earth": {"glow": Color("#7a5129"), "mote": Color("#ffe08a"), "vel": Vector2(12, -18), "size": 3.5, "count": 22},
	"wind": {"glow": Color("#3d7a28"), "mote": Color("#effff2"), "vel": Vector2(260, -10), "size": 3.0, "count": 14},
}

var elem := "fire"
## Where the glow centres, as a fraction of the size.
var focus := Vector2(0.5, 0.3)
var strength := 1.0
## Overrides the element's glow colour, such as a home region's colorway on the chronicle.
var tint := Color.TRANSPARENT
## Off for a motes-only layer laid over the art.
var glow := true
var _motes := []
var _t := 0.0
var _rng := RandomNumberGenerator.new()
var _glow: GradientTexture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.seed = 11
	var g := Gradient.new()
	g.set_color(0, Color.WHITE)
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.45, Color(1, 1, 1, 0.45))
	_glow = GradientTexture2D.new()
	_glow.gradient = g
	_glow.fill = GradientTexture2D.FILL_RADIAL
	_glow.fill_from = Vector2(0.5, 0.5)
	_glow.fill_to = Vector2(0.5, 0.0)
	_glow.width = 256
	_glow.height = 256
	for i in LOOKS[elem].count:
		_motes.append(_spawn(true))


func _spawn(anywhere: bool) -> Dictionary:
	var look: Dictionary = LOOKS[elem]
	var s := size if size != Vector2.ZERO else Vector2(720, 1560)
	var p := Vector2(_rng.randf() * s.x, _rng.randf() * s.y if anywhere else s.y + 20)
	if elem == "wind" and not anywhere:
		p = Vector2(-40, _rng.randf() * s.y)
	return {"p": p, "v": look.vel * _rng.randf_range(0.6, 1.3), "r": look.size * _rng.randf_range(0.6, 1.2),
		"ph": _rng.randf() * TAU}


func _process(delta: float) -> void:
	_t += delta
	for i in _motes.size():
		var m: Dictionary = _motes[i]
		m.p += m.v * delta + Vector2(sin(_t * 1.3 + m.ph) * 14 * delta, 0)
		if m.p.y < -30 or m.p.x > size.x + 50:
			_motes[i] = _spawn(false)
	queue_redraw()


func _draw() -> void:
	var look: Dictionary = LOOKS[elem]
	var c := size * focus
	var breathe := 0.75 + 0.25 * sin(_t * TAU / 7.0)
	var rad := Vector2(size.x * 0.95, size.y * 0.42) * (1.0 + 0.04 * breathe)
	if glow:
		draw_texture_rect(_glow, Rect2(c - rad, rad * 2), false, Color(look.glow if tint.a == 0 else tint, minf(1.0, 0.7 * breathe * strength)))
	for m in _motes:
		var fade := clampf(1.0 - absf(m.p.y - size.y * 0.45) / (size.y * 0.7), 0.0, 1.0)
		var col: Color = look.mote
		if elem == "wind":
			draw_line(m.p, m.p - Vector2(m.r * 9, 0), Color(col, 0.35 * fade * strength), m.r * 0.6)
		elif elem == "water":
			draw_arc(m.p, m.r, 0, TAU, 16, Color(col, 0.55 * fade * strength), 1.5)
		else:
			draw_circle(m.p, m.r * 2.4, Color(look.glow.lightened(0.3), 0.18 * fade * strength))
			draw_circle(m.p, m.r * 0.7, Color(col, 0.9 * fade * strength))

