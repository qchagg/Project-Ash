class_name Clips
extends RefCounted
## Heroes' video clips (idles, talk, skills) live outside the game pack, so the pack stays small and a clip costs
## nothing until it is wanted. In the editor and the checks they load from res://art/clips/; in the web build the
## export leaves them out and they ship beside the page in clips/ (as .ogg, a type the host serves), fetched one at a time into user:// as the app
## starts (idles first) and kept there. Until a clip has arrived, `stream` returns null and a Bust shows its still.
## Battle sprites' idle frame sheets travel the same way (in sheets/, fetched before the clips): until one has arrived,
## `sheet` returns null and the figure stands as its still sprite.

const DIR := "res://art/clips/"
const CACHE := "user://clips/"
const SHEETS := "user://sheets/"

static var _ready_set := {}
static var _queue: Array[String] = []
static var _http: HTTPRequest
static var _base := ""
static var _root := ""
static var _sheets := {}


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


## An idle frame sheet (by its res:// path) as a texture, or null while it is still on its way.
static func sheet(src: String) -> Texture2D:
	if _sheets.has(src):
		return _sheets[src]
	var tex: Texture2D = null
	if ResourceLoader.exists(src):
		tex = load(src)
	elif FileAccess.file_exists(SHEETS + src.get_file()):
		var img := Image.load_from_file(SHEETS + src.get_file())
		if img:
			tex = ImageTexture.create_from_image(img)
	if tex:
		_sheets[src] = tex
	return tex


## Every idle sheet the game's sprites use.
static func wanted_sheets() -> Array[String]:
	var out: Array[String] = []
	for key in Data.SPRITES:
		var src: String = Data.sprite_for({"key": key}).get("anim", {}).get("src", "")
		if src != "" and src not in out:
			out.append(src)
	return out


static func ready(clip: String) -> bool:
	return ResourceLoader.exists(DIR + clip + ".ogv") or _ready_set.has(clip)


## Every clip the game's heroes name, idles first, then talk, then skills.
static func wanted() -> Array[String]:
	var out: Array[String] = []
	for kind in ["idle", "talk", "skills", "chant", "other"]:
		for key in Faces.FACES:
			# Faces of characters who aren't in the game yet wait in the Asset Viewer.
			if Data.hero(key).is_empty():
				continue
			var f: Dictionary = Faces.FACES[key]
			var v: Variant = f.get(kind, [])
			for c in (v if v is Array else [v]):
				if c != "" and c not in out:
					out.append(c)
	return out


## Starts fetching what the web build doesn't have yet. `host` keeps the request node alive.
static func fetch_all(host: Node) -> void:
	if not OS.has_feature("web"):
		return
	_root = str(JavaScriptBridge.eval("new URL('./', document.baseURI).href", true))
	_base = _root + "clips/"
	DirAccess.make_dir_recursive_absolute(CACHE)
	DirAccess.make_dir_recursive_absolute(SHEETS)
	for src in wanted_sheets():
		if not ResourceLoader.exists(src) and not FileAccess.file_exists(SHEETS + src.get_file()):
			_queue.append(src)
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
	var url := _root + "sheets/" + c.get_file() if c.begins_with("res://") else _base + c + ".ogg"
	if _http.request(url) != OK:
		_queue.pop_front()
		_next()


static func _arrived(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var c: String = _queue.pop_front()
	# The web build's HTTPRequest ignores download_file, so the clip is written here, whole, before it counts.
	if result == HTTPRequest.RESULT_SUCCESS and code == 200 and body.size() > 0 and c.begins_with("res://"):
		var f := FileAccess.open(SHEETS + c.get_file(), FileAccess.WRITE)
		if f:
			f.store_buffer(body)
			f.close()
	elif result == HTTPRequest.RESULT_SUCCESS and code == 200 and body.size() > 0:
		var f := FileAccess.open(CACHE + c + ".ogv", FileAccess.WRITE)
		if f:
			f.store_buffer(body)
			f.close()
			_ready_set[c] = true
	_next()
