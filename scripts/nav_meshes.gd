extends Node

var playing_mesh = false
var mesh = {}
var playback_clock = 0.0
var playback_tick = 0

var fps = 0.1

var previous_point = null

func play(name):
	if get_node_or_null("/root/GameUINavMeshRecorder"):
		var nmrecorder = get_node_or_null("/root/GameUINavMeshRecorder")
		if nmrecorder.recording:
			print("Cannot play nav mesh as recorder is recording.")
			return
	
	var path = "res://maps/nav_meshes/%s.json" % [name]
	
	var file_buff = FileAccess.open(path, FileAccess.READ)
	var data = file_buff.get_as_text()
	var json = JSON.parse_string(data)
	
	if json != null:
		stop()
		playing_mesh = true
		mesh = json
		
		clock_tick()
	else:
		print("Error loading nav mesh at '%s', closing..." % [path])
		get_tree().quit(1)

func clock_tick():
	get_tree().create_timer(fps).timeout.connect(func ():
		if !playing_mesh:
			return clock_tick()

		playback_clock += fps
		act(playback_tick)
		playback_tick += 1
		clock_tick()
	)

func act(tick):
	if len(mesh.get("points")) <= tick:
		print("Out of frames to play, stopping nav mesh...")
		stop()
		return
	
	var point = mesh.get("points")[tick]
	var car = get_node_or_null("/root/Car")
	
	if !car:
		return
	
	if car.velocity.length() <= 0:
		return
	
	car.global_position.y = point.y
	
	car.velocity = Vector3(point.velocity[0], point.velocity[1], point.velocity[2])
	
	if previous_point:
		if previous_point.lane != point.lane:
			print("Moving lanes")
			car.move_to_lane(point.lane)
		elif !car.is_moving_lanes:
			print("moving z")
			create_tween().tween_property(car, "global_position:x", point.x, 0.1)
			create_tween().tween_property(car, "global_position:z", point.z, 0.1)
	
	previous_point = point
	
func stop():
	mesh = {}
	playing_mesh = false
	playback_clock = 0.0
	playback_tick = 0
