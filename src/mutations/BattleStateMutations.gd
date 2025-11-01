extends Node

# Helper function to get entity by ID (player, enemy_0, enemy_1, etc.)
func _get_entity_by_id(entity_id: String) -> EntityState:
	if entity_id == "player":
		return BattleStateStore.battle_state.player_state
	elif entity_id.begins_with("enemy_"):
		var index = int(entity_id.split("_")[1])
		if index >= 0 and index < BattleStateStore.battle_state.enemies.size():
			return BattleStateStore.battle_state.enemies[index]
	return null

# Helper function to get property path for entity (handles both old and new formats)
func _get_entity_property_path(entity_id: String, property: String) -> String:
	if entity_id == "player":
		return "player_state." + property
	elif entity_id.begins_with("enemy_"):
		var index = int(entity_id.split("_")[1])
		return "enemies.%d.%s" % [index, property]
	return ""

func set_entity_hp(entity_id: String, new_hp: int):
	var entity = _get_entity_by_id(entity_id)
	if not entity:
		return

	var property_path = _get_entity_property_path(entity_id, "current_hp")
	var old_hp = entity.current_hp
	entity.current_hp = new_hp
	BattleStateStore._emit_change(property_path, old_hp, new_hp)

func add_effect_to_entity(entity_id: String, effect: EffectState):
	var entity = _get_entity_by_id(entity_id)
	if not entity:
		return

	var property_path = _get_entity_property_path(entity_id, "active_effects")
	entity.active_effects.append(effect)
	BattleStateStore._emit_change(property_path, null, entity.active_effects)

func remove_effect_from_entity(entity_id: String, effect_index: int):
	var entity = _get_entity_by_id(entity_id)
	if not entity:
		return

	var property_path = _get_entity_property_path(entity_id, "active_effects")
	var removed_effect = entity.active_effects[effect_index]
	entity.active_effects.remove_at(effect_index)
	BattleStateStore._emit_change(property_path, removed_effect, entity.active_effects)

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

func set_entity_vigor(entity_id: String, new_vigor: int):
	var entity = _get_entity_by_id(entity_id)
	if not entity:
		return

	var property_path = _get_entity_property_path(entity_id, "current_vigor")
	var old_vigor = entity.current_vigor
	entity.current_vigor = new_vigor
	BattleStateStore._emit_change(property_path, old_vigor, new_vigor)

func consume_vigor(entity_id: String, amount: int):
	var entity = _get_entity_by_id(entity_id)
	if not entity:
		return

	var new_vigor = max(0, entity.current_vigor - amount)
	set_entity_vigor(entity_id, new_vigor)

func restore_vigor(entity_id: String, amount: int):
	var entity = _get_entity_by_id(entity_id)
	if not entity:
		return

	var new_vigor = min(entity.max_vigor, entity.current_vigor + amount)
	set_entity_vigor(entity_id, new_vigor)

func set_entity_position(entity_id: String, new_position: int):
	var entity = _get_entity_by_id(entity_id)
	if not entity:
		return

	var property_path = _get_entity_property_path(entity_id, "position")
	var old_position = entity.position
	entity.position = new_position
	BattleStateStore._emit_change(property_path, old_position, new_position)

func decrement_effect_durations(entity_id: String):
	var entity = _get_entity_by_id(entity_id)
	if not entity:
		return

	var property_path = _get_entity_property_path(entity_id, "active_effects")
	var old_effects = entity.active_effects  # Capture for signal

	for effect in entity.active_effects:
		effect.remaining_duration -= 1

	# Emit signal so UI updates
	BattleStateStore._emit_change(property_path, old_effects, entity.active_effects)

func set_turn_order(new_order: Array[String]):
	var old_order = BattleStateStore.get_state_value("turn_state.turn_order")
	BattleStateStore.battle_state.turn_state.turn_order = new_order
	BattleStateStore._emit_change("turn_state.turn_order", old_order, new_order)

func add_enemy_to_battle(enemy_data: EnemyData, position: int):
	var entity_state = EntityState.new()
	entity_state.name = enemy_data.enemy_name
	entity_state.max_hp = enemy_data.max_hp
	entity_state.current_hp = enemy_data.max_hp
	entity_state.max_vigor = enemy_data.max_vigor
	entity_state.current_vigor = enemy_data.max_vigor
	entity_state.base_stats = enemy_data.base_stats.duplicate()
	entity_state.equipped_attacks = enemy_data.equipped_attacks.duplicate()
	entity_state.position = position

	# Use properly typed array
	var empty_effects: Array[EffectState] = []
	entity_state.active_effects = empty_effects

	BattleStateStore.battle_state.enemies.append(entity_state)
	var enemy_index = BattleStateStore.battle_state.enemies.size() - 1

	# Emit signal for new enemy added
	BattleStateStore._emit_change("enemies.%d" % enemy_index, null, entity_state)
