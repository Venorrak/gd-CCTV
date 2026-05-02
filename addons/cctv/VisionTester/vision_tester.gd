@abstract
## Resource that checks if the Camera can see the target
class_name VisionTester extends Resource

## Checks if the Camera can see the target
@abstract
func can_see_target(target: Node3D, camera: CCTVCamera) -> bool
