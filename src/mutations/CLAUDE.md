# Mutations Layer Patterns

## Purpose
Pure functions that modify store data and trigger signal emissions. The ONLY layer allowed to mutate state.

## Rules
1. **Pure Functions**: Static methods with no side effects except state mutation
2. **Signal Emission**: Always call Store's `_emit_change()` after mutations
3. **Atomic Operations**: Each function performs one logical state change
4. **Parameter Validation**: Validate inputs before making changes
5. **Old Value Capture**: Capture old values before mutation for signal emission
6. **No Game Logic**: Only data manipulation, no business rules or calculations

## Naming
- Functions describe the mutation: `set_entity_hp()`, `move_entity()`, `add_effect_to_entity()`
- Use verbs that clearly indicate state changes
- Entity parameters use string identifiers: "player", "enemy"

## Function Pattern
```gdscript
func set_entity_hp(entity: String, new_hp: int):
    var old_hp = BattleStateStore.get_state_value("%s_state.current_hp" % entity)
    BattleStateStore.battle_state.get("%s_state" % entity).current_hp = new_hp
    BattleStateStore._emit_change("%s_state.current_hp" % entity, old_hp, new_hp)
```

## Responsibilities
- Directly modify store data
- Emit state change signals via store
- Validate mutation parameters
- Maintain data integrity during changes

## Forbidden
- Game logic or calculations (belongs in engine layer)
- Direct signal connections to UI
- Reading from external sources
- Calling other mutation functions (engine orchestrates these)