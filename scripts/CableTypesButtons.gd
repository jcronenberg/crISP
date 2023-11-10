extends HBoxContainer


func _on_cable_copper_button_pressed():
	get_node("/root/UiController").selected_cable_type = "copper"
	get_node("/root/UiController").change_cursor_mode("cable")


func _on_cable_fiber_button_pressed():
	get_node("/root/UiController").selected_cable_type = "fiber"
	get_node("/root/UiController").change_cursor_mode("cable")
