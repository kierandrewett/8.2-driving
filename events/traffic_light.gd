extends Node3D

@onready var car: CharacterBody3D = get_node("/root/Car")

var light_brightness = 5

var current_state = "green"

func _ready():
	print("Loaded traffic lights...")
	randomize()
	
	for light in get_lights():
		light.get_node("GreenLight").light_energy = light_brightness
		light.get_node("AmberLight").light_energy = 0
		light.get_node("RedLight").light_energy = 0
	
	get_node("PointArea").connect("body_entered", Callable(self, "on_car_pass_lights"))
	
	pass
	
func create_timer(duration):
	var t = Timer.new()
	t.wait_time = duration
	t.autostart = true
	get_tree().root.add_child(t)
	
	t.timeout.connect(func ():
		t.queue_free()	
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
	
	if GameUI.traffic_lights_process_timer:
		return
	
	var chance = randf_range(0, 1000)
	
	# Must be between 300-400
	if chance >= 390 and chance <= 400:
		var distance_from_player_to_node = self.global_position.distance_to(car.global_position)

		if distance_from_player_to_node >= 30:
			return
		
		print("set GOT LIGHTS")
		
		var lights = get_lights()
		
		for light in lights:
			light.get_node("GreenLight").light_energy = 0
			light.get_node("AmberLight").light_energy = 0
			light.get_node("RedLight").light_energy = 0
			print("reset lights")
		
		for light in lights:
			light.get_node("AmberLight").light_energy = light_brightness
			print("set amber")
		
		GameUI.traffic_lights_process_timer = create_timer(2)
		GameUI.traffic_lights_process_timer.timeout.connect(func ():			
			for light in lights:
				print("set red")
				light.get_node("AmberLight").light_energy = 0
				light.get_node("RedLight").light_energy = light_brightness
					
			GameUI.traffic_lights_process_timer = create_timer(round(randf_range(8, 14)))
			GameUI.traffic_lights_process_timer.timeout.connect(func ():
				for light in lights:
					print("set amber")
					light.get_node("RedLight").light_energy = 0
					light.get_node("AmberLight").light_energy = light_brightness
				
				GameUI.traffic_lights_process_timer = create_timer(2)
				
				GameUI.traffic_lights_process_timer.timeout.connect(func ():
					for light in lights:
						print("set green")
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
		print("on_car_pass_lights", body)
		
		if current_state == "red":
			body.deduct_points(20)
		elif current_state == "amber":
			body.deduct_points(5)
		else:
			body.add_points(30)
