# res://autoload/audio_settings.gd
## Global audio settings manager.
## Responsible for applying and updating volume on the Music and SFX buses.
##
## Usage:
##   AudioSettings.set_music_volume(0.5)
##   AudioSettings.set_sfx_volume(0.8)

extends Node

# ================================
#           CONSTANTS
# ================================

const BUS_MUSIC: String = "Music"
const BUS_SFX: String = "SFX"

const MIN_LINEAR_VOLUME: float = 0.0
const MAX_LINEAR_VOLUME: float = 1.0
const MUTE_DB: float = -80.0
const MIN_AUDIBLE_LINEAR: float = 0.001

# ================================
#        MEMBER VARIABLES
# ================================

## Master music volume in linear [0.0, 1.0].
var music_volume: float = 1.0

## Master SFX volume in linear [0.0, 1.0].
var sfx_volume: float = 1.0

# ================================
#         LIFECYCLE HOOKS
# ================================

func _ready() -> void:
	_apply_music_volume()
	_apply_sfx_volume()

# ================================
#            MUSIC API
# ================================

## Set the music volume in linear [0.0, 1.0].
func set_music_volume(value: float) -> void:
	music_volume = clamp(value, MIN_LINEAR_VOLUME, MAX_LINEAR_VOLUME)
	_apply_music_volume()

func _apply_music_volume() -> void:
	_set_bus_linear_volume(BUS_MUSIC, music_volume)

# ================================
#             SFX API
# ================================

## Set the SFX volume in linear [0.0, 1.0].
func set_sfx_volume(value: float) -> void:
	sfx_volume = clamp(value, MIN_LINEAR_VOLUME, MAX_LINEAR_VOLUME)
	_apply_sfx_volume()

func _apply_sfx_volume() -> void:
	_set_bus_linear_volume(BUS_SFX, sfx_volume)

# ================================
#          PRIVATE HELPERS
# ================================

func _set_bus_linear_volume(bus_name: String, volume: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_error("AudioSettings: Audio bus not found: %s" % bus_name)
		return

	if volume <= MIN_AUDIBLE_LINEAR:
		AudioServer.set_bus_volume_db(bus_index, MUTE_DB)
	else:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume))
