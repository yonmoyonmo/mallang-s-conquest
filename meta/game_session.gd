extends Node
## Owns persistent progression and the transient request passed into a battle scene.

const SAVE_PATH := "user://progress.json"
const SAVE_VERSION := 1

var cleared_rivals: Array[int] = []
var unlocked_patterns: Array[int] = GameData.STARTING_PATTERNS.duplicate()
var unlocked_themes: Array[String] = ["default"]
var deck: Array[int] = GameData.DEFAULT_DECK.duplicate()
var mallang_theme := "default"
var territory_theme := "default"
var selected_rival := 0
var free_board_size := 1
var free_energy := 12
var free_opponent := -1
var music_enabled := true
var sound_enabled := true
var haptics_enabled := true
var evolution_speed := 1
var battle_request: Dictionary = {}
var last_result: Dictionary = {}


func _ready() -> void:
	load_progress()


func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	var data: Dictionary = parsed
	cleared_rivals = _int_array(data.get("cleared_rivals", []))
	unlocked_patterns = _int_array(data.get("unlocked_patterns", GameData.STARTING_PATTERNS))
	unlocked_themes = _string_array(data.get("unlocked_themes", ["default"]))
	deck = _int_array(data.get("deck", GameData.DEFAULT_DECK))
	while deck.size() < 4:
		deck.append(-1)
	deck.resize(4)
	mallang_theme = _valid_theme(String(data.get("mallang_theme", "default")))
	territory_theme = _valid_theme(String(data.get("territory_theme", "default")))
	music_enabled = bool(data.get("music_enabled", true))
	sound_enabled = bool(data.get("sound_enabled", true))
	haptics_enabled = bool(data.get("haptics_enabled", true))
	evolution_speed = clampi(int(data.get("evolution_speed", 1)), 0, 2)
	_sanitize_progress()


func save_progress() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("진행 데이터를 저장할 수 없음: %s" % SAVE_PATH)
		return
	var data := {
		"version": SAVE_VERSION,
		"cleared_rivals": cleared_rivals,
		"unlocked_patterns": unlocked_patterns,
		"unlocked_themes": unlocked_themes,
		"deck": deck,
		"mallang_theme": mallang_theme,
		"territory_theme": territory_theme,
		"music_enabled": music_enabled,
		"sound_enabled": sound_enabled,
		"haptics_enabled": haptics_enabled,
		"evolution_speed": evolution_speed,
	}
	file.store_string(JSON.stringify(data, "\t"))


func is_rival_cleared(index: int) -> bool:
	return index in cleared_rivals


func is_final_unlocked() -> bool:
	for index in GameData.non_final_indices():
		if not is_rival_cleared(index):
			return false
	return true


func current_energy() -> int:
	var normal_clears := 0
	for index in cleared_rivals:
		if index != GameData.FINAL_RIVAL_INDEX:
			normal_clears += 1
	if normal_clears >= 8:
		return 12
	if normal_clears >= 6:
		return 10
	if normal_clears >= 3:
		return 8
	return 6


func prepare_rival_battle(index: int) -> bool:
	if index == GameData.FINAL_RIVAL_INDEX and not is_final_unlocked():
		return false
	selected_rival = clampi(index, 0, GameData.STAGES.size() - 1)
	var stage := GameData.stage(selected_rival)
	battle_request = {
		"mode": "rival",
		"rival": selected_rival,
		"board_size": stage["board_size"],
		"energy": current_energy(),
		"seed": stage["seed"],
		"enemy_patterns": stage["ai_patterns"],
		"deck": deck.duplicate(),
		"player_mallang_theme": mallang_theme,
		"player_territory_theme": territory_theme,
		"enemy_theme": stage["id"],
		"speed": evolution_speed,
	}
	return true


func prepare_free_battle() -> void:
	var opponent := free_opponent
	if opponent < 0:
		var choices: Array[int] = cleared_rivals.duplicate()
		if choices.is_empty():
			choices = GameData.non_final_indices()
		opponent = choices[randi() % choices.size()]
	var stage := GameData.stage(opponent)
	battle_request = {
		"mode": "free",
		"rival": opponent,
		"board_size": free_board_size,
		"energy": free_energy,
		"seed": int(stage["seed"]) + 10000,
		"enemy_patterns": stage["ai_patterns"],
		"deck": deck.duplicate(),
		"player_mallang_theme": mallang_theme,
		"player_territory_theme": territory_theme,
		"enemy_theme": stage["id"],
		"speed": evolution_speed,
	}


func finish_battle(player_territory: int, enemy_territory: int) -> Dictionary:
	var won := player_territory > enemy_territory
	var first_clear := false
	var unlocked_pattern := -1
	var unlocked_theme := ""
	var mode: String = battle_request.get("mode", "free")
	var rival := int(battle_request.get("rival", 0))
	if mode == "rival" and won and not is_rival_cleared(rival):
		first_clear = true
		cleared_rivals.append(rival)
		cleared_rivals.sort()
		var stage := GameData.stage(rival)
		unlocked_pattern = int(stage["pattern"])
		unlocked_theme = String(stage["id"])
		if unlocked_pattern not in unlocked_patterns:
			unlocked_patterns.append(unlocked_pattern)
			unlocked_patterns.sort()
		if unlocked_theme not in unlocked_themes:
			unlocked_themes.append(unlocked_theme)
		_fill_empty_deck_slot(unlocked_pattern)
		save_progress()
	last_result = {
		"won": won,
		"draw": player_territory == enemy_territory,
		"player_territory": player_territory,
		"enemy_territory": enemy_territory,
		"first_clear": first_clear,
		"unlocked_pattern": unlocked_pattern,
		"unlocked_theme": unlocked_theme,
		"rival": rival,
		"mode": mode,
	}
	return last_result


func cycle_deck_slot(slot: int) -> void:
	if slot < 0 or slot >= deck.size():
		return
	var candidates: Array[int] = []
	var filled_slots := 0
	for equipped in deck:
		if equipped >= 0:
			filled_slots += 1
	if deck[slot] < 0 or filled_slots > 1:
		candidates.append(-1)
	for pattern in unlocked_patterns:
		if pattern == deck[slot] or pattern not in deck:
			candidates.append(pattern)
	var current_index := candidates.find(deck[slot])
	deck[slot] = candidates[(current_index + 1) % candidates.size()]
	save_progress()


func cycle_mallang_theme() -> void:
	mallang_theme = _next_theme(mallang_theme)
	save_progress()


func cycle_territory_theme() -> void:
	territory_theme = _next_theme(territory_theme)
	save_progress()


func cycle_free_board_size() -> void:
	free_board_size = (free_board_size + 1) % 3


func cycle_free_energy() -> void:
	var values := [6, 8, 10, 12]
	free_energy = values[(values.find(free_energy) + 1) % values.size()]


func cycle_free_opponent() -> void:
	var options: Array[int] = [-1]
	for rival in cleared_rivals:
		options.append(rival)
	if options.size() == 1:
		for rival in GameData.non_final_indices():
			options.append(rival)
	var current := options.find(free_opponent)
	free_opponent = options[(current + 1) % options.size()]


func reset_progress() -> void:
	cleared_rivals.clear()
	unlocked_patterns = GameData.STARTING_PATTERNS.duplicate()
	unlocked_themes = ["default"]
	deck = GameData.DEFAULT_DECK.duplicate()
	mallang_theme = "default"
	territory_theme = "default"
	battle_request.clear()
	last_result.clear()
	save_progress()


func _fill_empty_deck_slot(pattern: int) -> void:
	var empty_slot := deck.find(-1)
	if empty_slot >= 0:
		deck[empty_slot] = pattern


func _next_theme(current: String) -> String:
	var index := unlocked_themes.find(current)
	return unlocked_themes[(index + 1) % unlocked_themes.size()]


func _valid_theme(value: String) -> String:
	return value if value in unlocked_themes else "default"


func _sanitize_progress() -> void:
	for pattern in GameData.STARTING_PATTERNS:
		if pattern not in unlocked_patterns:
			unlocked_patterns.append(pattern)
	if "default" not in unlocked_themes:
		unlocked_themes.push_front("default")
	for index in range(deck.size()):
		if deck[index] != -1 and deck[index] not in unlocked_patterns:
			deck[index] = -1
	if deck.count(-1) == deck.size():
		deck[0] = unlocked_patterns[0]


func _int_array(value: Variant) -> Array[int]:
	var result: Array[int] = []
	if value is Array:
		for item in value:
			result.append(int(item))
	return result


func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(String(item))
	return result
