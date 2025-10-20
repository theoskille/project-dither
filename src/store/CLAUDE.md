# Store Layer Patterns

## Purpose
Singleton that holds current game state and emits signals when data changes. Pure data storage with change notification.

## Rules
1. **Singleton Pattern**: Use autoload to ensure single instance across game
2. **Signal Emission**: Emit `state_changed(property_path, old_value, new_value)` for all changes
3. **No Mutations**: Store never modifies its own data - only mutations layer does
4. **Getter Methods**: Provide `get_state_value(property_path)` for nested property access
5. **Property Paths**: Use dot notation strings like "player_state.current_hp" or "battlefield.player_position"
6. **Change Detection**: Always emit signals with old and new values

## Naming
- Store classes end with "Store": `BattleStateStore`
- Signal names describe the event: `state_changed`
- Property paths use dot notation: `"entity_state.current_hp"`

## Signal Pattern
```gdscript
signal state_changed(property_path: String, old_value, new_value)

func _emit_change(property_path: String, old_value, new_value):
    state_changed.emit(property_path, old_value, new_value)
```

## Access Pattern
```gdscript
func get_state_value(property_path: String):
    return _get_nested_property(battle_state, property_path)
```

## Responsibilities
- Hold the current `BattleState` instance
- Emit signals when data changes (called by mutations layer)
- Provide read-only access to state data
- Never directly modify state data