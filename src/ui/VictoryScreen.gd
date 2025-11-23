extends Control

## Victory screen overlay shown after combat ends
## Displays XP gained, level progress, and level-up notifications
## Follows UI layer pattern: reactive display only, no game logic

signal continue_pressed()

var xp_label: Label
var scrap_label: Label
var level_label: Label
var xp_progress_label: Label
var level_up_label: Label
var xp_progress_bar: ProgressBar
var continue_button: Button

var _total_xp_gained: int = 0
var _total_scrap_gained: int = 0
var _levels_gained: int = 0

func _ready():
	# Set anchors to fill screen (overlay)
	anchor_right = 1.0
	anchor_bottom = 1.0

	# Semi-transparent dark background
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	_build_ui()

	# Update display with initialized data (if set before _ready)
	if _total_xp_gained > 0 or _total_scrap_gained > 0 or _levels_gained > 0:
		_update_display()

func _build_ui():
	# Center container
	var center_container = CenterContainer.new()
	center_container.anchor_right = 1.0
	center_container.anchor_bottom = 1.0
	add_child(center_container)

	# Victory panel
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 300)
	center_container.add_child(panel)

	# Main layout
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)

	# Victory title
	var title = Label.new()
	title.text = "VICTORY!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title)

	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer1)

	# XP gained label
	xp_label = Label.new()
	xp_label.text = "+0 XP Gained"
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(xp_label)

	# Scrap gained label
	scrap_label = Label.new()
	scrap_label.text = "+0 Scrap"
	scrap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scrap_label.add_theme_font_size_override("font_size", 18)
	scrap_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.5))  # Slightly golden
	vbox.add_child(scrap_label)

	# Level display
	level_label = Label.new()
	level_label.text = "Level 1"
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(level_label)

	# XP Progress bar
	var progress_container = MarginContainer.new()
	progress_container.add_theme_constant_override("margin_left", 40)
	progress_container.add_theme_constant_override("margin_right", 40)
	vbox.add_child(progress_container)

	xp_progress_bar = ProgressBar.new()
	xp_progress_bar.custom_minimum_size = Vector2(0, 30)
	xp_progress_bar.max_value = 100
	xp_progress_bar.value = 0
	xp_progress_bar.show_percentage = false
	progress_container.add_child(xp_progress_bar)

	# XP progress text (below bar)
	xp_progress_label = Label.new()
	xp_progress_label.text = "0 / 100 XP to next level"
	xp_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(xp_progress_label)

	# Level up notification (hidden by default)
	level_up_label = Label.new()
	level_up_label.text = "LEVEL UP!"
	level_up_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_up_label.add_theme_font_size_override("font_size", 24)
	level_up_label.add_theme_color_override("font_color", Color(1, 0.8, 0))  # Gold color
	level_up_label.visible = false
	vbox.add_child(level_up_label)

	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer2)

	# Continue button
	continue_button = Button.new()
	continue_button.text = "Continue"
	continue_button.custom_minimum_size = Vector2(150, 40)
	continue_button.pressed.connect(_on_continue_pressed)

	var button_container = CenterContainer.new()
	button_container.add_child(continue_button)
	vbox.add_child(button_container)

func initialize(total_xp: int, total_scrap: int, levels_gained: int):
	"""Initialize the victory screen with XP and scrap data before adding to tree"""
	_total_xp_gained = total_xp
	_total_scrap_gained = total_scrap
	_levels_gained = levels_gained

func _update_display():
	"""Update UI elements with current XP and scrap data"""

	# Update XP gained label
	xp_label.text = "+%d XP Gained" % _total_xp_gained

	# Update scrap gained label
	scrap_label.text = "+%d Scrap" % _total_scrap_gained

	# Update level display
	var current_level = PlayerStore.level
	level_label.text = "Level %d" % current_level

	# Calculate XP progress
	var current_xp = PlayerStore.current_xp
	var xp_for_next_level = _calculate_xp_for_next_level()
	var progress_percent = (float(current_xp) / float(xp_for_next_level)) * 100.0

	# Update progress bar
	xp_progress_bar.value = progress_percent

	# Update progress text
	xp_progress_label.text = "%d / %d XP to next level" % [current_xp, xp_for_next_level]

	# Show level up notification if player leveled up
	if _levels_gained > 0:
		level_up_label.visible = true
		if _levels_gained == 1:
			level_up_label.text = "LEVEL UP!"
		else:
			level_up_label.text = "LEVEL UP x%d!" % _levels_gained

	print("VictoryScreen: Displayed victory - %d XP, %d levels gained" % [_total_xp_gained, _levels_gained])

func _calculate_xp_for_next_level() -> int:
	"""Calculate XP needed for next level (engine logic mirrored for display)"""
	return 20 * (PlayerStore.level + 1)

func _on_continue_pressed():
	print("VictoryScreen: Continue button pressed")
	continue_pressed.emit()
