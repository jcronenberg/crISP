extends HBoxContainer


func _on_cable_copper_button_pressed():
	get_node("/root/UiController").selected_cable_type = "copper"


func _on_cable_fiber_button_pressed():
	get_node("/root/UiController").selected_cable_type = "fiber"
