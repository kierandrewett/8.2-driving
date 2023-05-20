extends Node

func _ready():
	pass

func load(path, offset = 0):
	var res = ResourceLoader.load(path)
	var initted = res.instantiate()
	get_window().add_child.call_deferred(initted)
	
	if offset != 0:
		initted.position.z -= offset
	
	return initted
	
func fixup_map(node = null):
	if !get_node_or_null("/root/Car/Collision"):
		return
	
	if node:
		var all_road_nodes = []
		
		Utils.get_all_nodes_by_name(node, "RoadContainer", all_road_nodes)
		Utils.get_all_nodes_by_name(node, "RoadLevel", all_road_nodes)

		var car_shape = get_node("/root/Car/Collision").shape.size

		for road in all_road_nodes:
			# In our map, we add the road in so we know where to put the obstacles
			# Since the obstacles are a child of the Road scene, we need to move 
			# the obstacles outside and then remove the road itself.
			# Removing the road is fine, because we just add it back in the actual game
			if road.get_parent().name == "Road" and road.name == "RoadLevel":
				var parent = road.get_parent()
				var node_to_move = road
				parent.remove_child(node_to_move)
				parent.get_parent().add_child(node_to_move)
				parent.queue_free()

			if "position" in road:
				road.position.y -= car_shape.x * 2
				road.position.x += car_shape.z * 2
	
