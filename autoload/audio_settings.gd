# res://autoload/audio_settings.gd
extends Node

const MUSIC_BUS := "Music"

var music_volume: float = 1.0 # 0.0–1.0

func _ready() -> void:
	_apply_music_volume()

func set_music_volume(value: float) -> void:
	music_volume = clamp(value, 0.0, 1.0)
	_apply_music_volume()

func _apply_music_volume() -> void:
	var idx := AudioServer.get_bus_index(MUSIC_BUS)
	if music_volume <= 0.001:
		AudioServer.set_bus_volume_db(idx, -80.0)
	else:
		AudioServer.set_bus_volume_db(idx, linear_to_db(music_volume))
