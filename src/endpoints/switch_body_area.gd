extends Area2D

func _input_event(_viewport, event, _shape_idx):
	if (
			event.is_action_pressed("LClick")
			and Global.cursor_mode == Global.CursorModes.MOVE_SWITCH
			and get_parent().placed
			):
		get_parent().placed = false
		get_parent().set_process(true)
		get_parent().set_process_input(true)
