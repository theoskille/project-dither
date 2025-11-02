extends PanelContainer

# Generic entity panel for both player and enemies
# Shows stats, actions, and effects for any entity

@export var entity_name: String = "player"

# References to UI elements
var title_label: Label
var hp_label: Label
var hp_bar: ProgressBar
var vigor_label: Label
var vigor_bar: ProgressBar
var stats_container: VBoxContainer
var actions_separator: HSeparator
var actions_container: VBoxContainer
var action_buttons: Array[Button] = []
var move_forward_button: Button
var move_backward_button: Button
var done_turn_button: Button
var effects_separator: HSeparator
var effects_title: Label
var effects_container: VBoxContainer
var target_selection_panel: VBoxContainer = null
var pending_action_id: String = ""

func _ready():
	BattleStateStore.state_changed.connect(_on_state_changed)
	_build_panel()
	_update_display()
	_update_buttons()

func _build_panel():
	# Set minimum size for panel (slightly smaller for grid layout)
	custom_minimum_size = Vector2(220, 400)

	# Main vertical container
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 6)
	add_child(main_vbox)

	# === HEADER SECTION ===
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 14)
	main_vbox.add_child(title_label)

	# Spacer after title
	var title_spacer = Control.new()
	title_spacer.custom_minimum_size = Vector2(0, 6)
	main_vbox.add_child(title_spacer)

	# === STATS SECTION ===
	# HP Label
	hp_label = Label.new()
	hp_label.add_theme_font_size_override("font_size", 11)
	main_vbox.add_child(hp_label)

	# HP Bar
	hp_bar = ProgressBar.new()
	hp_bar.set_script(preload("res://src/ui/HealthBar.gd"))
	hp_bar.entity_name = entity_name
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(0, 18)
	main_vbox.add_child(hp_bar)

	# Vigor Label
	vigor_label = Label.new()
	vigor_label.add_theme_font_size_override("font_size", 11)
	main_vbox.add_child(vigor_label)

	# Vigor Bar
	vigor_bar = ProgressBar.new()
	vigor_bar.set_script(preload("res://src/ui/VigorBar.gd"))
	vigor_bar.entity_name = entity_name
	vigor_bar.show_percentage = false
	vigor_bar.custom_minimum_size = Vector2(0, 18)
	main_vbox.add_child(vigor_bar)

	# Small spacer
	var stats_spacer = Control.new()
	stats_spacer.custom_minimum_size = Vector2(0, 3)
	main_vbox.add_child(stats_spacer)

	# Base Stats
	stats_container = VBoxContainer.new()
	stats_container.add_theme_constant_override("separation", 1)
	main_vbox.add_child(stats_container)

	var stat_names = ["STR", "DEX", "INT", "CON", "SPD", "LUCK"]
	for stat_name in stat_names:
		var stat_label = Label.new()
		stat_label.name = stat_name
		stat_label.add_theme_font_size_override("font_size", 10)
		stats_container.add_child(stat_label)

	# === ACTIONS SECTION ===
	actions_separator = HSeparator.new()
	main_vbox.add_child(actions_separator)

	var actions_title = Label.new()
	actions_title.text = "ACTIONS"
	actions_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	actions_title.add_theme_font_size_override("font_size", 12)
	main_vbox.add_child(actions_title)

	actions_container = VBoxContainer.new()
	actions_container.add_theme_constant_override("separation", 3)
	main_vbox.add_child(actions_container)

	# Movement buttons
	move_forward_button = Button.new()
	move_forward_button.text = "Move Forward"
	move_forward_button.pressed.connect(_on_move_forward_pressed)
	actions_container.add_child(move_forward_button)

	move_backward_button = Button.new()
	move_backward_button.text = "Move Backward"
	move_backward_button.pressed.connect(_on_move_backward_pressed)
	actions_container.add_child(move_backward_button)

	# Done turn button
	done_turn_button = Button.new()
	done_turn_button.text = "End Turn"
	done_turn_button.pressed.connect(_on_done_turn_pressed)
	actions_container.add_child(done_turn_button)

	# Attack buttons will be added dynamically
	_rebuild_action_buttons()

	# === EFFECTS SECTION ===
	effects_separator = HSeparator.new()
	main_vbox.add_child(effects_separator)

	effects_title = Label.new()
	effects_title.text = "EFFECTS"
	effects_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effects_title.add_theme_font_size_override("font_size", 12)
	main_vbox.add_child(effects_title)

	effects_container = VBoxContainer.new()
	effects_container.add_theme_constant_override("separation", 2)
	main_vbox.add_child(effects_container)

func _on_state_changed(property_path: String, _old_value, _new_value):
	# Handle both player and enemy state changes
	var is_player = entity_name == "player"
	var is_enemy = entity_name.begins_with("enemy_")

	# Update stats display
	if is_player and property_path.begins_with("player_state."):
		_update_display()
	elif is_enemy:
		var index = int(entity_name.split("_")[1])
		if property_path.begins_with("enemies.%d." % index) or property_path == "enemies.%d" % index:
			_update_display()

	# Rebuild action buttons if equipped attacks changed
	if is_player and property_path == "player_state.equipped_attacks":
		_rebuild_action_buttons()
	elif is_enemy:
		var index = int(entity_name.split("_")[1])
		if property_path == "enemies.%d.equipped_attacks" % index:
			_rebuild_action_buttons()

	# Update button states
	if (property_path.ends_with("current_turn_index") or
		property_path.contains("current_vigor") or
		property_path.contains("position")):
		_update_buttons()

	# Update effects display
	if is_player and property_path == "player_state.active_effects":
		_update_effects()
	elif is_enemy:
		var index = int(entity_name.split("_")[1])
		if property_path == "enemies.%d.active_effects" % index:
			_update_effects()

func _get_entity() -> EntityState:
	if entity_name == "player":
		return BattleStateStore.battle_state.player_state
	elif entity_name.begins_with("enemy_"):
		var index = int(entity_name.split("_")[1])
		if index >= 0 and index < BattleStateStore.battle_state.enemies.size():
			return BattleStateStore.battle_state.enemies[index]
	return null

func _update_display():
	var entity = _get_entity()
	if not entity:
		title_label.text = "NO ENTITY"
		hp_label.text = "HP: -/-"
		vigor_label.text = "Vigor: -/-"
		return

	# Update title
	if entity.name != null and not entity.name.is_empty():
		title_label.text = entity.name.to_upper()
	else:
		title_label.text = entity_name.to_upper()

	# Update HP
	hp_label.text = "HP: %d/%d" % [entity.current_hp, entity.max_hp]

	# Update Vigor
	vigor_label.text = "Vigor: %d/%d" % [entity.current_vigor, entity.max_vigor]

	# Update base stats
	if entity.base_stats != null:
		var stat_keys = ["str", "dex", "int", "con", "spd", "luck"]
		for i in range(stat_keys.size()):
			var stat_key = stat_keys[i]
			var stat_label = stats_container.get_child(i)
			if stat_label != null and entity.base_stats.has(stat_key):
				stat_label.text = "%s: %d" % [stat_key.to_upper(), entity.base_stats[stat_key]]

	# Update effects
	_update_effects()

func _update_effects():
	# Clear existing effects
	for child in effects_container.get_children():
		child.queue_free()

	var entity = _get_entity()
	if not entity:
		return

	var active_effects = entity.active_effects

	if active_effects.is_empty():
		var no_effects = Label.new()
		no_effects.text = "(None)"
		no_effects.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_effects.add_theme_font_size_override("font_size", 10)
		effects_container.add_child(no_effects)
	else:
		for effect in active_effects:
			_add_effect_display(effect)

func _add_effect_display(effect: EffectState):
	var effect_template = EffectDatabase.get_effect(effect.effect_id)
	var effect_name = effect_template.effect_name if effect_template else effect.effect_id

	# Effect name + duration
	var name_label = Label.new()
	name_label.text = "%s (%d)" % [effect_name, effect.remaining_duration]
	name_label.add_theme_font_size_override("font_size", 10)
	effects_container.add_child(name_label)

	# Effect details
	var details = _format_effect_details(effect)
	if not details.is_empty():
		var details_label = Label.new()
		details_label.text = "  " + details
		details_label.add_theme_font_size_override("font_size", 9)
		effects_container.add_child(details_label)

func _format_effect_details(effect: EffectState) -> String:
	var parts = []

	if effect.damage_per_turn > 0:
		parts.append("-%d HP/turn" % effect.damage_per_turn)

	var stat_keys = ["str", "dex", "int", "con", "spd", "luck"]
	for stat in stat_keys:
		var flat = effect.get("%s_modifier" % stat)
		var percent = effect.get("percent_%s_modifier" % stat)
		if flat != 0 or percent != 0:
			var parts_for_stat = []
			if flat > 0:
				parts_for_stat.append("+%d" % flat)
			elif flat < 0:
				parts_for_stat.append("%d" % flat)
			if percent > 0:
				parts_for_stat.append("+%d%%" % percent)
			elif percent < 0:
				parts_for_stat.append("%d%%" % percent)
			parts.append("%s %s" % [" ".join(parts_for_stat), stat.to_upper()])

	if effect.blocks_all_actions:
		parts.append("Cannot act")
	elif not effect.blocks_action_types.is_empty():
		parts.append("Blocks: " + ", ".join(effect.blocks_action_types))

	return ", ".join(parts)

func _rebuild_action_buttons():
	# Clear existing action buttons
	for button in action_buttons:
		button.queue_free()
	action_buttons.clear()

	# Get equipped attacks for this entity
	var equipped_attacks = null
	if entity_name == "player":
		equipped_attacks = BattleStateStore.get_state_value("player_state.equipped_attacks")
	elif entity_name.begins_with("enemy_"):
		var entity = _get_entity()
		if entity:
			equipped_attacks = entity.equipped_attacks

	if equipped_attacks == null:
		return

	# Create button for each equipped attack
	# Insert at beginning of actions_container
	var insert_index = 0

	for action_id in equipped_attacks:
		var action_data = AttackDatabase.get_action(action_id)
		if action_data == null:
			continue

		var button = Button.new()
		button.text = "%s (%d-%d)" % [action_data.action_name, action_data.min_range, action_data.max_range]
		button.add_theme_font_size_override("font_size", 10)
		button.pressed.connect(_on_action_button_pressed.bind(action_id))

		actions_container.add_child(button)
		actions_container.move_child(button, insert_index)
		insert_index += 1
		action_buttons.append(button)

func _update_buttons():
	var current_entity = CombatEngine._get_current_turn_entity()
	var is_my_turn = (current_entity == entity_name)

	var entity = _get_entity()
	var current_vigor = entity.current_vigor if entity else 0

	# Update action buttons
	for i in range(action_buttons.size()):
		var button = action_buttons[i]
		var equipped_attacks = null

		if entity_name == "player":
			equipped_attacks = BattleStateStore.get_state_value("player_state.equipped_attacks")
		elif entity:
			equipped_attacks = entity.equipped_attacks

		if equipped_attacks != null and i < equipped_attacks.size():
			var action_id = equipped_attacks[i]
			var action = AttackDatabase.get_action(action_id)
			button.disabled = not is_my_turn or (action and current_vigor < action.vigor_cost)
		else:
			button.disabled = true

	# Update movement buttons
	move_forward_button.disabled = not is_my_turn or current_vigor < 1
	move_backward_button.disabled = not is_my_turn or current_vigor < 1

	# Update done turn button
	done_turn_button.disabled = not is_my_turn

func _on_action_button_pressed(action_id: String):
	var action = AttackDatabase.get_action(action_id)
	if not action:
		return

	pending_action_id = action_id
	_show_target_selection(action)

func _show_target_selection(action: ActionData):
	# Create target selection panel if it doesn't exist
	if target_selection_panel == null:
		# Create a centered panel container for the overlay
		var overlay_panel = PanelContainer.new()
		overlay_panel.custom_minimum_size = Vector2(300, 200)

		# Position it in the center of the screen
		overlay_panel.anchor_left = 0.5
		overlay_panel.anchor_top = 0.5
		overlay_panel.anchor_right = 0.5
		overlay_panel.anchor_bottom = 0.5
		overlay_panel.offset_left = -150  # Half of width
		overlay_panel.offset_top = -100   # Half of height
		overlay_panel.offset_right = 150
		overlay_panel.offset_bottom = 100
		overlay_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
		overlay_panel.grow_vertical = Control.GROW_DIRECTION_BOTH

		target_selection_panel = VBoxContainer.new()
		target_selection_panel.set_script(preload("res://src/ui/TargetSelectionPanel.gd"))
		target_selection_panel.target_selected.connect(_on_target_selected)
		target_selection_panel.cancelled.connect(_on_target_selection_cancelled)
		overlay_panel.add_child(target_selection_panel)

		# Add to root Main scene to display as overlay
		get_tree().root.get_node("Main").add_child(overlay_panel)

	# Configure the panel
	target_selection_panel.caster_id = entity_name
	target_selection_panel.action_data = action
	target_selection_panel.get_parent().visible = true  # Show the overlay container
	target_selection_panel.refresh()

	# Hide action buttons while selecting
	_set_action_buttons_visible(false)

func _on_target_selected(target_id: String):
	if target_selection_panel:
		target_selection_panel.get_parent().visible = false

	_set_action_buttons_visible(true)

	var action = AttackDatabase.get_action(pending_action_id)
	if action:
		CombatEngine.execute_move(action, entity_name, target_id)

	pending_action_id = ""

func _on_target_selection_cancelled():
	if target_selection_panel:
		target_selection_panel.get_parent().visible = false

	_set_action_buttons_visible(true)
	pending_action_id = ""

func _set_action_buttons_visible(visible: bool):
	for button in action_buttons:
		button.visible = visible
	move_forward_button.visible = visible
	move_backward_button.visible = visible
	done_turn_button.visible = visible

func _on_move_forward_pressed():
	var action = AttackDatabase.get_action("move_forward")
	CombatEngine.execute_move(action, entity_name, entity_name)

func _on_move_backward_pressed():
	var action = AttackDatabase.get_action("move_backward")
	CombatEngine.execute_move(action, entity_name, entity_name)

func _on_done_turn_pressed():
	CombatEngine.end_turn()
