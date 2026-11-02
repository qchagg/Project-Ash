class_name Screen
extends Control
## A top-level screen behind one of the tabs: its title at the top and a scrolling body. The app owns the nav.
## Subclasses set `tab` and `title` and fill the body in _build().

var app: App
## Which tab this screen sits behind (lights up in the tab bar).
var tab := ""
var title := ""
## The scrolling column to fill, inside the screen's margins.
var body: VBoxContainer
## The row beside the title, for resource chips or a link.
var head_right: HBoxContainer
## The title and scrolling body together, so a screen can step aside for a view of its own.
var frame: Control
## A painting to stand behind the whole screen, dimmed so what's on it reads. Empty for none.
var backdrop := ""
## The road whose ground this screen stands on, if it has one (Backdrop.GROUNDS). Empty for none.
var ground := ""
## Stand on plain ink instead of home's scene, for a page whose own pictures should carry it.
var black := false
## The room around every screen's page: the side margins and the gap between what stands in its body, wide and phone.
const SIDE := Vector2(124, 44)
const BODY_GAP := Vector2(48, 44)


func setup(a: App) -> Screen:
	app = a
	return self


func _ready() -> void:
	if black:
		var ink := ColorRect.new()
		ink.color = Forge.INK
		ink.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(ink)
		ink.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var art := Painted.new().setup(backdrop) if backdrop != "" else Backdrop.ground(ground)
	if art:
		add_child(art)
		art.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var root := Forge.vbox(0)
	root.set_anchors_preset(PRESET_FULL_RECT)
	add_child(root)
	frame = root
	# A wide screen has height to spare for nothing, so the title sits tighter there.
	var wide := Forge.wide()
	var side := int(SIDE.x if wide else SIDE.y)
	var head := Forge.margins(MarginContainer.new(), side, 44 if wide else 64, side, 18 if wide else 28)
	root.add_child(head)
	var top := Forge.hbox(14)
	head.add_child(top)
	top.add_child(Forge.sc(title, 40 if wide else 52, Forge.GOLD, true, 0.16))
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
	var pad := Forge.margins(MarginContainer.new(), side, 16, side, 48) if wide else Forge.margins(MarginContainer.new(), side, 20, side, 72)
	pad.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(pad)
	body = Forge.vbox(int(BODY_GAP.x if wide else BODY_GAP.y))
	pad.add_child(body)
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
