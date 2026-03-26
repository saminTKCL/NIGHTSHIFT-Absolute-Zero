extends Control

## Main menu with flickering title.

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $VBoxContainer/SubtitleLabel
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

var _flicker_timer := 0.0
var _flicker_interval := 3.0

func _ready() -> void:
	_flicker_interval = randf_range(2.0, 5.0)
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func _process(delta: float) -> void:
	_flicker_timer += delta
	if _flicker_timer >= _flicker_interval:
		_flicker_timer = 0.0
		_flicker_interval = randf_range(2.0, 6.0)
		_do_flicker()

func _do_flicker() -> void:
	if not title_label:
		return
	var tween := create_tween()
	tween.tween_property(title_label, "modulate:a", 0.3, 0.05)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.05)
	tween.tween_property(title_label, "modulate:a", 0.5, 0.03)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.08)

func _on_start_pressed() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		GameManager.start_game()
		queue_free()
	)

func _on_quit_pressed() -> void:
	get_tree().quit()
