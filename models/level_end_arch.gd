extends Node3D

func _on_body_entered(body: CharacterBody3D):
	if body.name == "Car" and body is CharacterBody3D:
		body.add_points(15)
