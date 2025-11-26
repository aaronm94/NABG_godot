# res://autoload/music_player.gd
extends AudioStreamPlayer

const MENU_TRACK  := "res://addons/human gazpacho - 03 action for action's sake.mp3"
const LEVEL1_TRACK := "res://addons/Soularflair - Soundscape 30 (dark, spooky, emotive).mp3"

var _current_path: String = ""

func _ready() -> void:
	bus = "Music"
	autoplay = false

func _play(path: String) -> void:
	if _current_path == path and playing:
		return # already playing this track, don't restart

	_current_path = path
	stream = load(path)
	play()

func play_menu() -> void:
	_play(MENU_TRACK)

func play_level1() -> void:
	_play(LEVEL1_TRACK)
