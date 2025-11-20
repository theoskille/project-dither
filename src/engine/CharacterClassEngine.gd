extends Node

## Engine layer for class selection and initialization
## Orchestrates player class setup by calling mutations
## Follows 4-layer architecture: Engine -> Mutations -> Store -> UI

func initialize_player_class(class_id: String):
	"""
	Initialize the player with a specific class
	Sets base stats, unlocks starting skills, and loads class skill tree
	"""
	print("CharacterClassEngine: Initializing player as class '%s'" % class_id)

	# Get the class data
	var class_data = CharacterClassDatabase.get_character_class(class_id)
	if class_data == null:
		push_error("CharacterClassEngine: Failed to initialize - class '%s' not found" % class_id)
		return

	# Set the player's class
	PlayerMutations.set_character_class(class_id)

	# Set base stats from class
	PlayerMutations.set_base_stats(class_data.base_stats)

	# Load the class-specific skill tree
	SkillTreeEngine.load_class_skill_tree(class_id)

	# Unlock starting skills (these should have skill_point_cost = 0)
	for skill_id in class_data.starting_unlocked_skills:
		_unlock_starting_skill(skill_id)

	# Add starting passive abilities
	for passive_id in class_data.starting_passive_abilities:
		PlayerMutations.add_passive_ability(passive_id)

	print("CharacterClassEngine: Player initialized as %s with %d starting skills" % [class_data.display_name, class_data.starting_unlocked_skills.size()])

func _unlock_starting_skill(skill_id: String):
	"""
	Unlock a starting skill without spending skill points
	These skills should have skill_point_cost = 0
	"""
	var skill_node = SkillTreeEngine.get_skill_node(skill_id)
	if skill_node == null:
		push_error("CharacterClassEngine: Starting skill '%s' not found in skill tree" % skill_id)
		return

	# Verify it's actually a starting skill (cost should be 0)
	if skill_node.skill_point_cost != 0:
		push_warning("CharacterClassEngine: Starting skill '%s' has non-zero cost (%d). This may cause issues." % [skill_id, skill_node.skill_point_cost])

	# Unlock the skill (without spending points since cost is 0)
	PlayerMutations.unlock_skill(skill_id)

	# Apply the skill's rewards
	_apply_starting_skill_rewards(skill_node)

	print("CharacterClassEngine: Unlocked starting skill '%s'" % skill_id)

func _apply_starting_skill_rewards(skill_node: SkillNodeData):
	"""Apply the rewards for a starting skill"""
	match skill_node.skill_type:
		"attack":
			if skill_node.grants_attack_id != "":
				PlayerMutations.add_attack(skill_node.grants_attack_id)

		"passive":
			if skill_node.grants_passive_id != "":
				PlayerMutations.add_passive_ability(skill_node.grants_passive_id)

		"stat_bonus":
			if skill_node.stat_bonus_type != "" and skill_node.stat_bonus_amount > 0:
				PlayerMutations.add_stat_bonus(skill_node.stat_bonus_type, skill_node.stat_bonus_amount)

		"upgrade":
			# For upgrades, just log
			print("CharacterClassEngine: Starting upgrade unlocked for attack '%s'" % skill_node.upgrades_attack_id)
