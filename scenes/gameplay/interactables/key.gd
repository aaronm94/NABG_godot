# res://scenes/gameplay/interactables/key.gd
## Key interactable:
##  - Highlights when targeted
##  - Teleports the player to the exit spawn point
##  - Sets the new active spawn point for respawns
##  - Spawns a chaser enemy once
##  - Plays an AI spawn SFX after activation

extends Interactable
class_name Key

# ================================
#             EXPORTS
# ================================

## Explicit exit spawn point. If null, will be resolved via group/name.
@export var exit_spawn_point: Node3D

## Chaser enemy scene to spawn after teleport.
@export var chaser_scene: PackedScene

# ================================
#         ONREADY NODES
# ================================

@onready var mesh: MeshInstance3D = $KeyModel
@onready var hover_label: Label3D = $HoverLabel

# ================================
#        MEMBER VARIABLES
# ================================

var enemy_spawn_point: Node3D = null
var enemy_spawned: bool = false

var _base_material: StandardMaterial3D
var _highlight_material: StandardMaterial3D
var _is_highlighted: bool = false

# ================================
#         LIFECYCLE HOOKS
# ================================

func _ready() -> void:
	if hover_label:
		hover_label.visible = false

	# --- resolve spawn point ---
	if exit_spawn_point == null:
		exit_spawn_point = _find_exit_spawn_point()

	# --- setup highlight materials ---
	_setup_highlight_materials()

# ================================
#          HIGHLIGHT LOGIC
# ================================

## Override from Interactable: handle visual highlight + label.
func set_highlighted(on: bool) -> void:
	if _is_highlighted == on:
		return

	_is_highlighted = on

	if mesh:
		mesh.set_surface_override_material(0, _highlight_material if on else _base_material)

	if hover_label:
		hover_label.visible = on

# ================================
#           INTERACTION
# ================================

## Override from Interactable: behaviour when the player interacts with this key.
func interact() -> void:
	# 1) Resolve exit spawn
	if exit_spawn_point == null:
		exit_spawn_point = _find_exit_spawn_point()
	if exit_spawn_point == null:
		push_warning("%s: No exit_spawn_point set or found." % get_path())
		return

	# 2) Resolve enemy spawn
	if enemy_spawn_point == null:
		enemy_spawn_point = _find_enemy_spawn_point()
	if enemy_spawn_point == null:
		push_warning("%s: No enemy_spawn_point found, chaser will not spawn." % get_path())
	else:
		print("Key: enemy_spawn_point is", enemy_spawn_point.name)

	# 3) Teleport player to exit
	print("Key: Teleporting player to exit_spawn_point at", exit_spawn_point.global_transform.origin)
	GameActions.teleport_player_to(exit_spawn_point)

	# 4) Set new active spawn for respawns
	print("Key: Setting active spawn to exit_spawn_point")
	GameState.set_active_spawn_point(exit_spawn_point)

	# 5) Spawn the enemy once
	if not enemy_spawned and enemy_spawn_point and chaser_scene:
		_spawn_chaser(enemy_spawn_point)
		enemy_spawned = true
	elif not chaser_scene:
		push_warning("%s: chaser_scene is NOT assigned in inspector." % get_path())
	else:
		print("Key: enemy already spawned or no spawn_point/chaser_scene")

	# 6) Play AI spawn SFX (after teleport + enemy spawn)
	AudioManager.play_sfx(AudioManager.SFX_AI_SPAWN)

# ================================
#          PRIVATE HELPERS
# ================================

func _setup_highlight_materials() -> void:
	if mesh == null:
		push_warning("%s: MeshInstance3D not found; highlight will be disabled." % get_path())
		return

	var active_mat: Material = mesh.get_active_material(0)

	if active_mat == null:
		_base_material = StandardMaterial3D.new()
		mesh.set_surface_override_material(0, _base_material)
	elif active_mat is StandardMaterial3D:
		_base_material = active_mat
	else:
		_base_material = active_mat.duplicate() as StandardMaterial3D
		mesh.set_surface_override_material(0, _base_material)

	_highlight_material = _base_material.duplicate() as StandardMaterial3D
	_highlight_material.emission_enabled = true
	_highlight_material.emission = Color(1.0, 1.0, 0.3)
	_highlight_material.emission_energy_multiplier = 1.5

	mesh.set_surface_override_material(0, _base_material)

func _find_exit_spawn_point() -> Node3D:
	var nodes: Array = get_tree().get_nodes_in_group("exit_spawn_point")
	if nodes.size() > 0:
		return nodes[0] as Node3D

	var found: Node = get_tree().root.find_child("ExitSpawnPoint", true, false)
	return (found as Node3D) if found is Node3D else null

func _find_enemy_spawn_point() -> Node3D:
	# Prefer group-based lookup
	var nodes: Array = get_tree().get_nodes_in_group("enemy_spawn_point")
	if nodes.size() > 0:
		return nodes[0] as Node3D

	# Fallback by name anywhere in tree
	var found: Node = get_tree().root.find_child("EnemySpawnPoint", true, false)
	return (found as Node3D) if found is Node3D else null

func _spawn_chaser(spawn: Node3D) -> void:
	if chaser_scene == null:
		push_warning("%s: chaser_scene is not assigned." % get_path())
		return

	var enemy := chaser_scene.instantiate()

	# Add to same parent as spawn point
	spawn.get_parent().add_child(enemy)
	enemy.global_transform.origin = spawn.global_transform.origin

	# Tell the enemy to chase the current player immediately
	if GameState.player and enemy.has_method("set_target"):
		enemy.set_target(GameState.player)
