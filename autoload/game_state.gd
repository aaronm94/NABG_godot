# res://autoload/game_state.gd
## Global game state singleton.
## Owns:
##  - GameMode and pause state
##  - Scene transitions
##  - Player spawn / respawn logic
##  - Central death / level-complete flows
##  - High-level menu actions (restart, main menu, quit)

extends Node

# ================================
#            ENUMS
# ================================

enum GameMode { GAMEPLAY, PAUSE, DEATH, MENU, COMPLETE }

# ================================
#           CONSTANTS
# ================================

const PLAYER_SCENE: PackedScene = preload("res://scenes/gameplay/player/proto_controller.tscn")
const MAIN_MENU_SCENE_PATH: String = "res://scenes/ui/main_menu/main_menu.tscn"

const GROUP_START_SPAWN: String = "start_spawn_point"

# ================================
#            SIGNALS
# ================================

signal mode_changed(new_mode: GameMode)
signal player_died(reason: String)

# ================================
#        MEMBER VARIABLES
# ================================

var mode: GameMode = GameMode.GAMEPLAY

var current_scene: Node = null
var player: CharacterBody3D = null
var active_spawn_point: Node3D = null

# ================================
#         LIFECYCLE HOOKS
# ================================

func _ready() -> void:
	current_scene = get_tree().current_scene
	process_mode = Node.PROCESS_MODE_ALWAYS

# Handle global pause input
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()

# ================================
#          SCENE MANAGEMENT
# ================================

## Change the current scene to the given path.
## Always unpauses and recaptures the mouse.
func goto_scene(path: String) -> void:
	# Always unpause when changing scenes
	if get_tree().paused:
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	var resource: Resource = ResourceLoader.load(path)
	if resource == null or not (resource is PackedScene):
		push_error("GameState: Not a PackedScene: %s" % path)
		return

	var next_scene: Node = (resource as PackedScene).instantiate()
	call_deferred("_swap_scene", next_scene)

## Internal helper to replace the current scene with `next_scene`.
func _swap_scene(next_scene: Node) -> void:
	if is_instance_valid(current_scene):
		current_scene.queue_free()

	get_tree().root.add_child(next_scene)
	get_tree().current_scene = next_scene
	current_scene = next_scene

	# When we load a gameplay scene, assume gameplay mode by default.
	# (Main menu can explicitly set mode = GameMode.MENU if needed.)
	if mode != GameMode.MENU:
		_set_mode(GameMode.GAMEPLAY)

# ================================
#             PAUSE LOGIC
# ================================

## Set paused/unpaused state and handle mouse mode.
func set_paused(is_paused: bool) -> void:
	if get_tree().paused == is_paused:
		return

	get_tree().paused = is_paused
	Input.set_mouse_mode(
		Input.MOUSE_MODE_VISIBLE if is_paused else Input.MOUSE_MODE_CAPTURED
	)

## Toggle pause between GAMEPLAY <-> PAUSE.
func toggle_pause() -> void:
	match mode:
		GameMode.GAMEPLAY:
			set_paused(true)
			_set_mode(GameMode.PAUSE)
		GameMode.PAUSE:
			set_paused(false)
			_set_mode(GameMode.GAMEPLAY)
		_:
			# Ignore pause input in DEATH, MENU, COMPLETE
			pass

# ================================
#             SPAWN LOGIC
# ================================

## Set the active spawn point used for respawns.
func set_active_spawn_point(spawn: Node3D) -> void:
	if spawn and is_instance_valid(spawn):
		active_spawn_point = spawn

## Get the current spawn point:
##  1) explicit active spawn, else
##  2) first node in group GROUP_START_SPAWN, else null.
func get_spawn_point() -> Node3D:
	# 1) prefer explicit active spawn
	if active_spawn_point and is_instance_valid(active_spawn_point):
		return active_spawn_point

	# 2) fallback to start spawn point
	var points: Array = get_tree().get_nodes_in_group(GROUP_START_SPAWN)
	if points.size() > 0:
		return points[0] as Node3D

	return null

## Spawn the player from the player scene at the chosen spawn point.
func spawn_player() -> void:
	var spawn_point := get_spawn_point()
	if spawn_point == null:
		push_error("GameState: No spawn point found for initial spawn.")
		return

	player = PLAYER_SCENE.instantiate() as CharacterBody3D
	if player == null:
		push_error("GameState: PLAYER_SCENE did not instantiate a CharacterBody3D.")
		return

	spawn_point.get_parent().add_child(player)
	player.global_transform.origin = spawn_point.global_transform.origin
	print("GameState: Player spawned at:", player.global_transform.origin)

	_set_mode(GameMode.GAMEPLAY)

## Respawn the player at the current spawn point.
## If the player no longer exists, a new player is spawned.
func respawn_player() -> void:
	var spawn_point := get_spawn_point()
	if spawn_point == null:
		push_error("GameState: No spawn point found for respawn.")
		return

	if is_instance_valid(player):
		player.global_transform.origin = spawn_point.global_transform.origin

		if "velocity" in player:
			player.velocity = Vector3.ZERO

		if "reset_on_respawn" in player:
			player.reset_on_respawn()

		print("GameState: Player respawned at:", player.global_transform.origin)
	else:
		spawn_player()

# ================================
#         DEATH / LEVEL FLOW
# ================================

## Central death entry point (called by kill volumes, enemies, etc.).
func kill_player(reason: String = "") -> void:
	if mode == GameMode.DEATH:
		# Ignore duplicate kills in the same death flow
		return

	print("GameState: Player died, reason:", reason)
	player_died.emit(reason)

	set_paused(true)
	_set_mode(GameMode.DEATH)

## Central entry point when the player finishes the level.
func level_complete() -> void:
	# Ignore if already in a terminal/post-game state
	if mode == GameMode.DEATH or mode == GameMode.COMPLETE:
		return

	print("GameState: Level completed.")
	set_paused(true)
	_set_mode(GameMode.COMPLETE)

# ================================
#            MENU ACTIONS
# ================================

## Soft restart: respawn player at active / default spawn point.
## (Note: for a full procedural reset, use a hard scene reload instead.)
func restart_level() -> void:
	set_paused(false)
	_set_mode(GameMode.GAMEPLAY)
	respawn_player()

## Return to the main menu scene.
func go_to_main_menu() -> void:
	if MAIN_MENU_SCENE_PATH.is_empty():
		push_error("GameState: MAIN_MENU_SCENE_PATH is not set.")
		return

	set_paused(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_set_mode(GameMode.MENU)
	goto_scene(MAIN_MENU_SCENE_PATH)

## Quit the game.
func quit() -> void:
	get_tree().quit()

# ================================
#            MODE SETTER
# ================================

## Internal helper to update mode and emit mode_changed.
## Also drives audio based on mode via AudioManager.
func _set_mode(new_mode: GameMode) -> void:
	if mode == new_mode:
		return

	mode = new_mode
	mode_changed.emit(mode)

	match mode:
		GameMode.GAMEPLAY:
			AudioManager.play_music_by_id(AudioManager.MUSIC_LEVEL1)
		GameMode.DEATH:
			AudioManager.play_music_by_id(AudioManager.MUSIC_DEATH)
		GameMode.MENU:
			AudioManager.play_music_by_id(AudioManager.MUSIC_MENU)
		GameMode.COMPLETE:
			AudioManager.play_music_by_id(AudioManager.MUSIC_COMPLETE)
		GameMode.PAUSE:
			# Usually keep current track; no change
			pass
