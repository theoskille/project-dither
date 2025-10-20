extends Node

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
	
	if not action_data.status_effect.is_empty():
		var effect = _create_effect_from_data(action_data.status_effect)
		BattleStateMutations.add_effect_to_entity(target, effect)
	
	return true

func _perform_action_legacy(move_data: Dictionary, caster: String, target: String) -> bool:
	var damage = _calculate_damage(move_data, caster)
	
	var current_hp = BattleStateStore.get_state_value("%s_state.current_hp" % target)
	BattleStateMutations.set_entity_hp(target, max(0, current_hp - damage))
	
	if move_data.has("move_caster"):
		var current_pos = BattleStateStore.get_state_value("%s_state.position" % caster)
		var new_pos = max(0, current_pos + move_data.move_caster)
		BattleStateMutations.set_entity_position(caster, new_pos)
	
	if move_data.has("status_effect"):
		var effect = _create_effect_from_data(move_data.status_effect)
		BattleStateMutations.add_effect_to_entity(target, effect)
	
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
	BattleStateMutations.advance_turn()
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
	var total_modifier = 0
	
	for effect in effects:
		total_modifier += effect.get("%s_modifier" % stat, 0)
	
	return total_modifier

func _create_effect_from_data(effect_data: Dictionary) -> EffectState:
	var effect = EffectState.new()
	effect.effect_id = effect_data.get("id", "")
	effect.remaining_duration = effect_data.get("duration", 0)
	effect.damage_per_turn = effect_data.get("damage_per_turn", 0)
	effect.str_modifier = effect_data.get("str_modifier", 0)
	effect.dex_modifier = effect_data.get("dex_modifier", 0)
	effect.movement_blocked = effect_data.get("movement_blocked", false)
	return effect

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