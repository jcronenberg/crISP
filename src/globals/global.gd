extends Node

enum CursorModes {
	CABLE,
	DELETE_CABLE,
	MOVE_SWITCH,
}

enum CableTypes {
	COPPER,
	FIBER,
}

var cursor_mode: CursorModes = CursorModes.CABLE
var selected_cable_type: CableTypes = CableTypes.COPPER


func get_current_simulation() -> Simulation:
	return get_node("/root/Game/Simulation")
