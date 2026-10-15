extends Node
## Owns the top-level battle lifecycle and user interface.

@onready var _battle: Battle = $World/Battle
@onready var _player_label: Label = $GUI/TopBar/PlayerLabel
@onready var _enemy_label: Label = $GUI/TopBar/EnemyLabel
@onready var _status_label: Label = $GUI/TopBar/StatusLabel
@onready var _restart_overlay: ColorRect = $GUI/RestartOverlay
@onready var _restart_button: Button = $GUI/RestartOverlay/RestartButton


func _ready() -> void:
	_battle.stats_updated.connect(_on_stats_updated)
	_battle.battle_finished.connect(_on_battle_finished)
	_battle.waiting_for_first_touch.connect(_on_waiting_for_first_touch)
	_restart_button.pressed.connect(_on_restart_pressed)
	_on_waiting_for_first_touch()


func _on_stats_updated(
	player_cells: int,
	enemy_cells: int,
	elapsed_seconds: float,
	_seed: int,
) -> void:
	_player_label.text = "나  %d" % player_cells
	_enemy_label.text = "%d  적" % enemy_cells
	if elapsed_seconds > 0.0:
		_status_label.text = "%02d:%02d" % [
			int(elapsed_seconds / 60.0),
			int(elapsed_seconds) % 60,
		]


func _on_battle_finished(outcome: int) -> void:
	_restart_overlay.visible = true
	match outcome:
		Battle.Outcome.PLAYER_WON:
			_restart_button.text = "승리!\n탭하여 다시 시작"
		Battle.Outcome.ENEMY_WON:
			_restart_button.text = "패배\n탭하여 다시 시작"
		_:
			_restart_button.text = "무승부\n탭하여 다시 시작"


func _on_waiting_for_first_touch() -> void:
	_restart_overlay.visible = false
	_status_label.text = "빈칸을 터치해 시작"


func _on_restart_pressed() -> void:
	_restart_overlay.visible = false
	_battle.restart_battle()
