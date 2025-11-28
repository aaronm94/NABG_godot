# res://autoload/audio_manager.gd
extends Node

# ================================
#           MUSIC TRACKS
# ================================
const MENU_TRACK: String  = "res://scenes/sounds/music/Soularflair - Soundscape 30 (dark, spooky, emotive).ogg"
const DEATH_TRACK: String = "res://scenes/sounds/music/human gazpacho - 03 action for action's sake.ogg"
const LEVEL1_TRACK: String = "res://scenes/sounds/music/horrorambiance3.ogg"
const COMPLETE_TRACK: String = "res://scenes/sounds/music/fx-gentle-glass-bells-ringtone-320337.ogg"

var music_tracks: Dictionary[String, String] = {
	"menu": MENU_TRACK,
	"death": DEATH_TRACK,
	"level1": LEVEL1_TRACK,
	"complete": COMPLETE_TRACK,
}

var _current_music_path: String = ""

@onready var music_player: AudioStreamPlayer = AudioStreamPlayer.new()


func _ready() -> void:
	# Persistent music player on the Music bus
	add_child(music_player)
	music_player.bus = "Music"
	music_player.autoplay = false
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS


# ---------------- MUSIC API ----------------

func _play_music(path: String) -> void:
	if _current_music_path == path and music_player.playing:
		return # already playing this track

	_current_music_path = path
	music_player.stream = load(path)
	if music_player.stream == null:
		push_error("Failed to load music stream at path: %s" % path)
		return

	music_player.play()

func play_music_by_id(id: String) -> void:
	if not music_tracks.has(id):
		push_warning("Unknown music id: %s" % id)
		return
	_play_music(music_tracks[id])

func stop_music() -> void:
	music_player.stop()


# ================================
#              SFX
# ================================

var sfx_tracks: Dictionary[String, AudioStream] = {
	"step1": preload("res://scenes/sounds/sfx/loud-walking-on-carpet-99860/step1.ogg"),
	"step2": preload("res://scenes/sounds/sfx/loud-walking-on-carpet-99860/step2.ogg"),
	"step3": preload("res://scenes/sounds/sfx/loud-walking-on-carpet-99860/step3.ogg"),
	"step4": preload("res://scenes/sounds/sfx/loud-walking-on-carpet-99860/step4.ogg"),
	"step5": preload("res://scenes/sounds/sfx/loud-walking-on-carpet-99860/step5.ogg"),
	"step6": preload("res://scenes/sounds/sfx/loud-walking-on-carpet-99860/step6.ogg"),
	"death_fall": preload("res://scenes/sounds/sfx/fatal-body-fall-thud-352716.ogg"),
	"ai_spawn": preload("res://scenes/sounds/sfx/dungeon-wall-slowly-closi-2b7ngizl.ogg"),
	# "death_enemy": preload("res://path/to/enemy_death.ogg"),  #TBD
	# "ui_click": preload("res://path/to/ui_click.ogg"),
}

const SFX_BUS_NAME: String = "SFX"  # make sure this bus exists under Master

func play_random_footstep(pitch: float = 1.0) -> void:
	var keys : Array[String] = ["step1", "step2", "step3", "step4", "step5", "step6"]
	var id : String = keys[randi() % keys.size()]
	
	var p := AudioStreamPlayer.new()
	p.bus = SFX_BUS_NAME
	p.stream = sfx_tracks[id]
	p.pitch_scale = pitch
	p.volume_db = 6.0
	p.process_mode = Node.PROCESS_MODE_ALWAYS

	add_child(p)
	p.play()
	p.finished.connect(func(): p.queue_free())


func play_sfx(id: String) -> void:
	if not sfx_tracks.has(id):
		push_warning("Unknown SFX id: %s" % id)
		return

	var p := AudioStreamPlayer.new()
	p.bus = SFX_BUS_NAME
	p.stream = sfx_tracks[id]
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(p)
	p.play()
	p.finished.connect(func() -> void:
		p.queue_free()
	)
