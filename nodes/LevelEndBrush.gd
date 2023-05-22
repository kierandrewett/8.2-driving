extends Area3D

var level_ended = false
var hit_node = null

func _on_body_entered(node):
	if node.name == "Car" and node is CharacterBody3D:		
		if !level_ended:
			level_ended = true
			hit_node = node
			
			GameUI.on_start_game_pressed()

			GameUI.preload_map(len(GameUI.maps_loaded))
			GameUI.goto_map(GameUI.current_map_index + 1)
