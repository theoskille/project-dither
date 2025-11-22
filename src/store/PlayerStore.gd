extends Node

## Store for persistent player data
## Holds player stats, equipped attacks, and passive abilities
## Data persists across dungeon rooms and combat encounters
## Emits signals when player data changes

signal state_changed(property_path: String, old_value, new_value)
signal xp_gained(amount: int, new_total: int)
signal level_up(new_level: int)
signal skill_unlocked(skill_id: String)
signal character_class_changed(new_class_id: String)

# Player persistent data
var selected_character_class: String = ""
var level: int = 1
var current_xp: int = 0
var current_hp: int = 0  # Persistent health that carries between encounters

# Skill tree data
var skill_points: int = 0
var unlocked_skills: Array[String] = []

# Stats will be initialized from class data
var base_stats: Dictionary = {
	"str": 10,
	"dex": 10,
	"int": 10,
	"con": 10,
	"spd": 10,
	"luck": 10
}

# Attacks and passives will be granted by unlocking skills
var equipped_attacks: Array[String] = []

var passive_abilities: Array[String] = []

func _ready():
	pass  # Player data initialized with default values

## Calculate max vigor based on player level
## Formula: 2 base vigor + 1 every 5 levels
## Level 1-4: 2 vigor, Level 5-9: 3 vigor, Level 10-14: 4 vigor, etc.
func get_max_vigor_for_level() -> int:
	return 2 + int(floor(level / 5.0))

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
