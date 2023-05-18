extends Node

func get_all_nodes(node = get_tree().root, list = []):
	list.append(node)
	
	for child in node.get_children():
		get_all_nodes(child, list)
		
	return list

func get_all_nodes_of_type(node = get_tree().root, type = "", list = []):
	if node.get_class() == type:
		list.append(node)
	
	for child in node.get_children():
		get_all_nodes_of_type(child, type, list)
		
	return list
	
func get_all_nodes_by_name(node = get_tree().root, name = "", list = []):
	if node != null:
		if "name" in node and node.name == name:
			list.append(node)
		
		if "get_children" in node:
			for child in node.get_children():
				get_all_nodes_by_name(child, name, list)
		
	return list

func get_node_by_name(node = get_tree().root, name = ""):
	var list = []
	
	get_all_nodes_by_name(node, name, list)
	
	while list.size() == 1:
		return list[0]
