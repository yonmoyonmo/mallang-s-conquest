extends SceneTree

func _init() -> void:
	assert(GameData.STAGES.size() == 9)
	assert(GameData.non_final_indices().size() == 8)
	var rewards: Array[int] = GameData.STARTING_PATTERNS.duplicate()
	var ids: Array[String] = []
	for stage in GameData.STAGES:
		var reward := int(stage.pattern)
		assert(reward not in rewards)
		rewards.append(reward)
		assert(String(stage.id) not in ids)
		ids.append(String(stage.id))
		assert(int(stage.board_size) in [0, 1, 2])
	assert(rewards.size() == LifeConquestSimulation.PATTERN_COUNT)
	rewards.sort()
	for index in range(LifeConquestSimulation.PATTERN_COUNT):
		assert(rewards[index] == index)
	print("game data tests passed")
	quit()
