class_name CameraController
extends Camera3D

enum CAMERA_ACTION {
	MOVING,
	ROTATING_VIEW,
}

@export var movement_speed: float = 30
@export var movement_damping: float = 0.74

#Value in percentage of screen portion
#A value of 0.3 means that when you place the cursor 30% or less away from an edge it will start pushing the camera
@export var edge_size: float = 0.0

#EDIT HERE--->**,***<--- ZOOM MIN AND MAX LIMITS
@export var min_zoom: float = 10
@export var max_zoom: float = 100

@export var zoom_sensibility: float = 2.5

@export var rotation_sensibility: float = 2.3

var pitch: float
var yaw: float
var current_action: CAMERA_ACTION = CAMERA_ACTION.MOVING
var velocity: Vector2

var _dragging: bool = false

func _ready() -> void:
	# Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

	pitch = rotation.x
	yaw = rotation.y


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ZoomIn"):
		position.y -= 20
	elif event.is_action_pressed("ZoomOut"):
		position.y += 20
	elif event.is_action_pressed("PanMap"):
		if event.pressed:
			Input.set_default_cursor_shape(Input.CURSOR_DRAG) # delete to disable drag cursor

			_dragging = true
	elif event.is_action_released("PanMap") and _dragging:
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)

			_dragging = false
	elif event is InputEventMouseMotion:
		if _dragging:
			event.relative *= position.y
			h_offset -= event.relative.x / 100
			v_offset += event.relative.y / 100


func change_action(action: CAMERA_ACTION) -> void:
	current_action = action
	match(current_action):
		CAMERA_ACTION.MOVING:
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
		CAMERA_ACTION.ROTATING_VIEW:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# func _process(delta: float) -> void:
# 	print(_drag_movement)
# 	h_offset += (-_drag_movement).x
# 	v_offset += (-_drag_movement).y

# 	if _drag_movement.length_squared() < 0.01:
# 		set_process(false)


func change_velocity(_velocity: Vector2) -> void:
	velocity = _velocity

func move(_velocity: Vector2) -> void:
	#Move along cameras X axis
	global_transform.origin += global_transform.basis.x * velocity.x * movement_speed * get_process_delta_time()
	#Calculate a forward camera direction that is perpendicular to the XZ plane
	var forward: Vector3 = global_transform.basis.x.cross(Vector3.UP)
	#Move the camera along that forward direction
	global_transform.origin += forward * velocity.y * movement_speed * get_process_delta_time()


func zoom(direction : float) -> void:
	#Zooming using fov
	var new_fov: Vector2 = fov + (sign(direction) * pow(abs(direction),zoom_sensibility)/100 * get_process_delta_time())
	fov = clamp(new_fov,min_zoom,max_zoom)


func rotate_view(axis: Vector2) -> void:
	var pitch_rotation_amount: float = -axis.y/100 * get_process_delta_time() * rotation_sensibility
	var yaw_rotation_amount: float = -axis.x/100 * get_process_delta_time() * rotation_sensibility

	pitch += pitch_rotation_amount
	pitch = clamp(pitch,-PI/2,0)

	yaw += yaw_rotation_amount

	rotation.x = pitch
	rotation.y = yaw
