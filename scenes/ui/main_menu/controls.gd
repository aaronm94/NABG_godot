# res://scenes/ui/main_menu/main_menu.gd
## Main menu controller for starting the game.

extends Control
class_name ControlsMenu

# ================================
#       BUTTON CALLBACKS
# ================================

func _on_begin_pressed() -> void:
	GameState.goto_scene("res://scenes/world/levels/level_one.tscn")
