extends Control



@onready var player = $"../../Player"
@onready var stamina_bar = $"Stamina Bar"
@onready var health_bar = $"Health Bar"

func _ready() -> void:
	player.chara.stamina_changed.connect(_on_stamina_changed)
	player.chara.health_changed.connect(_on_health_changed)

func _on_stamina_changed(new_value: float) -> void:
	stamina_bar.value = new_value
func _on_health_changed(new_value: int) ->void:
	health_bar.value = new_value
	
