extends CharacterBody3D

@export var base_speed: float = 5.0
@export var speed_increase_amount: float = 0.5
@export var speed_increase_interval: float = 60.0
@export var acceleration: float = 6.0
@export var gravity: float = 9.8

var current_speed: float
var time_since_increase := 0.0
var player: CharacterBody3D = null

@onready var hitbox = $Hitbox


func _ready():
	current_speed = base_speed
	call_deferred("_post_spawn_setup")  # ← IMPORTANT FIX
	print("SCRIPT ON ENEMY AT RUNTIME:", self.get_script())
	print("TYPE NAME:", self.get_class())
	print("HAS _physics_process:", self.has_method("_physics_process"))

func _post_spawn_setup():
	_snap_to_floor()
	_find_player()
	hitbox.body_entered.connect(_on_body_entered)
	print("Enemy post-setup complete.")


func set_target(p: CharacterBody3D):
	player = p
	print("Chaser: Target set:", p)


func _find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		print("Chaser: Found player:", player)


func _physics_process(delta):
	print("PHYSICS RUNNING FOR ENEMY")
	if player == null:
		return

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	# Speed ramp
	time_since_increase += delta
	if time_since_increase >= speed_increase_interval:
		current_speed += speed_increase_amount
		time_since_increase = 0.0

	var pos = global_transform.origin
	var target_pos = player.global_transform.origin
	var direction = (target_pos - pos)
	direction.y = 0
	direction = direction.normalized()

	# Face player
	if direction.length() > 0.001:
		var target_rot = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rot, 6.0 * delta)

	# DIRECT velocity (no lerp)
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed

	# Correct movement call
	move_and_slide()

	print("DIR:", direction)
	print("VEL:", velocity)


func _on_body_entered(body):
	if body.is_in_group("player"):
		print("Enemy killed player!")
		
		# Call global death handler
		GameState.kill_player("enemy")

func _snap_to_floor():
	print("Snapping enemy to floor…")
	
	var origin_above = global_transform.origin + Vector3.UP * 2.0
	var target = origin_above + Vector3.DOWN * 20.0

	var params := PhysicsRayQueryParameters3D.new()
	params.from = origin_above
	params.to = target
	params.collide_with_bodies = true

	var hit = get_world_3d().direct_space_state.intersect_ray(params)

	if hit.has("position"):
		global_transform.origin = hit["position"]
		print("Enemy snapped to floor at:", hit["position"])
	else:
		print("⚠ FLOOR SNAP FAILED – enemy will float!")
