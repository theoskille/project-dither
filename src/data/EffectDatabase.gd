extends Node

# Static database of all status effect definitions
# Loads EffectData resources from res://data/effects/ at startup

const EffectData = preload("res://src/resources/EffectData.gd")

# Cache of all loaded effects, keyed by effect_id
var _effects: Dictionary = {}

func _ready():
	_load_all_effects()

func _load_all_effects():
	var effect_dir = "res://data/effects/"
	var dir = DirAccess.open(effect_dir)

	if dir == null:
		push_error("EffectDatabase: Failed to open directory: %s" % effect_dir)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var file_path = effect_dir + file_name
			var effect = load(file_path)

			if effect is EffectData:
				if effect.effect_id == "":
					push_warning("EffectDatabase: EffectData at %s has no effect_id set" % file_path)
				else:
					_effects[effect.effect_id] = effect
					print("EffectDatabase: Loaded effect '%s' from %s" % [effect.effect_id, file_name])
			else:
				push_warning("EffectDatabase: File %s is not an EffectData resource" % file_path)

		file_name = dir.get_next()

	dir.list_dir_end()
	print("EffectDatabase: Loaded %d effects" % _effects.size())

# Get an effect by its effect_id
func get_effect(effect_id: String) -> EffectData:
	if not _effects.has(effect_id):
		push_error("EffectDatabase: Effect '%s' not found" % effect_id)
		return null
	return _effects[effect_id]

# Check if an effect exists
func has_effect(effect_id: String) -> bool:
	return _effects.has(effect_id)

# Get all effect IDs (useful for debugging or UI generation)
func get_all_effect_ids() -> Array:
	return _effects.keys()
