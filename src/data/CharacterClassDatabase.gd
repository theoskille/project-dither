extends Node

# Static database of all character class definitions
# Loads CharacterClassData resources from res://data/classes/ at startup

# Cache of all loaded classes, keyed by class_id
var _classes: Dictionary = {}

func _ready():
	_load_all_classes()

func _load_all_classes():
	var class_dir = "res://data/classes/"
	var dir = DirAccess.open(class_dir)

	if dir == null:
		push_error("CharacterClassDatabase: Failed to open directory: %s" % class_dir)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var file_path = class_dir + file_name
			var class_data = load(file_path)

			if class_data is CharacterClassData:
				if class_data.class_id == "":
					push_warning("CharacterClassDatabase: CharacterClassData at %s has no class_id set" % file_path)
				else:
					_classes[class_data.class_id] = class_data
					print("CharacterClassDatabase: Loaded class '%s' from %s" % [class_data.class_id, file_name])
			else:
				push_warning("CharacterClassDatabase: File %s is not a CharacterClassData resource" % file_path)

		file_name = dir.get_next()

	dir.list_dir_end()
	print("CharacterClassDatabase: Loaded %d classes" % _classes.size())

# Get a character class by its class_id
func get_character_class(class_id: String) -> CharacterClassData:
	if not _classes.has(class_id):
		push_error("CharacterClassDatabase: Class '%s' not found" % class_id)
		return null
	return _classes[class_id]

# Check if a character class exists
func has_character_class(class_id: String) -> bool:
	return _classes.has(class_id)

# Get all class IDs (useful for class selection UI)
func get_all_class_ids() -> Array:
	return _classes.keys()

# Get all class data (useful for class selection UI)
func get_all_classes() -> Array[CharacterClassData]:
	var classes: Array[CharacterClassData] = []
	for class_data in _classes.values():
		classes.append(class_data)
	return classes
