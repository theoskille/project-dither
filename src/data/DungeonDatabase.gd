extends Node

# Static database of all dungeon definitions
# Loads DungeonData resources from res://data/dungeons/ at startup

const DungeonData = preload("res://src/resources/DungeonData.gd")

# Cache of all loaded dungeons, keyed by dungeon_id
var _dungeons: Dictionary = {}

func _ready():
	_load_all_dungeons()

func _load_all_dungeons():
	var dungeon_dir = "res://data/dungeons/"
	var dir = DirAccess.open(dungeon_dir)

	if dir == null:
		push_error("DungeonDatabase: Failed to open directory: %s" % dungeon_dir)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var file_path = dungeon_dir + file_name
			var dungeon = load(file_path)

			if dungeon is DungeonData:
				if dungeon.dungeon_id == "":
					push_warning("DungeonDatabase: DungeonData at %s has no dungeon_id set" % file_path)
				else:
					_dungeons[dungeon.dungeon_id] = dungeon
					print("DungeonDatabase: Loaded dungeon '%s' from %s" % [dungeon.dungeon_id, file_name])
			else:
				push_warning("DungeonDatabase: File %s is not a DungeonData resource" % file_path)

		file_name = dir.get_next()

	dir.list_dir_end()
	print("DungeonDatabase: Loaded %d dungeons" % _dungeons.size())

# Get a dungeon by its dungeon_id
func get_dungeon(dungeon_id: String) -> DungeonData:
	if not _dungeons.has(dungeon_id):
		push_error("DungeonDatabase: Dungeon '%s' not found" % dungeon_id)
		return null
	return _dungeons[dungeon_id]

# Check if a dungeon exists
func has_dungeon(dungeon_id: String) -> bool:
	return _dungeons.has(dungeon_id)

# Get all dungeon IDs (useful for debugging or UI generation)
func get_all_dungeon_ids() -> Array:
	return _dungeons.keys()
