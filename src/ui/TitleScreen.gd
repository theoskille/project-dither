extends Control

## Title screen - first screen shown when game starts
## Displays game title and Start button

signal start_clicked()
signal dev_mode_clicked()

func _ready():
	# Set up full screen coverage
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Create main container
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 50)
	margin.add_theme_constant_override("margin_right", 50)
	margin.add_theme_constant_override("margin_top", 50)
	margin.add_theme_constant_override("margin_bottom", 50)
	add_child(margin)

	# Create vertical layout
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 40)
	margin.add_child(vbox)

	# Add spacer to push content to center
	var top_spacer = Control.new()
	top_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(top_spacer)

	# Title label
	var title = Label.new()
	title.text = "Project Dither"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	vbox.add_child(title)

	# Start button
	var start_button = Button.new()
	start_button.text = "Start"
	start_button.custom_minimum_size = Vector2(200, 60)
	start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_button.pressed.connect(_on_start_pressed)
	vbox.add_child(start_button)

	# Dev Mode button
	var dev_mode_button = Button.new()
	dev_mode_button.text = "Dev Mode"
	dev_mode_button.custom_minimum_size = Vector2(200, 60)
	dev_mode_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dev_mode_button.pressed.connect(_on_dev_mode_pressed)
	vbox.add_child(dev_mode_button)

	# Add spacer to push content to center
	var bottom_spacer = Control.new()
	bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(bottom_spacer)

func _on_start_pressed():
	start_clicked.emit()

func _on_dev_mode_pressed():
	dev_mode_clicked.emit()
