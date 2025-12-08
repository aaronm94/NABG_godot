extends Node3D

func _ready():
	# Make sure this node is in the exit spawn group
	if not is_in_group("exit_spawn_point"):
		add_to_group("exit_spawn_point")

	# Tell GameState this is the exit spawn point
	GameState.set_exit_spawn_point(self)
