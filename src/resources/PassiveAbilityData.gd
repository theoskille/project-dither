class_name PassiveAbilityData
extends Resource

@export var passive_id: String = ""
@export var passive_name: String = ""
@export_multiline var description: String = ""

# Trigger type determines when this passive activates
# Supported: "on_kill" (when entity kills an enemy)
@export var trigger_type: String = "on_kill"

# Effects when triggered
@export var vigor_restore: int = 0  # Amount of vigor to restore
@export var heal_amount: int = 0   # Amount of HP to heal
@export var applies_effect_id: String = ""  # Effect to apply to self

# Life steal - percentage of damage dealt that heals the caster
# This is applied whenever damage is dealt, not only on trigger
@export var life_steal_percent: float = 0.0  # % of damage dealt as healing

# Future: could add cooldown, chance, conditions, etc.
