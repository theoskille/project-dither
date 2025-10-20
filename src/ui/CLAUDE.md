# UI Layer Patterns

## Purpose
Reactive components that listen to store signals and update display. Zero game logic.

## Rules
1. **Signal Listening**: Connect to `BattleStateStore.state_changed` in `_ready()`
2. **Reactive Updates**: Only update display in response to state changes
3. **No State Mutation**: Never modify game state directly - send actions to engine
4. **Property Filtering**: Only respond to relevant state changes using property_path
5. **Entity Configuration**: Use @export entity_name to configure which entity to track
6. **Engine Communication**: Send user actions to CombatEngine, not mutations

## Naming
- Components describe UI purpose: `HealthBar`, `BattlefieldDisplay`, `TurnIndicator`
- Event handlers: `_on_state_changed()`, `_on_button_pressed()`
- Display methods: `_update_display()`, `_refresh_ui()`

## Component Pattern
```gdscript
# HealthBar.gd
extends ProgressBar

@export var entity_name: String = "player"

func _ready():
    BattleStateStore.state_changed.connect(_on_state_changed)
    _update_display()

func _on_state_changed(property_path: String, old_value, new_value):
    if property_path == "%s_state.current_hp" % entity_name:
        _update_display()

func _update_display():
    var current_hp = BattleStateStore.get_state_value("%s_state.current_hp" % entity_name)
    var max_hp = BattleStateStore.get_state_value("%s_state.max_hp" % entity_name)
    value = float(current_hp) / float(max_hp) * 100
```

## Setup Pattern
```gdscript
func _ready():
    BattleStateStore.state_changed.connect(_on_state_changed)
    _update_display()  # Initial display setup
```

## Responsibilities
- Display current game state
- Respond to user input by calling engine functions
- Update visual elements based on state changes
- Handle UI-specific logic (animations, transitions)

## Forbidden
- Game logic or calculations
- Direct state mutation
- Calling mutation functions directly
- Business rule implementation