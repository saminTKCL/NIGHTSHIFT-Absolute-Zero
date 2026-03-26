extends Node

## Centralized audio manager — autoloaded singleton.

const SFX_POOL_SIZE := 8
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0
var _ambient_player: AudioStreamPlayer = null
var _ambient_player_b: AudioStreamPlayer = null
var _master_bus := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_master_bus = AudioServer.get_bus_index("Master")
	_setup_sfx_pool()
	_setup_ambient_players()

func _setup_sfx_pool() -> void:
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_sfx_players.append(player)

func _setup_ambient_players() -> void:
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = "Master"
	_ambient_player.volume_db = -6.0
	add_child(_ambient_player)
	_ambient_player_b = AudioStreamPlayer.new()
	_ambient_player_b.bus = "Master"
	_ambient_player_b.volume_db = -80.0
	add_child(_ambient_player_b)

func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> AudioStreamPlayer:
	var player := _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % SFX_POOL_SIZE
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()
	return player

func play_sfx_varied(stream: AudioStream, volume_db: float = 0.0, variation: float = 0.1) -> AudioStreamPlayer:
	var pitch := 1.0 + randf_range(-variation, variation)
	return play_sfx(stream, volume_db, pitch)

func set_ambient(stream: AudioStream, fade_duration: float = 2.0) -> void:
	if _ambient_player.stream == stream and _ambient_player.playing:
		return
	var old := _ambient_player
	_ambient_player = _ambient_player_b
	_ambient_player_b = old
	_ambient_player.stream = stream
	_ambient_player.volume_db = -80.0
	_ambient_player.play()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_ambient_player, "volume_db", -6.0, fade_duration)
	tween.tween_property(_ambient_player_b, "volume_db", -80.0, fade_duration)
	await tween.finished
	_ambient_player_b.stop()

func stop_ambient(fade_duration: float = 1.0) -> void:
	var tween := create_tween()
	tween.tween_property(_ambient_player, "volume_db", -80.0, fade_duration)
	await tween.finished
	_ambient_player.stop()

func set_master_volume(linear: float) -> void:
	AudioServer.set_bus_volume_db(_master_bus, linear_to_db(linear))
