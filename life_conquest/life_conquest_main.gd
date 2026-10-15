extends Node
## Top-level UI for the Life-based territory battle.

@onready var _battle: LifeConquestBattle = $World/LifeConquestBattle
@onready var _menu_button: Button = $GUI/TopBar/MenuButton
@onready var _round_label: Label = $GUI/TopBar/RoundLabel
@onready var _score_label: Label = $GUI/TopBar/ScoreLabel
@onready var _energy_label: Label = $GUI/TopBar/EnergyLabel
@onready var _status_label: Label = $GUI/StatusLabel
@onready var _pattern_buttons: Array[Button] = [
	$GUI/Controls/Pattern1,
	$GUI/Controls/Pattern2,
	$GUI/Controls/Pattern3,
	$GUI/Controls/Pattern4,
]
@onready var _rotate_button: Button = $GUI/Controls/RotateButton
@onready var _undo_button: Button = $GUI/Controls/UndoButton
@onready var _evolve_button: Button = $GUI/Controls/EvolveButton
@onready var _result_overlay: ColorRect = $GUI/ResultOverlay
@onready var _result_label: Label = $GUI/ResultOverlay/Panel/ResultLabel
@onready var _reward_label: Label = $GUI/ResultOverlay/Panel/RewardLabel
@onready var _retry_button: Button = $GUI/ResultOverlay/Panel/Actions/RetryButton
@onready var _exit_button: Button = $GUI/ResultOverlay/Panel/Actions/ExitButton

var _pattern_button_group := ButtonGroup.new()
var _rotation := 0
var _can_undo := false
var _deck_patterns: Array[int] = []


func _ready() -> void:
	for pattern in GameSession.battle_request.get("deck", GameData.DEFAULT_DECK):
		_deck_patterns.append(int(pattern))
	while _deck_patterns.size() < 4:
		_deck_patterns.append(-1)
	_battle.match_updated.connect(_on_match_updated)
	_battle.selection_changed.connect(_on_selection_changed)
	_battle.undo_availability_changed.connect(_on_undo_availability_changed)
	_battle.match_finished.connect(_on_match_finished)
	for index in range(_pattern_buttons.size()):
		var button := _pattern_buttons[index]
		button.button_group = _pattern_button_group
		button.pressed.connect(_on_pattern_pressed.bind(index))
		var pattern := _deck_patterns[index]
		button.text = "빈 칸" if pattern < 0 else _pattern_button_text(pattern)
		button.disabled = pattern < 0
	_rotate_button.pressed.connect(_battle.rotate_pattern)
	_undo_button.pressed.connect(_battle.undo_last_placement)
	_evolve_button.pressed.connect(_battle.end_placement)
	_retry_button.pressed.connect(_on_restart_pressed)
	_exit_button.pressed.connect(_on_menu_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)
	_configure_icon_button(_rotate_button, &"rotate", "↻")
	_configure_icon_button(_undo_button, &"undo", "취소")
	_configure_icon_button(_evolve_button, &"evolve", "진화")
	for pattern in _deck_patterns:
		if pattern >= 0:
			_battle.select_pattern(pattern)
			break
	_apply_snapshot()


func _apply_snapshot() -> void:
	var snapshot := _battle.current_snapshot()
	if snapshot.is_empty():
		return
	_on_match_updated(
		snapshot["round"],
		snapshot["total_rounds"],
		snapshot["generation"],
		snapshot["player_territory"],
		snapshot["enemy_territory"],
		snapshot["player_energy"],
		"패턴을 놓을 빈 공간을 터치",
		true,
	)
	_on_selection_changed(
		snapshot["pattern"],
		snapshot["pattern_name"],
		snapshot["rotation"],
		snapshot["pattern_cost"],
	)


func _on_match_updated(
	round_number: int,
	total_rounds: int,
	_generation: int,
	player_territory: int,
	enemy_territory: int,
	player_energy: int,
	status: String,
	placement_enabled: bool,
) -> void:
	_round_label.text = "라운드 %d/%d" % [round_number, total_rounds]
	_score_label.text = "나 %d  :  %d 적" % [player_territory, enemy_territory]
	_energy_label.text = "말랑력 %d" % player_energy
	_status_label.text = status
	for button in _pattern_buttons:
		var index := _pattern_buttons.find(button)
		button.disabled = not placement_enabled or _deck_patterns[index] < 0
	_rotate_button.disabled = not placement_enabled
	_undo_button.disabled = not placement_enabled or not _can_undo
	_evolve_button.disabled = not placement_enabled


func _on_selection_changed(
	pattern: int,
	_pattern_name: String,
	rotation: int,
	_cost: int,
) -> void:
	_rotation = rotation
	for index in range(_pattern_buttons.size()):
		_pattern_buttons[index].button_pressed = _deck_patterns[index] == pattern
	_update_rotate_button()


func _on_pattern_pressed(deck_index: int) -> void:
	if _deck_patterns[deck_index] >= 0:
		_battle.select_pattern(_deck_patterns[deck_index])


func _on_undo_availability_changed(enabled: bool) -> void:
	_can_undo = enabled
	_undo_button.disabled = not enabled


func _on_match_finished(player_territory: int, enemy_territory: int) -> void:
	_result_overlay.visible = true
	var result := GameSession.finish_battle(player_territory, enemy_territory)
	var outcome := "무승부"
	if result.won: outcome = "정복 성공"
	elif not result.draw: outcome = "정복 실패"
	_result_label.text = "%s\n%d : %d" % [outcome, player_territory, enemy_territory]
	_reward_label.text = ""
	if result.first_clear:
		_reward_label.text = "새 패턴: %s\n라이벌 말랑이·점령 셀 스킨 해금" % LifeConquestSimulation.pattern_name(result.unlocked_pattern)
	elif result.mode == "rival" and result.won:
		_reward_label.text = "이미 정복한 라이벌 · 자유롭게 재도전 가능"


func _on_restart_pressed() -> void:
	_result_overlay.visible = false
	_battle.restart_match()
	_apply_snapshot()


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://main/main.tscn")


func _pattern_button_text(pattern: int) -> String:
	var short_name := LifeConquestSimulation.pattern_name(pattern).trim_suffix(" 말랑")
	return "%s\n%d" % [short_name, LifeConquestSimulation.pattern_cost(pattern)]


func _configure_icon_button(button: Button, icon_id: StringName, fallback: String) -> void:
	var path := ArtCatalog.expected_path(&"ui/icon", icon_id)
	if ResourceLoader.exists(path, "Texture2D"):
		button.icon = load(path) as Texture2D
		button.expand_icon = true
		button.text = ""
	else:
		button.text = fallback
	match icon_id:
		&"rotate":
			button.tooltip_text = "시계방향 회전"
		&"undo":
			button.tooltip_text = "이번 라운드의 마지막 배치 취소"
		_:
			button.tooltip_text = "진화 시작"


func _update_rotate_button() -> void:
	var angle_text := "%d°" % (_rotation * 90)
	if _rotate_button.icon != null:
		_rotate_button.text = angle_text
	else:
		_rotate_button.text = "↻\n%s" % angle_text
