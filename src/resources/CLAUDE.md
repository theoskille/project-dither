# Resources Layer Patterns

## Purpose
Pure data structure definitions that define the shape of game state. No logic, only data.

## Rules
1. **Extend Resource**: All data classes must extend Godot's Resource class
2. **Export Properties**: Use @export for all properties to enable serialization
3. **No Logic**: Zero game logic or methods - pure data containers only
4. **Typed Arrays**: Use Array[ClassName] for typed collections
5. **Default Values**: Always provide sensible defaults for properties
6. **Composition**: Break complex state into smaller, focused resource classes

## Naming
- PascalCase for class names: `BattleState`, `EntityState`, `EffectState`
- snake_case for properties: `current_hp`, `active_effects`, `remaining_duration`

## File Structure
- One class per file
- File name matches class name: `BattleState.gd` contains `class_name BattleState`

## Example Pattern
```gdscript
# EntityState.gd
class_name EntityState
extends Resource

@export var max_hp: int = 100
@export var current_hp: int = 100
@export var base_stats: Dictionary = {}
@export var active_effects: Array[EffectState] = []
```