# res://scenes/gameplay/player/proto_controller.gd
# ProtoController (simplified)
# Adapted from Brackey's Unity prototyping controller
# https://www.youtube.com/watch?v=JfBmzXYFQJ8
# Features: mouse-look, WASD/Arrows, jump, sprint, freefly (noclip), gravity

extends CharacterBody3D
class_name ProtoController

# ================================
#             SIGNALS
# ================================

signal stamina_changed(new_value: float)
# signal health_changed(new_value: float)

# ================================
#        STAMINA / HEALTH
# ================================

@export var max_stamina: float = 100.0
@export var stamina: float = 100.0
@export var stamina_cost_per_sec: float = 25.0
@export var stamina_regen_per_sec: float = 10.0
@export var stamina_recovery_threshold: float = 25.0

var is_sprinting: bool = false
var exhausted: bool = false

@export var max_health: float = 100.0
var health: float = 100.0

# ================================
#           TOGGLES
# ================================

@export var can_move: bool = true
@export var has_gravity: bool = true
@export var can_jump: bool = true
@export var can_sprint: bool = true
@export var can_freefly: bool = true

# ================================
#     MOVEMENT / LOOK CONFIG
# ================================

@export var look_speed: float = 0.002
@export var base_speed: float = 5.0
@export var sprint_speed: float = 12.0
@export var decel_rate: float = 20.0        # per second, applied with delta
@export var jump_velocity: float = 4.0
@export var freefly_speed: float = 25.0

@export var walk_step_interval: float = 0.40
@export var sprint_step_interval: float = 0.20
var _step_timer: float = 0.0

# ---- Stair-friendly defaults ----
@export var step_max_height: float = 0.75    # max ledge height auto-step
@export var max_slope_degrees: float = 75.0  # allow fairly steep stairs
@export var extra_slides: int = 12           # more slide attempts helps on steps

# ================================
#          NODE REFERENCES
# ================================

@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider
@onready var interact_ray: RayCast3D = $Head/InteractRay

@export var interact_label_ui: Label

# ================================
#            STATE
# ================================

var base_yaw: float = 0.0
var look_rotation: Vector2 = Vector2.ZERO
var freeflying: bool = false

var g_value: float = 9.8
var g_vec: Vector3 = Vector3.DOWN * 9.8

var _current_interactable: Node = null

# ================================
#         LIFECYCLE HOOKS
# ================================

func _ready() -> void:
	randomize()

	add_to_group("player")

	g_value = ProjectSettings.get_setting("physics/3d/default_gravity")
	g_vec = Vector3.DOWN * g_value

	base_yaw = rotation.y
	look_rotation = Vector2(head.rotation.x, rotation.y) # (x=pitch, y=yaw)

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Stair / step handling
	floor_snap_length = step_max_height * 1.25
	floor_max_angle = deg_to_rad(max_slope_degrees)
	max_slides = extra_slides
	safe_margin = 0.02

func _unhandled_input(event: InputEvent) -> void:
	# Mouse look
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		rotate_look(event.relative)

	# Toggle freefly
	if can_freefly and Input.is_action_just_pressed("freefly"):
		_set_freefly(!freeflying)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact()

func _physics_process(delta: float) -> void:
	var input_vec := _input_vec()
	var dir_body := _move_dir_from_body(input_vec)
	var dir_head := _freefly_dir_from_head(input_vec)

	_update_stamina(delta, dir_body)

	# Freefly mode (no gravity, manual motion)
	if can_freefly and freeflying:
		if dir_head != Vector3.ZERO:
			move_and_collide(dir_head * freefly_speed * delta)
		return

	_apply_gravity(delta)
	_handle_jump()

	# Ground movement
	var speed: float = sprint_speed if (can_sprint and is_sprinting) else base_speed
	if can_move:
		if exhausted:
			_apply_ground_motion(dir_body, speed * 0.5, delta)
		else:
			_apply_ground_motion(dir_body, speed, delta)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	_update_footsteps(delta, dir_body)

	move_and_slide()

	_update_interact_highlight()

# ================================
#        INPUT / MOVEMENT
# ================================

func _input_vec() -> Vector2:
	return Input.get_vector("left", "right", "forward", "back")

func _move_dir_from_body(iv: Vector2) -> Vector3:
	var dir: Vector3 = basis.x * iv.x + basis.z * iv.y
	dir.y = 0.0
	return dir.normalized() if dir.length() > 0.001 else Vector3.ZERO

func _freefly_dir_from_head(iv: Vector2) -> Vector3:
	var dir: Vector3 = head.global_basis * Vector3(iv.x, 0.0, iv.y)
	return dir.normalized() if dir.length() > 0.001 else Vector3.ZERO

func _apply_ground_motion(dir: Vector3, speed: float, delta: float) -> void:
	if dir != Vector3.ZERO:
		var v: Vector3 = dir * speed
		velocity.x = v.x
		velocity.z = v.z
	else:
		# decel_rate now time-scaled (frame-rate independent)
		velocity.x = move_toward(velocity.x, 0.0, decel_rate * delta)
		velocity.z = move_toward(velocity.z, 0.0, decel_rate * delta)

func _apply_gravity(delta: float) -> void:
	if has_gravity and not is_on_floor():
		velocity += g_vec * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0

func _handle_jump() -> void:
	if can_jump and is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

func rotate_look(delta_mouse: Vector2) -> void:
	# Pitch (X) on head
	look_rotation.x = clamp(
		look_rotation.x - delta_mouse.y * look_speed,
		deg_to_rad(-85.0),
		deg_to_rad(85.0)
	)

	# Yaw (Y) on body, relative to starting yaw
	look_rotation.y -= delta_mouse.x * look_speed

	rotation.y = base_yaw + look_rotation.y
	head.rotation.x = look_rotation.x

func _set_freefly(enable: bool) -> void:
	freeflying = enable
	collider.disabled = enable
	if enable:
		velocity = Vector3.ZERO

# ================================
#        STAMINA / FOOTSTEPS
# ================================

func _update_stamina(delta: float, dir_body: Vector3) -> void:
	var wants_to_sprint: bool = Input.is_action_pressed("sprint")
	var is_moving: bool = dir_body != Vector3.ZERO

	if not exhausted and wants_to_sprint and is_moving and stamina > 0.0:
		is_sprinting = true
		stamina = max(stamina - stamina_cost_per_sec * delta, 0.0)

		if stamina <= 0.0:
			exhausted = true
			is_sprinting = false
	else:
		is_sprinting = false
		stamina = min(stamina + stamina_regen_per_sec * delta, max_stamina)

		if exhausted and stamina >= stamina_recovery_threshold:
			exhausted = false

	stamina_changed.emit(stamina)

func _update_footsteps(delta: float, dir_body: Vector3) -> void:
	var on_ground: bool = is_on_floor()
	var moving: bool = dir_body != Vector3.ZERO and can_move

	if on_ground and moving:
		var interval: float = walk_step_interval
		var pitch: float = 1.0

		if can_sprint and is_sprinting:
			interval = sprint_step_interval
			pitch = 1.15

		_step_timer -= delta

		if _step_timer <= 0.0:
			AudioManager.play_random_footstep(pitch + randf_range(-0.03, 0.03))
			_step_timer = interval
	else:
		# Reset so the first step fires immediately when you start moving again
		_step_timer = 0.0

# ================================
#        INTERACT SYSTEM
# ================================

func _try_interact() -> void:
	var target := _get_interact_target()
	if target and target.has_method("interact"):
		target.interact()

func _get_interact_target() -> Node:
	if interact_ray == null or not interact_ray.is_colliding():
		return null

	var hit := interact_ray.get_collider()
	if hit == null:
		return null

	var walker: Node = hit
	while walker and not walker.has_method("interact"):
		walker = walker.get_parent()

	return walker

func _update_interact_highlight() -> void:
	var new_target := _get_interact_target()

	if new_target == _current_interactable:
		_update_interact_label()
		return

	if _current_interactable and _current_interactable.has_method("set_highlighted"):
		_current_interactable.set_highlighted(false)

	_current_interactable = new_target

	if _current_interactable and _current_interactable.has_method("set_highlighted"):
		_current_interactable.set_highlighted(true)

	_update_interact_label()

func _update_interact_label() -> void:
	if interact_label_ui == null:
		return

	if _current_interactable == null:
		interact_label_ui.visible = false
		return

	var label_text := "Press E"
	if _current_interactable.has_method("get_interact_label"):
		label_text = _current_interactable.get_interact_label()

	interact_label_ui.text = label_text
	interact_label_ui.visible = true
