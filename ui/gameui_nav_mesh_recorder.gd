extends Window

var recording = false
var recording_start = null
var recording_clock = 0.0
var map_name = ""

var data = {}

var nm_fps = NavMeshes.fps

func _ready():
	self.position.x = get_viewport().size.x + self.size.x / 2 + 21
	self.position.y = 33
		
	reset()
	map_name = "dg_01"
	
	if !FileAccess.file_exists("res://maps/nav_meshes/%s.json" % [map_name]):
		record()

	pass # Replace with function body.

func reset():
	recording = false
	recording_clock = 0.0
	recording_start = null
	map_name = ""
	data = {
		"points": []
	}

func record():
	recording = true
	recording_clock = 0.0
	recording_start = Time.get_unix_time_from_system()
	
	data["map"] = map_name
	data["created_at"] = recording_start
	
	clock_tick()

func clock_tick():
	get_tree().create_timer(nm_fps).timeout.connect(func ():
		if GameUI.visible:
			return clock_tick()
		
		recording_clock += nm_fps
		record_point()
		clock_tick()
	)
	
func record_point():	
	var car = get_node("/root/Car")
	var current_lane = car.current_lane
	
	var points: Array = data["points"]
	points.append({
		"x": car.global_position.x,
		"y": car.global_position.y,
		"z": car.global_position.z,
		"lane": current_lane,
		"accelerating": Input.is_action_pressed("accelerate") and !Input.is_action_pressed("brake"),
		"braking": Input.is_action_pressed("brake") and !Input.is_action_pressed("accelerate"),
		"velocity": [car.velocity.x, car.velocity.y, car.velocity.z]
	})
	data["points"] = points

func _process(delta):
	get_node("Data/Container/State").text = "Paused." if GameUI.visible else "Recording..." if recording else "Ready"
	get_node("Data/Container/Duration").visible = false if GameUI.visible else recording
	get_node("Data/Container/Stats").visible = false if GameUI.visible else recording
	get_node("Data/Container/Buttons/RecordButton").disabled = recording
	get_node("Data/Container/Buttons/StopButton").disabled = !recording
	
	if self.visible and recording:
		Engine.time_scale = 0 if GameUI.visible else 1
	
	if GameUI.visible:
		return
	
	var recording_elapsed = Time.get_time_dict_from_unix_time(max(recording_clock, 0))
	
	get_node("Data/Container/Duration").text = "%02d:%02d:%02d" % [recording_elapsed.hour, recording_elapsed.minute, recording_elapsed.second]
	
	get_node("Data/Container/Stats").text = "Points = %d" % [len(data["points"])]
	
	pass

func on_stop_button_pressed():
	var file_buff = FileAccess.open("res://maps/nav_meshes/%s.json" % [data["map"]], FileAccess.WRITE)
	var json = JSON.stringify(data, "    ")
	file_buff.store_string(json)
	reset()

func on_record_button_pressed():
	reset()
	record()
