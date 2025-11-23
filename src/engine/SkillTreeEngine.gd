extends Node

## Engine layer for skill tree logic
## Validates prerequisites, checks requirements, and orchestrates skill unlocking
## Follows 4-layer architecture: Engine -> Mutations -> Store -> UI

var skill_tree_nodes: Dictionary = {}  # skill_id -> SkillNodeData

func _ready():
	# Skill tree will be loaded when class is initialized
	pass

func load_class_skill_tree(class_id: String):
	"""Load skill tree for a specific class"""
	var class_data = CharacterClassDatabase.get_character_class(class_id)
	if class_data == null:
		push_error("SkillTreeEngine: Cannot load skill tree - class '%s' not found" % class_id)
		return

	_load_skill_tree_from_path(class_data.skill_tree_path)

func _load_skill_tree_from_path(skill_dir: String):
	"""Load all skill nodes from the specified directory"""
	# Clear existing skill tree
	skill_tree_nodes.clear()

	var dir = DirAccess.open(skill_dir)

	if dir == null:
		push_warning("SkillTreeEngine: Skills directory not found at %s" % skill_dir)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.ends_with(".tres"):
			var skill_path = skill_dir + file_name
			var skill_node = load(skill_path) as SkillNodeData

			if skill_node and skill_node.node_id != "":
				skill_tree_nodes[skill_node.node_id] = skill_node
				print("SkillTreeEngine: Loaded skill node '%s'" % skill_node.node_id)

		file_name = dir.get_next()

	dir.list_dir_end()
	print("SkillTreeEngine: Loaded %d skill nodes from %s" % [skill_tree_nodes.size(), skill_dir])

func get_skill_node(skill_id: String) -> SkillNodeData:
	"""Get a skill node by ID"""
	return skill_tree_nodes.get(skill_id)

func get_all_skill_nodes() -> Array[SkillNodeData]:
	"""Get all skill nodes as an array"""
	var nodes: Array[SkillNodeData] = []
	for node in skill_tree_nodes.values():
		nodes.append(node)
	return nodes

func can_unlock_skill(skill_id: String) -> Dictionary:
	"""
	Check if a skill can be unlocked
	Returns: { "can_unlock": bool, "reason": String }
	"""
	var skill_node = skill_tree_nodes.get(skill_id)

	if skill_node == null:
		return {"can_unlock": false, "reason": "Skill not found"}

	# Check if already unlocked
	if skill_id in PlayerStore.unlocked_skills:
		return {"can_unlock": false, "reason": "Already unlocked"}

	# Check skill points
	if PlayerStore.skill_points < skill_node.skill_point_cost:
		return {
			"can_unlock": false,
			"reason": "Need %d skill point(s), have %d" % [skill_node.skill_point_cost, PlayerStore.skill_points]
		}

	# Check level requirement
	if PlayerStore.level < skill_node.level_requirement:
		return {
			"can_unlock": false,
			"reason": "Requires level %d, currently level %d" % [skill_node.level_requirement, PlayerStore.level]
		}

	# Check prerequisites
	for prereq_id in skill_node.prerequisite_node_ids:
		if not prereq_id in PlayerStore.unlocked_skills:
			var prereq_node = skill_tree_nodes.get(prereq_id)
			var prereq_name = prereq_node.node_name if prereq_node else prereq_id
			return {
				"can_unlock": false,
				"reason": "Requires skill: %s" % prereq_name
			}

	return {"can_unlock": true, "reason": ""}

func attempt_unlock_skill(skill_id: String) -> bool:
	"""
	Attempt to unlock a skill
	Returns true if successful, false otherwise
	"""
	var check = can_unlock_skill(skill_id)

	if not check.can_unlock:
		push_warning("SkillTreeEngine: Cannot unlock '%s' - %s" % [skill_id, check.reason])
		return false

	var skill_node = skill_tree_nodes.get(skill_id)

	# Spend skill points (one at a time for each point cost)
	for i in skill_node.skill_point_cost:
		PlayerMutations.spend_skill_point()

	# Unlock the skill
	PlayerMutations.unlock_skill(skill_id)

	# Apply the skill's rewards
	_apply_skill_rewards(skill_node)

	print("SkillTreeEngine: Successfully unlocked '%s'" % skill_id)
	return true

func _apply_skill_rewards(skill_node: SkillNodeData):
	"""Apply the rewards for unlocking a skill"""
	# Handle ability replacements first
	if skill_node.replaces_attack_id != "":
		PlayerMutations.remove_attack(skill_node.replaces_attack_id)

	if skill_node.replaces_passive_id != "":
		PlayerMutations.remove_passive_ability(skill_node.replaces_passive_id)

	# Then grant new abilities
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
			# For upgrades, we'll store them differently in the future
			# For now, just log that the upgrade was unlocked
			print("SkillTreeEngine: Upgrade unlocked for attack '%s'" % skill_node.upgrades_attack_id)
			# TODO: Implement attack upgrade system

func get_unlockable_skills() -> Array[String]:
	"""Get list of skill IDs that can currently be unlocked"""
	var unlockable: Array[String] = []

	for skill_id in skill_tree_nodes.keys():
		var check = can_unlock_skill(skill_id)
		if check.can_unlock:
			unlockable.append(skill_id)

	return unlockable

func get_adjacent_skills(skill_id: String) -> Array[String]:
	"""
	Get skills adjacent to this one in the grid (for constellation-style unlocking)
	Adjacent = within 1 grid space (including diagonals)
	"""
	var skill_node = skill_tree_nodes.get(skill_id)
	if skill_node == null:
		return []

	var adjacent: Array[String] = []
	var base_x = skill_node.grid_x
	var base_y = skill_node.grid_y

	for other_id in skill_tree_nodes.keys():
		if other_id == skill_id:
			continue

		var other_node = skill_tree_nodes[other_id]
		var dx = abs(other_node.grid_x - base_x)
		var dy = abs(other_node.grid_y - base_y)

		# Adjacent if within 1 space in both directions
		if dx <= 1 and dy <= 1:
			adjacent.append(other_id)

	return adjacent

func is_skill_unlocked(skill_id: String) -> bool:
	"""Check if a skill is unlocked"""
	return skill_id in PlayerStore.unlocked_skills
