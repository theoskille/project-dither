class_name DungeonData
extends Resource

## Complete dungeon definition with multiple floors
## Each dungeon is a predefined Resource (.tres file) loaded by DungeonDatabase

@export var dungeon_id: String = ""
@export var dungeon_name: String = ""

@export var floors: Array[FloorData] = []

## Get total number of floors
func get_floor_count() -> int:
	return floors.size()

## Get floor data for specific floor number (1-indexed)
func get_floor(floor_number: int) -> FloorData:
	if floor_number < 1 or floor_number > floors.size():
		push_error("Invalid floor number: %d (dungeon has %d floors)" % [floor_number, floors.size()])
		return null
	return floors[floor_number - 1]

## Check if this is the final floor
func is_final_floor(floor_number: int) -> bool:
	return floor_number >= floors.size()
