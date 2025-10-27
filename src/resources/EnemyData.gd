class_name EnemyData
extends Resource

@export var enemy_id: String = ""
@export var enemy_name: String = ""
@export var max_hp: int = 100
@export var max_vigor: int = 3
@export var base_stats: Dictionary = {
	"str": 10,
	"dex": 10,
	"int": 10,
	"con": 10,
	"spd": 10,
	"luck": 10
}
@export var equipped_attacks: Array[String] = []
