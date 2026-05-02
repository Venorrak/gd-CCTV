@abstract
## Used to declare how the camera will move and behave
class_name CameraBehaviour extends Resource

## Called each frame to move the camera and childrens
@abstract
func update_camera(delta: float, camera: CCTVCamera, target: Node3D) -> void
