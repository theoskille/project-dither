# Project Dither - 4-Layer Combat Architecture

## Architecture Overview

This project uses a strict 4-layer reactive architecture for combat systems:

```
User Input → Combat Engine → State Mutation Functions → Store → UI (via signals)
```

## Layer Structure

```
src/
├── resources/    # Data structure definitions (Resources)
├── store/        # State storage + signal emission (Store Layer)
├── mutations/    # Pure state mutation functions (Mutation Layer)  
├── engine/       # Game logic and orchestration (Engine Layer)
└── ui/           # Reactive UI components (UI Layer)
```

## Data Flow Rules

1. **UI Layer** → **Engine Layer**: User actions go to engine functions
2. **Engine Layer** → **Mutations Layer**: Engine calls mutation functions  
3. **Mutations Layer** → **Store Layer**: Mutations modify store and emit signals
4. **Store Layer** → **UI Layer**: Signals trigger UI updates

## Layer Dependencies

- **Resources**: No dependencies (pure data)
- **Store**: Depends only on Resources
- **Mutations**: Depends on Store (to modify and emit signals)
- **Engine**: Depends on Store (read) and Mutations (write)
- **UI**: Depends on Store (signals) and Engine (actions)

## Forbidden Patterns

- UI directly calling mutations
- Mutations calling engine functions
- Store containing game logic
- Engine directly modifying state without mutations

## Key Benefits

- **Predictable**: All state changes flow through mutations
- **Debuggable**: Every change emits a signal with old/new values
- **Testable**: Pure functions and clear separation of concerns
- **Reactive**: UI automatically updates when state changes