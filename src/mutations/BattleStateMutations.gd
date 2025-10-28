extends Node

func set_entity_hp(entity: String, new_hp: int):
	var old_hp = BattleStateStore.get_state_value("%s_state.current_hp" % entity)
	BattleStateStore.battle_state.get("%s_state" % entity).current_hp = new_hp
	BattleStateStore._emit_change("%s_state.current_hp" % entity, old_hp, new_hp)

func add_effect_to_entity(entity: String, effect: EffectState):
	var effects = BattleStateStore.get_state_value("%s_state.active_effects" % entity)
	effects.append(effect)
	BattleStateStore._emit_change("%s_state.active_effects" % entity, null, effects)

func remove_effect_from_entity(entity: String, effect_index: int):
	var effects = BattleStateStore.get_state_value("%s_state.active_effects" % entity)
	var removed_effect = effects[effect_index]
	effects.remove_at(effect_index)
	BattleStateStore._emit_change("%s_state.active_effects" % entity, removed_effect, effects)

func advance_turn():
	var current_index = BattleStateStore.get_state_value("turn_state.current_turn_index")
	var turn_order = BattleStateStore.get_state_value("turn_state.turn_order")
	var next_index = (current_index + 1) % turn_order.size()
	
	BattleStateStore.battle_state.turn_state.current_turn_index = next_index
	BattleStateStore._emit_change("turn_state.current_turn_index", current_index, next_index)

func set_turn_phase(new_phase: String):
	var old_phase = BattleStateStore.get_state_value("turn_state.phase")
	BattleStateStore.battle_state.turn_state.phase = new_phase
	BattleStateStore._emit_change("turn_state.phase", old_phase, new_phase)

func increment_turn_number():
	var old_turn = BattleStateStore.get_state_value("turn_state.current_turn_number")
	var new_turn = old_turn + 1
	BattleStateStore.battle_state.turn_state.current_turn_number = new_turn
	BattleStateStore._emit_change("turn_state.current_turn_number", old_turn, new_turn)

func set_entity_vigor(entity: String, new_vigor: int):
	var old_vigor = BattleStateStore.get_state_value("%s_state.current_vigor" % entity)
	BattleStateStore.battle_state.get("%s_state" % entity).current_vigor = new_vigor
	BattleStateStore._emit_change("%s_state.current_vigor" % entity, old_vigor, new_vigor)

func consume_vigor(entity: String, amount: int):
	var current_vigor = BattleStateStore.get_state_value("%s_state.current_vigor" % entity)
	var new_vigor = max(0, current_vigor - amount)
	set_entity_vigor(entity, new_vigor)

func restore_vigor(entity: String, amount: int):
	var current_vigor = BattleStateStore.get_state_value("%s_state.current_vigor" % entity)
	var max_vigor = BattleStateStore.get_state_value("%s_state.max_vigor" % entity)
	var new_vigor = min(max_vigor, current_vigor + amount)
	set_entity_vigor(entity, new_vigor)

func set_entity_position(entity: String, new_position: int):
	var old_position = BattleStateStore.get_state_value("%s_state.position" % entity)
	BattleStateStore.battle_state.get("%s_state" % entity).position = new_position
	BattleStateStore._emit_change("%s_state.position" % entity, old_position, new_position)

func decrement_effect_durations(entity: String):
	var effects = BattleStateStore.get_state_value("%s_state.active_effects" % entity)
	var old_effects = effects  # Capture for signal

	for effect in effects:
		effect.remaining_duration -= 1

	# Emit signal so UI updates
	BattleStateStore._emit_change("%s_state.active_effects" % entity, old_effects, effects)

func initialize_entity_from_enemy_data(entity: String, enemy_data: EnemyData, position: int):
	var entity_state = BattleStateStore.battle_state.get("%s_state" % entity)

	entity_state.name = enemy_data.enemy_name
	entity_state.max_hp = enemy_data.max_hp
	entity_state.current_hp = enemy_data.max_hp
	entity_state.max_vigor = enemy_data.max_vigor
	entity_state.current_vigor = enemy_data.max_vigor
	entity_state.base_stats = enemy_data.base_stats.duplicate()
	entity_state.equipped_attacks = enemy_data.equipped_attacks.duplicate()
	entity_state.position = position

	# Clear active effects using a properly typed array
	var empty_effects: Array[EffectState] = []
	entity_state.active_effects = empty_effects

	# Emit signals for all changed properties
	BattleStateStore._emit_change("%s_state.max_hp" % entity, null, enemy_data.max_hp)
	BattleStateStore._emit_change("%s_state.current_hp" % entity, null, enemy_data.max_hp)
	BattleStateStore._emit_change("%s_state.max_vigor" % entity, null, enemy_data.max_vigor)
	BattleStateStore._emit_change("%s_state.current_vigor" % entity, null, enemy_data.max_vigor)
	BattleStateStore._emit_change("%s_state.base_stats" % entity, null, enemy_data.base_stats)
	BattleStateStore._emit_change("%s_state.equipped_attacks" % entity, null, enemy_data.equipped_attacks)
	BattleStateStore._emit_change("%s_state.position" % entity, null, position)
