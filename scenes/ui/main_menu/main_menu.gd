# mainmenu.gd
extends Control

func _ready() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func startbutton_pressed():
	GameState.goto_scene("res://scenes/environments/levels/level_one.tscn")

func options_pressed():
	GameState.goto_scene("res://scenes/ui/main_menu/options.tscn")

func exitbutton_pressed():
	GameState.quit()
