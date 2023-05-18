extends CharacterBody3D

var SPEED = 5
var MIN_DRIVING_VELOCITY = 10
var DRIVING_VELOCITY = 0

var PAUSED_TERMINAL_VELOCITY = Globals.sv_terminal_velocity_idle

var ACCELERATION = Globals.sv_acceleration
var DECELERATION = Globals.sv_deceleration

var LANE_CHANGE_DURATION = Globals.cl_lane_change_duration

var ROAD_LOAD_FREQUENCY = Globals.r_road_frequency

var gravity = Globals.sv_gravity

var line_x = Globals.sv_lane_change_x
var line_rotation = Globals.cl_lane_change_shake_degree

var is_moving_lanes = false

@onready var camera: Camera3D = $Camera

var road: Node = null

var done_cam_x_reset = false

var has_render_roads_called_frame = false

var road_index = 0
var road_pieces = []

var all_road_nodes = []

func _ready():
	# Prerender 4 roads for us
	for i in range(0, 4):
		render_new_road()
	
	if GameUI.visible:
		camera.position.x -= 1

	Utils.get_all_nodes_by_name(get_tree().root, "RoadContainer", all_road_nodes)
	Utils.get_all_nodes_by_name(get_tree().root, "RoadLevel", all_road_nodes)

	var car_shape = get_node("Collision").shape.size

	for road in all_road_nodes:
		if "position" in road:
			print(road)
			road.position.y -= car_shape.x * 2
			road.position.x += car_shape.z * 2

func run_idle_movement():
	move_to_lane(randi() % 2)
	get_tree().create_timer(randi() % 10 + 5).timeout.connect(run_idle_movement())

func render_new_road():	
	var road_chunk = Maps.load("res://models/road.tscn")
	var car_shape = get_node("Collision").shape.size

	road_chunk.get_node("RoadContainer").position.y -= car_shape.x * 2
	road_chunk.get_node("RoadContainer").position.x += car_shape.z * 2
	road_chunk.get_node("RoadContainer").position.z -= road_chunk.get_node("RoadContainer/RoadSurface").size.z * road_index
		
	var bounds: Area3D = road_chunk.get_node("RoadContainer/AreaBounds")
	bounds.body_exited.connect(func (body):
		if body.name == self.name:
			var road_to_remove = road_pieces.pop_front()
			road_to_remove.queue_free()
	)
		
	road_pieces.append(road_chunk)
	road_index = road_index + 1
		
	get_tree().create_timer(0.1).timeout.connect(func ():
		has_render_roads_called_frame = false
	)
	
func reset_camera():
	print("er")
	done_cam_x_reset = true
	create_tween().tween_property(camera, "position:x", 0, 0.25).set_trans(Tween.TRANS_SINE)

func move_to_lane(id):
	is_moving_lanes = true
	var car_shape = get_node("Collision").shape.size
	
	create_tween().tween_property(self, "position:x", line_x * id, LANE_CHANGE_DURATION).set_trans(Tween.TRANS_SINE)
	create_tween().tween_property(camera, "rotation:z", -line_rotation, LANE_CHANGE_DURATION / 2).finished.connect(func ():
		print("done")
		is_moving_lanes = false
		create_tween().tween_property(camera, "rotation:z", 0, LANE_CHANGE_DURATION)
	)

func _process(delta):
	# start reset vars
	PAUSED_TERMINAL_VELOCITY = Globals.sv_terminal_velocity_idle

	ACCELERATION = Globals.sv_acceleration
	DECELERATION = Globals.sv_deceleration

	LANE_CHANGE_DURATION = Globals.cl_lane_change_duration

	ROAD_LOAD_FREQUENCY = Globals.r_road_frequency

	gravity = Globals.sv_gravity

	line_x = Globals.sv_lane_change_x
	line_rotation = Globals.cl_lane_change_shake_degree
	
	# end reset vars
	
	if len(road_pieces) < 1:
		return
		
	var previous_road_surface = road_pieces[len(road_pieces) - 1].get_node("RoadContainer").get_node("RoadSurface")

	if !has_render_roads_called_frame and int(global_position.z) % int(-(previous_road_surface.size.z / ROAD_LOAD_FREQUENCY)) == 0:
		has_render_roads_called_frame = true
		render_new_road()

func _physics_process(delta):	
	var collider = get_last_slide_collision()
	
	if collider:
		velocity.z = 0
		
		get_tree().create_timer(1).timeout.connect(func ():
			get_tree().quit()
		)
	else:
		if Input.is_action_just_released("car_reset") and !GameUI.visible:
			position.z = 10
		
		if !GameUI.visible and !done_cam_x_reset:
			reset_camera()
			move_to_lane(0)
		
		var accel = 0 if GameUI.visible else (ACCELERATION / (global_position.z / -1) / 50.0)
		
		if !GameUI.visible:
			var input_dir = Input.get_vector("moveleft", "moveright", "none", "none")

			if Input.is_action_just_pressed("moveleft"):
				move_to_lane(0)
			elif Input.is_action_just_pressed("moveright"):
				move_to_lane(1)
		
		velocity.z = move_toward(min(velocity.z - accel, -MIN_DRIVING_VELOCITY), 0, DRIVING_VELOCITY)

		move_and_slide()
		
		if GameUI.visible:
			create_tween().tween_property(camera, "fov", 45, 0.01)
		else:
			create_tween().tween_property(camera, "fov", clamp(velocity.length() * 6, 50, 120), 1)

func setpos(x, y, z):
	position = Vector3(x, y, z)
