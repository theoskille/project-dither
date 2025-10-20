# Engine Layer Patterns

## Purpose
Game logic and business rules. Orchestrates state mutations to implement combat mechanics.

## Rules
1. **Business Logic Only**: Contains all game rules, calculations, and mechanics
2. **Orchestration**: Calls multiple mutation functions to complete complex operations
3. **No Direct State Access**: Only reads from store, only writes via mutations layer
4. **Stateless Functions**: Each function represents one game action or process
5. **Pure Calculations**: Helper functions for damage, accuracy, etc. should be pure
6. **Event Processing**: Handles user input and game events

## Naming
- Functions describe game actions: `execute_move()`, `process_turn_end()`, `apply_damage()`
- Helper functions for calculations: `_calculate_damage()`, `_determine_accuracy()`
- Use present tense verbs for immediate actions

## Engine Pattern
```gdscript
func execute_move(move_data: Dictionary, caster: String, target: String):
    # 1. Calculate effects using game rules
    var damage = _calculate_damage(move_data, caster)
    
    # 2. Apply effects via mutations
    var current_hp = BattleStateStore.get_state_value("%s_state.current_hp" % target)
    BattleStateMutations.set_entity_hp(target, current_hp - damage)
    
    # 3. Handle secondary effects
    if move_data.has("status_effect"):
        var effect = _create_effect_from_data(move_data.status_effect)
        BattleStateMutations.add_effect_to_entity(target, effect)
```

## Responsibilities
- Implement all combat mechanics and rules
- Calculate damage, accuracy, and other derived values
- Orchestrate multiple state mutations for complex actions
- Process game events and user input
- Validate move legality and requirements

## Forbidden
- Direct state mutation (must use mutations layer)
- UI concerns or rendering logic
- File I/O or persistence (except for game rules data)