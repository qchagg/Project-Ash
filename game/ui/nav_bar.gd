class_name NavBar
extends RefCounted
## Roster · Squad · Town · Battle · Codex, at the foot of every top-level screen. Town, the home of meta-progression,
## sits raised in the centre on a medallion. Codex holds lore and settings.

const TABS := [["roster", "tab_roster"], ["squad", "tab_squad"], ["town", "tab_town"], ["battle", "tab_battle"], ["codex", "tab_codex"]]


static func make(app: App, active: String) -> Control:
	var bar := PanelContainer.new()
	var s := Forge.flat(Forge.PLAQUE_DEEP)
	s.border_width_top = 2
	s.border_color = Color(Forge.GOLD_DEEP, 0.7)
	bar.add_theme_stylebox_override("panel", s)
	bar.custom_minimum_size.y = 136
	var h := Forge.hbox(0)
	bar.add_child(h)
	for t in TABS:
		var on: bool = t[0] == active
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.tooltip_text = t[0].capitalize()
		b.pressed.connect(func(): app.show_tab(t[0]))
		h.add_child(b)
		var v := Forge.vbox(8)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.set_anchors_preset(Control.PRESET_FULL_RECT)
		v.alignment = BoxContainer.ALIGNMENT_END if t[0] == "town" else BoxContainer.ALIGNMENT_CENTER
		b.add_child(v)
		var col: Color = Forge.GOLD_LIGHT if on else Color(Forge.DIM, 0.75)
		if t[0] == "town":
			# The medallion rises above the bar; its glyph is drawn on it.
			var m := Control.new()
			m.custom_minimum_size = Vector2(0, 40)
			m.mouse_filter = Control.MOUSE_FILTER_IGNORE
			m.draw.connect(func():
				var c := Vector2(m.size.x / 2, -14)
				m.draw_circle(c, 56, Forge.INK)
				m.draw_circle(c, 52, Forge.GOLD_LIGHT if on else Forge.GOLD_DEEP)
				m.draw_circle(c, 49, Forge.PLAQUE_DEEP)
				m.draw_arc(c, 43, 0, TAU, 48, Color(Forge.GOLD, 0.35), 1.5, true)
				m.draw_texture_rect(Forge.icon("tab_town"), Rect2(c - Vector2(26, 26), Vector2(52, 52)), false, Forge.GOLD))
			v.add_child(m)
			var tl := Forge.sc("town", 20, Forge.GOLD)
			tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(tl)
			var pad := Control.new()
			pad.custom_minimum_size.y = 22
			pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
			v.add_child(pad)
		else:
			var g := Forge.glyph(t[1], 40, col)
			g.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			v.add_child(g)
			var l := Forge.sc(t[0], 20, col)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			v.add_child(l)
		if on and t[0] != "town":
			v.draw.connect(func(): Forge.diamond(v, Vector2(v.size.x / 2, -2), 9, Forge.GOLD))
	return bar
