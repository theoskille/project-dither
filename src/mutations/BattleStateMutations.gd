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

func heal_entity(entity_id: String, amount: int):
	var entity = _get_entity_by_id(entity_id)
	if not entity:
		return

	var new_hp = min(entity.max_hp, entity.current_hp + amount)
	set_entity_hp(entity_id, new_hp)

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

# Sync player_state with PlayerStore progression data
func sync_player_from_store():
	"""Sync player battle state with persistent PlayerStore data"""
	var player = BattleStateStore.battle_state.player_state

	# Sync equipped attacks from PlayerStore
	var old_attacks = player.equipped_attacks
	player.equipped_attacks = PlayerStore.equipped_attacks.duplicate()
	BattleStateStore._emit_change("player_state.equipped_attacks", old_attacks, player.equipped_attacks)

	# Sync passive abilities from PlayerStore
	var old_passives = player.passive_abilities
	player.passive_abilities = PlayerStore.passive_abilities.duplicate()
	BattleStateStore._emit_change("player_state.passive_abilities", old_passives, player.passive_abilities)

	# Sync base stats from PlayerStore
	var old_stats = player.base_stats
	player.base_stats = PlayerStore.base_stats.duplicate()
	BattleStateStore._emit_change("player_state.base_stats", old_stats, player.base_stats)

	# Calculate max HP based on constitution (CON * 5 + base 100)
	var old_max_hp = player.max_hp
	var new_max_hp = 100 + (PlayerStore.base_stats.get("con", 10) * 5)
	player.max_hp = new_max_hp
	BattleStateStore._emit_change("player_state.max_hp", old_max_hp, new_max_hp)

	# Restore persistent health from PlayerStore, or start at full if this is the first encounter
	var old_current_hp = player.current_hp
	var restored_hp = PlayerStore.current_hp if PlayerStore.current_hp > 0 else new_max_hp
	player.current_hp = min(restored_hp, new_max_hp)  # Cap at max HP in case it changed
	BattleStateStore._emit_change("player_state.current_hp", old_current_hp, player.current_hp)

	# Calculate max vigor based on player level (2 base + 1 every 5 levels)
	var calculated_max_vigor = PlayerStore.get_max_vigor_for_level()
	player.max_vigor = calculated_max_vigor
	player.current_vigor = calculated_max_vigor

	print("BattleStateMutations: Synced player from PlayerStore - Attacks: %s, Stats: %s, MaxHP: %d" % [player.equipped_attacks, player.base_stats, player.max_hp])

func save_player_hp_to_store():
	"""Save the current player HP from battle state back to persistent PlayerStore"""
	var player = BattleStateStore.battle_state.player_state
	var old_hp = PlayerStore.current_hp
	PlayerStore.current_hp = player.current_hp
	PlayerStore._emit_change("current_hp", old_hp, player.current_hp)
	print("BattleStateMutations: Saved player HP to PlayerStore - HP: %d" % player.current_hp)

# Cooldown management functions
func set_action_cooldown(entity_id: String, action_id: String, rounds: int):
	"""Set a cooldown for a specific action on an entity"""
	var entity = _get_entity_by_id(entity_id)
	if not entity:
		return

	var property_path = _get_entity_property_path(entity_id, "active_cooldowns")
	var old_cooldowns = entity.active_cooldowns.duplicate()

	if rounds > 0:
		entity.active_cooldowns[action_id] = rounds
	else:
		entity.active_cooldowns.erase(action_id)

	BattleStateStore._emit_change(property_path, old_cooldowns, entity.active_cooldowns)

func decrement_all_cooldowns(entity_id: String):
	"""Decrement all active cooldowns for an entity by 1 round"""
	var entity = _get_entity_by_id(entity_id)
	if not entity:
		return

	var property_path = _get_entity_property_path(entity_id, "active_cooldowns")
	var old_cooldowns = entity.active_cooldowns.duplicate()

	var actions_to_remove = []
	for action_id in entity.active_cooldowns.keys():
		entity.active_cooldowns[action_id] -= 1
		if entity.active_cooldowns[action_id] <= 0:
			actions_to_remove.append(action_id)

	# Remove cooldowns that have expired
	for action_id in actions_to_remove:
		entity.active_cooldowns.erase(action_id)

	BattleStateStore._emit_change(property_path, old_cooldowns, entity.active_cooldowns)

func clear_entity_cooldowns(entity_id: String):
	"""Clear all cooldowns for an entity"""
	var entity = _get_entity_by_id(entity_id)
	if not entity:
		return

	var property_path = _get_entity_property_path(entity_id, "active_cooldowns")
	var old_cooldowns = entity.active_cooldowns.duplicate()
	entity.active_cooldowns = {}
	BattleStateStore._emit_change(property_path, old_cooldowns, {})

func increment_round_counter():
	"""Increment the rounds_completed counter in turn state"""
	var old_rounds = BattleStateStore.get_state_value("turn_state.rounds_completed")
	var new_rounds = old_rounds + 1
	BattleStateStore.battle_state.turn_state.rounds_completed = new_rounds
	BattleStateStore._emit_change("turn_state.rounds_completed", old_rounds, new_rounds)
