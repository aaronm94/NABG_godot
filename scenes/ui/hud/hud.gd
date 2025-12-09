# res://scenes/ui/hud/hud.gd
## HUD layer that displays player health and stamina.
## Automatically binds to the first node in group "player" and tracks respawns.

extends CanvasLayer
class_name PlayerHUD

# ================================
#         ONREADY NODES
# ================================

@onready var health_bar: ProgressBar = $"Player Resources/Health Bar"
@onready var stamina_bar: ProgressBar = $"Player Resources/Stamina Bar"
@onready var resources_root: Control = $"Player Resources"

# ================================
#        MEMBER VARIABLES
# ================================

var _player: Node = null

# ================================
#         LIFECYCLE HOOKS
# ================================

func _ready() -> void:
	if resources_root:
		resources_root.visible = true

	_try_bind_player()

	# Listen for new nodes (respawns, scene changes)
	get_tree().node_added.connect(_on_node_added)
	get_tree().node_removed.connect(_on_node_removed)

# ================================
#          PLAYER BINDING
# ================================

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

	# Connect signals (if they exist)
	if p.has_signal("stamina_changed") and not p.stamina_changed.is_connected(_on_stamina_changed):
		p.stamina_changed.connect(_on_stamina_changed)

	if p.has_signal("health_changed") and not p.health_changed.is_connected(_on_health_changed):
		p.health_changed.connect(_on_health_changed)

	# Initialize bar ranges/values based on known player exports
	if stamina_bar:
		stamina_bar.min_value = 0.0
		stamina_bar.max_value = p.max_stamina if "max_stamina" in p else 100.0
		stamina_bar.value = p.stamina if "stamina" in p else stamina_bar.max_value

	if health_bar:
		health_bar.min_value = 0.0
		health_bar.max_value = p.max_health if "max_health" in p else 100.0
		health_bar.value = p.health if "health" in p else health_bar.max_value

func _unbind_player() -> void:
	if _player:
		if _player.has_signal("stamina_changed") and _player.stamina_changed.is_connected(_on_stamina_changed):
			_player.stamina_changed.disconnect(_on_stamina_changed)
		if _player.has_signal("health_changed") and _player.health_changed.is_connected(_on_health_changed):
			_player.health_changed.disconnect(_on_health_changed)

	_player = null

# ================================
#         SIGNAL HANDLERS
# ================================

func _on_stamina_changed(v: float) -> void:
	if stamina_bar:
		_set_bar(stamina_bar, v, stamina_bar.max_value)

func _on_health_changed(v: float) -> void:
	if health_bar:
		_set_bar(health_bar, v, health_bar.max_value)

# ================================
#          PRIVATE HELPERS
# ================================

func _set_bar(bar: ProgressBar, value: float, max_value: float) -> void:
	bar.min_value = 0.0
	bar.max_value = max_value
	bar.value = clamp(value, bar.min_value, bar.max_value)
