extends PanelContainer

# Fixed 2x2 grid for up to 4 enemies

var grid_container: GridContainer
var enemy_panels: Array[PanelContainer] = []

func _ready():
	BattleStateStore.state_changed.connect(_on_state_changed)
	_build_grid()
	_populate_enemies()

func _build_grid():
	# Create 2-column grid
	grid_container = GridContainer.new()
	grid_container.columns = 2
	add_child(grid_container)

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

	# Create up to 4 enemy panels
	var enemy_count = BattleStateStore.battle_state.enemies.size()
	var max_enemies = min(enemy_count, 4)  # Cap at 4

	for i in range(max_enemies):
		var panel = PanelContainer.new()
		panel.set_script(preload("res://src/ui/EntityPanel.gd"))
		panel.entity_name = "enemy_%d" % i

		# Let panel expand to fill grid cell
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

		grid_container.add_child(panel)
		enemy_panels.append(panel)
