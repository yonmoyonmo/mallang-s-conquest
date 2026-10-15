class_name LifeConquestBattle
extends Node2D
## Coordinates alternating placement and automatic Life evolution phases.

signal match_updated(
	round_number: int,
	total_rounds: int,
	generation_in_round: int,
	player_territory: int,
	enemy_territory: int,
	player_energy: int,
	status: String,
	placement_enabled: bool,
)
signal selection_changed(pattern: int, pattern_name: String, rotation: int, cost: int)
signal undo_availability_changed(enabled: bool)
signal match_finished(player_territory: int, enemy_territory: int)

enum Phase {
	PLACEMENT,
	EVOLUTION,
	FINISHED,
}

@export var config: LifeConquestConfig

@onready var _renderer: LifeConquestRenderer = $LifeConquestRenderer
@onready var _input: LifeConquestInput = $LifeConquestInput

var _simulation: LifeConquestSimulation
var _ai: LifeConquestAI
var _phase: int = Phase.PLACEMENT
var _round_number: int = 1
var _generation_in_round: int = 0
var _selected_pattern: int = LifeConquestSimulation.Pattern.BLINKER
var _selected_rotation: int = 0
var _timer: float = 0.0
var _player_energy: int = 0
var _placement_history: Array[Dictionary] = []
var _battle_request: Dictionary = {}


func _ready() -> void:
	_apply_battle_request()
	_input.configure(_renderer)
	_input.cell_pressed.connect(_on_cell_pressed)
	restart_match()


func _process(delta: float) -> void:
	if _phase != Phase.EVOLUTION:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_simulation.evolve()
	_generation_in_round += 1
	_renderer.update_state(_simulation.state)
	_emit_update("진화 중 · %d/%d세대" % [
		_generation_in_round,
		config.generations_per_round,
	])
	if _generation_in_round >= config.generations_per_round:
		_finish_round()
	else:
		_timer = config.generation_interval


func restart_match() -> void:
	config.apply_board_size(config.board_size)
	_simulation = LifeConquestSimulation.new(config.grid_width, config.grid_height)
	var enemy_patterns: Array[int] = []
	for pattern in _battle_request.get("enemy_patterns", []):
		enemy_patterns.append(int(pattern))
	_ai = LifeConquestAI.new(config.random_seed, enemy_patterns)
	_phase = Phase.PLACEMENT
	_round_number = 1
	_generation_in_round = 0
	_selected_pattern = LifeConquestSimulation.Pattern.BLINKER
	_selected_rotation = 0
	_player_energy = config.energy_per_round
	_placement_history.clear()
	_timer = 0.0
	_renderer.configure(config, _simulation.state)
	_renderer.set_themes(
		StringName(_battle_request.get("player_mallang_theme", "default")),
		StringName(_battle_request.get("player_territory_theme", "default")),
		StringName(_battle_request.get("enemy_theme", "default")),
	)
	_input.set_input_enabled(true)
	_emit_selection()
	undo_availability_changed.emit(false)
	_emit_update("패턴을 놓을 빈 공간을 터치")


func _apply_battle_request() -> void:
	config = config.duplicate(true)
	var session := get_node("/root/GameSession")
	_battle_request = session.battle_request
	if _battle_request.is_empty():
		session.prepare_free_battle()
		_battle_request = session.battle_request
	var request := _battle_request
	config.apply_board_size(int(request.get("board_size", config.board_size)))
	config.energy_per_round = int(request.get("energy", config.energy_per_round))
	config.random_seed = int(request.get("seed", config.random_seed))
	var intervals := [0.26, 0.16, 0.08]
	config.generation_interval = intervals[clampi(int(request.get("speed", 1)), 0, 2)]


func cycle_board_size() -> void:
	var next_size := (config.board_size + 1) % LifeConquestConfig.BOARD_DIMENSIONS.size()
	config.apply_board_size(next_size)
	restart_match()


func cycle_pattern() -> void:
	if _phase != Phase.PLACEMENT:
		return
	_selected_pattern = (
		(_selected_pattern + 1) % LifeConquestSimulation.PATTERN_COUNT
	)
	_emit_selection()


func select_pattern(pattern: int) -> void:
	if _phase != Phase.PLACEMENT:
		return
	if pattern < 0 or pattern >= LifeConquestSimulation.PATTERN_COUNT:
		return
	_selected_pattern = pattern
	_emit_selection()


func rotate_pattern() -> void:
	if _phase != Phase.PLACEMENT:
		return
	_selected_rotation = (_selected_rotation + 1) % 4
	_emit_selection()


func end_placement() -> void:
	if _phase != Phase.PLACEMENT:
		return
	_run_ai_placement()
	_placement_history.clear()
	undo_availability_changed.emit(false)
	_renderer.update_state(_simulation.state)
	_phase = Phase.EVOLUTION
	_generation_in_round = 0
	_timer = config.placement_pause
	_input.set_input_enabled(false)
	_emit_update("양쪽 배치 완료")


func undo_last_placement() -> void:
	if _phase != Phase.PLACEMENT or _placement_history.is_empty():
		return
	var previous: Dictionary = _placement_history.pop_back()
	_simulation.state = previous["state"]
	_player_energy = int(previous["energy"])
	_renderer.update_state(_simulation.state)
	undo_availability_changed.emit(not _placement_history.is_empty())
	_emit_update("마지막 배치 취소 · 말랑력 %d" % _player_energy)


func current_snapshot() -> Dictionary:
	if _simulation == null:
		return {}
	return {
		"round": _round_number,
		"total_rounds": config.total_rounds,
		"generation": _generation_in_round,
		"player_territory": _simulation.state.count_territory(
			LifeConquestState.Faction.PLAYER
		),
		"enemy_territory": _simulation.state.count_territory(
			LifeConquestState.Faction.ENEMY
		),
		"player_energy": _player_energy,
		"pattern": _selected_pattern,
		"pattern_name": LifeConquestSimulation.pattern_name(_selected_pattern),
		"pattern_cost": LifeConquestSimulation.pattern_cost(_selected_pattern),
		"rotation": _selected_rotation,
		"board_size_name": config.board_size_name(),
	}


func _on_cell_pressed(cell: Vector2i) -> void:
	if _phase != Phase.PLACEMENT:
		return
	var cost := LifeConquestSimulation.pattern_cost(_selected_pattern)
	if cost > _player_energy:
		_emit_update("말랑력이 부족함 · 필요 %d" % cost)
		return
	var previous_state := _simulation.state.clone()
	var placed := _simulation.place_pattern(
		LifeConquestState.Faction.PLAYER,
		cell,
		_selected_pattern,
		_selected_rotation,
	)
	if not placed:
		_emit_update("그 위치에는 패턴을 놓을 수 없음")
		return
	_placement_history.append({
		"state": previous_state,
		"energy": _player_energy,
	})
	_player_energy -= cost
	_renderer.update_state(_simulation.state)
	undo_availability_changed.emit(true)
	_emit_update("패턴 배치 · 남은 말랑력 %d" % _player_energy)


func _run_ai_placement() -> void:
	var ai_energy := config.energy_per_round
	while ai_energy >= LifeConquestSimulation.pattern_cost(
		LifeConquestSimulation.Pattern.BLOCK
	):
		var placement := _ai.choose_placement(_simulation, ai_energy)
		if placement.is_empty():
			break
		var pattern: int = placement["pattern"]
		var placed := _simulation.place_pattern(
			LifeConquestState.Faction.ENEMY,
			placement["anchor"],
			pattern,
			placement["rotation"],
		)
		if not placed:
			break
		ai_energy -= LifeConquestSimulation.pattern_cost(pattern)


func _finish_round() -> void:
	if _round_number >= config.total_rounds:
		_phase = Phase.FINISHED
		_input.set_input_enabled(false)
		var player_territory := _simulation.state.count_territory(
			LifeConquestState.Faction.PLAYER
		)
		var enemy_territory := _simulation.state.count_territory(
			LifeConquestState.Faction.ENEMY
		)
		match_finished.emit(player_territory, enemy_territory)
		return
	_round_number += 1
	_generation_in_round = 0
	_player_energy = config.energy_per_round
	_placement_history.clear()
	_phase = Phase.PLACEMENT
	_input.set_input_enabled(true)
	undo_availability_changed.emit(false)
	_emit_update("다음 패턴을 배치")


func _emit_selection() -> void:
	selection_changed.emit(
		_selected_pattern,
		LifeConquestSimulation.pattern_name(_selected_pattern),
		_selected_rotation,
		LifeConquestSimulation.pattern_cost(_selected_pattern),
	)


func _emit_update(status: String) -> void:
	match_updated.emit(
		_round_number,
		config.total_rounds,
		_generation_in_round,
		_simulation.state.count_territory(LifeConquestState.Faction.PLAYER),
		_simulation.state.count_territory(LifeConquestState.Faction.ENEMY),
		_player_energy,
		status,
		_phase == Phase.PLACEMENT,
	)
