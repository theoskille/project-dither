extends Node

# Static database of all encounter definitions
# Loads EncounterData resources from res://data/encounters/ at startup

const EncounterData = preload("res://src/resources/EncounterData.gd")

# Cache of all loaded encounters, keyed by encounter_id
var _encounters: Dictionary = {}

func _ready():
	_load_all_encounters()

func _load_all_encounters():
	var encounter_dir = "res://data/encounters/"
	var dir = DirAccess.open(encounter_dir)

	if dir == null:
		push_error("EncounterDatabase: Failed to open directory: %s" % encounter_dir)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var file_path = encounter_dir + file_name
			var encounter = load(file_path)

			if encounter is EncounterData:
				if encounter.encounter_id == "":
					push_warning("EncounterDatabase: EncounterData at %s has no encounter_id set" % file_path)
				else:
					_encounters[encounter.encounter_id] = encounter
					print("EncounterDatabase: Loaded encounter '%s' from %s" % [encounter.encounter_id, file_name])
			else:
				push_warning("EncounterDatabase: File %s is not an EncounterData resource" % file_path)

		file_name = dir.get_next()

	dir.list_dir_end()
	print("EncounterDatabase: Loaded %d encounters" % _encounters.size())

# Get an encounter by its encounter_id
func get_encounter(encounter_id: String) -> EncounterData:
	if not _encounters.has(encounter_id):
		push_error("EncounterDatabase: Encounter '%s' not found" % encounter_id)
		return null
	return _encounters[encounter_id]

# Check if an encounter exists
func has_encounter(encounter_id: String) -> bool:
	return _encounters.has(encounter_id)

# Get all encounter IDs (useful for debugging or random selection)
func get_all_encounter_ids() -> Array:
	return _encounters.keys()
