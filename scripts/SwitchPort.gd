extends Area2D

var cable_creator_scene = preload("res://scenes/cable_creator.tscn")
var is_endpoint := true
var connected_cable = null

func _input_event(_viewport, event, _shape_idx):
	var cable_creator = cable_creator_scene.instantiate()
	if event.is_action_pressed("LClick") and not get_parent().is_port_connected:
		add_child(cable_creator)
		cable_creator.init(get_parent().material.get_shader_parameter("color"), self)
		get_parent().set_is_port_connected(true)
	elif event.is_action_pressed("LClick") and connected_cable and not get_parent().just_connected:
		cable_creator.edit_cable(connected_cable, self)
		get_parent().set_is_port_connected(false)
		connected_cable = null
		add_child(cable_creator)
	elif event.is_action_pressed("LClick"):
		get_parent().just_connected = false
