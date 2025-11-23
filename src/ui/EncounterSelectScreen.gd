extends Control

## Encounter Select Screen - Dev tool for testing encounters
## Displays list of all available encounters with select buttons

signal encounter_selected(encounter_id: String)
signal back_clicked()

# List of all available encounters
const ENCOUNTERS = [
	{"id": "single_goblin", "name": "Single Goblin"},
	{"id": "slime_encounter", "name": "Slime Encounter"},
	{"id": "tank_and_archer", "name": "Tank and Archer"},
	{"id": "goblin_gang", "name": "Goblin Gang"},
	{"id": "spider_encounter", "name": "Spider Encounter"},
	{"id": "boss_encounter", "name": "Boss Encounter"},
	{"id": "foundry_1_rust_mite", "name": "Foundry 1: Rust Mite"},
	{"id": "foundry_2_slag_hauler", "name": "Foundry 2: Slag Hauler"},
	{"id": "foundry_3_sentry_pair", "name": "Foundry 3: Sentry Pair"},
	{"id": "foundry_4_molten_guard", "name": "Foundry 4: Molten Guard"},
	{"id": "foundry_5_hauler_support", "name": "Foundry 5: Hauler Support"},
	{"id": "foundry_6_sentry_squad", "name": "Foundry 6: Sentry Squad"},
	{"id": "foundry_7_weaver_core", "name": "Foundry 7: Weaver Core"},
	{"id": "foundry_8_forge_warden", "name": "Foundry 8: Forge Warden"},
	{"id": "foundry_9_foundry_heart", "name": "Foundry 9: Foundry Heart (BOSS)"}
]

func _ready():
	# Set up full screen coverage
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Create main container
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 50)
	margin.add_theme_constant_override("margin_right", 50)
	margin.add_theme_constant_override("margin_top", 50)
	margin.add_theme_constant_override("margin_bottom", 50)
	add_child(margin)

	# Create vertical layout
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)

	# Title label
	var title = Label.new()
	title.text = "Select Encounter"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	vbox.add_child(title)

	# Add spacing
	vbox.add_child(_create_spacer(20))

	# Create button for each encounter
	for encounter in ENCOUNTERS:
		var encounter_button = _create_encounter_button(encounter.id, encounter.name)
		vbox.add_child(encounter_button)

	# Add spacing
	vbox.add_child(_create_spacer(20))

	# Back button
	var back_button = Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(200, 50)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.pressed.connect(_on_back_pressed)
	vbox.add_child(back_button)

func _create_encounter_button(encounter_id: String, encounter_name: String) -> Button:
	"""Create a button for selecting an encounter"""
	var button = Button.new()
	button.text = encounter_name
	button.custom_minimum_size = Vector2(400, 50)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(_on_encounter_button_pressed.bind(encounter_id))
	return button

func _create_spacer(height: int) -> Control:
	"""Create a fixed-height spacer"""
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	return spacer

func _on_encounter_button_pressed(encounter_id: String):
	"""Handle encounter selection"""
	print("EncounterSelectScreen: Selected encounter: %s" % encounter_id)
	encounter_selected.emit(encounter_id)

func _on_back_pressed():
	"""Handle back button press"""
	print("EncounterSelectScreen: Back button pressed")
	back_clicked.emit()
