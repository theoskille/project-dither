class_name NarrativeData
extends Resource

## Resource representing a narrative encounter with choices and outcomes
##
## A narrative encounter displays dialogue text and presents the player with choices.
## Each choice can lead to different outcomes: continuing to another narrative,
## granting items/passives, or triggering combat.

## Unique identifier for this narrative
@export var narrative_id: String = ""

## The narrative text displayed to the player
@export_multiline var dialogue_text: String = ""

## Array of choice dictionaries
## Each choice has the structure:
## {
##   "text": String,           # The choice button text
##   "outcome_type": String,   # One of: "next_narrative", "grant_item", "grant_passive", "trigger_combat", "end"
##   "outcome_value": String   # The ID/value for the outcome (item_id, passive_id, combat_encounter_id, or narrative_id)
## }
@export var choices: Array[Dictionary] = []


func _init():
	resource_name = "NarrativeData"
