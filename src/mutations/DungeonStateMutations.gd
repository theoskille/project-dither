extends Node

## Pure state mutation functions for dungeon
## Only layer allowed to modify DungeonStateStore
## Always emits signals after mutations

# Initialize the entire dungeon layout
func set_rooms(room_dict: Dictionary):
	var old_rooms = DungeonStateStore.rooms
	DungeonStateStore.rooms = room_dict
	DungeonStateStore._emit_change("rooms", old_rooms, room_dict)

# Set the current room the player is in
func set_current_room(room_id: String):
	var old_room_id = DungeonStateStore.current_room_id
	DungeonStateStore.current_room_id = room_id
	DungeonStateStore._emit_change("current_room_id", old_room_id, room_id)

# Mark a room as visited
func mark_room_visited(room_id: String):
	var room = DungeonStateStore.get_room(room_id)
	if not room:
		push_error("DungeonStateMutations: Cannot mark non-existent room '%s' as visited" % room_id)
		return

	var property_path = "rooms.%s.visited" % room_id
	var old_visited = room.visited
	room.visited = true
	DungeonStateStore._emit_change(property_path, old_visited, true)

# Clear a room's encounter (e.g., after defeating enemies)
func clear_room_encounter(room_id: String):
	var room = DungeonStateStore.get_room(room_id)
	if not room:
		push_error("DungeonStateMutations: Cannot clear encounter for non-existent room '%s'" % room_id)
		return

	var property_path = "rooms.%s.encounter_id" % room_id
	var old_encounter_id = room.encounter_id
	room.encounter_id = ""
	DungeonStateStore._emit_change(property_path, old_encounter_id, "")

# Set a room's encounter (useful for dynamic encounter spawning later)
func set_room_encounter(room_id: String, encounter_id: String):
	var room = DungeonStateStore.get_room(room_id)
	if not room:
		push_error("DungeonStateMutations: Cannot set encounter for non-existent room '%s'" % room_id)
		return

	var property_path = "rooms.%s.encounter_id" % room_id
	var old_encounter_id = room.encounter_id
	room.encounter_id = encounter_id
	DungeonStateStore._emit_change(property_path, old_encounter_id, encounter_id)

# Set a room's type (normal or boss)
func set_room_type(room_id: String, room_type: String):
	var room = DungeonStateStore.get_room(room_id)
	if not room:
		push_error("DungeonStateMutations: Cannot set type for non-existent room '%s'" % room_id)
		return

	var property_path = "rooms.%s.room_type" % room_id
	var old_room_type = room.room_type
	room.room_type = room_type
	DungeonStateStore._emit_change(property_path, old_room_type, room_type)

# Increment enemies defeated counter
func increment_enemies_defeated():
	var old_value = DungeonStateStore.enemies_defeated
	DungeonStateStore.enemies_defeated += 1
	DungeonStateStore._emit_change("enemies_defeated", old_value, DungeonStateStore.enemies_defeated)

# Increment rooms cleared counter
func increment_rooms_cleared():
	var old_value = DungeonStateStore.rooms_cleared
	DungeonStateStore.rooms_cleared += 1
	DungeonStateStore._emit_change("rooms_cleared", old_value, DungeonStateStore.rooms_cleared)
