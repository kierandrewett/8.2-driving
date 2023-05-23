extends OmniLight3D

@onready var car: CharacterBody3D = get_parent()

var flashing_timer: SceneTreeTimer = null

func _process(delta):
	var is_visible = false
	
	if car.crashed:
		if flashing_timer == null:
			flashing_timer = get_tree().create_timer(1)
			flashing_timer.timeout.connect(func ():
				is_visible = !is_visible
				flashing_timer = null
			)

	self.light_energy = 1.5 if is_visible else 0.0
