extends PanelContainer

# Horizontal battlefield display spanning upper half of screen

@onready var position_labels = []
@onready var position_containers = []
var main_container: VBoxContainer
var positions_container: HBoxContainer
var tile_texture: Texture2D

func _ready():
	# Load tile texture
	tile_texture = load("res://assets/tiles/dungeon_tile_iso_128.png")

	BattleStateStore.state_changed.connect(_on_state_changed)
	_build_battlefield()
	_setup_position_tiles()
	_update_display()

func _build_battlefield():
	# Set minimum size for horizontal full-width display
	custom_minimum_size = Vector2(800, 180)

	# Main vertical container for title + positions (title at top, tiles centered below)
	main_container = VBoxContainer.new()
	main_container.add_theme_constant_override("separation", 16)
	add_child(main_container)

	# Add title at top
	var title = Label.new()
	title.text = "BATTLEFIELD"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	main_container.add_child(title)

	# Create a center container for tiles (expands to fill remaining space and centers vertically)
	var tiles_center_container = CenterContainer.new()
	tiles_center_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.add_child(tiles_center_container)

	# Create horizontal container for position tiles
	positions_container = HBoxContainer.new()
	positions_container.add_theme_constant_override("separation", 12)
	positions_container.alignment = BoxContainer.ALIGNMENT_CENTER
	tiles_center_container.add_child(positions_container)

func _on_state_changed(property_path: String, _old_value, _new_value):
	# Update display when any entity position changes or when enemies array changes
	if property_path.contains("position") or property_path.contains("enemies"):
		_update_display()

func _setup_position_tiles():
	var total_tiles = BattleStateStore.get_state_value("battlefield.total_tiles")
	for i in range(total_tiles):
		# Create VBoxContainer for each position (label on top, tile below)
		var position_vbox = VBoxContainer.new()
		position_vbox.add_theme_constant_override("separation", 4)
		position_vbox.alignment = BoxContainer.ALIGNMENT_CENTER

		# Create entity indicator label (positioned above tile)
		var label = Label.new()
		label.text = ""
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 20)
		label.custom_minimum_size = Vector2(96, 30)
		position_vbox.add_child(label)
		position_labels.append(label)

		# Create tile sprite
		var tile_sprite = TextureRect.new()
		tile_sprite.texture = tile_texture
		tile_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tile_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tile_sprite.custom_minimum_size = Vector2(96, 96)  # Larger tiles
		position_vbox.add_child(tile_sprite)

		positions_container.add_child(position_vbox)
		position_containers.append(position_vbox)

func _update_display():
	# Clear all positions
	for i in range(position_labels.size()):
		position_labels[i].text = ""

	# Show player
	var player_pos = BattleStateStore.get_state_value("player_state.position")
	if player_pos >= 0 and player_pos < position_labels.size():
		position_labels[player_pos].text = "P"

	# Show all enemies
	var enemies = BattleStateStore.battle_state.enemies
	for i in range(enemies.size()):
		var enemy_pos = enemies[i].position
		if enemy_pos >= 0 and enemy_pos < position_labels.size():
			# If multiple enemies on same tile, show count or concatenate
			if position_labels[enemy_pos].text == "":
				position_labels[enemy_pos].text = "E%d" % i
			elif position_labels[enemy_pos].text.begins_with("E"):
				# Multiple enemies on same tile - show as E0,E1
				position_labels[enemy_pos].text = "%s,E%d" % [position_labels[enemy_pos].text, i]
			elif position_labels[enemy_pos].text == "P":
				# Player and enemy on same tile
				position_labels[enemy_pos].text = "P,E%d" % i