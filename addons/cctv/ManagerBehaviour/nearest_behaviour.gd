## Will select the nearest camera that can see the target
class_name NearestBehaviour extends ManagerBehaviour

func select_camera(manager: CameraManager) -> CCTVCamera:
	var sorted_by_nearest_camera: Array[CCTVCamera] = manager.cameras.duplicate(true)
	sorted_by_nearest_camera.sort_custom(func(a, b): return a.distance_to_target() > b.distance_to_target())
	for c in sorted_by_nearest_camera:
		if c.can_see_target(): return c
	return null
