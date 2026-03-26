extends Camera3D

## Dynamic cinematic camera — smooth follow, zoom zones, screen shake.

@export_group("Follow")
@export var follow_target: NodePath
@export var follow_speed := 4.0
@export var look_ahead_distance := 2.0
@export var look_ahead_speed := 3.0
@export var vertical_offset := 2.0

@export_group("Zoom")
@export var default_zoom_distance := 12.0
@export var zoom_speed := 2.0
@export var min_zoom := 5.0
@export var max_zoom := 30.0

@export_group("Shake")
@export var shake_enabled := true

var _target: Node3D = null
var _current_zoom := 12.0
var _target_zoom := 12.0
var _look_ahead_offset := 0.0
var _shake_offset := Vector3.ZERO
var _shake_rotation := 0.0
var _base_rotation: Vector3
var _screen_shake: Node = null
var _zone_override := false
var _zone_zoom := 12.0
var _zone_offset := Vector3.ZERO
var _zone_tween: Tween = null

func _ready() -> void:
	_base_rotation = rotation
	_current_zoom = default_zoom_distance
	_target_zoom = default_zoom_distance
	if follow_target:
		_target = get_node_or_null(follow_target)
	_screen_shake = Node.new()
	var shake_script := preload("res://scripts/fx/screen_shake.gd")
	_screen_shake.set_script(shake_script)
	_screen_shake.name = "CameraShake"
	add_child(_screen_shake)
	_screen_shake.shake_applied.connect(_on_shake_applied)

func _process(delta: float) -> void:
	if not _target:
		_target = get_tree().get_first_node_in_group("player")
		if not _target:
			return
	_update_follow(delta)
	_update_zoom(delta)
	_apply_shake()

func _update_follow(delta: float) -> void:
	var target_pos := _target.global_position
	var player := _target as CharacterBody3D
	if player:
		var vel_x := player.velocity.x
		var target_ahead: float = sign(vel_x) * look_ahead_distance
		_look_ahead_offset = lerp(_look_ahead_offset, target_ahead, look_ahead_speed * delta)
	var desired := Vector3(
		target_pos.x + _look_ahead_offset,
		target_pos.y + vertical_offset,
		_current_zoom
	)
	if _zone_override:
		desired += _zone_offset
	global_position = global_position.lerp(desired + _shake_offset, follow_speed * delta)

func _update_zoom(delta: float) -> void:
	var target := _zone_zoom if _zone_override else _target_zoom
	_current_zoom = lerp(_current_zoom, target, zoom_speed * delta)

func _apply_shake() -> void:
	if not shake_enabled:
		return
	rotation = _base_rotation
	rotation.z += deg_to_rad(_shake_rotation)

func _on_shake_applied(offset: Vector3, rotation_deg: float) -> void:
	_shake_offset = offset
	_shake_rotation = rotation_deg

func set_zoom(distance: float, transition_time := 0.0) -> void:
	_target_zoom = clamp(distance, min_zoom, max_zoom)
	if transition_time > 0.0:
		var tween := create_tween()
		tween.tween_property(self, "_current_zoom", _target_zoom, transition_time).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)

func enter_zone(zoom: float, offset: Vector3, transition_time := 1.0) -> void:
	_zone_override = true
	_zone_zoom = clamp(zoom, min_zoom, max_zoom)
	if _zone_tween:
		_zone_tween.kill()
	_zone_tween = create_tween().set_parallel(true)
	_zone_tween.tween_property(self, "_zone_offset", offset, transition_time).set_ease(Tween.EASE_IN_OUT)

func exit_zone(transition_time := 1.0) -> void:
	_zone_override = false
	if _zone_tween:
		_zone_tween.kill()
	_zone_tween = create_tween()
	_zone_tween.tween_property(self, "_zone_offset", Vector3.ZERO, transition_time).set_ease(Tween.EASE_IN_OUT)

func shake(amount: float) -> void:
	if _screen_shake:
		_screen_shake.add_trauma(amount)

func get_shake() -> Node:
	return _screen_shake
