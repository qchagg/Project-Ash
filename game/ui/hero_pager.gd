class_name HeroPager
extends Control
## A hero's two pages stacked vertically: the character view fills the first screen, the sheet sits below it.
## Drag or scroll down past the arrow and the page snaps to the sheet; inside the sheet it scrolls freely.
## Swipe sideways for the next or previous hero, at the same level.

const PAGE_H := 1560.0
const W := 720.0
## How far a drag must travel before it counts as a swipe or a scroll rather than a tap.
const SLOP := 18.0
const SWIPE := 140.0

var app: App
var heroes: Array = []
var index := 0
var uid := ""
var on_sheet := false

var _page: Control
var _sheet: HeroSheet
var _oy := 0.0
var _max_oy := PAGE_H
var _vel := 0.0
var _press := false
var _start := Vector2.ZERO
var _last := Vector2.ZERO
var _axis := ""
var _dx := 0.0
var _tween: Tween
var _dots: Control


func setup(a: App, hero_key: String, card_uid: String, sheet := false) -> HeroPager:
	app = a
	heroes = []
	for h in Data.HEROES:
		if (app.filter == "" or h.elem == app.filter) and not app.copies(h.key).is_empty():
			heroes.append(h.key)
	if not hero_key in heroes:
		heroes.append(hero_key)
	index = heroes.find(hero_key)
	uid = card_uid
	on_sheet = sheet
	return self


func _ready() -> void:
	clip_contents = true
	_open(0)

	# Fixed over both pages: the way back and where you are in the roster.
	var back := Forge.link("roster")
	back.position = Vector2(30, 12)
	back.pressed.connect(app.show_roster)
	add_child(back)
	_dots = Control.new()
	_dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dots.position = Vector2(W / 2 - 100, 40)
	_dots.size = Vector2(200, 24)
	_dots.draw.connect(func():
		var n := heroes.size()
		for i in n:
			var x := _dots.size.x / 2 + (i - (n - 1) / 2.0) * 26
			Forge.diamond(_dots, Vector2(x, 12), 7 if i == index else 5, Forge.GOLD if i == index else Color(Forge.GOLD_DEEP, 0.45)))
	add_child(_dots)


## Builds the current hero's pages; `from` slides them in from the right (1) or left (-1).
func _open(from: int) -> void:
	var old := _page
	var key: String = heroes[index]
	var card_uid: String = uid if uid != "" and app.col.by(uid).get("hero", "") == key else app.copies(key)[0].uid
	uid = ""

	_page = Control.new()
	_page.size = Vector2(W, PAGE_H * 2)
	add_child(_page)
	move_child(_page, 0)
	var view := CharacterView.new().setup(app, key, card_uid)
	view.size = Vector2(W, PAGE_H)
	view.down_requested.connect(func(): _snap(PAGE_H))
	_page.add_child(view)
	_sheet = HeroSheet.new().setup(app, key, card_uid)
	_sheet.position = Vector2(0, PAGE_H)
	_sheet.size = Vector2(W, PAGE_H)
	_sheet.height_changed.connect(func(h: float):
		_page.size.y = PAGE_H + h
		_max_oy = maxf(PAGE_H, PAGE_H + h - PAGE_H)
		_set_oy(_oy))
	_page.add_child(_sheet)

	_oy = PAGE_H if on_sheet else 0.0
	_set_oy(_oy)
	if _dots:
		_dots.queue_redraw()
	if old and from != 0:
		_page.position.x = W * from
		var t := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		t.tween_property(_page, "position:x", 0.0, 0.32)
		t.tween_property(old, "position:x", -W * from, 0.32)
		t.chain().tween_callback(old.queue_free)
	elif old:
		old.queue_free()


func _set_oy(v: float) -> void:
	_oy = clampf(v, 0.0, _max_oy)
	if _page:
		_page.position.y = -_oy
	on_sheet = _oy >= PAGE_H - 1


func _snap(to: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_oy, _oy, to, 0.38)


func _go(step: int) -> void:
	index = posmod(index + step, heroes.size())
	_open(step)


func _process(delta: float) -> void:
	# A little glide after a flick inside the sheet.
	if not _press and absf(_vel) > 5 and _oy > PAGE_H:
		_set_oy(maxf(PAGE_H, _oy + _vel * delta))
		_vel *= pow(0.04, delta)
	elif not _press:
		_vel = 0.0


func _input(e: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if e is InputEventMouseButton and e.button_index in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_UP] and e.pressed:
		var down: bool = e.button_index == MOUSE_BUTTON_WHEEL_DOWN
		if _oy < PAGE_H - 1:
			_snap(PAGE_H if down else 0.0)
		elif not down and _oy <= PAGE_H + 1:
			_snap(0.0)
		else:
			_set_oy(maxf(PAGE_H, _oy + (90.0 if down else -90.0)))
		get_viewport().set_input_as_handled()
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_press = true
			_start = e.position
			_last = e.position
			_axis = ""
			_dx = 0.0
			_vel = 0.0
			if _tween:
				_tween.kill()
		else:
			_press = false
			var dragged := _axis != ""
			_release()
			if dragged:
				# A drag is not a tap: keep the button under the finger from firing.
				get_viewport().set_input_as_handled()
	elif e is InputEventMouseMotion and _press:
		var d: Vector2 = e.position - _last
		_last = e.position
		var total: Vector2 = e.position - _start
		if _axis == "" and total.length() > SLOP:
			_axis = "x" if absf(total.x) > absf(total.y) else "y"
		if _axis == "y":
			_set_oy(_oy - d.y)
			_vel = -d.y / maxf(get_process_delta_time(), 0.001)
		elif _axis == "x":
			_dx = total.x
			_page.position.x = _dx * 0.9


func _release() -> void:
	if _axis == "x":
		if absf(_dx) > SWIPE and heroes.size() > 1:
			_go(-1 if _dx > 0 else 1)
		else:
			create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).tween_property(_page, "position:x", 0.0, 0.25)
	elif _axis == "y" and _oy < PAGE_H:
		# Between the two pages: settle on whichever the drag was heading for.
		var going_down := _last.y < _start.y
		_snap(PAGE_H if (going_down and _oy > 120) or _oy > PAGE_H - 120 else 0.0)
