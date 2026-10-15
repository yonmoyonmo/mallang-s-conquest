class_name BattleState
extends RefCounted
## Data-only snapshot of the logical battlefield.

enum Faction {
	NONE,
	PLAYER,
	ENEMY,
}

enum CellStatus {
	EMPTY,
	ACTIVE,
	COLLAPSING,
}

enum Pattern {
	RADIAL,
}

var width: int
var height: int
var size: int

var faction: PackedInt32Array
var lineage_id: PackedInt32Array
var pattern: PackedInt32Array
var direction: PackedInt32Array
var age: PackedInt32Array
var generation: PackedInt32Array
var cell_status: PackedInt32Array

var active_min_x: int = 0
var active_min_y: int = 0
var active_max_x: int
var active_max_y: int


func _init(board_width: int = 1, board_height: int = 1) -> void:
	width = board_width
	height = board_height
	size = width * height
	active_max_x = width - 1
	active_max_y = height - 1

	faction.resize(size)
	lineage_id.resize(size)
	pattern.resize(size)
	direction.resize(size)
	age.resize(size)
	generation.resize(size)
	cell_status.resize(size)
	clear()


func clear() -> void:
	faction.fill(Faction.NONE)
	lineage_id.fill(0)
	pattern.fill(Pattern.RADIAL)
	direction.fill(0)
	age.fill(0)
	generation.fill(0)
	cell_status.fill(CellStatus.EMPTY)
	active_min_x = 0
	active_min_y = 0
	active_max_x = width - 1
	active_max_y = height - 1


func clone() -> BattleState:
	var result := BattleState.new(width, height)
	result.faction = faction.duplicate()
	result.lineage_id = lineage_id.duplicate()
	result.pattern = pattern.duplicate()
	result.direction = direction.duplicate()
	result.age = age.duplicate()
	result.generation = generation.duplicate()
	result.cell_status = cell_status.duplicate()
	result.active_min_x = active_min_x
	result.active_min_y = active_min_y
	result.active_max_x = active_max_x
	result.active_max_y = active_max_y
	return result


func index_of(cell: Vector2i) -> int:
	return cell.y * width + cell.x


func cell_of(index: int) -> Vector2i:
	return Vector2i(index % width, index / width)


func contains(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < width and cell.y >= 0 and cell.y < height


func is_active_cell(cell: Vector2i) -> bool:
	return (
		contains(cell)
		and cell.x >= active_min_x
		and cell.x <= active_max_x
		and cell.y >= active_min_y
		and cell.y <= active_max_y
	)


func is_active_index(index: int) -> bool:
	return is_active_cell(cell_of(index))


func clear_cell(index: int) -> void:
	faction[index] = Faction.NONE
	lineage_id[index] = 0
	pattern[index] = Pattern.RADIAL
	direction[index] = 0
	age[index] = 0
	generation[index] = 0
	cell_status[index] = CellStatus.EMPTY


func count_faction(target_faction: int) -> int:
	var count := 0
	for value in faction:
		if value == target_faction:
			count += 1
	return count
