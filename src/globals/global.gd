extends Node

enum CursorModes {
	CABLE,
}

enum CableTypes {
	COPPER,
	FIBER,
}

var cursor_mode: CursorModes = CursorModes.CABLE
var selected_cable_type: CableTypes = CableTypes.COPPER
@onready var current_simulation: Simulation =  get_node("/root/Game/Simulation")
