## Part of the CCTV addon.[br]
## Used to manage a group of [CCTVCamera].[br]
## Makes the camera closest to the target that can see it the current camera.
@icon("res://addons/cctv/icons/CCTVManager.svg")
class_name CCTVManager extends Node

@export var cameras : Array[CCTVCamera] ## group of managed [CCTVCamera]
@export var target : Node3D: ## Target given to each [CCTVCamera]
	set(value):
		target = value
		if cameras.is_empty(): return
		for c in cameras:
			c.target = value
@export var time_between_camera_change_check : float = 0.1 ## Each X seconds the manager checks which camera should be the current one
@export var enabled : bool = true ## enables / disables the manager. Stops changing the current camera 

var _camera_change_timer : Timer

func _ready() -> void:
	_setup_timer()

func _setup_timer() -> void:
	if _camera_change_timer: return
	_camera_change_timer = Timer.new()
	_camera_change_timer.autostart = true
	_camera_change_timer.wait_time = time_between_camera_change_check
	_camera_change_timer.timeout.connect(_camera_change_callback)
	add_child(_camera_change_timer)
	
func _camera_change_callback() -> void:
	if not enabled: return
	if cameras.is_empty(): return
	var nearest_camera : CCTVCamera
	var nearest : float = 999999999999
	for c in cameras:
		if not c.can_see_target(): continue
		var dist : float = c.distance_to_target()
		if dist < nearest:
			nearest = dist
			nearest_camera = c

	if not nearest_camera:
		push_warning("no camera can see the target")
		return

	if not nearest_camera.current:
		nearest_camera.make_current()
