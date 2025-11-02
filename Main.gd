extends Control

# Responsive three-column combat UI layout
# Layout: [Player Panel (2)] | [Battlefield (2.5)] | [Enemy Grid (3.5)]
# Uses size_flags_stretch_ratio for proportional scaling
# All panels are responsive and will resize with window
# Enemy grid gets more space to fit 2 columns of full EntityPanels

var player_panel: PanelContainer
var battlefield_display: PanelContainer
var enemy_grid_display: ScrollContainer
var turn_indicator: Label

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
	# Set anchors to fill the screen (responsive)
	anchor_right = 1.0
	anchor_bottom = 1.0

	# Root margin container for padding from screen edges
	var margin_container = MarginContainer.new()
	margin_container.anchor_right = 1.0
	margin_container.anchor_bottom = 1.0
	margin_container.add_theme_constant_override("margin_left", 16)
	margin_container.add_theme_constant_override("margin_top", 16)
	margin_container.add_theme_constant_override("margin_right", 16)
	margin_container.add_theme_constant_override("margin_bottom", 16)
	add_child(margin_container)

	# Main vertical container
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 12)
	margin_container.add_child(main_vbox)

	# === TURN INDICATOR (Top, full width) ===
	turn_indicator = Label.new()
	turn_indicator.set_script(preload("res://src/ui/TurnIndicator.gd"))
	turn_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_indicator.add_theme_font_size_override("font_size", 18)
	turn_indicator.custom_minimum_size = Vector2(0, 32)
	main_vbox.add_child(turn_indicator)

	# === THREE-COLUMN LAYOUT (Main content) ===
	var content_hbox = HBoxContainer.new()
	content_hbox.add_theme_constant_override("separation", 16)
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content_hbox)

	# LEFT COLUMN: Player Panel (2 parts ratio)
	player_panel = PanelContainer.new()
	player_panel.set_script(preload("res://src/ui/PlayerPanel.gd"))
	player_panel.entity_name = "player"
	player_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	player_panel.size_flags_stretch_ratio = 2.0
	content_hbox.add_child(player_panel)

	# CENTER COLUMN: Battlefield Display (2.5 parts ratio)
	battlefield_display = PanelContainer.new()
	battlefield_display.set_script(preload("res://src/ui/BattlefieldDisplay.gd"))
	battlefield_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battlefield_display.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battlefield_display.size_flags_stretch_ratio = 2.5
	content_hbox.add_child(battlefield_display)

	# RIGHT COLUMN: Enemy Grid Display (3.5 parts ratio - more space for 2-column grid)
	enemy_grid_display = ScrollContainer.new()
	enemy_grid_display.set_script(preload("res://src/ui/EnemyGridDisplay.gd"))
	enemy_grid_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_grid_display.size_flags_vertical = Control.SIZE_EXPAND_FILL
	enemy_grid_display.size_flags_stretch_ratio = 3.5
	content_hbox.add_child(enemy_grid_display)

func _connect_signals():
	# No signals to connect - EntityActionPanels handle their own signals
	pass
