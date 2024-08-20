extends Camera2D

var dragging := false
var previous_pos := Vector2(0, 0)

func _input(event):
	if event.is_action_pressed("MClick"):
		dragging = true
		previous_pos = event.position
	elif event.is_action_released("MClick"):
		dragging = false
		previous_pos = Vector2(0, 0)
	elif event.is_action_pressed("ZoomIn"):
		zoom += Vector2(0.1, 0.1)
	elif event.is_action_pressed("ZoomOut"):
		zoom -= Vector2(0.1, 0.1)
	elif event is InputEventMouseMotion and dragging:
		global_position += (previous_pos - event.position) / zoom
		previous_pos = event.position

	zoom = zoom.clamp(Vector2(0.2, 0.2), Vector2(2, 2))
