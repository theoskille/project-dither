extends Control

const ActionData = preload("res://src/resources/ActionData.gd")

var player_health_bar: ProgressBar
var enemy_health_bar: ProgressBar
var player_vigor_bar: ProgressBar
var enemy_vigor_bar: ProgressBar
var turn_indicator: Label
var battlefield_display: HBoxContainer
var attack_button: Button
var slash_button: Button
var move_forward_button: Button
var move_backward_button: Button
var magic_bolt_button: Button
var done_turn_button: Button

func _ready():
	_build_ui()
	_connect_signals()

func _build_ui():
	var vbox = VBoxContainer.new()
	add_child(vbox)
	
	turn_indicator = Label.new()
	turn_indicator.set_script(preload("res://src/ui/TurnIndicator.gd"))
	vbox.add_child(turn_indicator)
	
	vbox.add_child(Label.new())
	vbox.get_child(-1).text = "Player Health:"
	
	player_health_bar = ProgressBar.new()
	player_health_bar.set_script(preload("res://src/ui/HealthBar.gd"))
	player_health_bar.entity_name = "player"
	player_health_bar.value = 100
	vbox.add_child(player_health_bar)
	
	vbox.add_child(Label.new())
	vbox.get_child(-1).text = "Player Vigor:"
	
	player_vigor_bar = ProgressBar.new()
	player_vigor_bar.set_script(preload("res://src/ui/VigorBar.gd"))
	player_vigor_bar.entity_name = "player"
	player_vigor_bar.value = 3
	vbox.add_child(player_vigor_bar)
	
	vbox.add_child(Label.new())
	vbox.get_child(-1).text = "Enemy Health:"
	
	enemy_health_bar = ProgressBar.new()
	enemy_health_bar.set_script(preload("res://src/ui/HealthBar.gd"))
	enemy_health_bar.entity_name = "enemy"
	enemy_health_bar.value = 100
	vbox.add_child(enemy_health_bar)
	
	vbox.add_child(Label.new())
	vbox.get_child(-1).text = "Enemy Vigor:"
	
	enemy_vigor_bar = ProgressBar.new()
	enemy_vigor_bar.set_script(preload("res://src/ui/VigorBar.gd"))
	enemy_vigor_bar.entity_name = "enemy"
	enemy_vigor_bar.value = 3
	vbox.add_child(enemy_vigor_bar)
	
	vbox.add_child(Label.new())
	vbox.get_child(-1).text = "Battlefield:"
	
	battlefield_display = HBoxContainer.new()
	battlefield_display.set_script(preload("res://src/ui/BattlefieldDisplay.gd"))
	vbox.add_child(battlefield_display)
	
	attack_button = Button.new()
	attack_button.text = "Attack Enemy"
	vbox.add_child(attack_button)

	slash_button = Button.new()
	slash_button.text = "Slash (Range 1)"
	vbox.add_child(slash_button)

	move_forward_button = Button.new()
	move_forward_button.text = "Move Forward"
	vbox.add_child(move_forward_button)
	
	move_backward_button = Button.new()
	move_backward_button.text = "Move Backward"
	vbox.add_child(move_backward_button)
	
	magic_bolt_button = Button.new()
	magic_bolt_button.text = "Magic Bolt (Range 3-6)"
	vbox.add_child(magic_bolt_button)
	
	done_turn_button = Button.new()
	done_turn_button.text = "Done Turn"
	vbox.add_child(done_turn_button)

func _connect_signals():
	attack_button.pressed.connect(_on_attack_pressed)
	slash_button.pressed.connect(_on_slash_pressed)
	move_forward_button.pressed.connect(_on_move_forward_pressed)
	move_backward_button.pressed.connect(_on_move_backward_pressed)
	magic_bolt_button.pressed.connect(_on_magic_bolt_pressed)
	done_turn_button.pressed.connect(_on_done_turn_pressed)
	BattleStateStore.state_changed.connect(_on_state_changed)

func _on_attack_pressed():
	var action = ActionData.new()
	action.action_id = "basic_attack"
	action.action_name = "Attack"
	action.vigor_cost = 1
	action.base_damage = 5
	action.str_modifier = 1.0
	action.min_range = 0
	action.max_range = 1

	var current_entity = CombatEngine._get_current_turn_entity()
	var target = "enemy" if current_entity == "player" else "player"
	CombatEngine.execute_move(action, current_entity, target)

func _on_slash_pressed():
	var action = ActionData.new()
	action.action_id = "slash"
	action.action_name = "Slash"
	action.vigor_cost = 1
	action.base_damage = 5
	action.str_modifier = 1.5
	action.min_range = 1
	action.max_range = 1

	var current_entity = CombatEngine._get_current_turn_entity()
	var target = "enemy" if current_entity == "player" else "player"
	CombatEngine.execute_move(action, current_entity, target)

func _on_move_forward_pressed():
	var action = ActionData.new()
	action.action_id = "move_forward"
	action.action_name = "Move Forward"
	action.vigor_cost = 1
	action.move_caster = 1
	
	var current_entity = CombatEngine._get_current_turn_entity()
	CombatEngine.execute_move(action, current_entity, current_entity)

func _on_move_backward_pressed():
	var action = ActionData.new()
	action.action_id = "move_backward"
	action.action_name = "Move Backward"
	action.vigor_cost = 1
	action.move_caster = -1
	
	var current_entity = CombatEngine._get_current_turn_entity()
	CombatEngine.execute_move(action, current_entity, current_entity)

func _on_magic_bolt_pressed():
	var action = ActionData.new()
	action.action_id = "magic_bolt"
	action.action_name = "Magic Bolt"
	action.vigor_cost = 1
	action.base_damage = 8
	action.int_modifier = 1.5
	action.min_range = 3
	action.max_range = 6
	
	var current_entity = CombatEngine._get_current_turn_entity()
	var target = "enemy" if current_entity == "player" else "player"
	CombatEngine.execute_move(action, current_entity, target)

func _on_done_turn_pressed():
	CombatEngine.end_turn()

func _on_state_changed(_property_path: String, _old_value, _new_value):
	_update_button_states()

func _update_button_states():
	var current_entity = CombatEngine._get_current_turn_entity()
	var current_vigor = BattleStateStore.get_state_value("%s_state.current_vigor" % current_entity)
	var target = "enemy" if current_entity == "player" else "player"

	attack_button.disabled = not _can_use_action("basic_attack", current_entity, target)
	slash_button.disabled = not _can_use_action("slash", current_entity, target)
	move_forward_button.disabled = current_vigor < 1
	move_backward_button.disabled = current_vigor < 1
	magic_bolt_button.disabled = not _can_use_action("magic_bolt", current_entity, target)

func _can_use_action(action_id: String, caster: String, target: String) -> bool:
	var action = ActionData.new()
	if action_id == "basic_attack":
		action.vigor_cost = 1
		action.base_damage = 5
		action.str_modifier = 1.0
		action.min_range = 0
		action.max_range = 1
	elif action_id == "slash":
		action.vigor_cost = 1
		action.base_damage = 5
		action.str_modifier = 1.5
		action.min_range = 1
		action.max_range = 1
	elif action_id == "magic_bolt":
		action.vigor_cost = 1
		action.base_damage = 8
		action.int_modifier = 1.5
		action.min_range = 3
		action.max_range = 6

	return CombatEngine.can_execute_action(action, caster, target)