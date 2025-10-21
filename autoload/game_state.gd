# autoload/game_state.gd
extends Node

# Stores a tranform you can respawn from (set by checkpoints OR start point)
var respawn_transform: Transform3D
var last_death_reason: String = ""

# Group name for player scene
const PLAYER_GROUP: String = "player"

func kill_player(reason: String) -> void:
    last_death_reason = reason
    # Prefer respawn if we have a valid respawn point, otherwise reload level
    if respawn_transform:
        _respawn_player()
    else:
        _reload_level()

func _respawn_player() -> void:
    var player := _get_player()
    if not player:
        _reload_level()
        return
    # Reset transform & velocity safely
    player.global_transform = respawn_transform
    if "velocity" in player:
        player.velocity = Vector3.ZERO
    if "_vel" in player:
        # If using a custom velocity variable
        player._vel = Vector3.ZERO
    # OPTIONAL: Camera shake or fade effect can be added here
    # OPTIONAL: Emit a signal for UI updates or sound effects
    print("Respawn after: ", last_death_reason)

func _reload_level() -> void:
    var tree := get_tree()
    if tree:
        tree.reload_current_scene()

func _get_player() -> Node3D:
    var list := get_tree().get_nodes_in_group(PLAYER_GROUP)
    return list[0] if list.size() > 0 else null