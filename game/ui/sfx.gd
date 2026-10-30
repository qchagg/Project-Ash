class_name Sfx
extends RefCounted
## The game's sounds: `Sfx.play("hit")` plays audio/sfx/hit.ogg, or one of its variations (hit-2.ogg, hit-3.ogg…)
## at a slightly different pitch each time, so a flurry of blows never sounds like one sample on repeat. The files
## are placeholders from tools/make-sfx.py until a pack replaces them under the same names. A cue with no file is
## silent, never an error. Sound can be turned off; the choice is kept on the device.

const DIR := "res://audio/sfx/"
const VOICES := 10
const SETTINGS := "user://sound.cfg"

static var _streams := {}
static var _players: Array[AudioStreamPlayer] = []
static var _next := 0
static var _on := -1
## When each cue last started, so ten hits landing in one beat play as a few, not a wall of noise.
static var _last := {}


## Plays a cue. `pitch` is how far the pitch may wander either way; `db` raises or lowers it.
static func play(cue: String, pitch := 0.06, db := 0.0) -> void:
	if not on():
		return
	var now := Time.get_ticks_msec()
	if now - int(_last.get(cue, -1000)) < 45:
		return
	_last[cue] = now
	var pool := variants(cue)
	if pool.is_empty() or not _ensure():
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = pool.pick_random()
	p.pitch_scale = 1.0 + randf_range(-pitch, pitch)
	p.volume_db = db
	p.play()


## The streams a cue can play: its file and any numbered variations.
static func variants(cue: String) -> Array:
	if not _streams.has(cue):
		var pool := []
		for i in 6:
			var path := DIR + (cue if i == 0 else "%s-%d" % [cue, i + 1]) + ".ogg"
			if not ResourceLoader.exists(path):
				break
			pool.append(load(path))
		_streams[cue] = pool
	return _streams[cue]


static func on() -> bool:
	if _on < 0:
		var cfg := ConfigFile.new()
		_on = 1 if cfg.load(SETTINGS) != OK or cfg.get_value("sound", "on", true) else 0
	return _on == 1


static func set_on(v: bool) -> void:
	_on = 1 if v else 0
	var cfg := ConfigFile.new()
	cfg.set_value("sound", "on", v)
	cfg.save(SETTINGS)
	if v:
		play("tap")


## Sets up the players ahead of the first sound (the app calls this as it starts).
static func warm() -> void:
	_ensure()


## The players live on the tree's root, so a sound outlives the screen that started it.
static func _ensure() -> bool:
	if _players.size() and is_instance_valid(_players[0]):
		return true
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return false
	_players.clear()
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		tree.root.add_child.call_deferred(p)
		_players.append(p)
	return false
