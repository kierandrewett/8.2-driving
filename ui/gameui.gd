extends Control

var slomo_tween = null

var map_loaded = null
var maps_loaded = []
var current_map_index = 0
var car_loaded = null
var map_start_positions = []
var old_bus_volume = 0

var game_ended = false

var gibs = []

var road_index = 0
var road_pieces = []
var road_car_is_on = 0

var traffic_lights_process_timer: Timer = null

func _ready():
	self.visible = true

	car_loaded = Maps.load("res://models/car.tscn")
	map_loaded = Maps.load("res://maps/background01.tscn")
	
	get_viewport().connect("size_changed", Callable(self, "on_window_resize"))
	get_viewport().connect("focus_exited", Callable(self, "on_window_blur"))
	get_viewport().connect("focus_entered", Callable(self, "on_window_focus"))
	
	get_node("Options").visible = false
	
	slomo_tween = create_tween()
	
	init_resolution()
	
	old_bus_volume = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))
	
	get_node("Screen").visible = false

func render_new_road(on_record = true):	
	var road_chunk = Maps.load("res://models/road.tscn")
	var car_shape = car_loaded.get_node("Collision").shape.size

	road_chunk.get_node("RoadContainer").position.y -= car_shape.x * 2
	road_chunk.get_node("RoadContainer").position.x += car_shape.z * 2
	road_chunk.get_node("RoadContainer").position.z -= road_chunk.get_node("RoadContainer/RoadSurface").size.z * road_index
		
	var bounds: Area3D = road_chunk.get_node("RoadContainer/AreaBounds")
	bounds.body_exited.connect(func (body):
		print(body)
		
		if body.name == self.name:
			render_new_road()
			road_car_is_on = road_car_is_on + 1
	)
		
	if on_record:
		road_pieces.append(road_chunk)
		road_index = road_index + 1

func render_roads():
	# Prerender 5 roads for us
	for i in range(1, Globals.r_road_frequency):
		render_new_road()

func on_window_resize():
	var size = get_viewport_rect().size
	var x = size.x
	var y = size.y

	for node in get_tree().get_nodes_in_group("window_xy"):
		node.set_size(Vector2(x, y))

	for node in get_tree().get_nodes_in_group("window_x"):
		node.set_size(Vector2(x, node.get_size().y))

	for node in get_tree().get_nodes_in_group("window_y"):
		node.set_size(Vector2(node.get_size().x, y))

func on_window_blur():
	old_bus_volume = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))
	
	if visible == false:
		await get_tree().create_timer(0.1).timeout
		if visible == false:
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), -80)
			visible = true
		
func on_window_focus():
	print(old_bus_volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), old_bus_volume)

func _process(delta):
	if Input.is_action_just_pressed("open_gameui"):
		if get_node("Options").visible:
			on_options_pressed()
		
		var car = get_node("/root/Car")
		if !car.autopilot and !car.crashed:
			self.visible = !self.visible
	
	if get_node_or_null("/root/Car") and !get_node_or_null("/root/Car").autopilot and get_node_or_null("/root/Car").current_state != "complete":
		Sounds.set_paused_sounds(GameUI.visible, ["master", "crash"])

	var car = get_node("/root/Car")

	get_node("MainMenu/BoxContainer/BoxContainer/RestartButton").visible = len(maps_loaded) >= 1 and (!car.crashed or game_ended)
	get_node("MainMenu/BoxContainer/BoxContainer/StartButton").visible = !game_ended

	pass
	
func on_start_game_pressed(restart = false):
	var car = get_node_or_null("/root/Car")
	
	if !car:
		return
	
	GameUI.game_ended = false
	GameUI.get_node("Gradient").modulate.a = 1
	
	if car.autopilot and GameUI.map_loaded:
		GameUI.map_loaded.queue_free()
		GameUI.map_loaded = null
		GameUI.load_maps()
		car.reset()
	
	car.autopilot = false
	NavMeshes.stop()
	
	set_button_text("Resume Game")
	
	var current_state = car.current_state
	
	if car.crashed or current_state == "complete" or restart:
		car = get_node("/root/Car")
		
		if current_state == "complete":				
			if !car.autopilot and current_map_index >= len(maps_loaded):
				return

		if car.crashed or restart:
			reload_maps()
			car.reset()
			
		car.reset()
		
		road_index = 0
		
	self.visible = false

func on_restart_game_pressed():
	get_node("Screen").visible = true
	GameUI.map_loaded = null
	get_node("/root/Car").reset()
	
	for map in maps_loaded:
		if map != null:
			map.queue_free()
			
	for i in range(0, 20):
		await get_tree().process_frame
	on_start_game_pressed(true)
	get_node("Screen").visible = false

func on_options_pressed():
	get_node("MainMenu").visible = !get_node("MainMenu").visible
	get_node("Options").visible = !get_node("Options").visible

func on_quit_pressed():
	get_tree().quit()

func on_button_mouse_entered():
	Sounds.play_sound("res://sounds/ui/hover.wav")

func on_button_mouse_clicked():
	Sounds.play_sound("res://sounds/ui/click.ogg")

func set_button_text(text = "Start Game"):
	get_node("MainMenu/BoxContainer/BoxContainer/StartButton").text = text

func on_game_completed():
	var car = get_node("/root/Car")
	visible = true
	car.autopilot = true
	car.crashed = true
	game_ended = true
	car.velocity = Vector3.ZERO
	get_node("MainMenu/BoxContainer/BoxContainer/StartButton").visible = false

func preload_map(id, reloading = false, map_index = -1):
	var map_path = "res://maps/dg_%02d.tscn" % (id + 1)
	var map = Maps.load(map_path, 0)
	var map_offset = 0
	
	if map:
		if !reloading:
			var index = max(len(maps_loaded), 0)
			maps_loaded.insert(index, map)
			
			if index <= 0:
				var lst = Utils.get_node_by_name(map, "LevelStartBrush")
				print(lst.position.z)
				map_start_positions.insert(index, lst.position.z)
			else:
				var lst = Utils.get_node_by_name(maps_loaded[index - 1], "LevelEndBrush")
				map_start_positions.insert(index, -(map_start_positions[index - 1] - lst.position.z))
		else:
			maps_loaded.insert(map_index if reloading and map_index >= 0 else current_map_index, map)
			
		if !reloading:
			map_offset = map_start_positions[len(maps_loaded) - 1]
		else:
			map_offset = map_start_positions[map_index if reloading and map_index >= 0 else current_map_index]
			
		map.position.z += map_offset
	else:
		print("Failed to preload map at '%s'." % [map_path])
	
func goto_map(index, teleport = true):
	if index >= len(maps_loaded):
		print("No more maps to load :(")
		return
	
	map_loaded = maps_loaded[index]
	
	var car = get_node_or_null("/root/Car")
	
	current_map_index = index
	
	if car and teleport:
		var z = map_start_positions[current_map_index]
		
		car.global_position.z = z
	
	if car.autopilot:
		NavMeshes.play(map_loaded.scene_file_path.split("res://maps/")[1].replace(".tscn", ""))
	
func reload_maps():
	for map in maps_loaded:
		if map != null and map.get_parent() != null:
			map.get_parent().remove_child(map)
	
	load_maps(true)
	
func load_maps(reloading = false):
	var car = get_node_or_null("/root/Car")
	if car:
		car.position.z = 0
	
	preload_map(0, reloading, 0)
		
	goto_map(0)
	
func _input(ev):
	if Input.is_action_just_pressed("toggle_fullscreen"):
		Globals.fullscreen = !Globals.fullscreen
		init_resolution()

func init_resolution():
	var primary_screen = DisplayServer.window_get_current_screen()
	var screen = DisplayServer.screen_get_size(primary_screen)
	
	var width = screen.x
	var height = screen.y
	
	if OS.get_name() != "macOS":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, Globals.fullscreen)
	
		if Globals.fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			
			width = round(width / 2)
			height = round(height / 2)

		print("Resolution: %dx%d" % [width, height])

		DisplayServer.window_set_size(Vector2(width, height))

func push_gib(node):
	gibs.append(gibs)
