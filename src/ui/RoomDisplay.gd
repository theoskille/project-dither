extends PanelContainer

## Displays a single room in the dungeon map
## Shows visited state and current player position

@export var room_id: String = ""

var label: Label
var is_current: bool = false
var is_visited: bool = false
var connection_indicators: Dictionary = {}  # direction -> ColorRect

func _ready():
	custom_minimum_size = Vector2(80, 80)

	# Create a container to hold everything
	var container = Control.new()
	container.anchor_right = 1.0
	container.anchor_bottom = 1.0
	add_child(container)

	# Create connection indicators for all 4 directions
	_create_connection_indicators(container)

	# Create label to show room number (on top of indicators)
	label = Label.new()
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(label)

	# Connect to store signals
	DungeonStateStore.state_changed.connect(_on_state_changed)

	# Initial update
	_update_display()

func _create_connection_indicators(parent: Control):
	# North indicator (top center)
	var north_indicator = ColorRect.new()
	north_indicator.custom_minimum_size = Vector2(10, 3)
	north_indicator.anchor_left = 0.5
	north_indicator.anchor_right = 0.5
	north_indicator.offset_left = -5
	north_indicator.offset_right = 5
	north_indicator.offset_top = 0
	north_indicator.offset_bottom = 3
	north_indicator.color = Color(0.8, 0.8, 0.2)
	parent.add_child(north_indicator)
	connection_indicators["north"] = north_indicator

	# South indicator (bottom center)
	var south_indicator = ColorRect.new()
	south_indicator.custom_minimum_size = Vector2(10, 3)
	south_indicator.anchor_left = 0.5
	south_indicator.anchor_right = 0.5
	south_indicator.anchor_top = 1.0
	south_indicator.anchor_bottom = 1.0
	south_indicator.offset_left = -5
	south_indicator.offset_right = 5
	south_indicator.offset_top = -3
	south_indicator.offset_bottom = 0
	south_indicator.color = Color(0.8, 0.8, 0.2)
	parent.add_child(south_indicator)
	connection_indicators["south"] = south_indicator

	# East indicator (right center)
	var east_indicator = ColorRect.new()
	east_indicator.custom_minimum_size = Vector2(3, 10)
	east_indicator.anchor_left = 1.0
	east_indicator.anchor_right = 1.0
	east_indicator.anchor_top = 0.5
	east_indicator.anchor_bottom = 0.5
	east_indicator.offset_left = -3
	east_indicator.offset_right = 0
	east_indicator.offset_top = -5
	east_indicator.offset_bottom = 5
	east_indicator.color = Color(0.8, 0.8, 0.2)
	parent.add_child(east_indicator)
	connection_indicators["east"] = east_indicator

	# West indicator (left center)
	var west_indicator = ColorRect.new()
	west_indicator.custom_minimum_size = Vector2(3, 10)
	west_indicator.anchor_top = 0.5
	west_indicator.anchor_bottom = 0.5
	west_indicator.offset_left = 0
	west_indicator.offset_right = 3
	west_indicator.offset_top = -5
	west_indicator.offset_bottom = 5
	west_indicator.color = Color(0.8, 0.8, 0.2)
	parent.add_child(west_indicator)
	connection_indicators["west"] = west_indicator

func _on_state_changed(property_path: String, _old_value, _new_value):
	# Update if current room changed or if this room's visited state changed
	if property_path == "current_room_id" or property_path == "rooms.%s.visited" % room_id:
		_update_display()

func _update_display():
	# Check if this is the current room
	is_current = (DungeonStateStore.current_room_id == room_id)

	# Check if this room has been visited
	var room = DungeonStateStore.get_room(room_id)
	is_visited = room.visited if room else false

	# Update label text
	var room_number = room_id.replace("room_", "")
	var is_boss_room = room.room_type == "boss" if room else false

	if is_current:
		if is_boss_room:
			label.text = "[P] [X]\n%s" % room_number  # P for Player, X for Boss/Exit
		else:
			label.text = "[P]\n%s" % room_number  # P for Player
	else:
		if is_boss_room:
			label.text = "[X]\n%s" % room_number  # X for Boss/Exit
		else:
			label.text = "%s" % room_number

	# Update connection indicators visibility
	if room:
		for direction in ["north", "south", "east", "west"]:
			var has_connection = room.connections.get(direction) != null and room.connections.get(direction) != ""
			if connection_indicators.has(direction):
				connection_indicators[direction].visible = has_connection

	# Update visual style based on state
	if is_current:
		# Current room: bright/highlighted
		modulate = Color(1.2, 1.2, 1.0)  # Slightly yellow tint
	elif is_visited:
		# Visited room: normal
		modulate = Color(1.0, 1.0, 1.0)
	else:
		# Unvisited room: darker
		modulate = Color(0.5, 0.5, 0.5)
