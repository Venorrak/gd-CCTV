@tool
## Camera part of the CCTV addon.
@icon("res://addons/cctv/icons/CCTVCamera.svg")
class_name CCTVCamera extends Camera3D

@export var vision_tester : VisionTester = NormalVision.new() ## [VisionTester]
@export var camera_behaviour : CameraBehaviour = NormalBehaviour.new() ## [CameraBehaviour]
@export_tool_button("Align Transform With Viewport") var _align_transform_with_viewport_action = _align_transform_with_viewport
@export_tool_button("Align Rotation With Viewport") var _align_rotation_with_viewport_action = _align_rotation_with_viewport
@export_tool_button("Align Position With Viewport") var _align_position_with_viewport_action = _align_position_with_viewport
var target : Node3D ## Target attributed to the camera to look at

func _init() -> void:
	if not vision_tester : vision_tester = NormalVision.new()
	if not camera_behaviour: camera_behaviour = NormalBehaviour.new()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	if not target: return
	camera_behaviour.update_camera(delta, self, target)

## Returns if the camera can see the target using it's [VisionTester]. Always returns false if target is not defined
func can_see_target() -> bool:
	if not target: push_warning("No target defined"); return false
	return vision_tester.can_see_target(target, self)

## Returns the distance from the camera to the target. Will always return [constant @GDScript.INF] if the target is not defined
func distance_to_target() -> float:
	if not target: return INF
	return global_position.distance_to(target.global_position)

## Returns true if the target is in the camera's frustum. Will always return false if the target is not defined
func is_target_in_frustum() -> bool:
	if not target: return false
	return is_position_in_frustum(target.global_position)

func _align_transform_with_viewport() -> void:
	if Engine.is_editor_hint():
		var editor_viewport = EditorInterface.get_editor_viewport_3d(0)
		self.global_transform = editor_viewport.get_camera_3d().global_transform

func _align_rotation_with_viewport() -> void:
	if Engine.is_editor_hint():
		var editor_viewport = EditorInterface.get_editor_viewport_3d(0)
		self.global_rotation = editor_viewport.get_camera_3d().global_rotation

func _align_position_with_viewport() -> void:
	if Engine.is_editor_hint():
		var editor_viewport = EditorInterface.get_editor_viewport_3d(0)
		self.global_position = editor_viewport.get_camera_3d().global_position
