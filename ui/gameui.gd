extends Control

func _ready():
	self.visible = true

	Maps.load("res://models/car.tscn")
	
	get_viewport().connect("size_changed", Callable(self, "on_window_resize"))
	get_viewport().connect("focus_exited", Callable(self, "on_window_blur"))

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
		if !get_node("/root/Car").autopilot:
			self.visible = !self.visible
	
	if !get_node("/root/Car").autopilot:
		Sounds.set_paused_sounds(GameUI.visible, ["crash"])
		
	pass
	
func on_start_game_pressed():
	self.visible = false
	get_node("/root/Car").autopilot = false
	get_node("MainMenu/BoxContainer/BoxContainer/StartButton").text = "Resume Game"

func on_options_pressed():
	

func on_button_mouse_entered():
	Sounds.play_sound("res://sounds/ui/hover.wav")

func on_button_mouse_clicked():
	Sounds.play_sound("res://sounds/ui/click.ogg")
