extends Node

func initialize_enemy(enemy_id: String, position: int = 5):
	var enemy_data = EnemyDatabase.get_enemy(enemy_id)
	if enemy_data == null:
		push_error("CombatEngine: Cannot initialize enemy - enemy_id '%s' not found" % enemy_id)
		return

	BattleStateMutations.initialize_entity_from_enemy_data("enemy", enemy_data, position)
	print("CombatEngine: Initialized enemy '%s' at position %d" % [enemy_data.enemy_name, position])

func execute_move(action_data: ActionData, caster: String, target: String) -> bool:
	if not can_execute_action(action_data, caster, target):
		return false
	
	BattleStateMutations.consume_vigor(caster, action_data.vigor_cost)
	return _perform_action(action_data, caster, target)

func execute_move_legacy(move_data: Dictionary, caster: String, target: String):
	return _perform_action_legacy(move_data, caster, target)

func _perform_action(action_data: ActionData, caster: String, target: String) -> bool:
	var damage = _calculate_damage_from_action(action_data, caster)
	
	if damage > 0:
		var current_hp = BattleStateStore.get_state_value("%s_state.current_hp" % target)
		BattleStateMutations.set_entity_hp(target, max(0, current_hp - damage))
	
	if action_data.move_caster != 0:
		var current_pos = BattleStateStore.get_state_value("%s_state.position" % caster)
		var new_pos = max(0, current_pos + action_data.move_caster)
		BattleStateMutations.set_entity_position(caster, new_pos)
	
	if action_data.applies_effect_id != "":
		_apply_effect_to_entity(target, action_data.applies_effect_id, action_data.effect_duration_override)
	
	return true

func _perform_action_legacy(move_data: Dictionary, caster: String, target: String) -> bool:
	var damage = _calculate_damage(move_data, caster)
	
	var current_hp = BattleStateStore.get_state_value("%s_state.current_hp" % target)
	BattleStateMutations.set_entity_hp(target, max(0, current_hp - damage))
	
	if move_data.has("move_caster"):
		var current_pos = BattleStateStore.get_state_value("%s_state.position" % caster)
		var new_pos = max(0, current_pos + move_data.move_caster)
		BattleStateMutations.set_entity_position(caster, new_pos)
	
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

func can_execute_action(action_data: ActionData, caster: String, target: String) -> bool:
	if not _is_entity_turn(caster):
		return false

	# Check if caster is blocked by status effects
	if _is_action_blocked_by_effects(caster, action_data.action_type):
		return false

	var current_vigor = BattleStateStore.get_state_value("%s_state.current_vigor" % caster)
	if current_vigor < action_data.vigor_cost:
		return false

	var distance = _get_distance_between_entities(caster, target)
	if distance < action_data.min_range or distance > action_data.max_range:
		return false

	return true

func start_turn(entity: String):
	BattleStateMutations.restore_vigor(entity, 1)
	BattleStateMutations.set_turn_phase("action")

func end_turn():
	process_turn_end()
	var next_entity = _get_current_turn_entity()
	start_turn(next_entity)

func _is_entity_turn(entity: String) -> bool:
	var current_entity = _get_current_turn_entity()
	return current_entity == entity

func _get_current_turn_entity() -> String:
	var turn_order = BattleStateStore.get_state_value("turn_state.turn_order")
	var current_index = BattleStateStore.get_state_value("turn_state.current_turn_index")
	return turn_order[current_index]

func _get_distance_between_entities(entity1: String, entity2: String) -> int:
	var pos1 = BattleStateStore.get_state_value("%s_state.position" % entity1)
	var pos2 = BattleStateStore.get_state_value("%s_state.position" % entity2)
	return abs(pos1 - pos2)

func _is_action_blocked_by_effects(entity: String, action_type: String) -> bool:
	var effects = BattleStateStore.get_state_value("%s_state.active_effects" % entity)

	for effect in effects:
		# Check if effect blocks all actions
		if effect.blocks_all_actions:
			print("CombatEngine: %s cannot act - blocked by '%s'" % [entity, effect.effect_id])
			return true

		# Check if effect blocks this specific action type
		if action_type in effect.blocks_action_types:
			print("CombatEngine: %s cannot perform '%s' action - blocked by '%s'" % [entity, action_type, effect.effect_id])
			return true

	return false

func _calculate_damage_from_action(action_data: ActionData, caster: String) -> int:
	var total_damage = action_data.base_damage
	
	var stats = BattleStateStore.get_state_value("%s_state.base_stats" % caster)
	
	total_damage += int(stats.str * action_data.str_modifier)
	total_damage += int(stats.dex * action_data.dex_modifier)
	total_damage += int(stats.int * action_data.int_modifier)
	total_damage += int(stats.con * action_data.con_modifier)
	total_damage += int(stats.spd * action_data.spd_modifier)
	total_damage += int(stats.luck * action_data.luck_modifier)
	
	var effect_modifiers = _get_total_stat_modifier(caster, "str")
	total_damage += effect_modifiers
	
	return max(0, total_damage)

func _calculate_damage(move_data: Dictionary, caster: String) -> int:
	var base_damage = move_data.get("base_damage", 0)
	var str_stat = BattleStateStore.get_state_value("%s_state.base_stats.str" % caster)
	var str_modifier = _get_total_stat_modifier(caster, "str")
	
	return base_damage + str_stat + str_modifier

func _get_total_stat_modifier(entity: String, stat: String) -> int:
	var effects = BattleStateStore.get_state_value("%s_state.active_effects" % entity)
	var base_stat = BattleStateStore.get_state_value("%s_state.base_stats.%s" % [entity, stat])

	var flat_modifier = 0
	var percent_modifier = 0

	for effect in effects:
		flat_modifier += effect.get("%s_modifier" % stat, 0)
		percent_modifier += effect.get("percent_%s_modifier" % stat, 0)

	# Apply formula: (base_stat + flat_mods) * (1.0 + percent_mods/100.0) - base_stat
	var modified_stat = (base_stat + flat_modifier) * (1.0 + percent_modifier / 100.0)
	return int(modified_stat) - base_stat

func _apply_effect_to_entity(entity: String, effect_id: String, duration_override: int = 0):
	var effect_template = EffectDatabase.get_effect(effect_id)
	if effect_template == null:
		push_error("CombatEngine: Cannot apply effect - effect_id '%s' not found" % effect_id)
		return

	# Check if effect already exists (no stacking - refresh duration instead)
	var existing_effects = BattleStateStore.get_state_value("%s_state.active_effects" % entity)
	for i in range(existing_effects.size()):
		if existing_effects[i].effect_id == effect_id:
			# Refresh duration
			var new_duration = duration_override if duration_override > 0 else effect_template.base_duration
			existing_effects[i].remaining_duration = new_duration
			BattleStateStore._emit_change("%s_state.active_effects" % entity, null, existing_effects)
			print("CombatEngine: Refreshed effect '%s' on %s (duration: %d)" % [effect_id, entity, new_duration])
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

	BattleStateMutations.add_effect_to_entity(entity, effect)
	print("CombatEngine: Applied effect '%s' to %s (duration: %d)" % [effect_id, entity, effect.remaining_duration])

func _process_damage_over_time():
	for entity in ["player", "enemy"]:
		var effects = BattleStateStore.get_state_value("%s_state.active_effects" % entity)
		var total_dot_damage = 0
		
		for effect in effects:
			total_dot_damage += effect.damage_per_turn
		
		if total_dot_damage > 0:
			var current_hp = BattleStateStore.get_state_value("%s_state.current_hp" % entity)
			BattleStateMutations.set_entity_hp(entity, max(0, current_hp - total_dot_damage))

func _decrement_effect_durations():
	for entity in ["player", "enemy"]:
		var effects = BattleStateStore.get_state_value("%s_state.active_effects" % entity)
		
		for i in range(effects.size() - 1, -1, -1):
			effects[i].remaining_duration -= 1
			if effects[i].remaining_duration <= 0:
				BattleStateMutations.remove_effect_from_entity(entity, i)