extends SceneTree
## Makes a hero's tall standing art for the wide hero screen: keys a raw full body off its flat ground, trims it and sets
## it on a square canvas, saved to art/stands/<name>-stand.webp. Run from game/:
##   godot --headless --path . --script ../tools/hero-stand.gd -- <raw image> <name> [wears-green]
## Green is cleared from the whole figure, or only near its edge for a hero who wears green.
## Also clears the stray key-colour columns at a portrait's cut edge:
##   godot --headless --path . --script ../tools/hero-stand.gd -- --edges <portrait.webp> <left> <right>

const SIDE := 2048
const TOL := 46.0
const EDGE := 12.0
## How many pixels in from the edge green is cleared on a hero who wears it.
const SPILL := 7
## How strongly a pixel must lean to the ground's hue before it starts to clear, and over what range it clears.
const HUE := 18
const HUE_SOFT := 34.0


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a[0] == "--edges":
		_edges(a[1], int(a[2]), int(a[3]))
	else:
		_stand(a[0], a[1], a.size() > 2)
	quit()


func _edges(path: String, left: int, right: int) -> void:
	var img := Image.load_from_file(path)
	img.convert(Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			if x <= left or x >= right:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	img.save_webp(path, false)


func _stand(path: String, name: String, wears_green: bool) -> void:
	var img := Image.load_from_file(path)
	img.convert(Image.FORMAT_RGBA8)
	var scale := minf(1.0, float(SIDE) / maxf(img.get_width(), img.get_height()))
	img.resize(roundi(img.get_width() * scale), roundi(img.get_height() * scale), Image.INTERPOLATE_LANCZOS)
	if img.get_pixel(2, 2).a > 0.5:
		_key(img, wears_green)
	var used := img.get_used_rect()
	var fig := img.get_region(used)
	var side := maxi(fig.get_width(), fig.get_height())
	var out := Image.create_empty(side, side, false, Image.FORMAT_RGBA8)
	out.blit_rect(fig, Rect2i(Vector2i.ZERO, fig.get_size()), Vector2i((side - fig.get_width()) / 2, side - fig.get_height()))
	out.save_webp("res://art/stands/%s-stand.webp" % name, true, 0.85)
	print(name, " ", out.get_size(), " figure ", fig.get_size())


func _key(img: Image, wears_green: bool) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var data := img.get_data()
	var bg := _ground(data, w, h)
	var magenta := bg.x > bg.y and bg.z > bg.y
	var dist := PackedFloat32Array()
	dist.resize(w * h)
	for i in w * h:
		var o := i * 4
		var dr := data[o] - bg.x
		var dg := data[o + 1] - bg.y
		var db := data[o + 2] - bg.z
		dist[i] = sqrt(dr * dr + dg * dg + db * db)
		# A ground is rarely one flat colour, so anything as strongly its hue counts as ground too, shadows included.
		var k: int = mini(data[o], data[o + 2]) - data[o + 1] if magenta else data[o + 1] - maxi(data[o], data[o + 2])
		if k > HUE:
			dist[i] = minf(dist[i], TOL * (1.0 - clampf(float(k - HUE) / HUE_SOFT, 0.0, 1.0)))
	# The ground is what the border reaches, so green the hero wears stays; pockets take only the exact colour.
	var out := PackedByteArray()
	out.resize(w * h)
	var stack := PackedInt32Array()
	for x in w:
		stack.append(x)
		stack.append((h - 1) * w + x)
	for y in h:
		stack.append(y * w)
		stack.append(y * w + w - 1)
	while not stack.is_empty():
		var i := stack[-1]
		stack.resize(stack.size() - 1)
		if out[i] == 1 or dist[i] >= TOL:
			continue
		out[i] = 1
		if i % w > 0: stack.append(i - 1)
		if i % w < w - 1: stack.append(i + 1)
		if i >= w: stack.append(i - w)
		if i < w * (h - 1): stack.append(i + w)
	var near := PackedByteArray()
	near.resize(w * h)
	for i in w * h:
		near[i] = 1 if out[i] == 1 or dist[i] < EDGE else 0
	for _step in SPILL:
		var grown := near.duplicate()
		for i in w * h:
			if near[i] == 1:
				continue
			if (i % w > 0 and near[i - 1] == 1) or (i % w < w - 1 and near[i + 1] == 1) or (i >= w and near[i - w] == 1) or (i < w * (h - 1) and near[i + w] == 1):
				grown[i] = 1
		near = grown
	for i in w * h:
		var o := i * 4
		if out[i] == 1 or dist[i] < EDGE:
			data[o + 3] = roundi(255.0 * clampf((dist[i] - EDGE) / (TOL - EDGE), 0.0, 1.0))
		if magenta:
			if near[i] == 1:
				data[o] = mini(data[o], data[o + 1] + 40)
				data[o + 2] = mini(data[o + 2], data[o + 1] + 40)
		elif near[i] == 1 or not wears_green:
			# The edge still holds the green it was cut from.
			data[o + 1] = mini(data[o + 1], maxi(data[o], data[o + 2]))
	img.set_data(w, h, false, Image.FORMAT_RGBA8, data)


func _ground(data: PackedByteArray, w: int, h: int) -> Vector3:
	var r := []
	var g := []
	var b := []
	for x in range(0, w, 7):
		var o := x * 4
		r.append(data[o])
		g.append(data[o + 1])
		b.append(data[o + 2])
	r.sort()
	g.sort()
	b.sort()
	return Vector3(r[r.size() / 2], g[g.size() / 2], b[b.size() / 2])
