extends PanelContainer

# Horizontal battlefield display spanning upper half of screen

@onready var position_labels = []  # For player text
@onready var position_sprite_containers = []  # For enemy sprites
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
	add_child(main_container)

	# Add title at top
	var title = Label.new()
	title.text = "BATTLEFIELD"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(title)

	# Create a center container for tiles (expands to fill remaining space and centers vertically)
	var tiles_center_container = CenterContainer.new()
	tiles_center_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.add_child(tiles_center_container)

	# Create horizontal container for position tiles
	positions_container = HBoxContainer.new()
	positions_container.alignment = BoxContainer.ALIGNMENT_CENTER
	tiles_center_container.add_child(positions_container)

func _on_state_changed(property_path: String, _old_value, _new_value):
	# Update display when any entity position changes or when enemies array changes
	if property_path.contains("position") or property_path.contains("enemies"):
		_update_display()

func _setup_position_tiles():
	var total_tiles = BattleStateStore.get_state_value("battlefield.total_tiles")
	for i in range(total_tiles):
		# Create VBoxContainer for each position (sprites/label on top, tile below)
		var position_vbox = VBoxContainer.new()
		position_vbox.alignment = BoxContainer.ALIGNMENT_CENTER

		# Create container for entity sprites/labels (positioned above tile)
		var entity_container = Control.new()
		entity_container.custom_minimum_size = Vector2(96, 96)
		position_vbox.add_child(entity_container)
		position_sprite_containers.append(entity_container)

		# Create player label (will be shown when player is on this tile)
		var label = Label.new()
		label.text = ""
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(96, 20)
		label.position = Vector2(0, 0)
		entity_container.add_child(label)
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

	# Clear all enemy sprites
	for container in position_sprite_containers:
		# Remove all children except the player label (which is always first child)
		for child in container.get_children():
			if child is TextureRect:
				child.queue_free()

	# Show player
	var player_pos = BattleStateStore.get_state_value("player_state.position")
	if player_pos >= 0 and player_pos < position_labels.size():
		position_labels[player_pos].text = "P"

	# Show all living enemies as sprites
	var enemies = BattleStateStore.battle_state.enemies
	for i in range(enemies.size()):
		var enemy = enemies[i]

		# Skip dead enemies
		if enemy.is_dead:
			continue

		var enemy_pos = enemy.position
		if enemy_pos >= 0 and enemy_pos < position_sprite_containers.size():
			# Create sprite for this enemy
			var sprite = TextureRect.new()

			# Load the sprite texture
			if enemy.sprite_path != "" and ResourceLoader.exists(enemy.sprite_path):
				sprite.texture = load(enemy.sprite_path)
			else:
				# Fallback: use default goblin sprite
				sprite.texture = load("res://assets/sprites/dungeon_creature_goblin_ears_cutout.png")

			# Configure sprite rendering
			sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			sprite.custom_minimum_size = Vector2(96, 96)

			# Position sprite in container (stack multiple enemies if needed)
			var existing_sprites = 0
			for child in position_sprite_containers[enemy_pos].get_children():
				if child is TextureRect:
					existing_sprites += 1

			# Offset multiple enemies slightly so they're visible
			sprite.position = Vector2(existing_sprites * 10, 0)

			position_sprite_containers[enemy_pos].add_child(sprite)