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
var shop_view: Control
var narrative_view: Control
var victory_screen: Control
var floor_complete_screen: Control
var dungeon_victory_screen: Control

func _ready():
	# Set anchors to fill the screen
	anchor_right = 1.0
	anchor_bottom = 1.0

	# Connect to engine signals
	DungeonEngine.encounter_triggered.connect(_on_encounter_triggered)
	DungeonEngine.floor_completed.connect(_on_floor_completed)
	DungeonEngine.dungeon_completed.connect(_on_dungeon_completed)
	CombatEngine.victory_achieved.connect(_on_victory_achieved)
	NarrativeEngine.combat_triggered_from_narrative.connect(_on_combat_triggered_from_narrative)

	# Start with title screen
	_show_title_screen()

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

func _show_title_screen():
	"""Display the title screen as the first view"""
	print("Main: Showing title screen")

	# Clear view stack
	for view in view_stack:
		remove_child(view)
		view.queue_free()
	view_stack.clear()

	# Create title screen
	var title_screen = Control.new()
	title_screen.set_script(preload("res://src/ui/TitleScreen.gd"))
	title_screen.anchor_right = 1.0
	title_screen.anchor_bottom = 1.0
	add_child(title_screen)

	# Connect to title screen signals
	title_screen.start_clicked.connect(_on_title_start_clicked)
	title_screen.dev_mode_clicked.connect(_on_title_dev_mode_clicked)

	view_stack.append(title_screen)
	current_view = title_screen

func _show_class_select_screen():
	"""Display the class selection screen"""
	print("Main: Showing class select screen")

	# Push class select screen onto stack
	var class_select_screen = Control.new()
	class_select_screen.set_script(preload("res://src/ui/ClassSelectScreen.gd"))
	add_child(class_select_screen)

	# Connect to class select signals
	class_select_screen.class_selected.connect(_on_class_selected)
	class_select_screen.back_clicked.connect(_on_class_select_back)

	# Hide current view
	if current_view:
		current_view.visible = false

	view_stack.append(class_select_screen)
	current_view = class_select_screen

func _on_title_start_clicked():
	"""Handle Start button click from title screen"""
	print("Main: Title screen Start clicked")
	_show_class_select_screen()

func _on_class_selected(class_id: String):
	"""Handle class selection and start the game"""
	print("Main: Class selected: %s" % class_id)

	# Initialize player with selected class
	CharacterClassEngine.initialize_player_class(class_id)

	# Start dungeon
	DungeonEngine.start_dungeon("foundry_dungeon")

	# Switch to dungeon view (clears stack)
	_switch_to_dungeon_view()

func _on_class_select_back():
	"""Handle back button from class select screen"""
	print("Main: Class select back clicked")
	pop_view()

func _on_title_dev_mode_clicked():
	"""Handle Dev Mode button click from title screen"""
	print("Main: Title screen Dev Mode clicked")
	_show_encounter_select_screen()

func _reset_player_state_for_dev_mode():
	"""Reset PlayerStore to a clean slate for dev mode configuration"""
	print("Main: Resetting player state for dev mode")

	# Clear all equipped attacks
	for attack_id in PlayerStore.equipped_attacks.duplicate():
		PlayerMutations.unequip_attack(attack_id)

	# Clear all passive abilities
	for passive_id in PlayerStore.passive_abilities.duplicate():
		PlayerMutations.remove_passive_ability(passive_id)

	# Clear all equipment
	InventoryMutations.clear_all_equipment()

	# Set base stats to a default for dev testing
	PlayerMutations.set_base_stats({
		"str": 10,
		"dex": 10,
		"int": 10,
		"con": 10,
		"spd": 10,
		"luck": 10
	})

	# Set HP to a reasonable amount (will be recalculated on combat start)
	PlayerMutations.set_current_hp(150)

	print("Main: Player state reset complete")

func _show_encounter_select_screen():
	"""Display the encounter selection screen (dev mode)"""
	print("Main: Showing encounter select screen")

	# Reset player state for dev mode testing
	_reset_player_state_for_dev_mode()

	# Push encounter select screen onto stack
	var encounter_select_screen = Control.new()
	encounter_select_screen.set_script(preload("res://src/ui/EncounterSelectScreen.gd"))
	add_child(encounter_select_screen)

	# Connect to encounter select signals
	encounter_select_screen.encounter_selected.connect(_on_dev_encounter_selected)
	encounter_select_screen.back_clicked.connect(_on_encounter_select_back)

	# Hide current view
	if current_view:
		current_view.visible = false

	view_stack.append(encounter_select_screen)
	current_view = encounter_select_screen

func _on_dev_encounter_selected(encounter_id: String):
	"""Handle encounter selection from dev mode"""
	print("Main: Dev mode encounter selected: %s" % encounter_id)

	# Player state is already configured by dev UI
	# Just switch to combat - sync_player_from_store will handle the rest
	_switch_to_combat_view(encounter_id)

func _on_encounter_select_back():
	"""Handle back button from encounter select screen"""
	print("Main: Encounter select back clicked")
	pop_view()

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
	dungeon_view.shop_button_pressed.connect(_on_shop_button_pressed)

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

func _switch_to_shop_view():
	print("Main: Switching to shop view")

	# Clear view stack
	for view in view_stack:
		remove_child(view)
		view.queue_free()
	view_stack.clear()

	# Generate shop inventory
	var shop_items = ShopEngine.generate_shop_inventory()

	# Create shop view (but don't add to tree yet)
	shop_view = Control.new()
	shop_view.set_script(preload("res://src/ui/ShopView.gd"))

	# Initialize shop BEFORE adding to tree
	# This ensures shop items are set before _ready() is called
	shop_view.initialize_shop(shop_items)

	# Now add to tree - this triggers _ready() and UI building
	shop_view.anchor_right = 1.0
	shop_view.anchor_bottom = 1.0
	add_child(shop_view)

	# Connect to shop view signals
	shop_view.back_button_pressed.connect(_on_shop_closed)

	view_stack.append(shop_view)
	current_view = shop_view

func _on_encounter_triggered(encounter_id: String):
	print("Main: Encounter triggered: %s" % encounter_id)

	# Get encounter data to check type
	var encounter = EncounterDatabase.get_encounter(encounter_id)
	if encounter == null:
		push_error("Main: Encounter '%s' not found" % encounter_id)
		return

	# Handle different encounter types
	if encounter.encounter_type == "shop":
		var current_room_id = DungeonStateStore.current_room_id

		# Auto-enter shop on first visit
		if not ShopEngine.has_visited_shop(current_room_id):
			print("Main: First visit to shop, auto-entering")
			ShopEngine.mark_shop_as_visited(current_room_id)
			_switch_to_shop_view()
		else:
			print("Main: Shop already visited, player must use Shop button")
			# Don't auto-enter, player must click Shop button
	elif encounter.encounter_type == "narrative":
		# Narrative encounter
		_switch_to_narrative_view(encounter.narrative_id)
	else:
		# Regular combat encounter (default)
		_switch_to_combat_view(encounter_id)

func _on_victory_achieved(total_xp: int, total_scrap: int, levels_gained: int):
	print("Main: Victory achieved - showing victory screen")

	# Create victory screen overlay
	victory_screen = Control.new()
	victory_screen.set_script(preload("res://src/ui/VictoryScreen.gd"))
	victory_screen.anchor_right = 1.0
	victory_screen.anchor_bottom = 1.0

	# Initialize with XP and scrap data BEFORE adding to tree
	victory_screen.initialize(total_xp, total_scrap, levels_gained)

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
	var current_room = DungeonStateStore.get_room(current_room_id)

	# Track room cleared if it had an encounter
	if current_room and current_room.encounter_id != "":
		DungeonStateMutations.increment_rooms_cleared()

	DungeonStateMutations.clear_room_encounter(current_room_id)

	# Check if the boss was just defeated
	if DungeonEngine.is_current_room_boss():
		DungeonEngine.notify_boss_defeated()
		return  # Don't switch back to dungeon view yet - boss_defeated signal will handle it

	# Switch back to dungeon view
	_switch_to_dungeon_view()

func _on_floor_completed(floor_number: int):
	print("Main: Floor %d completed - showing floor complete screen" % floor_number)

	# Get total floor count from dungeon data
	var dungeon_id = DungeonStateStore.current_dungeon_id
	var dungeon_data = DungeonDatabase.get_dungeon(dungeon_id)
	var total_floors = dungeon_data.get_floor_count() if dungeon_data else floor_number + 1

	# Create floor complete screen overlay with floor info
	var FloorCompleteScreenScript = preload("res://src/ui/FloorCompleteScreen.gd")
	floor_complete_screen = FloorCompleteScreenScript.new(floor_number, total_floors)
	floor_complete_screen.anchor_right = 1.0
	floor_complete_screen.anchor_bottom = 1.0

	# Add to tree (this triggers _ready())
	add_child(floor_complete_screen)

	# Connect to descend button
	floor_complete_screen.descend_pressed.connect(_on_floor_complete_descend_pressed)

func _on_floor_complete_descend_pressed():
	print("Main: Floor complete - descending to next floor")

	# Remove floor complete screen
	if floor_complete_screen:
		remove_child(floor_complete_screen)
		floor_complete_screen.queue_free()
		floor_complete_screen = null

	# Advance to next floor (DungeonEngine handles generation)
	DungeonEngine.advance_to_next_floor()

	# Switch back to dungeon view for exploration
	_switch_to_dungeon_view()

func _on_dungeon_completed():
	print("Main: Dungeon completed - showing final victory screen")

	# Create dungeon victory screen overlay
	dungeon_victory_screen = Control.new()
	dungeon_victory_screen.set_script(preload("res://src/ui/DungeonVictoryScreen.gd"))
	dungeon_victory_screen.anchor_right = 1.0
	dungeon_victory_screen.anchor_bottom = 1.0

	# Add to tree (this triggers _ready())
	add_child(dungeon_victory_screen)

	# Connect to victory screen buttons
	dungeon_victory_screen.main_menu_pressed.connect(_on_dungeon_victory_main_menu_pressed)
	dungeon_victory_screen.continue_exploring_pressed.connect(_on_dungeon_victory_continue_pressed)

func _on_dungeon_victory_main_menu_pressed():
	print("Main: Dungeon victory - returning to main menu (restarting dungeon)")

	# Remove dungeon victory screen
	if dungeon_victory_screen:
		remove_child(dungeon_victory_screen)
		dungeon_victory_screen.queue_free()
		dungeon_victory_screen = null

	# Restart dungeon (in a real game, this would go to main menu)
	DungeonEngine.start_dungeon("foundry_dungeon")
	_switch_to_dungeon_view()

func _on_dungeon_victory_continue_pressed():
	print("Main: Dungeon victory - continuing exploration")

	# Remove dungeon victory screen
	if dungeon_victory_screen:
		remove_child(dungeon_victory_screen)
		dungeon_victory_screen.queue_free()
		dungeon_victory_screen = null

	# Switch back to dungeon view to allow continued exploration
	_switch_to_dungeon_view()

func _on_inventory_opened():
	print("Main: Opening inventory view")
	push_view(preload("res://src/ui/InventoryView.gd"))

func _on_inventory_closed():
	print("Main: Closing inventory view")
	pop_view()

func _on_shop_button_pressed():
	print("Main: Shop button pressed - entering shop")
	_switch_to_shop_view()

func _on_shop_closed():
	print("Main: Shop closed - returning to dungeon")
	_switch_to_dungeon_view()

func _switch_to_narrative_view(narrative_id: String):
	"""Switch to narrative view with the specified narrative"""
	print("Main: Switching to narrative view: %s" % narrative_id)

	# Clear view stack
	for view in view_stack:
		remove_child(view)
		view.queue_free()
	view_stack.clear()

	# Create narrative view
	narrative_view = Control.new()
	narrative_view.set_script(preload("res://src/ui/NarrativeView.gd"))
	narrative_view.anchor_right = 1.0
	narrative_view.anchor_bottom = 1.0

	# Initialize with narrative data BEFORE adding to tree
	narrative_view.initialize_narrative(narrative_id)

	# Start the narrative in the engine
	NarrativeEngine.start_narrative(narrative_id)

	# Add to tree (this triggers _ready())
	add_child(narrative_view)

	# Connect to narrative view signals
	narrative_view.narrative_view_exited.connect(_on_narrative_closed)

	view_stack.append(narrative_view)
	current_view = narrative_view

func _on_narrative_closed():
	"""Handle narrative view closing - return to dungeon"""
	print("Main: Narrative closed - returning to dungeon")

	# Clear the encounter from the current room
	var current_room_id = DungeonStateStore.current_room_id
	DungeonStateMutations.clear_room_encounter(current_room_id)

	_switch_to_dungeon_view()

func _on_combat_triggered_from_narrative(encounter_id: String):
	"""Handle combat being triggered from a narrative choice"""
	print("Main: Combat triggered from narrative: %s" % encounter_id)

	# Switch from narrative view to combat view
	_switch_to_combat_view(encounter_id)
