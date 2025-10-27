extends CanvasLayer

@onready var stamina_bar: ProgressBar = $"Player Resources/Stamina Bar"
@onready var health_bar: ProgressBar = $"Player Resources/Health Bar"

func _ready() -> void:
	$"Player Resources".visible = true # ensure it draws

	var player := get_tree().get_first_node_in_group("player")
	if player:
		if player.has_signal("stamina_changed"):
			player.stamina_changed.connect(_on_stamina_changed)
		if player.has_signal("health_changed"):
			player.health_changed.connect(_on_health_changed)

		if "stamina" in player and "max_stamina" in player:
			_set_bar(stamina_bar, float(player.stamina), float(player.max_stamina))
		if "health" in player and "max_health" in player:
			_set_bar(health_bar, float(player.health), float(player.max_health))
	else:
		_set_bar(stamina_bar, 75.0, 100.0)
		_set_bar(health_bar, 100.0, 100.0)

func _on_stamina_changed(v: float) -> void:
	_set_bar(stamina_bar, v, stamina_bar.max_value)

func _on_health_changed(v: float) -> void:
	_set_bar(health_bar, v, health_bar.max_value)

func _set_bar(bar: ProgressBar, value: float, max_value: float) -> void:
	bar.min_value = 0.0
	bar.max_value = max_value
	bar.value = clamp(value, bar.min_value, bar.max_value)
