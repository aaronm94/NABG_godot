@tool
extends Node3D

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	add_to_group("start_spawn_point")

	var gen := get_parent()
	if gen and gen.has_signal("done_generating"):
		gen.connect(
			"done_generating",
			Callable(GameState, "spawn_player"),
			CONNECT_ONE_SHOT
		)
		
	else:
		push_warning("Parent has no 'done_generating' signal or is missing.")
