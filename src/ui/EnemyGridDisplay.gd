extends ScrollContainer

# Horizontal row display for multiple enemy panels (full EntityPanel for each enemy)

var row_container: HBoxContainer
var enemy_panels: Array[PanelContainer] = []

func _ready():
	BattleStateStore.state_changed.connect(_on_state_changed)
	_build_row()
	_populate_enemies()

func _build_row():
	# Set minimum size
	custom_minimum_size = Vector2(600, 400)

	# Enable horizontal scrolling only
	horizontal_scroll_mode = SCROLL_MODE_AUTO
	vertical_scroll_mode = SCROLL_MODE_DISABLED

	# Create horizontal container for enemy panels
	row_container = HBoxContainer.new()
	row_container.add_theme_constant_override("separation", 12)
	add_child(row_container)

func _on_state_changed(property_path: String, _old_value, _new_value):
	# Rebuild row if enemies array changes size
	if property_path == "enemies" or property_path.begins_with("enemies.") and not property_path.contains("."):
		# Check if we need to rebuild (different number of enemies)
		var current_enemy_count = BattleStateStore.battle_state.enemies.size()
		if current_enemy_count != enemy_panels.size():
			_populate_enemies()

func _populate_enemies():
	# Clear existing panels
	for panel in enemy_panels:
		panel.queue_free()
	enemy_panels.clear()

	# Create full EntityPanel for each enemy
	var enemy_count = BattleStateStore.battle_state.enemies.size()
	for i in range(enemy_count):
		var panel = PanelContainer.new()
		panel.set_script(preload("res://src/ui/EntityPanel.gd"))
		panel.entity_name = "enemy_%d" % i
		row_container.add_child(panel)
		enemy_panels.append(panel)
