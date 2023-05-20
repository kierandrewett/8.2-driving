extends Control

@onready var speedometer: Label = get_node("MarginContainer/BoxContainer/Speedometer")
var car: CharacterBody3D = null

func _ready():
	pass

func _process(delta):
	if !car:
		car = get_node_or_null("/root/Car")
	
	if !car:
		return
	
	self.visible = !GameUI.visible
	
	if GameUI.visible:
		return
	
	speedometer.text = "%d mph" % [car.get_speed_mph()]
	
	pass
