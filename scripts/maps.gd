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
	
	if get_tree().root.get_node_or_null("blank") == null:
		initted.visible = false
	
	return initted
	
func fixup_map(node = null):
	print("Fixing up map...")
	
	if !get_node_or_null("/root/Car/Collision"):
		return
	
	if node:
		var all_road_nodes = []
		
		Utils.get_all_nodes_by_name(node, "RoadLevel", all_road_nodes)
		Utils.get_all_nodes_by_name(node, "RoadContainer", all_road_nodes)

		var car_shape = get_node("/root/Car/Collision").shape.size

		node.position.y -= car_shape.x * 2
		node.position.x += car_shape.z * 2
