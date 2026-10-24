class_name BattleFigure
extends Control
## A fighter standing on a battle tile (the landscape build): the full-body sprite on its tile, heroes facing right
## and foes facing left, breathing while it waits. Its name and health sit on a plate at its feet; statuses, its place
## in the queue, its intent and the forecast float over its head. It flashes when hit, the numbers rise off it, and a
## fallen fighter greys and sinks. Taps on its body go to its tile, so a tall figure never steals a tap meant for the
## tile behind it except where its body actually is.

## How tall a standard fighter stands, in tiles.
const TALL := 1.85
## Where on its tile a fighter's feet are, from the top; the rest of the tile holds its plate.
const FOOT := 0.56

var tile: BattleTile
## Fighters in the far lanes stand a little smaller, so the board has depth.
var depth := 1.0
var _t := 0.0
var _flash := 0.0
## How far the fighter is out of place while it acts (a lunge, a cast), and the light of a cast at its feet.
var _lunge := Vector2.ZERO
var _cast := 0.0
## Seconds into the fighter's attack sheet while it plays, else -1.
var _swing := -1.0
## Plates, statuses, the queue number and the forecast: drawn on a layer above every fighter, so the fighter in front
## never hides the name of the one behind.
var _over: Control


func _ready() -> void:
	_over = Control.new()
	_over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_over.z_index = 5
	add_child(_over)
	_over.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_over.draw.connect(_draw_over)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_t = randf() * 4.0
	gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			tile.screen.on_tile(tile.side, tile.r, tile.c))
	mouse_entered.connect(func(): tile.screen.on_hover(tile.side, tile.r, tile.c))


## The figure sits over its tile: as wide as two tiles, reaching up well above it.
func place() -> void:
	var ts := tile.size
	depth = 0.88 + 0.04 * tile.c
	size = Vector2(ts.x * 1.8, ts.y * (TALL + 1.3))
	position = tile.position + Vector2(ts.x / 2 - size.x / 2, ts.y * FOOT - size.y + ts.y * 0.42)


func _foot() -> Vector2:
	return Vector2(size.x / 2, size.y - tile.size.y * 0.42)


func _unit() -> Dictionary:
	return tile.screen.unit_view(tile.side, tile.r, tile.c)


func _process(delta: float) -> void:
	_t += delta
	_flash = maxf(0.0, _flash - delta * 3.0)
	if _swing >= 0.0:
		_swing += delta
		if not Figure.swinging(_unit().get("sprite", {}), _swing):
			_swing = -1.0
	queue_redraw()
	_over.queue_redraw()


## Only the body takes taps: a column up the middle of the figure.
func _has_point(p: Vector2) -> bool:
	var u := _unit()
	if u.is_empty() or u.get("sprite", {}).is_empty():
		return false
	var h := Figure.height(u.sprite, tile.size.y * TALL * depth)
	var f := _foot()
	return absf(p.x - f.x) < tile.size.x * 0.36 and p.y > f.y - h and p.y < f.y


func _draw() -> void:
	var u := _unit()
	if u.is_empty():
		return
	var spr: Dictionary = u.get("sprite", {})
	var alive: bool = u.view.alive
	var foot := _foot()
	var h := Figure.height(spr, tile.size.y * TALL * depth) if not spr.is_empty() else tile.size.y * TALL * depth
	# Marching in: the fighter strides from off the field, a bob for each step.
	var enter := tile.enter
	if enter < 1.0:
		var k := 1.0 - enter
		foot += tile._from * k + Vector2(0, -absf(sin(enter * PI * 4)) * 12 * k)
	foot += _lunge
	if _cast > 0.0:
		# A cast: a ring of the fighter's element opening at its feet.
		draw_set_transform(foot, 0, Vector2(1, 0.3))
		draw_arc(Vector2.ZERO, tile.size.x * (0.3 + 0.5 * (1.0 - _cast)), 0, TAU, 48, Color(Forge.ELEM[u.elem], _cast), 4.0, true)
		draw_set_transform(Vector2.ZERO)
	var mod := Color.WHITE
	if not alive:
		mod = Color(0.45, 0.42, 0.4, 0.5)
		foot.y += tile.size.y * 0.12
	elif _flash > 0.0:
		var k := 1.0 + _flash * 1.4
		mod = Color(k, k, k * 0.92)
	if spr.is_empty():
		# No art yet: the element's sigil on a disc where the fighter would stand.
		draw_circle(foot - Vector2(0, h * 0.4), h * 0.22, Color(Forge.ELEM[u.elem], 0.3))
		draw_texture_rect(Forge.sigil(u.elem), Rect2(foot - Vector2(h * 0.14, h * 0.54), Vector2(h * 0.28, h * 0.28)), false, Forge.GOLD)
	else:
		Figure.draw(self, spr, foot, h, {"t": _t, "flip": tile.side == "P", "breathe": 1.0 if alive else 0.0, "modulate": mod,
			"swing": _swing})


## Everything about the fighter that must stay readable: plate, KO, statuses, intent, forecast, queue number.
func _draw_over() -> void:
	var u := _unit()
	if u.is_empty():
		return
	var spr: Dictionary = u.get("sprite", {})
	var alive: bool = u.view.alive
	var foot := _foot()
	var h := Figure.height(spr, tile.size.y * TALL * depth) if not spr.is_empty() else tile.size.y * TALL * depth
	if tile.enter < 1.0:
		return
	var head := foot.y - h
	_plate(u, foot, alive)
	if not alive:
		var word := "down %d" % u.view.downed if u.view.downed > 0 else "ko"
		var f := Forge.tracked(Forge.SC_HEAVY, 4)
		_over.draw_string_outline(f, Vector2(0, foot.y - h * 0.4), word, HORIZONTAL_ALIGNMENT_CENTER, size.x, 24, 6, Forge.INK)
		_over.draw_string(f, Vector2(0, foot.y - h * 0.4), word, HORIZONTAL_ALIGNMENT_CENTER, size.x, 24, Color(Forge.PARCHMENT, 0.8))
		return
	# Over the head: statuses, then the intent, then the forecast on top.
	var y := head - 4.0
	var st: Dictionary = u.view.st
	var tags := []
	if st.get("stun", 0): tags.append(["stun", Forge.GOLD_LIGHT])
	if st.get("burn", 0): tags.append(["burn %d" % st.burn, Color("#ff7a3d")])
	if st.get("shield", 0): tags.append(["shd %d" % st.shield, Color("#7cc7ff")])
	if st.get("guard", false): tags.append(["grd", Color("#9fb3c8")])
	if tags.size():
		y -= 22
		var total := 0.0
		for t in tags:
			total += _tag_w(t[0]) + 4
		var x := size.x / 2 - total / 2
		for t in tags:
			x = _tag(Vector2(x, y), t[0], t[1]) + 4
	var intent := tile.screen.intent_of(u.id)
	if not intent.is_empty():
		var word: String = "stunned" if intent.stunned else intent.name.to_lower()
		y -= 24
		_tag(Vector2(size.x / 2 - _tag_w(word) / 2, y), word, Forge.MUTED if intent.stunned else (Forge.HARM if intent.kind == "dmg" else Forge.MEND))
	var pv := tile.screen.preview_at(tile.side, tile.r, tile.c)
	if not pv.is_empty():
		_preview(pv, y - 6)
	# Its place in the queue, a gold diamond at shoulder height on the side it faces.
	var qi := tile.screen.queue_index(u)
	if qi >= 0:
		var q := Vector2(foot.x + (1 if tile.side == "P" else -1) * tile.size.x * 0.42, head + h * 0.28)
		Forge.diamond(_over, q, 21, Forge.INK)
		Forge.diamond(_over, q, 19, Forge.GOLD, false)
		_over.draw_string_outline(Forge.SC_HEAVY, q + Vector2(-14, 10), str(qi + 1), HORIZONTAL_ALIGNMENT_CENTER, 28, 28, 4, Forge.INK)
		_over.draw_string(Forge.SC_HEAVY, q + Vector2(-14, 10), str(qi + 1), HORIZONTAL_ALIGNMENT_CENTER, 28, 28, Forge.GOLD_LIGHT)


## The name and health on a small plate at the fighter's feet.
func _plate(u: Dictionary, foot: Vector2, alive: bool) -> void:
	var w := tile.size.x * 0.92
	var r := Rect2(foot.x - w / 2, foot.y + 6, w, 30)
	_over.draw_rect(r, Color(Forge.INK, 0.82))
	_over.draw_rect(r, Color(Forge.ELEM[u.elem], 0.55) if alive else Color(Forge.DIM, 0.4), false, 1.0)
	_over.draw_string(Forge.tracked(Forge.SC, 1), Vector2(r.position.x + 6, r.position.y + 14), Battle.name_of(u).to_lower(),
		HORIZONTAL_ALIGNMENT_LEFT, w - 44, 14, Forge.PARCHMENT if alive else Forge.DIM)
	var hp: int = u.view.hp
	_over.draw_string(Forge.SANS_BOLD, Vector2(r.end.x - 44, r.position.y + 14), str(hp), HORIZONTAL_ALIGNMENT_RIGHT, 38, 13, Forge.MUTED)
	var bar := Rect2(r.position.x + 6, r.position.y + 19, w - 12, 5)
	_over.draw_rect(bar, Color(0, 0, 0, 0.9))
	var pct := clampf(float(hp) / u.max_hp, 0, 1)
	_over.draw_rect(Rect2(bar.position, Vector2(bar.size.x * pct, bar.size.y)), BattleTile.HP_LOW if pct < 0.35 else Forge.GAIN)


## The forecast over the head: red for damage, green for healing or shield, framed when it's the one in the bar.
func _preview(pv: Dictionary, bottom: float) -> void:
	var dmg: bool = pv.kind == "dmg"
	var col: Color = Forge.HARM if dmg else Forge.MEND
	var txt: String = "+%d" % pv.shield if pv.kind == "shield" else "%+d" % (pv.after - pv.before)
	var f := Forge.tracked(Forge.SC_HEAVY, 1)
	var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x + 18
	var box := Rect2((size.x - w) / 2, bottom - 38, w, 38)
	_over.draw_rect(box, Color(Forge.INK, 0.86))
	_over.draw_rect(box, col if pv.current else Color(col, 0.5), false, 3.0 if pv.current else 1.5)
	_over.draw_string(f, box.position + Vector2(9, 29), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, col.lightened(0.15))
	if pv.ko:
		BattleTile.skull(_over, Vector2(box.end.x + 14, box.position.y + 19))


func _tag_w(text: String) -> float:
	return Forge.tracked(Forge.SC, 1).get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 10


func _tag(at: Vector2, text: String, color: Color) -> float:
	var w := _tag_w(text)
	_over.draw_rect(Rect2(at.x, at.y, w, 20), Color(Forge.INK, 0.85))
	_over.draw_rect(Rect2(at.x, at.y, w, 20), Color(color, 0.7), false, 1.0)
	_over.draw_string(Forge.tracked(Forge.SC, 1), Vector2(at.x + 5, at.y + 15), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
	return at.x + w


func flash() -> void:
	_flash = 1.0


## A win: two hops, the second higher, each landing with a little settle.
func cheer() -> void:
	var tw := create_tween()
	tw.tween_interval(randf() * 0.2)
	for k in [16.0, 26.0]:
		tw.tween_property(self, "_lunge", Vector2(0, -k), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "_lunge", Vector2.ZERO, 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


## The fighter acts: melee lunges toward the other side, ranged leans in, support lifts and opens a ring of light.
## Returns how long until the blow lands: a fighter with an attack sheet swings it, and the hit waits for the blade.
func act(kind: String, reach: String) -> float:
	var dir := 1.0 if tile.side == "P" else -1.0
	var spr: Dictionary = _unit().get("sprite", {})
	if not kind in ["heal", "shield", "buff", "guard"] and spr.has("attack") and Clips.sheet(spr.attack.src):
		_swing = 0.0
		var step := create_tween()
		step.tween_property(self, "_lunge", Vector2(dir * (24.0 if reach == "melee" else 8.0), 0), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		step.tween_interval(spr.attack.hit)
		step.tween_property(self, "_lunge", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		return spr.attack.hit
	var tw := create_tween()
	if kind in ["heal", "shield", "buff", "guard"]:
		_cast = 1.0
		tw.tween_property(self, "_lunge", Vector2(0, -10), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(self, "_cast", 0.0, 0.6)
	else:
		var d := 46.0 if reach == "melee" else 16.0
		tw.tween_property(self, "_lunge", Vector2(dir * d, -4), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "_lunge", Vector2.ZERO, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return 0.16


## A number or word rising off the fighter's head and fading.
func float_text(text: String, cls: String) -> void:
	var u := _unit()
	var h := Figure.height(u.get("sprite", {}), tile.size.y * TALL * depth) if not u.is_empty() else tile.size.y
	var l := Forge.sc(text, 32, BattleTile.FLOAT_COLORS.get(cls, Forge.PARCHMENT), true, 0.04)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(size.x, 40)
	l.position = Vector2(0, _foot().y - h * 0.75)
	l.add_theme_color_override("font_outline_color", Forge.INK)
	l.add_theme_constant_override("outline_size", 8)
	_over.add_child(l)
	var t := create_tween().set_parallel()
	t.tween_property(l, "position:y", l.position.y - 56, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "modulate:a", 0.0, 0.85).set_delay(0.3)
	t.chain().tween_callback(l.queue_free)
