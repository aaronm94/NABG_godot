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

const PlayerScene: PackedScene = preload("res://scenes/environments/entities/proto_controller/proto_controller.tscn")
const MAIN_MENU_SCENE_PATH := "res://scenes/ui/main_menu/main_menu.tscn"

func _ready() -> void:
	current_scene = get_tree().current_scene
	process_mode = Node.PROCESS_MODE_ALWAYS


# ===================================================
#                  SCENE CHANGE
# ===================================================

func goto_scene(path: String) -> void:
	# Always unpause when changing scenes
	if get_tree().paused:
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	var packed := ResourceLoader.load(path)
	if packed == null or not (packed is PackedScene):
		push_error("Not a PackedScene: %s" % path)
		return

	var next := (packed as PackedScene).instantiate()
	call_deferred("_swap_scene", next)

func _swap_scene(next: Node) -> void: # RECHECK FOR USE CASE (NEXT LEVEL or HARD RESTART)
	if is_instance_valid(current_scene):
		current_scene.queue_free()

	get_tree().root.add_child(next)
	get_tree().current_scene = next
	current_scene = next

	# When we load a gameplay scene, assume gameplay mode by default.
	# (Main menu can explicitly set mode = GameMode.MENU if needed.)
	if mode != GameMode.MENU:
		mode = GameMode.GAMEPLAY


# ===================================================
#                  PAUSE LOGIC
# ===================================================

func set_paused(p: bool) -> void:
	if get_tree().paused == p:
		return
	get_tree().paused = p
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if p else Input.MOUSE_MODE_CAPTURED)

func toggle_pause() -> void:
	# Only allowed between GAMEPLAY <-> PAUSED
	match mode:
		GameMode.GAMEPLAY:
			set_paused(true)
			_set_mode(GameMode.PAUSE)
		GameMode.PAUSE:
			set_paused(false)
			_set_mode(GameMode.GAMEPLAY)
		_:
			# Ignore pause input in DEATH or MENU
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

func get_spawn_point() -> Node3D:
	# 1) prefer explicit active spawn
	if active_spawn_point and is_instance_valid(active_spawn_point):
		return active_spawn_point

	# 2) fallback to start spawn point
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
	sp.get_parent().add_child(player)
	player.global_transform.origin = sp.global_transform.origin
	print("Player spawned at:", player.global_transform.origin)

	_set_mode(GameMode.GAMEPLAY)

const EnemyScene: PackedScene = preload("res://scenes/environments/entities/enemy/chaser.tscn")

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

func respawn_player() -> void:
	# Non-fatal reset (e.g., checkpoints) can still use this.
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


# ===================================================
#                  DEATH / LEVEL
# ===================================================

func kill_player(reason: String = "") -> void:
	# Central death entry point (called by killzones, enemies, etc.)
	if mode == GameMode.DEATH:
		return # ignore duplicate kills in the same death flow

	print("[GameState] Player died, reason:", reason)
	player_died.emit(reason)

	set_paused(true)
	_set_mode(GameMode.DEATH)

func level_complete() -> void:
	# Central entry point when the player finishes the level
	# Ignore if already in a terminal state/post-game state
	if mode == GameMode.DEATH or mode == GameMode.COMPLETE:
		return

	print("[GameState] Level completed")

	# Freeze gameplay and switch to COMPLETE CanvasLayer
	set_paused(true)
	_set_mode(GameMode.COMPLETE)


# ===================================================
#            MENU ACTIONS
# ===================================================

func restart_level() -> void:
	# Soft restart: respawn player at active spawn point
	# LOOK INTO HARD RESET FOR PROCEDURAL GENERATION
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
#                  MODE SET
# ===================================================

func _set_mode(new_mode: GameMode) -> void:
	if mode == new_mode:
		return
	mode = new_mode
	mode_changed.emit(mode)

	# Drive music here based on global mode
	match mode:
		GameMode.GAMEPLAY:
			AudioManager.play_music_by_id("level1")
		GameMode.DEATH:
			AudioManager.play_music_by_id("death")
		GameMode.MENU:
			AudioManager.play_music_by_id("menu")
		GameMode.COMPLETE:
			AudioManager.play_music_by_id("complete")
		GameMode.PAUSE:
			# Usually keep current track; no change
			pass
