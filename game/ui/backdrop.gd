class_name Backdrop
extends Control
## The looping element backdrop behind a hero: a slow breathing glow and drifting motes.
## Fire rises as embers, water as bubbles, earth hangs as dust, wind streaks sideways.
## A home's painted background (`painted`) sits over the glow; the motes stay code-driven.

const LOOKS := {
	"fire": {"glow": Color("#c44616"), "mote": Color("#ffc58a"), "vel": Vector2(10, -110), "size": 5.0, "count": 16},
	"water": {"glow": Color("#1d6c8c"), "mote": Color("#c9f4ff"), "vel": Vector2(0, -60), "size": 6.0, "count": 12},
	"earth": {"glow": Color("#7a5129"), "mote": Color("#ffe08a"), "vel": Vector2(12, -18), "size": 3.5, "count": 22},
	"wind": {"glow": Color("#3d7a28"), "mote": Color("#effff2"), "vel": Vector2(260, -10), "size": 3.0, "count": 14},
}

## The painted backgrounds of each home: a hero's page picks one of them each time it opens.
const ART := {
	"marusthal": ["city", "saltglass-1", "saltglass-2"],
	"jaladesh": ["lotus-1", "lotus-2"],
	"khorvan": ["steppe"],
	"aurelia": ["imperial", "avenue"],
	"gwyntmoor": ["plains-1", "plains-2", "standing-stones"],
	"vetroles": ["plains-2", "plains-1", "walking-wood"],
	"hraunvald": ["basalt-city", "basalt-steps"],
	"mehfil": ["lantern-village", "empty-pavilions-1", "empty-pavilions-2"],
	"velata": ["silk-highlands", "silk-street", "undercroft"],
	"yuling": ["jade", "serpent-archive"],
	"sikuvik": ["ice", "whale-cathedral"],
	"mwambao": ["coast"],
}

## The ground a road's fights stand on: a seamless texture in art/grounds/, and how far it is dimmed so the fighters
## read on it. A road without one fights over the plain ink.
const GROUNDS := {
	"basalt": {"art": "basalt", "shade": 1.0},
	"lotus": {"art": "aqueduct", "shade": 0.5},
	"saltglass": {"art": "saltglass", "shade": 0.27},
}
## What stands nearest the camera on a road's wide board, in front of the fighters: plants, roots or rocks framing the
## foot and sides, in art/foregrounds/ (tools/foreground.py). `width` is how wide it is against the screen (over 1
## pushes the side clumps past the back columns), `sink` how much of its height drops below the bottom edge, and
## `shade` how dark it stands, so it reads as near the camera rather than part of the painting.
const FOREGROUNDS := {
	"wood": {"art": "jungle", "width": 1.5, "sink": 0.2, "shade": 1.0},
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


## One of a home's painted backgrounds, or null when that home has none yet.
static func painted(home: String) -> Painted:
	var arts: Array = ART.get(home, [])
	return Painted.new().setup(arts.pick_random()) if not arts.is_empty() else null


## The tiled ground of a road's fights, or null when that road has none yet.
static func ground(road: String) -> Painted:
	var g: Dictionary = GROUNDS.get(road, {})
	if g.is_empty():
		return null
	return Painted.new().setup("", Color(g.shade, g.shade, g.shade)).tiled(ground_path(g.art))


static func ground_path(art: String) -> String:
	return "res://art/grounds/ground-%s.webp" % art


## A road's foreground for a board `size` big, standing on its foot and centred, or null for a road with none.
static func foreground(road: String, size: Vector2) -> Control:
	var f: Dictionary = FOREGROUNDS.get(road, {})
	if f.is_empty():
		return null
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var w: float = size.x * f.width
	holder.size = Vector2(w, w / 2.0)
	holder.position = Vector2((size.x - w) / 2.0, size.y - holder.size.y * (1.0 - f.sink))
	holder.add_child(Painted.new().setup("", Color(f.shade, f.shade, f.shade)).layer(foreground_path(f.art)))
	return holder


static func foreground_path(art: String) -> String:
	return "res://art/foregrounds/fore-%s.webp" % art


## The music of a painting: the road it shows, else the road of the home it hangs in, else "" when its home has no road.
static func music_of(art: String) -> String:
	for key in Expedition.ROADS:
		if Expedition.ROADS[key].art == art:
			return Expedition.ROADS[key].music.map
	for home in ART:
		if art in ART[home]:
			for key in Expedition.ROADS:
				if Expedition.ROADS[key].region == home:
					return Expedition.ROADS[key].music.map
	return ""


static func art_path(art: String) -> String:
	return "res://art/backgrounds/%s.webp" % art


## The paintings behind whole screens, which belong to no home and have no weather.
const SCREEN_ART := ["caravan", "dream"]


## Every painted background, once each.
static func all_art() -> Array[String]:
	var out: Array[String] = []
	for arts in ART.values():
		for art in arts:
			if art not in out:
				out.append(art)
	return out


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

