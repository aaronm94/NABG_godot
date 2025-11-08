# autoload/game_actions.gd
extends Node

func teleport_player_to(target: Node3D) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("GameActions: no player found in group 'player'")
		return

	player.global_transform = target.global_transform

	if player is CharacterBody3D:
		player.velocity = Vector3.ZERO
