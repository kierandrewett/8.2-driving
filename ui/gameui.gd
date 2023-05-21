extends Control

var slomo_tween = null

var map_loaded = null
var maps_loaded = []
var current_map_index = 0
var car_loaded = null
var map_start_positions = []

func _ready():
	self.visible = true

	car_loaded = Maps.load("res://models/car.tscn")
	map_loaded = Maps.load("res://maps/background01.tscn")
	
	get_viewport().connect("size_changed", Callable(self, "on_window_resize"))
	get_viewport().connect("focus_exited", Callable(self, "on_window_blur"))
	
	get_node("Options").visible = false
	
	slomo_tween = create_tween()

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
	GameUI.visible = true

func _process(delta):
	if Input.is_action_just_pressed("open_gameui"):
		if get_node("Options").visible:
			on_options_pressed()
		
		var car = get_node("/root/Car")
		if !car.autopilot and !car.crashed:
			self.visible = !self.visible
	
	if get_node_or_null("/root/Car") and !get_node_or_null("/root/Car").autopilot and get_node_or_null("/root/Car").current_state != "complete":
		Sounds.set_paused_sounds(GameUI.visible, ["master", "crash"])
		
	pass
	
func on_start_game_pressed():
	var car = get_node_or_null("/root/Car")
	
	if !car:
		return
	
	self.visible = false
	GameUI.get_node("Gradient").modulate.a = 1
	
	if car.autopilot:
		GameUI.map_loaded.queue_free()
		GameUI.map_loaded = null
		GameUI.load_maps()
	
	car.autopilot = false
	NavMeshes.stop()
	
	set_button_text("Resume Game")
	
	var current_state = car.current_state
	print("current_state ", current_state)
	
	if car.crashed or current_state == "complete":
		car = get_node("/root/Car")
		
		if current_state == "complete":				
			if !car.autopilot and current_map_index >= len(maps_loaded):
				return

		if car.crashed:
			print(current_map_index)
			goto_map(current_map_index)
			car.reset()
			
		car.reset()

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

func preload_map(id):
	var map = Maps.load("res://maps/%s.tscn" % [id], 0)
	var map_offset = 0
	
	if map:
		if len(maps_loaded) >= 1:
			var prev_map = maps_loaded[len(maps_loaded) - 1]
			var let = Utils.get_node_by_name(prev_map, "LevelEndBrush")
			
			map_offset += let.position.z + prev_map.position.z

		map.position.z -= (map_offset / -1) + 40
	
		maps_loaded.append(map)
		
		var lst = Utils.get_node_by_name(map, "LevelStartBrush")
		map_start_positions.append(map.get_node("RoadLevel").position.z)
	
func goto_map(index):
	if index >= len(maps_loaded):
		print("No more maps to load :(")
		return
	
	map_loaded = maps_loaded[index]
	
	var car = get_node_or_null("/root/Car")
	
	if index == current_map_index:
		if car:
			car.global_position.z = map_start_positions[current_map_index]
	
	current_map_index = index
	
	if car.autopilot:
		NavMeshes.play(map_loaded.scene_file_path.split("res://maps/")[1].replace(".tscn", ""))
	
func load_maps():
	for i in range(0, 2):
		preload_map("dg_%02d" % (i + 1))
		
	goto_map(0)
