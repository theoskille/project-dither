extends Control

## UI Layer - Skill Tree View
## Displays skill tree in a grid layout with unlock functionality
## Reactive to PlayerStore changes (follows 4-layer architecture)

const GRID_CELL_SIZE = 60  # Smaller squares
const GRID_SPACING = 40    # More spacing to prevent overlap

var skill_tree_engine: Node
var selected_skill_id: String = ""
var detail_info_vbox: VBoxContainer = null
var detail_button_container: CenterContainer = null

func _ready():
	skill_tree_engine = get_node("/root/SkillTreeEngine")

	# Connect to store signals
	PlayerStore.state_changed.connect(_on_player_state_changed)
	PlayerStore.skill_unlocked.connect(_on_skill_unlocked)

	_build_ui()

func _build_ui():
	# Clear existing children
	for child in get_children():
		child.queue_free()

	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(main_vbox)

	# Header with title and skill points
	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 20)
	main_vbox.add_child(header_hbox)

	var title_label = Label.new()
	title_label.text = "SKILL TREE"
	title_label.add_theme_font_size_override("font_size", 24)
	header_hbox.add_child(title_label)

	header_hbox.add_child(Control.new())  # Spacer
	header_hbox.get_child(1).size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var points_label = Label.new()
	points_label.text = "Skill Points: %d" % PlayerStore.skill_points
	points_label.add_theme_font_size_override("font_size", 20)
	header_hbox.add_child(points_label)

	# Add some spacing
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	main_vbox.add_child(spacer1)

	# Main content area with grid and detail panel
	var content_hbox = HBoxContainer.new()
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.add_theme_constant_override("separation", 20)
	main_vbox.add_child(content_hbox)

	# Left side: Scrollable grid
	var scroll_container = ScrollContainer.new()
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.add_child(scroll_container)

	var grid_container = Control.new()
	grid_container.custom_minimum_size = Vector2(600, 400)
	scroll_container.add_child(grid_container)

	_build_skill_grid(grid_container)

	# Right side: Skill details panel
	var detail_panel = _build_detail_panel()
	detail_panel.custom_minimum_size = Vector2(350, 0)
	content_hbox.add_child(detail_panel)

	# Initialize with empty state
	_update_detail_panel()

func _build_skill_grid(container: Control):
	"""Build the grid of skill nodes"""
	var nodes = skill_tree_engine.get_all_skill_nodes()

	if nodes.is_empty():
		var label = Label.new()
		label.text = "No skills available"
		label.position = Vector2(20, 20)
		container.add_child(label)
		return

	# Find grid bounds
	var min_x = 0
	var min_y = 0
	var max_x = 0
	var max_y = 0

	for node in nodes:
		min_x = min(min_x, node.grid_x)
		min_y = min(min_y, node.grid_y)
		max_x = max(max_x, node.grid_x)
		max_y = max(max_y, node.grid_y)

	# Draw connection lines first (behind nodes)
	_draw_connections(container, nodes, min_x, min_y)

	# Create skill node buttons
	for node in nodes:
		var button = _create_skill_button(node, min_x, min_y)
		container.add_child(button)

func _grid_to_screen_pos(grid_x: int, grid_y: int, offset_x: int, offset_y: int) -> Vector2:
	"""Convert grid coordinates to screen position"""
	var x = (grid_x - offset_x) * (GRID_CELL_SIZE + GRID_SPACING) + GRID_CELL_SIZE / 2
	var y = (grid_y - offset_y) * (GRID_CELL_SIZE + GRID_SPACING) + GRID_CELL_SIZE / 2
	return Vector2(x, y)

func _draw_connections(container: Control, nodes: Array, offset_x: int, offset_y: int):
	"""Draw lines connecting prerequisite skills"""
	var line_drawer = Control.new()
	line_drawer.set_anchors_preset(Control.PRESET_FULL_RECT)
	line_drawer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(line_drawer)

	# Collect connection data
	var connections = []
	for node in nodes:
		for prereq_id in node.prerequisite_node_ids:
			var prereq_node = skill_tree_engine.get_skill_node(prereq_id)
			if prereq_node:
				var from_pos = _grid_to_screen_pos(prereq_node.grid_x, prereq_node.grid_y, offset_x, offset_y)
				var to_pos = _grid_to_screen_pos(node.grid_x, node.grid_y, offset_x, offset_y)
				var prereq_unlocked = prereq_id in PlayerStore.unlocked_skills
				connections.append({"from": from_pos, "to": to_pos, "unlocked": prereq_unlocked})

	# Draw lines
	line_drawer.draw.connect(func():
		for conn in connections:
			var color = Color(0.2, 0.8, 0.2) if conn.unlocked else Color(0.4, 0.4, 0.4)
			line_drawer.draw_line(conn.from, conn.to, color, 2.0)
	)

	line_drawer.queue_redraw()

func _get_skill_symbol(skill_type: String) -> String:
	"""Get the symbol for a skill type"""
	match skill_type:
		"stat_bonus":
			return "STR"
		"upgrade":
			return "UPG"
		"attack":
			return "ATK"
		"passive":
			return "PAS"
		_:
			return "?"

func _create_skill_button(node: SkillNodeData, offset_x: int, offset_y: int) -> Button:
	"""Create a button for a skill node"""
	var button = Button.new()
	button.custom_minimum_size = Vector2(GRID_CELL_SIZE, GRID_CELL_SIZE)

	# Position based on grid coordinates
	var pos = _grid_to_screen_pos(node.grid_x, node.grid_y, offset_x, offset_y)
	button.position = pos - Vector2(GRID_CELL_SIZE / 2, GRID_CELL_SIZE / 2)

	# Button text - just the symbol
	button.text = _get_skill_symbol(node.skill_type)
	button.add_theme_font_size_override("font_size", 14)

	# Style based on unlock status
	var is_unlocked = node.node_id in PlayerStore.unlocked_skills
	var can_unlock = skill_tree_engine.can_unlock_skill(node.node_id).can_unlock

	if is_unlocked:
		button.modulate = Color(0.2, 1.0, 0.2)  # Bright green
	elif can_unlock:
		button.modulate = Color(1.0, 1.0, 0.2)  # Bright yellow
	else:
		button.modulate = Color(0.3, 0.3, 0.3)  # Dark gray

	# Connect click handler
	button.pressed.connect(func(): _on_skill_button_pressed(node.node_id))

	# Tooltip for hover preview
	button.tooltip_text = node.node_name

	return button

func _build_detail_panel() -> PanelContainer:
	"""Build the skill detail panel on the right side"""
	var panel = PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# Title section
	var title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "Skill Details"
	title_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title_label)

	# Separator
	var separator = HSeparator.new()
	vbox.add_child(separator)

	# Info section (scrollable)
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var info_vbox = VBoxContainer.new()
	info_vbox.name = "InfoVBox"
	info_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(info_vbox)

	# Store reference for updates
	detail_info_vbox = info_vbox

	# Unlock button section
	var button_container = CenterContainer.new()
	button_container.name = "ButtonContainer"
	vbox.add_child(button_container)

	# Store reference for updates
	detail_button_container = button_container

	return panel

func _on_skill_button_pressed(skill_id: String):
	"""Handle skill button click"""
	selected_skill_id = skill_id
	_update_detail_panel()

func _update_detail_panel():
	"""Update the detail panel with selected skill info"""
	if not detail_info_vbox or not detail_button_container:
		return

	# Clear existing info
	for child in detail_info_vbox.get_children():
		child.queue_free()

	# Clear existing button
	for child in detail_button_container.get_children():
		child.queue_free()

	if selected_skill_id == "":
		var label = Label.new()
		label.text = "Click a skill node to view details"
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		detail_info_vbox.add_child(label)
		return

	var node = skill_tree_engine.get_skill_node(selected_skill_id)
	if not node:
		return

	var is_unlocked = node.node_id in PlayerStore.unlocked_skills
	var check = skill_tree_engine.can_unlock_skill(node.node_id)

	# Skill name
	var name_label = Label.new()
	name_label.text = node.node_name
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.8))
	detail_info_vbox.add_child(name_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = node.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	detail_info_vbox.add_child(desc_label)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	detail_info_vbox.add_child(spacer)

	# Type
	var type_label = Label.new()
	type_label.text = "Type: %s %s" % [_get_skill_symbol(node.skill_type), node.skill_type.capitalize()]
	detail_info_vbox.add_child(type_label)

	# Cost
	var cost_label = Label.new()
	cost_label.text = "Cost: %d skill point(s)" % node.skill_point_cost
	detail_info_vbox.add_child(cost_label)

	# Level requirement
	var level_label = Label.new()
	var level_met = PlayerStore.level >= node.level_requirement
	var level_color = Color.GREEN if level_met else Color.RED
	level_label.text = "Level Required: %d" % node.level_requirement
	level_label.add_theme_color_override("font_color", level_color)
	detail_info_vbox.add_child(level_label)

	# Prerequisites
	if node.prerequisite_node_ids.size() > 0:
		var prereq_spacer = Control.new()
		prereq_spacer.custom_minimum_size = Vector2(0, 5)
		detail_info_vbox.add_child(prereq_spacer)

		var prereq_header = Label.new()
		prereq_header.text = "Prerequisites:"
		prereq_header.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		detail_info_vbox.add_child(prereq_header)

		for prereq_id in node.prerequisite_node_ids:
			var prereq = skill_tree_engine.get_skill_node(prereq_id)
			var prereq_name = prereq.node_name if prereq else prereq_id
			var prereq_unlocked = prereq_id in PlayerStore.unlocked_skills
			var check_mark = "[X]" if prereq_unlocked else "[ ]"
			var prereq_color = Color.GREEN if prereq_unlocked else Color.RED

			var prereq_label = Label.new()
			prereq_label.text = "  %s %s" % [check_mark, prereq_name]
			prereq_label.add_theme_color_override("font_color", prereq_color)
			detail_info_vbox.add_child(prereq_label)

	# Status
	var status_spacer = Control.new()
	status_spacer.custom_minimum_size = Vector2(0, 10)
	detail_info_vbox.add_child(status_spacer)

	var status_label = Label.new()
	if is_unlocked:
		status_label.text = "UNLOCKED"
		status_label.add_theme_color_override("font_color", Color.GREEN)
		status_label.add_theme_font_size_override("font_size", 16)
	elif check.can_unlock:
		status_label.text = "Ready to unlock!"
		status_label.add_theme_color_override("font_color", Color.YELLOW)
		status_label.add_theme_font_size_override("font_size", 16)
	else:
		status_label.text = "%s" % check.reason
		status_label.add_theme_color_override("font_color", Color.RED)
		status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	detail_info_vbox.add_child(status_label)

	# Unlock button (only if can unlock)
	if not is_unlocked and check.can_unlock:
		var unlock_button = Button.new()
		unlock_button.text = "UNLOCK SKILL"
		unlock_button.custom_minimum_size = Vector2(200, 50)
		unlock_button.add_theme_font_size_override("font_size", 18)
		unlock_button.pressed.connect(func(): _on_unlock_button_pressed(selected_skill_id))
		detail_button_container.add_child(unlock_button)

func _on_unlock_button_pressed(skill_id: String):
	"""Handle unlock button press"""
	var success = skill_tree_engine.attempt_unlock_skill(skill_id)

	if success:
		# UI will update automatically via signals
		_update_detail_panel()

func _on_player_state_changed(_property_path: String, _old_value, _new_value):
	"""Handle player state changes"""
	_build_ui()

func _on_skill_unlocked(_skill_id: String):
	"""Handle skill unlock event"""
	# Rebuild UI to show new unlock status
	_build_ui()
