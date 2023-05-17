extends Node

func _ready():
	pass

func load(path):
	var res = ResourceLoader.load(path)
	var initted = res.instantiate()
	get_window().add_child.call_deferred(initted)
