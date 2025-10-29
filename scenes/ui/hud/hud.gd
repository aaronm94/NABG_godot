extends CanvasLayer

@onready var health_bar: ProgressBar = $"Player Resources/Health Bar"
@onready var stamina_bar: ProgressBar = $"Player Resources/Stamina Bar"

var _player: Node = null

func _ready() -> void:
	$"Player Resources".visible = true # ensure it draws

	_try_bind_player()
	# bind later too (handles spawn/respawn)
	get_tree().node_added.connect(_on_node_added)
	get_tree().node_removed.connect(_on_node_removed)

func _on_node_added(n: Node) -> void:
	if _player == null and n.is_in_group("player"):
		_bind_player(n)

func _on_node_removed(n: Node) -> void:
	if n == _player:
		_unbind_player()

func _try_bind_player() -> void:
	var p := get_tree().get_first_node_in_group("player")
	if p:
		_bind_player(p)

func _bind_player(p: Node) -> void:
	_unbind_player()
	_player = p

	# connect signals if they exist
	if p.has_signal("stamina_changed"):
		p.stamina_changed.connect(_on_stamina_changed)
	if p.has_signal("health_changed"):
		p.health_changed.connect(_on_health_changed)

	# set initial values if properties exist
	if "max_stamina" in p and "stamina" in p:
		_set_bar(stamina_bar, float(p.stamina), float(p.max_stamina))
	if "max_health" in p and "health" in p:
		_set_bar(health_bar, float(p.health), float(p.max_health))

func _unbind_player() -> void:
	if _player:
		if _player.has_signal("stamina_changed"):
			_player.stamina_changed.disconnect(_on_stamina_changed)
		if _player.has_signal("health_changed"):
			_player.health_changed.disconnect(_on_health_changed)
	_player = null

func _on_stamina_changed(v: float) -> void:
	_set_bar(stamina_bar, v, stamina_bar.max_value)

func _on_health_changed(v: float) -> void:
	_set_bar(health_bar, v, health_bar.max_value)

func _set_bar(bar: ProgressBar, value: float, max_value: float) -> void:
	bar.min_value = 0.0
	bar.max_value = max_value
	bar.value = clamp(value, bar.min_value, bar.max_value)
