extends Node

## Engine layer for narrative encounter logic
## Orchestrates narrative flow, choice processing, and outcome resolution
## Follows 4-layer architecture: Engine -> Mutations -> Store -> UI

signal narrative_started(narrative_id: String)
signal narrative_completed
signal combat_triggered_from_narrative(encounter_id: String)
signal choice_processed(outcome_type: String, outcome_value: String)

var _current_narrative: NarrativeData = null
var _current_narrative_id: String = ""

func start_narrative(narrative_id: String):
	"""
	Start a narrative encounter
	Loads narrative data and emits signal to UI
	"""
	if not EncounterDatabase.has_narrative(narrative_id):
		push_error("NarrativeEngine: Narrative '%s' not found" % narrative_id)
		return

	_current_narrative = EncounterDatabase.get_narrative(narrative_id)
	_current_narrative_id = narrative_id

	print("NarrativeEngine: Started narrative '%s'" % narrative_id)
	narrative_started.emit(narrative_id)

func get_current_narrative() -> NarrativeData:
	"""Get the currently active narrative"""
	return _current_narrative

func make_choice(choice_index: int):
	"""
	Process a player's choice selection
	Handles different outcome types: next_narrative, grant_item, grant_passive, trigger_combat, end
	"""
	if _current_narrative == null:
		push_error("NarrativeEngine: No active narrative")
		return

	if choice_index < 0 or choice_index >= _current_narrative.choices.size():
		push_error("NarrativeEngine: Invalid choice index %d (max: %d)" % [choice_index, _current_narrative.choices.size() - 1])
		return

	var choice = _current_narrative.choices[choice_index]
	var outcome_type = choice.get("outcome_type", "")
	var outcome_value = choice.get("outcome_value", "")

	print("NarrativeEngine: Processing choice %d - Type: '%s', Value: '%s'" % [choice_index, outcome_type, outcome_value])

	# Process the outcome based on type
	match outcome_type:
		"next_narrative":
			_handle_next_narrative(outcome_value)
		"grant_item":
			_handle_grant_item(outcome_value)
		"grant_passive":
			_handle_grant_passive(outcome_value)
		"trigger_combat":
			_handle_trigger_combat(outcome_value)
		"end":
			_handle_end_narrative()
		_:
			push_error("NarrativeEngine: Unknown outcome type '%s'" % outcome_type)
			_handle_end_narrative()

	choice_processed.emit(outcome_type, outcome_value)

func _handle_next_narrative(narrative_id: String):
	"""Chain to another narrative"""
	print("NarrativeEngine: Chaining to narrative '%s'" % narrative_id)
	start_narrative(narrative_id)

func _handle_grant_item(item_id: String):
	"""Grant an item to the player via mutations"""
	if not ItemDatabase.has_item(item_id):
		push_error("NarrativeEngine: Item '%s' not found in ItemDatabase" % item_id)
		_handle_end_narrative()
		return

	print("NarrativeEngine: Granting item '%s'" % item_id)
	InventoryMutations.add_item_to_inventory(item_id)

	# End narrative after granting item
	_handle_end_narrative()

func _handle_grant_passive(passive_id: String):
	"""Grant a passive ability to the player via mutations"""
	if not PassiveAbilityDatabase.has_passive(passive_id):
		push_error("NarrativeEngine: Passive '%s' not found in PassiveAbilityDatabase" % passive_id)
		_handle_end_narrative()
		return

	print("NarrativeEngine: Granting passive '%s'" % passive_id)
	PlayerMutations.add_passive_ability(passive_id)

	# End narrative after granting passive
	_handle_end_narrative()

func _handle_trigger_combat(encounter_id: String):
	"""Trigger a combat encounter from narrative choice"""
	if not EncounterDatabase.has_encounter(encounter_id):
		push_error("NarrativeEngine: Combat encounter '%s' not found" % encounter_id)
		_handle_end_narrative()
		return

	print("NarrativeEngine: Triggering combat encounter '%s'" % encounter_id)
	_current_narrative = null
	_current_narrative_id = ""
	combat_triggered_from_narrative.emit(encounter_id)

func _handle_end_narrative():
	"""End the current narrative and return to dungeon"""
	print("NarrativeEngine: Ending narrative '%s'" % _current_narrative_id)
	_current_narrative = null
	_current_narrative_id = ""
	narrative_completed.emit()

func is_narrative_active() -> bool:
	"""Check if a narrative is currently active"""
	return _current_narrative != null
