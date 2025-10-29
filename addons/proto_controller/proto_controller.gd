# ProtoController (simplified)
# Adapted from Brackey's Unity prototyping controller
# https://www.youtube.com/watch?v=JfBmzXYFQJ8
# Features: mouse-look, WASD/Arrows, jump, sprint, freefly (noclip), gravity
# Zero setup: actions are created at runtime.

extends CharacterBody3D

# ---- Player Resources ----
signal stamina_changed(new_value: float)
signal health_changed(new_value: float)

# --- Stamina / Sprint config ---
@export var max_stamina: float = 100.0
@export var stamina: float = 100.0
var is_sprinting := false

@export var max_health : float = 100.0
var health : float = 100.0

# ---- Toggles ----
@export var can_move := true
@export var has_gravity := true
@export var can_jump := true
@export var can_sprint := true
@export var can_freefly := true

# ---- Speeds ----
@export var look_speed := 0.002
@export var base_speed := 5.0
@export var sprint_speed := 10.0
@export var jump_velocity := 4.0
@export var freefly_speed := 25.0

# ---- Stair-friendly defaults (tweak to taste) ----
@export var step_max_height: float = 0.75   # max ledge height you’ll “auto step”
@export var max_slope_degrees: float = 75.0 # allow fairly steep faces on stairs
@export var extra_slides: int = 12           # more slide attempts helps on steps

# ---- Scene refs ----
@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider

# ---- State ----
var look_rotation := Vector2.ZERO
var freeflying := false
var g_value := 9.8
var g_vec := Vector3.DOWN * 9.8

func _ready() -> void:
	g_value = ProjectSettings.get_setting("physics/3d/default_gravity")
	g_vec = Vector3.DOWN * g_value
	look_rotation = Vector2(head.rotation.x, rotation.y) # (x=pitch, y=yaw)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	stamina_changed.emit(stamina)
	#health_changed.emit(health)
	
	
	# --- Stair helper ---
	# Snap keeps you glued to surfaces and helps you mount small ledges.
	floor_snap_length = step_max_height * 1.25
	# Let the body consider steeper surfaces as "floor".
	floor_max_angle = deg_to_rad(max_slope_degrees)
	# Give the solver more chances to slide along risers.
	max_slides = extra_slides
	# A small margin prevents getting wedged on sharp edges.
	safe_margin = 0.02

func _unhandled_input(event: InputEvent) -> void:
	# Look
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		rotate_look(event.relative)

	# Toggle freefly
	if can_freefly and Input.is_action_just_pressed("freefly"):
		_set_freefly(not freeflying)

# --- physics helper ---

func _input_vec() -> Vector2:
	return Input.get_vector("left", "right", "forward", "back")

func _move_dir_from_head(iv: Vector2) -> Vector3:
	var d := head.global_basis * Vector3(iv.x, 0.0, iv.y)
	return d.normalized()

func _apply_ground_motion(dir: Vector3, speed: float) -> void:
	if dir != Vector3.ZERO:
		var v := dir * speed
		velocity.x = v.x
		velocity.z = v.z
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

func _physics_process(delta: float) -> void:
	
	var iv := _input_vec()
	var dir := _move_dir_from_head(iv)
	
	# Example stamina drain/regeneration logic
	if Input.is_action_pressed("sprint") and stamina > 0.0:
		is_sprinting = true
		stamina = max(stamina - 10.0 * delta, 0.0)
	else:
		is_sprinting = false
		stamina = min(stamina + 5.0 * delta, 100.0)
	
	emit_signal("stamina_changed", stamina)
	
	# Freefly (noclip)
	if can_freefly and freeflying:
		if dir != Vector3.ZERO:
			move_and_collide(dir * freefly_speed * delta)
		return

	# Gravity
	if has_gravity and not is_on_floor():
		velocity += g_vec * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0

	# Jump
	if can_jump and is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	# Ground movement
	var speed := sprint_speed if (can_sprint and is_sprinting) else base_speed

	if can_move:
		_apply_ground_motion(dir, speed)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		# keep velocity.y for gravity

	move_and_slide()

func rotate_look(delta_mouse: Vector2) -> void:
	# yaw (y) on body, pitch (x) on head; clamp pitch
	look_rotation.x = clamp(look_rotation.x - delta_mouse.y * look_speed, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= delta_mouse.x * look_speed
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)

func _set_freefly(enable: bool) -> void:
	freeflying = enable
	collider.disabled = enable
	if enable:
		velocity = Vector3.ZERO
