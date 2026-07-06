## can see if within a certain range and in the frustum
class_name NormalVision extends VisionTester
@export var visual_range_limit : float = 100

func can_see_target(target: Node3D, camera: CCTVCamera) -> bool:
	if camera.distance_to_target() > visual_range_limit: return false
	if camera.is_target_in_frustum():
		return true
	return false
