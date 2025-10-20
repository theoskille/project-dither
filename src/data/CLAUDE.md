# Static Data Layer

## Purpose

This layer contains **static game data** - immutable definitions loaded at startup that define the rules and content of the game. This is **NOT** runtime state.

## Distinction from Store Layer

- **Store Layer** (`src/store/`): Runtime state that changes during gameplay (HP, vigor, positions, active effects)
- **Data Layer** (`src/data/`): Static definitions that never change during a game session (attack stats, item definitions, ability descriptions)

## Architecture Rules

1. **Read-Only**: Data layer provides lookup/query functions only
2. **Immutable**: Loaded once at startup, never modified at runtime
3. **No State Management**: Does not track changes or emit signals
4. **No Dependencies on Other Layers**: Only depends on Resources (data structures)
5. **Autoload Pattern**: Singletons that load data from `res://data/` directory

## Current Data Loaders

- **AttackDatabase**: Loads and provides access to all ActionData resources from `res://data/attacks/`

## Usage Pattern

```gdscript
# In UI or Engine layer
var attack = AttackDatabase.get_action("basic_attack")
CombatEngine.execute_move(attack, caster, target)
```

## File Organization

```
src/data/           # Data loader scripts (autoloads)
├── CLAUDE.md
└── AttackDatabase.gd

data/               # Actual data files (.tres, .json, etc.)
└── attacks/
    ├── basic_attack.tres
    └── slash.tres
```

## Benefits

- **Clear Separation**: Static data vs dynamic state
- **Performance**: Pre-loaded and cached
- **Maintainability**: Add content by adding files, not code
- **Type Safety**: Godot resources are type-checked
- **DRY Principle**: Single source of truth for game data
