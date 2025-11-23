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

# Set the current dungeon ID
func set_current_dungeon(dungeon_id: String):
	var old_dungeon_id = DungeonStateStore.current_dungeon_id
	DungeonStateStore.current_dungeon_id = dungeon_id
	DungeonStateStore._emit_change("current_dungeon_id", old_dungeon_id, dungeon_id)

# Set the current floor number
func set_current_floor(floor_num: int):
	var old_floor = DungeonStateStore.current_floor
	DungeonStateStore.current_floor = floor_num
	DungeonStateStore._emit_change("current_floor", old_floor, floor_num)

# Reset floor-specific state for new floor generation
# Clears rooms, current_room_id, visited_shops but preserves dungeon_id and floor number
func reset_floor_state():
	var old_rooms = DungeonStateStore.rooms
	var old_current_room = DungeonStateStore.current_room_id
	var old_visited_shops = DungeonStateStore.visited_shops

	DungeonStateStore.rooms = {}
	DungeonStateStore.current_room_id = ""
	DungeonStateStore.visited_shops = []

	DungeonStateStore._emit_change("rooms", old_rooms, {})
	DungeonStateStore._emit_change("current_room_id", old_current_room, "")
	DungeonStateStore._emit_change("visited_shops", old_visited_shops, [])
