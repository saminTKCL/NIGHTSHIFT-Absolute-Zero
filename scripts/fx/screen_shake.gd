extends Node

## Trauma-based screen shake utility.

signal shake_applied(offset: Vector3, rotation: float)

@export var max_offset := Vector2(0.5, 0.3)
@export var max_rotation_deg := 2.0
@export var trauma_decay_rate := 1.5
@export var frequency := 20.0

var trauma: float = 0.0
var _time: float = 0.0

func _process(delta: float) -> void:
	_time += delta
	if trauma > 0.0:
		trauma = max(trauma - trauma_decay_rate * delta, 0.0)
		var shake_amount := trauma * trauma
		var offset := Vector3(
			max_offset.x * shake_amount * _noise(_time * frequency, 0.0),
			max_offset.y * shake_amount * _noise(_time * frequency, 100.0),
			0.0
		)
		var rotation := max_rotation_deg * shake_amount * _noise(_time * frequency, 200.0)
		shake_applied.emit(offset, rotation)

func add_trauma(amount: float) -> void:
	trauma = min(trauma + amount, 1.0)

func shake_heavy() -> void:
	add_trauma(0.7)

func shake_light() -> void:
	add_trauma(0.2)

func shake_landing(fall_speed: float) -> void:
	var intensity: float = clampf(fall_speed / 20.0, 0.0, 0.6)
	add_trauma(intensity)

func _noise(t: float, seed_offset: float) -> float:
	var s := t + seed_offset
	return sin(s * 1.0) * 0.5 + sin(s * 2.3) * 0.3 + sin(s * 4.1) * 0.2
