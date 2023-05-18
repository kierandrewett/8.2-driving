extends Control

@onready var speedometer: Label = get_node("MarginContainer/BoxContainer/Speedometer")
var car: CharacterBody3D = null

func _ready():
	pass

func _process(delta):
	if !car:
		car = get_node("/root/Car")
	
	self.visible = !GameUI.visible
	
	if GameUI.visible:
		return
	
	speedometer.text = "%d mph" % [car.velocity.length() * 1.5]
	
	pass
