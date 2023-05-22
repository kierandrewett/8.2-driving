extends Control

var debug_info = null
var lines = []

func _ready():
	debug_info = get_node("/root/GameUIDebug/MarginContainer/DebugInformation")

func _process(delta):
	if !OS.is_debug_build():
		return
	
	lines = []

	lines.append("%s fps" % [str(Engine.get_frames_per_second())])

	if GameUI.map_loaded and GameUI.map_loaded != null and GameUI.map_loaded.scene_file_path:
		lines[0] += " on %s" % [GameUI.map_loaded.scene_file_path]
		
	var car = get_node("/root/Car")
		
	if car and GameUI.map_loaded != null:
		lines.append("pos: %s" % ["%s %s %s" % ["%.2f" % car.global_position.x, "%.2f" % car.global_position.y, "%.2f" % car.global_position.z] if car else ""])
		lines.append("ang: %s" % ["%s %s %s %s %s %s %s" % ["%.2f" % car.camera.position.x, "%.2f" % car.camera.position.y, "%.2f" % car.camera.position.z, "%.2f" % car.camera.rotation.x, "%.2f" % car.camera.rotation.y, "%.2f" % car.camera.rotation.z, "%.2f" % car.get_floor_angle()] if car else ""])
		lines.append("vel: %s" % ["%.2f" % (car.velocity.length() * 43.333 if car and car.velocity else 0.0)])
		lines.append("fov: %s" % ["%.2f" % car.camera.fov])
		lines.append("")
		
		lines.append("curr_lane: %s" % [car.current_lane + 1])
		lines.append("lanes: %s" % [GameUI.map_loaded.lanes if GameUI.map_loaded else 0])
		
		lines.append("")
		
		var filtered_roads = car.road_pieces.filter(func(piece): return piece != null)
		
		lines.append("roads: %s" % [len(filtered_roads)])
		lines.append("curr_road: %s" % ["0"])
		
		lines.append("")
		
		lines.append("mph: %.0f" % [car.get_speed_mph()])
		lines.append("km/h: %.0f" % [car.get_speed_kmh()])
	
	debug_info.text = "\n".join(lines)
