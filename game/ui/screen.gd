class_name Screen
extends Control
## A top-level screen behind one of the tabs: its title at the top, a scrolling body, the tab bar at the foot.
## Subclasses set `tab` and `title` and fill the body in _build().

var app: App
## Which tab this screen sits behind (lights up in the tab bar).
var tab := ""
var title := ""
## The scrolling column to fill, inside the screen's margins.
var body: VBoxContainer
## The row beside the title, for resource chips or a link.
var head_right: HBoxContainer


func setup(a: App) -> Screen:
	app = a
	return self


func _ready() -> void:
	var root := Forge.vbox(0)
	root.set_anchors_preset(PRESET_FULL_RECT)
	add_child(root)
	var head := Forge.margins(MarginContainer.new(), 44, 56, 44, 24)
	root.add_child(head)
	var top := Forge.hbox(14)
	head.add_child(top)
	top.add_child(Forge.sc(title, 52, Forge.GOLD, true, 0.16))
	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	top.add_child(spacer)
	head_right = Forge.hbox(14)
	top.add_child(head_right)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	root.add_child(scroll)
	var pad := Forge.margins(MarginContainer.new(), 44, 16, 44, 64)
	pad.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(pad)
	body = Forge.vbox(34)
	pad.add_child(body)
	root.add_child(NavBar.make(app, tab))
	_build()


## Fill `body` (and `head_right`). Called once the frame is built; call rebuild() to refill.
func _build() -> void:
	pass


func rebuild() -> void:
	for c in body.get_children():
		c.queue_free()
	for c in head_right.get_children():
		c.queue_free()
	_build()
