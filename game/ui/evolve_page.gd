class_name EvolvePage
extends Control
## Evolve or equip, opened from the sheet's buttons and sliding up over the hero.
## Evolve: the hero's four stars, what the next one brings, field or bench.
## Equip: one augment slot per star, and the loose augments that fit.

const PAGE_H := 1560.0
const TIERS := ["bronze", "silver", "gold", "crowned"]

var app: App
## "evolve" or "equip".
var mode := "evolve"
var hero := ""
var uid := ""
var status := ""
var _ui: Control

signal height_changed(h: float)
## The hero changed (re-equipped, fielded): the pages above should refresh.
signal changed
signal closed


func setup(a: App, hero_key: String, card_uid: String, page_mode := "evolve") -> EvolvePage:
	app = a
	hero = hero_key
	uid = card_uid
	mode = page_mode
	return self


func _ready() -> void:
	var bd := Backdrop.new()
	bd.elem = Data.hero(hero).elem
	bd.focus = Vector2(0.5, 0.0)
	bd.strength = 0.45
	bd.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bd)
	refresh()


func _card() -> Dictionary:
	return app.col.by(uid)


func refresh() -> void:
	if _ui:
		_ui.queue_free()
	var c := _card()
	var root := Forge.margins(MarginContainer.new(), 44, 12, 44, 80)
	root.custom_minimum_size = Vector2(720, PAGE_H)
	add_child(root)
	_ui = root
	var col := Forge.vbox(40)
	root.add_child(col)

	var back := Forge.link(Data.hero(hero).name)
	back.size_flags_horizontal = SIZE_SHRINK_BEGIN
	back.pressed.connect(func(): closed.emit())
	col.add_child(back)
	var head := Forge.vbox(8)
	col.add_child(head)
	head.add_child(Forge.sc(mode, 52, Forge.GOLD, true, 0.12))
	head.add_child(Forge.label("%s, %d★ %s" % [Data.hero(hero).name, c.stars, TIERS[c.stars - 1]], 26, Forge.MUTED))
	col.add_child(Forge.rule())
	col.add_child(_evolution(c) if mode == "evolve" else _equipment(c))
	_fit.call_deferred()


func _fit() -> void:
	if not is_instance_valid(_ui):
		return
	var hgt := maxf(PAGE_H, _ui.get_combined_minimum_size().y)
	_ui.size = Vector2(720, hgt)
	custom_minimum_size = Vector2(720, hgt)
	size = Vector2(720, hgt)
	height_changed.emit(hgt)


# ---- Evolution ----

func _evolution(c: Dictionary) -> Control:
	var v := Forge.vbox(26)
	v.add_child(_track(c.stars))
	var left: int = Collection.MAX_STARS - c.stars
	var how := "Each new copy of %s lights a star. %d more to reach 4★." % [Data.hero(hero).name, left] if left > 0 else "All four stars are lit. Spare copies turn into gold."
	v.add_child(_para(how))
	if left > 0:
		var next := c.duplicate()
		next.stars += 1
		v.add_child(_preview_panel(app.col.stats(c), app.col.stats(next), next.stars))
	if status != "":
		var l := Forge.label(status, 24, Forge.GOLD, Forge.SANS_ITALIC)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l)
	var field := Forge.ember("bench" if uid in app.col.squad else "field")
	field.size_flags_horizontal = SIZE_SHRINK_BEGIN
	field.tooltip_text = "Take %s off the field" % Data.hero(hero).name if uid in app.col.squad else "Put %s on the field" % Data.hero(hero).name
	field.pressed.connect(func():
		status = app.col.toggle_field(uid)
		_changed())
	v.add_child(field)
	return v


## Four tiers as diamonds on a line, lit up to the card's stars.
func _track(stars: int) -> Control:
	var t := Control.new()
	t.custom_minimum_size = Vector2(632, 86)
	t.draw.connect(func():
		var y := 22.0
		var xs := [40.0, 224.0, 408.0, 592.0]
		t.draw_line(Vector2(xs[0], y), Vector2(xs[3], y), Color(Forge.BRONZE, 0.6), 2.0)
		t.draw_line(Vector2(xs[0], y), Vector2(xs[stars - 1], y), Forge.GOLD, 3.0)
		for i in 4:
			var lit := i < stars
			var col: Color = Data.TIER_COLORS[i + 1] if lit else Color(Forge.BRONZE, 0.5)
			Forge.diamond(t, Vector2(xs[i], y), 15 if i == stars - 1 else 11, col if lit else Forge.INK)
			if not lit:
				Forge.diamond(t, Vector2(xs[i], y), 11, col, false)
			var f := Forge.tracked(Forge.SC, 2)
			t.draw_string(f, Vector2(xs[i] - 70, 74), "%d★ %s" % [i + 1, TIERS[i]], HORIZONTAL_ALIGNMENT_CENTER, 140, 19,
				Forge.PARCHMENT if lit else Forge.DIM))
	return t


## Before → after for each stat at the next star.
func _preview_panel(before: Dictionary, after: Dictionary, stars: int) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Forge.flat(Color(Forge.PLAQUE, 0.92), Forge.GAIN, 2, Vector4(26, 18, 26, 18)))
	var v := Forge.vbox(10)
	p.add_child(v)
	v.add_child(Forge.sc("at %d★" % stars, 22, Forge.GAIN))
	for k in Data.STATS:
		var h := Forge.hbox(14)
		h.add_child(Forge.glyph(Forge.STAT_ICON[k], 24, Forge.STAT_TINT[k]))
		var name := Forge.label(Forge.STAT_NAME[k].capitalize(), 24, Forge.MUTED)
		name.size_flags_horizontal = SIZE_EXPAND_FILL
		h.add_child(name)
		h.add_child(Forge.label("%d  →" % before[k], 24, Forge.MUTED, Forge.SANS_BOLD))
		h.add_child(Forge.label("%d (%+d)" % [after[k], after[k] - before[k]], 24, Forge.GAIN, Forge.SANS_BOLD))
		v.add_child(h)
	return p


# ---- Equipment ----

## One augment slot per star. Augments come off with a tap.
func _equipment(c: Dictionary) -> Control:
	var v := Forge.vbox(22)
	v.add_child(_para("One augment slot per star. Augments swap freely."))
	var skills: Array = Data.hero(hero).skills
	var slots := GridContainer.new()
	slots.columns = 2
	slots.add_theme_constant_override("h_separation", 16)
	slots.add_theme_constant_override("v_separation", 16)
	v.add_child(slots)
	for i in c.stars:
		if i < c.augs.size():
			var a: Dictionary = c.augs[i]
			slots.add_child(_aug_slot(a.aug, skills[a.skill].name, i))
		else:
			slots.add_child(_empty_slot())

	var free: int = c.stars - c.augs.size()
	v.add_child(Forge.sc("loose augments · %d" % app.col.loose.size(), 22, Forge.LABEL))
	if app.col.loose.is_empty():
		v.add_child(Forge.label("None left. Runs bring more.", 24, Forge.MUTED, Forge.SANS_ITALIC))
	for aug in _unique(app.col.loose):
		v.add_child(_loose_row(aug, skills, free > 0))
	return v


func _aug_slot(aug: String, skill_name: String, j: int) -> Control:
	var a: Dictionary = Data.AUGS[aug]
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(308, 0)
	p.add_theme_stylebox_override("panel", Forge.flat(Color(Forge.PLAQUE, 0.92), Forge.ELEM[a.fam].darkened(0.1), 2, Vector4(18, 14, 18, 14)))
	var h := Forge.hbox(14)
	p.add_child(h)
	var d := Control.new()
	d.custom_minimum_size = Vector2(28, 28)
	d.size_flags_vertical = SIZE_SHRINK_CENTER
	d.draw.connect(func(): Forge.diamond(d, Vector2(14, 14), 13, Forge.ELEM[a.fam]))
	h.add_child(d)
	var t := Forge.vbox(2)
	t.size_flags_horizontal = SIZE_EXPAND_FILL
	h.add_child(t)
	t.add_child(Forge.sc(a.name, 24, Forge.PARCHMENT))
	t.add_child(Forge.label("on " + skill_name, 20, Forge.MUTED))
	var off := Forge.link("off", "", 20)
	off.custom_minimum_size.y = 56
	off.tooltip_text = "Take %s off" % a.name
	off.pressed.connect(func():
		app.col.unslot_aug(uid, j)
		status = ""
		_changed())
	h.add_child(off)
	return p


func _empty_slot() -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(308, 86)
	p.add_theme_stylebox_override("panel", Forge.flat(Color(Forge.PLAQUE, 0.5), Color(Forge.BRONZE, 0.6), 2, Vector4(18, 14, 18, 14)))
	var h := Forge.hbox(14)
	p.add_child(h)
	var d := Control.new()
	d.custom_minimum_size = Vector2(28, 28)
	d.size_flags_vertical = SIZE_SHRINK_CENTER
	d.draw.connect(func(): Forge.diamond(d, Vector2(14, 14), 12, Forge.GOLD_DEEP, false))
	h.add_child(d)
	var l := Forge.sc("empty slot", 22, Forge.DIM)
	l.size_flags_vertical = SIZE_SHRINK_CENTER
	h.add_child(l)
	return p


## A loose augment with what it does and one equip choice per skill it fits.
func _loose_row(aug: String, skills: Array, can_equip: bool) -> Control:
	var a: Dictionary = Data.AUGS[aug]
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Forge.flat(Color(Forge.PLAQUE, 0.85), Color(Forge.BRONZE, 0.7), 2, Vector4(20, 14, 20, 14)))
	var v := Forge.vbox(6)
	p.add_child(v)
	var top := Forge.hbox(12)
	v.add_child(top)
	var d := Control.new()
	d.custom_minimum_size = Vector2(22, 22)
	d.size_flags_vertical = SIZE_SHRINK_CENTER
	d.draw.connect(func(): Forge.diamond(d, Vector2(11, 11), 10, Forge.ELEM[a.fam]))
	top.add_child(d)
	top.add_child(Forge.sc(a.name, 24, Forge.PARCHMENT))
	var n := app.col.loose.count(aug)
	if n > 1:
		top.add_child(Forge.label("×%d" % n, 22, Forge.LABEL, Forge.SANS_BOLD))
	var desc := Forge.label(a.desc, 22, Forge.MUTED)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 580
	v.add_child(desc)
	var row := Forge.hbox(24)
	v.add_child(row)
	var any := false
	for i in skills.size():
		if Data.fits(aug, skills[i]):
			any = true
			var b := Forge.link("equip on " + skills[i].name, "", 20)
			b.custom_minimum_size.y = 52
			b.disabled = not can_equip
			b.tooltip_text = "" if can_equip else "No free slot. A higher star gives another."
			b.pressed.connect(func():
				if app.col.slot_aug(uid, i, aug):
					status = ""
				_changed())
			row.add_child(b)
	if not any:
		row.add_child(Forge.label("Fits none of %s’s skills." % Data.hero(hero).name, 20, Forge.DIM, Forge.SANS_ITALIC))
	return p


## A wrapping line of explanation; unwrapped text would push the page wider than the screen.
func _para(text: String) -> Label:
	var l := Forge.label(text, 24, Forge.MUTED)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 600
	return l


func _unique(list: Array) -> Array:
	var out := []
	for x in list:
		if not x in out:
			out.append(x)
	return out


func _changed() -> void:
	refresh()
	changed.emit()
