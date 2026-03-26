extends Control

## Game over screen — red fade + restart.

@onready var restart_label: Label = $RestartLabel
@onready var background: ColorRect = $Background

var _blink_timer := 0.0

func _ready() -> void:
	modulate.a = 0.0
	_fade_in()
	GameManager.state_changed.connect(_on_state_changed)

func _process(delta: float) -> void:
	if restart_label:
		_blink_timer += delta
		restart_label.modulate.a = 0.5 + sin(_blink_timer * 2.0) * 0.5

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		GameManager.restart_from_checkpoint()
		_fade_out()

func _fade_in() -> void:
	visible = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.0)

func _fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): visible = false)

func _on_state_changed(new_state: GameManager.GameState) -> void:
	if new_state == GameManager.GameState.DEAD:
		_fade_in()
	elif new_state == GameManager.GameState.PLAYING:
		_fade_out()
