class_name Figure
extends RefCounted
## Draws a battle sprite standing on a point: the figure, cut out with its feet on the bottom edge, its contact shadow
## and its idle. A sprite with an `anim` sheet plays its frames. A still with a `rig` (tools/auto-rig.py) is drawn as a
## mesh and brought to life: the chest breathes, the head nods, the body shifts its weight, and whatever hangs loose
## (a braid, a sleeve, a hem) sways a beat behind, all while the feet stay planted. A plain still breathes in bands.
## A waist-up cutout (`bust`) fades out at the bottom so it still seems to stand. Every screen that shows a fighter
## uses this.

## How far each motion of a rigged still reaches, as shares of the figure's height.
const RIG_LIFT := 0.009
const RIG_CHEST := 0.035
const RIG_NOD := 0.012
const RIG_LEAN := 0.006
const RIG_SWAY := 0.016

static var _tex := {}
## Rigs unpacked for drawing, by sprite src: vertex weights as floats and the triangle indices.
static var _rigs := {}


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
	if spr.has("rig") and anim.is_empty() and not bust:
		_rigged(ci, spr, src, region, Vector2(left, foot.y), w, dh, breathe, t, flip, mod)
		return Rect2(foot.x - h * 0.2, foot.y - h, h * 0.4, h)
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


## The rig's weights per vertex (pin, head, chest, loose; 0..1) and its triangles, unpacked once per sprite.
static func rig_of(spr: Dictionary) -> Dictionary:
	if _rigs.has(spr.src):
		return _rigs[spr.src]
	var r: Dictionary = spr.rig
	var cols: int = r.cols
	var rows: int = r.rows
	var out := {"cols": cols, "rows": rows, "neck": Vector2(r.neck[0], r.neck[1]), "chest_at": Vector2(r.chest_at[0], r.chest_at[1])}
	for ch in ["pin", "head", "chest", "loose"]:
		var f := PackedFloat32Array()
		var digits: String = r[ch]
		f.resize(digits.length())
		for i in digits.length():
			f[i] = digits.unicode_at(i) - 48
			f[i] /= 9.0
		out[ch] = f
	var tri := PackedInt32Array()
	for y in rows:
		for x in cols:
			var i := y * (cols + 1) + x
			tri.append_array([i, i + 1, i + cols + 1, i + 1, i + cols + 2, i + cols + 1])
	out.tri = tri
	_rigs[spr.src] = out
	return out


## Where a rigged still's vertex moves at time `t`, as an offset in shares of the figure's height (x to the right as
## drawn unflipped). `u`, `v` place the vertex across and down the sprite; `aspect` is its width over its height.
static func rig_offset(rig: Dictionary, i: int, u: float, v: float, aspect: float, t: float, breathe: float) -> Vector2:
	var pin: float = rig.pin[i]
	var free := 1.0 - pin
	var br := sin(t * TAU * 0.32)
	var off := Vector2.ZERO
	# Breath: the body above the hips rises and settles, and the chest swells across.
	off.y -= br * RIG_LIFT * smoothstep(0.3, 0.95, 1.0 - v) * free
	var chest: float = rig.chest[i]
	off.x += (u - rig.chest_at.x) * aspect * chest * RIG_CHEST * br
	off.y -= chest * RIG_LIFT * 0.4 * br
	# The head nods and tilts about the neck.
	var head: float = rig.head[i]
	var nod := head * RIG_NOD * sin(t * 0.7 + 0.6)
	off.x += nod * (rig.neck.y - v) * 3.0
	off.y += head * RIG_NOD * 0.3 * sin(t * 0.55)
	# The weight shifts from foot to foot, the feet themselves planted.
	off.x += (1.0 - v) * free * RIG_LEAN * sin(t * 0.41)
	# Loose parts follow a beat behind, the further out the later, like cloth in a breeze.
	var loose: float = rig.loose[i]
	var wave := t * 1.6 - loose * 2.5 - v * 2.2
	off.x += loose * RIG_SWAY * sin(wave)
	off.y += loose * RIG_SWAY * 0.3 * cos(wave * 1.3)
	return off * breathe


## A rigged still as one mesh over its rig's grid, each vertex moved by rig_offset. `at` is the bottom-left corner.
static func _rigged(ci: CanvasItem, spr: Dictionary, src: Texture2D, region: Rect2, at: Vector2, w: float, h: float,
		breathe: float, t: float, flip: bool, mod: Color) -> void:
	var rig := rig_of(spr)
	var cols: int = rig.cols
	var rows: int = rig.rows
	var n := (cols + 1) * (rows + 1)
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	pts.resize(n)
	uvs.resize(n)
	var ts := src.get_size()
	var aspect := w / h
	for y in rows + 1:
		var v := float(y) / rows
		for x in cols + 1:
			var u := float(x) / cols
			var i := y * (cols + 1) + x
			var off := rig_offset(rig, i, u, v, aspect, t, breathe) * h
			var px := u * w + off.x
			pts[i] = Vector2(at.x + (w - px if flip else px), at.y - h + v * h + off.y)
			uvs[i] = (region.position + Vector2(u, v) * region.size) / ts
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), rig.tri, pts, PackedColorArray([mod]), uvs,
		PackedInt32Array(), PackedFloat32Array(), src.get_rid())
