@tool
extends Node3D

func _ready() -> void:
	# don’t run this in the editor scene tree (optional but safer)
	if Engine.is_editor_hint():
		return

	var gen := get_parent()
	if gen and gen.has_signal("done_generating"):
		gen.connect(
			"done_generating",
			Callable(GameState, "spawn_player"),
			CONNECT_ONE_SHOT
		)
	else:
		push_warning("Parent has no 'done_generating' signal or is missing.")
