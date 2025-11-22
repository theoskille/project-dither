extends Node

## Player-specific mutation functions
## Modifies PlayerStore data and emits signals
## Pure state modification - no game logic

func add_xp(amount: int):
	var old_xp = PlayerStore.current_xp
	var new_xp = old_xp + amount
	PlayerStore.current_xp = new_xp
	PlayerStore._emit_change("current_xp", old_xp, new_xp)
	PlayerStore.xp_gained.emit(amount, new_xp)
	print("PlayerMutations: Added %d XP (total: %d)" % [amount, new_xp])

func level_up():
	# Increase level
	var old_level = PlayerStore.level
	var new_level = old_level + 1

	# Check if max vigor should increase (happens every 5 levels)
	var old_max_vigor = 2 + int(floor(old_level / 5.0))
	var new_max_vigor = 2 + int(floor(new_level / 5.0))
	var vigor_increased = new_max_vigor > old_max_vigor

	PlayerStore.level = new_level
	PlayerStore._emit_change("level", old_level, new_level)

	# Increase all base stats by 1
	var old_stats = PlayerStore.base_stats.duplicate()
	for stat in PlayerStore.base_stats.keys():
		PlayerStore.base_stats[stat] += 1

	PlayerStore._emit_change("base_stats", old_stats, PlayerStore.base_stats)

	# Award a skill point
	var old_points = PlayerStore.skill_points
	var new_points = old_points + 1
	PlayerStore.skill_points = new_points
	PlayerStore._emit_change("skill_points", old_points, new_points)

	# Reset XP to 0 for next level
	var old_xp = PlayerStore.current_xp
	PlayerStore.current_xp = 0
	PlayerStore._emit_change("current_xp", old_xp, 0)

	PlayerStore.level_up.emit(new_level)

	var level_up_msg = "PlayerMutations: Level up! Now level %d. Stats increased: %s -> %s. Skill points: %d" % [new_level, old_stats, PlayerStore.base_stats, new_points]
	if vigor_increased:
		level_up_msg += ". Max vigor increased: %d -> %d" % [old_max_vigor, new_max_vigor]
	print(level_up_msg)

func award_skill_point():
	"""Award one skill point to the player"""
	var old_points = PlayerStore.skill_points
	var new_points = old_points + 1
	PlayerStore.skill_points = new_points
	PlayerStore._emit_change("skill_points", old_points, new_points)
	print("PlayerMutations: Awarded skill point (total: %d)" % new_points)

func unlock_skill(skill_id: String):
	"""Add a skill to the player's unlocked skills list"""
	if skill_id in PlayerStore.unlocked_skills:
		push_warning("PlayerMutations: Skill '%s' already unlocked" % skill_id)
		return

	var old_unlocked = PlayerStore.unlocked_skills.duplicate()
	PlayerStore.unlocked_skills.append(skill_id)
	PlayerStore._emit_change("unlocked_skills", old_unlocked, PlayerStore.unlocked_skills)
	PlayerStore.skill_unlocked.emit(skill_id)
	print("PlayerMutations: Unlocked skill '%s'" % skill_id)

func spend_skill_point():
	"""Spend one skill point"""
	var old_points = PlayerStore.skill_points
	var new_points = max(0, old_points - 1)
	PlayerStore.skill_points = new_points
	PlayerStore._emit_change("skill_points", old_points, new_points)
	print("PlayerMutations: Spent skill point (remaining: %d)" % new_points)

func add_stat_bonus(stat_name: String, amount: int):
	"""Add a permanent bonus to a base stat"""
	if not stat_name in PlayerStore.base_stats:
		push_error("PlayerMutations: Invalid stat name '%s'" % stat_name)
		return

	var old_stats = PlayerStore.base_stats.duplicate()
	PlayerStore.base_stats[stat_name] += amount
	PlayerStore._emit_change("base_stats", old_stats, PlayerStore.base_stats)
	print("PlayerMutations: Added +%d to %s (new value: %d)" % [amount, stat_name, PlayerStore.base_stats[stat_name]])

func add_attack(attack_id: String):
	"""Add an attack to the player's equipped attacks (used by skill tree unlocks)"""
	if attack_id in PlayerStore.equipped_attacks:
		push_warning("PlayerMutations: Attack '%s' already equipped" % attack_id)
		return

	var old_attacks = PlayerStore.equipped_attacks.duplicate()
	PlayerStore.equipped_attacks.append(attack_id)
	PlayerStore._emit_change("equipped_attacks", old_attacks, PlayerStore.equipped_attacks)
	print("PlayerMutations: Added attack '%s'" % attack_id)

func equip_attack(attack_id: String):
	"""Equip an attack (user-initiated, enforces max 4 limit)"""
	if attack_id in PlayerStore.equipped_attacks:
		push_warning("PlayerMutations: Attack '%s' is already equipped" % attack_id)
		return

	if PlayerStore.equipped_attacks.size() >= 4:
		push_error("PlayerMutations: Cannot equip '%s' - maximum of 4 attacks allowed" % attack_id)
		return

	var old_attacks = PlayerStore.equipped_attacks.duplicate()
	PlayerStore.equipped_attacks.append(attack_id)
	PlayerStore._emit_change("equipped_attacks", old_attacks, PlayerStore.equipped_attacks)
	print("PlayerMutations: Equipped attack '%s' (%d/4 equipped)" % [attack_id, PlayerStore.equipped_attacks.size()])

func unequip_attack(attack_id: String):
	"""Unequip an attack"""
	if not attack_id in PlayerStore.equipped_attacks:
		push_warning("PlayerMutations: Attack '%s' is not equipped" % attack_id)
		return

	var old_attacks = PlayerStore.equipped_attacks.duplicate()
	PlayerStore.equipped_attacks.erase(attack_id)
	PlayerStore._emit_change("equipped_attacks", old_attacks, PlayerStore.equipped_attacks)
	print("PlayerMutations: Unequipped attack '%s' (%d/4 equipped)" % [attack_id, PlayerStore.equipped_attacks.size()])

func add_passive_ability(passive_id: String):
	"""Add a passive ability to the player"""
	if passive_id in PlayerStore.passive_abilities:
		push_warning("PlayerMutations: Passive '%s' already active" % passive_id)
		return

	var old_passives = PlayerStore.passive_abilities.duplicate()
	PlayerStore.passive_abilities.append(passive_id)
	PlayerStore._emit_change("passive_abilities", old_passives, PlayerStore.passive_abilities)
	print("PlayerMutations: Added passive ability '%s'" % passive_id)

func reset_progression():
	# Reset level to 1
	var old_level = PlayerStore.level
	PlayerStore.level = 1
	PlayerStore._emit_change("level", old_level, 1)

	# Reset XP to 0
	var old_xp = PlayerStore.current_xp
	PlayerStore.current_xp = 0
	PlayerStore._emit_change("current_xp", old_xp, 0)

	print("PlayerMutations: Reset progression - Level 1, 0 XP")

func set_character_class(class_id: String):
	"""Set the player's selected character class"""
	var old_class = PlayerStore.selected_character_class
	PlayerStore.selected_character_class = class_id
	PlayerStore._emit_change("selected_character_class", old_class, class_id)
	PlayerStore.character_class_changed.emit(class_id)
	print("PlayerMutations: Set character class to '%s'" % class_id)

func set_base_stats(new_stats: Dictionary):
	"""Set the player's base stats (used during class initialization)"""
	var old_stats = PlayerStore.base_stats.duplicate()
	PlayerStore.base_stats = new_stats.duplicate()
	PlayerStore._emit_change("base_stats", old_stats, PlayerStore.base_stats)
	print("PlayerMutations: Set base stats to %s" % PlayerStore.base_stats)
