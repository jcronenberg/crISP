extends Area2D

class_name SwitchPort

var cable_creator_scene = preload("res://scenes/cable_creator.tscn")
const is_endpoint := true
var connected_cable = null
@onready var ui_controller = get_node("/root/UiController")

func get_real_parent():
	return get_node("../..")


func _input_event(_viewport, event, _shape_idx):
	var cable_creator = cable_creator_scene.instantiate()
	if event.is_action_pressed("LClick") and not get_parent().is_port_connected and ui_controller.cursor_mode == "cable":
		add_child(cable_creator)
		cable_creator.init(self)
		get_parent().set_is_port_connected(true)
	elif event.is_action_pressed("LClick") and connected_cable and ui_controller.cursor_mode == "delete_cable":
		get_node("/root/Main/Simulation").delete_cable(connected_cable)
		# Need to store cable temporarily because otherwise we set connected_cable to null in disconnect()
		# but we still need to queue_free() it
		var tmp_cable = connected_cable

		tmp_cable.port1.disconnect_port()
		tmp_cable.port2.disconnect_port()
		tmp_cable.queue_free()


func disconnect_port():
	connected_cable = null
	get_parent().set_is_port_connected(false)
