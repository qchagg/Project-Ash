class_name EvolvePage
extends Control
## Evolve or equip, opened from the sheet's buttons and sliding up over the hero.
## Evolve: copies, feeding (a two-step commit: Feed, pick a copy and see the result, Confirm), the Ashcrown, field or bench.
## Equip: one augment slot per star, and the loose augments that fit.

const PAGE_H := 1560.0
const TIERS := ["bronze", "silver", "gold", "ashcrown"]

var app: App
## "evolve" or "equip".
var mode := "evolve"
var hero := ""
var uid := ""
var feeding := false
var fodder := ""
var status := ""
var _ui: Control

signal height_changed(h: float)
## The card changed (merged, crowned, re-equipped, fielded): the pages above should refresh.
signal changed
## A different copy is now the one being looked at.
signal viewing(card_uid: String)
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
	var how := "Feed a copy of the same stars to rise a star." if c.stars < 3 else (
		"An Ashcrown takes a 3★ to 4★. You have %d." % app.col.crowns if c.stars == 3 else "Fully evolved.")
	v.add_child(_para(how))

	var copies := app.copies(hero)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	for cp in copies:
		grid.add_child(_thumb(cp))
	v.add_child(grid)

	var after := _preview()
	if not after.is_empty():
		v.add_child(_preview_panel(app.col.stats(c), after, c.stars + 1))

	var msg := status
	if msg == "" and feeding:
		msg = "Choose a copy to feed into this one." if fodder == "" else "Confirm to feed it in."
	if msg != "":
		var l := Forge.label(msg, 24, Forge.GOLD, Forge.SANS_ITALIC)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l)

	var act := Forge.hbox(24)
	v.add_child(act)
	var field := Forge.ember("bench" if uid in app.col.squad else "field")
	field.tooltip_text = "Take this copy off the field" if uid in app.col.squad else "Put this copy on the field"
	field.pressed.connect(func():
		status = app.col.toggle_field(uid)
		_changed())
	act.add_child(field)
	if feeding:
		var cancel := Forge.link("cancel", "")
		cancel.pressed.connect(func():
			feeding = false
			fodder = ""
			status = ""
			refresh())
		act.add_child(cancel)
	var sp := Control.new()
	sp.size_flags_horizontal = SIZE_EXPAND_FILL
	act.add_child(sp)
	var commit := _commit(c, copies)
	if commit:
		act.add_child(commit)
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


## The one commit on this page: feed below 3★, the Ashcrown at 3★, nothing at 4★.
func _commit(c: Dictionary, copies: Array) -> Button:
	if c.stars == 3:
		var b := Forge.studs("ashcrown")
		b.disabled = app.col.crowns < 1
		b.tooltip_text = "Spend an Ashcrown to take %s to 4★." % Data.hero(hero).name
		b.pressed.connect(func():
			if app.col.crown(uid):
				status = "The Ashcrown takes %s to 4★." % Data.hero(hero).name
				_celebrate()
			_changed())
		return b
	if c.stars >= 4:
		return null
	var b := Forge.studs("confirm feed" if feeding and fodder != "" else "feed")
	if not feeding:
		b.disabled = not copies.any(func(o): return o.uid != uid and o.stars == c.stars)
		b.tooltip_text = "Needs another %d★ copy." % c.stars if b.disabled else ""
		b.pressed.connect(func():
			feeding = true
			status = ""
			refresh())
	else:
		b.disabled = fodder == ""
		b.pressed.connect(func():
			var r := app.col.merge(uid, fodder)
			status = "%s rises to %d★." % [Data.hero(hero).name, _card().stars] if r.ok else r.msg
			if r.ok:
				_celebrate()
			feeding = false
			fodder = ""
			_changed())
	return b


func _thumb(cp: Dictionary) -> Control:
	var t := Control.new()
	t.custom_minimum_size = Vector2(144, 192)
	t.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var tex: Texture2D = load(Data.hero(hero).portrait.src)
	var can_feed: bool = feeding and cp.uid != uid and cp.stars == _card().stars
	t.tooltip_text = "%d★%s" % [cp.stars, " · on the field" if cp.uid in app.col.squad else ""]
	t.draw.connect(func():
		var r := Rect2(Vector2.ZERO, t.size)
		Forge.portrait(t, tex, r, Data.hero(hero).portrait, 0.62, "card")
		if feeding and cp.uid != uid and not can_feed:
			t.draw_rect(r, Color(Forge.INK, 0.65))
		var ring: Color = Data.TIER_COLORS[cp.stars]
		var w := 2.0
		if cp.uid == uid:
			ring = Forge.GOLD_LIGHT
			w = 5.0
		elif cp.uid == fodder:
			ring = Forge.GAIN
			w = 5.0
		elif can_feed:
			ring = Color(Forge.GAIN, 0.6)
			w = 3.0
		t.draw_rect(r.grow(-w / 2), ring, false, w)
		var cap := Rect2(0, t.size.y - 38, t.size.x, 38)
		t.draw_rect(cap, Color(Forge.INK, 0.85))
		var tag := "%d★" % cp.stars
		if cp.uid == uid: tag = "this"
		elif cp.uid == fodder: tag = "feed"
		elif cp.uid in app.col.squad: tag = "%d★ field" % cp.stars
		t.draw_string(Forge.tracked(Forge.SC, 2), Vector2(0, t.size.y - 11), tag, HORIZONTAL_ALIGNMENT_CENTER, t.size.x, 21,
			Forge.GOLD_LIGHT if cp.uid == uid else (Forge.GAIN if cp.uid == fodder else Forge.MUTED)))
	t.gui_input.connect(func(e: InputEvent):
		if not (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
			return
		status = ""
		if feeding:
			if can_feed:
				fodder = "" if fodder == cp.uid else cp.uid
			elif cp.uid != uid:
				status = "Only another %d★ copy can feed this one." % _card().stars
			refresh()
		elif cp.uid != uid:
			uid = cp.uid
			viewing.emit(uid)
			refresh())
	return t


## Before → after for each stat, shown once a copy to feed is chosen.
func _preview_panel(before: Dictionary, after: Dictionary, stars: int) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Forge.flat(Color(Forge.PLAQUE, 0.92), Forge.GAIN, 2, Vector4(26, 18, 26, 18)))
	var v := Forge.vbox(10)
	p.add_child(v)
	v.add_child(Forge.sc("becomes %d★" % stars, 22, Forge.GAIN))
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


## Runs the merge on a copy of the collection so the page can show the result before you commit.
func _preview() -> Dictionary:
	if not feeding or fodder == "":
		return {}
	var copy := Collection.new()
	copy.cards = app.col.cards.duplicate(true)
	copy.loose = app.col.loose.duplicate()
	copy.squad = app.col.squad.duplicate()
	copy.merge_mode = app.col.merge_mode
	var r := copy.merge(uid, fodder)
	return r.after if r.ok else {}


# ---- Equipment ----

## One augment slot per star. Free augments come off with a tap; a merge sets them for good.
func _equipment(c: Dictionary) -> Control:
	var v := Forge.vbox(22)
	v.add_child(_para("One augment slot per star. Augments swap freely until a merge sets them."))
	var skills: Array = Data.hero(hero).skills
	var slots := GridContainer.new()
	slots.columns = 2
	slots.add_theme_constant_override("h_separation", 16)
	slots.add_theme_constant_override("v_separation", 16)
	v.add_child(slots)
	for i in c.stars:
		if i < c.augs.size():
			var a: Dictionary = c.augs[i]
			slots.add_child(_aug_slot(a.aug, skills[a.skill].name, a.get("locked", false), i))
		else:
			slots.add_child(_empty_slot())

	var free: int = c.stars - c.augs.size()
	v.add_child(Forge.sc("loose augments · %d" % app.col.loose.size(), 22, Forge.LABEL))
	if app.col.loose.is_empty():
		v.add_child(Forge.label("None left. Merges and runs return them.", 24, Forge.MUTED, Forge.SANS_ITALIC))
	for aug in _unique(app.col.loose):
		v.add_child(_loose_row(aug, skills, free > 0))
	return v


func _aug_slot(aug: String, skill_name: String, locked: bool, j: int) -> Control:
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
	t.add_child(Forge.label(("set on " if locked else "on ") + skill_name, 20, Forge.MUTED))
	if not locked:
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


func _celebrate() -> void:
	if Faces.of(hero).get("chant", "") != "":
		CutIn.play(app, hero, Faces.of(hero).chant)


func _changed() -> void:
	refresh()
	changed.emit()
