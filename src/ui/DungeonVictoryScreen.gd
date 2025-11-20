extends Control

## Dungeon victory screen shown after defeating the final boss
## Displays dungeon statistics and completion message
## Follows UI layer pattern: reactive display only, no game logic

signal main_menu_pressed()
signal continue_exploring_pressed()

var title_label: Label
var stats_container: VBoxContainer
var main_menu_button: Button
var continue_button: Button

func _ready():
	# Set anchors to fill screen (overlay)
	anchor_right = 1.0
	anchor_bottom = 1.0

	# Semi-transparent dark background
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	_build_ui()
	_update_display()

func _build_ui():
	# Center container
	var center_container = CenterContainer.new()
	center_container.anchor_right = 1.0
	center_container.anchor_bottom = 1.0
	add_child(center_container)

	# Victory panel
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 400)
	center_container.add_child(panel)

	# Main layout
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)

	# Victory title
	title_label = Label.new()
	title_label.text = "DUNGEON COMPLETE!"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.add_theme_color_override("font_color", Color(1, 0.8, 0))  # Gold color
	vbox.add_child(title_label)

	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer1)

	# Statistics section
	var stats_title = Label.new()
	stats_title.text = "Statistics"
	stats_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(stats_title)

	# Stats container
	stats_container = VBoxContainer.new()
	stats_container.add_theme_constant_override("separation", 10)
	vbox.add_child(stats_container)

	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer2)

	# Buttons container
	var button_hbox = HBoxContainer.new()
	button_hbox.add_theme_constant_override("separation", 20)
	var button_center = CenterContainer.new()
	button_center.add_child(button_hbox)
	vbox.add_child(button_center)

	# Main menu button
	main_menu_button = Button.new()
	main_menu_button.text = "Return to Menu"
	main_menu_button.custom_minimum_size = Vector2(150, 40)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	button_hbox.add_child(main_menu_button)

	# Continue exploring button
	continue_button = Button.new()
	continue_button.text = "Continue Exploring"
	continue_button.custom_minimum_size = Vector2(150, 40)
	continue_button.pressed.connect(_on_continue_exploring_pressed)
	button_hbox.add_child(continue_button)

func _update_display():
	"""Update UI elements with current statistics"""
	# Clear existing stats
	for child in stats_container.get_children():
		child.queue_free()

	# Rooms cleared
	var rooms_label = Label.new()
	rooms_label.text = "Rooms Cleared: %d" % DungeonStateStore.rooms_cleared
	rooms_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rooms_label.add_theme_font_size_override("font_size", 18)
	stats_container.add_child(rooms_label)

	# Enemies defeated
	var enemies_label = Label.new()
	enemies_label.text = "Enemies Defeated: %d" % DungeonStateStore.enemies_defeated
	enemies_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemies_label.add_theme_font_size_override("font_size", 18)
	stats_container.add_child(enemies_label)

	# Current level
	var level_label = Label.new()
	level_label.text = "Final Level: %d" % PlayerStore.level
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 18)
	stats_container.add_child(level_label)

	# Current XP
	var xp_label = Label.new()
	xp_label.text = "Total XP: %d" % PlayerStore.current_xp
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_label.add_theme_font_size_override("font_size", 18)
	stats_container.add_child(xp_label)

	print("DungeonVictoryScreen: Displayed completion stats - %d rooms, %d enemies" % [DungeonStateStore.rooms_cleared, DungeonStateStore.enemies_defeated])

func _on_main_menu_pressed():
	print("DungeonVictoryScreen: Main menu button pressed")
	main_menu_pressed.emit()

func _on_continue_exploring_pressed():
	print("DungeonVictoryScreen: Continue exploring button pressed")
	continue_exploring_pressed.emit()
