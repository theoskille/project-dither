class_name ActionData
extends Resource

@export var action_id: String = ""
@export var action_name: String = ""
@export var action_type: String = "attack"  # "attack", "movement", "magic", "special"
@export var vigor_cost: int = 1
@export var cooldown: int = 0  # Number of rounds to wait before action can be used again (0 = no cooldown)
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
@export var movement_type: String = "none"  # "none", "dash", "teleport"
@export var stop_on_collision: bool = false  # DEPRECATED: Use movement_type instead
@export var applies_effect_id: String = ""
@export var effect_duration_override: int = 0  # 0 = use effect template's base_duration
@export var kills_user_on_use: bool = false  # If true, the user dies after using this action
@export var accuracy: float = 100.0  # Base hit chance (0-100%). Most attacks are 100%, some may be lower
