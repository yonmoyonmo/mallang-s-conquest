extends SceneTree
## Integration check for placement undo and energy refund.

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node_or_null("GameSession")
	if session == null:
		session = load("res://meta/game_session.gd").new()
		session.name = "GameSession"
		root.add_child(session)
	session.free_board_size = LifeConquestConfig.BoardSize.SMALL
	session.free_energy = 6
	session.prepare_free_battle()
	var scene: PackedScene = load("res://life_conquest/life_conquest_battle.tscn")
	var battle: LifeConquestBattle = scene.instantiate()
	root.add_child(battle)
	await process_frame

	battle.select_pattern(LifeConquestSimulation.Pattern.BLOCK)
	var before := battle.current_snapshot()
	battle.call("_on_cell_pressed", Vector2i(5, 5))
	var placed := battle.current_snapshot()
	assert(placed.player_energy == before.player_energy - 2)
	assert(placed.player_territory == before.player_territory + 4)
	battle.call("_on_cell_pressed", Vector2i(10, 10))
	var placed_twice := battle.current_snapshot()
	assert(placed_twice.player_energy == before.player_energy - 4)
	assert(placed_twice.player_territory == before.player_territory + 8)

	battle.undo_last_placement()
	var undone_once := battle.current_snapshot()
	assert(undone_once.player_energy == placed.player_energy)
	assert(undone_once.player_territory == placed.player_territory)

	battle.undo_last_placement()
	var undone := battle.current_snapshot()
	assert(undone.player_energy == before.player_energy)
	assert(undone.player_territory == before.player_territory)

	print("battle undo test passed")
	battle.queue_free()
	quit()
