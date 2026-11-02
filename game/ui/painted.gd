class_name Painted
extends TextureRect
## One painted background, covering its parent and dimmed so what stands on it reads. In the web build the art ships
## beside the page (see Clips), so it fades in when it arrives; until then the element's glow shows through.

## Dark enough that whoever stands on a painting lifts clear of it; every screen shares this one level.
const DIM := Color(0.36, 0.36, 0.36)
const FADE := 0.5
## How each painting's light moves: clouds darken it as they pass, rays brighten it from above, and `from` says where
## across the top the rays start. A painting not listed is still, as under a roof or a sky with no cloud.
const SKY := {
	"coast": {"clouds": 0.2}, "steppe": {"clouds": 0.22}, "standing-stones": {"clouds": 0.24}, "plains-1": {"clouds": 0.22}, "plains-2": {"clouds": 0.22},
	"saltglass-1": {"clouds": 0.18}, "saltglass-2": {"clouds": 0.18}, "silk-highlands": {"clouds": 0.2}, "imperial": {"clouds": 0.16},
	"caravan": {"clouds": 0.16, "rays": 0.1, "color": Color("#ffd9a0"), "from": 0.7}, "city": {"clouds": 0.14}, "ice": {"clouds": 0.14},
	"lotus-1": {"clouds": 0.16, "rays": 0.1, "color": Color("#ffe6c8"), "from": 0.6}, "lotus-2": {"clouds": 0.16, "rays": 0.1, "color": Color("#ffe6c8"), "from": 0.4},
	"jade": {"rays": 0.14, "color": Color("#e8ffd8"), "from": 0.45}, "walking-wood": {"rays": 0.16, "color": Color("#e6f7c0"), "from": 0.6},
	"serpent-archive": {"rays": 0.14, "color": Color("#d8fff0"), "from": 0.5}, "lantern-village": {"rays": 0.08, "color": Color("#ffc8d8"), "from": 0.5},
}
const LIGHT: Shader = preload("res://ui/painting.gdshader")

## Which background this is, a key of Weather.AIR and a file in art/backgrounds/.
var art := ""
## The file it shows: the background's own, or a ground's when tiled.
var src := ""


func setup(art_name: String, shade := DIM) -> Painted:
	art = art_name
	src = Backdrop.art_path(art_name)
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	modulate = Color(shade, 0.0)
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if SKY.has(art_name):
		var sky: Dictionary = SKY[art_name]
		var m := ShaderMaterial.new()
		m.shader = LIGHT
		m.set_shader_parameter("clouds", sky.get("clouds", 0.0))
		m.set_shader_parameter("rays", sky.get("rays", 0.0))
		m.set_shader_parameter("ray_color", sky.get("color", Color.WHITE))
		m.set_shader_parameter("ray_from", sky.get("from", 0.3))
		material = m
	return self


## Repeats a seamless texture at its own size instead of covering with a painting.
func tiled(path: String) -> Painted:
	src = path
	material = null
	stretch_mode = TextureRect.STRETCH_TILE
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	return self


func _ready() -> void:
	Clips.hurry(src)


func _process(_delta: float) -> void:
	var tex := Clips.sheet(src)
	if tex:
		texture = tex
		set_process(false)
		create_tween().tween_property(self, "modulate:a", 1.0, FADE)
