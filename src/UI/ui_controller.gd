extends Node

var selected_cable_type = "copper"
var cursor_mode = "cable"

func change_cursor_mode(mode: String):
	cursor_mode = mode
	match mode:
		"cable":
			if selected_cable_type == "copper":
				get_node("/root/Main/CanvasLayer/GameUI/CableTypesButtons/CableCopperButton").set_pressed_no_signal(true)
			else:
				get_node("/root/Main/CanvasLayer/GameUI/CableTypesButtons/CableFiberButton").set_pressed_no_signal(true)
		"move_switch":
			get_node("/root/Main/CanvasLayer/GameUI/CursorModeButtons/MoveSwitchButton").set_pressed_no_signal(true)
		"delete_cable":
			get_node("/root/Main/CanvasLayer/GameUI/CursorModeButtons/DeleteCableButton").set_pressed_no_signal(true)


func display_warning(text: String):
	get_node("/root/Main/CanvasLayer/GameUI/WarningLabel").text = text
	get_node("/root/Main/CanvasLayer/GameUI/WarningLabel").visible = true


func hide_warning():
	get_node("/root/Main/CanvasLayer/GameUI/WarningLabel").visible = false
