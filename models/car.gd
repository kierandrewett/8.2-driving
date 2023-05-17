extends CharacterBody3D

var SPEED = 5
var MIN_DRIVING_VELOCITY = 10
var DRIVING_VELOCITY = 0

var PAUSED_TERMINAL_VELOCITY = 10

var ACCELERATION = 10
var DECELERATION = 5

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var line_x = 10

var is_moving_lanes = false

@onready var camera: Camera3D = $Camera

func _ready():
	velocity.x = clamp(velocity.x, 0, line_x)

func _physics_process(delta):
	var input_dir = Input.get_vector("moveleft", "moveright", "none", "none")

	if Input.is_action_just_pressed("moveleft"):
		velocity.x = -line_x
	elif Input.is_action_just_pressed("moveright"):
		velocity.x = line_x
	
	velocity.z = move_toward(clamp(velocity.z - 0.1, 0, -PAUSED_TERMINAL_VELOCITY), 0, DRIVING_VELOCITY)

	move_and_slide()
