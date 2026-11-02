class_name RunChoices
extends Screen

## What opens over the road map: camps, boons, hero picks and wayside stops. Expedition's screens extend this,
## so the road and its choices can change apart.

## A choice's stage on a wide screen: where the offers stand, between the hero and the terms.
const STAGE_LEFT := 400.0
const STAGE_RIGHT := 300.0
const STAGE_TOP := 112.0
const STAGE_W := 800.0
## Terms a choice may use beyond the statuses in the Archive's glossary.
const STAGE_TERMS := [["Cooldown", "Rounds a skill waits before it can be used again."], ["Power", "How hard a skill lands, as a share of attack."]]


func _face(uid: String, px := 112) -> Control:
	if Forge.wide():
		return _figure(uid, px)
	var c := app.col.by(uid)
	var h := Data.hero(c.hero)
	var hp := app.run.health(uid) if app.run else 1.0
	var v := Forge.vbox(6)
	var face := Control.new()
	face.custom_minimum_size = Vector2(px, px)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex: Texture2D = load(h.portrait.src)
	face.draw.connect(func():
		var r := Rect2(Vector2.ZERO, face.size)
		Forge.portrait(face, tex, r.grow(-2), h.portrait, 0.75, "squad")
		if hp <= 0.0:
			face.draw_rect(r, Color(Forge.INK, 0.65))
		face.draw_rect(r.grow(-1), Forge.ELEM[h.elem].darkened(0.1) if hp > 0.0 else Color(Forge.DIM, 0.5), false, 2.0)
		var bar := Rect2(6, r.size.y - 12, r.size.x - 12, 6)
		face.draw_rect(bar, Color(Forge.INK, 0.9))
		face.draw_rect(Rect2(bar.position, Vector2(bar.size.x * hp, bar.size.y)), Forge.GAIN if hp > 0.35 else BattleTile.HP_LOW))
	v.add_child(face)
	var l := Forge.sc(h.name, 16, Forge.MUTED if hp > 0.0 else Forge.DIM)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	return v


## The wide build's party member: standing, with their health on the road under their feet.
func _figure(uid: String, px: int) -> Control:
	var c := app.col.by(uid)
	var hp := app.run.health(uid) if app.run else -1.0
	var v := Forge.vbox(2)
	var s := Stand.new().setup(c.hero, c.stars, hp)
	s.custom_minimum_size = Vector2(px * 1.3, px * 2.4)
	v.add_child(s)
	var l := Forge.sc(Data.hero(c.hero).name, 15, Forge.MUTED if hp != 0.0 else Forge.DIM)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	return v


## Someone at the fire says something: a living squad member with a face and camp lines, at random.
func _camp_talk(v: VBoxContainer) -> void:
	var who := []
	for uid in app.col.squad:
		var key: String = app.col.by(uid).hero
		if app.run.health(uid) > 0.0 and Bust.has_faces(key) and Speech.line_for(key, "camp") != "":
			who.append(key)
	if who.is_empty():
		return
	var key: String = who.pick_random()
	var row := Forge.hbox(10)
	v.add_child(row)
	var bust := Bust.new().setup(key)
	bust.melt = 0.3
	bust.custom_minimum_size = Vector2(200, 200)
	row.add_child(bust)
	var line := Speech.say(row, key, Speech.line_for(key, "camp"), 310.0, true)
	line.size_flags_vertical = SIZE_SHRINK_CENTER
	bust.say.call_deferred()


## A panel over the screen for a node's event; the studs button closes it.
func _event(icon_name: String, heading: String, rarity: int, fill: Callable, close_text := "go on", hero_key := "", words := []) -> void:
	var shade := Control.new()
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	app.add_child(shade)
	shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	# A choice on a wide screen is a stage of its own: the hero beside it, the title across the top, terms to the right.
	var stage := hero_key != "" and Forge.wide()
	shade.draw.connect(func(): shade.draw_rect(Rect2(Vector2.ZERO, shade.size), Color(Forge.INK, 0.9 if stage else 0.78)))
	var col: Color = Forge.RARITY[rarity] if rarity > 0 else Forge.GOLD
	if stage:
		_stage(shade, hero_key, heading, col, rarity, words)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	shade.add_child(center)
	if stage:
		center.offset_left = STAGE_LEFT
		center.offset_right = -STAGE_RIGHT
		center.offset_top = STAGE_TOP
	var panel := PanelContainer.new()
	if stage:
		panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	else:
		panel.add_theme_stylebox_override("panel", Forge.flat(Forge.PLAQUE, Color.TRANSPARENT, 0, Vector4(40, 36, 40, 36)))
		Rim.on(panel, "flow" if rarity >= 2 else "comet", [col, col.lightened(0.4), Forge.GOLD_LIGHT, col.darkened(0.3)] if rarity >= 2 else [col], 3.0).sparkles = rarity >= 3
	panel.custom_minimum_size.x = STAGE_W if stage else 600.0
	center.add_child(panel)
	var v := Forge.vbox(20)
	panel.add_child(v)
	if not stage:
		var head := Forge.hbox(14)
		v.add_child(head)
		head.add_child(Forge.glyph(icon_name, 44, col))
		head.add_child(Forge.sc(heading, 34, col, true, 0.16))
		if rarity > 0:
			var tag := Forge.sc(Expedition.RARITIES[rarity], 18, col)
			tag.size_flags_vertical = SIZE_SHRINK_CENTER
			head.add_child(tag)
	fill.call(v)
	if close_text != "":
		var done := Forge.studs(close_text, true, 76)
		done.pressed.connect(func():
			shade.queue_free()
			rebuild())
		v.add_child(done)
	panel.pivot_offset = Vector2(300, 200)
	panel.scale = Vector2(0.92, 0.92)
	panel.modulate.a = 0.0
	var tw := panel.create_tween().set_parallel()
	tw.tween_property(panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, 0.16)


## The parts of a choice's stage: the hero standing at the left, the title across the top, and the terms the offers use.
func _stage(shade: Control, hero_key: String, heading: String, col: Color, rarity: int, words: Array) -> void:
	var s := Stand.new().setup(hero_key, app.col.by(app.copies(hero_key)[0].uid).stars)
	s.tall = 0.96
	s.size = Vector2(430, 640)
	s.position = Vector2(-10, 76)
	shade.add_child(s)
	var band := ColorRect.new()
	band.color = Color(Forge.PLAQUE, 0.92)
	band.set_anchors_preset(PRESET_TOP_WIDE)
	band.offset_bottom = STAGE_TOP - 16.0
	shade.add_child(band)
	band.draw.connect(func():
		band.draw_line(Vector2(0, band.size.y - 1), Vector2(band.size.x, band.size.y - 1), Color(col, 0.8), 2.0))
	var title := Forge.sc(heading, 34, col if rarity > 0 else Forge.PARCHMENT, false, 0.3)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.set_anchors_preset(PRESET_FULL_RECT)
	band.add_child(title)
	var side := Forge.vbox(12)
	side.anchor_left = 1.0
	side.anchor_right = 1.0
	side.offset_left = -STAGE_RIGHT + 14.0
	side.offset_right = -24.0
	side.offset_top = STAGE_TOP + 20.0
	shade.add_child(side)
	for w in words:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", Forge.flat(Color(Forge.INK, 0.85), Color(Forge.GOLD_DEEP, 0.6), 1, Vector4(16, 12, 16, 12)))
		side.add_child(p)
		var t := Forge.vbox(4)
		p.add_child(t)
		t.add_child(Forge.sc(w[0], 18, Forge.GOLD_LIGHT, true))
		var d := Forge.label(w[1], 18, Forge.PARCHMENT)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.add_child(d)


## The terms that the offers' words use, explained for the side of the stage.
func _terms_in(texts: Array) -> Array:
	var all := " ".join(texts).to_lower()
	var out := []
	for s in CodexScreen.STATUSES + STAGE_TERMS:
		if s[0].to_lower() in all and out.size() < 3:
			out.append([s[0], s[-1]])
	return out


## Who stands beside a choice for the whole squad: the first hero still on their feet.
func _lead() -> String:
	for uid in app.col.squad:
		if app.run == null or app.run.health(uid) > 0.0:
			return app.col.by(uid).hero
	return app.col.by(app.col.squad[0]).hero


## The picture on a boon's card, by what it raises.
static func boon_glyph(key: String) -> String:
	return {"atk": "atk", "def": "def", "spd": "spd", "max_hp": "hp", "atk_elem": "atk", "embers": "gold"}.get(Expedition.BOONS[key].stat, "node_boon")


func _boon_pick(p: Vector2i) -> void:
	var run := app.run
	var offers := run.offers(p)
	var rarity: int = run.node(p).rarity
	var holder := [null]
	var words := _terms_in(offers.map(func(b): return Expedition.boon_text(b)))
	_event("node_boon", "choose a boon", rarity, func(v: VBoxContainer):
		v.add_child(_para("A blessing for the rest of this road. Take one."))
		for b in offers:
			var col: Color = Forge.RARITY[b.rarity]
			var card := _offer_card(boon_glyph(b.key), col, Expedition.BOONS[b.key].name, Expedition.boon_text(b), b.rarity)
			card.pressed.connect(func():
				run.take(b)
				Burst.on(card, col, 60, 10)
				await get_tree().create_timer(0.3).timeout
				_close_event(holder[0])
				rebuild())
			v.add_child(card)
		holder[0] = v, "", _lead(), words)


## One choice in an event: a glyph, a name and what it does. Rare ones turn a comet round the edge.
## `pic` stands in for the glyph badge when the offer is about something with its own icon.
func _offer_card(glyph_name: String, col: Color, heading: String, text: String, rarity: int, pic: Control = null) -> Button:
	var card := Button.new()
	card.focus_mode = Control.FOCUS_NONE
	card.custom_minimum_size = Vector2(0, 124 if Forge.wide() else 104)
	card.add_theme_stylebox_override("normal", Forge.flat(Color(Forge.INK, 0.8), Color(col, 0.55), 2))
	card.add_theme_stylebox_override("hover", Forge.flat(Color(Forge.INK, 0.9), col, 2))
	card.add_theme_stylebox_override("pressed", Forge.flat(Color(Forge.INK, 0.9), col, 2))
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	Forge.press_weight(card, 0.96)
	var m := Forge.margins(MarginContainer.new(), 20, 12, 20, 12)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.set_anchors_preset(PRESET_FULL_RECT)
	card.add_child(m)
	var h := Forge.hbox(16)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(h)
	h.add_child(pic if pic else _offer_badge(glyph_name, col))
	var tv := Forge.vbox(2)
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.size_flags_horizontal = SIZE_EXPAND_FILL
	h.add_child(tv)
	tv.add_child(Forge.sc(heading, 24, col, true))
	var d := Forge.label(text, 21, Forge.PARCHMENT)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tv.add_child(d)
	if rarity >= 2:
		Rim.on(card, "comet", [col], 2.0)
	return card


## An offer's picture in a diamond of its rarity's colour.
func _offer_badge(glyph_name: String, col: Color) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(84, 84)
	c.size_flags_vertical = SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var m := c.size / 2.0
		var d := PackedVector2Array([m + Vector2(0, -40), m + Vector2(40, 0), m + Vector2(0, 40), m + Vector2(-40, 0)])
		c.draw_colored_polygon(d, Color(col, 0.16))
		c.draw_polyline(d + PackedVector2Array([d[0]]), col, 2.0, true)
		c.draw_texture_rect(Forge.icon(glyph_name), Rect2(m - Vector2(21, 21), Vector2(42, 42)), false, col))
	return c


## Closes the event whose content box is `v`.
func _close_event(v: Control) -> void:
	v.get_parent().get_parent().get_parent().queue_free()


# ---------- the shrine ----------

## A shrine of the Graces, like a boon pick in Hades: three of them stand in a row, each offering her blessing. Touch
## one to choose her (she lights; the others stand back), then take it; it holds for every fight left on the road.
func _shrine(p: Vector2i) -> void:
	var run := app.run
	var keys := run.shrine_offers(p)
	if keys.is_empty():
		return
	var shade := Control.new()
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	app.add_child(shade)
	shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	shade.draw.connect(func(): shade.draw_rect(Rect2(Vector2.ZERO, shade.size), Color(Forge.INK, 0.97)))
	var glow := Forge.wash(Color(Forge.GOLD_DEEP, 0.18), Vector2(0.5, 0.6), Vector2(0.5, 0.0), true)
	shade.add_child(glow)
	glow.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var m := Forge.margins(MarginContainer.new(), 48, 26, 48, 64) if Forge.wide() else Forge.margins(MarginContainer.new(), 20, 70, 20, 110)
	shade.add_child(m)
	m.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var v := Forge.vbox(12 if Forge.wide() else 20)
	m.add_child(v)
	var head := Forge.sc("a shrine of the graces", 34 if Forge.wide() else 40, Forge.GOLD_LIGHT, true, 0.16)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(head)
	var line := Forge.label("Three of the dancers of Mehfil wait here. One will bless the rest of this road.", 21, Forge.DIM, Forge.SANS_ITALIC)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(line)
	var row := Forge.hbox(18 if Forge.wide() else 10)
	row.size_flags_vertical = SIZE_EXPAND_FILL
	v.add_child(row)
	var take := Forge.studs("choose a grace", true, 72 if Forge.wide() else 84)
	take.disabled = true
	var chosen := [""]
	var cols: Array[Control] = []
	for k in keys:
		var col := _shrine_grace(k)
		cols.append(col)
		row.add_child(col)
	for i in cols.size():
		cols[i].gui_input.connect(func(e: InputEvent):
			if not (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) or chosen[0] == keys[i]:
				return
			Sfx.play("page")
			chosen[0] = keys[i]
			for j in cols.size():
				_shrine_light(cols[j], j == i)
			take.disabled = false
			take.text = ("take %s's blessing" % Graces.by(keys[i]).name).to_lower())
	var foot := Forge.hbox(24)
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(foot)
	take.custom_minimum_size.x = 460
	foot.add_child(take)
	var pass_by := Forge.link("walk on", "chevron", 20)
	pass_by.tooltip_text = "Leave the shrine without a blessing"
	pass_by.pressed.connect(func():
		shade.queue_free()
		rebuild())
	foot.add_child(pass_by)
	take.pressed.connect(func():
		if not run.take_grace(chosen[0]):
			return
		var g := Graces.by(chosen[0])
		# On the shade, not the column: a container would lay the burst out at its corner.
		var her := cols[keys.find(chosen[0])]
		Burst.at(shade, her.global_position - shade.global_position + her.size / 2.0, Forge.ELEM.get(g.elem, Forge.GOLD_LIGHT), 90, 12)
		await get_tree().create_timer(0.45).timeout
		shade.queue_free()
		rebuild())
	shade.modulate.a = 0.0
	shade.create_tween().tween_property(shade, "modulate:a", 1.0, 0.25)


## One Grace at the shrine: her figure over her name, title and blessing, dim until she is chosen.
func _shrine_grace(key: String) -> Control:
	var g := Graces.by(key)
	var tint: Color = Forge.ELEM.get(g.elem, Forge.GOLD_LIGHT)
	var p := PanelContainer.new()
	p.size_flags_horizontal = SIZE_EXPAND_FILL
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	p.add_theme_stylebox_override("panel", Forge.flat(Color(Forge.PLAQUE, 0.55), Color(Forge.GOLD_DEEP, 0.35), 1, Vector4(12, 12, 12, 14)))
	var col := Forge.vbox(4)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(col)
	var fig := ShrineFigure.new()
	fig.key = key
	fig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fig.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fig.size_flags_vertical = SIZE_EXPAND_FILL
	fig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fig.material = ShaderMaterial.new()
	(fig.material as ShaderMaterial).shader = GracesScreen.shine()
	col.add_child(fig)
	var head := Forge.hbox(8)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if g.elem != "":
		var sig := Forge.glyph("elem_" + g.elem, 24, tint)
		sig.size_flags_vertical = SIZE_SHRINK_CENTER
		head.add_child(sig)
	head.add_child(Forge.sc(g.name, 34 if Forge.wide() else 30, Forge.GOLD_LIGHT, true, 0.06))
	col.add_child(head)
	# Titles wrap rather than widen a column, so the three stand the same width.
	var t := Forge.sc(g.title, 18, Forge.GOLD)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.custom_minimum_size.y = 26 if Forge.wide() else 50
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(t)
	var b := Forge.label(g.blessing, 19 if Forge.wide() else 18, Forge.PARCHMENT)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.custom_minimum_size = Vector2(0, 76 if Forge.wide() else 130)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(b)
	p.set_meta("tint", tint)
	_shrine_light(p, false, true)
	return p


## Lights the chosen Grace's column and stands the others back. Before any choice they all stand in full.
func _shrine_light(p: Control, on: bool, first := false) -> void:
	var fig := p.get_child(0).get_child(0) as TextureRect
	(fig.material as ShaderMaterial).set_shader_parameter("lit", 1.0 if on else 0.0)
	var tw := p.create_tween()
	tw.tween_property(p, "modulate", Color.WHITE if on or first else GracesScreen.DIMMED.lightened(0.3), GracesScreen.STEP)
	for c in p.get_children():
		if c is Rim:
			c.queue_free()
	if on:
		var tint: Color = p.get_meta("tint")
		Rim.on(p, "flow", [tint, Forge.GOLD_LIGHT, tint.darkened(0.3), Forge.GOLD], 2.0)
	else:
		Rim.on(p, "comet", [Forge.GOLD], 2.0)


## A Grace's figure, which arrives with the sheets (see Clips) and appears once it has.
class ShrineFigure extends TextureRect:
	var key := ""

	func _process(_delta: float) -> void:
		if texture == null:
			texture = Clips.sheet(Graces.art_path(key))
		else:
			set_process(false)


# ---------- hero picks ----------

## After a won fight: one hero chooses an upgrade for the rest of the road, or rerolls, or skips for embers.
func _hero_pick() -> void:
	var run := app.run
	var uid: String = run.pick_now.uid
	var hero := Data.hero(app.col.by(uid).hero)
	var holder := [null]
	var words := _terms_in(run.pick_now.options.map(func(o): return _pick_text(o)))
	_event("character", "%s grows" % hero.name, 0, func(v: VBoxContainer):
		holder[0] = v
		var top := Forge.hbox(16)
		v.add_child(top)
		# A wide screen is short, and the heading already names them, so only the phone shows the face.
		if not Forge.wide():
			top.add_child(_face(uid, 92))
		var line := _para("A change that lasts for this road. It holds for %s alone." % hero.name)
		line.size_flags_horizontal = SIZE_EXPAND_FILL
		top.add_child(line)
		for o in run.pick_now.options:
			var col: Color = Forge.RARITY[o.rarity]
			var card := _offer_card("elem_" + Data.AUGS[o.aug].fam, col, run.pick_preview(o).name, _pick_text(o), o.rarity, Forge.skill_icon(run.pick_preview(o), hero.elem, 84))
			card.pressed.connect(func():
				if run.picks_full(uid):
					_close_event(v)
					_replace_pick(o)
					return
				run.take_pick(o)
				Sfx.play("confirm")
				Burst.on(card, col, 60, 10)
				await get_tree().create_timer(0.3).timeout
				_close_event(v)
				rebuild())
			v.add_child(card)
		var foot := Forge.hbox(14)
		v.add_child(foot)
		var price := run.reroll_price()
		var again := Forge.ember("reroll · %s" % ("free (%d)" % run.rerolls if price == 0 else "%d gold" % price), 64)
		again.add_theme_font_size_override("font_size", 20)
		again.size_flags_horizontal = SIZE_EXPAND_FILL
		again.disabled = not run.can_reroll()
		again.pressed.connect(func():
			run.reroll_pick()
			Sfx.play("tap")
			_close_event(v)
			_hero_pick())
		foot.add_child(again)
		var skip := Forge.link("skip · +%d gold" % run.skip_share(), "chevron", 20)
		skip.pressed.connect(func():
			run.skip_pick()
			_close_event(v)
			rebuild())
		foot.add_child(skip), "", hero.key, words)


## What a pick does, and the numbers it moves on that skill.
func _pick_text(o: Dictionary) -> String:
	var run := app.run
	var was := run.pick_before(o)
	var now := run.pick_preview(o)
	var text: String = Data.AUGS[o.aug].desc.split(".")[0] + "."
	if now.cd != was.cd:
		text += " Cooldown %d → %d." % [was.cd, now.cd]
	if not is_equal_approx(now.power, was.power):
		text += " Power %d%% → %d%%." % [roundi(was.power * 100), roundi(now.power * 100)]
	return text


## A full hero gives up an old pick for the new one, or goes back to the offer.
func _replace_pick(o: Dictionary) -> void:
	var run := app.run
	var uid: String = run.pick_now.uid
	var c := app.col.by(uid)
	var skills: Array = Data.hero(c.hero).skills
	_event("character", "replace which?", 0, func(v: VBoxContainer):
		v.add_child(_para("%s holds %d picks on a road. %s takes the place of one." % [Data.hero(c.hero).name, Expedition.PICK_SLOTS, run.pick_preview(o).name]))
		var held: Array = run.picks[uid]
		for i in held.size():
			var aug: Dictionary = Data.AUGS[held[i].aug]
			var card := _offer_card("swap", Forge.ELEM[aug.fam], "%s · %s" % [skills[held[i].skill].name, aug.name], aug.desc.split(".")[0] + ".", 0, Forge.skill_icon(skills[held[i].skill], Data.hero(c.hero).elem, 84))
			card.pressed.connect(func():
				run.take_pick(o, i)
				Sfx.play("confirm")
				_close_event(v)
				rebuild())
			v.add_child(card)
		var back := Forge.link("back to the offer", "back", 20)
		back.pressed.connect(func():
			_close_event(v)
			_hero_pick())
		v.add_child(back), "", c.hero)


# ---------- the wayside ----------

## A wayside stop: the event's scene and its choices, in the panel every stop uses. See design/events.md.
func _wayside(p: Vector2i) -> void:
	var run := app.run
	var key := run.draw_event(p)
	var ev: Dictionary = Events.LIST[key]
	_event("node_wayside", ev.title, run.node(p).rarity, func(v: VBoxContainer):
		# A wide screen is short, so the panel widens to keep the longest scene with four choices on it.
		v.custom_minimum_size.x = 900.0 if Forge.wide() else 0.0
		v.add_child(_para(ev.scene))
		var list := Forge.vbox(10)
		v.add_child(list)
		var squad := {}
		for uid in app.col.squad:
			squad[uid] = app.col.by(uid).hero
		for c in run.event_choices(key, squad):
			var b := Forge.ember(c.text, 60)
			b.add_theme_font_size_override("font_size", 22)
			b.disabled = not run.can_pay(c)
			b.pressed.connect(_choose_wayside.bind(c, v, list))
			list.add_child(b)
			var terms := run.event_terms(c)
			if terms != "":
				var t := Forge.sc(terms, 18, Forge.MUTED, true)
				t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				list.add_child(t), "")


## A choice is made: pay, then roll if it asks for a hero, flip if it's luck, or simply happen.
func _choose_wayside(c: Dictionary, v: VBoxContainer, list: Control) -> void:
	var run := app.run
	run.event_pay(c)
	list.queue_free()
	if c.has("roll"):
		_wayside_roll(c, v)
	elif c.has("luck"):
		_wayside_outcome(c.win if randi() % 2 == 0 else c.lose, "", v)
	else:
		_wayside_outcome(c.do, c.get("uid", ""), v)


## Who tries a roll: the standing squad, as a trial always was. The odds are on the buttons.
func _wayside_roll(c: Dictionary, v: VBoxContainer) -> void:
	var run := app.run
	var apt: String = c.roll
	var test := _note("A test of %s: %s. Choose who tries. Roll d20 and reach %d; a hero who favors %s adds +%d." % [
		apt, Data.APTITUDES[apt].to_lower(), Expedition.ROLL_DC, apt, Data.FAVORED_BONUS])
	v.add_child(test)
	var row := GridContainer.new()
	row.columns = 2
	row.add_theme_constant_override("h_separation", 12)
	row.add_theme_constant_override("v_separation", 12)
	v.add_child(row)
	for uid in app.col.squad:
		if run.fallen(uid):
			continue
		var hero := Data.hero(app.col.by(uid).hero)
		var fav: bool = apt in hero.get("favored", [])
		var b := Forge.ember(hero.name + (" +%d" % Data.FAVORED_BONUS if fav else ""), 64)
		b.add_theme_font_size_override("font_size", 20)
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.pressed.connect(func():
			row.queue_free()
			test.queue_free()
			var roll := randi() % 20 + 1
			var total := roll + (Data.FAVORED_BONUS if fav else 0)
			v.add_child(Forge.sc("d20 · %d%s = %d vs %d" % [roll, " + %d" % Data.FAVORED_BONUS if fav else "", total, Expedition.ROLL_DC], 26, Forge.GOLD_LIGHT, true))
			_wayside_outcome(c.win if Expedition.roll_wins(roll, fav) else c.lose, uid, v))
		row.add_child(b)


## What came of it, in place of the scene so the panel stays on a wide screen, then the one way on: back to the road,
## or into the fight it started.
func _wayside_outcome(o: Dictionary, uid: String, v: VBoxContainer) -> void:
	var run := app.run
	var got := run.event_apply(o, uid)
	v.get_child(1).queue_free()
	var key: String = app.col.by(uid).hero if uid != "" else ""
	if key != "" and Bust.has_faces(key) and not got.has("hurt"):
		var row := Forge.hbox(10)
		v.add_child(row)
		var bust := Bust.new().setup(key)
		bust.melt = 0.3
		bust.custom_minimum_size = Vector2(160, 160)
		row.add_child(bust)
		var words := _para(got.say)
		words.custom_minimum_size.x = 340
		words.size_flags_vertical = SIZE_SHRINK_CENTER
		row.add_child(words)
	else:
		v.add_child(_para(got.say))
	if got.get("gold", 0) > 0:
		v.add_child(_gain("gold", "+%d gold" % got.gold))
	if got.get("gold", 0) < 0:
		v.add_child(_note("%d gold gone." % -got.gold))
	if got.has("debt"):
		v.add_child(_note("%d gold owed when you bank." % got.debt))
	if got.has("heal"):
		v.add_child(_gain("role_healer", "the squad heals %d%%" % roundi(got.heal * 100)))
	if got.has("hurt"):
		v.add_child(_note("%s loses %d%% health." % [Data.hero(key).name, roundi(got.hurt * 100)]))
	if got.has("hurt_all"):
		v.add_child(_note("Everyone loses %d%% health." % roundi(got.hurt_all * 100)))
	if got.has("boon"):
		v.add_child(_gain("node_boon", "%s · %s" % [Expedition.BOONS[got.boon.key].name, Expedition.boon_text(got.boon)]))
	if got.has("augment"):
		app.col.loose.append(got.augment)
		v.add_child(_gain("augment", "+1 augment · %s" % Data.AUGS[got.augment].name))
	if got.has("rerolls"):
		v.add_child(_gain("node_boon", "+%d free rerolls" % got.rerolls))
	if got.has("raise"):
		v.add_child(_gain("role_healer", "%s stands at %d%% health" % [Data.hero(key).name, roundi(got.raise * 100)]))
	var done := Forge.studs("to arms" if got.has("fight") else "go on", true, 76)
	done.pressed.connect(func():
		_close_event(v)
		if got.has("fight"):
			app.show_fight()
		else:
			rebuild())
	v.add_child(done)


func _heading(text: String) -> Control:
	var h := Forge.hbox(16)
	h.add_child(Forge.sc(text, 22, Forge.GOLD))
	var line := Control.new()
	line.size_flags_horizontal = SIZE_EXPAND_FILL
	line.custom_minimum_size.y = 28
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.draw.connect(func(): line.draw_line(Vector2(0, line.size.y / 2), Vector2(line.size.x, line.size.y / 2), Color(Forge.GOLD_DEEP, 0.5), 2.0))
	h.add_child(line)
	return h


func _chip(glyph_name: String, text: String, tip: String) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Forge.flat(Forge.PLAQUE, Color(Forge.BRONZE, 0.9), 2, Vector4(18, 6, 18, 6)))
	p.size_flags_vertical = SIZE_SHRINK_CENTER
	p.tooltip_text = tip
	var h := Forge.hbox(10)
	p.add_child(h)
	h.add_child(Forge.glyph(glyph_name, 26, Forge.GOLD_LIGHT))
	h.add_child(Forge.label(text, 26, Forge.PARCHMENT, Forge.SANS_BOLD))
	return p


func _para(text: String) -> Label:
	var l := Forge.label(text, 24, Forge.PARCHMENT)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 500
	return l


func _note(text: String) -> Label:
	var l := Forge.label(text, 21, Forge.DIM, Forge.SANS_ITALIC)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 500
	return l


func _gain(glyph_name: String, text: String) -> Control:
	var h := Forge.hbox(10)
	h.add_child(Forge.glyph(glyph_name, 26, Forge.GAIN))
	h.add_child(Forge.sc(text, 24, Forge.GAIN, true))
	return h


## A stop on the map: a disc with the node's icon. Open nodes wear a turning ring; where you stand is gold; the road
## behind you dims; boons show their rarity in the ring.
class MapNode extends Control:
	var at := Vector2i.ZERO
	var kind := "battle"
	var rarity := 0
	var open := false
	var here := false
	var past := false
	var _t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP if open else Control.MOUSE_FILTER_IGNORE
		_t = randf() * 3.0

	func _process(delta: float) -> void:
		if open or here:
			_t += delta
			queue_redraw()

	func _draw() -> void:
		var c := size / 2
		var r := ExpeditionScreen.NODE_R
		var big := kind == "boss"
		if big:
			r *= 1.3
		var tint: Color = Forge.RARITY[rarity] if kind == "boon" and rarity > 0 else (Forge.HARM if kind in ["elite", "boss"] else Forge.GOLD)
		var dim := past and not here
		if open:
			var k := 0.5 + 0.5 * sin(_t * TAU * 0.7)
			draw_circle(c, r + 10 + 4 * k, Color(tint, 0.12 + 0.1 * k))
		draw_circle(c, r, Forge.INK)
		draw_circle(c, r - 3, Forge.PLAQUE if not dim else Forge.PLAQUE_DEEP)
		var ring := Color(tint, 0.25 if dim else (0.95 if open or here else 0.5))
		draw_arc(c, r - 1.5, 0, TAU, 48, ring, 3.0, true)
		if open:
			var head := fposmod(_t * 0.5, 1.0) * TAU
			for i in 14:
				var k := i / 13.0
				draw_arc(c, r + 5, head - 0.9 * (1 - k) - 0.08, head - 0.9 * (1 - k), 4, Color(tint.lightened(0.3), k), 3.0, true)
		if here:
			draw_arc(c, r + 6, 0, TAU, 48, Forge.GOLD_LIGHT, 2.0, true)
		var g := r * 1.1
		draw_texture_rect(Forge.icon(Expedition.NODES[kind].icon), Rect2(c - Vector2(g, g) / 2, Vector2(g, g)), false,
			Color(tint.lightened(0.25) if not dim else Forge.DIM, 1.0 if not dim else 0.45))
