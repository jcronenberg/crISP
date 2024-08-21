class_name CableNode
extends Line2D

var port1: PortNode = null:
	set(port):
		port1 = port
		port.connected_cable = self
		global_position = port.global_position
		add_point(port.global_position)
var port2: PortNode = null
var cable_type: Global.CableTypes
var max_bandwidth: int = 1000
var cur_bandwidth: int = 0
@onready var cable_gradient = load("res://resources/cable_gradient.tres")
var being_edited: bool = true:
	set(value):
		being_edited = value
		set_process(value)
		set_process_input(value)

func _ready():
	cable_type = Global.selected_cable_type
	if cable_type == Global.CableTypes.COPPER:
		texture = null
		max_bandwidth = 250

func update_cur_bandwidth(bandwidth: int):
	cur_bandwidth = bandwidth
	var bandwidth_color: Color = cable_gradient.sample(float(cur_bandwidth) / max_bandwidth)
	default_color = bandwidth_color
	for port in [port1, port2]:
		if port is SwitchPort:
			port.material.set_shader_parameter("color", bandwidth_color)


func _input(event: InputEvent):
	if event.is_action_pressed("LClick"):
		# Check if position under cursor is possible endpoint
		var space_rid := get_world_2d().space
		var space_state := PhysicsServer2D.space_get_direct_state(space_rid)
		var query := PhysicsPointQueryParameters2D.new()
		query.collide_with_areas = true
		query.position = get_global_mouse_position()
		if Input.is_action_pressed("SnapToGrid"):
			query.position = query.position.snapped(Vector2i(20, 20))
		query.collide_with_bodies = false
		var nodes = space_state.intersect_point(query)
		for node in nodes:
			if node["collider"] is WanPort or node["collider"] is PortNode and not node["collider"].is_port_connected:
				# stop _process, otherwise we run into a race condition
				# where _process also tries to set the last point's position
				being_edited = false

				# Connect to port
				node["collider"].connected_cable = self

				port2 = node["collider"]
				set_point_position(points.size() - 1, node["collider"].global_position - global_position)

				# Add collision
				set_cable_collision()

				# Setup is finished, add to simulation
				Global.get_current_simulation().add_cable_to_sim(self)
				return
			# Invalid because point is an endpoint but not free
			elif "is_endpoint" in node["collider"]:
				return

		# Add new point, position doesn't matter, it get's set by _process
		add_point(Vector2(0, 0))

	if event.is_action_pressed("RClick") and points.size() > 2:
		remove_point(points.size() - 1)
	elif event.is_action_pressed("RClick"):
		free_cable()


func _process(_delta: float) -> void:
	var cursor_pos: Vector2 = get_global_mouse_position()
	if Input.is_action_pressed("SnapToGrid"):
		cursor_pos = cursor_pos.snapped(Vector2i(20, 20))
	set_point_position(points.size() - 1, cursor_pos - global_position)


func set_cable_collision() -> void:
	# Free existing collision areas
	for child in get_children():
		if child is not Area2D:
			continue
		child.queue_free()

	# Add new collision areas
	var line_collision_area: Area2D = cable_line_collision_area()
	line_collision_area.connect("input_event", _on_line_collision_input_event)
	add_child(line_collision_area)
	var point_collision_area: Area2D = cable_point_collision_area()
	point_collision_area.connect("input_event", _on_point_collision_input_event)
	add_child(point_collision_area)


func cable_line_collision_area() -> Area2D:
	var area: Area2D = Area2D.new()
	for poly in rotated_rectangle_points():
		area.add_child(poly)

	return area


func cable_point_collision_area() -> Area2D:
	var area: Area2D = Area2D.new()
	for point in points:
		var collision_shape: CollisionShape2D = CollisionShape2D.new()
		var circle: CircleShape2D = CircleShape2D.new()
		circle.radius = width / 2
		collision_shape.shape = circle
		collision_shape.global_position = point
		area.add_child(collision_shape)

	return area


func rotated_rectangle_points() -> Array[CollisionPolygon2D]:
	var col_polys: Array[CollisionPolygon2D] = []
	for i in points.size() - 1:
		var poly: CollisionPolygon2D = CollisionPolygon2D.new()
		var start: Vector2 = points[i]
		var end: Vector2 = points[i + 1]
		var diff: Vector2 = end - start
		var normal: Vector2 = diff.rotated(TAU/4).normalized()
		var offset: Vector2 = normal * width * 0.5
		poly.polygon = [start + offset, end + offset, end - offset, start - offset]
		col_polys.append(poly)

	return col_polys


func free_cable() -> void:
	if port1:
		port1.connected_cable = null
	if port2:
		port2.connected_cable = null
	queue_free()
	Global.get_current_simulation().delete_cable(self)


func _on_line_collision_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is not InputEventMouseButton or not event.pressed:
		return

	if Global.cursor_mode == Global.CursorModes.DELETE_CABLE:
		free_cable()


# TODO allow moving of points
func _on_point_collision_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is not InputEventMouseButton or not event.pressed:
		return

	if Global.cursor_mode == Global.CursorModes.DELETE_CABLE:
		free_cable()
