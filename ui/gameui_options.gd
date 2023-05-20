extends MarginContainer

var current_menu = null
var current_menu_name = ""

func _ready():
	hide_all_menus()
	on_back_button_mouse_leave()

func hide_all_menus():
	for m in GameUI.get_node("Options/BoxContainer/Menus").get_children():
		m.get_node("Title").visible = false
		m.visible = false

func on_visibility_changed():
	if self.visible:
		on_button_pressed("Main")
	else:
		hide_all_menus()

func on_back_button_mouse_enter():
	GameUI.get_node("Options/BoxContainer/VBoxContainer/BackButton").modulate.a = 1
	Sounds.play_sound("res://sounds/ui/hover.wav")

func on_back_button_mouse_leave():
	GameUI.get_node("Options/BoxContainer/VBoxContainer/BackButton").modulate.a = 0.5

func on_back_button_mouse_down():
	GameUI.get_node("Options/BoxContainer/VBoxContainer/BackButton").modulate.a = 0.25

func on_back_button_mouse_up():
	Sounds.play_sound("res://sounds/ui/click.ogg")
	if current_menu_name == "Main":
		GameUI.on_options_pressed()
	else:
		var parent_name_split = Array(current_menu_name.split("__"))
		parent_name_split.pop_back()
		var parent_name = "__".join(parent_name_split)
		on_button_pressed(parent_name)

func on_button_pressed(menu):
	hide_all_menus()
	
	var menu_node = GameUI.get_node_or_null("Options/BoxContainer/Menus/%s" % [menu])
	var menu_name = Array(menu.split("__"))[-1]

	var title_node = null
	
	if menu_node and menu_node.name == menu:
		current_menu = menu_node
		current_menu.visible = true
		title_node = current_menu.get_node_or_null("Title")
		
	current_menu_name = menu
	
	GameUI.get_node("Options/BoxContainer/VBoxContainer/OptionsTitle").text = title_node.text if title_node else menu_name
	
	var back_btn = GameUI.get_node("Options/BoxContainer/VBoxContainer/BackButton")
	
	if menu_name == "Main":
		back_btn.text = "Crashy Roads"
	else:
		back_btn.text = Array(menu.split("__"))[-2].replace("Main", "Options")

func init_resolutions():
	var resolution_4_3 = [320, 200]
	var resolution_16_9 = [480, 234]
	
	
	
	var resolutions_list = GameUI.get_node("Options/BoxContainer/Menus/Main__Video/Resolution/ResolutionsList")
	
