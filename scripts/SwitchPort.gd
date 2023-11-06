extends Area2D

var is_connected := false
var cable_creator_scene = preload("res://scenes/cable_creator.tscn")
var is_endpoint := true
var connected_cable = null
## kind of an ugly hack to not register the click if it was connected to another port
var just_connected := false

func _input_event(viewport, event, shape_idx):
	var cable_creator = cable_creator_scene.instantiate()
	if event.is_action_pressed("LClick") and not is_connected:
		add_child(cable_creator)
		cable_creator.init(get_parent().material.get_shader_parameter("color"), self)
		is_connected = true
	elif event.is_action_pressed("LClick") and not just_connected:
		cable_creator.edit_cable(connected_cable, self)
		is_connected = false
		connected_cable = null
		add_child(cable_creator)
	elif event.is_action_pressed("LClick"):
		just_connected = false
