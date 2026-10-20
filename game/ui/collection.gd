extends Control
## The Collection screen: every card, with merging and the Ashcrown.
## Tap a card to make it the base, tap a second card of the same stars to feed it, then Merge.

const GOLD := Color("#e3c278")
const GOLD_DEEP := Color("#c9a24f")
const PARCHMENT := Color("#ece0c4")
const INK := Color("#120e0a")
const CINZEL := preload("res://fonts/cinzel-black.woff")
const CORMORANT_I := preload("res://fonts/cormorant-bold-italic.woff")
const SANS := preload("res://fonts/alegreya-sans-medium.woff")
const SANS_BOLD := preload("res://fonts/alegreya-sans-bold.woff")
const SANS_SC := preload("res://fonts/alegreya-sans-sc-bold.woff")
# The text fonts have no ★; this subset of Noto Sans Symbols 2 fills in ★ ✦ → ◆.
const SYMBOLS := preload("res://fonts/symbols.woff")

var col := Collection.new()
var base := ""
var fodder := ""

var _grid: GridContainer
var _counts: Label
var _info: RichTextLabel
var _status: Label
var _merge: Button
var _crown: Button
var _field: Button


func _ready() -> void:
	for f in [CINZEL, CORMORANT_I, SANS, SANS_BOLD, SANS_SC, CardTile.CORMORANT]:
		f.fallbacks = [SYMBOLS]
	var bg := ColorRect.new()
	bg.color = INK
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	var head := MarginContainer.new()
	_margins(head, 28, 36, 28, 10)
	root.add_child(head)
	var hv := VBoxContainer.new()
	head.add_child(hv)
	hv.add_child(_label("Collection", CINZEL, 50, GOLD))
	hv.add_child(_label("Tap a base, then a card of the same stars to feed it.", CORMORANT_I, 24, Color(PARCHMENT, 0.8)))
	_counts = _label("", SANS_SC, 19, Color(PARCHMENT, 0.75))
	hv.add_child(_counts)
	root.add_child(_rule())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var pad := MarginContainer.new()
	_margins(pad, 20, 22, 20, 22)
	pad.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(pad)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 22)
	_grid.add_theme_constant_override("v_separation", 26)
	pad.add_child(_grid)

	root.add_child(_rule())
	var foot := PanelContainer.new()
	var fs := StyleBoxFlat.new()
	fs.bg_color = Color("#1a140e")
	fs.content_margin_left = 28; fs.content_margin_right = 28; fs.content_margin_top = 16; fs.content_margin_bottom = 26
	foot.add_theme_stylebox_override("panel", fs)
	root.add_child(foot)
	var fv := VBoxContainer.new()
	fv.add_theme_constant_override("separation", 10)
	foot.add_child(fv)
	_info = RichTextLabel.new()
	_info.bbcode_enabled = true
	_info.fit_content = true
	_info.scroll_active = false
	_info.custom_minimum_size.y = 150
	_info.add_theme_font_override("normal_font", SANS)
	_info.add_theme_font_override("bold_font", SANS_BOLD)
	_info.add_theme_font_size_override("normal_font_size", 21)
	_info.add_theme_font_size_override("bold_font_size", 21)
	_info.add_theme_color_override("default_color", PARCHMENT)
	fv.add_child(_info)
	_status = _label("", CORMORANT_I, 22, GOLD)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fv.add_child(_status)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	fv.add_child(row)
	_merge = _button("Merge", true, _on_merge)
	_crown = _button("Ashcrown", false, _on_crown)
	_field = _button("Field", false, _on_field)
	row.add_child(_merge)
	row.add_child(_crown)
	row.add_child(_field)

	_rebuild()


func _rebuild() -> void:
	for c in _grid.get_children():
		c.queue_free()
	for c in col.cards:
		var t := CardTile.new()
		t.setup(c)
		t.pressed.connect(_on_card)
		_grid.add_child(t)
	_refresh()


func _refresh() -> void:
	for t in _grid.get_children():
		if t.is_queued_for_deletion():
			continue
		t.role = "base" if t.card.uid == base else ("fodder" if t.card.uid == fodder else "")
		t.on_field = t.card.uid in col.squad
		t.queue_redraw()
	_counts.text = "%d cards  ·  %d on the field  ·  ashcrowns %d  ·  loose augments %d" % [col.cards.size(), col.squad.size(), col.crowns, col.loose.size()]
	_info.text = _describe()
	var b := col.by(base)
	_merge.disabled = not _merge_check().ok
	_crown.disabled = b.is_empty() or b.stars != 3 or col.crowns < 1
	_field.disabled = b.is_empty() or fodder != ""
	_field.text = "Bench" if base in col.squad else "Field"


func _describe() -> String:
	var b := col.by(base)
	if b.is_empty():
		return "[color=#ece0c4aa]No card chosen.[/color]"
	var h := Data.hero(b.hero)
	var s := col.stats(b)
	var out := "[b]%s %d★[/b]  ·  HP %d  ATK %d  DEF %d  SPD %d\n" % [h.name, b.stars, s.max_hp, s.atk, s.def, s.spd]
	for sk in col.skills(b):
		out += "[color=#e3c278]%s[/color]  [color=#ece0c4aa]CD %d[/color]\n" % [sk.name, sk.cd]
	var m := _merge_check()
	if m.ok:
		var after: Dictionary = m.preview.after
		out += "[b]Merge →[/b] %d★  HP %d  ATK %d  DEF %d  SPD %d" % [b.stars + 1, after.max_hp, after.atk, after.def, after.spd]
		if m.preview.carried: out += "  ·  carries " + ", ".join(m.preview.carried)
		if m.preview.loose: out += "  ·  loose " + ", ".join(m.preview.loose)
	return out


# Tries the merge on a copy, so the panel can preview it and the button knows whether it would work.
func _merge_check() -> Dictionary:
	if base == "" or fodder == "":
		return {"ok": false}
	var copy := Collection.new()
	copy.cards = col.cards.duplicate(true)
	copy.loose = col.loose.duplicate()
	copy.squad = col.squad.duplicate()
	copy.merge_mode = col.merge_mode
	var r := copy.merge(base, fodder)
	return {"ok": r.ok, "msg": r.get("msg", ""), "preview": r}


func _on_card(uid: String) -> void:
	if uid == base:
		base = ""
		fodder = ""
	elif uid == fodder:
		fodder = ""
	elif base == "":
		base = uid
	else:
		fodder = uid
	var m := _merge_check()
	_status.text = m.get("msg", "") if fodder != "" and not m.ok else ""
	_refresh()


func _on_merge() -> void:
	var name: String = Data.hero(col.by(base).hero).name
	var r := col.merge(base, fodder)
	fodder = ""
	_status.text = "%s rises to %d★." % [name, col.by(base).stars] if r.ok else r.msg
	_rebuild()


func _on_crown() -> void:
	if col.crown(base):
		_status.text = "The Ashcrown takes %s to 4★." % Data.hero(col.by(base).hero).name
	_rebuild()


func _on_field() -> void:
	var msg := col.toggle_field(base)
	_status.text = msg
	_refresh()


func _label(text: String, font: Font, px: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", px)
	l.add_theme_color_override("font_color", color)
	return l


# The double gold rule from the menus.
func _rule() -> Control:
	var r := Control.new()
	r.custom_minimum_size.y = 7
	r.draw.connect(func():
		r.draw_line(Vector2(0, 1), Vector2(r.size.x, 1), GOLD, 2.0)
		r.draw_line(Vector2(0, 6), Vector2(r.size.x, 6), Color(GOLD_DEEP, 0.6), 1.0))
	return r


func _button(text: String, primary: bool, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 64)
	b.size_flags_horizontal = SIZE_EXPAND_FILL
	b.add_theme_font_override("font", CINZEL)
	b.add_theme_font_size_override("font_size", 24)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var s := StyleBoxFlat.new()
		s.bg_color = GOLD if primary else Color("#2a2016")
		s.border_color = GOLD
		s.set_border_width_all(2)
		s.set_corner_radius_all(4)
		if state == "hover": s.bg_color = s.bg_color.lightened(0.12)
		if state == "pressed": s.bg_color = s.bg_color.darkened(0.15)
		if state == "disabled": s.bg_color = Color("#2a2016", 0.5); s.border_color = Color(GOLD, 0.25)
		if state == "focus": s.draw_center = false
		b.add_theme_stylebox_override(state, s)
	b.add_theme_color_override("font_color", INK if primary else GOLD)
	b.add_theme_color_override("font_hover_color", INK if primary else GOLD)
	b.add_theme_color_override("font_pressed_color", INK if primary else GOLD)
	b.add_theme_color_override("font_disabled_color", Color(PARCHMENT, 0.3))
	b.pressed.connect(cb)
	return b


func _margins(m: MarginContainer, l: int, t: int, r: int, b: int) -> void:
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_bottom", b)
