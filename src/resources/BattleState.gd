class_name BattleState
extends Resource

@export var battlefield: BattlefieldLayout
@export var player_state: EntityState
@export var enemy_state: EntityState
@export var turn_state: TurnState

func _init():
	if not battlefield:
		battlefield = BattlefieldLayout.new()
	if not player_state:
		player_state = EntityState.new()
		player_state.name = "Player"
		player_state.position = 0
	if not enemy_state:
		enemy_state = EntityState.new()
		enemy_state.position = 5
	if not turn_state:
		turn_state = TurnState.new()