# ProtoController (simplified)
# Adapted from Brackey's Unity prototyping controller
# https://www.youtube.com/watch?v=JfBmzXYFQJ8
# Features: mouse-look, WASD/Arrows, jump, sprint, freefly (noclip), gravity
# Zero setup: actions are created at runtime.

extends CharacterBody3D

# ---- Toggles ----
@export var can_move := true
@export var has_gravity := true
@export var can_jump := true
@export var can_sprint := true
@export var can_freefly := true

# ---- Speeds ----
@export var look_speed := 0.002
@export var base_speed := 6.0
@export var sprint_speed := 12.0
@export var jump_velocity := 4.5
@export var freefly_speed := 25.0

# ---- Scene refs ----
@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider

# ---- Input action names (fixed for prototype) ----
const ACT_LEFT := "move_left"
const ACT_RIGHT := "move_right"
const ACT_FORWARD := "move_forward"
const ACT_BACK := "move_back"
const ACT_JUMP := "jump"
const ACT_SPRINT := "sprint"
const ACT_FREEFLY := "freefly"

# ---- State ----
var look_rotation := Vector2.ZERO
var freeflying := false
var g_value := 9.8
var g_vec := Vector3.DOWN * 9.8

func _ready() -> void:
	g_value = ProjectSettings.get_setting("physics/3d/default_gravity")
	g_vec = Vector3.DOWN * g_value
	look_rotation = Vector2(head.rotation.x, rotation.y) # (x=pitch, y=yaw)

func _unhandled_input(event: InputEvent) -> void:
	# Capture / release mouse
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Look
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		rotate_look(event.relative)

	# Toggle freefly
	if can_freefly and Input.is_action_just_pressed(ACT_FREEFLY):
		_set_freefly(not freeflying)

func _physics_process(delta: float) -> void:
	# Freefly (noclip)
	if can_freefly and freeflying:
		var fly := Input.get_vector(ACT_LEFT, ACT_RIGHT, ACT_FORWARD, ACT_BACK)
		var dir := (head.global_basis * Vector3(fly.x, 0, fly.y)).normalized()
		if dir != Vector3.ZERO:
			move_and_collide(dir * freefly_speed * delta)
		return

	# Gravity
	if has_gravity and not is_on_floor():
		velocity += g_vec * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0

	# Jump
	if can_jump and is_on_floor() and Input.is_action_just_pressed(ACT_JUMP):
		velocity.y = jump_velocity

	# Ground movement
	var speed := sprint_speed if (can_sprint and Input.is_action_pressed(ACT_SPRINT)) else base_speed
	if can_move:
		var iv := Input.get_vector(ACT_LEFT, ACT_RIGHT, ACT_FORWARD, ACT_BACK)
		var dir := transform.basis * Vector3(iv.x, 0, iv.y)
		dir.y = 0.0
		if dir.length() > 0.001:
			dir = dir.normalized()
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
	else:
		velocity.x = 0
		velocity.z = 0
		# leave velocity.y to gravity unless you want to freeze falling

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

# --- Create default bindings once (no editor setup needed) ---
func _init() -> void:
	_bind(ACT_LEFT, [KEY_A, KEY_LEFT])
	_bind(ACT_RIGHT, [KEY_D, KEY_RIGHT])
	_bind(ACT_FORWARD, [KEY_W, KEY_UP])
	_bind(ACT_BACK, [KEY_S, KEY_DOWN])
	_bind(ACT_JUMP, [KEY_SPACE])
	_bind(ACT_SPRINT, [KEY_SHIFT])
	_bind(ACT_FREEFLY, [KEY_F])

func _bind(action_name: String, keys: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for keycode in keys:
		var exists := false
		for ev in InputMap.action_get_events(action_name):
			if ev is InputEventKey and ev.keycode == keycode:
				exists = true
				break
		if not exists:
			var e := InputEventKey.new()
			e.keycode = keycode
			InputMap.action_add_event(action_name, e)