extends Control

## Pause menu overlay.

@onready var resume_button: Button = $PanelContainer/VBoxContainer/ResumeButton
@onready var quit_button: Button = $PanelContainer/VBoxContainer/QuitButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	if resume_button:
		resume_button.pressed.connect(_on_resume)
	if quit_button:
		quit_button.pressed.connect(_on_quit)
	GameManager.state_changed.connect(_on_state_changed)

func _on_state_changed(new_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.PAUSED:
			visible = true
			_animate_in()
		GameManager.GameState.PLAYING:
			_animate_out()

func _animate_in() -> void:
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

func _animate_out() -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func(): visible = false)

func _on_resume() -> void:
	GameManager.resume_game()

func _on_quit() -> void:
	get_tree().quit()
