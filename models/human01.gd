extends Node3D

func _ready():
	get_node("AnimationPlayer").play("Idle")

func _process(delta):
	pass
