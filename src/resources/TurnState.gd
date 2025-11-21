class_name TurnState
extends Resource

@export var current_turn_number: int = 1
@export var turn_order: Array[String] = []
@export var current_turn_index: int = 0
@export var phase: String = "action"
@export var rounds_completed: int = 0  # Tracks how many full rounds have completed (for cooldown decrement)