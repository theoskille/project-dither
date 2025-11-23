extends Control

## Floor completion screen shown after defeating a non-final floor boss
## Displays floor statistics and progression message
## Follows UI layer pattern: reactive display only, no game logic

signal descend_pressed()

var title_label: Label
var stats_container: VBoxContainer
var descend_button: Button
var _completed_floor: int = 1
var _total_floors: int = 1

func _init(completed_floor: int, total_floors: int):
	_completed_floor = completed_floor
	_total_floors = total_floors

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

	# Floor complete title
	title_label = Label.new()
	title_label.text = "FLOOR %d COMPLETE!" % _completed_floor
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))  # Blue color
	vbox.add_child(title_label)

	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer1)

	# Statistics section
	var stats_title = Label.new()
	stats_title.text = "Floor Statistics"
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

	# Progress message
	var progress_label = Label.new()
	progress_label.text = "Prepare to descend deeper into the dungeon..."
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 16)
	progress_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(progress_label)

	# Spacer
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer3)

	# Descend button (centered)
	var button_center = CenterContainer.new()
	vbox.add_child(button_center)

	descend_button = Button.new()
	descend_button.text = "Descend to Floor %d" % (_completed_floor + 1)
	descend_button.custom_minimum_size = Vector2(200, 50)
	descend_button.add_theme_font_size_override("font_size", 20)
	descend_button.pressed.connect(_on_descend_pressed)
	button_center.add_child(descend_button)

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
	level_label.text = "Current Level: %d" % PlayerStore.level
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 18)
	stats_container.add_child(level_label)

	# Current HP (calculate max HP from base stats + equipment)
	var hp_label = Label.new()
	var base_max_hp = 100 + (PlayerStore.base_stats.get("con", 10) * 5)
	var total_stats = ItemEngine.calculate_total_stats()
	var max_hp = total_stats.get("max_hp", base_max_hp)
	hp_label.text = "Current HP: %d / %d" % [PlayerStore.current_hp, max_hp]
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.add_theme_font_size_override("font_size", 18)
	stats_container.add_child(hp_label)

	print("FloorCompleteScreen: Displayed floor %d/%d stats - %d rooms, %d enemies" % [_completed_floor, _total_floors, DungeonStateStore.rooms_cleared, DungeonStateStore.enemies_defeated])

func _on_descend_pressed():
	print("FloorCompleteScreen: Descend button pressed (floor %d → %d)" % [_completed_floor, _completed_floor + 1])
	descend_pressed.emit()
