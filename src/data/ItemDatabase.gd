extends Node

# Static database of all item definitions
# Loads ItemData resources from res://data/items/ at startup

const ItemData = preload("res://src/resources/ItemData.gd")

# Cache of all loaded items, keyed by item_id
var _items: Dictionary = {}

func _ready():
	_load_all_items()

func _load_all_items():
	var item_dir = "res://data/items/"
	var dir = DirAccess.open(item_dir)

	if dir == null:
		push_error("ItemDatabase: Failed to open directory: %s" % item_dir)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var file_path = item_dir + file_name
			var item = load(file_path)

			if item is ItemData:
				if item.item_id == "":
					push_warning("ItemDatabase: ItemData at %s has no item_id set" % file_path)
				else:
					_items[item.item_id] = item
					print("ItemDatabase: Loaded item '%s' from %s" % [item.item_id, file_name])
			else:
				push_warning("ItemDatabase: File %s is not an ItemData resource" % file_path)

		file_name = dir.get_next()

	dir.list_dir_end()
	print("ItemDatabase: Loaded %d items" % _items.size())

# Get an item by its item_id
func get_item(item_id: String) -> ItemData:
	if not _items.has(item_id):
		push_error("ItemDatabase: Item '%s' not found" % item_id)
		return null
	return _items[item_id]

# Check if an item exists
func has_item(item_id: String) -> bool:
	return _items.has(item_id)

# Get all item IDs (useful for debugging or UI generation)
func get_all_item_ids() -> Array:
	return _items.keys()
