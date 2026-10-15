class_name LifeConquestInput
extends Node
## Converts pointer presses into board cells.

signal cell_pressed(cell: Vector2i)

var _renderer: LifeConquestRenderer
var _enabled: bool = true


func configure(renderer: LifeConquestRenderer) -> void:
	_renderer = renderer


func set_input_enabled(value: bool) -> void:
	_enabled = value


func _unhandled_input(event: InputEvent) -> void:
	if not _enabled or _renderer == null:
		return
	var position := Vector2.ZERO
	var pressed := false
	if event is InputEventScreenTouch:
		position = event.position
		pressed = event.pressed
	elif event is InputEventMouseButton:
		position = event.position
		pressed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if not pressed:
		return
	var cell := _renderer.screen_to_cell(position)
	if cell.x < 0:
		return
	cell_pressed.emit(cell)
	get_viewport().set_input_as_handled()
