extends CharacterBody3D

## Player controller — weighted 2.5D movement locked to Z=0.

signal interacted_with(body: Node)
signal state_changed(new_state: PlayerState)

enum PlayerState { IDLE, RUNNING, JUMPING, FALLING, PUSHING, CLIMBING, DEAD }

@export_group("Movement")
@export var max_speed := 5.0
@export var acceleration := 25.0
@export var deceleration := 30.0
@export var push_speed_multiplier := 0.4

@export_group("Jump")
@export var jump_force := 10.0
@export var jump_cut_multiplier := 0.4
@export var gravity := 28.0
@export var fall_gravity_multiplier := 1.4
@export var max_fall_speed := 25.0
@export var coyote_time := 0.12
@export var jump_buffer_time := 0.1

@export_group("Feel")
@export var hard_landing_threshold := 12.0
@export var head_bob_amount := 0.02
@export var head_bob_speed := 12.0

@onready var mesh: MeshInstance3D = $PlayerMesh
@onready var collision_shape: CollisionShape3D = $CollisionShape
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var interact_ray: RayCast3D = $InteractRay
@onready var wall_ray_left: RayCast3D = $WallRayLeft
@onready var wall_ray_right: RayCast3D = $WallRayRight
@onready var screen_shake: Node = $ScreenShake

var current_state: PlayerState = PlayerState.IDLE
var facing_direction := 1.0
var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _was_on_floor := false
var _fall_start_speed := 0.0
var _head_bob_time := 0.0
var _push_target: Node = null
var _is_near_wall := false
var _wall_side := 0

var stamina := 1.0
var stamina_drain_rate := 0.08
var stamina_recover_rate := 0.15
var is_panting := false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 4
	if not screen_shake:
		var shake_script := preload("res://scripts/fx/screen_shake.gd")
		screen_shake = Node.new()
		screen_shake.set_script(shake_script)
		screen_shake.name = "ScreenShake"
		add_child(screen_shake)

func _physics_process(delta: float) -> void:
	if current_state == PlayerState.DEAD:
		return
	_handle_gravity(delta)
	_handle_movement(delta)
	_handle_jump(delta)
	_handle_interaction()
	_update_wall_detection()
	_update_stamina(delta)
	_update_head_bob(delta)
	_update_state()
	_lock_z_axis()
	var pre_move_y := velocity.y
	move_and_slide()
	_check_landing(pre_move_y)
	if is_on_floor():
		_coyote_timer = coyote_time
		_was_on_floor = true
	else:
		_coyote_timer = max(_coyote_timer - delta, 0.0)
		if _was_on_floor and velocity.y < 0:
			_fall_start_speed = 0.0
		_was_on_floor = false
	_jump_buffer_timer = max(_jump_buffer_timer - delta, 0.0)

func _handle_gravity(delta: float) -> void:
	if not is_on_floor():
		var grav_mult := fall_gravity_multiplier if velocity.y < 0 else 1.0
		velocity.y -= gravity * grav_mult * delta
		velocity.y = max(velocity.y, -max_fall_speed)

func _handle_movement(delta: float) -> void:
	var input_dir := Input.get_axis("move_left", "move_right")
	var speed := max_speed
	if current_state == PlayerState.PUSHING:
		speed *= push_speed_multiplier
	if abs(input_dir) > 0.1:
		velocity.x = move_toward(velocity.x, input_dir * speed, acceleration * delta)
		facing_direction = sign(input_dir)
		if mesh:
			mesh.scale.x = facing_direction
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)

func _handle_jump(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = jump_force
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		_fall_start_speed = 0.0
	if Input.is_action_just_released("jump") and velocity.y > 0:
		velocity.y *= jump_cut_multiplier

func _handle_interaction() -> void:
	if not Input.is_action_just_pressed("interact"):
		return
	if interact_ray and interact_ray.is_colliding():
		var collider := interact_ray.get_collider()
		if collider and collider.has_method("interact"):
			collider.interact(self)
			interacted_with.emit(collider)
	if interact_ray:
		interact_ray.target_position = Vector3(facing_direction * 1.2, 0, 0)

func _update_wall_detection() -> void:
	_is_near_wall = false
	_wall_side = 0
	if wall_ray_left and wall_ray_left.is_colliding():
		_is_near_wall = true
		_wall_side = -1
	elif wall_ray_right and wall_ray_right.is_colliding():
		_is_near_wall = true
		_wall_side = 1

func _update_stamina(delta: float) -> void:
	if abs(velocity.x) > max_speed * 0.8 and is_on_floor():
		stamina = max(stamina - stamina_drain_rate * delta, 0.0)
	else:
		stamina = min(stamina + stamina_recover_rate * delta, 1.0)
	is_panting = stamina < 0.3

func _update_head_bob(delta: float) -> void:
	if is_on_floor() and abs(velocity.x) > 1.0 and mesh:
		_head_bob_time += delta * head_bob_speed * (abs(velocity.x) / max_speed)
		mesh.position.y = sin(_head_bob_time) * head_bob_amount
	elif mesh:
		mesh.position.y = lerp(mesh.position.y, 0.0, delta * 10.0)

func _update_state() -> void:
	var new_state := current_state
	if not is_on_floor():
		new_state = PlayerState.JUMPING if velocity.y > 0 else PlayerState.FALLING
	elif _push_target != null and abs(velocity.x) > 0.1:
		new_state = PlayerState.PUSHING
	elif abs(velocity.x) > 0.5:
		new_state = PlayerState.RUNNING
	else:
		new_state = PlayerState.IDLE
	if new_state != current_state:
		current_state = new_state
		state_changed.emit(new_state)
		_play_state_animation()

func _play_state_animation() -> void:
	if not animation_player:
		return
	match current_state:
		PlayerState.IDLE:
			if is_panting and animation_player.has_animation("pant"):
				animation_player.play("pant")
			elif animation_player.has_animation("idle"):
				animation_player.play("idle")
		PlayerState.RUNNING:
			if animation_player.has_animation("run"):
				animation_player.play("run")
		PlayerState.JUMPING:
			if animation_player.has_animation("jump"):
				animation_player.play("jump")
		PlayerState.FALLING:
			if animation_player.has_animation("fall"):
				animation_player.play("fall")
		PlayerState.PUSHING:
			if animation_player.has_animation("push"):
				animation_player.play("push")

func _check_landing(pre_move_y: float) -> void:
	if is_on_floor() and not _was_on_floor:
		var impact_speed: float = absf(pre_move_y)
		if impact_speed > hard_landing_threshold and screen_shake:
			screen_shake.shake_landing(impact_speed)
			if mesh:
				var tween := create_tween()
				tween.tween_property(mesh, "scale", Vector3(1.2 * facing_direction, 0.8, 1.0), 0.06)
				tween.tween_property(mesh, "scale", Vector3(1.0 * facing_direction, 1.0, 1.0), 0.15).set_ease(Tween.EASE_OUT)

func _lock_z_axis() -> void:
	position.z = 0.0
	velocity.z = 0.0

func die() -> void:
	if current_state == PlayerState.DEAD:
		return
	current_state = PlayerState.DEAD
	velocity = Vector3.ZERO
	GameManager.kill_player()

func set_push_target(target: Node) -> void:
	_push_target = target

func clear_push_target() -> void:
	_push_target = null
