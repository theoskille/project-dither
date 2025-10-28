class_name ActionData
extends Resource

@export var action_id: String = ""
@export var action_name: String = ""
@export var action_type: String = "attack"  # "attack", "movement", "magic", "special"
@export var vigor_cost: int = 1
@export var base_damage: int = 0
@export var str_modifier: float = 0.0
@export var dex_modifier: float = 0.0
@export var int_modifier: float = 0.0
@export var con_modifier: float = 0.0
@export var spd_modifier: float = 0.0
@export var luck_modifier: float = 0.0
@export var min_range: int = 0
@export var max_range: int = 999
@export var move_caster: int = 0
@export var move_target: int = 0
@export var applies_effect_id: String = ""
@export var effect_duration_override: int = 0  # 0 = use effect template's base_duration
