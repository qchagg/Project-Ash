class_name NavBar
extends RefCounted
## Heroes · Expedition · Town: three places, one job each. Expedition, the thing you do most, sits raised in the middle
## on a medallion whose ring is always turning; Heroes is who you have, Town is what you build (the Archive, the
## Infirmary and the rest are inside it). On a wide screen the bar stands up as a rail down the left edge.

const TABS := [["heroes", "tab_roster"], ["expedition", "tab_expedition"], ["town", "tab_town"]]
const BAR_H := 136.0
const RAIL_W := 176.0


static func make(app: App, active: String) -> Control:
	var wide := Forge.wide()
	var bar := PanelContainer.new()
	var s := Forge.flat(Forge.PLAQUE_DEEP)
	if wide:
		s.border_width_right = 2
	else:
		s.border_width_top = 2
	s.border_color = Color(Forge.GOLD_DEEP, 0.7)
	bar.add_theme_stylebox_override("panel", s)
	if wide:
		bar.custom_minimum_size.x = RAIL_W
	else:
		bar.custom_minimum_size.y = BAR_H
	var box: BoxContainer = Forge.vbox(0) if wide else Forge.hbox(0)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_child(box)
	for t in TABS:
		box.add_child(_tab(app, t[0], t[1], t[0] == active, wide))
	return bar


static func _tab(app: App, key: String, glyph_name: String, on: bool, wide: bool) -> Control:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.tooltip_text = key.capitalize()
	if wide:
		b.custom_minimum_size = Vector2(NavBar.RAIL_W, 220 if key == "expedition" else 170)
	else:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(func(): app.show_tab(key))
	Forge.press_weight(b, 0.95)
	var v := Forge.vbox(10)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.add_child(v)
	var col: Color = Forge.GOLD_LIGHT if on else Color(Forge.DIM, 0.8)
	if key == "expedition":
		# The medallion: a disc that rises out of the bar, its ring turning, brighter when you are on the road.
		var m := Control.new()
		m.custom_minimum_size = Vector2(112, 112) if wide else Vector2(112, 72)
		m.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		m.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var lift := 0.0 if wide else -26.0
		m.draw.connect(func():
			var c := Vector2(m.size.x / 2, m.size.y / 2 + lift)
			m.draw_circle(c, 58, Forge.INK)
			m.draw_circle(c, 54, Forge.PLAQUE_DEEP)
			m.draw_texture_rect(Forge.icon("tab_expedition"), Rect2(c - Vector2(30, 30), Vector2(60, 60)), false, Forge.GOLD_LIGHT if on else Forge.GOLD))
		v.add_child(m)
		var ring := Ring.new()
		ring.on = on
		ring.lift = lift
		ring.set_anchors_preset(Control.PRESET_FULL_RECT)
		m.add_child(ring)
	else:
		var g := Forge.glyph(glyph_name, 42, col)
		g.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(g)
	var l := Forge.sc(key, 20, Forge.GOLD if key == "expedition" else col, key == "expedition" or on)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(l)
	if on and key != "expedition":
		# The current tab: a gold bar along the edge the bar meets the screen on.
		b.draw.connect(func():
			if wide:
				b.draw_rect(Rect2(b.size.x - 4, b.size.y * 0.3, 4, b.size.y * 0.4), Forge.GOLD)
			else:
				b.draw_rect(Rect2(b.size.x * 0.3, 0, b.size.x * 0.4, 4), Forge.GOLD))
	return b


## The medallion's ring: a gold circle with a bright comet running round it, quicker on the current tab.
class Ring extends Control:
	var on := false
	var lift := 0.0
	var _t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var c := Vector2(size.x / 2, size.y / 2 + lift)
		draw_arc(c, 55, 0, TAU, 64, Color(Forge.GOLD_DEEP, 0.9 if on else 0.55), 2.5, true)
		var head := fposmod(_t * (0.45 if on else 0.2), 1.0) * TAU
		for i in 18:
			var k := i / 17.0
			draw_arc(c, 55, head - 1.1 * (1.0 - k) - 0.07, head - 1.1 * (1.0 - k), 4, Color(Forge.GOLD_LIGHT, k * (0.95 if on else 0.6)), 3.5, true)
		draw_circle(c + Vector2(cos(head), sin(head)) * 55, 3.5, Forge.GOLD_LIGHT)
		draw_arc(c, 47, 0, TAU, 48, Color(Forge.GOLD, 0.3), 1.5, true)
