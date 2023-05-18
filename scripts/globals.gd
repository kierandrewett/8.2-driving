extends Node

@export var sv_acceleration = 10
@export var sv_deceleration = 2000
@export var sv_gravity = 0
@export var sv_lane_change_x = 5
@export var sv_terminal_velocity_idle = 10

@export var cl_lane_change_duration = 0.25
@export var cl_lane_change_shake_degree = 0.1

@export var r_road_frequency = 2

func _ready():
	sv_gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
