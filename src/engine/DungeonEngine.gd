extends Node

## Game logic for dungeon exploration
## Handles dungeon generation, navigation, and encounter triggering
## Emits signals for view transitions

signal encounter_triggered(encounter_id: String)
signal dungeon_completed()

# Generate a simple linear dungeon (rooms in a straight east-west line)
func generate_linear_dungeon(room_count: int = 4):
	var rooms_dict = {}

	# Define available encounters for random assignment
	var available_encounters = ["goblin_ambush", "orc_patrol", "single_goblin", ""]  # "" = no encounter

	for i in range(room_count):
		var room = DungeonStateStore.Room.new("room_%d" % i)

		# Set connections (east-west line)
		if i > 0:
			room.connections["west"] = "room_%d" % (i - 1)
		if i < room_count - 1:
			room.connections["east"] = "room_%d" % (i + 1)

		# Assign encounters (first room always safe, others may have encounters)
		if i == 0:
			room.encounter_id = ""  # Starting room is safe
		else:
			# 75% chance of encounter in other rooms
			if randf() < 0.75:
				var encounter_index = randi() % (available_encounters.size() - 1)  # Exclude empty string
				room.encounter_id = available_encounters[encounter_index]
			else:
				room.encounter_id = ""

		rooms_dict["room_%d" % i] = room

	# Initialize dungeon state via mutations
	DungeonStateMutations.set_rooms(rooms_dict)
	DungeonStateMutations.set_current_room("room_0")
	DungeonStateMutations.mark_room_visited("room_0")

	print("DungeonEngine: Generated linear dungeon with %d rooms" % room_count)
	_print_dungeon_layout()

# Start a new dungeon
func start_dungeon():
	generate_linear_dungeon(4)
	print("DungeonEngine: Dungeon started at room_0")

# Move player in a direction
func move_player(direction: String) -> bool:
	var current_room = DungeonStateStore.get_current_room()
	if not current_room:
		push_error("DungeonEngine: No current room set")
		return false

	# Check if movement is valid
	var target_room_id = current_room.connections.get(direction)
	if target_room_id == null or target_room_id == "":
		print("DungeonEngine: Cannot move %s - no connection" % direction)
		return false

	# Move to new room
	DungeonStateMutations.set_current_room(target_room_id)
	DungeonStateMutations.mark_room_visited(target_room_id)

	print("DungeonEngine: Player moved %s to %s" % [direction, target_room_id])

	# Check for encounter
	var new_room = DungeonStateStore.get_room(target_room_id)
	if new_room and new_room.encounter_id != "":
		print("DungeonEngine: Encounter triggered: %s" % new_room.encounter_id)
		encounter_triggered.emit(new_room.encounter_id)

	return true

# Get valid movement directions from current room
func get_valid_directions() -> Array[String]:
	var current_room = DungeonStateStore.get_current_room()
	if not current_room:
		return []

	var valid_dirs: Array[String] = []
	for direction in ["north", "south", "east", "west"]:
		var connection = current_room.connections.get(direction)
		if connection != null and connection != "":
			valid_dirs.append(direction)

	return valid_dirs

# Check if dungeon is complete (player reached final room)
func is_dungeon_complete() -> bool:
	var current_room = DungeonStateStore.get_current_room()
	if not current_room:
		return false

	# Check if this room has no forward connections (end of linear dungeon)
	var has_forward = false
	for direction in ["north", "south", "east", "west"]:
		var connection = current_room.connections.get(direction)
		if connection != null and connection != "":
			# Check if this is a "forward" connection (not back to start)
			has_forward = true

	# For linear dungeon, check if we're at the last room
	if current_room.room_id == "room_3":  # Hardcoded for 4-room dungeon
		return true

	return false

# Debug: Print dungeon layout
func _print_dungeon_layout():
	print("=== Dungeon Layout ===")
	var rooms = DungeonStateStore.rooms
	for room_id in rooms.keys():
		var room = rooms[room_id]
		var encounter_text = room.encounter_id if room.encounter_id != "" else "none"
		print("  %s: encounter='%s' | connections=%s" % [room_id, encounter_text, room.connections])
	print("=====================")
