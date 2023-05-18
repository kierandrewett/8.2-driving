extends Node

@export var sv_acceleration = 5
@export var sv_deceleration = 10
@export var sv_gravity = 0
@export var sv_lane_change_x = 5
@export var sv_terminal_velocity = 80
@export var sv_terminal_velocity_idle = 10

@export var cl_lane_change_shake_degree = 0.05

@export var r_road_frequency = 10

@export var volume = 1

func _ready():
	sv_gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
