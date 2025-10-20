class_name EntityState
extends Resource

@export var max_hp: int = 100
@export var current_hp: int = 100
@export var max_vigor: int = 3
@export var current_vigor: int = 3
@export var position: int = 0
@export var base_stats: Dictionary = {"str": 10, "dex": 8, "int": 12, "con": 9, "spd": 7, "luck": 5}
@export var active_effects: Array[EffectState] = []