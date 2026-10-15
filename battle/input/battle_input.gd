class_name BattleInput
extends Node
## Converts pointer input into logical grid coordinates.

signal cell_touched(cell: Vector2i)

var _renderer: BattleRenderer
var _enabled: bool = true


func configure(renderer: BattleRenderer) -> void:
	_renderer = renderer


func set_input_enabled(value: bool) -> void:
	_enabled = value


func _unhandled_input(event: InputEvent) -> void:
	if not _enabled or _renderer == null:
		return

	var screen_position := Vector2.ZERO
	var was_pressed := false
	if event is InputEventScreenTouch:
		screen_position = event.position
		was_pressed = event.pressed
	elif event is InputEventMouseButton:
		screen_position = event.position
		was_pressed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT

	if not was_pressed:
		return
	var cell := _renderer.screen_to_cell(screen_position)
	if cell.x < 0:
		return
	cell_touched.emit(cell)
	get_viewport().set_input_as_handled()
