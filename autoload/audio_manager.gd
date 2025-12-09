# res://autoload/audio_manager.gd
## Global audio manager responsible for playing music and SFX.
## Usage:
##   AudioManager.play_music_by_id(AudioManager.MUSIC_MENU)
##   AudioManager.play_sfx(AudioManager.SFX_DEATH_ENEMY)
##   AudioManager.play_random_footstep()

extends Node

# ================================
#           CONSTANTS
# ================================

# --- Audio buses ---
const BUS_MUSIC: String = "Music"
const BUS_SFX: String = "SFX"  # Ensure this bus exists under Master

# --- Music IDs ---
const MUSIC_MENU: String    = "menu"
const MUSIC_DEATH: String   = "death"
const MUSIC_LEVEL1: String  = "level1"
const MUSIC_COMPLETE: String = "complete"

# --- Music streams (preloaded for performance) ---
const MENU_TRACK: AudioStream = preload("res://assets/audio/music/Soularflair - Soundscape 30 (dark, spooky, emotive).ogg")
const DEATH_TRACK: AudioStream = preload("res://assets/audio/music/human gazpacho - 03 action for action's sake.ogg")
const LEVEL1_TRACK: AudioStream = preload("res://assets/audio/music/horrorambiance3.ogg")
const COMPLETE_TRACK: AudioStream = preload("res://assets/audio/music/fx-gentle-glass-bells-ringtone-320337.ogg")

# --- SFX IDs ---
const SFX_STEP_1: String      = "step1"
const SFX_STEP_2: String      = "step2"
const SFX_STEP_3: String      = "step3"
const SFX_STEP_4: String      = "step4"
const SFX_STEP_5: String      = "step5"
const SFX_STEP_6: String      = "step6"
const SFX_DEATH_FALL: String  = "death_fall"
const SFX_AI_SPAWN: String    = "ai_spawn"
const SFX_DEATH_ENEMY: String = "death_enemy"
# const SFX_UI_CLICK: String = "ui_click"  # Sample for future use

# --- Footstep config ---
const FOOTSTEP_IDS: Array[String] = [
	SFX_STEP_1, SFX_STEP_2, SFX_STEP_3,
	SFX_STEP_4, SFX_STEP_5, SFX_STEP_6,
]
const DEFAULT_FOOTSTEP_VOLUME_DB: float = 6.0

# ================================
#        MEMBER VARIABLES
# ================================

var _music_tracks: Dictionary[String, AudioStream] = {
	MUSIC_MENU: MENU_TRACK,
	MUSIC_DEATH: DEATH_TRACK,
	MUSIC_LEVEL1: LEVEL1_TRACK,
	MUSIC_COMPLETE: COMPLETE_TRACK,
}

var _sfx_tracks: Dictionary[String, AudioStream] = {
	SFX_STEP_1: preload("res://assets/audio/sfx/loud-walking-on-carpet-99860/step1.ogg"),
	SFX_STEP_2: preload("res://assets/audio/sfx/loud-walking-on-carpet-99860/step2.ogg"),
	SFX_STEP_3: preload("res://assets/audio/sfx/loud-walking-on-carpet-99860/step3.ogg"),
	SFX_STEP_4: preload("res://assets/audio/sfx/loud-walking-on-carpet-99860/step4.ogg"),
	SFX_STEP_5: preload("res://assets/audio/sfx/loud-walking-on-carpet-99860/step5.ogg"),
	SFX_STEP_6: preload("res://assets/audio/sfx/loud-walking-on-carpet-99860/step6.ogg"),
	SFX_DEATH_FALL: preload("res://assets/audio/sfx/fatal-body-fall-thud-352716.ogg"),
	SFX_AI_SPAWN: preload("res://assets/audio/sfx/dungeon-wall-slowly-closi-2b7ngizl.ogg"),
	SFX_DEATH_ENEMY: preload("res://assets/audio/sfx/terrifying-scream-353210.ogg"),
	# SFX_UI_CLICK: preload("res://assets/audio/sfx/ui_click.ogg"),
}

var _current_music_id: String = ""
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var _music_player: AudioStreamPlayer = AudioStreamPlayer.new()

# ================================
#         LIFECYCLE HOOKS
# ================================

func _ready() -> void:
	# Persistent music player on the Music bus
	add_child(_music_player)
	_music_player.bus = BUS_MUSIC
	_music_player.autoplay = false
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS

	_rng.randomize()

# ================================
#            MUSIC API
# ================================

## Play a music track by internal ID (see MUSIC_* constants).
func play_music_by_id(id: String) -> void:
	if not _music_tracks.has(id):
		push_warning("AudioManager: Unknown music id: %s" % id)
		return

	if _current_music_id == id and _music_player.playing:
		return  # Already playing this track

	_current_music_id = id
	_music_player.stream = _music_tracks[id]

	if _music_player.stream == null:
		push_error("AudioManager: Music stream for id '%s' is null." % id)
		return

	_music_player.play()

## Stop the currently playing music track.
func stop_music() -> void:
	_music_player.stop()
	_current_music_id = ""

# ================================
#              SFX API
# ================================

## Play a random footstep SFX. Optionally adjust pitch for variation.
func play_random_footstep(pitch: float = 1.0) -> void:
	if FOOTSTEP_IDS.is_empty():
		push_warning("AudioManager: No footstep SFX configured.")
		return

	var index := _rng.randi() % FOOTSTEP_IDS.size()
	var id := FOOTSTEP_IDS[index]
	_play_sfx_internal(id, pitch, DEFAULT_FOOTSTEP_VOLUME_DB)

## Play a specific SFX by ID (see SFX_* constants).
func play_sfx(id: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	_play_sfx_internal(id, pitch, volume_db)

# ================================
#          PRIVATE HELPERS
# ================================

func _play_sfx_internal(id: String, pitch: float, volume_db: float) -> void:
	if not _sfx_tracks.has(id):
		push_warning("AudioManager: Unknown SFX id: %s" % id)
		return

	var stream: AudioStream = _sfx_tracks[id]
	if stream == null:
		push_error("AudioManager: SFX stream for id '%s' is null." % id)
		return

	var player := AudioStreamPlayer.new()
	player.bus = BUS_SFX
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.process_mode = Node.PROCESS_MODE_ALWAYS

	add_child(player)
	player.play()

	player.finished.connect(func() -> void:
		player.queue_free()
	)
