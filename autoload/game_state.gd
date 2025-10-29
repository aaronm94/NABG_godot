# autoload/game_state.gd
extends Node

func _ready() -> void:
	# Using a negative index counts from the end, so this gets the last child node of `root`.
	current_scene = get_tree().current_scene
	process_mode = Node.PROCESS_MODE_ALWAYS

# ===================================================
#					SCENE CHANGE						
# ===================================================

var current_scene = null

func goto_scene(path: String) -> void:
	if get_tree().paused:
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	var packed := ResourceLoader.load(path)
	if packed == null or not (packed is PackedScene):
		push_error("Not a PackedScene: %s" % path)
		return
	
	var next := (packed as PackedScene).instantiate()
	call_deferred("_swap_scene", next)
	
func _swap_scene(next: Node) -> void:
	if is_instance_valid(current_scene):
		current_scene.queue_free()
	get_tree().root.add_child(next)
	get_tree().current_scene = next
	current_scene = next

func quit() -> void:
	get_tree().quit()

# ===================================================
#					PAUSE LOGIC							
# ===================================================

signal paused_changed(paused: bool)

func toggle_pause() -> void:
	set_paused(!get_tree().paused)

func set_paused(p: bool) -> void:
	if get_tree().paused == p:
		return
	get_tree().paused = p
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if p else Input.MOUSE_MODE_CAPTURED)
	paused_changed.emit(p)

func _unhandled_input(e):
	if e.is_action_pressed("pause"):
		toggle_pause()

# ===================================================
#					SPAWN LOGIC							
# ===================================================

const PlayerScene: PackedScene = preload("res://addons/proto_controller/proto_controller.tscn")
var player: Node3D # current player instance (set by player on _ready)

func spawn_player() -> void:
	var sp := get_spawn_point()
	if sp == null:
		push_error("No PlayerSpawnPoint found in scene.")
		return
	
	# Instantiate a new player and place them at the spawn point
	player = PlayerScene.instantiate()
	sp.get_parent().add_child(player)
	player.global_transform.origin = sp.global_transform.origin
	
	print("Player spawned at:", player.global_transform.origin)

func respawn_player() -> void:
	# If player exist and valid -> teleport
	if is_instance_valid(player):
		var sp := get_spawn_point()
		if sp == null:
			push_error("No PlayerSpawnPoint found for respawn.")
			return

		player.global_transform.origin = sp.global_transform.origin
		if "velocity" in player:
			player.velocity = Vector3.ZERO
		if "reset_on_respawn" in player:
			player.reset_on_respawn()
		print("Player respawned at:", player.global_transform.origin)
	else:
		# Player missing or freed → just spawn new
		spawn_player()

func get_spawn_point() -> Node3D:
	var points := get_tree().get_nodes_in_group("player_spawn_point")
	if points.size() > 0:
		return points[0] as Node3D
	return null

func kill_player(reason: String = "") -> void:
	print(reason)
	# Defer to avoid doing this inside physics callbacks (e.g., Area3D.body_entered)
	
	# OPTIONAL: add some fade effects or game over UI
	call_deferred("spawn_player")
