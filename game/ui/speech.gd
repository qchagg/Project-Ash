class_name Speech
extends PanelContainer
## A hero's spoken line: a dark plate with their name in their element's colour over the words, which type out while
## their talk clip plays and linger a moment after (or stay, inside a panel). Tap it to finish the line at once.

const RATE := 38.0
const LINGER := 2.6

var _text: Label
var _done := false
var _tw: Tween
var _stay := false


static func say(parent: Control, hero_key: String, line: String, width := 560.0, stay := false) -> Speech:
	var s := Speech.new()
	s._stay = stay
	s._build(Data.hero(hero_key), line, width)
	parent.add_child(s)
	return s


## A random line of the kind asked for (greet, camp…), or "" if the hero has none.
static func line_for(hero_key: String, kind: String) -> String:
	var lines: Array = Data.hero(hero_key).get("lines", {}).get(kind, [])
	return "" if lines.is_empty() else lines.pick_random()


func _build(h: Dictionary, line: String, width: float) -> void:
	custom_minimum_size.x = width
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", Forge.flat(Color(Forge.INK, 0.88), Color(Forge.ELEM[h.elem], 0.5), 2, Vector4(26, 18, 26, 20)))
	var v := Forge.vbox(8)
	add_child(v)
	v.add_child(Forge.sc(h.name, 22, Forge.ELEM[h.elem].lightened(0.25), false, 0.14))
	_text = Forge.label(line, 28, Forge.PARCHMENT, Forge.SANS_ITALIC)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size.x = width - 52
	_text.visible_ratio = 0.0
	v.add_child(_text)
	modulate.a = 0.0


func _ready() -> void:
	_tw = create_tween()
	_tw.tween_property(self, "modulate:a", 1.0, 0.15)
	_tw.tween_property(_text, "visible_ratio", 1.0, _text.text.length() / RATE)
	if not _stay:
		_tw.tween_interval(LINGER)
		_tw.tween_callback(close)


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if _text.visible_ratio < 1.0:
			_tw.kill()
			modulate.a = 1.0
			_text.visible_ratio = 1.0
			if not _stay:
				_tw = create_tween()
				_tw.tween_interval(LINGER)
				_tw.tween_callback(close)
		elif not _stay:
			close()


func close() -> void:
	if _done:
		return
	_done = true
	if _tw:
		_tw.kill()
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.25)
	t.tween_callback(queue_free)
