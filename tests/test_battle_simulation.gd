extends SceneTree
## Lightweight headless checks without an external test framework.

var _failures: int = 0


func _init() -> void:
	_test_touch_and_spread()
	_test_occupied_touch_is_rejected()
	_test_local_majority_collision()
	_test_deterministic_result()
	_test_natural_death_is_distinct()
	_test_stagnation_collapse()
	_test_border_death()

	if _failures == 0:
		print("BattleSimulation tests passed.")
		quit(0)
	else:
		push_error("BattleSimulation tests failed: %d" % _failures)
		quit(1)


func _test_touch_and_spread() -> void:
	var config := _make_config()
	var simulation := BattleSimulation.new(config, 100)
	var center := Vector2i(4, 4)
	simulation.queue_touch(BattleState.Faction.PLAYER, center)
	simulation.step()
	_expect(
		simulation.state.count_faction(BattleState.Faction.PLAYER) == 1,
		"A valid touch creates exactly one cell.",
	)
	simulation.step()
	_expect(
		simulation.state.count_faction(BattleState.Faction.PLAYER) == 5,
		"A radial cell spreads to four cardinal neighbors.",
	)


func _test_occupied_touch_is_rejected() -> void:
	var config := _make_config()
	var simulation := BattleSimulation.new(config, 200)
	var center := Vector2i(4, 4)
	simulation.queue_touch(BattleState.Faction.PLAYER, center)
	simulation.step()
	simulation.queue_touch(BattleState.Faction.ENEMY, center)
	var events := simulation.step()
	var found_invalid := false
	for event in events:
		if event.type == SimulationEvent.Type.INVALID_TOUCH:
			found_invalid = true
	_expect(found_invalid, "An occupied-cell touch emits INVALID_TOUCH.")
	_expect(
		simulation.state.faction[simulation.state.index_of(center)]
			== BattleState.Faction.PLAYER,
		"An occupied-cell touch does not directly damage its occupant.",
	)


func _test_deterministic_result() -> void:
	var config := _make_config()
	var first := BattleSimulation.new(config, 300)
	var second := BattleSimulation.new(config, 300)
	for simulation in [first, second]:
		simulation.queue_touch(BattleState.Faction.PLAYER, Vector2i(3, 4))
		simulation.queue_touch(BattleState.Faction.ENEMY, Vector2i(5, 4))
		for _tick in range(4):
			simulation.step()
	_expect(
		first.state.faction == second.state.faction,
		"The same seed and inputs reproduce the same factions.",
	)
	_expect(
		first.state.lineage_id == second.state.lineage_id,
		"The same seed and inputs reproduce the same lineages.",
	)


func _test_local_majority_collision() -> void:
	var config := _make_config()
	var simulation := BattleSimulation.new(config, 250)
	simulation.queue_touch(BattleState.Faction.PLAYER, Vector2i(3, 4))
	simulation.queue_touch(BattleState.Faction.PLAYER, Vector2i(3, 3))
	simulation.queue_touch(BattleState.Faction.ENEMY, Vector2i(5, 4))
	simulation.step()
	var events := simulation.step()
	var center := Vector2i(4, 4)
	var found_collision := false
	for event in events:
		if event.type == SimulationEvent.Type.COLLISION and event.cell == center:
			found_collision = true
	_expect(found_collision, "Opposing spread intents create a collision.")
	_expect(
		simulation.state.faction[simulation.state.index_of(center)]
			== BattleState.Faction.PLAYER,
		"The local majority wins only the contested cell.",
	)


func _test_natural_death_is_distinct() -> void:
	var config := _make_config()
	config.cell_lifetime_ticks = 2
	config.stagnation_ticks = 100
	var simulation := BattleSimulation.new(config, 400)
	simulation.queue_touch(BattleState.Faction.PLAYER, Vector2i(4, 4))
	simulation.step()
	var events := simulation.step()
	var found_natural_death := false
	var found_combat_death := false
	for event in events:
		found_natural_death = (
			found_natural_death
			or event.type == SimulationEvent.Type.DEATH_NATURAL
		)
		found_combat_death = (
			found_combat_death
			or event.type == SimulationEvent.Type.DEATH_COMBAT
		)
	_expect(found_natural_death, "Lifetime expiry emits DEATH_NATURAL.")
	_expect(not found_combat_death, "Lifetime expiry is not a combat death.")


func _test_stagnation_collapse() -> void:
	var config := _make_config()
	config.spread_age_ticks = 50
	config.cell_lifetime_ticks = 100
	config.stagnation_ticks = 1
	config.collapse_delay_ticks = 1
	var simulation := BattleSimulation.new(config, 500)
	simulation.queue_touch(BattleState.Faction.PLAYER, Vector2i(4, 4))
	simulation.step()
	simulation.step()
	var events := simulation.step()
	var found_stagnation_death := false
	for event in events:
		if event.type == SimulationEvent.Type.DEATH_STAGNATION:
			found_stagnation_death = true
	_expect(found_stagnation_death, "A stagnant lineage collapses after its warning.")
	_expect(
		simulation.state.count_faction(BattleState.Faction.PLAYER) == 0,
		"Stagnation collapse removes the lineage.",
	)


func _test_border_death() -> void:
	var config := _make_config()
	config.shrink_start_seconds = 0.1
	config.shrink_interval_seconds = 100.0
	var simulation := BattleSimulation.new(config, 600)
	simulation.queue_touch(BattleState.Faction.PLAYER, Vector2i(0, 0))
	var events := simulation.step()
	var found_border_death := false
	for event in events:
		if event.type == SimulationEvent.Type.DEATH_BORDER:
			found_border_death = true
	_expect(found_border_death, "A shrinking border emits DEATH_BORDER.")
	_expect(
		simulation.state.count_faction(BattleState.Faction.PLAYER) == 0,
		"The shrinking border removes cells outside the active area.",
	)


func _make_config() -> BattleConfig:
	var config := BattleConfig.new()
	config.grid_width = 9
	config.grid_height = 9
	config.tick_rate = 10.0
	config.spread_age_ticks = 1
	config.cell_lifetime_ticks = 20
	config.stagnation_ticks = 20
	config.collapse_delay_ticks = 2
	config.shrink_start_seconds = 1000.0
	return config


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error(message)
