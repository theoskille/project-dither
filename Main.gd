extends Control

var player_stats_panel: VBoxContainer
var enemy_stats_panel: VBoxContainer
var player_action_panel: VBoxContainer
var enemy_action_panel: VBoxContainer
var turn_indicator: Label
var battlefield_display: VBoxContainer

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

	# Spacer between stats and effects
	var stats_effects_spacer = Control.new()
	stats_effects_spacer.custom_minimum_size = Vector2(0, 20)
	main_vbox.add_child(stats_effects_spacer)

	# Effects panels section (below stats)
	var effects_hbox = HBoxContainer.new()
	effects_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(effects_hbox)

	# Player effects panel (left)
	var player_effects_panel = VBoxContainer.new()
	player_effects_panel.set_script(preload("res://src/ui/EntityEffectsPanel.gd"))
	player_effects_panel.entity_name = "player"
	player_effects_panel.custom_minimum_size = Vector2(200, 0)
	effects_hbox.add_child(player_effects_panel)

	# Spacer (center, matching battlefield width)
	var effects_center_spacer = Control.new()
	effects_center_spacer.custom_minimum_size = Vector2(180, 0)
	effects_hbox.add_child(effects_center_spacer)

	# Enemy effects panel (right)
	var enemy_effects_panel = VBoxContainer.new()
	enemy_effects_panel.set_script(preload("res://src/ui/EntityEffectsPanel.gd"))
	enemy_effects_panel.entity_name = "enemy"
	enemy_effects_panel.custom_minimum_size = Vector2(200, 0)
	effects_hbox.add_child(enemy_effects_panel)

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

	# Enemy action panel (right)
	enemy_action_panel = VBoxContainer.new()
	enemy_action_panel.set_script(preload("res://src/ui/EntityActionPanel.gd"))
	enemy_action_panel.entity_name = "enemy"
	enemy_action_panel.custom_minimum_size = Vector2(200, 0)
	actions_hbox.add_child(enemy_action_panel)

func _connect_signals():
	# No signals to connect - EntityActionPanels handle their own signals
	pass