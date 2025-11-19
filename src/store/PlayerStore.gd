extends Node

## Store for persistent player data
## Holds player stats, equipped attacks, and passive abilities
## Data persists across dungeon rooms and combat encounters
## Emits signals when player data changes

signal state_changed(property_path: String, old_value, new_value)

# Player persistent data
var base_stats: Dictionary = {
	"str": 10,
	"dex": 8,
	"int": 12,
	"con": 9,
	"spd": 7,
	"luck": 5
}

var equipped_attacks: Array[String] = [
	"slash",
	"magic_bolt",
	"dash_strike",
	"knockback_strike"
]

var passive_abilities: Array[String] = [
	"bloodthirst"
]

func _ready():
	pass  # Player data initialized with default values

func get_state_value(property_path: String):
	return _get_nested_property(self, property_path)

func _emit_change(property_path: String, old_value, new_value):
	state_changed.emit(property_path, old_value, new_value)

func _get_nested_property(obj, path: String):
	var parts = path.split(".")
	var current = obj

	for part in parts:
		if current == null:
			return null
		if current is Dictionary:
			current = current.get(part)
		else:
			current = current.get(part)

	return current
