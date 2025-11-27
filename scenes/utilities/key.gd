# key.gd
extends Node3D
class_name Key

@export var exit_spawn_point: Node3D
@onready var mesh: MeshInstance3D = $StaticBody3D/Key

var _base_material: StandardMaterial3D
var _highlight_material: StandardMaterial3D
var _is_highlighted: bool = false


func _ready() -> void:
	# --- exit spawn resolution (same as old TeleportButton) ---
	if exit_spawn_point == null:
		exit_spawn_point = _find_exit_spawn_point()

	# --- setup highlight materials ---
	var active_mat := mesh.get_active_material(0)

	if active_mat == null:
		# No material? create one so we can override it
		_base_material = StandardMaterial3D.new()
		mesh.set_surface_override_material(0, _base_material)
	elif active_mat is StandardMaterial3D:
		_base_material = active_mat
	else:
		# Non-standard material, duplicate as StandardMaterial3D so we can tweak emission
		_base_material = active_mat.duplicate() as StandardMaterial3D
		mesh.set_surface_override_material(0, _base_material)

	_highlight_material = _base_material.duplicate() as StandardMaterial3D
	_highlight_material.emission_enabled = true
	_highlight_material.emission = Color(1.0, 1.0, 0.3)  # pale yellow
	_highlight_material.emission_energy_multiplier = 1.5

	# Ensure we start un-highlighted
	mesh.set_surface_override_material(0, _base_material)

func set_highlighted(on: bool) -> void:
	if _is_highlighted == on:
		return
	_is_highlighted = on

	mesh.set_surface_override_material(0, _highlight_material if on else _base_material)

func interact() -> void:
	# Same behavior as your old TeleportButton, but key stays visible
	if exit_spawn_point == null:
		exit_spawn_point = _find_exit_spawn_point()
	if exit_spawn_point == null:
		push_warning("%s: no exit_spawn_point set or found" % get_path())
		return

	# 1) teleport now
	GameActions.teleport_player_to(exit_spawn_point)
	AudioManager.play_sfx("ai_spawn")

	# 2) tell game_state to use exit spawn point
	GameState.set_active_spawn_point(exit_spawn_point)

	# NOTE: we intentionally do NOT queue_free() here, so the key/box does not disappear.
	# OPTIONAL: if you want it to vanish after pickup, you can add: queue_free()

func _find_exit_spawn_point() -> Node3D:
	var nodes := get_tree().get_nodes_in_group("exit_spawn_point")
	if nodes.size() > 0:
		return nodes[0] as Node3D

	var found := get_tree().get_root().find_child("ExitSpawnPoint", true, false)
	return (found as Node3D) if found is Node3D else null
