# res://autoload/audio_settings.gd
extends Node

const MUSIC_BUS := "Music"
const SFX_BUS   := "SFX"

var music_volume: float = 1.0 # 0.0–1.0
var sfx_volume: float = 1.0   # 0.0–1.0

func _ready() -> void:
	_apply_music_volume()
	_apply_sfx_volume()


# ---------------- MUSIC ----------------

func set_music_volume(value: float) -> void:
	music_volume = clamp(value, 0.0, 1.0)
	_apply_music_volume()

func _apply_music_volume() -> void:
	_set_bus_linear_volume(MUSIC_BUS, music_volume)


# ---------------- SFX ----------------

func set_sfx_volume(value: float) -> void:
	sfx_volume = clamp(value, 0.0, 1.0)
	_apply_sfx_volume()

func _apply_sfx_volume() -> void:
	_set_bus_linear_volume(SFX_BUS, sfx_volume)


# ---------------- INTERNAL HELPER ----------------

func _set_bus_linear_volume(bus_name: String, volume: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		push_error("Audio bus not found: %s" % bus_name)
		return

	if volume <= 0.001:
		AudioServer.set_bus_volume_db(idx, -80.0)
	else:
		AudioServer.set_bus_volume_db(idx, linear_to_db(volume))
