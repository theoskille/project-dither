extends Node

## Store for runtime dungeon state
## Holds procedurally generated dungeon layout and player position
## Emits signals when dungeon state changes (room changes, visited flags, etc.)

signal state_changed(property_path: String, old_value, new_value)

# Runtime room class (not a Resource - generated procedurally)
class Room:
	var room_id: String
	var connections: Dictionary = {
		"north": null,
		"south": null,
		"east": null,
		"west": null
	}
	var encounter_id: String = ""  # Empty string = no encounter
	var visited: bool = false
	var room_type: String = "normal"  # "normal" or "boss"

	func _init(id: String):
		room_id = id

# Dungeon state
var rooms: Dictionary = {}  # Dictionary of Room instances, keyed by room_id
var current_room_id: String = ""

# Shop tracking
var visited_shops: Array[String] = []  # Array of room_ids where shops have been entered

# Dungeon statistics
var enemies_defeated: int = 0
var rooms_cleared: int = 0

func _ready():
	pass  # Dungeon initialized by DungeonEngine

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

# Helper to get current room
func get_current_room() -> Room:
	if rooms.has(current_room_id):
		return rooms[current_room_id]
	return null

# Helper to get a room by ID
func get_room(room_id: String) -> Room:
	if rooms.has(room_id):
		return rooms[room_id]
	return null
