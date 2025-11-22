class_name EffectState
extends Resource

@export var effect_id: String = ""
@export var remaining_duration: int = 0

# Flat stat modifiers
@export var str_modifier: int = 0
@export var dex_modifier: int = 0
@export var int_modifier: int = 0
@export var con_modifier: int = 0
@export var spd_modifier: int = 0
@export var luck_modifier: int = 0

# Percentage stat modifiers (applied after flat modifiers)
@export var percent_str_modifier: int = 0
@export var percent_dex_modifier: int = 0
@export var percent_int_modifier: int = 0
@export var percent_con_modifier: int = 0
@export var percent_spd_modifier: int = 0
@export var percent_luck_modifier: int = 0

# Armor modifier
@export var armor_modifier: int = 0

# Damage over time
@export var damage_per_turn: int = 0

# Action blocking
@export var blocks_all_actions: bool = false
@export var blocks_action_types: Array[String] = []