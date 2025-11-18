# autoload/game_state.gd
extends Node

var current_scene = null
var player: Node3D
var active_spawn_point: Node3D = null

const PlayerScene: PackedScene = preload("res://addons/proto_controller/proto_controller.tscn")

func _ready() -> void:
	current_scene = get_tree().current_scene
	process_mode = Node.PROCESS_MODE_ALWAYS

# ===================================================
#					SCENE CHANGE						
# ===================================================

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
func set_active_spawn_point(spawn: Node3D) -> void:
	if spawn and is_instance_valid(spawn):
		active_spawn_point = spawn

func get_spawn_point() -> Node3D:
	# 1) prefer explicit active spawn
	if active_spawn_point and is_instance_valid(active_spawn_point):
		return active_spawn_point

	# 2) fallback to start spwawn point
	var points := get_tree().get_nodes_in_group("start_spawn_point")
	if points.size() > 0:
		return points[0] as Node3D

	return null

func spawn_player() -> void:
	var sp := get_spawn_point()
	if sp == null:
		push_error("No spawn point found.")
		return
	
	# Instantiate a new player and place them at the spawn point
	player = PlayerScene.instantiate()
	sp.get_parent().add_child(player)
	player.global_transform.origin = sp.global_transform.origin
	print("Player spawned at:", player.global_transform.origin)

func respawn_player() -> void:
	var sp := get_spawn_point()
	if sp == null:
		push_error("No spawn point found for respawn.")
		return
	# If player exist and valid -> respawn
	if is_instance_valid(player):
		player.global_transform.origin = sp.global_transform.origin
		if "velocity" in player:
			player.velocity = Vector3.ZERO
		if "reset_on_respawn" in player:
			player.reset_on_respawn()
		print("Player respawned at:", player.global_transform.origin)
	else:
		# Player missing or freed → just spawn new
		spawn_player()

signal player_died(reason: String)

func kill_player(reason: String = "") -> void:
	print(reason)
	
	emit_signal("player_died", reason)
	# Defer to avoid doing this inside physics callbacks (e.g., Area3D.body_entered)
	
	# OPTIONAL: add some fade effects or game over UI
	call_deferred("spawn_player")
