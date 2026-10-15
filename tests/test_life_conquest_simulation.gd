extends SceneTree
## Headless checks for the Life-based conquest prototype.

var _failures: int = 0


func _init() -> void:
	_test_blinker_oscillates()
	_test_factions_reproduce_independently()
	_test_enemy_neighbors_do_not_overcrowd_allies()
	_test_contested_birth_annihilates_on_tie()
	_test_stronger_claim_captures_cell()
	_test_territory_persists_after_death()
	_test_pattern_rotation()
	_test_pattern_catalog()
	_test_pattern_reference_evolution()
	_test_board_size_presets()
	_test_prototype_uses_max_energy()

	if _failures == 0:
		print("LifeConquestSimulation tests passed.")
		quit(0)
	else:
		push_error("LifeConquestSimulation tests failed: %d" % _failures)
		quit(1)


func _test_blinker_oscillates() -> void:
	var simulation := LifeConquestSimulation.new(9, 9)
	var center := Vector2i(4, 4)
	_expect(
		simulation.place_pattern(
			LifeConquestState.Faction.PLAYER,
			center,
			LifeConquestSimulation.Pattern.BLINKER,
		),
		"A blinker can be placed on an empty board.",
	)
	simulation.evolve()
	for offset in [Vector2i.UP, Vector2i.ZERO, Vector2i.DOWN]:
		_expect(
			simulation.state.life[simulation.state.index_of(center + offset)]
				== LifeConquestState.Faction.PLAYER,
			"A horizontal blinker becomes vertical after one generation.",
		)
	simulation.evolve()
	for offset in [Vector2i.LEFT, Vector2i.ZERO, Vector2i.RIGHT]:
		_expect(
			simulation.state.life[simulation.state.index_of(center + offset)]
				== LifeConquestState.Faction.PLAYER,
			"A blinker returns to horizontal after two generations.",
		)


func _test_factions_reproduce_independently() -> void:
	var simulation := LifeConquestSimulation.new(7, 7)
	var center := Vector2i(3, 3)
	_set_life(simulation, center + Vector2i.LEFT, LifeConquestState.Faction.PLAYER)
	_set_life(simulation, center + Vector2i.RIGHT, LifeConquestState.Faction.PLAYER)
	_set_life(simulation, center + Vector2i.UP, LifeConquestState.Faction.ENEMY)
	simulation.evolve()
	_expect(
		simulation.state.life[simulation.state.index_of(center)]
			== LifeConquestState.Faction.NONE,
		"Mixed factions do not combine to create a birth.",
	)

	var allied_simulation := LifeConquestSimulation.new(7, 7)
	_set_life(
		allied_simulation,
		center + Vector2i.LEFT,
		LifeConquestState.Faction.PLAYER,
	)
	_set_life(
		allied_simulation,
		center + Vector2i.RIGHT,
		LifeConquestState.Faction.PLAYER,
	)
	_set_life(
		allied_simulation,
		center + Vector2i.UP,
		LifeConquestState.Faction.PLAYER,
	)
	allied_simulation.evolve()
	_expect(
		allied_simulation.state.life[allied_simulation.state.index_of(center)]
			== LifeConquestState.Faction.PLAYER,
		"Three allied neighbors create a birth for their faction.",
	)


func _test_enemy_neighbors_do_not_overcrowd_allies() -> void:
	var simulation := LifeConquestSimulation.new(9, 9)
	var center := Vector2i(4, 4)
	_set_life(simulation, center, LifeConquestState.Faction.PLAYER)
	_set_life(simulation, center + Vector2i.LEFT, LifeConquestState.Faction.PLAYER)
	_set_life(simulation, center + Vector2i.RIGHT, LifeConquestState.Faction.PLAYER)
	for offset in [
		Vector2i.UP,
		Vector2i.DOWN,
		Vector2i(-1, -1),
		Vector2i(1, 1),
	]:
		_set_life(simulation, center + offset, LifeConquestState.Faction.ENEMY)
	simulation.evolve()
	_expect(
		simulation.state.life[simulation.state.index_of(center)]
			== LifeConquestState.Faction.PLAYER,
		"Enemy neighbors do not cause allied overpopulation.",
	)


func _test_contested_birth_annihilates_on_tie() -> void:
	var simulation := LifeConquestSimulation.new(9, 9)
	var center := Vector2i(4, 4)
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]:
		_set_life(simulation, center + offset, LifeConquestState.Faction.PLAYER)
	for offset in [Vector2i.DOWN, Vector2i(-1, -1), Vector2i(1, -1)]:
		_set_life(simulation, center + offset, LifeConquestState.Faction.ENEMY)
	simulation.evolve()
	_expect(
		simulation.state.life[simulation.state.index_of(center)]
			== LifeConquestState.Faction.NONE,
		"Equal simultaneous claims annihilate and leave the cell empty.",
	)


func _test_stronger_claim_captures_cell() -> void:
	var simulation := LifeConquestSimulation.new(9, 9)
	var center := Vector2i(4, 4)
	_set_life(simulation, center, LifeConquestState.Faction.PLAYER)
	_set_life(simulation, center + Vector2i.LEFT, LifeConquestState.Faction.PLAYER)
	_set_life(simulation, center + Vector2i.RIGHT, LifeConquestState.Faction.PLAYER)
	for offset in [Vector2i.UP, Vector2i(-1, -1), Vector2i(1, -1)]:
		_set_life(simulation, center + offset, LifeConquestState.Faction.ENEMY)
	simulation.evolve()
	_expect(
		simulation.state.life[simulation.state.index_of(center)]
			== LifeConquestState.Faction.ENEMY,
		"The faction with stronger support wins a contested occupied cell.",
	)


func _test_territory_persists_after_death() -> void:
	var simulation := LifeConquestSimulation.new(7, 7)
	var cell := Vector2i(3, 3)
	_set_life(simulation, cell, LifeConquestState.Faction.PLAYER)
	var index := simulation.state.index_of(cell)
	simulation.state.territory[index] = LifeConquestState.Faction.PLAYER
	simulation.evolve()
	_expect(
		simulation.state.life[index] == LifeConquestState.Faction.NONE,
		"An isolated cell dies under B3/S23.",
	)
	_expect(
		simulation.state.territory[index] == LifeConquestState.Faction.PLAYER,
		"Claimed territory remains after its living cell dies.",
	)


func _test_pattern_rotation() -> void:
	var horizontal := LifeConquestSimulation.pattern_offsets(
		LifeConquestSimulation.Pattern.BLINKER,
		0,
	)
	var vertical := LifeConquestSimulation.pattern_offsets(
		LifeConquestSimulation.Pattern.BLINKER,
		1,
	)
	_expect(Vector2i.LEFT in horizontal, "The base blinker is horizontal.")
	_expect(Vector2i.UP in vertical, "A quarter-turn makes the blinker vertical.")


func _test_pattern_catalog() -> void:
	var expected_names: Array[String] = [
		"수비 말랑",
		"진동 말랑",
		"활공 말랑",
		"폭발 말랑",
		"두근 말랑",
		"등대 말랑",
		"질주 말랑",
		"돌진 말랑",
		"분열 말랑",
		"새싹 말랑",
		"맥동 말랑",
		"여왕 말랑",
	]
	var expected_costs: Array[int] = [2, 3, 4, 5, 4, 4, 6, 6, 6, 6, 6, 6]
	_expect(
		LifeConquestSimulation.PATTERN_COUNT == expected_names.size(),
		"The catalog contains all twelve test patterns.",
	)
	for pattern in range(expected_names.size()):
		_expect(
			LifeConquestSimulation.pattern_name(pattern) == expected_names[pattern],
			"Pattern %d has the expected display name." % pattern,
		)
		_expect(
			LifeConquestSimulation.pattern_cost(pattern) == expected_costs[pattern],
			"Pattern %d has the expected energy cost." % pattern,
		)


func _test_pattern_reference_evolution() -> void:
	var initial_population: Array[int] = [4, 3, 5, 5, 6, 8, 9, 7, 7, 7, 12, 12]
	var generation_fifteen_population: Array[int] = [
		4, 3, 5, 19, 6, 6, 12, 20, 39, 24, 12, 18,
	]
	var generation_fifteen_territory: Array[int] = [
		4, 5, 22, 47, 10, 8, 54, 63, 84, 62, 80, 66,
	]
	for pattern in range(LifeConquestSimulation.PATTERN_COUNT):
		var simulation := LifeConquestSimulation.new(81, 81)
		_expect(
			LifeConquestSimulation.pattern_offsets(pattern).size()
				== initial_population[pattern],
			"Pattern %d has the expected initial population." % pattern,
		)
		_expect(
			simulation.place_pattern(
				LifeConquestState.Faction.PLAYER,
				Vector2i(40, 40),
				pattern,
			),
			"Pattern %d can be placed on an empty board." % pattern,
		)
		for _generation in range(15):
			simulation.evolve()
		_expect(
			simulation.state.count_life(LifeConquestState.Faction.PLAYER)
				== generation_fifteen_population[pattern],
			"Pattern %d has the expected population after fifteen generations." % pattern,
		)
		_expect(
			simulation.state.count_territory(LifeConquestState.Faction.PLAYER)
				== generation_fifteen_territory[pattern],
			"Pattern %d paints the expected territory after fifteen generations." % pattern,
		)


func _test_board_size_presets() -> void:
	var config := LifeConquestConfig.new()
	var expected_names: Array[String] = ["소형", "중형", "대형"]
	var expected_dimensions: Array[Vector2i] = [
		Vector2i(18, 28),
		Vector2i(24, 36),
		Vector2i(30, 45),
	]
	var expected_rounds: Array[int] = [10, 15, 20]
	for board_size in range(expected_names.size()):
		config.apply_board_size(board_size)
		_expect(
			config.board_size_name() == expected_names[board_size],
			"Board preset %d has the expected player-facing name." % board_size,
		)
		_expect(
			Vector2i(config.grid_width, config.grid_height)
				== expected_dimensions[board_size],
			"Board preset %d has the expected dimensions." % board_size,
		)
		_expect(
			config.total_rounds == expected_rounds[board_size],
			"Board preset %d has the expected round count." % board_size,
		)


func _test_prototype_uses_max_energy() -> void:
	var config: LifeConquestConfig = load(
		"res://life_conquest/data/default_life_conquest_config.tres"
	)
	_expect(
		config.energy_per_round == 12,
		"The pattern test prototype starts every round with maximum energy.",
	)
	_expect(
		config.generations_per_round == 15,
		"The pattern test prototype evolves fifteen generations per round.",
	)


func _set_life(
	simulation: LifeConquestSimulation,
	cell: Vector2i,
	faction: int,
) -> void:
	simulation.state.life[simulation.state.index_of(cell)] = faction


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error(message)
