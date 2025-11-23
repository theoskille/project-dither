extends Control

## Main dungeon exploration UI
## Shows dungeon map and movement controls

signal inventory_button_pressed()
signal shop_button_pressed()

var room_displays: Dictionary = {}  # room_id -> RoomDisplay instance
var movement_buttons: Dictionary = {}  # direction -> Button instance
var shop_button: Button = null  # Reference to dynamically shown shop button
var button_grid: GridContainer = null  # Reference for rebuilding buttons

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

	# ScrollContainer for larger dungeons
	var scroll_container = ScrollContainer.new()
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	map_container.add_child(scroll_container)

	# Grid layout for rooms (10x10 sparse grid dungeon)
	var rooms_grid = GridContainer.new()
	rooms_grid.columns = 10
	rooms_grid.add_theme_constant_override("h_separation", 10)
	rooms_grid.add_theme_constant_override("v_separation", 10)
	scroll_container.add_child(rooms_grid)

	# Create room displays (10x10 grid with spacers for empty positions)
	for row in range(10):
		for col in range(10):
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

	# Movement button grid (3x3 with center as inventory button)
	button_grid = GridContainer.new()
	button_grid.columns = 3
	button_grid.add_theme_constant_override("h_separation", 10)
	button_grid.add_theme_constant_override("v_separation", 10)
	controls_vbox.add_child(button_grid)

	# Build the control buttons
	_rebuild_control_buttons()

	# Initial button state update
	_update_movement_buttons()

func _rebuild_control_buttons():
	"""Rebuild the control button grid based on current state"""
	# Clear existing buttons
	for child in button_grid.get_children():
		child.queue_free()

	movement_buttons.clear()
	shop_button = null

	# Check if we should show shop button (visited shop in current room)
	var current_room = DungeonStateStore.get_current_room()
	var show_shop_button = false

	if current_room and current_room.encounter_id == "shop_encounter":
		if ShopEngine.has_visited_shop(DungeonStateStore.current_room_id):
			show_shop_button = true

	# Create directional buttons with inventory button in center
	# Layout: if shop button shown, it replaces bottom-left spacer
	var directions = [
		["", "north", ""],
		["west", "inventory", "east"],
		["", "south", ""]
	]

	for row_idx in range(directions.size()):
		var row = directions[row_idx]
		for col_idx in range(row.size()):
			var dir = row[col_idx]

			if dir == "":
				# Check if this is the bottom-left position and we need shop button
				if row_idx == 2 and col_idx == 0 and show_shop_button:
					shop_button = Button.new()
					shop_button.text = "Shop"
					shop_button.custom_minimum_size = Vector2(80, 40)
					shop_button.pressed.connect(_on_shop_button_pressed)
					button_grid.add_child(shop_button)
				else:
					# Empty spacer
					var spacer = Control.new()
					spacer.custom_minimum_size = Vector2(80, 40)
					button_grid.add_child(spacer)
			elif dir == "inventory":
				# Inventory button in center
				var inv_btn = Button.new()
				inv_btn.text = "Inventory"
				inv_btn.custom_minimum_size = Vector2(80, 40)
				inv_btn.pressed.connect(_on_inventory_button_pressed)
				button_grid.add_child(inv_btn)
			else:
				var btn = Button.new()
				btn.text = dir.capitalize()
				btn.custom_minimum_size = Vector2(80, 40)
				btn.pressed.connect(_on_movement_button_pressed.bind(dir))
				button_grid.add_child(btn)
				movement_buttons[dir] = btn

func _connect_signals():
	DungeonStateStore.state_changed.connect(_on_state_changed)

func _on_state_changed(property_path: String, _old_value, _new_value):
	if property_path == "current_room_id":
		_rebuild_control_buttons()
		_update_movement_buttons()
	elif property_path == "visited_shops":
		# Rebuild buttons when a shop is visited
		_rebuild_control_buttons()

func _update_movement_buttons():
	var valid_directions = DungeonEngine.get_valid_directions()

	for direction in ["north", "south", "east", "west"]:
		if movement_buttons.has(direction):
			var btn = movement_buttons[direction]
			btn.disabled = not (direction in valid_directions)

func _on_movement_button_pressed(direction: String):
	print("DungeonView: Player clicked %s button" % direction)
	DungeonEngine.move_player(direction)

func _on_inventory_button_pressed():
	print("DungeonView: Inventory button pressed")
	inventory_button_pressed.emit()

func _on_shop_button_pressed():
	print("DungeonView: Shop button pressed")
	shop_button_pressed.emit()
