extends CharacterBody3D

var SPEED = 5
var MIN_DRIVING_VELOCITY = 10
var DRIVING_VELOCITY = 0

var PAUSED_TERMINAL_VELOCITY = Globals.sv_terminal_velocity_idle

var ACCELERATION = Globals.sv_acceleration
var DECELERATION = Globals.sv_deceleration

var ROAD_LOAD_FREQUENCY = Globals.r_road_frequency

var TERMINAL_VELOCITY = Globals.sv_terminal_velocity

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

var autopilot = false

var swerving_x = 0
var swerving_amt = 0

var current_lane = 0

var sound_accelerate_playing = false
var sound_braking_playing = false
var sound_collision_playing = false
var sound_indicator_playing = false

var indicator = false
var indicator_timer: SceneTreeTimer = null

var crashed = false
var crashed_z = 0

var accelerator_tween: Tween = null

func _ready():
	# Prerender 5 roads for us
	for i in range(1, ROAD_LOAD_FREQUENCY):
		render_new_road()
	
	if GameUI.visible:
		camera.position.x -= 1
		autopilot = true

	Utils.get_all_nodes_by_name(get_tree().root, "RoadContainer", all_road_nodes)
	Utils.get_all_nodes_by_name(get_tree().root, "RoadLevel", all_road_nodes)

	var car_shape = get_node("Collision").shape.size

	for road in all_road_nodes:
		# In our map, we add the road in so we know where to put the obstacles
		# Since the obstacles are a child of the Road scene, we need to move 
		# the obstacles outside and then remove the road itself.
		# Removing the road is fine, because we just add it back in the actual game
		if road.get_parent().name == "Road" and road.name == "RoadLevel":
			var parent = road.get_parent()
			var node_to_move = road
			parent.remove_child(node_to_move)
			parent.get_parent().add_child(node_to_move)
			parent.queue_free()
		
		if "position" in road:
			road.position.y -= car_shape.x * 2
			road.position.x += car_shape.z * 2
			
	Sounds.play_sound("res://sounds/engine_idle.wav", get_tree().root, Globals.volume, 1, "engine")
	Sounds.play_sound("res://sounds/engine_acceleration.wav", get_tree().root, -80, 1, "engine_accel")
	accelerator_tween = get_tree().create_tween().set_process_mode(Tween.TWEEN_PROCESS_IDLE)

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
			render_new_road()
	)
		
	road_pieces.append(road_chunk)
	road_index = road_index + 1
	
func reset_camera():
	done_cam_x_reset = true
	create_tween().tween_property(camera, "position:x", 0, 0.25).set_trans(Tween.TRANS_SINE)

func move_to_lane(id):
	if indicator_timer != null:
		indicator_timer = null
	
	var level = get_node("/root/Level")
	
	if id >= level.lanes or id < 0:
		return
		
	indicator = true
	
	var direction = "right" if id < current_lane else "left"
	
	current_lane = id
	is_moving_lanes = true
	var car_shape = get_node("Collision").shape.size
	
	var lane_change_duration = clamp(1 - velocity.length() / 40, 0.1, 0.25)

	create_tween().tween_property(self, "position:x", line_x * id, lane_change_duration).set_trans(Tween.TRANS_SINE)
	create_tween().tween_property(camera, "rotation:z", -line_rotation, lane_change_duration / 4).finished.connect(func ():
		is_moving_lanes = false
		create_tween().tween_property(camera, "rotation:z", 0, lane_change_duration)
	)
	
	if direction == "left":
		create_tween().tween_property(camera, "rotation:y", -line_rotation, lane_change_duration / 6).finished.connect(func ():
			create_tween().tween_property(camera, "rotation:y", 0, lane_change_duration)
		)
	elif direction == "right":
		create_tween().tween_property(camera, "rotation:y", line_rotation, lane_change_duration / 6).finished.connect(func ():
			create_tween().tween_property(camera, "rotation:y", 0, lane_change_duration)
		)
	
	indicator_timer = get_tree().create_timer(1)
	indicator_timer.timeout.connect(func ():
		indicator = false
		Sounds.stop_some_sounds(["indicator"])
		indicator_timer = null
	)
	
func play_engine_braking(type = "short"):
	print("sound_braking_playing ", sound_braking_playing)
	if sound_braking_playing == false:
		sound_braking_playing = true
	
		Sounds.play_sound("res://sounds/engine_%s.wav" % ["brake_short" if type == "short" else "brake_long"], get_tree().root, Globals.volume, randf_range(0.75, 1), "engine_brake").finished.connect(func ():
			sound_braking_playing = false
		)

func play_car_collision():
	if !sound_collision_playing:
		sound_collision_playing = true
		Sounds.play_sound("res://sounds/car_collision.wav", get_tree().root, Globals.volume, 1, "crash")

func play_indicator_tick():
	if !sound_indicator_playing:
		sound_indicator_playing = true
		Sounds.play_sound("res://sounds/indicator_tick.wav", get_tree().root, Globals.volume, 1, "indicator").finished.connect(func ():
			sound_indicator_playing = false
			play_indicator_tick()	
		)

func on_crash():
	print("crash")
	crashed_z = camera.position.x + 10

func _process(delta):
	# start reset vars
	PAUSED_TERMINAL_VELOCITY = Globals.sv_terminal_velocity_idle

	ACCELERATION = Globals.sv_acceleration
	DECELERATION = Globals.sv_deceleration

	ROAD_LOAD_FREQUENCY = Globals.r_road_frequency

	gravity = Globals.sv_gravity

	line_x = Globals.sv_lane_change_x
	line_rotation = Globals.cl_lane_change_shake_degree
	
	# end reset vars
	
	if GameUI.visible and !autopilot:
		return
		
	if indicator:
		play_indicator_tick()

func _physics_process(delta):
	if GameUI.visible and !autopilot:
		return
	
	var collider = get_last_slide_collision()
	
	if collider:
		velocity.z = 0
		play_car_collision()
		Sounds.stop_some_sounds(["engine"])
		create_tween().tween_property(camera, "fov", 45, 0.1)
		if !crashed:
			crashed = true
			on_crash()
		create_tween().tween_property(camera, "position:z", crashed_z, 4)
	else:
		if OS.is_debug_build() and Input.is_action_just_released("car_reset") and !GameUI.visible:
			position.z = 10
		
		if !GameUI.visible and !done_cam_x_reset:
			reset_camera()
			move_to_lane(0)
		
		# Higher modifier = longer to accelerate
		var accel = 0 if GameUI.visible else ACCELERATION / (velocity.length() * 800.0)
		var movement_amount = accel
		var deceleration_amount = 0
		var deceleration_modifier = 4000.0

		for wheel in get_node("Wheels").get_children():
			wheel.rotation.y += 1

		if !GameUI.visible:
			var input_dir = Input.get_vector("moveleft", "moveright", "none", "none")

			if Input.is_action_just_pressed("moveleft"):
				move_to_lane(current_lane - 1)
			elif Input.is_action_just_pressed("moveright"):
				move_to_lane(current_lane + 1)
			
			if Input.is_action_just_pressed("brake"):
				play_engine_braking("short" if velocity.length() < 20 else "long")
			
			if Input.is_action_pressed("brake"):
				deceleration_modifier = 600.0
			elif Input.is_action_just_released("brake"):
				deceleration_modifier = 8000.0
				for sound in Sounds.get_all_sounds_in_sink("engine_accel").values():
					sound.volume_db = -80
					sound_accelerate_playing = false
				
			if Input.is_action_just_pressed("accelerate"):
				print("just pressed")
				for sound in Sounds.get_all_sounds_in_sink("engine_accel").values():
					sound.seek(randf_range(1, 1.5) if sound_accelerate_playing else 0)
					sound.pitch_scale = 1
				
			if Input.is_action_pressed("accelerate"):
				movement_amount = ACCELERATION * (velocity.length() / 400.0)
				if !Input.is_action_pressed("brake"):
					for sound in Sounds.get_all_sounds_in_sink("engine_accel").values():
						create_tween().tween_property(sound, "volume_db", 0, 0.25)
						sound.pitch_scale = 1
						sound_accelerate_playing = true
			else:
				deceleration_amount = DECELERATION * (velocity.length() / deceleration_modifier)
				movement_amount = -deceleration_amount

				# Fade out accelerator if we become too slow
				if velocity.length() <= MIN_DRIVING_VELOCITY + 10:
					for sound in Sounds.get_all_sounds_in_sink("engine_accel").values():
						var vol = max(80 - velocity.length() / 0.2, 0)
						create_tween().tween_property(sound, "volume_db", -vol, 1)
						sound_accelerate_playing = false
				
				for sound in Sounds.get_all_sounds_in_sink("engine_accel").values():
					sound.pitch_scale = clamp(movement_amount / -1 * 10, 0.3, 1)
				
		var movement = max(min(velocity.z - movement_amount, -MIN_DRIVING_VELOCITY), -TERMINAL_VELOCITY)
		velocity.z = move_toward(movement, 0, DRIVING_VELOCITY)

		move_and_slide()
		
		if !is_moving_lanes:
			swerving_x += 1
			swerving_amt = sin(swerving_x * 4) * 0.08
		
		if GameUI.visible and autopilot:
			create_tween().tween_property(camera, "fov", 45, 0.01)
		else:
			create_tween().tween_property(camera, "fov", clamp(velocity.length() * 7 - ((1 - deceleration_amount) * 10), 40, 150), 1)
			create_tween().tween_property(camera, "position:y", clamp(velocity.length() / 20, 3, 20), 1)
			
func setpos(x, y, z):
	position = Vector3(x, y, z)
