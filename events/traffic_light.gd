extends Node3D

@onready var car: CharacterBody3D = get_node("/root/Car")
@onready var lights_hud: BoxContainer = get_node("/root/GameUIHud/MarginContainer/LightsContainer")

var light_brightness = 5

var car_in_prox = false

var current_state = "green"

func _ready():
	print("Loaded traffic lights...")
	randomize()
	
	for light in get_lights():
		light.get_node("GreenLight").light_energy = light_brightness
		light.get_node("AmberLight").light_energy = 0
		light.get_node("RedLight").light_energy = 0
	
	get_node("PointArea").connect("body_entered", Callable(self, "on_car_pass_lights"))
	get_node("LightHUDArea").connect("body_entered", Callable(self, "on_car_enter_lights_prox"))
	get_node("LightHUDArea").connect("body_exited", Callable(self, "on_car_leave_lights_prox"))
	
	pass
	
func create_timer(duration):
	var t = Timer.new()
	t.wait_time = duration
	t.one_shot = true
	t.process_callback = Timer.TIMER_PROCESS_PHYSICS
	t.autostart = true
	GameUI.map_loaded.add_child(t)
	
	t.timeout.connect(func ():
		t.queue_free()
		GameUI.traffic_lights_process_timer = null
	)
	
	return t

func get_lights():
	return get_children().filter(func (node: Node3D): 
		return node.scene_file_path == "res://models/traffic_light.tscn"	
	)

func _process(delta):
	if !GameUI.map_loaded and !car.autopilot and !car.crashed:
		return
	
	var first_light = get_lights()[0]

	if first_light.get_node("AmberLight").light_energy == light_brightness:
		current_state = "amber"
	elif first_light.get_node("RedLight").light_energy == light_brightness:
		current_state = "red"
	else:
		current_state = "green"
	
	lights_hud.visible = car_in_prox
		
	var red_light = lights_hud.get_node("NinePatchRect/MarginContainer/BoxContainer/RedLight")
	var amber_light = lights_hud.get_node("NinePatchRect/MarginContainer/BoxContainer/AmberLight")
	var green_light = lights_hud.get_node("NinePatchRect/MarginContainer/BoxContainer/GreenLight")
	
	red_light.modulate.a = 1 if current_state == "red" else 0
	amber_light.modulate.a = 1 if current_state == "amber" else 0
	green_light.modulate.a = 1 if current_state == "green" else 0
	
	if GameUI.traffic_lights_process_timer:
		return
	
	var chance = randf_range(0, 1000)
	
	# Must be between 300-400
	if chance >= 396 and chance <= 400:
		var distance_from_player_to_node = self.global_position.distance_to(car.global_position)

		if distance_from_player_to_node >= 50:
			return

		var lights = get_lights()
		
		for light in lights:
			light.get_node("GreenLight").light_energy = 0
			light.get_node("AmberLight").light_energy = 0
			light.get_node("RedLight").light_energy = 0
		
		for light in lights:
			light.get_node("AmberLight").light_energy = light_brightness
		
		GameUI.traffic_lights_process_timer = create_timer(2)
		GameUI.traffic_lights_process_timer.timeout.connect(func ():			
			for light in lights:
				light.get_node("AmberLight").light_energy = 0
				light.get_node("RedLight").light_energy = light_brightness
					
			GameUI.traffic_lights_process_timer = create_timer(round(randf_range(8, 14)))
			GameUI.traffic_lights_process_timer.timeout.connect(func ():
				for light in lights:
					light.get_node("RedLight").light_energy = 0
					light.get_node("AmberLight").light_energy = light_brightness
				
				GameUI.traffic_lights_process_timer = create_timer(2)
				
				GameUI.traffic_lights_process_timer.timeout.connect(func ():
					for light in lights:
						light.get_node("AmberLight").light_energy = 0
						light.get_node("GreenLight").light_energy = light_brightness
						
					if get_tree():
						GameUI.traffic_lights_process_timer = create_timer(5)
						GameUI.traffic_lights_process_timer.timeout.connect(func ():
							GameUI.traffic_lights_process_timer = null
						)
				)
			)
		)
	
	pass
	
func on_car_pass_lights(body: CharacterBody3D):
	if body.name == "Car" and body is CharacterBody3D and get_node("PointArea").overlaps_body(get_node("/root/Car")):
		if current_state == "red":
			body.deduct_points(20)
		else:
			body.add_points(30)

func on_car_enter_lights_prox(body: CharacterBody3D):
	if body.name == "Car" and body is CharacterBody3D and get_node("LightHUDArea").overlaps_body(get_node("/root/Car")):
		car_in_prox = true
		var animation: AnimationPlayer = get_node("/root/GameUIHud/LightsAnimPlayer")
		animation.play("lights")
		
func on_car_leave_lights_prox(body: CharacterBody3D):
	if body.name == "Car" and body is CharacterBody3D:
		car_in_prox = false
		var animation: AnimationPlayer = get_node("/root/GameUIHud/LightsAnimPlayer")
		animation.stop()
