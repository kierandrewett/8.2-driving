extends Node

func _ready():
	pass

func _process(delta):
	get_node("RoadContainer/DebugMarkings").visible = Globals.developer or OS.is_debug_build()
	
	pass
