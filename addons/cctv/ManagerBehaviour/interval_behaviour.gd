## Will rotate on an interval across all camera that can see the target
class_name IntervalBehaviour extends ManagerBehaviour

@export var switch_interval: float = 10.0 ## time in seconds between camera change
var _last_switch: int = 0
var _index: int = 0

func select_camera(manager: CameraManager) -> CCTVCamera:
	if Time.get_ticks_msec() > _last_switch + (switch_interval * 1000):
		_index += 1
		_last_switch = Time.get_ticks_msec()
	var can_see_camera: Array[CCTVCamera] = []
	for c in manager.cameras.duplicate(true): if c.can_see_target(): can_see_camera.append(c)
	if can_see_camera.is_empty(): return null
	return can_see_camera[_index % can_see_camera.size()]
