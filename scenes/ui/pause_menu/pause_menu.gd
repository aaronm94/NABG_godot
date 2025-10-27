# /ui/pause_menu/pause_menu.gd
# Adapted from https://www.youtube.com/watch?v=JEQR4ALlwVU
extends CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	hide()
	GameState.paused_changed.connect(_on_paused_changed)

func _on_paused_changed(paused: bool) -> void:
	visible = paused

func _on_resume_pressed() -> void:
	GameState.set_paused(false)

func _on_quit_pressed() -> void:
	GameState.set_paused(false)
	get_tree().quit()
