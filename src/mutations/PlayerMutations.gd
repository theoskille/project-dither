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
	PlayerStore.level = new_level
	PlayerStore._emit_change("level", old_level, new_level)

	# Increase all base stats by 1
	var old_stats = PlayerStore.base_stats.duplicate()
	for stat in PlayerStore.base_stats.keys():
		PlayerStore.base_stats[stat] += 1

	PlayerStore._emit_change("base_stats", old_stats, PlayerStore.base_stats)

	# Reset XP to 0 for next level
	var old_xp = PlayerStore.current_xp
	PlayerStore.current_xp = 0
	PlayerStore._emit_change("current_xp", old_xp, 0)

	PlayerStore.level_up.emit(new_level)
	print("PlayerMutations: Level up! Now level %d. Stats increased: %s -> %s" % [new_level, old_stats, PlayerStore.base_stats])

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
