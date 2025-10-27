extends Node

# Static database of all enemy definitions
# Loads EnemyData resources from res://data/enemies/ at startup

const EnemyData = preload("res://src/resources/EnemyData.gd")

# Cache of all loaded enemies, keyed by enemy_id
var _enemies: Dictionary = {}

func _ready():
	_load_all_enemies()

func _load_all_enemies():
	var enemy_dir = "res://data/enemies/"
	var dir = DirAccess.open(enemy_dir)

	if dir == null:
		push_error("EnemyDatabase: Failed to open directory: %s" % enemy_dir)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var file_path = enemy_dir + file_name
			var enemy = load(file_path)

			if enemy is EnemyData:
				if enemy.enemy_id == "":
					push_warning("EnemyDatabase: EnemyData at %s has no enemy_id set" % file_path)
				else:
					_enemies[enemy.enemy_id] = enemy
					print("EnemyDatabase: Loaded enemy '%s' from %s" % [enemy.enemy_id, file_name])
			else:
				push_warning("EnemyDatabase: File %s is not an EnemyData resource" % file_path)

		file_name = dir.get_next()

	dir.list_dir_end()
	print("EnemyDatabase: Loaded %d enemies" % _enemies.size())

# Get an enemy by its enemy_id
func get_enemy(enemy_id: String) -> EnemyData:
	if not _enemies.has(enemy_id):
		push_error("EnemyDatabase: Enemy '%s' not found" % enemy_id)
		return null
	return _enemies[enemy_id]

# Check if an enemy exists
func has_enemy(enemy_id: String) -> bool:
	return _enemies.has(enemy_id)

# Get all enemy IDs (useful for debugging or UI generation)
func get_all_enemy_ids() -> Array:
	return _enemies.keys()
