class_name Weather
extends Control
## A painted background's air, looping for ever between it and the hero: snow, dust, petals, mist. Everything here is
## drawn, so a new kind costs the game pack nothing. Each mote lives in fractions of the screen and wraps at the edges,
## so the loop has no join, and three depths give it distance: far motes are small, slow and dim, near ones large and quick.

## `kind` is how a mote is drawn. `color` tints it, `vel` is pixels a second at the nearest depth (and how the rest
## drift), `size` is its radius there, `count` how many, `sway` how far it wanders sideways. `mist` adds slow banks of haze,
## and `extra` one more air of its own kind over the first, or a list of them.
const AIR := {
	"ice": {"kind": "snow", "color": Color("#e8f4ff"), "vel": Vector2(-30, 96), "size": 7.0, "count": 150, "sway": 30.0},
	"city": {"kind": "dust", "color": Color("#ffd591"), "vel": Vector2(18, -10), "size": 4.4, "count": 90, "sway": 18.0},
	"saltglass-1": {"kind": "dust", "color": Color("#ffe2ad"), "vel": Vector2(150, -6), "size": 3.0, "count": 110, "sway": 8.0,
		"extra": [{"kind": "streak", "color": Color("#fff2d6"), "vel": Vector2(360, -10), "size": 4.0, "count": 26, "sway": 4.0},
			{"kind": "glint", "color": Color("#fff8e6"), "vel": Vector2(4, 0), "size": 7.0, "count": 22, "sway": 0.0}]},
	"saltglass-2": {"kind": "dust", "color": Color("#ffe2ad"), "vel": Vector2(150, -6), "size": 3.0, "count": 110, "sway": 8.0,
		"extra": [{"kind": "streak", "color": Color("#fff2d6"), "vel": Vector2(360, -10), "size": 4.0, "count": 26, "sway": 4.0},
			{"kind": "glint", "color": Color("#fff8e6"), "vel": Vector2(4, 0), "size": 7.0, "count": 22, "sway": 0.0}]},
	"lotus-1": {"kind": "petal", "color": Color("#f590b0"), "vel": Vector2(-26, 30), "size": 24.0, "count": 48, "sway": 34.0},
	"lotus-2": {"kind": "petal", "color": Color("#f590b0"), "vel": Vector2(-26, 30), "size": 24.0, "count": 48, "sway": 34.0},
	"imperial": {"kind": "dust", "color": Color("#f4ecd8"), "vel": Vector2(12, -6), "size": 3.6, "count": 70, "sway": 16.0},
	"plains-1": {"kind": "dust", "color": Color("#eaf2a2"), "vel": Vector2(34, -12), "size": 4.2, "count": 90, "sway": 26.0},
	"plains-2": {"kind": "dust", "color": Color("#eaf2a2"), "vel": Vector2(34, -12), "size": 4.2, "count": 90, "sway": 26.0},
	"basalt-steps": {"kind": "dust", "color": Color("#ff9a4a"), "vel": Vector2(14, -74), "size": 4.4, "count": 90, "sway": 22.0},
	"lantern-village": {"kind": "petal", "color": Color("#ff9cc0"), "vel": Vector2(-34, 26), "size": 24.0, "count": 90, "sway": 34.0},
	"silk-highlands": {"kind": "dust", "color": Color("#ff7a45"), "vel": Vector2(10, -46), "size": 4.2, "count": 90, "sway": 24.0},
	"silk-street": {"kind": "dust", "color": Color("#ff7a45"), "vel": Vector2(10, -46), "size": 3.6, "count": 70, "sway": 24.0},
	"steppe": {"kind": "dust", "color": Color("#f4e2a8"), "vel": Vector2(46, -8), "size": 3.8, "count": 90, "sway": 18.0},
	"standing-stones": {"kind": "dust", "color": Color("#eaf2a2"), "vel": Vector2(60, -10), "size": 3.8, "count": 60, "sway": 22.0,
		"extra": {"kind": "streak", "color": Color("#ffffff"), "vel": Vector2(320, -18), "size": 4.0, "count": 22, "sway": 6.0}},
	"empty-pavilions-1": {"kind": "dust", "color": Color("#ff8fb0"), "vel": Vector2(6, -22), "size": 4.4, "count": 50, "sway": 22.0,
		"extra": {"kind": "lantern", "color": Color("#ff8a52"), "vel": Vector2(5, -16), "size": 20.0, "count": 9, "sway": 20.0}},
	"empty-pavilions-2": {"kind": "dust", "color": Color("#ff8fb0"), "vel": Vector2(6, -22), "size": 4.4, "count": 50, "sway": 22.0,
		"extra": {"kind": "lantern", "color": Color("#ff8a52"), "vel": Vector2(5, -16), "size": 20.0, "count": 9, "sway": 20.0}},
	"walking-wood": {"kind": "leaf", "color": Color("#9ccf7e"), "vel": Vector2(-30, 28), "size": 17.0, "count": 60, "sway": 36.0,
		"mist": Color("#cfe8c8")},
	"serpent-archive": {"kind": "leaf", "color": Color("#b7d9b0"), "vel": Vector2(-24, 30), "size": 15.0, "count": 40, "sway": 32.0,
		"mist": Color("#d8f0ea")},
	"coast": {"kind": "dust", "color": Color("#fff0c8"), "vel": Vector2(26, -8), "size": 3.8, "count": 70, "sway": 18.0},
	"whale-cathedral": {"kind": "snow", "color": Color("#e8f4ff"), "vel": Vector2(-20, 70), "size": 6.0, "count": 110, "sway": 26.0},
	"basalt-city": {"kind": "dust", "color": Color("#8ff0d0"), "vel": Vector2(6, -34), "size": 4.2, "count": 70, "sway": 20.0, "mist": Color("#bfeee0")},
	"avenue": {"kind": "dust", "color": Color("#ffd9b0"), "vel": Vector2(14, -8), "size": 3.8, "count": 70, "sway": 16.0},
	"undercroft": {"kind": "dust", "color": Color("#ff7a45"), "vel": Vector2(6, -58), "size": 4.0, "count": 80, "sway": 20.0,
		"extra": {"kind": "ember", "color": Color("#ffa040"), "vel": Vector2(10, -120), "size": 9.0, "count": 54, "sway": 26.0}},
	"jade": {"kind": "leaf", "color": Color("#b7d9b0"), "vel": Vector2(-40, 34), "size": 18.0, "count": 60, "sway": 36.0,
		"mist": Color("#d8f0ea")},
}
## The shapes of what tumbles, as outlines around their middle, one unit long.
const PETAL := [Vector2(0, -1), Vector2(0.42, -0.62), Vector2(0.56, 0.05), Vector2(0.3, 0.7), Vector2(0, 1), Vector2(-0.3, 0.7), Vector2(-0.56, 0.05), Vector2(-0.42, -0.62)]
const LEAF := [Vector2(0, -1.2), Vector2(0.3, -0.7), Vector2(0.42, -0.1), Vector2(0.26, 0.55), Vector2(0, 1.2), Vector2(-0.26, 0.55), Vector2(-0.42, -0.1), Vector2(-0.3, -0.7)]
## A paper lantern's outline, tall and rounded.
const LANTERN := [Vector2(-0.42, -0.85), Vector2(0.42, -0.85), Vector2(0.62, -0.4), Vector2(0.66, 0.2), Vector2(0.46, 0.85), Vector2(-0.46, 0.85), Vector2(-0.66, 0.2), Vector2(-0.62, -0.4)]
## The wind's strongest gust against its calm, and how slowly gusts come and go.
const GUST := 2.4
## What is light enough to ride the gusts.
const RIDES := ["petal", "leaf", "streak"]
const GUST_RATE := 0.21
## How far away each depth feels: its share of the motes, then its speed, size and strength against the nearest.
## How strongly a light shines at the top of its flicker.
const LAMP := 0.3
## How strongly all of it shows, so it sits in a dimmed painting and never outshines it.
const STRENGTH := 0.6
## Petals and leaves are things, not haze, so they show more strongly.
const TUMBLE_STRENGTH := 0.85
const DEPTHS := [[0.5, 0.38, 0.5, 0.4], [0.32, 0.65, 0.75, 0.65], [0.18, 1.0, 1.0, 0.95]]
const MIST_BANKS := 5

var art := ""
## No haze, even on a background whose air has it: the title screen keeps only its drifting lights.
var clear := false
var _motes := []
var _banks := []
var _t := 0.0
var _rng := RandomNumberGenerator.new()
var _soft: GradientTexture2D
## The painting's lights, drawn on their own additive layer so they brighten what is under them.
var _lamps: Control


## The air of a painted background, covering its parent, or null when it has none.
static func over(of_art: String) -> Weather:
	if not AIR.has(of_art):
		return null
	var w := Weather.new()
	w.art = of_art
	w.set_anchors_preset(PRESET_FULL_RECT)
	w.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return w


func _ready() -> void:
	modulate.a = TUMBLE_STRENGTH if AIR[art].kind in ["petal", "leaf"] else STRENGTH
	var g := Gradient.new()
	g.set_color(0, Color.WHITE)
	g.set_color(1, Color(1, 1, 1, 0))
	_soft = GradientTexture2D.new()
	_soft.gradient = g
	_soft.fill = GradientTexture2D.FILL_RADIAL
	_soft.fill_from = Vector2(0.5, 0.5)
	_soft.fill_to = Vector2(0.5, 0.0)
	_soft.width = 64
	_soft.height = 64
	if not lamps().is_empty():
		_lamps = Control.new()
		_lamps.set_anchors_preset(PRESET_FULL_RECT)
		_lamps.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var add := CanvasItemMaterial.new()
		add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_lamps.material = add
		_lamps.show_behind_parent = true
		_lamps.draw.connect(_draw_lamps)
		add_child(_lamps)
	fill()


## Scatters the motes across the screen, so the air is already there on the first frame.
func fill() -> void:
	var air: Dictionary = AIR[art]
	_rng.seed = hash(art)
	_motes.clear()
	_banks.clear()
	for each in airs():
		for d in DEPTHS:
			for i in roundi(each.count * d[0]):
				_motes.append({"air": each, "p": Vector2(_rng.randf(), _rng.randf()), "k": _rng.randf_range(0.8, 1.2), "ph": _rng.randf() * TAU,
					"speed": d[1], "size": d[2], "alpha": d[3]})
	if air.has("mist") and not clear:
		for i in MIST_BANKS:
			_banks.append({"p": Vector2(_rng.randf(), _rng.randf_range(0.2, 0.85)), "k": _rng.randf_range(0.7, 1.3), "ph": _rng.randf() * TAU})


func _process(delta: float) -> void:
	step(delta)
	queue_redraw()
	if _lamps:
		_lamps.queue_redraw()


## A slow flicker for each light in the painting, placed the way Painted covers the screen.
func _draw_lamps() -> void:
	var w := maxf(size.x, size.y * 2.0)
	var at := (size - Vector2(w, w / 2.0)) / 2.0
	for i in lamps().size():
		var l: Array = lamps()[i]
		var flicker := 0.7 + 0.2 * sin(_t * 1.7 + i * 2.1) + 0.1 * sin(_t * 4.3 + i * 0.7)
		var r := maxf(l[2] * w, 18.0) * (2.2 + 0.25 * flicker)
		var c := at + Vector2(l[0], l[1]) * w
		_lamps.draw_texture_rect(_soft, Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(Color(l[3]), LAMP * flicker))


func lamps() -> Array:
	return Faces.GLOWS.get(art, [])


## Moves the air on, wrapping what leaves one edge round to the other.
func step(delta: float) -> void:
	_t += delta
	var s := size if size.x > 0.0 and size.y > 0.0 else Vector2(720, 1560)
	for m in _motes:
		var move: Vector2 = m.air.vel * m.speed * m.k * delta / s
		if m.air.kind in RIDES:
			move.x *= gust()
		m.p = Vector2(fposmod(m.p.x + move.x, 1.0), fposmod(m.p.y + move.y, 1.0))
	for b in _banks:
		b.p.x = fposmod(b.p.x + 0.006 * b.k * delta, 1.0)


## The wind now: mostly calm, rising in long breaths, for what is light enough to ride it.
func gust() -> float:
	var breath := sin(_t * GUST_RATE * TAU) + 0.5 * sin(_t * GUST_RATE * 2.3 * TAU + 1.0)
	return 1.0 + (GUST - 1.0) * smoothstep(0.5, 1.3, breath)


func motes() -> Array:
	return _motes


## The painting's air, then its extra air if it has one.
func airs() -> Array:
	var air: Dictionary = AIR[art]
	var extra = air.get("extra", [])
	return [air] + (extra if extra is Array else [extra])


func _draw() -> void:
	var air: Dictionary = AIR[art]
	for b in _banks:
		# Each bank is drawn twice across the wrap, so it slides off one side as it comes in the other.
		var r: Vector2 = Vector2(size.x * 0.62, size.y * 0.16) * b.k
		var col := Color(air.get("mist", air.color.lightened(0.5)), 0.24 + 0.06 * sin(_t * 0.25 + b.ph))
		for shift in [0.0, -1.0]:
			var c := Vector2((b.p.x + shift) * size.x, b.p.y * size.y)
			draw_texture_rect(_soft, Rect2(c - r, r * 2), false, col)
	for m in _motes:
		air = m.air
		var r: float = air.size * m.size * m.k
		var at := Vector2(m.p.x * size.x + sin(_t * 0.7 + m.ph) * air.sway * m.size, m.p.y * size.y)
		var twinkle := 0.75 + 0.25 * sin(_t * 1.1 + m.ph)
		match air.kind:
			"snow":
				_soft_dot(at, r * 1.6, Color(air.color, 0.95 * m.alpha))
			"dust":
				_soft_dot(at, r * 2.4, Color(air.color, 0.34 * m.alpha * twinkle))
				_soft_dot(at, r * 0.8, Color(air.color, 0.9 * m.alpha * twinkle))
			"leaf", "petal":
				# It spins as it falls and flips over, its face catching the light and its back in shade.
				var flip := sin(_t * 1.6 * m.k + m.ph)
				var face: Color = air.color.lightened(0.06) if flip > 0.0 else air.color.darkened(0.22)
				draw_set_transform(at, m.ph + _t * 0.8 * m.k, Vector2(r, r) * Vector2(1.0, 0.25 + 0.75 * absf(flip)))
				draw_colored_polygon(PackedVector2Array(LEAF if air.kind == "leaf" else PETAL), Color(face, 0.82 * m.alpha))
				if air.kind == "leaf":
					draw_line(Vector2(0, -1.1), Vector2(0, 1.1), Color(face.darkened(0.3), 0.7 * m.alpha), 0.09)
				draw_set_transform(Vector2.ZERO)
			"streak":
				# A thread of wind: thin, long along the way it blows, brightest in the middle.
				var along: Vector2 = air.vel.normalized() * r * 14.0 * gust()
				var thread := Color(air.color, 0.0)
				draw_polyline_colors(PackedVector2Array([at - along, at, at + along]),
					PackedColorArray([thread, Color(air.color, 0.9 * m.alpha), thread]), maxf(1.5, r * 0.5), true)
			"glint":
				# Light catching the glass: mostly dark, then a sharp four-pointed flash.
				var flash := pow(maxf(0.0, sin(_t * 0.9 * m.k + m.ph * 3.0)), 14.0)
				if flash > 0.02:
					var g := Color(air.color, flash * m.alpha)
					_soft_dot(at, r * 1.6, Color(air.color, 0.45 * flash * m.alpha))
					draw_line(at - Vector2(r * 1.8, 0), at + Vector2(r * 1.8, 0), g, maxf(1.0, r * 0.18), true)
					draw_line(at - Vector2(0, r * 1.8), at + Vector2(0, r * 1.8), g, maxf(1.0, r * 0.18), true)
			"ember":
				# A spark off the vents: a hot core in a flickering glow, trailing as it rises.
				var heat := 0.65 + 0.35 * sin(_t * 9.0 * m.k + m.ph * 5.0)
				var trail: Vector2 = -air.vel.normalized() * r * 3.0
				draw_line(at, at + trail, Color(air.color, 0.6 * heat * m.alpha), maxf(1.0, r * 0.6), true)
				_soft_dot(at, r * 3.2, Color(air.color, 0.7 * heat * m.alpha))
				_soft_dot(at, r * 0.8, Color(1.0, 0.92, 0.7, heat * m.alpha))
			"lantern":
				# A paper lantern left behind, rising slowly with its flame flickering.
				var burn := 0.8 + 0.12 * sin(_t * 3.1 + m.ph) + 0.08 * sin(_t * 7.3 + m.ph * 2.0)
				_soft_dot(at, r * 3.4, Color(air.color, 0.4 * burn * m.alpha))
				draw_set_transform(at, sin(_t * 0.6 + m.ph) * 0.12, Vector2(r, r))
				draw_colored_polygon(PackedVector2Array(LANTERN), Color(air.color.lightened(0.15), 0.95 * burn * m.alpha))
				draw_line(Vector2(-0.42, -0.8), Vector2(0.42, -0.8), Color(Forge.INK, 0.6 * m.alpha), 0.14)
				draw_line(Vector2(-0.42, 0.8), Vector2(0.42, 0.8), Color(Forge.INK, 0.6 * m.alpha), 0.14)
				draw_set_transform(Vector2.ZERO)
				_soft_dot(at + Vector2(0, r * 0.25), r * 0.75, Color(1, 0.96, 0.82, 0.95 * burn * m.alpha))


func _soft_dot(at: Vector2, r: float, col: Color) -> void:
	draw_texture_rect(_soft, Rect2(at - Vector2(r, r), Vector2(r, r) * 2), false, col)
