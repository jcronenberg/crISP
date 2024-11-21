@tool
class_name RiverGenerator2D
extends Node2D
## Generates a river along a [Path2D] with some optional random width deviation.
##
## Add a [Polygon2D] to [member river_polygon] and [Path2D] to [member path].

## Width curve from 0 (path start) to 1 (path end).
@export var width_curve: Curve:
	set(value):
		width_curve = value
		width_curve.changed.connect(draw_river)
		draw_river()
## Path that river will follow.
@export var path: Path2D:
	set(value):
		path = value
		path.curve.changed.connect(draw_river)
		draw_river()
## Amount of extra points between path curve points.
@export var extra_points: int:
	set(value):
		extra_points = value
		draw_river()
## Maximum value that points are allowed to randomly deviate.
@export var deviation: float:
	set(value):
		deviation = value
		draw_river()
## Length of the generated bezier curve tangent.
@export var smooth_spline_length: float:
	set(value):
		smooth_spline_length = value
		_draw_river()
		_draw_debug_points()
## Draws red points where the polygon points are and along the [member path].
@export var draw_debug_points: bool:
	set(value):
		draw_debug_points = value
		_draw_debug_points()
## Polygon node that will be the river.
@export var river_polygon: Polygon2D = Polygon2D.new()

# River side bezier curves
var _curve1: Curve2D = Curve2D.new()
var _curve2: Curve2D = Curve2D.new()
# Store debug points to give access when drawing
var _debug_points: PackedVector2Array = []


func _ready() -> void:
	if not river_polygon.get_parent():
		add_child(river_polygon)
	draw_river()


## Draws the river by populating [member river_polygon]'s polygon points.
func draw_river() -> void:
	# Node would be drawn a bunch of times too early when values are being set
	if not is_node_ready():
		return

	if path.curve.point_count < 2:
		push_error("At least two points are required")
		return

	_curve1.clear_points()
	_curve2.clear_points()
	for i in path.curve.point_count - 1:
		var segment_points: Array[PackedVector2Array] = _get_segment_points(i)
		for point in segment_points[0]:
			_curve1.add_point(point)
		for point in segment_points[1]:
			_curve2.add_point(point)

		# Unless at the end the last points would clash with the next segments first points,
		# because both include the starting and end points.
		if i != path.curve.point_count - 2:
			_curve1.remove_point(_curve1.get_point_count() - 1)
			_curve2.remove_point(_curve2.get_point_count() - 1)

	_draw_river()
	_draw_debug_points()


# For a given point [param point1_idx] returns 2 PackedVector2Arrays.
# They contain the points of the outside curves which are the starting
# point, the extra points in between and the end point.
# These points are mutated to be away from the center along the width curve,
# and randomly deviated in accordance to [member deviation].
func _get_segment_points(point1_idx: int) -> Array[PackedVector2Array]:
	var points1: PackedVector2Array = []
	var points2: PackedVector2Array = []
	for i in extra_points + 2:
		var from: Vector2 = path.curve.sample(point1_idx, (1.0 / (extra_points + 2)) * i)
		var to: Vector2 = path.curve.sample(point1_idx, (1.0 / (extra_points + 2)) * (i + 1))
		var diff: Vector2 = to - from
		var normal: Vector2 = diff.rotated(TAU/4).normalized()
		# The calculation here represents basically a linear increasing value from 0 to 1.0
		# depending on how far along the generation of the points we are
		var width: float = width_curve.sample(
			# How many points are there overall
			(1.0 / (path.curve.point_count + (extra_points * (path.curve.point_count - 1))))
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


# Smoothes out the side curves and then populates [member river_polygon]'s polygon.
func _draw_river() -> void:
	# Node would be drawn a bunch of times too early when values are being set
	if not is_node_ready():
		return

	_smooth_curve(_curve1, smooth_spline_length)
	_smooth_curve(_curve2, smooth_spline_length)

	var vertices: PackedVector2Array = _curve1.tessellate()
	var vertices2: PackedVector2Array = _curve2.tessellate()
	vertices2.reverse()
	vertices.append_array(vertices2)

	river_polygon.polygon = vertices


# Draw _debug_points.
func _draw() -> void:
	if not draw_debug_points:
		return
	for point in _debug_points:
		draw_circle(point, 2, Color.RED)


# Populates [member _debug_points] and queues a redraw.
func _draw_debug_points() -> void:
	if not is_node_ready():
		return
	_debug_points = []
	_debug_points.append_array(river_polygon.polygon)
	_debug_points.append_array(path.curve.tessellate())
	queue_redraw()


# Smooths a [param curve] by setting the in and out points along a tangent with length [param spline_length].
func _smooth_curve(curve: Curve2D, spline_length: float) -> void:
	for i in range(1, curve.get_point_count() - 1):
		var spline: Vector2 = _get_spline(curve, i, spline_length)
		curve.set_point_in(i, -spline)
		curve.set_point_out(i, spline)


# Generates a tangent for a [param curve] at point [param i] with length [param spline_length].
func _get_spline(curve: Curve2D, i: int, spline_length: float) -> Vector2:
	if i == 0 or curve.get_point_count() < i + 1:
		return Vector2(0, 0)
	var last_point: Vector2 = curve.get_point_position(i - 1)
	var next_point: Vector2 = curve.get_point_position(i + 1)
	var spline: Vector2 = last_point.direction_to(next_point) * spline_length
	return spline
