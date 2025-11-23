class_name FloorData
extends Resource

## Configuration for a single floor within a dungeon
## Defines room count, boss, and weighted encounter pool

@export var floor_number: int = 1
@export var room_count: int = 27  ## Exact number of rooms to generate

@export var boss_encounter_id: String = ""  ## Encounter to spawn in boss room

@export var available_encounters: Array[EncounterSpawnConfig] = []  ## Weighted pool of encounters

@export var guaranteed_shop_count: int = 1  ## Number of guaranteed shop rooms

## Calculate total weight for probability normalization
func get_total_encounter_weight() -> float:
	var total = 0.0
	for config in available_encounters:
		total += config.weight
	return total

## Get a random encounter_id from the weighted pool
func select_random_encounter() -> String:
	if available_encounters.is_empty():
		return ""

	var total_weight = get_total_encounter_weight()
	if total_weight <= 0:
		return ""

	var rand_val = randf() * total_weight
	var cumulative = 0.0

	for config in available_encounters:
		cumulative += config.weight
		if rand_val <= cumulative:
			return config.encounter_id

	# Fallback to first encounter if something goes wrong
	return available_encounters[0].encounter_id
