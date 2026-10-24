class_name Figure
extends RefCounted
## Draws a battle sprite standing on a point: the figure, cut out with its feet on the bottom edge, its contact shadow
## and its idle. A plain sprite breathes in bands (the body above the hips
## rises and settles while the feet stay planted); a sprite with an `anim` sheet plays its frames instead. A waist-up
## cutout (`bust`) fades out at the bottom so it still seems to stand. Every screen that shows a fighter uses this.

static var _tex := {}


static func tex(src: String) -> Texture2D:
	if not _tex.has(src):
		_tex[src] = load(src)
	return _tex[src]


## The size a sprite draws at for a given standard height: its own `size` against the others.
static func height(spr: Dictionary, base: float) -> float:
	return base * spr.get("size", 1.0) * (0.78 if spr.get("bust", false) else 1.0)


## Draws `spr` with its feet at `foot`, `h` tall. Options: flip (face the other way), t (seconds, for the idle),
## breathe (0 still … 1 normal), shadow, modulate (tint and fade, for the fallen).
static func draw(ci: CanvasItem, spr: Dictionary, foot: Vector2, h: float, opts := {}) -> Rect2:
	if spr.is_empty():
		return Rect2()
	var t: float = opts.get("t", 0.0)
	var flip: bool = opts.get("flip", false)
	var mod: Color = opts.get("modulate", Color.WHITE)
	var anim: Dictionary = spr.get("anim", {})
	var src: Texture2D
	var region: Rect2
	if not anim.is_empty() and opts.get("breathe", 1.0) > 0.0:
		src = tex(anim.src)
		var f := int(t * anim.fps) % int(anim.n)
		region = Rect2((f % int(anim.cols)) * anim.w, (f / int(anim.cols)) * anim.h, anim.w, anim.h)
	else:
		src = tex(spr.src)
		region = Rect2(Vector2.ZERO, src.get_size())
	var w := h * region.size.x / region.size.y
	if opts.get("shadow", true):
		# A soft dark oval where the feet meet the ground, darker at its heart.
		ci.draw_set_transform(foot, 0, Vector2(1, 0.22))
		for i in 6:
			var k := 1.0 - i / 6.0
			ci.draw_circle(Vector2.ZERO, w * 0.42 * k, Color(0, 0, 0, 0.11 * mod.a))
		ci.draw_set_transform(Vector2.ZERO)
	var bust: bool = spr.get("bust", false)
	var breathe: float = 0.0 if not anim.is_empty() else opts.get("breathe", 1.0)
	var phase: float = t * TAU * 0.32
	var bands := 1 if breathe <= 0.0 and not bust else maxi(24, int(h / 4.0))
	_bands(ci, src, region, foot, w, h, bands, breathe, phase, flip, bust, mod)
	return Rect2(foot.x - w / 2, foot.y - h, w, h)


## The figure in horizontal bands, each shifted by how high it sits (the breathing), faded at the foot for a bust.
static func _bands(ci: CanvasItem, src: Texture2D, region: Rect2, foot: Vector2, w: float, h: float, n: int, breathe: float,
		phase: float, flip: bool, bust: bool, mod: Color) -> void:
	for i in n:
		var y0 := float(i) / n
		var y1 := float(i + 1) / n
		var up := 1.0 - (y0 + y1) / 2.0
		var lift := smoothstep(0.3, 0.95, up)
		var dy := -sin(phase) * 0.011 * h * breathe * lift
		var a := mod.a
		if bust:
			a *= clampf((1.0 - y1) / 0.22, 0.0, 1.0)
		var dst := Rect2(foot.x - w / 2, foot.y - h + y0 * h + dy, w, (y1 - y0) * h + 1.0)
		var srect := Rect2(region.position.x, region.position.y + y0 * region.size.y, region.size.x, (y1 - y0) * region.size.y)
		if flip:
			# A negative width mirrors the band in place.
			dst.size.x = -dst.size.x
		ci.draw_texture_rect_region(src, dst, srect, Color(mod.r, mod.g, mod.b, a))
