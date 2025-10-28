extends VBoxContainer

@export var entity_name: String = "player"

var action_buttons: Array[Button] = []
var move_forward_button: Button
var move_backward_button: Button
var done_turn_button: Button

func _ready():
	BattleStateStore.state_changed.connect(_on_state_changed)
	_build_panel()
	_update_buttons()

func _build_panel():
	# Title label
	var title = Label.new()
	title.text = "%s ACTIONS" % entity_name.to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	add_child(spacer)

	# Movement buttons
	move_forward_button = Button.new()
	move_forward_button.text = "Move Forward"
	move_forward_button.pressed.connect(_on_move_forward_pressed)
	add_child(move_forward_button)

	move_backward_button = Button.new()
	move_backward_button.text = "Move Backward"
	move_backward_button.pressed.connect(_on_move_backward_pressed)
	add_child(move_backward_button)

	# Done turn button
	done_turn_button = Button.new()
	done_turn_button.text = "Done Turn"
	done_turn_button.pressed.connect(_on_done_turn_pressed)
	add_child(done_turn_button)

	# Attack buttons will be added dynamically in _rebuild_action_buttons()
	# They will be inserted before the movement buttons
	_rebuild_action_buttons()

func _on_state_changed(property_path: String, _old_value, _new_value):
	# Rebuild attack buttons if equipped attacks changed for this entity
	if property_path == "%s_state.equipped_attacks" % entity_name:
		_rebuild_action_buttons()

	# Determine target entity
	var target = "enemy" if entity_name == "player" else "player"

	# Update button states when turn changes, vigor changes, or positions change
	if (property_path.ends_with("current_turn_index") or
		property_path == "%s_state.current_vigor" % entity_name or
		property_path == "%s_state.position" % entity_name or
		property_path == "%s_state.position" % target):
		_update_buttons()

func _rebuild_action_buttons():
	# Clear existing action buttons
	for button in action_buttons:
		button.queue_free()
	action_buttons.clear()

	# Get equipped attacks for this entity
	var equipped_attacks = BattleStateStore.get_state_value("%s_state.equipped_attacks" % entity_name)
	if equipped_attacks == null:
		return

	# Create button for each equipped attack
	# Insert position is after title (index 0) and spacer (index 1), so start at index 2
	var insert_index = 2

	for action_id in equipped_attacks:
		var action_data = AttackDatabase.get_action(action_id)
		if action_data == null:
			continue

		var button = Button.new()
		button.text = "%s (Range %d-%d)" % [action_data.action_name, action_data.min_range, action_data.max_range]
		button.pressed.connect(_on_action_button_pressed.bind(action_id))

		# Insert at the current position and increment for next button
		add_child(button)
		move_child(button, insert_index)
		insert_index += 1
		action_buttons.append(button)

func _update_buttons():
	var current_entity = CombatEngine._get_current_turn_entity()
	var is_my_turn = (current_entity == entity_name)
	var current_vigor = BattleStateStore.get_state_value("%s_state.current_vigor" % entity_name)
	var target = "enemy" if entity_name == "player" else "player"

	# Update action buttons
	for i in range(action_buttons.size()):
		var button = action_buttons[i]
		var equipped_attacks = BattleStateStore.get_state_value("%s_state.equipped_attacks" % entity_name)
		if equipped_attacks != null and i < equipped_attacks.size():
			var action_id = equipped_attacks[i]
			button.disabled = not is_my_turn or not _can_use_action(action_id, entity_name, target)
		else:
			button.disabled = true

	# Update movement buttons
	move_forward_button.disabled = not is_my_turn or current_vigor < 1
	move_backward_button.disabled = not is_my_turn or current_vigor < 1

	# Update done turn button
	done_turn_button.disabled = not is_my_turn

func _can_use_action(action_id: String, caster: String, target: String) -> bool:
	var action = AttackDatabase.get_action(action_id)
	if action == null:
		return false
	return CombatEngine.can_execute_action(action, caster, target)

func _on_action_button_pressed(action_id: String):
	var action = AttackDatabase.get_action(action_id)
	var target = "enemy" if entity_name == "player" else "player"
	CombatEngine.execute_move(action, entity_name, target)

func _on_move_forward_pressed():
	var action = AttackDatabase.get_action("move_forward")
	CombatEngine.execute_move(action, entity_name, entity_name)

func _on_move_backward_pressed():
	var action = AttackDatabase.get_action("move_backward")
	CombatEngine.execute_move(action, entity_name, entity_name)

func _on_done_turn_pressed():
	CombatEngine.end_turn()
