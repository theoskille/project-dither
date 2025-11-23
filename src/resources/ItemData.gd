extends Resource
class_name ItemData

# Unique identifier for this item
@export var item_id: String = ""

# Display information
@export var item_name: String = ""
@export_multiline var description: String = ""

# Item type determines which slot it can be equipped in
enum ItemType {
	WEAPON,
	ARMOR,
	ACCESSORY
}
@export var item_type: ItemType = ItemType.ACCESSORY

# Rarity affects visuals and gameplay value
enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	LEGENDARY
}
@export var rarity: Rarity = Rarity.COMMON

# Visual representation
@export var sprite_path: String = ""

# Shop system
@export var shop_price: int = 50

# Flat stat bonuses (added directly to stats)
@export_group("Flat Stat Bonuses")
@export var str_bonus: int = 0
@export var dex_bonus: int = 0
@export var int_bonus: int = 0
@export var con_bonus: int = 0
@export var spd_bonus: int = 0
@export var luck_bonus: int = 0

# Percentage stat bonuses (multiplied by base stat value)
@export_group("Percentage Stat Bonuses")
@export_range(0, 100) var percent_str_bonus: int = 0
@export_range(0, 100) var percent_dex_bonus: int = 0
@export_range(0, 100) var percent_int_bonus: int = 0
@export_range(0, 100) var percent_con_bonus: int = 0
@export_range(0, 100) var percent_spd_bonus: int = 0
@export_range(0, 100) var percent_luck_bonus: int = 0

# HP and Vigor bonuses
@export_group("HP and Vigor Bonuses")
@export var max_hp_bonus: int = 0
@export var max_vigor_bonus: int = 0
@export_range(0, 100) var percent_max_hp_bonus: int = 0
@export_range(0, 100) var percent_max_vigor_bonus: int = 0

# Validation
func _validate_property(property: Dictionary) -> void:
	if property.name == "item_id":
		if item_id.is_empty():
			push_warning("ItemData: item_id should not be empty")

# Helper to get item type as string for slot matching
func get_item_type_string() -> String:
	match item_type:
		ItemType.WEAPON:
			return "weapon"
		ItemType.ARMOR:
			return "armor"
		ItemType.ACCESSORY:
			return "accessory"
	return ""

# Helper to get rarity as string for UI display
func get_rarity_string() -> String:
	match rarity:
		Rarity.COMMON:
			return "Common"
		Rarity.UNCOMMON:
			return "Uncommon"
		Rarity.RARE:
			return "Rare"
		Rarity.LEGENDARY:
			return "Legendary"
	return ""

# Get all bonuses as a formatted description
func get_bonus_description() -> String:
	var bonuses: Array[String] = []

	# Flat stat bonuses
	if str_bonus != 0:
		bonuses.append("+%d STR" % str_bonus)
	if dex_bonus != 0:
		bonuses.append("+%d DEX" % dex_bonus)
	if int_bonus != 0:
		bonuses.append("+%d INT" % int_bonus)
	if con_bonus != 0:
		bonuses.append("+%d CON" % con_bonus)
	if spd_bonus != 0:
		bonuses.append("+%d SPD" % spd_bonus)
	if luck_bonus != 0:
		bonuses.append("+%d LUCK" % luck_bonus)

	# Percentage stat bonuses
	if percent_str_bonus != 0:
		bonuses.append("+%d%% STR" % percent_str_bonus)
	if percent_dex_bonus != 0:
		bonuses.append("+%d%% DEX" % percent_dex_bonus)
	if percent_int_bonus != 0:
		bonuses.append("+%d%% INT" % percent_int_bonus)
	if percent_con_bonus != 0:
		bonuses.append("+%d%% CON" % percent_con_bonus)
	if percent_spd_bonus != 0:
		bonuses.append("+%d%% SPD" % percent_spd_bonus)
	if percent_luck_bonus != 0:
		bonuses.append("+%d%% LUCK" % percent_luck_bonus)

	# HP/Vigor bonuses
	if max_hp_bonus != 0:
		bonuses.append("+%d Max HP" % max_hp_bonus)
	if max_vigor_bonus != 0:
		bonuses.append("+%d Max Vigor" % max_vigor_bonus)
	if percent_max_hp_bonus != 0:
		bonuses.append("+%d%% Max HP" % percent_max_hp_bonus)
	if percent_max_vigor_bonus != 0:
		bonuses.append("+%d%% Max Vigor" % percent_max_vigor_bonus)

	return ", ".join(bonuses) if bonuses.size() > 0 else "No bonuses"
