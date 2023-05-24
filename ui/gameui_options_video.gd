extends BoxContainer

func _ready():
	init_presets()

func init_presets():
	var presets_list: OptionButton = get_node("Preset/OptionButton")
	presets_list.add_item("Low")
	presets_list.add_item("Medium")
	presets_list.add_item("High")
	presets_list.add_item("Ultra High")

func _process(delta):
	pass
