extends Control

# Responsive top/bottom split combat UI layout
# Top: Turn Indicator + Horizontal Battlefield (takes ~45% of height)
# Bottom: Player Panel (40% width) | Enemy Row (60% width)
# Uses size_flags_stretch_ratio for proportional scaling
# All panels are responsive and will resize with window

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

	# Main vertical container (top/bottom split)
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 16)
	margin_container.add_child(main_vbox)

	# === TURN INDICATOR (Top, full width) ===
	turn_indicator = Label.new()
	turn_indicator.set_script(preload("res://src/ui/TurnIndicator.gd"))
	turn_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_indicator.add_theme_font_size_override("font_size", 18)
	turn_indicator.custom_minimum_size = Vector2(0, 32)
	main_vbox.add_child(turn_indicator)

	# === TOP SECTION: Battlefield (horizontal) ===
	battlefield_display = PanelContainer.new()
	battlefield_display.set_script(preload("res://src/ui/BattlefieldDisplay.gd"))
	battlefield_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battlefield_display.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battlefield_display.size_flags_stretch_ratio = 1.0  # Takes up space
	main_vbox.add_child(battlefield_display)

	# === BOTTOM SECTION: Player (left) and Enemies (right) ===
	var bottom_hbox = HBoxContainer.new()
	bottom_hbox.add_theme_constant_override("separation", 16)
	bottom_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom_hbox.size_flags_stretch_ratio = 1.2  # Slightly more space than battlefield
	main_vbox.add_child(bottom_hbox)

	# LEFT: Player Panel (40% of bottom width)
	player_panel = PanelContainer.new()
	player_panel.set_script(preload("res://src/ui/PlayerPanel.gd"))
	player_panel.entity_name = "player"
	player_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	player_panel.size_flags_stretch_ratio = 2.0  # 40% (2 out of 5 total)
	bottom_hbox.add_child(player_panel)

	# RIGHT: Enemy Row Display (60% of bottom width)
	enemy_grid_display = ScrollContainer.new()
	enemy_grid_display.set_script(preload("res://src/ui/EnemyGridDisplay.gd"))
	enemy_grid_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_grid_display.size_flags_vertical = Control.SIZE_EXPAND_FILL
	enemy_grid_display.size_flags_stretch_ratio = 3.0  # 60% (3 out of 5 total)
	bottom_hbox.add_child(enemy_grid_display)

func _connect_signals():
	# No signals to connect - EntityActionPanels handle their own signals
	pass
