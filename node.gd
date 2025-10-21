extends Node


@onready var player = $"../Player"

func _ready() -> void:
	timeout.connect(_on_timeout)

func _on_timeout() -> void:
	if player.stats.is_running():
		player.stats.increment_stamina(-30)
	else:
		player.stats.increment_stamina(1)
