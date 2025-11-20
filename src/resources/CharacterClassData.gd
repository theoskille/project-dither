class_name CharacterClassData
extends Resource

## Data structure for character classes
## Defines starting stats, skill tree, and initial abilities for a class

@export var class_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

# Starting base stats for this class
@export var base_stats: Dictionary = {
	"str": 10,
	"dex": 10,
	"int": 10,
	"con": 10,
	"spd": 10,
	"luck": 10
}

# Path to the class-specific skill tree directory
# e.g., "res://data/skills/brawler/"
@export var skill_tree_path: String = ""

# Skill node IDs that start unlocked for this class
# These skills should have skill_point_cost = 0
@export var starting_unlocked_skills: Array[String] = []

# Starting passive abilities for this class
@export var starting_passive_abilities: Array[String] = []
