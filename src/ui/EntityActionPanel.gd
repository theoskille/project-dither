extends VBoxContainer

@export var entity_name: String = "player"

var action_buttons: Array[Button] = []
var move_forward_button: Button
var move_backward_button: Button
var done_turn_button: Button
var target_selection_panel: VBoxContainer = null
var pending_action_id: String = ""

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
	if property_path.contains("%s_state.equipped_attacks" % entity_name) or property_path.contains("enemies."):
		_rebuild_action_buttons()

	# Update button states when turn changes, vigor changes, or positions change
	if (property_path.ends_with("current_turn_index") or
		property_path.contains("%s_state.current_vigor" % entity_name) or
		property_path.contains("position")):
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
	var current_vigor = BattleStateStore.get_state_value("%s_state.current_vigor" % entity_name) if entity_name == "player" else 0

	# For enemies, check if they exist in the enemies array
	if entity_name.begins_with("enemy_"):
		var index = int(entity_name.split("_")[1])
		if index >= BattleStateStore.battle_state.enemies.size():
			# This enemy doesn't exist, disable everything
			for button in action_buttons:
				button.disabled = true
			move_forward_button.disabled = true
			move_backward_button.disabled = true
			done_turn_button.disabled = true
			return
		var enemy = BattleStateStore.battle_state.enemies[index]
		current_vigor = enemy.current_vigor

	# Update action buttons (basic enabled/disabled based on turn and vigor)
	for i in range(action_buttons.size()):
		var button = action_buttons[i]
		var equipped_attacks = BattleStateStore.get_state_value("%s_state.equipped_attacks" % entity_name) if entity_name == "player" else null
		if entity_name.begins_with("enemy_"):
			var index = int(entity_name.split("_")[1])
			var enemy = BattleStateStore.battle_state.enemies[index]
			equipped_attacks = enemy.equipped_attacks

		if equipped_attacks != null and i < equipped_attacks.size():
			var action_id = equipped_attacks[i]
			var action = AttackDatabase.get_action(action_id)
			button.disabled = not is_my_turn or (action and current_vigor < action.vigor_cost)
		else:
			button.disabled = true

	# Update movement buttons
	move_forward_button.disabled = not is_my_turn or current_vigor < 1
	move_backward_button.disabled = not is_my_turn or current_vigor < 1

	# Update done turn button
	done_turn_button.disabled = not is_my_turn

func _on_action_button_pressed(action_id: String):
	var action = AttackDatabase.get_action(action_id)
	if not action:
		return

	# For player, show target selection panel
	if entity_name == "player":
		pending_action_id = action_id
		_show_target_selection(action)
	# For enemies, auto-target the player (simple AI)
	else:
		CombatEngine.execute_move(action, entity_name, "player")

func _show_target_selection(action: ActionData):
	# Create target selection panel if it doesn't exist
	if target_selection_panel == null:
		target_selection_panel = VBoxContainer.new()
		target_selection_panel.set_script(preload("res://src/ui/TargetSelectionPanel.gd"))
		target_selection_panel.target_selected.connect(_on_target_selected)
		target_selection_panel.cancelled.connect(_on_target_selection_cancelled)
		add_child(target_selection_panel)

	# Configure the panel
	target_selection_panel.caster_id = entity_name
	target_selection_panel.action_data = action
	target_selection_panel.visible = true
	target_selection_panel.refresh()  # Update target buttons with current HP/position

	# Hide action buttons while selecting target
	_set_action_buttons_visible(false)

func _on_target_selected(target_id: String):
	# Hide target selection panel
	if target_selection_panel:
		target_selection_panel.visible = false

	# Show action buttons again
	_set_action_buttons_visible(true)

	# Execute the action
	var action = AttackDatabase.get_action(pending_action_id)
	if action:
		CombatEngine.execute_move(action, entity_name, target_id)

	pending_action_id = ""

func _on_target_selection_cancelled():
	# Hide target selection panel
	if target_selection_panel:
		target_selection_panel.visible = false

	# Show action buttons again
	_set_action_buttons_visible(true)

	pending_action_id = ""

func _set_action_buttons_visible(visible: bool):
	for button in action_buttons:
		button.visible = visible
	move_forward_button.visible = visible
	move_backward_button.visible = visible
	done_turn_button.visible = visible

func _on_move_forward_pressed():
	var action = AttackDatabase.get_action("move_forward")
	CombatEngine.execute_move(action, entity_name, entity_name)

func _on_move_backward_pressed():
	var action = AttackDatabase.get_action("move_backward")
	CombatEngine.execute_move(action, entity_name, entity_name)

func _on_done_turn_pressed():
	CombatEngine.end_turn()
