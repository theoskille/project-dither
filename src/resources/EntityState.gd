class_name EntityState
extends Resource

@export var name: String = ""
@export var enemy_id: String = ""
@export var max_hp: int = 100
@export var current_hp: int = 100
@export var max_vigor: int = 3
@export var current_vigor: int = 3
@export var position: int = 0
@export var is_dead: bool = false
@export var base_stats: Dictionary = {"str": 10, "dex": 8, "int": 12, "con": 9, "spd": 7, "luck": 5}
@export var active_effects: Array[EffectState] = []
@export var active_cooldowns: Dictionary = {}  # Maps action_id -> remaining_rounds
@export var equipped_attacks: Array[String] = []
@export var passive_abilities: Array[String] = []
@export var sprite_path: String = ""