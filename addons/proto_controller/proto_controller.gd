# ProtoController (simplified)
# Adapted from Brackey's Unity prototyping controller
# https://www.youtube.com/watch?v=JfBmzXYFQJ8
# Features: mouse-look, WASD/Arrows, jump, sprint, freefly (noclip), gravity

extends CharacterBody3D

# ---- Signals----
signal stamina_changed(new_value: float)
signal health_changed(new_value: float)

# --- Resources / stamina ---
@export var max_stamina: float = 100.0
@export var stamina: float = 100.0
@export var stamina_cost_per_sec: float = 50.0
@export var stamina_regen_per_sec: float = 10.0
@export var stamina_recovery_threshold: float = 25.0
var is_sprinting := false
var exhausted := false

@export var max_health : float = 100.0
var health : float = 100.0

# ---- Toggles ----
@export var can_move := true
@export var has_gravity := true
@export var can_jump := true
@export var can_sprint := true
@export var can_freefly := true

# ---- Movement / look ----
@export var look_speed := 0.002
@export var base_speed := 5.0
@export var sprint_speed := 12.0
@export var decel_rate:= 20.0
@export var jump_velocity := 4.0
@export var freefly_speed := 25.0

# ---- Stair-friendly defaults (tweak to taste) ----
@export var step_max_height: float = 0.75   # max ledge height you’ll “auto step”
@export var max_slope_degrees: float = 75.0 # allow fairly steep faces on stairs
@export var extra_slides: int = 12           # more slide attempts helps on steps

# ---- Scene refs ----
@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider
@onready var interact_ray: RayCast3D = $Head/InteractRay

# ---- State ----
var base_yaw := 0.0
var look_rotation := Vector2.ZERO
var freeflying := false
var g_value := 9.8
var g_vec := Vector3.DOWN * 9.8

func _ready() -> void:
	# let HUD find us
	add_to_group("player")
	
	# gravity from project
	g_value = ProjectSettings.get_setting("physics/3d/default_gravity")
	g_vec = Vector3.DOWN * g_value
	
	# configure look
	base_yaw = rotation.y
	look_rotation = Vector2(head.rotation.x, rotation.y) # (x=pitch, y=yaw)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
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

# --- Input helper ---

func _input_vec() -> Vector2:
	return Input.get_vector("left", "right", "forward", "back")

func _move_dir_from_body(iv: Vector2) -> Vector3:
	var basis := global_transform.basis
	var dir := (basis.x * iv.x + basis.z * iv.y)
	dir.y = 0.0
	return dir.normalized() if dir.length() > 0.001 else Vector3.ZERO

func _freefly_dir_from_head(iv: Vector2) -> Vector3:
	var dir := head.global_basis * Vector3(iv.x, 0.0, iv.y)
	return dir.normalized() if dir.length() > 0.001 else Vector3.ZERO

func _apply_ground_motion(dir: Vector3, speed: float) -> void:
	if dir != Vector3.ZERO:
		var v := dir * speed
		velocity.x = v.x
		velocity.z = v.z
	else:
		velocity.x = move_toward(velocity.x, 0.0, decel_rate)
		velocity.z = move_toward(velocity.z, 0.0, decel_rate)

func _physics_process(delta: float) -> void:
	var iv := _input_vec()
	var dir_body := _move_dir_from_body(iv)
	var dir_head := _freefly_dir_from_head(iv)
	
	# Stamina drain/regeneration logic
	var wants_to_sprint := Input.is_action_pressed("sprint")
	var is_moving := dir_body != Vector3.ZERO
	
	# drain
	if not exhausted and wants_to_sprint and is_moving and stamina > 0.0:
		is_sprinting = true
		stamina = max(stamina - stamina_cost_per_sec * delta, 0.0)
		
		# if we just hit 0, mark exhausted
		if stamina <= 0.0:
			exhausted = true
			is_sprinting = false
	else:
		# regen
		is_sprinting = false
		stamina = min(stamina + stamina_regen_per_sec * delta, max_stamina)
		
		# only un-exhaust when you've refilled enough
		if exhausted and stamina >= stamina_recovery_threshold:
			exhausted = false
	
	stamina_changed.emit(stamina)
	
	# Freefly mode
	if can_freefly and freeflying:
		if dir_head != Vector3.ZERO:
			move_and_collide(dir_head * freefly_speed * delta)
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
		if exhausted:
			_apply_ground_motion(dir_body, speed * 0.5)
		else:
			_apply_ground_motion(dir_body, speed)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()

func rotate_look(delta_mouse: Vector2) -> void:
	# pitch (X) on head
	look_rotation.x = clamp(
		look_rotation.x - delta_mouse.y * look_speed, 
		deg_to_rad(-85), 
		deg_to_rad(85)
	)
	
	# yaw (Y) on body, relative to starting yaw
	look_rotation.y -= delta_mouse.x * look_speed
	
	# apply yaw WITHOUT resetting the basis to identity
	rotation.y = base_yaw + look_rotation.y

	# apply pitch on head, also without resetting to identity
	head.rotation.x = look_rotation.x

func _set_freefly(enable: bool) -> void:
	freeflying = enable
	collider.disabled = enable
	if enable:
		velocity = Vector3.ZERO

# --- Interact Logic ---
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("interact"):
		_try_interact()

func _try_interact() -> void:
	if interact_ray == null or not interact_ray.is_colliding():
		return

	var target := interact_ray.get_collider()
	if target == null:
		return

	# climb to parent until we find something interactable
	var walker := target
	while walker and not walker.has_method("interact"):
		walker = walker.get_parent()

	if walker and walker.has_method("interact"):
		walker.interact()
