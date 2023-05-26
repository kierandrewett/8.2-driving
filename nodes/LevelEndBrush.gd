extends Area3D

var level_ended = false
var hit_node = null

func _on_body_entered(node):
	if node.name == "Car" and node is CharacterBody3D:		
		if !level_ended:
			level_ended = true
			hit_node = node
			
			GameUI.visible = true
			
			if GameUI.current_map_index + 1 >= len(GameUI.maps_loaded):
				GameUI.on_game_completed()
			else:
				GameUI.goto_map(GameUI.current_map_index + 1, false)
				if GameUI.current_map_index + 1 < len(GameUI.maps_loaded):
					GameUI.preload_map(GameUI.current_map_index + 1)
				
			level_ended = false
			hit_node = null
