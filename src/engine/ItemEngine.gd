extends Node

## Engine layer for item and equipment logic
## Validates equipment rules, calculates stat bonuses, and orchestrates item operations
## Follows 4-layer architecture: Engine -> Mutations -> Store -> UI

const ItemData = preload("res://src/resources/ItemData.gd")

func can_equip_item(item_id: String) -> Dictionary:
	"""
	Check if an item can be equipped
	Returns: { "can_equip": bool, "reason": String, "slot": String, "swap_needed": bool, "old_item": String }
	"""
	if not ItemDatabase.has_item(item_id):
		return {"can_equip": false, "reason": "Item not found", "slot": "", "swap_needed": false, "old_item": ""}

	var item = ItemDatabase.get_item(item_id)
	var slot_type = item.get_item_type_string()
	var swap_needed = false
	var old_item = ""

	match item.item_type:
		ItemData.ItemType.WEAPON:
			if PlayerStore.equipped_weapon != "":
				swap_needed = true
				old_item = PlayerStore.equipped_weapon
			return {
				"can_equip": true,
				"reason": "",
				"slot": "weapon",
				"swap_needed": swap_needed,
				"old_item": old_item
			}

		ItemData.ItemType.ARMOR:
			if PlayerStore.equipped_armor != "":
				swap_needed = true
				old_item = PlayerStore.equipped_armor
			return {
				"can_equip": true,
				"reason": "",
				"slot": "armor",
				"swap_needed": swap_needed,
				"old_item": old_item
			}

		ItemData.ItemType.ACCESSORY:
			# Ensure accessories array has 3 slots
			while PlayerStore.equipped_accessories.size() < 3:
				PlayerStore.equipped_accessories.append("")

			# Find first empty slot
			var empty_slot = -1
			for i in range(3):
				if PlayerStore.equipped_accessories[i] == "":
					empty_slot = i
					break

			if empty_slot == -1:
				# All slots full, need to swap with first slot
				return {
					"can_equip": true,
					"reason": "All accessory slots full, will swap with slot 0",
					"slot": "accessory_0",
					"swap_needed": true,
					"old_item": PlayerStore.equipped_accessories[0]
				}
			else:
				return {
					"can_equip": true,
					"reason": "",
					"slot": "accessory_%d" % empty_slot,
					"swap_needed": false,
					"old_item": ""
				}

	return {"can_equip": false, "reason": "Unknown item type", "slot": "", "swap_needed": false, "old_item": ""}

func equip_item(item_id: String) -> bool:
	"""
	Equip an item from inventory, automatically detecting slot and handling swaps
	Returns true if successful, false otherwise
	"""
	# Check if item is in inventory
	if not item_id in PlayerStore.inventory:
		push_warning("ItemEngine: Cannot equip '%s' - not in inventory" % item_id)
		return false

	var check = can_equip_item(item_id)

	if not check.can_equip:
		push_warning("ItemEngine: Cannot equip '%s' - %s" % [item_id, check.reason])
		return false

	var item = ItemDatabase.get_item(item_id)

	# Remove from inventory
	InventoryMutations.remove_item_from_inventory(item_id)

	# If swapping, return old item to inventory
	if check.swap_needed and check.old_item != "":
		InventoryMutations.add_item_to_inventory(check.old_item)

	# Equip in appropriate slot
	match item.item_type:
		ItemData.ItemType.WEAPON:
			InventoryMutations.equip_weapon(item_id)

		ItemData.ItemType.ARMOR:
			InventoryMutations.equip_armor(item_id)

		ItemData.ItemType.ACCESSORY:
			# Extract slot index from slot string (e.g., "accessory_0" -> 0)
			var slot_parts = check.slot.split("_")
			var slot_index = int(slot_parts[1]) if slot_parts.size() > 1 else 0
			InventoryMutations.equip_accessory(item_id, slot_index)

	print("ItemEngine: Successfully equipped '%s' in slot '%s'" % [item_id, check.slot])
	return true

func unequip_item_by_slot(slot: String) -> bool:
	"""
	Unequip an item from a specific slot and return it to inventory
	Slot can be: "weapon", "armor", "accessory_0", "accessory_1", "accessory_2"
	Returns true if successful, false otherwise
	"""
	var item_id = ""

	if slot == "weapon":
		item_id = PlayerStore.equipped_weapon
		if item_id == "":
			push_warning("ItemEngine: No weapon equipped to unequip")
			return false
		InventoryMutations.unequip_weapon()

	elif slot == "armor":
		item_id = PlayerStore.equipped_armor
		if item_id == "":
			push_warning("ItemEngine: No armor equipped to unequip")
			return false
		InventoryMutations.unequip_armor()

	elif slot.begins_with("accessory_"):
		var slot_parts = slot.split("_")
		var slot_index = int(slot_parts[1]) if slot_parts.size() > 1 else 0

		if PlayerStore.equipped_accessories.size() <= slot_index:
			push_warning("ItemEngine: No accessory in slot %d" % slot_index)
			return false

		item_id = PlayerStore.equipped_accessories[slot_index]
		if item_id == "":
			push_warning("ItemEngine: No accessory equipped in slot %d" % slot_index)
			return false

		InventoryMutations.unequip_accessory(slot_index)

	else:
		push_error("ItemEngine: Invalid slot '%s'" % slot)
		return false

	# Add back to inventory
	InventoryMutations.add_item_to_inventory(item_id)

	print("ItemEngine: Successfully unequipped '%s' from slot '%s'" % [item_id, slot])
	return true

func get_equipped_stat_bonuses() -> Dictionary:
	"""
	Calculate total stat bonuses from all equipped items
	Returns dictionary with flat and percentage bonuses for all stats
	"""
	var bonuses = {
		# Flat bonuses
		"str": 0, "dex": 0, "int": 0, "con": 0, "spd": 0, "luck": 0,
		"max_hp": 0, "max_vigor": 0,
		# Percentage bonuses
		"percent_str": 0, "percent_dex": 0, "percent_int": 0,
		"percent_con": 0, "percent_spd": 0, "percent_luck": 0,
		"percent_max_hp": 0, "percent_max_vigor": 0
	}

	# Weapon bonuses
	if PlayerStore.equipped_weapon != "" and ItemDatabase.has_item(PlayerStore.equipped_weapon):
		var weapon = ItemDatabase.get_item(PlayerStore.equipped_weapon)
		_add_item_bonuses_to_total(weapon, bonuses)

	# Armor bonuses
	if PlayerStore.equipped_armor != "" and ItemDatabase.has_item(PlayerStore.equipped_armor):
		var armor = ItemDatabase.get_item(PlayerStore.equipped_armor)
		_add_item_bonuses_to_total(armor, bonuses)

	# Accessory bonuses
	for accessory_id in PlayerStore.equipped_accessories:
		if accessory_id != "" and ItemDatabase.has_item(accessory_id):
			var accessory = ItemDatabase.get_item(accessory_id)
			_add_item_bonuses_to_total(accessory, bonuses)

	return bonuses

func calculate_total_stats() -> Dictionary:
	"""
	Calculate player's final stats including base stats + equipment bonuses
	Returns dictionary with all stat values after applying equipment
	"""
	var equipment_bonuses = get_equipped_stat_bonuses()
	var final_stats = {}

	# Calculate each stat: base + flat_bonus + (base * percent_bonus / 100)
	for stat in ["str", "dex", "int", "con", "spd", "luck"]:
		var base_value = PlayerStore.base_stats.get(stat, 10)
		var flat_bonus = equipment_bonuses.get(stat, 0)
		var percent_bonus = equipment_bonuses.get("percent_" + stat, 0)

		var percent_amount = int(base_value * percent_bonus / 100.0)
		final_stats[stat] = base_value + flat_bonus + percent_amount

	# Calculate max HP: base (100 + con * 5) + flat_bonus + percent_bonus
	var base_max_hp = 100 + (final_stats["con"] * 5)
	var hp_flat = equipment_bonuses.get("max_hp", 0)
	var hp_percent = equipment_bonuses.get("percent_max_hp", 0)
	var hp_percent_amount = int(base_max_hp * hp_percent / 100.0)
	final_stats["max_hp"] = base_max_hp + hp_flat + hp_percent_amount

	# Calculate max vigor: base (2 + level/5) + flat_bonus + percent_bonus
	var base_max_vigor = PlayerStore.get_max_vigor_for_level()
	var vigor_flat = equipment_bonuses.get("max_vigor", 0)
	var vigor_percent = equipment_bonuses.get("percent_max_vigor", 0)
	var vigor_percent_amount = int(base_max_vigor * vigor_percent / 100.0)
	final_stats["max_vigor"] = base_max_vigor + vigor_flat + vigor_percent_amount

	return final_stats

func _add_item_bonuses_to_total(item: ItemData, bonuses: Dictionary):
	"""Helper to add an item's bonuses to the running total"""
	# Flat stat bonuses
	bonuses["str"] += item.str_bonus
	bonuses["dex"] += item.dex_bonus
	bonuses["int"] += item.int_bonus
	bonuses["con"] += item.con_bonus
	bonuses["spd"] += item.spd_bonus
	bonuses["luck"] += item.luck_bonus

	# Percentage stat bonuses
	bonuses["percent_str"] += item.percent_str_bonus
	bonuses["percent_dex"] += item.percent_dex_bonus
	bonuses["percent_int"] += item.percent_int_bonus
	bonuses["percent_con"] += item.percent_con_bonus
	bonuses["percent_spd"] += item.percent_spd_bonus
	bonuses["percent_luck"] += item.percent_luck_bonus

	# HP and Vigor bonuses
	bonuses["max_hp"] += item.max_hp_bonus
	bonuses["max_vigor"] += item.max_vigor_bonus
	bonuses["percent_max_hp"] += item.percent_max_hp_bonus
	bonuses["percent_max_vigor"] += item.percent_max_vigor_bonus

func get_all_equipped_items() -> Array[String]:
	"""Get list of all currently equipped item IDs"""
	var equipped: Array[String] = []

	if PlayerStore.equipped_weapon != "":
		equipped.append(PlayerStore.equipped_weapon)

	if PlayerStore.equipped_armor != "":
		equipped.append(PlayerStore.equipped_armor)

	for accessory_id in PlayerStore.equipped_accessories:
		if accessory_id != "":
			equipped.append(accessory_id)

	return equipped
