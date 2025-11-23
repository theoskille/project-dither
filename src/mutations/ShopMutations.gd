extends Node

## Shop-specific mutation functions
## Modifies PlayerStore scrap and DungeonStateStore shop tracking
## Pure state modification - no game logic

func add_scrap(amount: int):
	"""Add scrap currency to the player"""
	var old_scrap = PlayerStore.scrap
	PlayerStore.scrap += amount
	PlayerStore._emit_change("scrap", old_scrap, PlayerStore.scrap)
	PlayerStore.scrap_changed.emit(old_scrap, PlayerStore.scrap)
	print("ShopMutations: Added %d scrap (total: %d)" % [amount, PlayerStore.scrap])

func deduct_scrap(amount: int):
	"""Remove scrap currency from the player"""
	var old_scrap = PlayerStore.scrap
	PlayerStore.scrap -= amount
	PlayerStore._emit_change("scrap", old_scrap, PlayerStore.scrap)
	PlayerStore.scrap_changed.emit(old_scrap, PlayerStore.scrap)
	print("ShopMutations: Deducted %d scrap (total: %d)" % [amount, PlayerStore.scrap])

func mark_shop_visited(room_id: String):
	"""Mark a shop as visited in the current dungeon"""
	if room_id in DungeonStateStore.visited_shops:
		push_warning("ShopMutations: Shop at room '%s' already marked as visited" % room_id)
		return

	var old_visited = DungeonStateStore.visited_shops.duplicate()
	DungeonStateStore.visited_shops.append(room_id)
	DungeonStateStore._emit_change("visited_shops", old_visited, DungeonStateStore.visited_shops)
	print("ShopMutations: Marked shop at room '%s' as visited" % room_id)
