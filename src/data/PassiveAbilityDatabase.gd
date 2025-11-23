extends Node

# Singleton database for passive abilities
# Loads all .tres files from res://data/passives/

var _passives: Dictionary = {}

func _ready():
	_load_all_passives()

func _load_all_passives():
	var passives_dir = "res://data/passives/"
	var dir = DirAccess.open(passives_dir)

	if dir == null:
		push_warning("PassiveAbilityDatabase: passives directory not found at '%s'" % passives_dir)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.ends_with(".tres"):
			var file_path = passives_dir + file_name
			var passive = load(file_path) as PassiveAbilityData

			if passive != null:
				_passives[passive.passive_id] = passive
				print("PassiveAbilityDatabase: Loaded passive '%s' (%s)" % [passive.passive_name, passive.passive_id])
			else:
				push_error("PassiveAbilityDatabase: Failed to load passive from '%s'" % file_path)

		file_name = dir.get_next()

	dir.list_dir_end()
	print("PassiveAbilityDatabase: Loaded %d passive abilities" % _passives.size())

func has_passive(passive_id: String) -> bool:
	return _passives.has(passive_id)

func get_passive(passive_id: String) -> PassiveAbilityData:
	return _passives.get(passive_id)

func get_all_passives() -> Dictionary:
	return _passives
