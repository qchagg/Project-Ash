class_name BattleTile
extends Control
## One tile of a battle grid: the unit standing there as a small card (portrait, sigil, name, HP, statuses), or an
## empty tile. Lit when it can be aimed at; flashes and floats numbers when the fight touches it. Draws from the
## screen's current view of the board, so playback can show each beat.

const HP_LOW := Color("#e86a5a")
const FLOAT_COLORS := {"crit": Color("#ffb347"), "resist": Color("#cbbd9f"), "hurt": Color("#f3e6c4"), "blocked": Color("#9fb3c8"),
	"mend": Color("#a9dd92"), "shield": Color("#7cc7ff"), "burn": Color("#ff7a3d"), "stun": Color("#f6dc94")}

var screen: BattleScreen
var side := "P"
var r := 0
var c := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			screen.on_tile(side, r, c))


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var u := screen.unit_view(side, r, c)
	var lit := screen.is_lit(side, r, c)
	var area := screen.in_area(side, r, c)
	if u.is_empty():
		draw_style_box(Forge.flat(Color(Forge.PLAQUE, 0.55), Color(Forge.BRONZE, 0.3), 1), rect)
		var fx := screen.b.effects_at(side, r, c)
		if fx.size():
			_tag(Vector2(8, 8), fx[0].label.to_lower(), Color("#ff7a3d"))
		if lit:
			draw_rect(rect.grow(-2), Color(Forge.GOLD, 0.10))
			draw_rect(rect, Forge.GOLD, false, 2.0)
			Forge.diamond(self, size / 2, 8, Color(Forge.GOLD, 0.8), false)
		return
	var tex := screen.tex(u.portrait.src) if u.has("portrait") else null
	if tex:
		Forge.portrait(self, tex, rect.grow(-2), u.portrait)
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
	if area:
		draw_rect(rect.grow(-2), Color(Forge.GOLD, 0.16))
	if lit:
		draw_rect(rect.grow(-3), Forge.GOLD, false, 2.0)
	# Element sigil: a black disc with a gold ring, top-left.
	var sc := Vector2(17, 17)
	draw_circle(sc, 13, Forge.INK)
	draw_arc(sc, 12, 0, TAU, 24, Forge.GOLD_DEEP, 1.5, true)
	draw_texture_rect(Forge.sigil(u.elem), Rect2(sc - Vector2(8, 8), Vector2(16, 16)), false, Forge.GOLD)
	var f := Forge.tracked(Forge.SC, 2)
	draw_string(f, Vector2(8, size.y - 20), Battle.name_of(u).to_lower(), HORIZONTAL_ALIGNMENT_LEFT, size.x - 12, 17, Forge.PARCHMENT)
	var hp: int = u.view.hp
	draw_string(Forge.SANS_BOLD, Vector2(size.x - 50, size.y - 4), str(hp), HORIZONTAL_ALIGNMENT_RIGHT, 44, 15, Forge.MUTED)
	var bar := Rect2(6, size.y - 12, size.x - 62, 5)
	draw_rect(bar, Color(Forge.INK, 0.9))
	var pct := clampf(float(hp) / u.max_hp, 0, 1)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * pct, bar.size.y)), HP_LOW if pct < 0.35 else Forge.GAIN)
	# Statuses, top-right, newest rule first.
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
	# Queue order for planned heroes.
	var qi := screen.queue_index(u)
	if qi >= 0:
		var q := Vector2(size.x - 16, size.y * 0.5 - 6)
		Forge.diamond(self, q, 14, Forge.INK)
		Forge.diamond(self, q, 13, Forge.GOLD, false)
		draw_string(Forge.SANS_BOLD, q + Vector2(-10, 6), str(qi + 1), HORIZONTAL_ALIGNMENT_CENTER, 20, 16, Forge.GOLD_LIGHT)
	var edge_note := screen.edge_note(u)
	if edge_note != "":
		_tag(Vector2(36, 6), edge_note, Forge.GAIN if edge_note == "weak" else Forge.MUTED)
	if not alive:
		draw_rect(rect, Color(Forge.INK, 0.72))
		var word := "down %d" % u.view.downed if u.view.downed > 0 else "ko"
		draw_string(Forge.tracked(Forge.SC_HEAVY, 4), Vector2(0, size.y / 2 + 8), word, HORIZONTAL_ALIGNMENT_CENTER, size.x, 24, Color(Forge.PARCHMENT, 0.7))


## A small status tag. Anchored at its left edge, or its right edge when `from_right`; returns the far edge's x.
func _tag(at: Vector2, text: String, color: Color, from_right := false) -> float:
	var f := Forge.tracked(Forge.SC, 1)
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 10
	var x := at.x - w if from_right else at.x
	draw_rect(Rect2(x, at.y, w, 20), Color(Forge.INK, 0.85))
	draw_rect(Rect2(x, at.y, w, 20), Color(color, 0.7), false, 1.0)
	draw_string(f, Vector2(x + 5, at.y + 15), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
	return x if from_right else x + w


func flash() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate", Color(1.5, 1.4, 1.15), 0.08)
	t.tween_property(self, "modulate", Color.WHITE, 0.22)


## A number or word rising off the tile and fading.
func float_text(text: String, cls: String) -> void:
	var l := Forge.sc(text, 30, FLOAT_COLORS.get(cls, Forge.PARCHMENT), true, 0.04)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(size.x, 40)
	l.position = Vector2(0, size.y / 2 - 30)
	l.add_theme_color_override("font_outline_color", Forge.INK)
	l.add_theme_constant_override("outline_size", 8)
	add_child(l)
	var t := create_tween().set_parallel()
	t.tween_property(l, "position:y", l.position.y - 44, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.3)
	t.chain().tween_callback(l.queue_free)
