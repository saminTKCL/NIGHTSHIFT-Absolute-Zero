extends Node3D

## Searchlight sentry — sweeping cone detection → alert → game over.

signal player_detected
signal alert_started
signal alert_ended

@export_group("Sweep")
@export var sweep_arc_degrees := 90.0
@export var sweep_speed := 30.0
@export var pause_at_edges := 1.0
@export var start_angle := -45.0

@export_group("Detection")
@export var cone_range := 15.0
@export var cone_angle_degrees := 25.0
@export var detection_delay := 0.0

@export_group("Visual")
@export var light_color := Color(1.0, 0.95, 0.8)
@export var alert_color := Color(1.0, 0.15, 0.1)
@export var light_energy := 3.0

var _sweep_direction := 1.0
var _current_angle := 0.0
var _pause_timer := 0.0
var _is_paused := false
var _is_alerted := false
var _detection_timer := 0.0

@onready var spot_light: SpotLight3D = $SpotLight
@onready var detection_area: Area3D = $DetectionArea

func _ready() -> void:
	_current_angle = start_angle
	_setup_light()
	_setup_detection()

func _process(delta: float) -> void:
	if _is_alerted:
		return
	_update_sweep(delta)
	_update_detection(delta)

func _setup_light() -> void:
	if not spot_light:
		spot_light = SpotLight3D.new()
		spot_light.name = "SpotLight"
		add_child(spot_light)
	spot_light.light_color = light_color
	spot_light.light_energy = light_energy
	spot_light.spot_range = cone_range
	spot_light.spot_angle = cone_angle_degrees
	spot_light.shadow_enabled = true

func _setup_detection() -> void:
	if not detection_area:
		detection_area = Area3D.new()
		detection_area.name = "DetectionArea"
		add_child(detection_area)
	detection_area.collision_layer = 16
	detection_area.collision_mask = 2
	var col_shape := CollisionShape3D.new()
	var cone := CylinderShape3D.new()
	cone.radius = cone_range * tan(deg_to_rad(cone_angle_degrees))
	cone.height = cone_range
	col_shape.shape = cone
	col_shape.position = Vector3(0, 0, -cone_range * 0.5)
	col_shape.rotation_degrees.x = 90
	detection_area.add_child(col_shape)
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

func _update_sweep(delta: float) -> void:
	if _is_paused:
		_pause_timer -= delta
		if _pause_timer <= 0.0:
			_is_paused = false
			_sweep_direction *= -1.0
		return
	_current_angle += sweep_speed * _sweep_direction * delta
	rotation_degrees.y = _current_angle
	var half_arc := sweep_arc_degrees * 0.5
	if abs(_current_angle - start_angle) > half_arc:
		_current_angle = start_angle + half_arc * _sweep_direction
		rotation_degrees.y = _current_angle
		_is_paused = true
		_pause_timer = pause_at_edges

func _update_detection(delta: float) -> void:
	if _detection_timer > 0.0:
		_detection_timer -= delta
		if _detection_timer <= 0.0:
			_trigger_alert()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not _is_alerted:
		if detection_delay > 0.0:
			_detection_timer = detection_delay
		else:
			_trigger_alert()

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_detection_timer = 0.0

func _trigger_alert() -> void:
	_is_alerted = true
	alert_started.emit()
	player_detected.emit()
	if spot_light:
		spot_light.light_color = alert_color
		spot_light.light_energy = light_energy * 2.0
	var camera := get_viewport().get_camera_3d()
	if camera and camera.has_method("shake"):
		camera.shake(1.0)
	await get_tree().create_timer(0.3).timeout
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("die"):
		player.die()
	await get_tree().create_timer(2.0).timeout
	_reset()

func _reset() -> void:
	_is_alerted = false
	_detection_timer = 0.0
	if spot_light:
		spot_light.light_color = light_color
		spot_light.light_energy = light_energy
	alert_ended.emit()
