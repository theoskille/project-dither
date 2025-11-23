extends Control

## Encounter Select Screen with Player Configuration - Dev Mode
## Left panel: Configure player skills, passives, and equipment
## Right panel: Select encounter to test

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
	{"id": "foundry_9_foundry_heart", "name": "Foundry 9: Foundry Heart (BOSS)"},
	{"id": "narrative_shrine", "name": "NARRATIVE: Mysterious Shrine"},
	{"id": "narrative_merchant", "name": "NARRATIVE: Strange Merchant"}
]

# UI references for player config
var skill_checkboxes: Dictionary = {}  # attack_id -> CheckBox
var passive_checkboxes: Dictionary = {}  # passive_id -> CheckBox
var weapon_option: OptionButton
var armor_option: OptionButton
var accessory_checkboxes: Array[CheckBox] = []  # 3 checkboxes for accessories

# Currently selected encounter
var selected_encounter_id: String = ""

func _ready():
	# Set up full screen coverage
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Create main container
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)

	# Create vertical layout for the whole screen
	var main_vbox = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 20)
	margin.add_child(main_vbox)

	# Title label
	var title = Label.new()
	title.text = "Dev Mode - Configure Player & Select Encounter"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	main_vbox.add_child(title)

	# Create horizontal split for config and encounters
	var hsplit = HSplitContainer.new()
	hsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hsplit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hsplit.custom_minimum_size = Vector2(0, 500)  # Minimum height
	main_vbox.add_child(hsplit)

	# Left panel: Player Configuration
	var config_panel = _create_player_config_panel()
	hsplit.add_child(config_panel)

	# Right panel: Encounter Selection
	var encounter_panel = _create_encounter_panel()
	hsplit.add_child(encounter_panel)

	# Bottom buttons
	var button_hbox = HBoxContainer.new()
	button_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	button_hbox.add_theme_constant_override("separation", 20)
	main_vbox.add_child(button_hbox)

	# Back button
	var back_button = Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(150, 50)
	back_button.pressed.connect(_on_back_pressed)
	button_hbox.add_child(back_button)

	# Start Battle button
	var start_button = Button.new()
	start_button.text = "Start Battle"
	start_button.custom_minimum_size = Vector2(200, 50)
	start_button.pressed.connect(_on_start_battle_pressed)
	button_hbox.add_child(start_button)

func _create_player_config_panel() -> Control:
	"""Create the left panel for player configuration"""
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	panel.add_child(margin)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	margin.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 15)
	scroll.add_child(vbox)

	# Panel title
	var panel_title = Label.new()
	panel_title.text = "Player Configuration"
	panel_title.add_theme_font_size_override("font_size", 24)
	panel_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(panel_title)

	vbox.add_child(_create_separator())

	# Skills section
	vbox.add_child(_create_skills_section())

	vbox.add_child(_create_separator())

	# Passives section
	vbox.add_child(_create_passives_section())

	vbox.add_child(_create_separator())

	# Equipment section
	vbox.add_child(_create_equipment_section())

	return panel

func _create_skills_section() -> Control:
	"""Create the skills configuration section"""
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)

	var header = Label.new()
	header.text = "Skills (Select up to 4 attacks)"
	header.add_theme_font_size_override("font_size", 18)
	vbox.add_child(header)

	# Get all available attacks
	var attack_ids = AttackDatabase.get_all_action_ids()
	attack_ids.sort()

	for attack_id in attack_ids:
		var attack_data = AttackDatabase.get_action(attack_id)
		if attack_data == null:
			continue

		var checkbox = CheckBox.new()
		checkbox.text = "%s (%s)" % [attack_data.action_name, attack_id]
		checkbox.toggled.connect(_on_skill_checkbox_toggled.bind(attack_id))
		vbox.add_child(checkbox)

		skill_checkboxes[attack_id] = checkbox

	return vbox

func _create_passives_section() -> Control:
	"""Create the passives configuration section"""
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)

	var header = Label.new()
	header.text = "Passive Abilities"
	header.add_theme_font_size_override("font_size", 18)
	vbox.add_child(header)

	# Get all available passives
	var passives_dict = PassiveAbilityDatabase.get_all_passives()
	var passive_ids = passives_dict.keys()
	passive_ids.sort()

	for passive_id in passive_ids:
		var passive_data = passives_dict[passive_id]
		if passive_data == null:
			continue

		var checkbox = CheckBox.new()
		checkbox.text = "%s (%s)" % [passive_data.passive_name, passive_id]
		checkbox.toggled.connect(_on_passive_checkbox_toggled.bind(passive_id))
		vbox.add_child(checkbox)

		passive_checkboxes[passive_id] = checkbox

	return vbox

func _create_equipment_section() -> Control:
	"""Create the equipment configuration section"""
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)

	var header = Label.new()
	header.text = "Equipment"
	header.add_theme_font_size_override("font_size", 18)
	vbox.add_child(header)

	# Get all available items
	var item_ids = ItemDatabase.get_all_item_ids()
	item_ids.sort()

	# Weapon dropdown
	var weapon_label = Label.new()
	weapon_label.text = "Weapon:"
	vbox.add_child(weapon_label)

	weapon_option = OptionButton.new()
	weapon_option.add_item("(None)", 0)
	var weapon_idx = 1
	for item_id in item_ids:
		var item_data = ItemDatabase.get_item(item_id)
		if item_data != null and item_data.item_type == ItemData.ItemType.WEAPON:
			weapon_option.add_item("%s (%s)" % [item_data.item_name, item_id], weapon_idx)
			weapon_option.set_item_metadata(weapon_idx, item_id)
			weapon_idx += 1
	weapon_option.item_selected.connect(_on_weapon_selected)
	vbox.add_child(weapon_option)

	# Armor dropdown
	var armor_label = Label.new()
	armor_label.text = "Armor:"
	vbox.add_child(armor_label)

	armor_option = OptionButton.new()
	armor_option.add_item("(None)", 0)
	var armor_idx = 1
	for item_id in item_ids:
		var item_data = ItemDatabase.get_item(item_id)
		if item_data != null and item_data.item_type == ItemData.ItemType.ARMOR:
			armor_option.add_item("%s (%s)" % [item_data.item_name, item_id], armor_idx)
			armor_option.set_item_metadata(armor_idx, item_id)
			armor_idx += 1
	armor_option.item_selected.connect(_on_armor_selected)
	vbox.add_child(armor_option)

	# Accessories checkboxes (max 3)
	var accessories_label = Label.new()
	accessories_label.text = "Accessories (Select up to 3):"
	vbox.add_child(accessories_label)

	for item_id in item_ids:
		var item_data = ItemDatabase.get_item(item_id)
		if item_data != null and item_data.item_type == ItemData.ItemType.ACCESSORY:
			var checkbox = CheckBox.new()
			checkbox.text = "%s (%s)" % [item_data.item_name, item_id]
			checkbox.toggled.connect(_on_accessory_checkbox_toggled.bind(item_id))
			vbox.add_child(checkbox)
			accessory_checkboxes.append(checkbox)

	return vbox

func _create_encounter_panel() -> Control:
	"""Create the right panel for encounter selection"""
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	panel.add_child(margin)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	margin.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)

	# Panel title
	var panel_title = Label.new()
	panel_title.text = "Select Encounter"
	panel_title.add_theme_font_size_override("font_size", 24)
	panel_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(panel_title)

	vbox.add_child(_create_separator())

	# Create button for each encounter
	for encounter in ENCOUNTERS:
		var encounter_button = _create_encounter_button(encounter.id, encounter.name)
		vbox.add_child(encounter_button)

	return panel

func _create_encounter_button(encounter_id: String, encounter_name: String) -> Button:
	"""Create a button for selecting an encounter"""
	var button = Button.new()
	button.text = encounter_name
	button.custom_minimum_size = Vector2(0, 40)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(_on_encounter_button_pressed.bind(encounter_id))
	return button

func _create_separator() -> Control:
	"""Create a visual separator line"""
	var separator = HSeparator.new()
	return separator

# === Event Handlers ===

func _on_skill_checkbox_toggled(checked: bool, attack_id: String):
	"""Handle skill checkbox toggle - enforce max 4 limit"""
	if checked:
		# Count currently selected skills
		var selected_count = 0
		for checkbox in skill_checkboxes.values():
			if checkbox.button_pressed:
				selected_count += 1

		# Enforce max 4 limit
		if selected_count > 4:
			skill_checkboxes[attack_id].button_pressed = false
			print("EncounterSelectScreen: Cannot select more than 4 skills")
			return

		# Add attack to PlayerStore
		PlayerMutations.equip_attack(attack_id)
	else:
		# Remove attack from PlayerStore
		PlayerMutations.unequip_attack(attack_id)

func _on_passive_checkbox_toggled(checked: bool, passive_id: String):
	"""Handle passive checkbox toggle"""
	if checked:
		PlayerMutations.add_passive_ability(passive_id)
	else:
		PlayerMutations.remove_passive_ability(passive_id)

func _on_weapon_selected(index: int):
	"""Handle weapon selection"""
	if index == 0:
		# (None) selected - unequip
		InventoryMutations.unequip_weapon()
	else:
		var item_id = weapon_option.get_item_metadata(index)
		InventoryMutations.equip_weapon(item_id)

func _on_armor_selected(index: int):
	"""Handle armor selection"""
	if index == 0:
		# (None) selected - unequip
		InventoryMutations.unequip_armor()
	else:
		var item_id = armor_option.get_item_metadata(index)
		InventoryMutations.equip_armor(item_id)

func _on_accessory_checkbox_toggled(checked: bool, item_id: String):
	"""Handle accessory checkbox toggle - enforce max 3 limit"""
	if checked:
		# Count currently selected accessories
		var selected_count = 0
		for checkbox in accessory_checkboxes:
			if checkbox.button_pressed:
				selected_count += 1

		# Enforce max 3 limit
		if selected_count > 3:
			# Find and uncheck the checkbox for this item
			for checkbox in accessory_checkboxes:
				if item_id in checkbox.text:
					checkbox.button_pressed = false
			print("EncounterSelectScreen: Cannot select more than 3 accessories")
			return

		# Find first empty accessory slot and equip
		for slot_idx in range(3):
			var is_empty: bool = false
			if PlayerStore.equipped_accessories.size() <= slot_idx:
				is_empty = true
			else:
				var slot_value = PlayerStore.equipped_accessories[slot_idx]
				is_empty = (slot_value == "")
			if is_empty:
				InventoryMutations.equip_accessory(item_id, slot_idx)
				break
	else:
		# Find and unequip from the slot
		for slot_idx in range(PlayerStore.equipped_accessories.size()):
			if PlayerStore.equipped_accessories[slot_idx] == item_id:
				InventoryMutations.unequip_accessory(slot_idx)
				break

func _on_encounter_button_pressed(encounter_id: String):
	"""Handle encounter selection - just highlight it"""
	selected_encounter_id = encounter_id
	print("EncounterSelectScreen: Selected encounter: %s" % encounter_id)

func _on_start_battle_pressed():
	"""Handle start battle button - apply config and start encounter"""
	if selected_encounter_id == "":
		print("EncounterSelectScreen: No encounter selected!")
		return

	print("EncounterSelectScreen: Starting battle with encounter: %s" % selected_encounter_id)
	encounter_selected.emit(selected_encounter_id)

func _on_back_pressed():
	"""Handle back button press"""
	print("EncounterSelectScreen: Back button pressed")
	back_clicked.emit()
