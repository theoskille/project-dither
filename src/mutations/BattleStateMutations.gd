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
	entity_state.enemy_id = enemy_data.enemy_id
	entity_state.max_hp = enemy_data.max_hp
	entity_state.current_hp = enemy_data.max_hp
	entity_state.max_vigor = enemy_data.max_vigor
	entity_state.current_vigor = enemy_data.max_vigor
	entity_state.base_stats = enemy_data.base_stats.duplicate()
	entity_state.equipped_attacks = enemy_data.equipped_attacks.duplicate()
	entity_state.passive_abilities = enemy_data.passive_abilities.duplicate()
	entity_state.position = position

	# Use properly typed array
	var empty_effects: Array[EffectState] = []
	entity_state.active_effects = empty_effects

	BattleStateStore.battle_state.enemies.append(entity_state)
	var enemy_index = BattleStateStore.battle_state.enemies.size() - 1

	# Emit signal for new enemy added
	BattleStateStore._emit_change("enemies.%d" % enemy_index, null, entity_state)

# Mark an entity as dead
func set_entity_dead(entity_id: String, dead: bool):
	var entity = _get_entity_by_id(entity_id)
	if not entity:
		return

	var property_path = _get_entity_property_path(entity_id, "is_dead")
	var old_dead = entity.is_dead
	entity.is_dead = dead
	BattleStateStore._emit_change(property_path, old_dead, dead)
	print("BattleStateMutations: Set %s is_dead = %s" % [entity_id, dead])

# Clear all enemies from battle
func clear_enemies():
	var old_enemies = BattleStateStore.battle_state.enemies
	BattleStateStore.battle_state.enemies = []
	BattleStateStore._emit_change("enemies", old_enemies, [])
	print("BattleStateMutations: Cleared all enemies")

# Reset turn state to defaults
func reset_turn_state():
	var turn_state = BattleStateStore.battle_state.turn_state
	var old_order = turn_state.turn_order
	var old_index = turn_state.current_turn_index
	var old_number = turn_state.current_turn_number
	var old_phase = turn_state.phase

	# Use properly typed array for turn_order
	var empty_order: Array[String] = []
	turn_state.turn_order = empty_order
	turn_state.current_turn_index = 0
	turn_state.current_turn_number = 1
	turn_state.phase = "action"

	BattleStateStore._emit_change("turn_state.turn_order", old_order, empty_order)
	BattleStateStore._emit_change("turn_state.current_turn_index", old_index, 0)
	BattleStateStore._emit_change("turn_state.current_turn_number", old_number, 1)
	BattleStateStore._emit_change("turn_state.phase", old_phase, "action")
	print("BattleStateMutations: Reset turn state")

# Reset player to default state
func reset_player():
	var player = BattleStateStore.battle_state.player_state

	# Reset stats to defaults
	player.current_hp = player.max_hp
	player.current_vigor = player.max_vigor
	player.position = 0

	# Use properly typed array for active_effects
	var empty_effects: Array[EffectState] = []
	player.active_effects = empty_effects

	BattleStateStore._emit_change("player_state.current_hp", null, player.max_hp)
	BattleStateStore._emit_change("player_state.current_vigor", null, player.max_vigor)
	BattleStateStore._emit_change("player_state.position", null, 0)
	BattleStateStore._emit_change("player_state.active_effects", null, empty_effects)
	print("BattleStateMutations: Reset player to defaults")
