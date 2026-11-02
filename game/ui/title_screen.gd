class_name TitleScreen
extends Control
## The first thing the game shows: its name over one painted background, picked at random each time, drifting slowly under
## that background's own air and a soft haze. It lies over the app, which is already on the main menu, and fades away
## when you begin. Playtest links skip it.

## What the world is called, here and on the loading page (web/shell.html).
const NAME := "A Thousand Roads"
const FADE := 0.45
## The art stands a little larger than it needs to, so there is always some left to drift across.
const ZOOM := 1.08
## One slow swing there and back, and the furthest it strays from the middle.
const PAN_SECONDS := 60.0
const PAN_MAX := Vector2(260, 40)
## The words fade in, then "set out" breathes.
const WAKE := 1.6
const BREATH := 4.0
const DIMMEST := 0.82
## How far the version and the sound sit from the corners.
const CORNER := 14.0
## The first screen shows the painting nearly whole: nothing stands on it but the name.
const SHADE := Color(0.84, 0.84, 0.84)

var _art: Painted
var _t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var ink := ColorRect.new()
	ink.color = Forge.INK
	ink.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	ink.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(ink)
	_art = Painted.new().setup(Backdrop.all_art().pick_random())
	add_child(_art)
	_art.set_anchors_preset(PRESET_TOP_LEFT)
	_art.modulate = Color(SHADE, 0.0)
	add_child(Forge.wash(Color(Forge.INK), Vector2(0.5, 1.0), Vector2(0.5, 0.68)))
	# Deferred, so it follows the app's own first track. A painting whose home has no road keeps that one.
	var track := Backdrop.music_of(_art.art)
	if track != "":
		Music.play.call_deferred(track)
	var air := Weather.over(_art.art)
	if air:
		air.clear = true
		add_child(air)
		air.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var m := Forge.margins(MarginContainer.new(), 40, 40, 40, 26 if Forge.wide() else 56)
	m.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(m)
	m.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var v := Forge.vbox(6)
	v.alignment = BoxContainer.ALIGNMENT_END
	v.mouse_filter = MOUSE_FILTER_IGNORE
	m.add_child(v)
	# The whole screen is the way in, so the words only need to whisper it.
	var go := Forge.sc("set out", 20, Forge.PARCHMENT)
	go.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_readable(go)
	v.add_child(go)
	var name := Forge.sc(NAME, 46 if Forge.wide() else 38, Forge.GOLD_LIGHT, false, 0.12)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_readable(name)
	v.add_child(name)
	var version := Forge.sc(App.VERSION, 16, Forge.LABEL)
	_readable(version)
	version.position = Vector2(CORNER, CORNER)
	version.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(version)
	var sound := Forge.sound_toggle()
	sound.set_anchors_and_offsets_preset(PRESET_TOP_RIGHT)
	sound.position += Vector2(-sound.custom_minimum_size.x - CORNER + 8.0, CORNER - 8.0)
	add_child(sound)
	v.modulate.a = 0.0
	var wake := create_tween()
	wake.tween_property(v, "modulate:a", 1.0, WAKE)
	var breath := go.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	breath.tween_property(go, "modulate:a", DIMMEST - 0.2, BREATH)
	breath.tween_property(go, "modulate:a", 1.0, BREATH)


func _process(delta: float) -> void:
	_t += delta
	if _art.texture == null:
		return
	var tex := _art.texture.get_size()
	var full := tex * maxf(size.x / tex.x, size.y / tex.y) * ZOOM
	_art.size = full
	_art.position = pan(full, size, _t)


## Where art of size `full` stands in a screen of size `view` after `t` seconds: swinging across the middle, never so far
## that an edge shows.
static func pan(full: Vector2, view: Vector2, t: float) -> Vector2:
	var spare := (full - view) / 2.0
	var swing := Vector2(sin(t * TAU / PAN_SECONDS), sin(t * TAU / PAN_SECONDS * 0.5 + 1.0))
	return -spare + swing * Vector2(minf(spare.x, PAN_MAX.x), minf(spare.y, PAN_MAX.y))


## A soft dark edge, so words read on any painting without a band behind them.
func _readable(l: Label) -> void:
	l.add_theme_color_override("font_outline_color", Color(Forge.INK, 0.8))
	l.add_theme_constant_override("outline_size", 7)


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed or e is InputEventKey and e.pressed:
		_begin()


func _begin() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	Sfx.play("confirm")
	var app := get_parent() as App
	if app:
		app.music()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, FADE)
	tw.tween_callback(queue_free)
