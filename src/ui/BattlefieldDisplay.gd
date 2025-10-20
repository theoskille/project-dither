extends Control

@onready var position_labels = []

func _ready():
	BattleStateStore.state_changed.connect(_on_state_changed)
	_setup_position_labels()
	_update_display()

func _on_state_changed(property_path: String, _old_value, _new_value):
	if property_path.ends_with("_state.position"):
		_update_display()

func _setup_position_labels():
	var total_tiles = BattleStateStore.get_state_value("battlefield.total_tiles")
	for i in range(total_tiles):
		var label = Label.new()
		label.text = "[ ]"
		add_child(label)
		position_labels.append(label)

func _update_display():
	for i in range(position_labels.size()):
		position_labels[i].text = "[ ]"

	var player_pos = BattleStateStore.get_state_value("player_state.position")
	var enemy_pos = BattleStateStore.get_state_value("enemy_state.position")

	if player_pos >= 0 and player_pos < position_labels.size():
		position_labels[player_pos].text = "[P]"

	if enemy_pos >= 0 and enemy_pos < position_labels.size():
		position_labels[enemy_pos].text = "[E]"