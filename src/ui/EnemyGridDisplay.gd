extends PanelContainer

# Horizontal scrollable row for any number of enemies

var scroll_container: ScrollContainer
var grid_container: GridContainer
var enemy_panels: Array[PanelContainer] = []

func _ready():
	BattleStateStore.state_changed.connect(_on_state_changed)
	_build_grid()
	_populate_enemies()

func _build_grid():
	# Create scroll container for horizontal scrolling
	scroll_container = ScrollContainer.new()
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO  # Show scrollbar when needed
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED  # No vertical scroll
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll_container)

	# Create single-row grid container
	grid_container = GridContainer.new()
	grid_container.columns = 10  # High number to ensure single row (supports up to 10 enemies)
	scroll_container.add_child(grid_container)

func _on_state_changed(property_path: String, _old_value, _new_value):
	# Rebuild if enemies array changes size
	if property_path == "enemies" or property_path.begins_with("enemies.") and not property_path.contains("."):
		var current_enemy_count = BattleStateStore.battle_state.enemies.size()
		if current_enemy_count != enemy_panels.size():
			_populate_enemies()

func _populate_enemies():
	# Clear existing panels
	for panel in enemy_panels:
		panel.queue_free()
	enemy_panels.clear()

	# Create panel for each enemy
	var enemy_count = BattleStateStore.battle_state.enemies.size()

	for i in range(enemy_count):
		var panel = PanelContainer.new()
		panel.set_script(preload("res://src/ui/EntityPanel.gd"))
		panel.entity_name = "enemy_%d" % i

		# Set minimum width so panels don't get too narrow
		# Let panel expand vertically to fill available height
		panel.custom_minimum_size = Vector2(300, 0)  # Min width 300px, height flexible
		panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

		grid_container.add_child(panel)
		enemy_panels.append(panel)
