extends Node3D

## Swingable chain — PinJoint3D-connected segments with pendulum physics.

signal player_grabbed
signal player_released

@export var segment_count := 6
@export var segment_length := 0.8
@export var segment_mass := 2.0
@export var swing_force := 8.0
@export var grab_offset := Vector3(0, -0.3, 0)

var _segments: Array[RigidBody3D] = []
var _joints: Array[PinJoint3D] = []
var _is_grabbed := false
var _grabbing_player: CharacterBody3D = null
var _grab_segment_index := -1

func _ready() -> void:
	_build_chain()

func _physics_process(delta: float) -> void:
	if not _is_grabbed or not _grabbing_player:
		return
	var seg := _segments[_grab_segment_index]
	_grabbing_player.global_position = seg.global_position + grab_offset
	var input_x := Input.get_axis("move_left", "move_right")
	if abs(input_x) > 0.1:
		seg.apply_central_force(Vector3(input_x * swing_force, 0, 0))
	if Input.is_action_just_pressed("jump"):
		release_player()
		var launch_vel := seg.linear_velocity
		_grabbing_player.velocity = Vector3(launch_vel.x * 1.5, max(launch_vel.y, 6.0), 0)

func _build_chain() -> void:
	for i in segment_count:
		var seg := RigidBody3D.new()
		seg.name = "Segment_%d" % i
		seg.mass = segment_mass
		seg.collision_layer = 4
		seg.collision_mask = 1
		seg.axis_lock_linear_z = true
		seg.axis_lock_angular_x = true
		seg.axis_lock_angular_y = true
		seg.linear_damp = 0.3
		add_child(seg)
		var col := CollisionShape3D.new()
		var shape := CapsuleShape3D.new()
		shape.radius = 0.05
		shape.height = segment_length
		col.shape = shape
		seg.add_child(col)
		var mesh_inst := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.03
		mesh.bottom_radius = 0.03
		mesh.height = segment_length
		mesh_inst.mesh = mesh
		seg.add_child(mesh_inst)
		seg.position = Vector3(0, -i * segment_length, 0)
		var joint := PinJoint3D.new()
		joint.name = "Joint_%d" % i
		add_child(joint)
		if i == 0:
			joint.node_a = get_path()
			joint.node_b = seg.get_path()
		else:
			joint.node_a = _segments[i - 1].get_path()
			joint.node_b = seg.get_path()
		_segments.append(seg)
		_joints.append(joint)

func interact(player: CharacterBody3D) -> void:
	if _is_grabbed:
		return
	grab_player(player, _segments.size() - 2)

func grab_player(player: CharacterBody3D, segment_index: int) -> void:
	_is_grabbed = true
	_grabbing_player = player
	_grab_segment_index = clamp(segment_index, 0, _segments.size() - 1)
	player.velocity = Vector3.ZERO
	player_grabbed.emit()

func release_player() -> void:
	_is_grabbed = false
	_grabbing_player = null
	_grab_segment_index = -1
	player_released.emit()
