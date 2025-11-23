extends Control

## Inventory view UI
## Shows player base stats, equipped attacks, passive abilities, and skill tree
## Reactive component that listens to PlayerStore signals

signal back_button_pressed()

enum Tab { STATS, ATTACKS, PASSIVES, SKILLS, ITEMS }
var current_tab: Tab = Tab.STATS

# Attack detail panel references
var selected_attack_id: String = ""
var attack_detail_info_vbox: VBoxContainer = null
var attack_detail_button_container: CenterContainer = null

# Item detail panel references
var selected_item_id: String = ""
var item_detail_info_vbox: VBoxContainer = null
var item_detail_button_container: CenterContainer = null

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
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	# Main vertical layout
	var main_vbox = VBoxContainer.new()
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 15)
	margin.add_child(main_vbox)

	# Title with skill points
	var title_hbox = HBoxContainer.new()
	title_hbox.custom_minimum_size = Vector2(0, 48)
	main_vbox.add_child(title_hbox)

	var title = Label.new()
	title.text = "INVENTORY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_hbox.add_child(title)

	var skill_points_label = Label.new()
	skill_points_label.text = "Skill Points: %d" % PlayerStore.skill_points
	skill_points_label.add_theme_font_size_override("font_size", 18)
	skill_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title_hbox.add_child(skill_points_label)

	# Tab buttons
	var tab_hbox = HBoxContainer.new()
	tab_hbox.add_theme_constant_override("separation", 10)
	main_vbox.add_child(tab_hbox)

	var stats_button = Button.new()
	stats_button.text = "Stats"
	stats_button.toggle_mode = true
	stats_button.button_pressed = (current_tab == Tab.STATS)
	stats_button.pressed.connect(func(): _switch_tab(Tab.STATS))
	tab_hbox.add_child(stats_button)

	var attacks_button = Button.new()
	attacks_button.text = "Attacks"
	attacks_button.toggle_mode = true
	attacks_button.button_pressed = (current_tab == Tab.ATTACKS)
	attacks_button.pressed.connect(func(): _switch_tab(Tab.ATTACKS))
	tab_hbox.add_child(attacks_button)

	var passives_button = Button.new()
	passives_button.text = "Passives"
	passives_button.toggle_mode = true
	passives_button.button_pressed = (current_tab == Tab.PASSIVES)
	passives_button.pressed.connect(func(): _switch_tab(Tab.PASSIVES))
	tab_hbox.add_child(passives_button)

	var skills_button = Button.new()
	skills_button.text = "Skill Tree"
	skills_button.toggle_mode = true
	skills_button.button_pressed = (current_tab == Tab.SKILLS)
	skills_button.pressed.connect(func(): _switch_tab(Tab.SKILLS))
	tab_hbox.add_child(skills_button)

	var items_button = Button.new()
	items_button.text = "Items"
	items_button.toggle_mode = true
	items_button.button_pressed = (current_tab == Tab.ITEMS)
	items_button.pressed.connect(func(): _switch_tab(Tab.ITEMS))
	tab_hbox.add_child(items_button)

	# Content area (scrollable)
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll)

	var content_vbox = VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 20)
	scroll.add_child(content_vbox)

	# Render content based on current tab
	match current_tab:
		Tab.STATS:
			_build_stats_panel(content_vbox)
		Tab.ATTACKS:
			_build_attacks_panel(content_vbox)
		Tab.PASSIVES:
			_build_passives_panel(content_vbox)
		Tab.SKILLS:
			_build_skills_panel(scroll)
		Tab.ITEMS:
			_build_items_panel(content_vbox)

	# === BACK BUTTON ===
	var back_button = Button.new()
	back_button.text = "Back to Dungeon"
	back_button.custom_minimum_size = Vector2(200, 50)
	back_button.pressed.connect(_on_back_button_pressed)
	main_vbox.add_child(back_button)

	# Center the back button
	var back_container = CenterContainer.new()
	back_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(back_container)
	main_vbox.remove_child(back_button)
	back_container.add_child(back_button)

func _switch_tab(tab: Tab):
	"""Switch to a different tab"""
	current_tab = tab
	for child in get_children():
		child.queue_free()
	_build_ui()

func _build_stats_panel(parent: VBoxContainer):
	"""Build the character stats panel with equipment bonuses"""
	var stats_panel = PanelContainer.new()
	stats_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(stats_panel)

	var stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 10)
	stats_panel.add_child(stats_vbox)

	var stats_header = Label.new()
	stats_header.text = "Character Stats"
	stats_header.add_theme_font_size_override("font_size", 18)
	stats_vbox.add_child(stats_header)

	# Get both base stats and total stats (with equipment)
	var base_stats = PlayerStore.base_stats
	var total_stats = ItemEngine.calculate_total_stats()

	# Display each stat showing: base → total (if different)
	for stat_name in ["str", "dex", "int", "con", "spd", "luck"]:
		var stat_label = Label.new()
		var display_name = stat_name.to_upper()
		var base_value = base_stats.get(stat_name, 0)
		var total_value = total_stats.get(stat_name, base_value)

		# Show "STR: 10 → 15" if equipment provides bonuses
		if total_value != base_value:
			stat_label.text = "%s: %d → %d" % [display_name, base_value, total_value]
			stat_label.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))  # Green for boosted
		else:
			stat_label.text = "%s: %d" % [display_name, base_value]

		stats_vbox.add_child(stat_label)

	# Add HP and Vigor display
	var base_max_hp = 100 + (base_stats.get("con", 10) * 5)
	var total_max_hp = total_stats.get("max_hp", base_max_hp)

	var base_max_vigor = PlayerStore.get_max_vigor_for_level()
	var total_max_vigor = total_stats.get("max_vigor", base_max_vigor)

	# Spacer before HP/Vigor
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	stats_vbox.add_child(spacer)

	# Max HP
	var hp_label = Label.new()
	if total_max_hp != base_max_hp:
		hp_label.text = "MAX HP: %d → %d" % [base_max_hp, total_max_hp]
		hp_label.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
	else:
		hp_label.text = "MAX HP: %d" % base_max_hp
	stats_vbox.add_child(hp_label)

	# Max Vigor
	var vigor_label = Label.new()
	if total_max_vigor != base_max_vigor:
		vigor_label.text = "MAX VIGOR: %d → %d" % [base_max_vigor, total_max_vigor]
		vigor_label.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
	else:
		vigor_label.text = "MAX VIGOR: %d" % base_max_vigor
	stats_vbox.add_child(vigor_label)

	# Dodge Chance (calculated from dex and spd with equipment bonuses)
	var base_dex = base_stats.get("dex", 0)
	var base_spd = base_stats.get("spd", 0)
	var total_dex = total_stats.get("dex", base_dex)
	var total_spd = total_stats.get("spd", base_spd)

	var base_dodge = (base_dex * 0.6) + (base_spd * 0.4)
	var total_dodge = (total_dex * 0.6) + (total_spd * 0.4)

	var dodge_label = Label.new()
	if abs(total_dodge - base_dodge) > 0.01:  # Account for floating point comparison
		dodge_label.text = "DODGE: %.1f%% → %.1f%%" % [base_dodge, total_dodge]
		dodge_label.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
	else:
		dodge_label.text = "DODGE: %.1f%%" % base_dodge
	stats_vbox.add_child(dodge_label)

func _build_attacks_panel(parent: VBoxContainer):
	"""Build the attacks panel with three columns: equipped, unlocked, detail"""
	# Main horizontal container (left: equipped, middle: unlocked, right: detail)
	var main_hbox = HBoxContainer.new()
	main_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_hbox.add_theme_constant_override("separation", 15)
	parent.add_child(main_hbox)

	var equipped_attacks = PlayerStore.equipped_attacks
	var unlocked_attack_ids = _get_unlocked_attack_ids()

	# Left panel: Equipped attacks
	var equipped_panel = _build_equipped_panel(equipped_attacks)
	equipped_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(equipped_panel)

	# Middle panel: Unlocked attacks
	var unlocked_panel = _build_unlocked_panel(equipped_attacks, unlocked_attack_ids)
	unlocked_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(unlocked_panel)

	# Right panel: Attack detail panel
	var detail_panel = _build_attack_detail_panel()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(detail_panel)

	# Initialize detail panel
	_update_attack_detail_panel()

func _build_equipped_panel(equipped_attacks: Array[String]) -> PanelContainer:
	"""Build the equipped attacks panel"""
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# Header
	var header = Label.new()
	header.text = "EQUIPPED (%d/4)" % equipped_attacks.size()
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)

	var separator = HSeparator.new()
	vbox.add_child(separator)

	# Scrollable list
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var list_vbox = VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 5)
	scroll.add_child(list_vbox)

	if equipped_attacks.size() > 0:
		for attack_id in equipped_attacks:
			var button = _create_attack_button(attack_id, true)
			list_vbox.add_child(button)
	else:
		var empty_label = Label.new()
		empty_label.text = "No attacks equipped"
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		list_vbox.add_child(empty_label)

	return panel

func _build_unlocked_panel(equipped_attacks: Array[String], unlocked_attack_ids: Array[String]) -> PanelContainer:
	"""Build the unlocked attacks panel"""
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# Header
	var header = Label.new()
	header.text = "UNLOCKED"
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)

	var separator = HSeparator.new()
	vbox.add_child(separator)

	# Scrollable list
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var list_vbox = VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 5)
	scroll.add_child(list_vbox)

	# Get unequipped attacks
	var unequipped_attacks = []
	for attack_id in unlocked_attack_ids:
		if not attack_id in equipped_attacks:
			unequipped_attacks.append(attack_id)

	if unequipped_attacks.size() > 0:
		for attack_id in unequipped_attacks:
			var button = _create_attack_button(attack_id, false)
			list_vbox.add_child(button)
	else:
		var empty_label = Label.new()
		if unlocked_attack_ids.size() == 0:
			empty_label.text = "No attacks unlocked.\nUnlock via Skill Tree."
		else:
			empty_label.text = "All attacks equipped!"
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		list_vbox.add_child(empty_label)

	return panel

func _create_attack_button(attack_id: String, is_equipped: bool) -> Button:
	"""Create a button for an attack in the list"""
	var button = Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.clip_text = false
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size = Vector2(0, 40)

	var action_data = AttackDatabase.get_action(attack_id)
	var display_name = action_data.action_name if action_data else attack_id.replace("_", " ").capitalize()

	if is_equipped:
		button.text = "✓ %s" % display_name
	else:
		button.text = "  %s" % display_name

	# Highlight if selected
	if attack_id == selected_attack_id:
		button.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0))

	button.pressed.connect(func(): _on_attack_selected(attack_id))
	return button

func _build_attack_detail_panel() -> PanelContainer:
	"""Build the attack detail panel (right side)"""
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

	# Title
	var title = Label.new()
	title.name = "TitleLabel"
	title.text = "Attack Details"
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)

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

	attack_detail_info_vbox = info_vbox

	# Button container
	var button_container = CenterContainer.new()
	button_container.name = "ButtonContainer"
	vbox.add_child(button_container)

	attack_detail_button_container = button_container

	return panel

func _on_attack_selected(attack_id: String):
	"""Handle attack selection"""
	selected_attack_id = attack_id
	_update_attack_detail_panel()
	_switch_tab(Tab.ATTACKS)  # Refresh to show selection highlight

func _update_attack_detail_panel():
	"""Update the attack detail panel with selected attack info"""
	if not attack_detail_info_vbox or not attack_detail_button_container:
		return

	# Clear existing content
	for child in attack_detail_info_vbox.get_children():
		child.queue_free()

	for child in attack_detail_button_container.get_children():
		child.queue_free()

	if selected_attack_id == "":
		var label = Label.new()
		label.text = "Select an attack to view details"
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		attack_detail_info_vbox.add_child(label)
		return

	var action_data = AttackDatabase.get_action(selected_attack_id)
	if not action_data:
		return

	var is_equipped = selected_attack_id in PlayerStore.equipped_attacks

	# Attack name
	var name_label = Label.new()
	name_label.text = action_data.action_name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.8))
	attack_detail_info_vbox.add_child(name_label)

	# Stats section
	var stats_spacer = Control.new()
	stats_spacer.custom_minimum_size = Vector2(0, 10)
	attack_detail_info_vbox.add_child(stats_spacer)

	var stats_label = Label.new()
	stats_label.text = "STATS:"
	stats_label.add_theme_font_size_override("font_size", 14)
	attack_detail_info_vbox.add_child(stats_label)

	# Damage
	if action_data.base_damage > 0:
		var dmg_label = Label.new()
		dmg_label.text = "Base Damage: %d" % action_data.base_damage
		attack_detail_info_vbox.add_child(dmg_label)

	# Vigor cost
	var vigor_label = Label.new()
	vigor_label.text = "Vigor Cost: %d" % action_data.vigor_cost
	attack_detail_info_vbox.add_child(vigor_label)

	# Range
	var range_label = Label.new()
	range_label.text = "Range: %d-%d" % [action_data.min_range, action_data.max_range]
	attack_detail_info_vbox.add_child(range_label)

	# Stat modifiers
	if action_data.str_modifier > 0:
		var str_label = Label.new()
		str_label.text = "STR Modifier: %.1fx" % action_data.str_modifier
		attack_detail_info_vbox.add_child(str_label)

	if action_data.dex_modifier > 0:
		var dex_label = Label.new()
		dex_label.text = "DEX Modifier: %.1fx" % action_data.dex_modifier
		attack_detail_info_vbox.add_child(dex_label)

	if action_data.int_modifier > 0:
		var int_label = Label.new()
		int_label.text = "INT Modifier: %.1fx" % action_data.int_modifier
		attack_detail_info_vbox.add_child(int_label)

	# Status
	var status_spacer = Control.new()
	status_spacer.custom_minimum_size = Vector2(0, 15)
	attack_detail_info_vbox.add_child(status_spacer)

	var status_label = Label.new()
	if is_equipped:
		status_label.text = "✓ EQUIPPED"
		status_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		status_label.text = "NOT EQUIPPED"
		status_label.add_theme_color_override("font_color", Color.YELLOW)
	status_label.add_theme_font_size_override("font_size", 16)
	attack_detail_info_vbox.add_child(status_label)

	# Equip/Unequip button
	var button = Button.new()
	button.custom_minimum_size = Vector2(200, 50)
	button.add_theme_font_size_override("font_size", 16)

	if is_equipped:
		button.text = "UNEQUIP"
		button.pressed.connect(func(): _on_unequip_pressed(selected_attack_id))
	else:
		if PlayerStore.equipped_attacks.size() >= 4:
			button.text = "Max 4 Equipped"
			button.disabled = true
		else:
			button.text = "EQUIP"
			button.pressed.connect(func(): _on_equip_pressed(selected_attack_id))

	attack_detail_button_container.add_child(button)

func _on_equip_pressed(attack_id: String):
	"""Handle equip button press"""
	PlayerMutations.equip_attack(attack_id)
	_update_attack_detail_panel()

func _on_unequip_pressed(attack_id: String):
	"""Handle unequip button press"""
	PlayerMutations.unequip_attack(attack_id)
	_update_attack_detail_panel()

func _get_unlocked_attack_ids() -> Array[String]:
	"""Get all attack IDs from unlocked skills"""
	var attack_ids: Array[String] = []

	for skill_id in PlayerStore.unlocked_skills:
		var skill_node = SkillTreeEngine.get_skill_node(skill_id)
		if skill_node and skill_node.skill_type == "attack":
			if skill_node.grants_attack_id != "":
				attack_ids.append(skill_node.grants_attack_id)

	return attack_ids

func _build_passives_panel(parent: VBoxContainer):
	"""Build the passive abilities panel"""
	var abilities_panel = PanelContainer.new()
	abilities_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(abilities_panel)

	var abilities_vbox = VBoxContainer.new()
	abilities_vbox.add_theme_constant_override("separation", 10)
	abilities_panel.add_child(abilities_vbox)

	var abilities_header = Label.new()
	abilities_header.text = "Passive Abilities"
	abilities_header.add_theme_font_size_override("font_size", 18)
	abilities_vbox.add_child(abilities_header)

	var passive_abilities = PlayerStore.passive_abilities
	if passive_abilities.size() > 0:
		for ability_id in passive_abilities:
			var ability_label = Label.new()
			# Format ability name: "bloodthirst" -> "Bloodthirst"
			var display_name = ability_id.replace("_", " ").capitalize()
			ability_label.text = "• %s" % display_name
			abilities_vbox.add_child(ability_label)
	else:
		var no_abilities_label = Label.new()
		no_abilities_label.text = "No passive abilities"
		no_abilities_label.modulate = Color(0.7, 0.7, 0.7)
		abilities_vbox.add_child(no_abilities_label)

func _build_skills_panel(parent: ScrollContainer):
	"""Build the skill tree panel"""
	# Load the SkillTreeView script
	var skill_tree_script = load("res://src/ui/SkillTreeView.gd")
	var skill_tree_view = skill_tree_script.new()
	skill_tree_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill_tree_view.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Remove the scroll container's existing child and add skill tree directly
	parent.get_child(0).queue_free()
	parent.add_child(skill_tree_view)

func _connect_signals():
	PlayerStore.state_changed.connect(_on_player_state_changed)

func _on_player_state_changed(_property_path: String, _old_value, _new_value):
	# Rebuild UI when player data changes
	# For now, we just rebuild the entire UI
	# In the future, could optimize to only update changed elements
	for child in get_children():
		child.queue_free()
	_build_ui()

func _build_items_panel(parent: VBoxContainer):
	"""Build the items panel with equipment slots and inventory"""
	# Main horizontal container (left: equipment, middle: inventory, right: detail)
	var main_hbox = HBoxContainer.new()
	main_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_hbox.add_theme_constant_override("separation", 15)
	parent.add_child(main_hbox)

	# Left panel: Equipment slots
	var equipment_panel = _build_equipment_panel()
	equipment_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(equipment_panel)

	# Middle panel: Inventory
	var inventory_panel = _build_inventory_panel()
	inventory_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(inventory_panel)

	# Right panel: Item detail panel
	var detail_panel = _build_item_detail_panel()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(detail_panel)

	# Initialize detail panel
	_update_item_detail_panel()

func _build_equipment_panel() -> PanelContainer:
	"""Build the equipment slots panel"""
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# Header
	var header = Label.new()
	header.text = "EQUIPMENT"
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)

	var separator = HSeparator.new()
	vbox.add_child(separator)

	# Equipment slots
	_add_equipment_slot(vbox, "WEAPON", PlayerStore.equipped_weapon, "weapon")
	_add_equipment_slot(vbox, "ARMOR", PlayerStore.equipped_armor, "armor")

	# Ensure accessories array has 3 slots
	while PlayerStore.equipped_accessories.size() < 3:
		PlayerStore.equipped_accessories.append("")

	_add_equipment_slot(vbox, "ACCESSORY 1", PlayerStore.equipped_accessories[0] if PlayerStore.equipped_accessories.size() > 0 else "", "accessory_0")
	_add_equipment_slot(vbox, "ACCESSORY 2", PlayerStore.equipped_accessories[1] if PlayerStore.equipped_accessories.size() > 1 else "", "accessory_1")
	_add_equipment_slot(vbox, "ACCESSORY 3", PlayerStore.equipped_accessories[2] if PlayerStore.equipped_accessories.size() > 2 else "", "accessory_2")

	return panel

func _add_equipment_slot(parent: VBoxContainer, slot_label: String, item_id: String, slot_id: String):
	"""Add an equipment slot with label and item button"""
	var slot_vbox = VBoxContainer.new()
	slot_vbox.add_theme_constant_override("separation", 3)
	parent.add_child(slot_vbox)

	# Slot label
	var label = Label.new()
	label.text = slot_label
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	slot_vbox.add_child(label)

	# Item button or empty slot
	var button = Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 40)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT

	if item_id != "" and ItemDatabase.has_item(item_id):
		var item = ItemDatabase.get_item(item_id)
		button.text = "✓ %s" % item.item_name
		button.pressed.connect(func(): _on_equipped_item_selected(item_id, slot_id))
	else:
		button.text = "[Empty]"
		button.disabled = true
		button.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

	slot_vbox.add_child(button)

func _build_inventory_panel() -> PanelContainer:
	"""Build the inventory items panel"""
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# Header
	var header = Label.new()
	header.text = "INVENTORY (%d items)" % PlayerStore.inventory.size()
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)

	var separator = HSeparator.new()
	vbox.add_child(separator)

	# Scrollable list
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var list_vbox = VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 5)
	scroll.add_child(list_vbox)

	if PlayerStore.inventory.size() > 0:
		for item_id in PlayerStore.inventory:
			if ItemDatabase.has_item(item_id):
				var button = _create_item_button(item_id)
				list_vbox.add_child(button)
	else:
		var empty_label = Label.new()
		empty_label.text = "No items in inventory"
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		list_vbox.add_child(empty_label)

	return panel

func _create_item_button(item_id: String) -> Button:
	"""Create a button for an item in inventory"""
	var button = Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.clip_text = false
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size = Vector2(0, 40)

	var item = ItemDatabase.get_item(item_id)
	if item:
		button.text = "  %s" % item.item_name

		# Highlight if selected
		if item_id == selected_item_id:
			button.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0))

	button.pressed.connect(func(): _on_item_selected(item_id))
	return button

func _build_item_detail_panel() -> PanelContainer:
	"""Build the item detail panel (right side)"""
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

	# Title
	var title = Label.new()
	title.name = "TitleLabel"
	title.text = "Item Details"
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)

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

	item_detail_info_vbox = info_vbox

	# Button container
	var button_container = CenterContainer.new()
	button_container.name = "ButtonContainer"
	vbox.add_child(button_container)

	item_detail_button_container = button_container

	return panel

func _on_item_selected(item_id: String):
	"""Handle item selection from inventory"""
	selected_item_id = item_id
	_update_item_detail_panel()
	_switch_tab(Tab.ITEMS)  # Refresh to show selection highlight

func _on_equipped_item_selected(item_id: String, slot_id: String):
	"""Handle equipped item selection"""
	selected_item_id = item_id
	_update_item_detail_panel()
	_switch_tab(Tab.ITEMS)  # Refresh to show selection highlight

func _update_item_detail_panel():
	"""Update the item detail panel with selected item info"""
	if not item_detail_info_vbox or not item_detail_button_container:
		return

	# Clear existing content
	for child in item_detail_info_vbox.get_children():
		child.queue_free()

	for child in item_detail_button_container.get_children():
		child.queue_free()

	if selected_item_id == "":
		var label = Label.new()
		label.text = "Select an item to view details"
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		item_detail_info_vbox.add_child(label)
		return

	var item = ItemDatabase.get_item(selected_item_id)
	if not item:
		return

	# Item name
	var name_label = Label.new()
	name_label.text = item.item_name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.8))
	item_detail_info_vbox.add_child(name_label)

	# Item type and rarity
	var type_label = Label.new()
	type_label.text = "%s - %s" % [item.get_item_type_string().capitalize(), item.get_rarity_string()]
	type_label.add_theme_font_size_override("font_size", 12)
	type_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	item_detail_info_vbox.add_child(type_label)

	# Description
	if item.description != "":
		var desc_spacer = Control.new()
		desc_spacer.custom_minimum_size = Vector2(0, 10)
		item_detail_info_vbox.add_child(desc_spacer)

		var desc_label = Label.new()
		desc_label.text = item.description
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_label.add_theme_font_size_override("font_size", 12)
		desc_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.7))
		item_detail_info_vbox.add_child(desc_label)

	# Bonuses
	var bonuses_spacer = Control.new()
	bonuses_spacer.custom_minimum_size = Vector2(0, 10)
	item_detail_info_vbox.add_child(bonuses_spacer)

	var bonuses_label = Label.new()
	bonuses_label.text = "BONUSES:"
	bonuses_label.add_theme_font_size_override("font_size", 14)
	item_detail_info_vbox.add_child(bonuses_label)

	var bonus_desc = Label.new()
	bonus_desc.text = item.get_bonus_description()
	bonus_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	bonus_desc.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
	item_detail_info_vbox.add_child(bonus_desc)

	# Check if equipped
	var is_equipped = _is_item_equipped(selected_item_id)
	var equipped_slot = _get_equipped_slot(selected_item_id)

	# Status
	var status_spacer = Control.new()
	status_spacer.custom_minimum_size = Vector2(0, 15)
	item_detail_info_vbox.add_child(status_spacer)

	var status_label = Label.new()
	if is_equipped:
		status_label.text = "✓ EQUIPPED (%s)" % equipped_slot.to_upper()
		status_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		status_label.text = "IN INVENTORY"
		status_label.add_theme_color_override("font_color", Color.YELLOW)
	status_label.add_theme_font_size_override("font_size", 16)
	item_detail_info_vbox.add_child(status_label)

	# Button (Equip/Unequip/Use depending on item type)
	var button = Button.new()
	button.custom_minimum_size = Vector2(200, 50)
	button.add_theme_font_size_override("font_size", 16)

	# Check if item is a consumable
	if item.item_type == ItemData.ItemType.CONSUMABLE:
		button.text = "USE"
		button.pressed.connect(func(): _on_use_consumable_pressed(selected_item_id))
	elif is_equipped:
		button.text = "UNEQUIP"
		button.pressed.connect(func(): _on_unequip_item_pressed(equipped_slot))
	else:
		button.text = "EQUIP"
		button.pressed.connect(func(): _on_equip_item_pressed(selected_item_id))

	item_detail_button_container.add_child(button)

func _is_item_equipped(item_id: String) -> bool:
	"""Check if an item is currently equipped"""
	if PlayerStore.equipped_weapon == item_id:
		return true
	if PlayerStore.equipped_armor == item_id:
		return true
	if item_id in PlayerStore.equipped_accessories:
		return true
	return false

func _get_equipped_slot(item_id: String) -> String:
	"""Get the slot name where an item is equipped"""
	if PlayerStore.equipped_weapon == item_id:
		return "weapon"
	if PlayerStore.equipped_armor == item_id:
		return "armor"
	for i in range(PlayerStore.equipped_accessories.size()):
		if PlayerStore.equipped_accessories[i] == item_id:
			return "accessory_%d" % i
	return ""

func _on_equip_item_pressed(item_id: String):
	"""Handle equip button press"""
	if ItemEngine.equip_item(item_id):
		selected_item_id = ""  # Clear selection after equipping
		_switch_tab(Tab.ITEMS)  # Refresh UI

func _on_unequip_item_pressed(slot: String):
	"""Handle unequip button press"""
	if ItemEngine.unequip_item_by_slot(slot):
		selected_item_id = ""  # Clear selection after unequipping
		_switch_tab(Tab.ITEMS)  # Refresh UI

func _on_use_consumable_pressed(item_id: String):
	"""Handle use consumable button press"""
	if ItemEngine.use_consumable(item_id, false):  # false = not in battle
		selected_item_id = ""  # Clear selection after using
		_switch_tab(Tab.ITEMS)  # Refresh UI

func _on_back_button_pressed():
	print("InventoryView: Back button pressed")
	back_button_pressed.emit()
