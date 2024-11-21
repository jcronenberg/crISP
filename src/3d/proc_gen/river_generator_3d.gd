class_name RiverGenerator3D
extends Node

@export var width_curve: Curve:
	set(value):
		width_curve = value
		width_curve.changed.connect(draw_river)
		draw_river()
@export var path: Curve2D:
	set(value):
		path = value
		path.changed.connect(draw_river)
		draw_river()
@export var extra_points: int:
	set(value):
		extra_points = value
		draw_river()
@export var deviation: float:
	set(value):
		deviation = value
		draw_river()
@export var smooth_spline_length: float:
	set(value):
		smooth_spline_length = value
		_draw_river()
		_multi_mesh_points = 0
		_draw_points(_curve1.tessellate())
		_draw_points(_curve2.tessellate())
@export var draw_debug_points: bool:
	set(value):
		draw_debug_points = value
		_multi_mesh_points = 0
		if _multi_mesh:
			_multi_mesh.multimesh.visible_instance_count = 0
		_draw_points(_curve1.tessellate())
		_draw_points(_curve2.tessellate())
		_draw_points(path.tessellate())

var _curve1: Curve2D = Curve2D.new()
var _curve2: Curve2D = Curve2D.new()
var _river_mesh: MeshInstance3D = MeshInstance3D.new()
@onready var _multi_mesh: MultiMeshInstance3D = $MultiMeshInstance3D
var _multi_mesh_points: int = 0


func _ready() -> void:
	add_child(_river_mesh)
	draw_river()


func draw_river() -> void:
	# Node would be drawn a bunch of times too early when values are being set
	if not is_node_ready():
		return

	if path.point_count < 2:
		push_error("At least two points are required")
		return

	_curve1.clear_points()
	_curve2.clear_points()
	for i in path.get_point_count() - 1:
		var segment_points: Array[PackedVector2Array] = _get_segment_points(i)
		for point in segment_points[0]:
			_curve1.add_point(point)
		for point in segment_points[1]:
			_curve2.add_point(point)

		if i != path.get_point_count() - 2:
			_curve1.remove_point(_curve1.get_point_count() - 1)
			_curve2.remove_point(_curve2.get_point_count() - 1)

	_draw_river()
	_draw_points(path.tessellate())


func _get_segment_points(point1_idx: int) -> Array[PackedVector2Array]:
	var points1: PackedVector2Array = []
	var points2: PackedVector2Array = []
	for i in extra_points + 2:
		var from: Vector2 = path.sample(point1_idx, (1.0 / (extra_points + 2)) * i)
		var to: Vector2 = path.sample(point1_idx, (1.0 / (extra_points + 2)) * (i + 1))
		var diff: Vector2 = to - from
		var normal: Vector2 = diff.rotated(TAU/4).normalized()
		# The calculation here represents basically a linear increasing value from 0 to 1.0
		# depending on how far along the generation of the points we are
		var width: float = width_curve.sample(
			# How many points are there overall
			(1.0 / (path.point_count + (extra_points * (path.point_count - 1))))
			# Where are we at currently
			* ((point1_idx * (extra_points + 2)) + i))
		var offset: Vector2 = normal * width * 0.5

		var point1: Vector2 = from + offset + normal * randf_range(0, deviation)
		var point2: Vector2 = from - offset - normal * randf_range(0, deviation)
		points1.append(point1)
		points2.append(point2)

		# At the end the last(to vector) also needs to be added
		if i == extra_points + 1:
			points1.append(to + offset + normal * randf_range(0, deviation))
			points2.append(to - offset - normal * randf_range(0, deviation))

	return [points1, points2]



func _draw_river() -> void:
	# Node would be drawn a bunch of times too early when values are being set
	if not is_node_ready():
		return

	smooth_curve(_curve1, smooth_spline_length)
	smooth_curve(_curve2, smooth_spline_length)
	var vertices: PackedVector2Array = _curve1.tessellate()
	var vertices2: PackedVector2Array = _curve2.tessellate()

	vertices2.reverse()
	vertices.append_array(vertices2)
	_multi_mesh_points = 0
	_draw_points(vertices)

	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color.BLUE
	var mesh: ArrayMesh = ProcGen.flat_3d_mesh_from_2d_outlines(vertices)
	if not mesh:
		push_error("Failed to triangulate river, adjust the values to have a valid set of points")
	_river_mesh.mesh = mesh
	_river_mesh.material_override = material


func _draw_points(points: PackedVector2Array) -> void:
	if not is_node_ready() or not draw_debug_points:
		return
	if not _multi_mesh:
		push_error("To show debug points, a multi mesh node is required")
		return

	for point in points:
		_multi_mesh.multimesh.set_instance_transform(_multi_mesh_points, Transform3D(Basis(), Vector3(point.x, 0.5, point.y)))
		_multi_mesh.multimesh.visible_instance_count = _multi_mesh_points
		_multi_mesh_points += 1


func smooth_curve(curve: Curve2D, spline_length: float) -> void:
	for i in range(1, curve.get_point_count() - 1):
		var spline: Vector2 = _get_spline(curve, i, spline_length)
		curve.set_point_in(i, -spline)
		curve.set_point_out(i, spline)

func _get_spline(curve: Curve2D, i: int, spline_length: float) -> Vector2:
	if i == 0 or curve.get_point_count() < i + 1:
		return Vector2(0, 0)
	var last_point: Vector2 = curve.get_point_position(i - 1)
	var next_point: Vector2 = curve.get_point_position(i + 1)
	var spline: Vector2 = last_point.direction_to(next_point) * spline_length
	return spline
