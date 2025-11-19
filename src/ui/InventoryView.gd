extends Control

## Inventory view UI
## Shows player base stats, equipped attacks, and passive abilities
## Reactive component that listens to PlayerStore signals

signal back_button_pressed()

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
	main_vbox.add_theme_constant_override("separation", 15)
	margin.add_child(main_vbox)

	# Title
	var title = Label.new()
	title.text = "INVENTORY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.custom_minimum_size = Vector2(0, 48)
	main_vbox.add_child(title)

	# Content area (scrollable)
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll)

	var content_vbox = VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 20)
	scroll.add_child(content_vbox)

	# === BASE STATS SECTION ===
	var stats_panel = PanelContainer.new()
	stats_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(stats_panel)

	var stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 10)
	stats_panel.add_child(stats_vbox)

	var stats_header = Label.new()
	stats_header.text = "Base Stats"
	stats_header.add_theme_font_size_override("font_size", 18)
	stats_vbox.add_child(stats_header)

	# Create stat labels
	var base_stats = PlayerStore.base_stats
	for stat_name in ["str", "dex", "int", "con", "spd", "luck"]:
		var stat_label = Label.new()
		var display_name = stat_name.to_upper()
		var stat_value = base_stats.get(stat_name, 0)
		stat_label.text = "%s: %d" % [display_name, stat_value]
		stats_vbox.add_child(stat_label)

	# === EQUIPPED ATTACKS SECTION ===
	var attacks_panel = PanelContainer.new()
	attacks_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(attacks_panel)

	var attacks_vbox = VBoxContainer.new()
	attacks_vbox.add_theme_constant_override("separation", 10)
	attacks_panel.add_child(attacks_vbox)

	var attacks_header = Label.new()
	attacks_header.text = "Equipped Attacks"
	attacks_header.add_theme_font_size_override("font_size", 18)
	attacks_vbox.add_child(attacks_header)

	var equipped_attacks = PlayerStore.equipped_attacks
	if equipped_attacks.size() > 0:
		for attack_id in equipped_attacks:
			var attack_label = Label.new()
			# Format attack name: "dash_strike" -> "Dash Strike"
			var display_name = attack_id.replace("_", " ").capitalize()
			attack_label.text = "• %s" % display_name
			attacks_vbox.add_child(attack_label)
	else:
		var no_attacks_label = Label.new()
		no_attacks_label.text = "No attacks equipped"
		no_attacks_label.modulate = Color(0.7, 0.7, 0.7)
		attacks_vbox.add_child(no_attacks_label)

	# === PASSIVE ABILITIES SECTION ===
	var abilities_panel = PanelContainer.new()
	abilities_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(abilities_panel)

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

func _connect_signals():
	PlayerStore.state_changed.connect(_on_player_state_changed)

func _on_player_state_changed(_property_path: String, _old_value, _new_value):
	# Rebuild UI when player data changes
	# For now, we just rebuild the entire UI
	# In the future, could optimize to only update changed elements
	for child in get_children():
		child.queue_free()
	_build_ui()

func _on_back_button_pressed():
	print("InventoryView: Back button pressed")
	back_button_pressed.emit()
