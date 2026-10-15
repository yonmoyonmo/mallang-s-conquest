class_name LifeConquestRenderer
extends Node2D
## Draws territory beneath the current Life generation in a single CanvasItem.

const TOP_MARGIN := 104.0
const SIDE_MARGIN := 18.0
const BOTTOM_MARGIN := 142.0

var _config: LifeConquestConfig
var _state: LifeConquestState
var _player_mallang_theme: StringName = &"default"
var _player_territory_theme: StringName = &"default"
var _enemy_theme: StringName = &"default"
var _player_mallang_texture: Texture2D
var _player_territory_texture: Texture2D
var _enemy_mallang_texture: Texture2D
var _enemy_territory_texture: Texture2D


func configure(config: LifeConquestConfig, state: LifeConquestState) -> void:
	_config = config
	_state = state
	_load_theme_textures()
	queue_redraw()


func update_state(state: LifeConquestState) -> void:
	_state = state
	queue_redraw()


func set_themes(player_mallang: StringName, player_territory: StringName, enemy: StringName) -> void:
	_player_mallang_theme = player_mallang
	_player_territory_theme = player_territory
	_enemy_theme = enemy
	_load_theme_textures()
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
	return cell if _state.contains(cell) else Vector2i(-1, -1)


func _draw() -> void:
	if _config == null or _state == null:
		return
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), _config.background_color)
	var layout := _board_layout()
	var board_rect: Rect2 = layout["rect"]
	var cell_size: float = layout["cell_size"]
	draw_rect(board_rect, _config.board_color)

	for index in range(_state.size):
		var cell := _state.cell_of(index)
		var cell_rect := Rect2(
			board_rect.position + Vector2(cell) * cell_size,
			Vector2.ONE * cell_size,
		)
		match _state.territory[index]:
			LifeConquestState.Faction.PLAYER:
				draw_rect(cell_rect, _config.player_territory_color)
				_draw_territory_texture(cell_rect, _config.player_color, _player_territory_texture)
			LifeConquestState.Faction.ENEMY:
				draw_rect(cell_rect, _config.enemy_territory_color)
				_draw_territory_texture(cell_rect, _config.enemy_color, _enemy_territory_texture)

	for x in range(_state.width + 1):
		var x_pos := board_rect.position.x + x * cell_size
		draw_line(
			Vector2(x_pos, board_rect.position.y),
			Vector2(x_pos, board_rect.end.y),
			_config.grid_color,
		)
	for y in range(_state.height + 1):
		var y_pos := board_rect.position.y + y * cell_size
		draw_line(
			Vector2(board_rect.position.x, y_pos),
			Vector2(board_rect.end.x, y_pos),
			_config.grid_color,
		)

	for index in range(_state.size):
		var faction := _state.life[index]
		if faction == LifeConquestState.Faction.NONE:
			continue
		var cell := _state.cell_of(index)
		var cell_rect := Rect2(
			board_rect.position + Vector2(cell) * cell_size,
			Vector2.ONE * cell_size,
		)
		var color := _config.player_color
		if faction == LifeConquestState.Faction.ENEMY:
			color = _config.enemy_color
		var center := (
			board_rect.position
			+ Vector2(cell) * cell_size
			+ Vector2.ONE * cell_size * 0.5
		)
		draw_circle(center, maxf(2.0, cell_size * 0.39), color)
		var texture := _player_mallang_texture
		if faction == LifeConquestState.Faction.ENEMY:
			texture = _enemy_mallang_texture
		_draw_mallang_texture(cell_rect, color, texture)


func _board_layout() -> Dictionary:
	var viewport_size := get_viewport_rect().size
	var available := Vector2(
		viewport_size.x - SIDE_MARGIN * 2.0,
		viewport_size.y - TOP_MARGIN - BOTTOM_MARGIN,
	)
	var cell_size := floorf(minf(
		available.x / float(_state.width),
		available.y / float(_state.height),
	))
	var board_size := Vector2(_state.width, _state.height) * cell_size
	var board_position := Vector2(
		floorf((viewport_size.x - board_size.x) * 0.5),
		floorf(TOP_MARGIN + (available.y - board_size.y) * 0.5),
	)
	return {"rect": Rect2(board_position, board_size), "cell_size": cell_size}


func _load_theme_textures() -> void:
	_player_mallang_texture = _load_texture(ArtCatalog.expected_path(&"theme/mallang", _player_mallang_theme))
	_player_territory_texture = _load_texture(ArtCatalog.expected_path(&"theme/territory", _player_territory_theme))
	_enemy_mallang_texture = _load_texture(ArtCatalog.expected_path(&"theme/mallang", _enemy_theme))
	_enemy_territory_texture = _load_texture(ArtCatalog.expected_path(&"theme/territory", _enemy_theme))


func _load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path, "Texture2D"):
		return null
	return load(path) as Texture2D


func _draw_territory_texture(cell_rect: Rect2, faction_color: Color, texture: Texture2D) -> void:
	if texture == null:
		return
	var tint := faction_color
	tint.a = 0.36
	draw_texture_rect(texture, cell_rect, false, tint)


func _draw_mallang_texture(cell_rect: Rect2, faction_color: Color, texture: Texture2D) -> void:
	if texture == null:
		return
	var texture_size := Vector2(texture.get_size())
	var max_scale := minf(
		cell_rect.size.x / texture_size.x,
		cell_rect.size.y / texture_size.y,
	)
	var integer_scale := maxf(1.0, floorf(max_scale))
	var draw_size := texture_size * integer_scale
	if draw_size.x > cell_rect.size.x or draw_size.y > cell_rect.size.y:
		draw_size = texture_size * max_scale
	var draw_rect := Rect2(cell_rect.get_center() - draw_size * 0.5, draw_size)
	draw_texture_rect(texture, draw_rect, false, faction_color)
