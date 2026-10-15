class_name Battle
extends Node2D
## Coordinates input, AI, the deterministic simulation, and presentation.

signal stats_updated(
	player_cells: int,
	enemy_cells: int,
	elapsed_seconds: float,
	seed: int,
)
signal battle_finished(outcome: int)
signal waiting_for_first_touch()

enum Outcome {
	PLAYER_WON,
	ENEMY_WON,
	DRAW,
}

@export var config: BattleConfig

@onready var _renderer: BattleRenderer = $BattleRenderer
@onready var _input: BattleInput = $BattleInput
@onready var _enemy_ai: EnemyTouchAI = $EnemyTouchAI

var _simulation: BattleSimulation
var _accumulator: float = 0.0
var _elapsed_seconds: float = 0.0
var _battle_number: int = 0
var _current_seed: int
var _started: bool = false
var _running: bool = false
var _had_player_cells: bool = false
var _had_enemy_cells: bool = false


func _ready() -> void:
	_input.configure(_renderer)
	_input.cell_touched.connect(_on_player_cell_touched)
	_enemy_ai.touch_announced.connect(_on_enemy_touch_announced)
	_enemy_ai.touch_requested.connect(_on_enemy_touch_requested)
	restart_battle()


func _process(delta: float) -> void:
	if not _running or not _started:
		return

	_elapsed_seconds += delta
	_enemy_ai.update(delta, _simulation.state)
	_accumulator += delta
	var tick_duration := 1.0 / config.tick_rate
	var processed_steps := 0
	while _accumulator >= tick_duration and processed_steps < 8:
		_accumulator -= tick_duration
		processed_steps += 1
		_run_simulation_tick()
		if not _running:
			break


func restart_battle() -> void:
	_battle_number += 1
	_current_seed = config.random_seed + _battle_number - 1
	_simulation = BattleSimulation.new(config, _current_seed)
	_accumulator = 0.0
	_elapsed_seconds = 0.0
	_started = false
	_running = true
	_had_player_cells = false
	_had_enemy_cells = false
	_renderer.configure(config, _simulation.state)
	_renderer.reset()
	_input.set_input_enabled(true)
	_enemy_ai.reset(_current_seed ^ 0x5F3759DF, config)
	stats_updated.emit(0, 0, 0.0, _current_seed)
	waiting_for_first_touch.emit()


func _run_simulation_tick() -> void:
	var events := _simulation.step()
	_renderer.update_state(_simulation.state, events)
	var player_cells := _simulation.state.count_faction(BattleState.Faction.PLAYER)
	var enemy_cells := _simulation.state.count_faction(BattleState.Faction.ENEMY)
	_had_player_cells = _had_player_cells or player_cells > 0
	_had_enemy_cells = _had_enemy_cells or enemy_cells > 0
	stats_updated.emit(player_cells, enemy_cells, _elapsed_seconds, _current_seed)

	if not (_had_player_cells and _had_enemy_cells):
		return
	if player_cells == 0 and enemy_cells == 0:
		_finish_battle(Outcome.DRAW)
	elif enemy_cells == 0:
		_finish_battle(Outcome.PLAYER_WON)
	elif player_cells == 0:
		_finish_battle(Outcome.ENEMY_WON)


func _finish_battle(outcome: int) -> void:
	_running = false
	_input.set_input_enabled(false)
	_enemy_ai.set_ai_enabled(false)
	battle_finished.emit(outcome)


func _on_player_cell_touched(cell: Vector2i) -> void:
	if not _running:
		return
	var is_valid := (
		_simulation.state.is_active_cell(cell)
		and _simulation.state.faction[_simulation.state.index_of(cell)]
			== BattleState.Faction.NONE
	)
	_renderer.show_player_touch(cell, is_valid)
	_simulation.queue_touch(BattleState.Faction.PLAYER, cell)
	if not _started:
		_started = true
		_enemy_ai.set_ai_enabled(true)


func _on_enemy_touch_announced(cell: Vector2i) -> void:
	_renderer.show_enemy_target(cell, config.ai_telegraph_seconds)


func _on_enemy_touch_requested(cell: Vector2i) -> void:
	if _running:
		_simulation.queue_touch(BattleState.Faction.ENEMY, cell)
