class_name BattleTile
extends Control
## One tile of a battle grid: the unit standing there as a small card (portrait, sigil, name, HP, statuses), or an
## empty tile. Lit when it can be aimed at; flashes and floats numbers when the fight touches it. Draws from the
## screen's current view of the board, so playback can show each beat. On the landscape board a BattleFigure stands
## on the tile instead of a card, and the tile is floor: a pool of light under the fighter, and the move, attack and
## danger lights.

const HP_LOW := Color("#e86a5a")
const FLOAT_COLORS := {"crit": Color("#ffb347"), "resist": Color("#cbbd9f"), "hurt": Color("#f3e6c4"), "blocked": Color("#9fb3c8"),
	"mend": Color("#a9dd92"), "shield": Color("#7cc7ff"), "burn": Color("#ff7a3d"), "stun": Color("#f6dc94")}

var screen: BattleScreen
var side := "P"
var r := 0
var c := 0
## 0 → 1 as the unit here walks onto the field at the start of a fight; 1 when settled.
var enter := 1.0
## The fighter standing here on the landscape board (null on the card board).
var figure: BattleFigure
## Clock for the selected hero's comet rim.
var _t := 0.0
var _from := Vector2.ZERO
## 0 → 1 as the unit here falls (1 when it fell before this screen saw it, so it simply lies there).
var _ko := 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	Forge.press_weight(self, 0.95)
	gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			screen.on_tile(side, r, c))
	mouse_entered.connect(func(): screen.on_hover(side, r, c))


## The unit here marches in from `from` (an offset), bobbing in step, and sparks as it lands.
func _process(delta: float) -> void:
	_t += delta
	if figure:
		queue_redraw()
	elif side == "P" and screen and not screen.view.is_empty():
		var u := screen.unit_view(side, r, c)
		if not u.is_empty() and screen.is_selected(u):
			queue_redraw()


func intro(delay: float, from: Vector2) -> void:
	if screen.unit_view(side, r, c).is_empty():
		return
	_from = from
	enter = 0.0
	queue_redraw()
	var t := create_tween()
	t.tween_interval(delay)
	t.tween_method(func(v): enter = v; queue_redraw(), 0.0, 1.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_callback(func():
		var u := screen.unit_view(side, r, c)
		Sfx.play("step", 0.12)
		Burst.on(self, Forge.ELEM.get(u.get("elem", ""), Forge.GOLD), 46, 10))


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var u := screen.unit_view(side, r, c)
	var lit := screen.is_lit(side, r, c)
	var area := screen.area_kind(side, r, c)
	var tint: Color = Forge.HARM if area == "harm" else Forge.MEND
	var threat := screen.threat_at(side, r, c)
	if figure:
		_floor(rect, u, lit, area, tint, threat)
		return
	if u.is_empty():
		draw_style_box(Forge.flat(Color(Forge.PLAQUE, 0.55), Color(Forge.BRONZE, 0.3), 1), rect)
		var fx := screen.b.effects_at(side, r, c)
		if fx.size():
			_tag(Vector2(8, 8), fx[0].label.to_lower(), Color("#ff7a3d"))
		var ghost := screen.ghost_at(side, r, c)
		if not ghost.is_empty():
			# The spot a hero will step away from: their portrait, faded, in a dashed blue frame.
			if ghost.has("portrait"):
				Forge.portrait(self, screen.tex(ghost.portrait.src), rect.grow(-6), ghost.portrait, 0.62, "tile")
				draw_rect(rect.grow(-6), Color(Forge.INK, 0.72))
			_dashed(rect.grow(-3), Color(Forge.MOVE, 0.8))
		elif screen.is_step(side, r, c):
			# Blue: where the selected hero can step.
			draw_rect(rect.grow(-2), Color(Forge.MOVE, 0.28))
			draw_rect(rect.grow(-1), Color(Forge.MOVE, 0.9), false, 2.0)
		elif area != "":
			draw_rect(rect.grow(-2), Color(tint, 0.30))
			draw_rect(rect.grow(-1), tint, false, 3.0)
		elif lit:
			draw_rect(rect.grow(-1), Color(tint if screen._armed_act().get("kind", "dmg") != "dmg" else Forge.HARM, 0.55), false, 1.5)
		if screen.aim_center(side, r, c):
			_crosshair(tint)
		if threat > 0:
			_threat(rect, threat)
		return
	if enter < 1.0:
		# Marching in: the empty tile waits underneath while the card steps in, a bob for each stride.
		draw_style_box(Forge.flat(Color(Forge.PLAQUE, 0.55), Color(Forge.BRONZE, 0.3), 1), rect)
		var k := 1.0 - enter
		var s := 0.7 + 0.3 * enter
		var bob := -absf(sin(enter * PI * 3)) * 10 * k
		draw_set_transform(size / 2 * (1 - s) + _from * k + Vector2(0, bob), 0, Vector2(s, s))
	var tex := screen.tex(u.portrait.src) if u.has("portrait") else null
	if tex:
		Forge.portrait(self, tex, rect.grow(-2), u.portrait, 0.62, "tile")
	else:
		draw_rect(rect, Color(Forge.ELEM[u.elem], 0.25))
	# Fade the lower half into ink so the name and HP read.
	var top := size.y * 0.42
	draw_polygon(PackedVector2Array([Vector2(0, top), Vector2(size.x, top), Vector2(size.x, size.y), Vector2(0, size.y)]),
		PackedColorArray([Color(Forge.INK, 0), Color(Forge.INK, 0), Color(Forge.INK, 0.92), Color(Forge.INK, 0.92)]))
	var alive: bool = u.view.alive
	var sel := screen.is_selected(u)
	var edge: Color = Forge.GOLD_LIGHT if sel else Forge.ELEM[u.elem].darkened(0.2) if side == "E" else Color(Forge.BRONZE, 0.9)
	draw_rect(rect, edge, false, 4.0 if sel else 2.0)
	if sel:
		Rim.comet(self, rect.grow(-1), Color("#fff1c4"), fposmod(_t * 0.3, 1.0), 0.2, 4.0)
	if area != "":
		draw_rect(rect.grow(-2), Color(tint, 0.26))
		draw_rect(rect.grow(-1), tint, false, 3.0)
	elif lit:
		draw_rect(rect.grow(-3), Color(Forge.HARM if screen._armed_act().get("kind", "dmg") == "dmg" else Forge.MEND, 0.7), false, 2.0)
	if threat > 0:
		_threat(rect, threat)
	# Element sigil: a black disc with a gold ring, top-left.
	var sc := Vector2(17, 17)
	draw_circle(sc, 13, Forge.INK)
	draw_arc(sc, 12, 0, TAU, 24, Forge.GOLD_DEEP, 1.5, true)
	draw_texture_rect(Forge.sigil(u.elem), Rect2(sc - Vector2(8, 8), Vector2(16, 16)), false, Forge.GOLD)
	var f := Forge.tracked(Forge.SC, 2)
	draw_string(f, Vector2(8, size.y - 20), Battle.name_of(u).to_lower(), HORIZONTAL_ALIGNMENT_LEFT, size.x - 12, 17, Forge.PARCHMENT)
	var hp: int = u.view.hp
	draw_string(Forge.SANS_BOLD, Vector2(size.x - 50, size.y - 4), str(hp), HORIZONTAL_ALIGNMENT_RIGHT, 44, 15, Forge.MUTED)
	hp_bar(self, Rect2(6, size.y - 12, size.x - 62, 5), screen.hp_fx(u.id, hp, u.max_hp), Color(Forge.INK, 0.9))
	# Statuses, top-right.
	var st: Dictionary = u.view.st
	var tags := []
	if not alive: st = {}
	if st.get("stun", 0): tags.append(["stun", Forge.GOLD_LIGHT])
	if st.get("burn", 0): tags.append(["burn %d" % st.burn, Color("#ff7a3d")])
	if st.get("shield", 0): tags.append(["shd %d" % st.shield, Color("#7cc7ff")])
	if st.get("guard", false): tags.append(["grd", Color("#9fb3c8")])
	var x := size.x - 6
	for t in tags:
		x = _tag(Vector2(x, 6), t[0], t[1], true) - 4
	# Turn order, big on the portrait, like Enchanted Arms' numbers over its units.
	var qi := screen.queue_index(u)
	if qi >= 0:
		var q := Vector2(size.x - 24, size.y * 0.5 - 4)
		Forge.diamond(self, q, 21, Forge.INK)
		Forge.diamond(self, q, 19, Forge.GOLD, false)
		draw_string_outline(Forge.SC_HEAVY, q + Vector2(-14, 10), str(qi + 1), HORIZONTAL_ALIGNMENT_CENTER, 28, 28, 4, Forge.INK)
		draw_string(Forge.SC_HEAVY, q + Vector2(-14, 10), str(qi + 1), HORIZONTAL_ALIGNMENT_CENTER, 28, 28, Forge.GOLD_LIGHT)
	# Danger view: what this foe means to do.
	var intent := screen.intent_of(u.id)
	if not intent.is_empty() and alive:
		var word: String = "stunned" if intent.stunned else intent.name.to_lower()
		_tag(Vector2(6, 34), word, Forge.MUTED if intent.stunned else (Forge.HARM if intent.kind == "dmg" else Forge.MEND))
	if screen.aim_center(side, r, c):
		_crosshair(tint)
	# Forecast: the number this tile would take, big, and a skull for a knockout.
	var pv := screen.preview_at(side, r, c)
	if not pv.is_empty():
		_preview(pv)
	if not alive:
		draw_rect(rect, Color(Forge.INK, 0.72 * _ko))
		var word := "down %d" % u.view.downed if u.view.downed > 0 else "ko"
		draw_string(Forge.tracked(Forge.SC_HEAVY, 4), Vector2(0, size.y / 2 + 8 + 14 * (1.0 - _ko)), word, HORIZONTAL_ALIGNMENT_CENTER, size.x, 24, Color(Forge.PARCHMENT, 0.7 * _ko))


## The landscape board's floor: a dark slab, a pool of light under whoever stands here (gold under the hero you're
## moving, with a comet running round it), and the same move, attack and danger lights as the card board.
func _floor(rect: Rect2, u: Dictionary, lit: bool, area: String, tint: Color, threat: int) -> void:
	# The floor shows through: a tile is only a faint slab, scored at its edges.
	draw_rect(rect, Color(Forge.PLAQUE, 0.22))
	draw_line(rect.position + Vector2(3, 1), Vector2(rect.end.x - 3, 1), Color(Forge.GOLD_LIGHT, 0.05), 1.0)
	draw_rect(rect, Color(Forge.BRONZE, 0.13), false, 1.0)
	var foot := Vector2(size.x / 2, size.y * BattleFigure.FOOT)
	if not u.is_empty() and u.view.alive:
		var sel := screen.is_selected(u)
		var col: Color = Forge.GOLD if sel else Forge.ELEM[u.elem]
		draw_set_transform(foot, 0, Vector2(1, 0.34))
		for i in 7:
			var k := 1.0 - i / 7.0
			draw_circle(Vector2.ZERO, size.x * 0.5 * k, Color(col, (0.07 if sel else 0.045)))
		draw_arc(Vector2.ZERO, size.x * 0.44, 0, TAU, 48, Color(col, 0.6 if sel else 0.3), 3.0, true)
		if sel:
			var head := fposmod(_t * 0.45, 1.0) * TAU
			for i in 14:
				var k := i / 13.0
				draw_arc(Vector2.ZERO, size.x * 0.44, head - 1.0 * (1 - k) - 0.08, head - 1.0 * (1 - k), 4, Color("#fff1c4", k), 3.0, true)
		draw_set_transform(Vector2.ZERO)
	var ghost := screen.ghost_at(side, r, c)
	if u.is_empty() and not ghost.is_empty():
		_dashed(rect.grow(-3), Color(Forge.MOVE, 0.8))
	elif u.is_empty() and screen.is_step(side, r, c):
		_glow(rect, Forge.MOVE, 0.16)
	elif area != "":
		_glow(rect, tint, 0.2)
	elif lit:
		# Setting the formation lights where a hero may stand in gold; otherwise lit means aimable.
		var lc: Color = Forge.GOLD_DEEP if screen.b.phase == "form" else (tint if screen._armed_act().get("kind", "dmg") != "dmg" else Forge.HARM)
		draw_rect(rect.grow(-1), Color(lc, 0.5), false, 1.5)
	if u.is_empty():
		var fx := screen.b.effects_at(side, r, c)
		if fx.size():
			_tag(Vector2(8, 8), fx[0].label.to_lower(), Color("#ff7a3d"))
	if screen.aim_center(side, r, c):
		_crosshair(tint)
	if threat > 0:
		_threat(rect, threat)


## Light cast on the floor: brightest at the tile's edge, fading toward its middle.
func _glow(rect: Rect2, col: Color, a: float) -> void:
	draw_rect(rect.grow(-1), Color(col, a))
	draw_rect(rect.grow(-4), Color(col, a * 0.6), false, 6.0)
	draw_rect(rect.grow(-1), Color(col, 0.8), false, 1.5)


## The forecast number over a unit: red for damage, green for healing or shield; the one in the bar gets a frame.
func _preview(pv: Dictionary) -> void:
	var dmg: bool = pv.kind == "dmg"
	var col: Color = Forge.HARM if dmg else Forge.MEND
	var txt: String = "+%d" % pv.shield if pv.kind == "shield" else "%+d" % (pv.after - pv.before)
	var f := Forge.tracked(Forge.SC_HEAVY, 1)
	var px := 30
	var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x + 18
	var box := Rect2((size.x - w) / 2, size.y * 0.5 - 26, w, 38)
	draw_rect(box, Color(Forge.INK, 0.86))
	draw_rect(box, col if pv.current else Color(col, 0.5), false, 3.0 if pv.current else 1.5)
	draw_string(f, box.position + Vector2(9, 29), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, px, col.lightened(0.15))
	if pv.ko:
		skull(self, Vector2(box.end.x + 14, box.position.y + 19))


## A small skull: the forecast says this hit knocks the unit out.
static func skull(ci: CanvasItem, cpt: Vector2, k := 1.0) -> void:
	ci.draw_circle(cpt, 12 * k, Forge.INK)
	ci.draw_circle(cpt + Vector2(0, -2) * k, 9 * k, Forge.PARCHMENT)
	ci.draw_rect(Rect2(cpt + Vector2(-5, 4) * k, Vector2(10, 6) * k), Forge.PARCHMENT)
	ci.draw_circle(cpt + Vector2(-3.5, -2) * k, 2.6 * k, Forge.INK)
	ci.draw_circle(cpt + Vector2(3.5, -2) * k, 2.6 * k, Forge.INK)


## The aimed tile: corner brackets in the action's colour.
func _crosshair(col: Color) -> void:
	var l := 16.0
	var g := 5.0
	for cn in [[Vector2(g, g), Vector2(1, 1)], [Vector2(size.x - g, g), Vector2(-1, 1)], [Vector2(g, size.y - g), Vector2(1, -1)], [Vector2(size.x - g, size.y - g), Vector2(-1, -1)]]:
		var o: Vector2 = cn[0]
		var d: Vector2 = cn[1]
		draw_polyline(PackedVector2Array([o + Vector2(0, l * d.y), o, o + Vector2(l * d.x, 0)]), col.lightened(0.25), 4.0)


## Danger view: a tile a foe means to hit wears red hatching, with the count when more than one.
func _threat(rect: Rect2, n: int) -> void:
	var col := Color(Forge.HARM, 0.55)
	var step := 16.0
	var x := -size.y
	while x < size.x:
		var a := Vector2(maxf(x, 0), maxf(0, -x))
		var b := Vector2(minf(x + size.y, size.x), minf(size.y, size.x - x))
		draw_line(a, b, Color(col, 0.35), 2.0)
		x += step
	draw_rect(rect.grow(-1), col, false, 2.0)
	if n > 1:
		_tag(Vector2(size.x - 6, size.y - 26), "×%d" % n, Forge.HARM, true)


## A small status tag. Anchored at its left edge, or its right edge when `from_right`; returns the far edge's x.
func _tag(at: Vector2, text: String, color: Color, from_right := false) -> float:
	var f := Forge.tracked(Forge.SC, 1)
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 10
	var x := at.x - w if from_right else at.x
	draw_rect(Rect2(x, at.y, w, 20), Color(Forge.INK, 0.85))
	draw_rect(Rect2(x, at.y, w, 20), Color(color, 0.7), false, 1.0)
	draw_string(f, Vector2(x + 5, at.y + 15), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
	return x if from_right else x + w


## A health bar: the bar itself, the pale chunk a hit just took (it hangs, then drains) and, while a heal fills it,
## a bright edge where it is rising to. `fx` is BattleScreen.hp_fx.
static func hp_bar(ci: CanvasItem, bar: Rect2, fx: Dictionary, ground: Color) -> void:
	ci.draw_rect(bar, ground)
	var w := bar.size.x
	if fx.lag > fx.lead:
		ci.draw_rect(Rect2(bar.position + Vector2(w * fx.lead, 0), Vector2(w * (fx.lag - fx.lead), bar.size.y)), Color("#f6e3b4"))
	if fx.gain:
		ci.draw_rect(Rect2(bar.position, Vector2(w * fx.target, bar.size.y)), Color(Forge.MEND, 0.35))
	var low: bool = fx.target < 0.35
	ci.draw_rect(Rect2(bar.position, Vector2(w * fx.lead, bar.size.y)), HP_LOW if low else Forge.GAIN)


## Taking a blow: the card jolts and settles (a heavy one jolts harder). A fighter on the tile staggers instead.
func recoil(heavy := false) -> void:
	if figure:
		figure.recoil(heavy)
		return
	pivot_offset = size / 2
	var t := create_tween()
	t.tween_property(self, "scale", Vector2.ONE * (0.88 if heavy else 0.93), 0.05)
	t.tween_property(self, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## The unit here has just fallen: it goes down over a moment rather than at once.
func fall() -> void:
	if figure:
		figure.fall()
		return
	_ko = 0.0
	var t := create_tween()
	t.tween_method(func(v): _ko = v; queue_redraw(), 0.0, 1.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	Burst.on(self, Color("#8a8178"), 50, 12)


func flash() -> void:
	if figure:
		figure.flash()
		return
	var t := create_tween()
	t.tween_property(self, "modulate", Color(1.5, 1.4, 1.15), 0.08)
	t.tween_property(self, "modulate", Color.WHITE, 0.22)


## A number or word rising off the tile and fading.
func float_text(text: String, cls: String) -> void:
	if figure and not screen.unit_view(side, r, c).is_empty():
		figure.float_text(text, cls)
		return
	pop_text(self, text, cls, Vector2(0, size.y / 2 - 30), size.x, 30, 44)


## A number or word that punches in large, settles to size and rises away: bigger and with a shudder on a weak spot.
## Each one lands a little off-centre, so numbers landing together don't sit on top of each other.
static func pop_text(parent: Control, text: String, cls: String, at: Vector2, width: float, px: int, rise: float) -> void:
	var heavy := cls == "crit"
	var l := Forge.sc(text, roundi(px * (1.3 if heavy else 1.0)), FLOAT_COLORS.get(cls, Forge.PARCHMENT), true, 0.04)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(width, px * 1.6)
	l.position = at + Vector2(randf_range(-14, 14), -8 if heavy else 0)
	l.pivot_offset = l.size / 2
	l.scale = Vector2.ONE * (2.0 if heavy else 1.55)
	l.add_theme_color_override("font_outline_color", Forge.INK)
	l.add_theme_constant_override("outline_size", 10 if heavy else 8)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	var t := l.create_tween()
	t.tween_property(l, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if heavy:
		for i in 3:
			t.tween_property(l, "rotation", 0.06 * (1 if i % 2 == 0 else -1), 0.04)
		t.tween_property(l, "rotation", 0.0, 0.04)
	t.tween_interval(0.18)
	t.tween_property(l, "position:y", l.position.y - rise, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.55).set_delay(0.15)
	t.tween_callback(l.queue_free)


## A dashed frame, for tiles a hero can step to or will leave.
func _dashed(r: Rect2, color: Color) -> void:
	var pts := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
	for i in 4:
		draw_dashed_line(pts[i], pts[i + 1], color, 2.0, 8.0)
