extends HBoxContainer

@onready var new_switch := preload("res://scenes/switch.tscn")
@onready var new_house := preload("res://scenes/house.tscn")

func _on_new_switch_button_pressed():
	get_node("/root/Main/Switches").add_child(new_switch.instantiate())


func _on_new_house_button_pressed():
	get_node("/root/Main/Houses").add_child(new_house.instantiate())
