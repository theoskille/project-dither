extends "res://src/ui/EntityPanel.gd"

# Player-specific panel (inherits all functionality from EntityPanel)
# Simply sets entity_name to "player" by default

func _init():
	entity_name = "player"
