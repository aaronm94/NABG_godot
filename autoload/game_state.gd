# autoload/game_state.gd
extends Node

# ================================
#          GAME MODE STATE
# ================================
enum GameMode { GAMEPLAY, PAUSE, DEATH, MENU, COMPLETE }

var mode: GameMode = GameMode.GAMEPLAY

signal mode_changed(new_mode: GameMode)
signal player_died(reason: String)

# ================================
#          SCENE / PLAYER
# ================================
var current_scene: Node = null
var player: Node3D
var active_spawn_point: Node3D = null
var exit_spawn_point: Node3D = null

const PlayerScene: PackedScene = preload("res://scenes/environments/entities/proto_controller/proto_controller.tscn")
const EnemyScene: PackedScene = preload("res://scenes/environments/entities/enemy/chaser.tscn")
const MAIN_MENU_SCENE_PATH := "res://scenes/ui/main_menu/main_menu.tscn"

func _ready() -> void:
	current_scene = get_tree().current_scene
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Auto-register exit spawn point if exists
	var exit_sp = current_scene.get_node_or_null("ExitSpawnPoint")
	if exit_sp:
		exit_spawn_point = exit_sp

	var keys := get_tree().get_nodes_in_group("keys")
	
	for key in keys:
		if key.has_signal("key_collected"):
			key.connect("key_collected", Callable(self, "on_key_collected"))
			print("🔌 Connected key:", key)


# ===================================================
#                  SCENE CHANGE
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

	if mode != GameMode.MENU:
		mode = GameMode.GAMEPLAY


# ===================================================
#               PAUSE SYSTEM
# ===================================================

func set_paused(p: bool) -> void:
	if get_tree().paused == p:
		return
	get_tree().paused = p
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if p else Input.MOUSE_MODE_CAPTURED)

func toggle_pause() -> void:
	match mode:
		GameMode.GAMEPLAY:
			set_paused(true)
			_set_mode(GameMode.PAUSE)
		GameMode.PAUSE:
			set_paused(false)
			_set_mode(GameMode.GAMEPLAY)
		_:
			pass

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("pause"):
		toggle_pause()


# ===================================================
#                  SPAWN LOGIC
# ===================================================

func set_active_spawn_point(spawn: Node3D) -> void:
	if spawn and is_instance_valid(spawn):
		active_spawn_point = spawn

func set_exit_spawn_point(spawn: Node3D) -> void:
	if spawn and is_instance_valid(spawn):
		exit_spawn_point = spawn


func get_spawn_point() -> Node3D:
	if active_spawn_point and is_instance_valid(active_spawn_point):
		return active_spawn_point

	var points := get_tree().get_nodes_in_group("start_spawn_point")
	if points.size() > 0:
		return points[0] as Node3D

	return null


func spawn_player() -> void:
	var sp := get_spawn_point()
	if sp == null:
		push_error("No spawn point found.")
		return

	player = PlayerScene.instantiate()
	player.add_to_group("player")
	
	print(">>> PLAYER GROUPS:", player.get_groups())

	sp.get_parent().add_child(player)
	player.global_transform.origin = sp.global_transform.origin
	print("Player spawned at:", player.global_transform.origin)

	_set_mode(GameMode.GAMEPLAY)



func respawn_player() -> void:
	var sp := get_spawn_point()
	if sp == null:
		push_error("No spawn point found for respawn.")
		return

	if is_instance_valid(player):
		player.global_transform.origin = sp.global_transform.origin
		if "velocity" in player:
			player.velocity = Vector3.ZERO
		if "reset_on_respawn" in player:
			player.reset_on_respawn()
		print("Player respawned at:", player.global_transform.origin)
	else:
		spawn_player()


func spawn_enemy() -> void:
	print("GameState: spawn_enemy CALLED")

	var level := get_tree().current_scene
	if level == null:
		push_error("No current scene to spawn enemy into.")
		return

	var sp := get_spawn_point()
	if sp == null:
		push_error("No start spawn point found for enemy.")
		return

	var enemy := EnemyScene.instantiate()
	level.add_child(enemy)
	enemy.global_transform.origin = sp.global_transform.origin

	print("Enemy spawned at:", enemy.global_transform.origin)

	if enemy.has_method("set_target") and player:
		enemy.set_target(player)


# ======================================
#       ENEMY SPAWN AT EXIT (NEW)
# ======================================

func spawn_enemy_at_exit() -> void:
	print("\n--- spawn_enemy_at_exit CALLED ---")

	if exit_spawn_point == null:
		print("❌ exit_spawn_point IS NULL — searching in scene...")
		exit_spawn_point = current_scene.get_node_or_null("ExitSpawnPoint")

		if exit_spawn_point == null:
			print("🚨 FATAL ERROR: EXIT SPAWN POINT NOT FOUND IN SCENE!")
			print("Make sure the ExitSpawnPoint node exists and is in the group 'exit_spawn_point'.")
			return
		else:
			print("✅ Found ExitSpawnPoint node AFTER searching:", exit_spawn_point)

	print("⬆ EXIT SPAWN LOCATION:", exit_spawn_point.global_transform.origin)

	var enemy := EnemyScene.instantiate()
	current_scene.add_child(enemy)

	print("🧟 ENEMY INSTANCE CREATED:", enemy)

	enemy.global_transform.origin = exit_spawn_point.global_transform.origin
	print("📍 ENEMY POSITION SET TO EXIT SPAWN POINT")

	if enemy.has_method("set_target") and player:
		print("🎯 Setting enemy target to player")
		enemy.set_target(player)
	else:
		print("⚠ Enemy missing set_target() OR player is null")

	print("🎉 ENEMY SPAWN COMPLETE\n")



# ======================================
#          KEY PICKUP CALLBACK
# ======================================

func ensure_player_exists():
	while player == null:
		await get_tree().process_frame

func on_key_collected() -> void:
	print("GameState: Key collected → waiting 3 seconds before spawning enemy...")

	await get_tree().create_timer(3.0).timeout

	spawn_enemy_at_exit()

# ===================================================
#               PLAYER DEATH SYSTEM
# ===================================================

func kill_player(reason: String = "") -> void:
	if mode == GameMode.DEATH:
		return

	print("[GameState] Player died, reason:", reason)
	player_died.emit(reason)

	set_paused(true)
	_set_mode(GameMode.DEATH)


# ===================================================
#               LEVEL COMPLETE
# ===================================================

func level_complete() -> void:
	if mode == GameMode.DEATH or mode == GameMode.COMPLETE:
		return

	print("[GameState] Level completed")

	set_paused(true)
	_set_mode(GameMode.COMPLETE)


# ===================================================
#               MENU ACTIONS
# ===================================================

func restart_level() -> void:
	set_paused(false)
	_set_mode(GameMode.GAMEPLAY)
	respawn_player()

func go_to_main_menu() -> void:
	if MAIN_MENU_SCENE_PATH == "":
		push_error("MAIN_MENU_SCENE_PATH is not set.")
		return

	set_paused(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_set_mode(GameMode.MENU)
	goto_scene(MAIN_MENU_SCENE_PATH)

func quit() -> void:
	get_tree().quit()


# ===================================================
#               MODE SYSTEM
# ===================================================

func _set_mode(new_mode: GameMode) -> void:
	if mode == new_mode:
		return

	mode = new_mode
	mode_changed.emit(mode)

	match mode:
		GameMode.GAMEPLAY:
			AudioManager.play_music_by_id("level1")
		GameMode.DEATH:
			AudioManager.play_music_by_id("death")
		GameMode.MENU:
			AudioManager.play_music_by_id("menu")
		GameMode.COMPLETE:
			AudioManager.play_music_by_id("complete")
		_:
			pass
