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
## breathe (0 still … 1 normal), shadow, modulate (tint and fade, for the fallen), swing (seconds into the sprite's
## attack, while it plays; see `swinging`). A sheet whose feet aren't centred says where they are (`foot_x`).
static func draw(ci: CanvasItem, spr: Dictionary, foot: Vector2, h: float, opts := {}) -> Rect2:
	if spr.is_empty():
		return Rect2()
	var t: float = opts.get("t", 0.0)
	# `flip` asks for a right-facing figure; a sprite drawn facing right (`faces`) is mirrored the other way round.
	var want_right: bool = opts.get("flip", false)
	var flip := mirrored(spr, want_right)
	var mod: Color = opts.get("modulate", Color.WHITE)
	var anim: Dictionary = spr.get("anim", {})
	var fx: float = spr.get("foot_x", 0.5)
	var src: Texture2D = tex(spr.src)
	var region := Rect2(Vector2.ZERO, src.get_size())
	var dh := h
	# The idle sheet, once it is here (see Clips); until then the still sprite stands in and breathes.
	var sheet: Texture2D = Clips.sheet(anim.src) if not anim.is_empty() else null
	if sheet == null:
		anim = {}
	var swing: Dictionary = spr.get("attack", {})
	var st: float = opts.get("swing", -1.0)
	var swing_tex: Texture2D = Clips.sheet(swing.src) if swinging(spr, st) else null
	if swing_tex:
		# The attack: its own cells, taller than the idle's by `tall`, the feet where the swing sheet says.
		var f := mini(int(st * swing.fps), int(swing.n) - 1)
		src = swing_tex
		region = Rect2((f % int(swing.cols)) * swing.w, (f / int(swing.cols)) * swing.h, swing.w, swing.h)
		dh = h * swing.tall
		fx = swing.foot_x
		flip = mirrored(swing, want_right)
		anim = {"playing": true}
	elif not anim.is_empty() and opts.get("breathe", 1.0) > 0.0:
		src = sheet
		var f := int(t * anim.fps) % int(anim.n)
		region = Rect2((f % int(anim.cols)) * anim.w, (f / int(anim.cols)) * anim.h, anim.w, anim.h)
	var w := dh * region.size.x / region.size.y
	var left := foot.x - w * ((1.0 - fx) if flip else fx)
	if opts.get("shadow", true):
		# A soft dark oval where the feet meet the ground, darker at its heart.
		ci.draw_set_transform(foot, 0, Vector2(1, 0.22))
		for i in 6:
			var k := 1.0 - i / 6.0
			ci.draw_circle(Vector2.ZERO, h * 0.26 * k, Color(0, 0, 0, 0.11 * mod.a))
		ci.draw_set_transform(Vector2.ZERO)
	var bust: bool = spr.get("bust", false)
	var breathe: float = 0.0 if not anim.is_empty() else opts.get("breathe", 1.0)
	var phase: float = t * TAU * 0.32
	var bands := 1 if breathe <= 0.0 and not bust else maxi(24, int(dh / 4.0))
	_bands(ci, src, region, Vector2(left, foot.y), w, dh, bands, breathe, phase, flip, bust, mod)
	return Rect2(foot.x - h * 0.2, foot.y - h, h * 0.4, h)


## Whether art drawn facing `art.faces` (left unless it says right) must be mirrored to face right (or left).
static func mirrored(art: Dictionary, want_right: bool) -> bool:
	return want_right != (art.get("faces", "left") == "right")


## True while `t` (seconds since a strike began) is inside the sprite's attack.
static func swinging(spr: Dictionary, t: float) -> bool:
	var swing: Dictionary = spr.get("attack", {})
	return t >= 0.0 and not swing.is_empty() and t < swing.n / swing.fps


## The figure in horizontal bands, each shifted by how high it sits (the breathing), faded at the foot for a bust.
## `at` is the bottom-left corner.
static func _bands(ci: CanvasItem, src: Texture2D, region: Rect2, at: Vector2, w: float, h: float, n: int, breathe: float,
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
		var dst := Rect2(at.x, at.y - h + y0 * h + dy, w, (y1 - y0) * h + 1.0)
		var srect := Rect2(region.position.x, region.position.y + y0 * region.size.y, region.size.x, (y1 - y0) * region.size.y)
		if flip:
			# A negative width mirrors the band in place.
			dst.size.x = -dst.size.x
		ci.draw_texture_rect_region(src, dst, srect, Color(mod.r, mod.g, mod.b, a))
