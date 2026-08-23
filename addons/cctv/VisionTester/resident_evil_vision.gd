## Can see if the target is in the area of if it has visual line of sight
class_name ResidentEvilVision extends VisionTester
@export_node_path("Area3D") var activation_area : NodePath ## Area3D the [VisionTester] can use to determine if the camera sees the target.

var _raycast : RayCast3D

func _setup_raycast(camera: CCTVCamera) -> void:
	if _raycast: return
	_raycast = RayCast3D.new()
	_raycast.target_position = Vector3(0.0, 0.0, -99999.0)
	camera.add_child(_raycast)

func can_see_target(target: Node3D, camera: CCTVCamera) -> bool:
	var area : Area3D = camera.get_node(activation_area)
	if area and area.overlaps_body(target): return true
	elif camera.is_target_in_frustum() and is_raycast_colliding_with_target(camera): return true
	return false

## Returns true if the raycast is colliding with the target
func is_raycast_colliding_with_target(camera: CCTVCamera) -> bool:
	if not _raycast: _setup_raycast(camera)
	if _raycast.is_colliding() and _raycast.get_collider() == camera.target:
		return true
	return false
