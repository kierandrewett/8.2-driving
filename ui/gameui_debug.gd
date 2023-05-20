extends Control

var debug_info = null
var lines = []

func _ready():
	debug_info = get_node("/root/GameUIDebug/MarginContainer/DebugInformation")

func _process(delta):
	lines = []

	lines.append("%s fps" % [str(Engine.get_frames_per_second())])
		
	var car = get_node("/root/Car")
		
	if car:
		lines.append("pos: %s" % ["%s %s %s" % ["%.2f" % car.global_position.x, "%.2f" % car.global_position.y, "%.2f" % car.global_position.z] if car else ""])
		lines.append("ang: %s" % ["%s %s %s %s" % ["%.2f" % car.camera.rotation.x, "%.2f" % car.camera.rotation.y, "%.2f" % car.camera.rotation.z, "%.2f" % car.get_floor_angle()] if car else ""])
		lines.append("vel: %s" % ["%.2f" % (car.velocity.length() * 43.333 if car and car.velocity else 0.0)])
		lines.append("fov: %s" % ["%.2f" % car.camera.fov])
		lines.append("")
		
		lines.append("curr_lane: %s" % [car.current_lane + 1])
		lines.append("lanes: %s" % [get_node_or_null("/root/Level").lanes if get_node_or_null("/root/Level") else 0])
		
		lines.append("")
		
		var filtered_roads = car.road_pieces.filter(func(piece): return piece != null)
		
		lines.append("roads: %s" % [len(filtered_roads)])
		lines.append("curr_road: %s" % ["0"])
		
		lines.append("")
		
		lines.append("mph: %.0f" % [car.get_speed_mph()])
		lines.append("km/h: %.0f" % [car.get_speed_kmh()])
	
	debug_info.text = "\n".join(lines)
