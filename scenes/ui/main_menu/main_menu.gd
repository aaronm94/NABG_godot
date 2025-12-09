# res://scenes/ui/main_menu/mainmenu.gd
## Main menu controller.
## Handles: Start → Controls, Options, Quit.

extends Control
class_name MainMenu

# ================================
#             READY
# ================================

func _ready() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Menu theme music
	AudioManager.play_music_by_id("menu")

# ================================
#          BUTTON CALLBACKS
# ================================

func _on_start_button_pressed() -> void:
	GameState.goto_scene("res://scenes/ui/main_menu/controls.tscn")

func _on_options_button_pressed() -> void:
	GameState.goto_scene("res://scenes/ui/main_menu/options.tscn")

func _on_exit_button_pressed() -> void:
	GameState.quit()
