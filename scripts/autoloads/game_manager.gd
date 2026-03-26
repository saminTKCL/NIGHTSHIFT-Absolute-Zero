extends Node

## Global game state manager — autoloaded singleton.

signal state_changed(new_state: GameState)
signal checkpoint_reached(position: Vector3)
signal player_died

enum GameState { MENU, PLAYING, PAUSED, DEAD, CUTSCENE, LOADING }

var current_state: GameState = GameState.MENU
var current_level: String = ""
var checkpoint_position: Vector3 = Vector3.ZERO
var death_count: int = 0
var vignette_material: ShaderMaterial = null
var grain_material: ShaderMaterial = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if current_state == GameState.PLAYING:
			pause_game()
		elif current_state == GameState.PAUSED:
			resume_game()

func start_game() -> void:
	death_count = 0
	change_state(GameState.LOADING)
	load_level("res://scenes/levels/level_01.tscn")

func change_state(new_state: GameState) -> void:
	current_state = new_state
	state_changed.emit(new_state)
	match new_state:
		GameState.PAUSED:
			get_tree().paused = true
		GameState.PLAYING:
			get_tree().paused = false
		GameState.DEAD:
			get_tree().paused = false

func pause_game() -> void:
	change_state(GameState.PAUSED)

func resume_game() -> void:
	change_state(GameState.PLAYING)

func kill_player() -> void:
	if current_state == GameState.DEAD:
		return
	death_count += 1
	change_state(GameState.DEAD)
	player_died.emit()
	if vignette_material:
		var tween := create_tween()
		tween.tween_property(vignette_material, "shader_parameter/danger_intensity", 1.0, 0.15)
		tween.tween_interval(0.8)
		tween.tween_callback(restart_from_checkpoint)

func restart_from_checkpoint() -> void:
	if vignette_material:
		vignette_material.set_shader_parameter("danger_intensity", 0.0)
	if current_level != "":
		load_level(current_level)

func set_checkpoint(pos: Vector3) -> void:
	checkpoint_position = pos
	checkpoint_reached.emit(pos)

func load_level(scene_path: String) -> void:
	current_level = scene_path
	change_state(GameState.LOADING)
	var tree := get_tree()
	await tree.create_timer(0.3).timeout
	tree.change_scene_to_file(scene_path)
	await tree.tree_changed
	change_state(GameState.PLAYING)

func is_playing() -> bool:
	return current_state == GameState.PLAYING

func is_paused() -> bool:
	return current_state == GameState.PAUSED
