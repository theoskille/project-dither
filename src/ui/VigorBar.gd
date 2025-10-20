extends ProgressBar

@export var entity_name: String = ""

func _ready():
	BattleStateStore.state_changed.connect(_on_state_changed)
	_update_vigor()

func _on_state_changed(property_path: String, _old_value, _new_value):
	if property_path.begins_with("%s_state.current_vigor" % entity_name) or property_path.begins_with("%s_state.max_vigor" % entity_name):
		_update_vigor()

func _update_vigor():
	var current_vigor = BattleStateStore.get_state_value("%s_state.current_vigor" % entity_name)
	var max_vigor = BattleStateStore.get_state_value("%s_state.max_vigor" % entity_name)
	
	if current_vigor != null and max_vigor != null:
		max_value = max_vigor
		value = current_vigor