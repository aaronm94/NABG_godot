# teleport_button.gd
extends MeshInstance3D
class_name TeleportButton

@export var exit_spawn_point: Node3D
# Play confetti when the user presses the button
@onready var confetti_player: AudioStreamPlayer3D = $ConfettiPlayer

func _ready() -> void:
	if exit_spawn_point == null:
		exit_spawn_point = _find_exit_spawn_point()

func interact() -> void:
	if exit_spawn_point == null:
		exit_spawn_point = _find_exit_spawn_point()
	if exit_spawn_point == null:
		push_warning("%s: no exit_spawn_point set or found" % get_path())
		return

#	Commented out for now because we dont have multiple maps
	## 1) teleport now
	#GameActions.teleport_player_to(exit_spawn_point)
#
	## 2) tell game_state to use exit spawn point
	#GameState.set_active_spawn_point(exit_spawn_point)
	
	# --- Play the confetti sound ---
	if confetti_player and confetti_player.stream:
		confetti_player.play()
		# Wait for the sound to finish playing before continuing
		await confetti_player.finished

func _find_exit_spawn_point() -> Node3D:
	var nodes := get_tree().get_nodes_in_group("exit_spawn_point")
	if nodes.size() > 0:
		return nodes[0] as Node3D
	var found := get_tree().get_root().find_child("ExitSpawnPoint", true, false)
	return (found as Node3D) if found is Node3D else null
