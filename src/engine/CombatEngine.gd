extends Node

## Signals
signal battle_ended()  # Emitted when all enemies are defeated

# Reset battle state to clean slate (call before starting new encounter)
func reset_battle():
	print("CombatEngine: Resetting battle state")
	BattleStateMutations.clear_enemies()
	BattleStateMutations.reset_turn_state()
	BattleStateMutations.reset_player()
	print("CombatEngine: Battle state reset complete")

func initialize_enemies(enemy_configs: Array):
	for config in enemy_configs:
		var enemy_id = config.get("enemy_id", "")
		var position = config.get("position", 5)

		var enemy_data = EnemyDatabase.get_enemy(enemy_id)
		if enemy_data == null:
			push_error("CombatEngine: Cannot initialize enemy - enemy_id '%s' not found" % enemy_id)
			continue

		BattleStateMutations.add_enemy_to_battle(enemy_data, position)
		print("CombatEngine: Initialized enemy '%s' at position %d" % [enemy_data.enemy_name, position])

func execute_move(action_data: ActionData, caster: String, target: String) -> bool:
	if not can_execute_action(action_data, caster, target):
		return false
	
	BattleStateMutations.consume_vigor(caster, action_data.vigor_cost)
	return _perform_action(action_data, caster, target)

func execute_move_legacy(move_data: Dictionary, caster: String, target: String):
	return _perform_action_legacy(move_data, caster, target)

func _perform_action(action_data: ActionData, caster_id: String, target_id: String) -> bool:
	var damage = _calculate_damage_from_action(action_data, caster_id)

	if damage > 0:
		var target_entity = _get_entity_by_id(target_id)
		if target_entity:
			var new_hp = max(0, target_entity.current_hp - damage)
			BattleStateMutations.set_entity_hp(target_id, new_hp)

			# Check for death and trigger on_kill passives
			if new_hp == 0:
				_trigger_passives(caster_id, "on_kill", target_id)
				_check_victory()

	# Get battlefield size for boundary clamping
	var max_position = BattleStateStore.get_state_value("battlefield.total_tiles") - 1

	# Track collision entity for damage application
	var collision_entity_id = ""

	# Move caster if specified
	if action_data.move_caster != 0:
		var caster_entity = _get_entity_by_id(caster_id)
		if caster_entity:
			var new_pos = 0

			# Check for collision-based movement
			if action_data.stop_on_collision:
				collision_entity_id = _find_collision_entity(caster_id, caster_entity.position, action_data.move_caster)

				if collision_entity_id != "":
					# Collision detected - move to collision entity's position
					var collision_entity = _get_entity_by_id(collision_entity_id)
					new_pos = collision_entity.position
					print("CombatEngine: %s dashed and collided with %s at position %d" % [caster_id, collision_entity_id, new_pos])
				else:
					# No collision - move full distance (clamped to boundaries)
					new_pos = clamp(caster_entity.position + action_data.move_caster, 0, max_position)
					print("CombatEngine: %s dashed full distance to position %d (no collision)" % [caster_id, new_pos])
			else:
				# Normal movement without collision detection
				new_pos = clamp(caster_entity.position + action_data.move_caster, 0, max_position)

			BattleStateMutations.set_entity_position(caster_id, new_pos)

	# Apply collision damage if a collision occurred
	if collision_entity_id != "":
		var collision_damage = _calculate_damage_from_action(action_data, caster_id)
		if collision_damage > 0:
			var collision_target = _get_entity_by_id(collision_entity_id)
			if collision_target:
				var new_hp = max(0, collision_target.current_hp - collision_damage)
				BattleStateMutations.set_entity_hp(collision_entity_id, new_hp)
				print("CombatEngine: Collision damage applied to %s: %d damage" % [collision_entity_id, collision_damage])

				# Check for death from collision damage
				if new_hp == 0:
					_trigger_passives(caster_id, "on_kill", collision_entity_id)
					_check_victory()

	# Move target if specified (relative to caster position)
	if action_data.move_target != 0:
		var caster_entity = _get_entity_by_id(caster_id)
		var target_entity = _get_entity_by_id(target_id)

		if caster_entity and target_entity:
			# Calculate direction: positive if target is to the right, negative if to the left
			var direction = sign(target_entity.position - caster_entity.position)

			# Apply relative movement: positive move_target = away from caster, negative = toward caster
			var new_pos = clamp(target_entity.position + (action_data.move_target * direction), 0, max_position)
			BattleStateMutations.set_entity_position(target_id, new_pos)

	if action_data.applies_effect_id != "":
		_apply_effect_to_entity(target_id, action_data.applies_effect_id, action_data.effect_duration_override)

	return true

func _perform_action_legacy(move_data: Dictionary, caster: String, target: String) -> bool:
	var damage = _calculate_damage(move_data, caster)

	var current_hp = BattleStateStore.get_state_value("%s_state.current_hp" % target)
	BattleStateMutations.set_entity_hp(target, max(0, current_hp - damage))

	# Get battlefield size for boundary clamping
	var max_position = BattleStateStore.get_state_value("battlefield.total_tiles") - 1

	if move_data.has("move_caster"):
		var current_pos = BattleStateStore.get_state_value("%s_state.position" % caster)
		var new_pos = clamp(current_pos + move_data.move_caster, 0, max_position)
		BattleStateMutations.set_entity_position(caster, new_pos)

	if move_data.has("move_target"):
		var caster_pos = BattleStateStore.get_state_value("%s_state.position" % caster)
		var target_pos = BattleStateStore.get_state_value("%s_state.position" % target)
		var direction = sign(target_pos - caster_pos)
		var new_pos = clamp(target_pos + (move_data.move_target * direction), 0, max_position)
		BattleStateMutations.set_entity_position(target, new_pos)

	if move_data.has("status_effect") and not move_data.status_effect.is_empty():
		# Legacy Dictionary-based effect application
		var effect_id = move_data.status_effect.get("id", "")
		if effect_id != "":
			var duration = move_data.status_effect.get("duration", 0)
			_apply_effect_to_entity(target, effect_id, duration)

	return true

func process_turn_end():
	_process_damage_over_time()
	_decrement_effect_durations()
	BattleStateMutations.set_turn_phase("turn_end")
	BattleStateMutations.advance_turn()
	BattleStateMutations.set_turn_phase("action")

func can_execute_action(action_data: ActionData, caster_id: String, target_id: String) -> bool:
	if not _is_entity_turn(caster_id):
		return false

	# Check if caster is blocked by status effects
	if _is_action_blocked_by_effects(caster_id, action_data.action_type):
		return false

	var caster_entity = _get_entity_by_id(caster_id)
	if not caster_entity or caster_entity.current_vigor < action_data.vigor_cost:
		return false

	var distance = _get_distance_between_entities(caster_id, target_id)
	if distance < action_data.min_range or distance > action_data.max_range:
		return false

	return true

func start_battle():
	# Generate speed-based turn order
	var turn_order = _generate_turn_order()
	BattleStateMutations.set_turn_order(turn_order)

	# Start the first turn
	if turn_order.size() > 0:
		var first_entity = turn_order[0]
		start_turn(first_entity)

func start_turn(entity_id: String):
	BattleStateMutations.restore_vigor(entity_id, 1)
	BattleStateMutations.set_turn_phase("action")

func end_turn():
	process_turn_end()
	var next_entity = _get_current_turn_entity()
	start_turn(next_entity)

func _generate_turn_order() -> Array[String]:
	var combatants = []

	# Add player
	var player = BattleStateStore.battle_state.player_state
	combatants.append({"id": "player", "spd": player.base_stats.get("spd", 0)})

	# Add all enemies
	var enemies = BattleStateStore.battle_state.enemies
	for i in range(enemies.size()):
		combatants.append({"id": "enemy_%d" % i, "spd": enemies[i].base_stats.get("spd", 0)})

	# Sort by speed (highest first)
	combatants.sort_custom(func(a, b): return a.spd > b.spd)

	# Extract IDs
	var turn_order: Array[String] = []
	for combatant in combatants:
		turn_order.append(combatant.id)

	print("CombatEngine: Generated turn order: %s" % str(turn_order))
	return turn_order

func _is_entity_turn(entity: String) -> bool:
	var current_entity = _get_current_turn_entity()
	return current_entity == entity

func _get_current_turn_entity() -> String:
	var turn_order = BattleStateStore.get_state_value("turn_state.turn_order")
	var current_index = BattleStateStore.get_state_value("turn_state.current_turn_index")
	return turn_order[current_index]

func _get_distance_between_entities(entity1_id: String, entity2_id: String) -> int:
	var entity1 = _get_entity_by_id(entity1_id)
	var entity2 = _get_entity_by_id(entity2_id)

	if not entity1 or not entity2:
		return 999  # Return large distance if entity not found

	return abs(entity1.position - entity2.position)

func _find_collision_entity(caster_id: String, start_position: int, movement: int) -> String:
	"""
	Finds the nearest entity in the movement path during a dash.
	Returns the entity_id of the first enemy encountered, or empty string if no collision.
	"""
	if movement == 0:
		return ""

	var direction = sign(movement)
	var distance = abs(movement)

	# Get all entities to check for collisions
	var turn_order = BattleStateStore.get_state_value("turn_state.turn_order")
	var nearest_entity = ""
	var nearest_distance = distance + 1  # Start beyond max dash distance

	# Check each tile in the dash path (including current position)
	for i in range(0, distance + 1):
		var check_position = start_position + (direction * i)

		# Check if any entity is at this position
		for entity_id in turn_order:
			if entity_id == caster_id:
				continue  # Skip the caster

			var entity = _get_entity_by_id(entity_id)
			if entity and entity.position == check_position:
				# Found an entity closer than previous finds
				if i < nearest_distance:
					nearest_entity = entity_id
					nearest_distance = i
					return nearest_entity  # Return immediately (stop at first collision)

	return nearest_entity

func _get_entity_by_id(entity_id: String) -> EntityState:
	if entity_id == "player":
		return BattleStateStore.battle_state.player_state
	elif entity_id.begins_with("enemy_"):
		var index = int(entity_id.split("_")[1])
		if index >= 0 and index < BattleStateStore.battle_state.enemies.size():
			return BattleStateStore.battle_state.enemies[index]
	return null

func _is_action_blocked_by_effects(entity_id: String, action_type: String) -> bool:
	var entity = _get_entity_by_id(entity_id)
	if not entity:
		return false

	for effect in entity.active_effects:
		# Check if effect blocks all actions
		if effect.blocks_all_actions:
			print("CombatEngine: %s cannot act - blocked by '%s'" % [entity_id, effect.effect_id])
			return true

		# Check if effect blocks this specific action type
		if action_type in effect.blocks_action_types:
			print("CombatEngine: %s cannot perform '%s' action - blocked by '%s'" % [entity_id, action_type, effect.effect_id])
			return true

	return false

func _calculate_damage_from_action(action_data: ActionData, caster_id: String) -> int:
	var total_damage = action_data.base_damage

	var caster = _get_entity_by_id(caster_id)
	if not caster:
		return 0

	var stats = caster.base_stats

	total_damage += int(stats.str * action_data.str_modifier)
	total_damage += int(stats.dex * action_data.dex_modifier)
	total_damage += int(stats.int * action_data.int_modifier)
	total_damage += int(stats.con * action_data.con_modifier)
	total_damage += int(stats.spd * action_data.spd_modifier)
	total_damage += int(stats.luck * action_data.luck_modifier)

	var effect_modifiers = _get_total_stat_modifier(caster_id, "str")
	total_damage += effect_modifiers

	return max(0, total_damage)

func _calculate_damage(move_data: Dictionary, caster: String) -> int:
	var base_damage = move_data.get("base_damage", 0)
	var str_stat = BattleStateStore.get_state_value("%s_state.base_stats.str" % caster)
	var str_modifier = _get_total_stat_modifier(caster, "str")
	
	return base_damage + str_stat + str_modifier

func _get_total_stat_modifier(entity_id: String, stat: String) -> int:
	var entity = _get_entity_by_id(entity_id)
	if not entity:
		return 0

	var base_stat = entity.base_stats.get(stat, 0)

	var flat_modifier = 0
	var percent_modifier = 0

	for effect in entity.active_effects:
		flat_modifier += effect.get("%s_modifier" % stat)
		percent_modifier += effect.get("percent_%s_modifier" % stat)

	# Apply formula: (base_stat + flat_mods) * (1.0 + percent_mods/100.0) - base_stat
	var modified_stat = (base_stat + flat_modifier) * (1.0 + percent_modifier / 100.0)
	return int(modified_stat) - base_stat

func _apply_effect_to_entity(entity_id: String, effect_id: String, duration_override: int = 0):
	var effect_template = EffectDatabase.get_effect(effect_id)
	if effect_template == null:
		push_error("CombatEngine: Cannot apply effect - effect_id '%s' not found" % effect_id)
		return

	# Check if effect already exists (no stacking - refresh duration instead)
	var entity = _get_entity_by_id(entity_id)
	if not entity:
		return

	for i in range(entity.active_effects.size()):
		if entity.active_effects[i].effect_id == effect_id:
			# Refresh duration
			var new_duration = duration_override if duration_override > 0 else effect_template.base_duration
			entity.active_effects[i].remaining_duration = new_duration
			var property_path = BattleStateMutations._get_entity_property_path(entity_id, "active_effects")
			BattleStateStore._emit_change(property_path, null, entity.active_effects)
			print("CombatEngine: Refreshed effect '%s' on %s (duration: %d)" % [effect_id, entity_id, new_duration])
			return

	# Create new effect instance from template
	var effect = EffectState.new()
	effect.effect_id = effect_template.effect_id
	effect.remaining_duration = duration_override if duration_override > 0 else effect_template.base_duration
	effect.str_modifier = effect_template.str_modifier
	effect.dex_modifier = effect_template.dex_modifier
	effect.int_modifier = effect_template.int_modifier
	effect.con_modifier = effect_template.con_modifier
	effect.spd_modifier = effect_template.spd_modifier
	effect.luck_modifier = effect_template.luck_modifier
	effect.percent_str_modifier = effect_template.percent_str_modifier
	effect.percent_dex_modifier = effect_template.percent_dex_modifier
	effect.percent_int_modifier = effect_template.percent_int_modifier
	effect.percent_con_modifier = effect_template.percent_con_modifier
	effect.percent_spd_modifier = effect_template.percent_spd_modifier
	effect.percent_luck_modifier = effect_template.percent_luck_modifier
	effect.damage_per_turn = effect_template.base_damage_per_turn
	effect.blocks_all_actions = effect_template.blocks_all_actions
	effect.blocks_action_types = effect_template.blocks_action_types.duplicate()

	BattleStateMutations.add_effect_to_entity(entity_id, effect)
	print("CombatEngine: Applied effect '%s' to %s (duration: %d)" % [effect_id, entity_id, effect.remaining_duration])

func _process_damage_over_time():
	var turn_order = BattleStateStore.get_state_value("turn_state.turn_order")
	for entity_id in turn_order:
		var entity = _get_entity_by_id(entity_id)
		if not entity:
			continue

		var total_dot_damage = 0
		for effect in entity.active_effects:
			total_dot_damage += effect.damage_per_turn

		if total_dot_damage > 0:
			BattleStateMutations.set_entity_hp(entity_id, max(0, entity.current_hp - total_dot_damage))

func _decrement_effect_durations():
	var turn_order = BattleStateStore.get_state_value("turn_state.turn_order")
	for entity_id in turn_order:
		# Decrement all durations via mutation layer
		BattleStateMutations.decrement_effect_durations(entity_id)

		# Remove expired effects (must check after decrement)
		var entity = _get_entity_by_id(entity_id)
		if not entity:
			continue

		for i in range(entity.active_effects.size() - 1, -1, -1):
			if entity.active_effects[i].remaining_duration <= 0:
				BattleStateMutations.remove_effect_from_entity(entity_id, i)

func _trigger_passives(entity_id: String, trigger_type: String, context_target: String = ""):
	"""
	Triggers passive abilities for an entity based on a trigger type.
	Engine layer orchestration: checks which passives to trigger, then calls mutations.
	"""
	var entity = _get_entity_by_id(entity_id)
	if not entity:
		return

	# Check each passive ability on this entity
	for passive_id in entity.passive_abilities:
		var passive = PassiveAbilityDatabase.get_passive(passive_id)
		if passive == null:
			push_warning("CombatEngine: Passive ability '%s' not found in database" % passive_id)
			continue

		# Check if this passive triggers on this event
		if passive.trigger_type != trigger_type:
			continue

		# Execute passive effects via mutations layer
		if passive.vigor_restore > 0:
			BattleStateMutations.restore_vigor(entity_id, passive.vigor_restore)
			print("CombatEngine: Passive '%s' triggered for %s! +%d vigor" % [passive.passive_name, entity_id, passive.vigor_restore])

		if passive.heal_amount > 0:
			var current_hp = entity.current_hp
			var healed_hp = min(entity.max_hp, current_hp + passive.heal_amount)
			BattleStateMutations.set_entity_hp(entity_id, healed_hp)
			print("CombatEngine: Passive '%s' triggered for %s! +%d HP" % [passive.passive_name, entity_id, passive.heal_amount])

		if passive.applies_effect_id != "":
			_apply_effect_to_entity(entity_id, passive.applies_effect_id)
			print("CombatEngine: Passive '%s' triggered for %s! Applied effect '%s'" % [passive.passive_name, entity_id, passive.applies_effect_id])

# Check if all enemies are defeated
func _check_victory():
	var enemies = BattleStateStore.battle_state.enemies
	var all_dead = true

	for enemy in enemies:
		if enemy.current_hp > 0:
			all_dead = false
			break

	if all_dead and enemies.size() > 0:
		print("CombatEngine: All enemies defeated! Victory!")
		battle_ended.emit()
		return true

	return false
