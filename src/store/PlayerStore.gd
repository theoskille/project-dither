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
signal item_equipped(slot: String, item_id: String)
signal item_unequipped(slot: String, item_id: String)
signal item_added(item_id: String)
signal item_removed(item_id: String)
signal scrap_changed(old_value: int, new_value: int)

# Player persistent data
var selected_character_class: String = ""
var level: int = 1
var current_xp: int = 0
var current_hp: int = 0  # Persistent health that carries between encounters
var scrap: int = 0  # Currency for shop purchases

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

# Inventory and equipment system
var inventory: Array[String] = []  # Unequipped item IDs
var equipped_weapon: String = ""  # Single weapon slot
var equipped_armor: String = ""  # Single armor slot
var equipped_accessories: Array[String] = []  # Max 3 accessory slots

func _ready():
	# Player data initialized with default values

	# Add starter items to inventory for testing
	if inventory.size() == 0:
		inventory = ["dented_metal_blade", "rusted_plating", "tarnished_gear", "repair_fluid", "repair_fluid"]
		print("PlayerStore: Initialized with starter items: %s" % inventory)

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
