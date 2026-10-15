class_name BattleSimulation
extends RefCounted
## Deterministic, data-only battle rules. It never reads the SceneTree.

const CARDINAL_DIRECTIONS: Array[Vector2i] = [
	Vector2i.UP,
	Vector2i.RIGHT,
	Vector2i.DOWN,
	Vector2i.LEFT,
]

var state: BattleState
var tick_index: int = 0

var _config: BattleConfig
var _rng := RandomNumberGenerator.new()
var _input_queue: Array[Dictionary] = []
var _next_lineage_id: int = 1
var _lineage_last_growth: Dictionary = {}
var _lineage_warning_tick: Dictionary = {}
var _lineage_origin: Dictionary = {}


func _init(config: BattleConfig, seed: int) -> void:
	_config = config
	_rng.seed = seed
	state = BattleState.new(config.grid_width, config.grid_height)


func queue_touch(faction: int, cell: Vector2i) -> void:
	_input_queue.append({"faction": faction, "cell": cell})


func has_queued_input() -> bool:
	return not _input_queue.is_empty()


func step() -> Array[SimulationEvent]:
	var events: Array[SimulationEvent] = []
	var base_state := state.clone()
	_apply_touch_inputs(base_state, events)

	var player_sources := PackedInt32Array()
	var enemy_sources := PackedInt32Array()
	player_sources.resize(base_state.size)
	enemy_sources.resize(base_state.size)
	player_sources.fill(-1)
	enemy_sources.fill(-1)
	_collect_spread_intents(base_state, player_sources, enemy_sources)

	var next_state := base_state.clone()
	_resolve_spread(base_state, next_state, player_sources, enemy_sources, events)
	_retire_spread_sources(base_state, next_state, events)
	_age_and_expire(next_state, events)
	_update_stagnation(next_state, events)
	_update_border(next_state, events)

	state = next_state
	tick_index += 1
	return events


func _apply_touch_inputs(
	base_state: BattleState,
	events: Array[SimulationEvent],
) -> void:
	var claims: Dictionary = {}

	for command in _input_queue:
		var cell: Vector2i = command["cell"]
		var command_faction: int = command["faction"]
		if not base_state.is_active_cell(cell):
			events.append(SimulationEvent.new(
				SimulationEvent.Type.INVALID_TOUCH,
				cell,
				command_faction,
			))
			continue

		var index := base_state.index_of(cell)
		if base_state.faction[index] != BattleState.Faction.NONE:
			events.append(SimulationEvent.new(
				SimulationEvent.Type.INVALID_TOUCH,
				cell,
				command_faction,
			))
			continue

		var faction_bit := 1 if command_faction == BattleState.Faction.PLAYER else 2
		claims[index] = claims.get(index, 0) | faction_bit

	_input_queue.clear()
	var claim_indices: Array = claims.keys()
	claim_indices.sort()
	for value in claim_indices:
		var index: int = value
		var mask: int = claims[index]
		var winner := BattleState.Faction.PLAYER
		if mask == 2:
			winner = BattleState.Faction.ENEMY
		elif mask == 3:
			winner = _rng.randi_range(
				BattleState.Faction.PLAYER,
				BattleState.Faction.ENEMY,
			)
			var loser := _opposing_faction(winner)
			events.append(SimulationEvent.new(
				SimulationEvent.Type.COLLISION,
				base_state.cell_of(index),
				winner,
				loser,
			))

		_spawn_touch_cell(base_state, index, winner, events)


func _spawn_touch_cell(
	target_state: BattleState,
	index: int,
	spawn_faction: int,
	events: Array[SimulationEvent],
) -> void:
	var lineage := _next_lineage_id
	_next_lineage_id += 1
	target_state.faction[index] = spawn_faction
	target_state.lineage_id[index] = lineage
	target_state.pattern[index] = BattleState.Pattern.RADIAL
	target_state.direction[index] = _random_radial_mask()
	target_state.age[index] = 0
	target_state.generation[index] = 0
	target_state.cell_status[index] = BattleState.CellStatus.ACTIVE
	_lineage_last_growth[lineage] = tick_index
	_lineage_origin[lineage] = target_state.cell_of(index)
	events.append(SimulationEvent.new(
		SimulationEvent.Type.CELL_SPAWNED,
		target_state.cell_of(index),
		spawn_faction,
		BattleState.Faction.NONE,
		lineage,
	))


func _collect_spread_intents(
	base_state: BattleState,
	player_sources: PackedInt32Array,
	enemy_sources: PackedInt32Array,
) -> void:
	for source_index in range(base_state.size):
		var source_faction := base_state.faction[source_index]
		if source_faction == BattleState.Faction.NONE:
			continue
		if base_state.cell_status[source_index] != BattleState.CellStatus.ACTIVE:
			continue
		if base_state.age[source_index] != _config.spread_age_ticks:
			continue

		var source_cell := base_state.cell_of(source_index)
		for direction_index in range(CARDINAL_DIRECTIONS.size()):
			if (base_state.direction[source_index] & (1 << direction_index)) == 0:
				continue
			var offset := CARDINAL_DIRECTIONS[direction_index]
			var target_cell := source_cell + offset
			if not base_state.is_active_cell(target_cell):
				continue
			if not _is_outward_step(base_state, source_index, target_cell):
				continue
			var target_index := base_state.index_of(target_cell)
			if source_faction == BattleState.Faction.PLAYER:
				if player_sources[target_index] == -1:
					player_sources[target_index] = source_index
			elif enemy_sources[target_index] == -1:
				enemy_sources[target_index] = source_index


func _random_radial_mask() -> int:
	var available_directions := [0, 1, 2, 3]
	var minimum := clampi(_config.radial_min_arms, 1, 4)
	var maximum := clampi(_config.radial_max_arms, minimum, 4)
	var arm_count := _rng.randi_range(minimum, maximum)
	var mask := 0
	for _arm in range(arm_count):
		var pick := _rng.randi_range(0, available_directions.size() - 1)
		var direction_index: int = available_directions.pop_at(pick)
		mask |= 1 << direction_index
	return mask


func _is_outward_step(
	base_state: BattleState,
	source_index: int,
	target_cell: Vector2i,
) -> bool:
	var lineage := base_state.lineage_id[source_index]
	if not _lineage_origin.has(lineage):
		return true
	var origin: Vector2i = _lineage_origin[lineage]
	var source_cell := base_state.cell_of(source_index)
	var source_distance := absi(source_cell.x - origin.x) + absi(source_cell.y - origin.y)
	var target_distance := absi(target_cell.x - origin.x) + absi(target_cell.y - origin.y)
	return target_distance > source_distance


func _resolve_spread(
	base_state: BattleState,
	next_state: BattleState,
	player_sources: PackedInt32Array,
	enemy_sources: PackedInt32Array,
	events: Array[SimulationEvent],
) -> void:
	for target_index in range(base_state.size):
		var player_source := player_sources[target_index]
		var enemy_source := enemy_sources[target_index]
		if player_source == -1 and enemy_source == -1:
			continue

		var occupant := base_state.faction[target_index]
		var has_player_attack := player_source != -1
		var has_enemy_attack := enemy_source != -1
		var is_collision := (
			(occupant == BattleState.Faction.NONE and has_player_attack and has_enemy_attack)
			or (occupant == BattleState.Faction.PLAYER and has_enemy_attack)
			or (occupant == BattleState.Faction.ENEMY and has_player_attack)
		)

		if not is_collision:
			if occupant != BattleState.Faction.NONE:
				continue
			var source := player_source if has_player_attack else enemy_source
			_spawn_from_source(base_state, next_state, source, target_index, events)
			continue

		var winner := _resolve_local_majority(base_state, target_index)
		var loser := _opposing_faction(winner)
		var target_cell := base_state.cell_of(target_index)
		events.append(SimulationEvent.new(
			SimulationEvent.Type.COLLISION,
			target_cell,
			winner,
			loser,
		))
		events.append(SimulationEvent.new(
			SimulationEvent.Type.DEATH_COMBAT,
			target_cell,
			loser,
			winner,
		))

		if occupant == winner:
			# A defending front that wins becomes the next generation and keeps moving.
			next_state.age[target_index] = 0
			next_state.generation[target_index] = base_state.generation[target_index] + 1
			next_state.cell_status[target_index] = BattleState.CellStatus.ACTIVE
			continue
		var winning_source := player_source
		if winner == BattleState.Faction.ENEMY:
			winning_source = enemy_source
		_spawn_from_source(base_state, next_state, winning_source, target_index, events)


func _resolve_local_majority(base_state: BattleState, target_index: int) -> int:
	var center := base_state.cell_of(target_index)
	var player_count := 0
	var enemy_count := 0
	for y_offset in range(-1, 2):
		for x_offset in range(-1, 2):
			if x_offset == 0 and y_offset == 0:
				continue
			var neighbor := center + Vector2i(x_offset, y_offset)
			if not base_state.is_active_cell(neighbor):
				continue
			var neighbor_faction := base_state.faction[base_state.index_of(neighbor)]
			if neighbor_faction == BattleState.Faction.PLAYER:
				player_count += 1
			elif neighbor_faction == BattleState.Faction.ENEMY:
				enemy_count += 1

	if player_count > enemy_count:
		return BattleState.Faction.PLAYER
	if enemy_count > player_count:
		return BattleState.Faction.ENEMY
	return _rng.randi_range(BattleState.Faction.PLAYER, BattleState.Faction.ENEMY)


func _spawn_from_source(
	base_state: BattleState,
	next_state: BattleState,
	source_index: int,
	target_index: int,
	events: Array[SimulationEvent],
) -> void:
	if source_index < 0:
		return
	var spread_faction := base_state.faction[source_index]
	var lineage := base_state.lineage_id[source_index]
	next_state.faction[target_index] = spread_faction
	next_state.lineage_id[target_index] = lineage
	next_state.pattern[target_index] = base_state.pattern[source_index]
	next_state.direction[target_index] = base_state.direction[source_index]
	next_state.age[target_index] = 0
	next_state.generation[target_index] = base_state.generation[source_index] + 1
	next_state.cell_status[target_index] = BattleState.CellStatus.ACTIVE
	_lineage_last_growth[lineage] = tick_index
	events.append(SimulationEvent.new(
		SimulationEvent.Type.CELL_SPREAD,
		next_state.cell_of(target_index),
		spread_faction,
		BattleState.Faction.NONE,
		lineage,
	))


func _retire_spread_sources(
	base_state: BattleState,
	next_state: BattleState,
	events: Array[SimulationEvent],
) -> void:
	for index in range(base_state.size):
		if base_state.faction[index] == BattleState.Faction.NONE:
			continue
		if base_state.cell_status[index] != BattleState.CellStatus.ACTIVE:
			continue
		if base_state.age[index] != _config.spread_age_ticks:
			continue
		# Converted or refreshed collision winners must survive as a new front.
		if next_state.faction[index] != base_state.faction[index]:
			continue
		if next_state.lineage_id[index] != base_state.lineage_id[index]:
			continue
		if next_state.age[index] != base_state.age[index]:
			continue
		events.append(SimulationEvent.new(
			SimulationEvent.Type.DEATH_NATURAL,
			base_state.cell_of(index),
			base_state.faction[index],
			BattleState.Faction.NONE,
			base_state.lineage_id[index],
		))
		next_state.clear_cell(index)


func _age_and_expire(
	next_state: BattleState,
	events: Array[SimulationEvent],
) -> void:
	for index in range(next_state.size):
		var cell_faction := next_state.faction[index]
		if cell_faction == BattleState.Faction.NONE:
			continue
		next_state.age[index] = next_state.age[index] + 1
		if next_state.age[index] < _config.cell_lifetime_ticks:
			continue
		events.append(SimulationEvent.new(
			SimulationEvent.Type.DEATH_NATURAL,
			next_state.cell_of(index),
			cell_faction,
			BattleState.Faction.NONE,
			next_state.lineage_id[index],
		))
		next_state.clear_cell(index)


func _update_stagnation(
	next_state: BattleState,
	events: Array[SimulationEvent],
) -> void:
	var live_lineages: Dictionary = {}
	for index in range(next_state.size):
		var lineage := next_state.lineage_id[index]
		if lineage > 0:
			live_lineages[lineage] = true

	var lineages: Array = live_lineages.keys()
	lineages.sort()
	for value in lineages:
		var lineage: int = value
		var last_growth: int = _lineage_last_growth.get(lineage, tick_index)
		if tick_index - last_growth < _config.stagnation_ticks:
			continue

		if not _lineage_warning_tick.has(lineage):
			_lineage_warning_tick[lineage] = tick_index
			_mark_lineage_collapsing(next_state, lineage, events)
			continue

		var warning_tick: int = _lineage_warning_tick[lineage]
		if tick_index - warning_tick >= _config.collapse_delay_ticks:
			_remove_stagnant_lineage(next_state, lineage, events)

	var known_lineages: Array = _lineage_last_growth.keys()
	for value in known_lineages:
		var lineage: int = value
		if live_lineages.has(lineage):
			continue
		_lineage_last_growth.erase(lineage)
		_lineage_warning_tick.erase(lineage)
		_lineage_origin.erase(lineage)


func _mark_lineage_collapsing(
	next_state: BattleState,
	lineage: int,
	events: Array[SimulationEvent],
) -> void:
	for index in range(next_state.size):
		if next_state.lineage_id[index] != lineage:
			continue
		next_state.cell_status[index] = BattleState.CellStatus.COLLAPSING
		events.append(SimulationEvent.new(
			SimulationEvent.Type.STAGNATION_WARNING,
			next_state.cell_of(index),
			next_state.faction[index],
			BattleState.Faction.NONE,
			lineage,
		))


func _remove_stagnant_lineage(
	next_state: BattleState,
	lineage: int,
	events: Array[SimulationEvent],
) -> void:
	for index in range(next_state.size):
		if next_state.lineage_id[index] != lineage:
			continue
		events.append(SimulationEvent.new(
			SimulationEvent.Type.DEATH_STAGNATION,
			next_state.cell_of(index),
			next_state.faction[index],
			BattleState.Faction.NONE,
			lineage,
		))
		next_state.clear_cell(index)


func _update_border(
	next_state: BattleState,
	events: Array[SimulationEvent],
) -> void:
	var elapsed_ticks := tick_index + 1
	var start_tick := int(round(_config.shrink_start_seconds * _config.tick_rate))
	var interval_ticks: int = maxi(1, int(round(
		_config.shrink_interval_seconds * _config.tick_rate
	)))
	if elapsed_ticks < start_tick:
		return
	if (elapsed_ticks - start_tick) % interval_ticks != 0:
		return

	next_state.active_min_x += 1
	next_state.active_min_y += 1
	next_state.active_max_x -= 1
	next_state.active_max_y -= 1
	events.append(SimulationEvent.new(SimulationEvent.Type.BORDER_SHRUNK))

	for index in range(next_state.size):
		if next_state.faction[index] == BattleState.Faction.NONE:
			continue
		if next_state.is_active_index(index):
			continue
		events.append(SimulationEvent.new(
			SimulationEvent.Type.DEATH_BORDER,
			next_state.cell_of(index),
			next_state.faction[index],
			BattleState.Faction.NONE,
			next_state.lineage_id[index],
		))
		next_state.clear_cell(index)


func _opposing_faction(source_faction: int) -> int:
	if source_faction == BattleState.Faction.PLAYER:
		return BattleState.Faction.ENEMY
	return BattleState.Faction.PLAYER
