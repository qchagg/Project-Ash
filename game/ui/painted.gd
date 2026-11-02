class_name Painted
extends TextureRect
## One painted background, covering its parent and dimmed so what stands on it reads. In the web build the art ships
## beside the page (see Clips), so it fades in when it arrives; until then the element's glow shows through.

## Dark enough that whoever stands on a painting lifts clear of it; every screen shares this one level.
const DIM := Color(0.36, 0.36, 0.36)
const FADE := 0.5

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
	return self


## Repeats a seamless texture at its own size instead of covering with a painting.
func tiled(path: String) -> Painted:
	src = path
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
