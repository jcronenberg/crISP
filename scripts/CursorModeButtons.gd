extends HBoxContainer


func _on_move_switch_button_pressed():
	get_node("/root/UiController").change_cursor_mode("move_switch")


func _on_delete_cable_button_pressed():
	get_node("/root/UiController").change_cursor_mode("delete_cable")
