class_name Music
extends RefCounted
## The game's music: `Music.play("<track>")` crossfades to a looping track, and the players live on the tree's root, so
## it keeps going across screens. What plays where is the road's choice (Expedition.music_for). The licensed files stay
## out of the game pack and out of git: audio/music/ has a .gdignore, and in the web build they ship beside the page in
## music/, fetched one at a time into user:// as the app starts (see ui/clips.gd). While a track is on its way the last
## one keeps playing. Music follows the sound switch (Sfx.on).

const DIR := "res://audio/music/"
const CACHE := "user://music/"
const FADE := 1.6
## Under the sound effects, which play at 0 dB.
const LEVEL_DB := -3.0

static var _players: Array[AudioStreamPlayer] = []
static var _fades := [null, null]
static var _live := 0
## The track the game wants, and the one actually sounding.
static var _want := ""
static var _sounding := ""
static var _streams := {}
static var _queue: Array[String] = []
static var _http: HTTPRequest
static var _base := ""


static func play(track: String) -> void:
	_want = track
	sync()


static func wanted() -> String:
	return _want


static func sounding() -> String:
	return _sounding


## The track as a looping stream, or null if its file hasn't arrived.
static func stream(track: String) -> AudioStream:
	if _streams.has(track):
		return _streams[track]
	for path in [DIR + track + ".ogg", CACHE + track + ".ogg"]:
		if FileAccess.file_exists(path):
			var s := AudioStreamOggVorbis.load_from_file(path)
			if s:
				s.loop = true
				_streams[track] = s
				return s
	return null


## Brings the players in line with the wanted track and the sound switch.
static func sync() -> void:
	if not _ensure():
		return
	if not Sfx.on():
		if _sounding != "":
			_fade(_live, 0.0)
			_sounding = ""
		return
	if _want == _sounding or _want == "":
		return
	var s := stream(_want)
	if s == null:
		_hurry(_want)
		return
	if not _players[0].is_inside_tree():
		sync.call_deferred()
		return
	_fade(_live, 0.0)
	_live = 1 - _live
	var p := _players[_live]
	p.stream = s
	p.volume_linear = 0.0
	p.play()
	_fade(_live, db_to_linear(LEVEL_DB))
	_sounding = _want


## Sets up the players ahead of the first track (the app calls this as it starts).
static func warm() -> void:
	_ensure()


## Starts fetching what the web build doesn't have yet. `host` keeps the request node alive.
static func fetch_all(host: Node) -> void:
	if not OS.has_feature("web"):
		return
	_base = str(JavaScriptBridge.eval("new URL('./', document.baseURI).href", true)) + "music/"
	DirAccess.make_dir_recursive_absolute(CACHE)
	for track in Expedition.music_tracks():
		if not FileAccess.file_exists(CACHE + track + ".ogg"):
			_queue.append(track)
	_http = HTTPRequest.new()
	host.add_child(_http)
	_http.request_completed.connect(_arrived)
	_next()


## Volume is tweened linearly and ignores time_scale, so a battle's hit-stop never catches a fade.
static func _fade(i: int, to: float) -> void:
	var p := _players[i]
	if _fades[i]:
		_fades[i].kill()
	if not p.is_inside_tree():
		return
	var tw := p.create_tween().set_ignore_time_scale(true)
	tw.tween_property(p, "volume_linear", to, FADE)
	if to == 0.0:
		tw.tween_callback(p.stop)
	_fades[i] = tw


## The wanted track goes to the front of the queue, behind the one already on its way.
static func _hurry(track: String) -> void:
	var at := _queue.find(track)
	if at > 1:
		_queue.remove_at(at)
		_queue.insert(1, track)


static func _next() -> void:
	if _queue.is_empty():
		return
	if _http.request(_base + _queue[0] + ".ogg") != OK:
		_queue.pop_front()
		_next()


static func _arrived(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var track: String = _queue.pop_front()
	if result == HTTPRequest.RESULT_SUCCESS and code == 200 and body.size() > 0:
		var f := FileAccess.open(CACHE + track + ".ogg", FileAccess.WRITE)
		if f:
			f.store_buffer(body)
			f.close()
			if track == _want:
				sync()
	_next()


## Two players, so one can fade out as the other fades in.
static func _ensure() -> bool:
	if _players.size() and is_instance_valid(_players[0]):
		return true
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return false
	_players.clear()
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		tree.root.add_child.call_deferred(p)
		_players.append(p)
	return true
