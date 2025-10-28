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

func _on_state_changed(property_path: String, _old_value, _new_value):
	# Update when any property of this entity changes
	if property_path.begins_with("%s_state." % entity_name):
		_update_display()

func _update_display():
	# Update title - use stored name if available, otherwise fallback to entity_name
	var stored_name = BattleStateStore.get_state_value("%s_state.name" % entity_name)
	if stored_name != null and not stored_name.is_empty():
		title_label.text = stored_name.to_upper()
	else:
		title_label.text = entity_name.to_upper()

	# Update HP label
	var current_hp = BattleStateStore.get_state_value("%s_state.current_hp" % entity_name)
	var max_hp = BattleStateStore.get_state_value("%s_state.max_hp" % entity_name)
	hp_label.text = "HP: %d/%d" % [current_hp, max_hp]

	# Update Vigor label
	var current_vigor = BattleStateStore.get_state_value("%s_state.current_vigor" % entity_name)
	var max_vigor = BattleStateStore.get_state_value("%s_state.max_vigor" % entity_name)
	vigor_label.text = "Vigor: %d/%d" % [current_vigor, max_vigor]

	# Update base stats
	var base_stats = BattleStateStore.get_state_value("%s_state.base_stats" % entity_name)
	if base_stats != null:
		var stat_keys = ["con", "dex", "str", "int", "spd", "luck"]
		for i in range(stat_keys.size()):
			var stat_key = stat_keys[i]
			var stat_label = stats_container.get_child(i)
			if stat_label != null and base_stats.has(stat_key):
				stat_label.text = "%s: %d" % [stat_key.to_upper(), base_stats[stat_key]]
