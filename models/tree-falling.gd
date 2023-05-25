extends Node

func body_entered(body: CharacterBody3D):
	if body.name == "Car" and body is CharacterBody3D:
		if get_node_or_null("TreeFall"):
			get_node("TreeFall").play("fall")
			
		if get_node_or_null("BusStop"):
			var bus_stop = get_node_or_null("BusStop")
			bus_stop.shatter()
