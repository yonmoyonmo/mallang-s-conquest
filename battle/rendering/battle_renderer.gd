class_name BattleRenderer
extends Node2D
## Draws the entire grid in one CanvasItem and owns only presentation state.

const TOP_MARGIN := 76.0
const SIDE_MARGIN := 14.0
const BOTTOM_MARGIN := 24.0

var _config: BattleConfig
var _state: BattleState
var _effects: Array[Dictionary] = []
var _enemy_targets: Array[Dictionary] = []


func configure(config: BattleConfig, initial_state: BattleState) -> void:
	_config = config
	_state = initial_state
	queue_redraw()


func update_state(new_state: BattleState, events: Array[SimulationEvent]) -> void:
	_state = new_state
	for event in events:
		_consume_event(event)
	queue_redraw()


func reset() -> void:
	_effects.clear()
	_enemy_targets.clear()
	queue_redraw()


func show_player_touch(cell: Vector2i, is_valid: bool) -> void:
	var color := _config.player_color if is_valid else Color("ffca5c")
	_add_effect(cell, color, 0.18, 0.65)


func show_enemy_target(cell: Vector2i, duration: float) -> void:
	_enemy_targets.append({
		"cell": cell,
		"time": duration,
		"duration": max(duration, 0.01),
	})
	queue_redraw()


func screen_to_cell(screen_position: Vector2) -> Vector2i:
	if _state == null:
		return Vector2i(-1, -1)
	var layout := _board_layout()
	var board_rect: Rect2 = layout["rect"]
	var cell_size: float = layout["cell_size"]
	if not board_rect.has_point(screen_position):
		return Vector2i(-1, -1)
	var local_position := screen_position - board_rect.position
	var cell := Vector2i(
		int(floor(local_position.x / cell_size)),
		int(floor(local_position.y / cell_size)),
	)
	if not _state.contains(cell):
		return Vector2i(-1, -1)
	return cell


func _process(delta: float) -> void:
	var changed := false
	for index in range(_effects.size() - 1, -1, -1):
		var effect := _effects[index]
		effect["time"] = float(effect["time"]) - delta
		if effect["time"] <= 0.0:
			_effects.remove_at(index)
		else:
			_effects[index] = effect
		changed = true

	for index in range(_enemy_targets.size() - 1, -1, -1):
		var target := _enemy_targets[index]
		target["time"] = float(target["time"]) - delta
		if target["time"] <= 0.0:
			_enemy_targets.remove_at(index)
		else:
			_enemy_targets[index] = target
		changed = true

	if changed:
		queue_redraw()


func _draw() -> void:
	if _config == null or _state == null:
		return
	var viewport_size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), _config.background_color)

	var layout := _board_layout()
	var board_rect: Rect2 = layout["rect"]
	var cell_size: float = layout["cell_size"]
	draw_rect(board_rect, _config.closed_color)

	if _state.active_min_x <= _state.active_max_x and _state.active_min_y <= _state.active_max_y:
		var active_position := board_rect.position + Vector2(
			_state.active_min_x * cell_size,
			_state.active_min_y * cell_size,
		)
		var active_size := Vector2(
			(_state.active_max_x - _state.active_min_x + 1) * cell_size,
			(_state.active_max_y - _state.active_min_y + 1) * cell_size,
		)
		draw_rect(Rect2(active_position, active_size), _config.board_color)

	_draw_grid(board_rect, cell_size)
	_draw_cells(board_rect, cell_size)
	_draw_enemy_targets(board_rect, cell_size)
	_draw_effects(board_rect, cell_size)


func _draw_grid(board_rect: Rect2, cell_size: float) -> void:
	for x in range(0, _state.width + 1, 4):
		var x_position := board_rect.position.x + x * cell_size
		draw_line(
			Vector2(x_position, board_rect.position.y),
			Vector2(x_position, board_rect.end.y),
			_config.grid_color,
			1.0,
		)
	for y in range(0, _state.height + 1, 4):
		var y_position := board_rect.position.y + y * cell_size
		draw_line(
			Vector2(board_rect.position.x, y_position),
			Vector2(board_rect.end.x, y_position),
			_config.grid_color,
			1.0,
		)


func _draw_cells(board_rect: Rect2, cell_size: float) -> void:
	for index in range(_state.size):
		var cell_faction := _state.faction[index]
		if cell_faction == BattleState.Faction.NONE:
			continue
		var color := _config.player_color
		if cell_faction == BattleState.Faction.ENEMY:
			color = _config.enemy_color
		if _state.cell_status[index] == BattleState.CellStatus.COLLAPSING:
			color = color.lerp(Color.WHITE, 0.55)
			color.a = 0.65
		var center := _cell_center(_state.cell_of(index), board_rect, cell_size)
		var age_ratio: float = clampf(
			float(_state.age[index]) / max(1.0, float(_config.cell_lifetime_ticks)),
			0.0,
			1.0,
		)
		var radius: float = cell_size * lerpf(0.42, 0.29, age_ratio)
		draw_circle(center, max(1.5, radius), color)


func _draw_enemy_targets(board_rect: Rect2, cell_size: float) -> void:
	for target in _enemy_targets:
		var ratio: float = float(target["time"]) / float(target["duration"])
		var center := _cell_center(target["cell"], board_rect, cell_size)
		var color := _config.enemy_color
		color.a = 0.35 + 0.55 * (1.0 - ratio)
		draw_arc(
			center,
			cell_size * (0.25 + ratio * 0.65),
			0.0,
			TAU,
			20,
			color,
			max(1.0, cell_size * 0.1),
		)


func _draw_effects(board_rect: Rect2, cell_size: float) -> void:
	for effect in _effects:
		var progress := 1.0 - float(effect["time"]) / float(effect["duration"])
		var center := _cell_center(effect["cell"], board_rect, cell_size)
		var color: Color = effect["color"]
		color.a *= 1.0 - progress
		draw_arc(
			center,
			cell_size * float(effect["radius"]) * (0.35 + progress),
			0.0,
			TAU,
			20,
			color,
			max(1.0, cell_size * 0.12),
		)


func _consume_event(event: SimulationEvent) -> void:
	match event.type:
		SimulationEvent.Type.COLLISION:
			var color := _config.player_color
			if event.faction == BattleState.Faction.ENEMY:
				color = _config.enemy_color
			_add_effect(event.cell, color, 0.25, 1.0)
		SimulationEvent.Type.INVALID_TOUCH:
			if event.faction == BattleState.Faction.PLAYER:
				_add_effect(event.cell, Color("ffca5c"), 0.18, 0.65)
		SimulationEvent.Type.DEATH_BORDER:
			_add_effect(event.cell, Color("dce5ff"), 0.25, 0.8)
		SimulationEvent.Type.DEATH_STAGNATION:
			_add_effect(event.cell, Color("ffffff"), 0.2, 0.55)


func _add_effect(
	cell: Vector2i,
	color: Color,
	duration: float,
	radius: float,
) -> void:
	_effects.append({
		"cell": cell,
		"color": color,
		"time": duration,
		"duration": duration,
		"radius": radius,
	})
	queue_redraw()


func _cell_center(cell: Vector2i, board_rect: Rect2, cell_size: float) -> Vector2:
	return board_rect.position + Vector2(cell) * cell_size + Vector2.ONE * cell_size * 0.5


func _board_layout() -> Dictionary:
	var viewport_size: Vector2 = get_viewport_rect().size
	var available_width: float = maxf(1.0, viewport_size.x - SIDE_MARGIN * 2.0)
	var available_height: float = maxf(1.0, viewport_size.y - TOP_MARGIN - BOTTOM_MARGIN)
	var cell_size: float = minf(
		available_width / float(_state.width),
		available_height / float(_state.height),
	)
	var board_size: Vector2 = Vector2(_state.width, _state.height) * cell_size
	var board_position: Vector2 = Vector2(
		(viewport_size.x - board_size.x) * 0.5,
		TOP_MARGIN + (available_height - board_size.y) * 0.5,
	)
	return {
		"rect": Rect2(board_position, board_size),
		"cell_size": cell_size,
	}
