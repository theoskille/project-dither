extends Control

## Main scene manager with view stack
## Handles transitions between dungeon exploration, combat, and inventory
## Supports push/pop navigation for hierarchical views

enum GameMode { DUNGEON, COMBAT }

var current_mode: GameMode = GameMode.DUNGEON
var view_stack: Array[Control] = []  # Stack of active views
var current_view: Control = null

var dungeon_view: Control
var combat_view: Control
var victory_screen: Control

func _ready():
	# Set anchors to fill the screen
	anchor_right = 1.0
	anchor_bottom = 1.0

	# Connect to engine signals
	DungeonEngine.encounter_triggered.connect(_on_encounter_triggered)
	CombatEngine.victory_achieved.connect(_on_victory_achieved)

	# Start in dungeon mode
	DungeonEngine.start_dungeon()
	_switch_to_dungeon_view()

func push_view(view_script: GDScript):
	"""Push a new view onto the stack and display it"""
	print("Main: Pushing view onto stack")

	# Hide current view if it exists
	if current_view:
		current_view.visible = false

	# Create new view
	var new_view = Control.new()
	new_view.set_script(view_script)
	add_child(new_view)

	# Connect to view signals if they exist
	if new_view.has_signal("back_button_pressed"):
		new_view.back_button_pressed.connect(_on_inventory_closed)

	# Add to stack
	view_stack.append(new_view)
	current_view = new_view

func pop_view():
	"""Remove the current view and return to the previous one"""
	print("Main: Popping view from stack")

	if view_stack.size() <= 1:
		push_warning("Main: Cannot pop last view from stack")
		return

	# Remove and free current view
	var old_view = view_stack.pop_back()
	remove_child(old_view)
	old_view.queue_free()

	# Show previous view
	current_view = view_stack[-1]
	current_view.visible = true

func _switch_to_dungeon_view():
	print("Main: Switching to dungeon view")

	# Clear view stack
	for view in view_stack:
		remove_child(view)
		view.queue_free()
	view_stack.clear()

	# Create dungeon view
	dungeon_view = Control.new()
	dungeon_view.set_script(preload("res://src/ui/DungeonView.gd"))
	dungeon_view.anchor_right = 1.0
	dungeon_view.anchor_bottom = 1.0
	add_child(dungeon_view)

	# Connect to dungeon view signals
	dungeon_view.inventory_button_pressed.connect(_on_inventory_opened)

	view_stack.append(dungeon_view)
	current_view = dungeon_view
	current_mode = GameMode.DUNGEON

func _switch_to_combat_view(encounter_id: String):
	print("Main: Switching to combat view for encounter: %s" % encounter_id)

	# Clear view stack
	for view in view_stack:
		remove_child(view)
		view.queue_free()
	view_stack.clear()

	# Get encounter data
	var encounter = EncounterDatabase.get_encounter(encounter_id)
	if not encounter:
		push_error("Main: Failed to load encounter '%s'" % encounter_id)
		_switch_to_dungeon_view()
		return

	# CRITICAL: Reset battle state before starting new encounter
	CombatEngine.reset_battle()

	# Create combat view (but don't add to tree yet)
	combat_view = Control.new()
	combat_view.set_script(preload("res://src/ui/CombatView.gd"))

	# Initialize combat state BEFORE adding to tree
	# This ensures battle state is populated before UI components try to read it
	combat_view.initialize_combat(encounter.enemy_configs)

	# Now add to tree - this triggers _ready() and UI building
	combat_view.anchor_right = 1.0
	combat_view.anchor_bottom = 1.0
	add_child(combat_view)

	view_stack.append(combat_view)
	current_view = combat_view
	current_mode = GameMode.COMBAT

func _on_encounter_triggered(encounter_id: String):
	print("Main: Encounter triggered: %s" % encounter_id)
	_switch_to_combat_view(encounter_id)

func _on_victory_achieved(total_xp: int, levels_gained: int):
	print("Main: Victory achieved - showing victory screen")

	# Create victory screen overlay
	victory_screen = Control.new()
	victory_screen.set_script(preload("res://src/ui/VictoryScreen.gd"))
	victory_screen.anchor_right = 1.0
	victory_screen.anchor_bottom = 1.0

	# Initialize with XP data BEFORE adding to tree
	victory_screen.initialize(total_xp, levels_gained)

	# Add to tree (this triggers _ready())
	add_child(victory_screen)

	# Connect to victory screen's continue button
	victory_screen.continue_pressed.connect(_on_victory_continue_pressed)

func _on_victory_continue_pressed():
	print("Main: Victory continue pressed, returning to dungeon")

	# Remove victory screen
	if victory_screen:
		remove_child(victory_screen)
		victory_screen.queue_free()
		victory_screen = null

	# Clear the encounter from the current room
	var current_room_id = DungeonStateStore.current_room_id
	DungeonStateMutations.clear_room_encounter(current_room_id)

	# Switch back to dungeon view
	_switch_to_dungeon_view()

func _on_inventory_opened():
	print("Main: Opening inventory view")
	push_view(preload("res://src/ui/InventoryView.gd"))

func _on_inventory_closed():
	print("Main: Closing inventory view")
	pop_view()
