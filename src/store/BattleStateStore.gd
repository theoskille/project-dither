extends Node

signal state_changed(property_path: String, old_value, new_value)

var battle_state: BattleState

# Change this value to fight different enemies
const CURRENT_ENEMY: String = "goblin"

func _ready():
	battle_state = BattleState.new()
	# Initialize the enemy from database
	CombatEngine.initialize_enemy(CURRENT_ENEMY, 5)
	CombatEngine.start_turn(CombatEngine._get_current_turn_entity())

func get_state_value(property_path: String):
	return _get_nested_property(battle_state, property_path)

func _emit_change(property_path: String, old_value, new_value):
	state_changed.emit(property_path, old_value, new_value)

func _get_nested_property(obj, path: String):
	var parts = path.split(".")
	var current = obj
	
	for part in parts:
		if current == null:
			return null
		if current is Dictionary:
			current = current.get(part)
		else:
			current = current.get(part)
	
	return current
