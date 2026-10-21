class_name CodexScreen
extends Screen
## The codex tab. Placeholder until its prototype lands.


func _init() -> void:
	tab = "codex"
	title = "codex"


func _build() -> void:
	body.add_child(Forge.label("Being built.", 26, Forge.MUTED, Forge.SANS_ITALIC))
