@tool
## Part of the CCTV addon.[br]
## Used to manage a group of [CCTVCamera].[br]
## Makes the camera closest to the target that can see it the current camera.
@icon("res://addons/cctv/icons/CCTVManager.svg")
class_name CameraManager extends Node

@export var cameras : Array[CCTVCamera] ## group of managed [CCTVCamera]
@export var target : Node3D: ## Target given to each [CCTVCamera]
	set(value):
		target = value
		if cameras.is_empty(): return
		for c in cameras:
			c.target = value
@export var behaviour: ManagerBehaviour
@export var time_between_camera_change_check : float = 0.1 ## Each X seconds the manager checks which camera should be the current one
@export var return_to_old_cam: bool = true ## Will remember the camera used before toggling on the manager and will revert back to it when disabled
@export var enabled : bool = true:
	set(value):
		enabled = value
		enable_toggled.emit(value)## enables / disables the manager. Stops changing the current camera 
		
		if value:
			toggle_back_camera = get_viewport().get_camera_3d()
		elif toggle_back_camera and not value and return_to_old_cam:
			toggle_back_camera.make_current()
@export_tool_button("Auto Detect Cameras In Scene") var _auto_detect_cameras_action = _auto_detect_camera

var _camera_change_timer : Timer
var toggle_back_camera: Camera3D

signal camera_changed(oldCamera: Camera3D, newCamera: CCTVCamera)
signal enable_toggled(enabled: bool)

func _init() -> void:
	behaviour = NearestBehaviour.new()

func _ready() -> void:
	if Engine.is_editor_hint(): return
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
	
	var chosen_camera : CCTVCamera = behaviour.select_camera(self)

	if not chosen_camera:
		push_warning("no camera was selected")
		return

	if not chosen_camera.current:
		var oldCam : Camera3D = get_viewport().get_camera_3d()
		chosen_camera.make_current()
		camera_changed.emit(oldCam, chosen_camera)

func _auto_detect_camera() -> void:
	var root : Node = EditorInterface.get_edited_scene_root()
	var _camera_list: Array[CCTVCamera] = []
	_auto_detect_camera_rec(root, _camera_list)
	cameras = _camera_list

func _auto_detect_camera_rec(node: Node, list: Array[CCTVCamera]) -> void:
	if node is CCTVCamera: list.append(node)
	for n in node.get_children():
		_auto_detect_camera_rec(n, list)
