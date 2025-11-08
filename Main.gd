extends Control

## Main scene manager
## Handles transitions between dungeon exploration and combat

enum GameMode { DUNGEON, COMBAT }

var current_mode: GameMode = GameMode.DUNGEON
var current_view: Control = null

var dungeon_view: Control
var combat_view: Control

func _ready():
	# Set anchors to fill the screen
	anchor_right = 1.0
	anchor_bottom = 1.0

	# Connect to engine signals
	DungeonEngine.encounter_triggered.connect(_on_encounter_triggered)
	CombatEngine.battle_ended.connect(_on_battle_ended)

	# Start in dungeon mode
	DungeonEngine.start_dungeon()
	_switch_to_dungeon_view()

func _switch_to_dungeon_view():
	print("Main: Switching to dungeon view")

	# Remove current view if it exists
	if current_view:
		remove_child(current_view)
		current_view.queue_free()

	# Create dungeon view
	dungeon_view = Control.new()
	dungeon_view.set_script(preload("res://src/ui/DungeonView.gd"))
	add_child(dungeon_view)

	current_view = dungeon_view
	current_mode = GameMode.DUNGEON

func _switch_to_combat_view(encounter_id: String):
	print("Main: Switching to combat view for encounter: %s" % encounter_id)

	# Remove current view if it exists
	if current_view:
		remove_child(current_view)
		current_view.queue_free()

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
	add_child(combat_view)

	current_view = combat_view
	current_mode = GameMode.COMBAT

func _on_encounter_triggered(encounter_id: String):
	print("Main: Encounter triggered: %s" % encounter_id)
	_switch_to_combat_view(encounter_id)

func _on_battle_ended():
	print("Main: Battle ended, returning to dungeon")

	# Clear the encounter from the current room
	var current_room_id = DungeonStateStore.current_room_id
	DungeonStateMutations.clear_room_encounter(current_room_id)

	# Switch back to dungeon view
	_switch_to_dungeon_view()
