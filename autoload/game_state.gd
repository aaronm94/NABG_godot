# autoload/game_state.gd
extends Node

	# Keep receiving input whether paused or not
func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

# ---- Mouse Capture Management ----

# Request mouse capture on next scene change (one-shot)
func request_capture_on_next_scene() -> void:
    # Connect a one-shot handler so the next scene change will capture the mouse
    # Using CONNECT_ONESHOT ensures the handler disconnects itself after running
    get_tree().scene_changed.connect(self._on_scene_changed_once, CONNECT_ONE_SHOT)

func _on_scene_changed_once(_new_root: Node = null) -> void:
    # Wait one frame to ensure the new scene is fully rendered, then capture the mouse
    await get_tree().process_frame
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# ---- Global Pause Management ----

signal paused_changed(paused: bool)

func toggle_pause() -> void:
    set_paused(!get_tree().paused)

func set_paused(p: bool) -> void:
    if get_tree().paused == p:
        return
    get_tree().paused = p
    
    # Cursor visibility/capture
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if p else Input.MOUSE_MODE_CAPTURED)
    paused_changed.emit(p)
        
func _unhandled_input(event: InputEvent) -> void:
    # No InputMap: catch ESC directly
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        toggle_pause()

# ---- Player Respawn Management ----

# Stores a tranform you can respawn from (set by checkpoints OR start point)
var respawn_transform: Transform3D
var last_death_reason: String = ""

# Group name for player scene
const PLAYER_GROUP: String = "player"

func kill_player(reason: String) -> void:
    # Called from Area3D.body_entered (physics step) → defer actual work
    last_death_reason = reason
    call_deferred("_handle_kill")

func _handle_kill() -> void:
    if respawn_transform:
        _respawn_player()
    else:
        # Reloading removes lots of nodes; always defer on the tree
        get_tree().call_deferred("reload_current_scene")

func _respawn_player() -> void:
    var player := _get_player()
    if not player:
        get_tree().call_deferred("reload_current_scene")
        return
    # Do transform/velocity changes outside the physics callback as well
    player.set_deferred("global_transform", respawn_transform)
    if "velocity" in player:
        player.set_deferred("velocity", Vector3.ZERO)
    if "_vel" in player:
        player.set_deferred("_vel", Vector3.ZERO)
    # OPTIONAL: Camera shake or fade effect can be added here
    # OPTIONAL: Emit a signal for UI updates or sound effects

func _get_player() -> Node3D:
    return get_tree().get_first_node_in_group(PLAYER_GROUP)