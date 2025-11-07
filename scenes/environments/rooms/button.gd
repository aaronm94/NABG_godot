# teleport_button.gd
extends MeshInstance3D
class_name TeleportButton

@export var exit_spawn_point: Node3D
@export var exit_spawn_group: String = "exit_spawn_point"  # makes it configurable

func _ready() -> void:
	if exit_spawn_point == null:
		exit_spawn_point = _find_exit_spawn_point()

func interact() -> void:
	if exit_spawn_point == null:
		exit_spawn_point = _find_exit_spawn_point()
	if exit_spawn_point == null:
		push_warning("%s: no exit_spawn_point set or found" % get_path())
		return

	GameActions.teleport_player_to(exit_spawn_point)

func _find_exit_spawn_point() -> Node3D:
	# 1) group-based
	if exit_spawn_group != "":
		var nodes := get_tree().get_nodes_in_group(exit_spawn_group)
		if nodes.size() > 0:
			return nodes[0] as Node3D

	# 2) name fallback
	var root := get_tree().get_root()
	var found := root.find_child("ExitSpawnPoint", true, false)
	if found and found is Node3D:
		return found

	return null
