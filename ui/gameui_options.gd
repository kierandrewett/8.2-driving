extends MarginContainer

func on_visibility_changed():
	GameUI.get_node("MainMenu").visible = !self.visible
