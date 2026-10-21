class_name BattleScreen
extends Screen
## The battle tab. Placeholder until its prototype lands.


func _init() -> void:
	tab = "battle"
	title = "battle"


func _build() -> void:
	body.add_child(Forge.label("Being built.", 26, Forge.MUTED, Forge.SANS_ITALIC))
