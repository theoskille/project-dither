extends Control

var player_stats_panel: VBoxContainer
var enemy_stats_panels: Array[VBoxContainer] = []
var player_action_panel: VBoxContainer
var enemy_action_panels: Array[VBoxContainer] = []
var turn_indicator: Label
var battlefield_display: VBoxContainer
var player_effects_panel: VBoxContainer
var enemy_effects_panels: Array[VBoxContainer] = []

func _ready():
	# Initialize battle with multiple enemies
	var enemy_configs = [
		{"enemy_id": "goblin", "position": 5},
		{"enemy_id": "orc", "position": 7}
	]
	CombatEngine.initialize_enemies(enemy_configs)
	CombatEngine.start_battle()

	# Build UI
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

	# Enemy stats panels (right) - dynamically create for each enemy
	var enemies_container = VBoxContainer.new()
	middle_hbox.add_child(enemies_container)

	var enemy_count = BattleStateStore.battle_state.enemies.size()
	for i in range(enemy_count):
		var enemy_stats_panel = VBoxContainer.new()
		enemy_stats_panel.set_script(preload("res://src/ui/EntityStatsPanel.gd"))
		enemy_stats_panel.entity_name = "enemy_%d" % i
		enemy_stats_panel.custom_minimum_size = Vector2(200, 0)
		enemies_container.add_child(enemy_stats_panel)
		enemy_stats_panels.append(enemy_stats_panel)

		# Add spacer between enemy panels
		if i < enemy_count - 1:
			var enemy_spacer = Control.new()
			enemy_spacer.custom_minimum_size = Vector2(0, 10)
			enemies_container.add_child(enemy_spacer)

	# Spacer between stats and effects
	var stats_effects_spacer = Control.new()
	stats_effects_spacer.custom_minimum_size = Vector2(0, 20)
	main_vbox.add_child(stats_effects_spacer)

	# Effects panels section (below stats)
	var effects_hbox = HBoxContainer.new()
	effects_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(effects_hbox)

	# Player effects panel (left)
	player_effects_panel = VBoxContainer.new()
	player_effects_panel.set_script(preload("res://src/ui/EntityEffectsPanel.gd"))
	player_effects_panel.entity_name = "player"
	player_effects_panel.custom_minimum_size = Vector2(200, 0)
	effects_hbox.add_child(player_effects_panel)

	# Spacer (center, matching battlefield width)
	var effects_center_spacer = Control.new()
	effects_center_spacer.custom_minimum_size = Vector2(180, 0)
	effects_hbox.add_child(effects_center_spacer)

	# Enemy effects panels (right) - dynamically create for each enemy
	var enemies_effects_container = VBoxContainer.new()
	effects_hbox.add_child(enemies_effects_container)

	for i in range(enemy_count):
		var enemy_effects_panel = VBoxContainer.new()
		enemy_effects_panel.set_script(preload("res://src/ui/EntityEffectsPanel.gd"))
		enemy_effects_panel.entity_name = "enemy_%d" % i
		enemy_effects_panel.custom_minimum_size = Vector2(200, 0)
		enemies_effects_container.add_child(enemy_effects_panel)
		enemy_effects_panels.append(enemy_effects_panel)

		# Add spacer between enemy effect panels
		if i < enemy_count - 1:
			var enemy_effect_spacer = Control.new()
			enemy_effect_spacer.custom_minimum_size = Vector2(0, 10)
			enemies_effects_container.add_child(enemy_effect_spacer)

	# Spacer before action panels
	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 30)
	main_vbox.add_child(bottom_spacer)

	# Action panels section (split left/right)
	var actions_hbox = HBoxContainer.new()
	actions_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(actions_hbox)

	# Player action panel (left)
	player_action_panel = VBoxContainer.new()
	player_action_panel.set_script(preload("res://src/ui/EntityActionPanel.gd"))
	player_action_panel.entity_name = "player"
	player_action_panel.custom_minimum_size = Vector2(200, 0)
	actions_hbox.add_child(player_action_panel)

	# Spacer between action panels
	var action_spacer = Control.new()
	action_spacer.custom_minimum_size = Vector2(180, 0)
	actions_hbox.add_child(action_spacer)

	# Enemy action panels (right) - dynamically create for each enemy
	var enemies_actions_container = VBoxContainer.new()
	actions_hbox.add_child(enemies_actions_container)

	for i in range(enemy_count):
		var enemy_action_panel = VBoxContainer.new()
		enemy_action_panel.set_script(preload("res://src/ui/EntityActionPanel.gd"))
		enemy_action_panel.entity_name = "enemy_%d" % i
		enemy_action_panel.custom_minimum_size = Vector2(200, 0)
		enemies_actions_container.add_child(enemy_action_panel)
		enemy_action_panels.append(enemy_action_panel)

		# Add spacer between enemy action panels
		if i < enemy_count - 1:
			var enemy_action_spacer = Control.new()
			enemy_action_spacer.custom_minimum_size = Vector2(0, 10)
			enemies_actions_container.add_child(enemy_action_spacer)

func _connect_signals():
	# No signals to connect - EntityActionPanels handle their own signals
	pass
