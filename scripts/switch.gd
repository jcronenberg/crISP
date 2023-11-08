extends Node2D

var placed := false

func _process(_delta):
	if not placed:
		global_position = get_global_mouse_position()
		global_position.x -= 110
		global_position.y -= 50
		global_position = global_position.snapped(Vector2i(20, 20))


func _input(event):
	if event.is_action_pressed("LClick"):
		placed = true
	elif event.is_action_pressed("RClick") or event.is_action_pressed("Cancel"):
		queue_free()
