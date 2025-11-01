extends VBoxContainer

@onready var position_labels = []

func _ready():
	BattleStateStore.state_changed.connect(_on_state_changed)
	_setup_position_labels()
	_update_display()

func _on_state_changed(property_path: String, _old_value, _new_value):
	# Update display when any entity position changes or when enemies array changes
	if property_path.contains("position") or property_path.contains("enemies"):
		_update_display()

func _setup_position_labels():
	var total_tiles = BattleStateStore.get_state_value("battlefield.total_tiles")
	for i in range(total_tiles):
		var label = Label.new()
		label.text = "[ ]"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(label)
		position_labels.append(label)

func _update_display():
	# Clear all positions
	for i in range(position_labels.size()):
		position_labels[i].text = "[ ]"

	# Show player
	var player_pos = BattleStateStore.get_state_value("player_state.position")
	if player_pos >= 0 and player_pos < position_labels.size():
		position_labels[player_pos].text = "[P]"

	# Show all enemies
	var enemies = BattleStateStore.battle_state.enemies
	for i in range(enemies.size()):
		var enemy_pos = enemies[i].position
		if enemy_pos >= 0 and enemy_pos < position_labels.size():
			# If multiple enemies on same tile, show count or concatenate
			if position_labels[enemy_pos].text == "[ ]":
				position_labels[enemy_pos].text = "[E%d]" % i
			elif position_labels[enemy_pos].text.begins_with("[E"):
				# Multiple enemies on same tile - show as [E0,E1]
				var existing = position_labels[enemy_pos].text.trim_prefix("[").trim_suffix("]")
				position_labels[enemy_pos].text = "[%s,E%d]" % [existing, i]
			elif position_labels[enemy_pos].text == "[P]":
				# Player and enemy on same tile
				position_labels[enemy_pos].text = "[P,E%d]" % i