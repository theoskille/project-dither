extends Node

# Static database of all attack/action definitions
# Loads ActionData resources from res://data/attacks/ at startup

const ActionData = preload("res://src/resources/ActionData.gd")

# Cache of all loaded attacks, keyed by action_id
var _attacks: Dictionary = {}

func _ready():
	_load_all_attacks()

func _load_all_attacks():
	var attack_dir = "res://data/attacks/"
	var dir = DirAccess.open(attack_dir)

	if dir == null:
		push_error("AttackDatabase: Failed to open directory: %s" % attack_dir)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var file_path = attack_dir + file_name
			var action = load(file_path)

			if action is ActionData:
				if action.action_id == "":
					push_warning("AttackDatabase: ActionData at %s has no action_id set" % file_path)
				else:
					_attacks[action.action_id] = action
					print("AttackDatabase: Loaded attack '%s' from %s" % [action.action_id, file_name])
			else:
				push_warning("AttackDatabase: File %s is not an ActionData resource" % file_path)

		file_name = dir.get_next()

	dir.list_dir_end()
	print("AttackDatabase: Loaded %d attacks" % _attacks.size())

# Get an attack by its action_id
func get_action(action_id: String) -> ActionData:
	if not _attacks.has(action_id):
		push_error("AttackDatabase: Attack '%s' not found" % action_id)
		return null
	return _attacks[action_id]

# Check if an attack exists
func has_action(action_id: String) -> bool:
	return _attacks.has(action_id)

# Get all attack IDs (useful for debugging or UI generation)
func get_all_action_ids() -> Array:
	return _attacks.keys()
