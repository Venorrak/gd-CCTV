@tool
## Camera smoothly turns towards the target and the raycast is pointed directly at the target
class_name NormalBehaviour extends CameraBehaviour

@export_group("Rotation")
@export var smoothing : float = 2.0 ## Value used to lerp the camera's rotation to see the target.[br][code]smoothing * delta[/code]
@export_range(0.0, 180.0, 0.1, "degrees") var max_yaw_deg: float = 90.0   ## max left/right angle
@export_range(0.0, 180.0, 0.1, "degrees") var max_pitch_deg: float = 90.0 ## max up/down angle

@export_group("FOV")
@export_range(1.0, 179, 0.1, "degrees") var max_zoom_fov : float = 35 ## Maximum fov the camera can have
@export_range(1.0, 179, 0.1, "degrees") var min_zoom_fov : float = 75 ## Minimum fov the camera can have
@export var min_zoom_dist : float = 10 ## The fov will start getting smaller when the target is further than this
@export var max_zoom_dist : float = 50 ## The fow will stop getting smaller when the target is further than this
@export var zoom_curve : Curve = Curve.new() ## The fov between the max and min will follow this curve

var _base_basis : Basis

func update_camera(delta: float, camera: CCTVCamera, target: Node3D) -> void:
    if not _base_basis: _base_basis = camera.basis # set the initial camera basis as the base

    #camera.basis = camera.basis.slerp(Basis.looking_at(camera.global_position.direction_to(target.global_position)), smoothing * delta) # turn the camera
    var desired_basis : Basis = Basis.looking_at(camera.global_position.direction_to(target.global_position))

    # Convert desired rotation into local rotation relative to base
    var relative : Basis = _base_basis.inverse() * desired_basis

    # Extract local euler angles and clamp angles
    var euler : Vector3 = relative.get_euler()
    euler.x = clamp(euler.x, deg_to_rad(-max_pitch_deg), deg_to_rad(max_pitch_deg))
    euler.y = clamp(euler.y, deg_to_rad(-max_yaw_deg), deg_to_rad(max_yaw_deg))
    euler.z = 0.0

    var clamped_basis : Basis = _base_basis * Basis.from_euler(euler) # back to basis
    camera.basis = camera.basis.slerp(clamped_basis, smoothing * delta) # smoothly turn the camera
    
    var q : Quaternion = (camera.basis.inverse() * Basis.looking_at(camera.global_position.direction_to(target.global_position))).get_rotation_quaternion()
    camera.get_raycast().target_position = Vector3(0.0, 0.0, -99999.0).rotated(q.get_axis().normalized(), q.get_angle()) #points the raycast directly towards the target
    
    var i : float = inverse_lerp(min_zoom_dist, max_zoom_dist, clamp(camera.distance_to_target(), min_zoom_dist, max_zoom_dist)) # get the clamped value of where we are between min_zoom_dist and max_zoom_dist 
    camera.fov = lerp(min_zoom_fov, max_zoom_fov, zoom_curve.sample(i)) # set the fov following the curve
