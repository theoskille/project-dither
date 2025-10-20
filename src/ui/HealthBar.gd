extends ProgressBar

@export var entity_name: String = "player"

func _ready():
	BattleStateStore.state_changed.connect(_on_state_changed)
	_update_display()

func _on_state_changed(property_path: String, _old_value, _new_value):
	if property_path == "%s_state.current_hp" % entity_name or property_path == "%s_state.max_hp" % entity_name:
		_update_display()

func _update_display():
	var current_hp = BattleStateStore.get_state_value("%s_state.current_hp" % entity_name)
	var max_hp = BattleStateStore.get_state_value("%s_state.max_hp" % entity_name)
	
	if max_hp > 0:
		value = float(current_hp) / float(max_hp) * 100
	else:
		value = 0