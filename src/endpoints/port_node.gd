class_name PortNode
extends Area2D

const is_endpoint := true
var connected_cable = null

func get_real_parent():
	push_error("Shouldn't have been called without overwrite")

func _input_event(_viewport, event, _shape_idx):
	if (
			event.is_action_pressed("LClick")
			and not get_parent().is_port_connected
			and Global.cursor_mode == Global.CursorModes.CABLE
			):
		Global.get_current_simulation().request_cable_creation(self)
		get_parent().set_is_port_connected(true)
	elif (
			event.is_action_pressed("LClick")
			and connected_cable
			and Global.cursor_mode == Global.CursorModes.DELETE_CABLE
			):
		Global.get_current_simulation().delete_cable(connected_cable)


func disconnect_port():
	connected_cable = null
	get_parent().set_is_port_connected(false)
