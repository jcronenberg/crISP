class_name Building3D
extends MeshInstance3D

@export var height: float
@export var plot_size: float


func set_values(new_plot_size: float, new_height: float) -> void:
	plot_size = new_plot_size
	height = new_height

	var new_house_mesh: BoxMesh = BoxMesh.new()
	new_house_mesh.set_size(Vector3(plot_size, height, plot_size))
	var house_material: StandardMaterial3D = StandardMaterial3D.new()
	house_material.albedo_color = Color("#03346e")
	new_house_mesh.material = house_material
	mesh = new_house_mesh
	$Roof.mesh.size.x = plot_size
	$Roof.mesh.size.y = plot_size

	# global_position.y = height / 2
	$Roof.position.y = height / 2
