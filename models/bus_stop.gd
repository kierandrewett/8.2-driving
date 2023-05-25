extends Node3D

func shatter():
	get_node("Glass").visible = false
	
	var shattered = load("res://models/bus_stop_glass_shatter.tscn").instantiate()
	get_tree().root.add_child(shattered)
	shattered.global_position = global_position
	shattered.rotation = rotation
	shattered.scale = Vector3(9.234, 9.234, 9.234)
