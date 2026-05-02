## Camera part of the CCTV addon.
@icon("res://addons/cctv/icons/CCTVCamera.svg")
class_name CCTVCamera extends Camera3D

@export var vision_tester : VisionTester = NormalVision.new() ## [VisionTester]
@export var camera_behaviour : CameraBehaviour = NormalBehaviour.new() ## [CameraBehaviour]

var target : Node3D ## Target attributed to the camera to look at
var _raycast : RayCast3D

func _init() -> void:
    if not vision_tester : vision_tester = NormalVision.new()
    if not camera_behaviour: camera_behaviour = NormalBehaviour.new()

func _ready() -> void:
    _setup_raycast()

func _physics_process(delta: float) -> void:
    if Engine.is_editor_hint(): return
    if not target: return
    camera_behaviour.update_camera(delta, self, target)
        
func _setup_raycast() -> void:
    if _raycast: return
    _raycast = RayCast3D.new()
    _raycast.target_position = Vector3(0.0, 0.0, -99999.0)
    add_child(_raycast)

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

## Returns true if the raycast is colliding with the target
func is_raycast_colliding_with_target() -> bool:
    if _raycast.is_colliding() and _raycast.get_collider() == target:
        return true
    return false

## Returns the raycast3D child
func get_raycast() -> RayCast3D:
    return _raycast
