extends AnimatableBody3D

## Industrial lever — interact to toggle.

signal lever_activated(is_on: bool)

@export var is_on := false
@export var rotation_degrees_on := -45.0
@export var rotation_degrees_off := 45.0
@export var toggle_duration := 0.8

var _is_animating := false

func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	rotation_degrees.z = rotation_degrees_on if is_on else rotation_degrees_off

func interact(player: CharacterBody3D) -> void:
	if _is_animating:
		return
	toggle()

func toggle() -> void:
	_is_animating = true
	is_on = !is_on
	var target_rot := rotation_degrees_on if is_on else rotation_degrees_off
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "rotation_degrees:z", target_rot, toggle_duration)
	tween.tween_callback(func():
		_is_animating = false
		lever_activated.emit(is_on)
	)
