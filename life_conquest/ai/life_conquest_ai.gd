class_name LifeConquestAI
extends RefCounted
## Chooses legal pattern placements with deterministic randomness.

var _rng := RandomNumberGenerator.new()
var _allowed_patterns: Array[int] = []


func _init(seed: int, allowed_patterns: Array[int] = []) -> void:
	_rng.seed = seed
	_allowed_patterns = allowed_patterns.duplicate()
	if _allowed_patterns.is_empty():
		for pattern in range(LifeConquestSimulation.PATTERN_COUNT):
			_allowed_patterns.append(pattern)


func choose_placement(
	simulation: LifeConquestSimulation,
	available_energy: int,
) -> Dictionary:
	for _attempt in range(128):
		var pattern := _allowed_patterns[_rng.randi_range(0, _allowed_patterns.size() - 1)]
		if LifeConquestSimulation.pattern_cost(pattern) > available_energy:
			continue
		var rotation := _rng.randi_range(0, 3)
		var anchor := Vector2i(
			_rng.randi_range(1, simulation.state.width - 2),
			_rng.randi_range(1, simulation.state.height - 2),
		)
		if simulation.can_place_pattern(anchor, pattern, rotation):
			return {"anchor": anchor, "pattern": pattern, "rotation": rotation}

	for index in range(simulation.state.size):
		var anchor := simulation.state.cell_of(index)
		for pattern in _allowed_patterns:
			if LifeConquestSimulation.pattern_cost(pattern) > available_energy:
				continue
			for rotation in range(4):
				if simulation.can_place_pattern(anchor, pattern, rotation):
					return {"anchor": anchor, "pattern": pattern, "rotation": rotation}
	return {}
