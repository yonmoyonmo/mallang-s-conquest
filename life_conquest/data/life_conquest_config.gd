class_name LifeConquestConfig
extends Resource
## Tunable values for the turn-based cellular territory prototype.

enum BoardSize {
	SMALL,
	MEDIUM,
	LARGE,
}

const BOARD_SIZE_NAMES: Array[String] = ["소형", "중형", "대형"]
const BOARD_DIMENSIONS: Array[Vector2i] = [
	Vector2i(18, 28),
	Vector2i(24, 36),
	Vector2i(30, 45),
]
const BOARD_ROUNDS: Array[int] = [10, 15, 20]

@export_group("Board")
@export_enum("소형", "중형", "대형") var board_size: int = BoardSize.MEDIUM
@export_range(8, 64, 1) var grid_width: int = 24
@export_range(8, 96, 1) var grid_height: int = 36

@export_group("Match")
@export_range(1, 20, 1) var total_rounds: int = 8
@export_range(1, 60, 1) var generations_per_round: int = 15
@export_range(1, 20, 1) var energy_per_round: int = 12
@export_range(0.05, 1.0, 0.05) var generation_interval: float = 0.16
@export_range(0.0, 2.0, 0.05) var placement_pause: float = 0.3

@export_group("Debug")
@export var random_seed: int = 20261015

@export_group("Colors")
@export var background_color: Color = Color("0d1119")
@export var board_color: Color = Color("151d2a")
@export var grid_color: Color = Color(0.45, 0.52, 0.65, 0.16)
@export var player_color: Color = Color("5ce1c4")
@export var enemy_color: Color = Color("ff6b7a")
@export var player_territory_color: Color = Color(0.18, 0.55, 0.49, 0.32)
@export var enemy_territory_color: Color = Color(0.65, 0.20, 0.27, 0.32)


func apply_board_size(value: int) -> void:
	board_size = clampi(value, BoardSize.SMALL, BoardSize.LARGE)
	var dimensions := BOARD_DIMENSIONS[board_size]
	grid_width = dimensions.x
	grid_height = dimensions.y
	total_rounds = BOARD_ROUNDS[board_size]


func board_size_name() -> String:
	return BOARD_SIZE_NAMES[board_size]
