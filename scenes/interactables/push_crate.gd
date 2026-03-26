extends RigidBody3D

## Pushable heavy crate constrained to X-axis.

@export var push_force := 3.0
@export var max_push_speed := 2.5

var _is_being_pushed := false
var _pusher: CharacterBody3D = null

func _ready() -> void:
	mass = 50.0
	collision_layer = 4
	collision_mask = 1
	linear_damp = 3.0
	angular_damp = 10.0
	axis_lock_angular_x = true
	axis_lock_angular_y = true
	axis_lock_angular_z = true
	axis_lock_linear_z = true
	contact_monitor = true
	max_contacts_reported = 4

func _physics_process(delta: float) -> void:
	if abs(linear_velocity.x) > max_push_speed:
		linear_velocity.x = sign(linear_velocity.x) * max_push_speed
	position.z = 0.0
	linear_velocity.z = 0.0
	if _is_being_pushed and _pusher:
		var push_dir: float = sign(_pusher.velocity.x)
		if abs(_pusher.velocity.x) > 0.5:
			apply_central_force(Vector3(push_dir * push_force, 0, 0))

func interact(player: CharacterBody3D) -> void:
	if _is_being_pushed:
		release_push()
	else:
		start_push(player)

func start_push(player: CharacterBody3D) -> void:
	_is_being_pushed = true
	_pusher = player
	player.set_push_target(self)

func release_push() -> void:
	if _pusher:
		_pusher.clear_push_target()
	_is_being_pushed = false
	_pusher = null

func _on_body_exited(body: Node) -> void:
	if body == _pusher:
		release_push()
