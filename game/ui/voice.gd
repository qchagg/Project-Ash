class_name Voice
extends RefCounted
## Who cries out in a fight: a grunt on a blow, a cry when hurt, a last sound when they fall. Each hero borrows one of the
## pack's five actors at their own pitch, so the cast sound like different people. The clips stay out of the game pack:
## audio/voice/ has a .gdignore, and in the web build they ship beside the page in sheets/ (see ui/clips.gd). A clip that
## hasn't arrived is silent. From the Super Dialogue Audio Pack by Dillon Becker, CC BY 4.0, credited in the Archive.

const DIR := "res://audio/voice/"
## Each voice's actor and pitch, by unit key; foes who share a hero's art sound like them.
const CAST := {
	"kaede": ["alex", 1.04], "brann": ["ian", 0.96], "sorrel": ["sean", 1.0], "ilse": ["karen", 1.0], "rock": ["ian", 0.72],
	"leaf": ["sean", 0.88], "snake": ["alex", 0.86], "smoke": ["ian", 1.08], "seer": ["meghan", 0.94], "caller": ["alex", 1.12],
	"golem": ["ian", 1.08], "blade": ["sean", 0.88],
}
const ACTORS := ["alex", "ian", "sean", "karen", "meghan"]
## How many clips each actor has of each sound.
const CLIPS := {"attack": 4, "hurt": 4, "fall": 2}
## How often a blow or a hurt is voiced, so a long fight isn't a shouting match. A fall always is.
const CHANCE := {"attack": 0.5, "hurt": 0.45, "fall": 1.0}
## Voices sit under the blows, and never overlap within this many milliseconds.
const LEVEL_DB := -5.0
const GAP_MS := 700

static var _streams := {}
static var _last := -10000


## Every clip, for the web build to fetch.
static func files() -> Array[String]:
	var out: Array[String] = []
	for actor in ACTORS:
		for kind in CLIPS:
			for i in CLIPS[kind]:
				out.append("%s%s-%s-%d.wav" % [DIR, actor, kind, i + 1])
	return out


## The clip this unit would use, or null if it has no voice or the clip hasn't arrived.
static func stream(actor: String, kind: String, i: int) -> AudioStream:
	var src := "%s%s-%s-%d.wav" % [DIR, actor, kind, i]
	if _streams.has(src):
		return _streams[src]
	for path in [src, Clips.SHEETS + src.get_file()]:
		if FileAccess.file_exists(path):
			var s := AudioStreamWAV.load_from_file(path)
			if s:
				_streams[src] = s
				return s
	return null


static func play(unit_key: String, kind: String) -> void:
	if not CAST.has(unit_key) or randf() > CHANCE[kind]:
		return
	var now := Time.get_ticks_msec()
	if now - _last < GAP_MS and kind != "fall":
		return
	var s := stream(CAST[unit_key][0], kind, randi_range(1, CLIPS[kind]))
	if s:
		_last = now
		Sfx.play_stream(s, CAST[unit_key][1], LEVEL_DB)
