class_name GracesScreen
extends Control
## The Graces of Mehfil in a row, dim; the chosen one steps forward, lit, with her lore and blessing beside her.
## A wide screen puts the words on the left and the row across the rest; a phone, too narrow for five tall figures,
## stands the chosen one large above a small row of all five, with her words below.
## The figures ship beside the page (see Clips), so each one appears when it arrives.

## A slow band of light passing down the chosen Grace's gold.
const SHINE := """
shader_type canvas_item;
uniform float lit = 0.0;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float d = (UV.x * 0.4 + UV.y) - (fract(TIME * 0.12) * 2.4 - 0.7);
	float band = exp(-d * d * 40.0) * lit;
	COLOR = vec4(c.rgb * (1.0 + band * 0.9) * COLOR.rgb, c.a * COLOR.a);
}
"""
## How the ones not chosen stand back.
const DIMMED := Color(0.34, 0.34, 0.34, 0.8)
## Heights in the row, as a share of the stage: the chosen one, then the rest.
const TALL := 0.94
const SHORT := 0.7
## On a phone, the small row's height as a share of the stage.
const ROW := 0.24
const NAMES_H := 40.0
const STEP := 0.35

static var _shader: Shader

var app: App
var tab := "menu"
var at := 2
var _stage: Control
var _figures: Array[TextureRect] = []
var _names: Array[Label] = []
## The phone's large figure of the chosen one.
var _hero: TextureRect
var _pool: TextureRect
var _name: Label
var _title: Label
var _sigil: TextureRect
var _lore: Label
var _blessing: Label
var _crest: TextureRect


func setup(a: App) -> GracesScreen:
	app = a
	return self


func _ready() -> void:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHINE
	_pool = Forge.wash(Color(Forge.GOLD_DEEP, 0.16), Vector2(0.5, 0.55), Vector2(0.5, 0.0), true)
	add_child(_pool)
	var m := Forge.margins(MarginContainer.new(), 56, 30, 56, 20) if Forge.wide() else Forge.margins(MarginContainer.new(), 28, 30, 28, 24)
	add_child(m)
	m.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var box: BoxContainer = Forge.hbox(40) if Forge.wide() else Forge.vbox(18)
	m.add_child(box)
	var words := _words()
	_stage = Control.new()
	_stage.size_flags_horizontal = SIZE_EXPAND_FILL
	_stage.size_flags_vertical = SIZE_EXPAND_FILL
	_stage.resized.connect(_lay.bind(false))
	for i in Graces.LIST.size():
		_stage.add_child(_figure(i))
	if not Forge.wide():
		_hero = TextureRect.new()
		_hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_hero.mouse_filter = MOUSE_FILTER_IGNORE
		_hero.material = ShaderMaterial.new()
		(_hero.material as ShaderMaterial).shader = _shader
		(_hero.material as ShaderMaterial).set_shader_parameter("lit", 1.0)
		_stage.add_child(_hero)
	if Forge.wide():
		box.add_child(words)
		box.add_child(_stage)
	else:
		words.size_flags_vertical = SIZE_SHRINK_END
		box.add_child(_header())
		box.add_child(_stage)
		box.add_child(words)
	_choose(at)


## The order's crest and name.
func _header() -> Control:
	var h := Forge.hbox(14)
	_crest = TextureRect.new()
	_crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_crest.custom_minimum_size = Vector2(44, 72)
	h.add_child(_crest)
	var t := Forge.sc("The Graces of Mehfil", 22, Forge.DIM)
	t.size_flags_vertical = SIZE_SHRINK_CENTER
	h.add_child(t)
	return h


## The chosen Grace's name, title, lore and blessing.
func _words() -> Control:
	var v := Forge.vbox(10)
	v.custom_minimum_size.x = 420 if Forge.wide() else 0
	if Forge.wide():
		v.add_child(_header())
		var gap := Control.new()
		gap.custom_minimum_size.y = 90
		v.add_child(gap)
	_name = Forge.sc("", 64 if Forge.wide() else 54, Forge.GOLD_LIGHT, true, 0.06)
	v.add_child(_name)
	var t := Forge.hbox(10)
	_sigil = TextureRect.new()
	_sigil.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sigil.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sigil.custom_minimum_size = Vector2(26, 26)
	_sigil.size_flags_vertical = SIZE_SHRINK_CENTER
	t.add_child(_sigil)
	_title = Forge.sc("", 26, Forge.GOLD)
	t.add_child(_title)
	v.add_child(t)
	v.add_child(Forge.rule())
	_lore = Forge.label("", 22, Forge.DIM, Forge.SANS_ITALIC)
	_lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_lore)
	var gap2 := Control.new()
	gap2.custom_minimum_size.y = 12
	v.add_child(gap2)
	v.add_child(Forge.sc("Her blessing", 18, Forge.GOLD))
	_blessing = Forge.label("", 22, Forge.PARCHMENT)
	_blessing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_blessing)
	var soon := Forge.label("Shrines on the road will offer it.", 17, Forge.LABEL, Forge.SANS_ITALIC)
	v.add_child(soon)
	return v


## One Grace in the row, and her name under it; touching either chooses her.
func _figure(i: int) -> Control:
	var f := TextureRect.new()
	f.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	f.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	f.pivot_offset = Vector2.ZERO
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	f.material = mat
	f.gui_input.connect(_tapped.bind(i))
	_figures.append(f)
	var n := Forge.sc(Graces.LIST[i].name, 20, Forge.DIM)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.mouse_filter = MOUSE_FILTER_STOP
	n.gui_input.connect(_tapped.bind(i))
	_names.append(n)
	_stage.add_child(n)
	return f


func _tapped(e: InputEvent, i: int) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed and i != at:
		Sfx.play("page")
		_choose(i)


func _choose(i: int) -> void:
	at = i
	var g: Dictionary = Graces.LIST[i]
	_name.text = g.name.to_lower()
	_title.text = g.title.to_lower()
	_sigil.visible = g.elem != ""
	if g.elem != "":
		_sigil.texture = Forge.sigil(g.elem)
		_sigil.modulate = Forge.ELEM[g.elem]
	_lore.text = g.lore
	_blessing.text = g.blessing
	for j in _names.size():
		_names[j].add_theme_color_override("font_color", Forge.GOLD_LIGHT if j == i else Forge.DIM)
		(_figures[j].material as ShaderMaterial).set_shader_parameter("lit", 1.0 if j == i else 0.0)
	if _hero:
		_hero.texture = _figures[i].texture
		_hero.modulate.a = 0.0
		create_tween().tween_property(_hero, "modulate:a", 1.0, STEP)
	_lay(true)


## Spreads the row across the stage, the chosen one tall and lit, the rest shorter and dim, all standing on one line.
func _lay(tween: bool) -> void:
	if _stage == null or _stage.size.x <= 0:
		return
	var n := Graces.LIST.size()
	var slot := _stage.size.x / n
	var floor_y := _stage.size.y - NAMES_H
	var t: Tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT) if tween else null
	for j in n:
		var f := _figures[j]
		# The rect takes the figure's own shape, so her feet are on the line; a narrow slot makes her shorter, not thinner.
		var shape := f.texture.get_size().aspect() if f.texture else 0.5
		var h := floor_y * (ROW if _hero else TALL if j == at else SHORT)
		var w := minf(h * shape, slot * (1.05 if _hero or j != at else 1.7))
		h = w / shape
		var r := Rect2(clampf(slot * (j + 0.5) - w / 2.0, 0.0, _stage.size.x - w), floor_y - h, w, h)
		var tint := Color.WHITE if j == at else DIMMED
		if t:
			t.tween_property(f, "position", r.position, STEP)
			t.tween_property(f, "size", r.size, STEP)
			t.tween_property(f, "modulate", tint, STEP)
		else:
			f.position = r.position
			f.size = r.size
			f.modulate = tint
		_names[j].position = Vector2(slot * j, floor_y + 6)
		_names[j].size = Vector2(slot, NAMES_H - 6)
	if _hero:
		var shape := _hero.texture.get_size().aspect() if _hero.texture else 0.5
		var hh := floor_y * (1.0 - ROW) - 24.0
		var hw := minf(hh * shape, _stage.size.x * 0.9)
		hh = hw / shape
		_hero.position = Vector2((_stage.size.x - hw) / 2.0, floor_y * (1.0 - ROW) - 24.0 - hh)
		_hero.size = Vector2(hw, hh)
	if _pool:
		var gt := _pool.texture as GradientTexture2D
		var cx := (_stage.global_position.x - global_position.x + slot * (at + 0.5)) / maxf(size.x, 1.0)
		gt.fill_from = Vector2(cx, 0.6)
		gt.fill_to = Vector2(cx, 0.05)


## Each figure (and the crest) appears once its file has arrived.
func _process(_delta: float) -> void:
	if _crest and _crest.texture == null:
		_crest.texture = Clips.sheet(Graces.art_path("crest"))
	for j in _figures.size():
		if _figures[j].texture == null:
			_figures[j].texture = Clips.sheet(Graces.art_path(Graces.LIST[j].key))
			if _figures[j].texture:
				if _hero and j == at:
					_hero.texture = _figures[j].texture
				_lay(false)
