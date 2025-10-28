extends Control

var player_stats_panel: VBoxContainer
var enemy_stats_panel: VBoxContainer
var turn_indicator: Label
var battlefield_display: VBoxContainer
var attack_buttons: Array[Button] = []
var attack_container: HBoxContainer
var move_forward_button: Button
var move_backward_button: Button
var done_turn_button: Button

func _ready():
	_build_ui()
	_connect_signals()

func _build_ui():
	# Main vertical container
	var main_vbox = VBoxContainer.new()
	add_child(main_vbox)

	# Turn indicator at top (full width)
	turn_indicator = Label.new()
	turn_indicator.set_script(preload("res://src/ui/TurnIndicator.gd"))
	turn_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(turn_indicator)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	main_vbox.add_child(spacer)

	# Middle section: Player Stats | Battlefield | Enemy Stats
	var middle_hbox = HBoxContainer.new()
	middle_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(middle_hbox)

	# Player stats panel (left)
	player_stats_panel = VBoxContainer.new()
	player_stats_panel.set_script(preload("res://src/ui/EntityStatsPanel.gd"))
	player_stats_panel.entity_name = "player"
	player_stats_panel.custom_minimum_size = Vector2(200, 0)
	middle_hbox.add_child(player_stats_panel)

	# Spacer
	var center_spacer = Control.new()
	center_spacer.custom_minimum_size = Vector2(40, 0)
	middle_hbox.add_child(center_spacer)

	# Battlefield display (center)
	battlefield_display = VBoxContainer.new()
	battlefield_display.set_script(preload("res://src/ui/BattlefieldDisplay.gd"))
	battlefield_display.custom_minimum_size = Vector2(100, 0)
	middle_hbox.add_child(battlefield_display)

	# Spacer
	var right_spacer = Control.new()
	right_spacer.custom_minimum_size = Vector2(40, 0)
	middle_hbox.add_child(right_spacer)

	# Enemy stats panel (right)
	enemy_stats_panel = VBoxContainer.new()
	enemy_stats_panel.set_script(preload("res://src/ui/EntityStatsPanel.gd"))
	enemy_stats_panel.entity_name = "enemy"
	enemy_stats_panel.custom_minimum_size = Vector2(200, 0)
	middle_hbox.add_child(enemy_stats_panel)

	# Spacer before controls
	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 30)
	main_vbox.add_child(bottom_spacer)

	# Controls section at bottom
	var controls_vbox = VBoxContainer.new()
	controls_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(controls_vbox)

	# Attack buttons container (horizontal)
	attack_container = HBoxContainer.new()
	attack_container.alignment = BoxContainer.ALIGNMENT_CENTER
	controls_vbox.add_child(attack_container)
	_rebuild_attack_buttons()

	# Movement buttons container
	var movement_hbox = HBoxContainer.new()
	movement_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	controls_vbox.add_child(movement_hbox)

	move_forward_button = Button.new()
	move_forward_button.text = "Move Forward"
	movement_hbox.add_child(move_forward_button)

	move_backward_button = Button.new()
	move_backward_button.text = "Move Backward"
	movement_hbox.add_child(move_backward_button)

	# Done turn button
	done_turn_button = Button.new()
	done_turn_button.text = "Done Turn"
	controls_vbox.add_child(done_turn_button)

func _connect_signals():
	move_forward_button.pressed.connect(_on_move_forward_pressed)
	move_backward_button.pressed.connect(_on_move_backward_pressed)
	done_turn_button.pressed.connect(_on_done_turn_pressed)
	BattleStateStore.state_changed.connect(_on_state_changed)

func _rebuild_attack_buttons():
	# Clear existing attack buttons
	for button in attack_buttons:
		button.queue_free()
	attack_buttons.clear()

	# Get current entity's equipped attacks
	var current_entity = CombatEngine._get_current_turn_entity()
	var equipped_attacks = BattleStateStore.get_state_value("%s_state.equipped_attacks" % current_entity)

	if equipped_attacks == null:
		return

	# Create button for each equipped attack
	for action_id in equipped_attacks:
		var action_data = AttackDatabase.get_action(action_id)
		if action_data == null:
			continue

		var button = Button.new()
		button.text = "%s (Range %d-%d)" % [action_data.action_name, action_data.min_range, action_data.max_range]
		button.pressed.connect(_on_attack_button_pressed.bind(action_id))
		attack_container.add_child(button)
		attack_buttons.append(button)

func _on_attack_button_pressed(action_id: String):
	var action = AttackDatabase.get_action(action_id)
	var current_entity = CombatEngine._get_current_turn_entity()
	var target = "enemy" if current_entity == "player" else "player"
	CombatEngine.execute_move(action, current_entity, target)

func _on_move_forward_pressed():
	var action = AttackDatabase.get_action("move_forward")
	var current_entity = CombatEngine._get_current_turn_entity()
	CombatEngine.execute_move(action, current_entity, current_entity)

func _on_move_backward_pressed():
	var action = AttackDatabase.get_action("move_backward")
	var current_entity = CombatEngine._get_current_turn_entity()
	CombatEngine.execute_move(action, current_entity, current_entity)

func _on_done_turn_pressed():
	CombatEngine.end_turn()

func _on_state_changed(_property_path: String, _old_value, _new_value):
	# Rebuild attack buttons if turn changed
	if _property_path.ends_with("current_turn"):
		_rebuild_attack_buttons()
	_update_button_states()

func _update_button_states():
	var current_entity = CombatEngine._get_current_turn_entity()
	var current_vigor = BattleStateStore.get_state_value("%s_state.current_vigor" % current_entity)
	var target = "enemy" if current_entity == "player" else "player"

	# Update dynamic attack buttons
	var equipped_attacks = BattleStateStore.get_state_value("%s_state.equipped_attacks" % current_entity)
	if equipped_attacks != null:
		for i in range(attack_buttons.size()):
			if i < equipped_attacks.size():
				var action_id = equipped_attacks[i]
				attack_buttons[i].disabled = not _can_use_action(action_id, current_entity, target)

	# Update movement buttons
	move_forward_button.disabled = current_vigor < 1
	move_backward_button.disabled = current_vigor < 1

func _can_use_action(action_id: String, caster: String, target: String) -> bool:
	var action = AttackDatabase.get_action(action_id)
	if action == null:
		return false
	return CombatEngine.can_execute_action(action, caster, target)