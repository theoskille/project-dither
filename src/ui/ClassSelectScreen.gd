extends Control

## Class selection screen
## Allows player to choose their character class
## Currently only supports Brawler class

signal class_selected(class_id: String)
signal back_clicked()

const CharacterClassDatabase = preload("res://src/data/CharacterClassDatabase.gd")
const AttackDatabase = preload("res://src/data/AttackDatabase.gd")

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
	vbox.add_theme_constant_override("separation", 30)
	margin.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "Choose Your Class"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	vbox.add_child(title)

	# Add spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	# Load brawler class data
	var class_db = CharacterClassDatabase.new()
	var brawler_data = class_db.get_character_class("brawler")

	if brawler_data:
		# Create class panel
		var class_panel = _create_class_panel(brawler_data)
		vbox.add_child(class_panel)

	# Button container
	var button_hbox = HBoxContainer.new()
	button_hbox.add_theme_constant_override("separation", 20)
	button_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(button_hbox)

	# Back button
	var back_button = Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(150, 50)
	back_button.pressed.connect(_on_back_pressed)
	button_hbox.add_child(back_button)

	# Select button
	var select_button = Button.new()
	select_button.text = "Select Brawler"
	select_button.custom_minimum_size = Vector2(200, 50)
	select_button.pressed.connect(_on_select_pressed.bind("brawler"))
	button_hbox.add_child(select_button)

func _create_class_panel(class_data) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Panel content
	var panel_margin = MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 30)
	panel_margin.add_theme_constant_override("margin_right", 30)
	panel_margin.add_theme_constant_override("margin_top", 30)
	panel_margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(panel_margin)

	var panel_vbox = VBoxContainer.new()
	panel_vbox.add_theme_constant_override("separation", 20)
	panel_margin.add_child(panel_vbox)

	# Class name
	var class_name_label = Label.new()
	class_name_label.text = class_data.display_name
	class_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	class_name_label.add_theme_font_size_override("font_size", 28)
	panel_vbox.add_child(class_name_label)

	# Class description
	var description = Label.new()
	description.text = "A melee fighter specializing in close combat and raw power"
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_vbox.add_child(description)

	# Separator
	var separator1 = HSeparator.new()
	panel_vbox.add_child(separator1)

	# Base stats section
	var stats_label = Label.new()
	stats_label.text = "Base Stats"
	stats_label.add_theme_font_size_override("font_size", 20)
	panel_vbox.add_child(stats_label)

	# Stats grid
	var stats_grid = GridContainer.new()
	stats_grid.columns = 3
	stats_grid.add_theme_constant_override("h_separation", 40)
	stats_grid.add_theme_constant_override("v_separation", 10)
	panel_vbox.add_child(stats_grid)

	# Add stats
	var stat_names = ["STR", "DEX", "INT", "CON", "SPD", "LUCK"]
	for stat_name in stat_names:
		var stat_key = stat_name.to_lower()
		var stat_value = class_data.base_stats.get(stat_key, 0)

		var stat_label = Label.new()
		stat_label.text = "%s: %d" % [stat_name, stat_value]
		stats_grid.add_child(stat_label)

	# Separator
	var separator2 = HSeparator.new()
	panel_vbox.add_child(separator2)

	# Starting abilities section
	var abilities_label = Label.new()
	abilities_label.text = "Starting Abilities"
	abilities_label.add_theme_font_size_override("font_size", 20)
	panel_vbox.add_child(abilities_label)

	# Load and display starting abilities
	if class_data.starting_unlocked_skills.size() > 0:
		var attack_db = AttackDatabase.new()
		for skill_id in class_data.starting_unlocked_skills:
			var action_data = attack_db.get_action(skill_id)
			if action_data:
				var ability_label = Label.new()
				ability_label.text = "• %s - %s" % [action_data.action_name, _get_action_description(action_data)]
				ability_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				panel_vbox.add_child(ability_label)
	else:
		var no_abilities = Label.new()
		no_abilities.text = "• None"
		panel_vbox.add_child(no_abilities)

	return panel

func _get_action_description(action_data) -> String:
	var desc = ""

	if action_data.base_damage > 0:
		desc += "Deals %d base damage" % action_data.base_damage
		if action_data.str_modifier > 0:
			desc += " + %.1fx STR" % action_data.str_modifier
		elif action_data.dex_modifier > 0:
			desc += " + %.1fx DEX" % action_data.dex_modifier
		elif action_data.int_modifier > 0:
			desc += " + %.1fx INT" % action_data.int_modifier

	if action_data.min_range > 0 or action_data.max_range < 999:
		if desc != "":
			desc += ". "
		desc += "Range: %d-%d" % [action_data.min_range, action_data.max_range]

	if action_data.vigor_cost > 0:
		if desc != "":
			desc += ". "
		desc += "Costs %d vigor" % action_data.vigor_cost

	return desc if desc != "" else "Basic ability"

func _on_select_pressed(class_id: String):
	class_selected.emit(class_id)

func _on_back_pressed():
	back_clicked.emit()
