extends PanelContainer

## Displays a single room in the dungeon map
## Shows visited state and current player position

@export var room_id: String = ""

var label: Label
var is_current: bool = false
var is_visited: bool = false

func _ready():
	custom_minimum_size = Vector2(80, 80)

	# Create label to show room number
	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(label)

	# Connect to store signals
	DungeonStateStore.state_changed.connect(_on_state_changed)

	# Initial update
	_update_display()

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
	if is_current:
		label.text = "[P]\n%s" % room_number  # P for Player
	else:
		label.text = "%s" % room_number

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
