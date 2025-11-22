extends VBoxContainer

@export var entity_name: String = "player"

var title_label: Label
var hp_label: Label
var hp_bar: ProgressBar
var vigor_label: Label
var vigor_bar: ProgressBar
var stats_container: VBoxContainer

func _ready():
	BattleStateStore.state_changed.connect(_on_state_changed)
	_build_panel()
	_update_display()

func _build_panel():
	# Title
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title_label)

	# Spacer
	add_child(Control.new())

	# HP Label
	hp_label = Label.new()
	add_child(hp_label)

	# HP Bar
	hp_bar = ProgressBar.new()
	hp_bar.set_script(preload("res://src/ui/HealthBar.gd"))
	hp_bar.entity_name = entity_name
	hp_bar.show_percentage = false
	add_child(hp_bar)

	# Vigor Label
	vigor_label = Label.new()
	add_child(vigor_label)

	# Vigor Bar
	vigor_bar = ProgressBar.new()
	vigor_bar.set_script(preload("res://src/ui/VigorBar.gd"))
	vigor_bar.entity_name = entity_name
	vigor_bar.show_percentage = false
	add_child(vigor_bar)

	# Spacer
	add_child(Control.new())

	# Base Stats
	stats_container = VBoxContainer.new()
	add_child(stats_container)

	var stat_names = ["CON", "DEX", "STR", "INT", "SPD", "LUCK"]
	for stat_name in stat_names:
		var stat_label = Label.new()
		stat_label.name = stat_name
		stats_container.add_child(stat_label)

	# Add dodge chance label
	var dodge_label = Label.new()
	dodge_label.name = "DODGE"
	stats_container.add_child(dodge_label)

func _on_state_changed(property_path: String, _old_value, _new_value):
	# Update when any property of this entity changes
	# Handle both old format (player_state) and new format (enemies.0)
	if entity_name == "player" and property_path.begins_with("player_state."):
		_update_display()
	elif entity_name.begins_with("enemy_"):
		var index = int(entity_name.split("_")[1])
		if property_path.begins_with("enemies.%d." % index) or property_path == "enemies.%d" % index:
			_update_display()

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

	# Update title - use stored name if available, otherwise fallback to entity_name
	if entity.name != null and not entity.name.is_empty():
		title_label.text = entity.name.to_upper()
	else:
		title_label.text = entity_name.to_upper()

	# Update HP label
	hp_label.text = "HP: %d/%d" % [entity.current_hp, entity.max_hp]

	# Update Vigor label
	vigor_label.text = "Vigor: %d/%d" % [entity.current_vigor, entity.max_vigor]

	# Update base stats
	if entity.base_stats != null:
		var stat_keys = ["con", "dex", "str", "int", "spd", "luck"]
		for i in range(stat_keys.size()):
			var stat_key = stat_keys[i]
			var stat_label = stats_container.get_child(i)
			if stat_label != null and entity.base_stats.has(stat_key):
				stat_label.text = "%s: %d" % [stat_key.to_upper(), entity.base_stats[stat_key]]

		# Update dodge chance (7th child in stats_container)
		var dodge_label = stats_container.get_child(6)  # Index 6 = 7th child (after 6 stats)
		if dodge_label != null:
			dodge_label.text = "DODGE: %.1f%%" % entity.dodge_chance
