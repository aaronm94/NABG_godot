extends Node3D

func _ready():
	# This node becomes the Exit Spawn Point for GameState
	if not is_in_group("exit_spawn_point"):
		add_to_group("exit_spawn_point")

	# Register this node as the official exit spawn point
	GameState.set_exit_spawn_point(self)
