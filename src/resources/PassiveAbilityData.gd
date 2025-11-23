class_name PassiveAbilityData
extends Resource

@export var passive_id: String = ""
@export var passive_name: String = ""
@export_multiline var description: String = ""

# Trigger type determines when this passive activates
# Supported trigger types:
#   "" (empty string) - Always active (e.g., life steal)
#   "on_kill" - When entity kills an enemy
#   "on_turn_end" - At the end of entity's turn
#   "on_being_hit" - When entity is hit by a successful attack
@export var trigger_type: String = ""

# Effects when triggered
@export var vigor_restore: int = 0  # Amount of vigor to restore
@export var heal_amount: int = 0   # Amount of HP to heal
@export var applies_effect_id: String = ""  # Effect to apply to self

# Life steal - percentage of damage dealt that heals the caster
# This is applied whenever damage is dealt, not only on trigger
@export var life_steal_percent: float = 0.0  # % of damage dealt as healing

# AoE damage - dealt to adjacent entities when triggered
@export var aoe_damage_amount: int = 0  # Damage dealt to adjacent entities
@export var aoe_targets_allies: bool = false  # If true, damages allies too; if false, only enemies

# Armor gain - permanent armor increase when triggered
@export var armor_gain_on_hit: int = 0  # Amount of armor % to gain when hit

# Future: could add cooldown, chance, conditions, etc.
