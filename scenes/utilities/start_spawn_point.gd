# res://scenes/world/generation/player_spawn_hook.gd
## Hooks into a parent generator's `done_generating` signal and spawns the player once.

@tool
extends Node3D
class_name PlayerSpawnHook

# ================================
#           LIFECYCLE
# ================================

func _ready() -> void:
	# Don't run game logic while editing in the editor
	if Engine.is_editor_hint():
		return

	_connect_to_generator()

# ================================
#          PRIVATE HELPERS
# ================================

func _connect_to_generator() -> void:
	var generator := get_parent()
	if generator == null:
		push_warning("PlayerSpawnHook: No parent generator found.")
		return

	if not generator.has_signal("done_generating"):
		push_warning("PlayerSpawnHook: Parent has no 'done_generating' signal.")
		return

	# Avoid double-connecting if this node is re-added
	if not generator.done_generating.is_connected(_on_done_generating):
		generator.done_generating.connect(
			_on_done_generating,
			Object.CONNECT_ONE_SHOT
		)

func _on_done_generating() -> void:
	GameState.spawn_player()
