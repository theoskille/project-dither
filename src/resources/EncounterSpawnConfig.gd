class_name EncounterSpawnConfig
extends Resource

## Configuration for encounter spawn probability within a floor
## Used by FloorData to define weighted encounter pools

@export var encounter_id: String = ""
@export var weight: float = 1.0  ## Higher weight = more common (will be normalized)

## Helper function to get normalized probability for display/debug
func get_probability(total_weight: float) -> float:
	if total_weight <= 0:
		return 0.0
	return weight / total_weight
