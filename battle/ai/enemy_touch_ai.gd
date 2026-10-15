class_name EnemyTouchAI
extends Node
## Produces the same touch commands as the player, with a visible delay.

signal touch_announced(cell: Vector2i)
signal touch_requested(cell: Vector2i)

var _config: BattleConfig
var _rng := RandomNumberGenerator.new()
var _enabled: bool = false
var _cooldown: float = 0.0
var _telegraph_left: float = 0.0
var _pending_cell := Vector2i(-1, -1)


func reset(seed: int, config: BattleConfig) -> void:
	_config = config
	_rng.seed = seed
	_enabled = false
	_cooldown = 0.15
	_telegraph_left = 0.0
	_pending_cell = Vector2i(-1, -1)


func set_ai_enabled(value: bool) -> void:
	_enabled = value
	if not value:
		_pending_cell = Vector2i(-1, -1)
		_telegraph_left = 0.0


func update(delta: float, state: BattleState) -> void:
	if not _enabled or _config == null:
		return

	if _pending_cell.x >= 0:
		_telegraph_left -= delta
		if _telegraph_left <= 0.0:
			touch_requested.emit(_pending_cell)
			_pending_cell = Vector2i(-1, -1)
			_cooldown = _rng.randf_range(
				_config.ai_min_interval,
				max(_config.ai_min_interval, _config.ai_max_interval),
			)
		return

	_cooldown -= delta
	if _cooldown > 0.0:
		return

	var target := _pick_empty_cell(state)
	if target.x < 0:
		_cooldown = 0.1
		return
	_pending_cell = target
	_telegraph_left = _config.ai_telegraph_seconds
	touch_announced.emit(target)


func _pick_empty_cell(state: BattleState) -> Vector2i:
	if state.active_min_x > state.active_max_x or state.active_min_y > state.active_max_y:
		return Vector2i(-1, -1)

	for _attempt in range(32):
		var cell := Vector2i(
			_rng.randi_range(state.active_min_x, state.active_max_x),
			_rng.randi_range(state.active_min_y, state.active_max_y),
		)
		if state.faction[state.index_of(cell)] == BattleState.Faction.NONE:
			return cell

	var start := _rng.randi_range(0, state.size - 1)
	for offset in range(state.size):
		var index := (start + offset) % state.size
		if not state.is_active_index(index):
			continue
		if state.faction[index] == BattleState.Faction.NONE:
			return state.cell_of(index)
	return Vector2i(-1, -1)
