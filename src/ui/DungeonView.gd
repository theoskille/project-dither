extends Control

## Main dungeon exploration UI
## Shows dungeon map and movement controls

var room_displays: Dictionary = {}  # room_id -> RoomDisplay instance
var movement_buttons: Dictionary = {}  # direction -> Button instance

func _ready():
	# Set anchors to fill the screen
	anchor_right = 1.0
	anchor_bottom = 1.0

	_build_ui()
	_connect_signals()

func _build_ui():
	# Root margin container
	var margin = MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	add_child(margin)

	# Main vertical layout
	var main_vbox = VBoxContainer.new()
	margin.add_child(main_vbox)

	# Title
	var title = Label.new()
	title.text = "DUNGEON EXPLORATION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(0, 48)
	main_vbox.add_child(title)

	# === DUNGEON MAP (Center) ===
	var map_container = PanelContainer.new()
	map_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_container.size_flags_stretch_ratio = 2.0
	main_vbox.add_child(map_container)

	# Grid layout for rooms (5x5 sparse grid dungeon)
	var rooms_grid = GridContainer.new()
	rooms_grid.columns = 5
	rooms_grid.add_theme_constant_override("h_separation", 10)
	rooms_grid.add_theme_constant_override("v_separation", 10)
	map_container.add_child(rooms_grid)

	# Create room displays (5x5 grid with spacers for empty positions)
	for row in range(5):
		for col in range(5):
			var room_id = "room_%d_%d" % [row, col]

			# Check if this position has a room in the dungeon
			var room_exists = DungeonStateStore.get_room(room_id) != null

			if room_exists:
				# Create actual room display
				var room_display = PanelContainer.new()
				room_display.set_script(preload("res://src/ui/RoomDisplay.gd"))
				room_display.room_id = room_id
				rooms_grid.add_child(room_display)
				room_displays[room_id] = room_display
			else:
				# Create invisible spacer for empty grid position
				var spacer = Control.new()
				spacer.custom_minimum_size = Vector2(80, 80)
				spacer.modulate = Color(0, 0, 0, 0)  # Fully transparent
				rooms_grid.add_child(spacer)

	# === MOVEMENT CONTROLS (Bottom) ===
	var controls_container = PanelContainer.new()
	controls_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls_container.custom_minimum_size = Vector2(0, 150)
	main_vbox.add_child(controls_container)

	var controls_vbox = VBoxContainer.new()
	controls_container.add_child(controls_vbox)

	var controls_label = Label.new()
	controls_label.text = "Movement"
	controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_vbox.add_child(controls_label)

	# Movement button grid (3x3 with center empty)
	var button_grid = GridContainer.new()
	button_grid.columns = 3
	button_grid.add_theme_constant_override("h_separation", 10)
	button_grid.add_theme_constant_override("v_separation", 10)
	controls_vbox.add_child(button_grid)

	# Create directional buttons
	var directions = [
		["", "north", ""],
		["west", "", "east"],
		["", "south", ""]
	]

	for row in directions:
		for dir in row:
			if dir == "":
				# Empty spacer
				var spacer = Control.new()
				spacer.custom_minimum_size = Vector2(80, 40)
				button_grid.add_child(spacer)
			else:
				var btn = Button.new()
				btn.text = dir.capitalize()
				btn.custom_minimum_size = Vector2(80, 40)
				btn.pressed.connect(_on_movement_button_pressed.bind(dir))
				button_grid.add_child(btn)
				movement_buttons[dir] = btn

	# Initial button state update
	_update_movement_buttons()

func _connect_signals():
	DungeonStateStore.state_changed.connect(_on_state_changed)

func _on_state_changed(property_path: String, _old_value, _new_value):
	if property_path == "current_room_id":
		_update_movement_buttons()

func _update_movement_buttons():
	var valid_directions = DungeonEngine.get_valid_directions()

	for direction in ["north", "south", "east", "west"]:
		if movement_buttons.has(direction):
			var btn = movement_buttons[direction]
			btn.disabled = not (direction in valid_directions)

func _on_movement_button_pressed(direction: String):
	print("DungeonView: Player clicked %s button" % direction)
	DungeonEngine.move_player(direction)
