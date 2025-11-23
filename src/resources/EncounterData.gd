class_name EncounterData
extends Resource

## Static template for encounters (combat, shop, or narrative)
## Loaded from data/encounters/ by EncounterDatabase
## Contains configuration for initializing different encounter types

@export var encounter_id: String = ""

## Type of encounter: "combat", "shop", or "narrative"
@export var encounter_type: String = "combat"

## For combat encounters: enemy configurations
@export var enemy_configs: Array[Dictionary] = []
# enemy_configs format: [{"enemy_id": "goblin", "position": 5}, {"enemy_id": "orc", "position": 7}, ...]

## For narrative encounters: reference to narrative data
@export var narrative_id: String = ""
