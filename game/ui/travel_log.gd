class_name TravelLog
extends Control
## How far you have come: milestones rising along a chart at the foot of the screen, one for each count of wardens felled.
## A milestone you have reached is yours to claim. A wide screen climbs left to right; a phone stacks them.

const STOP_W := 190.0
const STEP := Vector2(236, -34)
const FIRST := Vector2(150, 236)
## A milestone's disc: its height and radius. Its prize and what is left to go sit tight under it, one line apart.
const DISC_H := 128.0
const DISC_R := 52.0
## How far below a stop's top the line down to the road begins, just under its words.
const LINE_FROM := 182.0

var app: App
var tab := "menu"


func setup(a: App) -> TravelLog:
	app = a
	return self


func _ready() -> void:
	_fill()


func _fill() -> void:
	for c in get_children():
		c.queue_free()
	var side := int(Screen.SIDE.x if Forge.wide() else Screen.SIDE.y)
	var m := Forge.margins(MarginContainer.new(), side, 56 if Forge.wide() else 64, side, 30)
	add_child(m)
	m.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var v := Forge.vbox(14)
	m.add_child(v)
	v.add_child(Forge.sc("Travel Log", 44, Forge.PARCHMENT, true, 0.08))
	v.add_child(Forge.sc("%d wardens felled" % app.town.felled, 20, Forge.GOLD))
	if Forge.wide():
		var field := Control.new()
		field.size_flags_vertical = SIZE_EXPAND_FILL
		field.mouse_filter = MOUSE_FILTER_IGNORE
		v.add_child(field)
		field.draw.connect(_chart.bind(field))
		for i in Town.LOG.size():
			var s := _stop(i)
			field.add_child(s)
			s.position = FIRST + STEP * i
	else:
		var scroll := ScrollContainer.new()
		scroll.size_flags_vertical = SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		v.add_child(scroll)
		var list := Forge.vbox(52)
		list.size_flags_horizontal = SIZE_EXPAND_FILL
		list.alignment = BoxContainer.ALIGNMENT_CENTER
		scroll.add_child(list)
		for i in Town.LOG.size():
			list.add_child(_stop(i))


## The road under the milestones: a thin line down from each stop, gold as far as you have come.
func _chart(field: Control) -> void:
	for i in Town.LOG.size():
		var at: Vector2 = FIRST + STEP * i + Vector2(STOP_W / 2.0, LINE_FROM)
		var foot := Vector2(at.x, field.size.y - 10)
		var c := Forge.GOLD if app.town.felled >= Town.LOG[i].at else Color(Forge.GOLD_DEEP, 0.4)
		field.draw_line(at, foot, c, 1.0, true)
		field.draw_circle(foot, 5.0, c)
		if i > 0:
			field.draw_line(Vector2(foot.x - STEP.x, foot.y), foot, c, 1.0, true)


func _stop(i: int) -> Control:
	var m: Dictionary = Town.LOG[i]
	var state := app.town.log_state(i)
	var v := Forge.vbox(2)
	v.custom_minimum_size.x = STOP_W
	var disc := Control.new()
	disc.custom_minimum_size = Vector2(STOP_W, DISC_H)
	disc.mouse_filter = MOUSE_FILTER_IGNORE
	disc.draw.connect(func():
		var c := Vector2(STOP_W / 2.0, DISC_H / 2.0)
		disc.draw_circle(c, DISC_R, Color(Forge.PLAQUE, 0.85))
		disc.draw_arc(c, DISC_R + 9, 0, TAU, 64, Forge.GOLD if state != "locked" else Color(Forge.GOLD_DEEP, 0.5), 1.5, true)
		disc.draw_string(Forge.SANS_BOLD, Vector2(0, c.y + 14), str(m.at), HORIZONTAL_ALIGNMENT_CENTER, STOP_W, 40,
			Forge.GOLD_LIGHT if state != "locked" else Forge.DIM))
	v.add_child(disc)
	# The prize and what is left to go read as one pair, pulled tight together.
	var pair := Forge.vbox(-10)
	v.add_child(pair)
	var prize := Forge.sc("%d gold" % m.gold if m.has("gold") else "a star for your lead", 18, Forge.PARCHMENT)
	prize.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pair.add_child(prize)
	if state == "ready":
		var b := Forge.ember("claim", 50)
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(func():
			app.claim_log(i)
			_fill())
		v.add_child(b)
	else:
		var l := Forge.sc("claimed" if state == "claimed" else "%d to go" % (m.at - app.town.felled), 16, Forge.LABEL)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pair.add_child(l)
	return v
