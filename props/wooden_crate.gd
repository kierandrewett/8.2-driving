extends Node3D

var broken_crate = null

func destroy(car: CharacterBody3D):
	if !broken_crate:
		await get_tree().create_timer(0.01).timeout
		broken_crate = load("res://props/wooden_crate_broken.tscn").instantiate()
		get_parent().add_child(broken_crate)
		broken_crate.global_position = global_position
		
		for node in Utils.get_all_nodes_of_type(broken_crate, "RigidBody3D"):
			node.apply_impulse(Vector3(0.1, 0.1, 0.1))
			get_tree().create_timer(2).timeout.connect(func ():
				if !car.crashed:
					node.queue_free()
			)
		
		visible = false
		await get_tree().create_timer(0.01).timeout
		Sounds.play_sound("res://sounds/collisions/wood%d.wav" % [round(randf_range(1, 3))], get_tree().root, Globals.volume, randf_range(0.8, 1.1), "crash")

func _on_body_entered(body: CharacterBody3D):
	if body.name == "Car" and body is CharacterBody3D:
		destroy(body)
