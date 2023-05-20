extends Control

var slomo_tween = null

var map_loaded = null
var car_loaded = null

func _ready():
	self.visible = true

	car_loaded = Maps.load("res://models/car.tscn")
	
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
	
	if get_node_or_null("/root/Car") and !get_node_or_null("/root/Car").autopilot:
		Sounds.set_paused_sounds(GameUI.visible, ["master", "crash"])
		
	pass
	
func on_start_game_pressed():
	var car = get_node_or_null("/root/Car")
	
	if !car:
		return
	
	self.visible = false
	GameUI.get_node("Gradient").modulate.a = 1
	
	car.autopilot = false
	NavMeshes.stop()
	
	set_button_text("Resume Game")
	
	if car.crashed:
		if map_loaded:
			map_loaded.queue_free()
			map_loaded = null
	
	if !map_loaded:
		for i in range(0, 4):
			await get_tree().process_frame
		
		car = get_node("/root/Car")
		
		car.reset()
		map_loaded = Maps.load("res://maps/dg_01.tscn", (car.position.z / -1) + 20)

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
