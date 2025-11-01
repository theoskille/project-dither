extends ProgressBar

@export var entity_name: String = ""

func _ready():
	BattleStateStore.state_changed.connect(_on_state_changed)
	_update_vigor()

func _on_state_changed(property_path: String, _old_value, _new_value):
	# Handle both old format (player_state) and new format (enemies.0)
	if entity_name == "player":
		if property_path == "player_state.current_vigor" or property_path == "player_state.max_vigor":
			_update_vigor()
	elif entity_name.begins_with("enemy_"):
		var index = int(entity_name.split("_")[1])
		if property_path.begins_with("enemies.%d." % index):
			_update_vigor()

func _get_entity() -> EntityState:
	if entity_name == "player":
		return BattleStateStore.battle_state.player_state
	elif entity_name.begins_with("enemy_"):
		var index = int(entity_name.split("_")[1])
		if index >= 0 and index < BattleStateStore.battle_state.enemies.size():
			return BattleStateStore.battle_state.enemies[index]
	return null

func _update_vigor():
	var entity = _get_entity()
	if not entity:
		max_value = 0
		value = 0
		return

	max_value = entity.max_vigor
	value = entity.current_vigor