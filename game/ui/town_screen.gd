class_name TownScreen
extends Screen
## The town tab. Placeholder until its prototype lands.


func _init() -> void:
	tab = "town"
	title = "town"


func _build() -> void:
	body.add_child(Forge.label("Being built.", 26, Forge.MUTED, Forge.SANS_ITALIC))
