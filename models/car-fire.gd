extends GPUParticles3D

@onready var car: CharacterBody3D = get_parent()

func _ready():
	self.emitting = false
	self.amount = 1

func _process(delta):	
	pass
