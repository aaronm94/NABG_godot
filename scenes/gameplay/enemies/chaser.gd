# res://scenes/gameplay/enemies/chaser.gd
## Chaser enemy that idles until it detects the player, then pursues and kills on contact.

extends CharacterBody3D
class_name Chaser

# ================================
#             ENUMS
# ================================

enum State { IDLE, CHASING }

# ================================
#           EXPORTS
# ================================

@export var move_speed: float = 4.0
@export var acceleration: float = 10.0
@export var gravity: float = 9.8
@export var auto_acquire_player: bool = true

## Reason passed into GameState.kill_player().
@export_enum("fall", "enemy_capture")
var death_reason: String = "enemy_capture"

## Optional override for the SFX id played on kill.
## If empty, a default from AudioManager will be used.
@export var death_sfx_id: String = ""

# ================================
#        MEMBER VARIABLES
# ================================

var state: State = State.IDLE
var target: Node3D = null

# ================================
#         ONREADY NODES
# ================================

@onready var detection_area: Area3D = $DetectionArea
@onready var kill_area: Area3D = $KillArea
@onready var idle_sfx: AudioStreamPlayer3D = $IdleSFX
@onready var chasing_sfx: AudioStreamPlayer3D = $ChasingSFX

# ================================
#         LIFECYCLE HOOKS
# ================================

func _ready() -> void:
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	kill_area.body_entered.connect(_on_kill_body_entered)

	if auto_acquire_player:
		_try_set_player_target()

	_set_state(State.IDLE)
	print("Chaser: Ready at", global_transform.origin)

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)

	match state:
		State.IDLE:
			_update_idle_movement(delta)
		State.CHASING:
			if is_instance_valid(target):
				_chase_target(delta)
			else:
				print("Chaser: Lost target, switching to IDLE")
				_set_state(State.IDLE)

	move_and_slide()

# ================================
#          MOVEMENT / AI
# ================================

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

func _update_idle_movement(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
	velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)

func _chase_target(delta: float) -> void:
	if not is_instance_valid(target):
		return

	var to_target: Vector3 = target.global_transform.origin - global_transform.origin
	var flat: Vector3 = to_target
	flat.y = 0.0

	if flat.length() < 0.1:
		# Basically on top of the player already
		return

	var dir: Vector3 = flat.normalized()
	var desired_velocity: Vector3 = dir * move_speed

	velocity.x = lerp(velocity.x, desired_velocity.x, acceleration * delta)
	velocity.z = lerp(velocity.z, desired_velocity.z, acceleration * delta)

	look_at(target.global_transform.origin, Vector3.UP)

# ================================
#      TARGET / DETECTION LOGIC
# ================================

func set_target(new_target: Node3D) -> void:
	if new_target == null:
		return

	target = new_target
	print("Chaser: Target set to", target.name)
	_set_state(State.CHASING)

func _try_set_player_target() -> void:
	# Prefer GameState.player
	if GameState.player and is_instance_valid(GameState.player):
		print("Chaser: Auto-acquire GameState.player:", GameState.player)
		set_target(GameState.player)
		return

	# Fallback: first node in group "player"
	var players: Array = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		print("Chaser: Auto-acquire group 'player':", players[0])
		set_target(players[0] as Node3D)
	else:
		print("Chaser: No player found for auto-acquire")

func _on_detection_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		print("Chaser: DetectionArea → player entered, CHASING")
		set_target(body as Node3D)

func _on_detection_body_exited(body: Node) -> void:
	if body == target and state == State.CHASING:
		print("Chaser: DetectionArea → player exited, IDLE")
		target = null
		_set_state(State.IDLE)

# ================================
#            KILL LOGIC
# ================================

func _on_kill_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	_kill_now()

func _kill_now() -> void:
	idle_sfx.stop()
	chasing_sfx.stop()

	var sfx_id := death_sfx_id
	if sfx_id.is_empty():
		# Use a sensible default from AudioManager if nothing is set
		sfx_id = AudioManager.SFX_DEATH_ENEMY

	AudioManager.play_sfx(sfx_id)
	GameState.kill_player(death_reason)

# ================================
#          STATE / SFX LOGIC
# ================================

func _set_state(new_state: State) -> void:
	if state == new_state:
		return

	state = new_state
	_on_state_changed()
	print("Chaser: State changed to", state)

func _on_state_changed() -> void:
	match state:
		State.IDLE:
			if not idle_sfx.playing:
				idle_sfx.play()
			chasing_sfx.stop()
		State.CHASING:
			idle_sfx.stop()
			if not chasing_sfx.playing:
				chasing_sfx.play()
