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
var basic_actions_container: VBoxContainer  # Left column: movement + end turn
var attack_actions_container: VBoxContainer  # Right column: attacks/abilities
var action_buttons: Array[Button] = []
var move_forward_button: Button
var move_backward_button: Button
var done_turn_button: Button
var effects_separator: HSeparator
var effects_title: Label
var effects_container: VBoxContainer
var passives_title: Label
var passives_container: VBoxContainer
var target_selection_panel: VBoxContainer = null
var direction_selection_panel: VBoxContainer = null
var pending_action_id: String = ""

func _ready():
	BattleStateStore.state_changed.connect(_on_state_changed)
	_build_panel()
	_update_display()
	_update_buttons()

func _build_panel():
	# Main vertical container (no fixed size, responsive)
	var main_vbox = VBoxContainer.new()
	add_child(main_vbox)

	# === HEADER SECTION ===
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title_label)

	# Spacer after title
	var title_spacer = Control.new()
	title_spacer.custom_minimum_size = Vector2(0, 6)
	main_vbox.add_child(title_spacer)

	# === TOP ROW: STATS (LEFT) + EFFECTS (RIGHT) ===
	var top_row_hbox = HBoxContainer.new()
	top_row_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(top_row_hbox)

	# LEFT COLUMN: Stats
	var stats_vbox = VBoxContainer.new()
	stats_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row_hbox.add_child(stats_vbox)

	# HP Label
	hp_label = Label.new()
	stats_vbox.add_child(hp_label)

	# HP Bar
	hp_bar = ProgressBar.new()
	hp_bar.set_script(preload("res://src/ui/HealthBar.gd"))
	hp_bar.entity_name = entity_name
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(0, 18)
	stats_vbox.add_child(hp_bar)

	# Vigor Label
	vigor_label = Label.new()
	stats_vbox.add_child(vigor_label)

	# Vigor Bar
	vigor_bar = ProgressBar.new()
	vigor_bar.set_script(preload("res://src/ui/VigorBar.gd"))
	vigor_bar.entity_name = entity_name
	vigor_bar.show_percentage = false
	vigor_bar.custom_minimum_size = Vector2(0, 18)
	stats_vbox.add_child(vigor_bar)

	# Small spacer
	var stats_spacer = Control.new()
	stats_spacer.custom_minimum_size = Vector2(0, 3)
	stats_vbox.add_child(stats_spacer)

	# Base Stats
	stats_container = VBoxContainer.new()
	stats_vbox.add_child(stats_container)

	var stat_names = ["STR", "DEX", "INT", "CON", "SPD", "LUCK"]
	for stat_name in stat_names:
		var stat_label = Label.new()
		stat_label.name = stat_name
		stats_container.add_child(stat_label)

	# Add dodge chance label
	var dodge_label = Label.new()
	dodge_label.name = "DODGE"
	stats_container.add_child(dodge_label)

	# Add armor label
	var armor_label = Label.new()
	armor_label.name = "ARMOR"
	stats_container.add_child(armor_label)

	# RIGHT COLUMN: Effects
	var effects_vbox = VBoxContainer.new()
	effects_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row_hbox.add_child(effects_vbox)

	effects_title = Label.new()
	effects_title.text = "EFFECTS"
	effects_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effects_vbox.add_child(effects_title)

	effects_container = VBoxContainer.new()
	effects_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	effects_vbox.add_child(effects_container)

	# Small spacer between effects and passives
	var passives_spacer = Control.new()
	passives_spacer.custom_minimum_size = Vector2(0, 8)
	effects_vbox.add_child(passives_spacer)

	# Passives title
	passives_title = Label.new()
	passives_title.text = "PASSIVES"
	passives_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effects_vbox.add_child(passives_title)

	# Passives container
	passives_container = VBoxContainer.new()
	passives_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	effects_vbox.add_child(passives_container)

	# === ACTIONS SECTION ===
	actions_separator = HSeparator.new()
	main_vbox.add_child(actions_separator)

	var actions_title = Label.new()
	actions_title.text = "ACTIONS"
	actions_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(actions_title)

	# Two-column action layout
	var actions_hbox = HBoxContainer.new()
	actions_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(actions_hbox)

	# LEFT COLUMN: Basic actions (movement only)
	basic_actions_container = VBoxContainer.new()
	basic_actions_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_hbox.add_child(basic_actions_container)

	# Movement buttons
	move_forward_button = Button.new()
	move_forward_button.text = "Move Fwd"
	move_forward_button.pressed.connect(_on_move_forward_pressed)
	basic_actions_container.add_child(move_forward_button)

	move_backward_button = Button.new()
	move_backward_button.text = "Move Back"
	move_backward_button.pressed.connect(_on_move_backward_pressed)
	basic_actions_container.add_child(move_backward_button)

	# RIGHT COLUMN: Attack/ability actions
	attack_actions_container = VBoxContainer.new()
	attack_actions_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_hbox.add_child(attack_actions_container)

	# Attack buttons will be added dynamically
	_rebuild_action_buttons()

	# === END TURN SECTION (separate row at bottom) ===
	done_turn_button = Button.new()
	done_turn_button.text = "End Turn"
	done_turn_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	done_turn_button.pressed.connect(_on_done_turn_pressed)
	main_vbox.add_child(done_turn_button)

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

	# Update passives display
	if is_player and property_path == "player_state.passive_abilities":
		_update_passives()
	elif is_enemy:
		var index = int(entity_name.split("_")[1])
		if property_path == "enemies.%d.passive_abilities" % index:
			_update_passives()

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
		modulate = Color(1, 1, 1)  # Reset to normal
		return

	# Check if entity is dead
	if entity.is_dead:
		# Grey out the panel
		modulate = Color(0.5, 0.5, 0.5)

		# Show DEAD label
		title_label.text = "DEAD"
		hp_label.text = "HP: 0/%d" % entity.max_hp
		vigor_label.text = "Vigor: -/-"

		# Hide action buttons
		_set_action_buttons_visible(false)
		done_turn_button.visible = false

		return

	# Entity is alive - normal display
	modulate = Color(1, 1, 1)  # Reset to normal color

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

		# Update dodge chance (7th child in stats_container)
		var dodge_label = stats_container.get_child(6)  # Index 6 = 7th child (after 6 stats)
		if dodge_label != null:
			dodge_label.text = "DODGE: %.1f%%" % entity.dodge_chance

		# Update armor (8th child in stats_container)
		var armor_label = stats_container.get_child(7)  # Index 7 = 8th child (after 6 stats + dodge)
		if armor_label != null:
			armor_label.text = "ARMOR: %.1f%%" % entity.armor

	# Update effects
	_update_effects()

	# Update passives
	_update_passives()

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
	effects_container.add_child(name_label)

	# Effect details
	var details = _format_effect_details(effect)
	if not details.is_empty():
		var details_label = Label.new()
		details_label.text = "  " + details
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

func _update_passives():
	# Clear existing passive displays
	for child in passives_container.get_children():
		child.queue_free()

	var entity = _get_entity()
	if not entity:
		return

	var passive_abilities = entity.passive_abilities

	if passive_abilities.is_empty():
		var no_passives = Label.new()
		no_passives.text = "(None)"
		no_passives.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		passives_container.add_child(no_passives)
	else:
		for passive_id in passive_abilities:
			_add_passive_display(passive_id)

func _add_passive_display(passive_id: String):
	var passive = PassiveAbilityDatabase.get_passive(passive_id)
	if not passive:
		var error_label = Label.new()
		error_label.text = "Unknown: %s" % passive_id
		passives_container.add_child(error_label)
		return

	# Passive name label
	var name_label = Label.new()
	name_label.text = passive.passive_name
	passives_container.add_child(name_label)

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

	# Create button for each equipped attack in right column (attack_actions_container)
	for action_id in equipped_attacks:
		var action_data = AttackDatabase.get_action(action_id)
		if action_data == null:
			continue

		var button = Button.new()
		button.text = "%s (%d-%d)" % [action_data.action_name, action_data.min_range, action_data.max_range]
		button.pressed.connect(_on_action_button_pressed.bind(action_id))

		attack_actions_container.add_child(button)
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
		print("EntityPanel ERROR: Could not load action '%s'" % action_id)
		return

	# DEBUG: Check property values
	print("EntityPanel [%s]: action_id='%s', targets_self=%s, requires_direction=%s" % [entity_name, action_id, action.targets_self, action.requires_direction])

	# If action targets self, execute immediately without target selection
	if action.targets_self:
		print("EntityPanel: Executing self-targeting action for %s" % entity_name)
		CombatEngine.execute_move(action, entity_name, entity_name)
		return

	# If action requires direction, show direction selection panel
	if action.requires_direction:
		print("EntityPanel: Showing direction selection for %s" % entity_name)
		pending_action_id = action_id
		_show_direction_selection(action)
		return

	print("EntityPanel: Showing target selection for %s" % entity_name)
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

func _show_direction_selection(_action: ActionData):
	# Create direction selection panel if it doesn't exist
	if direction_selection_panel == null:
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

		direction_selection_panel = VBoxContainer.new()
		direction_selection_panel.set_script(preload("res://src/ui/DirectionSelectionPanel.gd"))
		direction_selection_panel.direction_selected.connect(_on_direction_selected)
		direction_selection_panel.cancelled.connect(_on_direction_selection_cancelled)
		overlay_panel.add_child(direction_selection_panel)

		# Add to root Main scene to display as overlay
		get_tree().root.get_node("Main").add_child(overlay_panel)

	# Show the overlay
	direction_selection_panel.get_parent().visible = true

	# Hide action buttons while selecting
	_set_action_buttons_visible(false)

func _on_direction_selected(direction: int):
	if direction_selection_panel:
		direction_selection_panel.get_parent().visible = false

	_set_action_buttons_visible(true)

	# Execute the action with direction
	var action = AttackDatabase.get_action(pending_action_id)
	if action:
		CombatEngine.execute_move(action, entity_name, entity_name, direction)

	pending_action_id = ""

func _on_direction_selection_cancelled():
	if direction_selection_panel:
		direction_selection_panel.get_parent().visible = false

	_set_action_buttons_visible(true)
	pending_action_id = ""

func _set_action_buttons_visible(buttons_visible: bool):
	for button in action_buttons:
		button.visible = buttons_visible
	move_forward_button.visible = buttons_visible
	move_backward_button.visible = buttons_visible
	done_turn_button.visible = buttons_visible

func _on_move_forward_pressed():
	var action = AttackDatabase.get_action("move_forward")
	CombatEngine.execute_move(action, entity_name, entity_name)

func _on_move_backward_pressed():
	var action = AttackDatabase.get_action("move_backward")
	CombatEngine.execute_move(action, entity_name, entity_name)

func _on_done_turn_pressed():
	CombatEngine.end_turn()
