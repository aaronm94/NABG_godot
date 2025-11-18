extends CanvasLayer
@onready var timer: Timer = $Timer
@onready var control: Control = $Control
const LEVEL_COMPLETED_DURATION = 4

func _ready() -> void:
		# Layer above HUDs and still respond when paused
	layer = 101
	#process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	timer.wait_time = LEVEL_COMPLETED_DURATION
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	GameState.level_completed.connect(_on_level_completed)
	

func _on_level_completed()->void:
	$"Control/Completed Text".modulate.a = 1
	visible = true
	
	var tween = create_tween()
	tween.tween_property($"Control/Completed Text", "modulate:a", 0, LEVEL_COMPLETED_DURATION)
	timer.start()


	





func _on_timer_timeout() -> void:
	visible = false
	GameState.call_deferred("goto_scene", "res://scenes/ui/main_menu/main_menu.tscn")
