class_name SquadScreen
extends Screen
## The squad tab. Placeholder until its prototype lands.


func _init() -> void:
	tab = "squad"
	title = "squad"


func _build() -> void:
	body.add_child(Forge.label("Being built.", 26, Forge.MUTED, Forge.SANS_ITALIC))
