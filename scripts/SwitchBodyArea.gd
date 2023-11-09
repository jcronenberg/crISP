extends Area2D

@onready var ui_controller = get_node("/root/UiController")

func _input_event(_viewport, event, _shape_idx):
	if event.is_action_pressed("LClick") and ui_controller.cursor_mode == "move_switch" and get_parent().placed:
		get_parent().placed = false
		get_parent().set_process(true)
		get_parent().set_process_input(true)
