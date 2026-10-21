class_name ChroniclePage
extends Control
## The third page of a hero: their history and bio. Lore, home region, bonds and scars.
## Mostly empty until the lore is written and runs record what happened; each section says what will fill it.

const PAGE_H := 1560.0

var app: App
var hero := ""
var uid := ""


func setup(a: App, hero_key: String, card_uid: String) -> ChroniclePage:
	app = a
	hero = hero_key
	uid = card_uid
	return self


func _ready() -> void:
	var h := Data.hero(hero)
	var bd := Backdrop.new()
	bd.elem = h.elem
	bd.focus = Vector2(0.5, 0.0)
	bd.strength = 0.4
	bd.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bd)

	var root := Forge.margins(MarginContainer.new(), 44, 150, 44, 80)
	root.custom_minimum_size = Vector2(720, PAGE_H)
	add_child(root)
	var col := Forge.vbox(38)
	root.add_child(col)
	var head := Forge.vbox(8)
	col.add_child(head)
	head.add_child(Forge.sc("chronicle", 52, Forge.GOLD, true, 0.12))
	head.add_child(Forge.label("%s, %s" % [h.name, h.title], 26, Forge.MUTED))
	col.add_child(Forge.rule())
	col.add_child(_section("lore", "[%s’s story goes here: where they come from, what they want, what they hide.]" % h.name))
	col.add_child(_section("home region", "Not decided yet. Their region will also set the backdrop behind their art."))
	col.add_child(_section("bonds", "None yet. Friends, rivals and lovers form on runs."))
	col.add_child(_section("scars", "None. Dying twice back to back leaves a scar that only specific means can heal."))


func _section(title: String, text: String) -> Control:
	var v := Forge.vbox(10)
	v.add_child(Forge.sc(title, 24, Forge.GOLD))
	var l := Forge.label(text, 26, Color("#e2d5b6"), Forge.SANS_ITALIC)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 620
	v.add_child(l)
	return v
