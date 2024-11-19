class_name City3D
extends Node3D

const building_scene = preload("res://src/3d/house.tscn")
#var base_fov: float = 75.0
#var zoom_factor: float = 1
@onready var walls_multmesh: MultiMesh = $RoofsMultiMesh.multimesh
@onready var roofs_multmesh: MultiMesh = $WallsMultiMesh.multimesh
@onready var parks_multmesh: MultiMesh = $ParksMultiMesh.multimesh
var objects: Array[CityObjectInstance3D] = []


func _ready() -> void:
	populate_multi_meshes()


func set_camera_pos(pos: Vector2, zoom: Vector2) -> void:
	# camera fov 77.3
	# 300 for 4 to 1
	# 300 for 2 to 1
	# 450 for 1 to 1
	# 900 for 1 to 2
	# 1800 for 1 to 4
	# Honestly no idea how this works, but through trial and error I found this calculation and it is surprisingly accurate
	var base_height: float = clamp((450 * (float(DisplayServer.window_get_size().y) / float(DisplayServer.window_get_size().x))), 300, 100000)
	$Camera3D.position = Vector3(pos.x, base_height / zoom.x, pos.y)
	#$Camera3D.position = Vector3(pos.x / 5, 85, pos.y / 5)
	#$Camera3D.fov = base_fov / zoom.x * zoom_factor


func populate_multi_meshes() -> void:
	var new_house_mesh: BoxMesh = BoxMesh.new()
	new_house_mesh.set_size(Vector3(1, 10, 1))
	# var house_material: StandardMaterial3D = load("res://resources/orange_placeholder.tres")
	var house_material: StandardMaterial3D = StandardMaterial3D.new()
	house_material.albedo_color = Color("#03346e")
	new_house_mesh.material = house_material
	walls_multmesh.mesh = new_house_mesh
	# TODO allow resizing
	walls_multmesh.use_colors = true
	walls_multmesh.instance_count = 16384
	walls_multmesh.visible_instance_count = 0

	var new_roof_mesh: PlaneMesh = PlaneMesh.new()
	new_roof_mesh.set_size(Vector2(1, 1))
	var roof_material: StandardMaterial3D = StandardMaterial3D.new()
	roof_material.albedo_color = Color("#e2e2b6")
	new_roof_mesh.material = roof_material
	roofs_multmesh.mesh = new_roof_mesh
	roofs_multmesh.use_colors = true
	roofs_multmesh.instance_count = 16384
	roofs_multmesh.visible_instance_count = 0

	parks_multmesh.use_colors = true
	parks_multmesh.instance_count = 16384
	parks_multmesh.visible_instance_count = 0


func place_building(pos: Vector2, width: int, height: float) -> void:
	var building: CityObjectInstance3D = CityObjectInstance3D.new(objects.size(), Vector2(width, width), height, pos)
	objects.append(building)
	walls_multmesh.visible_instance_count = objects.size()
	roofs_multmesh.visible_instance_count = objects.size()
	_place_building_instance(building)


func _place_building_instance(building: CityObjectInstance3D) -> void:
	walls_multmesh.set_instance_transform(building.index,
		Transform3D(Basis().scaled(Vector3(building.width.x, building.height, building.width.y)), Vector3(building.pos.x, building.height * 5, building.pos.y)))
	roofs_multmesh.set_instance_transform(building.index,
		Transform3D(Basis().scaled(Vector3(building.width.x, 1, building.width.y)), Vector3(building.pos.x, building.height * 10 + 0.1, building.pos.y)))


func place_park(pos: Vector2, width: int) -> void:
	var park: CityObjectInstance3D = CityObjectInstance3D.new(objects.size(), Vector2(width, width), 0, pos)
	objects.append(park)
	parks_multmesh.visible_instance_count = objects.size()
	_place_park_instance(park)


func _place_park_instance(park: CityObjectInstance3D) -> void:
	parks_multmesh.set_instance_transform(park.index,
		Transform3D(Basis().scaled(Vector3(park.width.x, park.height, park.width.y)), Vector3(park.pos.x + park.width.x / 2, park.height, park.pos.y + park.width.y / 2)))


class CityObjectInstance3D:
	# signal building_changed(building: CityObjectInstance3D)

	var index: int # Index of building in objects array
	var width: Vector2
	var height: float
	var pos: Vector2

	func _init(init_index: int, init_width: Vector2, init_height: float, init_pos: Vector2) -> void:
		index = init_index
		width = init_width
		height = init_height
		pos = init_pos


	func set_values(new_width: Vector2, new_height: float, new_pos: Vector2) -> void:
		width = new_width
		height = new_height
		pos = new_pos
		# building_changed.emit(self)
