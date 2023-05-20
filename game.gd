extends Node

func _ready():
	pass

func _process(delta):
	get_tree().root.content_scale_factor = Globals.hud_scale
