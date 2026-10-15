class_name LifeConquestSimulation
extends RefCounted
## Two independent factional B3/S23 layers with contested-cell resolution.

enum Pattern {
	BLOCK,
	BLINKER,
	GLIDER,
	R_PENTOMINO,
	TOAD,
	BEACON,
	LWSS,
	B_HEPTOMINO,
	PI_HEPTOMINO,
	ACORN,
	PENTADECATHLON,
	QUEEN_BEE,
}

const PATTERN_COUNT := 12
const PATTERN_NAMES: Array[String] = [
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
const PATTERN_COSTS: Array[int] = [2, 3, 4, 5, 4, 4, 6, 6, 6, 6, 6, 6]
const PATTERN_OFFSETS: Array = [
	# Block
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
	# Blinker
	[Vector2i(-1, 0), Vector2i.ZERO, Vector2i(1, 0)],
	# Glider
	[
		Vector2i(0, -1),
		Vector2i(1, 0),
		Vector2i(-1, 1),
		Vector2i(0, 1),
		Vector2i(1, 1),
	],
	# R-pentomino
	[
		Vector2i(0, -1),
		Vector2i(1, -1),
		Vector2i(-1, 0),
		Vector2i(0, 0),
		Vector2i(0, 1),
	],
	# Toad
	[
		Vector2i(-1, 0),
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(-2, 1),
		Vector2i(-1, 1),
		Vector2i(0, 1),
	],
	# Beacon, dense phase
	[
		Vector2i(-1, -1),
		Vector2i(0, -1),
		Vector2i(-1, 0),
		Vector2i(0, 0),
		Vector2i(1, 1),
		Vector2i(2, 1),
		Vector2i(1, 2),
		Vector2i(2, 2),
	],
	# Lightweight spaceship
	[
		Vector2i(-1, -1),
		Vector2i(2, -1),
		Vector2i(-2, 0),
		Vector2i(-2, 1),
		Vector2i(2, 1),
		Vector2i(-2, 2),
		Vector2i(-1, 2),
		Vector2i(0, 2),
		Vector2i(1, 2),
	],
	# B-heptomino
	[
		Vector2i(-1, -1),
		Vector2i(1, -1),
		Vector2i(2, -1),
		Vector2i(-1, 0),
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(0, 1),
	],
	# Pi-heptomino
	[
		Vector2i(-1, -1),
		Vector2i(0, -1),
		Vector2i(1, -1),
		Vector2i(-1, 0),
		Vector2i(1, 0),
		Vector2i(-1, 1),
		Vector2i(1, 1),
	],
	# Acorn
	[
		Vector2i(-2, -1),
		Vector2i(0, 0),
		Vector2i(-3, 1),
		Vector2i(-2, 1),
		Vector2i(1, 1),
		Vector2i(2, 1),
		Vector2i(3, 1),
	],
	# Pentadecathlon
	[
		Vector2i(-2, -1),
		Vector2i(3, -1),
		Vector2i(-4, 0),
		Vector2i(-3, 0),
		Vector2i(-1, 0),
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(2, 0),
		Vector2i(4, 0),
		Vector2i(5, 0),
		Vector2i(-2, 1),
		Vector2i(3, 1),
	],
	# Queen bee
	[
		Vector2i(-2, -3),
		Vector2i(-2, -2),
		Vector2i(0, -2),
		Vector2i(-1, -1),
		Vector2i(1, -1),
		Vector2i(-1, 0),
		Vector2i(2, 0),
		Vector2i(-1, 1),
		Vector2i(1, 1),
		Vector2i(-2, 2),
		Vector2i(0, 2),
		Vector2i(-2, 3),
	],
]
const NEIGHBOR_OFFSETS: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1, 0), Vector2i(1, 0),
	Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
]

var state: LifeConquestState
var generation: int = 0


func _init(width: int, height: int) -> void:
	state = LifeConquestState.new(width, height)


static func pattern_name(pattern: int) -> String:
	if pattern < 0 or pattern >= PATTERN_COUNT:
		return "알 수 없는 말랑"
	return PATTERN_NAMES[pattern]


static func pattern_cost(pattern: int) -> int:
	if pattern < 0 or pattern >= PATTERN_COUNT:
		return 0
	return PATTERN_COSTS[pattern]


static func pattern_offsets(pattern: int, rotation: int = 0) -> Array[Vector2i]:
	var rotated: Array[Vector2i] = []
	if pattern < 0 or pattern >= PATTERN_COUNT:
		return rotated
	for offset: Vector2i in PATTERN_OFFSETS[pattern]:
		var result := offset
		for _turn in range(posmod(rotation, 4)):
			result = Vector2i(-result.y, result.x)
		rotated.append(result)
	return rotated


func can_place_pattern(anchor: Vector2i, pattern: int, rotation: int = 0) -> bool:
	for offset in pattern_offsets(pattern, rotation):
		var cell := anchor + offset
		if not state.contains(cell):
			return false
		if state.life[state.index_of(cell)] != LifeConquestState.Faction.NONE:
			return false
	return true


func place_pattern(
	faction: int,
	anchor: Vector2i,
	pattern: int,
	rotation: int = 0,
) -> bool:
	if not can_place_pattern(anchor, pattern, rotation):
		return false
	for offset in pattern_offsets(pattern, rotation):
		var index := state.index_of(anchor + offset)
		state.life[index] = faction
		state.territory[index] = faction
	return true


func evolve() -> void:
	var previous := state
	var next_state := LifeConquestState.new(previous.width, previous.height)
	next_state.territory = previous.territory.duplicate()

	for index in range(previous.size):
		var player_neighbors := 0
		var enemy_neighbors := 0
		var cell := previous.cell_of(index)
		for offset in NEIGHBOR_OFFSETS:
			var neighbor := cell + offset
			if not previous.contains(neighbor):
				continue
			match previous.life[previous.index_of(neighbor)]:
				LifeConquestState.Faction.PLAYER:
					player_neighbors += 1
				LifeConquestState.Faction.ENEMY:
					enemy_neighbors += 1

		var current_faction := previous.life[index]
		var next_faction := LifeConquestState.Faction.NONE
		var player_claims := _faction_claims_cell(
			current_faction == LifeConquestState.Faction.PLAYER,
			player_neighbors,
		)
		var enemy_claims := _faction_claims_cell(
			current_faction == LifeConquestState.Faction.ENEMY,
			enemy_neighbors,
		)
		if player_claims and enemy_claims:
			if player_neighbors > enemy_neighbors:
				next_faction = LifeConquestState.Faction.PLAYER
			elif enemy_neighbors > player_neighbors:
				next_faction = LifeConquestState.Faction.ENEMY
		elif player_claims:
			next_faction = LifeConquestState.Faction.PLAYER
		elif enemy_claims:
			next_faction = LifeConquestState.Faction.ENEMY

		next_state.life[index] = next_faction
		if next_faction != LifeConquestState.Faction.NONE:
			next_state.territory[index] = next_faction

	state = next_state
	generation += 1


static func _faction_claims_cell(is_alive: bool, friendly_neighbors: int) -> bool:
	if is_alive:
		return friendly_neighbors == 2 or friendly_neighbors == 3
	return friendly_neighbors == 3
