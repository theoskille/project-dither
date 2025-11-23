extends Node

## Engine layer for shop logic
## Validates purchases, generates shop inventory, and orchestrates shop operations
## Follows 4-layer architecture: Engine -> Mutations -> Store -> UI

signal shop_closed

const ItemData = preload("res://src/resources/ItemData.gd")
const MAX_INVENTORY_SIZE = 20  # Configurable inventory limit

func has_visited_shop(room_id: String) -> bool:
	"""Check if a shop in the given room has been visited"""
	return room_id in DungeonStateStore.visited_shops

func mark_shop_as_visited(room_id: String):
	"""Mark a shop as visited - orchestrates the mutation"""
	ShopMutations.mark_shop_visited(room_id)

func generate_shop_inventory() -> Array[String]:
	"""
	Generate 3 random items from the entire item pool
	Returns: Array of item IDs
	"""
	var all_item_ids = ItemDatabase.get_all_item_ids()

	if all_item_ids.size() == 0:
		push_error("ShopEngine: No items found in ItemDatabase")
		return []

	# Shuffle and pick first 3
	all_item_ids.shuffle()
	var shop_items: Array[String] = []
	var count = min(3, all_item_ids.size())

	for i in range(count):
		shop_items.append(all_item_ids[i])

	print("ShopEngine: Generated shop inventory: %s" % shop_items)
	return shop_items

func can_purchase(item_id: String) -> Dictionary:
	"""
	Check if an item can be purchased
	Returns: { "can_purchase": bool, "reason": String }
	"""
	# Check if item exists
	if not ItemDatabase.has_item(item_id):
		return {"can_purchase": false, "reason": "Item not found"}

	var item = ItemDatabase.get_item(item_id)

	# Check if player has enough scrap
	if PlayerStore.scrap < item.shop_price:
		var shortage = item.shop_price - PlayerStore.scrap
		return {
			"can_purchase": false,
			"reason": "Need %d more scrap" % shortage
		}

	# Check if inventory is full
	if PlayerStore.inventory.size() >= MAX_INVENTORY_SIZE:
		return {
			"can_purchase": false,
			"reason": "Inventory full (%d/%d)" % [PlayerStore.inventory.size(), MAX_INVENTORY_SIZE]
		}

	return {"can_purchase": true, "reason": ""}

func purchase_item(item_id: String) -> bool:
	"""
	Purchase an item from the shop
	Orchestrates scrap deduction and inventory addition
	Returns true if successful, false otherwise
	"""
	var check = can_purchase(item_id)

	if not check.can_purchase:
		push_warning("ShopEngine: Cannot purchase '%s' - %s" % [item_id, check.reason])
		return false

	var item = ItemDatabase.get_item(item_id)

	# Deduct scrap
	ShopMutations.deduct_scrap(item.shop_price)

	# Add to inventory
	InventoryMutations.add_item_to_inventory(item_id)

	print("ShopEngine: Purchased '%s' for %d scrap" % [item_id, item.shop_price])
	return true

func close_shop():
	"""Signal that the shop should be closed"""
	shop_closed.emit()
	print("ShopEngine: Shop closed")
