extends Node

## Game logic for dungeon exploration
## Handles dungeon generation, navigation, and encounter triggering
## Emits signals for view transitions

signal encounter_triggered(encounter_id: String)
signal dungeon_completed()
signal boss_defeated()
signal floor_completed(floor_number: int)  # Emitted when non-final floor boss defeated

var _exit_room_id: String = ""  # Tracks the designated exit room
var _current_dungeon_data: DungeonData = null  # Current dungeon being played

# Generate a sparse grid-based maze dungeon (organic layout using grow-and-branch)
func generate_grid_dungeon(rows: int = 10, cols: int = 10, floor_data: FloorData = null):
	var rooms_dict = {}

	# Use FloorData if provided, otherwise use legacy hardcoded values
	var target_room_count: int
	var boss_encounter: String
	var guaranteed_shop_count: int

	if floor_data:
		target_room_count = floor_data.room_count
		boss_encounter = floor_data.boss_encounter_id
		guaranteed_shop_count = floor_data.guaranteed_shop_count
	else:
		# Legacy hardcoded values
		target_room_count = int(rows * cols * 0.55)
		boss_encounter = "foundry_9_foundry_heart"
		guaranteed_shop_count = 1

	# Step 1: Grow dungeon organically using "grow-and-branch" algorithm
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
			room.encounter_id = boss_encounter
			room.room_type = "boss"
		else:
			# Randomly assign encounter from weighted pool
			room.room_type = "normal"

			if floor_data:
				# Use FloorData weighted selection
				room.encounter_id = floor_data.select_random_encounter()
			else:
				# Legacy: Use hardcoded probabilities
				var combat_encounters = [
					"foundry_1_rust_mite", "foundry_2_slag_hauler", "foundry_3_sentry_pair",
					"foundry_4_molten_guard", "foundry_5_hauler_support", "foundry_6_sentry_squad",
					"foundry_7_weaver_core", "foundry_8_forge_warden"
				]
				var narrative_encounters = [
					"narrative_forge_sentinel", "narrative_memory_core",
					"narrative_living_metal_pool", "narrative_whispering_machinery"
				]
				var combat_chance = 0.65
				var narrative_chance = 0.15

				var roll = randf()
				if roll < combat_chance:
					room.encounter_id = combat_encounters[randi() % combat_encounters.size()]
				elif roll < combat_chance + narrative_chance:
					room.encounter_id = narrative_encounters[randi() % narrative_encounters.size()]
				else:
					room.encounter_id = ""

	# Step 5: Ensure guaranteed shop placement
	# Count existing shops from random spawns
	var shop_rooms = []
	for room_id in rooms_dict.keys():
		if rooms_dict[room_id].encounter_id == "shop_encounter":
			shop_rooms.append(room_id)

	# Get list of eligible rooms for shop placement (not start, not boss, not already shop)
	var eligible_rooms = []
	for room_id in rooms_dict.keys():
		var room = rooms_dict[room_id]
		if room_id != "room_0_0" and room_id != exit_room_id and room.encounter_id != "shop_encounter":
			eligible_rooms.append(room_id)

	# Place shops to meet guaranteed count
	while shop_rooms.size() < guaranteed_shop_count and eligible_rooms.size() > 0:
		var random_room_id = eligible_rooms[randi() % eligible_rooms.size()]
		rooms_dict[random_room_id].encounter_id = "shop_encounter"
		shop_rooms.append(random_room_id)
		eligible_rooms.erase(random_room_id)
		print("DungeonEngine: Placed shop %d/%d in %s" % [shop_rooms.size(), guaranteed_shop_count, random_room_id])

	print("DungeonEngine: Final shop count: %d" % shop_rooms.size())

	# Step 6: Guarantee narrative encounter in first adjacent room (legacy mode only)
	if not floor_data:
		var narrative_encounters = [
			"narrative_forge_sentinel", "narrative_memory_core",
			"narrative_living_metal_pool", "narrative_whispering_machinery"
		]
		var adjacent_positions = [
			Vector2i(0, 1),   # South
			Vector2i(0, -1),  # North
			Vector2i(1, 0),   # East
			Vector2i(-1, 0)   # West
		]

		var first_adjacent_room_id = ""
		for adj_pos in adjacent_positions:
			var potential_room_id = "room_%d_%d" % [adj_pos.y, adj_pos.x]
			if rooms_dict.has(potential_room_id):
				first_adjacent_room_id = potential_room_id
				break

		if first_adjacent_room_id != "":
			var narrative_index = randi() % narrative_encounters.size()
			rooms_dict[first_adjacent_room_id].encounter_id = narrative_encounters[narrative_index]
			print("DungeonEngine: Guaranteed narrative '%s' in second room '%s'" % [narrative_encounters[narrative_index], first_adjacent_room_id])

	# Initialize dungeon state via mutations
	DungeonStateMutations.set_rooms(rooms_dict)
	DungeonStateMutations.set_current_room("room_0_0")
	DungeonStateMutations.mark_room_visited("room_0_0")

	var fill_percentage = float(rooms_dict.size()) / (rows * cols)
	print("DungeonEngine: Generated %dx%d sparse maze (%d rooms, %.0f%% filled)" % [rows, cols, rooms_dict.size(), fill_percentage * 100])
	print("DungeonEngine: Exit room at %s with boss: %s" % [exit_room_id, boss_encounter])
	_print_dungeon_layout()

	# Store exit room for completion check
	_exit_room_id = exit_room_id

# Start a new dungeon from DungeonData
func start_dungeon(dungeon_id: String = ""):
	# Reset player progression (level and XP) for new dungeon run
	PlayerMutations.reset_progression()

	if dungeon_id == "":
		# Legacy mode: generate without DungeonData
		print("DungeonEngine: Starting dungeon in legacy mode (no DungeonData)")
		generate_grid_dungeon(10, 10, null)
	else:
		# Load dungeon data
		_current_dungeon_data = DungeonDatabase.get_dungeon(dungeon_id)

		if not _current_dungeon_data:
			push_error("DungeonEngine: Failed to load dungeon '%s'" % dungeon_id)
			return

		print("DungeonEngine: Starting dungeon '%s' with %d floors" % [_current_dungeon_data.dungeon_name, _current_dungeon_data.get_floor_count()])

		# Initialize dungeon state
		DungeonStateMutations.set_current_dungeon(dungeon_id)
		DungeonStateMutations.set_current_floor(1)

		# Generate first floor
		var first_floor = _current_dungeon_data.get_floor(1)
		if first_floor:
			generate_grid_dungeon(10, 10, first_floor)
			print("DungeonEngine: Generated floor 1/%d" % _current_dungeon_data.get_floor_count())
		else:
			push_error("DungeonEngine: Failed to get floor 1 data")

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

	# Check if this is the final floor
	if is_final_floor():
		print("DungeonEngine: Final boss defeated - dungeon complete!")
		dungeon_completed.emit()
	else:
		var current_floor = DungeonStateStore.current_floor
		print("DungeonEngine: Floor %d boss defeated!" % current_floor)
		floor_completed.emit(current_floor)

# Check if currently on the final floor of the dungeon
func is_final_floor() -> bool:
	if not _current_dungeon_data:
		return true  # Legacy mode: always final floor

	return _current_dungeon_data.is_final_floor(DungeonStateStore.current_floor)

# Advance to the next floor (called after floor boss defeated)
func advance_to_next_floor():
	if not _current_dungeon_data:
		push_error("DungeonEngine: Cannot advance floor - no dungeon data loaded")
		return

	var current_floor = DungeonStateStore.current_floor
	var next_floor_num = current_floor + 1

	if next_floor_num > _current_dungeon_data.get_floor_count():
		push_error("DungeonEngine: Cannot advance - already on final floor")
		return

	print("DungeonEngine: Advancing from floor %d to floor %d" % [current_floor, next_floor_num])

	# Update floor number
	DungeonStateMutations.set_current_floor(next_floor_num)

	# Reset floor-specific state (preserves HP, scrap, inventory)
	DungeonStateMutations.reset_floor_state()

	# Generate new floor
	var next_floor_data = _current_dungeon_data.get_floor(next_floor_num)
	if next_floor_data:
		generate_grid_dungeon(10, 10, next_floor_data)
		print("DungeonEngine: Generated floor %d/%d (%d rooms)" % [next_floor_num, _current_dungeon_data.get_floor_count(), next_floor_data.room_count])
	else:
		push_error("DungeonEngine: Failed to get floor %d data" % next_floor_num)

# Debug: Print dungeon layout
func _print_dungeon_layout():
	print("=== Dungeon Layout ===")
	var rooms = DungeonStateStore.rooms
	for room_id in rooms.keys():
		var room = rooms[room_id]
		var encounter_text = room.encounter_id if room.encounter_id != "" else "none"
		print("  %s: encounter='%s' | connections=%s" % [room_id, encounter_text, room.connections])
	print("=====================")
