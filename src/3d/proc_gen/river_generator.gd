class_name RiverGenerator
extends Node

@export var from: Vector2:
	set(value):
		from = value
		draw_river()
@export var to: Vector2:
	set(value):
		to = value
		draw_river()
@export var sample_point_amount: int:
	set(value):
		sample_point_amount = value
		draw_river()
@export var width: float:
	set(value):
		width = value
		draw_river()
@export var deviation: float:
	set(value):
		deviation = value
		draw_river()
@export var smooth_spline_length: float:
	set(value):
		smooth_spline_length = value
		_draw_river()
		mult_mesh_points = 0
		_draw_tessellation_points_for_curve(_curve1)
		_draw_tessellation_points_for_curve(_curve2)

var _curve1: Curve2D = Curve2D.new()
var _curve2: Curve2D = Curve2D.new()

var _river_mesh: MeshInstance3D = MeshInstance3D.new()
@onready var _multi_mesh: MultiMeshInstance3D = $MultiMeshInstance3D


func _ready() -> void:
	add_child(_river_mesh)
	draw_river()


func draw_river() -> void:
	_curve1.clear_points()
	_curve2.clear_points()
	var diff: Vector2 = to - from
	var normal: Vector2 = diff.rotated(TAU/4).normalized()
	var offset: Vector2 = normal * width * 0.5
	var per_point_diff: Vector2 = diff / sample_point_amount

	for i in sample_point_amount + 1:
		var point1: Vector2 = from + per_point_diff * i + offset + normal * randf_range(0, deviation)
		var point2: Vector2 = from + per_point_diff * i - offset - normal * randf_range(0, deviation)
		_curve1.add_point(point1)
		_curve2.add_point(point2)

	_draw_river()


func _draw_river() -> void:
	smooth_curve(_curve1, smooth_spline_length)
	smooth_curve(_curve2, smooth_spline_length)
	var vertices: PackedVector2Array = _curve1.tessellate()
	var vertices2: PackedVector2Array = _curve2.tessellate()
	mult_mesh_points = 0
	_draw_tessellation_points_for_curve(_curve1)
	_draw_tessellation_points_for_curve(_curve2)

	vertices2.reverse()
	vertices.append_array(vertices2)

	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color.BLUE
	_river_mesh.mesh = ProcGen.flat_3d_mesh_from_2d_outlines(vertices)
	_river_mesh.material_override = material


var mult_mesh_points: int = 0
func _draw_tessellation_points_for_curve(curve: Curve2D) -> void:
	if not _multi_mesh:
		return
	for point in curve.tessellate():
		_multi_mesh.multimesh.set_instance_transform(mult_mesh_points, Transform3D(Basis(), Vector3(point.x, 0.5, point.y)))
		_multi_mesh.multimesh.visible_instance_count = mult_mesh_points
		mult_mesh_points += 1


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
