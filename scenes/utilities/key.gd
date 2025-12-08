# key.gd
extends StaticBody3D
class_name Key

signal key_collected   # Signal for GameState to detect when the key is picked up

@export var exit_spawn_point: Node3D

@onready var mesh: MeshInstance3D = $KeyModel
@onready var hover_label: Label3D = $HoverLabel

var _base_material: StandardMaterial3D
var _highlight_material: StandardMaterial3D
var _is_highlighted: bool = false


func _ready() -> void:
	add_to_group("keys")
	hover_label.visible = false

	# --- resolve exit spawn point ---
	if exit_spawn_point == null:
		exit_spawn_point = _find_exit_spawn_point()

	# --- setup highlight materials ---
	var active_mat := mesh.get_active_material(0)

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

	# --- AUTO-CONNECT to GameState (critical for procedural levels) ---
	if GameState.has_method("on_key_collected"):
		connect("key_collected", Callable(GameState, "on_key_collected"))
		print("🔌 Key connected to GameState from inside key.gd:", self)
	else:
		print("⚠ Could not connect key to GameState — method missing?")


func set_highlighted(on: bool) -> void:
	if _is_highlighted == on:
		return

	_is_highlighted = on

	# Material highlight
	mesh.set_surface_override_material(0, _highlight_material if on else _base_material)

	# Show/hide 3D label
	if hover_label:
		hover_label.visible = on


func interact() -> void:
	# 🔥 DEBUG LOGS
	print("🔑 Key interacted with!")
	print("📢 Emitting key_collected signal now…")

	emit_signal("key_collected")
	print("✅ key_collected signal emitted successfully.")

	# Continue normal key behavior
	if exit_spawn_point == null:
		exit_spawn_point = _find_exit_spawn_point()
	if exit_spawn_point == null:
		push_warning("%s: no exit_spawn_point set or found" % get_path())
		return

	GameActions.teleport_player_to(exit_spawn_point)
	AudioManager.play_sfx("ai_spawn")
	GameState.set_active_spawn_point(exit_spawn_point)

	# Remove key after use (optional)
	# queue_free()


func _find_exit_spawn_point() -> Node3D:
	var nodes := get_tree().get_nodes_in_group("exit_spawn_point")
	if nodes.size() > 0:
		return nodes[0] as Node3D

	var found := get_tree().get_root().find_child("ExitSpawnPoint", true, false)
	return (found as Node3D) if found is Node3D else null
