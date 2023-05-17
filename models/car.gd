extends CharacterBody3D

var SPEED = 5
var DRIVING_VELOCITY = MIN_DRIVING_VELOCITY

var ACCELERATION = 1
var DECELERATION = 3

var MIN_DRIVING_VELOCITY = 10

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var line_x = 10

var is_moving_lanes = false

func _ready():
	velocity.x = clamp(velocity.x, 0, line_x)

func _physics_process(delta):
	if GameUI.visible:
		DRIVING_VELOCITY = MIN_DRIVING_VELOCITY
		move_and_slide()
		
		return
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("moveleft", "moveright", "", "")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var is_moving_lanes = !(velocity.x == 0 or velocity.x == line_x)

	if direction:
		DRIVING_VELOCITY = min(DRIVING_VELOCITY - DECELERATION, MIN_DRIVING_VELOCITY) * delta
	else:
		DRIVING_VELOCITY += ACCELERATION * delta

	if Input.is_action_just_pressed("moveleft"):
		velocity.x = -line_x
	elif Input.is_action_just_pressed("moveright"):
		velocity.x = line_x
	
	velocity.z = move_toward(velocity.z - 0.1, 0, DRIVING_VELOCITY)

	move_and_slide()
