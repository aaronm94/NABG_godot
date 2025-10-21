extends CanvasLayer

#https://www.youtube.com/watch?v=JEQR4ALlwVU

@onready var main = $".."


func _ready() -> void:
	hide()
	main.paused_changed.connect(_on_paused_changed)

func _on_paused_changed(paused: bool) -> void:
	if paused:
		show()
	else:
		hide()


func _on_resume_pressed() -> void:
	var ev := InputEventAction.new()
	ev.action = "Pause"
	ev.pressed = true
	Input.parse_input_event(ev)

func _on_quit_pressed() -> void:
	get_tree().quit()
