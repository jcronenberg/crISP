extends HBoxContainer

@onready var new_switch := preload("res://scenes/switch.tscn")

func _on_new_switch_button_pressed():
	get_node("/root/Main/Switches").add_child(new_switch.instantiate())
