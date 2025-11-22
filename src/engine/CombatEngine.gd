extends Node

## Signals
signal battle_ended()  # Emitted when all enemies are defeated
signal victory_achieved(total_xp: int, levels_gained: int)  # Emitted after XP awarded and level ups processed

# Reset battle state to clean slate (call before starting new encounter)
func reset_battle():
	print("CombatEngine: Resetting battle state")
	BattleStateMutations.clear_enemies()
	BattleStateMutations.reset_turn_state()
	BattleStateMutations.reset_player()
	BattleStateMutations.sync_player_from_store()  # Sync player with persistent progression data
	_update_entity_dodge_chance("player")  # Calculate initial dodge chance
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

	# Update dodge chance for all enemies
	var enemies = BattleStateStore.battle_state.enemies
	for i in range(enemies.size()):
		_update_entity_dodge_chance("enemy_%d" % i)

func execute_move(action_data: ActionData, caster: String, target: String) -> bool:
	if not can_execute_action(action_data, caster, target):
		return false

	BattleStateMutations.consume_vigor(caster, action_data.vigor_cost)

	# Set cooldown if the action has one
	if action_data.cooldown > 0:
		BattleStateMutations.set_action_cooldown(caster, action_data.action_id, action_data.cooldown)

	# Apply self-damage if the action damages the caster
	if action_data.damage_caster > 0:
		var caster_entity = _get_entity_by_id(caster)
		if caster_entity:
			var new_hp = max(0, caster_entity.current_hp - action_data.damage_caster)
			BattleStateMutations.set_entity_hp(caster, new_hp)
			print("CombatEngine: %s took %d self-damage from using %s" % [caster, action_data.damage_caster, action_data.action_name])

	return _perform_action(action_data, caster, target)

func execute_move_legacy(move_data: Dictionary, caster: String, target: String):
	return _perform_action_legacy(move_data, caster, target)

func _perform_action(action_data: ActionData, caster_id: String, target_id: String) -> bool:
	# Check if attack hits (only for damage-dealing actions)
	var attack_hits = true
	if action_data.base_damage > 0 or _has_damage_modifiers(action_data):
		attack_hits = _check_attack_hits(action_data, target_id)
		if not attack_hits:
			print("CombatEngine: %s's attack missed %s!" % [caster_id, target_id])

	var damage = _calculate_damage_from_action(action_data, caster_id)

	if damage > 0 and attack_hits:
		var target_entity = _get_entity_by_id(target_id)
		if target_entity:
			# Apply armor reduction to damage
			var final_damage = _apply_armor_reduction(target_id, damage)
			var new_hp = max(0, target_entity.current_hp - final_damage)
			BattleStateMutations.set_entity_hp(target_id, new_hp)

			# Apply life steal from passives
			var heal_amount = _calculate_life_steal(caster_id, damage)
			if heal_amount > 0:
				BattleStateMutations.heal_entity(caster_id, heal_amount)

			# Apply target healing if action has heal_target property
			if action_data.base_heal_target > 0:
				var target_heal = _calculate_heal_from_action(action_data, caster_id, "target")
				if target_heal > 0:
					BattleStateMutations.heal_entity(target_id, target_heal)
					print("CombatEngine: %s healed %s for %d HP" % [caster_id, target_id, target_heal])

			# Check for death and trigger on_kill passives
			if new_hp == 0:
				_trigger_passives(caster_id, "on_kill", target_id)

				# Mark entity as dead
				BattleStateMutations.set_entity_dead(target_id, true)

				# Track enemy defeats (only count enemies, not the player)
				if target_id != "player":
					DungeonStateMutations.increment_enemies_defeated()

				_check_victory()

	# Get battlefield size for boundary clamping
	var max_position = BattleStateStore.get_state_value("battlefield.total_tiles") - 1

	# Track hit entity for damage application
	var hit_entity_id = ""

	# Move caster if specified
	if action_data.move_caster != 0:
		var caster_entity = _get_entity_by_id(caster_id)
		if caster_entity:
			# Use MovementEngine to resolve movement
			var movement_result = MovementEngine.resolve_movement(
				caster_id,
				action_data.movement_type,
				caster_entity.position,
				action_data.move_caster,
				max_position
			)

			var new_pos = movement_result.final_position
			hit_entity_id = movement_result.hit_entity

			BattleStateMutations.set_entity_position(caster_id, new_pos)

			if hit_entity_id != "":
				print("CombatEngine: %s moved to position %d and hit %s" % [caster_id, new_pos, hit_entity_id])
			else:
				print("CombatEngine: %s moved to position %d" % [caster_id, new_pos])

	# Apply damage to hit entity if movement resulted in a hit
	if hit_entity_id != "":
		# Check if collision attack hits
		var collision_hits = _check_attack_hits(action_data, hit_entity_id)
		if not collision_hits:
			print("CombatEngine: %s's collision attack missed %s!" % [caster_id, hit_entity_id])

		var hit_damage = _calculate_damage_from_action(action_data, caster_id)
		if hit_damage > 0 and collision_hits:
			var hit_target = _get_entity_by_id(hit_entity_id)
			if hit_target:
				# Apply armor reduction to collision damage
				var final_hit_damage = _apply_armor_reduction(hit_entity_id, hit_damage)
				var new_hp = max(0, hit_target.current_hp - final_hit_damage)
				BattleStateMutations.set_entity_hp(hit_entity_id, new_hp)
				print("CombatEngine: Hit damage applied to %s: %d damage" % [hit_entity_id, final_hit_damage])

				# Apply life steal from hit damage
				var heal_amount = _calculate_life_steal(caster_id, hit_damage)
				if heal_amount > 0:
					BattleStateMutations.heal_entity(caster_id, heal_amount)

				# Check for death from hit damage
				if new_hp == 0:
					_trigger_passives(caster_id, "on_kill", hit_entity_id)

					# Mark entity as dead
					BattleStateMutations.set_entity_dead(hit_entity_id, true)

					# Track enemy defeats (only count enemies, not the player)
					if hit_entity_id != "player":
						DungeonStateMutations.increment_enemies_defeated()

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

	# Apply self-healing if action has heal_self property
	if action_data.base_heal_self > 0:
		var self_heal = _calculate_heal_from_action(action_data, caster_id, "self")
		if self_heal > 0:
			BattleStateMutations.heal_entity(caster_id, self_heal)
			print("CombatEngine: %s healed self for %d HP" % [caster_id, self_heal])

	# Handle self-destruct attacks
	if action_data.kills_user_on_use:
		BattleStateMutations.set_entity_hp(caster_id, 0)
		BattleStateMutations.set_entity_dead(caster_id, true)

		# Track enemy defeats if caster was an enemy
		if caster_id != "player":
			DungeonStateMutations.increment_enemies_defeated()

		_check_victory()

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

	# Trigger end-of-turn passive abilities (e.g., self-repair) for current entity
	var current_entity_id = _get_current_turn_entity()
	_trigger_passives(current_entity_id, "on_turn_end")

	# Check if we're at the end of a round (about to loop back to turn index 0)
	var current_index = BattleStateStore.get_state_value("turn_state.current_turn_index")
	var turn_order = BattleStateStore.get_state_value("turn_state.turn_order")
	var is_round_end = (current_index == turn_order.size() - 1)

	BattleStateMutations.advance_turn()

	# If we just completed a round, decrement all cooldowns
	if is_round_end:
		BattleStateMutations.increment_round_counter()
		for entity_id in turn_order:
			BattleStateMutations.decrement_all_cooldowns(entity_id)
		print("CombatEngine: Round completed - cooldowns decremented for all entities")

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

	# Check if action is on cooldown
	if caster_entity.active_cooldowns.has(action_data.action_id):
		var remaining_rounds = caster_entity.active_cooldowns[action_data.action_id]
		print("CombatEngine: %s cannot use '%s' - on cooldown for %d more rounds" % [caster_id, action_data.action_id, remaining_rounds])
		return false

	var distance = _get_distance_between_entities(caster_id, target_id)
	if distance < action_data.min_range or distance > action_data.max_range:
		return false

	# Check if caster movement is blocked
	if action_data.move_caster != 0:
		if not MovementEngine.validate_movement(caster_id, action_data.movement_type, caster_entity.position, action_data.move_caster):
			print("CombatEngine: %s cannot move - blocked" % caster_id)
			return false

	return true

func start_battle():
	# Generate speed-based turn order
	var turn_order = _generate_turn_order()
	BattleStateMutations.set_turn_order(turn_order)

	# Clear all cooldowns at battle start
	for entity_id in turn_order:
		BattleStateMutations.clear_entity_cooldowns(entity_id)
	print("CombatEngine: Cleared all cooldowns at battle start")

	# Start the first turn
	if turn_order.size() > 0:
		var first_entity = turn_order[0]
		start_turn(first_entity)

func start_turn(entity_id: String):
	BattleStateMutations.restore_vigor(entity_id, 1)
	BattleStateMutations.set_turn_phase("action")

func end_turn():
	process_turn_end()

	# Skip dead entities in turn order
	var next_entity = _get_current_turn_entity()
	var max_iterations = 20  # Safety limit to prevent infinite loops
	var iterations = 0

	while _is_entity_dead(next_entity) and iterations < max_iterations:
		print("CombatEngine: Skipping turn for dead entity: %s" % next_entity)
		process_turn_end()  # Advance turn index
		next_entity = _get_current_turn_entity()
		iterations += 1

	if iterations >= max_iterations:
		push_error("CombatEngine: Exceeded max iterations while skipping dead entities")
		return

	start_turn(next_entity)

func _generate_turn_order() -> Array[String]:
	var combatants = []

	# Add player
	var player = BattleStateStore.battle_state.player_state
	combatants.append({"id": "player", "spd": player.base_stats.get("spd", 0)})

	# Add all living enemies
	var enemies = BattleStateStore.battle_state.enemies
	for i in range(enemies.size()):
		if not enemies[i].is_dead:
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

func _get_adjacent_entities(entity_id: String) -> Array[String]:
	"""
	Get all entities adjacent to the given entity (position ± 1).
	Returns array of entity IDs.
	"""
	var entity = _get_entity_by_id(entity_id)
	if not entity:
		return []

	var adjacent_ids: Array[String] = []
	var entity_pos = entity.position

	# Check player
	var player = BattleStateStore.battle_state.player_state
	if not player.is_dead:
		var distance = abs(player.position - entity_pos)
		if distance == 1:
			adjacent_ids.append("player")

	# Check all enemies
	var enemies = BattleStateStore.battle_state.enemies
	for i in range(enemies.size()):
		if not enemies[i].is_dead:
			var distance = abs(enemies[i].position - entity_pos)
			if distance == 1:
				adjacent_ids.append("enemy_%d" % i)

	return adjacent_ids

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

func _calculate_heal_from_action(action_data: ActionData, caster_id: String, heal_type: String) -> int:
	"""
	Calculate healing amount from an action, similar to damage calculation.
	heal_type should be either "target" or "self" to determine which base_heal value to use.
	"""
	var base_heal = action_data.base_heal_target if heal_type == "target" else action_data.base_heal_self
	var total_heal = base_heal

	var caster = _get_entity_by_id(caster_id)
	if not caster:
		return 0

	var stats = caster.base_stats

	# Apply stat modifiers for healing
	total_heal += int(stats.int * action_data.int_heal_modifier)
	total_heal += int(stats.con * action_data.con_heal_modifier)
	total_heal += int(stats.spd * action_data.spd_heal_modifier)
	total_heal += int(stats.luck * action_data.luck_heal_modifier)

	# TODO: Add effect modifiers for healing if needed in the future
	# var effect_modifiers = _get_total_heal_modifier(caster_id)
	# total_heal += effect_modifiers

	return max(0, total_heal)

func _calculate_life_steal(entity_id: String, damage_dealt: int) -> int:
	"""
	Calculate total healing from life steal passives.
	Checks all passive abilities on the entity for life_steal_percent.
	"""
	var entity = _get_entity_by_id(entity_id)
	if not entity:
		return 0

	var total_heal = 0
	for passive_id in entity.passive_abilities:
		var passive = PassiveAbilityDatabase.get_passive(passive_id)
		if passive and passive.life_steal_percent > 0:
			var heal_amount = int(damage_dealt * passive.life_steal_percent / 100.0)
			total_heal += heal_amount
			print("CombatEngine: Life steal from '%s': %d HP (%.1f%% of %d damage)" % [passive.passive_name, heal_amount, passive.life_steal_percent, damage_dealt])

	return total_heal

func _apply_armor_reduction(target_id: String, raw_damage: int) -> int:
	"""
	Apply armor reduction to damage.
	Armor reduces damage by a percentage (e.g., 25 armor = 25% reduction).
	Formula: final_damage = raw_damage * (1 - (armor / 100))
	"""
	var target = _get_entity_by_id(target_id)
	if not target:
		return raw_damage

	var base_armor = target.armor
	var armor_modifier = _get_total_armor_modifier(target_id)
	var armor_percent = base_armor + armor_modifier
	var damage_multiplier = 1.0 - (armor_percent / 100.0)
	var final_damage = int(raw_damage * damage_multiplier)

	if armor_percent > 0 or armor_modifier != 0:
		print("CombatEngine: Armor reduced %d damage to %d (%.1f%% armor, %d modifier)" % [raw_damage, final_damage, armor_percent, armor_modifier])

	return max(0, final_damage)

func _has_damage_modifiers(action_data: ActionData) -> bool:
	"""
	Check if an action has any stat modifiers that could result in damage.
	"""
	return (action_data.str_modifier != 0.0 or
			action_data.dex_modifier != 0.0 or
			action_data.int_modifier != 0.0 or
			action_data.con_modifier != 0.0 or
			action_data.spd_modifier != 0.0 or
			action_data.luck_modifier != 0.0)

func _calculate_dodge_chance(entity_id: String) -> float:
	"""
	Calculate entity's dodge chance based on dex and speed stats.
	Formula: (dex * 0.6) + (spd * 0.4) + dodge_modifiers = dodge chance percentage
	Includes stat modifiers from equipment and effects, plus direct dodge modifiers.
	"""
	var entity = _get_entity_by_id(entity_id)
	if not entity:
		return 0.0

	# Get base stats
	var dex = entity.base_stats.get("dex", 0)
	var spd = entity.base_stats.get("spd", 0)

	# Add stat modifiers from effects
	dex += _get_total_stat_modifier(entity_id, "dex")
	spd += _get_total_stat_modifier(entity_id, "spd")

	# Calculate dodge chance: weighted formula favoring dexterity
	var dodge_chance = (dex * 0.6) + (spd * 0.4)

	# Add direct dodge modifiers from effects
	var dodge_modifier = _get_total_dodge_modifier(entity_id)
	dodge_chance += dodge_modifier

	return dodge_chance

func _update_entity_dodge_chance(entity_id: String):
	"""
	Calculate and update an entity's dodge chance in the state.
	Should be called whenever dex, spd, or effects change.
	"""
	var new_dodge = _calculate_dodge_chance(entity_id)
	BattleStateMutations.set_entity_dodge_chance(entity_id, new_dodge)

func _check_attack_hits(action: ActionData, target_id: String) -> bool:
	"""
	Determine if an attack hits or misses based on accuracy vs dodge.
	Returns true if attack hits, false if it misses.
	"""
	var base_accuracy = action.accuracy
	var dodge_chance = _calculate_dodge_chance(target_id)

	# Calculate final hit chance
	var hit_chance = base_accuracy - dodge_chance
	hit_chance = clamp(hit_chance, 0.0, 100.0)

	# Roll for hit
	var roll = randf() * 100.0
	return roll < hit_chance

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

func _get_total_armor_modifier(entity_id: String) -> int:
	var entity = _get_entity_by_id(entity_id)
	if not entity:
		return 0

	var armor_modifier = 0

	for effect in entity.active_effects:
		armor_modifier += effect.armor_modifier

	return armor_modifier

func _get_total_dodge_modifier(entity_id: String) -> int:
	"""
	Calculate total dodge chance modifier from all active effects.
	Returns the sum of all dodge_modifier values from effects.
	"""
	var entity = _get_entity_by_id(entity_id)
	if not entity:
		return 0

	var dodge_modifier = 0

	for effect in entity.active_effects:
		dodge_modifier += effect.dodge_modifier

	return dodge_modifier

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
	effect.armor_modifier = effect_template.armor_modifier
	effect.dodge_modifier = effect_template.dodge_modifier
	effect.damage_per_turn = effect_template.base_damage_per_turn
	effect.blocks_all_actions = effect_template.blocks_all_actions
	effect.blocks_action_types = effect_template.blocks_action_types.duplicate()

	BattleStateMutations.add_effect_to_entity(entity_id, effect)
	print("CombatEngine: Applied effect '%s' to %s (duration: %d)" % [effect_id, entity_id, effect.remaining_duration])

	# Update dodge chance if effect modifies dex, spd, or dodge directly
	if (effect.dex_modifier != 0 or effect.spd_modifier != 0 or
		effect.percent_dex_modifier != 0 or effect.percent_spd_modifier != 0 or
		effect.dodge_modifier != 0):
		_update_entity_dodge_chance(entity_id)

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
			# DoT bypasses armor - apply damage directly
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

		var dodge_needs_update = false
		for i in range(entity.active_effects.size() - 1, -1, -1):
			if entity.active_effects[i].remaining_duration <= 0:
				var expired_effect = entity.active_effects[i]
				# Check if removing this effect affects dodge
				if (expired_effect.dex_modifier != 0 or expired_effect.spd_modifier != 0 or
					expired_effect.percent_dex_modifier != 0 or expired_effect.percent_spd_modifier != 0 or
					expired_effect.dodge_modifier != 0):
					dodge_needs_update = true

				BattleStateMutations.remove_effect_from_entity(entity_id, i)

		# Update dodge if any dex/spd/dodge effects expired
		if dodge_needs_update:
			_update_entity_dodge_chance(entity_id)

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

		# Handle AoE damage to adjacent entities
		if passive.aoe_damage_amount > 0:
			var adjacent_entities = _get_adjacent_entities(entity_id)
			for target_id in adjacent_entities:
				# Filter by team if aoe_targets_allies is false
				if not passive.aoe_targets_allies:
					# Only damage enemies
					var is_same_team = (entity_id == "player" and target_id == "player") or \
									   (entity_id.begins_with("enemy_") and target_id.begins_with("enemy_"))
					if is_same_team:
						continue  # Skip allies

				# Deal damage using full damage mechanics (triggers life steal, on-kill, etc.)
				var target_entity = _get_entity_by_id(target_id)
				if target_entity:
					# Apply armor reduction to AoE damage
					var final_damage = _apply_armor_reduction(target_id, passive.aoe_damage_amount)
					var new_hp = max(0, target_entity.current_hp - final_damage)
					BattleStateMutations.set_entity_hp(target_id, new_hp)
					print("CombatEngine: Passive '%s' dealt %d AoE damage to %s" % [passive.passive_name, final_damage, target_id])

					# Apply life steal from AoE damage
					var heal_amount = _calculate_life_steal(entity_id, passive.aoe_damage_amount)
					if heal_amount > 0:
						BattleStateMutations.heal_entity(entity_id, heal_amount)

					# Check for death and trigger on_kill passives
					if new_hp == 0:
						_trigger_passives(entity_id, "on_kill", target_id)

						# Mark entity as dead
						BattleStateMutations.set_entity_dead(target_id, true)

						# Track enemy defeats (only count enemies, not the player)
						if target_id != "player":
							DungeonStateMutations.increment_enemies_defeated()

						_check_victory()

# Check if all enemies are defeated
func _check_victory():
	var enemies = BattleStateStore.battle_state.enemies
	var all_dead = true

	# Victory occurs when all enemies are marked as dead
	for enemy in enemies:
		if not enemy.is_dead:
			all_dead = false
			break

	if all_dead and enemies.size() > 0:
		print("CombatEngine: All enemies defeated! Victory!")

		# Save player health to persistent store
		BattleStateMutations.save_player_hp_to_store()

		# Calculate total XP from all defeated enemies
		var total_xp = _calculate_total_xp_reward()

		# Award XP to player
		PlayerMutations.add_xp(total_xp)

		# Check for level ups (loop to handle multiple level ups)
		var levels_gained = 0
		while PlayerStore.current_xp >= _calculate_xp_for_level(PlayerStore.level + 1):
			PlayerMutations.level_up()
			levels_gained += 1

		# Emit signals
		battle_ended.emit()
		victory_achieved.emit(total_xp, levels_gained)

		return true

	return false

func _calculate_total_xp_reward() -> int:
	"""Calculate total XP from all defeated enemies in current battle"""
	var total_xp = 0
	var enemies = BattleStateStore.battle_state.enemies

	for i in range(enemies.size()):
		var enemy_state = enemies[i]
		var enemy_data = EnemyDatabase.get_enemy(enemy_state.enemy_id)
		if enemy_data:
			total_xp += enemy_data.xp_reward
			print("CombatEngine: Enemy %d (%s) rewards %d XP" % [i, enemy_data.enemy_name, enemy_data.xp_reward])
		else:
			push_warning("CombatEngine: Could not find enemy data for enemy_id '%s'" % enemy_state.enemy_id)

	print("CombatEngine: Total XP reward: %d" % total_xp)
	return total_xp

func _calculate_xp_for_level(level: int) -> int:
	"""Calculate XP required to reach the given level (linear curve: 20 * level)"""
	return 20 * level

func _is_entity_dead(entity_id: String) -> bool:
	"""Check if an entity is dead"""
	var entity = _get_entity_by_id(entity_id)
	if not entity:
		return true  # Treat missing entities as dead
	return entity.is_dead
