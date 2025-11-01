extends VBoxContainer

signal target_selected(target_id: String)
signal cancelled

@export var caster_id: String = ""
@export var action_data: ActionData = null

var target_buttons: Array[Button] = []

func _ready():
	_build_ui()
	_connect_signals()

func _build_ui():
	# Title
	var title = Label.new()
	title.text = "Select Target"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	add_child(spacer)

	# Create target buttons
	_create_target_buttons()

	# Spacer
	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 10)
	add_child(bottom_spacer)

	# Cancel button
	var cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(_on_cancel_pressed)
	add_child(cancel_button)

func _create_target_buttons():
	# Clear existing buttons
	for button in target_buttons:
		button.queue_free()
	target_buttons.clear()

	# Determine valid targets based on caster
	var potential_targets = _get_potential_targets()

	for target_id in potential_targets:
		var entity = _get_entity_by_id(target_id)
		if not entity:
			continue

		# Create button for this target
		var button = Button.new()

		# Format: "Enemy Name HP: 123/150 Pos: 5"
		var hp_text = "%d/%d" % [entity.current_hp, entity.max_hp]
		var pos_text = "Pos: %d" % entity.position
		button.text = "%s HP: %s %s" % [entity.name, hp_text, pos_text]

		# Check if target is in range
		var is_in_range = _is_target_in_range(target_id)
		button.disabled = not is_in_range

		# Connect signal with target_id
		button.pressed.connect(_on_target_button_pressed.bind(target_id))

		add_child(button)
		target_buttons.append(button)

func _get_potential_targets() -> Array[String]:
	var targets: Array[String] = []

	# If player is casting, can target all enemies
	if caster_id == "player":
		var enemies = BattleStateStore.battle_state.enemies
		for i in range(enemies.size()):
			targets.append("enemy_%d" % i)
	# If enemy is casting, can only target player (for now)
	else:
		targets.append("player")

	return targets

func _is_target_in_range(target_id: String) -> bool:
	if not action_data:
		return true  # No range restriction if no action data

	var distance = CombatEngine._get_distance_between_entities(caster_id, target_id)
	return distance >= action_data.min_range and distance <= action_data.max_range

func _get_entity_by_id(entity_id: String) -> EntityState:
	if entity_id == "player":
		return BattleStateStore.battle_state.player_state
	elif entity_id.begins_with("enemy_"):
		var index = int(entity_id.split("_")[1])
		if index >= 0 and index < BattleStateStore.battle_state.enemies.size():
			return BattleStateStore.battle_state.enemies[index]
	return null

func refresh():
	# Only rebuild target buttons (for updated HP/position info)
	# Don't recreate static UI elements (title, spacers, cancel button)
	_create_target_buttons()

func _connect_signals():
	# Subscribe to HP and position changes to update button text
	BattleStateStore.state_changed.connect(_on_state_changed)

func _on_state_changed(property_path: String, old_value, new_value):
	# If HP or position changed, rebuild buttons to show updated info
	if "current_hp" in property_path or "position" in property_path:
		refresh()

func _on_target_button_pressed(target_id: String):
	target_selected.emit(target_id)

func _on_cancel_pressed():
	cancelled.emit()
