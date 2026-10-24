class_name Clips
extends RefCounted
## Heroes' video clips (idles, talk, skills) live outside the game pack, so the pack stays small and a clip costs
## nothing until it is wanted. In the editor and the checks they load from res://art/clips/; in the web build the
## export leaves them out and they ship beside the page in clips/, fetched one at a time into user:// as the app
## starts (idles first) and kept there. Until a clip has arrived, `stream` returns null and a Bust shows its still.

const DIR := "res://art/clips/"
const CACHE := "user://clips/"

static var _ready_set := {}
static var _queue: Array[String] = []
static var _http: HTTPRequest
static var _base := ""


## The clip as a playable stream, or null while it is still on its way.
static func stream(clip: String) -> VideoStream:
	var local := DIR + clip + ".ogv"
	if ResourceLoader.exists(local):
		return load(local)
	if not _ready_set.has(clip):
		return null
	var s := VideoStreamTheora.new()
	s.file = CACHE + clip + ".ogv"
	return s


static func ready(clip: String) -> bool:
	return ResourceLoader.exists(DIR + clip + ".ogv") or _ready_set.has(clip)


## Every clip the heroes name, idles first, then talk, then skills.
static func wanted() -> Array[String]:
	var out: Array[String] = []
	for kind in ["idle", "talk", "skills", "chant", "other"]:
		for f in Faces.FACES.values():
			var v: Variant = f.get(kind, [])
			for c in (v if v is Array else [v]):
				if c != "" and c not in out:
					out.append(c)
	return out


## Starts fetching what the web build doesn't have yet. `host` keeps the request node alive.
static func fetch_all(host: Node) -> void:
	if not OS.has_feature("web"):
		return
	_base = str(JavaScriptBridge.eval("new URL('clips/', document.baseURI).href", true))
	DirAccess.make_dir_recursive_absolute(CACHE)
	for c in wanted():
		if FileAccess.file_exists(CACHE + c + ".ogv"):
			_ready_set[c] = true
		else:
			_queue.append(c)
	_http = HTTPRequest.new()
	host.add_child(_http)
	_http.request_completed.connect(_arrived)
	_next()


static func _next() -> void:
	if _queue.is_empty():
		return
	var c: String = _queue[0]
	_http.download_file = CACHE + c + ".part"
	if _http.request(_base + c + ".ogv") != OK:
		_queue.pop_front()
		_next()


static func _arrived(result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	var c: String = _queue.pop_front()
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		DirAccess.rename_absolute(CACHE + c + ".part", CACHE + c + ".ogv")
		_ready_set[c] = true
	_next()
