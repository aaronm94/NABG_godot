# res://autoload/game_actions.gd
## Global helper for high-level game actions such as teleporting the player.
##
## Usage:
##   GameActions.teleport_player_to(spawn_point)

extends Node

# ================================
#           CONSTANTS
# ================================

const PLAYER_GROUP: String = "player"

# ================================
#            API METHODS
# ================================

## Teleport the player to a target Node3D and reset velocity if applicable.
func teleport_player_to(target: Node3D) -> void:
	if target == null:
		push_error("GameActions: teleport_player_to() called with a null target.")
		return

	var player := _get_player()
	if player == null:
		return  # Already handled in _get_player()

	# Apply new global transform
	player.global_transform = target.global_transform

	# Reset physics velocity for CharacterBody3D players
	if player is CharacterBody3D:
		player.velocity = Vector3.ZERO

# ================================
#          PRIVATE HELPERS
# ================================

func _get_player() -> Node3D:
	var player := get_tree().get_first_node_in_group(PLAYER_GROUP)

	if player == null:
		push_warning("GameActions: No player found in group '%s'." % PLAYER_GROUP)
		return null

	if not (player is Node3D):
		push_error("GameActions: Player found in group '%s' is not a Node3D." % PLAYER_GROUP)
		return null

	return player
