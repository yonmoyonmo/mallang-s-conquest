class_name SimulationEvent
extends RefCounted
## A data-only fact emitted after a simulation tick.

enum Type {
	CELL_SPAWNED,
	CELL_SPREAD,
	COLLISION,
	DEATH_COMBAT,
	DEATH_NATURAL,
	STAGNATION_WARNING,
	DEATH_STAGNATION,
	DEATH_BORDER,
	INVALID_TOUCH,
	BORDER_SHRUNK,
}

var type: int
var cell: Vector2i
var faction: int
var other_faction: int
var lineage_id: int


func _init(
	event_type: int = Type.CELL_SPAWNED,
	event_cell: Vector2i = Vector2i.ZERO,
	event_faction: int = BattleState.Faction.NONE,
	event_other_faction: int = BattleState.Faction.NONE,
	event_lineage_id: int = 0,
) -> void:
	type = event_type
	cell = event_cell
	faction = event_faction
	other_faction = event_other_faction
	lineage_id = event_lineage_id
