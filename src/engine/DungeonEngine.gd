extends Node

## Game logic for dungeon exploration
## Handles dungeon generation, navigation, and encounter triggering
## Emits signals for view transitions

signal encounter_triggered(encounter_id: String)
signal dungeon_completed()
signal boss_defeated()

var _exit_room_id: String = ""  # Tracks the designated exit room

# Generate a sparse grid-based maze dungeon (organic layout using grow-and-branch)
func generate_grid_dungeon(rows: int = 5, cols: int = 5, fill_percentage: float = 0.55):
	var rooms_dict = {}

	# Define available encounters for random assignment
	var available_encounters = ["single_goblin", "slime_encounter", "tank_and_archer", "goblin_gang", "spider_encounter", ""]  # "" = no encounter

	# Step 1: Grow dungeon organically using "grow-and-branch" algorithm
	var total_positions = rows * cols
	var target_room_count = int(total_positions * fill_percentage)
	var selected_positions = {}
	var frontier = []  # Positions we can potentially grow from

	# Start at (0,0)
	var start_pos = Vector2i(0, 0)
	selected_positions[start_pos] = true
	frontier.append(start_pos)

	# Grow the dungeon by adding adjacent rooms
	while selected_positions.size() < target_room_count and frontier.size() > 0:
		# Pick a random position from frontier to grow from
		var frontier_index = randi() % frontier.size()
		var current_pos = frontier[frontier_index]

		# Get all unselected neighbors (N, S, E, W)
		var neighbor_offsets = [
			Vector2i(0, -1),  # North
			Vector2i(0, 1),   # South
			Vector2i(1, 0),   # East
			Vector2i(-1, 0)   # West
		]

		var available_neighbors = []
		for offset in neighbor_offsets:
			var neighbor_pos = current_pos + offset
			# Check if in bounds and not already selected
			if neighbor_pos.x >= 0 and neighbor_pos.x < cols and neighbor_pos.y >= 0 and neighbor_pos.y < rows:
				if not selected_positions.has(neighbor_pos):
					available_neighbors.append(neighbor_pos)

		if available_neighbors.size() > 0:
			# Add a random neighbor to the dungeon
			var new_pos = available_neighbors[randi() % available_neighbors.size()]
			selected_positions[new_pos] = true
			frontier.append(new_pos)

			# 60% chance to keep current position in frontier (allows branching)
			# 40% chance to remove it (creates more linear paths)
			if randf() > 0.6:
				frontier.remove_at(frontier_index)
		else:
			# No available neighbors, remove from frontier (dead end)
			frontier.remove_at(frontier_index)

	# Step 2: Create rooms only for selected positions
	for pos in selected_positions.keys():
		var room_id = "room_%d_%d" % [pos.y, pos.x]
		var room = DungeonStateStore.Room.new(room_id)
		rooms_dict[room_id] = room

	# Step 3: Generate maze using recursive backtracker (only on selected positions)
	var visited_cells = {}
	var stack = []
	var start_cell = Vector2i(0, 0)

	visited_cells[start_cell] = true
	stack.push_back(start_cell)

	# Track furthest room for exit designation
	var furthest_room_pos = start_cell
	var max_distance = 0

	while stack.size() > 0:
		var current_cell = stack.back()

		# Get unvisited neighbors (only from selected positions)
		var unvisited_neighbors = []
		var directions = [
			{"vec": Vector2i(0, -1), "dir": "north", "opposite": "south"},  # North
			{"vec": Vector2i(0, 1), "dir": "south", "opposite": "north"},   # South
			{"vec": Vector2i(1, 0), "dir": "east", "opposite": "west"},     # East
			{"vec": Vector2i(-1, 0), "dir": "west", "opposite": "east"}     # West
		]

		for dir_data in directions:
			var neighbor = current_cell + dir_data.vec
			# Check if neighbor is in selected positions AND not visited
			if selected_positions.has(neighbor) and not visited_cells.has(neighbor):
				unvisited_neighbors.append({"cell": neighbor, "data": dir_data})

		if unvisited_neighbors.size() > 0:
			# Choose random unvisited neighbor
			var chosen = unvisited_neighbors[randi() % unvisited_neighbors.size()]
			var neighbor_cell = chosen.cell
			var dir_data = chosen.data

			# Create connection between current and neighbor
			var current_room_id = "room_%d_%d" % [current_cell.y, current_cell.x]
			var neighbor_room_id = "room_%d_%d" % [neighbor_cell.y, neighbor_cell.x]

			rooms_dict[current_room_id].connections[dir_data.dir] = neighbor_room_id
			rooms_dict[neighbor_room_id].connections[dir_data.opposite] = current_room_id

			# Mark neighbor as visited and add to stack
			visited_cells[neighbor_cell] = true
			stack.push_back(neighbor_cell)

			# Track furthest room (Manhattan distance from start)
			var distance = abs(neighbor_cell.x - start_cell.x) + abs(neighbor_cell.y - start_cell.y)
			if distance > max_distance:
				max_distance = distance
				furthest_room_pos = neighbor_cell
		else:
			# Backtrack
			stack.pop_back()

	# Step 4: Assign encounters (first room always safe, furthest room is boss room)
	var exit_room_id = "room_%d_%d" % [furthest_room_pos.y, furthest_room_pos.x]

	for room_id in rooms_dict.keys():
		var room = rooms_dict[room_id]

		if room_id == "room_0_0":  # Starting room
			room.encounter_id = ""
			room.room_type = "normal"
		elif room_id == exit_room_id:  # Boss room (exit)
			room.encounter_id = "boss_encounter"
			room.room_type = "boss"
		else:
			# 75% chance of encounter in other rooms
			room.room_type = "normal"
			if randf() < 0.75:
				var encounter_index = randi() % (available_encounters.size() - 1)  # Exclude empty string
				room.encounter_id = available_encounters[encounter_index]
			else:
				room.encounter_id = ""

	# Initialize dungeon state via mutations
	DungeonStateMutations.set_rooms(rooms_dict)
	DungeonStateMutations.set_current_room("room_0_0")
	DungeonStateMutations.mark_room_visited("room_0_0")

	print("DungeonEngine: Generated %dx%d sparse maze (%d rooms, %.0f%% filled)" % [rows, cols, rooms_dict.size(), fill_percentage * 100])
	print("DungeonEngine: Exit room at %s" % exit_room_id)
	_print_dungeon_layout()

	# Store exit room for completion check
	_exit_room_id = exit_room_id

# Start a new dungeon
func start_dungeon():
	# Reset player progression (level and XP) for new dungeon run
	PlayerMutations.reset_progression()

	generate_grid_dungeon(10, 10, 0.55)  # 10x10 grid, 55% filled (organic layout)
	print("DungeonEngine: Dungeon started at room_0_0")

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

	# Check if we're at the designated exit room (furthest from start)
	if current_room.room_id == _exit_room_id:
		return true

	return false

# Check if the current room is the boss room
func is_current_room_boss() -> bool:
	var current_room = DungeonStateStore.get_current_room()
	if not current_room:
		return false

	return current_room.room_type == "boss"

# Notify that boss has been defeated (called after boss encounter is cleared)
func notify_boss_defeated():
	print("DungeonEngine: Boss defeated!")
	boss_defeated.emit()

# Debug: Print dungeon layout
func _print_dungeon_layout():
	print("=== Dungeon Layout ===")
	var rooms = DungeonStateStore.rooms
	for room_id in rooms.keys():
		var room = rooms[room_id]
		var encounter_text = room.encounter_id if room.encounter_id != "" else "none"
		print("  %s: encounter='%s' | connections=%s" % [room_id, encounter_text, room.connections])
	print("=====================")
