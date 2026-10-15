class_name LifeConquestState
extends RefCounted
## Data-only snapshot containing separate life and persistent territory layers.

enum Faction {
	NONE,
	PLAYER,
	ENEMY,
}

var width: int
var height: int
var size: int
var life: PackedInt32Array
var territory: PackedInt32Array


func _init(board_width: int = 1, board_height: int = 1) -> void:
	width = board_width
	height = board_height
	size = width * height
	life.resize(size)
	territory.resize(size)
	life.fill(Faction.NONE)
	territory.fill(Faction.NONE)


func clone() -> LifeConquestState:
	var result := LifeConquestState.new(width, height)
	result.life = life.duplicate()
	result.territory = territory.duplicate()
	return result


func contains(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < width and cell.y >= 0 and cell.y < height


func index_of(cell: Vector2i) -> int:
	return cell.y * width + cell.x


func cell_of(index: int) -> Vector2i:
	return Vector2i(index % width, index / width)


func count_life(faction: int) -> int:
	return life.count(faction)


func count_territory(faction: int) -> int:
	return territory.count(faction)
