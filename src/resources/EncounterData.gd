class_name EncounterData
extends Resource

## Static template for combat encounters
## Loaded from data/encounters/ by EncounterDatabase
## Contains enemy configurations for initializing combat

@export var encounter_id: String = ""
@export var enemy_configs: Array[Dictionary] = []
# enemy_configs format: [{"enemy_id": "goblin", "position": 5}, {"enemy_id": "orc", "position": 7}, ...]
