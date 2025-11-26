extends VBoxContainer

signal direction_selected(direction: int)
signal cancelled

func _ready():
	_build_ui()

func _build_ui():
	# Title
	var title = Label.new()
	title.text = "Select Direction"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	add_child(spacer)

	# Forward button
	var forward_button = Button.new()
	forward_button.text = "Forward (Right)"
	forward_button.pressed.connect(_on_forward_pressed)
	add_child(forward_button)

	# Backward button
	var backward_button = Button.new()
	backward_button.text = "Backward (Left)"
	backward_button.pressed.connect(_on_backward_pressed)
	add_child(backward_button)

	# Spacer
	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 10)
	add_child(bottom_spacer)

	# Cancel button
	var cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(_on_cancel_pressed)
	add_child(cancel_button)

func _on_forward_pressed():
	direction_selected.emit(1)

func _on_backward_pressed():
	direction_selected.emit(-1)

func _on_cancel_pressed():
	cancelled.emit()
