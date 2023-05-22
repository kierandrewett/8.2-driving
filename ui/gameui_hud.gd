extends Control

@onready var speedometer: Label = get_node("MarginContainer/SpeedometerContainer/Speedometer")
@onready var progress: ProgressBar = get_node("MarginContainer/ProgressContainer/BoxContainer/ProgressBar")
@onready var points: Label = get_node("MarginContainer/PointsContainer/Points")

var car: CharacterBody3D = null

var jiggy_tween: Tween = null

var points_int = 0

func _ready():
	jiggy_tween = get_tree().create_tween()
	
	points.text = "%02d" % points_int
	points_jig()
	
	pass

func points_jig():		
	points.pivot_offset = points.size / 2
		
	points.rotation = -0.3
	points.scale = Vector2(1.3, 1.3)

	if jiggy_tween:
		jiggy_tween = get_tree().create_tween()

	jiggy_tween.tween_property(points, "rotation", 0, 0.2).set_trans(Tween.TRANS_SINE)
	
	if jiggy_tween:
		jiggy_tween = get_tree().create_tween()
	
	jiggy_tween.tween_property(points, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_SINE)

func _process(delta):
	if !car:
		car = get_node_or_null("/root/Car")
	
	if !car:
		return
	
	speedometer.visible = !GameUI.visible
	progress.visible = !car.autopilot
	
	if GameUI.visible:
		return
	
	speedometer.text = "%d mph" % [car.get_speed_mph()]
	
	if !GameUI.map_loaded:
		return
		
	var new_points = GameUI.current_map_index
	
	var movement_points = floor(car.position.z / -490 * (min(car.velocity.length_squared(), 5) / 5))
	
	if movement_points >= 1:
		new_points = movement_points
	
	if car.crashed:
		new_points = 0
		
	points_int += new_points
		
	if int(points.text) != points_int:
		points.text = "%02d" % (points_int)
		points_jig()
	
	if GameUI.map_loaded:
		var level_start = Utils.get_node_by_name(GameUI.maps_loaded[GameUI.current_map_index - 1], "LevelEndBrush")
		var level_end = Utils.get_node_by_name(GameUI.map_loaded, "LevelEndBrush")
		
		var start_pos = car.start_position.z if GameUI.current_map_index == 0 else level_start.global_position.z
		var end_pos = level_end.global_position.z
		
		if !level_end:
			return

		var percent = clamp((car.global_position.z - start_pos) / ((end_pos + 3) - start_pos) * 100, 0, 100)
		
		progress.value = percent
	
	pass
