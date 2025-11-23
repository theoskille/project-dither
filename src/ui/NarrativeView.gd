extends Control

## Narrative view UI
## Displays narrative text and choice options
## Reactive component that responds to NarrativeEngine signals

signal narrative_view_exited()

var _narrative_data: NarrativeData = null

# UI references
var _dialogue_label: Label = null
var _choices_container: VBoxContainer = null

func initialize_narrative(narrative_id: String):
	"""Initialize narrative view with specific narrative BEFORE _ready() is called"""
	if not EncounterDatabase.has_narrative(narrative_id):
		push_error("NarrativeView: Narrative '%s' not found" % narrative_id)
		return

	_narrative_data = EncounterDatabase.get_narrative(narrative_id)
	print("NarrativeView: Initialized with narrative '%s'" % narrative_id)

func _ready():
	# Set anchors to fill the screen
	anchor_right = 1.0
	anchor_bottom = 1.0

	_build_ui()
	_connect_signals()
	_update_display()

func _build_ui():
	# Root margin container
	var margin = MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)

	# Main vertical layout
	var main_vbox = VBoxContainer.new()
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 30)
	margin.add_child(main_vbox)

	# === TITLE ===
	var title = Label.new()
	title.text = "NARRATIVE ENCOUNTER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.custom_minimum_size = Vector2(0, 48)
	main_vbox.add_child(title)

	# === NARRATIVE TEXT PANEL ===
	var text_panel = PanelContainer.new()
	text_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_panel.custom_minimum_size = Vector2(0, 200)
	main_vbox.add_child(text_panel)

	var text_margin = MarginContainer.new()
	text_margin.add_theme_constant_override("margin_left", 20)
	text_margin.add_theme_constant_override("margin_right", 20)
	text_margin.add_theme_constant_override("margin_top", 20)
	text_margin.add_theme_constant_override("margin_bottom", 20)
	text_panel.add_child(text_margin)

	var text_scroll = ScrollContainer.new()
	text_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_margin.add_child(text_scroll)

	_dialogue_label = Label.new()
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_label.add_theme_font_size_override("font_size", 16)
	_dialogue_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_scroll.add_child(_dialogue_label)

	# === CHOICES PANEL ===
	var choices_panel = PanelContainer.new()
	choices_panel.custom_minimum_size = Vector2(0, 150)
	main_vbox.add_child(choices_panel)

	var choices_margin = MarginContainer.new()
	choices_margin.add_theme_constant_override("margin_left", 20)
	choices_margin.add_theme_constant_override("margin_right", 20)
	choices_margin.add_theme_constant_override("margin_top", 20)
	choices_margin.add_theme_constant_override("margin_bottom", 20)
	choices_panel.add_child(choices_margin)

	_choices_container = VBoxContainer.new()
	_choices_container.add_theme_constant_override("separation", 10)
	choices_margin.add_child(_choices_container)

func _connect_signals():
	"""Connect to NarrativeEngine signals"""
	NarrativeEngine.narrative_started.connect(_on_narrative_started)
	NarrativeEngine.narrative_completed.connect(_on_narrative_completed)
	NarrativeEngine.combat_triggered_from_narrative.connect(_on_combat_triggered)

func _update_display():
	"""Update the narrative text and choices based on current narrative data"""
	if _narrative_data == null:
		push_warning("NarrativeView: No narrative data to display")
		return

	# Update dialogue text
	_dialogue_label.text = _narrative_data.dialogue_text

	# Clear existing choice buttons
	for child in _choices_container.get_children():
		child.queue_free()

	# Create choice buttons
	for i in range(_narrative_data.choices.size()):
		var choice = _narrative_data.choices[i]
		var choice_button = Button.new()
		choice_button.text = choice.get("text", "Choice %d" % (i + 1))
		choice_button.custom_minimum_size = Vector2(0, 50)
		choice_button.add_theme_font_size_override("font_size", 16)

		# Connect button to choice handler with index
		choice_button.pressed.connect(_on_choice_pressed.bind(i))

		_choices_container.add_child(choice_button)

	print("NarrativeView: Displayed narrative '%s' with %d choices" % [_narrative_data.narrative_id, _narrative_data.choices.size()])

func _on_choice_pressed(choice_index: int):
	"""Handle choice button press - send to engine"""
	print("NarrativeView: Choice %d selected" % choice_index)
	NarrativeEngine.make_choice(choice_index)

func _on_narrative_started(narrative_id: String):
	"""Handle narrative change (for chaining narratives)"""
	print("NarrativeView: Loading new narrative '%s'" % narrative_id)
	_narrative_data = EncounterDatabase.get_narrative(narrative_id)
	_update_display()

func _on_narrative_completed():
	"""Handle narrative completion - return to dungeon"""
	print("NarrativeView: Narrative completed, exiting view")
	narrative_view_exited.emit()

func _on_combat_triggered(encounter_id: String):
	"""Handle combat being triggered from narrative - will be handled by Main.gd"""
	print("NarrativeView: Combat triggered, encounter '%s'" % encounter_id)
	# Don't emit narrative_view_exited - let Main handle the transition
