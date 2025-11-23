extends Node

## Movement Engine - Handles all movement validation and resolution
## Part of the Engine Layer: contains movement logic and rules

## Validates if a movement is legal (checks sentinel blocking and other rules)
## target_position: Optional. If provided, calculates end position based on direction toward target
func validate_movement(entity_id: String, movement_type: String, start_pos: int, distance: int, target_position: int = -1) -> bool:
	if distance == 0:
		return true

	var end_pos: int

	# Calculate end position (same logic as resolve_movement)
	if target_position >= 0:
		var direction = sign(target_position - start_pos)
		if direction == 0:
			end_pos = start_pos + distance
		else:
			end_pos = start_pos + (abs(distance) * direction)
	else:
		end_pos = start_pos + distance

	# Check movement type specific rules
	match movement_type:
		"dash":
			# Dash is blocked by sentinel passives
			if _is_blocked_by_sentinel(entity_id, start_pos, end_pos):
				return false
		"teleport":
			# Teleport bypasses all blocking mechanics
			pass
		"none":
			# Simple movement, no special blocking rules
			pass

	return true

## Resolves movement and returns final position and any entity encountered
## Returns: {final_position: int, hit_entity: String}
## target_position: Optional. If provided, movement direction is calculated toward target
## stop_on_collision: If true, movement stops at first entity encountered along the path
func resolve_movement(entity_id: String, movement_type: String, start_pos: int, distance: int, max_position: int, target_position: int = -1, stop_on_collision: bool = false) -> Dictionary:
	if distance == 0:
		return {
			"final_position": start_pos,
			"hit_entity": ""
		}

	var intended_end_pos: int

	# If target position is provided, calculate direction toward target
	if target_position >= 0:
		var direction = sign(target_position - start_pos)
		# If already at target position or target is invalid, use raw distance
		if direction == 0:
			intended_end_pos = clamp(start_pos + distance, 0, max_position)
		else:
			# Move toward target: apply absolute distance in target direction
			intended_end_pos = clamp(start_pos + (abs(distance) * direction), 0, max_position)
	else:
		# No target specified - use raw distance (positive = right, negative = left)
		intended_end_pos = clamp(start_pos + distance, 0, max_position)

	var final_pos = intended_end_pos
	var hit_entity = ""

	# If stop_on_collision is true, check each tile along the path
	if stop_on_collision:
		var direction = sign(intended_end_pos - start_pos)
		var current_pos = start_pos

		# Scan each tile along the path
		while current_pos != intended_end_pos:
			current_pos += direction
			var entity_at_pos = _find_entity_at_position(entity_id, current_pos)
			if entity_at_pos != "":
				# Found an entity - stop here
				final_pos = current_pos
				hit_entity = entity_at_pos
				break
	else:
		# Only check final destination
		hit_entity = _find_entity_at_position(entity_id, intended_end_pos)

	return {
		"final_position": final_pos,
		"hit_entity": hit_entity
	}

## Checks if movement is blocked by sentinel passive
## Sentinel blocks movement that would cross from one side to the other
## You can move TO sentinel tile from either side, but can't cross to the opposite side
func _is_blocked_by_sentinel(mover_id: String, start_pos: int, end_pos: int) -> bool:
	# Get all entities to check for sentinel
	var turn_order = BattleStateStore.get_state_value("turn_state.turn_order")

	for entity_id in turn_order:
		if entity_id == mover_id:
			continue  # Skip the moving entity

		var entity = _get_entity_by_id(entity_id)
		if not entity or entity.is_dead:
			continue

		# Check if this entity has sentinel passive
		if "sentinel" not in entity.passive_abilities:
			continue

		var sentinel_pos = entity.position

		# Determine if movement crosses to the opposite side of the sentinel
		# Blocked if: start and end are on opposite sides of sentinel (sentinel is between them)
		# OR if starting from sentinel and moving away from it
		var min_pos = min(start_pos, end_pos)
		var max_pos = max(start_pos, end_pos)

		# Case 1: Sentinel is strictly between start and end - blocks crossing
		if sentinel_pos > min_pos and sentinel_pos < max_pos:
			print("MovementEngine: Movement blocked - would cross sentinel at position %d (entity: %s)" % [sentinel_pos, entity_id])
			return true

		# Case 2: Starting from sentinel position - check if moving to opposite side
		# Start at sentinel, moving away means we're trying to cross to the other side
		if start_pos == sentinel_pos and end_pos != sentinel_pos:
			print("MovementEngine: Movement blocked - cannot leave sentinel position %d to reach %d (entity: %s)" % [sentinel_pos, end_pos, entity_id])
			return true

	return false

## Finds which entity (if any) is at the specified position
func _find_entity_at_position(exclude_entity_id: String, position: int) -> String:
	var turn_order = BattleStateStore.get_state_value("turn_state.turn_order")

	for entity_id in turn_order:
		if entity_id == exclude_entity_id:
			continue

		var entity = _get_entity_by_id(entity_id)
		if entity and not entity.is_dead and entity.position == position:
			return entity_id

	return ""

## Helper function to get entity by ID
func _get_entity_by_id(entity_id: String) -> EntityState:
	if entity_id == "player":
		return BattleStateStore.battle_state.player_state
	elif entity_id.begins_with("enemy_"):
		var index = int(entity_id.split("_")[1])
		if index >= 0 and index < BattleStateStore.battle_state.enemies.size():
			return BattleStateStore.battle_state.enemies[index]
	return null
