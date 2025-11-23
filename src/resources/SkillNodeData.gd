class_name SkillNodeData
extends Resource

## Represents a single node in the skill tree
## Follows the Resources layer - pure data structure with no logic

# Node identification
@export var node_id: String = ""
@export var node_name: String = ""
@export_multiline var description: String = ""
@export var icon_path: String = ""  # Path to icon texture (future use)

# Grid positioning for constellation-style layout
@export var grid_x: int = 0
@export var grid_y: int = 0

# Requirements to unlock this skill
@export var skill_point_cost: int = 1
@export var level_requirement: int = 1
@export var prerequisite_node_ids: Array[String] = []  # Must have these skills unlocked first

# Skill type - determines what happens when unlocked
@export_enum("attack", "passive", "stat_bonus", "upgrade") var skill_type: String = "stat_bonus"

# Reward data - what the player gets when unlocking this skill
# For "attack" type
@export var grants_attack_id: String = ""  # Adds this attack to available attacks

# For "passive" type
@export var grants_passive_id: String = ""  # Adds this passive ability

# For "stat_bonus" type
@export var stat_bonus_type: String = ""  # "str", "dex", "int", "con", "spd", "luck"
@export var stat_bonus_amount: int = 0

# For "upgrade" type
@export var upgrades_attack_id: String = ""  # Which attack to upgrade
@export var damage_bonus: int = 0
@export var vigor_cost_reduction: int = 0
@export var cooldown_reduction: int = 0

# For ability replacement - removes old abilities when unlocking new ones
@export var replaces_attack_id: String = ""  # Remove this attack when unlocking this skill
@export var replaces_passive_id: String = ""  # Remove this passive when unlocking this skill
