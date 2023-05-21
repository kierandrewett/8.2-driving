extends Node

func _ready():
	pass

func load(path, offset = 0):
	if !ResourceLoader.exists(path):
		print("Resource at '%s' not found." % path)
		return null
		
	var res = ResourceLoader.load(path)
	var initted = res.instantiate()
	get_window().add_child.call_deferred(initted)
	
	if offset != 0:
		initted.position.z -= offset
	
	return initted
	
func fixup_map(node = null):
	print("Fixing up map...")
	
	if !get_node_or_null("/root/Car/Collision"):
		return
	
	if node:
		var all_road_nodes = []
		
		Utils.get_all_nodes_by_name(node, "RoadContainer", all_road_nodes)
		Utils.get_all_nodes_by_name(node, "RoadLevel", all_road_nodes)

		var car_shape = get_node("/root/Car/Collision").shape.size

		for road in all_road_nodes:
			print(road.name, " ", road.get_parent().name, " ", road.get_parent().get_parent().name, " ")
			
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
				
			if road.name == "RoadContainer" and road.get_parent().name == "Road" and road.get_parent().get_parent().name == "Level" or road.get_parent().get_parent().name.begins_with("@Level@"):
				road.get_parent().queue_free()

			if "position" in road and road.name == "RoadLevel" or road.name == "RoadContainer":
				road.position.y -= car_shape.x * 2
				road.position.x += car_shape.z * 2
	
			if road.name == "RoadLevel":
				road.position.z -= 1.9
