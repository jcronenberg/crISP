extends HBoxContainer

@onready var new_switch := preload("res://src/endpoints/switch_node.tscn")
@onready var new_house := preload("res://src/endpoints/house_node.tscn")

func _on_new_switch_button_pressed():
	get_node("/root/Main/Switches").add_child(new_switch.instantiate())
	get_node("/root/UiController").change_cursor_mode("cable")


func _on_new_house_button_pressed():
	get_node("/root/Main/Houses").add_child(new_house.instantiate())
	get_node("/root/UiController").change_cursor_mode("cable")
