extends Node3D

var paused = false
signal paused_changed(value: bool)

func _ready() -> void:
	paused_changed.connect(_on_paused_changed)

func _on_paused_changed(paused: bool) -> void:
	if paused:
		Engine.time_scale = 0
	else:
		Engine.time_scale = 1

func _input(event):
	if event.is_action_pressed("Pause"):
		paused = !paused
		emit_signal("paused_changed", paused)
