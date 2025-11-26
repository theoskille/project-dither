extends Control

# Responsive top/bottom split combat UI layout
# Top: Turn Indicator + Horizontal Battlefield (takes ~45% of height)
# Bottom: Player Panel (40% width) | Enemy Row (60% width)
# Uses size_flags_stretch_ratio for proportional scaling
# All panels are responsive and will resize with window

var player_panel: PanelContainer
var battlefield_display: PanelContainer
var enemy_grid_display: PanelContainer
var turn_indicator: Label

var _combat_initialized: bool = false

func _ready():
	# Set anchors to fill the screen
	anchor_right = 1.0
	anchor_bottom = 1.0

	# Only build UI if combat has been initialized
	# This prevents UI from accessing empty battle state
	if _combat_initialized:
		_build_ui()
		_connect_signals()
	else:
		push_error("CombatView: _ready() called before initialize_combat()! UI not built.")

func initialize_combat(enemy_configs: Array):
	"""Initialize combat state with the given enemy configurations.
	MUST be called before adding this node to the tree!"""
	CombatEngine.initialize_enemies(enemy_configs)
	CombatEngine.start_battle()
	_combat_initialized = true
	print("CombatView: Combat initialized, ready to build UI")

func _build_ui():
	# Root margin container for padding from screen edges
	var margin_container = MarginContainer.new()
	margin_container.anchor_right = 1.0
	margin_container.anchor_bottom = 1.0
	add_child(margin_container)

	# Main vertical container (top/bottom split)
	var main_vbox = VBoxContainer.new()
	margin_container.add_child(main_vbox)

	# === TURN INDICATOR (Top, full width) ===
	turn_indicator = Label.new()
	turn_indicator.set_script(preload("res://src/ui/TurnIndicator.gd"))
	turn_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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

	# RIGHT: Enemy Grid Display (60% of bottom width)
	enemy_grid_display = PanelContainer.new()
	enemy_grid_display.set_script(preload("res://src/ui/EnemyGridDisplay.gd"))
	enemy_grid_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_grid_display.size_flags_vertical = Control.SIZE_EXPAND_FILL
	enemy_grid_display.size_flags_stretch_ratio = 3.0  # 60% (3 out of 5 total)
	bottom_hbox.add_child(enemy_grid_display)

func _connect_signals():
	# No signals to connect - EntityPanels handle their own signals
	pass
