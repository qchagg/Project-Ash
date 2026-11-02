class_name StatusFx
extends RefCounted
## What a fighter's statuses look like on the body, drawn each frame over their sprite: burn sheds embers, stun circles
## the head with stars, a shield shimmers round them, and guard rings their feet. Everything is drawn, so it costs the
## game pack nothing. The tags over the head still say the numbers; this is how a status reads at a glance.

const BURN := Color("#ff7a3d")
const STUN := Color("#ffe08a")
const SHIELD := Color("#7cc7ff")
const GUARD := Color("#9fb3c8")
const EMBERS := 9
const STARS := 3
## How long one ember takes to rise, and the stars' turns a second.
const EMBER_LIFE := 1.3
const STAR_SPIN := 0.55


## The effects a fighter's statuses call for, in the order they are drawn.
static func active(st: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for key in ["guard", "shield", "burn", "stun"]:
		if st.get(key, 0):
			out.append(key)
	return out


## Draws them on `c`, for a fighter `h` tall with their feet at `foot`, `t` seconds in.
static func draw(c: CanvasItem, st: Dictionary, foot: Vector2, h: float, t: float) -> void:
	var w := h * 0.42
	for kind in active(st):
		match kind:
			"guard":
				_ring(c, foot, w, t)
			"shield":
				_bubble(c, foot, h, w, t)
			"burn":
				_embers(c, foot, h, w, t)
			"stun":
				_stars(c, foot, h, t)


static func _ring(c: CanvasItem, foot: Vector2, w: float, t: float) -> void:
	c.draw_set_transform(foot, 0.0, Vector2(1.0, 0.28))
	c.draw_arc(Vector2.ZERO, w * 0.8, 0.0, TAU, 40, Color(GUARD, 0.55 + 0.2 * sin(t * 2.4)), 3.0, true)
	c.draw_set_transform(Vector2.ZERO)


static func _bubble(c: CanvasItem, foot: Vector2, h: float, w: float, t: float) -> void:
	var centre := foot - Vector2(0.0, h * 0.5)
	var breathe := 1.0 + 0.02 * sin(t * 2.2)
	c.draw_set_transform(centre, 0.0, Vector2(w * 1.05, h * 0.56) * breathe)
	c.draw_circle(Vector2.ZERO, 1.0, Color(SHIELD, 0.07))
	# A brighter band sweeps round the edge, so the bubble reads as moving even when the fighter is still.
	c.draw_arc(Vector2.ZERO, 1.0, 0.0, TAU, 48, Color(SHIELD, 0.35), 0.012, true)
	var at := t * 1.4
	c.draw_arc(Vector2.ZERO, 1.0, at, at + 1.1, 18, Color(SHIELD, 0.9), 0.02, true)
	c.draw_set_transform(Vector2.ZERO)


static func _embers(c: CanvasItem, foot: Vector2, h: float, w: float, t: float) -> void:
	for i in EMBERS:
		var seed_i := float(i) * 2.399
		var age := fposmod(t / EMBER_LIFE + float(i) / EMBERS, 1.0)
		var x := sin(seed_i) * w * 0.7 + sin(t * 2.0 + seed_i) * 6.0
		var at := foot + Vector2(x, -h * (0.12 + 0.75 * age))
		var fade := sin(age * PI)
		c.draw_circle(at, 6.0 * fade, Color(BURN, 0.28 * fade))
		c.draw_circle(at, 2.4 * fade, Color(STUN, 0.95 * fade))


static func _stars(c: CanvasItem, foot: Vector2, h: float, t: float) -> void:
	var centre := foot - Vector2(0.0, h * 1.02)
	for i in STARS:
		var a := TAU * (t * STAR_SPIN + float(i) / STARS)
		# A flat circle: stars passing behind the head sit a little higher and dimmer.
		var at := centre + Vector2(cos(a) * h * 0.2, sin(a) * h * 0.05)
		_star(c, at, 7.0 + 2.0 * sin(a), Color(STUN, 0.75 + 0.25 * sin(a)))


static func _star(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 10:
		var a := TAU * k / 10.0 - PI / 2.0
		pts.append(at + Vector2(cos(a), sin(a)) * (r if k % 2 == 0 else r * 0.42))
	c.draw_colored_polygon(pts, col)
