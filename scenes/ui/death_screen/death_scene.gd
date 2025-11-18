extends CanvasLayer

@onready var control: Control = $Control
@onready var timer: Timer = $Timer
const  DEATH_SCREEN_DURATION = 5

func _ready() -> void:
	# Layer above HUDs and still respond when paused
	layer = 101
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	# Block gameplay clicks
	control.mouse_filter = Control.MOUSE_FILTER_STOP
	
	visible = false
	timer.wait_time = DEATH_SCREEN_DURATION
	GameState.player_died.connect(_on_death)
	
	
func _on_death(reason: String) -> void:
	GameState.set_paused(true)
	visible = true
	$"Control/Death Text".modulate.a = 0
	
	var tween = create_tween()
	tween.tween_property($"Control/Death Text", "modulate:a", 1.0, DEATH_SCREEN_DURATION*2/3)
	timer.start()
	



func _on_timer_timeout() -> void:
	visible = false
	GameState.set_paused(false) 
