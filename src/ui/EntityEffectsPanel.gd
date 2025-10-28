extends VBoxContainer

@export var entity_name: String = "player"

var title_label: Label
var effects_container: VBoxContainer

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

	# Effects container (dynamically populated)
	effects_container = VBoxContainer.new()
	add_child(effects_container)

func _on_state_changed(property_path: String, _old_value, _new_value):
	# Only update when active_effects changes for this entity
	if property_path == "%s_state.active_effects" % entity_name:
		_update_display()

func _update_display():
	# Clear existing effect displays
	for child in effects_container.get_children():
		child.queue_free()

	# Update title
	var stored_name = BattleStateStore.get_state_value("%s_state.name" % entity_name)
	if stored_name != null and not stored_name.is_empty():
		title_label.text = "EFFECTS (%s)" % stored_name.to_upper()
	else:
		title_label.text = "EFFECTS (%s)" % entity_name.to_upper()

	# Get active effects
	var active_effects = BattleStateStore.get_state_value("%s_state.active_effects" % entity_name)

	if active_effects.is_empty():
		var no_effects_label = Label.new()
		no_effects_label.text = "(No active effects)"
		no_effects_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		effects_container.add_child(no_effects_label)
	else:
		for effect in active_effects:
			_add_effect_display(effect)

func _add_effect_display(effect: EffectState):
	# Get effect template for display name
	var effect_template = EffectDatabase.get_effect(effect.effect_id)
	var effect_name = effect_template.effect_name if effect_template else effect.effect_id

	# Effect name + duration label
	var name_label = Label.new()
	name_label.text = "%s (%d)" % [effect_name, effect.remaining_duration]
	effects_container.add_child(name_label)

	# Effect details label
	var details = _format_effect_details(effect)
	if not details.is_empty():
		var details_label = Label.new()
		details_label.text = "  " + details  # Indent with spaces
		details_label.add_theme_font_size_override("font_size", 11)
		effects_container.add_child(details_label)

func _format_effect_details(effect: EffectState) -> String:
	var parts = []

	# Damage over time
	if effect.damage_per_turn > 0:
		parts.append("-%d HP/turn" % effect.damage_per_turn)

	# Stat modifiers (flat and percent)
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

	# Action blocking
	if effect.blocks_all_actions:
		parts.append("Cannot act")
	elif not effect.blocks_action_types.is_empty():
		parts.append("Blocks: " + ", ".join(effect.blocks_action_types))

	return ", ".join(parts)
