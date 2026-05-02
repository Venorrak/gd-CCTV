## Can see if the target is in the area of if it has visual line of sight
class_name ResidentEvilVision extends VisionTester
@export_node_path("Area3D") var activation_area : NodePath ## Area3D the [VisionTester] can use to determine if the camera sees the target.

func can_see_target(target: Node3D, camera: CCTVCamera) -> bool:
    var area : Area3D = camera.get_node(activation_area)
    if area and area.overlaps_body(target): return true
    elif camera.is_target_in_frustum() and camera.is_raycast_colliding_with_target(): return true
    return false
