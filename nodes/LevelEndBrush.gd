extends Area3D

var level_ended = false
var hit_node = null

func _on_body_entered(node):
	print(node)
	if node.name == "Car" and node is CharacterBody3D:		
		if !level_ended:
			level_ended = true
			hit_node = node
			
			GameUI.on_start_game_pressed()
		
			print("entered body")
		
			GameUI.preload_map("dg_%02d" % (len(GameUI.maps_loaded) + 1))
			GameUI.goto_map(GameUI.current_map_index + 1)
