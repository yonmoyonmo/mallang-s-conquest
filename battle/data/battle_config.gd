class_name BattleConfig
extends Resource
## Tunable values for one extermination battle.

@export_group("Board")
@export_range(8, 128, 1) var grid_width: int = 36
@export_range(8, 192, 1) var grid_height: int = 64
@export_range(1.0, 30.0, 1.0) var tick_rate: float = 10.0

@export_group("Cells")
@export_range(1, 10, 1) var spread_age_ticks: int = 1
@export_range(1, 4, 1) var radial_min_arms: int = 2
@export_range(1, 4, 1) var radial_max_arms: int = 4
@export_range(2, 120, 1) var cell_lifetime_ticks: int = 18
@export_range(1, 120, 1) var stagnation_ticks: int = 10
@export_range(1, 30, 1) var collapse_delay_ticks: int = 3

@export_group("Border")
@export_range(1.0, 300.0, 1.0) var shrink_start_seconds: float = 30.0
@export_range(0.5, 60.0, 0.5) var shrink_interval_seconds: float = 5.0

@export_group("Enemy AI")
@export_range(0.05, 5.0, 0.05) var ai_min_interval: float = 0.45
@export_range(0.05, 5.0, 0.05) var ai_max_interval: float = 0.85
@export_range(0.0, 2.0, 0.05) var ai_telegraph_seconds: float = 0.3

@export_group("Debug")
@export var random_seed: int = 1337

@export_group("Colors")
@export var background_color: Color = Color("11151f")
@export var board_color: Color = Color("192131")
@export var closed_color: Color = Color("090c12")
@export var grid_color: Color = Color(0.35, 0.42, 0.52, 0.16)
@export var player_color: Color = Color("5ce1c4")
@export var enemy_color: Color = Color("ff6b7a")
