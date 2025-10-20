extends Label

func _ready():
	BattleStateStore.state_changed.connect(_on_state_changed)
	_update_turn_display()

func _on_state_changed(property_path: String, _old_value, _new_value):
	if property_path.begins_with("turn_state"):
		_update_turn_display()

func _update_turn_display():
	var turn_order = BattleStateStore.get_state_value("turn_state.turn_order")
	var current_index = BattleStateStore.get_state_value("turn_state.current_turn_index")
	var turn_number = BattleStateStore.get_state_value("turn_state.current_turn_number")
	
	if turn_order != null and current_index != null and turn_number != null:
		var current_entity = turn_order[current_index]
		text = "Turn %d: %s's turn" % [turn_number, current_entity.capitalize()]