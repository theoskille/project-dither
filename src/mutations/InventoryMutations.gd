extends Node

## Inventory-specific mutation functions
## Modifies PlayerStore inventory and equipment data and emits signals
## Pure state modification - no game logic

func add_item_to_inventory(item_id: String):
	"""Add an item to the player's inventory"""
	var old_inventory = PlayerStore.inventory.duplicate()
	PlayerStore.inventory.append(item_id)
	PlayerStore._emit_change("inventory", old_inventory, PlayerStore.inventory)
	PlayerStore.item_added.emit(item_id)
	print("InventoryMutations: Added item '%s' to inventory (total items: %d)" % [item_id, PlayerStore.inventory.size()])

func remove_item_from_inventory(item_id: String):
	"""Remove an item from the player's inventory"""
	if not item_id in PlayerStore.inventory:
		push_warning("InventoryMutations: Item '%s' is not in inventory" % item_id)
		return

	var old_inventory = PlayerStore.inventory.duplicate()
	PlayerStore.inventory.erase(item_id)
	PlayerStore._emit_change("inventory", old_inventory, PlayerStore.inventory)
	PlayerStore.item_removed.emit(item_id)
	print("InventoryMutations: Removed item '%s' from inventory (total items: %d)" % [item_id, PlayerStore.inventory.size()])

func equip_weapon(item_id: String):
	"""Equip an item in the weapon slot"""
	var old_weapon = PlayerStore.equipped_weapon
	PlayerStore.equipped_weapon = item_id
	PlayerStore._emit_change("equipped_weapon", old_weapon, item_id)
	PlayerStore.item_equipped.emit("weapon", item_id)
	print("InventoryMutations: Equipped weapon '%s'" % item_id)

func unequip_weapon():
	"""Unequip the current weapon"""
	var old_weapon = PlayerStore.equipped_weapon
	if old_weapon == "":
		push_warning("InventoryMutations: No weapon equipped to unequip")
		return

	PlayerStore.equipped_weapon = ""
	PlayerStore._emit_change("equipped_weapon", old_weapon, "")
	PlayerStore.item_unequipped.emit("weapon", old_weapon)
	print("InventoryMutations: Unequipped weapon '%s'" % old_weapon)

func equip_armor(item_id: String):
	"""Equip an item in the armor slot"""
	var old_armor = PlayerStore.equipped_armor
	PlayerStore.equipped_armor = item_id
	PlayerStore._emit_change("equipped_armor", old_armor, item_id)
	PlayerStore.item_equipped.emit("armor", item_id)
	print("InventoryMutations: Equipped armor '%s'" % item_id)

func unequip_armor():
	"""Unequip the current armor"""
	var old_armor = PlayerStore.equipped_armor
	if old_armor == "":
		push_warning("InventoryMutations: No armor equipped to unequip")
		return

	PlayerStore.equipped_armor = ""
	PlayerStore._emit_change("equipped_armor", old_armor, "")
	PlayerStore.item_unequipped.emit("armor", old_armor)
	print("InventoryMutations: Unequipped armor '%s'" % old_armor)

func equip_accessory(item_id: String, slot_index: int):
	"""Equip an item in an accessory slot (0-2)"""
	if slot_index < 0 or slot_index > 2:
		push_error("InventoryMutations: Invalid accessory slot index %d (must be 0-2)" % slot_index)
		return

	# Ensure the accessories array has 3 slots
	while PlayerStore.equipped_accessories.size() < 3:
		PlayerStore.equipped_accessories.append("")

	var old_accessories = PlayerStore.equipped_accessories.duplicate()
	var old_item = PlayerStore.equipped_accessories[slot_index]
	PlayerStore.equipped_accessories[slot_index] = item_id
	PlayerStore._emit_change("equipped_accessories", old_accessories, PlayerStore.equipped_accessories)
	PlayerStore.item_equipped.emit("accessory_%d" % slot_index, item_id)
	print("InventoryMutations: Equipped accessory '%s' in slot %d" % [item_id, slot_index])

func unequip_accessory(slot_index: int):
	"""Unequip an accessory from a specific slot (0-2)"""
	if slot_index < 0 or slot_index > 2:
		push_error("InventoryMutations: Invalid accessory slot index %d (must be 0-2)" % slot_index)
		return

	if PlayerStore.equipped_accessories.size() <= slot_index:
		push_warning("InventoryMutations: No accessory equipped in slot %d" % slot_index)
		return

	var old_item = PlayerStore.equipped_accessories[slot_index]
	if old_item == "":
		push_warning("InventoryMutations: No accessory equipped in slot %d to unequip" % slot_index)
		return

	var old_accessories = PlayerStore.equipped_accessories.duplicate()
	PlayerStore.equipped_accessories[slot_index] = ""
	PlayerStore._emit_change("equipped_accessories", old_accessories, PlayerStore.equipped_accessories)
	PlayerStore.item_unequipped.emit("accessory_%d" % slot_index, old_item)
	print("InventoryMutations: Unequipped accessory '%s' from slot %d" % [old_item, slot_index])

func clear_all_equipment():
	"""Remove all equipped items (does not return to inventory)"""
	var old_weapon = PlayerStore.equipped_weapon
	var old_armor = PlayerStore.equipped_armor
	var old_accessories = PlayerStore.equipped_accessories.duplicate()

	PlayerStore.equipped_weapon = ""
	PlayerStore.equipped_armor = ""
	PlayerStore.equipped_accessories = ["", "", ""]

	PlayerStore._emit_change("equipped_weapon", old_weapon, "")
	PlayerStore._emit_change("equipped_armor", old_armor, "")
	PlayerStore._emit_change("equipped_accessories", old_accessories, PlayerStore.equipped_accessories)

	print("InventoryMutations: Cleared all equipment")
